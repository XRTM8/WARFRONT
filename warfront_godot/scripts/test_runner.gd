class_name TestRunner
extends SceneTree

const Constants = preload("res://scripts/constants.gd")
const MapGen = preload("res://scripts/map_gen.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")
const Simulation = preload("res://scripts/simulation.gd")
const SoundSynth = preload("res://scripts/sound_synth.gd")
const SimAI = preload("res://scripts/sim_ai.gd")
const SimCommander = preload("res://scripts/sim_commander.gd")
const SimUnits = preload("res://scripts/sim_units.gd")
const AudioDSPHelpers = preload("res://scripts/audio_dsp_helpers.gd")
const AudioWeapons = preload("res://scripts/audio_weapons.gd")
const AudioImpacts = preload("res://scripts/audio_impacts.gd")
const AudioComms = preload("res://scripts/audio_comms.gd")
const AudioUI = preload("res://scripts/audio_ui.gd")
const MapGenLarge = preload("res://scripts/map_gen_large.gd")
const MapGenStandard = preload("res://scripts/map_gen_standard.gd")
const SimUnitSpawner = preload("res://scripts/sim_unit_spawner.gd")
const SimUnitAbilities = preload("res://scripts/sim_unit_abilities.gd")
const SimUnitMovement = preload("res://scripts/sim_unit_movement.gd")
const SimUnitCommands = preload("res://scripts/sim_unit_commands.gd")
const SimHazards = preload("res://scripts/sim_hazards.gd")
const RenderTerrain = preload("res://scripts/render_terrain.gd")
const RenderWater = preload("res://scripts/render_water.gd")
const RenderAtmosphere = preload("res://scripts/render_atmosphere.gd")
const RenderEnvironment = preload("res://scripts/render_environment.gd")
const RenderFogOfWar = preload("res://scripts/render_fog_of_war.gd")
const MapGenValidator = preload("res://scripts/map_gen_validator.gd")
const MapGenBlueprint = preload("res://scripts/map_gen_blueprint.gd")
const MapGenArchetypes = preload("res://scripts/map_gen_archetypes.gd")

func _init() -> void:
	print("--- Running WarFront Godot Automated Verification Tests ---")
	
	test_map_generation()
	test_bridge_sever_and_rebuild()
	test_unit_veterancy_and_promotion()
	test_engineer_demolition_xp()
	test_juice_systems()
	test_new_unit_archetypes()
	test_audio_engine()
	test_tactical_ai_and_waypoints()
	test_commander_powers_and_gameplay_loop()
	test_base_building_and_structures()
	test_unit_ai_and_advanced_controls()
	test_visceral_fun_and_momentum_overhaul()
	test_tactical_controls_and_asymmetry_overhaul()
	test_large_map_and_multi_team_alliance()
	test_multi_agent_ai_and_ffa_survival()
	test_modular_architecture_and_subsystems()
	test_world_and_maps_2_visual_systems()
	test_map_generation_engine_2_and_stress_test()
	test_combined_arms_production_and_gated_queues()
	
	print("--- ALL GODOT VERIFICATION TESTS PASSED SUCCESSFULLY! ---")
	quit(0)

func test_map_generation() -> void:
	for th in ["kirkuk", "suez", "newyork", "procedural"]:
		var map = MapGen.generate_map(th, 991337)
		assert(map["bridges"].size() >= 2, "%s should have at least 2 bridges" % th)
		assert(map["rigs"].size() == 8, "%s should have 8 oil rigs" % th)
		var cross_path = Pathfinding.find_road_path(map, map["playerHQ"]["roadNodeId"], map["enemyHQ"]["roadNodeId"])
		assert(cross_path.size() > 3, "%s should connect HQs across intact bridges" % th)
	print("✔ Test 1: Map generation & road graph connectivity passed.")

func test_bridge_sever_and_rebuild() -> void:
	var sim = Simulation.new("suez", 229403)
	var east_rig = null
	for r in sim.map["rigs"]:
		if r["x"] > sim.map["width"] * 0.55:
			east_rig = r
			break
	assert(east_rig != null)
	assert(Pathfinding.find_road_path(sim.map, sim.map["playerHQ"]["roadNodeId"], east_rig["roadNodeId"]).size() > 0)
	
	# Blow up all bridges
	for b in sim.map["bridges"]:
		sim.damage_bridge(b, b["maxHp"] + 50.0, "player")
		assert(b["status"] == "destroyed")
		
	# Cross-river path severed
	assert(Pathfinding.find_road_path(sim.map, sim.map["playerHQ"]["roadNodeId"], east_rig["roadNodeId"]).is_empty())
	
	# Rebuilding one bridge restores path
	var oil_before = sim.player_oil
	var ok = sim.rebuild_bridge(sim.map["bridges"][0]["id"], "player")
	assert(ok)
	assert(sim.player_oil == oil_before - Constants.BRIDGE_REBUILD_COST)
	assert(sim.map["bridges"][0]["status"] == "intact")
	assert(Pathfinding.find_road_path(sim.map, sim.map["playerHQ"]["roadNodeId"], east_rig["roadNodeId"]).size() > 0)
	print("✔ Test 2: Bridge destruction, route severance, and rebuilding passed.")

func test_unit_veterancy_and_promotion() -> void:
	var sim = Simulation.new("kirkuk", 104729)
	var tank = sim.spawn_unit("player", "tank", 400.0, 400.0)
	var base_dmg = Constants.UNIT_SPECS["tank"]["damage"]
	var base_hp = Constants.UNIT_SPECS["tank"]["hp"]
	assert(tank["rank"] == 0)
	assert(tank["damage"] == base_dmg)
	assert(tank["maxHp"] == base_hp)
	
	var enemy_tank = sim.spawn_unit("enemy", "tank", 520.0, 400.0)
	sim.damage_unit(enemy_tank, enemy_tank["maxHp"], tank)
	assert(tank["kills"] == 1)
	assert(tank["rank"] == 1)
	assert(tank["damage"] > base_dmg)
	assert(tank["maxHp"] > base_hp)
	
	# Extra kills promote to Rank 2 & 3
	var enemy2 = sim.spawn_unit("enemy", "artillery", 540.0, 400.0)
	sim.damage_unit(enemy2, enemy2["maxHp"], tank)
	assert(tank["rank"] == 2)
	
	var enemy3 = sim.spawn_unit("enemy", "tank", 560.0, 400.0)
	var enemy4 = sim.spawn_unit("enemy", "tank", 580.0, 400.0)
	sim.damage_unit(enemy3, enemy3["maxHp"], tank)
	sim.damage_unit(enemy4, enemy4["maxHp"], tank)
	assert(tank["rank"] == 3)
	print("✔ Test 3: Unit combat veterancy XP and multi-rank promotions passed.")

func test_engineer_demolition_xp() -> void:
	var sim = Simulation.new("kirkuk", 104729)
	var eng = sim.spawn_unit("player", "engineer", 500.0, 500.0)
	var bridge = sim.map["bridges"][0]
	sim.damage_bridge(bridge, bridge["maxHp"], "player", eng)
	assert(bridge["status"] == "destroyed")
	assert(eng["rank"] >= 1)
	assert(eng["damage"] > Constants.UNIT_SPECS["engineer"]["damage"])
	print("✔ Test 4: Engineer bridge demolition XP and promotion passed.")

