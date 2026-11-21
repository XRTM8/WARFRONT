class_name Constants
extends RefCounted

const TILE_SIZE: int = 48
const MAP_COLS: int = 72
const MAP_ROWS: int = 40

const STARTING_PLAYER_OIL: int = 260
const STARTING_ENEMY_OIL: int = 220
const BRIDGE_REBUILD_COST: int = 110
const BRIDGE_MAX_HP: float = 420.0
const HQ_MAX_HP: float = 1600.0
const TRUCK_CARGO_CAPACITY: int = 55
const REVERSE_SPEED_RATIO: float = 0.70

const MATCH_PRESETS: Dictionary = {
	"1v1": {
		"id": "1v1",
		"name": "مواجهة ثنائية حاسمة",
		"code": "[ 1 vs 1 DUEL ]",
		"slots_count": 2,
		"default_teams": [1, 2],
		"desc": "مباراة تكتيكية مباشرة 1 ضد 1 بين التحالف والمغاوير."
	},
	"2v2": {
		"id": "2v2",
		"name": "حلف العمليات المشتركة",
		"code": "[ 2 vs 2 ALLIANCE ]",
		"slots_count": 4,
		"default_teams": [1, 1, 2, 2],
		"desc": "معركة فرق كبرى: تحالف قاعدتين ضد قاعدتين أخريين."
	},
	"ffa": {
		"id": "ffa",
		"name": "الاشتباك الشامل (الكل ضد الكل)",
		"code": "[ 4-WAY FREE FOR ALL ]",
		"slots_count": 4,
		"default_teams": [1, 2, 3, 4],
		"desc": "أربعة جيوش متناحرة تتصارع للسيطرة على كافة حقول النفط."
	},
	"1v3": {
		"id": "1v3",
		"name": "صمود الحصار المستميت",
		"code": "[ 1 vs 3 SURVIVAL ]",
		"slots_count": 4,
		"default_teams": [1, 2, 2, 2],
		"desc": "قاعدة وحيدة محاصرة تواجه 3 جيوش معادية متحالفة ضدها."
	}
}

const SLOT_DEFAULT_COLORS: Array[Color] = [
	Color("#22c55e"), # Slot 0: Green (Player)
	Color("#38bdf8"), # Slot 1: Sky Blue (Ally)
	Color("#ef4444"), # Slot 2: Crimson Red (Enemy 1)
	Color("#f97316")  # Slot 3: Amber Orange (Enemy 2)
]

const THEATER_CONFIGS: Dictionary = {
	"kirkuk": {
		"name": "وادي كركوك النفطي",
		"code": "[ KIRKUK VALLEY // 1v1 ]",
		"cols": 72,
		"rows": 40,
		"max_slots": 2,
		"desc": "مسرح عمليات كلاسيكي: نهر وسطي و3 جسور ومخاضات تكتيكية."
	},
	"basra": {
		"name": "دلتا البصرة الكبرى",
		"code": "[ BASRA DELTA // 2v2 & 4-WAY ]",
		"cols": 100,
		"rows": 60,
		"max_slots": 4,
		"desc": "خريطة عملاقة 4800x2880: دلتا متقاطعة، 4 مقرات في الزوايا، 4 جسور، و6 حقول نفط."
	},
	"zagros": {
		"name": "حوض هضبة زاغروس",
		"code": "[ ZAGROS BASIN // 4-WAY FFA ]",
		"cols": 100,
		"rows": 60,
		"max_slots": 4,
		"desc": "حوض صخري واسع 4800x2880 مع 8 حقول نفطية متنازع عليها وممرات جبلية."
	}
}

