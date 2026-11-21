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
const SimProductionQueue = preload("res://scripts/sim_production_queue.gd")
const SimHazards = preload("res://scripts/sim_hazards.gd")
const SimAITactics = preload("res://scripts/sim_ai_tactics.gd")
const SimBuildingSystems = preload("res://scripts/sim_building_systems.gd")
const HardwareDisplayManager = preload("res://scripts/hardware_display_manager.gd")

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

var flying_turrets: Array[Dictionary] = []
var combat_momentum: float = 0.0
var combat_surge_active: bool = false
var combat_surge_timer: float = 0.0
var landmines: Array[Dictionary] = []
var napalm_patches: Array[Dictionary] = []
var airdrop_crates: Array[Dictionary] = []
var airdrop_timer: float = 40.0
var cargo_shadows: Array[Dictionary] = []
var recent_player_kills: Array[float] = []

var player_rally_point: Vector2 = Vector2.ZERO
var player_doctrine: String = ""
var enemy_doctrine: String = ""
var reverse_move_mode: bool = false
var match_mode: String = "1v1"
var slots: Array[Dictionary] = []
var active_human_slot: int = 0

var next_unit_id: int = 1
var next_projectile_id: int = 1
var elapsed_seconds: float = 0.0
var sim_time: float = 0.0
var camera_trauma: float = 0.0
var hitstop_timer: float = 0.0

var bridges_destroyed_by_player: int = 0
var enemy_trucks_destroyed: int = 0
var build_mode: String = "none" # "none", "turret"
var build_rotation: float = 0.0
var attack_move_mode: bool = false
var order_pulse: Dictionary = {} # { x, y, color, timer }
var fog_of_war_enabled: bool = false

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
	flying_turrets.clear()
	landmines.clear()
	napalm_patches.clear()
	airdrop_crates.clear()
	cargo_shadows.clear()
	recent_player_kills.clear()
	combat_momentum = 0.0
	combat_surge_active = false
	combat_surge_timer = 0.0
	airdrop_timer = 45.0
	player_rally_point = Vector2.ZERO
	player_doctrine = ""
	enemy_doctrine = ""
	reverse_move_mode = false
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
	init_slots(match_mode, active_human_slot, player_doctrine if player_doctrine != "" else "vanguard")
	SimUnits.setup_initial_forces(self)

func init_match(th: String, preset_mode: String = "1v1", player_fac: String = "vanguard") -> void:
	theater = th
	match_mode = preset_mode
	player_doctrine = player_fac
	reset(th, seed_val)

func init_slots(preset: String = "1v1", human_slot: int = 0, human_fac: String = "vanguard") -> void:
	match_mode = preset
	active_human_slot = human_slot
	slots.clear()
	
	var preset_cfg = Constants.MATCH_PRESETS.get(preset, Constants.MATCH_PRESETS["1v1"])
	var slot_count: int = preset_cfg["slots_count"]
	var teams: Array = preset_cfg["default_teams"]
	
	for i in range(slot_count):
		var is_human = (i == human_slot)
		var fac = human_fac if is_human else ("raiders" if human_fac == "vanguard" else "vanguard")
		var team_id = teams[i] if i < teams.size() else (i + 1)
		var col = Constants.SLOT_DEFAULT_COLORS[i % Constants.SLOT_DEFAULT_COLORS.size()]
		
		slots.push_back({
			"slot_id": i,
			"team_id": team_id,
			"is_human": is_human,
			"faction": fac,
			"color": col,
			"hq_id": "hq_%d" % i if slot_count > 2 else ("hq_player" if i == 0 else "hq_enemy"),
			"oil": Constants.STARTING_PLAYER_OIL if is_human else Constants.STARTING_ENEMY_OIL,
			"oil_delivered": 0,
			"alive": true
		})

func get_slot_hq(slot_id: int) -> Dictionary:
	var hqs = map.get("hqs", [])
	if slot_id >= 0 and slot_id < hqs.size():
		return hqs[slot_id]
	return map["playerHQ"] if slot_id == 0 else map["enemyHQ"]

func are_hostile(entity_a: Variant, entity_b: Variant) -> bool:
	if entity_a == null or entity_b == null:
		return false
	var team_a = get_entity_team(entity_a)
	var team_b = get_entity_team(entity_b)
	if team_a == 0 or team_b == 0:
		return false
	return team_a != team_b

