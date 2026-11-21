class_name MapGenLarge
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Utils = preload("res://scripts/map_gen_utils.gd")

static func generate(theater: String, _seed_val: int) -> Dictionary:
	var effective_seed = 551829 if theater == "basra" else 882194
	var rng = Utils.create_rng(effective_seed)
	var cols = 100
	var rows = 60
	var ts = Constants.TILE_SIZE
	var width = cols * ts
	var height = rows * ts
	
	var tiles: Array = []
	tiles.resize(cols * rows)
	tiles.fill("ground")
	
	var set_t = func(c: int, r: int, kind: String) -> void:
		if c >= 0 and c < cols and r >= 0 and r < rows:
			tiles[r * cols + c] = kind
			
	var get_center = func(c: int, r: int) -> Vector2:
		return Vector2(c * ts + ts * 0.5, r * ts + ts * 0.5)

	# 1. Delta Waterways (Vertical river + Horizontal river)
	var island_left = 44
	var island_right = 55
	var island_top = 24
	var island_bottom = 35
	
	# Vertical River
	for r in range(rows):
		if r < island_top or r > island_bottom:
			for c in range(48, 52):
				set_t.call(c, r, "water")
		else:
			for c in range(41, 44):
				set_t.call(c, r, "water")
			for c in range(56, 59):
				set_t.call(c, r, "water")
				
	# Horizontal River
	for c in range(cols):
		if c < island_left or c > island_right:
			for r in range(28, 32):
				set_t.call(c, r, "water")
				
	# Central Island (Refinery Complex)
	for r in range(island_top, island_bottom + 1):
		for c in range(island_left, island_right + 1):
			var is_edge = (r == island_top or r == island_bottom or c == island_left or c == island_right)
			set_t.call(c, r, "concrete" if is_edge else "oilfield")

	# 2. 4 Strategic Bridges (North, South, West, East)
	var bridges: Array[Dictionary] = [
		{ "id": "bridge_north", "name": "جسر الدلتا الشمالي", "x": get_center.call(50, 14).x, "y": get_center.call(50, 14).y, "width": 192.0, "height": 60.0, "orientation": "horizontal", "hp": 420.0, "maxHp": 420.0, "status": "intact", "rebuildProgress": 0.0, "hitFlash": 0.0 },
		{ "id": "bridge_south", "name": "جسر الدلتا الجنوبي", "x": get_center.call(50, 46).x, "y": get_center.call(50, 46).y, "width": 192.0, "height": 60.0, "orientation": "horizontal", "hp": 420.0, "maxHp": 420.0, "status": "intact", "rebuildProgress": 0.0, "hitFlash": 0.0 },
		{ "id": "bridge_west", "name": "معبر الهور الغربي", "x": get_center.call(26, 30).x, "y": get_center.call(26, 30).y, "width": 192.0, "height": 60.0, "orientation": "horizontal", "hp": 420.0, "maxHp": 420.0, "status": "intact", "rebuildProgress": 0.0, "hitFlash": 0.0 },
		{ "id": "bridge_east", "name": "معبر الهور الشرقي", "x": get_center.call(74, 30).x, "y": get_center.call(74, 30).y, "width": 192.0, "height": 60.0, "orientation": "horizontal", "hp": 420.0, "maxHp": 420.0, "status": "intact", "rebuildProgress": 0.0, "hitFlash": 0.0 }
	]
	
	for b in bridges:
		var bc = int(b["x"] / ts)
		var br = int(b["y"] / ts)
		for dc in range(-2, 3):
			for dr in range(-2, 3):
				var tidx = clamp(br + dr, 0, rows - 1) * cols + clamp(bc + dc, 0, cols - 1)
				if tiles[tidx] == "water":
					tiles[tidx] = "bridge"

	# 3. 4 Command HQs in the 4 Quadrants
	var hq_positions = [
		Vector2i(8, 10),   # Slot 0 (NW)
		Vector2i(8, 50),   # Slot 1 (SW)
		Vector2i(91, 10),  # Slot 2 (NE)
		Vector2i(91, 50)   # Slot 3 (SE)
	]
	
	var hqs: Array[Dictionary] = []
	for i in range(4):
		var p_tile = hq_positions[i]
		for dr in range(-2, 3):
			for dc in range(-3, 4):
				set_t.call(p_tile.x + dc, p_tile.y + dr, "concrete")
		var p_world = get_center.call(p_tile.x, p_tile.y)
		var hq_data = {
			"id": "hq_%d" % i,
			"slot_id": i,
			"team_id": 1 if i < 2 else 2,
			"faction": "vanguard" if i < 2 else "raiders",
			"x": p_world.x,
			"y": p_world.y,
			"hp": Constants.HQ_MAX_HP,
			"maxHp": Constants.HQ_MAX_HP,
			"roadNodeId": "hq_%d" % i,
			"radarAngle": 0.0 if i < 2 else PI,
			"hitFlash": 0.0
		}
		hqs.push_back(hq_data)

	# 4. 6 Tactical Oil Rigs
	var rig_configs = [
		{ "id": "rig_nw", "col": 20, "row": 16, "owner": "neutral", "name": "حقل الزبير الشمالي" },
		{ "id": "rig_sw", "col": 20, "row": 44, "owner": "neutral", "name": "حقل الرميلة الجنوبي" },
		{ "id": "rig_ne", "col": 80, "row": 16, "owner": "neutral", "name": "حقل مجنون الشرقي" },
		{ "id": "rig_se", "col": 80, "row": 44, "owner": "neutral", "name": "حقل غرب القرنة" },
		{ "id": "rig_island_1", "col": 47, "row": 29, "owner": "neutral", "name": "مجمع مصفاة الجزيرة A" },
		{ "id": "rig_island_2", "col": 52, "row": 31, "owner": "neutral", "name": "مجمع مصفاة الجزيرة B" }
	]
	
	var rigs: Array[Dictionary] = []
	for rc in rig_configs:
		var pos = get_center.call(rc["col"], rc["row"])
		for dr in range(-1, 2):
			for dc in range(-1, 2):
				set_t.call(rc["col"] + dc, rc["row"] + dr, "oilfield")
		rigs.push_back({
			"id": rc["id"],
			"name": rc["name"],
			"x": pos.x,
			"y": pos.y,
			"owner": rc["owner"],
			"captureProgress": 0.0,
			"storedBarrels": 40.0,
			"maxBarrels": 100.0,
			"pumpPhase": rng.call() * TAU,
			"roadNodeId": "node_%s" % rc["id"],
			"truckCooldown": 1.5,
			"isBurning": false
		})

	# 5. Road Network Nodes
	var road_nodes: Dictionary = {}
	for hq in hqs:
		road_nodes[hq["roadNodeId"]] = { "id": hq["roadNodeId"], "x": hq["x"], "y": hq["y"], "neighbors": [] as Array[String] }
	for b in bridges:
		road_nodes[b["id"]] = { "id": b["id"], "x": b["x"], "y": b["y"], "neighbors": [] as Array[String], "bridgeId": b["id"] }
	for r in rigs:
		road_nodes[r["roadNodeId"]] = { "id": r["roadNodeId"], "x": r["x"], "y": r["y"], "neighbors": [] as Array[String] }

	var add_edge = func(id_a: String, id_b: String):
		var na = road_nodes.get(id_a)
		var nb = road_nodes.get(id_b)
		if na != null and nb != null:
			if not na["neighbors"].has(id_b): na["neighbors"].push_back(id_b)
			if not nb["neighbors"].has(id_a): nb["neighbors"].push_back(id_a)

	add_edge.call("hq_0", "node_rig_nw")
	add_edge.call("node_rig_nw", "bridge_north")
	add_edge.call("node_rig_nw", "bridge_west")
	
	add_edge.call("hq_1", "node_rig_sw")
	add_edge.call("node_rig_sw", "bridge_south")
	add_edge.call("node_rig_sw", "bridge_west")
	
	add_edge.call("hq_2", "node_rig_ne")
	add_edge.call("node_rig_ne", "bridge_north")
	add_edge.call("node_rig_ne", "bridge_east")
	
	add_edge.call("hq_3", "node_rig_se")
	add_edge.call("node_rig_se", "bridge_south")
	add_edge.call("node_rig_se", "bridge_east")
	
	add_edge.call("bridge_north", "node_rig_island_1")
	add_edge.call("bridge_south", "node_rig_island_2")
	add_edge.call("bridge_west", "node_rig_island_1")
	add_edge.call("bridge_east", "node_rig_island_2")
	add_edge.call("node_rig_island_1", "node_rig_island_2")

	var paint_road = func(c0: int, r0: int, c1: int, r1: int):
		var c = c0
		var r = r0
		var steps = 0
		while (c != c1 or r != r1) and steps < 200:
			steps += 1
			var idx = r * cols + c
			if tiles[idx] != "water" and tiles[idx] != "bridge":
				tiles[idx] = "road"
			if c != c1: c += 1 if c < c1 else -1
			elif r != r1: r += 1 if r < r1 else -1

	for n_id in road_nodes:
		var n = road_nodes[n_id]
		var c0 = int(n["x"] / ts)
		var r0 = int(n["y"] / ts)
		for nbr_id in n["neighbors"]:
			var other = road_nodes.get(nbr_id)
			if other != null:
				paint_road.call(c0, r0, int(other["x"] / ts), int(other["y"] / ts))

	# 6. Burning Wells
	var burning_wells: Array[Vector2] = []
	for i in range(12):
		var c = 12 + int(rng.call() * 76)
		var r = 8 + int(rng.call() * 44)
		if tiles[r * cols + c] == "ground":
			burning_wells.push_back(get_center.call(c, r))
			tiles[r * cols + c] = "oilfield"

	return {
		"theater": theater,
		"seed": effective_seed,
		"cols": cols,
		"rows": rows,
		"tileSize": ts,
		"width": float(width),
		"height": float(height),
		"tiles": tiles,
		"roadNodes": road_nodes,
		"bridges": bridges,
		"rigs": rigs,
		"playerHQ": hqs[0],
		"enemyHQ": hqs[2],
		"hqs": hqs,
		"burningWells": burning_wells
	}