const FACTION_DOCTRINES: Dictionary = {
	"vanguard": {
		"id": "vanguard",
		"name": "طليعة التحالف المدرعة",
		"code": "[ COALITION VANGUARD ]",
		"hp_mult": 1.15,
		"speed_mult": 0.95,
		"damage_mult": 1.05,
		"desc": "عقيدة ترتكز على صلابة الدروع الفولاذية والقصف المدفعي المنسق مع تعزيز متانة الهياكل."
	},
	"raiders": {
		"id": "raiders",
		"name": "مغاوير الصحراء السريعة",
		"code": "[ DESERT RAIDERS ]",
		"hp_mult": 0.90,
		"speed_mult": 1.20,
		"damage_mult": 1.10,
		"desc": "عقيدة خفيفة تعتمد على المناورة الصاعقة والسرعة القصوى والالتفاف السريع خلف خطوط الإمداد."
	}
}

const TACTICAL_STANCES: Dictionary = {
	"guard": { "id": "guard", "name": "حراسة ودفاع", "leash_dist": 140.0, "icon": "[GUARD]" },
	"attack_move": { "id": "attack_move", "name": "اشتباك وتقدم", "leash_dist": 280.0, "icon": "[ENGAGE]" },
	"hold_ground": { "id": "hold_ground", "name": "ثبات وتمركز", "leash_dist": 0.0, "icon": "[HOLD]" },
	"retreat": { "id": "retreat", "name": "انسحاب تكتيكي", "leash_dist": 9999.0, "icon": "[RETREAT]" }
}

