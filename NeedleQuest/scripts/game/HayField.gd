extends Node3D
## The haystack: a layered grid of hay clumps rendered with ONE
## MultiMesh per layer (a handful of draw calls for thousands of strands).
## No per-straw physics: interaction uses analytic ray-sphere picking and
## lightweight transform animation - fast on mid-range phones.

signal clump_removed(removed_count: int, pos: Vector3)
signal item_revealed(id: String)
signal item_collected(id: String, value: int, pos: Vector3)
signal needle_revealed
signal needle_tapped
signal secret_opened
signal prop_primed
signal prop_moved
signal blocked_by_prop

const CELL := 0.55
const LAYER_H := 0.3
const REMOVE_ANIM_T := 0.45

var data: Dictionary
var rng := RandomNumberGenerator.new()

# cell -> {h:int, h0:int, prop:Dictionary or null, secret:bool, chest:Node3D}
var cells: Dictionary = {}
# per layer: {mm:MultiMesh, mmi:MultiMeshInstance3D}
var layers: Array[Dictionary] = []
# clump lookup: Vector3i(cell.x, cell.y, layer) -> {start:int, count:int, center:Vector3}
var clumps: Dictionary = {}
var strands_pc: int = 10
var removed_total: int = 0

# item records
var items: Array[Dictionary] = []
var needle_rec: Dictionary = {}

var props: Array[Dictionary] = []
var _animating: Array[Dictionary] = []
var _base_transforms: Dictionary = {}  # "layer:idx" -> Transform3D


func setup(level_data: Dictionary) -> void:
	data = level_data
	rng.seed = int(data["seed"]) + 777
	strands_pc = G.strands_per_clump()
	var skin: Dictionary = G.SKINS.get(SaveGame.data.get("skin", "classic"), G.SKINS["classic"])
	var c_base: Color = skin["base"]
	var c_tip: Color = skin["tip"]

	var src_cells: Dictionary = data["cells"]
	var max_layers: int = data["max_layers"]

	# ---- count clumps per layer
	var layer_counts: Array[int] = []
	for l in max_layers:
		layer_counts.append(0)
	for cell: Vector2i in src_cells.keys():
		var h: int = src_cells[cell]
		cells[cell] = {"h": h, "h0": h, "prop": null, "secret": false, "chest": null}
		for l in h:
			layer_counts[l] += 1

	# ---- strand mesh (shared)
	var strand := BoxMesh.new()
	strand.size = Vector3(0.035, 0.035, 0.48)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mat.albedo_color = Color.WHITE
	strand.material = mat

	# ---- build one MultiMesh per layer
	for l in max_layers:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = strand
		mm.instance_count = layer_counts[l] * strands_pc
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if (G.shadows_enabled() and l == max_layers - 1) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		layers.append({"mm": mm, "mmi": mmi})

	# ---- fill instances
	var cursors: Array[int] = []
	for l in max_layers:
		cursors.append(0)
	for cell: Vector2i in src_cells.keys():
		var h: int = src_cells[cell]
		for l in h:
			var mm: MultiMesh = layers[l]["mm"]
			var start: int = cursors[l]
			var center := cell_world(cell) + Vector3(0, float(l) * LAYER_H + 0.16, 0)
			center.x += rng.randf_range(-0.08, 0.08)
			center.z += rng.randf_range(-0.08, 0.08)
			var depth_shade := lerpf(0.5, 1.0, float(l + 1) / float(max_layers))
			for s in strands_pc:
				var idx := start + s
				var off := Vector3(rng.randf_range(-0.24, 0.24), rng.randf_range(-0.1, 0.12), rng.randf_range(-0.24, 0.24))
				var basis := Basis.from_euler(Vector3(
					rng.randf_range(-0.25, 0.25),
					rng.randf_range(0.0, TAU),
					rng.randf_range(-0.3, 0.3)))
				var t := Transform3D(basis, center + off)
				mm.set_instance_transform(idx, t)
				var col := c_base.lerp(c_tip, rng.randf()) * depth_shade
				col.a = 1.0
				mm.set_instance_color(idx, col)
				_base_transforms["%d:%d" % [l, idx]] = t
			clumps[Vector3i(cell.x, cell.y, l)] = {"start": start, "count": strands_pc, "center": center}
			cursors[l] = start + strands_pc

	# ---- hidden items
	for it: Dictionary in data["items"]:
		var node := ItemFactory.make_item(it["id"])
		var cell2: Vector2i = it["cell"]
		var lay: int = it["layer"]
		node.position = cell_world(cell2) + Vector3(rng.randf_range(-0.12, 0.12), float(lay) * LAYER_H + 0.1, rng.randf_range(-0.12, 0.12))
		node.rotation_degrees.y = rng.randf_range(0, 360)
		node.visible = false
		add_child(node)
		items.append({"id": it["id"], "cell": cell2, "layer": lay, "node": node, "revealed": false, "collected": false})

	# ---- the needle
	var ncell: Vector2i = data["needle_cell"]
	var nlayer: int = data["needle_layer"]
	var nnode := ItemFactory.make_needle()
	nnode.position = cell_world(ncell) + Vector3(0, float(nlayer) * LAYER_H + 0.08, 0)
	nnode.rotation_degrees = Vector3(0, rng.randf_range(0, 360), rng.randf_range(-12, 12))
	nnode.visible = false
	add_child(nnode)
	needle_rec = {"cell": ncell, "layer": nlayer, "node": nnode, "revealed": false}

	# ---- secret cells
	for sc: Vector2i in data["secrets"]:
		if cells.has(sc):
			cells[sc]["secret"] = true

	# ---- movable props
	for pr: Dictionary in data["props"]:
		var cell3: Vector2i = pr["cell"]
		if not cells.has(cell3):
			continue
		var pnode := ItemFactory.make_prop(pr["kind"])
		var h3: int = cells[cell3]["h"]
		pnode.position = cell_world(cell3) + Vector3(0, float(h3) * LAYER_H + 0.05, 0)
		pnode.rotation_degrees.y = rng.randf_range(0, 360)
		add_child(pnode)
		var rec := {"kind": pr["kind"], "cell": cell3, "node": pnode, "primed_until": 0.0, "moved": false}
		props.append(rec)
		cells[cell3]["prop"] = rec