func get_entity_team(entity: Variant) -> int:
	if entity is String:
		if entity == "player":
			return slots[active_human_slot]["team_id"] if slots.size() > active_human_slot else 1
		elif entity == "enemy":
			return 2
		return 0
	if entity is Dictionary:
		if entity.has("team_id"):
			return entity["team_id"]
		if entity.has("slot_id"):
			var sid = entity["slot_id"]
			if sid >= 0 and sid < slots.size():
				return slots[sid]["team_id"]
		var fac = entity.get("faction", "")
		if fac == "player":
			return slots[active_human_slot]["team_id"] if slots.size() > active_human_slot else 1
		elif fac == "enemy":
			return 2
	return 0

func get_unit_color(u: Dictionary) -> Color:
	if u.has("color"):
		return u["color"]
	var sid = u.get("slot_id", -1)
	if sid >= 0 and sid < slots.size():
		return slots[sid]["color"]
	var fac = u.get("faction", "player")
	return Color("#22c55e") if fac == "player" else Color("#ef4444")

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

	# Combat momentum & Tactical Surge management
	if combat_surge_active:
		combat_surge_timer -= dt
		combat_momentum = max(0.0, (combat_surge_timer / Constants.SURGE_DURATION) * Constants.MOMENTUM_MAX)
		if combat_surge_timer <= 0.0:
			combat_surge_active = false
			combat_momentum = 0.0
			push_event("surge_ended", "normal")
	else:
		combat_momentum = max(0.0, combat_momentum - dt * 1.4)

	SimLogistics.update_oil_rigs(self, dt)
	SimUnits.update_units(self, dt)
	SimBuildings.update_structures(self, dt)
	SimProductionQueue.tick_production(self, dt)
	SimCombat.update_projectiles(self, dt)
	SimCommander.update_commander(self, dt)
	SimHazards.update_flying_turrets(self, dt)
	SimHazards.update_napalm_patches(self, dt)
	SimHazards.update_landmines(self, dt)
	SimCommander.update_airdrop_crates(self, dt)
	SimCommander.update_cargo_shadows(self, dt)
	
	if phase == "playing":
		airdrop_timer -= dt
		if airdrop_timer <= 0.0:
			airdrop_timer = randf_range(70.0, 95.0)
			_spawn_ambient_airdrop()
			
		SimAI.update_enemy_ai(self, dt)
		SimAITactics.update_coordinated_assault(self, dt)
		SimAI.check_win_loss(self)

func _spawn_ambient_airdrop() -> void:
	if map.is_empty():
		return
	var drop_x = randf_range(map["width"] * 0.32, map["width"] * 0.68)
	var drop_y = randf_range(map["height"] * 0.22, map["height"] * 0.78)
	var keys = Constants.AIRDROP_TYPES.keys()
	var type_id = keys[randi() % keys.size()]
	SimCommander.trigger_airdrop(self, Vector2(drop_x, drop_y), type_id)

func add_combat_momentum(amount: float) -> void:
	if combat_surge_active or amount <= 0.0:
		return
	combat_momentum = min(Constants.MOMENTUM_MAX, combat_momentum + amount)
	if combat_momentum >= Constants.MOMENTUM_MAX:
		combat_surge_active = true
		combat_surge_timer = Constants.SURGE_DURATION
		sound_triggered.emit("war_horn")
		camera_trauma = min(1.0, camera_trauma + 0.45)
		push_event("surge_active", "good")
		var phq = map.get("playerHQ", {})
		if not phq.is_empty():
			spawn_floating_text(phq["x"], phq["y"] - 55.0, "[ TACTICAL SURGE // عاصفة القتال: هجوم شامل ]", Color("#f59e0b"), 2.2)

