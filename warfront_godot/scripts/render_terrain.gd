class_name RenderTerrain
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func build_terrain_texture(map: Dictionary) -> ImageTexture:
	if map.is_empty():
		return null
		
	var theater = map.get("theater", "kirkuk")
	var pal = Constants.THEATER_PALETTES.get(theater, Constants.THEATER_PALETTES["kirkuk"])
	var w = int(map["width"])
	var h = int(map["height"])
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var ts = Constants.TILE_SIZE
	var cols = int(map["cols"])
	var rows = int(map["rows"])
	var tiles: Array = map["tiles"]
	var map_seed: int = int(map.get("seed", 104729))
	
	# Pseudo-random hash utility
	var hash2d = func(x: int, y: int, seed_offset: float) -> float:
		var n = sin(float(x) * 127.1 + float(y) * 311.7 + seed_offset) * 43758.5453
		return n - floor(n)

	# --------------------------------------------------------------------------
	# Pass 1: Base Terrain Shading with Multi-Frequency Noise & Blending
	# --------------------------------------------------------------------------
	img.fill(pal["groundB"])

	for r in range(rows):
		var y_base = r * ts
		for c in range(cols):
			var x_base = c * ts
			var tile = tiles[r * cols + c]
			var h_val = hash2d.call(c, r, float(map_seed) * 0.13)
			
			if tile == "water" or tile == "bridge":
				# Deep vs Shallow water base
				var w_col = pal["waterDeep"] if h_val > 0.45 else pal["waterShallow"]
				img.fill_rect(Rect2i(x_base, y_base, ts, ts), w_col)
				
				# Shoreline Wet Sand & Foam fringe
				var left_tile = tiles[r * cols + (c - 1)] if c > 0 else "water"
				var right_tile = tiles[r * cols + (c + 1)] if c < cols - 1 else "water"
				var up_tile = tiles[(r - 1) * cols + c] if r > 0 else "water"
				var down_tile = tiles[(r + 1) * cols + c] if r < rows - 1 else "water"
				
				if left_tile != "water" and left_tile != "bridge":
					# Dark wet sand soaked border + water foam edge
					img.fill_rect(Rect2i(x_base, y_base, 8, ts), pal["groundDetail"].darkened(0.25))
					img.fill_rect(Rect2i(x_base + 8, y_base, 3, ts), pal["waterFoam"])
				if right_tile != "water" and right_tile != "bridge":
					img.fill_rect(Rect2i(x_base + ts - 8, y_base, 8, ts), pal["groundDetail"].darkened(0.25))
					img.fill_rect(Rect2i(x_base + ts - 11, y_base, 3, ts), pal["waterFoam"])
				if up_tile != "water" and up_tile != "bridge":
					img.fill_rect(Rect2i(x_base, y_base, ts, 8), pal["groundDetail"].darkened(0.25))
					img.fill_rect(Rect2i(x_base, y_base + 8, ts, 3), pal["waterFoam"])
				if down_tile != "water" and down_tile != "bridge":
					img.fill_rect(Rect2i(x_base, y_base + ts - 8, ts, 8), pal["groundDetail"].darkened(0.25))
					img.fill_rect(Rect2i(x_base, y_base + ts - 11, ts, 3), pal["waterFoam"])
					
			elif tile == "road":
				_paint_road_tile(img, map, c, r, x_base, y_base, ts, pal)
			elif tile == "concrete":
				_paint_concrete_tile(img, x_base, y_base, ts, pal)
			elif tile == "oilfield":
				_paint_oilfield_tile(img, x_base, y_base, ts, pal, h_val)
			elif tile == "rock" or tile == "cliff":
				_paint_cliff_tile(img, x_base, y_base, ts, pal)
			elif tile == "ford":
				_paint_ford_tile(img, x_base, y_base, ts, pal)
			else:
				# Organic Desert / Ground Multi-frequency Noise
				var blob = sin(float(c) * 0.42 + float(map_seed) * 0.01) * cos(float(r) * 0.37) + (h_val - 0.5) * 0.65
				var g_col = pal["groundA"] if blob > 0.15 else pal["groundB"]
				img.fill_rect(Rect2i(x_base, y_base, ts, ts), g_col)
				
				# Sub-tile natural variations (pebbles, sand ripples, silt)
				if h_val > 0.55:
					var px1 = x_base + int(h_val * 28.0)
					var py1 = y_base + int(fmod(h_val * 19.0, 1.0) * 32.0)
					img.fill_rect(Rect2i(px1, py1, 8, 4), pal["groundDetail"])
					img.fill_rect(Rect2i(x_base + int(fmod(h_val * 11.0, 1.0) * 34.0), y_base + int(h_val * 24.0), 4, 4), pal["groundDetail"])
				if h_val < 0.22:
					# Wind-blown sand ridge highlight
					img.fill_rect(Rect2i(x_base + 8 + int(h_val * 40.0), y_base + 16, 14, 3), Color(1.0, 0.94, 0.78, 0.14))
					img.fill_rect(Rect2i(x_base + 12 + int(h_val * 30.0), y_base + 20, 8, 2), Color(1.0, 0.94, 0.78, 0.14))
				if h_val > 0.86:
					# Desert rock outcrops
					img.fill_rect(Rect2i(x_base + 18, y_base + 18, 6, 6), Color("#3d3a2c"))
					img.fill_rect(Rect2i(x_base + 18, y_base + 16, 4, 3), Color("#5c5840"))

	# Tactical Military Sector Grid (Every 4 tiles)
	var grid_col = Color(0.06, 0.06, 0.05, 0.07)
	for gx in range(0, w, ts * 4):
		for gy in range(h):
			img.set_pixel(gx, gy, grid_col)
	for gy in range(0, h, ts * 4):
		for gx in range(w):
			img.set_pixel(gx, gy, grid_col)

	return ImageTexture.create_from_image(img)

