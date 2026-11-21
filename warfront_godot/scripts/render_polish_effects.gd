class_name RenderPolishEffects
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func draw_dynamic_muzzle_lights(canvas: CanvasItem, units: Array) -> void:
	for u in units:
		if not u.get("alive", false) or u.get("recoil", 0.0) <= 0.08:
			continue
			
		var pos = Vector2(u["x"], u["y"])
		var ang = u.get("turretAngle", u.get("angle", 0.0))
		var fwd = Vector2(cos(ang), sin(ang))
		var r = u.get("radius", 16.0)
		var flash_pos = pos + fwd * (r * 1.2)
		var flash_radius = 42.0 * (u["recoil"] / 0.4)
		
		# Radial ground illumination
		canvas.draw_circle(flash_pos, flash_radius, Color(1.0, 0.85, 0.4, 0.22))
		canvas.draw_circle(flash_pos, flash_radius * 0.45, Color(1.0, 0.95, 0.8, 0.35))

static func draw_drag_to_face_arrow(canvas: CanvasItem, font: Font, start: Vector2, end: Vector2, sim_time: float) -> void:
	var diff = end - start
	if diff.length() < 14.0:
		return
		
	var facing_angle = diff.angle()
	var fwd = Vector2(cos(facing_angle), sin(facing_angle))
	var nrm = Vector2(-fwd.y, fwd.x)
	var arrow_col = Color("#38bdf8")
	
	# Main direction arrow
	canvas.draw_line(start, end, arrow_col, 2.5)
	var arrow_head_1 = end - fwd * 14.0 + nrm * 8.0
	var arrow_head_2 = end - fwd * 14.0 - nrm * 8.0
	canvas.draw_line(end, arrow_head_1, arrow_col, 2.5)
	canvas.draw_line(end, arrow_head_2, arrow_col, 2.5)
	
	# Transverse line showing squad combat facing
	var line_len = 65.0
	canvas.draw_line(start - nrm * line_len, start + nrm * line_len, Color(0.2, 0.8, 1.0, 0.5), 2.0)
	canvas.draw_string(font, end + Vector2(10, 4), "[ COMBAT FACING // اتجاه الانتشار والمواجهة ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#38bdf8"))

static func draw_building_damage_state(canvas: CanvasItem, s: Dictionary, sim_time: float) -> void:
	var cur_hp: float = s.get("hp", 100.0)
	var max_hp: float = s.get("maxHp", 100.0)
	var ratio = cur_hp / max(1.0, max_hp)
	if ratio >= 0.50:
		return
		
	var pos = Vector2(s["x"], s["y"])
	var w = s.get("width", 50.0)
	var h = s.get("height", 50.0)
	
	# Red warning beacon on heavily damaged structures
	if ratio < 0.25:
		var beacon_flicker = 0.5 + sin(sim_time * 12.0) * 0.5
		canvas.draw_circle(pos + Vector2(0, -h * 0.4), 4.5, Color(1.0, 0.1, 0.1, beacon_flicker))
		# Structural fracture crack decals
		canvas.draw_line(pos - Vector2(w * 0.2, h * 0.2), pos + Vector2(w * 0.1, h * 0.1), Color("#0a0a0c"), 2.0)
		canvas.draw_line(pos + Vector2(w * 0.1, h * 0.1), pos + Vector2(w * 0.25, 0), Color("#0a0a0c"), 1.8)
