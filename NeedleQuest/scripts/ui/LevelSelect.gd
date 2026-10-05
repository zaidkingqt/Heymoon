extends Control
## Level selection grid. Levels are procedurally generated & endless;
## the grid always shows a window of levels around the player's progress.

var main: Node


func get_screen_id() -> String:
	return "levels"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var page := UIH.page(Loc.t("select_level"), func() -> void: main.show_screen("menu"))
	add_child(page["root"])
	var body: VBoxContainer = page["body"]

	var shown: int = maxi(G.max_level() + 11, 24)
	shown = mini(shown, 400)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for i in range(1, shown + 1):
		grid.add_child(_level_tile(i))
	var sc := UIH.scroll(grid)
	body.add_child(sc)

	var note := UIH.label(Loc.t("endless_note"), 22, UIH.C_TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(note)


func _level_tile(idx: int) -> Control:
	var unlocked := idx <= G.max_level()
	var rec := G.level_record(idx)
	var stars := int(rec.get("stars", 0))
	var v := UIH.vbox(4)
	var b := Button.new()
	UIH.ensure_fonts()
	b.add_theme_font_override("font", UIH.font_bold)
	b.add_theme_font_size_override("font_size", 30)
	b.custom_minimum_size = Vector2(150, 110)
	if unlocked:
		var done := stars > 0
		var col := UIH.C_GREEN if done else UIH.C_ACCENT
		b.text = str(idx)
		b.add_theme_color_override("font_color", Color(0.1, 0.09, 0.03))
		b.add_theme_stylebox_override("normal", UIH.style_box(col, 18))
		b.add_theme_stylebox_override("hover", UIH.style_box(col, 18))
		b.add_theme_stylebox_override("pressed", UIH.style_box(col.darkened(0.25), 18))
		b.pressed.connect(func() -> void:
			Snd.play("click", -6.0)
			main.start_level(idx)
		)
	else:
		b.text = "🔒"
		b.disabled = true
		b.add_theme_stylebox_override("normal", UIH.style_box(UIH.C_PANEL2, 18))
		b.add_theme_stylebox_override("disabled", UIH.style_box(UIH.C_PANEL2, 18))
	v.add_child(b)
	var star_text := ""
	for s in 3:
		star_text += "★" if s < stars else "☆"
	var sl := UIH.label(star_text, 20, UIH.C_ACCENT if stars > 0 else UIH.C_TEXT_DIM)
	v.add_child(sl)
	return v