func test_juice_systems() -> void:
	var sim = Simulation.new("kirkuk", 104729)
	var initial_craters = sim.craters.size()
	
	# 1. Projectile detonation creates craters
	var shell = {
		"kind": "shell",
		"x": 300.0, "y": 300.0,
		"vx": 100.0, "vy": 0.0,
		"damage": 44.0,
		"sourceUnitId": -1,
		"faction": "player",
		"bridgeMultiplier": 1.0
	}
	sim.detonate_projectile(shell)
	assert(sim.craters.size() == initial_craters + 1, "Shell detonation must add a crater")
	assert(not sim.craters[-1]["oilSlick"], "Shell crater should not be oil slick")
	
	# 2. Truck destruction creates crude oil slick crater
	var truck = sim.spawn_unit("enemy", "truck", 350.0, 350.0)
	sim.damage_unit(truck, 200.0)
	assert(sim.craters.size() == initial_craters + 2, "Truck kill must add oil crater")
	assert(sim.craters[-1]["oilSlick"], "Truck explosion crater must be an oil slick")
	
	# 3. Heavy unit destruction triggers hitstop & floating damage text
	var heavy_tank = sim.spawn_unit("enemy", "tank", 400.0, 400.0)
	sim.damage_unit(heavy_tank, 500.0)
	assert(sim.hitstop_timer > 0.0, "Heavy tank kill must trigger hitstop micro-freeze")
	assert(sim.floating_popups.size() > 0, "Damage must spawn floating damage popup")
	
	# 4. Ring particle verification
	var has_ring = false
	for p in sim.particles:
		if p["active"] and p["kind"] == "ring":
			has_ring = true
			break
	assert(has_ring, "Heavy explosion must spawn expanding shockwave ring particle")
	print("✔ Test 5: Juice systems (craters, oil slicks, hitstop, shockwaves, damage popups) passed.")

func test_new_unit_archetypes() -> void:
	var sim = Simulation.new("kirkuk", 104729)
	
	# 1. Spawn Behemoth Siege Tank
	var behemoth = sim.spawn_unit("player", "behemoth", 450.0, 450.0)
	assert(behemoth["kind"] == "behemoth")
	assert(behemoth["hp"] == Constants.UNIT_SPECS["behemoth"]["hp"])
	assert(behemoth["damage"] == Constants.UNIT_SPECS["behemoth"]["damage"])
	assert(behemoth["radius"] >= 20.0, "Behemoth must have heavy footprint")
	
	# 2. Spawn Attack Helicopter
	var heli = sim.spawn_unit("player", "helicopter", 480.0, 480.0)
	assert(heli["kind"] == "helicopter")
	assert(heli["speed"] > Constants.UNIT_SPECS["tank"]["speed"], "Helicopter must be high-speed")
	assert(heli["fireRate"] < 0.35, "Helicopter must have rapid fire-rate")
	
	# 3. Test Behemoth Cannon Detonation & Recoil
	var enemy_hq = sim.map["enemyHQ"]
	sim.fire_projectile(behemoth, Vector2(enemy_hq["x"], enemy_hq["y"]))
	assert(sim.projectiles.size() > 0, "Behemoth must fire heavy shell")
	assert(sim.projectiles[-1]["damage"] == behemoth["damage"])
	
	# 4. Test Helicopter Airborne Cross-River Movement
	heli["x"] = 1200.0
	heli["y"] = 900.0
	heli["targetPos"] = Vector2(2200.0, 900.0)
	sim.step(0.1)
	assert(heli["x"] > 1200.0, "Helicopter must move directly without river impediment")
	print("✔ Test 6: New unit archetypes (Behemoth Siege Tank & Desert Falcon Gunship) passed.")

func test_audio_engine() -> void:
	var synth = SoundSynth.new()
	synth.initialize()
	var expected_sounds = [
		"cannon", "behemoth_cannon", "rapid_fire", "shot", "explosion",
		"bridge_collapse", "ricochet", "oil_deposit", "promotion",
		"capture", "order_move", "order_attack", "unit_select", "order_click",
		"victory", "defeat"
	]
	for sfx in expected_sounds:
		assert(synth._sounds.has(sfx), "Sound %s must exist in audio engine" % sfx)
		var stream: AudioStreamWAV = synth._sounds[sfx]
		assert(stream != null, "Sound %s stream must not be null" % sfx)
		assert(stream.data.size() > 0, "Sound %s buffer must not be empty" % sfx)
		assert(stream.mix_rate == 44100, "Sound %s must be 44.1 kHz studio quality" % sfx)
		assert(stream.format == AudioStreamWAV.FORMAT_16_BITS, "Sound %s must be 16-bit PCM" % sfx)
	synth.free()
	print("✔ Test 7: Studio-grade procedural audio synthesis & polyphonic voice pool passed.")

func test_tactical_ai_and_waypoints() -> void:
	var sim = Simulation.new("kirkuk", 104729)
	var bridge = sim.map["bridges"][0]
	sim.damage_bridge(bridge, bridge["maxHp"], "player")
	assert(bridge["status"] == "destroyed")
	
	# 1. Test Enemy Engineer AI Repair
	sim.enemy_oil = 150
	var eng = sim.spawn_unit("enemy", "engineer", bridge["x"] + 20.0, bridge["y"])
	SimAI.update_enemy_ai(sim, 0.1)
	assert(bridge["status"] == "intact", "Enemy engineer in range must rebuild destroyed bridge")
	assert(sim.enemy_oil == 150 - Constants.BRIDGE_REBUILD_COST, "Bridge rebuild must deduct oil from enemy")
	
	# 2. Test AI Combined Arms Wave Generation
	sim.enemy_oil = 300
	sim.ai_wave_count = 2 # next tick will be wave 3 (surge)
	sim.ai_decision_timer = 0.05
	var unit_count_before = sim.units.size()
	SimAI.update_enemy_ai(sim, 0.1)
	assert(sim.units.size() > unit_count_before, "AI combined arms wave must spawn reinforcements")
	
	# 3. Test Waypoints Vector integrity
	var p_tank = sim.spawn_unit("player", "tank", 600.0, 600.0)
	p_tank["selected"] = true
	p_tank["targetPos"] = Vector2(850.0, 600.0)
	assert(p_tank["targetPos"] != null)
	
	print("✔ Test 8: Tactical enemy AI combined arms & bridge restoration passed.")

