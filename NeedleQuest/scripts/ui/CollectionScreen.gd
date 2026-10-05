extends Control
## Collection book - every hidden item ever discovered.

var main: Node

const ITEM_ICONS := {
	"coin": "🪙", "button": "🔘", "bolt": "🔩", "gem": "💎", "key": "🗝",
	"toy": "🧸", "horseshoe": "🧲", "photo": "🖼", "watch": "⌚", "ring": "💍",
	"artifact": "🏺", "treasure": "💰", "nail": "📍",
	"golden_needle": "🪡", "legendary_needle": "✨",
}


func get_screen_id() -> String:
	return "collection"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var page := UIH.page(Loc.t("collection"), func() -> void: main.show_screen("menu"))
	add_child(page["root"])
	var body: VBoxContainer = page["body"]

	var found := G.collection_discovered()
	var total := G.ITEMS.size()
	var prog := UIH.label(Loc.tf("collection_progress", [found, total]), 26, UIH.C_ACCENT, true)
	body.add_child(prog)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = total
	bar.value = found
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	body.add_child(bar)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	# sort by rarity then name
	var ids: Array = G.ITEMS.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ra := int(G.ITEMS[a]["rarity"])
		var rb := int(G.ITEMS[b]["rarity"])
		if ra == rb:
			return a < b
		return ra < rb)
	for id: String in ids:
		grid.add_child(_item_tile(id))
	body.add_child(UIH.scroll(grid))


func _item_tile(id: String) -> Control:
	var count := G.collection_count(id)
	var discovered := count > 0
	var rarity := int(G.ITEMS[id]["rarity"])
	var rcolor: Color = G.RARITY_COLORS[rarity]
	var p := UIH.panel(UIH.C_PANEL if discovered else Color(0.1, 0.1, 0.09, 0.9), 16)
	p.custom_minimum_size = Vector2(210, 170)
	var v := UIH.vbox(2)
	p.add_child(v)
	var icon := UIH.label(ITEM_ICONS.get(id, "❓") if discovered else "❓", 44)
	if not discovered:
		icon.modulate = Color(1, 1, 1, 0.3)
	v.add_child(icon)
	var name_l := UIH.label(Loc.t("item_" + id) if discovered else "???", 22, UIH.C_TEXT if discovered else UIH.C_TEXT_DIM, true)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(name_l)
	v.add_child(UIH.label(Loc.t(G.RARITY_KEYS[rarity]), 18, rcolor))
	if discovered:
		v.add_child(UIH.label(Loc.tf("found_x", [count]), 18, UIH.C_TEXT_DIM))
	return p
