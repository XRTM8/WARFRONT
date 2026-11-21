class_name RenderFX
extends RefCounted

static func draw_tread_marks(canvas: CanvasItem, tread_marks: Array) -> void:
	for tm in tread_marks:
		var alpha = (tm["life"] / tm["maxLife"]) * 0.32
		canvas.draw_set_transform(Vector2(tm["x"], tm["y"]), tm["angle"], Vector2.ONE)
		# Dual continuous tracks
		canvas.draw_rect(Rect2(-8, -7, 16, 2.5), Color(0.16, 0.14, 0.11, alpha))
		canvas.draw_rect(Rect2(-8, 4.5, 16, 2.5), Color(0.16, 0.14, 0.11, alpha))
		# Intermediate tread track ridges
		canvas.draw_rect(Rect2(-6, -7, 2, 2.5), Color(0.08, 0.07, 0.05, alpha * 1.3))
		canvas.draw_rect(Rect2(2, -7, 2, 2.5), Color(0.08, 0.07, 0.05, alpha * 1.3))
		canvas.draw_rect(Rect2(-6, 4.5, 2, 2.5), Color(0.08, 0.07, 0.05, alpha * 1.3))
		canvas.draw_rect(Rect2(2, 4.5, 2, 2.5), Color(0.08, 0.07, 0.05, alpha * 1.3))
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

static func draw_craters(canvas: CanvasItem, craters: Array) -> void:
	for c in craters:
		var pos = Vector2(c["x"], c["y"])
		var r = c["radius"]
		if c.get("oilSlick", false):
			canvas.draw_set_transform(pos, c.get("angle", 0.0), Vector2(1.2, 0.8))
			# Outer thick crude oil spill
			canvas.draw_circle(Vector2.ZERO, r, Color(0.06, 0.05, 0.04, 0.85))
			canvas.draw_circle(Vector2(2, 1), r * 0.7, Color(0.11, 0.09, 0.07, 0.75))
			# Specular oil sheen highlights (multi-color reflection)
			canvas.draw_arc(Vector2.ZERO, r * 0.9, 0.0, PI * 1.4, 16, Color(0.22, 0.28, 0.32, 0.45), 2.0)
			canvas.draw_arc(Vector2(1, 1), r * 0.5, PI * 0.5, PI * 1.8, 12, Color(0.35, 0.25, 0.18, 0.35), 1.5)
			canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		else:
			canvas.draw_set_transform(pos, c.get("angle", 0.0), Vector2(1.1, 0.85))
			# Scorch pit
			canvas.draw_circle(Vector2.ZERO, r, Color(0.11, 0.09, 0.07, 0.65))
			canvas.draw_circle(Vector2.ZERO, r * 0.62, Color(0.06, 0.05, 0.04, 0.82))
			# Ejecta debris ring
			canvas.draw_arc(Vector2(0, 1), r * 0.85, PI * 0.2, PI * 0.8, 12, Color(0.25, 0.21, 0.16, 0.45), 1.8)
			canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

static func draw_wrecks(canvas: CanvasItem, wrecks: Array) -> void:
	for wrk in wrecks:
		var pos = Vector2(wrk["x"], wrk["y"])
		var alpha = min(1.0, wrk["life"] / 4.0)
		canvas.draw_set_transform(pos, wrk["angle"], Vector2.ONE)
		
		# Charred Shadow
		canvas.draw_circle(Vector2(2, 2), 16.0, Color(0, 0, 0, 0.4 * alpha))
		
		# Twisted Charred Chassis
		var c_burnt = Color(0.12, 0.11, 0.10, alpha)
		var c_rust = Color(0.24, 0.18, 0.14, alpha)
		var c_plate = Color(0.32, 0.28, 0.22, alpha)
		
		canvas.draw_rect(Rect2(-14, -10, 28, 20), c_burnt)
		canvas.draw_rect(Rect2(-12, -8, 24, 16), c_rust)
		canvas.draw_rect(Rect2(-10, -6, 20, 12), c_plate)
		
		# Blown-off Displaced Turret & Ruptured Barrel
		canvas.draw_circle(Vector2(3, -2), 7.0, c_burnt)
		canvas.draw_circle(Vector2(3, -2), 5.5, c_rust)
		canvas.draw_line(Vector2(3, -2), Vector2(18, -6), c_burnt, 2.5)
		
		# Torn Caterpillars / Tracks
		canvas.draw_line(Vector2(-14, -11), Vector2(12, -11), Color(0.1, 0.1, 0.09, alpha), 3.0)
		canvas.draw_line(Vector2(-12, 11), Vector2(14, 11), Color(0.1, 0.1, 0.09, alpha), 3.0)
		
		# Glowing Fire Embers
		if wrk["life"] > 8.0:
			var ember_flash = 0.5 + sin(Time.get_ticks_msec() * 0.012 + pos.x) * 0.5
			canvas.draw_circle(Vector2(-2, 1), 2.5, Color(1.0, 0.45, 0.1, ember_flash * alpha))
			canvas.draw_circle(Vector2(4, -1), 1.5, Color(1.0, 0.75, 0.2, ember_flash * alpha))
			
		canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

