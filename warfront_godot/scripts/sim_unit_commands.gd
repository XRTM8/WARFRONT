class_name SimUnitCommands
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")
const SimUnitMovement = preload("res://scripts/sim_unit_movement.gd")

static func select_units_in_box(sim, rect: Rect2, additive: bool = false) -> int:
	if not additive:
		for u in sim.units:
			u["selected"] = false
			
	var count = 0
	var is_click = rect.size.length() < 10.0
	if is_click:
		var center = rect.position
		var nearest = null
		var best_d = 30.0
		for u in sim.units:
			if not u["alive"] or u["faction"] != "player" or u["kind"] == "truck" or u["kind"] == "turret":
				continue
			var d = Vector2(u["x"], u["y"]).distance_to(center)
			if d < best_d:
				best_d = d
				nearest = u
		if nearest != null:
			nearest["selected"] = true
			count = 1
	else:
		for u in sim.units:
			if not u["alive"] or u["faction"] != "player" or u["kind"] == "truck" or u["kind"] == "turret":
				continue
			if rect.has_point(Vector2(u["x"], u["y"])):
				u["selected"] = true
				count += 1
	if count > 0:
		sim.sound_triggered.emit("unit_select")
	return count

static func get_selected_player_combat_units(sim) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	for u in sim.units:
		if u["alive"] and u["faction"] == "player" and u["selected"] and u["kind"] != "truck" and u["kind"] != "turret":
			selected.push_back(u)
	return selected

static func issue_player_command(sim, world_x: float, world_y: float, shift_queued: bool = false) -> bool:
	if sim.phase != "playing":
		return false
	var selected = get_selected_player_combat_units(sim)
	if selected.is_empty():
		return false
		
	# 1. Clicked Enemy HQ?
	var ehq = sim.map["enemyHQ"]
	if Vector2(world_x, world_y).distance_to(Vector2(ehq["x"], ehq["y"])) < 52.0:
		for u in selected:
			u["is_reversing"] = false
			u["targetHqFaction"] = "enemy"
			u["targetEntityId"] = null
			u["targetBridgeId"] = null
			u["targetPos"] = Vector2(ehq["x"], ehq["y"])
			u["stance"] = "attack_move"
			if not shift_queued:
				u["waypointQueue"].clear()
		sim.order_pulse = { "x": ehq["x"], "y": ehq["y"], "color": Color("#ef5350"), "timer": 0.55, "type": "attack" }
		sim.sound_triggered.emit("order_attack")
		return true

	# 2. Clicked Enemy Unit?
	var clicked_enemy = null
	var best_d = 32.0
	for u in sim.units:
		if not u["alive"] or u["faction"] != "enemy":
			continue
		var d = Vector2(u["x"], u["y"]).distance_to(Vector2(world_x, world_y))
		if d < best_d:
			best_d = d
			clicked_enemy = u
	if clicked_enemy != null:
		for u in selected:
			u["is_reversing"] = false
			u["targetEntityId"] = clicked_enemy["id"]
			u["targetBridgeId"] = null
			u["targetHqFaction"] = null
			u["targetPos"] = Vector2(clicked_enemy["x"], clicked_enemy["y"])
			u["stance"] = "attack_move"
			if not shift_queued:
				u["waypointQueue"].clear()
		sim.order_pulse = { "x": clicked_enemy["x"], "y": clicked_enemy["y"], "color": Color("#ef5350"), "timer": 0.55, "type": "attack" }
		sim.sound_triggered.emit("order_attack")
		return true

	# 3. Clicked Bridge?
	var clicked_bridge = Pathfinding.get_bridge_at_world(sim.map, world_x, world_y, 16.0)
	if not clicked_bridge.is_empty():
		if clicked_bridge["status"] == "intact":
			for u in selected:
				u["is_reversing"] = false
				u["targetBridgeId"] = clicked_bridge["id"]
				u["targetEntityId"] = null
				u["targetHqFaction"] = null
				u["targetPos"] = Vector2(clicked_bridge["x"], clicked_bridge["y"])
				u["stance"] = "attack_move"
				if not shift_queued:
					u["waypointQueue"].clear()
			sim.order_pulse = { "x": clicked_bridge["x"], "y": clicked_bridge["y"], "color": Color("#f5c249"), "timer": 0.55, "type": "attack" }
			sim.sound_triggered.emit("order_attack")
			return true

	# 4. Standard Group Movement in Tactical Formations
	var formation_slots = SimUnitMovement.calculate_formation_positions(selected, Vector2(world_x, world_y))
	for u in selected:
		u["is_reversing"] = false
		u["targetEntityId"] = null
		u["targetBridgeId"] = null
		u["targetHqFaction"] = null
		u["stance"] = "guard"
		var slot_pos: Vector2 = formation_slots.get(u["id"], Vector2(world_x, world_y))
		
		if shift_queued:
			if u["targetPos"] == null:
				u["targetPos"] = slot_pos
			else:
				u["waypointQueue"].push_back(slot_pos)
		else:
			u["waypointQueue"].clear()
			u["targetPos"] = slot_pos

	sim.order_pulse = { "x": world_x, "y": world_y, "color": Color("#78d464"), "timer": 0.55, "type": "move" }
	sim.sound_triggered.emit("order_move")
	return true