const UNIT_SPECS: Dictionary = {
	"truck": {
		"kind": "truck",
		"hotkey": "",
		"cost": 0,
		"hp": 110.0,
		"speed": 138.0,
		"radius": 14.0,
		"range": 0.0,
		"damage": 0.0,
		"fireRate": 0.0,
		"bridgeBonus": 1.0,
	},
	"scout": {
		"kind": "scout",
		"hotkey": "1",
		"cost": 60,
		"hp": 115.0,
		"speed": 132.0,
		"radius": 14.0,
		"range": 175.0,
		"damage": 11.0,
		"fireRate": 0.34,
		"bridgeBonus": 0.65,
	},
	"tank": {
		"kind": "tank",
		"hotkey": "2",
		"cost": 140,
		"hp": 290.0,
		"speed": 74.0,
		"radius": 17.0,
		"range": 220.0,
		"damage": 44.0,
		"fireRate": 1.35,
		"bridgeBonus": 1.35,
	},
	"behemoth": {
		"kind": "behemoth",
		"hotkey": "3",
		"cost": 240,
		"hp": 540.0,
		"speed": 46.0,
		"radius": 22.0,
		"range": 250.0,
		"damage": 96.0,
		"fireRate": 2.10,
		"bridgeBonus": 2.2,
	},
	"artillery": {
		"kind": "artillery",
		"hotkey": "4",
		"cost": 185,
		"hp": 155.0,
		"speed": 62.0,
		"radius": 16.0,
		"range": 375.0,
		"damage": 82.0,
		"fireRate": 2.65,
		"bridgeBonus": 3.4,
	},
	"helicopter": {
		"kind": "helicopter",
		"hotkey": "5",
		"cost": 215,
		"hp": 185.0,
		"speed": 145.0,
		"radius": 15.0,
		"range": 200.0,
		"damage": 24.0,
		"fireRate": 0.28,
		"bridgeBonus": 0.8,
	},
	"engineer": {
		"kind": "engineer",
		"hotkey": "6",
		"cost": 75,
		"hp": 135.0,
		"speed": 96.0,
		"radius": 14.0,
		"range": 95.0,
		"damage": 18.0,
		"fireRate": 0.70,
		"bridgeBonus": 4.5,
	},
	"turret": {
		"kind": "turret",
		"hotkey": "7",
		"cost": 120,
		"hp": 380.0,
		"speed": 0.0,
		"radius": 18.0,
		"range": 260.0,
		"damage": 26.0,
		"fireRate": 0.45,
		"bridgeBonus": 0.8,
	},
	"infantry_rifle": {
		"kind": "infantry_rifle",
		"hotkey": "",
		"cost": 40,
		"hp": 65.0,
		"speed": 105.0,
		"radius": 9.0,
		"range": 140.0,
		"damage": 8.0,
		"fireRate": 0.28,
		"bridgeBonus": 0.5,
		"category": "barracks",
		"captureBonus": 2.0,
		"name": "فصيل بنادق مشاة",
		"role_tag": "سيطرة سريعة",
		"role_color": Color("#84cc16"),
		"build_time": 1.8
	},
	"infantry_at": {
		"kind": "infantry_at",
		"hotkey": "",
		"cost": 85,
		"hp": 75.0,
		"speed": 90.0,
		"radius": 10.0,
		"range": 190.0,
		"damage": 52.0,
		"fireRate": 1.6,
		"bridgeBonus": 0.6,
		"category": "barracks",
		"vsArmorBonus": 1.5,
		"name": "فريق صواريخ RPG",
		"role_tag": "مضاد دروع",
		"role_color": Color("#ef4444"),
		"build_time": 2.4
	},
	"infantry_mortar": {
		"kind": "infantry_mortar",
		"hotkey": "",
		"cost": 110,
		"hp": 70.0,
		"speed": 75.0,
		"radius": 10.0,
		"range": 340.0,
		"damage": 65.0,
		"fireRate": 2.4,
		"bridgeBonus": 1.0,
		"category": "barracks",
		"isIndirect": true,
		"name": "طاقم هاون ثقيل",
		"role_tag": "قصف غير مباشر",
		"role_color": Color("#f59e0b"),
		"build_time": 3.0
	},
	"jet_interceptor": {
		"kind": "jet_interceptor",
		"hotkey": "",
		"cost": 230,
		"hp": 210.0,
		"speed": 235.0,
		"radius": 16.0,
		"range": 240.0,
		"damage": 38.0,
		"fireRate": 0.32,
		"bridgeBonus": 0.0,
		"category": "airfield",
		"is_air": true,
		"altitude": 48.0,
		"name": "مقاتلة اعتراضية",
		"role_tag": "سيادة جوية",
		"role_color": Color("#38bdf8"),
		"build_time": 4.5
	},
	"strike_bomber": {
		"kind": "strike_bomber",
		"hotkey": "",
		"cost": 280,
		"hp": 280.0,
		"speed": 180.0,
		"radius": 18.0,
		"range": 180.0,
		"damage": 130.0,
		"fireRate": 2.8,
		"bridgeBonus": 0.0,
		"category": "airfield",
		"is_air": true,
		"altitude": 54.0,
		"name": "قاذفة هجوم أرضي",
		"role_tag": "قصف ثقيل",
		"role_color": Color("#f97316"),
		"build_time": 5.5
	},
	"patrol_boat": {
		"kind": "patrol_boat",
		"hotkey": "",
		"cost": 95,
		"hp": 160.0,
		"speed": 130.0,
		"radius": 15.0,
		"range": 190.0,
		"damage": 18.0,
		"fireRate": 0.36,
		"bridgeBonus": 1.0,
		"category": "shipyard",
		"is_naval": true,
		"name": "زورق دورية نهري",
		"role_tag": "دورية وسرعة",
		"role_color": Color("#06b6d4"),
		"build_time": 2.5
	},
	"missile_corvette": {
		"kind": "missile_corvette",
		"hotkey": "",
		"cost": 175,
		"hp": 320.0,
		"speed": 95.0,
		"radius": 18.0,
		"range": 270.0,
		"damage": 58.0,
		"fireRate": 1.4,
		"bridgeBonus": 1.2,
		"category": "shipyard",
		"is_naval": true,
		"name": "كورفيت صواريخ",
		"role_tag": "صواريخ بحرية",
		"role_color": Color("#38bdf8"),
		"build_time": 3.8
	},
	"river_gunboat": {
		"kind": "river_gunboat",
		"hotkey": "",
		"cost": 240,
		"hp": 440.0,
		"speed": 70.0,
		"radius": 21.0,
		"range": 350.0,
		"damage": 92.0,
		"fireRate": 2.2,
		"bridgeBonus": 1.8,
		"category": "shipyard",
		"is_naval": true,
		"name": "زورق مدفعية ثقيل",
		"role_tag": "قصف ساحلي",
		"role_color": Color("#f59e0b"),
		"build_time": 4.8
	},
	"sam_launcher": {
		"kind": "sam_launcher",
		"hotkey": "",
		"cost": 190,
		"hp": 170.0,
		"speed": 65.0,
		"radius": 16.0,
		"range": 380.0,
		"damage": 78.0,
		"fireRate": 1.5,
		"bridgeBonus": 0.8,
		"category": "missile_plant",
		"is_aa": true,
		"name": "عربة دفاع جوي SAM",
		"role_tag": "اعتراض جوي",
		"role_color": Color("#ef4444"),
		"build_time": 3.6
	}
}