static func draw_order_pulse(canvas: CanvasItem, order_pulse: Dictionary) -> void:
	if order_pulse.is_empty():
		return
		
	var alpha = order_pulse["timer"] / 0.55
	var base_col: Color = order_pulse["color"]
	var pos = Vector2(order_pulse["x"], order_pulse["y"])
	var is_attack = order_pulse.get("type", "") == "attack"
	
	# Concentric Expanding Rings
	var r1 = 30.0 * (1.0 - alpha * 0.6)
	var r2 = 18.0 * (1.0 - alpha * 0.4)
	var col1 = Color(base_col.r, base_col.g, base_col.b, alpha * 0.85)
	var col2 = Color(base_col.r, base_col.g, base_col.b, alpha * 0.5)
	
	canvas.draw_arc(pos, r1, 0, TAU, 24, col1, 2.5)
	canvas.draw_arc(pos, r2, 0, TAU, 16, col2, 1.5)
	
	# 4-Tick Crosshair Reticle (Rotating)
	var rot = (1.0 - alpha) * 1.5
	for i in range(4):
		var ang = rot + float(i) * (PI * 0.5)
		var p_out = pos + Vector2(cos(ang), sin(ang)) * (r1 + 6.0)
		var p_in = pos + Vector2(cos(ang), sin(ang)) * (r1 - 4.0)
		canvas.draw_line(p_in, p_out, col1, 2.0)
		
	# Center Tactical Icon
	if is_attack:
		# Attack crosshair reticle
		canvas.draw_line(pos + Vector2(-6, 0), pos + Vector2(6, 0), col1, 2.0)
		canvas.draw_line(pos + Vector2(0, -6), pos + Vector2(0, 6), col1, 2.0)
	else:
		# Move chevron waypoint
		canvas.draw_line(pos + Vector2(-4, 3), pos + Vector2(0, -3), col1, 2.0)
		canvas.draw_line(pos + Vector2(0, -3), pos + Vector2(4, 3), col1, 2.0)

