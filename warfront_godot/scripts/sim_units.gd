class_name SimUnits
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")
const SimCombat = preload("res://scripts/sim_combat.gd")
const SimLogistics = preload("res://scripts/sim_logistics.gd")

static func spawn_unit(sim, faction: String, kind: String, x: float, y: float) -> Dictionary:
	var spec = Constants.UNIT_SPECS[kind]
	var unit = {
		"id": sim.next_unit_id,
		"faction": faction,
		"kind": kind,
		"x": x,
		"y": y,
		"hp": spec["hp"],
		"maxHp": spec["hp"],
		"speed": spec["speed"],
		"radius": spec["radius"],
		"range": spec["range"],
		"damage": spec["damage"],
		"fireRate": spec["fireRate"],
		"angle": 0.0 if faction == "player" else PI,
		"turretAngle": 0.0 if faction == "player" else PI,
		"targetPos": null,
		"targetEntityId": null,
		"targetBridgeId": null,
		"targetHqFaction": null,
		"selected": false,
		"alive": true,
		"stance": "guard",
		"rank": 0,
		"xp": 0.0,
		"kills": 0,
		"hitFlash": 0.0,
		"promoFlash": 0.0,
		"recoil": 0.0,
		"cooldown": 0.0,
		"treadAccum": 0.0,
		"cargoOil": 0.0,
		"truckState": "idle",
		"roadPath": [],
		"roadPathIndex": 0,
		"assignedRigId": -1
	}
	sim.next_unit_id += 1
	sim.units.push_back(unit)
	return unit

static func setup_initial_forces(sim) -> void:
	var phq = sim.map["playerHQ"]
	var ehq = sim.map["enemyHQ"]
	
	# Player starter battlegroup
	spawn_unit(sim, "player", "tank", phq["x"] + 110.0, phq["y"] - 35.0)
	spawn_unit(sim, "player", "tank", phq["x"] + 110.0, phq["y"] + 35.0)
	spawn_unit(sim, "player", "scout", phq["x"] + 140.0, phq["y"] - 65.0)
	spawn_unit(sim, "player", "scout", phq["x"] + 140.0, phq["y"] + 65.0)
	spawn_unit(sim, "player", "behemoth", phq["x"] + 160.0, phq["y"])
	spawn_unit(sim, "player", "engineer", phq["x"] + 80.0, phq["y"] + 80.0)

	# Enemy starter battlegroup
	spawn_unit(sim, "enemy", "tank", ehq["x"] - 110.0, ehq["y"] - 35.0)
	spawn_unit(sim, "enemy", "tank", ehq["x"] - 110.0, ehq["y"] + 35.0)
	spawn_unit(sim, "enemy", "scout", ehq["x"] - 140.0, ehq["y"] - 65.0)
	spawn_unit(sim, "enemy", "scout", ehq["x"] - 140.0, ehq["y"] + 65.0)
	spawn_unit(sim, "enemy", "behemoth", ehq["x"] - 160.0, ehq["y"])
	spawn_unit(sim, "enemy", "artillery", ehq["x"] - 180.0, ehq["y"] + 40.0)

	# Initial supply convoys for owned rigs
	for rig in sim.map["rigs"]:
		if rig["owner"] == "player":
			SimLogistics.spawn_truck_for_rig(sim, "player", rig)
		elif rig["owner"] == "enemy":
			SimLogistics.spawn_truck_for_rig(sim, "enemy", rig)

