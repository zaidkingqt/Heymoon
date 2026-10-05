extends Node
## Central game state & databases (data-driven).
## Holds: economy, tools, upgrades, items/collection, achievements,
## graphics quality application, daily challenge helpers, profile XP.

signal coins_changed(amount: int)
signal achievement_unlocked(id: String)
signal tools_changed

# ----------------------------------------------------------------- databases

const TOOLS: Dictionary = {
	"hand":      {"order": 0, "unlock_level": 1,  "price": 0,    "base_uses": -1, "refill": 0,   "icon": "✋"},
	"broom":     {"order": 1, "unlock_level": 3,  "price": 150,  "base_uses": 3,  "refill": 30,  "icon": "🧹"},
	"magnifier": {"order": 2, "unlock_level": 5,  "price": 250,  "base_uses": -1, "refill": 0,   "icon": "🔍"},
	"fan":       {"order": 3, "unlock_level": 7,  "price": 400,  "base_uses": 2,  "refill": 45,  "icon": "🌀"},
	"digger":    {"order": 4, "unlock_level": 10, "price": 600,  "base_uses": 2,  "refill": 60,  "icon": "⛏"},
	"magnet":    {"order": 5, "unlock_level": 13, "price": 800,  "base_uses": 2,  "refill": 70,  "icon": "🧲"},
	"detector":  {"order": 6, "unlock_level": 17, "price": 1200, "base_uses": 1,  "refill": 90,  "icon": "📡"},
}

const UPGRADES: Dictionary = {
	"remove_speed": {"order": 0, "max": 5, "base_cost": 100},
	"capacity":     {"order": 1, "max": 5, "base_cost": 150},
	"broom_power":  {"order": 2, "max": 5, "base_cost": 200},
	"magnet_power": {"order": 3, "max": 5, "base_cost": 250},
	"hint_acc":     {"order": 4, "max": 5, "base_cost": 300},
	"search":       {"order": 5, "max": 5, "base_cost": 350},
	"tool_power":   {"order": 6, "max": 5, "base_cost": 400},
}

# rarity: 0 common, 1 uncommon, 2 rare, 3 epic, 4 legendary, 5 mythic
const ITEMS: Dictionary = {
	"coin":             {"rarity": 0, "value": 5,    "weight": 34.0, "metal": true},
	"button":           {"rarity": 0, "value": 3,    "weight": 22.0, "metal": false},
	"bolt":             {"rarity": 0, "value": 4,    "weight": 20.0, "metal": true},
	"gem":              {"rarity": 1, "value": 18,   "weight": 9.0,  "metal": false},
	"key":              {"rarity": 1, "value": 15,   "weight": 8.0,  "metal": true},
	"toy":              {"rarity": 1, "value": 20,   "weight": 7.0,  "metal": false},
	"horseshoe":        {"rarity": 1, "value": 25,   "weight": 6.0,  "metal": true},
	"photo":            {"rarity": 2, "value": 40,   "weight": 3.0,  "metal": false},
	"watch":            {"rarity": 2, "value": 50,   "weight": 2.5,  "metal": true},
	"ring":             {"rarity": 2, "value": 60,   "weight": 2.0,  "metal": true},
	"artifact":         {"rarity": 3, "value": 100,  "weight": 1.0,  "metal": false},
	"treasure":         {"rarity": 3, "value": 150,  "weight": 0.7,  "metal": true},
	"nail":             {"rarity": 0, "value": 2,    "weight": 0.0,  "metal": true},
	"golden_needle":    {"rarity": 4, "value": 300,  "weight": 0.0,  "metal": true},
	"legendary_needle": {"rarity": 5, "value": 1000, "weight": 0.0,  "metal": true},
}

const RARITY_KEYS: Array[String] = [
	"rar_common", "rar_uncommon", "rar_rare", "rar_epic", "rar_legendary", "rar_mythic"
]
const RARITY_COLORS: Array[Color] = [
	Color(0.75, 0.75, 0.75), Color(0.45, 0.85, 0.45), Color(0.4, 0.65, 1.0),
	Color(0.75, 0.45, 1.0), Color(1.0, 0.8, 0.25), Color(1.0, 0.4, 0.3),
]

const SKINS: Dictionary = {
	"classic": {"price": 0,    "base": Color(0.85, 0.68, 0.3),  "tip": Color(0.93, 0.8, 0.45)},
	"golden":  {"price": 500,  "base": Color(0.95, 0.78, 0.2),  "tip": Color(1.0, 0.92, 0.5)},
	"green":   {"price": 400,  "base": Color(0.55, 0.7, 0.3),   "tip": Color(0.7, 0.85, 0.45)},
	"autumn":  {"price": 600,  "base": Color(0.8, 0.5, 0.25),   "tip": Color(0.9, 0.65, 0.3)},
	"silver":  {"price": 800,  "base": Color(0.72, 0.75, 0.8),  "tip": Color(0.88, 0.9, 0.95)},
}