static func _paint_road_tile(img: Image, map: Dictionary, c: int, r: int, x: int, y: int, ts: int, pal: Dictionary) -> void:
	var cols = int(map["cols"])
	var rows = int(map["rows"])
	var is_road_conn = func(tc: int, tr: int) -> bool:
		if tc < 0 or tc >= cols or tr < 0 or tr >= rows:
			return false
		var nt = map["tiles"][tr * cols + tc]
		return nt == "road" or nt == "bridge" or nt == "concrete"

	var n_up = is_road_conn.call(c, r - 1)
	var n_down = is_road_conn.call(c, r + 1)
	var n_left = is_road_conn.call(c - 1, r)
	var n_right = is_road_conn.call(c + 1, r)

	# 1. Compacted gravel shoulder / road foundation
	img.fill_rect(Rect2i(x, y, ts, ts), pal["roadEdge"])

	# 2. Main asphalt deck
	var m = 4 # curb margin
	img.fill_rect(Rect2i(x + m, y + m, ts - m * 2, ts - m * 2), pal["roadAsphalt"])
	if n_left:
		img.fill_rect(Rect2i(x, y + m, m, ts - m * 2), pal["roadAsphalt"])
	if n_right:
		img.fill_rect(Rect2i(x + ts - m, y + m, m, ts - m * 2), pal["roadAsphalt"])
	if n_up:
		img.fill_rect(Rect2i(x + m, y, ts - m * 2, m), pal["roadAsphalt"])
	if n_down:
		img.fill_rect(Rect2i(x + m, y + ts - m, ts - m * 2, m), pal["roadAsphalt"])

	# 3. Heavy vehicle tire wear grooves & central oil drips
	var tire_col = Color(0.06, 0.06, 0.05, 0.32)
	var oil_drip = Color(0.04, 0.04, 0.03, 0.45)
	if (n_left or n_right) and not (n_up or n_down):
		img.fill_rect(Rect2i(x, y + 9, ts, 3), tire_col)
		img.fill_rect(Rect2i(x, y + ts - 12, ts, 3), tire_col)
		img.fill_rect(Rect2i(x + 12, y + int(ts / 2) - 1, 14, 2), oil_drip)
	elif (n_up or n_down) and not (n_left or n_right):
		img.fill_rect(Rect2i(x + 9, y, 3, ts), tire_col)
		img.fill_rect(Rect2i(x + ts - 12, y, 3, ts), tire_col)
		img.fill_rect(Rect2i(x + int(ts / 2) - 1, y + 12, 2, 14), oil_drip)

	# 4. White edge guide lines (fog lines)
	var white_edge = Color(1.0, 1.0, 1.0, 0.42)
	if not n_up:
		img.fill_rect(Rect2i(x + (0 if n_left else m), y + m, ts - (0 if n_left else m) - (0 if n_right else m), 1), white_edge)
	if not n_down:
		img.fill_rect(Rect2i(x + (0 if n_left else m), y + ts - m - 1, ts - (0 if n_left else m) - (0 if n_right else m), 1), white_edge)
	if not n_left:
		img.fill_rect(Rect2i(x + m, y + (0 if n_up else m), 1, ts - (0 if n_up else m) - (0 if n_down else m)), white_edge)
	if not n_right:
		img.fill_rect(Rect2i(x + ts - m - 1, y + (0 if n_up else m), 1, ts - (0 if n_up else m) - (0 if n_down else m)), white_edge)

	# 5. Yellow road markings
	var stripe_col = pal["roadStripe"]
	var mid = int(ts / 2)
	var conn_count = (1 if n_up else 0) + (1 if n_down else 0) + (1 if n_left else 0) + (1 if n_right else 0)

	if conn_count <= 2 and (n_left or n_right) and not (n_up or n_down):
		img.fill_rect(Rect2i(x + 6, y + mid - 1, 11, 2), stripe_col)
		img.fill_rect(Rect2i(x + 27, y + mid - 1, 11, 2), stripe_col)
	elif conn_count <= 2 and (n_up or n_down) and not (n_left or n_right):
		img.fill_rect(Rect2i(x + mid - 1, y + 6, 2, 11), stripe_col)
		img.fill_rect(Rect2i(x + mid - 1, y + 27, 2, 11), stripe_col)
	elif conn_count == 2 and not ((n_left and n_right) or (n_up and n_down)):
		# L-Corner Turn
		if n_left and n_up:
			img.fill_rect(Rect2i(x + 6, y + mid - 1, 8, 2), stripe_col)
			img.fill_rect(Rect2i(x + mid - 1, y + 6, 2, 8), stripe_col)
			img.fill_rect(Rect2i(x + mid - 3, y + mid - 3, 3, 3), stripe_col)
		elif n_right and n_up:
			img.fill_rect(Rect2i(x + mid, y + mid - 1, 8, 2), stripe_col)
			img.fill_rect(Rect2i(x + mid - 1, y + 6, 2, 8), stripe_col)
			img.fill_rect(Rect2i(x + mid, y + mid - 3, 3, 3), stripe_col)
		elif n_left and n_down:
			img.fill_rect(Rect2i(x + 6, y + mid - 1, 8, 2), stripe_col)
			img.fill_rect(Rect2i(x + mid - 1, y + mid, 2, 8), stripe_col)
			img.fill_rect(Rect2i(x + mid - 3, y + mid, 3, 3), stripe_col)
		elif n_right and n_down:
			img.fill_rect(Rect2i(x + mid, y + mid - 1, 8, 2), stripe_col)
			img.fill_rect(Rect2i(x + mid - 1, y + mid, 2, 8), stripe_col)
			img.fill_rect(Rect2i(x + mid, y + mid, 3, 3), stripe_col)
	elif conn_count >= 3:
		# Junctions
		img.fill_rect(Rect2i(x + mid - 2, y + mid - 2, 4, 4), stripe_col)
		if n_left:
			img.fill_rect(Rect2i(x + 4, y + mid - 1, 6, 2), stripe_col)
		if n_right:
			img.fill_rect(Rect2i(x + ts - 10, y + mid - 1, 6, 2), stripe_col)
		if n_up:
			img.fill_rect(Rect2i(x + mid - 1, y + 4, 2, 6), stripe_col)
		if n_down:
			img.fill_rect(Rect2i(x + mid - 1, y + ts - 10, 2, 6), stripe_col)
	else:
		img.fill_rect(Rect2i(x + 10, y + mid - 1, 10, 2), stripe_col)
		img.fill_rect(Rect2i(x + 28, y + mid - 1, 10, 2), stripe_col)

