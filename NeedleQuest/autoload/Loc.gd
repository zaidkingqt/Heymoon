extends Node
## Localization system. Supports English (LTR) and Arabic (RTL).
## Add more languages by appending to each entry array.
## Index 0 = English, index 1 = Arabic.

signal language_changed

const LANGS: Array[String] = ["en", "ar"]

var lang: String = "ar"

const T: Dictionary = {
	# ------------------------------------------------- general
	"app_name": ["Needle Quest", "مهمة الإبرة"],
	"tagline": ["Find the needle in the haystack!", "ابحث عن الإبرة في كومة القش!"],
	"play": ["PLAY", "العب"],
	"daily": ["DAILY CHALLENGE", "التحدي اليومي"],
	"collection": ["COLLECTION", "المجموعة"],
	"shop": ["SHOP", "المتجر"],
	"upgrades": ["UPGRADES", "الترقيات"],
	"achievements": ["ACHIEVEMENTS", "الإنجازات"],
	"profile": ["PROFILE", "الملف الشخصي"],
	"settings": ["SETTINGS", "الإعدادات"],
	"back": ["Back", "رجوع"],
	"close": ["Close", "إغلاق"],
	"ok": ["OK", "حسنًا"],
	"cancel": ["Cancel", "إلغاء"],
	"yes": ["Yes", "نعم"],
	"no": ["No", "لا"],
	"level": ["Level", "المرحلة"],
	"level_n": ["Level %d", "المرحلة %d"],
	"coins": ["Coins", "العملات"],
	"locked": ["Locked", "مقفل"],
	"unlock_at": ["Unlocks at level %d", "يُفتح عند المرحلة %d"],
	"loading": ["Loading...", "جارِ التحميل..."],
	"select_level": ["SELECT LEVEL", "اختر المرحلة"],
	"endless_note": ["More levels are generated endlessly as you progress!", "تتولد مراحل جديدة بلا نهاية كلما تقدمت!"],

	# ------------------------------------------------- gameplay HUD
	"time": ["Time", "الوقت"],
	"removed": ["Removed", "المُزال"],
	"hint": ["Hint", "تلميح"],
	"hints_used": ["Hints used", "التلميحات المستخدمة"],
	"pause": ["Pause", "إيقاف"],
	"paused": ["PAUSED", "اللعبة متوقفة"],
	"resume": ["RESUME", "متابعة"],
	"restart": ["RESTART", "إعادة"],
	"home": ["HOME", "الرئيسية"],
	"next_level": ["NEXT LEVEL", "المرحلة التالية"],
	"replay": ["REPLAY", "إعادة اللعب"],
	"retry": ["RETRY", "حاول مجددًا"],
	"use_hint": ["USE HINT", "استخدم تلميحًا"],
	"times_up": ["TIME'S UP!", "انتهى الوقت!"],
	"times_up_sub": ["The needle is still hiding...", "ما زالت الإبرة مختبئة..."],
	"extra_time": ["+30s (watch ad)", "+٣٠ ثانية (شاهد إعلانًا)"],
	"victory": ["YOU FOUND IT!", "لقد وجدتها!"],
	"needle_found": ["The needle has been found!", "تم العثور على الإبرة!"],
	"reward": ["Reward", "المكافأة"],
	"best": ["Best", "الأفضل"],
	"new_record": ["NEW RECORD!", "رقم قياسي جديد!"],
	"items_found": ["Items found", "العناصر المكتشفة"],
	"no_uses": ["No uses left! Refill in the shop.", "لا توجد استخدامات! أعد التعبئة من المتجر."],
	"time_left": ["Time left", "الوقت المتبقي"],
	"timed_level": ["Timed level! Find it fast!", "مرحلة بوقت محدد! أسرع بالبحث!"],
	"secret_found": ["Secret stash discovered!", "اكتشفت مخبأً سريًا!"],
	"golden_bonus": ["Golden needle bonus!", "مكافأة الإبرة الذهبية!"],
	"legendary_bonus": ["LEGENDARY NEEDLE!!", "إبرة أسطورية!!"],
	"getting_warm": ["You're getting close...", "أنت تقترب..."],
	"very_warm": ["Very close now!", "قريب جدًا الآن!"],

	# ------------------------------------------------- hints
	"magnet_nothing": ["No metal detected here...", "لا توجد معادن هنا..."],
	"hint_dir": ["The needle is in the %s part of the pile.", "الإبرة في الجزء %s من الكومة."],
	"hint_zone": ["The search area has been narrowed!", "تم تضييق منطقة البحث!"],
	"hint_small": ["The needle is inside the small circle!", "الإبرة داخل الدائرة الصغيرة!"],
	"dir_n": ["northern", "الشمالي"],
	"dir_s": ["southern", "الجنوبي"],
	"dir_e": ["eastern", "الشرقي"],
	"dir_w": ["western", "الغربي"],
	"dir_ne": ["north-eastern", "الشمالي الشرقي"],
	"dir_nw": ["north-western", "الشمالي الغربي"],
	"dir_se": ["south-eastern", "الجنوبي الشرقي"],
	"dir_sw": ["south-western", "الجنوبي الغربي"],
	"dir_c": ["central", "الأوسط"],

	# ------------------------------------------------- tools
	"tool_hand": ["Hand", "اليد"],
	"tool_hand_d": ["Remove hay piece by piece.", "أزل القش قطعة قطعة."],
	"tool_broom": ["Broom", "المكنسة"],
	"tool_broom_d": ["Sweeps a wide area of hay.", "تكنس منطقة واسعة من القش."],
	"tool_fan": ["Fan", "المروحة"],
	"tool_fan_d": ["Blows away the whole top layer around.", "تزيح الطبقة العلوية في منطقة كبيرة."],
	"tool_digger": ["Digger", "أداة الحفر"],
	"tool_digger_d": ["Digs through all layers at once.", "تحفر عبر كل الطبقات دفعة واحدة."],
	"tool_magnet": ["Magnet", "المغناطيس"],
	"tool_magnet_d": ["Pings nearby hidden metal objects.", "يكشف الأجسام المعدنية المخفية القريبة."],
	"tool_detector": ["Detector", "أداة الكشف"],
	"tool_detector_d": ["Shows how close the needle is.", "تُظهر مدى قربك من الإبرة."],
	"tool_magnifier": ["Magnifier", "المكبر"],
	"tool_magnifier_d": ["Zooms in and highlights small items.", "يقرّب الصورة ويبرز العناصر الصغيرة."],
	"uses": ["Uses", "الاستخدامات"],
	"unlimited": ["Unlimited", "غير محدود"],
	"refill": ["Refill", "إعادة تعبئة"],
	"unlock": ["Unlock", "فتح"],
	"tool_level": ["Tool level", "مستوى الأداة"],

	# ------------------------------------------------- items
	"item_coin": ["Coin", "عملة"],
	"item_button": ["Old Button", "زر قديم"],
	"item_bolt": ["Bolt", "برغي"],
	"item_gem": ["Gem", "جوهرة"],
	"item_key": ["Old Key", "مفتاح قديم"],
	"item_toy": ["Tiny Toy", "لعبة صغيرة"],
	"item_horseshoe": ["Horseshoe", "حدوة حصان"],
	"item_photo": ["Old Photo", "صورة قديمة"],
	"item_watch": ["Pocket Watch", "ساعة جيب"],
	"item_ring": ["Ring", "خاتم"],
	"item_artifact": ["Artifact", "قطعة أثرية"],
	"item_treasure": ["Treasure", "كنز"],
	"item_nail": ["Rusty Nail", "مسمار صدئ"],
	"item_golden_needle": ["Golden Needle", "إبرة ذهبية"],
	"item_legendary_needle": ["Legendary Needle", "إبرة أسطورية"],
	"item_chest": ["Secret Chest", "صندوق سري"],
	"item_needle": ["Needle", "الإبرة"],
	"rar_common": ["Common", "شائع"],
	"rar_uncommon": ["Uncommon", "غير شائع"],
	"rar_rare": ["Rare", "نادر"],
	"rar_epic": ["Epic", "ملحمي"],
	"rar_legendary": ["Legendary", "أسطوري"],
	"rar_mythic": ["Mythic", "خرافي"],
	"found_x": ["Found: %d", "وجدت: %d"],
	"not_found": ["Not discovered yet", "لم يُكتشف بعد"],
	"collection_progress": ["Discovered %d / %d", "اكتشفت %d / %d"],

	# ------------------------------------------------- upgrades
	"up_remove_speed": ["Removal Speed", "سرعة الإزالة"],
	"up_remove_speed_d": ["Hay flies away faster and combos trigger more.", "يتطاير القش أسرع وتزداد الإزالات المتتالية."],
	"up_capacity": ["Tool Capacity", "سعة الأدوات"],
	"up_capacity_d": ["+1 use for every limited tool.", "استخدام إضافي لكل أداة محدودة."],
	"up_broom_power": ["Broom Power", "قوة المكنسة"],
	"up_broom_power_d": ["The broom sweeps a wider area.", "تكنس المكنسة منطقة أوسع."],
	"up_magnet_power": ["Magnet Power", "قوة المغناطيس"],
	"up_magnet_power_d": ["The magnet detects from farther away.", "يكشف المغناطيس من مسافة أبعد."],
	"up_hint_acc": ["Hint Accuracy", "دقة التلميحات"],
	"up_hint_acc_d": ["Hint circles become smaller and cheaper.", "تصبح دوائر التلميح أصغر وأرخص."],
	"up_search": ["Search Speed", "سرعة البحث"],
	"up_search_d": ["Detector and magnet last longer.", "يدوم الكاشف والمغناطيس لفترة أطول."],
	"up_tool_power": ["Tool Power", "قوة الأدوات"],
	"up_tool_power_d": ["Fan and digger affect a bigger area.", "تؤثر المروحة والحفّار في منطقة أكبر."],
	"max_level": ["MAX", "الحد الأقصى"],
	"upgrade": ["Upgrade", "ترقية"],
	"lvl_short": ["Lv.%d", "مستوى %d"],

	# ------------------------------------------------- shop
	"shop_tools": ["Tools", "الأدوات"],
	"shop_skins": ["Hay Skins", "مظاهر القش"],
	"shop_extras": ["Effects", "المؤثرات"],
	"owned": ["Owned", "مملوك"],
	"equipped": ["Equipped", "مُفعّل"],
	"equip": ["Equip", "تفعيل"],
	"buy": ["Buy", "شراء"],
	"not_enough": ["Not enough coins!", "لا تملك عملات كافية!"],
	"skin_classic": ["Classic Hay", "القش الكلاسيكي"],
	"skin_golden": ["Golden Luxury", "الذهبي الفاخر"],
	"skin_green": ["Fresh Green", "الأخضر الريفي"],
	"skin_autumn": ["Autumn Mix", "خليط الخريف"],
	"skin_silver": ["Silver Frost", "الصقيع الفضي"],
	"fx_classic": ["Classic Dust", "غبار كلاسيكي"],
	"fx_sparkle": ["Sparkles", "شرارات لامعة"],
	"fx_leaves": ["Leaf Burst", "تطاير الأوراق"],
	"fx_fireflies": ["Fireflies", "يراعات مضيئة"],

	# ------------------------------------------------- achievements
	"ach_first_needle": ["First Needle", "أول إبرة"],
	"ach_first_needle_d": ["Find your first needle.", "اعثر على أول إبرة لك."],
	"ach_needles_10": ["Needle Hunter", "صائد الإبر"],
	"ach_needles_10_d": ["Find 10 needles.", "اعثر على ١٠ إبر."],
	"ach_needles_50": ["Needle Master", "سيد الإبر"],
	"ach_needles_50_d": ["Find 50 needles.", "اعثر على ٥٠ إبرة."],
	"ach_needles_100": ["Needle Legend", "أسطورة الإبر"],
	"ach_needles_100_d": ["Find 100 needles.", "اعثر على ١٠٠ إبرة."],
	"ach_no_hint": ["Pure Instinct", "حدس خالص"],
	"ach_no_hint_d": ["Complete a level without hints.", "أكمل مرحلة بدون تلميحات."],
	"ach_speed": ["Lightning Finder", "الباحث البرق"],
	"ach_speed_d": ["Find the needle in under 30 seconds.", "اعثر على الإبرة في أقل من ٣٠ ثانية."],
	"ach_clumps_1000": ["Hay Mover", "ناقل القش"],
	"ach_clumps_1000_d": ["Remove 1,000 clumps of hay.", "أزل ١٠٠٠ حزمة قش."],
	"ach_clumps_10000": ["Hay Storm", "عاصفة القش"],
	"ach_clumps_10000_d": ["Remove 10,000 clumps of hay.", "أزل ١٠٠٠٠ حزمة قش."],
	"ach_golden": ["Golden Touch", "اللمسة الذهبية"],
	"ach_golden_d": ["Find a golden needle.", "اعثر على إبرة ذهبية."],
	"ach_legendary": ["Myth Hunter", "صائد الأساطير"],
	"ach_legendary_d": ["Find a legendary needle.", "اعثر على إبرة أسطورية."],
	"ach_collector": ["Collector", "هاوي التجميع"],
	"ach_collector_d": ["Discover half of the collection.", "اكتشف نصف المجموعة."],
	"ach_collector_full": ["Museum Curator", "أمين المتحف"],
	"ach_collector_full_d": ["Discover the full collection.", "اكتشف المجموعة كاملة."],
	"ach_tools_all": ["Fully Equipped", "عدة كاملة"],
	"ach_tools_all_d": ["Unlock all tools.", "افتح جميع الأدوات."],
	"ach_stars_50": ["Star Gatherer", "جامع النجوم"],
	"ach_stars_50_d": ["Earn 50 stars.", "اجمع ٥٠ نجمة."],
	"ach_daily_5": ["Daily Devotion", "مواظب يومي"],
	"ach_daily_5_d": ["Complete 5 daily challenges.", "أكمل ٥ تحديات يومية."],
	"ach_level_25": ["Deep Searcher", "الباحث العميق"],
	"ach_level_25_d": ["Reach level 25.", "صِل إلى المرحلة ٢٥."],
	"ach_items_100": ["Treasure Rain", "مطر الكنوز"],
	"ach_items_100_d": ["Collect 100 hidden items.", "اجمع ١٠٠ عنصر مخفي."],
	"ach_unlocked": ["Achievement unlocked!", "إنجاز جديد!"],

	# ------------------------------------------------- daily
	"daily_title": ["Daily Challenge", "التحدي اليومي"],
	"daily_sub": ["A special seeded level. Same for everyone, every day!", "مرحلة خاصة بنفس التوليد للجميع كل يوم!"],
	"play_daily": ["PLAY TODAY'S CHALLENGE", "العب تحدي اليوم"],
	"today_best": ["Today's best", "أفضل نتيجة اليوم"],
	"streak": ["Streak", "أيام متتالية"],
	"not_played": ["Not played yet", "لم تُلعب بعد"],
	"daily_done": ["Completed!", "مكتمل!"],
	"total_dailies": ["Dailies completed", "التحديات المكتملة"],

	# ------------------------------------------------- profile
	"pf_name": ["Player name", "اسم اللاعب"],
	"pf_level": ["Player level", "مستوى اللاعب"],
	"pf_needles": ["Needles found", "الإبر الموجودة"],
	"pf_levels": ["Levels completed", "المراحل المكتملة"],
	"pf_best": ["Fastest find", "أسرع عثور"],
	"pf_items": ["Items discovered", "العناصر المكتشفة"],
	"pf_completion": ["Collection completion", "نسبة إكمال المجموعة"],
	"pf_stars": ["Total stars", "مجموع النجوم"],
	"pf_rare": ["Rare items found", "العناصر النادرة"],
	"pf_removed": ["Hay removed", "القش المُزال"],
	"rename": ["Rename", "تغيير الاسم"],
	"enter_name": ["Enter your name", "أدخل اسمك"],

	# ------------------------------------------------- settings
	"music": ["Music", "الموسيقى"],
	"sound_fx": ["Sound Effects", "المؤثرات الصوتية"],
	"language": ["Language", "اللغة"],
	"vibration": ["Vibration", "الاهتزاز"],
	"graphics": ["Graphics Quality", "جودة الرسومات"],
	"q_low": ["Low", "منخفضة"],
	"q_medium": ["Medium", "متوسطة"],
	"q_high": ["High", "عالية"],
	"q_ultra": ["Ultra", "فائقة"],
	"fps_limit": ["FPS Limit", "حد الإطارات"],
	"notifications": ["Notifications", "الإشعارات"],
	"reset_progress": ["Reset Progress", "إعادة تعيين التقدم"],
	"reset_confirm": ["Delete ALL progress? This cannot be undone!", "حذف كل التقدم؟ لا يمكن التراجع عن هذا!"],
	"privacy": ["Privacy", "الخصوصية"],
	"privacy_text": ["Needle Quest stores your progress locally on your device only. No personal data is collected or shared.", "تحفظ مهمة الإبرة تقدمك محليًا على جهازك فقط. لا يتم جمع أي بيانات شخصية أو مشاركتها."],
	"credits": ["Credits", "فريق العمل"],
	"credits_text": ["Needle Quest\nAn original 3D search game.\nBuilt with Godot Engine 4.\nFont: Cairo (SIL OFL).\nAll assets are original.", "مهمة الإبرة\nلعبة بحث ثلاثية الأبعاد أصلية.\nصُنعت بمحرك Godot 4.\nالخط: Cairo (رخصة SIL OFL).\nجميع الأصول أصلية."],

	# ------------------------------------------------- tutorial
	"tut_1": ["Drag with one finger to rotate the camera.", "اسحب بإصبع واحد لتدوير الكاميرا."],
	"tut_2": ["Pinch with two fingers to zoom in and out.", "قرّب أو أبعد بإصبعين (أو عجلة الفأرة)."],
	"tut_3": ["Tap the hay to remove it!", "اضغط على القش لإزالته!"],
	"tut_4": ["Keep digging! A needle hides deep inside...", "تابع الحفر! هناك إبرة مختبئة في الأعماق..."],
	"tut_5": ["Tools at the bottom help you search faster.", "الأدوات في الأسفل تساعدك على البحث أسرع."],
	"tut_6": ["Stuck? The hint button narrows the search area.", "عالق؟ زر التلميح يضيّق منطقة البحث."],
	"tut_skip": ["Skip", "تخطي"],

	# ------------------------------------------------- misc
	"watch_ad": ["Watch Ad", "شاهد إعلانًا"],
	"free_hint_ad": ["Free hint (watch ad)", "تلميح مجاني (شاهد إعلانًا)"],
	"free_use_ad": ["+1 use (watch ad)", "استخدام إضافي (شاهد إعلانًا)"],
	"move_obstacle": ["Tap again to move it!", "اضغط مرة أخرى لتحريكه!"],
	"theme_meadow": ["Meadow", "المرج"],
	"theme_farm": ["Farm", "المزرعة"],
	"theme_barn": ["Barn", "الحظيرة"],
	"theme_warehouse": ["Warehouse", "المستودع"],
	"theme_truck": ["Hay Truck", "شاحنة القش"],
	"theme_night": ["Night Farm", "مزرعة الليل"],
	"theme_factory": ["Old Factory", "المصنع القديم"],
	"theme_abandoned": ["Abandoned Farm", "المزرعة المهجورة"],
	"diff_tutorial": ["Tutorial", "تعليمي"],
	"diff_easy": ["Easy", "سهل"],
	"diff_normal": ["Normal", "عادي"],
	"diff_hard": ["Hard", "صعب"],
	"diff_expert": ["Expert", "خبير"],
	"diff_extreme": ["Extreme", "متطرف"],
	"diff_impossible": ["Impossible", "مستحيل"],
}


func t(key: String) -> String:
	var idx: int = LANGS.find(lang)
	if idx < 0:
		idx = 0
	if T.has(key):
		var arr: Array = T[key]
		if idx < arr.size():
			return arr[idx]
		return arr[0]
	return key


func tf(key: String, args: Array) -> String:
	return t(key) % args


func is_rtl() -> bool:
	return lang == "ar"


func set_lang(new_lang: String) -> void:
	if new_lang in LANGS and new_lang != lang:
		lang = new_lang
		language_changed.emit()