const FX_STYLES: Dictionary = {
	"classic":   {"price": 0},
	"sparkle":   {"price": 350},
	"leaves":    {"price": 450},
	"fireflies": {"price": 700},
}

const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "first_needle", "stat": "needles", "goal": 1, "reward": 50},
	{"id": "needles_10", "stat": "needles", "goal": 10, "reward": 150},
	{"id": "needles_50", "stat": "needles", "goal": 50, "reward": 500},
	{"id": "needles_100", "stat": "needles", "goal": 100, "reward": 1500},
	{"id": "no_hint", "stat": "_special", "goal": 1, "reward": 100},
	{"id": "speed", "stat": "_special", "goal": 1, "reward": 150},
	{"id": "clumps_1000", "stat": "clumps_removed", "goal": 1000, "reward": 200},
	{"id": "clumps_10000", "stat": "clumps_removed", "goal": 10000, "reward": 1000},
	{"id": "golden", "stat": "golden_needles", "goal": 1, "reward": 250},
	{"id": "legendary", "stat": "legendary_needles", "goal": 1, "reward": 800},
	{"id": "collector", "stat": "_collection_half", "goal": 1, "reward": 300},
	{"id": "collector_full", "stat": "_collection_full", "goal": 1, "reward": 1000},
	{"id": "tools_all", "stat": "_tools_all", "goal": 1, "reward": 400},
	{"id": "stars_50", "stat": "_stars", "goal": 50, "reward": 350},
	{"id": "daily_5", "stat": "_daily", "goal": 5, "reward": 300},
	{"id": "level_25", "stat": "_max_level", "goal": 25, "reward": 400},
	{"id": "items_100", "stat": "items_collected", "goal": 100, "reward": 300},
]

const THEMES: Array[String] = [
	"meadow", "farm", "barn", "warehouse", "truck", "night", "factory", "abandoned"
]

# ----------------------------------------------------------------- state

var pending_level: int = 1
var pending_daily: bool = false


func _ready() -> void:
	_init_tools()
	var s: Dictionary = settings()
	Loc.lang = s.get("lang", "ar")
	Snd.set_music_volume(s.get("music", 0.8))
	Snd.set_sfx_volume(s.get("sfx", 1.0))
	Engine.max_fps = int(s.get("fps", 60))
	apply_graphics_viewport()


func _init_tools() -> void:
	var tools: Dictionary = SaveGame.data["tools"]
	for id: String in TOOLS.keys():
		if not tools.has(id):
			tools[id] = {
				"unlocked": id == "hand",
				"level": 1,
				"uses": TOOLS[id]["base_uses"],
			}
	SaveGame.mark_dirty()

# ----------------------------------------------------------------- settings

func settings() -> Dictionary:
	return SaveGame.data["settings"]


func set_setting(key: String, value: Variant) -> void:
	SaveGame.data["settings"][key] = value
	SaveGame.mark_dirty()


func apply_graphics_viewport() -> void:
	var q: String = settings().get("graphics", "high")
	var vp := get_viewport()
	match q:
		"low":
			vp.msaa_3d = Viewport.MSAA_DISABLED
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
		"medium":
			vp.msaa_3d = Viewport.MSAA_2X
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
		"high":
			vp.msaa_3d = Viewport.MSAA_4X
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
		"ultra":
			vp.msaa_3d = Viewport.MSAA_4X
			RenderingServer.directional_shadow_atlas_set_size(4096, true)


func quality_index() -> int:
	return ["low", "medium", "high", "ultra"].find(settings().get("graphics", "high"))


func strands_per_clump() -> int:
	return [7, 10, 13, 16][clampi(quality_index(), 0, 3)]


func particle_scale() -> float:
	return [0.5, 0.75, 1.0, 1.3][clampi(quality_index(), 0, 3)]


func shadows_enabled() -> bool:
	return quality_index() >= 1

# ----------------------------------------------------------------- economy

func coins() -> int:
	return int(SaveGame.data["coins"])


func add_coins(amount: int) -> void:
	SaveGame.data["coins"] = coins() + amount
	SaveGame.mark_dirty()
	coins_changed.emit(coins())


func spend_coins(amount: int) -> bool:
	if coins() < amount:
		return false
	SaveGame.data["coins"] = coins() - amount
	SaveGame.mark_dirty()
	coins_changed.emit(coins())
	return true

