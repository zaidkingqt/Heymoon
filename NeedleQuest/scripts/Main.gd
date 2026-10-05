extends Node
## Root screen router. Owns the UI layer and swaps screens.

const SCREENS := {
	"menu": "res://scripts/ui/MainMenu.gd",
	"levels": "res://scripts/ui/LevelSelect.gd",
	"shop": "res://scripts/ui/Shop.gd",
	"upgrades": "res://scripts/ui/Upgrades.gd",
	"collection": "res://scripts/ui/CollectionScreen.gd",
	"achievements": "res://scripts/ui/AchievementsScreen.gd",
	"profile": "res://scripts/ui/ProfileScreen.gd",
	"settings": "res://scripts/ui/SettingsScreen.gd",
	"daily": "res://scripts/ui/DailyScreen.gd",
}

var ui_root: Control
var current_screen: Node
var gameplay: Node


func _ready() -> void:
	ui_root = Control.new()
	ui_root.name = "UIRoot"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.theme = UIH.make_theme()
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	canvas.add_child(ui_root)
	Loc.language_changed.connect(_on_language_changed)
	G.achievement_unlocked.connect(_on_achievement)
	show_screen("menu")
	Snd.play_music("music_menu")


func _on_language_changed() -> void:
	UIH.apply_rtl(ui_root)
	# Rebuild current screen so texts refresh instantly.
	if is_instance_valid(current_screen) and current_screen.has_method("get_screen_id"):
		var id: String = current_screen.get_screen_id()
		show_screen(id)


func _on_achievement(id: String) -> void:
	Snd.play("star", -2.0)
	UIH.toast(ui_root, "🏆 " + Loc.t("ach_unlocked") + " " + Loc.t("ach_" + id), 2.6, UIH.C_ACCENT_DARK)


func show_screen(id: String) -> void:
	if is_instance_valid(current_screen):
		current_screen.queue_free()
		current_screen = null
	UIH.apply_rtl(ui_root)
	var script_res: GDScript = load(SCREENS[id])
	var screen: Control = script_res.new()
	screen.set("main", self)
	ui_root.add_child(screen)
	current_screen = screen


func start_level(level_idx: int, daily: bool = false) -> void:
	if is_instance_valid(current_screen):
		current_screen.queue_free()
		current_screen = null
	G.pending_level = level_idx
	G.pending_daily = daily
	var gp_script: GDScript = load("res://scripts/game/Gameplay.gd")
	gameplay = gp_script.new()
	gameplay.set("main", self)
	add_child(gameplay)
	Snd.play_music("music_game")


func end_gameplay(next: String = "menu") -> void:
	if is_instance_valid(gameplay):
		gameplay.queue_free()
		gameplay = null
	Snd.play_music("music_menu")
	show_screen(next)


func restart_level() -> void:
	var lvl: int = G.pending_level
	var daily: bool = G.pending_daily
	if is_instance_valid(gameplay):
		gameplay.queue_free()
		gameplay = null
	# Defer so the old gameplay frees cleanly first.
	call_deferred("start_level", lvl, daily)


func next_level() -> void:
	var lvl: int = G.pending_level + 1
	if is_instance_valid(gameplay):
		gameplay.queue_free()
		gameplay = null
	call_deferred("start_level", lvl, false)