const BUILDABLE_UNITS: Array[String] = [
	"scout", "tank", "behemoth", "artillery", "helicopter", "engineer",
	"infantry_rifle", "infantry_at", "infantry_mortar",
	"jet_interceptor", "strike_bomber",
	"patrol_boat", "missile_corvette", "river_gunboat",
	"sam_launcher"
]

const BUILDING_SPECS: Dictionary = {
	"war_factory": {
		"kind": "war_factory",
		"name": "مصنع الدروع والآليات",
		"hotkey": "Q",
		"cost": 210,
		"hp": 750.0,
		"radius": 34.0,
		"width": 68.0,
		"height": 56.0,
		"build_time": 4.5,
		"role_tag": "إنتاج مدرعات",
		"role_color": Color("#f59e0b"),
		"desc": "منشأة صناعية عسكرية متطورة لتجميع الدبابات وراجمات الصواريخ ودبابات الفيلق."
	},
	"repair_depot": {
		"kind": "repair_depot",
		"name": "منصة الصيانة والتجديد",
		"hotkey": "W",
		"cost": 140,
		"hp": 520.0,
		"radius": 30.0,
		"width": 60.0,
		"height": 52.0,
		"build_time": 3.5,
		"heal_rate": 32.0,
		"heal_radius": 60.0,
		"role_tag": "صيانة الآليات",
		"role_color": Color("#38bdf8"),
		"desc": "منصة صيانة هيدروليكية تصلح وتجدد دروع كافة المركبات العسكرية الصديقة القريبة."
	},
	"refinery_silo": {
		"kind": "refinery_silo",
		"name": "مصفاة وصوامع الوقود",
		"hotkey": "E",
		"cost": 160,
		"hp": 620.0,
		"radius": 28.0,
		"width": 56.0,
		"height": 50.0,
		"build_time": 3.8,
		"refining_bonus": 0.25,
		"role_tag": "مضاعفة النفط",
		"role_color": Color("#eab308"),
		"desc": "مجمع تكرير وتخزين نفطي يرفع كفاءة تكرير الشحنات القادمة بنسبة +25%."
	},
	"turret": {
		"kind": "turret",
		"name": "برج رشاش مزدوج",
		"hotkey": "R",
		"cost": 120,
		"hp": 420.0,
		"radius": 20.0,
		"width": 40.0,
		"height": 40.0,
		"build_time": 2.8,
		"range": 260.0,
		"damage": 26.0,
		"fireRate": 0.45,
		"role_tag": "دفاع نقطي",
		"role_color": Color("#84cc16"),
		"desc": "برج تحصين دفاعي بمدفع رشاش مزدوج عيار 12.7 ملم لصد هجمات المشاة والآليات."
	},
	"missile_battery": {
		"kind": "missile_battery",
		"name": "بطارية صواريخ دفاعية",
		"hotkey": "T",
		"cost": 175,
		"hp": 480.0,
		"radius": 22.0,
		"width": 44.0,
		"height": 44.0,
		"build_time": 3.8,
		"range": 340.0,
		"damage": 82.0,
		"fireRate": 1.75,
		"role_tag": "صواريخ ثقيلة",
		"role_color": Color("#ef4444"),
		"desc": "منظومة دفاعية تطلق صواريخ موجهة بعيدة المدى لسحق الدبابات والمروحيات."
	},
	"sandbag_wall": {
		"kind": "sandbag_wall",
		"name": "ساتر خرساني محصن",
		"hotkey": "Y",
		"cost": 45,
		"hp": 650.0,
		"radius": 18.0,
		"width": 48.0,
		"height": 26.0,
		"build_time": 1.5,
		"role_tag": "إعاقة وحواجز",
		"role_color": Color("#a1a1aa"),
		"desc": "حواجز خرسانية وأكياس رمل متراصة تعترض تقدم آليات العدو وتحمي المداخل."
	},
	"barracks": {
		"kind": "barracks",
		"name": "ثكنة المشاة والعمليات",
		"hotkey": "F1",
		"cost": 140,
		"hp": 580.0,
		"radius": 28.0,
		"width": 60.0,
		"height": 52.0,
		"build_time": 3.0,
		"role_tag": "تدريب مشاة",
		"role_color": Color("#84cc16"),
		"desc": "مجمع تدريب وتحصين عسكري يجهز فصائل المشاة وفرق الصواريخ ومهندسي الميدان."
	},
	"airfield": {
		"kind": "airfield",
		"name": "المطار وقاعدة العمليات الجوية",
		"hotkey": "F3",
		"cost": 240,
		"hp": 720.0,
		"radius": 38.0,
		"width": 84.0,
		"height": 64.0,
		"build_time": 4.5,
		"role_tag": "سلاح الجو",
		"role_color": Color("#38bdf8"),
		"desc": "مدرج وحظيرة طيران حديثة لإطلاق المقاتلات الاعتراضية وقاذفات الهجوم التكتيكي."
	},
	"shipyard": {
		"kind": "shipyard",
		"name": "حوض السفن والترسانة النهرية",
		"hotkey": "F4",
		"cost": 210,
		"hp": 680.0,
		"radius": 34.0,
		"width": 72.0,
		"height": 64.0,
		"build_time": 4.0,
		"role_tag": "أسطول نهري",
		"role_color": Color("#06b6d4"),
		"shore_only": true,
		"desc": "ترسانة بحرية خرسانية تُبنى على ضفاف الأنهار لتصنيع زوارق الدورية والفرقاطات."
	},
	"missile_plant": {
		"kind": "missile_plant",
		"name": "مجمع الصواريخ ومنظومات الردع",
		"hotkey": "F5",
		"cost": 225,
		"hp": 690.0,
		"radius": 32.0,
		"width": 64.0,
		"height": 54.0,
		"build_time": 4.2,
		"role_tag": "راجمات ودفاع جوي",
		"role_color": Color("#ef4444"),
		"desc": "منشأة هندسية متقدمة لتجميع راجمات صواريخ كاتيوشا وعربات الدفاع الجوي المحمولة."
	}
}