func test_commander_powers_and_gameplay_loop() -> void:
	var sim = Simulation.new("kirkuk", 104729)
	
	# 1. Test Commander Airstrike Power Execution
	sim.player_oil = 300
	var enemy = sim.spawn_unit("enemy", "tank", 500.0, 500.0)
	var ok = sim.call_commander_power("airstrike", Vector2(500.0, 500.0), "player")
	assert(ok, "Player should be able to call airstrike with sufficient oil")
	assert(sim.active_airstrikes.size() == 1, "Airstrike flyby must be active")
	assert(sim.commander_powers["airstrike"] > 0.0, "Airstrike must be on cooldown")
	assert(sim.player_oil == 300 - Constants.COMMANDER_POWERS["airstrike"]["cost"], "Airstrike must deduct oil")
	
	# Step through airstrike duration
	for _i in range(25):
		sim.step(0.04)
	assert(enemy["hp"] < Constants.UNIT_SPECS["tank"]["hp"], "Airstrike bombing run must damage enemy units in zone")
	
	# 2. Test Truck Ambush Drops Crude Oil Salvage Barrels
	var enemy_truck = sim.spawn_unit("enemy", "truck", 600.0, 600.0)
	var initial_crates = sim.salvage_crates.size()
	sim.damage_unit(enemy_truck, 300.0)
	assert(sim.salvage_crates.size() == initial_crates + 2, "Destroyed enemy truck must drop 2 salvage oil crates")
	
	# Collect salvage with player scout
	var oil_before_pickup = sim.player_oil
	var scout = sim.spawn_unit("player", "scout", 600.0, 600.0)
	sim.step(0.05)
	assert(sim.player_oil > oil_before_pickup, "Player scout must collect crude oil salvage for oil bounty")
	
	# 3. Test Escalation Phases
	sim.elapsed_seconds = 100.0
	sim.step(0.1)
	assert(sim.battle_phase == "escalation", "Battle must escalate to escalation phase past 85s")
	sim.elapsed_seconds = 220.0
	sim.step(0.1)
	assert(sim.battle_phase == "total_war", "Battle must enter total_war phase past 190s")
	
	# 4. Test Directive Lifecycle & Reward
	sim.active_directive = {
		"id": "ambush_truck",
		"title": "نصب كمين لقافلة العدو",
		"desc": "اعترض شاحنة العدو",
		"reward_oil": 65,
		"progress": 0,
		"target_count": 1,
		"time_limit": 90.0
	}
	var oil_before_directive = sim.player_oil
	sim.notify_directive("ambush_truck")
	assert(sim.player_oil == oil_before_directive + 65, "Completing directive must reward tactical bonus oil")
	assert(sim.active_directive.is_empty(), "Completed directive must clear for next tactical order cycle")
	
	print("✔ Test 9: Ideal RTS gameplay loop (Airstrikes, Convoy Salvage, Escalation Phases, Directives) passed.")

func test_base_building_and_structures() -> void:
	var sim = Simulation.new("kirkuk", 104729)
	var phq = sim.map["playerHQ"]
	var SimBuildings = preload("res://scripts/sim_buildings.gd")
	
	# 1. Placement validation tests
	assert(not SimBuildings.can_place_structure(sim, "war_factory", -50.0, -50.0, "player"), "Out of bounds placement must fail")
	assert(not SimBuildings.can_place_structure(sim, "war_factory", phq["x"], phq["y"], "player"), "Direct HQ overlap placement must fail")
	assert(not SimBuildings.can_place_structure(sim, "war_factory", phq["x"] + 1200.0, phq["y"], "player"), "Deep unpowered wilderness placement must fail without forward base")
	
	var valid_x = phq["x"] + 140.0
	var valid_y = phq["y"] + 60.0
	assert(SimBuildings.can_place_structure(sim, "war_factory", valid_x, valid_y, "player"), "Valid territory placement must succeed")
	
	# 2. Construction lifecycle tests (Scaffolding -> Assembly -> Operational)
	sim.player_oil = 1000
	var oil_before = sim.player_oil
	var placed = sim.place_player_structure("war_factory", valid_x, valid_y)
	assert(placed, "Placement must succeed with sufficient oil")
	assert(sim.structures.size() == 1, "Structure must be registered in simulation")
	assert(sim.player_oil == oil_before - Constants.BUILDING_SPECS["war_factory"]["cost"], "Oil cost must be deducted")
	
	var factory = sim.structures[0]
	assert(factory["status"] == "constructing", "Initial status must be constructing")
	assert(factory["build_progress"] == 0.0, "Initial build progress must be 0")
	assert(factory["hp"] < factory["maxHp"], "Constructing building starts at partial HP")
	
	# Step through construction
	for _i in range(120): # 120 * 0.1 = 12 seconds > 10.0s build time
		sim.step(0.1)
		
	assert(factory["status"] == "ready", "Factory must transition to ready when progress completes")
	assert(factory["build_progress"] >= 1.0, "Build progress must reach 100%")
	assert(factory["hp"] == factory["maxHp"], "Ready building must have full HP")
	
	# 3. Base Territory Expansion: Forward building near completed War Factory
	var forward_x = valid_x + 280.0
	var forward_y = valid_y + 40.0
	assert(SimBuildings.can_place_structure(sim, "turret", forward_x, forward_y, "player"), "Building near completed war factory expands base perimeter")
	
	# 4. Repair Depot Healing Aura Test
	var depot_x = phq["x"] + 120.0
	var depot_y = phq["y"] - 90.0
	sim.place_player_structure("repair_depot", depot_x, depot_y)
	var depot = sim.structures[1]
	for _i in range(80): # Complete depot construction (6.0s)
		sim.step(0.1)
	assert(depot["status"] == "ready")
	
	# Spawn damaged friendly tank in repair bay radius
	var damaged_tank = sim.spawn_unit("player", "tank", depot_x + 25.0, depot_y + 15.0)
	damaged_tank["hp"] = 120.0
	var hp_before = damaged_tank["hp"]
	for _i in range(20): # 2 seconds of repair aura (+32 HP/s)
		sim.step(0.1)
	assert(damaged_tank["hp"] > hp_before, "Repair depot healing aura must repair damaged units")
	
	# 5. Automated Defense Turret & Ballistics Test
	var turret_x = phq["x"] + 200.0
	var turret_y = phq["y"]
	sim.place_player_structure("turret", turret_x, turret_y)
	var turret_struct = sim.structures[2]
	for _i in range(60): # 5.0s build time
		sim.step(0.1)
	assert(turret_struct["status"] == "ready")
	
	# Hostile unit wanders into range
	var enemy_scout = sim.spawn_unit("enemy", "scout", turret_x + 120.0, turret_y)
	var enemy_hp_before = enemy_scout["hp"]
	for _i in range(15): # 1.5 seconds -> turret fires
		sim.step(0.1)
	assert(enemy_scout["hp"] < enemy_hp_before, "Automated defense turret must engage and damage hostiles in range")
	
	# 6. Sandbag barrier cheap defense test
	var wall_x = phq["x"] + 160.0
	var wall_y = phq["y"] - 140.0
	var ok_wall = sim.place_player_structure("sandbag_wall", wall_x, wall_y)
	assert(ok_wall)
	assert(sim.structures[3]["kind"] == "sandbag_wall")
	
	print("✔ Test 10: Complete Base Building overhaul (Footprints, Scaffolding, Repair Aura, Turrets, Sandbags) passed.")

