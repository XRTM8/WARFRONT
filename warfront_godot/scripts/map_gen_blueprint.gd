class_name MapGenBlueprint
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

const THEATER_BLUEPRINTS: Dictionary = {
	"kirkuk": {
		"id": "kirkuk",
		"name": "وادي كركوك النفطي (Kirkuk Valley)",
		"archetype": "river_divide",
		"symmetry": "rotational_180",
		"cols": 72,
		"rows": 40,
		"rig_count": 8,
		"bridge_count": 4,
		"palette": "kirkuk",
		"desc": "مسرح 1v1 كلاسيكي: نهر وسطي يقسم الميدان مع 4 جسور ومخاضات تكتيكية."
	},
	"suez": {
		"id": "suez",
		"name": "قناة السويس البحرية (Suez Canal)",
		"archetype": "coastal_highway",
		"symmetry": "rotational_180",
		"cols": 72,
		"rows": 40,
		"rig_count": 8,
		"bridge_count": 4,
		"palette": "suez",
		"desc": "ممر بحري مع شريان لوجستي ساحلي وتنافس شرس على خطوط الإمداد."
	},
	"newyork": {
		"id": "newyork",
		"name": "جبهة نيويورك النهرية (New York Front)",
		"archetype": "river_divide",
		"symmetry": "rotational_180",
		"cols": 72,
		"rows": 40,
		"rig_count": 8,
		"bridge_count": 4,
		"palette": "newyork",
		"desc": "مضايق خرسانية وأرصفة صناعية متفرعة مع سرعة اشتباك عالية."
	},
	"basra": {
		"id": "basra",
		"name": "دلتا البصرة الكبرى (Basra Delta)",
		"archetype": "delta_archipelago",
		"symmetry": "radial_4way",
		"cols": 100,
		"rows": 60,
		"rig_count": 6,
		"bridge_count": 4,
		"palette": "basra",
		"desc": "مسرح عمليات عملاق 4800x2880 لـ 4 مقرات في الزوايا مع جزر دلتا متقاطعة."
	},
	"zagros": {
		"id": "zagros",
		"name": "حوض مضايق زاغروس (Zagros Pass)",
		"archetype": "canyon_pass",
		"symmetry": "radial_4way",
		"cols": 100,
		"rows": 60,
		"rig_count": 6,
		"bridge_count": 4,
		"palette": "zagros",
		"desc": "حوض صخري جبلي 4800x2880 مع ممرات خنق حربية محاطة بالجروف."
	},
	"canyon_pass_1v1": {
		"id": "canyon_pass_1v1",
		"name": "ممر الخنق الجبلي (Canyon Chokepoints)",
		"archetype": "canyon_pass",
		"symmetry": "rotational_180",
		"cols": 72,
		"rows": 40,
		"rig_count": 8,
		"bridge_count": 3,
		"palette": "zagros",
		"desc": "ممرات جبلية حجرية ضيقة تفصل بين القواعد مع مرتفعات التفافية للقناصة."
	},
	"central_plateau_1v1": {
		"id": "central_plateau_1v1",
		"name": "هضبة النزاع الكبرى (Central Plateau)",
		"archetype": "central_plateau",
		"symmetry": "rotational_180",
		"cols": 72,
		"rows": 40,
		"rig_count": 8,
		"bridge_count": 4,
		"palette": "kirkuk",
		"desc": "هضبة صخرية مرتفعة في قلب الخريطة تضم أكبر ثروة نفطية محاطة بوادٍ دائري."
	}
}

static func get_blueprint(theater_id: String) -> Dictionary:
	if THEATER_BLUEPRINTS.has(theater_id):
		return THEATER_BLUEPRINTS[theater_id]
	return THEATER_BLUEPRINTS["kirkuk"]

static func transform_rotational_180(pos: Vector2, width: float, height: float) -> Vector2:
	return Vector2(width - pos.x, height - pos.y)

static func transform_mirror_x(pos: Vector2, width: float) -> Vector2:
	return Vector2(width - pos.x, pos.y)