func cell_world(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * CELL, 0, float(cell.y) * CELL)


func needle_world() -> Vector3:
	return (needle_rec["node"] as Node3D).global_position


func total_remaining() -> int:
	var n := 0
	for c: Vector2i in cells.keys():
		n += int(cells[c]["h"])
	return n

# ------------------------------------------------------------------ picking

static func _ray_sphere(o: Vector3, d: Vector3, c: Vector3, r: float) -> float:
	var oc := o - c
	var b := oc.dot(d)
	var cq := oc.dot(oc) - r * r
	var disc := b * b - cq
	if disc < 0.0:
		return -1.0
	var t := -b - sqrt(disc)
	return t if t > 0.0 else -1.0


## Returns a Dictionary describing what the ray hits first, or {} if nothing.
func pick(o: Vector3, d: Vector3) -> Dictionary:
	var best_t := 1e9
	var best: Dictionary = {}
	# props (they sit on top)
	for pr: Dictionary in props:
		if pr["moved"]:
			continue
		var t := _ray_sphere(o, d, (pr["node"] as Node3D).global_position + Vector3(0, 0.25, 0), 0.5)
		if t > 0.0 and t < best_t:
			best_t = t
			best = {"type": "prop", "prop": pr}
	# chests
	for c: Vector2i in cells.keys():
		var chest: Variant = cells[c]["chest"]
		if chest != null and is_instance_valid(chest):
			var t2 := _ray_sphere(o, d, (chest as Node3D).global_position + Vector3(0, 0.2, 0), 0.45)
			if t2 > 0.0 and t2 < best_t:
				best_t = t2
				best = {"type": "chest", "cell": c}
	# needle
	if needle_rec["revealed"]:
		var t3 := _ray_sphere(o, d, needle_world(), 0.34)
		if t3 > 0.0 and t3 < best_t:
			best_t = t3
			best = {"type": "needle"}
	# revealed items
	for it: Dictionary in items:
		if it["revealed"] and not it["collected"]:
			var t4 := _ray_sphere(o, d, (it["node"] as Node3D).global_position, 0.3)
			if t4 > 0.0 and t4 < best_t:
				best_t = t4
				best = {"type": "item", "item": it}
	# top clumps
	for c2: Vector2i in cells.keys():
		var h: int = cells[c2]["h"]
		if h <= 0:
			continue
		var key := Vector3i(c2.x, c2.y, h - 1)
		if not clumps.has(key):
			continue
		var center: Vector3 = clumps[key]["center"]
		var t5 := _ray_sphere(o, d, center + Vector3(0, 0.06, 0), 0.4)
		if t5 > 0.0 and t5 < best_t:
			best_t = t5
			best = {"type": "clump", "cell": c2, "pos": center}
	return best

# ------------------------------------------------------------------ removal

