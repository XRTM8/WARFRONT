class_name SimProductionQueue
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func init_production_system(sim) -> void:
	if not sim.has_meta("production_queues"):
		var queues = {
			"player": _create_empty_category_dict(),
			"enemy": _create_empty_category_dict()
		}
		sim.set_meta("production_queues", queues)

static func _create_empty_category_dict() -> Dictionary:
	var d = {}
	for cat in ["barracks", "war_factory", "airfield", "shipyard", "missile_plant"]:
		d[cat] = {
			"items": [],
			"rally_point": Vector2.ZERO,
			"state": "idle", # "idle", "pending_rally", "producing"
			"progress": 0.0,
			"current_unit": "",
			"current_timer": 0.0,
			"current_total_time": 1.0
		}
	return d

static func get_queues(sim, faction: String = "player") -> Dictionary:
	init_production_system(sim)
	var all_queues = sim.get_meta("production_queues")
	if not all_queues.has(faction):
		all_queues[faction] = _create_empty_category_dict()
	return all_queues[faction]

static func get_facility_count(sim, faction: String, facility_kind: String) -> int:
	var count = 0
	for s in sim.structures:
		if s["faction"] == faction and s["kind"] == facility_kind and s.get("status", "") == "ready":
			count += 1
	return count

static func get_speed_multiplier(sim, faction: String, category_id: String) -> float:
	var count = get_facility_count(sim, faction, category_id)
	# Stacking formula: 1 facility = 1.0x, each extra +0.5x speed
	if count <= 1:
		return 1.0
	return 1.0 + 0.5 * float(count - 1)

static func get_unit_category(kind: String) -> String:
	if Constants.UNIT_SPECS.has(kind):
		var spec = Constants.UNIT_SPECS[kind]
		if spec.has("category"):
			return spec["category"]
	if kind in ["scout", "tank", "behemoth"]:
		return "war_factory"
	elif kind in ["artillery", "sam_launcher"]:
		return "missile_plant"
	elif kind in ["helicopter", "jet_interceptor", "strike_bomber"]:
		return "airfield"
	elif kind in ["patrol_boat", "missile_corvette", "river_gunboat"]:
		return "shipyard"
	elif kind in ["infantry_rifle", "infantry_at", "infantry_mortar", "engineer"]:
		return "barracks"
	return "war_factory"

static func queue_unit(sim, faction: String, kind: String) -> bool:
	if not Constants.UNIT_SPECS.has(kind):
		return false
	var spec = Constants.UNIT_SPECS[kind]
	var cost = spec.get("cost", 100)
	
	if faction == "player":
		if sim.player_oil < cost:
			sim.push_event("not_enough_oil", "warn")
			return false
		sim.player_oil -= cost
	else:
		if sim.enemy_oil < cost:
			return false
		sim.enemy_oil -= cost

	var category = get_unit_category(kind)
	var queues = get_queues(sim, faction)
	var cat_data = queues[category]
	
	# Determine effective rally point (inherit global player rally point if set)
	if cat_data["rally_point"] == Vector2.ZERO:
		if faction == "player" and sim.player_rally_point != Vector2.ZERO:
			cat_data["rally_point"] = sim.player_rally_point
	
	var base_time = spec.get("build_time", 3.0)
	var item = {
		"kind": kind,
		"cost": cost,
		"base_time": base_time
	}
	cat_data["items"].push_back(item)
	
	# If currently idle, check if rally point exists
	if cat_data["state"] == "idle":
		if cat_data["rally_point"] == Vector2.ZERO:
			cat_data["state"] = "pending_rally"
		else:
			_start_next_item(sim, faction, category)
			
	return true

static func set_category_rally_point(sim, faction: String, category: String, point: Vector2) -> void:
	var queues = get_queues(sim, faction)
	if not queues.has(category):
		return
	var cat_data = queues[category]
	cat_data["rally_point"] = point
	
	# If pending rally, start production immediately
	if cat_data["state"] == "pending_rally" and cat_data["items"].size() > 0:
		_start_next_item(sim, faction, category)

