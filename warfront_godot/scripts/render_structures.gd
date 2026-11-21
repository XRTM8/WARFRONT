class_name RenderStructures
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func draw_water_ripples(canvas: CanvasItem, sim_map: Dictionary, foam_color: Color, sim_time: float) -> void:
	var foam = Color(foam_color.r, foam_color.g, foam_color.b, 0.35)
	var ts = Constants.TILE_SIZE
	for r in range(sim_map["rows"]):
		for c in range(sim_map["cols"]):
			var tile = sim_map["tiles"][r * sim_map["cols"] + c]
			if tile == "water":
				var shift = fmod(sim_time * 18.0 + float(r * 13 + c * 9), 36.0)
				var rx = c * ts + 6 + int(fmod(shift, 24.0))
				var ry = r * ts + 12 + int(fmod(float(r * 7), 20.0))
				canvas.draw_rect(Rect2(rx, ry, 12, 2), foam)
				# Secondary subtle shimmer
				if int(shift) % 4 == 0:
					canvas.draw_rect(Rect2(rx + 14, ry + 8, 6, 1), Color(1, 1, 1, 0.2))

static func draw_burning_well(canvas: CanvasItem, pos: Vector2, sim_time: float) -> void:
	var flicker = 0.85 + sin(sim_time * 19.0 + pos.x * 0.1) * 0.15
	
	# 1. Scorch ring on ground
	canvas.draw_circle(pos, 36.0, Color(0.12, 0.10, 0.08, 0.55))
	canvas.draw_arc(pos, 36.0, 0, TAU, 16, Color(0.08, 0.07, 0.05, 0.7), 2.0)
	
	# 2. Dynamic ground combustion light
	canvas.draw_circle(pos, 52.0 * flicker, Color(1.0, 0.42, 0.08, 0.22 * flicker))
	
	# 3. Steel Christmas tree wellhead assembly
	# Base flange
	canvas.draw_rect(Rect2(pos.x - 9, pos.y - 4, 18, 10), Color("#181816"))
	canvas.draw_rect(Rect2(pos.x - 7, pos.y - 2, 14, 6), Color("#27272a"))
	# Vertical master valve stem
	canvas.draw_rect(Rect2(pos.x - 4, pos.y - 12, 8, 12), Color("#181816"))
	canvas.draw_rect(Rect2(pos.x - 3, pos.y - 11, 6, 10), Color("#3f3f46"))
	# Horizontal choke arms & valve handwheels
	canvas.draw_rect(Rect2(pos.x - 12, pos.y - 9, 24, 3), Color("#181816"))
	canvas.draw_circle(Vector2(pos.x - 12, pos.y - 7.5), 2.5, Color("#dc2626")) # Red valve wheel
	canvas.draw_circle(Vector2(pos.x + 12, pos.y - 7.5), 2.5, Color("#dc2626"))
	
	# 4. Multi-layer turbulent roaring fire plume
	# Outer rolling flame
	canvas.draw_circle(pos + Vector2(0, -12), 22.0 * flicker, Color(0.95, 0.32, 0.05, 0.75 * flicker))
	# Mid roaring fireball
	canvas.draw_circle(pos + Vector2(0, -14), 14.0 * flicker, Color(1.0, 0.65, 0.12, 0.88 * flicker))
	# Inner white-hot ignition core
	canvas.draw_circle(pos + Vector2(0, -15), 6.5 * flicker, Color(1.0, 0.96, 0.82, 0.98))
	
	# 5. Billowing black carbon smoke puffs drifting upward
	for s_idx in range(3):
		var s_offset = fmod(sim_time * 24.0 + float(s_idx * 14), 42.0)
		var s_y = pos.y - 24.0 - s_offset
		var s_x = pos.x + sin(s_y * 0.12 + float(s_idx)) * 8.0
		var s_rad = 7.0 + (s_offset / 42.0) * 12.0
		var s_alpha = (1.0 - (s_offset / 42.0)) * 0.45
		canvas.draw_circle(Vector2(s_x, s_y), s_rad, Color(0.12, 0.11, 0.10, s_alpha))

