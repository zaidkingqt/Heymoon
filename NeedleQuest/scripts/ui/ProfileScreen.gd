extends Control
## Player profile & statistics.

var main: Node


func get_screen_id() -> String:
	return "profile"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var page := UIH.page(Loc.t("profile"), func() -> void: main.show_screen("menu"))
	add_child(page["root"])
	var body: VBoxContainer = page["body"]

	var name_panel := UIH.panel(UIH.C_PANEL2, 20)
	body.add_child(name_panel)
	var nh := UIH.hbox(14)
	name_panel.add_child(nh)
	var pname: String = SaveGame.data["player_name"]
	if pname == "":
		pname = Loc.t("pf_name")
	nh.add_child(UIH.label("👤", 44))
	var name_l := UIH.label(pname, 32, UIH.C_ACCENT, true)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nh.add_child(name_l)
	var rename := UIH.small_button("✏ " + Loc.t("rename"))
	rename.pressed.connect(_rename_dialog)
	nh.add_child(rename)

	var list := UIH.vbox(10)
	body.add_child(UIH.scroll(list))
	var completion := 0.0
	if G.ITEMS.size() > 0:
		completion = 100.0 * float(G.collection_discovered()) / float(G.ITEMS.size())
	var best := G.stat("best_time")
	var best_text := UIH.format_time(best) if best > 0.0 else "—"
	_stat_row(list, "🧑", Loc.t("pf_level"), str(G.player_level()))
	_stat_row(list, "🪡", Loc.t("pf_needles"), str(int(G.stat("needles"))))
	_stat_row(list, "🗺", Loc.t("pf_levels"), str(maxi(G.max_level() - 1, 0)))
	_stat_row(list, "⏱", Loc.t("pf_best"), best_text)
	_stat_row(list, "📦", Loc.t("pf_items"), str(int(G.stat("items_collected"))))
	_stat_row(list, "📖", Loc.t("pf_completion"), "%.0f%%" % completion)
	_stat_row(list, "⭐", Loc.t("pf_stars"), str(G.total_stars()))
	_stat_row(list, "💎", Loc.t("pf_rare"), str(int(G.stat("rare_items"))))
	_stat_row(list, "🌾", Loc.t("pf_removed"), str(int(G.stat("clumps_removed"))))
	_stat_row(list, "🏆", Loc.t("achievements"), "%d / %d" % [SaveGame.data["achievements"].size(), G.ACHIEVEMENTS.size()])


func _stat_row(parent: Node, icon: String, key: String, value: String) -> void:
	var p := UIH.panel(UIH.C_PANEL, 14)
	var h := UIH.hbox(14)
	p.add_child(h)
	h.add_child(UIH.label(icon, 28))
	var k := UIH.label(key, 26, UIH.C_TEXT_DIM)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(k)
	h.add_child(UIH.label(value, 26, UIH.C_TEXT, true))
	parent.add_child(p)


func _rename_dialog() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.z_index = 300
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var p := UIH.panel(UIH.C_PANEL2, 24)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(540, 0)
	dim.add_child(p)
	var v := UIH.vbox(16)
	p.add_child(v)
	v.add_child(UIH.label(Loc.t("enter_name"), 28, UIH.C_ACCENT, true))
	var edit := LineEdit.new()
	edit.text = SaveGame.data["player_name"]
	edit.max_length = 16
	edit.add_theme_font_size_override("font_size", 28)
	edit.custom_minimum_size = Vector2(0, 64)
	v.add_child(edit)
	var okb := UIH.button(Loc.t("ok"))
	okb.pressed.connect(func() -> void:
		SaveGame.data["player_name"] = edit.text.strip_edges()
		SaveGame.mark_dirty()
		dim.queue_free()
		main.show_screen("profile")
	)
	v.add_child(okb)
	UIH.center_panel(p)
