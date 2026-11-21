class_name WarFrontRenderer2D
extends Node2D

const Constants = preload("res://scripts/constants.gd")
const Simulation = preload("res://scripts/simulation.gd")
const RenderStructures = preload("res://scripts/render_structures.gd")
const RenderUnits = preload("res://scripts/render_units.gd")
const RenderFX = preload("res://scripts/render_fx.gd")
const SimBuildings = preload("res://scripts/sim_buildings.gd")

var sim: Simulation = null
var terrain_texture: ImageTexture = null
var selection_box: Rect2 = Rect2()
var is_dragging_selection: bool = false
var hover_world_pos: Vector2 = Vector2.ZERO

var default_font: Font = null

func _ready() -> void:
	default_font = ThemeDB.fallback_font

func init_with_simulation(simulation: Simulation) -> void:
	sim = simulation
	build_terrain_texture()

func build_terrain_texture() -> void:
	if sim == null or sim.map.is_empty():
		return
		
	var map = sim.map
	var pal = Constants.THEATER_PALETTES.get(map["theater"], Constants.THEATER_PALETTES["kirkuk"])
	var img = Image.create(int(map["width"]), int(map["height"]), false, Image.FORMAT_RGBA8)
	var ts = Constants.TILE_SIZE
	
	img.fill(pal["groundB"])
	
	var hash_func = func(x: int, y: int) -> float:
		var n = sin(float(x) * 127.1 + float(y) * 311.7 + float(map["seed"]) * 0.13) * 43758.5453
		return n - floor(n)
		
	for r in range(map["rows"]):
		for c in range(map["cols"]):
			var tile = map["tiles"][r * map["cols"] + c]
			var x = c * ts
			var y = r * ts
			var h = hash_func.call(c, r)
			
			if tile == "water" or tile == "bridge":
				var w_col = pal["waterDeep"] if h > 0.5 else pal["waterShallow"]
				img.fill_rect(Rect2i(x, y, ts, ts), w_col)
				var left_tile = map["tiles"][r * map["cols"] + (c - 1)] if c > 0 else "water"
				var right_tile = map["tiles"][r * map["cols"] + (c + 1)] if c < map["cols"] - 1 else "water"
				if left_tile != "water" and left_tile != "bridge":
					img.fill_rect(Rect2i(x, y, 6, ts), pal["groundDetail"])
					img.fill_rect(Rect2i(x + 6, y, 3, ts), pal["waterFoam"])
				if right_tile != "water" and right_tile != "bridge":
					img.fill_rect(Rect2i(x + ts - 6, y, 6, ts), pal["groundDetail"])
					img.fill_rect(Rect2i(x + ts - 9, y, 3, ts), pal["waterFoam"])
			elif tile == "road":
				# Directional Road Autotiling (4-neighbor connectivity)
				var is_road_conn = func(tc: int, tr: int) -> bool:
					if tc < 0 or tc >= map["cols"] or tr < 0 or tr >= map["rows"]:
						return false
					var nt = map["tiles"][tr * map["cols"] + tc]
					return nt == "road" or nt == "bridge" or nt == "concrete"

				var n_up = is_road_conn.call(c, r - 1)
				var n_down = is_road_conn.call(c, r + 1)
				var n_left = is_road_conn.call(c - 1, r)
				var n_right = is_road_conn.call(c + 1, r)

				# 1. Compacted gravel shoulder / road foundation
				img.fill_rect(Rect2i(x, y, ts, ts), pal["roadEdge"])

				# 2. Main asphalt deck
				var m = 4 # curb margin
				# Fill central asphalt intersection box
				img.fill_rect(Rect2i(x + m, y + m, ts - m * 2, ts - m * 2), pal["roadAsphalt"])
				# Extend asphalt into connected neighbors
				if n_left:
					img.fill_rect(Rect2i(x, y + m, m, ts - m * 2), pal["roadAsphalt"])
				if n_right:
					img.fill_rect(Rect2i(x + ts - m, y + m, m, ts - m * 2), pal["roadAsphalt"])
				if n_up:
					img.fill_rect(Rect2i(x + m, y, ts - m * 2, m), pal["roadAsphalt"])
				if n_down:
					img.fill_rect(Rect2i(x + m, y + ts - m, ts - m * 2, m), pal["roadAsphalt"])

				# 3. Heavy vehicle tire wear grooves (weathering)
				var tire_col = Color(0.06, 0.06, 0.05, 0.28)
				if (n_left or n_right) and not (n_up or n_down):
					# Horizontal dual tire tracks
					img.fill_rect(Rect2i(x, y + 9, ts, 3), tire_col)
					img.fill_rect(Rect2i(x, y + ts - 12, ts, 3), tire_col)
				elif (n_up or n_down) and not (n_left or n_right):
					# Vertical dual tire tracks
					img.fill_rect(Rect2i(x + 9, y, 3, ts), tire_col)
					img.fill_rect(Rect2i(x + ts - 12, y, 3, ts), tire_col)

				# 4. White edge guide lines (fog lines) along unconnected road boundaries
				var white_edge = Color(1.0, 1.0, 1.0, 0.42)
				if not n_up:
					img.fill_rect(Rect2i(x + (0 if n_left else m), y + m, ts - (0 if n_left else m) - (0 if n_right else m), 1), white_edge)
				if not n_down:
					img.fill_rect(Rect2i(x + (0 if n_left else m), y + ts - m - 1, ts - (0 if n_left else m) - (0 if n_right else m), 1), white_edge)
				if not n_left:
					img.fill_rect(Rect2i(x + m, y + (0 if n_up else m), 1, ts - (0 if n_up else m) - (0 if n_down else m)), white_edge)
				if not n_right:
					img.fill_rect(Rect2i(x + ts - m - 1, y + (0 if n_up else m), 1, ts - (0 if n_up else m) - (0 if n_down else m)), white_edge)

				# 5. Yellow road markings (Direction-aware)
				var stripe_col = pal["roadStripe"]
				var mid = int(ts / 2)
				var conn_count = (1 if n_up else 0) + (1 if n_down else 0) + (1 if n_left else 0) + (1 if n_right else 0)

				if conn_count <= 2 and (n_left or n_right) and not (n_up or n_down):
					# Straight horizontal road dashes
					img.fill_rect(Rect2i(x + 6, y + mid - 1, 11, 2), stripe_col)
					img.fill_rect(Rect2i(x + 27, y + mid - 1, 11, 2), stripe_col)
				elif conn_count <= 2 and (n_up or n_down) and not (n_left or n_right):
					# Straight vertical road dashes
					img.fill_rect(Rect2i(x + mid - 1, y + 6, 2, 11), stripe_col)
					img.fill_rect(Rect2i(x + mid - 1, y + 27, 2, 11), stripe_col)
				elif conn_count == 2 and not ((n_left and n_right) or (n_up and n_down)):
					# L-Corner Turn: smooth diagonal/curved dashed stripe
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
					# 3-Way T-Junction or 4-Way Cross Intersection
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
					# Fallback horizontal dashes
					img.fill_rect(Rect2i(x + 10, y + mid - 1, 10, 2), stripe_col)
					img.fill_rect(Rect2i(x + 28, y + mid - 1, 10, 2), stripe_col)
			elif tile == "concrete":
				# Pre-cast Heavy Military Concrete Engineering Slabs
				img.fill_rect(Rect2i(x, y, ts, ts), pal["concrete"])
				var half = int(ts / 2)
				var joint_col = Color(0.10, 0.10, 0.08, 0.55)
				var bevel_light = Color(1.0, 1.0, 1.0, 0.16)
				var bevel_shadow = Color(0.06, 0.06, 0.05, 0.22)
				var bolt_col = Color(0.18, 0.18, 0.16, 0.8)

				# 4 Sub-slabs (2x2 grid per tile)
				var sub_rects = [
					Rect2i(x, y, half, half),
					Rect2i(x + half, y, half, half),
					Rect2i(x, y + half, half, half),
					Rect2i(x + half, y + half, half, half)
				]
				for sr in sub_rects:
					# Bevel highlight along top and left edge of each slab
					img.fill_rect(Rect2i(sr.position.x + 1, sr.position.y + 1, sr.size.x - 2, 1), bevel_light)
					img.fill_rect(Rect2i(sr.position.x + 1, sr.position.y + 1, 1, sr.size.y - 2), bevel_light)
					# Bevel shadow along bottom and right edge
					img.fill_rect(Rect2i(sr.position.x + 1, sr.position.y + sr.size.y - 2, sr.size.x - 2, 1), bevel_shadow)
					img.fill_rect(Rect2i(sr.position.x + sr.size.x - 2, sr.position.y + 1, 1, sr.size.y - 2), bevel_shadow)
					# Tie-down anchor sockets at slab corners
					img.fill_rect(Rect2i(sr.position.x + 3, sr.position.y + 3, 2, 2), bolt_col)
					img.fill_rect(Rect2i(sr.position.x + sr.size.x - 5, sr.position.y + 3, 2, 2), bolt_col)
					img.fill_rect(Rect2i(sr.position.x + 3, sr.position.y + sr.size.y - 5, 2, 2), bolt_col)
					img.fill_rect(Rect2i(sr.position.x + sr.size.x - 5, sr.position.y + sr.size.y - 5, 2, 2), bolt_col)

				# Tar-sealed expansion joints between slabs
				img.fill_rect(Rect2i(x, y, ts, 1), joint_col)
				img.fill_rect(Rect2i(x, y, 1, ts), joint_col)
				img.fill_rect(Rect2i(x, y + half, ts, 1), joint_col)
				img.fill_rect(Rect2i(x + half, y, 1, ts), joint_col)
			elif tile == "oilfield":
				# Oilfield industrial pad: crushed gravel with dark crude tar seepages
				img.fill_rect(Rect2i(x, y, ts, ts), pal["oilfield"])
				img.fill_rect(Rect2i(x + 5 + int(h * 12.0), y + 6 + int(h * 10.0), 16, 12), Color("#151310"))
				img.fill_rect(Rect2i(x + 7 + int(h * 12.0), y + 8 + int(h * 10.0), 12, 8), Color("#0b0a08"))
				img.fill_rect(Rect2i(x + 8 + int(h * 12.0), y + 9 + int(h * 10.0), 4, 2), Color(0.25, 0.28, 0.32, 0.45))
				img.fill_rect(Rect2i(x + 3, y + 3, ts - 6, 2), Color(0.48, 0.42, 0.32, 0.35))
				img.fill_rect(Rect2i(x + 3, y + ts - 5, ts - 6, 2), Color(0.18, 0.16, 0.12, 0.4))
			elif tile == "rock" or tile == "cliff":
				# Mesa formation: dark rock shadow foundation
				img.fill_rect(Rect2i(x, y, ts, ts), pal.get("rockShadow", Color("#302417")))
				# Sedimentary rock strata face
				img.fill_rect(Rect2i(x + 2, y + 2, ts - 4, ts - 5), pal.get("rockFace", Color("#523f2a")))
				# Sunlit top rim
				img.fill_rect(Rect2i(x + 2, y + 2, ts - 4, 6), pal.get("rockTop", Color("#b49667")))
				# Horizontal strata cracks
				img.fill_rect(Rect2i(x + 4, y + 16, ts - 8, 2), Color(0.12, 0.08, 0.05, 0.65))
				img.fill_rect(Rect2i(x + 8, y + 28, ts - 14, 2), Color(0.12, 0.08, 0.05, 0.65))
			elif tile == "ford":
				# Shallow rocky water crossing
				img.fill_rect(Rect2i(x, y, ts, ts), pal.get("ford", Color("#326177")))
				# Sand/gravel silt streaks
				img.fill_rect(Rect2i(x + 4, y + 8, ts - 8, 4), pal["groundDetail"])
				img.fill_rect(Rect2i(x + 8, y + 24, ts - 16, 4), pal["groundDetail"])
				# Exposed boulders
				img.fill_rect(Rect2i(x + 12, y + 14, 8, 6), pal.get("rockFace", Color("#523f2a")))
				img.fill_rect(Rect2i(x + 28, y + 30, 6, 5), pal.get("rockFace", Color("#523f2a")))
				# Water ripples around rocks
				img.fill_rect(Rect2i(x + 10, y + 13, 12, 2), pal["waterFoam"])
				img.fill_rect(Rect2i(x + 26, y + 29, 10, 2), pal["waterFoam"])
			else:
				# Organic pixel-art terrain shading (matches renderer.ts lines 110-135)
				var blob = sin(float(c) * 0.42 + float(map["seed"]) * 0.01) * cos(float(r) * 0.37) + (h - 0.5) * 0.65
				var g_col = pal["groundA"] if blob > 0.15 else pal["groundB"]
				img.fill_rect(Rect2i(x, y, ts, ts), g_col)
				
				if h > 0.55:
					img.fill_rect(Rect2i(x + int(h * 28.0), y + int(fmod(h * 19.0, 1.0) * 32.0), 8, 4), pal["groundDetail"])
					img.fill_rect(Rect2i(x + int(fmod(h * 11.0, 1.0) * 34.0), y + int(h * 24.0), 4, 4), pal["groundDetail"])
				if h < 0.22:
					img.fill_rect(Rect2i(x + 8 + int(h * 40.0), y + 16, 14, 3), Color(1.0, 0.94, 0.78, 0.12))
					img.fill_rect(Rect2i(x + 12 + int(h * 30.0), y + 20, 8, 2), Color(1.0, 0.94, 0.78, 0.12))
				if h > 0.86:
					img.fill_rect(Rect2i(x + 18, y + 18, 6, 6), Color("#3d3a2c"))
					img.fill_rect(Rect2i(x + 18, y + 16, 4, 3), Color("#5c5840"))

	# Sector gridlines every 4 tiles
	for gx in range(0, int(map["width"]), ts * 4):
		for gy in range(int(map["height"])):
			img.set_pixel(gx, gy, Color(0.06, 0.06, 0.05, 0.06))
	for gy in range(0, int(map["height"]), ts * 4):
		for gx in range(int(map["width"])):
			img.set_pixel(gx, gy, Color(0.06, 0.06, 0.05, 0.06))

	terrain_texture = ImageTexture.create_from_image(img)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if sim == null or sim.map.is_empty():
		return
		
	var map = sim.map
	var pal = Constants.THEATER_PALETTES.get(map["theater"], Constants.THEATER_PALETTES["kirkuk"])
	
	# 1. Render Terrain
	if terrain_texture != null:
		draw_texture(terrain_texture, Vector2.ZERO)

	# 1.5 Tread Skid Marks on Desert Sand
	RenderFX.draw_tread_marks(self, sim.tread_marks)

	# 1.6 Battle Craters & Crude Oil Slicks
	RenderFX.draw_craters(self, sim.craters)

	# 1.7 Persistent Smoking Battlefield Wrecks
	RenderFX.draw_wrecks(self, sim.wrecks)
		
	# 2. Water ripples
	RenderStructures.draw_water_ripples(self, map, pal["waterFoam"], sim.sim_time)
	
	# 3. Burning wellheads
	for well in map["burningWells"]:
		RenderStructures.draw_burning_well(self, well, sim.sim_time)
		
	# 4. Bridges
	for b in map["bridges"]:
		RenderStructures.draw_bridge(self, default_font, b, pal)
		
	# 5. Oil rigs
	for rig in map["rigs"]:
		RenderStructures.draw_oil_rig(self, rig)
		
	# 6. Command HQs
	RenderStructures.draw_hq(self, map["playerHQ"])
	RenderStructures.draw_hq(self, map["enemyHQ"])

	# 6.2 Base Structures (War Factories, Repair Depots, Refineries, Turrets, Walls)
	for s in sim.structures:
		RenderStructures.draw_structure(self, default_font, s, pal, sim.sim_time)
	
	# 6.5 Tactical Recon Drone Radar Sweeps
	RenderFX.draw_recon_sweeps(self, sim.active_recon_sweeps, sim.sim_time)

	# 6.6 Crude Oil Salvage Barrels (Interactive Ground Loot)
	RenderFX.draw_salvage_crates(self, sim.salvage_crates, sim.sim_time)

	# 7. Order marker pulse
	RenderFX.draw_order_pulse(self, sim.order_pulse)

	# 7.2 Off-Map Artillery Target Designation Flares & Danger Rings
	RenderFX.draw_artillery_barrages(self, sim.active_barrages, sim.sim_time)

	# 7.5 Tactical Waypoint Vectors (Selected Unit Trajectory Lines)
	RenderFX.draw_tactical_waypoints(self, sim.units, sim.sim_time)

	# 8. Units
	for u in sim.units:
		if u["alive"]:
			RenderUnits.draw_unit(self, default_font, u, sim.sim_time)
			
	# 9. Projectiles
	for pr in sim.projectiles:
		RenderFX.draw_projectile(self, pr)
		
	# 10. Particles (Smoke column, fire, shockwaves, sparks, debris)
	RenderFX.draw_particles(self, sim.particles)

	# 10.5 High-Altitude Supersonic Airstrike Jet Flybys & Shadows
	RenderFX.draw_commander_airstrikes(self, sim.active_airstrikes)
			
	# 11. Floating Popups with drop shadow
	RenderFX.draw_floating_popups(self, default_font, sim.floating_popups)
		
	# 12. Drag Selection Box
	RenderFX.draw_selection_box(self, selection_box, is_dragging_selection)

	# 13. Ghost Placement Hologram (Real-Time Base Construction Blueprint Preview)
	if sim.build_mode != "none" and Constants.BUILDING_SPECS.has(sim.build_mode):
		var b_spec = Constants.BUILDING_SPECS[sim.build_mode]
		var m_pos = get_global_mouse_position()
		var valid = SimBuildings.can_place_structure(sim, sim.build_mode, m_pos.x, m_pos.y, "player")
		var holo_col = Color(0.25, 0.95, 0.35, 0.38) if valid else Color(0.95, 0.25, 0.25, 0.38)
		var border_col = Color(0.35, 1.0, 0.45, 0.85) if valid else Color(1.0, 0.3, 0.3, 0.85)
		
		var hw: float = b_spec["width"]
		var hh: float = b_spec["height"]
		draw_rect(Rect2(m_pos.x - hw * 0.5, m_pos.y - hh * 0.5, hw, hh), holo_col)
		draw_rect(Rect2(m_pos.x - hw * 0.5, m_pos.y - hh * 0.5, hw, hh), border_col, false, 2.0)
		draw_circle(m_pos, b_spec["radius"], Color(border_col.r, border_col.g, border_col.b, 0.12))

# Backward-compatible convenience delegates
func draw_craters() -> void:
	RenderFX.draw_craters(self, sim.craters)

func draw_bridge(b: Dictionary, pal: Dictionary) -> void:
	RenderStructures.draw_bridge(self, default_font, b, pal)

func draw_oil_rig(rig: Dictionary) -> void:
	RenderStructures.draw_oil_rig(self, rig)

func draw_hq(hq: Dictionary) -> void:
	RenderStructures.draw_hq(self, hq)

func draw_unit(u: Dictionary) -> void:
	RenderUnits.draw_unit(self, default_font, u, sim.sim_time)

func draw_projectile(pr: Dictionary) -> void:
	RenderFX.draw_projectile(self, pr)