static func draw_bridge(canvas: CanvasItem, default_font: Font, b: Dictionary, pal: Dictionary) -> void:
	var left = b["x"] - b["width"] / 2.0
	var top = b["y"] - b["height"] / 2.0
	
	if b["status"] == "intact":
		# 1. Ground and water drop shadow
		canvas.draw_rect(Rect2(left + 5, top + 10, b["width"], b["height"]), Color(0, 0, 0, 0.38))
		
		# 2. Heavy reinforced concrete piers embedded into water bed
		for px in [left + b["width"] * 0.28, left + b["width"] * 0.72]:
			# Triangular pier cutwater facing upstream
			canvas.draw_rect(Rect2(px - 9, top - 6, 18, b["height"] + 12), Color("#27272a"))
			canvas.draw_rect(Rect2(px - 7, top - 4, 14, b["height"] + 8), Color("#52525b"))
			# Upstream pointed triangular prow
			var cutwater_p1 = Vector2(px - 7, top - 4)
			var cutwater_p2 = Vector2(px, top - 11)
			var cutwater_p3 = Vector2(px + 7, top - 4)
			canvas.draw_colored_polygon(PackedVector2Array([cutwater_p1, cutwater_p2, cutwater_p3]), Color("#71717a"))
			# Pier foam water wake
			canvas.draw_rect(Rect2(px - 11, top - 12, 22, 2), pal["waterFoam"])
		
		# 3. Bridge Road Deck & Asphalt
		var deck_col = Color("#fff5dc") if b["hitFlash"] > 0.0 else pal["bridgeDeck"]
		canvas.draw_rect(Rect2(left, top, b["width"], b["height"]), deck_col)
		canvas.draw_rect(Rect2(left, top + 8, b["width"], b["height"] - 16), pal["roadAsphalt"])
		
		# Steel expansion joints at abutments
		canvas.draw_rect(Rect2(left + 2, top + 8, 3, b["height"] - 16), Color("#18181b"))
		canvas.draw_rect(Rect2(left + b["width"] - 5, top + 8, 3, b["height"] - 16), Color("#18181b"))
		
		# White edge fog lines
		canvas.draw_rect(Rect2(left, top + 9, b["width"], 1), Color(1, 1, 1, 0.35))
		canvas.draw_rect(Rect2(left, top + b["height"] - 10, b["width"], 1), Color(1, 1, 1, 0.35))
		
		# Heavy Industrial Warren-Truss Steel Girders
		# Top girder
		canvas.draw_rect(Rect2(left - 6, top, b["width"] + 12, 8), pal["bridgeSteel"])
		canvas.draw_rect(Rect2(left - 6, top, b["width"] + 12, 2), Color(1, 1, 1, 0.2))
		# Bottom girder
		canvas.draw_rect(Rect2(left - 6, top + b["height"] - 8, b["width"] + 12, 8), pal["bridgeSteel"])
		canvas.draw_rect(Rect2(left - 6, top + b["height"] - 2, b["width"] + 12, 2), Color(0.1, 0.1, 0.1, 0.4))
		
		# Structural Vertical Posts & Diagonal X-Braces
		var cur_post = left + 8.0
		while cur_post <= left + b["width"] - 8.0:
			canvas.draw_rect(Rect2(cur_post, top + 1, 3, 6), Color("#27272a"))
			canvas.draw_rect(Rect2(cur_post, top + b["height"] - 7, 3, 6), Color("#27272a"))
			# Reflective safety cat-eye marker
			canvas.draw_circle(Vector2(cur_post + 1.5, top + 4), 1.5, Color("#f59e0b"))
			canvas.draw_circle(Vector2(cur_post + 1.5, top + b["height"] - 4), 1.5, Color("#f59e0b"))
			cur_post += 24.0
		
		# Yellow Road Center Dashes
		var cur_x = left + 14.0
		while cur_x < left + b["width"] - 14.0:
			canvas.draw_rect(Rect2(cur_x, b["y"] - 1.0, 14, 2), pal["roadStripe"])
			cur_x += 28.0
			
		# Damage HP Bar
		if b["hp"] < b["maxHp"]:
			var pct = max(0.0, b["hp"] / b["maxHp"])
			canvas.draw_rect(Rect2(b["x"] - 36, top - 14, 72, 7), Color(0.08, 0.08, 0.07, 0.9))
			canvas.draw_rect(Rect2(b["x"] - 35, top - 13, round(70.0 * pct), 5), Color("#ef4444") if pct < 0.35 else Color("#eab308"))
	else:
		# Blown Bridge / Destruction State
		# Shattered jagged concrete abutments
		canvas.draw_rect(Rect2(left - 6, top + 2, 26, b["height"] - 4), pal["bridgeDeck"])
		canvas.draw_rect(Rect2(left + b["width"] - 20, top + 2, 26, b["height"] - 4), pal["bridgeDeck"])
		
		# Jagged fracture lines
		canvas.draw_line(Vector2(left + 20, top + 2), Vector2(left + 16, top + b["height"] - 2), Color("#18181b"), 2.5)
		canvas.draw_line(Vector2(left + b["width"] - 20, top + 2), Vector2(left + b["width"] - 16, top + b["height"] - 2), Color("#18181b"), 2.5)
		
		# Protruding twisted rebar rods
		for ry in [top + 8, top + 16, top + 24]:
			canvas.draw_line(Vector2(left + 20, ry), Vector2(left + 30 + randf() * 4, ry - 3), Color("#71717a"), 1.8)
			canvas.draw_line(Vector2(left + b["width"] - 20, ry), Vector2(left + b["width"] - 30 - randf() * 4, ry + 2), Color("#71717a"), 1.8)
		
		# Submerged bridge deck tilted under water with water foam
		canvas.draw_rect(Rect2(b["x"] - 44, b["y"] - 8, 38, 12), Color(0.1, 0.14, 0.16, 0.65))
		canvas.draw_rect(Rect2(b["x"] + 6, b["y"] + 2, 42, 10), Color(0.1, 0.14, 0.16, 0.65))
		canvas.draw_rect(Rect2(b["x"] - 46, b["y"] - 10, 42, 2), pal["waterFoam"])
		canvas.draw_rect(Rect2(b["x"] + 4, b["y"] + 12, 46, 2), pal["waterFoam"])
		
		# Interactive Rebuild Prompt
		var pulse = 0.85 + sin(Time.get_ticks_msec() * 0.006) * 0.15
		var prompt_col = Color(0.96, 0.8, 0.3, pulse)
		canvas.draw_string(default_font, Vector2(b["x"] - 50, b["y"] + 6), "[ REPAIR // انقر للإصلاح ]", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, prompt_col)