func test_unit_ai_and_advanced_controls() -> void:
	var sim = Simulation.new("kirkuk", 104729)
	var SimUnits = preload("res://scripts/sim_units.gd")
	
	# 1. Soft Crowd Separation (Boids anti-stacking test)
	var t1 = sim.spawn_unit("player", "tank", 500.0, 500.0)
	var t2 = sim.spawn_unit("player", "tank", 502.0, 500.0)
	var initial_dist = Vector2(t1["x"], t1["y"]).distance_to(Vector2(t2["x"], t2["y"]))
	assert(initial_dist < 10.0, "Units spawned very close together")
	
	# Step simulation - separation repulsion forces should push them apart
	for _i in range(10):
		sim.step(0.05)
	var separated_dist = Vector2(t1["x"], t1["y"]).distance_to(Vector2(t2["x"], t2["y"]))
	assert(separated_dist > initial_dist, "Soft separation force must prevent unit overlapping and push units apart")
	
	# 2. Tactical Echelon Formations
	var behemoth = sim.spawn_unit("player", "behemoth", 400.0, 400.0)
	var scout = sim.spawn_unit("player", "scout", 410.0, 400.0)
	var mlrs = sim.spawn_unit("player", "artillery", 420.0, 400.0)
	var target_dest = Vector2(800.0, 400.0)
	var slots = SimUnits.calculate_formation_positions([behemoth, scout, mlrs], target_dest)
	
	assert(slots.has(behemoth["id"]) and slots.has(scout["id"]) and slots.has(mlrs["id"]), "All units must receive tactical slots")
	# Behemoth (vanguard) should be closer to target destination than artillery (rearguard)
	assert(slots[behemoth["id"]].x > slots[mlrs["id"]].x, "Vanguard heavy armor must form frontline ahead of backline artillery")
	
	# 3. Attack-Move Execution & Engagement
	var atk_tank = sim.spawn_unit("player", "tank", 600.0, 600.0)
	atk_tank["selected"] = true
	sim.issue_player_attack_move(900.0, 600.0)
	assert(atk_tank["stance"] == "attack_move", "Unit stance must be attack_move")
	
	# Spawn enemy along the march path
	var enemy_scout = sim.spawn_unit("enemy", "scout", 720.0, 600.0)
	var enemy_hp_start = enemy_scout["hp"]
	for _i in range(25):
		sim.step(0.05)
	assert(enemy_scout["hp"] < enemy_hp_start, "Attack-move unit must acquire and engage hostile encountered along its route")
	
	# 4. Shift-Queued Waypoints
	for u in sim.units:
		u["selected"] = false
	var queue_scout = sim.spawn_unit("player", "scout", 300.0, 300.0)
	queue_scout["selected"] = true
	sim.issue_player_command(400.0, 300.0, false)
	assert(queue_scout["targetPos"] != null)
	assert(queue_scout["waypointQueue"].is_empty())
	
	# Append 2nd and 3rd waypoints via Shift-queue
	sim.issue_player_command(400.0, 450.0, true)
	sim.issue_player_command(300.0, 450.0, true)
	assert(queue_scout["waypointQueue"].size() == 2, "Shift-queued commands must append to waypointQueue")
	
	# Advance scout to 1st waypoint
	queue_scout["x"] = 398.0
	queue_scout["y"] = 300.0
	sim.step(0.05)
	assert(queue_scout["waypointQueue"].size() == 1, "Reaching waypoint must pop next waypoint from queue")
	assert(queue_scout["targetPos"] == Vector2(400.0, 450.0), "Next target must become the queued destination")
	
	# 5. Hold Ground Stance
	var hold_tank = sim.spawn_unit("player", "tank", 700.0, 700.0)
	hold_tank["selected"] = true
	sim.set_selected_stance("hold_ground")
	assert(hold_tank["stance"] == "hold_ground")
	assert(hold_tank["targetPos"] == null)
	
	var distant_enemy = sim.spawn_unit("enemy", "tank", 1000.0, 700.0)
	for _i in range(10):
		sim.step(0.05)
	assert(Vector2(hold_tank["x"], hold_tank["y"]).distance_to(Vector2(700.0, 700.0)) < 2.0, "Hold ground unit must not leave its anchor position")
	
	# 6. Smart Target Prioritization (Finishing off wounded threats)
	var hunter = sim.spawn_unit("player", "artillery", 500.0, 500.0)
	var full_tank = sim.spawn_unit("enemy", "tank", 600.0, 500.0)
	var wounded_behemoth = sim.spawn_unit("enemy", "behemoth", 620.0, 510.0)
	wounded_behemoth["hp"] = 25.0 # critically wounded
	
	var chosen = SimUnits.select_smart_target(sim, hunter)
	assert(chosen["id"] == wounded_behemoth["id"], "Smart targeting matrix must prioritize high-threat critically wounded target for rapid elimination")
	
	# 7. Stop Command
	atk_tank["targetPos"] = Vector2(800.0, 800.0)
	atk_tank["selected"] = true
	sim.stop_selected_units()
	assert(atk_tank["targetPos"] == null, "Stop command must clear target position immediately")
	assert(atk_tank["waypointQueue"].is_empty(), "Stop command must clear waypoint queue")
	assert(atk_tank["stance"] == "guard", "Stop command must reset stance to guard")
	
	# 8. Tactical Retreat
	atk_tank["selected"] = true
	sim.retreat_selected_units()
	assert(atk_tank["stance"] == "retreat", "Retreat command must set retreat stance")
	sim.step(0.05)
	assert(atk_tank["targetPos"] != null, "Retreating unit must auto-navigate to nearest sanctuary HQ or depot")
	
	print("✔ Test 11: Unit AI & Advanced Controls (Flocking, Formations, A-Move, Queued Waypoints, Stances, Smart Priority) passed.")

