extends Control
## Shop: tools (unlock/refill), hay skins, particle effect styles.
## Everything is earnable with in-game coins (no pay-to-win).

var main: Node
var tab_idx: int = 0
var body: VBoxContainer
var content: VBoxContainer
var _tab_buttons: Array[Button] = []


func get_screen_id() -> String:
	return "shop"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var page := UIH.page(Loc.t("shop"), func() -> void: main.show_screen("menu"))
	add_child(page["root"])
	body = page["body"]

	var chip := UIH.panel(UIH.C_PANEL, 30)
	chip.add_child(UIH.coin_chip())
	body.add_child(chip)

	var tabs := UIH.hbox(10)
	body.add_child(tabs)
	var tab_names := [Loc.t("shop_tools"), Loc.t("shop_skins"), Loc.t("shop_extras")]
	for i in 3:
		var b := UIH.small_button(tab_names[i], UIH.C_PANEL2, UIH.C_TEXT)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured := i
		b.pressed.connect(func() -> void:
			tab_idx = captured
			_style_tabs()
			_refresh_tab()
		)
		tabs.add_child(b)
		_tab_buttons.append(b)
	_style_tabs()

	content = UIH.vbox(12)
	var sc := UIH.scroll(content)
	body.add_child(sc)
	_fill_tab()


func _style_tabs() -> void:
	for i in _tab_buttons.size():
		var b := _tab_buttons[i]
		var active := i == tab_idx
		var col := UIH.C_ACCENT if active else UIH.C_PANEL2
		b.add_theme_stylebox_override("normal", UIH.style_box(col, 22))
		b.add_theme_stylebox_override("hover", UIH.style_box(col, 22))
		b.add_theme_stylebox_override("pressed", UIH.style_box(col.darkened(0.2), 22))
		b.add_theme_color_override("font_color", Color(0.1, 0.09, 0.03) if active else UIH.C_TEXT)
		b.add_theme_color_override("font_pressed_color", Color(0.1, 0.09, 0.03) if active else UIH.C_TEXT)
		b.add_theme_color_override("font_hover_color", Color(0.1, 0.09, 0.03) if active else UIH.C_TEXT)


func _refresh_tab() -> void:
	for c in content.get_children():
		c.queue_free()
	_fill_tab()


func _fill_tab() -> void:
	match tab_idx:
		0: _fill_tools()
		1: _fill_skins()
		2: _fill_fx()


func _fill_tools() -> void:
	var ids: Array = G.TOOLS.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(G.TOOLS[a]["order"]) < int(G.TOOLS[b]["order"]))
	for id: String in ids:
		if id == "hand":
			continue
		content.add_child(_tool_card(id))


func _tool_card(id: String) -> Control:
	var db: Dictionary = G.TOOLS[id]
	var p := UIH.panel(UIH.C_PANEL, 18)
	var h := UIH.hbox(16)
	p.add_child(h)
	var icon := UIH.label(str(db["icon"]), 44)
	icon.custom_minimum_size = Vector2(70, 70)
	h.add_child(icon)
	var v := UIH.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(_left_label(Loc.t("tool_" + id), 28, UIH.C_TEXT, true))
	var desc := _left_label(Loc.t("tool_" + id + "_d"), 22, UIH.C_TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)

	var unlocked := G.tool_unlocked(id)
	var reachable := G.max_level() >= int(db["unlock_level"])
	if not unlocked:
		if not reachable:
			var lockl := _left_label("🔒 " + Loc.tf("unlock_at", [int(db["unlock_level"])]), 22, UIH.C_RED)
			v.add_child(lockl)
		else:
			var buy := UIH.small_button("%s  🪙 %d" % [Loc.t("unlock"), int(db["price"])], UIH.C_ACCENT, Color(0.1, 0.09, 0.03))
			buy.pressed.connect(func() -> void:
				if G.unlock_tool(id):
					Snd.play("buy")
					_refresh_tab()
				else:
					Snd.play("error", -4.0)
					UIH.toast(self, Loc.t("not_enough"))
			)
			h.add_child(buy)
	else:
		var uses := G.tool_uses(id)
		var mx := G.tool_max_uses(id)
		var uses_text := Loc.t("unlimited") if mx < 0 else "%d / %d" % [uses, mx]
		v.add_child(_left_label("%s: %s   |   %s %d" % [Loc.t("uses"), uses_text, Loc.t("tool_level"), G.tool_level(id)], 22, UIH.C_GREEN))
		if mx > 0 and uses < mx:
			var refill := UIH.small_button("%s 🪙 %d" % [Loc.t("refill"), int(db["refill"])], UIH.C_BLUE, Color.WHITE)
			refill.pressed.connect(func() -> void:
				if G.refill_tool(id):
					Snd.play("buy")
					_refresh_tab()
				else:
					Snd.play("error", -4.0)
					UIH.toast(self, Loc.t("not_enough"))
			)
			h.add_child(refill)
	return p


func _fill_skins() -> void:
	for id: String in G.SKINS.keys():
		content.add_child(_cosmetic_card(id, "skin_" + id, int(G.SKINS[id]["price"]), "owned_skins", "skin", G.SKINS[id]["base"]))


func _fill_fx() -> void:
	for id: String in G.FX_STYLES.keys():
		content.add_child(_cosmetic_card(id, "fx_" + id, int(G.FX_STYLES[id]["price"]), "owned_fx", "fx", UIH.C_BLUE))


func _cosmetic_card(id: String, loc_key: String, price: int, owned_key: String, equip_key: String, swatch: Color) -> Control:
	var p := UIH.panel(UIH.C_PANEL, 18)
	var h := UIH.hbox(16)
	p.add_child(h)
	var sw := ColorRect.new()
	sw.color = swatch
	sw.custom_minimum_size = Vector2(56, 56)
	h.add_child(sw)
	var name_l := _left_label(Loc.t(loc_key), 26, UIH.C_TEXT, true)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name_l)
	var owned: bool = id in SaveGame.data[owned_key]
	var equipped: bool = SaveGame.data[equip_key] == id
	if equipped:
		h.add_child(UIH.label("✔ " + Loc.t("equipped"), 24, UIH.C_GREEN, true))
	elif owned:
		var eq := UIH.small_button(Loc.t("equip"), UIH.C_GREEN, Color.WHITE)
		eq.pressed.connect(func() -> void:
			SaveGame.data[equip_key] = id
			SaveGame.mark_dirty()
			Snd.play("click")
			_refresh_tab()
		)
		h.add_child(eq)
	else:
		var buy := UIH.small_button("%s 🪙 %d" % [Loc.t("buy"), price], UIH.C_ACCENT, Color(0.1, 0.09, 0.03))
		buy.pressed.connect(func() -> void:
			if G.spend_coins(price):
				SaveGame.data[owned_key].append(id)
				SaveGame.data[equip_key] = id
				SaveGame.mark_dirty()
				Snd.play("buy")
				_refresh_tab()
			else:
				Snd.play("error", -4.0)
				UIH.toast(self, Loc.t("not_enough"))
		)
		h.add_child(buy)
	return p


func _left_label(text: String, size: int, color: Color, bold: bool = false) -> Label:
	var l := UIH.label(text, size, color, bold)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l
