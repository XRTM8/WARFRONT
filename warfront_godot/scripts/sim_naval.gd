class_name SimNaval
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func update_naval_unit(sim, u: Dictionary, dt: float) -> void:
	if not u.get("is_naval", false) or not u.get("alive", true):
		return
		
	var map = sim.map
	if map.is_empty():
		return
		
	var ts = Constants.TILE_SIZE
	var cur_col = int(u["x"] / ts)
	var cur_row = int(u["y"] / ts)
	
	# Spawn water wake foam behind the boat when moving
	if u.get("targetPos") != null:
		var move_speed = u.get("speed", 100.0)
		var angle = u.get("angle", 0.0)
		var stern_offset = Vector2(-cos(angle), -sin(angle)) * (u.get("radius", 16.0) * 0.9)
		if randf() < 0.35:
			sim.spawn_particle("spark", u["x"] + stern_offset.x, u["y"] + stern_offset.y, 
				randf_range(-8, 8), randf_range(-8, 8), 2.5, 6.0, 0.45, Color(0.7, 0.88, 1.0, 0.5))

	# Shoreline avoidance & water-tile clamping
	# Naval units cannot drive onto dry ground
	if u.get("targetPos") != null:
		var target = u["targetPos"] as Vector2
		var t_col = int(target.x / ts)
		var t_row = int(target.y / ts)
		if t_col >= 0 and t_col < map["cols"] and t_row >= 0 and t_row < map["rows"]:
			var target_tile = map["tiles"][t_row * map["cols"] + t_col]
			if target_tile != "water":
				# Find nearest water tile to target
				var nearest_water = _find_nearest_water_pos(map, target)
				if nearest_water != Vector2.ZERO:
					u["targetPos"] = nearest_water

static func _find_nearest_water_pos(map: Dictionary, pos: Vector2) -> Vector2:
	var ts = Constants.TILE_SIZE
	var center_c = int(pos.x / ts)
	var center_r = int(pos.y / ts)
	var best_dist = 99999.0
	var best_pos = Vector2.ZERO
	
	for rad in range(1, 5):
		for dr in range(-rad, rad + 1):
			for dc in range(-rad, rad + 1):
				var c = center_c + dc
				var r = center_r + dr
				if c >= 0 and c < map["cols"] and r >= 0 and r < map["rows"]:
					if map["tiles"][r * map["cols"] + c] == "water":
						var w_pos = Vector2(c * ts + ts * 0.5, r * ts + ts * 0.5)
						var d = pos.distance_to(w_pos)
						if d < best_dist:
							best_dist = d
							best_pos = w_pos
		if best_pos != Vector2.ZERO:
			break
			
	return best_pos

static func is_water_tile_at(map: Dictionary, x: float, y: float) -> bool:
	var ts = Constants.TILE_SIZE
	var c = int(x / ts)
	var r = int(y / ts)
	if c >= 0 and c < map["cols"] and r >= 0 and r < map["rows"]:
		return map["tiles"][r * map["cols"] + c] == "water"
	return false