static func draw_oil_rig(canvas: CanvasItem, rig: Dictionary) -> void:
	var owner_col = Color("#6cc758") if rig["owner"] == "player" else (Color("#e5534b") if rig["owner"] == "enemy" else Color("#cbb986"))
	var center = Vector2(round(rig["x"]), round(rig["y"]))
	
	# 1. Concrete containment pad with raised perimeter safety curb
	canvas.draw_rect(Rect2(center.x - 28, center.y - 26, 56, 52), Color("#181715"))
	canvas.draw_rect(Rect2(center.x - 27, center.y - 25, 54, 50), Color("#2e2c28"))
	canvas.draw_rect(Rect2(center.x - 28, center.y - 26, 56, 52), owner_col, false, 2.0)
	
	# Corner anchor bolt plates
	for bx in [center.x - 25, center.x + 23]:
		for by in [center.y - 23, center.y + 21]:
			canvas.draw_rect(Rect2(bx, by, 3, 3), Color("#181816"))
			
	# 2. Horizontal crude oil buffer storage tank with live fill sight-glass
	canvas.draw_rect(Rect2(center.x + 8, center.y - 18, 16, 34), Color("#141412"))
	canvas.draw_rect(Rect2(center.x + 9, center.y - 17, 14, 32), Color("#27272a"))
	# Tank saddle cradle supports
	canvas.draw_rect(Rect2(center.x + 7, center.y - 14, 2, 6), Color("#52525b"))
	canvas.draw_rect(Rect2(center.x + 7, center.y + 8, 2, 6), Color("#52525b"))
	# Tank hazard flammability diamond (red/yellow)
	canvas.draw_rect(Rect2(center.x + 13, center.y - 12, 6, 6), Color("#dc2626"))
	canvas.draw_rect(Rect2(center.x + 14, center.y - 11, 4, 4), Color("#f59e0b"))
	# Live crude oil fill sight-glass
	var max_b = max(1.0, rig.get("maxBarrels", 80.0))
	var fill_h = int(round((rig["storedBarrels"] / max_b) * 26.0))
	canvas.draw_rect(Rect2(center.x + 11, center.y + 13 - fill_h, 10, fill_h), Color("#e6a838"))
	canvas.draw_rect(Rect2(center.x + 11, center.y - 13, 2, 26), Color("#fef3c7")) # Glass reflection
	
	# 3. Steel Lattice Derrick Tower with Structural X-Bracing
	canvas.draw_rect(Rect2(center.x - 22, center.y - 18, 24, 36), Color("#181816"))
	canvas.draw_rect(Rect2(center.x - 20, center.y - 16, 20, 32), Color("#3f3f46"))
	canvas.draw_rect(Rect2(center.x - 17, center.y - 13, 14, 26), Color("#18181b"))
	# Structural diagonal cross-braces
	canvas.draw_line(Vector2(center.x - 20, center.y - 16), Vector2(center.x, center.y + 16), Color("#52525b"), 1.5)
	canvas.draw_line(Vector2(center.x, center.y - 16), Vector2(center.x - 20, center.y + 16), Color("#52525b"), 1.5)
	# Derrick apex crown block
	canvas.draw_rect(Rect2(center.x - 14, center.y - 22, 8, 5), Color("#71717a"))
	
	# 4. Rocking Walking Beam & Curved Horse-Head Pumpjack
	var rock = sin(rig["pumpPhase"]) * 6.0
	# Samson post pivot
	canvas.draw_rect(Rect2(center.x - 12, center.y - 6, 6, 16), Color("#27272a"))
	# Rocking walking beam
	canvas.draw_rect(Rect2(center.x - 24, center.y - 6 + rock * 0.45, 30, 6), Color("#71717a"))
	canvas.draw_rect(Rect2(center.x - 24, center.y - 5 + rock * 0.45, 28, 4), Color("#a1a1aa"))
	# Front curved horse-head
	canvas.draw_rect(Rect2(center.x - 26, center.y - 9 + rock * 0.45, 7, 12), owner_col)
	canvas.draw_rect(Rect2(center.x - 25, center.y - 8 + rock * 0.45, 5, 10), Color(1, 1, 1, 0.35))
	# Sucker rod line dropping into stuffing box
	var rod_y_bottom = center.y + 12
	var rod_y_top = center.y - 3 + rock * 0.45
	canvas.draw_line(Vector2(center.x - 23, rod_y_top), Vector2(center.x - 23, rod_y_bottom), Color("#e4e4e7"), 1.5)
	
	# 5. Transformer / Utility Box
	canvas.draw_rect(Rect2(center.x - 26, center.y + 12, 8, 10), Color("#181816"))
	canvas.draw_rect(Rect2(center.x - 25, center.y + 13, 6, 8), Color("#3f3f46"))
	canvas.draw_circle(Vector2(center.x - 22, center.y + 17), 1.5, Color("#f59e0b")) # Status light
	
	# 6. Contested Capture Arc
	var abs_cap = abs(rig["captureProgress"])
	if abs_cap > 2.0 and abs_cap < 100.0:
		var cap_col = Color("#78d464") if rig["captureProgress"] > 0.0 else Color("#ef5350")
		var ang = (abs_cap / 100.0) * PI * 2.0
		canvas.draw_arc(center, 36.0, -PI / 2.0, -PI / 2.0 + ang, 24, cap_col, 3.5)
		canvas.draw_arc(center, 36.0, -PI / 2.0, -PI / 2.0 + ang, 24, Color(1, 1, 1, 0.4), 1.5)

