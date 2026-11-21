class_name MapGenValidator
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")

static func validate_map(map: Dictionary) -> Dictionary:
	if map.is_empty():
		return { "valid": false, "reason": "Map dictionary is empty" }
		
	var cols = int(map.get("cols", 0))
	var rows = int(map.get("rows", 0))
	var tiles: Array = map.get("tiles", [])
	
	if cols <= 0 or rows <= 0 or tiles.size() != cols * rows:
		return { "valid": false, "reason": "Invalid map grid dimensions or tile array size" }

	# 1. Base Buildable Clearance Check (Around all HQs)
	var hq_list: Array = []
	if map.has("hqs") and map["hqs"].size() > 0:
		hq_list = map["hqs"]
	else:
		if map.has("playerHQ"):
			hq_list.push_back(map["playerHQ"])
		if map.has("enemyHQ"):
			hq_list.push_back(map["enemyHQ"])
			
	var ts = Constants.TILE_SIZE
	for hq in hq_list:
		var hq_c = int(hq["x"] / ts)
		var hq_r = int(hq["y"] / ts)
		var clear_rad = 2 # 5x5 tile clearance
		for dr in range(-clear_rad, clear_rad + 1):
			for dc in range(-clear_rad, clear_rad + 1):
				var check_c = hq_c + dc
				var check_r = hq_r + dr
				if check_c >= 0 and check_c < cols and check_r >= 0 and check_r < rows:
					var t = tiles[check_r * cols + check_c]
					if t == "water" or t == "rock":
						return {
							"valid": false,
							"reason": "HQ at (%d, %d) obstructed by %s at tile (%d, %d)" % [hq_c, hq_r, t, check_c, check_r]
						}

	# 2. Resource Rig Clearance & Minimum Count
	var rigs: Array = map.get("rigs", [])
	if rigs.size() < 4:
		return { "valid": false, "reason": "Map must contain at least 4 oil rigs (found %d)" % rigs.size() }
		
	for rig in rigs:
		var rc = int(rig["x"] / ts)
		var rr = int(rig["y"] / ts)
		if rc >= 0 and rc < cols and rr >= 0 and rr < rows:
			var t = tiles[rr * cols + rc]
			if t == "water" or t == "rock":
				return { "valid": false, "reason": "Rig '%s' placed on impassable tile '%s'" % [rig.get("id", "rig"), t] }

	# 3. Bridge Abutment & Integrity Check
	var bridges: Array = map.get("bridges", [])
	if bridges.size() < 2:
		return { "valid": false, "reason": "Map must feature at least 2 bridges (found %d)" % bridges.size() }
		
	for b in bridges:
		var bc = int(b["x"] / ts)
		var br = int(b["y"] / ts)
		# Check horizontal land abutment
		var has_left_land = (bc > 0 and tiles[br * cols + (bc - 1)] != "water")
		var has_right_land = (bc < cols - 1 and tiles[br * cols + (bc + 1)] != "water")
		# Check vertical land abutment
		var has_up_land = (br > 0 and tiles[(br - 1) * cols + bc] != "water")
		var has_down_land = (br < rows - 1 and tiles[(br + 1) * cols + bc] != "water")
		
		if not ((has_left_land and has_right_land) or (has_up_land and has_down_land)):
			return { "valid": false, "reason": "Bridge '%s' lacks connected land abutments on both ends" % b.get("id", "bridge") }

	# 4. Road Connectivity Verification
	var phq = map.get("playerHQ", {})
	var ehq = map.get("enemyHQ", {})
	if phq.size() > 0 and ehq.size() > 0 and phq.has("roadNodeId") and ehq.has("roadNodeId"):
		var road_path = Pathfinding.find_road_path(map, phq["roadNodeId"], ehq["roadNodeId"])
		if road_path.size() < 2:
			return { "valid": false, "reason": "No intact road path connects player and enemy HQs" }

	return { "valid": true, "reason": "OK" }
