class_name UIH
## Static UI factory helpers - consistent modern mobile look.

const C_BG := Color(0.09, 0.1, 0.08)
const C_PANEL := Color(0.14, 0.15, 0.12, 0.96)
const C_PANEL2 := Color(0.19, 0.2, 0.16, 0.98)
const C_ACCENT := Color(0.98, 0.75, 0.22)
const C_ACCENT_DARK := Color(0.72, 0.5, 0.1)
const C_GREEN := Color(0.4, 0.78, 0.35)
const C_RED := Color(0.9, 0.35, 0.3)
const C_BLUE := Color(0.35, 0.6, 0.95)
const C_TEXT := Color(0.96, 0.95, 0.9)
const C_TEXT_DIM := Color(0.75, 0.74, 0.68)

static var font_regular: FontFile
static var font_bold: FontFile
static var font_emoji: FontFile


static func ensure_fonts() -> void:
	if font_regular == null:
		font_regular = load("res://fonts/Cairo-Regular.ttf")
		font_bold = load("res://fonts/Cairo-Bold.ttf")
		font_emoji = load("res://fonts/NotoEmoji.ttf")
		font_regular.fallbacks = [font_emoji]
		font_bold.fallbacks = [font_emoji]


static func make_theme() -> Theme:
	ensure_fonts()
	var th := Theme.new()
	th.default_font = font_regular
	th.default_font_size = 28
	return th


static func style_box(color: Color, radius: int = 18, border: Color = Color.TRANSPARENT, border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func label(text: String, size: int = 28, color: Color = C_TEXT, bold: bool = false) -> Label:
	ensure_fonts()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", font_bold)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func button(text: String, color: Color = C_ACCENT, font_size: int = 30, text_color: Color = Color(0.12, 0.1, 0.04)) -> Button:
	ensure_fonts()
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font_bold)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", text_color)
	b.add_theme_color_override("font_pressed_color", text_color)
	b.add_theme_color_override("font_hover_color", text_color)
	b.add_theme_color_override("font_focus_color", text_color)
	var sb := style_box(color, 22)
	var sb_down := style_box(color.darkened(0.25), 22)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb_down)
	b.add_theme_stylebox_override("focus", sb)
	b.custom_minimum_size = Vector2(0, 72)
	b.pressed.connect(func() -> void: Snd.play("click", -6.0))
	return b


static func small_button(text: String, color: Color = C_PANEL2, text_color: Color = C_TEXT) -> Button:
	var b := button(text, color, 24, text_color)
	b.custom_minimum_size = Vector2(0, 56)
	return b


static func panel(color: Color = C_PANEL, radius: int = 20) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style_box(color, radius))
	return p


static func vbox(sep: int = 14) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = 14) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func spacer(size: float = 10.0, horizontal: bool = false) -> Control:
	var c := Control.new()
	if horizontal:
		c.custom_minimum_size = Vector2(size, 0)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.custom_minimum_size = Vector2(0, size)
	return c


static func scroll(inner: Control) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(inner)
	return sc


## Full-screen page scaffold with a header (back button + title) and a body.
## Returns {root, body, title_label}.
static func page(title_text: String, on_back: Callable) -> Dictionary:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	root.add_child(margin)
	var v := vbox(18)
	margin.add_child(v)
	var header := hbox(16)
	v.add_child(header)
	var back := small_button("‹  " + Loc.t("back"))
	back.custom_minimum_size = Vector2(130, 60)
	back.pressed.connect(on_back)
	header.add_child(back)
	var title := label(title_text, 36, C_ACCENT, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var ghost := Control.new()
	ghost.custom_minimum_size = Vector2(130, 10)
	header.add_child(ghost)
	var body := vbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	return {"root": root, "body": body, "title": title}


static func coin_chip() -> HBoxContainer:
	var h := hbox(8)
	var icon := label("🪙", 26)
	h.add_child(icon)
	var amount := label(str(G.coins()), 28, C_ACCENT, true)
	amount.name = "CoinAmount"
	h.add_child(amount)
	var cb := func(c: int) -> void:
		if is_instance_valid(amount):
			amount.text = str(c)
	G.coins_changed.connect(cb)
	amount.tree_exited.connect(func() -> void:
		if G.coins_changed.is_connected(cb):
			G.coins_changed.disconnect(cb)
	)
	return h


static func toast(parent: Node, text: String, duration: float = 2.2, color: Color = C_PANEL2) -> void:
	var p := panel(color, 16)
	p.z_index = 200
	var l := label(text, 26, C_TEXT, true)
	p.add_child(l)
	parent.add_child(p)
	p.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_END
	p.offset_top = 150
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(duration)
	tw.tween_property(p, "modulate:a", 0.0, 0.35)
	tw.tween_callback(p.queue_free)


static func confirm_dialog(parent: Node, text: String, on_yes: Callable) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.z_index = 300
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(dim)
	var p := panel(C_PANEL2, 24)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(540, 0)
	dim.add_child(p)
	var v := vbox(20)
	p.add_child(v)
	var l := label(text, 28)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(500, 0)
	v.add_child(l)
	var h := hbox(16)
	v.add_child(h)
	var yes := button(Loc.t("yes"), C_RED, 26, Color.WHITE)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(func() -> void:
		dim.queue_free()
		on_yes.call()
	)
	h.add_child(yes)
	var no := button(Loc.t("no"), C_PANEL, 26, C_TEXT)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(dim.queue_free)
	h.add_child(no)
	center_panel(p)


static func info_dialog(parent: Node, title_text: String, text: String) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.z_index = 300
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(dim)
	var p := panel(C_PANEL2, 24)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(560, 0)
	dim.add_child(p)
	var v := vbox(18)
	p.add_child(v)
	v.add_child(label(title_text, 32, C_ACCENT, true))
	var l := label(text, 26)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(520, 0)
	v.add_child(l)
	var okb := button(Loc.t("ok"))
	okb.pressed.connect(dim.queue_free)
	v.add_child(okb)
	center_panel(p)


## Makes a PRESET_CENTER panel actually center around the screen middle.
static func center_panel(p: Control) -> void:
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH


static func format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	return "%02d:%02d" % [m, s]


static func apply_rtl(control: Control) -> void:
	control.layout_direction = Control.LAYOUT_DIRECTION_RTL if Loc.is_rtl() else Control.LAYOUT_DIRECTION_LTR
