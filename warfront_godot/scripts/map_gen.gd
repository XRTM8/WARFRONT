class_name MapGen
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func create_rng(seed_val: int) -> Callable:
	var s: int = seed_val & 0xFFFFFFFF
	return func() -> float:
		s = (s + 0x6d2b79f5) & 0xFFFFFFFF
		var t: int = ((s ^ (s >> 15)) * (1 | s)) & 0xFFFFFFFF
		t = ((t ^ (t >> 7)) * (61 | t)) ^ t
		t = t & 0xFFFFFFFF
		return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0

static func tile_center(col: int, row: int) -> Vector2:
	return Vector2(
		col * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
		row * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0
	)

static func set_tile(tiles: Array, col: int, row: int, kind: String) -> void:
	if col >= 0 and col < Constants.MAP_COLS and row >= 0 and row < Constants.MAP_ROWS:
		tiles[row * Constants.MAP_COLS + col] = kind

static func paint_road_segment(tiles: Array, c0: int, r0: int, c1: int, r1: int) -> void:
	var c = c0
	var r = r0
	var max_steps = Constants.MAP_COLS + Constants.MAP_ROWS + 20
	var steps = 0
	while (c != c1 or r != r1) and steps < max_steps:
		steps += 1
		var idx = r * Constants.MAP_COLS + c
		if tiles[idx] != "water" and tiles[idx] != "bridge" and tiles[idx] != "rock":
			tiles[idx] = "road"
		if c != c1:
			c += 1 if c < c1 else -1
		elif r != r1:
			r += 1 if r < r1 else -1
	var end_idx = r1 * Constants.MAP_COLS + c1
	if tiles[end_idx] != "water" and tiles[end_idx] != "bridge" and tiles[end_idx] != "rock":
		tiles[end_idx] = "road"

