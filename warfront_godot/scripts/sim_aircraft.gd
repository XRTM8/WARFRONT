class_name SimAircraft
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func update_aircraft(sim, u: Dictionary, dt: float) -> void:
	if not u.get("is_air", false) or not u.get("alive", true):
		return
		
	var kind = u.get("kind", "")
	
	# 1. Jet Afterburner & High Speed Flight Trails
	if kind in ["jet_interceptor", "strike_bomber"]:
		var angle = u.get("angle", 0.0)
		var tail_offset = Vector2(-cos(angle), -sin(angle)) * (u.get("radius", 16.0) * 1.1)
		# Afterburner heat shimmer
		if randf() < 0.45:
			var flame_col = Color("#38bdf8") if kind == "jet_interceptor" else Color("#f97316")
			sim.spawn_particle("fire", u["x"] + tail_offset.x, u["y"] + tail_offset.y,
				-cos(angle) * 35.0 + randf_range(-6, 6), -sin(angle) * 35.0 + randf_range(-6, 6),
				2.0, 4.5, 0.22, flame_col)
				
	# 2. Air Superiority Target Scanning for Interceptor
	if kind == "jet_interceptor":
		_scan_air_targets(sim, u)
		
	# 3. Dedicated Bombing Run for Strike Bomber
	elif kind == "strike_bomber":
		_scan_ground_targets(sim, u)

static func _scan_air_targets(sim, u: Dictionary) -> void:
	# Prioritize enemy aircraft
	var cur_target = u.get("targetEntityId")
	if cur_target != null:
		return
		
	var best_dist = u.get("range", 240.0)
	var best_target_id = null
	
	for other in sim.units:
		if not other.get("alive", true) or not other.get("is_air", false):
			continue
		if not sim.is_entity_hostile(u, other):
			continue
			
		var d = Vector2(u["x"], u["y"]).distance_to(Vector2(other["x"], other["y"]))
		if d <= best_dist:
			best_dist = d
			best_target_id = other["id"]
			
	if best_target_id != null:
		u["targetEntityId"] = best_target_id

static func _scan_ground_targets(sim, u: Dictionary) -> void:
	# Strike bomber targets enemy buildings and heavy vehicles
	if u.get("targetEntityId") != null:
		return
		
	var best_dist = u.get("range", 200.0)
	var best_target_id = null
	
	for other in sim.units:
		if not other.get("alive", true) or other.get("is_air", false):
			continue
		if not sim.is_entity_hostile(u, other):
			continue
		if other["kind"] in ["tank", "behemoth", "artillery", "sam_launcher"]:
			var d = Vector2(u["x"], u["y"]).distance_to(Vector2(other["x"], other["y"]))
			if d <= best_dist:
				best_dist = d
				best_target_id = other["id"]
				
	if best_target_id != null:
		u["targetEntityId"] = best_target_id

static func filter_aa_target(u: Dictionary, other: Dictionary) -> bool:
	# Units with is_aa == true strongly prioritize airborne targets
	if u.get("is_aa", false):
		return other.get("is_air", false)
	return true
