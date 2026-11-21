class_name RenderStructuresProd
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func draw_production_structure(canvas: CanvasItem, s: Dictionary, sim_time: float, pal: Dictionary) -> bool:
	var kind = s.get("kind", "")
	var pos = Vector2(s["x"], s["y"])
	var w = s.get("width", 64.0)
	var h = s.get("height", 54.0)
	var fac_col = pal.get("player", Color("#22c55e")) if s["faction"] == "player" else pal.get("enemy", Color("#ef4444"))
	var base_col = Color("#1e211a")
	
	if kind == "airfield":
		_draw_airfield(canvas, pos, w, h, fac_col, base_col, sim_time)
		return true
	elif kind == "shipyard":
		_draw_shipyard(canvas, pos, w, h, fac_col, base_col, sim_time)
		return true
	elif kind == "barracks":
		_draw_barracks(canvas, pos, w, h, fac_col, base_col, sim_time)
		return true
	elif kind == "missile_plant":
		_draw_missile_plant(canvas, pos, w, h, fac_col, base_col, sim_time)
		return true
		
	return false

static func _draw_airfield(canvas: CanvasItem, pos: Vector2, w: float, h: float, fac_col: Color, base_col: Color, sim_time: float) -> void:
	# 1. Main Asphalt Runway & Apron
	canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), Color("#151618"))
	canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), Color("#3f3f46"), false, 1.5)
	
	# Runway yellow centerline dashed markings
	var rw_y = pos.y + h * 0.12
	for x_seg in range(int(pos.x - w * 0.45), int(pos.x + w * 0.45), 14):
		canvas.draw_line(Vector2(x_seg, rw_y), Vector2(x_seg + 8, rw_y), Color("#facc15"), 2.0)
		
	# Runway threshold piano keys (stripes) at both ends
	for ox in [-w * 0.45, w * 0.40]:
		for oy in range(-8, 10, 4):
			canvas.draw_rect(Rect2(pos.x + ox, rw_y + oy - 1, 6, 2), Color("#f8fafc"))
			
	# 2. Hardened Aircraft Hangar Bay
	var h_w = w * 0.38
	var h_h = h * 0.45
	var h_pos = Vector2(pos.x - w * 0.26, pos.y - h * 0.24)
	canvas.draw_rect(Rect2(h_pos.x - h_w * 0.5, h_pos.y - h_h * 0.5, h_w, h_h), Color("#27272a"))
	canvas.draw_rect(Rect2(h_pos.x - h_w * 0.5, h_pos.y - h_h * 0.5, h_w, h_h), fac_col, false, 2.0)
	
	# Hangar door opening
	canvas.draw_rect(Rect2(h_pos.x - h_w * 0.4, h_pos.y + h_h * 0.1, h_w * 0.8, h_h * 0.4), Color("#09090b"))
	
	# 3. Rotating Air Traffic Radar Dome
	var r_pos = Vector2(pos.x + w * 0.34, pos.y - h * 0.24)
	canvas.draw_circle(r_pos, 7.5, Color("#18181b"))
	canvas.draw_circle(r_pos, 6.0, Color("#38bdf8"))
	var r_ang = sim_time * 4.2
	var r_dish = r_pos + Vector2(cos(r_ang), sin(r_ang)) * 8.0
	canvas.draw_line(r_pos, r_dish, Color("#f8fafc"), 2.0)