static func generate_map(theater: String, seed_val: int = 104729) -> Dictionary:
	if theater == "basra" or theater == "zagros":
		return _generate_large_4p_map(theater, seed_val)
		
	var effective_seed: int = 104729
	if theater == "kirkuk":
		effective_seed = 104729
	elif theater == "suez":
		effective_seed = 229403
	elif theater == "newyork":
		effective_seed = 778121
	else:
		effective_seed = seed_val

	var rng = create_rng(effective_seed)
	var tiles: Array = []
	tiles.resize(Constants.MAP_COLS * Constants.MAP_ROWS)
	tiles.fill("ground")
	
	var width = Constants.MAP_COLS * Constants.TILE_SIZE
	var height = Constants.MAP_ROWS * Constants.TILE_SIZE
	
	# 1. Procedural Meandering River with Central Island ("Al-Jazirah")
	var river_half_w = 2
	var island_top = 17
	var island_bottom = 23
	var island_left = 35
	var island_right = 39

	for r in range(Constants.MAP_ROWS):
		var t = float(r) / float(Constants.MAP_ROWS)
		var bend = int(round(sin(t * PI * 2.0 - 0.4) * 2.8))
		var center_col = 36 + bend
		
		if r >= island_top and r <= island_bottom:
			# River splits around the central island!
			# West Channel
			for c in range(32, 35):
				set_tile(tiles, c, r, "water")
			# Central Island (Solid elevated ground with concrete pad)
			for c in range(island_left, island_right + 1):
				set_tile(tiles, c, r, "concrete" if (r == island_top or r == island_bottom or c == island_left or c == island_right) else "oilfield")
			# East Channel
			for c in range(40, 43):
				set_tile(tiles, c, r, "water")
		else:
			# Single channel
			for dc in range(-river_half_w, river_half_w + 1):
				set_tile(tiles, center_col + dc, r, "water")

	# 2. Natural Shallow River Ford (Rocky Crossing)
	# Located at rows 27-28 south of the island
	for fr in [27, 28]:
		var t_f = float(fr) / float(Constants.MAP_ROWS)
		var f_center = 36 + int(round(sin(t_f * PI * 2.0 - 0.4) * 2.8))
		for dc in range(-river_half_w, river_half_w + 1):
			set_tile(tiles, f_center + dc, fr, "ford")

	# 3. Mesa Ridges & Impassable Rock Cliffs
	var paint_mesa = func(c_start: int, c_end: int, r_start: int, r_end: int) -> void:
		for r in range(r_start, r_end + 1):
			for c in range(c_start, c_end + 1):
				set_tile(tiles, c, r, "rock")

	# West Mesas
	paint_mesa.call(16, 22, 3, 7)    # North Ridge Pass
	paint_mesa.call(16, 22, 32, 36)  # South Wadi Canyon
	# East Mesas
	paint_mesa.call(50, 56, 3, 7)    # North Ridge Pass (East)
	paint_mesa.call(50, 56, 32, 36)  # South Wadi Canyon (East)
	# River Bluff Chokepoints
	paint_mesa.call(28, 30, 11, 13)
	paint_mesa.call(44, 46, 28, 30)

	# 4. Command HQs
	var player_hq_col = 6
	var player_hq_row = 20
	var enemy_hq_col = Constants.MAP_COLS - 7
	var enemy_hq_row = 20

	for dr in range(-2, 3):
		for dc in range(-2, 3):
			set_tile(tiles, player_hq_col + dc, player_hq_row + dr, "concrete")
			set_tile(tiles, enemy_hq_col + dc, enemy_hq_row + dr, "concrete")

	# 5. Bridges Construction
	var bridges: Array[Dictionary] = []
	var road_nodes: Dictionary = {}

	var add_node = func(id: String, col: int, row: int, bridge_id: String = "") -> Dictionary:
		var pos = tile_center(col, row)
		var node: Dictionary = {
			"id": id,
			"x": pos.x,
			"y": pos.y,
			"neighbors": [] as Array[String],
			"bridgeId": bridge_id
		}
		road_nodes[id] = node
		return node

	var link_nodes = func(a_id: String, b_id: String, paint: bool = true) -> void:
		var a = road_nodes.get(a_id)
		var b = road_nodes.get(b_id)
		if a == null or b == null:
			return
		if not a["neighbors"].has(b_id):
			a["neighbors"].push_back(b_id)
		if not b["neighbors"].has(a_id):
			b["neighbors"].push_back(a_id)
		if paint:
			var ac = int(floor(a["x"] / Constants.TILE_SIZE))
			var ar = int(floor(a["y"] / Constants.TILE_SIZE))
			var bc = int(floor(b["x"] / Constants.TILE_SIZE))
			var br = int(floor(b["y"] / Constants.TILE_SIZE))
			paint_road_segment(tiles, ac, ar, bc, br)

	# Setup HQs in Graph
	add_node.call("hq_player", player_hq_col, player_hq_row)
	add_node.call("hq_enemy", enemy_hq_col, enemy_hq_row)

	# Bridge 0: North Highway Crossing (row 8)
	var b0_row = 8
	var b0_west_col = 31
	var b0_east_col = 37
	var b0_tiles: Array = []
	for c in range(b0_west_col + 1, b0_east_col):
		set_tile(tiles, c, b0_row, "bridge")
		b0_tiles.push_back({ "col": c, "row": b0_row })
	var b0_w = (b0_east_col - b0_west_col - 1) * Constants.TILE_SIZE
	bridges.push_back({
		"id": "bridge_0",
		"name": "جسر الطريق السريع الشمالي",
		"x": (b0_west_col + 1) * Constants.TILE_SIZE + b0_w / 2.0,
		"y": b0_row * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
		"width": float(b0_w),
		"height": float(Constants.TILE_SIZE + 12),
		"orientation": "horizontal",
		"hp": Constants.BRIDGE_MAX_HP,
		"maxHp": Constants.BRIDGE_MAX_HP,
		"status": "intact",
		"rebuildProgress": 0.0,
		"hitFlash": 0.0,
		"tiles": b0_tiles
	})

	# Bridge 1: Island West Causeway (row 20, cols 32 to 34)
	var b1_row = 20
	var b1_west_col = 31
	var b1_east_col = 35
	var b1_tiles: Array = []
	for c in range(32, 35):
		set_tile(tiles, c, b1_row, "bridge")
		b1_tiles.push_back({ "col": c, "row": b1_row })
	var b1_w = 3 * Constants.TILE_SIZE
	bridges.push_back({
		"id": "bridge_1",
		"name": "معبر الجزيرة الغربي",
		"x": 32 * Constants.TILE_SIZE + b1_w / 2.0,
		"y": b1_row * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
		"width": float(b1_w),
		"height": float(Constants.TILE_SIZE + 12),
		"orientation": "horizontal",
		"hp": Constants.BRIDGE_MAX_HP,
		"maxHp": Constants.BRIDGE_MAX_HP,
		"status": "intact",
		"rebuildProgress": 0.0,
		"hitFlash": 0.0,
		"tiles": b1_tiles
	})

	# Bridge 2: Island East Causeway (row 20, cols 40 to 42)
	var b2_row = 20
	var b2_west_col = 39
	var b2_east_col = 43
	var b2_tiles: Array = []
	for c in range(40, 43):
		set_tile(tiles, c, b2_row, "bridge")
		b2_tiles.push_back({ "col": c, "row": b2_row })
	var b2_w = 3 * Constants.TILE_SIZE
	bridges.push_back({
		"id": "bridge_2",
		"name": "معبر الجزيرة الشرقي",
		"x": 40 * Constants.TILE_SIZE + b2_w / 2.0,
		"y": b2_row * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
		"width": float(b2_w),
		"height": float(Constants.TILE_SIZE + 12),
		"orientation": "horizontal",
		"hp": Constants.BRIDGE_MAX_HP,
		"maxHp": Constants.BRIDGE_MAX_HP,
		"status": "intact",
		"rebuildProgress": 0.0,
		"hitFlash": 0.0,
		"tiles": b2_tiles
	})

	# Bridge 3: South Valley Bridge (row 34, cols 35 to 41)
	var b3_row = 34
	var b3_west_col = 34
	var b3_east_col = 41
	var b3_tiles: Array = []
	for c in range(b3_west_col + 1, b3_east_col):
		set_tile(tiles, c, b3_row, "bridge")
		b3_tiles.push_back({ "col": c, "row": b3_row })
	var b3_w = (b3_east_col - b3_west_col - 1) * Constants.TILE_SIZE
	bridges.push_back({
		"id": "bridge_3",
		"name": "جسر الوادي الجنوبي",
		"x": (b3_west_col + 1) * Constants.TILE_SIZE + b3_w / 2.0,
		"y": b3_row * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
		"width": float(b3_w),
		"height": float(Constants.TILE_SIZE + 12),
		"orientation": "horizontal",
		"hp": Constants.BRIDGE_MAX_HP,
		"maxHp": Constants.BRIDGE_MAX_HP,
		"status": "intact",
		"rebuildProgress": 0.0,
		"hitFlash": 0.0,
		"tiles": b3_tiles
	})

	# 6. Road Graph Network Connecting All Spines and Crossings
	var west_spine_col = 13
	var east_spine_col = Constants.MAP_COLS - 14

	# West Nodes
	add_node.call("w_hq_junc", west_spine_col, player_hq_row)
	add_node.call("w_spine_0", west_spine_col, b0_row)
	add_node.call("w_spine_3", west_spine_col, b3_row)
	add_node.call("b_west_0", b0_west_col, b0_row)
	add_node.call("b_mid_0", 34, b0_row, "bridge_0")
	add_node.call("b_east_0", b0_east_col, b0_row)
	
	add_node.call("b_west_1", b1_west_col, b1_row)
	add_node.call("b_mid_1", 33, b1_row, "bridge_1")
	add_node.call("island_hub", 37, 20)
	add_node.call("b_mid_2", 41, b2_row, "bridge_2")
	add_node.call("b_east_2", b2_east_col, b2_row)

	add_node.call("b_west_3", b3_west_col, b3_row)
	add_node.call("b_mid_3", 37, b3_row, "bridge_3")
	add_node.call("b_east_3", b3_east_col, b3_row)
	add_node.call("e_spine_0", east_spine_col, b0_row)
	add_node.call("e_spine_3", east_spine_col, b3_row)
	add_node.call("e_hq_junc", east_spine_col, enemy_hq_row)

	# Link West Main Arteries
	link_nodes.call("hq_player", "w_hq_junc")
	link_nodes.call("w_hq_junc", "w_spine_0")
	link_nodes.call("w_hq_junc", "w_spine_3")
	link_nodes.call("w_spine_0", "b_west_0")
	link_nodes.call("b_west_0", "b_mid_0", false)
	link_nodes.call("b_mid_0", "b_east_0", false)
	link_nodes.call("w_hq_junc", "b_west_1")
	link_nodes.call("b_west_1", "b_mid_1", false)
	link_nodes.call("b_mid_1", "island_hub", false)
	link_nodes.call("w_spine_3", "b_west_3")
	link_nodes.call("b_west_3", "b_mid_3", false)
	link_nodes.call("b_mid_3", "b_east_3", false)

	# Link East Main Arteries
	link_nodes.call("b_east_0", "e_spine_0")
	link_nodes.call("island_hub", "b_mid_2", false)
	link_nodes.call("b_mid_2", "b_east_2", false)
	link_nodes.call("b_east_2", "e_hq_junc")
	link_nodes.call("b_east_3", "e_spine_3")
	link_nodes.call("e_spine_0", "e_hq_junc")
	link_nodes.call("e_spine_3", "e_hq_junc")
	link_nodes.call("e_hq_junc", "hq_enemy")

	# 7. Strategic 8 Oil Rigs Configuration
	var rigs: Array[Dictionary] = []
	var rig_configs: Array[Dictionary] = [
		{
			"id": "rig_p_home",
			"col": 11,
			"row": 16,
			"owner": "player",
			"connectTo": "w_hq_junc",
			"maxBarrels": 80.0,
			"initBarrels": 40.0
		},
		{
			"id": "rig_p_north",
			"col": 26,
			"row": 5,
			"owner": "neutral",
			"connectTo": "b_west_0",
			"maxBarrels": 80.0,
			"initBarrels": 20.0
		},
		{
			"id": "rig_p_south",
			"col": 26,
			"row": 34,
			"owner": "neutral",
			"connectTo": "b_west_3",
			"maxBarrels": 80.0,
			"initBarrels": 20.0
		},
		{
			"id": "rig_w_bank",
			"col": 29,
			"row": 26,
			"owner": "neutral",
			"connectTo": "w_hq_junc",
			"maxBarrels": 80.0,
			"initBarrels": 25.0
		},
		{
			"id": "rig_island",
			"col": 37,
			"row": 20,
			"owner": "neutral",
			"connectTo": "island_hub",
			"maxBarrels": 120.0, # High Yield Crown Jewel!
			"initBarrels": 50.0
		},
		{
			"id": "rig_e_bank",
			"col": 44,
			"row": 14,
			"owner": "neutral",
			"connectTo": "e_hq_junc",
			"maxBarrels": 80.0,
			"initBarrels": 25.0
		},
		{
			"id": "rig_e_north",
			"col": 46,
			"row": 5,
			"owner": "neutral",
			"connectTo": "b_east_0",
			"maxBarrels": 80.0,
			"initBarrels": 20.0
		},
		{
			"id": "rig_e_home",
			"col": 60,
			"row": 24,
			"owner": "enemy",
			"connectTo": "e_hq_junc",
			"maxBarrels": 80.0,
			"initBarrels": 40.0
		}
	]

	for cfg in rig_configs:
		var col = cfg["col"]
		var row = cfg["row"]
		for dr in range(-1, 2):
			for dc in range(-1, 2):
				var idx = (row + dr) * Constants.MAP_COLS + (col + dc)
				if tiles[idx] == "ground":
					tiles[idx] = "oilfield"

		var node_id = "node_%s" % cfg["id"]
		add_node.call(node_id, col, row)
		link_nodes.call(node_id, cfg["connectTo"])

		var pos = tile_center(col, row)
		rigs.push_back({
			"id": cfg["id"],
			"x": pos.x,
			"y": pos.y,
			"owner": cfg["owner"],
			"captureProgress": 100.0 if cfg["owner"] == "player" else (-100.0 if cfg["owner"] == "enemy" else 0.0),
			"captureFaction": cfg["owner"],
			"storedBarrels": cfg["initBarrels"],
			"maxBarrels": cfg["maxBarrels"],
			"pumpPhase": rng.call() * PI * 2.0,
			"roadNodeId": node_id,
			"truckCooldown": 0.5 if cfg["owner"] == "player" else 2.5,
			"isBurning": theater == "kirkuk" and rng.call() < 0.25
		})

	# 8. Burning Wellheads in Desert Basins
	var burning_wells: Array[Vector2] = []
	var well_count = 10 if theater == "kirkuk" else 5
	for i in range(well_count):
		var col = 4 + int(rng.call() * (Constants.MAP_COLS - 8))
		var row = 3 + int(rng.call() * (Constants.MAP_ROWS - 6))
		var idx = row * Constants.MAP_COLS + col
		if tiles[idx] == "ground":
			var pos = tile_center(col, row)
			burning_wells.push_back(pos)
			tiles[idx] = "oilfield"

	var p_pos = tile_center(player_hq_col, player_hq_row)
	var e_pos = tile_center(enemy_hq_col, enemy_hq_row)

	return {
		"theater": theater,
		"seed": effective_seed,
		"cols": Constants.MAP_COLS,
		"rows": Constants.MAP_ROWS,
		"tileSize": Constants.TILE_SIZE,
		"width": float(width),
		"height": float(height),
		"tiles": tiles,
		"roadNodes": road_nodes,
		"bridges": bridges,
		"rigs": rigs,
		"playerHQ": {
			"id": "hq_player",
			"faction": "player",
			"slot_id": 0,
			"team_id": 1,
			"x": p_pos.x,
			"y": p_pos.y,
			"hp": Constants.HQ_MAX_HP,
			"maxHp": Constants.HQ_MAX_HP,
			"roadNodeId": "hq_player",
			"radarAngle": 0.0,
			"hitFlash": 0.0
		},
		"enemyHQ": {
			"id": "hq_enemy",
			"faction": "enemy",
			"slot_id": 1,
			"team_id": 2,
			"x": e_pos.x,
			"y": e_pos.y,
			"hp": Constants.HQ_MAX_HP,
			"maxHp": Constants.HQ_MAX_HP,
			"roadNodeId": "hq_enemy",
			"radarAngle": PI,
			"hitFlash": 0.0
		},
		"hqs": [
			{
				"id": "hq_player",
				"faction": "player",
				"slot_id": 0,
				"team_id": 1,
				"x": p_pos.x,
				"y": p_pos.y,
				"hp": Constants.HQ_MAX_HP,
				"maxHp": Constants.HQ_MAX_HP,
				"roadNodeId": "hq_player",
				"radarAngle": 0.0,
				"hitFlash": 0.0
			},
			{
				"id": "hq_enemy",
				"faction": "enemy",
				"slot_id": 1,
				"team_id": 2,
				"x": e_pos.x,
				"y": e_pos.y,
				"hp": Constants.HQ_MAX_HP,
				"maxHp": Constants.HQ_MAX_HP,
				"roadNodeId": "hq_enemy",
				"radarAngle": PI,
				"hitFlash": 0.0
			}
		],
		"burningWells": burning_wells
	}

static func _generate_large_4p_map(theater: String, seed_val: int) -> Dictionary:
	var effective_seed = 551829 if theater == "basra" else 882194
	var rng = create_rng(effective_seed)
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
