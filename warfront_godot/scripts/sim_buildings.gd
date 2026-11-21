class_name SimBuildings
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")

static func can_place_structure(sim, kind: String, x: float, y: float, faction: String = "player") -> bool:
	if not Constants.BUILDING_SPECS.has(kind):
		return false
	var spec = Constants.BUILDING_SPECS[kind]
	var rad: float = spec["radius"]
	var map = sim.map
	
	# 1. Bounds check
	if x - rad < 40.0 or x + rad > map["width"] - 40.0:
		return false
	if y - rad < 40.0 or y + rad > map["height"] - 40.0:
		return false
		
	# 2. Land tile check (cannot build inside water)
	var ts = Constants.TILE_SIZE
	var col = int(x / ts)
	var row = int(y / ts)
	if col < 0 or col >= map["cols"] or row < 0 or row >= map["rows"]:
		return false
	var tile = map["tiles"][row * map["cols"] + col]
	if tile == "water":
		return false
		
	# Check 4 footprint corners
	for ox in [-rad * 0.7, rad * 0.7]:
		for oy in [-rad * 0.7, rad * 0.7]:
			var c_idx = int((x + ox) / ts)
			var r_idx = int((y + oy) / ts)
			if c_idx >= 0 and c_idx < map["cols"] and r_idx >= 0 and r_idx < map["rows"]:
				if map["tiles"][r_idx * map["cols"] + c_idx] == "water":
					return false

	# 3. Overlap check with HQs
	for hq in [map["playerHQ"], map["enemyHQ"]]:
		if Vector2(x, y).distance_to(Vector2(hq["x"], hq["y"])) < rad + 50.0:
			return false

	# 4. Overlap check with oil rigs & bridges
	for rig in map.get("rigs", []):
		if Vector2(x, y).distance_to(Vector2(rig["x"], rig["y"])) < rad + 40.0:
			return false
	for b in map.get("bridges", []):
		if Vector2(x, y).distance_to(Vector2(b["x"], b["y"])) < rad + 36.0:
			return false

	# 5. Overlap check with existing structures
	for s in sim.structures:
		if Vector2(x, y).distance_to(Vector2(s["x"], s["y"])) < rad + s["radius"] + 6.0:
			return false

	# 6. Base Territory / Build Radius check (must be within 450px of friendly HQ or friendly War Factory)
	var in_range = false
	var friendly_hq = map["playerHQ"] if faction == "player" else map["enemyHQ"]
	if Vector2(x, y).distance_to(Vector2(friendly_hq["x"], friendly_hq["y"])) <= 460.0:
		in_range = true
	else:
		for s in sim.structures:
			if s["faction"] == faction and s["status"] == "ready" and s["kind"] == "war_factory":
				if Vector2(x, y).distance_to(Vector2(s["x"], s["y"])) <= 380.0:
					in_range = true
					break

	return in_range

static func place_structure(sim, kind: String, x: float, y: float, faction: String = "player") -> bool:
	if not can_place_structure(sim, kind, x, y, faction):
		if faction == "player":
			sim.push_event("invalid_placement", "warn")
		return false
		
	var spec = Constants.BUILDING_SPECS[kind]
	var cost = spec["cost"]
	if faction == "player":
		if sim.player_oil < cost:
			sim.push_event("not_enough_oil", "warn")
			sim.build_mode = "none"
			return false
		sim.player_oil -= cost
	else:
		if sim.enemy_oil < cost:
			return false
		sim.enemy_oil -= cost

	var struct = {
		"id": randi(),
		"kind": kind,
		"faction": faction,
		"x": x,
		"y": y,
		"hp": spec["hp"] * 0.25, # starts at partial hp while under construction
		"maxHp": spec["hp"],
		"radius": spec["radius"],
		"width": spec["width"],
		"height": spec["height"],
		"status": "constructing",
		"build_progress": 0.0,
		"build_time": spec["build_time"],
		"cooldown": 0.0,
		"hitFlash": 0.0,
		"turretAngle": 0.0 if faction == "player" else PI
	}
	sim.structures.push_back(struct)
	sim.spawn_burst(x, y, "debris", 12, Color("#69645b"), 80.0)
	sim.sound_triggered.emit("capture")
	if faction == "player":
		sim.build_mode = "none"
		sim.push_event("structure_placed", "good")
		
	return true

