extends Node
## Gameplay orchestrator: builds the 3D world + HUD, runs the search
## loop, tools, hints, scoring, tutorial, pause/victory/timeout.

enum State { PLAYING, PAUSED, VICTORY, TIMEOUT }

var main: Node

var world: Node3D
var rig: Node3D
var hay: Node3D
var level_data: Dictionary

var hud: Control
var toast_layer: Control
var top_bar: Control
var tools_panel: Control
var time_label: Label
var removed_label: Label
var level_label: Label
var countdown_label: Label
var hint_btn: Button
var warmth_bar: ProgressBar
var warmth_panel: Control

var state: int = State.PLAYING
var play_time: float = 0.0
var removed_count: int = 0
var hints_used: int = 0
var hint_level: int = 0
var items_gained: Array[String] = []
var coins_from_items: int = 0

var selected_tool: String = "hand"
var modal_open: bool = false
var magnet_armed: bool = false
var magnifier_on: bool = false
var detector_left: float = 0.0
var _near_cooldown: float = 0.0
var _hint_ring: MeshInstance3D
var _extra_time_used: bool = false
var _tool_buttons: Dictionary = {}

# tutorial
var tut_step: int = -1
var tut_label: Label
var tut_panel: Control
var _tut_counter: int = 0
var _tut_timer: float = 0.0


func _ready() -> void:
	var level: int = G.pending_level
	var is_daily: bool = G.pending_daily
	var seed_val: int
	if is_daily:
		seed_val = G.daily_seed()
		level = 10 + (G.daily_seed() % 7)
	else:
		seed_val = randi()
	level_data = LevelGen.generate(level, seed_val, is_daily)

	# ---------- 3D world
	world = Node3D.new()
	add_child(world)
	var env_rng := RandomNumberGenerator.new()
	env_rng.seed = seed_val
	EnvBuilder.build(world, level_data["theme"], env_rng)

	var hay_script: GDScript = load("res://scripts/game/HayField.gd")
	hay = hay_script.new()
	world.add_child(hay)
	hay.call("setup", level_data)
	hay.connect("clump_removed", _on_clump_removed)
	hay.connect("item_collected", _on_item_collected)
	hay.connect("needle_tapped", _on_needle_tapped)
	hay.connect("secret_opened", _on_secret_opened)
	hay.connect("prop_primed", func() -> void: _toast(Loc.t("move_obstacle")))
	hay.connect("prop_moved", func() -> void: Snd.vibrate(25))
	hay.connect("blocked_by_prop", func() -> void: _toast(Loc.t("move_obstacle")))

	var rig_script: GDScript = load("res://scripts/game/CameraRig.gd")
	rig = rig_script.new()
	world.add_child(rig)
	rig.call("setup", float(level_data["radius"]) * 0.7)
	rig.connect("tapped", _on_tap)
	rig.connect("orbited", func() -> void: _tut_event("orbit"))
	rig.connect("zoomed", func() -> void: _tut_event("zoom"))

	G.refill_all_tools_for_level()
	_build_hud()

	if bool(level_data["time_limit"] > 0.0):
		_toast(Loc.t("timed_level"), 2.6)

	if not bool(SaveGame.data["tutorial_done"]) and level <= 1 and not is_daily:
		_start_tutorial()

	G.track("level_start", {"level": level, "daily": is_daily})


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	play_time += delta
	_near_cooldown = maxf(_near_cooldown - delta, 0.0)
	if detector_left > 0.0:
		detector_left -= delta
		if detector_left <= 0.0:
			warmth_panel.visible = false
	time_label.text = "⏱ " + UIH.format_time(play_time)
	var limit: float = level_data["time_limit"]
	if limit > 0.0:
		var left := maxf(limit - play_time, 0.0)
		countdown_label.text = "⏳ " + UIH.format_time(left)
		countdown_label.add_theme_color_override("font_color", UIH.C_RED if left < 20.0 else UIH.C_TEXT)
		if left <= 0.0:
			_on_time_up()
	if tut_step >= 0:
		_tut_timer += delta
		if (tut_step == 4 or tut_step == 5) and _tut_timer > 4.0:
			_tut_advance()