static func update_units(sim, dt: float) -> void:
	for u in sim.units:
		if not u["alive"]:
			continue
			
		if u["hitFlash"] > 0.0:
			u["hitFlash"] = max(0.0, u["hitFlash"] - dt)
		if u["recoil"] > 0.0:
			u["recoil"] = max(0.0, u["recoil"] - dt * 3.5)
		if u["promoFlash"] > 0.0:
			u["promoFlash"] = max(0.0, u["promoFlash"] - dt)
		if u["cooldown"] > 0.0:
			u["cooldown"] = max(0.0, u["cooldown"] - dt)
			
		# Passive veterancy rank 2 / 3 healing
		if u["rank"] >= 2 and u["hp"] < u["maxHp"]:
			var heal_rate = Constants.VETERANCY_RANKS[u["rank"]]["healPerSec"]
			u["hp"] = min(u["maxHp"], u["hp"] + dt * heal_rate)

		# Critical damage smoke & sparks on heavily damaged units
		if u["hp"] < u["maxHp"] * 0.35 and randf() < 0.18:
			sim.spawn_particle("smoke", u["x"] + randf_range(-4.0, 4.0), u["y"] + randf_range(-4.0, 4.0), randf_range(-3.0, 3.0), -14.0 - randf() * 10.0, 4.0, 14.0, 0.65, Color("#1e1c19"))
			if u["hp"] < u["maxHp"] * 0.15 and randf() < 0.22:
				sim.spawn_particle("spark", u["x"], u["y"], randf_range(-12.0, 12.0), randf_range(-16.0, -4.0), 2.0, 4.0, 0.3, Color("#f97316"))
			
		if u["kind"] == "truck":
			SimLogistics.update_truck(sim, u, dt)
		else:
			update_combat_unit(sim, u, dt)

static func update_combat_unit(sim, u: Dictionary, dt: float) -> void:
	# Unit movement with smart river & obstacle navigation
	if u["targetPos"] != null and u["speed"] > 0.0:
		var target_vec: Vector2 = u["targetPos"]
		var goal_vec = target_vec
		var is_airborne = u["kind"] == "helicopter"
		
		# If land unit target is across the river, steer toward the nearest intact bridge
		if not is_airborne and Pathfinding.is_opposite_river_side(sim.map, u["x"], target_vec.x):
			var bridge = Pathfinding.find_nearest_intact_bridge(sim.map, u["x"], u["y"], target_vec.x, target_vec.y)
			if not bridge.is_empty():
				var dist_to_b = Vector2(bridge["x"], bridge["y"]).distance_to(Vector2(u["x"], u["y"]))
				if dist_to_b > 44.0:
					goal_vec = Vector2(bridge["x"], bridge["y"])
		
		var cur_vec = Vector2(u["x"], u["y"])
		var d = cur_vec.distance_to(goal_vec)
		if d < 8.0:
			if goal_vec != target_vec and not is_airborne:
				# Reached bridge waypoint, continue onward
				pass
			else:
				u["targetPos"] = null
		else:
			var cur_tile = Pathfinding.get_tile_at_world(sim.map, u["x"], u["y"])
			var speed = u["speed"]
			if not is_airborne and cur_tile == "ford":
				speed *= 0.55
				if randf() < 0.25:
					sim.spawn_particle("spark", u["x"], u["y"], randf_range(-15, 15), randf_range(-15, 15), 2.0, 4.0, 0.35, Color(0.4, 0.75, 0.9, 0.6))
					
			var move_step = min(d, speed * dt)
			var dir = (goal_vec - cur_vec).normalized()
			
			if is_airborne:
				# Airborne gunship flies directly over all terrain & water!
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
					u["angle"] = dir.angle()
				elif Pathfinding.is_point_passable_for_land(sim.map, u["x"], cand_y):
					u["y"] = cand_y
					u["angle"] = Vector2(0, dir.y).angle()
				elif Pathfinding.is_point_passable_for_land(sim.map, cand_x, u["y"]):
					u["x"] = cand_x
					u["angle"] = Vector2(dir.x, 0).angle()
				else:
					u["targetPos"] = null

				# Dust plumes & tread marks
				if u["kind"] == "tank" or u["kind"] == "behemoth" or u["kind"] == "scout":
					u["treadAccum"] = u.get("treadAccum", 0.0) + move_step
					if u["treadAccum"] >= 16.0:
						u["treadAccum"] = 0.0
						sim.add_tread_mark(u["x"], u["y"], u["angle"])
					if randf() < 0.22 and cur_tile != "ford":
						sim.spawn_particle("dust", u["x"] - dir.x * 12.0, u["y"] - dir.y * 12.0, -dir.x * 8.0 + randf_range(-4, 4), -dir.y * 8.0 + randf_range(-4, 4), 3.0, 9.0, 0.45, Color(0.74, 0.63, 0.47, 0.4))
			
	# Combat engagement
	if u["range"] <= 0.0:
		return
		
	var enemy_target = null
	var best_dist = u["range"]
	
	# Check specific target entity
	if u["targetEntityId"] != null:
		for e in sim.units:
			if e["id"] == u["targetEntityId"] and e["alive"]:
				var d = Vector2(u["x"], u["y"]).distance_to(Vector2(e["x"], e["y"]))
				if d <= u["range"] + 40.0:
					enemy_target = e
					break
					
	# Auto-acquire closest hostile within weapon range
	if enemy_target == null:
		var target_faction = "enemy" if u["faction"] == "player" else "player"
		for e in sim.units:
			if e["alive"] and e["faction"] == target_faction:
				var d = Vector2(u["x"], u["y"]).distance_to(Vector2(e["x"], e["y"]))
				if d < best_dist:
					best_dist = d
					enemy_target = e
					
	# Also target opposing HQ if in range
	var opposing_hq = sim.map["enemyHQ"] if u["faction"] == "player" else sim.map["playerHQ"]
	if opposing_hq["hp"] > 0.0:
		var d_hq = Vector2(u["x"], u["y"]).distance_to(Vector2(opposing_hq["x"], opposing_hq["y"]))
		if d_hq < best_dist:
			enemy_target = opposing_hq
			
	if enemy_target != null:
		var target_pos = Vector2(enemy_target["x"], enemy_target["y"])
		var aim_angle = (target_pos - Vector2(u["x"], u["y"])).angle()
		u["turretAngle"] = aim_angle
		
		if u["cooldown"] <= 0.0:
			SimCombat.fire_projectile(sim, u, target_pos)
			u["cooldown"] = 1.0 / u["fireRate"] if u["fireRate"] > 0.0 else 1.0
			u["recoil"] = 6.0

