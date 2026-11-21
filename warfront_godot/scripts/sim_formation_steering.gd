class_name SimFormationSteering
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")

static func apply_drag_to_face(sim, start_pos: Vector2, end_pos: Vector2) -> bool:
	var selected_units: Array[Dictionary] = []
	for u in sim.units:
		if u.get("alive", true) and u.get("faction") == "player" and u.get("selected", false):
			selected_units.push_back(u)
			
	if selected_units.is_empty():
		return false
		
	var facing_vec = end_pos - start_pos
	var facing_angle = facing_vec.angle() if facing_vec.length() > 16.0 else 0.0
	var fwd = Vector2(cos(facing_angle), sin(facing_angle))
	var nrm = Vector2(-fwd.y, fwd.x)
	var count = selected_units.size()
	var spacing = 36.0
	
	# Order line abreast perpendicular to drag direction
	for i in range(count):
		var u = selected_units[i]
		var offset = (float(i) - float(count - 1) * 0.5) * spacing
		var dest = start_pos + nrm * offset
		u["targetPos"] = dest
		u["guardPos"] = dest
		u["targetAngle"] = facing_angle
		u["is_reversing"] = false
		u["waypointQueue"].clear()
		
	sim.sound_triggered.emit("order_click")
	return true

static func cycle_sub_selection(sim, reverse: bool = false) -> String:
	# Group currently selected units by kind
	var selected_kinds: Array[String] = []
	for u in sim.units:
		if u.get("alive", true) and u.get("faction") == "player" and u.get("selected", false):
			var k = u.get("kind", "")
			if not selected_kinds.has(k):
				selected_kinds.push_back(k)
				
	if selected_kinds.size() <= 1:
		return ""
		
	var cur_kind = sim.get_meta("active_sub_selection") if sim.has_meta("active_sub_selection") else ""
	var next_idx = 0
	if cur_kind != "":
		var cur_idx = selected_kinds.find(cur_kind)
		next_idx = (cur_idx - 1 + selected_kinds.size()) % selected_kinds.size() if reverse else (cur_idx + 1) % selected_kinds.size()
		
	var chosen_kind = selected_kinds[next_idx]
	sim.set_meta("active_sub_selection", chosen_kind)
	
	# Filter selection to only chosen_kind
	for u in sim.units:
		if u.get("alive", true) and u.get("faction") == "player":
			u["selected"] = (u.get("kind") == chosen_kind)
			
	sim.sound_triggered.emit("click")
	return chosen_kind

static func constrain_bridge_funnel(map: Dictionary, u: Dictionary, cur_pos: Vector2, target_pos: Vector2) -> Vector2:
	# If unit is crossing a bridge, clamp lateral movement to bridge deck center
	var b = Pathfinding.get_bridge_at_world(map, cur_pos.x, cur_pos.y, 24.0)
	if not b.is_empty() and b.get("status", "") == "intact":
		var b_center_x = b["x"]
		var b_center_y = b["y"]
		# Bridges run across river vertically or horizontally
		var dx = abs(cur_pos.x - b_center_x)
		var dy = abs(cur_pos.y - b_center_y)
		if dx < 30.0 and dy < 60.0:
			# Pull slightly towards bridge centerline to prevent rail snagging
			return cur_pos.lerp(Vector2(b_center_x, cur_pos.y), 0.18)
	return cur_pos