static func draw_tactical_waypoints(canvas: CanvasItem, units: Array, sim_time: float) -> void:
	for u in units:
		if not u.get("alive", false) or not u.get("selected", false) or u.get("faction", "") != "player":
			continue
		
		# 1. Waypoint movement trajectory lines & queued patrol paths
		var all_waypoints: Array[Vector2] = []
		if u.get("targetPos") != null:
			all_waypoints.push_back(u["targetPos"])
		for qp in u.get("waypointQueue", []):
			all_waypoints.push_back(qp)
			
		if all_waypoints.size() > 0:
			var path_points: Array[Vector2] = [Vector2(u["x"], u["y"])]
			path_points.append_array(all_waypoints)
			
			var is_atk = (u.get("stance", "") == "attack_move")
			var is_ret = (u.get("stance", "") == "retreat")
			var col = Color(0.95, 0.28, 0.28, 0.8) if is_atk else (Color(0.25, 0.75, 1.0, 0.8) if is_ret else Color(0.48, 0.92, 0.38, 0.75))
			
			for seg_idx in range(path_points.size() - 1):
				var start = path_points[seg_idx]
				var end = path_points[seg_idx + 1]
				var dist = start.distance_to(end)
				if dist > 8.0:
					var dir = (end - start).normalized()
					var dash_len = 7.0
					var gap_len = 5.0
					var offset = fmod(sim_time * 26.0, dash_len + gap_len)
					var cur = offset
					
					while cur < dist:
						var p1 = start + dir * cur
						var p2 = start + dir * min(cur + dash_len, dist)
						canvas.draw_line(p1, p2, col, 1.8)
						cur += dash_len + gap_len
						
					# Destination waypoint marker
					var pulse = 0.5 + 0.5 * sin(sim_time * 8.0 + float(seg_idx))
					canvas.draw_circle(end, 4.0, Color(col.r, col.g, col.b, 0.35))
					canvas.draw_arc(end, 5.5 + pulse * 1.5, 0, TAU, 14, col, 1.4)
					canvas.draw_line(end - Vector2(7, 0), end + Vector2(7, 0), col, 1.0)
					canvas.draw_line(end - Vector2(0, 7), end + Vector2(0, 7), col, 1.0)
					
					# Draw sequence number dot for queued waypoints
					if all_waypoints.size() > 1:
						canvas.draw_circle(end + Vector2(8, -8), 3.5, Color(0.08, 0.09, 0.07, 0.9))
						canvas.draw_arc(end + Vector2(8, -8), 3.5, 0, TAU, 10, col, 1.2)
				
		# 2. Target enemy attack vector line
		elif u.get("targetEntityId") != null:
			var tgt = null
			for other in units:
				if other["id"] == u["targetEntityId"] and other["alive"]:
					tgt = other
					break
			if tgt != null:
				var start = Vector2(u["x"], u["y"])
				var end = Vector2(tgt["x"], tgt["y"])
				var dist = start.distance_to(end)
				var dir = (end - start).normalized()
				var dash_len = 6.0
				var gap_len = 5.0
				var offset = fmod(sim_time * 28.0, dash_len + gap_len)
				var cur = offset
				var atk_col = Color(0.95, 0.3, 0.28, 0.85)
				
				while cur < dist:
					var p1 = start + dir * cur
					var p2 = start + dir * min(cur + dash_len, dist)
					canvas.draw_line(p1, p2, atk_col, 1.8)
					cur += dash_len + gap_len
				
				# Target attack reticle around enemy unit
				var r = tgt["radius"] + 5.0
				canvas.draw_arc(end, r, 0, TAU, 16, atk_col, 1.6)
				canvas.draw_line(end - Vector2(r + 4, 0), end + Vector2(r + 4, 0), atk_col, 1.2)
				canvas.draw_line(end - Vector2(0, r + 4), end + Vector2(0, r + 4), atk_col, 1.2)

static func draw_attack_move_reticle(canvas: CanvasItem, mouse_pos: Vector2, sim_time: float) -> void:
	var r = 16.0 + sin(sim_time * 12.0) * 2.0
	var col = Color("#ef4444")
	# Outer danger reticle ring
	canvas.draw_arc(mouse_pos, r, 0, TAU, 24, col, 2.0)
	canvas.draw_circle(mouse_pos, 3.0, Color.WHITE)
	# 4 Crosshair teeth
	for i in range(4):
		var ang = float(i) * PI * 0.5 + sim_time * 1.5
		var p_in = mouse_pos + Vector2(cos(ang), sin(ang)) * (r - 4.0)
		var p_out = mouse_pos + Vector2(cos(ang), sin(ang)) * (r + 7.0)
		canvas.draw_line(p_in, p_out, col, 2.5)

static func draw_projectile(canvas: CanvasItem, pr: Dictionary) -> void:
	var pos = Vector2(pr["x"], pr["y"])
	if pr["kind"] == "bullet":
		# High-velocity glowing tracer streak
		var v = Vector2(pr["vx"], pr["vy"])
		var tail = pos - v * 0.025
		canvas.draw_line(pos, tail, Color("#ffea79"), 2.5)
		canvas.draw_circle(pos, 2.0, Color.WHITE)
	elif pr["kind"] == "shell":
		var start_p = Vector2(pr.get("startX", pr["x"]), pr.get("startY", pr["y"]))
		var d_traveled = start_p.distance_to(pos)
		var total_d = max(1.0, pr.get("totalDist", 1.0))
		var progress = clamp(d_traveled / total_d, 0.0, 1.0)
		var height = sin(progress * PI) * 55.0

		# Ground Ballistic Drop Shadow
		canvas.draw_circle(pos, 4.0, Color(0.08, 0.07, 0.05, 0.45))
		
		# Elevated Artillery Shell with Fire Trail
		var shell_pos = Vector2(pos.x, pos.y - height)
		canvas.draw_rect(Rect2(shell_pos.x - 3.5, shell_pos.y - 3.5, 7, 7), Color("#fffbeb"))
		canvas.draw_circle(shell_pos, 3.0, Color("#f59e0b"))
		canvas.draw_line(shell_pos, shell_pos - Vector2(pr["vx"], pr["vy"]) * 0.035, Color("#ea580c"), 3.0)
	else:
		# Guided Rocket with Backblast Flame
		canvas.draw_circle(pos, 3.5, Color("#fbbf24"))
		canvas.draw_line(pos, pos - Vector2(pr["vx"], pr["vy"]) * 0.04, Color("#f97316"), 3.0)
		canvas.draw_line(pos, pos - Vector2(pr["vx"], pr["vy"]) * 0.08, Color(1, 1, 1, 0.4), 2.0)