static func train_player_unit(sim, kind: String) -> bool:
	if sim.phase != "playing":
		return false
	if kind == "turret":
		sim.build_mode = "none" if sim.build_mode == "turret" else "turret"
		return true
	var spec = Constants.UNIT_SPECS[kind]
	if sim.player_oil < spec["cost"]:
		sim.push_event("not_enough_oil", "warn")
		return false
	sim.player_oil -= spec["cost"]
	var phq = sim.map["playerHQ"]
	var offset_angle = fmod(float(sim.next_unit_id) * 1.15, PI * 2.0)
	var sx = phq["x"] + 88.0 + cos(offset_angle) * 26.0
	var sy = phq["y"] + sin(offset_angle) * 52.0
	var u = spawn_unit(sim, "player", kind, sx, sy)
	u["targetPos"] = Vector2(phq["x"] + 170.0 + cos(offset_angle) * 32.0, phq["y"] + sin(offset_angle) * 58.0)
	u["stance"] = "move"
	sim.spawn_burst(sx, sy, "smoke", 6, Color("#b8aa8f"), 45.0)
	sim.sound_triggered.emit("unit_ready")
	return true

static func place_player_turret(sim, x: float, y: float) -> bool:
	if sim.phase != "playing":
		return false
	var cost = Constants.UNIT_SPECS["turret"]["cost"]
	if sim.player_oil < cost:
		sim.push_event("not_enough_oil", "warn")
		sim.build_mode = "none"
		return false
	sim.player_oil -= cost
	spawn_unit(sim, "player", "turret", x, y)
	sim.spawn_burst(x, y, "spark", 10, Color("#f3c363"), 70.0)
	sim.sound_triggered.emit("unit_ready")
	sim.build_mode = "none"
	return true

