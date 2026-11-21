class_name SimLogistics
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")

static func update_oil_rigs(sim, dt: float) -> void:
	for rig in sim.map["rigs"]:
		rig["pumpPhase"] += dt * (1.1 if rig["owner"] == "neutral" else 2.8)
		
		# Capture detection
		var player_power = 0.0
		var enemy_power = 0.0
		for u in sim.units:
			if not u["alive"] or u["kind"] == "truck" or u["kind"] == "turret":
				continue
			if Vector2(u["x"], u["y"]).distance_to(Vector2(rig["x"], rig["y"])) <= 88.0:
				var weight = 2.1 if u["kind"] == "engineer" else 1.0
				if u["faction"] == "player":
					player_power += weight
				else:
					enemy_power += weight
					
		if player_power > 0.0 and enemy_power == 0.0:
			rig["captureProgress"] = min(100.0, rig["captureProgress"] + dt * (22.0 + player_power * 10.0))
			if rig["captureProgress"] >= 100.0 and rig["owner"] != "player":
				rig["owner"] = "player"
				rig["captureFaction"] = "player"
				sim.sound_triggered.emit("capture")
				if sim.phase == "playing":
					sim.push_event("rig_captured", "good")
				sim.notify_directive("capture_rig")
				ensure_truck_for_rig(sim, "player", rig)
		elif enemy_power > 0.0 and player_power == 0.0:
			rig["captureProgress"] = max(-100.0, rig["captureProgress"] - dt * (22.0 + enemy_power * 10.0))
			if rig["captureProgress"] <= -100.0 and rig["owner"] != "enemy":
				var was_player = rig["owner"] == "player"
				rig["owner"] = "enemy"
				rig["captureFaction"] = "enemy"
				if was_player:
					sim.sound_triggered.emit("capture")
					if sim.phase == "playing":
						sim.push_event("rig_lost", "warn")
				ensure_truck_for_rig(sim, "enemy", rig)
				
		if rig["owner"] == "player" or rig["owner"] == "enemy":
			rig["storedBarrels"] = min(rig["maxBarrels"], rig["storedBarrels"] + dt * 9.5)
			rig["truckCooldown"] = max(0.0, rig["truckCooldown"] - dt)
			if rig["truckCooldown"] <= 0.0:
				ensure_truck_for_rig(sim, rig["owner"], rig)
				rig["truckCooldown"] = 7.5

static func ensure_truck_for_rig(sim, faction: String, rig: Dictionary) -> void:
	var existing = null
	for u in sim.units:
		if u["alive"] and u["kind"] == "truck" and u["faction"] == faction and u["assignedRigId"] == rig["id"]:
			existing = u
			break
	if existing == null:
		spawn_truck_for_rig(sim, faction, rig)

static func spawn_truck_for_rig(sim, faction: String, rig: Dictionary) -> Dictionary:
	var hq = sim.map["playerHQ"] if faction == "player" else sim.map["enemyHQ"]
	var path = Pathfinding.find_road_path(sim.map, hq["roadNodeId"], rig["roadNodeId"])
	var sx = hq["x"] + (32.0 if faction == "player" else -32.0)
	var truck = sim.spawn_unit(faction, "truck", sx, hq["y"])
	truck["assignedRigId"] = rig["id"]
	truck["targetRigNodeId"] = rig["roadNodeId"]
	
	if path.size() > 0:
		truck["truckState"] = "to_rig"
		truck["roadPath"] = path
		truck["roadPathIndex"] = 1
	else:
		truck["truckState"] = "stranded"
	return truck