static func _paint_concrete_tile(img: Image, x: int, y: int, ts: int, pal: Dictionary) -> void:
	img.fill_rect(Rect2i(x, y, ts, ts), pal["concrete"])
	var half = int(ts / 2)
	var joint_col = Color(0.10, 0.10, 0.08, 0.55)
	var bevel_light = Color(1.0, 1.0, 1.0, 0.16)
	var bevel_shadow = Color(0.06, 0.06, 0.05, 0.22)
	var bolt_col = Color(0.18, 0.18, 0.16, 0.8)

	var sub_rects = [
		Rect2i(x, y, half, half),
		Rect2i(x + half, y, half, half),
		Rect2i(x, y + half, half, half),
		Rect2i(x + half, y + half, half, half)
	]
	for sr in sub_rects:
		img.fill_rect(Rect2i(sr.position.x + 1, sr.position.y + 1, sr.size.x - 2, 1), bevel_light)
		img.fill_rect(Rect2i(sr.position.x + 1, sr.position.y + 1, 1, sr.size.y - 2), bevel_light)
		img.fill_rect(Rect2i(sr.position.x + 1, sr.position.y + sr.size.y - 2, sr.size.x - 2, 1), bevel_shadow)
		img.fill_rect(Rect2i(sr.position.x + sr.size.x - 2, sr.position.y + 1, 1, sr.size.y - 2), bevel_shadow)
		img.fill_rect(Rect2i(sr.position.x + 3, sr.position.y + 3, 2, 2), bolt_col)
		img.fill_rect(Rect2i(sr.position.x + sr.size.x - 5, sr.position.y + 3, 2, 2), bolt_col)
		img.fill_rect(Rect2i(sr.position.x + 3, sr.position.y + sr.size.y - 5, 2, 2), bolt_col)
		img.fill_rect(Rect2i(sr.position.x + sr.size.x - 5, sr.position.y + sr.size.y - 5, 2, 2), bolt_col)

	img.fill_rect(Rect2i(x, y, ts, 1), joint_col)
	img.fill_rect(Rect2i(x, y, 1, ts), joint_col)
	img.fill_rect(Rect2i(x, y + half, ts, 1), joint_col)
	img.fill_rect(Rect2i(x + half, y, 1, ts), joint_col)