func _unhandled_input(event: InputEvent) -> void:
	if state == State.PLAYING and not modal_open:
		rig.call("handle_input", event)

# =================================================================== HUD

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.theme = UIH.make_theme()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud)
	UIH.apply_rtl(hud)

	# ------- top bar
	top_bar = UIH.panel(Color(0.08, 0.09, 0.07, 0.85), 0)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.add_child(top_bar)
	var tv := UIH.vbox(2)
	top_bar.add_child(tv)
	var row1 := UIH.hbox(10)
	tv.add_child(row1)
	var pause_btn := UIH.small_button("⏸", UIH.C_PANEL2)
	pause_btn.custom_minimum_size = Vector2(72, 56)
	pause_btn.pressed.connect(_pause)
	row1.add_child(pause_btn)
	var lv_text: String
	if bool(level_data["daily"]):
		lv_text = "🎯 " + Loc.t("daily_title")
	else:
		lv_text = Loc.tf("level_n", [int(level_data["level"])]) + " · " + Loc.t("diff_" + str(level_data["difficulty"]))
	level_label = UIH.label(lv_text, 24, UIH.C_ACCENT, true)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(level_label)
	row1.add_child(UIH.coin_chip())
	var row2 := UIH.hbox(18)
	tv.add_child(row2)
	time_label = UIH.label("⏱ 00:00", 22, UIH.C_TEXT_DIM)
	row2.add_child(time_label)
	removed_label = UIH.label("🌾 0", 22, UIH.C_TEXT_DIM)
	row2.add_child(removed_label)
	countdown_label = UIH.label("", 22, UIH.C_TEXT)
	row2.add_child(countdown_label)
	row2.add_child(UIH.spacer(0, true))
	var theme_label := UIH.label(Loc.t("theme_" + str(level_data["theme"])), 20, UIH.C_TEXT_DIM)
	row2.add_child(theme_label)

	# ------- warmth (detector) bar
	warmth_panel = UIH.panel(Color(0.08, 0.09, 0.07, 0.8), 14)
	warmth_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	warmth_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	warmth_panel.offset_top = 130
	warmth_panel.visible = false
	hud.add_child(warmth_panel)
	var wh := UIH.hbox(8)
	warmth_panel.add_child(wh)
	wh.add_child(UIH.label("📡", 24))
	warmth_bar = ProgressBar.new()
	warmth_bar.min_value = 0
	warmth_bar.max_value = 100
	warmth_bar.value = 0
	warmth_bar.show_percentage = false
	warmth_bar.custom_minimum_size = Vector2(300, 22)
	wh.add_child(warmth_bar)

	# ------- bottom: tools + hint
	tools_panel = UIH.panel(Color(0.08, 0.09, 0.07, 0.88), 24)
	tools_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tools_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hud.add_child(tools_panel)
	var bv := UIH.vbox(8)
	tools_panel.add_child(bv)
	var hint_row := UIH.hbox(10)
	bv.add_child(hint_row)
	hint_row.add_child(UIH.spacer(0, true))
	hint_btn = UIH.small_button("💡 " + Loc.t("hint") + "  🪙 " + str(_hint_cost()), UIH.C_BLUE, Color.WHITE)
	hint_btn.pressed.connect(_use_hint)
	hint_row.add_child(hint_btn)
	hint_row.add_child(UIH.spacer(0, true))
	var tools_row := UIH.hbox(8)
	tools_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bv.add_child(tools_row)
	var ids: Array = G.TOOLS.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(G.TOOLS[a]["order"]) < int(G.TOOLS[b]["order"]))
	for id: String in ids:
		var b := _make_tool_button(id)
		_tool_buttons[id] = b
		tools_row.add_child(b)
	G.tools_changed.connect(_refresh_tool_buttons)
	_refresh_tool_buttons()

	# toast layer
	toast_layer = Control.new()
	toast_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(toast_layer)


