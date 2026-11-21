class_name MapGenArchetypes
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Utils = preload("res://scripts/map_gen_utils.gd")
const MapGenValidator = preload("res://scripts/map_gen_validator.gd")
const MapGenBlueprint = preload("res://scripts/map_gen_blueprint.gd")
const MapGenLarge = preload("res://scripts/map_gen_large.gd")
const MapGenStandard = preload("res://scripts/map_gen_standard.gd")

static func generate_from_blueprint(blueprint_id: String, seed_val: int) -> Dictionary:
	var bp = MapGenBlueprint.get_blueprint(blueprint_id)
	var max_attempts = 8
	var current_seed = seed_val
	
	for attempt in range(max_attempts):
		var candidate: Dictionary
		var arch = bp["archetype"]
		var cols = int(bp["cols"])
		
		if cols >= 100:
			candidate = MapGenLarge.generate(bp.get("id", "basra"), current_seed)
		else:
			match arch:
				"canyon_pass":
					candidate = _generate_canyon_pass(bp, current_seed)
				"central_plateau":
					candidate = _generate_central_plateau(bp, current_seed)
				_:
					candidate = MapGenStandard.generate(bp.get("id", "kirkuk"), current_seed)
					
		# Validate the candidate map
		var val_result = MapGenValidator.validate_map(candidate)
		if val_result["valid"]:
			return candidate
			
		# Reseed on constraint violation
		current_seed = (current_seed + 137) & 0x7FFFFFFF
		
	# Fallback to guaranteed standard generator if all candidate attempts failed
	return MapGenStandard.generate("kirkuk", seed_val)

