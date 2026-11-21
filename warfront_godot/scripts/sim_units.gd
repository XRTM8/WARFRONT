class_name SimUnits
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")
const SimCombat = preload("res://scripts/sim_combat.gd")
const SimLogistics = preload("res://scripts/sim_logistics.gd")
const SimUnitSpawner = preload("res://scripts/sim_unit_spawner.gd")
const SimUnitAbilities = preload("res://scripts/sim_unit_abilities.gd")
const SimUnitMovement = preload("res://scripts/sim_unit_movement.gd")
const SimUnitCommands = preload("res://scripts/sim_unit_commands.gd")
const SimNaval = preload("res://scripts/sim_naval.gd")
const SimAircraft = preload("res://scripts/sim_aircraft.gd")
const SimKinematics = preload("res://scripts/sim_kinematics.gd")

# ------------------------------------------------------------------------------
# Facade Delegations: Spawning & Recruitment
# ------------------------------------------------------------------------------

static func spawn_unit(sim, faction: String, kind: String, x: float, y: float, slot_idx: int = -1) -> Dictionary:
	return SimUnitSpawner.spawn_unit(sim, faction, kind, x, y, slot_idx)

static func setup_initial_forces(sim) -> void:
	SimUnitSpawner.setup_initial_forces(sim)

static func train_player_unit(sim, kind: String) -> bool:
	return SimUnitSpawner.train_player_unit(sim, kind)

static func place_player_turret(sim, x: float, y: float) -> bool:
	return SimUnitSpawner.place_player_turret(sim, x, y)

static func rebuild_bridge(sim, bridge_id: String, faction: String = "player") -> bool:
	return SimUnitSpawner.rebuild_bridge(sim, bridge_id, faction)

# ------------------------------------------------------------------------------
# Facade Delegations: Heroic & Tactical Abilities
# ------------------------------------------------------------------------------

static func deploy_landmine_at(sim, faction: String, pos: Vector2) -> bool:
	return SimUnitAbilities.deploy_landmine_at(sim, faction, pos)

static func execute_unit_ability(sim, u: Dictionary, target_pos: Vector2) -> bool:
	return SimUnitAbilities.execute_unit_ability(sim, u, target_pos)

static func execute_selected_ability(sim, target_pos: Vector2) -> bool:
	return SimUnitAbilities.execute_selected_ability(sim, target_pos)

# ------------------------------------------------------------------------------
# Facade Delegations: Tactical Commands & Selection
# ------------------------------------------------------------------------------

static func calculate_formation_positions(selected: Array[Dictionary], target_pos: Vector2) -> Dictionary:
	return SimUnitMovement.calculate_formation_positions(selected, target_pos)

static func select_units_in_box(sim, rect: Rect2, additive: bool = false) -> int:
	return SimUnitCommands.select_units_in_box(sim, rect, additive)

static func get_selected_player_combat_units(sim) -> Array[Dictionary]:
	return SimUnitCommands.get_selected_player_combat_units(sim)

static func issue_player_command(sim, world_x: float, world_y: float, shift_queued: bool = false) -> bool:
	return SimUnitCommands.issue_player_command(sim, world_x, world_y, shift_queued)

static func issue_player_reverse_move(sim, world_x: float, world_y: float, shift_queued: bool = false) -> bool:
	return SimUnitCommands.issue_player_reverse_move(sim, world_x, world_y, shift_queued)

static func issue_player_attack_move(sim, world_x: float, world_y: float, shift_queued: bool = false) -> bool:
	return SimUnitCommands.issue_player_attack_move(sim, world_x, world_y, shift_queued)

static func stop_selected_units(sim) -> void:
	SimUnitCommands.stop_selected_units(sim)

static func set_selected_stance(sim, stance: String) -> void:
	SimUnitCommands.set_selected_stance(sim, stance)

static func retreat_selected_units(sim) -> void:
	SimUnitCommands.retreat_selected_units(sim)

