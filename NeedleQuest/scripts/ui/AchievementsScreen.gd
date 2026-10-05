extends Control
## Achievements list with live progress bars.

var main: Node


func get_screen_id() -> String:
	return "achievements"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var page := UIH.page(Loc.t("achievements"), func() -> void: main.show_screen("menu"))
	add_child(page["root"])
	var body: VBoxContainer = page["body"]
	var list := UIH.vbox(12)
	body.add_child(UIH.scroll(list))
	for a: Dictionary in G.ACHIEVEMENTS:
		list.add_child(_ach_card(a))


func _ach_card(a: Dictionary) -> Control:
	var id: String = a["id"]
	var done := G.achievement_done(id)
	var p := UIH.panel(UIH.C_PANEL2 if done else UIH.C_PANEL, 18)
	var h := UIH.hbox(16)
	p.add_child(h)
	var icon := UIH.label("🏆" if done else "🔒", 40)
	icon.custom_minimum_size = Vector2(60, 60)
	h.add_child(icon)
	var v := UIH.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var title := UIH.label(Loc.t("ach_" + id), 26, UIH.C_ACCENT if done else UIH.C_TEXT, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(title)
	var desc := UIH.label(Loc.t("ach_" + id + "_d"), 22, UIH.C_TEXT_DIM)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)
	var prog := G.achievement_progress(a)
	if not done and prog.y > 1:
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = prog.y
		bar.value = prog.x
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 10)
		v.add_child(bar)
		v.add_child(UIH.label("%d / %d" % [prog.x, prog.y], 18, UIH.C_TEXT_DIM))
	var reward := UIH.label("🪙 %d" % int(a["reward"]), 22, UIH.C_ACCENT, true)
	h.add_child(reward)
	return p