static func rebuild_bridge(sim, bridge_id: String, faction: String = "player") -> bool:
	var bridge = null
	for b in sim.map["bridges"]:
		if b["id"] == bridge_id:
			bridge = b
			break
	if bridge == null or bridge["status"] == "intact":
		return false
	if faction == "player":
		if sim.player_oil < Constants.BRIDGE_REBUILD_COST:
			sim.push_event("not_enough_oil", "warn")
			return false
		sim.player_oil -= Constants.BRIDGE_REBUILD_COST
		sim.build_mode = "none"
	else:
		if sim.enemy_oil < Constants.BRIDGE_REBUILD_COST:
			return false
		sim.enemy_oil -= Constants.BRIDGE_REBUILD_COST
		
	bridge["status"] = "intact"
	bridge["hp"] = bridge["maxHp"]
	sim.spawn_burst(bridge["x"], bridge["y"], "spark", 18, Color("#f0c45c"), 120.0)
	sim.spawn_burst(bridge["x"], bridge["y"], "smoke", 10, Color("#c2bab0"), 75.0)
	sim.sound_triggered.emit("capture")
	if faction == "player":
		sim.push_event("bridge_rebuilt", "good")
		sim.notify_directive("rebuild_bridge")
	SimLogistics.reroute_stranded_trucks(sim)
	return true

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

static func issue_player_command(sim, world_x: float, world_y: float) -> bool:
	if sim.phase != "playing":
		return false
	var selected: Array[Dictionary] = []
	for u in sim.units:
		if u["alive"] and u["faction"] == "player" and u["selected"] and u["kind"] != "truck" and u["kind"] != "turret":
			selected.push_back(u)
	if selected.is_empty():
		return false
		
	# 1. Clicked Enemy HQ?
	var ehq = sim.map["enemyHQ"]
	if Vector2(world_x, world_y).distance_to(Vector2(ehq["x"], ehq["y"])) < 52.0:
		for u in selected:
			u["targetHqFaction"] = "enemy"
			u["targetEntityId"] = null
			u["targetBridgeId"] = null
			u["targetPos"] = Vector2(ehq["x"], ehq["y"])
			u["stance"] = "attack"
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
			u["targetEntityId"] = clicked_enemy["id"]
			u["targetBridgeId"] = null
			u["targetHqFaction"] = null
			u["targetPos"] = Vector2(clicked_enemy["x"], clicked_enemy["y"])
			u["stance"] = "attack"
		sim.order_pulse = { "x": clicked_enemy["x"], "y": clicked_enemy["y"], "color": Color("#ef5350"), "timer": 0.55, "type": "attack" }
		sim.sound_triggered.emit("order_attack")
		return true

	# 3. Clicked Bridge?
	var clicked_bridge = Pathfinding.get_bridge_at_world(sim.map, world_x, world_y, 16.0)
	if not clicked_bridge.is_empty():
		if clicked_bridge["status"] == "intact":
			for u in selected:
				u["targetBridgeId"] = clicked_bridge["id"]
				u["targetEntityId"] = null
				u["targetHqFaction"] = null
				u["targetPos"] = Vector2(clicked_bridge["x"], clicked_bridge["y"])
				u["stance"] = "demolish"
			sim.order_pulse = { "x": clicked_bridge["x"], "y": clicked_bridge["y"], "color": Color("#f5c249"), "timer": 0.55, "type": "attack" }
			sim.sound_triggered.emit("order_attack")
			return true

	# 4. Move command
	for i in range(selected.size()):
		var u = selected[i]
		u["targetEntityId"] = null
		u["targetBridgeId"] = null
		u["targetHqFaction"] = null
		var offset = Vector2.ZERO if selected.size() == 1 else Vector2(cos(i * 1.2), sin(i * 1.2)) * 24.0
		u["targetPos"] = Vector2(world_x, world_y) + offset
		u["stance"] = "move"
	sim.order_pulse = { "x": world_x, "y": world_y, "color": Color("#78d464"), "timer": 0.55, "type": "move" }
	sim.sound_triggered.emit("order_move")
	return true