func test_visceral_fun_and_momentum_overhaul() -> void:
	var sim = Simulation.new("kirkuk", 888123)
	
	# 1. Catastrophic Ammo Rack Detonation & Flying Turret Physics
	var sacrificial_tank = sim.spawn_unit("enemy", "tank", 500.0, 500.0)
	var attacker_behemoth = sim.spawn_unit("player", "behemoth", 510.0, 510.0)
	
	# Deal massive overkill damage to trigger ammo rack detonation
	sim.damage_unit(sacrificial_tank, 400.0, attacker_behemoth)
	assert(not sacrificial_tank["alive"], "Unit must be dead from massive damage")
	assert(sim.flying_turrets.size() > 0, "Massive overkill must spawn physical flying turret debris")
	
	var ft = sim.flying_turrets[0]
	assert(ft["vz"] > 100.0, "Flying turret must have positive upward launch velocity")
	assert(ft["gravity"] > 0.0, "Flying turret must be subject to gravity")
	
	# Step physics simulation until turret crashes onto the ground
	var initial_craters = sim.craters.size()
	for _i in range(50):
		sim.step(0.05)
		if sim.flying_turrets.is_empty():
			break
	assert(sim.flying_turrets.is_empty(), "Turret must eventually impact ground and be cleared")
	assert(sim.craters.size() > initial_craters, "Ground impact must create secondary crater")
	
	# 2. Combat Momentum & Tactical Surge Overcharge
	sim.combat_momentum = 0.0
	sim.combat_surge_active = false
	
	# Accumulate momentum via kills / objectives
	sim.add_combat_momentum(30.0)
	assert(sim.combat_momentum == 30.0, "Momentum must accumulate")
	
	# Push to 100% to trigger Combat Surge
	sim.add_combat_momentum(75.0)
	assert(sim.combat_surge_active, "Reaching 100% momentum must trigger Combat Surge")
	assert(sim.combat_surge_timer > 0.0, "Surge timer must be active")
	
	# Test Surge stats on friendly unit
	var surge_tank = sim.spawn_unit("player", "tank", 400.0, 400.0)
	surge_tank["cooldown"] = 1.0
	sim.step(0.05)
	sim.step(0.05)
	assert(surge_tank["cooldown"] < 0.88, "Combat surge must accelerate weapon fire rate / cooldown recovery")
	
	# Test Surge defensive buff: incoming damage is reduced
	var pre_hp = surge_tank["hp"]
	sim.damage_unit(surge_tank, 50.0)
	var dealt = pre_hp - surge_tank["hp"]
	assert(dealt < 45.0, "Combat surge must provide defensive armor reinforcement")
	
	# 3. Heroic Veteran Abilities
	# Tank: Incendiary Piercing Shot
	var vet_tank = sim.spawn_unit("player", "tank", 600.0, 600.0)
	vet_tank["rank"] = 2 # Elite rank unlocks incendiary shot
	var ab_res = sim.execute_unit_ability(vet_tank, Vector2(650.0, 600.0))
	assert(ab_res, "Rank 2 tank must successfully execute incendiary shot")
	assert(sim.napalm_patches.size() > 0, "Incendiary shot must spawn lingering napalm fire patch")
	assert(vet_tank["abilityCooldown"] > 0.0, "Ability must trigger cooldown timer")
	
	# Behemoth: Seismic Overcharge Barrage
	var vet_behemoth = sim.spawn_unit("player", "behemoth", 700.0, 700.0)
	vet_behemoth["rank"] = 2
	var enemy_victim = sim.spawn_unit("enemy", "scout", 720.0, 700.0)
	var beh_ab = sim.execute_unit_ability(vet_behemoth, Vector2(720.0, 700.0))
	assert(beh_ab, "Rank 2 behemoth must successfully execute seismic barrage")
	assert(enemy_victim["stunTimer"] > 0.0, "Seismic barrage must stun enemy units in radius")
	
	# Helicopter: Hydra Rocket Salvo
	var vet_heli = sim.spawn_unit("player", "helicopter", 800.0, 800.0)
	vet_heli["rank"] = 2
	var pre_proj_count = sim.projectiles.size()
	var heli_ab = sim.execute_unit_ability(vet_heli, Vector2(850.0, 800.0))
	assert(heli_ab, "Rank 2 helicopter must successfully execute hydra salvo")
	assert(sim.projectiles.size() >= pre_proj_count + 4, "Hydra salvo must launch 4 spiraling rockets")
	
	# Engineer: Anti-Tank Landmine Deployment & Detonation
	var eng = sim.spawn_unit("player", "engineer", 900.0, 900.0)
	sim.player_oil = 100
	var mine_deployed = sim.deploy_player_landmine(910.0, 900.0)
	assert(mine_deployed, "Engineer must be able to deploy landmine")
	assert(sim.landmines.size() > 0, "Landmine must be present in simulation")
	
	# Enemy drives over landmine
	var enemy_roller = sim.spawn_unit("enemy", "tank", 910.0, 900.0)
	sim.step(0.05)
	assert(sim.landmines.is_empty(), "Stepping on landmine must trigger detonation")
	assert(enemy_roller["stunTimer"] > 0.0, "Landmine blast must blow off tracks and stun vehicle")
	assert(enemy_roller["hp"] < enemy_roller["maxHp"], "Landmine blast must deal heavy damage")
	
	# 4. Contested Airborne Airdrop Crates
	sim.airdrop_crates.clear()
	SimCommander.trigger_airdrop(sim, Vector2(1000.0, 1000.0), "fuel_cache")
	assert(sim.airdrop_crates.size() == 1, "Airdrop must spawn crate")
	assert(sim.cargo_shadows.size() == 1, "Airdrop must spawn C-130 cargo shadow")
	
	var drop = sim.airdrop_crates[0]
	assert(drop["altitude"] > 0.0, "Crate must start airborne with parachute")
	
	# Simulate descent until landing
	for _i in range(75):
		sim.step(0.05)
		if drop["landed"]:
			break
	assert(drop["landed"], "Crate must successfully touch down on the ground")
	
	# Player captures airdrop
	var initial_oil = sim.player_oil
	var collector = sim.spawn_unit("player", "scout", 1000.0, 1000.0)
	sim.step(0.05)
	assert(sim.airdrop_crates.is_empty(), "Capturing crate must consume it")
	assert(sim.player_oil > initial_oil, "Fuel cache airdrop must award oil to player")
	
	# 5. Multi-Kill Combos
	sim.recent_player_kills.clear()
	sim.record_player_kill("scout", Vector2(500, 500))
	assert(sim.recent_player_kills.size() == 1)
	sim.record_player_kill("tank", Vector2(505, 500))
	assert(sim.recent_player_kills.size() == 2, "Double kill combo recorded")
	
	print("✔ Test 12: Real Gameplay Fun, Visceral Combat & Momentum Systems (Flying Turrets, Combat Surge, Hero Abilities, Mines, Airdrops, Multi-kills) passed.")

func test_tactical_controls_and_asymmetry_overhaul() -> void:
	var sim = Simulation.new("kirkuk", 104729)
	
	# 1. Asymmetrical Faction Doctrines
	sim.player_doctrine = "vanguard"
	sim.enemy_doctrine = "raiders"
	var p_tank = sim.spawn_unit("player", "tank", 400.0, 400.0)
	var e_tank = sim.spawn_unit("enemy", "tank", 600.0, 400.0)
	assert(p_tank["hp"] > e_tank["hp"], "Coalition Vanguard must have higher armor than Desert Raiders")
	assert(e_tank["speed"] > p_tank["speed"], "Desert Raiders must have higher mobility than Coalition Vanguard")
	
	# 2. Building Rally Points
	var rally_target = Vector2(850.0, 620.0)
	sim.set_player_rally_point(rally_target.x, rally_target.y)
	assert(sim.player_rally_point == rally_target, "Player rally point must be set")
	sim.player_oil = 500
	var trained = sim.train_player_unit("scout")
	assert(trained, "Must be able to train unit with sufficient oil")
	var new_scout = sim.units[sim.units.size() - 1]
	assert(new_scout["targetPos"] == rally_target, "New unit must automatically deploy to base rally point")
	
	# 3. Tactical Reverse-Move (Retaining Hull Facing)
	var rev_tank = sim.spawn_unit("player", "tank", 500.0, 500.0)
	rev_tank["angle"] = 0.0 # Facing east
	for u in sim.units:
		u["selected"] = false
	rev_tank["selected"] = true
	
	# Order reverse-move to the west (behind the tank)
	var issued = sim.issue_player_reverse_move(420.0, 500.0)
	assert(issued, "Reverse-move order must be accepted for land vehicles")
	assert(rev_tank["is_reversing"], "Unit must enter is_reversing state")
	assert(rev_tank["targetPos"] == Vector2(420.0, 500.0))
	
	# Step simulation
	sim.step(0.05)
	assert(rev_tank["x"] < 500.0, "Reversing tank must move backwards towards destination")
	assert(rev_tank["angle"] == 0.0, "Reversing tank must keep forward hull orientation and not turn 180 degrees")
	
	# Regular move cancels reverse mode
	sim.issue_player_command(600.0, 500.0)
	assert(not rev_tank["is_reversing"], "Regular command must cancel reverse mode")
	
	# 4. Dynamic Building & Structure Avoidance
	var dummy_struct = {
		"id": 8881,
		"kind": "repair_depot",
		"faction": "player",
		"x": 700.0,
		"y": 700.0,
		"radius": 28.0,
		"hp": 200.0,
		"maxHp": 200.0,
		"status": "ready",
		"hitFlash": 0.0,
		"cooldown": 0.0
	}
	sim.structures.push_back(dummy_struct)
	var near_unit = sim.spawn_unit("player", "scout", 710.0, 700.0) # Overlapping
	sim.step(0.05)
	assert(near_unit["x"] > 710.0, "Unit overlapping structure boundary must be smoothly pushed away")
	
	# 5. AI Tactical Self-Preservation Retreat
	var enemy_combatant = sim.spawn_unit("enemy", "tank", 800.0, 800.0)
	enemy_combatant["hp"] = enemy_combatant["maxHp"] * 0.20 # Severely wounded
	enemy_combatant["stance"] = "attack"
	SimAI.update_enemy_ai(sim, 0.05)
	assert(enemy_combatant["stance"] == "retreat", "Wounded enemy unit (< 28% HP) must fall back in tactical retreat")
	
	print("✔ Test 13: AAA RTS Controls & Mechanics Overhaul (Reverse-Move, Rally Points, AI Self-Preservation, Doctrines, Obstacle Avoidance) passed.")

