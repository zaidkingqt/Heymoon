class_name LevelGen
## Procedural level generator. Seeded + validated:
## guarantees the needle is reachable, inside bounds, covered by at
## least MIN_COVER clumps and never exposed at level start.

const MIN_COVER := 2

const DIFF_TABLE := [
	# [max_level_idx, name, radius, layers, items, decoys, props, secret_chance]
	[1,   "tutorial",   3.0, 3, 3,  0, 0, 0.0],
	[5,   "easy",       3.8, 4, 4,  1, 0, 0.0],
	[12,  "normal",     4.6, 5, 6,  2, 1, 0.15],
	[22,  "hard",       5.4, 5, 8,  3, 2, 0.2],
	[35,  "expert",     6.2, 6, 10, 4, 3, 0.25],
	[50,  "extreme",    7.0, 6, 12, 5, 3, 0.3],
	[9999, "impossible", 7.8, 7, 14, 6, 4, 0.35],
]


static func generate(level: int, seed_val: int, is_daily: bool = false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var row: Array = DIFF_TABLE[DIFF_TABLE.size() - 1]
	for r: Array in DIFF_TABLE:
		if level <= int(r[0]):
			row = r
			break
	if is_daily:
		row = DIFF_TABLE[3]  # daily is always "hard" flavored

	var diff_name: String = row[1]
	var radius: float = row[2] + rng.randf_range(-0.3, 0.3)
	var max_layers: int = row[3]
	var n_items: int = row[4] + rng.randi_range(0, 2)
	var n_decoys: int = row[5]
	var n_props: int = row[6]
	var secret_chance: float = row[7]

	# ---- heightmap: elliptical hay mound with noise
	var noise := FastNoiseLite.new()
	noise.seed = seed_val
	noise.frequency = 0.35
	var rx := radius * rng.randf_range(0.9, 1.15)
	var rz := radius * rng.randf_range(0.8, 1.05)
	var cells: Dictionary = {}
	var ri := int(ceil(maxf(rx, rz)))
	for x in range(-ri, ri + 1):
		for z in range(-ri, ri + 1):
			var d := sqrt(pow(x / rx, 2.0) + pow(z / rz, 2.0))
			if d > 1.0:
				continue
			var base := (1.0 - d * d) * float(max_layers)
			var n := noise.get_noise_2d(float(x), float(z)) * 1.6
			var h := int(round(base + n))
			h = clampi(h, 1, max_layers)
			cells[Vector2i(x, z)] = h

	# ---- theme rotation (daily rotates by date)
	var theme_idx: int = ((level - 1) / 5) % G.THEMES.size()
	if is_daily:
		theme_idx = seed_val % G.THEMES.size()
	var theme: String = G.THEMES[theme_idx]

	# ---- needle placement with validation
	var needle_cell := Vector2i.ZERO
	var needle_layer := 0
	var placed := false
	var keys: Array = cells.keys()
	for attempt in 200:
		var c: Vector2i = keys[rng.randi_range(0, keys.size() - 1)]
		var h: int = cells[c]
		# must be well inside the pile and deep enough
		var d := sqrt(pow(c.x / rx, 2.0) + pow(c.y / rz, 2.0))
		if d > 0.75:
			continue
		if h < MIN_COVER + 1:
			continue
		needle_cell = c
		needle_layer = rng.randi_range(0, h - MIN_COVER - 1)
		placed = true
		break
	if not placed:
		# Impossible-state prevention: force a valid column.
		needle_cell = Vector2i.ZERO
		cells[needle_cell] = max_layers
		needle_layer = 0

	# ---- hidden items
	var items: Array = []
	var used_cells: Dictionary = {needle_cell: true}
	for i in n_items:
		var c2 := _rand_cell(rng, keys, used_cells, cells, 1)
		if c2 == Vector2i(999, 999):
			break
		var id := _pick_weighted_item(rng)
		items.append({"id": id, "cell": c2, "layer": rng.randi_range(0, cells[c2] - 1)})
		used_cells[c2] = true

	# ---- decoy needle-like nails (some placed near the real needle)
	for i in n_decoys:
		var c3: Vector2i
		if i % 2 == 0:
			c3 = _rand_cell_near(rng, cells, needle_cell, 2, used_cells)
		else:
			c3 = _rand_cell(rng, keys, used_cells, cells, 1)
		if c3 == Vector2i(999, 999):
			continue
		items.append({"id": "nail", "cell": c3, "layer": rng.randi_range(0, maxi(cells[c3] - 2, 0))})
		used_cells[c3] = true

	# ---- rare bonus needles
	if rng.randf() < 0.08 + float(level) * 0.001:
		var c4 := _rand_cell(rng, keys, used_cells, cells, 2)
		if c4 != Vector2i(999, 999):
			items.append({"id": "golden_needle", "cell": c4, "layer": 0})
			used_cells[c4] = true
	if rng.randf() < 0.015:
		var c5 := _rand_cell(rng, keys, used_cells, cells, 2)
		if c5 != Vector2i(999, 999):
			items.append({"id": "legendary_needle", "cell": c5, "layer": 0})
			used_cells[c5] = true

	# ---- movable props (crates & barrels) resting on the pile
	var props: Array = []
	for i in n_props:
		var c6 := _rand_cell(rng, keys, {}, cells, 1)
		if c6 == Vector2i(999, 999):
			continue
		var dup := false
		for pr: Dictionary in props:
			if pr["cell"] == c6:
				dup = true
		if dup:
			continue
		props.append({"kind": "crate" if rng.randf() < 0.6 else "barrel", "cell": c6})

	# ---- secret stash cells
	var secrets: Array = []
	if rng.randf() < secret_chance:
		var c7 := _rand_cell(rng, keys, used_cells, cells, 2)
		if c7 != Vector2i(999, 999):
			secrets.append(c7)

	# ---- pacing targets
	var total_clumps := 0
	for k: Vector2i in cells.keys():
		total_clumps += int(cells[k])
	var target_time := 20.0 + float(total_clumps) * 0.32
	var time_limit := 0.0
	if not is_daily and level >= 15 and level % 10 == 5:
		time_limit = target_time * 2.2

	return {
		"seed": seed_val,
		"level": level,
		"daily": is_daily,
		"theme": theme,
		"difficulty": diff_name,
		"cells": cells,
		"max_layers": max_layers,
		"radius": maxf(rx, rz),
		"needle_cell": needle_cell,
		"needle_layer": needle_layer,
		"items": items,
		"props": props,
		"secrets": secrets,
		"target_time": target_time,
		"time_limit": time_limit,
		"total_clumps": total_clumps,
	}


static func _pick_weighted_item(rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for id: String in G.ITEMS.keys():
		total += float(G.ITEMS[id]["weight"])
	var roll := rng.randf() * total
	for id: String in G.ITEMS.keys():
		roll -= float(G.ITEMS[id]["weight"])
		if roll <= 0.0:
			return id
	return "coin"


static func _rand_cell(rng: RandomNumberGenerator, keys: Array, used: Dictionary, cells: Dictionary, min_h: int) -> Vector2i:
	for attempt in 60:
		var c: Vector2i = keys[rng.randi_range(0, keys.size() - 1)]
		if used.has(c):
			continue
		if int(cells[c]) < min_h:
			continue
		return c
	return Vector2i(999, 999)


static func _rand_cell_near(rng: RandomNumberGenerator, cells: Dictionary, center: Vector2i, max_dist: int, used: Dictionary) -> Vector2i:
	for attempt in 40:
		var off := Vector2i(rng.randi_range(-max_dist, max_dist), rng.randi_range(-max_dist, max_dist))
		var c := center + off
		if c == center or used.has(c) or not cells.has(c):
			continue
		return c
	return Vector2i(999, 999)