func _make_tool_button(id: String) -> Button:
	var b := Button.new()
	UIH.ensure_fonts()
	b.add_theme_font_override("font", UIH.font_bold)
	b.add_theme_font_size_override("font_size", 30)
	b.custom_minimum_size = Vector2(88, 88)
	b.pressed.connect(func() -> void: _select_tool(id))
	return b


func _refresh_tool_buttons() -> void:
	for id: String in _tool_buttons.keys():
		var b: Button = _tool_buttons[id]
		var db: Dictionary = G.TOOLS[id]
		var unlocked := G.tool_unlocked(id)
		var selected := selected_tool == id or (id == "magnifier" and magnifier_on)
		var icon: String = db["icon"]
		if not unlocked:
			b.text = "🔒"
			b.add_theme_stylebox_override("normal", UIH.style_box(Color(0.12, 0.12, 0.1, 0.9), 18))
			b.add_theme_stylebox_override("pressed", UIH.style_box(Color(0.12, 0.12, 0.1, 0.9), 18))
			b.add_theme_stylebox_override("hover", UIH.style_box(Color(0.12, 0.12, 0.1, 0.9), 18))
		else:
			var uses := G.tool_uses(id)
			var badge := "" if uses < 0 else "\n" + str(uses)
			b.text = icon + badge
			var col := UIH.C_ACCENT if selected else UIH.C_PANEL2
			b.add_theme_stylebox_override("normal", UIH.style_box(col, 18))
			b.add_theme_stylebox_override("hover", UIH.style_box(col, 18))
			b.add_theme_stylebox_override("pressed", UIH.style_box(col.darkened(0.2), 18))
			b.add_theme_color_override("font_color", Color(0.1, 0.09, 0.03) if selected else UIH.C_TEXT)


func _select_tool(id: String) -> void:
	if not G.tool_unlocked(id):
		var lvl := int(G.TOOLS[id]["unlock_level"])
		if G.max_level() < lvl:
			_toast(Loc.tf("unlock_at", [lvl]))
		else:
			_toast(Loc.t("shop") + " → " + Loc.t("tool_" + id))
		Snd.play("error", -6.0)
		return
	Snd.play("click", -6.0)
	_tut_event("tool")
	match id:
		"magnifier":
			magnifier_on = not magnifier_on
			rig.call("set_magnify", magnifier_on)
		"detector":
			_activate_detector()
		"magnet":
			magnet_armed = true
			selected_tool = "magnet"
			_toast(Loc.t("tool_magnet_d"))
		_:
			selected_tool = id
			magnet_armed = false
	_refresh_tool_buttons()


func _activate_detector() -> void:
	if detector_left > 0.0:
		return
	if not G.consume_tool_use("detector"):
		_offer_ad_use("detector")
		return
	detector_left = 12.0 + 3.0 * float(G.upgrade_level("search"))
	warmth_panel.visible = true
	Snd.play("hint")
	_update_warmth(Vector3.ZERO)


func _offer_ad_use(id: String) -> void:
	Snd.play("error", -6.0)
	modal_open = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(dim)
	dim.tree_exited.connect(func() -> void: modal_open = false)
	var p := UIH.panel(UIH.C_PANEL2, 22)
	p.set_anchors_preset(Control.PRESET_CENTER)
	UIH.center_panel(p)
	p.custom_minimum_size = Vector2(500, 0)
	dim.add_child(p)
	var v := UIH.vbox(14)
	p.add_child(v)
	v.add_child(UIH.label(Loc.t("no_uses"), 26))
	var ad := UIH.button("📺 " + Loc.t("free_use_ad"), UIH.C_GREEN, 26, Color.WHITE)
	ad.pressed.connect(func() -> void:
		dim.queue_free()
		Ads.show_rewarded(func(ok: bool) -> void:
			if ok:
				G.grant_tool_use(id)
				Snd.play("buy")
		)
	)
	v.add_child(ad)
	var c := UIH.small_button(Loc.t("cancel"))
	c.pressed.connect(dim.queue_free)
	v.add_child(c)