# ------------------------------------------------------------------------------
# Coordinator: Unit Lifecycle & Status Simulation
# ------------------------------------------------------------------------------

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
	var is_airborne = u.get("is_air", false) or (u["kind"] == "helicopter")
	var cur_vec = Vector2(u["x"], u["y"])
	
	if u.get("is_naval", false):
		SimNaval.update_naval_unit(sim, u, dt)
	if u.get("is_air", false):
		SimAircraft.update_aircraft(sim, u, dt)

	# 1. Soft Crowd Flocking & Dynamic Building Avoidance
	cur_vec = SimUnitMovement.apply_crowd_separation(sim, u, dt, is_airborne, cur_vec)

	# 2. Smart Target Selection & Threat Assessment
	var enemy_target = select_smart_target(sim, u)
	var has_hostile_in_range = (enemy_target != null)

	# 3. Tactical Stance Handling
	if u["stance"] == "hold_ground":
		u["targetPos"] = null
		u["waypointQueue"].clear()
	elif u["stance"] == "retreat":
		var retreat_dest = Vector2(sim.map["playerHQ"]["x"], sim.map["playerHQ"]["y"]) if u["faction"] == "player" else Vector2(sim.map["enemyHQ"]["x"], sim.map["enemyHQ"]["y"])
		var best_depot_dist = INF
		for s in sim.structures:
			if s["faction"] == u["faction"] and s["kind"] == "repair_depot" and s["status"] == "ready":
				var d_depot = cur_vec.distance_to(Vector2(s["x"], s["y"]))
				if d_depot < best_depot_dist:
					best_depot_dist = d_depot
					retreat_dest = Vector2(s["x"], s["y"])
					
		u["targetPos"] = retreat_dest
		if u.get("smokeCooldown", 0.0) <= 0.0:
			u["smokeCooldown"] = 0.65
			sim.spawn_particle("smoke", u["x"], u["y"], randf_range(-6, 6), -10.0, 6.0, 22.0, 0.95, Color(0.85, 0.85, 0.88, 0.65))
			
		if cur_vec.distance_to(retreat_dest) <= 55.0:
			u["stance"] = "guard"
			u["targetPos"] = null
			u["guardPos"] = cur_vec

	var is_holding_fire_position = false
	if u["stance"] == "attack_move" and has_hostile_in_range:
		is_holding_fire_position = true

	# 4. Waypoint & Movement Execution
	SimUnitMovement.update_waypoint_movement(sim, u, dt, is_airborne, cur_vec, is_holding_fire_position)

	# 5. Combat Engagement & Mechanical Turret Slew / Kinematics
	if enemy_target != null:
		var target_pos = Vector2(enemy_target["x"], enemy_target["y"])
		var desired_aim = (target_pos - Vector2(u["x"], u["y"])).angle()
		u["targetTurretAngle"] = desired_aim
	elif u.get("targetPos") != null:
		u["targetTurretAngle"] = u.get("angle", 0.0)

	SimKinematics.update_unit_kinematics(u, dt)

	if u["range"] <= 0.0 or enemy_target == null:
		return
		
	var target_pos = Vector2(enemy_target["x"], enemy_target["y"])
	var desired_aim = (target_pos - Vector2(u["x"], u["y"])).angle()
	var angle_diff = abs(angle_difference(u["turretAngle"], desired_aim))
	if angle_diff < 0.38:
		if u["cooldown"] <= 0.0:
			SimCombat.fire_projectile(sim, u, target_pos)
			u["cooldown"] = 1.0 / u["fireRate"] if u["fireRate"] > 0.0 else 1.0
			u["recoil"] = 6.0

static func select_smart_target(sim, u: Dictionary) -> Variant:
	if u.get("targetEntityId") != null:
		for e in sim.units:
			if e["id"] == u["targetEntityId"] and e["alive"]:
				var d = Vector2(u["x"], u["y"]).distance_to(Vector2(e["x"], e["y"]))
				if d <= u["range"] + 80.0:
					return e
		u["targetEntityId"] = null

	var max_scan_range = u["range"]
	if u["stance"] == "attack_move":
		max_scan_range += 45.0
	elif u["stance"] == "guard":
		max_scan_range += 20.0
		
	var best_target = null
	var highest_score = -9999.0
	
	for e in sim.units:
		if not e["alive"] or not sim.are_hostile(u, e):
			continue
		var dist = Vector2(u["x"], u["y"]).distance_to(Vector2(e["x"], e["y"]))
		if dist > max_scan_range:
			continue
			
		var score = 100.0 - (dist / max_scan_range) * 25.0
		var hp_ratio = e["hp"] / e["maxHp"]
		score += (1.0 - hp_ratio) * 45.0
		
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
			
	if best_target == null:
		var opposing_hq = sim.map["enemyHQ"] if u["faction"] == "player" else sim.map["playerHQ"]
		if opposing_hq["hp"] > 0.0:
			var d_hq = Vector2(u["x"], u["y"]).distance_to(Vector2(opposing_hq["x"], opposing_hq["y"]))
			if d_hq <= u["range"]:
				return opposing_hq
				
	return best_target