static func _draw_shipyard(canvas: CanvasItem, pos: Vector2, w: float, h: float, fac_col: Color, base_col: Color, sim_time: float) -> void:
	# 1. Reinforced Concrete Mooring Quay
	canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w * 0.65, h), base_col)
	canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w * 0.65, h), fac_col, false, 2.0)
	
	# 2. Flooded Drydock Slipway extending into river
	var slip_x = pos.x + w * 0.15
	var slip_w = w * 0.35
	canvas.draw_rect(Rect2(slip_x - slip_w * 0.5, pos.y - h * 0.42, slip_w, h * 0.84), Color("#0e2537"))
	canvas.draw_rect(Rect2(slip_x - slip_w * 0.5, pos.y - h * 0.42, slip_w, h * 0.84), Color("#0284c7"), false, 1.5)
	
	# Timber slipway guide rails
	canvas.draw_line(Vector2(slip_x - slip_w * 0.35, pos.y - h * 0.35), Vector2(slip_x - slip_w * 0.35, pos.y + h * 0.35), Color("#a1a1aa"), 2.0)
	canvas.draw_line(Vector2(slip_x + slip_w * 0.35, pos.y - h * 0.35), Vector2(slip_x + slip_w * 0.35, pos.y + h * 0.35), Color("#a1a1aa"), 2.0)
	
	# Water foam in the slipway basin
	var wave_shift = sin(sim_time * 3.0) * 4.0
	canvas.draw_line(Vector2(slip_x - 8, pos.y + wave_shift), Vector2(slip_x + 8, pos.y + wave_shift), Color(0.6, 0.9, 1.0, 0.45), 2.0)
	
	# 3. Heavy Gantry Crane Tower
	var crane_pos = Vector2(pos.x - w * 0.22, pos.y - h * 0.2)
	canvas.draw_rect(Rect2(crane_pos.x - 5, crane_pos.y - 5, 10, 10), Color("#f59e0b"))
	canvas.draw_line(crane_pos, crane_pos + Vector2(16, -6), Color("#d97706"), 3.0) # Crane boom

static func _draw_barracks(canvas: CanvasItem, pos: Vector2, w: float, h: float, fac_col: Color, base_col: Color, sim_time: float) -> void:
	# 1. Concrete Garrison Compound
	canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), base_col)
	canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), fac_col, false, 2.0)
	
	# Sandbag perimeter wall
	canvas.draw_rect(Rect2(pos.x - w * 0.46, pos.y + h * 0.36, w * 0.92, 5), Color("#b45309"))
	
	# Quonset Hut Roof Ribs
	for i in range(-2, 3):
		var rib_x = pos.x + float(i) * (w * 0.16)
		canvas.draw_line(Vector2(rib_x, pos.y - h * 0.35), Vector2(rib_x, pos.y + h * 0.25), Color("#3f3f46"), 2.0)
		
	# 2. Communications Antenna Mast with beacon light
	var mast_pos = Vector2(pos.x + w * 0.35, pos.y - h * 0.35)
	canvas.draw_line(mast_pos, mast_pos + Vector2(0, -14), Color("#e4e4e7"), 1.8)
	var beacon_flicker = 0.5 + sin(sim_time * 8.0) * 0.5
	canvas.draw_circle(mast_pos + Vector2(0, -15), 2.5, Color(1.0, 0.2, 0.2, beacon_flicker))

static func _draw_missile_plant(canvas: CanvasItem, pos: Vector2, w: float, h: float, fac_col: Color, base_col: Color, sim_time: float) -> void:
	# 1. Reinforced Blast Walls & Launch Pit
	canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), Color("#18181b"))
	canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), Color("#dc2626"), false, 2.0)
	
	# Blast deflector wedges (slanted blast walls)
	for ox in [-w * 0.42, w * 0.42]:
		canvas.draw_rect(Rect2(pos.x + ox - 4, pos.y - h * 0.4, 8, h * 0.8), Color("#3f3f46"))
		
	# 2. Central Missile Assembly Bay & Silo Doors
	var bay_w = w * 0.44
	var bay_h = h * 0.55
	canvas.draw_rect(Rect2(pos.x - bay_w * 0.5, pos.y - bay_h * 0.5, bay_w, bay_h), Color("#27272a"))
	
	# Missile warhead resting on elevator rack
	canvas.draw_circle(pos, 6.0, Color("#ef4444"))
	canvas.draw_line(pos + Vector2(0, -10), pos + Vector2(0, 10), Color("#f8fafc"), 2.0)
	
	# Hazard chevron stripes on launch platform
	for cx in range(int(pos.x - bay_w * 0.4), int(pos.x + bay_w * 0.4), 8):
		canvas.draw_line(Vector2(cx, pos.y + bay_h * 0.3), Vector2(cx + 4, pos.y + bay_h * 0.45), Color("#f59e0b"), 1.5)