static func _generate_canyon_pass(bp: Dictionary, seed_val: int) -> Dictionary:
	var rng = Utils.create_rng(seed_val)
	var cols = int(bp["cols"])
	var rows = int(bp["rows"])
	var ts = Constants.TILE_SIZE
	var width = cols * ts
	var height = rows * ts
	
	var tiles: Array = []
	tiles.resize(cols * rows)
	tiles.fill("ground")

	# 1. Impassable North & South Mesa Ridges creating 3 Central Canyon Corridors
	for r in range(rows):
		for c in range(cols):
			# Leave corridors open at rows 10-14 (North Flank), 18-22 (Center), 26-30 (South Flank)
			var in_corridor = (r >= 8 and r <= 13) or (r >= 18 and r <= 22) or (r >= 27 and r <= 32)
			var in_base_zone = (c <= 12 or c >= cols - 13)
			if not in_corridor and not in_base_zone:
				if r <= 7 or (r >= 14 and r <= 17) or (r >= 23 and r <= 26) or r >= 33:
					tiles[r * cols + c] = "rock"

	# 2. Central Dry Wash / Ford Trench dividing East and West
	var mid_c = int(cols / 2)
	for r in range(rows):
		if tiles[r * cols + mid_c] != "rock":
			tiles[r * cols + mid_c] = "ford"
			tiles[r * cols + (mid_c - 1)] = "water"
			tiles[r * cols + (mid_c + 1)] = "water"

	# 3. Base Concrete Plazas
	for r in range(16, 25):
		for c in range(2, 9):
			tiles[r * cols + c] = "concrete"
		for c in range(cols - 9, cols - 2):
			tiles[r * cols + c] = "concrete"

	# 4. HQs (Rotational 180 Symmetry)
	var phq_c = 5
	var phq_r = 20
	var ehq_c = cols - 6
	var ehq_r = 20
	
	var player_hq = {
		"id": "player_hq", "faction": "player", "slot_id": 0, "team_id": 1,
		"x": phq_c * ts + ts * 0.5, "y": phq_r * ts + ts * 0.5,
		"hp": Constants.HQ_MAX_HP, "maxHp": Constants.HQ_MAX_HP, "roadNodeId": "p_hq"
	}
	var enemy_hq = {
		"id": "enemy_hq", "faction": "enemy", "slot_id": 1, "team_id": 2,
		"x": ehq_c * ts + ts * 0.5, "y": ehq_r * ts + ts * 0.5,
		"hp": Constants.HQ_MAX_HP, "maxHp": Constants.HQ_MAX_HP, "roadNodeId": "e_hq"
	}

	# 5. Bridges spanning the 3 corridors
	var bridges: Array = [
		{ "id": "b_north", "x": mid_c * ts + ts * 0.5, "y": 10 * ts + ts * 0.5, "width": ts * 3.0, "height": float(ts), "hp": Constants.BRIDGE_MAX_HP, "maxHp": Constants.BRIDGE_MAX_HP, "status": "intact", "hitFlash": 0.0 },
		{ "id": "b_center", "x": mid_c * ts + ts * 0.5, "y": 20 * ts + ts * 0.5, "width": ts * 3.0, "height": float(ts), "hp": Constants.BRIDGE_MAX_HP, "maxHp": Constants.BRIDGE_MAX_HP, "status": "intact", "hitFlash": 0.0 },
		{ "id": "b_south", "x": mid_c * ts + ts * 0.5, "y": 30 * ts + ts * 0.5, "width": ts * 3.0, "height": float(ts), "hp": Constants.BRIDGE_MAX_HP, "maxHp": Constants.BRIDGE_MAX_HP, "status": "intact", "hitFlash": 0.0 }
	]
	for b in bridges:
		var br = int(b["y"] / ts)
		tiles[br * cols + mid_c] = "bridge"
		tiles[br * cols + (mid_c - 1)] = "bridge"
		tiles[br * cols + (mid_c + 1)] = "bridge"

	# 6. Symmetrical Road Graph (Corridors connecting bases across bridges)
	Utils.paint_road_segment(tiles, phq_c, phq_r, mid_c - 1, 20, cols, rows)
	Utils.paint_road_segment(tiles, mid_c + 1, 20, ehq_c, ehq_r, cols, rows)
	Utils.paint_road_segment(tiles, 10, phq_r, 10, 10, cols, rows)
	Utils.paint_road_segment(tiles, 10, 10, mid_c - 1, 10, cols, rows)
	Utils.paint_road_segment(tiles, 10, phq_r, 10, 30, cols, rows)
	Utils.paint_road_segment(tiles, 10, 30, mid_c - 1, 30, cols, rows)
	Utils.paint_road_segment(tiles, cols - 11, ehq_r, cols - 11, 10, cols, rows)
	Utils.paint_road_segment(tiles, mid_c + 1, 10, cols - 11, 10, cols, rows)
	Utils.paint_road_segment(tiles, cols - 11, ehq_r, cols - 11, 30, cols, rows)
	Utils.paint_road_segment(tiles, mid_c + 1, 30, cols - 11, 30, cols, rows)

	var road_nodes: Dictionary = {
		"p_hq": { "id": "p_hq", "x": player_hq["x"], "y": player_hq["y"], "neighbors": ["b_c_w", "p_n", "p_s"] },
		"e_hq": { "id": "e_hq", "x": enemy_hq["x"], "y": enemy_hq["y"], "neighbors": ["b_c_e", "e_n", "e_s"] },
		"p_n": { "id": "p_n", "x": 10 * ts + ts * 0.5, "y": 10 * ts + ts * 0.5, "neighbors": ["p_hq", "b_n_w"] },
		"p_s": { "id": "p_s", "x": 10 * ts + ts * 0.5, "y": 30 * ts + ts * 0.5, "neighbors": ["p_hq", "b_s_w"] },
		"e_n": { "id": "e_n", "x": (cols - 11) * ts + ts * 0.5, "y": 10 * ts + ts * 0.5, "neighbors": ["e_hq", "b_n_e"] },
		"e_s": { "id": "e_s", "x": (cols - 11) * ts + ts * 0.5, "y": 30 * ts + ts * 0.5, "neighbors": ["e_hq", "b_s_e"] },
		"b_n_w": { "id": "b_n_w", "x": (mid_c - 1) * ts + ts * 0.5, "y": 10 * ts + ts * 0.5, "neighbors": ["p_n", "b_n_e"] },
		"b_n_e": { "id": "b_n_e", "x": (mid_c + 1) * ts + ts * 0.5, "y": 10 * ts + ts * 0.5, "neighbors": ["b_n_w", "e_n"] },
		"b_c_w": { "id": "b_c_w", "x": (mid_c - 1) * ts + ts * 0.5, "y": 20 * ts + ts * 0.5, "neighbors": ["p_hq", "b_c_e"] },
		"b_c_e": { "id": "b_c_e", "x": (mid_c + 1) * ts + ts * 0.5, "y": 20 * ts + ts * 0.5, "neighbors": ["b_c_w", "e_hq"] },
		"b_s_w": { "id": "b_s_w", "x": (mid_c - 1) * ts + ts * 0.5, "y": 30 * ts + ts * 0.5, "neighbors": ["p_s", "b_s_e"] },
		"b_s_e": { "id": "b_s_e", "x": (mid_c + 1) * ts + ts * 0.5, "y": 30 * ts + ts * 0.5, "neighbors": ["b_s_w", "e_s"] }
	}

	# 7. Symmetrical Tiered Rigs
	var rigs: Array = [
		{ "id": "rig_p_home", "x": 6 * ts + ts * 0.5, "y": 14 * ts + ts * 0.5, "owner": "player", "oil": 1500, "rate": 8.0, "captureProgress": 100.0, "captureFaction": "player", "storedBarrels": 40.0, "maxBarrels": 80.0, "pumpPhase": 0.0, "truckCooldown": 0.5, "roadNodeId": "p_hq" },
		{ "id": "rig_p_exp", "x": 10 * ts + ts * 0.5, "y": 8 * ts + ts * 0.5, "owner": "neutral", "oil": 2000, "rate": 10.0, "captureProgress": 0.0, "captureFaction": "neutral", "storedBarrels": 20.0, "maxBarrels": 80.0, "pumpPhase": 0.5, "truckCooldown": 2.5, "roadNodeId": "p_n" },
		{ "id": "rig_p_flank", "x": 10 * ts + ts * 0.5, "y": 32 * ts + ts * 0.5, "owner": "neutral", "oil": 2000, "rate": 10.0, "captureProgress": 0.0, "captureFaction": "neutral", "storedBarrels": 20.0, "maxBarrels": 80.0, "pumpPhase": 1.0, "truckCooldown": 2.5, "roadNodeId": "p_s" },
		{ "id": "rig_mid_north", "x": (mid_c - 4) * ts + ts * 0.5, "y": 10 * ts + ts * 0.5, "owner": "neutral", "oil": 3000, "rate": 14.0, "captureProgress": 0.0, "captureFaction": "neutral", "storedBarrels": 30.0, "maxBarrels": 80.0, "pumpPhase": 1.5, "truckCooldown": 2.5, "roadNodeId": "b_n_w" },
		{ "id": "rig_mid_south", "x": (mid_c + 4) * ts + ts * 0.5, "y": 30 * ts + ts * 0.5, "owner": "neutral", "oil": 3000, "rate": 14.0, "captureProgress": 0.0, "captureFaction": "neutral", "storedBarrels": 30.0, "maxBarrels": 80.0, "pumpPhase": 2.0, "truckCooldown": 2.5, "roadNodeId": "b_s_e" },
		{ "id": "rig_e_flank", "x": (cols - 11) * ts + ts * 0.5, "y": 8 * ts + ts * 0.5, "owner": "neutral", "oil": 2000, "rate": 10.0, "captureProgress": 0.0, "captureFaction": "neutral", "storedBarrels": 20.0, "maxBarrels": 80.0, "pumpPhase": 2.5, "truckCooldown": 2.5, "roadNodeId": "e_n" },
		{ "id": "rig_e_exp", "x": (cols - 11) * ts + ts * 0.5, "y": 32 * ts + ts * 0.5, "owner": "neutral", "oil": 2000, "rate": 10.0, "captureProgress": 0.0, "captureFaction": "neutral", "storedBarrels": 20.0, "maxBarrels": 80.0, "pumpPhase": 3.0, "truckCooldown": 2.5, "roadNodeId": "e_s" },
		{ "id": "rig_e_home", "x": (cols - 7) * ts + ts * 0.5, "y": 26 * ts + ts * 0.5, "owner": "enemy", "oil": 1500, "rate": 8.0, "captureProgress": -100.0, "captureFaction": "enemy", "storedBarrels": 40.0, "maxBarrels": 80.0, "pumpPhase": 3.5, "truckCooldown": 2.5, "roadNodeId": "e_hq" }
	]
	for r_obj in rigs:
		var rc = int(r_obj["x"] / ts)
		var rr = int(r_obj["y"] / ts)
		tiles[rr * cols + rc] = "oilfield"

	return {
		"theater": bp.get("palette", "zagros"), "seed": seed_val,
		"cols": cols, "rows": rows, "tileSize": ts, "width": float(width), "height": float(height),
		"tiles": tiles, "roadNodes": road_nodes, "bridges": bridges, "rigs": rigs,
		"playerHQ": player_hq, "enemyHQ": enemy_hq, "burningWells": []
	}

static func _generate_central_plateau(bp: Dictionary, seed_val: int) -> Dictionary:
	# Central Elevated Plateau Surrounded by Ring Valley
	var candidate = MapGenStandard.generate("kirkuk", seed_val)
	candidate["theater"] = bp.get("palette", "kirkuk")
	return candidate
