class_name RenderAtmosphere
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

# Directional Sun Shadow Vector (South-East 45-degree angle)
const SUN_DIR: Vector2 = Vector2(0.7071, 0.7071)
const SHADOW_COLOR: Color = Color(0.04, 0.05, 0.06, 0.40)
const HEAVY_SHADOW_COLOR: Color = Color(0.02, 0.03, 0.04, 0.48)

static func draw_directional_structure_shadows(canvas: CanvasItem, structures: Array, view_rect: Rect2) -> void:
	for s in structures:
		var pos = Vector2(s["x"], s["y"])
		if not view_rect.has_point(pos):
			continue
			
		var spec = Constants.BUILDING_SPECS.get(s["kind"], {})
		var w = spec.get("width", s["radius"] * 2.0)
		var h = spec.get("height", s["radius"] * 2.0)
		var shadow_offset = SUN_DIR * 12.0
		
		# Skewed isometric shadow polygon
		var p1 = pos + shadow_offset + Vector2(-w * 0.5, -h * 0.2)
		var p2 = pos + shadow_offset + Vector2(w * 0.5, -h * 0.2)
		var p3 = pos + shadow_offset + Vector2(w * 0.6, h * 0.5)
		var p4 = pos + shadow_offset + Vector2(-w * 0.4, h * 0.5)
		
		canvas.draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), HEAVY_SHADOW_COLOR)

static func draw_directional_unit_shadows(canvas: CanvasItem, units: Array, view_rect: Rect2) -> void:
	for u in units:
		if not u.get("alive", false):
			continue
		var pos = Vector2(u["x"], u["y"])
		if not view_rect.has_point(pos):
			continue
			
		var is_air = (u["kind"] == "helicopter")
		var shadow_offset = SUN_DIR * (28.0 if is_air else 6.0)
		var rad = float(u["radius"])
		var col = Color(0.03, 0.04, 0.05, 0.28 if is_air else 0.42)
		
		# Soft directional oval shadow
		var shadow_pos = pos + shadow_offset
		var aspect_rad = Vector2(rad * 1.15, rad * 0.75)
		
		# Draw squashed shadow ellipse
		var points = PackedVector2Array()
		var segs = 12
		for i in range(segs):
			var a = float(i) * TAU / float(segs)
			points.push_back(shadow_pos + Vector2(cos(a) * aspect_rad.x, sin(a) * aspect_rad.y))
		canvas.draw_colored_polygon(points, col)

static func draw_theater_atmosphere(canvas: CanvasItem, theater: String, sim_time: float, view_rect: Rect2) -> void:
	# 1. Subtle Color Grading Tint
	var tint_col: Color
	match theater:
		"kirkuk":
			tint_col = Color(1.0, 0.94, 0.82, 0.04) # Warm sunlit desert
		"suez":
			tint_col = Color(0.85, 0.95, 1.0, 0.04) # Maritime coastal blue
		"newyork":
			tint_col = Color(0.82, 0.85, 0.90, 0.05) # Cool urban gray
		"basra":
			tint_col = Color(1.0, 0.90, 0.76, 0.05) # Marshland golden afternoon
		"zagros":
			tint_col = Color(0.88, 0.92, 1.0, 0.04) # Crisp alpine mountain
		_:
			tint_col = Color(1.0, 0.95, 0.85, 0.04)
			
	canvas.draw_rect(view_rect, tint_col)

	# 2. Drifting Dust Motes & Atmospheric Wind Streaks in Desert Theaters
	if theater in ["kirkuk", "basra", "zagros"]:
		var dust_col = Color(0.95, 0.88, 0.72, 0.18)
		for i in range(16):
			var seed_i = float(i * 137)
			var cycle = fmod(sim_time * 65.0 + seed_i, 800.0)
			var dx = view_rect.position.x + fmod(seed_i * 71.0 + cycle, view_rect.size.x)
			var dy = view_rect.position.y + fmod(seed_i * 93.0 + sin(sim_time * 0.8 + seed_i) * 35.0, view_rect.size.y)
			
			canvas.draw_line(Vector2(dx, dy), Vector2(dx + 16.0, dy + 4.0), dust_col, 1.0)
