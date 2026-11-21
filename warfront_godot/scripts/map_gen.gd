class_name MapGen
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Utils = preload("res://scripts/map_gen_utils.gd")
const Standard = preload("res://scripts/map_gen_standard.gd")
const Large = preload("res://scripts/map_gen_large.gd")

static func generate_map(theater: String, seed_val: int = 104729) -> Dictionary:
	if theater == "basra" or theater == "zagros":
		return Large.generate(theater, seed_val)
	return Standard.generate(theater, seed_val)

# Backward-compatibility delegates for scripts/tests expecting MapGen static methods
static func create_rng(seed_val: int) -> Callable:
	return Utils.create_rng(seed_val)

static func tile_center(col: int, row: int, ts: int = Constants.TILE_SIZE) -> Vector2:
	return Utils.tile_center(col, row, ts)

static func set_tile(tiles: Array, col: int, row: int, kind: String, cols: int = Constants.MAP_COLS, rows: int = Constants.MAP_ROWS) -> void:
	Utils.set_tile(tiles, col, row, kind, cols, rows)

static func paint_road_segment(tiles: Array, c0: int, r0: int, c1: int, r1: int, cols: int = Constants.MAP_COLS, rows: int = Constants.MAP_ROWS) -> void:
	Utils.paint_road_segment(tiles, c0, r0, c1, r1, cols, rows)
