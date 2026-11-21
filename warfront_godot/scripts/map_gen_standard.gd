class_name MapGenStandard
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Utils = preload("res://scripts/map_gen_utils.gd")

static func generate(theater: String, seed_val: int = 104729) -> Dictionary:
	var effective_seed: int = 104729
	if theater == "kirkuk":
		effective_seed = 104729
	elif theater == "suez":
		effective_seed = 229403
	elif theater == "newyork":
		effective_seed = 778121
	else:
		effective_seed = seed_val

	var rng = Utils.create_rng(effective_seed)
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
			for c in range(32, 35):
				Utils.set_tile(tiles, c, r, "water")
			for c in range(island_left, island_right + 1):
				Utils.set_tile(tiles, c, r, "concrete" if (r == island_top or r == island_bottom or c == island_left or c == island_right) else "oilfield")
			for c in range(40, 43):
				Utils.set_tile(tiles, c, r, "water")
		else:
			for dc in range(-river_half_w, river_half_w + 1):
				Utils.set_tile(tiles, center_col + dc, r, "water")

	# 2. Natural Shallow River Ford (Rocky Crossing)
	for fr in [27, 28]:
		var t_f = float(fr) / float(Constants.MAP_ROWS)
		var f_center = 36 + int(round(sin(t_f * PI * 2.0 - 0.4) * 2.8))
		for dc in range(-river_half_w, river_half_w + 1):
			Utils.set_tile(tiles, f_center + dc, fr, "ford")

	# 3. Mesa Ridges & Impassable Rock Cliffs
	var paint_mesa = func(c_start: int, c_end: int, r_start: int, r_end: int) -> void:
		for r in range(r_start, r_end + 1):
			for c in range(c_start, c_end + 1):
				Utils.set_tile(tiles, c, r, "rock")

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
			Utils.set_tile(tiles, player_hq_col + dc, player_hq_row + dr, "concrete")
			Utils.set_tile(tiles, enemy_hq_col + dc, enemy_hq_row + dr, "concrete")

	# 5. Bridges Construction
	var bridges: Array[Dictionary] = []
	var road_nodes: Dictionary = {}

	var add_node = func(id: String, col: int, row: int, bridge_id: String = "") -> Dictionary:
		var pos = Utils.tile_center(col, row)
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
			Utils.paint_road_segment(tiles, ac, ar, bc, br)

	# Setup HQs in Graph
	add_node.call("hq_player", player_hq_col, player_hq_row)
	add_node.call("hq_enemy", enemy_hq_col, enemy_hq_row)

	# Bridge 0: North Highway Crossing (row 8)
	var b0_row = 8
	var b0_west_col = 31
	var b0_east_col = 37
	var b0_tiles: Array = []
	for c in range(b0_west_col + 1, b0_east_col):
		Utils.set_tile(tiles, c, b0_row, "bridge")
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
		Utils.set_tile(tiles, c, b1_row, "bridge")
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
		Utils.set_tile(tiles, c, b2_row, "bridge")
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
		Utils.set_tile(tiles, c, b3_row, "bridge")
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
			"maxBarrels": 120.0,
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

		var pos = Utils.tile_center(col, row)
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
			var pos = Utils.tile_center(col, row)
			burning_wells.push_back(pos)
			tiles[idx] = "oilfield"

	var p_pos = Utils.tile_center(player_hq_col, player_hq_row)
	var e_pos = Utils.tile_center(enemy_hq_col, enemy_hq_row)

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