static func draw_particles(canvas: CanvasItem, particles: Array) -> void:
	for pt in particles:
		if not pt["active"]:
			continue
		var progress = 1.0 - (pt["life"] / pt["maxLife"])
		var cur_size = pt["size"] + (pt["endSize"] - pt["size"]) * progress
		var col: Color = pt["color"]
		col.a = pt["alpha"] * (0.8 if pt["kind"] == "smoke" or pt["kind"] == "dust" else 0.98)
		var p_curr = Vector2(pt["x"], pt["y"])
		
		if pt["kind"] == "ring":
			var thickness = max(1.5, 4.0 * pt["alpha"])
			canvas.draw_arc(p_curr, cur_size, 0, TAU, 24, col, thickness)
		elif pt["kind"] == "spark":
			var v = Vector2(pt["vx"], pt["vy"])
			var streak_len = min(14.0, max(4.0, v.length() * 0.045))
			var p_tail = p_curr - v.normalized() * streak_len
			canvas.draw_line(p_curr, p_tail, col, 2.0)
		elif pt["kind"] == "casing":
			# Bouncing brass shell casing
			canvas.draw_rect(Rect2(p_curr.x - 1.5, p_curr.y - 0.75, 3.0, 1.5), col)
			canvas.draw_rect(Rect2(p_curr.x - 1.0, p_curr.y - 0.5, 1.5, 1.0), Color.WHITE)
		elif pt["kind"] == "dust":
			# Soft billowy desert sand cloud
			canvas.draw_circle(p_curr, cur_size * 0.5, col)
		elif pt["kind"] == "splash":
			# Water spray droplets
			canvas.draw_circle(p_curr, max(1.5, cur_size * 0.35), col)
		elif pt["kind"] == "smoke" or pt["kind"] == "fire":
			canvas.draw_circle(p_curr, cur_size * 0.5, col)
		else:
			var s = max(2.0, round(cur_size))
			canvas.draw_rect(Rect2(p_curr.x - s * 0.5, p_curr.y - s * 0.5, s, s), col)

static func draw_floating_popups(canvas: CanvasItem, default_font: Font, popups: Array) -> void:
	for fp in popups:
		var col: Color = fp["color"]
		col.a = min(1.0, fp["life"] / 0.45)
		var shadow_col = Color(0.04, 0.04, 0.03, col.a * 0.95)
		var txt = fp["text"]
		var p = Vector2(fp["x"] - 22.0, fp["y"])
		# Dual drop shadow for high contrast on desert sand
		canvas.draw_string(default_font, p + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, shadow_col)
		canvas.draw_string(default_font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, col)