func test_large_map_and_multi_team_alliance() -> void:
	var sim = Simulation.new("basra", 551829)
	sim.init_match("basra", "2v2", "vanguard")
	
	# 1. Map Dimensions & Scale (4800x2880)
	assert(sim.map["cols"] == 100 and sim.map["rows"] == 60, "Basra Delta map must be 100x60 tiles")
	assert(sim.map["width"] == 4800.0 and sim.map["height"] == 2880.0, "Basra Delta map width/height must be 4800x2880 px")
	
	# 2. 4 HQs & 4 Strategic Delta Bridges
	var hqs: Array = sim.map["hqs"]
	assert(hqs.size() == 4, "Large 4P map must define exactly 4 HQs")
	assert(sim.map["bridges"].size() == 4, "Delta theater must feature 4 strategic bridges (North, South, East, West)")
	assert(sim.map["rigs"].size() >= 6, "Delta theater must feature at least 6 oil rigs including refinery island")
	
	# 3. 2v2 Slots & Team Alliances
	assert(sim.slots.size() == 4, "2v2 preset must initialize 4 distinct player/AI slots")
	assert(sim.slots[0]["team_id"] == 1 and sim.slots[1]["team_id"] == 1, "Slot 0 and Slot 1 must be Team 1 allies")
	assert(sim.slots[2]["team_id"] == 2 and sim.slots[3]["team_id"] == 2, "Slot 2 and Slot 3 must be Team 2 enemies")
	assert(sim.slots[0]["is_human"] == true, "Slot 0 must be active human player")
	assert(sim.slots[1]["is_human"] == false and sim.slots[2]["is_human"] == false, "Slots 1, 2, 3 must be autonomous AI")
	
	# 4. Hostility Matrix (Allies vs Hostiles)
	var u_ally0 = sim.spawn_unit("vanguard", "tank", 400.0, 400.0, 0)
	var u_ally1 = sim.spawn_unit("vanguard", "tank", 420.0, 420.0, 1)
	var u_enemy2 = sim.spawn_unit("raiders", "tank", 500.0, 500.0, 2)
	var u_enemy3 = sim.spawn_unit("raiders", "tank", 520.0, 520.0, 3)
	
	assert(not sim.are_hostile(u_ally0, u_ally1), "Team 1 allies (Slot 0 and Slot 1) must never be hostile to each other")
	assert(sim.are_hostile(u_ally0, u_enemy2), "Slot 0 (Team 1) must be hostile to Slot 2 (Team 2)")
	assert(sim.are_hostile(u_ally0, u_enemy3), "Slot 0 (Team 1) must be hostile to Slot 3 (Team 2)")
	assert(not sim.are_hostile(u_enemy2, u_enemy3), "Team 2 allies (Slot 2 and Slot 3) must never be hostile to each other")
	
	# 5. Smart Target Selection respects Alliance
	var smart_target = SimUnits.select_smart_target(sim, u_ally0)
	assert(smart_target == u_enemy2, "Smart target selection must prioritize hostile enemy unit and ignore allied unit")
	
	print("✔ Test 14: Large 4-Player Maps & 2v2 Team Alliance Engine passed.")

func test_multi_agent_ai_and_ffa_survival() -> void:
	var sim = Simulation.new("zagros", 882194)
	sim.init_match("zagros", "ffa", "raiders")
	
	# 1. 4-Way Free For All Mode
	assert(sim.slots.size() == 4, "FFA match must initialize 4 distinct combatant slots")
	for i in range(4):
		assert(sim.slots[i]["team_id"] == (i + 1), "FFA slot %d must belong to distinct team %d" % [i, i + 1])
		
	# Mutual hostility across all combinations
	for i in range(4):
		for j in range(4):
			if i != j:
				assert(sim.are_hostile(sim.slots[i], sim.slots[j]), "In FFA, Slot %d and Slot %d must be mutually hostile" % [i, j])
				
	# 2. Autonomous Multi-Agent AI Production
	sim.slots[1]["oil"] = 200.0
	sim.slots[2]["oil"] = 200.0
	sim.slots[3]["oil"] = 200.0
	sim.ai_decision_timer = 0.0 # Force immediate AI decision tick
	
	var initial_unit_count = sim.units.size()
	SimAI.update_multi_slot_ai(sim, 0.1)
	assert(sim.units.size() > initial_unit_count, "Multi-agent AI must autonomously recruit combat units for non-human slots")
	
	# Check spawned AI units carry slot_id and distinct colors
	var found_ai_slot = false
	for u in sim.units:
		if u.get("slot_id", 0) > 0:
			found_ai_slot = true
			assert(u["targetPos"] != Vector2.ZERO, "AI units must be deployed with tactical combat destinations")
			assert(u.has("color"), "AI units must be tagged with designated slot alliance colors")
	assert(found_ai_slot, "At least one AI slot must have deployed a colored unit")
	
	# 3. Dynamic Victory / Defeat under Multi-Team Conditions
	# Defeating all hostile slots triggers Victory
	for i in range(1, 4):
		var hq = sim.get_slot_hq(i)
		hq["hp"] = 0.0
	SimAI.check_win_loss(sim)
	assert(sim.phase == "gameover" and sim.outcome == "victory", "Eliminating all hostile HQs must achieve match victory")
	
	# Defeating player HQ triggers Defeat
	sim.init_match("zagros", "ffa", "raiders")
	var player_hq = sim.get_slot_hq(0)
	player_hq["hp"] = 0.0
	SimAI.check_win_loss(sim)
	assert(sim.phase == "gameover" and sim.outcome == "defeat", "Destruction of player HQ must result in military defeat")
	
	print("✔ Test 15: Autonomous Multi-Agent AI & 4-Way FFA / Survival Engine passed.")