static func update_truck(sim, u: Dictionary, dt: float) -> void:
	var hq = sim.map["playerHQ"] if u["faction"] == "player" else sim.map["enemyHQ"]
	var nodes: Dictionary = sim.map["roadNodes"]
	
	if u["truckState"] == "to_rig":
		if u["roadPathIndex"] < u["roadPath"].size():
			var target_node_id = u["roadPath"][u["roadPathIndex"]]
			var target_node = nodes.get(target_node_id)
			if target_node != null:
				var target_vec = Vector2(target_node["x"], target_node["y"])
				var cur_vec = Vector2(u["x"], u["y"])
				var d = cur_vec.distance_to(target_vec)
				if d < 12.0:
					u["roadPathIndex"] += 1
				else:
					var move_step = min(d, u["speed"] * dt)
					var dir = (target_vec - cur_vec).normalized()
					u["x"] += dir.x * move_step
					u["y"] += dir.y * move_step
					u["angle"] = dir.angle()
		else:
			# Arrived at oil rig, load barrels!
			var rig = null
			for r in sim.map["rigs"]:
				if r["id"] == u["assignedRigId"]:
					rig = r
					break
			if rig != null and rig["owner"] == u["faction"]:
				var pumped = min(rig["storedBarrels"], dt * 35.0)
				rig["storedBarrels"] -= pumped
				u["cargoOil"] += pumped
				if u["cargoOil"] >= Constants.TRUCK_CARGO_CAPACITY or rig["storedBarrels"] <= 2.0:
					var return_path = Pathfinding.find_road_path(sim.map, rig["roadNodeId"], hq["roadNodeId"])
					if return_path.size() > 0:
						u["truckState"] = "to_hq"
						u["roadPath"] = return_path
						u["roadPathIndex"] = 1
					else:
						u["truckState"] = "stranded"
			else:
				u["truckState"] = "stranded"
				
	elif u["truckState"] == "to_hq":
		if u["roadPathIndex"] < u["roadPath"].size():
			var target_node_id = u["roadPath"][u["roadPathIndex"]]
			var target_node = nodes.get(target_node_id)
			if target_node != null:
				var target_vec = Vector2(target_node["x"], target_node["y"])
				var cur_vec = Vector2(u["x"], u["y"])
				var d = cur_vec.distance_to(target_vec)
				if d < 12.0:
					u["roadPathIndex"] += 1
				else:
					var move_step = min(d, u["speed"] * dt)
					var dir = (target_vec - cur_vec).normalized()
					u["x"] += dir.x * move_step
					u["y"] += dir.y * move_step
					u["angle"] = dir.angle()
		else:
			# Deposited oil into HQ reserve!
			var delivered = int(round(u["cargoOil"]))
			if delivered > 0:
				if u["faction"] == "player":
					sim.player_oil += delivered
					sim.player_oil_delivered += delivered
					sim.sound_triggered.emit("oil_deposit")
					sim.spawn_floating_text(hq["x"] + 30.0, hq["y"] - 20.0, "+%d OIL" % delivered, Color("#f5c94c"), 1.4)
				else:
					sim.enemy_oil += delivered
				u["cargoOil"] = 0.0
			# Return to rig
			var rig = null
			for r in sim.map["rigs"]:
				if r["id"] == u["assignedRigId"]:
					rig = r
					break
			if rig != null and rig["owner"] == u["faction"]:
				var next_path = Pathfinding.find_road_path(sim.map, hq["roadNodeId"], rig["roadNodeId"])
				if next_path.size() > 0:
					u["truckState"] = "to_rig"
					u["roadPath"] = next_path
					u["roadPathIndex"] = 1
				else:
					u["truckState"] = "stranded"
			else:
				u["truckState"] = "stranded"

static func reroute_stranded_trucks(sim) -> void:
	for u in sim.units:
		if not u["alive"] or u["kind"] != "truck":
			continue
		var hq = sim.map["playerHQ"] if u["faction"] == "player" else sim.map["enemyHQ"]
		var rig = null
		for r in sim.map["rigs"]:
			if r["id"] == u["assignedRigId"]:
				rig = r
				break
		if rig == null or rig["owner"] != u["faction"]:
			continue
			
		if u["truckState"] == "stranded":
			var path_to_rig = Pathfinding.find_road_path(sim.map, hq["roadNodeId"], rig["roadNodeId"])
			if path_to_rig.size() > 0:
				u["truckState"] = "to_rig"
				u["roadPath"] = path_to_rig
				u["roadPathIndex"] = 1
