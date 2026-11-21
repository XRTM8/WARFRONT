class_name SimUnits
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")
const SimCombat = preload("res://scripts/sim_combat.gd")
const SimLogistics = preload("res://scripts/sim_logistics.gd")

static func spawn_unit(sim, faction: String, kind: String, x: float, y: float) -> Dictionary:
	var spec = Constants.UNIT_SPECS[kind]
	var doctrine_id = sim.player_doctrine if faction == "player" else sim.enemy_doctrine
	var doctrine = Constants.FACTION_DOCTRINES.get(doctrine_id, {})
	var hp_mult = doctrine.get("hp_mult", 1.0)
	var speed_mult = doctrine.get("speed_mult", 1.0)
	var damage_mult = doctrine.get("damage_mult", 1.0)
	
	var base_hp = round(spec["hp"] * hp_mult) if doctrine.size() > 0 else spec["hp"]
	var base_speed = spec["speed"] * speed_mult if doctrine.size() > 0 else spec["speed"]
	var base_dmg = round(spec["damage"] * damage_mult) if doctrine.size() > 0 else spec["damage"]
	
	var unit = {
		"id": sim.next_unit_id,
		"faction": faction,
		"kind": kind,
		"x": x,
		"y": y,
		"hp": base_hp,
		"maxHp": base_hp,
		"speed": base_speed,
		"radius": spec["radius"],
		"range": spec["range"],
		"damage": base_dmg,
		"fireRate": spec["fireRate"],
		"angle": 0.0 if faction == "player" else PI,
		"turretAngle": 0.0 if faction == "player" else PI,
		"targetPos": null,
		"waypointQueue": [] as Array[Vector2],
		"guardPos": Vector2(x, y),
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
		"smokeCooldown": 0.0,
		"treadAccum": 0.0,
		"cargoOil": 0.0,
		"abilityCooldown": 0.0,
		"is_reversing": false,
		"stunTimer": 0.0,
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
		if u.get("smokeCooldown", 0.0) > 0.0:
			u["smokeCooldown"] = max(0.0, u["smokeCooldown"] - dt)
		if u.get("abilityCooldown", 0.0) > 0.0:
			u["abilityCooldown"] = max(0.0, u["abilityCooldown"] - dt)
			
		# Handle stun status (EMP / Seismic shockwave / Landmine track immobilization)
		if u.get("stunTimer", 0.0) > 0.0:
			u["stunTimer"] = max(0.0, u["stunTimer"] - dt)
			if randf() < 0.24:
				sim.spawn_particle("spark", u["x"] + randf_range(-7, 7), u["y"] + randf_range(-7, 7), 0.0, -14.0, 2.0, 1.0, 0.25, Color("#38bdf8"))
			continue # Stunned units cannot steer or fire!

		# Combat Surge tactical buffs for player units
		if u["faction"] == "player" and sim.combat_surge_active:
			if u["cooldown"] > 0.0:
				u["cooldown"] = max(0.0, u["cooldown"] - dt * 0.25) # 25% faster reload
			if randf() < 0.06:
				sim.spawn_particle("spark", u["x"] + randf_range(-6, 6), u["y"] + randf_range(-6, 6), 0.0, -12.0, 2.0, 1.0, 0.2, Color("#facc15"))
			
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
	var is_airborne = (u["kind"] == "helicopter")
	var cur_vec = Vector2(u["x"], u["y"])

	# --------------------------------------------------------------------------
	# 1. Soft Crowd Flocking & Separation (Anti-Blob Physics)
	# --------------------------------------------------------------------------
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
			cur_vec = Vector2(nx, ny)

	# --------------------------------------------------------------------------
	# 2. Smart Target Selection & Threat Assessment
	# --------------------------------------------------------------------------
	var enemy_target = select_smart_target(sim, u)
	var has_hostile_in_range = (enemy_target != null)

	# --------------------------------------------------------------------------
	# 3. Tactical Stance Handling
	# --------------------------------------------------------------------------
	# Stance A: Hold Ground (strict stationary firing bunker)
	if u["stance"] == "hold_ground":
		u["targetPos"] = null
		u["waypointQueue"].clear()

	# Stance B: Tactical Retreat
	elif u["stance"] == "retreat":
		# Auto-locate nearest friendly Repair Depot or HQ
		var retreat_dest = Vector2(sim.map["playerHQ"]["x"], sim.map["playerHQ"]["y"]) if u["faction"] == "player" else Vector2(sim.map["enemyHQ"]["x"], sim.map["enemyHQ"]["y"])
		var best_depot_dist = INF
		for s in sim.structures:
			if s["faction"] == u["faction"] and s["kind"] == "repair_depot" and s["status"] == "ready":
				var d_depot = cur_vec.distance_to(Vector2(s["x"], s["y"]))
				if d_depot < best_depot_dist:
					best_depot_dist = d_depot
					retreat_dest = Vector2(s["x"], s["y"])
					
		u["targetPos"] = retreat_dest
		# Deploy defensive tactical smoke screen while retreating
		if u.get("smokeCooldown", 0.0) <= 0.0:
			u["smokeCooldown"] = 0.65
			sim.spawn_particle("smoke", u["x"], u["y"], randf_range(-6, 6), -10.0, 6.0, 22.0, 0.95, Color(0.85, 0.85, 0.88, 0.65))
			
		# Check if safely arrived at sanctuary
		if cur_vec.distance_to(retreat_dest) <= 55.0:
			u["stance"] = "guard"
			u["targetPos"] = null
			u["guardPos"] = cur_vec

	# Stance C: Attack-Move (march forward, but halt to engage any threats)
	var is_holding_fire_position = false
	if u["stance"] == "attack_move" and has_hostile_in_range:
		# Temporarily halt movement to establish a firing line
		is_holding_fire_position = true

	# --------------------------------------------------------------------------
	# 4. Waypoint & Movement Execution
	# --------------------------------------------------------------------------
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

	# --------------------------------------------------------------------------
	# 5. Combat Engagement & Smooth Turret Traversal
	# --------------------------------------------------------------------------
	if u["range"] <= 0.0 or enemy_target == null:
		return
		
	var target_pos = Vector2(enemy_target["x"], enemy_target["y"])
	var desired_aim = (target_pos - Vector2(u["x"], u["y"])).angle()
	
	# Rate-limited turret rotation (rad/s)
	var max_rot = 8.5 * dt
	if u["kind"] == "behemoth":
		max_rot = 3.6 * dt
	elif u["kind"] == "scout":
		max_rot = 14.0 * dt
	elif u["kind"] == "artillery":
		max_rot = 4.8 * dt
		
	u["turretAngle"] = rotate_toward(u["turretAngle"], desired_aim, max_rot)
	
	# Angular precision check: fire only when gun is trained on target (< 22 degrees)
	var angle_diff = abs(angle_difference(u["turretAngle"], desired_aim))
	if angle_diff < 0.38:
		if u["cooldown"] <= 0.0:
			SimCombat.fire_projectile(sim, u, target_pos)
			u["cooldown"] = 1.0 / u["fireRate"] if u["fireRate"] > 0.0 else 1.0
			u["recoil"] = 6.0

static func select_smart_target(sim, u: Dictionary) -> Variant:
	# Explicit player focus-fire command
	if u.get("targetEntityId") != null:
		for e in sim.units:
			if e["id"] == u["targetEntityId"] and e["alive"]:
				var d = Vector2(u["x"], u["y"]).distance_to(Vector2(e["x"], e["y"]))
				if d <= u["range"] + 80.0:
					return e
		u["targetEntityId"] = null

	var target_faction = "enemy" if u["faction"] == "player" else "player"
	var max_scan_range = u["range"]
	if u["stance"] == "attack_move":
		max_scan_range += 45.0
	elif u["stance"] == "guard":
		max_scan_range += 20.0
		
	var best_target = null
	var highest_score = -9999.0
	
	for e in sim.units:
		if not e["alive"] or e["faction"] != target_faction:
			continue
		var dist = Vector2(u["x"], u["y"]).distance_to(Vector2(e["x"], e["y"]))
		if dist > max_scan_range:
			continue
			
		var score = 100.0 - (dist / max_scan_range) * 25.0
		
		# Low HP Execution Bonus (Finishing off wounded units)
		var hp_ratio = e["hp"] / e["maxHp"]
		score += (1.0 - hp_ratio) * 45.0
		
		# Threat & Counter-Battery Bonus
		if e.get("targetEntityId") == u["id"]:
			score += 35.0
			
		match e["kind"]:
			"behemoth": score += 34.0
			"artillery": score += 30.0
			"tank": score += 24.0
			"turret": score += 20.0
			"helicopter": score += 18.0
			"engineer": score += 16.0
			"scout": score += 12.0
			"truck": score += 5.0
			
		if score > highest_score:
			highest_score = score
			best_target = e
			
	# Target opposing HQ if in range and no higher priority unit
	if best_target == null:
		var opposing_hq = sim.map["enemyHQ"] if u["faction"] == "player" else sim.map["playerHQ"]
		if opposing_hq["hp"] > 0.0:
			var d_hq = Vector2(u["x"], u["y"]).distance_to(Vector2(opposing_hq["x"], opposing_hq["y"]))
			if d_hq <= u["range"]:
				return opposing_hq
				
	return best_target

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
	if sim.player_rally_point != Vector2.ZERO:
		u["targetPos"] = sim.player_rally_point
		u["guardPos"] = sim.player_rally_point
	else:
		u["targetPos"] = Vector2(phq["x"] + 170.0 + cos(offset_angle) * 32.0, phq["y"] + sin(offset_angle) * 58.0)
		u["guardPos"] = u["targetPos"]
	u["stance"] = "guard"
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
	var formation_slots = calculate_formation_positions(selected, Vector2(world_x, world_y))
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

	var formation_slots = calculate_formation_positions(selected, Vector2(world_x, world_y))
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

# ------------------------------------------------------------------------------
# Heroic Veteran Abilities & Tactical Engineering
# ------------------------------------------------------------------------------

static func deploy_landmine_at(sim, faction: String, pos: Vector2) -> bool:
	var spec = Constants.VETERAN_ABILITIES["engineer"]
	if faction == "player":
		if sim.player_oil < spec["cost"]:
			sim.push_event("not_enough_oil", "warn")
			return false
		sim.player_oil -= spec["cost"]
		
	sim.landmines.push_back({
		"id": randi(),
		"x": pos.x,
		"y": pos.y,
		"faction": faction,
		"damage": spec["damage"],
		"stun_duration": spec["stun_duration"],
		"life": 220.0
	})
	sim.spawn_particle("ring", pos.x, pos.y, 0.0, 0.0, 4.0, 26.0, 0.3, Color("#22c55e"))
	sim.sound_triggered.emit("capture")
	sim.spawn_floating_text(pos.x, pos.y - 14.0, "[ AT-MINE ARMED // لغم الدروع نشط ]", Color("#84cc16"), 1.1)
	return true

static func execute_unit_ability(sim, u: Dictionary, target_pos: Vector2) -> bool:
	if not u.get("alive", false) or u.get("stunTimer", 0.0) > 0.0:
		return false
	if u.get("abilityCooldown", 0.0) > 0.0:
		return false
		
	var kind = u["kind"]
	if not Constants.VETERAN_ABILITIES.has(kind):
		return false
		
	var spec = Constants.VETERAN_ABILITIES[kind]
	if u["rank"] < spec["min_rank"]:
		return false
		
	u["abilityCooldown"] = spec["cooldown"]
	u["hitFlash"] = 0.1
	
	if kind == "tank":
		# Incendiary Piercing Shot & Napalm Patch
		u["recoil"] = 9.0
		sim.sound_triggered.emit("cannon")
		sim.camera_trauma = min(1.0, sim.camera_trauma + 0.35)
		
		var start_p = Vector2(u["x"], u["y"])
		var dir = (target_pos - start_p).normalized()
		var dist = start_p.distance_to(target_pos)
		
		# High velocity piercing incendiary projectile
		sim.projectiles.push_back({
			"id": sim.next_projectile_id,
			"sourceUnitId": u["id"],
			"faction": u["faction"],
			"kind": "shell",
			"x": start_p.x,
			"y": start_p.y,
			"startX": start_p.x,
			"startY": start_p.y,
			"totalDist": dist,
			"vx": dir.x * 550.0,
			"vy": dir.y * 550.0,
			"targetX": target_pos.x,
			"targetY": target_pos.y,
			"damage": spec["damage"],
			"bridgeMultiplier": 1.5,
			"life": 1.2
		})
		sim.next_projectile_id += 1
		
		# Spawn Lingering Napalm Patch
		sim.napalm_patches.push_back({
			"x": target_pos.x,
			"y": target_pos.y,
			"radius": spec["napalm_radius"],
			"life": spec["napalm_duration"],
			"faction": u["faction"]
		})
		sim.spawn_burst(target_pos.x, target_pos.y, "fire", 22, Color("#ea580c"), 110.0)
		sim.spawn_floating_text(u["x"], u["y"] - 22.0, "[ INCENDIARY SHELL // قذيفة حارقة ]", Color("#f97316"), 1.2)
		return true
		
	elif kind == "behemoth":
		# Seismic Overcharge Barrage (Stun + Heavy Shockwave)
		u["recoil"] = 14.0
		sim.sound_triggered.emit("behemoth_cannon")
		sim.camera_trauma = min(1.0, sim.camera_trauma + 0.65)
		sim.spawn_particle("ring", target_pos.x, target_pos.y, 0.0, 0.0, 16.0, 110.0, 0.45, Color("#ef4444"))
		sim.add_crater(target_pos.x, target_pos.y, 22.0, false)
		sim.spawn_burst(target_pos.x, target_pos.y, "fire", 26, Color("#ff4444"), 135.0)
		sim.spawn_floating_text(target_pos.x, target_pos.y - 28.0, "[ SEISMIC IMPACT // صدمة زلزالية ]", Color("#ef4444"), 1.5)
		
		var opp = "enemy" if u["faction"] == "player" else "player"
		for target in sim.units:
			if target["alive"] and target["faction"] == opp:
				if Vector2(target["x"], target["y"]).distance_to(target_pos) <= spec["stun_radius"] + target["radius"]:
					target["stunTimer"] = spec["stun_duration"]
					target["recoil"] = 8.0
					sim.damage_unit(target, spec["damage"], u)
		return true
		
	elif kind == "helicopter":
		# Hydra Rocket Salvo (4 spiraling micro-missiles)
		sim.sound_triggered.emit("hydra_salvo")
		sim.spawn_floating_text(u["x"], u["y"] - 22.0, "[ HYDRA VOLLEY // صواريخ هايدرا ]", Color("#38bdf8"), 1.25)
		var start_p = Vector2(u["x"], u["y"])
		var dir = (target_pos - start_p).normalized()
		var dist = start_p.distance_to(target_pos)
		
		for r in range(spec["rocket_count"]):
			var side_offset = Vector2(-dir.y, dir.x) * ((float(r) - 1.5) * 9.0)
			sim.projectiles.push_back({
				"id": sim.next_projectile_id,
				"sourceUnitId": u["id"],
				"faction": u["faction"],
				"kind": "rocket",
				"x": start_p.x + side_offset.x,
				"y": start_p.y + side_offset.y,
				"startX": start_p.x,
				"startY": start_p.y,
				"totalDist": dist,
				"vx": (dir.x + randf_range(-0.12, 0.12)) * 430.0,
				"vy": (dir.y + randf_range(-0.12, 0.12)) * 430.0,
				"targetX": target_pos.x + randf_range(-16, 16),
				"targetY": target_pos.y + randf_range(-16, 16),
				"damage": spec["damage"],
				"bridgeMultiplier": 1.0,
				"life": 1.4
			})
			sim.next_projectile_id += 1
		return true
		
	elif kind == "engineer":
		return deploy_landmine_at(sim, u["faction"], Vector2(u["x"], u["y"]))
		
	return false

static func execute_selected_ability(sim, target_pos: Vector2) -> bool:
	var selected = get_selected_player_combat_units(sim)
	for u in selected:
		if execute_unit_ability(sim, u, target_pos):
			return true
	return false

