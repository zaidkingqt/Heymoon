class_name EnvBuilder
## Builds themed 3D environments: sky, lighting, fog, ground and
## decorative props. 8 original themes, all procedural geometry.

const THEME_DATA := {
	"meadow": {
		"sky_top": Color(0.35, 0.6, 0.9), "sky_bottom": Color(0.8, 0.88, 0.95),
		"sun": Color(1.0, 0.96, 0.85), "energy": 1.3, "angle": -55.0,
		"ground": Color(0.38, 0.52, 0.25), "fog": Color(0.75, 0.85, 0.9), "fog_density": 0.004,
		"ambient": 0.45, "night": false, "decor": "meadow",
	},
	"farm": {
		"sky_top": Color(0.4, 0.62, 0.88), "sky_bottom": Color(0.9, 0.85, 0.7),
		"sun": Color(1.0, 0.93, 0.78), "energy": 1.25, "angle": -48.0,
		"ground": Color(0.5, 0.42, 0.26), "fog": Color(0.85, 0.8, 0.65), "fog_density": 0.005,
		"ambient": 0.42, "night": false, "decor": "farm",
	},
	"barn": {
		"sky_top": Color(0.3, 0.32, 0.38), "sky_bottom": Color(0.55, 0.5, 0.42),
		"sun": Color(1.0, 0.85, 0.6), "energy": 0.9, "angle": -40.0,
		"ground": Color(0.42, 0.33, 0.22), "fog": Color(0.45, 0.4, 0.32), "fog_density": 0.012,
		"ambient": 0.3, "night": false, "decor": "barn",
	},
	"warehouse": {
		"sky_top": Color(0.25, 0.27, 0.3), "sky_bottom": Color(0.45, 0.45, 0.45),
		"sun": Color(0.9, 0.92, 1.0), "energy": 0.85, "angle": -65.0,
		"ground": Color(0.4, 0.4, 0.42), "fog": Color(0.35, 0.35, 0.38), "fog_density": 0.01,
		"ambient": 0.35, "night": false, "decor": "warehouse",
	},
	"truck": {
		"sky_top": Color(0.45, 0.65, 0.9), "sky_bottom": Color(0.9, 0.8, 0.65),
		"sun": Color(1.0, 0.9, 0.7), "energy": 1.2, "angle": -50.0,
		"ground": Color(0.35, 0.33, 0.3), "fog": Color(0.8, 0.75, 0.65), "fog_density": 0.006,
		"ambient": 0.4, "night": false, "decor": "truck",
	},
	"night": {
		"sky_top": Color(0.05, 0.07, 0.16), "sky_bottom": Color(0.12, 0.14, 0.25),
		"sun": Color(0.6, 0.7, 1.0), "energy": 0.35, "angle": -60.0,
		"ground": Color(0.16, 0.2, 0.14), "fog": Color(0.08, 0.1, 0.18), "fog_density": 0.015,
		"ambient": 0.12, "night": true, "decor": "meadow",
	},
	"factory": {
		"sky_top": Color(0.3, 0.28, 0.26), "sky_bottom": Color(0.55, 0.48, 0.4),
		"sun": Color(0.95, 0.85, 0.7), "energy": 0.8, "angle": -58.0,
		"ground": Color(0.35, 0.33, 0.3), "fog": Color(0.4, 0.36, 0.3), "fog_density": 0.014,
		"ambient": 0.3, "night": false, "decor": "warehouse",
	},
	"abandoned": {
		"sky_top": Color(0.4, 0.38, 0.3), "sky_bottom": Color(0.7, 0.6, 0.45),
		"sun": Color(1.0, 0.8, 0.55), "energy": 0.95, "angle": -35.0,
		"ground": Color(0.38, 0.35, 0.22), "fog": Color(0.6, 0.52, 0.38), "fog_density": 0.012,
		"ambient": 0.28, "night": false, "decor": "farm",
	},
}