static func draw_hq(canvas: CanvasItem, hq: Dictionary) -> void:
	var is_player = hq["faction"] == "player"
	var primary = Color("#589e47") if is_player else Color("#c9453e")
	var primary_light = Color("#78d464") if is_player else Color("#ef5350")
	var center = Vector2(round(hq["x"]), round(hq["y"]))
	
	# 1. Ground Drop Shadow
	canvas.draw_rect(Rect2(center.x - 44, center.y - 38, 90, 80), Color(0, 0, 0, 0.42))
	
	# 2. Multi-tier Reinforced Blast Bunker Foundation
	var base_col = Color.WHITE if hq["hitFlash"] > 0.0 else Color("#2c2d28")
	canvas.draw_rect(Rect2(center.x - 42, center.y - 36, 84, 72), base_col)
	canvas.draw_rect(Rect2(center.x - 42, center.y - 36, 84, 72), primary, false, 3.0)
	# Chamfered blast corners
	canvas.draw_line(Vector2(center.x - 42, center.y - 30), Vector2(center.x - 36, center.y - 36), primary, 3.0)
	canvas.draw_line(Vector2(center.x + 36, center.y - 36), Vector2(center.x + 42, center.y - 30), primary, 3.0)
	canvas.draw_line(Vector2(center.x - 42, center.y + 30), Vector2(center.x - 36, center.y + 36), primary, 3.0)
	canvas.draw_line(Vector2(center.x + 36, center.y + 36), Vector2(center.x + 42, center.y + 30), primary, 3.0)
	
	# Perimeter Sandbag Revetments
	for sy in [-26, 22]:
		canvas.draw_rect(Rect2(center.x - 40, center.y + sy, 14, 5), Color("#8a7146"))
		canvas.draw_rect(Rect2(center.x - 39, center.y + sy + 1, 12, 3), Color("#a88b56"))
	
	# 3. Dual Heavy Crude Oil Storage Silos
	for so_y in [-14, 14]:
		var silo_center = Vector2(center.x - 22, center.y + so_y)
		# Shadow
		canvas.draw_circle(silo_center + Vector2(2, 2), 13.0, Color(0, 0, 0, 0.35))
		# Outer cylindrical iron tank
		canvas.draw_circle(silo_center, 12.5, Color("#181715"))
		canvas.draw_circle(silo_center, 11.0, Color("#27272a"))
		# Rivet structural bands
		canvas.draw_arc(silo_center, 11.0, 0, TAU, 16, Color("#d49a35"), 2.0)
		canvas.draw_circle(silo_center, 4.0, Color("#3f3f46")) # Domed center vent
		# NFPA Hazard diamond decal (red / yellow)
		canvas.draw_rect(Rect2(silo_center.x - 3, silo_center.y - 3, 6, 6), Color("#dc2626"))
		canvas.draw_rect(Rect2(silo_center.x - 2, silo_center.y - 2, 4, 4), Color("#f59e0b"))
		
	# Connecting industrial pipelines to central refinery
	canvas.draw_rect(Rect2(center.x - 12, center.y - 16, 14, 4), Color("#181816"))
	canvas.draw_rect(Rect2(center.x - 12, center.y + 12, 14, 4), Color("#181816"))
	canvas.draw_rect(Rect2(center.x - 11, center.y - 15, 12, 2), Color("#71717a"))
	canvas.draw_rect(Rect2(center.x - 11, center.y + 13, 12, 2), Color("#71717a"))
	
	# 4. Central Command Citadel & Armored Penthouse
	canvas.draw_rect(Rect2(center.x - 2, center.y - 26, 38, 52), primary)
	canvas.draw_rect(Rect2(center.x + 2, center.y - 22, 30, 44), Color("#1c1d19"))
	# Armored command vision slits
	canvas.draw_rect(Rect2(center.x + 6, center.y - 18, 22, 3), Color("#38bdf8"))
	canvas.draw_rect(Rect2(center.x + 6, center.y + 15, 22, 3), Color("#38bdf8"))
	
	# Armored Vehicle Bay / Blast Gate with Hazard Chevrons
	canvas.draw_rect(Rect2(center.x + 8, center.y - 10, 18, 20), Color("#18181b"))
	for ch_y in [-8, -2, 4]:
		canvas.draw_line(Vector2(center.x + 10, center.y + ch_y), Vector2(center.x + 16, center.y + ch_y + 4), Color("#f59e0b"), 2.0)
		canvas.draw_line(Vector2(center.x + 18, center.y + ch_y), Vector2(center.x + 24, center.y + ch_y + 4), Color("#f59e0b"), 2.0)
		
	# 5. Rotating Radar Dish & Transmission Mast
	hq["radarAngle"] += 0.038
	var dish_center = Vector2(center.x + 17, center.y)
	# Mast foundation
	canvas.draw_circle(dish_center, 4.0, Color("#3f3f46"))
	var dish_vec = Vector2(cos(hq["radarAngle"]), sin(hq["radarAngle"])) * 15.0
	var normal = Vector2(-dish_vec.y, dish_vec.x).normalized() * 6.0
	# Radar dish curved reflector
	canvas.draw_line(dish_center + dish_vec - normal, dish_center + dish_vec + normal, primary_light, 2.5)
	# Feed horn
	canvas.draw_line(dish_center, dish_center + dish_vec * 0.7, Color("#e4e4e7"), 1.8)
	
	# Blinking red aviation warning beacon on the mast
	var beacon_alpha = 0.35 + sin(Time.get_ticks_msec() * 0.008) * 0.65
	canvas.draw_circle(dish_center, 2.5, Color(1.0, 0.2, 0.2, beacon_alpha))
	
	# 6. HQ Health Bar
	var pct = max(0.0, hq["hp"] / hq["maxHp"])
	canvas.draw_rect(Rect2(center.x - 38, center.y - 48, 76, 8), Color(0.08, 0.08, 0.07, 0.9))
	canvas.draw_rect(Rect2(center.x - 37, center.y - 47, round(74.0 * pct), 6), primary)
	canvas.draw_rect(Rect2(center.x - 37, center.y - 47, round(74.0 * pct), 2), Color(1, 1, 1, 0.25))

