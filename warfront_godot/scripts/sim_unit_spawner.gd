class_name SimUnitSpawner
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const SimLogistics = preload("res://scripts/sim_logistics.gd")

static func spawn_unit(sim, faction: String, kind: String, x: float, y: float, slot_idx: int = -1) -> Dictionary:
	var spec = Constants.UNIT_SPECS[kind]
	var doctrine_id = sim.player_doctrine if faction == "player" else sim.enemy_doctrine
	var doctrine = Constants.FACTION_DOCTRINES.get(doctrine_id, {})
	var hp_mult = doctrine.get("hp_mult", 1.0)
	var speed_mult = doctrine.get("speed_mult", 1.0)
	var damage_mult = doctrine.get("damage_mult", 1.0)
	
	var base_hp = round(spec["hp"] * hp_mult) if doctrine.size() > 0 else spec["hp"]
	var base_speed = spec["speed"] * speed_mult if doctrine.size() > 0 else spec["speed"]
	var base_dmg = round(spec["damage"] * damage_mult) if doctrine.size() > 0 else spec["damage"]
	
	if slot_idx == -1:
		slot_idx = sim.active_human_slot if faction == "player" else (1 if sim.slots.size() <= 2 else 2)
		
	var team_id = 1 if faction == "player" else 2
	var col = Color("#22c55e") if faction == "player" else Color("#ef4444")
	if slot_idx >= 0 and slot_idx < sim.slots.size():
		team_id = sim.slots[slot_idx]["team_id"]
		col = sim.slots[slot_idx]["color"]

	var unit = {
		"id": sim.next_unit_id,
		"faction": faction,
		"slot_id": slot_idx,
		"team_id": team_id,
		"color": col,
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
		"assignedRigId": -1,
		"is_air": spec.get("is_air", false) or kind == "helicopter",
		"altitude": spec.get("altitude", 36.0 if kind == "helicopter" else 0.0),
		"is_naval": spec.get("is_naval", false),
		"is_aa": spec.get("is_aa", false),
		"isIndirect": spec.get("isIndirect", false),
		"category": spec.get("category", "war_factory"),
		"captureBonus": spec.get("captureBonus", 1.0)
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