static func build(root: Node3D, theme: String, rng: RandomNumberGenerator) -> Dictionary:
	var td: Dictionary = THEME_DATA.get(theme, THEME_DATA["meadow"])

	# ---- sky & environment
	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = td["sky_top"]
	sky_mat.sky_horizon_color = td["sky_bottom"]
	sky_mat.ground_bottom_color = td["ground"].darkened(0.4)
	sky_mat.ground_horizon_color = td["sky_bottom"]
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = td["ambient"] * 2.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = td["fog"]
	env.fog_density = td["fog_density"]
	if G.quality_index() >= 2:
		env.glow_enabled = true
		env.glow_intensity = 0.5
		env.glow_bloom = 0.1
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	# ---- sun
	var sun := DirectionalLight3D.new()
	sun.light_color = td["sun"]
	sun.light_energy = td["energy"]
	sun.rotation_degrees = Vector3(td["angle"], rng.randf_range(20.0, 70.0), 0)
	sun.shadow_enabled = G.shadows_enabled()
	sun.directional_shadow_max_distance = 40.0
	root.add_child(sun)
	if td["night"]:
		var moon := OmniLight3D.new()
		moon.light_color = Color(0.7, 0.8, 1.0)
		moon.light_energy = 0.6
		moon.omni_range = 25.0
		moon.position = Vector3(4, 8, 4)
		root.add_child(moon)

	# ---- ground
	var ground := MeshInstance3D.new()
	var gm := PlaneMesh.new()
	gm.size = Vector2(70, 70)
	ground.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = td["ground"]
	gmat.roughness = 1.0
	ground.material_override = gmat
	root.add_child(ground)
	# darker patch under the pile (fake AO / scattered hay ring)
	var patch := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 6.5
	pm.bottom_radius = 6.5
	pm.height = 0.02
	patch.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = td["ground"].darkened(0.25).lerp(Color(0.6, 0.5, 0.3), 0.35)
	pmat.roughness = 1.0
	patch.material_override = pmat
	patch.position = Vector3(0, 0.01, 0)
	root.add_child(patch)

	# ---- decorative props
	_decorate(root, td["decor"], rng, td)
	return {"env": env, "sun": sun}


static func _decorate(root: Node3D, decor: String, rng: RandomNumberGenerator, td: Dictionary) -> void:
	match decor:
		"meadow":
			for i in 7:
				var a := rng.randf_range(0.0, TAU)
				var d := rng.randf_range(11.0, 20.0)
				root.add_child(_tree(Vector3(cos(a) * d, 0, sin(a) * d), rng))
			_fence_ring(root, 9.5, 14, rng)
		"farm":
			_fence_ring(root, 9.0, 16, rng)
			root.add_child(_barn_silhouette(Vector3(0, 0, -14), false))
			for i in 3:
				var a2 := rng.randf_range(0.0, TAU)
				var d2 := rng.randf_range(10.0, 15.0)
				var barrel := ItemFactory.make_prop("barrel")
				barrel.position = Vector3(cos(a2) * d2, 0, sin(a2) * d2)
				root.add_child(barrel)
		"barn":
			root.add_child(_barn_silhouette(Vector3.ZERO, true))
			for i in 4:
				var crate := ItemFactory.make_prop("crate")
				var a3 := rng.randf_range(0.0, TAU)
				var d3 := rng.randf_range(9.0, 12.0)
				crate.position = Vector3(cos(a3) * d3, 0, sin(a3) * d3)
				crate.rotation_degrees.y = rng.randf_range(0, 360)
				root.add_child(crate)
		"warehouse":
			_walls(root, 16.0, Color(0.35, 0.36, 0.4))
			for i in 6:
				var crate2 := ItemFactory.make_prop("crate")
				var side := 1 if i % 2 == 0 else -1
				crate2.position = Vector3(rng.randf_range(10.0, 14.0) * side, 0, rng.randf_range(-12.0, 12.0))
				crate2.scale = Vector3.ONE * rng.randf_range(1.2, 2.2)
				root.add_child(crate2)
		"truck":
			_truck_bed(root)
	_scatter_hay_tufts(root, rng, td)


static func _tree(pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var t := Node3D.new()
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.18
	tm.bottom_radius = 0.28
	tm.height = 2.2
	trunk.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.4, 0.28, 0.16)
	trunk.material_override = tmat
	trunk.position.y = 1.1
	t.add_child(trunk)
	var crown := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = rng.randf_range(1.1, 1.7)
	cm.height = cm.radius * 2.0
	cm.radial_segments = 10
	cm.rings = 6
	crown.mesh = cm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.25, 0.45, 0.18).lerp(Color(0.4, 0.55, 0.2), rng.randf())
	crown.material_override = cmat
	crown.position.y = 2.8
	t.add_child(crown)
	t.position = pos
	return t