# =================================================================== input / taps

func _hud_blocks(pos: Vector2) -> bool:
	if top_bar and top_bar.get_global_rect().has_point(pos):
		return true
	if tools_panel and tools_panel.get_global_rect().has_point(pos):
		return true
	return false


func _on_tap(pos: Vector2) -> void:
	if state != State.PLAYING or _hud_blocks(pos):
		return
	var o: Vector3 = rig.call("ray_origin", pos)
	var d: Vector3 = rig.call("ray_dir", pos)
	var hit: Dictionary = hay.call("pick", o, d)
	if hit.is_empty():
		return
	match str(hit["type"]):
		"needle":
			hay.emit_signal("needle_tapped")
		"item":
			hay.call("collect_item", hit["item"])
		"chest":
			hay.call("open_chest", hit["cell"])
		"prop":
			hay.call("tap_prop", hit["prop"])
		"clump":
			_apply_tool(hit)


func _apply_tool(hit: Dictionary) -> void:
	var cell: Vector2i = hit["cell"]
	var pos: Vector3 = hit["pos"]
	if magnet_armed:
		if G.consume_tool_use("magnet"):
			magnet_armed = false
			selected_tool = "hand"
			var radius := 1.6 + 0.35 * float(G.upgrade_level("magnet_power")) + 0.2 * float(G.tool_level("magnet"))
			var found: int = hay.call("magnet_scan", pos, radius)
			Snd.play("magnet")
			if found == 0:
				_toast(Loc.t("magnet_nothing"))
			_refresh_tool_buttons()
		else:
			magnet_armed = false
			selected_tool = "hand"
			_offer_ad_use("magnet")
		return
	match selected_tool:
		"hand":
			if bool(hay.call("remove_top", cell)):
				Snd.rustle()
				# combo chance from removal speed upgrade
				if randf() < 0.1 * float(G.upgrade_level("remove_speed")):
					var neighbors := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
					hay.call("remove_top", cell + neighbors[randi() % 4])
		"broom":
			if G.consume_tool_use("broom"):
				var r := 1.1 + 0.25 * float(G.upgrade_level("broom_power")) + 0.15 * float(G.tool_level("broom"))
				var n: int = hay.call("broom_sweep", pos, r)
				if n > 0:
					Snd.play("sweep")
				selected_tool = "hand"
				_refresh_tool_buttons()
			else:
				selected_tool = "hand"
				_offer_ad_use("broom")
		"fan":
			if G.consume_tool_use("fan"):
				var r2 := 2.0 + 0.4 * float(G.upgrade_level("tool_power"))
				hay.call("fan_blow", pos, r2)
				Snd.play("fan")
				selected_tool = "hand"
				_refresh_tool_buttons()
			else:
				selected_tool = "hand"
				_offer_ad_use("fan")
		"digger":
			if G.consume_tool_use("digger"):
				var rc := 1 if G.upgrade_level("tool_power") >= 3 else 0
				hay.call("dig_column", cell, rc)
				Snd.play("dig")
				Snd.vibrate(40)
				selected_tool = "hand"
				_refresh_tool_buttons()
			else:
				selected_tool = "hand"
				_offer_ad_use("digger")

# =================================================================== events

func _on_clump_removed(total: int, pos: Vector3) -> void:
	removed_count = total
	removed_label.text = "🌾 " + str(total)
	G.add_stat("clumps_removed", 1)
	_tut_event("removed")
	# near-needle feedback
	var npos: Vector3 = hay.call("needle_world")
	var dist := Vector2(pos.x, pos.z).distance_to(Vector2(npos.x, npos.z))
	if _near_cooldown <= 0.0:
		if dist < 0.9:
			FX.shimmer(world, pos + Vector3(0, 0.3, 0), true)
			Snd.play("near", -2.0, 1.3)
			Snd.vibrate(15)
			_near_cooldown = 0.6
		elif dist < 1.8:
			Snd.play("near", -8.0, 1.0)
			_near_cooldown = 0.6
	if detector_left > 0.0:
		_update_warmth(pos)