static func cancel_queued_unit(sim, faction: String, category: String, index: int = -1) -> bool:
	var queues = get_queues(sim, faction)
	if not queues.has(category):
		return false
	var cat_data = queues[category]
	if cat_data["items"].is_empty():
		return false
		
	var idx = index if index >= 0 and index < cat_data["items"].size() else cat_data["items"].size() - 1
	var item = cat_data["items"][idx]
	# Refund oil
	if faction == "player":
		sim.player_oil += item["cost"]
	else:
		sim.enemy_oil += item["cost"]
		
	cat_data["items"].remove_at(idx)
	if cat_data["items"].is_empty():
		cat_data["state"] = "idle"
		cat_data["progress"] = 0.0
		cat_data["current_unit"] = ""
	elif idx == 0:
		_start_next_item(sim, faction, category)
	return true

static func _start_next_item(sim, faction: String, category: String) -> void:
	var cat_data = get_queues(sim, faction)[category]
	if cat_data["items"].is_empty():
		cat_data["state"] = "idle"
		cat_data["progress"] = 0.0
		cat_data["current_unit"] = ""
		return
		
	if cat_data["rally_point"] == Vector2.ZERO:
		cat_data["state"] = "pending_rally"
		cat_data["progress"] = 0.0
		return
		
	var item = cat_data["items"][0]
	var speed_mult = get_speed_multiplier(sim, faction, category)
	var final_time = max(0.5, item["base_time"] / speed_mult)
	
	cat_data["state"] = "producing"
	cat_data["current_unit"] = item["kind"]
	cat_data["current_total_time"] = final_time
	cat_data["current_timer"] = final_time
	cat_data["progress"] = 0.0

static func tick_production(sim, dt: float) -> void:
	init_production_system(sim)
	for faction in ["player", "enemy"]:
		var queues = get_queues(sim, faction)
		for cat in queues.keys():
			var cat_data = queues[cat]
			if cat_data["state"] != "producing":
				continue
				
			cat_data["current_timer"] -= dt
			var total = cat_data["current_total_time"]
			cat_data["progress"] = clamp(1.0 - (cat_data["current_timer"] / total), 0.0, 1.0)
			
			if cat_data["current_timer"] <= 0.0:
				_complete_unit(sim, faction, cat)

static func _complete_unit(sim, faction: String, category: String) -> void:
	var cat_data = get_queues(sim, faction)[category]
	if cat_data["items"].is_empty():
		cat_data["state"] = "idle"
		return
		
	var item = cat_data["items"][0]
	cat_data["items"].remove_at(0)
	var kind = item["kind"]
	
	# Determine spawn position
	var spawn_pos = _find_spawn_position(sim, faction, category)
	var u = sim.spawn_unit(faction, kind, spawn_pos.x, spawn_pos.y)
	
	var rally = cat_data["rally_point"]
	if rally != Vector2.ZERO:
		u["targetPos"] = rally
		u["guardPos"] = rally
		u["stance"] = "guard"
		
	sim.spawn_burst(spawn_pos.x, spawn_pos.y, "smoke", 6, Color("#b8aa8f"), 40.0)
	if faction == "player":
		sim.sound_triggered.emit("unit_ready")
		
	# Proceed with next item
	_start_next_item(sim, faction, category)

static func _find_spawn_position(sim, faction: String, category: String) -> Vector2:
	# Prefer an active structure belonging to this category
	var structure_kind = Constants.PRODUCTION_CATEGORIES[category].get("structure", "")
	for s in sim.structures:
		if s["faction"] == faction and s["kind"] == structure_kind and s.get("status", "") == "ready":
			var offset = Vector2(s["width"] * 0.5 + 16.0, randf_range(-10, 10))
			return Vector2(s["x"] + offset.x, s["y"] + offset.y)
			
	# Fallback to HQ
	var hq = sim.map["playerHQ"] if faction == "player" else sim.map["enemyHQ"]
	var angle = randf_range(-0.5, 0.5)
	var dir = 1.0 if faction == "player" else -1.0
	return Vector2(hq["x"] + dir * 80.0, hq["y"] + sin(angle) * 45.0)