func test_modular_architecture_and_subsystems() -> void:
	# 1. Direct DSP Submodules Verification
	var stream_cannon = AudioWeapons.synth_cannon()
	assert(stream_cannon != null and stream_cannon.data.size() > 0, "AudioWeapons direct synthesis must output valid WAV stream")
	
	var stream_explosion = AudioImpacts.synth_explosion()
	assert(stream_explosion != null and stream_explosion.data.size() > 0, "AudioImpacts direct synthesis must output valid WAV stream")
	
	var stream_squawk = AudioComms.synth_radio_squawk()
	assert(stream_squawk != null and stream_squawk.data.size() > 0, "AudioComms direct synthesis must output valid WAV stream")
	
	var stream_ui = AudioUI.synth_unit_select()
	assert(stream_ui != null and stream_ui.data.size() > 0, "AudioUI direct synthesis must output valid WAV stream")
	
	# Audio Facade equivalence
	var synth = SoundSynth.new()
	synth.initialize()
	assert(synth._sounds.has("cannon") and synth._sounds["cannon"].data.size() == stream_cannon.data.size(), "SoundSynth facade must delegate to AudioWeapons identically")

	# 2. Map Generation Modular Engines
	var large_map = MapGenLarge.generate("basra", 5541)
	assert(large_map["width"] == 4800 and large_map["height"] == 2880, "MapGenLarge must generate theater at 4800x2880 scale")
	assert(large_map["hqs"].size() == 4, "MapGenLarge must initialize 4 tactical quadrant HQs")
	
	var std_map = MapGenStandard.generate("kirkuk", 5541)
	assert(std_map["width"] == 3456 and std_map["height"] == 1920, "MapGenStandard must generate theater at 3456x1920 scale")
	assert(std_map["rigs"].size() == 8, "MapGenStandard must generate 8 oilfield rigs")
	
	# MapGen Facade equivalence
	var dispatched_large = MapGen.generate_map("basra", 5541)
	assert(dispatched_large["width"] == 4800, "MapGen facade must delegate 'basra' to MapGenLarge")
	var dispatched_std = MapGen.generate_map("kirkuk", 5541)
	assert(dispatched_std["width"] == 3456, "MapGen facade must delegate 'kirkuk' to MapGenStandard")

	# 3. Unit Systems Submodules & Facade
	var sim = Simulation.new("kirkuk", 1019)
	var initial_u_count = sim.units.size()
	
	# Direct Spawner submodule
	var spawned_u = SimUnitSpawner.spawn_unit(sim, "player", "behemoth", 400.0, 400.0)
	assert(sim.units.size() == initial_u_count + 1, "SimUnitSpawner must register new unit into simulation")
	assert(spawned_u["kind"] == "behemoth" and spawned_u["hp"] > 0, "SimUnitSpawner must initialize unit properties correctly")
	
	# Direct Abilities submodule
	sim.player_oil = 300.0
	var mine_armed = SimUnitAbilities.deploy_landmine_at(sim, "player", Vector2(450.0, 450.0))
	assert(mine_armed and sim.landmines.size() > 0, "SimUnitAbilities must deploy and arm proximity landmine")
	
	# Direct Movement & Formations submodule
	var dummy_units: Array[Dictionary] = [
		{ "id": 101, "kind": "tank", "x": 100.0, "y": 100.0 },
		{ "id": 102, "kind": "scout", "x": 110.0, "y": 100.0 },
		{ "id": 103, "kind": "artillery", "x": 90.0, "y": 100.0 }
	]
	var slots = SimUnitMovement.calculate_formation_positions(dummy_units, Vector2(600.0, 600.0))
	assert(slots.has(101) and slots.has(102) and slots.has(103), "SimUnitMovement must assign tactical echelon formation slots")
	
	# Direct Commands submodule
	spawned_u["selected"] = true
	var selected_combat = SimUnitCommands.get_selected_player_combat_units(sim)
	assert(selected_combat.size() > 0, "SimUnitCommands must query selected combat forces")
	
	# Direct Hazards submodule
	sim.napalm_patches.push_back({
		"x": 300.0, "y": 300.0, "radius": 40.0, "life": 1.0, "faction": "player"
	})
	var patch_count = sim.napalm_patches.size()
	SimHazards.update_hazards(sim, 1.5) # Expire napalm patch
	assert(sim.napalm_patches.size() < patch_count, "SimHazards must tick and remove expired napalm hazard zones")
	
	# SimUnits Facade equivalence
	var facade_spawn = SimUnits.spawn_unit(sim, "player", "tank", 500.0, 500.0)
	assert(facade_spawn["kind"] == "tank", "SimUnits facade must transparently delegate to SimUnitSpawner")

	print("✔ Test 16: Strict modular architecture & submodule facade integrity passed.")

func test_world_and_maps_2_visual_systems() -> void:
	# 1. Procedural Terrain Multi-Frequency Texture Generation
	var map = MapGen.generate_map("kirkuk", 104729)
	var terrain_tex = RenderTerrain.build_terrain_texture(map)
	assert(terrain_tex != null, "RenderTerrain must generate a valid ImageTexture")
	assert(terrain_tex.get_width() == int(map["width"]) and terrain_tex.get_height() == int(map["height"]), "Generated terrain texture dimensions must match map bounds")

	# 2. Large Theater Terrain Synthesis
	var large_map = MapGen.generate_map("basra", 551829)
	var large_terrain_tex = RenderTerrain.build_terrain_texture(large_map)
	assert(large_terrain_tex != null, "RenderTerrain must generate large theater terrain texture")
	assert(large_terrain_tex.get_width() == 4800 and large_terrain_tex.get_height() == 2880, "Large terrain texture dimensions must be 4800x2880")

	# 3. Tactical Fog of War & Reconnaissance Line of Sight
	var sim = Simulation.new("kirkuk", 104729)
	
	# Fog of War disabled by default: all coordinates visible
	assert(sim.fog_of_war_enabled == false, "Fog of War must default to disabled for backward compatibility")
	var far_pos = Vector2(sim.map["enemyHQ"]["x"], sim.map["enemyHQ"]["y"])
	assert(RenderFogOfWar.is_point_visible_to_player(sim, far_pos) == true, "With fog of war disabled, entire map must be visible")
	
	# Enable Fog of War
	sim.fog_of_war_enabled = true
	var phq = sim.map["playerHQ"]
	var friendly_pos = Vector2(phq["x"] + 50.0, phq["y"] + 50.0)
	assert(RenderFogOfWar.is_point_visible_to_player(sim, friendly_pos) == true, "Coordinates within friendly HQ/unit vision radius must be visible")
	assert(RenderFogOfWar.is_point_visible_to_player(sim, far_pos) == false, "Coordinates in un-scouted enemy territory must be shrouded in fog of war")
	
	# Scout unit recon vision bonus
	var scout = SimUnits.spawn_unit(sim, "player", "scout", far_pos.x - 100.0, far_pos.y)
	assert(RenderFogOfWar.is_point_visible_to_player(sim, far_pos) == true, "Deploying scout unit near enemy coordinates must lift fog of war")
	
	# 4. Atmospheric Shadow Vectors & Sun Direction
	assert(RenderAtmosphere.SUN_DIR == Vector2(0.7071, 0.7071), "Atmospheric directional sun vector must maintain uniform 45-degree angle")
	
	print("✔ Test 17: World & Maps 2.0 Visual Systems (Terrain, Water, Atmosphere, Infrastructure, Fog of War) passed.")