# ----------------------------------------------------------------- tools

func tool_state(id: String) -> Dictionary:
	return SaveGame.data["tools"].get(id, {"unlocked": false, "level": 1, "uses": 0})


func tool_unlocked(id: String) -> bool:
	return bool(tool_state(id).get("unlocked", false))


func tool_level(id: String) -> int:
	return int(tool_state(id).get("level", 1))


func tool_uses(id: String) -> int:
	return int(tool_state(id).get("uses", 0))


func tool_max_uses(id: String) -> int:
	var base: int = TOOLS[id]["base_uses"]
	if base < 0:
		return -1
	return base + upgrade_level("capacity")


func unlock_tool(id: String) -> bool:
	var price: int = TOOLS[id]["price"]
	if tool_unlocked(id) or not spend_coins(price):
		return false
	SaveGame.data["tools"][id]["unlocked"] = true
	SaveGame.data["tools"][id]["uses"] = tool_max_uses(id)
	SaveGame.mark_dirty()
	tools_changed.emit()
	check_achievements()
	return true


func refill_tool(id: String) -> bool:
	var cost: int = TOOLS[id]["refill"]
	if not spend_coins(cost):
		return false
	SaveGame.data["tools"][id]["uses"] = tool_max_uses(id)
	SaveGame.mark_dirty()
	tools_changed.emit()
	return true


func consume_tool_use(id: String) -> bool:
	var st: Dictionary = SaveGame.data["tools"][id]
	if int(st["uses"]) < 0:
		return true
	if int(st["uses"]) <= 0:
		return false
	st["uses"] = int(st["uses"]) - 1
	SaveGame.mark_dirty()
	tools_changed.emit()
	return true


func grant_tool_use(id: String) -> void:
	var st: Dictionary = SaveGame.data["tools"][id]
	if int(st["uses"]) >= 0:
		st["uses"] = int(st["uses"]) + 1
		SaveGame.mark_dirty()
		tools_changed.emit()


func refill_all_tools_for_level() -> void:
	# At level start every limited tool gets at least 1 use (generosity rule),
	# capped at max capacity.
	for id: String in TOOLS.keys():
		var st: Dictionary = SaveGame.data["tools"][id]
		var mx := tool_max_uses(id)
		if mx > 0 and bool(st["unlocked"]) and int(st["uses"]) < 1:
			st["uses"] = 1
	SaveGame.mark_dirty()

# ----------------------------------------------------------------- upgrades

func upgrade_level(id: String) -> int:
	return int(SaveGame.data["upgrades"].get(id, 0))


func upgrade_cost(id: String) -> int:
	var lv := upgrade_level(id)
	return int(UPGRADES[id]["base_cost"] * pow(1.8, lv))


func buy_upgrade(id: String) -> bool:
	var lv := upgrade_level(id)
	if lv >= int(UPGRADES[id]["max"]):
		return false
	if not spend_coins(upgrade_cost(id)):
		return false
	SaveGame.data["upgrades"][id] = lv + 1
	SaveGame.mark_dirty()
	return true

# ----------------------------------------------------------------- collection

func collect_item(id: String) -> void:
	var col: Dictionary = SaveGame.data["collection"]
	col[id] = int(col.get(id, 0)) + 1
	add_stat("items_collected", 1)
	if ITEMS.has(id) and int(ITEMS[id]["rarity"]) >= 2:
		add_stat("rare_items", 1)
	SaveGame.mark_dirty()


func collection_count(id: String) -> int:
	return int(SaveGame.data["collection"].get(id, 0))


func collection_discovered() -> int:
	var n := 0
	for id: String in ITEMS.keys():
		if collection_count(id) > 0:
			n += 1
	return n

# ----------------------------------------------------------------- stats / profile

func stat(id: String) -> float:
	return float(SaveGame.data["stats"].get(id, 0))


func add_stat(id: String, amount: float) -> void:
	SaveGame.data["stats"][id] = stat(id) + amount
	SaveGame.mark_dirty()


func add_xp(amount: int) -> void:
	SaveGame.data["xp"] = int(SaveGame.data["xp"]) + amount
	SaveGame.mark_dirty()


func player_level() -> int:
	return 1 + int(sqrt(float(SaveGame.data["xp"]) / 50.0))


func total_stars() -> int:
	var n := 0
	for k: Variant in SaveGame.data["levels"].keys():
		n += int(SaveGame.data["levels"][k].get("stars", 0))
	return n

# ----------------------------------------------------------------- levels

func max_level() -> int:
	return int(SaveGame.data["max_level"])


func level_record(idx: int) -> Dictionary:
	return SaveGame.data["levels"].get(str(idx), {})