static func _fence_ring(root: Node3D, radius: float, posts: int, _rng: RandomNumberGenerator) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.38, 0.22)
	for i in posts:
		var a := TAU * float(i) / float(posts)
		var post := MeshInstance3D.new()
		var pmesh := BoxMesh.new()
		pmesh.size = Vector3(0.12, 1.0, 0.12)
		post.mesh = pmesh
		post.material_override = mat
		post.position = Vector3(cos(a) * radius, 0.5, sin(a) * radius)
		root.add_child(post)
		var rail := MeshInstance3D.new()
		var rmesh := BoxMesh.new()
		var seg := TAU * radius / float(posts)
		rmesh.size = Vector3(seg * 1.05, 0.08, 0.06)
		rail.mesh = rmesh
		rail.material_override = mat
		var mid_a := a + TAU / float(posts) * 0.5
		rail.position = Vector3(cos(mid_a) * radius, 0.75, sin(mid_a) * radius)
		rail.rotation.y = -mid_a + PI * 0.5
		root.add_child(rail)


static func _barn_silhouette(pos: Vector3, large: bool) -> Node3D:
	var b := Node3D.new()
	var scale_f := 1.6 if large else 1.0
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.55, 0.2, 0.15)
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.3, 0.22, 0.18)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(8, 4, 6) * scale_f
	body.mesh = bm
	body.material_override = wall_mat
	body.position = Vector3(0, 2 * scale_f, 0)
	b.add_child(body)
	var roof := MeshInstance3D.new()
	var rm := PrismMesh.new()
	rm.size = Vector3(8.4, 2.5, 6.4) * scale_f
	roof.mesh = rm
	roof.material_override = roof_mat
	roof.position = Vector3(0, (4.0 + 1.25) * scale_f, 0)
	b.add_child(roof)
	b.position = pos
	if large:
		b.position = Vector3(0, 0, -11)
	return b


static func _walls(root: Node3D, half: float, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	var sides := [
		[Vector3(0, 3, -half), Vector3(half * 2, 6, 0.4)],
		[Vector3(0, 3, half), Vector3(half * 2, 6, 0.4)],
		[Vector3(-half, 3, 0), Vector3(0.4, 6, half * 2)],
		[Vector3(half, 3, 0), Vector3(0.4, 6, half * 2)],
	]
	for s: Array in sides:
		var w := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = s[1]
		w.mesh = wm
		w.material_override = mat
		w.position = s[0]
		root.add_child(w)


static func _truck_bed(root: Node3D) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.35, 0.5)
	var bed_parts := [
		[Vector3(0, 0.4, -8.5), Vector3(14, 0.8, 0.5)],
		[Vector3(0, 0.4, 8.5), Vector3(14, 0.8, 0.5)],
		[Vector3(-7, 0.4, 0), Vector3(0.5, 0.8, 17)],
		[Vector3(7, 0.4, 0), Vector3(0.5, 0.8, 17)],
	]
	for s: Array in bed_parts:
		var w := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = s[1]
		w.mesh = wm
		w.material_override = mat
		w.position = s[0]
		root.add_child(w)
	# cab silhouette
	var cab := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(6, 3, 4)
	cab.mesh = cm
	cab.material_override = mat
	cab.position = Vector3(0, 1.5, -11.5)
	root.add_child(cab)


static func _scatter_hay_tufts(root: Node3D, rng: RandomNumberGenerator, _td: Dictionary) -> void:
	# small decorative hay tufts around the scene
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var strand := BoxMesh.new()
	strand.size = Vector3(0.03, 0.03, 0.4)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.65, 0.3)
	mat.roughness = 1.0
	strand.material = mat
	mm.mesh = strand
	mm.instance_count = 120
	for i in 120:
		var a := rng.randf_range(0.0, TAU)
		var d := rng.randf_range(7.5, 13.0)
		var t := Transform3D(Basis.from_euler(Vector3(0, rng.randf_range(0, TAU), rng.randf_range(-0.1, 0.1))),
			Vector3(cos(a) * d, 0.03, sin(a) * d))
		mm.set_instance_transform(i, t)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
