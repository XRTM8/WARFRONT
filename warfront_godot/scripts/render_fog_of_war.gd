class_name RenderFogOfWar
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func get_vision_sources(sim) -> Array[Dictionary]:
	var sources: Array[Dictionary] = []
	if sim == null or not sim.fog_of_war_enabled:
		return sources
		
	# 1. Player HQ Vision
	var phq = sim.map.get("playerHQ", {})
	if phq.size() > 0:
		sources.push_back({
			"pos": Vector2(phq["x"], phq["y"]),
			"radius": 380.0
		})
		
	# 2. Player Combat Units Vision
	for u in sim.units:
		if not u.get("alive", false) or u["faction"] != "player":
			continue
		var v_rad = float(u["range"]) + 90.0
		if u["kind"] == "scout":
			v_rad = 320.0 # Advanced recon optics
		elif u["kind"] == "truck":
			v_rad = 160.0
		sources.push_back({
			"pos": Vector2(u["x"], u["y"]),
			"radius": v_rad
		})
		
	# 3. Player Base Structures Vision
	for s in sim.structures:
		if s["faction"] == "player":
			sources.push_back({
				"pos": Vector2(s["x"], s["y"]),
				"radius": 240.0
			})
			
	# 4. Active Recon Drone Sweeps
	for sweep in sim.active_recon_sweeps:
		sources.push_back({
			"pos": Vector2(sweep["x"], sweep["y"]),
			"radius": sweep["radius"]
		})
		
	return sources

static func is_point_visible_to_player(sim, point: Vector2) -> bool:
	if sim == null or not sim.fog_of_war_enabled:
		return true
		
	var sources = get_vision_sources(sim)
	for src in sources:
		if point.distance_to(src["pos"]) <= src["radius"]:
			return true
	return false

static func draw_fog_of_war(canvas: CanvasItem, sim, view_rect: Rect2) -> void:
	if sim == null or not sim.fog_of_war_enabled:
		return
		
	var sources = get_vision_sources(sim)
	var shroud_col = Color(0.02, 0.03, 0.04, 0.62)
	
	# Draw ambient shroud across the viewport
	canvas.draw_rect(view_rect, shroud_col)
	
	# Carve out active vision circular apertures with soft penumbra rings
	for src in sources:
		var pos: Vector2 = src["pos"]
		var rad: float = src["radius"]
		
		if not view_rect.intersects(Rect2(pos.x - rad, pos.y - rad, rad * 2.0, rad * 2.0)):
			continue
			
		# Multilayer gradient rings creating soft penumbra edge
		var inner_rad = rad * 0.75
		var outer_rad = rad
		
		# Clear inner circle (full visibility)
		canvas.draw_circle(pos, inner_rad, Color(0.9, 0.95, 1.0, 0.08))
		# Soft penumbra perimeter ring
		canvas.draw_arc(pos, (inner_rad + outer_rad) * 0.5, 0, TAU, 24, Color(0.3, 0.6, 0.9, 0.12), (outer_rad - inner_rad))