static func draw_selection_box(canvas: CanvasItem, selection_box: Rect2, is_dragging: bool) -> void:
	if not is_dragging or selection_box.size.length() <= 4.0:
		return
		
	# Military Translucent Green Box
	canvas.draw_rect(selection_box, Color(0.3, 0.8, 0.25, 0.16), true)
	canvas.draw_rect(selection_box, Color(0.45, 0.92, 0.35, 0.85), false, 1.5)
	
	# Corner Reticle Brackets
	var c_len = min(12.0, min(abs(selection_box.size.x), abs(selection_box.size.y)) * 0.4)
	var b_col = Color("#a3e635")
	var r = selection_box.abs()
	
	# Top-Left
	canvas.draw_line(Vector2(r.position.x, r.position.y), Vector2(r.position.x + c_len, r.position.y), b_col, 2.5)
	canvas.draw_line(Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.position.y + c_len), b_col, 2.5)
	# Top-Right
	canvas.draw_line(Vector2(r.end.x, r.position.y), Vector2(r.end.x - c_len, r.position.y), b_col, 2.5)
	canvas.draw_line(Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.position.y + c_len), b_col, 2.5)
	# Bottom-Left
	canvas.draw_line(Vector2(r.position.x, r.end.y), Vector2(r.position.x + c_len, r.end.y), b_col, 2.5)
	canvas.draw_line(Vector2(r.position.x, r.end.y), Vector2(r.position.x, r.end.y - c_len), b_col, 2.5)
	# Bottom-Right
	canvas.draw_line(Vector2(r.end.x, r.end.y), Vector2(r.end.x - c_len, r.end.y), b_col, 2.5)
	canvas.draw_line(Vector2(r.end.x, r.end.y), Vector2(r.end.x, r.end.y - c_len), b_col, 2.5)

# ------------------------------------------------------------------------------
# Tactical Commander Powers & Salvage Visual FX
# ------------------------------------------------------------------------------

static func draw_salvage_crates(canvas: CanvasItem, salvage_crates: Array, sim_time: float) -> void:
	for c in salvage_crates:
		var pos = Vector2(c["x"], c["y"])
		var bob = sin(sim_time * 5.0 + pos.x) * 1.5
		var alpha = min(1.0, c["life"] / 5.0)
		
		# Ground Drop Shadow
		canvas.draw_circle(pos + Vector2(2, 4), 10.0, Color(0, 0, 0, 0.35 * alpha))
		
		# Pulsating Tactical Acquisition Ring
		var pulse_r = 14.0 + sin(sim_time * 6.0) * 2.0
		canvas.draw_arc(pos, pulse_r, 0, TAU, 16, Color(0.98, 0.8, 0.2, 0.45 * alpha), 1.2)
		
		# Dual Crude Oil Barrels
		var b_pos = pos + Vector2(0, bob)
		canvas.draw_set_transform(b_pos, 0.0, Vector2.ONE)
		# Barrel 1
		canvas.draw_rect(Rect2(-8, -6, 7, 12), Color(0.12, 0.11, 0.09, alpha))
		canvas.draw_rect(Rect2(-7, -5, 5, 10), Color(0.92, 0.65, 0.15, alpha))
		canvas.draw_line(Vector2(-7, -2), Vector2(-2, -2), Color(0.1, 0.1, 0.1, alpha), 1.2)
		canvas.draw_line(Vector2(-7, 2), Vector2(-2, 2), Color(0.1, 0.1, 0.1, alpha), 1.2)
		# Barrel 2
		canvas.draw_rect(Rect2(1, -6, 7, 12), Color(0.12, 0.11, 0.09, alpha))
		canvas.draw_rect(Rect2(2, -5, 5, 10), Color(0.92, 0.65, 0.15, alpha))
		canvas.draw_line(Vector2(2, -2), Vector2(7, -2), Color(0.1, 0.1, 0.1, alpha), 1.2)
		canvas.draw_line(Vector2(2, 2), Vector2(7, 2), Color(0.1, 0.1, 0.1, alpha), 1.2)
		# Steel strap
		canvas.draw_line(Vector2(-8, 0), Vector2(8, 0), Color(0.25, 0.25, 0.27, alpha), 2.0)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func draw_recon_sweeps(canvas: CanvasItem, recon_sweeps: Array, sim_time: float) -> void:
	for r in recon_sweeps:
		var pos = r["pos"]
		var rad = r["radius"]
		var alpha = min(1.0, r["life"] / 2.0)
		
		# Radar Area Grid & Tint
		canvas.draw_circle(pos, rad, Color(0.15, 0.65, 0.35, 0.10 * alpha))
		canvas.draw_arc(pos, rad, 0, TAU, 32, Color(0.35, 0.85, 0.45, 0.75 * alpha), 1.6)
		canvas.draw_arc(pos, rad * 0.65, 0, TAU, 24, Color(0.35, 0.85, 0.45, 0.35 * alpha), 1.0)
		canvas.draw_arc(pos, rad * 0.32, 0, TAU, 16, Color(0.35, 0.85, 0.45, 0.35 * alpha), 1.0)
		
		# Rotating Radar Beam Line
		var sweep_ang = fmod(sim_time * 2.2, 1.0) * TAU
		var p_sweep = pos + Vector2(cos(sweep_ang), sin(sweep_ang)) * rad
		canvas.draw_line(pos, p_sweep, Color(0.55, 0.98, 0.55, 0.85 * alpha), 2.0)
		
		# 4 Crosshair Tick Marks
		for i in range(4):
			var ang = float(i) * (PI * 0.5)
			var p_out = pos + Vector2(cos(ang), sin(ang)) * (rad + 8.0)
			var p_in = pos + Vector2(cos(ang), sin(ang)) * (rad - 8.0)
			canvas.draw_line(p_in, p_out, Color(0.45, 0.95, 0.55, 0.8 * alpha), 2.0)

