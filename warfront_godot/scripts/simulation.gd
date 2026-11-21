class_name Simulation
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const MapGen = preload("res://scripts/map_gen.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")
const SimCombat = preload("res://scripts/sim_combat.gd")
const SimLogistics = preload("res://scripts/sim_logistics.gd")
const SimAI = preload("res://scripts/sim_ai.gd")
const SimUnits = preload("res://scripts/sim_units.gd")
const SimCommander = preload("res://scripts/sim_commander.gd")
const SimBuildings = preload("res://scripts/sim_buildings.gd")

signal event_pushed(key: String, tone: String)
signal sound_triggered(sfx_name: String)

var theater: String = "kirkuk"
var seed_val: int = 104729
var phase: String = "playing" # "title", "playing", "gameover"
var outcome: String = "none" # "victory", "defeat", "none"

var player_oil: int = Constants.STARTING_PLAYER_OIL
var enemy_oil: int = Constants.STARTING_ENEMY_OIL
var player_oil_delivered: int = 0

var map: Dictionary = {}
var units: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var floating_popups: Array[Dictionary] = []
var craters: Array[Dictionary] = []
const MAX_CRATERS: int = 80
var wrecks: Array[Dictionary] = []
const MAX_WRECKS: int = 40

var structures: Array[Dictionary] = []
var commander_powers: Dictionary = {}
var enemy_commander_powers: Dictionary = {}
var salvage_crates: Array[Dictionary] = []
var active_airstrikes: Array[Dictionary] = []
var active_barrages: Array[Dictionary] = []
var active_recon_sweeps: Array[Dictionary] = []
var battle_phase: String = "recon" # "recon", "escalation", "total_war"
var active_directive: Dictionary = {}
var directive_cycle_timer: float = 3.0
var commander_targeting_power: String = ""

var next_unit_id: int = 1
var next_projectile_id: int = 1
var elapsed_seconds: float = 0.0
var sim_time: float = 0.0
var camera_trauma: float = 0.0
var hitstop_timer: float = 0.0

var bridges_destroyed_by_player: int = 0
var enemy_trucks_destroyed: int = 0
var build_mode: String = "none" # "none", "turret"
var attack_move_mode: bool = false
var order_pulse: Dictionary = {} # { x, y, color, timer }

var ai_decision_timer: float = 5.0
var ai_wave_count: int = 0
var smoke_emit_timer: float = 0.0
var tread_marks: Array[Dictionary] = []

const MAX_PARTICLES: int = 2048
var particle_cursor: int = 0

func _init(th: String = "kirkuk", sd: int = 104729) -> void:
	theater = th
	seed_val = sd
	
	particles.resize(MAX_PARTICLES)
	for i in range(MAX_PARTICLES):
		particles[i] = {
			"active": false,
			"kind": "smoke",
			"x": 0.0, "y": 0.0,
			"vx": 0.0, "vy": 0.0,
			"size": 4.0, "endSize": 12.0,
			"life": 0.0, "maxLife": 1.0,
			"color": Color("#222222"),
			"alpha": 1.0
		}
		
	reset(theater, seed_val)

func reset(th: String = theater, sd: int = seed_val, start_phase: String = "playing") -> void:
	theater = th
	seed_val = sd
	phase = start_phase
	outcome = "none"
	player_oil = Constants.STARTING_PLAYER_OIL
	enemy_oil = Constants.STARTING_ENEMY_OIL
	player_oil_delivered = 0
	units.clear()
	projectiles.clear()
	floating_popups.clear()
	tread_marks.clear()
	craters.clear()
	wrecks.clear()
	structures.clear()
	for p in particles:
		p["active"] = false
	particle_cursor = 0
	next_unit_id = 1
	next_projectile_id = 1
	elapsed_seconds = 0.0
	sim_time = 0.0
	camera_trauma = 0.0
	hitstop_timer = 0.0
	bridges_destroyed_by_player = 0
	enemy_trucks_destroyed = 0
	build_mode = "none"
	order_pulse = {}
	ai_decision_timer = 5.5
	ai_wave_count = 0
	SimCommander.init_commander_state(self)
	
	map = MapGen.generate_map(theater, seed_val)
	SimUnits.setup_initial_forces(self)

