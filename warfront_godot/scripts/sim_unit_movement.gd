class_name SimUnitMovement
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")

static func calculate_formation_positions(selected: Array[Dictionary], target_pos: Vector2) -> Dictionary:
	var positions: Dictionary = {}
	if selected.is_empty():
		return positions
	if selected.size() == 1:
		positions[selected[0]["id"]] = target_pos
		return positions
		
	var center = Vector2.ZERO
	for u in selected:
		center += Vector2(u["x"], u["y"])
	center /= float(selected.size())
	
	var forward_dir = (target_pos - center).normalized()
	if forward_dir == Vector2.ZERO:
		forward_dir = Vector2.RIGHT
	var lateral_dir = Vector2(-forward_dir.y, forward_dir.x)
	
	var vanguard: Array[Dictionary] = []
	var flanks: Array[Dictionary] = []
	var rearguard: Array[Dictionary] = []
	var air: Array[Dictionary] = []
	
	for u in selected:
		match u["kind"]:
			"behemoth", "tank": vanguard.push_back(u)
			"scout", "engineer": flanks.push_back(u)
			"artillery": rearguard.push_back(u)
			"helicopter": air.push_back(u)
			_: vanguard.push_back(u)
			
	var assign_echelon = func(echelon: Array[Dictionary], row_offset: float, col_spacing: float):
		var n = echelon.size()
		if n == 0:
			return
		for idx in range(n):
			var u = echelon[idx]
			var col_idx = float(idx) - float(n - 1) * 0.5
			var slot_pos = target_pos + forward_dir * row_offset + lateral_dir * (col_idx * col_spacing)
			positions[u["id"]] = slot_pos
			
	assign_echelon.call(vanguard, 0.0, 36.0)
	assign_echelon.call(flanks, -14.0, 42.0)
	assign_echelon.call(rearguard, -46.0, 38.0)
	assign_echelon.call(air, -22.0, 34.0)
	
	return positions

static func apply_crowd_separation(sim, u: Dictionary, dt: float, is_airborne: bool, cur_vec: Vector2) -> Vector2:
	var sep_push = Vector2.ZERO
	for other in sim.units:
		if other["id"] == u["id"] or not other["alive"]:
			continue
		var other_is_air = (other["kind"] == "helicopter")
		if is_airborne != other_is_air:
			continue # Air and land do not push each other
		var delta_pos = cur_vec - Vector2(other["x"], other["y"])
		var min_dist = u["radius"] + other["radius"] + 4.0
		var dist_sq = delta_pos.length_squared()
		if dist_sq < min_dist * min_dist and dist_sq > 0.001:
			var d = sqrt(dist_sq)
			var push_mag = (1.0 - d / min_dist) * (26.0 if u["targetPos"] == null else 40.0)
			sep_push += (delta_pos / d) * push_mag

	# Dynamic Building & Structure Avoidance
	if not is_airborne:
		for s in sim.structures:
			var delta_s = cur_vec - Vector2(s["x"], s["y"])
			var min_s_dist = u["radius"] + s["radius"] + 8.0
			var dist_s_sq = delta_s.length_squared()
			if dist_s_sq < min_s_dist * min_s_dist and dist_s_sq > 0.001:
				var ds = sqrt(dist_s_sq)
				sep_push += (delta_s / ds) * (1.0 - ds / min_s_dist) * 55.0

	if sep_push != Vector2.ZERO:
		var nx = u["x"] + sep_push.x * dt
		var ny = u["y"] + sep_push.y * dt
		if is_airborne or Pathfinding.is_point_passable_for_land(sim.map, nx, ny):
			u["x"] = nx
			u["y"] = ny
			return Vector2(nx, ny)

	return cur_vec

