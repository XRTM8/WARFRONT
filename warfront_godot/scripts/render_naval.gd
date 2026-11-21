class_name RenderNaval
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func draw_naval_unit(canvas: CanvasItem, u: Dictionary, pos: Vector2, u_color: Color, sim_time: float) -> bool:
	var kind = u.get("kind", "")
	if not u.get("is_naval", false):
		return false
		
	var angle = u.get("angle", 0.0)
	var radius = u.get("radius", 16.0)
	var fwd = Vector2(cos(angle), sin(angle))
	var nrm = Vector2(-fwd.y, fwd.x)
	var hull_col = Color("#1e293b")
	var deck_col = Color("#334155")
	
	# 1. Hydrodynamic Water Wake & Bow Spray
	_draw_boat_wakes(canvas, pos, fwd, nrm, radius, sim_time)
	
	if kind == "patrol_boat":
		# Sleek fast patrol boat with pointed bow
		var bow = pos + fwd * (radius * 1.25)
		var stern_l = pos - fwd * (radius * 0.9) - nrm * (radius * 0.6)
		var stern_r = pos - fwd * (radius * 0.9) + nrm * (radius * 0.6)
		var mid_l = pos - nrm * (radius * 0.65)
		var mid_r = pos + nrm * (radius * 0.65)
		
		var pts = PackedVector2Array([bow, mid_r, stern_r, stern_l, mid_l])
		canvas.draw_colored_polygon(pts, hull_col)
		canvas.draw_polyline(PackedVector2Array([bow, mid_r, stern_r, stern_l, mid_l, bow]), u_color, 1.8)
		
		# Wheelhouse cabin
		canvas.draw_rect(Rect2(pos.x - 4, pos.y - 3, 8, 6), deck_col)
		# Dual 12.7mm bow gun
		var gun_pos = pos + fwd * (radius * 0.5)
		canvas.draw_line(gun_pos, gun_pos + fwd * 8.0, Color("#f8fafc"), 2.0)
		return true
		
	elif kind == "missile_corvette":
		# Faceted angled stealth warship hull
		var bow = pos + fwd * (radius * 1.35)
		var bow_notch_l = pos + fwd * (radius * 0.6) - nrm * (radius * 0.75)
		var bow_notch_r = pos + fwd * (radius * 0.6) + nrm * (radius * 0.75)
		var stern_l = pos - fwd * (radius * 1.0) - nrm * (radius * 0.75)
		var stern_r = pos - fwd * (radius * 1.0) + nrm * (radius * 0.75)
		
		var pts = PackedVector2Array([bow, bow_notch_r, stern_r, stern_l, bow_notch_l])
		canvas.draw_colored_polygon(pts, hull_col)
		canvas.draw_polyline(PackedVector2Array([bow, bow_notch_r, stern_r, stern_l, bow_notch_l, bow]), u_color, 2.0)
		
		# Twin missile canister pods on aft deck
		for offset_side in [-3.5, 3.5]:
			var pod_pos = pos - fwd * (radius * 0.35) + nrm * offset_side
			canvas.draw_rect(Rect2(pod_pos.x - 3, pod_pos.y - 2, 6, 4), Color("#0f172a"))
			canvas.draw_circle(pod_pos + fwd * 3.0, 1.5, Color("#ef4444"))
			
		# Radar bridge mast
		canvas.draw_circle(pos + fwd * 2.0, 3.5, Color("#38bdf8"))
		return true
		
	elif kind == "river_gunboat":
		# Heavy armored river monitor with rotating naval turret
		var bow = pos + fwd * (radius * 1.2)
		var stern_l = pos - fwd * (radius * 1.1) - nrm * (radius * 0.85)
		var stern_r = pos - fwd * (radius * 1.1) + nrm * (radius * 0.85)
		var pts = PackedVector2Array([bow, pos + nrm * (radius * 0.85), stern_r, stern_l, pos - nrm * (radius * 0.85)])
		canvas.draw_colored_polygon(pts, Color("#18181b"))
		canvas.draw_polyline(PackedVector2Array([bow, pos + nrm * (radius * 0.85), stern_r, stern_l, pos - nrm * (radius * 0.85), bow]), u_color, 2.2)
		
		# Rotating naval gun turret
		var t_ang = u.get("turretAngle", angle)
		var t_fwd = Vector2(cos(t_ang), sin(t_ang))
		var turret_pos = pos + fwd * (radius * 0.2)
		canvas.draw_circle(turret_pos, radius * 0.45, Color("#27272a"))
		canvas.draw_circle(turret_pos, radius * 0.45, u_color, false, 1.5)
		# Long 105mm naval cannon with muzzle brake
		var recoil_offset = -t_fwd * (u.get("recoil", 0.0) * 4.0)
		var barrel_end = turret_pos + recoil_offset + t_fwd * (radius * 1.1)
		canvas.draw_line(turret_pos, barrel_end, Color("#e4e4e7"), 3.0)
		canvas.draw_circle(barrel_end, 2.5, Color("#71717a")) # Muzzle brake
		return true
		
	return false

static func _draw_boat_wakes(canvas: CanvasItem, pos: Vector2, fwd: Vector2, nrm: Vector2, radius: float, sim_time: float) -> void:
	# V-shaped foaming bow waves
	var bow = pos + fwd * (radius * 0.9)
	var wave_alpha = 0.35 + sin(sim_time * 5.0) * 0.12
	var wave_col = Color(0.7, 0.9, 1.0, wave_alpha)
	
	# Left & right spreading wake lines
	var wake_l = pos - fwd * (radius * 1.4) - nrm * (radius * 1.1)
	var wake_r = pos - fwd * (radius * 1.4) + nrm * (radius * 1.1)
	canvas.draw_line(bow, wake_l, wave_col, 1.5)
	canvas.draw_line(bow, wake_r, wave_col, 1.5)
	
	# Stern engine wash
	var stern = pos - fwd * radius
	canvas.draw_circle(stern, 4.0 + sin(sim_time * 8.0) * 1.5, Color(1.0, 1.0, 1.0, wave_alpha * 0.8))
