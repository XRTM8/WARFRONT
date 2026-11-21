class_name RenderGhostFormation
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func draw_ghost_formations(canvas: CanvasItem, font: Font, sim, mouse_pos: Vector2, sim_time: float) -> void:
	if sim == null or not sim.has_meta("production_queues"):
		return
		
	var queues = sim.get_meta("production_queues").get("player", {})
	var targeting_cat = sim.get_meta("rally_targeting_category") if sim.has_meta("rally_targeting_category") else ""
	
	# 1. Preview Hover Ghost Formation at Mouse Cursor
	if targeting_cat != "":
		var cat_data = queues.get(targeting_cat, {})
		var items = cat_data.get("items", [])
		if items.size() > 0:
			_draw_hover_ghost_formation(canvas, font, sim, targeting_cat, items, mouse_pos, sim_time)

	# 2. Anchored Ghost Formations at confirmed Rally Points for active queues
	for cat in queues.keys():
		var cat_data = queues[cat]
		var slots = cat_data.get("formation_slots", [])
		var rally_pt = cat_data.get("rally_point", Vector2.ZERO)
		if rally_pt == Vector2.ZERO or slots.is_empty():
			continue
			
		_draw_anchored_ghost_slots(canvas, font, slots, rally_pt, sim_time)

static func _draw_hover_ghost_formation(canvas: CanvasItem, font: Font, sim, cat_id: String, items: Array, center: Vector2, sim_time: float) -> void:
	var count = items.size()
	var slots = calculate_formation_positions(items, center, Vector2.RIGHT)
	var pulse = 0.65 + sin(sim_time * 6.0) * 0.25
	var ghost_col = Color(0.2, 0.85, 1.0, 0.45 * pulse)
	var border_col = Color(0.3, 0.95, 1.0, 0.85 * pulse)
	
	# Draw trajectory link from building/HQ to mouse cursor
	var spawn_pos = _get_facility_origin(sim, cat_id)
	canvas.draw_dashed_line(spawn_pos, center, Color(0.2, 0.85, 1.0, 0.35), 2.0, 8.0)
	
	# Bounding tactical formation bracket
	var bounds = _get_formation_bounds(slots, center)
	canvas.draw_rect(bounds.grow(12.0), Color(0.1, 0.4, 0.6, 0.12))
	canvas.draw_rect(bounds.grow(12.0), border_col, false, 1.5)
	
	# R.U.S.E. Holographic Banner
	var banner_text = "[ R.U.S.E. TACTICAL FORMATION // انقر لتأكيد وجهة انطلاق الدفعة (%d وحدات) ]" % count
	canvas.draw_string(font, Vector2(bounds.position.x - 20.0, bounds.position.y - 14.0), banner_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#38bdf8"))
	
	# Draw each ghost silhouette in the formation
	for s in slots:
		_draw_single_ghost(canvas, s["pos"], s["kind"], ghost_col, border_col, 0.0)

static func _draw_anchored_ghost_slots(canvas: CanvasItem, font: Font, slots: Array, rally_pt: Vector2, sim_time: float) -> void:
	var pulse = 0.5 + sin(sim_time * 4.0) * 0.2
	var ghost_col = Color(0.25, 0.85, 0.45, 0.35 * pulse)
	var border_col = Color(0.4, 0.95, 0.55, 0.75 * pulse)
	
	for s in slots:
		if s.get("arrived", false):
			continue # Slot fulfilled by real unit!
			
		var pos = s["pos"]
		_draw_single_ghost(canvas, pos, s["kind"], ghost_col, border_col, 0.0)
		
		# Slot index tag
		canvas.draw_arc(pos, 16.0, 0, TAU, 16, border_col, 1.2)
		if s.get("claimed", false):
			# Beacon ring indicating unit is en route
			var beacon_rad = 8.0 + fmod(sim_time * 18.0, 16.0)
			canvas.draw_arc(pos, beacon_rad, 0, TAU, 12, Color(1.0, 0.8, 0.2, 0.6), 1.5)

static func _draw_single_ghost(canvas: CanvasItem, pos: Vector2, kind: String, body_col: Color, edge_col: Color, angle: float) -> void:
	var spec = Constants.UNIT_SPECS.get(kind, {})
	var r = spec.get("radius", 16.0)
	
	if kind in ["tank", "behemoth"]:
		# Boxy tank hull ghost
		var hw = r * 1.6
		var hh = r * 1.2
		canvas.draw_rect(Rect2(pos.x - hw * 0.5, pos.y - hh * 0.5, hw, hh), body_col)
		canvas.draw_rect(Rect2(pos.x - hw * 0.5, pos.y - hh * 0.5, hw, hh), edge_col, false, 1.8)
		# Gun barrel
		canvas.draw_line(pos, pos + Vector2(r * 1.3, 0), edge_col, 2.0)
	elif kind in ["jet_interceptor", "strike_bomber"]:
		# Delta wing ghost
		var nose = pos + Vector2(r * 1.2, 0)
		var wing_l = pos + Vector2(-r * 0.6, -r)
		var wing_r = pos + Vector2(-r * 0.6, r)
		canvas.draw_colored_polygon(PackedVector2Array([nose, wing_r, pos - Vector2(r * 0.4, 0), wing_l]), body_col)
		canvas.draw_polyline(PackedVector2Array([nose, wing_r, pos - Vector2(r * 0.4, 0), wing_l, nose]), edge_col, 1.8)
	elif kind in ["patrol_boat", "missile_corvette", "river_gunboat"]:
		# Boat hull ghost
		var bow = pos + Vector2(r * 1.2, 0)
		var stern_l = pos + Vector2(-r * 0.8, -r * 0.6)
		var stern_r = pos + Vector2(-r * 0.8, r * 0.6)
		canvas.draw_colored_polygon(PackedVector2Array([bow, stern_r, stern_l]), body_col)
		canvas.draw_polyline(PackedVector2Array([bow, stern_r, stern_l, bow]), edge_col, 1.8)
	elif kind in ["infantry_rifle", "infantry_at", "infantry_mortar"]:
		# Compact squad circle ghost
		canvas.draw_circle(pos, r * 0.85, body_col)
		canvas.draw_arc(pos, r * 0.85, 0, TAU, 16, edge_col, 1.8)
	else:
		canvas.draw_rect(Rect2(pos.x - r, pos.y - r * 0.75, r * 2.0, r * 1.5), body_col)
		canvas.draw_rect(Rect2(pos.x - r, pos.y - r * 0.75, r * 2.0, r * 1.5), edge_col, false, 1.8)

static func calculate_formation_positions(items: Array, center: Vector2, fwd: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count = items.size()
	if count == 0:
		return result
		
	var nrm = Vector2(-fwd.y, fwd.x)
	var spacing = 38.0
	
	if count <= 3:
		# Single tactical line abreast
		for i in range(count):
			var offset = (float(i) - float(count - 1) * 0.5) * spacing
			var p = center + nrm * offset
			result.push_back({
				"id": i,
				"kind": items[i]["kind"],
				"pos": p,
				"claimed": false,
				"arrived": false
			})
	else:
		# Staggered tactical wedge / double line formation (R.U.S.E. style)
		var front_count = int(ceil(float(count) * 0.5))
		var rear_count = count - front_count
		
		# Front rank
		for i in range(front_count):
			var offset = (float(i) - float(front_count - 1) * 0.5) * spacing
			var p = center + fwd * 16.0 + nrm * offset
			result.push_back({
				"id": i,
				"kind": items[i]["kind"],
				"pos": p,
				"claimed": false,
				"arrived": false
			})
			
		# Rear rank (staggered between front gaps)
		for j in range(rear_count):
			var offset = (float(j) - float(rear_count - 1) * 0.5) * spacing
			var p = center - fwd * 24.0 + nrm * offset
			result.push_back({
				"id": front_count + j,
				"kind": items[front_count + j]["kind"],
				"pos": p,
				"claimed": false,
				"arrived": false
			})
			
	return result

static func _get_formation_bounds(slots: Array, fallback: Vector2) -> Rect2:
	if slots.is_empty():
		return Rect2(fallback - Vector2(20, 20), Vector2(40, 40))
	var min_p = Vector2(INF, INF)
	var max_p = Vector2(-INF, -INF)
	for s in slots:
		var p: Vector2 = s["pos"]
		min_p.x = min(min_p.x, p.x - 20.0)
		min_p.y = min(min_p.y, p.y - 20.0)
		max_p.x = max(max_p.x, p.x + 20.0)
		max_p.y = max(max_p.y, p.y + 20.0)
	return Rect2(min_p, max_p - min_p)

static func _get_facility_origin(sim, cat_id: String) -> Vector2:
	var f_kind = Constants.PRODUCTION_CATEGORIES.get(cat_id, {}).get("structure", "")
	for s in sim.structures:
		if s["faction"] == "player" and s["kind"] == f_kind and s.get("status", "") == "ready":
			return Vector2(s["x"], s["y"])
	return Vector2(sim.map["playerHQ"]["x"], sim.map["playerHQ"]["y"])