func step(dt: float) -> void:
	dt = min(dt, 0.05)
	sim_time += dt
	elapsed_seconds += dt
	
	if camera_trauma > 0.0:
		camera_trauma = max(0.0, camera_trauma - dt * 1.8)
		
	if not order_pulse.is_empty():
		order_pulse["timer"] -= dt
		if order_pulse["timer"] <= 0.0:
			order_pulse = {}
			
	# Update tread marks
	for i in range(tread_marks.size() - 1, -1, -1):
		var tm = tread_marks[i]
		tm["life"] -= dt
		if tm["life"] <= 0.0:
			tread_marks.remove_at(i)

	# Update battlefield wrecks
	for i in range(wrecks.size() - 1, -1, -1):
		var wrk = wrecks[i]
		wrk["life"] -= dt
		if wrk["life"] <= 0.0:
			wrecks.remove_at(i)

	# Update floating popups
	for i in range(floating_popups.size() - 1, -1, -1):
		var fp = floating_popups[i]
		fp["life"] -= dt
		fp["y"] -= dt * 26.0
		if fp["life"] <= 0.0:
			floating_popups.remove_at(i)
			
	# Update particles
	for p in particles:
		if not p["active"]:
			continue
		p["life"] -= dt
		if p["life"] <= 0.0:
			p["active"] = false
			continue
		p["x"] += p["vx"] * dt
		p["y"] += p["vy"] * dt
		p["alpha"] = p["life"] / p["maxLife"]

	# Hitstop micro-freeze on heavy kills & detonations
	if hitstop_timer > 0.0:
		hitstop_timer = max(0.0, hitstop_timer - dt)
		return

	# Smoke & fire emission for burning wells & destroyed bridges
	smoke_emit_timer -= dt
	if smoke_emit_timer <= 0.0:
		smoke_emit_timer = 0.14
		for well in map.get("burningWells", []):
			spawn_particle("fire", well.x + randf_range(-3.0, 3.0), well.y - 4.0, randf_range(-5.0, 5.0), -24.0 - randf() * 14.0, 5.0, 2.0, 0.45, Color("#ff8d29"))
			spawn_particle("smoke", well.x + randf_range(-4.0, 4.0), well.y - 10.0, 14.0 + randf() * 10.0, -26.0 - randf() * 12.0, 7.0, 22.0, 1.4, Color("#1b1a18"))
		for b in map.get("bridges", []):
			if b["status"] == "destroyed":
				spawn_particle("smoke", b["x"] + randf_range(-22.0, 22.0), b["y"] + randf_range(-7.0, 7.0), 8.0, -18.0, 6.0, 16.0, 1.0, Color("#2a2826"))
		for wrk in wrecks:
			if wrk["life"] > 4.0 and randf() < 0.4:
				spawn_particle("smoke", wrk["x"] + randf_range(-6.0, 6.0), wrk["y"] + randf_range(-4.0, 4.0), randf_range(-4.0, 4.0), -16.0 - randf() * 10.0, 4.0, 14.0, 0.85, Color("#22201d"))

	SimLogistics.update_oil_rigs(self, dt)
	SimUnits.update_units(self, dt)
	SimBuildings.update_structures(self, dt)
	SimCombat.update_projectiles(self, dt)
	SimCommander.update_commander(self, dt)
	
	if phase == "playing":
		SimAI.update_enemy_ai(self, dt)
		SimAI.check_win_loss(self)

func call_commander_power(power_id: String, target_world: Vector2, faction: String = "player") -> bool:
	return SimCommander.call_commander_power(self, power_id, target_world, faction)

func spawn_salvage(x: float, y: float, oil_amount: int) -> void:
	SimCommander.spawn_salvage(self, x, y, oil_amount)

func notify_directive(directive_type: String) -> void:
	SimCommander.notify_directive_progress(self, directive_type)

func spawn_unit(faction: String, kind: String, x: float, y: float) -> Dictionary:
	return SimUnits.spawn_unit(self, faction, kind, x, y)

func train_player_unit(kind: String) -> bool:
	return SimUnits.train_player_unit(self, kind)

func place_player_turret(x: float, y: float) -> bool:
	return SimUnits.place_player_turret(self, x, y)

func place_player_structure(kind: String, x: float, y: float) -> bool:
	return SimBuildings.place_structure(self, kind, x, y, "player")

func rebuild_bridge(bridge_id: String, faction: String = "player") -> bool:
	return SimUnits.rebuild_bridge(self, bridge_id, faction)