static func update_structures(sim, dt: float) -> void:
	for i in range(sim.structures.size() - 1, -1, -1):
		var s = sim.structures[i]
		if s.get("hitFlash", 0.0) > 0.0:
			s["hitFlash"] = max(0.0, s["hitFlash"] - dt)
		if s.get("cooldown", 0.0) > 0.0:
			s["cooldown"] = max(0.0, s["cooldown"] - dt)
			
		# 1. Construction Progress
		if s["status"] == "constructing":
			s["build_progress"] += dt / s["build_time"]
			s["hp"] = s["maxHp"] * (0.25 + s["build_progress"] * 0.75)
			if randf() < 0.22:
				sim.spawn_particle("spark", s["x"] + randf_range(-14, 14), s["y"] + randf_range(-14, 14), randf_range(-10, 10), -15.0, 2.0, 4.0, 0.25, Color("#fde047"))
			if s["build_progress"] >= 1.0:
				s["build_progress"] = 1.0
				s["status"] = "ready"
				s["hp"] = s["maxHp"]
				sim.spawn_burst(s["x"], s["y"], "spark", 14, Color("#ffd659"), 90.0)
				sim.sound_triggered.emit("unit_ready")
				if s["faction"] == "player":
					sim.push_event("structure_ready", "good")
			continue

		# 2. Active Operational Behaviors
		if s["kind"] == "repair_depot":
			# Repair Bay Healing Aura (Heals self and all allied units)
			for u in sim.units:
				if u["alive"] and not sim.are_hostile(s, u) and u["kind"] != "turret" and u["hp"] < u["maxHp"]:
					if Vector2(u["x"], u["y"]).distance_to(Vector2(s["x"], s["y"])) <= Constants.BUILDING_SPECS["repair_depot"]["heal_radius"]:
						var heal = Constants.BUILDING_SPECS["repair_depot"]["heal_rate"] * dt
						u["hp"] = min(u["maxHp"], u["hp"] + heal)
						if randf() < 0.18:
							sim.spawn_particle("spark", u["x"] + randf_range(-6, 6), u["y"] + randf_range(-6, 6), randf_range(-10, 10), -12.0, 1.5, 3.5, 0.22, Color("#38bdf8"))
							
		elif s["kind"] == "turret":
			# Automated Point Defense Gun
			if s["cooldown"] <= 0.0:
				var target = _find_nearest_hostile(sim, s, Vector2(s["x"], s["y"]), Constants.BUILDING_SPECS["turret"]["range"])
				if target != null:
					var dir = (Vector2(target["x"], target["y"]) - Vector2(s["x"], s["y"])).normalized()
					s["turretAngle"] = dir.angle()
					sim.fire_projectile({
						"id": s["id"],
						"x": s["x"],
						"y": s["y"],
						"turretAngle": s["turretAngle"],
						"faction": s["faction"],
						"damage": Constants.BUILDING_SPECS["turret"]["damage"],
						"kind": "turret"
					}, Vector2(target["x"], target["y"]))
					s["cooldown"] = Constants.BUILDING_SPECS["turret"]["fireRate"]

		elif s["kind"] == "missile_battery":
			# Heavy Guided Missile Battery
			if s["cooldown"] <= 0.0:
				var target = _find_nearest_hostile(sim, s, Vector2(s["x"], s["y"]), Constants.BUILDING_SPECS["missile_battery"]["range"])
				if target != null:
					var dir = (Vector2(target["x"], target["y"]) - Vector2(s["x"], s["y"])).normalized()
					s["turretAngle"] = dir.angle()
					sim.fire_projectile({
						"id": s["id"],
						"x": s["x"],
						"y": s["y"],
						"turretAngle": s["turretAngle"],
						"faction": s["faction"],
						"damage": Constants.BUILDING_SPECS["missile_battery"]["damage"],
						"kind": "artillery"
					}, Vector2(target["x"], target["y"]))
					s["cooldown"] = Constants.BUILDING_SPECS["missile_battery"]["fireRate"]

static func _find_nearest_hostile(sim, source: Variant, pos: Vector2, max_range: float) -> Variant:
	var best_target = null
	var best_d = max_range
	for u in sim.units:
		if u["alive"] and sim.are_hostile(source, u):
			var d = pos.distance_to(Vector2(u["x"], u["y"]))
			if d <= best_d:
				best_d = d
				best_target = u
	return best_target