func _update_warmth(from_pos: Vector3) -> void:
	var npos: Vector3 = hay.call("needle_world")
	var dist := Vector2(from_pos.x, from_pos.z).distance_to(Vector2(npos.x, npos.z))
	var max_d: float = float(level_data["radius"]) * 0.55 + 2.0
	var warmth := clampf(1.0 - dist / max_d, 0.0, 1.0) * 100.0
	var tw := create_tween()
	tw.tween_property(warmth_bar, "value", warmth, 0.3)


func _on_item_collected(id: String, value: int, _pos: Vector3) -> void:
	G.collect_item(id)
	G.add_coins(value)
	coins_from_items += value
	items_gained.append(id)
	match id:
		"golden_needle":
			G.add_stat("golden_needles", 1)
			_toast("🪡✨ " + Loc.t("golden_bonus"), 2.4)
			Snd.play("victory", -4.0)
		"legendary_needle":
			G.add_stat("legendary_needles", 1)
			_toast("💜 " + Loc.t("legendary_bonus"), 3.0)
			Snd.play("victory")
		"gem":
			Snd.play("gem")
		"coin":
			Snd.play("coin")
		_:
			Snd.play("item")
	G.check_achievements()


func _on_secret_opened() -> void:
	G.add_stat("secrets_found", 1)
	var bonus := 40 + int(level_data["level"]) * 2
	G.add_coins(bonus)
	var rare_pool := ["photo", "watch", "ring", "artifact", "treasure"]
	var rare: String = rare_pool[randi() % rare_pool.size()]
	G.collect_item(rare)
	items_gained.append(rare)
	_toast("🎁 " + Loc.t("secret_found") + "  +🪙" + str(bonus) + "  +" + Loc.t("item_" + rare), 3.0)
	G.check_achievements()

# =================================================================== hints

func _hint_cost() -> int:
	var base := [25, 50, 100]
	var idx := clampi(hint_level, 0, 2)
	var discount := 1.0 - 0.06 * float(G.upgrade_level("hint_acc"))
	return int(float(base[idx]) * discount)


func _use_hint() -> void:
	if state != State.PLAYING or hint_level >= 3:
		return
	var cost := _hint_cost()
	if not G.spend_coins(cost):
		# offer free hint through rewarded ad
		Ads.show_rewarded(func(ok: bool) -> void:
			if ok:
				_grant_hint()
		)
		return
	_grant_hint()


func _grant_hint() -> void:
	hint_level += 1
	hints_used += 1
	Snd.play("hint")
	_tut_event("hint")
	var npos: Vector3 = hay.call("needle_world")
	match hint_level:
		1:
			var dir_key := _direction_key(npos)
			_toast("💡 " + Loc.tf("hint_dir", [Loc.t(dir_key)]), 3.2)
		2:
			var acc := 1.0 - 0.07 * float(G.upgrade_level("hint_acc"))
			_show_ring(npos, maxf(float(level_data["radius"]) * 0.28, 1.4) * acc, 0.45)
			_toast("💡 " + Loc.t("hint_zone"), 2.6)
		3:
			var acc2 := 1.0 - 0.07 * float(G.upgrade_level("hint_acc"))
			_show_ring(npos, 0.95 * acc2, 0.3)
			_toast("💡 " + Loc.t("hint_small"), 2.6)
	if hint_level >= 3:
		hint_btn.disabled = true
		hint_btn.text = "💡 —"
	else:
		hint_btn.text = "💡 " + Loc.t("hint") + "  🪙 " + str(_hint_cost())