const PRODUCTION_CATEGORIES: Dictionary = {
	"defense": {
		"id": "defense",
		"name": "دفاعات وتحصين",
		"code": "[ DEFENSE // F6-F8 ]",
		"structures": ["turret", "missile_battery", "sandbag_wall", "repair_depot", "refinery_silo"]
	},
	"barracks": {
		"id": "barracks",
		"name": "ثكنات المشاة",
		"code": "[ BARRACKS // ثكنة ]",
		"structure": "barracks",
		"units": ["infantry_rifle", "infantry_at", "engineer", "infantry_mortar"]
	},
	"war_factory": {
		"id": "war_factory",
		"name": "مصنع المدرعات",
		"code": "[ FACTORY // مدرعات ]",
		"structure": "war_factory",
		"units": ["scout", "tank", "behemoth"]
	},
	"airfield": {
		"id": "airfield",
		"name": "المطار العسكري",
		"code": "[ AIRFIELD // سلاح الجو ]",
		"structure": "airfield",
		"units": ["jet_interceptor", "strike_bomber", "helicopter"]
	},
	"shipyard": {
		"id": "shipyard",
		"name": "حوض السفن النهري",
		"code": "[ SHIPYARD // أسطول نهري ]",
		"structure": "shipyard",
		"units": ["patrol_boat", "missile_corvette", "river_gunboat"]
	},
	"missile_plant": {
		"id": "missile_plant",
		"name": "مجمع الصواريخ",
		"code": "[ MISSILES // راجمات ]",
		"structure": "missile_plant",
		"units": ["artillery", "sam_launcher"]
	}
}