func save_level_result(idx: int, stars: int, time_s: float) -> bool:
	var rec: Dictionary = SaveGame.data["levels"].get(str(idx), {})
	var new_record: bool = rec.is_empty() or time_s < float(rec.get("best_time", 1e9))
	var best_stars: int = maxi(stars, int(rec.get("stars", 0)))
	var best_time: float = time_s if new_record else float(rec.get("best_time", time_s))
	SaveGame.data["levels"][str(idx)] = {"stars": best_stars, "best_time": best_time}
	if idx + 1 > max_level():
		SaveGame.data["max_level"] = idx + 1
	if stat("best_time") <= 0.0 or time_s < stat("best_time"):
		SaveGame.data["stats"]["best_time"] = time_s
	SaveGame.mark_dirty()
	return new_record

# ----------------------------------------------------------------- daily

func today_string() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


func daily_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])


func daily_best_today() -> float:
	return float(SaveGame.data["daily"]["bests"].get(today_string(), 0.0))


func record_daily(time_s: float) -> bool:
	var daily: Dictionary = SaveGame.data["daily"]
	var today := today_string()
	var prev: float = float(daily["bests"].get(today, 0.0))
	var is_new := prev <= 0.0 or time_s < prev
	if is_new:
		daily["bests"][today] = time_s
	if daily["last_date"] != today:
		# streak logic
		var yesterday := _yesterday_string()
		if daily["last_date"] == yesterday:
			daily["streak"] = int(daily["streak"]) + 1
		else:
			daily["streak"] = 1
		daily["last_date"] = today
		daily["total"] = int(daily["total"]) + 1
	SaveGame.mark_dirty()
	check_achievements()
	return is_new


func _yesterday_string() -> String:
	var ts := Time.get_unix_time_from_system() - 86400.0
	var d := Time.get_datetime_dict_from_unix_time(int(ts))
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]

# ----------------------------------------------------------------- achievements

func achievement_done(id: String) -> bool:
	return id in SaveGame.data["achievements"]


func _unlock_achievement(a: Dictionary) -> void:
	SaveGame.data["achievements"].append(a["id"])
	add_coins(int(a["reward"]))
	SaveGame.mark_dirty()
	achievement_unlocked.emit(a["id"])


func trigger_special(id: String) -> void:
	# For event-based achievements (no_hint, speed).
	for a: Dictionary in ACHIEVEMENTS:
		if a["id"] == id and not achievement_done(id):
			_unlock_achievement(a)


func check_achievements() -> void:
	for a: Dictionary in ACHIEVEMENTS:
		if achievement_done(a["id"]):
			continue
		var done := false
		var s: String = a["stat"]
		match s:
			"_special":
				continue
			"_collection_half":
				done = collection_discovered() >= ITEMS.size() / 2
			"_collection_full":
				done = collection_discovered() >= ITEMS.size()
			"_tools_all":
				done = _all_tools_unlocked()
			"_stars":
				done = total_stars() >= int(a["goal"])
			"_daily":
				done = int(SaveGame.data["daily"]["total"]) >= int(a["goal"])
			"_max_level":
				done = max_level() >= int(a["goal"])
			_:
				done = stat(s) >= float(a["goal"])
		if done:
			_unlock_achievement(a)


func _all_tools_unlocked() -> bool:
	for id: String in TOOLS.keys():
		if not tool_unlocked(id):
			return false
	return true


func achievement_progress(a: Dictionary) -> Vector2i:
	var s: String = a["stat"]
	match s:
		"_special":
			return Vector2i(1 if achievement_done(a["id"]) else 0, 1)
		"_collection_half":
			return Vector2i(collection_discovered(), ITEMS.size() / 2)
		"_collection_full":
			return Vector2i(collection_discovered(), ITEMS.size())
		"_tools_all":
			var n := 0
			for id: String in TOOLS.keys():
				if tool_unlocked(id):
					n += 1
			return Vector2i(n, TOOLS.size())
		"_stars":
			return Vector2i(total_stars(), int(a["goal"]))
		"_daily":
			return Vector2i(int(SaveGame.data["daily"]["total"]), int(a["goal"]))
		"_max_level":
			return Vector2i(max_level(), int(a["goal"]))
		_:
			return Vector2i(int(stat(s)), int(a["goal"]))

# ----------------------------------------------------------------- analytics (lightweight stub)

var _events: Array[Dictionary] = []


func track(event: String, props: Dictionary = {}) -> void:
	_events.append({"t": Time.get_unix_time_from_system(), "e": event, "p": props})
	if _events.size() > 200:
		_events = _events.slice(100)
