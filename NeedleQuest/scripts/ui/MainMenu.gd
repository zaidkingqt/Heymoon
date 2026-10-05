extends Control
## Main menu screen.

var main: Node


func get_screen_id() -> String:
	return "menu"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UIH.C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# decorative background art if present
	if ResourceLoader.exists("res://art/menu_bg.jpg"):
		var tex := TextureRect.new()
		tex.texture = load("res://art/menu_bg.jpg")
		tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERING
		tex.modulate = Color(1, 1, 1, 0.55)
		add_child(tex)
		var grad := ColorRect.new()
		grad.color = Color(0.05, 0.06, 0.04, 0.45)
		grad.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(grad)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)
	var v := UIH.vbox(14)
	margin.add_child(v)

	# top row: coins + player level
	var top := UIH.hbox(10)
	v.add_child(top)
	var chip := UIH.panel(UIH.C_PANEL, 30)
	chip.add_child(UIH.coin_chip())
	top.add_child(chip)
	top.add_child(UIH.spacer(0, true))
	var lvl_chip := UIH.panel(UIH.C_PANEL, 30)
	lvl_chip.add_child(UIH.label("⭐ %d   |   🧑 %s %d" % [G.total_stars(), Loc.t("pf_level"), G.player_level()], 24, UIH.C_TEXT_DIM))
	top.add_child(lvl_chip)

	v.add_child(UIH.spacer(30))

	# title
	var title := UIH.label(Loc.t("app_name"), 64, UIH.C_ACCENT, true)
	v.add_child(title)
	var sub := UIH.label(Loc.t("tagline"), 26, UIH.C_TEXT_DIM)
	v.add_child(sub)

	# animated needle emblem
	var emblem := UIH.label("🌾🪡🌾", 54)
	v.add_child(emblem)
	var tw := emblem.create_tween().set_loops()
	tw.tween_property(emblem, "modulate:a", 0.55, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(emblem, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)

	v.add_child(UIH.spacer(26))

	# main play button
	var play := UIH.button(Loc.t("play") + "  ›", UIH.C_ACCENT, 40)
	play.custom_minimum_size = Vector2(0, 100)
	play.pressed.connect(func() -> void: main.show_screen("levels"))
	v.add_child(play)

	var daily := UIH.button("🎯  " + Loc.t("daily"), UIH.C_BLUE, 30, Color.WHITE)
	daily.pressed.connect(func() -> void: main.show_screen("daily"))
	v.add_child(daily)

	# grid of secondary buttons
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	v.add_child(grid)
	_menu_btn(grid, "🛒  " + Loc.t("shop"), "shop")
	_menu_btn(grid, "⬆️  " + Loc.t("upgrades"), "upgrades")
	_menu_btn(grid, "📖  " + Loc.t("collection"), "collection")
	_menu_btn(grid, "🏆  " + Loc.t("achievements"), "achievements")
	_menu_btn(grid, "👤  " + Loc.t("profile"), "profile")
	_menu_btn(grid, "⚙️  " + Loc.t("settings"), "settings")

	v.add_child(UIH.spacer(0, false))

	# entrance animation
	modulate.a = 0.0
	var tw2 := create_tween()
	tw2.tween_property(self, "modulate:a", 1.0, 0.3)


func _menu_btn(grid: GridContainer, text: String, screen: String) -> void:
	var b := UIH.small_button(text, UIH.C_PANEL2, UIH.C_TEXT)
	b.custom_minimum_size = Vector2(305, 76)
	b.pressed.connect(func() -> void: main.show_screen(screen))
	grid.add_child(b)
