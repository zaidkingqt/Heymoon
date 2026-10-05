extends Control
## Upgrade tree screen - each upgrade has a real gameplay effect.

var main: Node
var content: VBoxContainer


func get_screen_id() -> String:
	return "upgrades"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var page := UIH.page(Loc.t("upgrades"), func() -> void: main.show_screen("menu"))
	add_child(page["root"])
	var body: VBoxContainer = page["body"]
	var chip := UIH.panel(UIH.C_PANEL, 30)
	chip.add_child(UIH.coin_chip())
	body.add_child(chip)
	content = UIH.vbox(12)
	body.add_child(UIH.scroll(content))
	_refresh()


func _refresh() -> void:
	for c in content.get_children():
		c.queue_free()
	var ids: Array = G.UPGRADES.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(G.UPGRADES[a]["order"]) < int(G.UPGRADES[b]["order"]))
	for id: String in ids:
		content.add_child(_upgrade_card(id))


func _upgrade_card(id: String) -> Control:
	var p := UIH.panel(UIH.C_PANEL, 18)
	var h := UIH.hbox(16)
	p.add_child(h)
	var v := UIH.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var name_l := UIH.label(Loc.t("up_" + id), 28, UIH.C_TEXT, true)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(name_l)
	var desc := UIH.label(Loc.t("up_" + id + "_d"), 22, UIH.C_TEXT_DIM)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)
	var lv := G.upgrade_level(id)
	var mx := int(G.UPGRADES[id]["max"])
	var pips := ""
	for i in mx:
		pips += "●" if i < lv else "○"
	var pips_l := UIH.label(pips, 26, UIH.C_ACCENT)
	pips_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(pips_l)
	if lv >= mx:
		h.add_child(UIH.label(Loc.t("max_level"), 26, UIH.C_GREEN, true))
	else:
		var cost := G.upgrade_cost(id)
		var b := UIH.small_button("%s\n🪙 %d" % [Loc.t("upgrade"), cost], UIH.C_ACCENT, Color(0.1, 0.09, 0.03))
		b.custom_minimum_size = Vector2(150, 80)
		b.pressed.connect(func() -> void:
			if G.buy_upgrade(id):
				Snd.play("upgrade")
				_refresh()
			else:
				Snd.play("error", -4.0)
				UIH.toast(self, Loc.t("not_enough"))
		)
		h.add_child(b)
	return p
