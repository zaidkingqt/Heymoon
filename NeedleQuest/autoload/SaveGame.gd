extends Node
## Modular local save system (JSON on disk).
## Designed so the backend can later be swapped for cloud saves:
## everything goes through read_all()/write_all().

const SAVE_PATH := "user://needle_quest_save.json"
const SAVE_VERSION := 1

var data: Dictionary = {}
var _dirty: bool = false
var _save_timer: float = 0.0


func _ready() -> void:
	load_from_disk()


func _process(delta: float) -> void:
	# Debounced autosave: writes at most twice per second.
	if _dirty:
		_save_timer += delta
		if _save_timer >= 0.5:
			flush()


func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"coins": 100,
		"player_name": "",
		"xp": 0,
		"max_level": 1,
		"levels": {},            # "1": {stars:int, best_time:float}
		"tools": {},             # id: {unlocked:bool, level:int, uses:int}
		"upgrades": {},          # id: level
		"collection": {},        # item_id: count
		"achievements": [],      # unlocked ids
		"stats": {
			"needles": 0, "clumps_removed": 0, "items_collected": 0,
			"golden_needles": 0, "legendary_needles": 0, "secrets_found": 0,
			"best_time": 0.0, "play_seconds": 0.0, "rare_items": 0,
		},
		"daily": {"last_date": "", "streak": 0, "total": 0, "bests": {}},
		"skin": "classic",
		"fx": "classic",
		"owned_skins": ["classic"],
		"owned_fx": ["classic"],
		"tutorial_done": false,
		"settings": {
			"music": 0.8, "sfx": 1.0, "lang": "ar", "vibration": true,
			"graphics": "high", "fps": 60, "notifications": true,
		},
	}


func load_from_disk() -> void:
	data = default_data()
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var txt := f.get_as_text()
			f.close()
			var parsed: Variant = JSON.parse_string(txt)
			if parsed is Dictionary:
				_merge_into(data, parsed)


func _merge_into(base: Dictionary, incoming: Dictionary) -> void:
	for k: Variant in incoming.keys():
		if base.has(k) and base[k] is Dictionary and incoming[k] is Dictionary:
			_merge_into(base[k], incoming[k])
		else:
			base[k] = incoming[k]


func mark_dirty() -> void:
	_dirty = true


func flush() -> void:
	_dirty = false
	_save_timer = 0.0
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()


func reset_all() -> void:
	data = default_data()
	flush()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		flush()
