class_name WarFrontRenderer2D
extends Node2D

const Constants = preload("res://scripts/constants.gd")
const Simulation = preload("res://scripts/simulation.gd")
const RenderTerrain = preload("res://scripts/render_terrain.gd")
const RenderWater = preload("res://scripts/render_water.gd")
const RenderAtmosphere = preload("res://scripts/render_atmosphere.gd")
const RenderEnvironment = preload("res://scripts/render_environment.gd")
const RenderFogOfWar = preload("res://scripts/render_fog_of_war.gd")
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
	terrain_texture = RenderTerrain.build_terrain_texture(sim.map)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if sim == null or sim.map.is_empty():
		return
		
	var map = sim.map
	var pal = Constants.THEATER_PALETTES.get(map.get("theater", "kirkuk"), Constants.THEATER_PALETTES["kirkuk"])

	# Viewport Frustum Culling Box for 60 FPS performance
	var vp = get_viewport()
	var cam = vp.get_camera_2d() if vp != null else null
	var view_rect: Rect2
	if cam != null:
		var cam_pos = cam.get_screen_center_position()
		var zoom_val = cam.zoom if (cam.zoom.x > 0.001 and cam.zoom.y > 0.001) else Vector2.ONE
		var visible_size = vp.get_visible_rect().size / zoom_val
		var margin = Vector2(160.0, 160.0)
		view_rect = Rect2(cam_pos - (visible_size * 0.5) - margin, visible_size + (margin * 2.0))
	else:
		view_rect = Rect2(0.0, 0.0, map.get("width", 5000.0), map.get("height", 3000.0))
	
	# 1. Base Terrain Texture
	if terrain_texture != null:
		draw_texture(terrain_texture, Vector2.ZERO)

	# 1.2 Environmental Clutter: Natural Boulders & Desert Shrubs
	RenderEnvironment.draw_arid_vegetation_and_rocks(self, map, view_rect)

	# 1.4 Persistent Battlefield Scars: Tread Marks, Craters, Wrecks
	RenderFX.draw_tread_marks(self, sim.tread_marks)
	RenderFX.draw_craters(self, sim.craters)
	RenderFX.draw_wrecks(self, sim.wrecks)
		
	# 2. Water Dynamics 2.0: Vector River Currents, Caustic Glints, and Shoreline Foams
	RenderWater.draw_water_dynamics(self, map, pal, sim.sim_time, view_rect)
	RenderWater.draw_pier_wakes(self, map, pal, sim.sim_time, view_rect)
	
	# 2.5 Industrial Infrastructure: Crude Pipelines & High-Voltage Pylons
	RenderEnvironment.draw_pipeline_conduits(self, map, view_rect)
	RenderEnvironment.draw_power_pylons(self, map, sim.sim_time, view_rect)
	
	# 3. Burning Wellheads
	for well in map.get("burningWells", []):
		if view_rect.has_point(well):
			RenderStructures.draw_burning_well(self, well, sim.sim_time)
		
	# 4. Directional Cast Shadows: Grounding Structures & Units in 3D Depth
	RenderAtmosphere.draw_directional_structure_shadows(self, sim.structures, view_rect)
	RenderAtmosphere.draw_directional_unit_shadows(self, sim.units, view_rect)

	# 5. Bridges
	for b in map.get("bridges", []):
		if view_rect.has_point(Vector2(b["x"], b["y"])):
			RenderStructures.draw_bridge(self, default_font, b, pal)
		
	# 6. Oil Rigs
	for rig in map.get("rigs", []):
		if view_rect.has_point(Vector2(rig["x"], rig["y"])):
			RenderStructures.draw_oil_rig(self, rig)
		
	# 7. Command HQs
	var hqs_list = map.get("hqs", [])
	if hqs_list.size() > 0:
		for hq in hqs_list:
			if view_rect.has_point(Vector2(hq["x"], hq["y"])):
				RenderStructures.draw_hq(self, hq)
	else:
		if map.has("playerHQ") and view_rect.has_point(Vector2(map["playerHQ"]["x"], map["playerHQ"]["y"])):
			RenderStructures.draw_hq(self, map["playerHQ"])
		if map.has("enemyHQ") and view_rect.has_point(Vector2(map["enemyHQ"]["x"], map["enemyHQ"]["y"])):
			RenderStructures.draw_hq(self, map["enemyHQ"])

	# 8. Base Structures
	for s in sim.structures:
		if view_rect.has_point(Vector2(s["x"], s["y"])):
			RenderStructures.draw_structure(self, default_font, s, pal, sim.sim_time)
	
	# 9. Rally Point Beacon
	if sim.player_rally_point != Vector2.ZERO:
		RenderStructures.draw_rally_beacon(self, default_font, sim.player_rally_point, sim.sim_time)
	
	# 10. Tactical Recon Drone Radar Sweeps
	RenderFX.draw_recon_sweeps(self, sim.active_recon_sweeps, sim.sim_time)

	# 11. Ground Salvage Crates
	RenderFX.draw_salvage_crates(self, sim.salvage_crates, sim.sim_time)

	# 12. Napalm Patches & Anti-Tank Landmines
	RenderFX.draw_napalm_patches(self, sim.napalm_patches, sim.sim_time)
	RenderFX.draw_landmines(self, sim.landmines, sim.sim_time)

	# 13. Airborne Airdrops & Cargo Shadows
	RenderFX.draw_airdrop_crates(self, sim.airdrop_crates, sim.sim_time)
	RenderFX.draw_cargo_shadows(self, sim.cargo_shadows)

	# 14. Order Marker Pulse & Artillery Designation Rings
	RenderFX.draw_order_pulse(self, sim.order_pulse)
	RenderFX.draw_artillery_barrages(self, sim.active_barrages, sim.sim_time)

	# 15. Tactical Waypoint Trajectories
	RenderFX.draw_tactical_waypoints(self, sim.units, sim.sim_time)

	# 16. Units
	for u in sim.units:
		if u.get("alive", false) and view_rect.has_point(Vector2(u["x"], u["y"])):
			RenderUnits.draw_unit(self, default_font, u, sim.sim_time)
			
	# 17. Projectiles
	for pr in sim.projectiles:
		if view_rect.has_point(Vector2(pr["x"], pr["y"])):
			RenderFX.draw_projectile(self, pr)
		
	# 18. Particle Systems
	RenderFX.draw_particles(self, sim.particles)

	# 19. Flying Turrets Physics & Airstrike Jet Flybys
	RenderFX.draw_flying_turrets(self, sim.flying_turrets)
	RenderFX.draw_commander_airstrikes(self, sim.active_airstrikes)
			
	# 20. Floating Popups & Drag Selection Box
	RenderFX.draw_floating_popups(self, default_font, sim.floating_popups)
	RenderFX.draw_selection_box(self, selection_box, is_dragging_selection)

	# 21. Ghost Placement Hologram
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

	# 22. Attack-Move Tactical Reticle
	if sim.attack_move_mode:
		var m_pos = get_global_mouse_position()
		RenderFX.draw_attack_move_reticle(self, m_pos, sim.sim_time)

	# 23. Atmospheric Lighting & Drifting Dust Motes
	RenderAtmosphere.draw_theater_atmosphere(self, map.get("theater", "kirkuk"), sim.sim_time, view_rect)

	# 24. Tactical Fog of War & Reconnaissance Shroud
	RenderFogOfWar.draw_fog_of_war(self, sim, view_rect)

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
