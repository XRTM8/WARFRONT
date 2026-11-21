class_name RenderEnvironment
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func draw_pipeline_conduits(canvas: CanvasItem, map: Dictionary, view_rect: Rect2) -> void:
	if not map.has("rigs") or not map.has("playerHQ"):
		return
		
	var pipe_col = Color("#3f3f46")
	var pipe_hilight = Color("#71717a")
	var flange_col = Color("#18181b")
	var shadow_col = Color(0.04, 0.05, 0.06, 0.35)
	
	# Connect nearest 2 rigs to player HQ with industrial surface pipeline
	var hq = map["playerHQ"]
	var hq_pos = Vector2(hq["x"], hq["y"])
	
	for rig in map["rigs"]:
		var r_pos = Vector2(rig["x"], rig["y"])
		if r_pos.distance_to(hq_pos) > 850.0:
			continue
			
		var line_rect = Rect2(min(hq_pos.x, r_pos.x), min(hq_pos.y, r_pos.y), abs(hq_pos.x - r_pos.x), abs(hq_pos.y - r_pos.y))
		if not view_rect.intersects(line_rect):
			continue
			
		# Mid-point routing (L-shaped industrial conduit along ground)
		var corner = Vector2(hq_pos.x + (r_pos.x - hq_pos.x) * 0.45, hq_pos.y + 45.0)
		
		# 1. Pipeline drop shadows
		canvas.draw_line(hq_pos + Vector2(4, 4), corner + Vector2(4, 4), shadow_col, 5.0)
		canvas.draw_line(corner + Vector2(4, 4), r_pos + Vector2(4, 4), shadow_col, 5.0)
		
		# 2. Main Steel Pipeline
		canvas.draw_line(hq_pos, corner, pipe_col, 4.0)
		canvas.draw_line(corner, r_pos, pipe_col, 4.0)
		canvas.draw_line(hq_pos - Vector2(0, 1), corner - Vector2(0, 1), pipe_hilight, 1.2)
		canvas.draw_line(corner - Vector2(0, 1), r_pos - Vector2(0, 1), pipe_hilight, 1.2)
		
		# 3. Expansion Joint Flanges
		var segs = int(hq_pos.distance_to(corner) / 65.0)
		for i in range(1, segs):
			var fp = hq_pos.lerp(corner, float(i) / float(segs))
			canvas.draw_rect(Rect2(fp.x - 3, fp.y - 4, 6, 8), flange_col)
			canvas.draw_circle(fp, 1.8, Color("#ef4444")) # Valve indicator

static func draw_power_pylons(canvas: CanvasItem, map: Dictionary, sim_time: float, view_rect: Rect2) -> void:
	if not map.has("width") or not map.has("height"):
		return
		
	var w = float(map["width"])
	var h = float(map["height"])
	var ts = Constants.TILE_SIZE
	
	# Place transmission corridor across map periphery
	var pylon_y = 120.0
	var step_x = 260.0
	var cur_x = 100.0
	
	var pylon_col = Color("#52525b")
	var cable_col = Color(0.12, 0.12, 0.14, 0.55)
	var shadow_col = Color(0.04, 0.05, 0.06, 0.38)
	
	var prev_pylon = Vector2.ZERO
	
	while cur_x < w - 100.0:
		var p_pos = Vector2(cur_x, pylon_y)
		
		if view_rect.has_point(p_pos):
			# Directional shadow of lattice tower
			var s_off = Vector2(10, 10)
			canvas.draw_line(p_pos + s_off, p_pos + s_off + Vector2(0, -32), shadow_col, 3.5)
			
			# Steel Lattice Tower
			canvas.draw_line(Vector2(cur_x - 7, pylon_y), Vector2(cur_x, pylon_y - 36), pylon_col, 2.0)
			canvas.draw_line(Vector2(cur_x + 7, pylon_y), Vector2(cur_x, pylon_y - 36), pylon_col, 2.0)
			# Crossarm
			canvas.draw_line(Vector2(cur_x - 14, pylon_y - 28), Vector2(cur_x + 14, pylon_y - 28), pylon_col, 2.0)
			# Insulator pods
			canvas.draw_circle(Vector2(cur_x - 12, pylon_y - 26), 2.0, Color("#e4e4e7"))
			canvas.draw_circle(Vector2(cur_x + 12, pylon_y - 26), 2.0, Color("#e4e4e7"))
			
			# Red warning strobe light on tower tip
			var blink = sin(sim_time * 4.0 + cur_x * 0.01) > 0.6
			if blink:
				canvas.draw_circle(Vector2(cur_x, pylon_y - 37), 2.5, Color("#ef4444"))
		
		# Overhead Power Cable Swag (Catenary curve)
		if prev_pylon != Vector2.ZERO:
			if view_rect.intersects(Rect2(prev_pylon.x, pylon_y - 40, cur_x - prev_pylon.x, 50)):
				var mid_x = (prev_pylon.x + cur_x) * 0.5
				var sag_y = pylon_y - 23.0 # Sagging cable
				canvas.draw_line(prev_pylon + Vector2(12, -26), Vector2(mid_x, sag_y), cable_col, 1.2)
				canvas.draw_line(Vector2(mid_x, sag_y), Vector2(cur_x - 12, pylon_y - 26), cable_col, 1.2)
				
		prev_pylon = p_pos
		cur_x += step_x

static func draw_arid_vegetation_and_rocks(canvas: CanvasItem, map: Dictionary, view_rect: Rect2) -> void:
	if not map.has("tiles"):
		return
		
	var ts = Constants.TILE_SIZE
	var cols = int(map["cols"])
	var rows = int(map["rows"])
	var tiles: Array = map["tiles"]
	var map_seed = int(map.get("seed", 104729))
	
	var c_start = max(0, int(view_rect.position.x / ts) - 1)
	var c_end = min(cols - 1, int((view_rect.position.x + view_rect.size.x) / ts) + 1)
	var r_start = max(0, int(view_rect.position.y / ts) - 1)
	var r_end = min(rows - 1, int((view_rect.position.y + view_rect.size.y) / ts) + 1)
	
	var scrub_col1 = Color("#555938")
	var scrub_col2 = Color("#3e4228")
	var rock_col = Color("#4a3e2f")
	var shadow_col = Color(0.04, 0.05, 0.06, 0.32)
	
	for r in range(r_start, r_end + 1):
		for c in range(c_start, c_end + 1):
			var tile = tiles[r * cols + c]
			if tile != "ground":
				continue
				
			# Deterministic hash for natural placement
			var h = sin(float(c) * 31.7 + float(r) * 89.3 + float(map_seed) * 0.17) * 43758.5453
			h = h - floor(h)
			
			var px = float(c * ts) + 10.0 + h * 12.0
			var py = float(r * ts) + 10.0 + fmod(h * 13.0, 1.0) * 12.0
			
			if h > 0.94:
				# Clustered Desert Scrub Shrub
				canvas.draw_circle(Vector2(px + 3, py + 3), 4.5, shadow_col)
				canvas.draw_circle(Vector2(px, py), 4.0, scrub_col1)
				canvas.draw_circle(Vector2(px + 2, py - 1), 2.5, scrub_col2)
			elif h < 0.045:
				# Natural Granite Boulder Field
				canvas.draw_rect(Rect2(px + 2, py + 2, 7, 5), shadow_col)
				canvas.draw_rect(Rect2(px, py, 7, 5), rock_col)
				canvas.draw_rect(Rect2(px + 1, py + 1, 5, 2), Color("#716350")) # Sunlight edge