func remove_top(cell: Vector2i, fx: bool = true) -> bool:
	if not cells.has(cell):
		return false
	var cd: Dictionary = cells[cell]
	if cd["prop"] != null and not cd["prop"]["moved"]:
		blocked_by_prop.emit()
		return false
	var h: int = cd["h"]
	if h <= 0:
		return false
	var l := h - 1
	var key := Vector3i(cell.x, cell.y, l)
	var clump: Dictionary = clumps[key]
	cd["h"] = h - 1
	removed_total += 1
	_launch_strands(l, clump)
	if fx:
		FX.dust(self, clump["center"], 1.0)
	_after_removal(cell, clump["center"])
	return true


func _launch_strands(layer: int, clump: Dictionary) -> void:
	var mm: MultiMesh = layers[layer]["mm"]
	var center: Vector3 = clump["center"]
	var start: int = clump["start"]
	for s in int(clump["count"]):
		var idx := start + s
		var base: Transform3D = _base_transforms.get("%d:%d" % [layer, idx], Transform3D())
		var out_dir := (base.origin - center)
		out_dir.y = 0.0
		if out_dir.length() < 0.01:
			out_dir = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1))
		out_dir = out_dir.normalized()
		var vel := out_dir * rng.randf_range(0.8, 2.0) + Vector3(0, rng.randf_range(1.6, 3.0), 0)
		_animating.append({
			"mm": mm, "idx": idx, "base": base, "vel": vel,
			"axis": Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized(),
			"spin": rng.randf_range(4.0, 12.0), "age": 0.0,
		})


func _process(delta: float) -> void:
	if _animating.is_empty():
		return
	var speed_mult := 1.0 + 0.15 * float(G.upgrade_level("remove_speed"))
	var i := _animating.size() - 1
	while i >= 0:
		var a: Dictionary = _animating[i]
		a["age"] = float(a["age"]) + delta * speed_mult
		var p: float = float(a["age"]) / REMOVE_ANIM_T
		var mm: MultiMesh = a["mm"]
		if p >= 1.0:
			var dead: Transform3D = a["base"]
			dead.basis = dead.basis.scaled(Vector3.ONE * 0.0001)
			dead.origin = Vector3(0, -50, 0)
			mm.set_instance_transform(int(a["idx"]), dead)
			_animating.remove_at(i)
		else:
			var base: Transform3D = a["base"]
			var age: float = float(a["age"])
			var origin: Vector3 = base.origin + (a["vel"] as Vector3) * age + Vector3(0, -6.0, 0) * age * age * 0.5
			var basis: Basis = base.basis.rotated(a["axis"], float(a["spin"]) * age)
			basis = basis.scaled(Vector3.ONE * maxf(1.0 - p, 0.05))
			mm.set_instance_transform(int(a["idx"]), Transform3D(basis, origin))
		i -= 1