const VETERANCY_RANKS: Array[Dictionary] = [
	{ "rank": 0, "xpRequired": 0, "damageMultiplier": 1.0, "hpMultiplier": 1.0, "healPerSec": 0.0, "badgeLabel": "" },
	{ "rank": 1, "xpRequired": 100, "damageMultiplier": 1.18, "hpMultiplier": 1.15, "healPerSec": 0.0, "badgeLabel": "VET" },
	{ "rank": 2, "xpRequired": 240, "damageMultiplier": 1.38, "hpMultiplier": 1.32, "healPerSec": 1.5, "badgeLabel": "ELITE" },
	{ "rank": 3, "xpRequired": 450, "damageMultiplier": 1.6, "hpMultiplier": 1.55, "healPerSec": 3.5, "badgeLabel": "ACE" },
]

const XP_PER_DAMAGE: float = 0.28
const XP_KILL_LIGHT: float = 45.0
const XP_KILL_HEAVY: float = 85.0
const XP_BRIDGE_DEMOLISH: float = 70.0

const COMMANDER_POWERS: Dictionary = {
	"airstrike": {
		"id": "airstrike",
		"name": "غارة صقر النفاثة",
		"hotkey": "Z",
		"cost": 160,
		"cooldown": 26.0,
		"radius": 95.0,
		"damage": 170.0,
		"desc": "غارة جوية نفاثة خارقة للدروع تقصف موقع الهدف بوابل قنابل موجهة."
	},
	"artillery_barrage": {
		"id": "artillery_barrage",
		"name": "قصف تمهيدي",
		"hotkey": "X",
		"cost": 125,
		"cooldown": 22.0,
		"radius": 125.0,
		"damage": 85.0,
		"desc": "قصف صاروخي مكثف من خارج الخريطة يغطي منطقة واسعة لتطهير التحصينات."
	},
	"recon_drone": {
		"id": "recon_drone",
		"name": "مسح استطلاع تكتيكي",
		"hotkey": "C",
		"cost": 65,
		"cooldown": 18.0,
		"radius": 220.0,
		"duration": 14.0,
		"desc": "طائرة استطلاع تكشف التحركات وتزيد دقة وقوة ضربات القوات بنسبة 25%."
	},
	"supply_drop": {
		"id": "supply_drop",
		"name": "إنزال إمداد عاجل",
		"hotkey": "V",
		"cost": 90,
		"cooldown": 30.0,
		"oil_yield": 160,
		"desc": "إسقاط براميل وقود خام بالمظلات مباشرة في الميدان لإنعاش خطوط القتال."
	}
}

const DIRECTIVES_LIST: Array[Dictionary] = [
	{
		"id": "capture_rig",
		"title": "السيطرة على حقل نفط أمامي",
		"desc": "قم بالسيطرة على بئر نفط غير محرر لتأمين خط إمداد إضافي لقواتك.",
		"reward_oil": 75,
		"target_count": 1
	},
	{
		"id": "ambush_truck",
		"title": "نصب كمين لقافلة وقود العدو",
		"desc": "اعترض ودمر شاحنة إمداد معادية واغتنم براميل النفط المتساقطة.",
		"reward_oil": 65,
		"target_count": 1
	},
	{
		"id": "rebuild_bridge",
		"title": "ترميم جسر استراتيجي حيوي",
		"desc": "أرسل مهندساً حربياً لإصلاح أحد الجسور المنهارة وفتح ممر إمداد جديد.",
		"reward_oil": 80,
		"target_count": 1
	},
	{
		"id": "promote_veteran",
		"title": "ترقية وحدة إلى رتبة نخبة",
		"desc": "شارك في الاشتباكات وحقق انتصارات ميدانية لترقية وحدة إلى رتبة ضابط.",
		"reward_oil": 60,
		"target_count": 1
	},
	{
		"id": "destroy_heavy",
		"title": "تدمير آلية ثقيلة للعدو",
		"desc": "استهدف ودمر دبابة قتالية أو راجمة صواريخ للعدو لكسر هجومه.",
		"reward_oil": 70,
		"target_count": 1
	}
]

