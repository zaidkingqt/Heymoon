extends Control
## Daily Challenge screen - one special seeded level per day,
## identical for every player (seed derived from the date).

var main: Node


func get_screen_id() -> String:
	return "daily"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var page := UIH.page(Loc.t("daily_title"), func() -> void: main.show_screen("menu"))
	add_child(page["root"])
	var body: VBoxContainer = page["body"]

	var sub := UIH.label(Loc.t("daily_sub"), 24, UIH.C_TEXT_DIM)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(sub)
	body.add_child(UIH.spacer(8))

	var date_p := UIH.panel(UIH.C_PANEL2, 20)
	body.add_child(date_p)
	var dv := UIH.vbox(6)
	date_p.add_child(dv)
	dv.add_child(UIH.label("📅 " + G.today_string(), 36, UIH.C_ACCENT, true))

	var best := G.daily_best_today()
	if best > 0.0:
		dv.add_child(UIH.label("✅ " + Loc.t("daily_done"), 26, UIH.C_GREEN, true))
		dv.add_child(UIH.label(Loc.t("today_best") + ": " + UIH.format_time(best), 26))
	else:
		dv.add_child(UIH.label(Loc.t("not_played"), 24, UIH.C_TEXT_DIM))

	var daily: Dictionary = SaveGame.data["daily"]
	var stats := UIH.hbox(14)
	body.add_child(stats)
	stats.add_child(_stat_box("🔥", Loc.t("streak"), str(int(daily["streak"]))))
	stats.add_child(_stat_box("🏁", Loc.t("total_dailies"), str(int(daily["total"]))))

	body.add_child(UIH.spacer(10))
	var play := UIH.button("🎯 " + Loc.t("play_daily"), UIH.C_BLUE, 30, Color.WHITE)
	play.custom_minimum_size = Vector2(0, 96)
	play.pressed.connect(func() -> void:
		main.start_level(0, true)
	)
	body.add_child(play)

	# last 7 days history
	var hist := UIH.vbox(8)
	body.add_child(UIH.scroll(hist))
	var bests: Dictionary = daily["bests"]
	var keys: Array = bests.keys()
	keys.sort()
	keys.reverse()
	for i in mini(keys.size(), 7):
		var k: String = keys[i]
		var p := UIH.panel(UIH.C_PANEL, 14)
		var h := UIH.hbox(12)
		p.add_child(h)
		var dl := UIH.label(k, 24, UIH.C_TEXT_DIM)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(dl)
		h.add_child(UIH.label("⏱ " + UIH.format_time(float(bests[k])), 24, UIH.C_TEXT))
		hist.add_child(p)


func _stat_box(icon: String, key: String, value: String) -> Control:
	var p := UIH.panel(UIH.C_PANEL, 16)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UIH.vbox(2)
	p.add_child(v)
	v.add_child(UIH.label(icon + " " + value, 32, UIH.C_ACCENT, true))
	v.add_child(UIH.label(key, 20, UIH.C_TEXT_DIM))
	return p