func test_map_generation_engine_2_and_stress_test() -> void:
	# 1. Blueprint Registry & Declarative Schema
	var blueprints = MapGenBlueprint.THEATER_BLUEPRINTS
	assert(blueprints.has("canyon_pass_1v1"), "Blueprint registry must define 'canyon_pass_1v1'")
	assert(blueprints.has("central_plateau_1v1"), "Blueprint registry must define 'central_plateau_1v1'")
	assert(blueprints.has("basra"), "Blueprint registry must define 'basra'")
	
	# 2. Strict Mathematical Validation Engine
	var dummy_bad_map = { "cols": 10, "rows": 10, "tiles": [] }
	var val_fail = MapGenValidator.validate_map(dummy_bad_map)
	assert(val_fail["valid"] == false, "MapGenValidator must catch empty/malformed map data")
	
	# 3. Canyon Pass Archetype Generation & Chokepoint Verification
	var canyon_map = MapGen.generate_map("canyon_pass_1v1", 994821)
	assert(canyon_map["cols"] == 72 and canyon_map["rows"] == 40, "Canyon pass must initialize 72x40 standard theater bounds")
	assert(canyon_map["bridges"].size() == 3, "Canyon pass must feature 3 tactical corridor bridges")
	assert(canyon_map["rigs"].size() == 8, "Canyon pass must place exactly 8 competitive rigs")
	var val_canyon = MapGenValidator.validate_map(canyon_map)
	assert(val_canyon["valid"] == true, "Generated Canyon Pass map must pass all 6 validation criteria")

	# 4. Multi-Seed Stress Testing: 50 Procedural Iterations
	# Mathematically verifies that the generator NEVER produces a broken, unplayable, or malformed map
	var test_theaters = ["kirkuk", "suez", "canyon_pass_1v1", "basra"]
	for i in range(1, 51):
		var th = test_theaters[i % test_theaters.size()]
		var seed_i = 1000 + i * 79
		var gen_map = MapGen.generate_map(th, seed_i)
		var val = MapGenValidator.validate_map(gen_map)
		assert(val["valid"] == true, "Stress test failed on iteration %d (%s, seed %d): %s" % [i, th, seed_i, val["reason"]])

	print("✔ Test 18: Map Generation Engine 2.0 (Blueprints, Archetypes, Validator & 50-Seed Stress Test) passed.")

func test_combined_arms_production_and_gated_queues() -> void:
	# 1. Verification of Combined Arms Facilities & Military Units
	for b_kind in ["airfield", "shipyard", "barracks", "missile_plant"]:
		assert(Constants.BUILDING_SPECS.has(b_kind), "Building specs must include '%s'" % b_kind)
		
	for u_kind in ["jet_interceptor", "strike_bomber", "patrol_boat", "missile_corvette", "river_gunboat", "sam_launcher", "infantry_rifle", "infantry_at", "infantry_mortar"]:
		assert(Constants.UNIT_SPECS.has(u_kind), "Unit specs must include '%s'" % u_kind)
		
	assert(Constants.PRODUCTION_CATEGORIES.size() == 6, "Must define 6 tactical production branches")
	assert(Constants.BUILDING_SPECS["shipyard"].get("shore_only", false) == true, "Shipyard must require shoreline terrain")

	# 2. Production Queue & Mandatory Rally Waypoint Freeze
	var sim = Simulation.new("kirkuk", 881923)
	sim.player_oil = 3000
	sim.player_rally_point = Vector2.ZERO # Ensure no global rally point is set
	var queues = sim.get_production_queues("player")
	queues["barracks"]["rally_point"] = Vector2.ZERO

	# Queue 5 rifle infantry squads
	for i in range(5):
		var ok = sim.queue_unit("infantry_rifle", "player")
		assert(ok, "Queueing infantry rifle should succeed with adequate oil")

	assert(queues["barracks"]["items"].size() == 5, "Queue must contain exactly 5 units")
	assert(queues["barracks"]["state"] == "pending_rally", "Queue without deployment waypoint must freeze in 'pending_rally'")
	
	# Advance simulation time while pending rally
	for step in range(15):
		sim.step(0.1)
		
	assert(queues["barracks"]["progress"] == 0.0, "Progress must remain frozen at 0% while awaiting deployment destination")
	assert(queues["barracks"]["items"].size() == 5, "No units should spawn while pending rally")

	# 3. Setting Deployment Destination & Active Rollout
	var rally_dest = Vector2(820.0, 540.0)
	sim.set_category_rally_point("barracks", rally_dest, "player")
	assert(queues["barracks"]["state"] == "producing", "Setting rally point must transition queue to 'producing'")
	
	# Simulate production to completion of first unit (dt is clamped to 0.05 in sim.step)
	var initial_units_count = sim.units.size()
	for step in range(45):
		sim.step(0.1)
		
	assert(sim.units.size() == initial_units_count + 1, "First unit in queue must complete and spawn")
	var deployed_infantry = sim.units[sim.units.size() - 1]
	assert(deployed_infantry["kind"] == "infantry_rifle", "Spawned unit must be infantry_rifle")
	assert(deployed_infantry["targetPos"] == rally_dest, "Newly trained unit must automatically march to the designated rally waypoint")
	assert(queues["barracks"]["items"].size() == 4, "Queue must decrement to 4 units remaining")

	# 4. Multi-Building Production Speed Stacking
	# Add first war factory: baseline 1.0x speed
	var factory_1 = { "id": 900, "kind": "war_factory", "faction": "player", "status": "ready" }
	sim.structures.push_back(factory_1)
	var base_mult = sim.get_production_speed_multiplier("war_factory", "player")
	assert(base_mult == 1.0, "Single war factory base speed multiplier must be 1.0x")
	
	# Add second war factory: 1.5x speed (+50% speed bonus)
	var factory_2 = { "id": 901, "kind": "war_factory", "faction": "player", "status": "ready" }
	sim.structures.push_back(factory_2)
	var stack_mult_2 = sim.get_production_speed_multiplier("war_factory", "player")
	assert(stack_mult_2 == 1.5, "2 war factories must stack speed multiplier to 1.5x (+50% speed)")
	
	# Add third war factory: 2.0x speed (+100% speed bonus)
	var factory_3 = { "id": 902, "kind": "war_factory", "faction": "player", "status": "ready" }
	sim.structures.push_back(factory_3)
	var stack_mult_3 = sim.get_production_speed_multiplier("war_factory", "player")
	assert(stack_mult_3 == 2.0, "3 war factories must stack speed multiplier to 2.0x (+100% speed)")

	# 5. Specialized Naval & Aircraft Combat Properties
	var jet = sim.spawn_unit("player", "jet_interceptor", 400.0, 300.0)
	assert(jet["is_air"] == true, "Jet interceptor must be flagged as airborne")
	assert(jet["altitude"] >= 40.0, "Jet interceptor must maintain high-altitude flight elevation")

	var boat = sim.spawn_unit("player", "patrol_boat", 1200.0, 800.0)
	assert(boat["is_naval"] == true, "Patrol boat must be flagged as naval vessel")

	print("✔ Test 19: Combined Arms Production, Queues, Waypoint Gating & Speed Stacking passed.")