static func _paint_oilfield_tile(img: Image, x: int, y: int, ts: int, pal: Dictionary, h_val: float) -> void:
	img.fill_rect(Rect2i(x, y, ts, ts), pal["oilfield"])
	img.fill_rect(Rect2i(x + 5 + int(h_val * 12.0), y + 6 + int(h_val * 10.0), 16, 12), Color("#151310"))
	img.fill_rect(Rect2i(x + 7 + int(h_val * 12.0), y + 8 + int(h_val * 10.0), 12, 8), Color("#0b0a08"))
	img.fill_rect(Rect2i(x + 8 + int(h_val * 12.0), y + 9 + int(h_val * 10.0), 4, 2), Color(0.25, 0.28, 0.32, 0.45))
	img.fill_rect(Rect2i(x + 3, y + 3, ts - 6, 2), Color(0.48, 0.42, 0.32, 0.35))
	img.fill_rect(Rect2i(x + 3, y + ts - 5, ts - 6, 2), Color(0.18, 0.16, 0.12, 0.4))

static func _paint_cliff_tile(img: Image, x: int, y: int, ts: int, pal: Dictionary) -> void:
	img.fill_rect(Rect2i(x, y, ts, ts), pal.get("rockShadow", Color("#302417")))
	img.fill_rect(Rect2i(x + 2, y + 2, ts - 4, ts - 5), pal.get("rockFace", Color("#523f2a")))
	img.fill_rect(Rect2i(x + 2, y + 2, ts - 4, 6), pal.get("rockTop", Color("#b49667")))
	img.fill_rect(Rect2i(x + 4, y + 16, ts - 8, 2), Color(0.12, 0.08, 0.05, 0.65))
	img.fill_rect(Rect2i(x + 8, y + 28, ts - 14, 2), Color(0.12, 0.08, 0.05, 0.65))

static func _paint_ford_tile(img: Image, x: int, y: int, ts: int, pal: Dictionary) -> void:
	img.fill_rect(Rect2i(x, y, ts, ts), pal.get("ford", Color("#326177")))
	img.fill_rect(Rect2i(x + 4, y + 8, ts - 8, 4), pal["groundDetail"])
	img.fill_rect(Rect2i(x + 8, y + 24, ts - 16, 4), pal["groundDetail"])
	img.fill_rect(Rect2i(x + 12, y + 14, 8, 6), pal.get("rockFace", Color("#523f2a")))
	img.fill_rect(Rect2i(x + 28, y + 30, 6, 5), pal.get("rockFace", Color("#523f2a")))
	img.fill_rect(Rect2i(x + 10, y + 13, 12, 2), pal["waterFoam"])
	img.fill_rect(Rect2i(x + 26, y + 29, 10, 2), pal["waterFoam"])