const THEATER_PALETTES: Dictionary = {
	"kirkuk": {
		"groundA": Color("#9d8258"),
		"groundB": Color("#8e744c"),
		"groundDetail": Color("#7a613c"),
		"concrete": Color("#777166"),
		"oilfield": Color("#4d4132"),
		"waterDeep": Color("#224a5e"),
		"waterShallow": Color("#2d5f74"),
		"waterFoam": Color("#6397a8"),
		"roadAsphalt": Color("#3b3936"),
		"roadEdge": Color("#5b5244"),
		"roadStripe": Color("#c9a45c"),
		"bridgeDeck": Color("#5e5a52"),
		"bridgeSteel": Color("#8d877a"),
		"rockTop": Color("#b49667"),
		"rockFace": Color("#523f2a"),
		"rockShadow": Color("#302417"),
		"ford": Color("#326177")
	},
	"suez": {
		"groundA": Color("#b4986a"),
		"groundB": Color("#a68b5e"),
		"groundDetail": Color("#8c7249"),
		"concrete": Color("#827e74"),
		"oilfield": Color("#584c3a"),
		"waterDeep": Color("#175267"),
		"waterShallow": Color("#1f6c82"),
		"waterFoam": Color("#6bb0bf"),
		"roadAsphalt": Color("#3e3d3b"),
		"roadEdge": Color("#6b604e"),
		"roadStripe": Color("#d4b46b"),
		"bridgeDeck": Color("#63605a"),
		"bridgeSteel": Color("#9ea39d"),
		"rockTop": Color("#c9aa76"),
		"rockFace": Color("#5a442d"),
		"rockShadow": Color("#3a2a1a"),
		"ford": Color("#27758e")
	},
	"newyork": {
		"groundA": Color("#54614d"),
		"groundB": Color("#4a5743"),
		"groundDetail": Color("#3c4736"),
		"concrete": Color("#696d70"),
		"oilfield": Color("#3e4244"),
		"waterDeep": Color("#1c364d"),
		"waterShallow": Color("#264863"),
		"waterFoam": Color("#6288a3"),
		"roadAsphalt": Color("#323539"),
		"roadEdge": Color("#52575e"),
		"roadStripe": Color("#d4b44b"),
		"bridgeDeck": Color("#525963"),
		"bridgeSteel": Color("#8d99a6"),
		"rockTop": Color("#677561"),
		"rockFace": Color("#313a2d"),
		"rockShadow": Color("#1d231b"),
		"ford": Color("#2b5372")
	},
	"basra": {
		"groundA": Color("#927b58"),
		"groundB": Color("#826d4c"),
		"groundDetail": Color("#6e5a3c"),
		"concrete": Color("#757065"),
		"oilfield": Color("#473c2e"),
		"waterDeep": Color("#1b4d5e"),
		"waterShallow": Color("#276378"),
		"waterFoam": Color("#589cb3"),
		"roadAsphalt": Color("#353330"),
		"roadEdge": Color("#524a3c"),
		"roadStripe": Color("#c49f54"),
		"bridgeDeck": Color("#545048"),
		"bridgeSteel": Color("#837d70"),
		"rockTop": Color("#a88b5c"),
		"rockFace": Color("#4a3924"),
		"rockShadow": Color("#2a1f13"),
		"ford": Color("#2c677c")
	},
	"zagros": {
		"groundA": Color("#8f7a62"),
		"groundB": Color("#7e6b54"),
		"groundDetail": Color("#695742"),
		"concrete": Color("#6e6961"),
		"oilfield": Color("#42382c"),
		"waterDeep": Color("#284b5c"),
		"waterShallow": Color("#335f73"),
		"waterFoam": Color("#6299ad"),
		"roadAsphalt": Color("#32312f"),
		"roadEdge": Color("#4d463b"),
		"roadStripe": Color("#bf9d58"),
		"bridgeDeck": Color("#4f4c45"),
		"bridgeSteel": Color("#7a756b"),
		"rockTop": Color("#a38865"),
		"rockFace": Color("#443525"),
		"rockShadow": Color("#261c13"),
		"ford": Color("#386377")
	}
}