func record_player_kill(kind: String, pos: Vector2) -> void:
	var now = sim_time
	recent_player_kills.push_back(now)
	while recent_player_kills.size() > 0 and (now - recent_player_kills[0]) > 4.0:
		recent_player_kills.pop_front()
		
	var count = recent_player_kills.size()
	if count == 2:
		spawn_floating_text(pos.x, pos.y - 28.0, "[ DOUBLE KILL // تصفية مزدوجة ]", Color("#f59e0b"), 1.4)
		sound_triggered.emit("multi_kill")
		add_combat_momentum(16.0)
	elif count >= 3:
		spawn_floating_text(pos.x, pos.y - 36.0, "[ TRIPLE KILL // إبادة ثلاثية ]", Color("#ef4444"), 1.8)
		sound_triggered.emit("multi_kill")
		add_combat_momentum(24.0)
	else:
		if kind == "behemoth":
			spawn_floating_text(pos.x, pos.y - 36.0, "[ TARGET NEUTRALIZED // تحييد العملاق ]", Color("#fbbf24"), 2.0)
			sound_triggered.emit("multi_kill")
			add_combat_momentum(25.0)
		elif kind == "tank" or kind == "artillery":
			add_combat_momentum(12.0)
		else:
			add_combat_momentum(6.0)

func deploy_player_landmine(x: float, y: float) -> bool:
	return SimUnits.deploy_landmine_at(self, "player", Vector2(x, y))

func execute_selected_ability(target_pos: Vector2) -> bool:
	return SimUnits.execute_selected_ability(self, target_pos)

func execute_unit_ability(unit: Dictionary, target_pos: Vector2) -> bool:
	return SimUnits.execute_unit_ability(self, unit, target_pos)

func call_commander_power(power_id: String, target_world: Vector2, faction: String = "player") -> bool:
	return SimCommander.call_commander_power(self, power_id, target_world, faction)

func spawn_salvage(x: float, y: float, oil_amount: int) -> void:
	SimCommander.spawn_salvage(self, x, y, oil_amount)

func notify_directive(directive_type: String) -> void:
	SimCommander.notify_directive_progress(self, directive_type)

func spawn_unit(faction: String, kind: String, x: float, y: float, slot_idx: int = -1) -> Dictionary:
	return SimUnits.spawn_unit(self, faction, kind, x, y, slot_idx)

func train_player_unit(kind: String) -> bool:
	return SimUnits.train_player_unit(self, kind)

func queue_unit(kind: String, faction: String = "player") -> bool:
	return SimProductionQueue.queue_unit(self, faction, kind)

func cancel_queued_unit(faction: String, category: String, index: int = -1) -> bool:
	return SimProductionQueue.cancel_queued_unit(self, faction, category, index)

func set_category_rally_point(category: String, point: Vector2, faction: String = "player") -> void:
	SimProductionQueue.set_category_rally_point(self, faction, category, point)

func get_production_queues(faction: String = "player") -> Dictionary:
	return SimProductionQueue.get_queues(self, faction)

func get_facility_count(facility_kind: String, faction: String = "player") -> int:
	return SimProductionQueue.get_facility_count(self, faction, facility_kind)

func get_production_speed_multiplier(category: String, faction: String = "player") -> float:
	return SimProductionQueue.get_speed_multiplier(self, faction, category)

func place_player_turret(x: float, y: float) -> bool:
	return SimUnits.place_player_turret(self, x, y)

func place_player_structure(kind: String, x: float, y: float) -> bool:
	return SimBuildings.place_structure(self, kind, x, y, "player")

func decommission_structure(structure_id: int, faction: String = "player") -> bool:
	return SimBuildingSystems.decommission_structure(self, structure_id, faction)

func trigger_emergency_repair(structure_id: int, faction: String = "player") -> bool:
	return SimBuildingSystems.trigger_emergency_repair(self, structure_id, faction)

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

func issue_player_reverse_move(world_x: float, world_y: float, shift_queued: bool = false) -> bool:
	return SimUnits.issue_player_reverse_move(self, world_x, world_y, shift_queued)

func set_player_rally_point(world_x: float, world_y: float) -> void:
	player_rally_point = Vector2(world_x, world_y)
	sound_triggered.emit("radio_in")
	push_event("rally_point_set", "good")
	spawn_floating_text(world_x, world_y - 20.0, "[ RALLY POINT // راية التجمع ]", Color("#38bdf8"), 1.25)
	spawn_particle("ring", world_x, world_y, 0.0, 0.0, 4.0, 36.0, 0.35, Color("#38bdf8"))
	for cat in ["barracks", "war_factory", "airfield", "shipyard", "missile_plant"]:
		set_category_rally_point(cat, player_rally_point, "player")

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
	var mult = HardwareDisplayManager.get_instance().active_settings.get("particle_multiplier", 1.0)
	var final_count = max(1, int(round(float(count) * mult)))
	for i in range(final_count):
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
