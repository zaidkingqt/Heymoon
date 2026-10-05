extends Control
## Settings: audio, language, vibration, graphics quality, FPS,
## notifications, reset, privacy, credits.

var main: Node


func get_screen_id() -> String:
	return "settings"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var page := UIH.page(Loc.t("settings"), func() -> void: main.show_screen("menu"))
	add_child(page["root"])
	var body: VBoxContainer = page["body"]
	var list := UIH.vbox(14)
	body.add_child(UIH.scroll(list))
	var s := G.settings()

	# --- music volume
	list.add_child(_slider_row("🎵 " + Loc.t("music"), s.get("music", 0.8), func(v: float) -> void:
		G.set_setting("music", v)
		Snd.set_music_volume(v)
	))
	# --- sfx volume
	list.add_child(_slider_row("🔊 " + Loc.t("sound_fx"), s.get("sfx", 1.0), func(v: float) -> void:
		G.set_setting("sfx", v)
		Snd.set_sfx_volume(v)
	))

	# --- language
	var lang_row := _row("🌐 " + Loc.t("language"))
	var lang_btn := UIH.small_button("العربية" if Loc.lang == "ar" else "English", UIH.C_ACCENT, Color(0.1, 0.09, 0.03))
	lang_btn.custom_minimum_size = Vector2(190, 56)
	lang_btn.pressed.connect(func() -> void:
		var new_lang := "en" if Loc.lang == "ar" else "ar"
		G.set_setting("lang", new_lang)
		Loc.set_lang(new_lang)
	)
	lang_row.add_child(lang_btn)
	list.add_child(lang_row.get_parent())

	# --- vibration
	list.add_child(_toggle_row("📳 " + Loc.t("vibration"), bool(s.get("vibration", true)), func(v: bool) -> void:
		G.set_setting("vibration", v)
		if v:
			Snd.vibrate(40)
	))

	# --- graphics quality
	var q_row := _row("🖥 " + Loc.t("graphics"))
	var qualities := ["low", "medium", "high", "ultra"]
	var q_keys := ["q_low", "q_medium", "q_high", "q_ultra"]
	var q_idx: int = maxi(qualities.find(s.get("graphics", "high")), 0)
	var q_btn := UIH.small_button(Loc.t(q_keys[q_idx]), UIH.C_BLUE, Color.WHITE)
	q_btn.custom_minimum_size = Vector2(190, 56)
	q_btn.pressed.connect(func() -> void:
		var cur: int = maxi(qualities.find(G.settings().get("graphics", "high")), 0)
		cur = (cur + 1) % 4
		G.set_setting("graphics", qualities[cur])
		G.apply_graphics_viewport()
		q_btn.text = Loc.t(q_keys[cur])
	)
	q_row.add_child(q_btn)
	list.add_child(q_row.get_parent())

	# --- fps
	var fps_row := _row("⚡ " + Loc.t("fps_limit"))
	var fps_btn := UIH.small_button(str(int(s.get("fps", 60))), UIH.C_BLUE, Color.WHITE)
	fps_btn.custom_minimum_size = Vector2(190, 56)
	fps_btn.pressed.connect(func() -> void:
		var cur := int(G.settings().get("fps", 60))
		var new_fps := 30 if cur == 60 else 60
		G.set_setting("fps", new_fps)
		Engine.max_fps = new_fps
		fps_btn.text = str(new_fps)
	)
	fps_row.add_child(fps_btn)
	list.add_child(fps_row.get_parent())

	# --- notifications
	list.add_child(_toggle_row("🔔 " + Loc.t("notifications"), bool(s.get("notifications", true)), func(v: bool) -> void:
		G.set_setting("notifications", v)
	))

	# --- privacy / credits / reset
	var privacy := UIH.small_button("🔒 " + Loc.t("privacy"))
	privacy.pressed.connect(func() -> void:
		UIH.info_dialog(self, Loc.t("privacy"), Loc.t("privacy_text"))
	)
	list.add_child(privacy)
	var credits := UIH.small_button("🎬 " + Loc.t("credits"))
	credits.pressed.connect(func() -> void:
		UIH.info_dialog(self, Loc.t("credits"), Loc.t("credits_text"))
	)
	list.add_child(credits)
	var reset := UIH.small_button("⚠️ " + Loc.t("reset_progress"), Color(0.45, 0.15, 0.12), Color.WHITE)
	reset.pressed.connect(func() -> void:
		UIH.confirm_dialog(self, Loc.t("reset_confirm"), func() -> void:
			SaveGame.reset_all()
			G._init_tools()
			var s2 := G.settings()
			Loc.lang = s2.get("lang", "ar")
			main.show_screen("menu")
		)
	)
	list.add_child(reset)


func _row(text: String) -> HBoxContainer:
	var p := UIH.panel(UIH.C_PANEL, 16)
	var h := UIH.hbox(14)
	p.add_child(h)
	var l := UIH.label(text, 26)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return h


func _slider_row(text: String, value: float, on_change: Callable) -> Control:
	var h := _row(text)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(240, 48)
	slider.value_changed.connect(on_change)
	h.add_child(slider)
	return h.get_parent()


func _toggle_row(text: String, value: bool, on_change: Callable) -> Control:
	var h := _row(text)
	var check := CheckButton.new()
	check.button_pressed = value
	check.toggled.connect(on_change)
	h.add_child(check)
	return h.get_parent()