static func issue_player_reverse_move(sim, world_x: float, world_y: float, shift_queued: bool = false) -> bool:
	if sim.phase != "playing":
		return false
	var selected = get_selected_player_combat_units(sim)
	if selected.is_empty():
		return false
		
	var dest = Vector2(world_x, world_y)
	var issued = false
	for u in selected:
		if u["kind"] != "helicopter":
			issued = true
			u["is_reversing"] = true
			u["targetEntityId"] = null
			u["targetBridgeId"] = null
			u["targetHqFaction"] = null
			u["stance"] = "guard"
			if shift_queued and (u["targetPos"] != null or u["waypointQueue"].size() > 0):
				u["waypointQueue"].push_back(dest)
			else:
				u["waypointQueue"].clear()
				u["targetPos"] = dest
				
	if issued:
		sim.order_pulse = { "x": world_x, "y": world_y, "color": Color("#f59e0b"), "timer": 0.55, "type": "reverse" }
		sim.sound_triggered.emit("bark_retreat")
		sim.sound_triggered.emit("order_click")
	return issued

static func issue_player_attack_move(sim, world_x: float, world_y: float, shift_queued: bool = false) -> bool:
	if sim.phase != "playing":
		return false
	var selected = get_selected_player_combat_units(sim)
	if selected.is_empty():
		return false

	var formation_slots = SimUnitMovement.calculate_formation_positions(selected, Vector2(world_x, world_y))
	for u in selected:
		u["targetEntityId"] = null
		u["targetBridgeId"] = null
		u["targetHqFaction"] = null
		u["stance"] = "attack_move"
		var slot_pos: Vector2 = formation_slots.get(u["id"], Vector2(world_x, world_y))
		
		if shift_queued:
			if u["targetPos"] == null:
				u["targetPos"] = slot_pos
			else:
				u["waypointQueue"].push_back(slot_pos)
		else:
			u["waypointQueue"].clear()
			u["targetPos"] = slot_pos

	sim.order_pulse = { "x": world_x, "y": world_y, "color": Color("#ef4444"), "timer": 0.65, "type": "attack" }
	sim.sound_triggered.emit("order_attack")
	return true

static func stop_selected_units(sim) -> void:
	var selected = get_selected_player_combat_units(sim)
	for u in selected:
		u["targetPos"] = null
		u["waypointQueue"].clear()
		u["targetEntityId"] = null
		u["targetBridgeId"] = null
		u["targetHqFaction"] = null
		u["stance"] = "guard"
		u["guardPos"] = Vector2(u["x"], u["y"])
	sim.sound_triggered.emit("order_stop")

static func set_selected_stance(sim, stance: String) -> void:
	var selected = get_selected_player_combat_units(sim)
	for u in selected:
		u["stance"] = stance
		if stance == "hold_ground":
			u["targetPos"] = null
			u["waypointQueue"].clear()
			u["guardPos"] = Vector2(u["x"], u["y"])
	if stance == "hold_ground":
		sim.sound_triggered.emit("order_hold")
	else:
		sim.sound_triggered.emit("order_move")

static func retreat_selected_units(sim) -> void:
	var selected = get_selected_player_combat_units(sim)
	for u in selected:
		u["stance"] = "retreat"
		u["waypointQueue"].clear()
		u["targetEntityId"] = null
		# Smoke discharge on retreat
		sim.spawn_particle("smoke", u["x"], u["y"], randf_range(-12, 12), -15.0, 8.0, 26.0, 1.2, Color(0.9, 0.9, 0.92, 0.75))
	sim.sound_triggered.emit("order_retreat")