static func update_waypoint_movement(sim, u: Dictionary, dt: float, is_airborne: bool, cur_vec: Vector2, is_holding_fire_position: bool) -> void:
	# Queue transition: if current target reached or idle, pop next queued waypoint
	if u["targetPos"] == null and u["waypointQueue"].size() > 0:
		u["targetPos"] = u["waypointQueue"].pop_front()

	if u["targetPos"] != null and u["speed"] > 0.0 and not is_holding_fire_position:
		var target_vec: Vector2 = u["targetPos"]
		var goal_vec = target_vec
		
		# Land river & bridge navigation
		if not is_airborne and Pathfinding.is_opposite_river_side(sim.map, u["x"], target_vec.x):
			var bridge = Pathfinding.find_nearest_intact_bridge(sim.map, u["x"], u["y"], target_vec.x, target_vec.y)
			if not bridge.is_empty():
				var dist_to_b = Vector2(bridge["x"], bridge["y"]).distance_to(cur_vec)
				if dist_to_b > 44.0:
					goal_vec = Vector2(bridge["x"], bridge["y"])
		
		var d = cur_vec.distance_to(goal_vec)
		if d < 12.0:
			if goal_vec != target_vec and not is_airborne:
				# Intermediate bridge waypoint reached, continue onward
				pass
			else:
				# Target reached!
				if u["waypointQueue"].size() > 0:
					u["targetPos"] = u["waypointQueue"].pop_front()
				else:
					u["targetPos"] = null
					u["is_reversing"] = false
					u["guardPos"] = cur_vec
					if u["stance"] == "attack_move":
						u["stance"] = "guard"
		else:
			var cur_tile = Pathfinding.get_tile_at_world(sim.map, u["x"], u["y"])
			var speed = u["speed"]
			var is_rev = u.get("is_reversing", false)
			if is_rev:
				speed *= Constants.REVERSE_SPEED_RATIO
			if u["stance"] == "retreat":
				speed *= 1.15 # Sprint boost when retreating
			if u["faction"] == "player" and sim.combat_surge_active:
				speed *= 1.18 # +18% speed in combat surge
			if not is_airborne and cur_tile == "ford":
				speed *= 0.55
				if randf() < 0.25:
					sim.spawn_particle("spark", u["x"], u["y"], randf_range(-15, 15), randf_range(-15, 15), 2.0, 4.0, 0.35, Color(0.4, 0.75, 0.9, 0.6))
					
			var move_step = min(d, speed * dt)
			var dir = (goal_vec - cur_vec).normalized()
			
			if is_airborne:
				u["x"] += dir.x * move_step
				u["y"] += dir.y * move_step
				u["angle"] = dir.angle()
				if (cur_tile == "water" or cur_tile == "ford") and randf() < 0.28:
					sim.spawn_particle("ring", u["x"], u["y"] + 12.0, 0, 0, 4.0, 16.0, 0.35, Color(0.4, 0.8, 0.9, 0.45))
			else:
				var cand_x = u["x"] + dir.x * move_step
				var cand_y = u["y"] + dir.y * move_step
				
				if Pathfinding.is_point_passable_for_land(sim.map, cand_x, cand_y):
					u["x"] = cand_x
					u["y"] = cand_y
					if not is_rev:
						u["angle"] = dir.angle()
				elif Pathfinding.is_point_passable_for_land(sim.map, u["x"], cand_y):
					u["y"] = cand_y
					if not is_rev:
						u["angle"] = Vector2(0, dir.y).angle()
				elif Pathfinding.is_point_passable_for_land(sim.map, cand_x, u["y"]):
					u["x"] = cand_x
					if not is_rev:
						u["angle"] = Vector2(dir.x, 0).angle()
				else:
					# Path blocked, advance queue or halt
					if u["waypointQueue"].size() > 0:
						u["targetPos"] = u["waypointQueue"].pop_front()
					else:
						u["targetPos"] = null
						u["guardPos"] = cur_vec

				# Tread marks & dust plumes
				if u["kind"] == "tank" or u["kind"] == "behemoth" or u["kind"] == "scout":
					u["treadAccum"] = u.get("treadAccum", 0.0) + move_step
					if u["treadAccum"] >= 16.0:
						u["treadAccum"] = 0.0
						sim.add_tread_mark(u["x"], u["y"], u["angle"])
					if randf() < 0.22 and cur_tile != "ford":
						sim.spawn_particle("dust", u["x"] - dir.x * 12.0, u["y"] - dir.y * 12.0, -dir.x * 8.0 + randf_range(-4, 4), -dir.y * 8.0 + randf_range(-4, 4), 3.0, 9.0, 0.45, Color(0.74, 0.63, 0.47, 0.4))