func _direction_key(npos: Vector3) -> String:
	var v := Vector2(npos.x, npos.z)
	if v.length() < float(level_data["radius"]) * 0.2:
		return "dir_c"
	var ang := rad_to_deg(atan2(-v.y, v.x))  # +z is "south"
	if ang < 0.0:
		ang += 360.0
	var octant := int(round(ang / 45.0)) % 8
	return ["dir_e", "dir_ne", "dir_n", "dir_nw", "dir_w", "dir_sw", "dir_s", "dir_se"][octant]


func _show_ring(npos: Vector3, radius: float, max_offset: float) -> void:
	if is_instance_valid(_hint_ring):
		_hint_ring.queue_free()
	var rng_local := RandomNumberGenerator.new()
	var ang := rng_local.randf_range(0.0, TAU)
	var off := Vector3(cos(ang), 0, sin(ang)) * rng_local.randf_range(0.0, max_offset * radius)
	_hint_ring = FX.make_hint_ring(radius, Color(0.4, 0.8, 1.0, 0.8))
	world.add_child(_hint_ring)
	_hint_ring.position = Vector3(npos.x, 0.08, npos.z) + off
	var tw := _hint_ring.create_tween().set_loops()
	tw.tween_property(_hint_ring, "scale", Vector3(1.12, 1.0, 1.12), 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_hint_ring, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_SINE)

# =================================================================== victory

func _on_needle_tapped() -> void:
	if state != State.PLAYING:
		return
	state = State.VICTORY
	rig.call("set_locked", true)
	G.add_stat("play_seconds", play_time)
	Snd.play("needle_found")
	Snd.vibrate(80)
	var npos: Vector3 = hay.call("needle_world")
	rig.call("focus_on", npos, 2.4, 1.1)
	# needle celebration: rise + spin + light
	var nnode: Node3D = hay.get("needle_rec")["node"]
	var tw := nnode.create_tween()
	tw.set_parallel(true)
	tw.tween_property(nnode, "position:y", nnode.position.y + 1.1, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(nnode, "rotation_degrees:y", nnode.rotation_degrees.y + 360.0, 1.2)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.7)
	light.light_energy = 0.0
	light.omni_range = 5.0
	world.add_child(light)
	light.global_position = npos + Vector3(0, 1.0, 0)
	var ltw := light.create_tween()
	ltw.tween_property(light, "light_energy", 2.5, 0.5)
	FX.confetti(world, npos + Vector3(0, 1.5, 0))
	# hide gameplay chrome
	tools_panel.visible = false
	hint_btn.visible = false
	warmth_panel.visible = false
	var t := get_tree().create_timer(1.7)
	t.timeout.connect(_show_victory_panel)


func _calc_stars() -> int:
	var target: float = level_data["target_time"]
	if play_time <= target and hints_used == 0:
		return 3
	if play_time <= target * 1.8 and hints_used <= 1:
		return 2
	return 1


