class_name RenderAircraft
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func draw_air_or_special_unit(canvas: CanvasItem, u: Dictionary, pos: Vector2, u_color: Color, sim_time: float) -> bool:
	var kind = u.get("kind", "")
	var angle = u.get("angle", 0.0)
	var radius = u.get("radius", 16.0)
	var fwd = Vector2(cos(angle), sin(angle))
	var nrm = Vector2(-fwd.y, fwd.x)
	
	if kind == "jet_interceptor":
		# 1. 45-degree High-Altitude Ground Shadow
		var shadow_offset = Vector2(24.0, 24.0)
		_draw_jet_shape(canvas, pos + shadow_offset, fwd, nrm, radius, Color(0.04, 0.04, 0.04, 0.42), Color.TRANSPARENT)
		# 2. Main Jet Aircraft Body
		_draw_jet_shape(canvas, pos, fwd, nrm, radius, Color("#1e293b"), u_color)
		# 3. Cockpit Canopy & Twin Canards
		canvas.draw_circle(pos + fwd * 4.0, 3.2, Color("#38bdf8"))
		# 4. Afterburner Exhaust Flame
		var flame_len = 8.0 + sin(sim_time * 28.0) * 3.5
		var tail = pos - fwd * (radius * 1.1)
		canvas.draw_line(tail, tail - fwd * flame_len, Color("#00f0ff"), 3.0)
		canvas.draw_line(tail, tail - fwd * (flame_len * 0.6), Color("#ffffff"), 1.8)
		return true
		
	elif kind == "strike_bomber":
		# 1. Ground Shadow
		var shadow_offset = Vector2(30.0, 30.0)
		_draw_bomber_shape(canvas, pos + shadow_offset, fwd, nrm, radius, Color(0.04, 0.04, 0.04, 0.45), Color.TRANSPARENT)
		# 2. Heavy Stealth Flying Wing
		_draw_bomber_shape(canvas, pos, fwd, nrm, radius, Color("#18181b"), u_color)
		# 3. Payload Bomb Bay Doors
		canvas.draw_rect(Rect2(pos.x - 4, pos.y - 3, 8, 6), Color("#27272a"))
		canvas.draw_line(pos - nrm * 3, pos + nrm * 3, Color("#ef4444"), 1.5)
		return true
		
	elif kind == "sam_launcher":
		# Tracked vehicle chassis with quad SAM missiles
		canvas.draw_rect(Rect2(pos.x - radius * 0.8, pos.y - radius * 0.65, radius * 1.6, radius * 1.3), Color("#18181b"))
		canvas.draw_rect(Rect2(pos.x - radius * 0.8, pos.y - radius * 0.65, radius * 1.6, radius * 1.3), u_color, false, 2.0)
		# Quad missile rack
		var t_ang = u.get("turretAngle", angle)
		var t_fwd = Vector2(cos(t_ang), sin(t_ang))
		var t_nrm = Vector2(-t_fwd.y, t_fwd.x)
		for ox in [-4, 4]:
			for oy in [-3, 3]:
				var mp = pos + t_fwd * 2.0 + t_nrm * ox + t_fwd * oy
				canvas.draw_line(mp - t_fwd * 6.0, mp + t_fwd * 8.0, Color("#f8fafc"), 2.2)
				canvas.draw_circle(mp + t_fwd * 8.0, 1.8, Color("#ef4444")) # Red seeker cone
		return true
		
	elif kind in ["infantry_rifle", "infantry_at", "infantry_mortar"]:
		_draw_infantry_squad(canvas, u, pos, u_color, kind, sim_time)
		return true
		
	return false

static func _draw_jet_shape(canvas: CanvasItem, p: Vector2, fwd: Vector2, nrm: Vector2, r: float, body_col: Color, edge_col: Color) -> void:
	var nose = p + fwd * (r * 1.4)
	var wing_l = p - fwd * (r * 0.4) - nrm * (r * 1.25)
	var wing_r = p - fwd * (r * 0.4) + nrm * (r * 1.25)
	var tail_l = p - fwd * (r * 1.1) - nrm * (r * 0.45)
	var tail_r = p - fwd * (r * 1.1) + nrm * (r * 0.45)
	var tail_c = p - fwd * (r * 0.9)
	
	var pts = PackedVector2Array([nose, wing_r, tail_r, tail_c, tail_l, wing_l])
	canvas.draw_colored_polygon(pts, body_col)
	if edge_col.a > 0.0:
		canvas.draw_polyline(PackedVector2Array([nose, wing_r, tail_r, tail_c, tail_l, wing_l, nose]), edge_col, 1.8)

static func _draw_bomber_shape(canvas: CanvasItem, p: Vector2, fwd: Vector2, nrm: Vector2, r: float, body_col: Color, edge_col: Color) -> void:
	var nose = p + fwd * (r * 1.1)
	var wing_l = p - fwd * (r * 0.7) - nrm * (r * 1.8)
	var wing_r = p - fwd * (r * 0.7) + nrm * (r * 1.8)
	var notch_l = p - fwd * (r * 0.9) - nrm * (r * 0.8)
	var notch_r = p - fwd * (r * 0.9) + nrm * (r * 0.8)
	var tail_tip = p - fwd * (r * 0.5)
	
	var pts = PackedVector2Array([nose, wing_r, notch_r, tail_tip, notch_l, wing_l])
	canvas.draw_colored_polygon(pts, body_col)
	if edge_col.a > 0.0:
		canvas.draw_polyline(PackedVector2Array([nose, wing_r, notch_r, tail_tip, notch_l, wing_l, nose]), edge_col, 2.0)

static func _draw_infantry_squad(canvas: CanvasItem, u: Dictionary, pos: Vector2, u_color: Color, kind: String, sim_time: float) -> void:
	# 3-man squad formation
	var squad_offsets = [Vector2(0, -4), Vector2(-4, 3), Vector2(4, 3)]
	for i in range(3):
		var sp = pos + squad_offsets[i]
		# Helmet
		canvas.draw_circle(sp, 3.2, Color("#3f3f46"))
		canvas.draw_circle(sp, 2.2, u_color)
		# Weapon
		if kind == "infantry_at" and i == 0:
			canvas.draw_line(sp, sp + Vector2(6, -2), Color("#18181b"), 2.0) # RPG tube
		elif kind == "infantry_mortar" and i == 0:
			canvas.draw_circle(sp + Vector2(3, 0), 2.0, Color("#f59e0b")) # Mortar baseplate
		else:
			canvas.draw_line(sp, sp + Vector2(4, -1), Color("#27272a"), 1.5) # Assault rifle
