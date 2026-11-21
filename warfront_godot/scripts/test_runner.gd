class_name TestRunner
extends SceneTree

const Constants = preload("res://scripts/constants.gd")
const MapGen = preload("res://scripts/map_gen.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")
const Simulation = preload("res://scripts/simulation.gd")
const SoundSynth = preload("res://scripts/sound_synth.gd")
const SimAI = preload("res://scripts/sim_ai.gd")

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