static func draw_artillery_barrages(canvas: CanvasItem, barrages: Array, sim_time: float) -> void:
	for b in barrages:
		var pos: Vector2 = b["target_pos"]
		var rad: float = b["radius"]
		
		# Red Flare designation on ground
		var flare_pulse = 0.6 + sin(sim_time * 16.0) * 0.4
		canvas.draw_circle(pos, 6.0, Color(1.0, 0.2, 0.2, flare_pulse))
		canvas.draw_circle(pos, 3.0, Color.WHITE)
		
		# Danger perimeter warning ring
		var warn_col = Color(0.95, 0.25, 0.25, 0.5 + 0.3 * sin(sim_time * 10.0))
		canvas.draw_arc(pos, rad, 0, TAU, 32, warn_col, 1.8)
		
		# 4 Danger Cardinal Arrows
		for i in range(4):
			var ang = float(i) * (PI * 0.5)
			var p_out = pos + Vector2(cos(ang), sin(ang)) * (rad + 10.0)
			var p_in = pos + Vector2(cos(ang), sin(ang)) * (rad - 4.0)
			canvas.draw_line(p_in, p_out, warn_col, 2.0)

static func draw_commander_airstrikes(canvas: CanvasItem, airstrikes: Array) -> void:
	for strike in airstrikes:
		var prog: float = strike["progress"]
		var start: Vector2 = strike["start_pos"]
		var end: Vector2 = strike["end_pos"]
		var dir: Vector2 = strike["dir"]
		var cur_pos = start.lerp(end, prog)
		var ang = strike["dir"].angle()
		
		# Trailing Supersonic Jet Contrails
		var contrail_len = 160.0
		var c_start = cur_pos - dir * contrail_len
		canvas.draw_line(c_start, cur_pos - dir * 18.0, Color(0.95, 0.95, 0.95, 0.35), 4.0)
		canvas.draw_line(c_start, cur_pos - dir * 18.0, Color(1.0, 0.7, 0.2, 0.65), 2.0)
		
		# Ground Shadow of Jet Fighter (Swept-wing strike craft)
		canvas.draw_set_transform(cur_pos + Vector2(30, 45), ang, Vector2.ONE)
		var s_col = Color(0, 0, 0, 0.32)
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(24, 0),
			Vector2(-4, -18),
			Vector2(-12, -22),
			Vector2(-8, -6),
			Vector2(-20, -12),
			Vector2(-18, 0),
			Vector2(-20, 12),
			Vector2(-8, 6),
			Vector2(-12, 22),
			Vector2(-4, 18)
		]), s_col)
		canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		
		# Airborne High-Altitude Jet Silhouette
		canvas.draw_set_transform(cur_pos, ang, Vector2.ONE)
		var jet_col = Color("#38424b") if strike["faction"] == "player" else Color("#4a3230")
		var jet_light = Color("#718290") if strike["faction"] == "player" else Color("#8c5e5b")
		var jet_glass = Color("#67e8f9")
		
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(24, 0),
			Vector2(-4, -18),
			Vector2(-12, -22),
			Vector2(-8, -6),
			Vector2(-20, -12),
			Vector2(-18, 0),
			Vector2(-20, 12),
			Vector2(-8, 6),
			Vector2(-12, 22),
			Vector2(-4, 18)
		]), jet_col)
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(14, 0),
			Vector2(-2, -6),
			Vector2(-14, 0),
			Vector2(-2, 6)
		]), jet_light)
		# Cockpit Canopy
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(10, 0),
			Vector2(2, -2.5),
			Vector2(-4, 0),
			Vector2(2, 2.5)
		]), jet_glass)
		# Engine Afterburner Glow
		canvas.draw_circle(Vector2(-19, 0), 4.5, Color("#fb923c"))
		canvas.draw_circle(Vector2(-19, 0), 2.5, Color.WHITE)
		canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# ------------------------------------------------------------------------------