func reroute_stranded_trucks() -> void:
	SimLogistics.reroute_stranded_trucks(self)

func select_units_in_box(rect: Rect2, additive: bool = false) -> int:
	return SimUnits.select_units_in_box(self, rect, additive)

func issue_player_command(world_x: float, world_y: float, shift_queued: bool = false) -> bool:
	return SimUnits.issue_player_command(self, world_x, world_y, shift_queued)

func issue_player_attack_move(world_x: float, world_y: float, shift_queued: bool = false) -> bool:
	return SimUnits.issue_player_attack_move(self, world_x, world_y, shift_queued)

func stop_selected_units() -> void:
	SimUnits.stop_selected_units(self)

func set_selected_stance(stance: String) -> void:
	SimUnits.set_selected_stance(self, stance)

func retreat_selected_units() -> void:
	SimUnits.retreat_selected_units(self)

func award_unit_xp(unit: Dictionary, amount: float) -> bool:
	return SimCombat.award_unit_xp(self, unit, amount)

func detonate_projectile(p: Dictionary) -> void:
	SimCombat.detonate_projectile(self, p)

func damage_unit(u: Dictionary, amount: float, attacker: Variant = null) -> void:
	SimCombat.damage_unit(self, u, amount, attacker)

func damage_bridge(bridge: Dictionary, amount: float, attacker_faction: String, attacker_unit: Variant = null) -> void:
	SimCombat.damage_bridge(self, bridge, amount, attacker_faction, attacker_unit)

func push_event(key: String, tone: String) -> void:
	event_pushed.emit(key, tone)

func spawn_floating_text(x: float, y: float, text: String, col: Color, life: float = 0.85) -> void:
	if floating_popups.size() > 50:
		floating_popups.pop_front()
	floating_popups.push_back({
		"x": x + randf_range(-4.0, 4.0),
		"y": y,
		"text": text,
		"color": col,
		"life": life,
		"maxLife": life
	})

func add_crater(x: float, y: float, radius: float, oil_slick: bool = false) -> void:
	if craters.size() >= MAX_CRATERS:
		craters.pop_front()
	craters.append({
		"x": x,
		"y": y,
		"radius": radius,
		"oilSlick": oil_slick,
		"angle": randf() * TAU,
		"seed": randi() % 100
	})

func add_tread_mark(x: float, y: float, angle: float) -> void:
	if tread_marks.size() > 400:
		tread_marks.pop_front()
	tread_marks.push_back({
		"x": x,
		"y": y,
		"angle": angle,
		"life": 22.0,
		"maxLife": 22.0
	})

func add_wreck(kind: String, x: float, y: float, angle: float) -> void:
	if wrecks.size() >= MAX_WRECKS:
		wrecks.pop_front()
	wrecks.append({
		"kind": kind,
		"x": x,
		"y": y,
		"angle": angle,
		"life": 26.0,
		"maxLife": 26.0
	})

func spawn_particle(kind: String, x: float, y: float, vx: float, vy: float, size: float, end_size: float, life: float, col: Color) -> void:
	var p = particles[particle_cursor]
	particle_cursor = (particle_cursor + 1) % MAX_PARTICLES
	p["active"] = true
	p["kind"] = kind
	p["x"] = x
	p["y"] = y
	p["vx"] = vx
	p["vy"] = vy
	p["size"] = size
	p["endSize"] = end_size
	p["maxLife"] = life
	p["life"] = life
	p["color"] = col
	p["alpha"] = 1.0

func spawn_burst(x: float, y: float, kind: String, count: int, col: Color, spd: float) -> void:
	for i in range(count):
		var p = particles[particle_cursor]
		particle_cursor = (particle_cursor + 1) % MAX_PARTICLES
		p["active"] = true
		p["kind"] = kind
		p["x"] = x
		p["y"] = y
		var ang = randf() * PI * 2.0
		var s = randf() * spd
		p["vx"] = cos(ang) * s
		p["vy"] = sin(ang) * s
		p["size"] = randf_range(3.0, 7.0)
		p["endSize"] = randf_range(10.0, 20.0)
		p["maxLife"] = randf_range(0.3, 0.7)
		p["life"] = p["maxLife"]
		p["color"] = col
		p["alpha"] = 1.0

func fire_projectile(attacker: Dictionary, target_pos: Vector2) -> void:
	SimCombat.fire_projectile(self, attacker, target_pos)