func _show_victory_panel() -> void:
	Snd.play("victory")
	var level: int = level_data["level"]
	var is_daily: bool = level_data["daily"]
	var stars := _calc_stars()
	var reward := 20 + level * 2 + stars * 10
	if is_daily:
		reward += 50
	G.add_coins(reward)
	G.add_xp(10 * stars + 5)
	G.add_stat("needles", 1)
	if hints_used == 0:
		G.trigger_special("no_hint")
	if play_time < 30.0:
		G.trigger_special("speed")
	var new_record := false
	if is_daily:
		new_record = G.record_daily(play_time)
	else:
		new_record = G.save_level_result(G.pending_level, stars, play_time)
	G.check_achievements()
	SaveGame.flush()
	G.track("level_done", {"level": level, "time": play_time, "stars": stars})

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(dim)
	var dtw := dim.create_tween()
	dtw.tween_property(dim, "color:a", 0.55, 0.4)

	var p := UIH.panel(UIH.C_PANEL2, 28)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(600, 0)
	dim.add_child(p)
	var v := UIH.vbox(12)
	p.add_child(v)
	v.add_child(UIH.label("🪡 " + Loc.t("victory"), 44, UIH.C_ACCENT, true))
	if new_record:
		v.add_child(UIH.label("🏅 " + Loc.t("new_record"), 26, UIH.C_GREEN, true))

	# animated stars
	var stars_row := UIH.hbox(10)
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(stars_row)
	for i in 3:
		var sl := UIH.label("★" if i < stars else "☆", 56, UIH.C_ACCENT if i < stars else UIH.C_TEXT_DIM)
		sl.modulate.a = 0.0
		stars_row.add_child(sl)
		var stw := sl.create_tween()
		stw.tween_interval(0.25 * float(i) + 0.2)
		stw.tween_callback(func() -> void:
			if i < stars:
				Snd.play("star", -4.0, 1.0 + 0.15 * float(i))
		)
		stw.tween_property(sl, "modulate:a", 1.0, 0.25)

	v.add_child(_stat_line("⏱", Loc.t("time"), UIH.format_time(play_time)))
	v.add_child(_stat_line("🌾", Loc.t("removed"), str(removed_count)))
	v.add_child(_stat_line("💡", Loc.t("hints_used"), str(hints_used)))
	v.add_child(_stat_line("🪙", Loc.t("reward"), "+" + str(reward + coins_from_items)))
	if not items_gained.is_empty():
		var names: Array[String] = []
		for id in items_gained:
			names.append(Loc.t("item_" + id))
		var il := UIH.label("📦 " + ", ".join(names), 20, UIH.C_TEXT_DIM)
		il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(il)

	var btns := UIH.vbox(10)
	v.add_child(btns)
	if not is_daily:
		var next := UIH.button(Loc.t("next_level") + " ›", UIH.C_GREEN, 30, Color.WHITE)
		next.pressed.connect(func() -> void: main.next_level())
		btns.add_child(next)
	var row := UIH.hbox(10)
	btns.add_child(row)
	var replay := UIH.button("↻ " + Loc.t("replay"), UIH.C_BLUE, 26, Color.WHITE)
	replay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay.pressed.connect(func() -> void: main.restart_level())
	row.add_child(replay)
	var home := UIH.button("⌂ " + Loc.t("home"), UIH.C_PANEL, 26, UIH.C_TEXT)
	home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.pressed.connect(func() -> void: main.end_gameplay("menu"))
	row.add_child(home)
	UIH.center_panel(p)
	p.scale = Vector2(0.8, 0.8)
	p.resized.connect(func() -> void: p.pivot_offset = p.size * 0.5)
	var ptw := p.create_tween()
	ptw.tween_property(p, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _stat_line(icon: String, key: String, value: String) -> Control:
	var h := UIH.hbox(10)
	h.add_child(UIH.label(icon, 24))
	var k := UIH.label(key, 24, UIH.C_TEXT_DIM)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(k)
	h.add_child(UIH.label(value, 24, UIH.C_TEXT, true))
	return h

# =================================================================== timeout

func _on_time_up() -> void:
	if state != State.PLAYING:
		return
	state = State.TIMEOUT
	rig.call("set_locked", true)
	Snd.play("timeup")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(dim)
	var p := UIH.panel(UIH.C_PANEL2, 28)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(560, 0)
	dim.add_child(p)
	var v := UIH.vbox(14)
	p.add_child(v)
	v.add_child(UIH.label("⏳ " + Loc.t("times_up"), 40, UIH.C_RED, true))
	v.add_child(UIH.label(Loc.t("times_up_sub"), 24, UIH.C_TEXT_DIM))
	var retry := UIH.button("↻ " + Loc.t("retry"), UIH.C_ACCENT, 28)
	retry.pressed.connect(func() -> void: main.restart_level())
	v.add_child(retry)
	if not _extra_time_used:
		var extra := UIH.button("📺 " + Loc.t("extra_time"), UIH.C_GREEN, 26, Color.WHITE)
		extra.pressed.connect(func() -> void:
			Ads.show_rewarded(func(ok: bool) -> void:
				if ok:
					_extra_time_used = true
					level_data["time_limit"] = float(level_data["time_limit"]) + 30.0
					state = State.PLAYING
					rig.call("set_locked", false)
					dim.queue_free()
			)
		)
		v.add_child(extra)
	var home := UIH.button("⌂ " + Loc.t("home"), UIH.C_PANEL, 26, UIH.C_TEXT)
	home.pressed.connect(func() -> void: main.end_gameplay("menu"))
	v.add_child(home)
	UIH.center_panel(p)

# =================================================================== pause

func _pause() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	rig.call("set_locked", true)
	Snd.play("click", -6.0)
	var dim := ColorRect.new()
	dim.name = "PauseDim"
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(dim)
	var p := UIH.panel(UIH.C_PANEL2, 28)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(540, 0)
	dim.add_child(p)
	var v := UIH.vbox(14)
	p.add_child(v)
	v.add_child(UIH.label("⏸ " + Loc.t("paused"), 38, UIH.C_ACCENT, true))
	var resume := UIH.button("▶ " + Loc.t("resume"), UIH.C_GREEN, 28, Color.WHITE)
	resume.pressed.connect(func() -> void:
		dim.queue_free()
		state = State.PLAYING
		rig.call("set_locked", false)
	)
	v.add_child(resume)
	var restart := UIH.button("↻ " + Loc.t("restart"), UIH.C_BLUE, 28, Color.WHITE)
	restart.pressed.connect(func() -> void: main.restart_level())
	v.add_child(restart)
	var home := UIH.button("⌂ " + Loc.t("home"), UIH.C_PANEL, 28, UIH.C_TEXT)
	home.pressed.connect(func() -> void: main.end_gameplay("menu"))
	v.add_child(home)
	UIH.center_panel(p)

# =================================================================== tutorial

func _start_tutorial() -> void:
	tut_step = 0
	_tut_counter = 0
	_tut_timer = 0.0
	tut_panel = UIH.panel(Color(0.1, 0.12, 0.2, 0.95), 18)
	tut_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hud.add_child(tut_panel)
	var h := UIH.hbox(12)
	tut_panel.add_child(h)
	tut_label = UIH.label(Loc.t("tut_1"), 24, Color.WHITE, true)
	tut_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tut_label.custom_minimum_size = Vector2(440, 0)
	h.add_child(tut_label)
	var skip := UIH.small_button(Loc.t("tut_skip"))
	skip.pressed.connect(_tut_finish)
	h.add_child(skip)
	tut_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tut_panel.offset_top = 140


func _tut_event(kind: String) -> void:
	if tut_step < 0:
		return
	match tut_step:
		0:
			if kind == "orbit":
				_tut_counter += 1
				if _tut_counter > 6:
					_tut_advance()
		1:
			if kind == "zoom":
				_tut_counter += 1
				if _tut_counter > 2:
					_tut_advance()
		2:
			if kind == "removed":
				_tut_advance()
		3:
			if kind == "removed" and removed_count >= 10:
				_tut_advance()
		4:
			if kind == "tool":
				_tut_advance()
		5:
			if kind == "hint":
				_tut_advance()


func _tut_advance() -> void:
	tut_step += 1
	_tut_counter = 0
	_tut_timer = 0.0
	Snd.play("pop", -8.0)
	if tut_step >= 6:
		_tut_finish()
		return
	var keys := ["tut_1", "tut_2", "tut_3", "tut_4", "tut_5", "tut_6"]
	tut_label.text = Loc.t(keys[tut_step])


func _tut_finish() -> void:
	tut_step = -1
	if is_instance_valid(tut_panel):
		tut_panel.queue_free()
	SaveGame.data["tutorial_done"] = true
	SaveGame.mark_dirty()

# =================================================================== misc

func _toast(text: String, duration: float = 2.0) -> void:
	if is_instance_valid(toast_layer):
		UIH.toast(toast_layer, text, duration)
