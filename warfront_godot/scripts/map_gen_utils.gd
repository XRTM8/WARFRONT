class_name MapGenUtils
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

static func tile_center(col: int, row: int, ts: int = Constants.TILE_SIZE) -> Vector2:
	return Vector2(
		col * ts + ts / 2.0,
		row * ts + ts / 2.0
	)

static func set_tile(tiles: Array, col: int, row: int, kind: String, cols: int = Constants.MAP_COLS, rows: int = Constants.MAP_ROWS) -> void:
	if col >= 0 and col < cols and row >= 0 and row < rows:
		tiles[row * cols + col] = kind

static func paint_road_segment(tiles: Array, c0: int, r0: int, c1: int, r1: int, cols: int = Constants.MAP_COLS, rows: int = Constants.MAP_ROWS) -> void:
	var c = c0
	var r = r0
	var max_steps = cols + rows + 20
	var steps = 0
	while (c != c1 or r != r1) and steps < max_steps:
		steps += 1
		var idx = r * cols + c
		if tiles[idx] != "water" and tiles[idx] != "bridge" and tiles[idx] != "rock":
			tiles[idx] = "road"
		if c != c1:
			c += 1 if c < c1 else -1
		elif r != r1:
			r += 1 if r < r1 else -1
	var end_idx = r1 * cols + c1
	if tiles[end_idx] != "water" and tiles[end_idx] != "bridge" and tiles[end_idx] != "rock":
		tiles[end_idx] = "road"