func _after_removal(cell: Vector2i, pos: Vector3) -> void:
	var cd: Dictionary = cells[cell]
	var h: int = cd["h"]
	# reveal items in this cell
	for it: Dictionary in items:
		if it["cell"] == cell and not it["revealed"] and h <= int(it["layer"]):
			it["revealed"] = true
			var node: Node3D = it["node"]
			node.visible = true
			node.scale = Vector3.ONE * 0.1
			var tw := node.create_tween()
			tw.tween_property(node, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			Snd.play("pop", -6.0)
			item_revealed.emit(it["id"])
	# reveal needle
	if not needle_rec["revealed"] and needle_rec["cell"] == cell and h <= int(needle_rec["layer"]):
		needle_rec["revealed"] = true
		var nn: Node3D = needle_rec["node"]
		nn.visible = true
		nn.scale = Vector3.ONE * 0.1
		var tw2 := nn.create_tween()
		tw2.tween_property(nn, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_needle_shimmer_loop()
		needle_revealed.emit()
	# secret chest
	if h == 0 and cd["secret"] and cd["chest"] == null:
		var chest := ItemFactory.make_chest()
		chest.position = cell_world(cell)
		chest.scale = Vector3.ONE * 0.1
		add_child(chest)
		cd["chest"] = chest
		var tw3 := chest.create_tween()
		tw3.tween_property(chest, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Snd.play("secret")
	clump_removed.emit(removed_total, pos)


func _needle_shimmer_loop() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.4
	timer.timeout.connect(func() -> void:
		if needle_rec["revealed"] and is_instance_valid(needle_rec["node"]):
			FX.shimmer(self, needle_world() + Vector3(0, 0.1, 0), false)
	)
	add_child(timer)
	timer.start()

# ------------------------------------------------------------------ tools

func broom_sweep(world_pos: Vector3, radius: float) -> int:
	var n := 0
	for c: Vector2i in cells.keys():
		if int(cells[c]["h"]) <= 0:
			continue
		if cell_world(c).distance_to(Vector3(world_pos.x, 0, world_pos.z)) <= radius:
			if remove_top(c, n < 6):
				n += 1
	return n


func fan_blow(world_pos: Vector3, radius: float) -> int:
	var n := 0
	FX.wind(self, world_pos + Vector3(0, 0.4, 0))
	for c: Vector2i in cells.keys():
		if int(cells[c]["h"]) <= 0:
			continue
		if cell_world(c).distance_to(Vector3(world_pos.x, 0, world_pos.z)) <= radius:
			if remove_top(c, n < 8):
				n += 1
	return n


func dig_column(cell: Vector2i, radius_cells: int) -> int:
	var n := 0
	for dx in range(-radius_cells, radius_cells + 1):
		for dz in range(-radius_cells, radius_cells + 1):
			var c := cell + Vector2i(dx, dz)
			if not cells.has(c):
				continue
			var guard := 0
			while int(cells[c]["h"]) > 0 and guard < 16:
				if not remove_top(c, guard == 0):
					break
				n += 1
				guard += 1
	return n


func magnet_scan(world_pos: Vector3, radius: float) -> int:
	var found := 0
	for it: Dictionary in items:
		if it["revealed"] or it["collected"]:
			continue
		var idb: Dictionary = G.ITEMS.get(it["id"], {})
		if not bool(idb.get("metal", false)):
			continue
		var p := cell_world(it["cell"])
		if p.distance_to(Vector3(world_pos.x, 0, world_pos.z)) <= radius:
			var h: int = cells[it["cell"]]["h"]
			FX.marker(self, p + Vector3(0, float(h) * LAYER_H + 0.45, 0), Color(0.4, 0.7, 1.0), 3.0)
			found += 1
	if not needle_rec["revealed"]:
		var np := cell_world(needle_rec["cell"])
		if np.distance_to(Vector3(world_pos.x, 0, world_pos.z)) <= radius:
			var h2: int = cells[needle_rec["cell"]]["h"]
			FX.marker(self, np + Vector3(0, float(h2) * LAYER_H + 0.45, 0), Color(0.4, 0.7, 1.0), 3.0)
			found += 1
	return found

# ------------------------------------------------------------------ interactions

func collect_item(it: Dictionary) -> void:
	if it["collected"]:
		return
	it["collected"] = true
	var node: Node3D = it["node"]
	var value := int(G.ITEMS.get(it["id"], {}).get("value", 1))
	FX.burst(self, node.global_position, G.RARITY_COLORS[int(G.ITEMS.get(it["id"], {}).get("rarity", 0))])
	var tw := node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "position:y", node.position.y + 1.2, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector3.ONE * 0.05, 0.45).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(node.queue_free)
	item_collected.emit(it["id"], value, node.global_position)


func open_chest(cell: Vector2i) -> void:
	var cd: Dictionary = cells[cell]
	var chest: Node3D = cd["chest"]
	if chest == null or not is_instance_valid(chest):
		return
	cd["chest"] = null
	var lid: Node3D = chest.get_node_or_null("Lid")
	var tw := chest.create_tween()
	if lid:
		tw.tween_property(lid, "rotation_degrees:x", -110.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.2)
	tw.tween_property(chest, "scale", Vector3.ONE * 0.02, 0.4)
	tw.tween_callback(chest.queue_free)
	FX.burst(self, chest.global_position + Vector3(0, 0.4, 0), Color(1.0, 0.85, 0.3))
	secret_opened.emit()


func tap_prop(pr: Dictionary) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var node: Node3D = pr["node"]
	if now < float(pr["primed_until"]):
		pr["moved"] = true
		cells[pr["cell"]]["prop"] = null
		var dir := node.position
		dir.y = 0
		if dir.length() < 0.1:
			dir = Vector3(1, 0, 0)
		dir = dir.normalized()
		var dest := dir * (float(data["radius"]) * CELL + 2.5)
		dest.y = 0.0
		var tw := node.create_tween()
		tw.set_parallel(true)
		tw.tween_property(node, "position", dest, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(node, "rotation_degrees:y", node.rotation_degrees.y + 180.0, 0.6)
		Snd.play("whoosh")
		prop_moved.emit()
	else:
		pr["primed_until"] = now + 2.0
		var tw2 := node.create_tween()
		tw2.tween_property(node, "rotation_degrees:z", 8.0, 0.08)
		tw2.tween_property(node, "rotation_degrees:z", -8.0, 0.12)
		tw2.tween_property(node, "rotation_degrees:z", 0.0, 0.08)
		Snd.play("click", -4.0)
		prop_primed.emit()
