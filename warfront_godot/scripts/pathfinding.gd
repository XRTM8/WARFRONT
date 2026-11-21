class_name Pathfinding
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func find_road_path(map: Dictionary, start_node_id: String, goal_node_id: String) -> Array[String]:
	if start_node_id == goal_node_id:
		return [start_node_id]
	
	var nodes: Dictionary = map["roadNodes"]
	if not nodes.has(start_node_id) or not nodes.has(goal_node_id):
		return []
		
	var bridge_by_id: Dictionary = {}
	for b in map["bridges"]:
		bridge_by_id[b["id"]] = b
		
	var is_passable = func(node_id: String) -> bool:
		if not nodes.has(node_id):
			return false
		var node = nodes[node_id]
		if node.has("bridgeId") and node["bridgeId"] != "":
			var b = bridge_by_id.get(node["bridgeId"])
			if b != null and b["status"] != "intact":
				return false
		return true
		
	if not is_passable.call(start_node_id) or not is_passable.call(goal_node_id):
		return []
		
	var dist: Dictionary = {}
	var prev: Dictionary = {}
	var visited: Dictionary = {}
	var open: Array[String] = [start_node_id]
	dist[start_node_id] = 0.0
	
	while open.size() > 0:
		var best_idx = 0
		var best_dist = dist.get(open[0], INF)
		for i in range(1, open.size()):
			var d = dist.get(open[i], INF)
			if d < best_dist:
				best_dist = d
				best_idx = i
				
		var current = open[best_idx]
		open.remove_at(best_idx)
		
		if visited.has(current):
			continue
		visited[current] = true
		
		if current == goal_node_id:
			var path: Array[String] = []
			var cur = goal_node_id
			while cur != "":
				path.push_back(cur)
				cur = prev.get(cur, "")
			path.reverse()
			return path
			
		var cur_node = nodes[current]
		for next_id in cur_node["neighbors"]:
			if visited.has(next_id) or not is_passable.call(next_id):
				continue
			var next_node = nodes[next_id]
			var step_dist = Vector2(cur_node["x"], cur_node["y"]).distance_to(Vector2(next_node["x"], next_node["y"]))
			var cand = best_dist + step_dist
			if cand < dist.get(next_id, INF):
				dist[next_id] = cand
				prev[next_id] = current
				open.push_back(next_id)
				
	return []

static func get_tile_at_world(map: Dictionary, x: float, y: float) -> String:
	var col = int(floor(x / map["tileSize"]))
	var row = int(floor(y / map["tileSize"]))
	if col < 0 or col >= map["cols"] or row < 0 or row >= map["rows"]:
		return "water"
	return map["tiles"][row * map["cols"] + col]

static func get_bridge_at_world(map: Dictionary, x: float, y: float, pad: float = 6.0) -> Dictionary:
	for b in map["bridges"]:
		if abs(x - b["x"]) <= b["width"] / 2.0 + pad and abs(y - b["y"]) <= b["height"] / 2.0 + pad:
			return b
	return {}

static func is_point_passable_for_land(map: Dictionary, x: float, y: float) -> bool:
	if x < 24.0 or x > map["width"] - 24.0 or y < 24.0 or y > map["height"] - 24.0:
		return false
	var tile = get_tile_at_world(map, x, y)
	if tile == "water":
		return false
	if tile == "rock" or tile == "cliff":
		return false
	if tile == "bridge":
		var b = get_bridge_at_world(map, x, y, 4.0)
		if not b.is_empty() and b["status"] != "intact":
			return false
	return true

static func find_nearest_intact_bridge(map: Dictionary, from_x: float, from_y: float, to_x: float, to_y: float) -> Dictionary:
	var best: Dictionary = {}
	var best_cost = INF
	for b in map["bridges"]:
		if b["status"] != "intact":
			continue
		var cost = Vector2(from_x, from_y).distance_to(Vector2(b["x"], b["y"])) + Vector2(to_x, to_y).distance_to(Vector2(b["x"], b["y"]))
		if cost < best_cost:
			best_cost = cost
			best = b
	return best

static func is_opposite_river_side(map: Dictionary, x1: float, x2: float) -> bool:
	var mid = map["width"] * 0.5
	return (x1 < mid - 60.0 and x2 > mid + 60.0) or (x1 > mid + 60.0 and x2 < mid - 60.0)