# Visceral Combat Juice: Flying Turrets, Airdrops, Landmines & Napalm
# ------------------------------------------------------------------------------

static func draw_flying_turrets(canvas: CanvasItem, turrets: Array) -> void:
	for ft in turrets:
		var shadow_pos = Vector2(ft["x"], ft["y"])
		var scale_factor = clampf(1.0 / (1.0 + ft["z"] * 0.007), 0.35, 1.0)
		canvas.draw_circle(shadow_pos, 10.0 * scale_factor, Color(0, 0, 0, 0.45 * scale_factor))
		
		var turret_pos = Vector2(ft["x"], ft["y"] - ft["z"])
		canvas.draw_set_transform(turret_pos, ft["angle"], Vector2.ONE)
		var t_col = Color(0.24, 0.22, 0.19)
		var b_col = Color(0.12, 0.11, 0.09)
		canvas.draw_circle(Vector2.ZERO, 7.5, t_col)
		canvas.draw_circle(Vector2.ZERO, 5.0, b_col)
		canvas.draw_line(Vector2.ZERO, Vector2(16.0, 0.0), b_col, 2.5)
		canvas.draw_circle(Vector2(-2, 0), 3.0, Color("#ea580c"))
		canvas.draw_circle(Vector2(-2, 0), 1.5, Color("#fde047"))
		canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

static func draw_airdrop_crates(canvas: CanvasItem, crates: Array, sim_time: float) -> void:
	for c in crates:
		var ground_pos = Vector2(c["x"], c["y"])
		if not c["landed"]:
			var alt = c["altitude"]
			var scale_f = clampf(1.0 - (alt / 350.0) * 0.5, 0.3, 1.0)
			canvas.draw_circle(ground_pos, 12.0 * scale_f, Color(0, 0, 0, 0.35 * scale_f))
			
			var air_pos = Vector2(c["x"], c["y"] - alt)
			var sway = sin(sim_time * 4.0 + ground_pos.x) * 0.12
			canvas.draw_set_transform(air_pos, sway, Vector2.ONE)
			
			var canopy_y = -34.0
			var ch_col = Color("#e2ded4")
			canvas.draw_arc(Vector2(0, canopy_y), 24.0, PI, TAU, 20, ch_col, 8.0)
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(-24, canopy_y),
				Vector2(-12, canopy_y - 12),
				Vector2(0, canopy_y - 16),
				Vector2(12, canopy_y - 12),
				Vector2(24, canopy_y)
			]), ch_col)
			
			var cord_col = Color(0.18, 0.17, 0.15, 0.7)
			canvas.draw_line(Vector2(-22, canopy_y + 2), Vector2(-6, -4), cord_col, 1.2)
			canvas.draw_line(Vector2(-10, canopy_y + 4), Vector2(-3, -4), cord_col, 1.2)
			canvas.draw_line(Vector2(10, canopy_y + 4), Vector2(3, -4), cord_col, 1.2)
			canvas.draw_line(Vector2(22, canopy_y + 2), Vector2(6, -4), cord_col, 1.2)
			
			canvas.draw_rect(Rect2(-10, -10, 20, 20), Color("#1e293b"))
			canvas.draw_rect(Rect2(-8, -8, 16, 16), Color("#d97706"))
			canvas.draw_rect(Rect2(-4, -4, 8, 8), Color("#fef3c7"))
			canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		else:
			var alpha = min(1.0, c["life"] / 6.0)
			canvas.draw_circle(ground_pos + Vector2(2, 3), 14.0, Color(0, 0, 0, 0.45 * alpha))
			
			var r = 20.0 + sin(sim_time * 6.0) * 3.0
			var r_col = Color("#38bdf8") if c["type"] == "nano_repair" else (Color("#84cc16") if c["type"] == "armor_reinforce" else Color("#f59e0b"))
			canvas.draw_arc(ground_pos, r, 0, TAU, 24, Color(r_col.r, r_col.g, r_col.b, 0.5 * alpha), 1.5)
			
			canvas.draw_colored_polygon(PackedVector2Array([
				ground_pos + Vector2(8, 2),
				ground_pos + Vector2(22, -6),
				ground_pos + Vector2(28, 4),
				ground_pos + Vector2(16, 8)
			]), Color(0.88, 0.85, 0.78, 0.75 * alpha))
			
			canvas.draw_rect(Rect2(ground_pos.x - 11, ground_pos.y - 11, 22, 22), Color("#0f172a"))
			canvas.draw_rect(Rect2(ground_pos.x - 9, ground_pos.y - 9, 18, 18), r_col)
			canvas.draw_rect(Rect2(ground_pos.x - 5, ground_pos.y - 5, 10, 10), Color(0.1, 0.1, 0.1, alpha))
			
			var strobe = 0.5 + sin(sim_time * 14.0) * 0.5
			canvas.draw_circle(ground_pos, 3.0, Color(1.0, 1.0, 1.0, strobe * alpha))