const MOMENTUM_MAX: float = 100.0
const SURGE_DURATION: float = 14.0

const VETERAN_ABILITIES: Dictionary = {
	"tank": {
		"id": "incendiary_shot",
		"name": "قذيفة خارقة حارقة",
		"hotkey": "F",
		"min_rank": 2,
		"cooldown": 9.0,
		"damage": 85.0,
		"napalm_radius": 40.0,
		"napalm_duration": 6.0,
		"desc": "تطلق قذيفة خارقة فائقة السرعة تترك منطقة حارقة تسحق المشاة وتذيب دروع الآليات."
	},
	"behemoth": {
		"id": "seismic_barrage",
		"name": "وابل الحصار الزلزالي",
		"hotkey": "F",
		"min_rank": 2,
		"cooldown": 14.0,
		"damage": 120.0,
		"stun_radius": 85.0,
		"stun_duration": 2.8,
		"desc": "قصف مدفعي مزدوج عنيف يحدث زلزالاً يشل حركة آليات العدو القريبة ويلحق بها أضراراً بالغة."
	},
	"helicopter": {
		"id": "hydra_salvo",
		"name": "غارة صواريخ هايدرا",
		"hotkey": "F",
		"min_rank": 2,
		"cooldown": 8.0,
		"damage": 30.0, # per rocket (4 rockets = 120 dmg)
		"rocket_count": 4,
		"desc": "إطلاق رشقة من 4 صواريخ هايدرا موجهة لولبياً تسحق الهدف بضربات متتالية."
	},
	"engineer": {
		"id": "deploy_landmine",
		"name": "زرع لغم مضاد للدروع",
		"hotkey": "T",
		"min_rank": 0,
		"cost": 25,
		"cooldown": 5.0,
		"damage": 190.0,
		"stun_duration": 4.5,
		"desc": "يزرع لغماً أرضياً ثقيلاً على الطريق ينفجر عند مرور آليات العدو مشلاً حركتها بالكامل."
	}
}

const AIRDROP_TYPES: Dictionary = {
	"nano_repair": {
		"id": "nano_repair",
		"title": "نانو الصيانة والخبرة التكتيكية",
		"icon": "[REPAIR]",
		"color": Color("#38bdf8"),
		"desc": "يصلح فوراً كافة آليات الفصيل القريبة إلى 100% ويمنحها +120 نقطة خبرة!"
	},
	"fuel_cache": {
		"id": "fuel_cache",
		"title": "مخزون وقود استراتيجي عاجل",
		"icon": "[SUPPLY]",
		"color": Color("#facc15"),
		"oil": 240,
		"desc": "يمنح الفصيل فوراً +240 برميل نفط لدعم العمليات الحربية المكثفة!"
	},
	"armor_reinforce": {
		"id": "armor_reinforce",
		"title": "دعم مدرع فوري من النخبة",
		"icon": "[ARMOR]",
		"color": Color("#84cc16"),
		"unit_kind": "tank",
		"unit_rank": 2,
		"desc": "إنزال فوري لدبابة قتالية من رتبة النخبة جاهزة للاشتباك الميداني!"
	}
}

