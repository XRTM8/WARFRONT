class_name RenderWater
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func draw_water_dynamics(canvas: CanvasItem, map: Dictionary, pal: Dictionary, sim_time: float, view_rect: Rect2) -> void:
	if map.is_empty() or not map.has("tiles"):
		return
		
	var ts = Constants.TILE_SIZE
	var cols = int(map["cols"])
	var rows = int(map["rows"])
	var tiles: Array = map["tiles"]
	
	var foam_base = pal.get("waterFoam", Color("#589cb3"))
	var foam_col = Color(foam_base.r, foam_base.g, foam_base.b, 0.45)
	var shimmer_col = Color(1.0, 1.0, 1.0, 0.28)
	var caustic_col = Color(0.85, 0.95, 1.0, 0.16)
	
	# Compute tile bounds inside view_rect for 60 FPS culling
	var c_start = max(0, int(view_rect.position.x / ts) - 1)
	var c_end = min(cols - 1, int((view_rect.position.x + view_rect.size.x) / ts) + 1)
	var r_start = max(0, int(view_rect.position.y / ts) - 1)
	var r_end = min(rows - 1, int((view_rect.position.y + view_rect.size.y) / ts) + 1)
	
	for r in range(r_start, r_end + 1):
		for c in range(c_start, c_end + 1):
			var tile = tiles[r * cols + c]
			if tile != "water" and tile != "ford":
				continue
				
			var tx = float(c * ts)
			var ty = float(r * ts)
			
			# 1. Vector River Current (Downstream flow North -> South with slight diagonal drift)
			var flow_speed = 32.0 # px/sec
			var stream_shift = fmod(sim_time * flow_speed + float(c * 17 + r * 23), 48.0)
			
			var ripple_y = ty + stream_shift
			var ripple_x = tx + 8.0 + sin(ripple_y * 0.08 + sim_time * 2.0) * 6.0
			
			if ripple_y < ty + ts:
				canvas.draw_rect(Rect2(ripple_x, ripple_y, 14.0, 2.0), foam_col)
				
			# 2. Specular Sunlight Glints & Caustic Ribbons in Shallow Areas
			var caustic_pulse = sin(sim_time * 3.5 + float(c * 2 + r * 3))
			if caustic_pulse > 0.3:
				var cx = tx + 12.0 + caustic_pulse * 8.0
				var cy = ty + 10.0 + sin(sim_time * 2.5 + float(c)) * 6.0
				canvas.draw_line(Vector2(cx, cy), Vector2(cx + 8.0, cy + 4.0), caustic_col, 1.5)
				canvas.draw_line(Vector2(cx + 4.0, cy - 2.0), Vector2(cx + 12.0, cy + 2.0), shimmer_col, 1.0)
				
			# 3. Dynamic Shoreline Breaking Foam (checks if bordering land)
			var has_land_left = (c > 0 and tiles[r * cols + (c - 1)] != "water" and tiles[r * cols + (c - 1)] != "ford")
			var has_land_right = (c < cols - 1 and tiles[r * cols + (c + 1)] != "water" and tiles[r * cols + (c + 1)] != "ford")
			
			var surf = (sin(sim_time * 4.0 + float(r * 2)) + 1.0) * 0.5 # 0.0 to 1.0 wave pulse
			if has_land_left:
				var wave_w = 4.0 + surf * 5.0
				canvas.draw_rect(Rect2(tx, ty, wave_w, float(ts)), Color(foam_base.r, foam_base.g, foam_base.b, 0.30 + surf * 0.25))
			if has_land_right:
				var wave_w = 4.0 + surf * 5.0
				canvas.draw_rect(Rect2(tx + float(ts) - wave_w, ty, wave_w, float(ts)), Color(foam_base.r, foam_base.g, foam_base.b, 0.30 + surf * 0.25))

static func draw_pier_wakes(canvas: CanvasItem, map: Dictionary, pal: Dictionary, sim_time: float, view_rect: Rect2) -> void:
	if not map.has("bridges"):
		return
	var foam_base = pal.get("waterFoam", Color("#589cb3"))
	
	for b in map["bridges"]:
		var bx = float(b["x"])
		var by = float(b["y"])
		var bw = float(b["width"])
		var bh = float(b["height"])
		
		if not view_rect.has_point(Vector2(bx, by)):
			continue
			
		var piers = [bx - bw * 0.22, bx + bw * 0.22]
		for px in piers:
			var py_top = by - bh * 0.5 - 4.0
			var py_bottom = by + bh * 0.5 + 4.0
			
			# V-Shaped Wake upstream
			var wake_expand = (sin(sim_time * 6.0 + px) + 1.0) * 2.0
			var left_wing = Vector2(px - 10.0 - wake_expand, py_top - 6.0)
			var apex = Vector2(px, py_top - 12.0)
			var right_wing = Vector2(px + 10.0 + wake_expand, py_top - 6.0)
			
			canvas.draw_line(apex, left_wing, Color(foam_base.r, foam_base.g, foam_base.b, 0.55), 1.8)
			canvas.draw_line(apex, right_wing, Color(foam_base.r, foam_base.g, foam_base.b, 0.55), 1.8)
			
			# Downstream trailing foam vortices
			var vortex_shift = fmod(sim_time * 26.0 + px, 32.0)
			canvas.draw_circle(Vector2(px - 3.0, py_bottom + vortex_shift), 2.5, Color(foam_base.r, foam_base.g, foam_base.b, 0.35 * (1.0 - vortex_shift / 32.0)))
			canvas.draw_circle(Vector2(px + 3.0, py_bottom + vortex_shift * 0.8), 2.0, Color(foam_base.r, foam_base.g, foam_base.b, 0.35 * (1.0 - vortex_shift / 32.0)))