# ------------------------------------------------------------------------------
# Modular Base Building Rendering (Scaffold, Factories, Silos, Defenses)
# ------------------------------------------------------------------------------

static func draw_structure(canvas: CanvasItem, default_font: Font, s: Dictionary, pal: Dictionary, sim_time: float) -> void:
	var pos = Vector2(round(s["x"]), round(s["y"]))
	var w: float = s["width"]
	var h: float = s["height"]
	var is_player = s["faction"] == "player"
	var fac_col = Color("#589e47") if is_player else Color("#c9453e")
	var fac_light = Color("#78d464") if is_player else Color("#ef5350")
	var flash = s.get("hitFlash", 0.0) > 0.0
	
	# 1. Ground Drop Shadow
	canvas.draw_rect(Rect2(pos.x - w * 0.5 + 4, pos.y - h * 0.5 + 5, w, h), Color(0, 0, 0, 0.38))

	# 2. Construction Scaffolding Phase
	if s["status"] == "constructing":
		# Concrete slab
		var slab_col = Color("#2e2f2a")
		canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), slab_col)
		canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), Color("#55594e"), false, 1.5)
		
		# Steel rebar grid
		for gx in range(int(pos.x - w * 0.45), int(pos.x + w * 0.45), 10):
			canvas.draw_line(Vector2(gx, pos.y - h * 0.4), Vector2(gx, pos.y + h * 0.4), Color("#47463f"), 1.0)
		for gy in range(int(pos.y - h * 0.4), int(pos.y + h * 0.4), 10):
			canvas.draw_line(Vector2(pos.x - w * 0.4, gy), Vector2(pos.x + w * 0.4, gy), Color("#47463f"), 1.0)
			
		# Yellow crane arm & scaffold struts
		var crane_ang = sin(sim_time * 2.5) * 0.35
		var c_arm = Vector2(cos(crane_ang), sin(crane_ang)) * (w * 0.4)
		canvas.draw_line(pos, pos + c_arm, Color("#eab308"), 2.5)
		canvas.draw_circle(pos, 3.5, Color("#ca8a04"))
		
		# Construction progress bar
		var bar_w = w * 0.85
		var prog: float = s["build_progress"]
		canvas.draw_rect(Rect2(pos.x - bar_w * 0.5, pos.y - h * 0.5 - 12, bar_w, 5), Color(0.08, 0.08, 0.08, 0.9))
		canvas.draw_rect(Rect2(pos.x - bar_w * 0.5 + 1, pos.y - h * 0.5 - 11, (bar_w - 2) * prog, 3), Color("#eab308"))
		return

	# 3. Operational Structure Visuals
	var base_col = Color.WHITE if flash else Color("#22231e")
	
	if s["kind"] == "war_factory":
		# Heavy armored factory building
		canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), base_col)
		canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), fac_col, false, 2.5)
		
		# Corrugated steel roof & skylight panels
		canvas.draw_rect(Rect2(pos.x - w * 0.42, pos.y - h * 0.42, w * 0.84, h * 0.4), Color("#32352d"))
		canvas.draw_rect(Rect2(pos.x - w * 0.35, pos.y - h * 0.35, w * 0.7, 4), Color("#38bdf8"))
		
		# Vehicle Rollout Bay with Hazard Chevrons
		var door_w = w * 0.55
		var door_h = h * 0.38
		var d_x = pos.x - door_w * 0.5
		var d_y = pos.y + h * 0.08
		canvas.draw_rect(Rect2(d_x, d_y, door_w, door_h), Color("#131315"))
		for cx in range(int(d_x + 4), int(d_x + door_w - 4), 10):
			canvas.draw_line(Vector2(cx, d_y + door_h), Vector2(cx + 6, d_y), Color("#f59e0b"), 2.0)
			
		# Smokestack exhaust
		canvas.draw_circle(Vector2(pos.x - w * 0.35, pos.y - h * 0.3), 5.0, Color("#181816"))
		canvas.draw_circle(Vector2(pos.x - w * 0.35, pos.y - h * 0.3), 3.5, Color("#3f3f46"))

	elif s["kind"] == "repair_depot":
		# Octagonal repair platform pad
		canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), base_col)
		canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), Color("#38bdf8"), false, 2.0)
		
		# Turntable ring & hydraulic repair arm
		canvas.draw_circle(pos, w * 0.32, Color("#2b3127"))
		canvas.draw_arc(pos, w * 0.32, 0, TAU, 24, Color("#f59e0b"), 2.0)
		
		# Animated welding arm
		var arm_rot = sin(sim_time * 3.5) * 0.6
		var arm_end = pos + Vector2(cos(arm_rot), sin(arm_rot)) * (w * 0.28)
		canvas.draw_line(pos, arm_end, Color("#e4e4e7"), 2.5)
		# Blue electrical repair arc flash
		var arc_flicker = 0.5 + sin(sim_time * 24.0) * 0.5
		canvas.draw_circle(arm_end, 3.5, Color(0.25, 0.75, 1.0, arc_flicker))

	elif s["kind"] == "refinery_silo":
		# Domed heavy fuel storage tank
		canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), base_col)
		canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), Color("#eab308"), false, 2.0)
		
		# Metal sphere tank
		canvas.draw_circle(pos, w * 0.36, Color("#181715"))
		canvas.draw_circle(pos, w * 0.32, Color("#2b2a26"))
		canvas.draw_arc(pos, w * 0.32, 0, TAU, 24, Color("#f59e0b"), 2.5)
		
		# NFPA diamond & pressure valve
		canvas.draw_rect(Rect2(pos.x - 4, pos.y - 4, 8, 8), Color("#dc2626"))
		canvas.draw_rect(Rect2(pos.x - 2, pos.y - 2, 4, 4), Color("#facc15"))

	elif s["kind"] == "turret":
		# Circular bunker with rotating twin gun
		canvas.draw_circle(pos, w * 0.46, base_col)
		canvas.draw_circle(pos, w * 0.46, fac_col, false, 2.0)
		canvas.draw_circle(pos, w * 0.30, Color("#181816"))
		
		var t_angle: float = s.get("turretAngle", 0.0)
		var fwd = Vector2(cos(t_angle), sin(t_angle))
		var nrm = Vector2(-fwd.y, fwd.x)
		# Twin 12.7mm gun barrels
		canvas.draw_line(pos + nrm * 3.0, pos + nrm * 3.0 + fwd * 18.0, Color("#e4e4e7"), 2.5)
		canvas.draw_line(pos - nrm * 3.0, pos - nrm * 3.0 + fwd * 18.0, Color("#e4e4e7"), 2.5)

	elif s["kind"] == "missile_battery":
		# Hexagonal launch bunker with quad rocket pod
		canvas.draw_rect(Rect2(pos.x - w * 0.46, pos.y - h * 0.46, w * 0.92, h * 0.92), base_col)
		canvas.draw_rect(Rect2(pos.x - w * 0.46, pos.y - h * 0.46, w * 0.92, h * 0.92), Color("#ef4444"), false, 2.0)
		
		var t_angle: float = s.get("turretAngle", 0.0)
		var fwd = Vector2(cos(t_angle), sin(t_angle))
		var nrm = Vector2(-fwd.y, fwd.x)
		
		# Rocket launch pod
		var pod_center = pos + fwd * 4.0
		canvas.draw_circle(pod_center, 9.0, Color("#181816"))
		# 4 Red missile warheads
		for ox in [-4, 4]:
			for oy in [-4, 4]:
				var mp = pod_center + fwd * 8.0 + nrm * ox
				canvas.draw_circle(mp, 2.0, Color("#ef4444"))

	elif s["kind"] == "sandbag_wall":
		# Stacked canvas sandbags and concrete teeth
		canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), Color("#8a7146"))
		for bx in range(int(pos.x - w * 0.45), int(pos.x + w * 0.45), 12):
			canvas.draw_rect(Rect2(bx, pos.y - h * 0.35, 10, h * 0.7), Color("#a88b56"))
			canvas.draw_line(Vector2(bx, pos.y), Vector2(bx + 10, pos.y), Color("#715832"), 1.0)
		canvas.draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.5, w, h), Color("#544327"), false, 1.5)

	# Health Bar if damaged
	if s["hp"] < s["maxHp"]:
		var hp_pct = max(0.0, s["hp"] / s["maxHp"])
		var bar_w = w * 0.8
		canvas.draw_rect(Rect2(pos.x - bar_w * 0.5, pos.y - h * 0.5 - 8, bar_w, 4), Color(0.08, 0.08, 0.08, 0.9))
		canvas.draw_rect(Rect2(pos.x - bar_w * 0.5 + 1, pos.y - h * 0.5 - 7, (bar_w - 2) * hp_pct, 2), fac_col)