static func draw_landmines(canvas: CanvasItem, landmines: Array, sim_time: float) -> void:
	for lm in landmines:
		var pos = Vector2(lm["x"], lm["y"])
		canvas.draw_circle(pos, 6.0, Color(0.18, 0.16, 0.13, 0.85))
		canvas.draw_circle(pos, 4.5, Color(0.3, 0.28, 0.24, 0.95))
		canvas.draw_circle(pos, 2.0, Color(0.1, 0.1, 0.1, 0.95))
		var is_player = (lm["faction"] == "player")
		var led_col = Color("#22c55e") if is_player else Color("#ef4444")
		var blink = 0.4 + sin(sim_time * 6.0 + pos.x) * 0.6
		canvas.draw_circle(pos + Vector2(0, -2.5), 1.2, Color(led_col.r, led_col.g, led_col.b, blink))

static func draw_napalm_patches(canvas: CanvasItem, patches: Array, sim_time: float) -> void:
	for np in patches:
		var pos = Vector2(np["x"], np["y"])
		var rad = np["radius"]
		var alpha = min(1.0, np["life"] / 2.0)
		canvas.draw_circle(pos, rad, Color(0.12, 0.08, 0.05, 0.6 * alpha))
		canvas.draw_circle(pos, rad * 0.7, Color(0.8, 0.25, 0.05, 0.45 * alpha))
		var pulse = sin(sim_time * 12.0 + pos.x) * 2.0
		canvas.draw_arc(pos, rad * 0.85 + pulse, 0, TAU, 20, Color(0.95, 0.5, 0.1, 0.6 * alpha), 2.0)
		canvas.draw_circle(pos, rad * 0.35, Color(1.0, 0.8, 0.2, 0.5 * alpha))

static func draw_cargo_shadows(canvas: CanvasItem, shadows: Array) -> void:
	for cs in shadows:
		var start: Vector2 = cs["start_pos"]
		var end: Vector2 = cs["end_pos"]
		var cur_pos = start.lerp(end, cs["progress"])
		var ang = cs["dir"].angle()
		
		canvas.draw_set_transform(cur_pos, ang, Vector2(1.5, 1.5))
		var s_col = Color(0, 0, 0, 0.28)
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(45, 0),
			Vector2(30, -7),
			Vector2(-20, -8),
			Vector2(-24, -38),
			Vector2(-32, -38),
			Vector2(-28, -8),
			Vector2(-42, -5),
			Vector2(-48, -18),
			Vector2(-54, -18),
			Vector2(-50, 0),
			Vector2(-54, 18),
			Vector2(-48, 18),
			Vector2(-42, 5),
			Vector2(-28, 8),
			Vector2(-32, 38),
			Vector2(-24, 38),
			Vector2(-20, 8),
			Vector2(30, 7)
		]), s_col)
		canvas.draw_rect(Rect2(-28, -26, 8, 4), s_col)
		canvas.draw_rect(Rect2(-28, -16, 8, 4), s_col)
		canvas.draw_rect(Rect2(-28, 12, 8, 4), s_col)
		canvas.draw_rect(Rect2(-28, 22, 8, 4), s_col)
		canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

