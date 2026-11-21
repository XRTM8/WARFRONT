class_name WarFrontMain
extends Node2D

const WarFrontRenderer2D = preload("res://scripts/renderer_2d.gd")
const GameHUD = preload("res://scripts/hud.gd")
const SoundSynth = preload("res://scripts/sound_synth.gd")
const Simulation = preload("res://scripts/simulation.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")
const Constants = preload("res://scripts/constants.gd")

@onready var camera: Camera2D = $Camera2D
@onready var renderer: WarFrontRenderer2D = $Renderer2D
@onready var hud: GameHUD = $HUD
@onready var sound: SoundSynth = $SoundSynth

var sim: Simulation = null

var is_dragging_select: bool = false
var drag_start_world: Vector2 = Vector2.ZERO
var drag_start_screen: Vector2 = Vector2.ZERO

var camera_speed: float = 650.0
var base_camera_pos: Vector2 = Vector2.ZERO
var target_camera_pos: Vector2 = Vector2.ZERO
var target_zoom: Vector2 = Vector2(1.0, 1.0)
var is_dragging_pan: bool = false
var pan_drag_start: Vector2 = Vector2.ZERO

var control_groups: Dictionary = {}
var last_group_tap_time: Dictionary = {}

func _ready() -> void:
	sim = Simulation.new("kirkuk", 104729)
	sim.sound_triggered.connect(sound.play_sound)
	
	renderer.init_with_simulation(sim)
	hud.setup(sim)
	hud.train_requested.connect(_on_train_requested)
	hud.bridge_rebuild_requested.connect(_on_bridge_rebuild_requested)
	hud.select_all_requested.connect(_on_select_all_requested)
	hud.center_hq_requested.connect(_on_center_hq_requested)
	hud.minimap_pan_requested.connect(_on_minimap_pan_requested)
	hud.restart_requested.connect(_on_restart_requested)
	hud.theater_change_requested.connect(_on_theater_change_requested)
	hud.audio_toggle_requested.connect(_on_audio_toggle_requested)
	hud.commander_power_requested.connect(_on_commander_power_requested)
	hud.place_structure_requested.connect(_on_place_structure_requested)
	hud.micro_action_requested.connect(_on_micro_action_requested)
	hud.match_start_requested.connect(_on_match_start_requested)
	
	# Restrict camera within valid map bounds (eliminates any gray void)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(sim.map.get("width", 3456.0))
	camera.limit_bottom = int(sim.map.get("height", 1920.0))

	# Center camera around player HQ
	var phq = sim.map["playerHQ"]
	camera.position = Vector2(phq["x"], phq["y"])
	base_camera_pos = camera.position
	target_camera_pos = base_camera_pos
	target_zoom = camera.zoom

	# Tactical CRT Optics Vignette Overlay
	var vig_canvas = CanvasLayer.new()
	vig_canvas.layer = 2
	var vig_rect = ColorRect.new()
	vig_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vig_shader = load("res://shaders/vignette.gdshader")
	if vig_shader != null:
		var mat = ShaderMaterial.new()
		mat.shader = vig_shader
		vig_rect.material = mat
	vig_canvas.add_child(vig_rect)
	add_child(vig_canvas)

func _on_train_requested(kind: String) -> void:
	sim.train_player_unit(kind)

func _on_place_structure_requested(kind: String) -> void:
	sim.build_mode = "none" if sim.build_mode == kind else kind

func _on_micro_action_requested(action_id: String) -> void:
	if action_id == "attack_move":
		sim.attack_move_mode = not sim.attack_move_mode
		if sim.attack_move_mode:
			sound.play_sound("order_attack")
	elif action_id == "stop":
		sim.stop_selected_units()
	elif action_id == "hold":
		sim.set_selected_stance("hold_ground")
	elif action_id == "reverse":
		var m_pos = get_global_mouse_position()
		sim.issue_player_reverse_move(m_pos.x, m_pos.y, Input.is_key_pressed(KEY_SHIFT))
	elif action_id == "retreat":
		sim.retreat_selected_units()
	elif action_id == "ability":
		var m_pos = get_global_mouse_position()
		sim.execute_selected_ability(m_pos)

func _on_bridge_rebuild_requested() -> void:
	for b in sim.map["bridges"]:
		if b["status"] == "destroyed":
			sim.rebuild_bridge(b["id"], "player")
			break

func _on_commander_power_requested(power_id: String) -> void:
	if power_id == "supply_drop":
		var world_pos = get_global_mouse_position()
		sim.call_commander_power("supply_drop", world_pos, "player")
	else:
		sim.commander_targeting_power = power_id

func _on_select_all_requested() -> void:
	for u in sim.units:
		if u["alive"] and u["faction"] == "player" and u["kind"] != "truck" and u["kind"] != "turret":
			u["selected"] = true

func _on_center_hq_requested() -> void:
	var phq = sim.map["playerHQ"]
	target_camera_pos = Vector2(phq["x"], phq["y"])
	base_camera_pos = target_camera_pos

func _on_minimap_pan_requested(world_pos: Vector2) -> void:
	target_camera_pos = world_pos
	base_camera_pos = target_camera_pos

func _on_restart_requested() -> void:
	sim.reset(sim.theater, randi())
	renderer.init_with_simulation(sim)
	hud.modal.hide_all()
	_on_center_hq_requested()

func _on_theater_change_requested(theater_id: String) -> void:
	sim.reset(theater_id, randi())
	renderer.init_with_simulation(sim)
	camera.limit_right = int(sim.map.get("width", 3456.0))
	camera.limit_bottom = int(sim.map.get("height", 1920.0))
	hud.modal.hide_all()
	_on_center_hq_requested()

func _on_match_start_requested(theater_id: String, mode_id: String, faction_id: String) -> void:
	sim.init_match(theater_id, mode_id, faction_id)
	renderer.init_with_simulation(sim)
	camera.limit_right = int(sim.map.get("width", 4800.0))
	camera.limit_bottom = int(sim.map.get("height", 2880.0))
	hud.modal.hide_all()
	_on_center_hq_requested()

func _on_audio_toggle_requested(muted: bool) -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, muted)

func _physics_process(delta: float) -> void:
	if sim != null:
		if not hud.modal.is_paused:
			sim.step(delta)
		
		# Camera Trauma Shake
		if sim.camera_trauma > 0.0:
			var shake_amount = pow(sim.camera_trauma, 2.0) * 16.0
			camera.offset = Vector2(
				randf_range(-shake_amount, shake_amount),
				randf_range(-shake_amount, shake_amount)
			)
			camera.rotation = pow(sim.camera_trauma, 2.0) * randf_range(-0.025, 0.025)
		else:
			camera.offset = Vector2.ZERO
			camera.rotation = 0.0

func _process(delta: float) -> void:
	# Camera Pan Controls (Keyboard + Screen Edge Panning)
	var move_vec = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_vec.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_vec.y += 1.0
		
	# Edge-screen panning (when mouse is near viewport boundaries and not paused)
	var vp = get_viewport()
	if vp != null and not hud.modal.is_paused:
		var m_pos = vp.get_mouse_position()
		var vp_size = vp.get_visible_rect().size
		var edge_margin = 16.0
		if m_pos.x >= 0 and m_pos.x <= vp_size.x and m_pos.y >= 0 and m_pos.y <= vp_size.y:
			if m_pos.x <= edge_margin:
				move_vec.x -= 1.0
			elif m_pos.x >= vp_size.x - edge_margin:
				move_vec.x += 1.0
			if m_pos.y <= edge_margin:
				move_vec.y -= 1.0
			elif m_pos.y >= vp_size.y - edge_margin:
				move_vec.y += 1.0
		
	if move_vec != Vector2.ZERO:
		target_camera_pos += move_vec.normalized() * (camera_speed / target_zoom.x) * delta
		var map_w = sim.map.get("width", 3456.0)
		var map_h = sim.map.get("height", 1920.0)
		target_camera_pos.x = clamp(target_camera_pos.x, 200.0, map_w - 200.0)
		target_camera_pos.y = clamp(target_camera_pos.y, 200.0, map_h - 200.0)
		base_camera_pos = target_camera_pos

	# AAA Smooth Camera Lerp (Inertial damping & smooth zoom)
	camera.position = camera.position.lerp(target_camera_pos, 12.0 * delta)
	camera.zoom = camera.zoom.lerp(target_zoom, 14.0 * delta)

func _unhandled_input(event: InputEvent) -> void:
	# Tactical Pause Toggle
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			hud.toggle_pause()
			return

	if hud.modal.is_paused:
		return

	# Unit Training Hotkeys & RTS Tactical Control Commands
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_A:
			_on_micro_action_requested("attack_move")
		elif event.keycode == KEY_S:
			_on_micro_action_requested("stop")
		elif event.keycode == KEY_H:
			_on_micro_action_requested("hold")
		elif event.keycode == KEY_G:
			_on_micro_action_requested("reverse")
		elif event.keycode == KEY_Y:
			var m_pos = get_global_mouse_position()
			sim.set_player_rally_point(m_pos.x, m_pos.y)
		elif event.keycode == KEY_R:
			_on_micro_action_requested("retreat")
		elif event.keycode == KEY_F:
			_on_micro_action_requested("ability")
		elif event.keycode == KEY_T:
			var m_pos = get_global_mouse_position()
			sim.deploy_player_landmine(m_pos.x, m_pos.y)
		elif event.keycode in [KEY_1, KEY_2, KEY_3, KEY_4]:
			var grp_idx = event.keycode - KEY_0
			if Input.is_key_pressed(KEY_CTRL):
				var grp_ids: Array[int] = []
				for u in sim.units:
					if u["alive"] and u["faction"] == "player" and u["selected"] and u["kind"] != "truck" and u["kind"] != "turret":
						grp_ids.push_back(u["id"])
				control_groups[grp_idx] = grp_ids
				sound.play_sound("unit_select")
				sim.push_event("group_bound", "good")
			elif control_groups.has(grp_idx) and not control_groups[grp_idx].is_empty():
				var found_any = false
				var grp_center = Vector2.ZERO
				var active_count = 0
				for u in sim.units:
					if u["alive"] and u["faction"] == "player" and u["kind"] != "truck" and u["kind"] != "turret":
						var in_grp = control_groups[grp_idx].has(u["id"])
						u["selected"] = in_grp
						if in_grp:
							found_any = true
							grp_center += Vector2(u["x"], u["y"])
							active_count += 1
				if found_any:
					sound.play_sound("unit_select")
					var now = sim.sim_time
					if now - last_group_tap_time.get(grp_idx, -99.0) < 0.35 and active_count > 0:
						target_camera_pos = grp_center / float(active_count)
					last_group_tap_time[grp_idx] = now
			else:
				if event.keycode == KEY_1:
					sim.train_player_unit("scout")
				elif event.keycode == KEY_2:
					sim.train_player_unit("tank")
				elif event.keycode == KEY_3:
					sim.train_player_unit("behemoth")
				elif event.keycode == KEY_4:
					sim.train_player_unit("artillery")
		elif event.keycode == KEY_5:
			sim.train_player_unit("helicopter")
		elif event.keycode == KEY_6:
			sim.train_player_unit("engineer")
		elif event.keycode == KEY_7:
			_on_place_structure_requested("turret")
		elif event.keycode == KEY_F1:
			_on_place_structure_requested("war_factory")
		elif event.keycode == KEY_F2:
			_on_place_structure_requested("repair_depot")
		elif event.keycode == KEY_F3:
			_on_place_structure_requested("refinery_silo")
		elif event.keycode == KEY_F4:
			_on_place_structure_requested("turret")
		elif event.keycode == KEY_F5:
			_on_place_structure_requested("missile_battery")
		elif event.keycode == KEY_F6:
			_on_place_structure_requested("sandbag_wall")
		elif event.keycode == KEY_B:
			_on_bridge_rebuild_requested()
		elif event.keycode == KEY_Z:
			_on_commander_power_requested("airstrike")
		elif event.keycode == KEY_X:
			_on_commander_power_requested("artillery_barrage")
		elif event.keycode == KEY_C:
			_on_commander_power_requested("recon_drone")
		elif event.keycode == KEY_V:
			_on_commander_power_requested("supply_drop")
			
	# Smooth Mouse Zoom & Middle Mouse Drag Pan
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			target_zoom = (target_zoom * 1.15).clamp(Vector2(0.6, 0.6), Vector2(2.0, 2.0))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			target_zoom = (target_zoom / 1.15).clamp(Vector2(0.6, 0.6), Vector2(2.0, 2.0))
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging_pan = event.is_pressed()
			pan_drag_start = event.position
			
		# Left Click: Selection or Turret placement or Bridge rebuild or Commander Power
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var world_pos = get_global_mouse_position()
			if event.is_pressed():
				# Commander power targeting execution
				if sim.commander_targeting_power != "":
					sim.call_commander_power(sim.commander_targeting_power, world_pos, "player")
					sim.commander_targeting_power = ""
					return

				# Attack-Move tactical targeting execution
				if sim.attack_move_mode:
					var shift = Input.is_key_pressed(KEY_SHIFT)
					sim.issue_player_attack_move(world_pos.x, world_pos.y, shift)
					sim.attack_move_mode = false
					return

				# Base Building placement mode
				if sim.build_mode != "none" and Constants.BUILDING_SPECS.has(sim.build_mode):
					var placed = sim.place_player_structure(sim.build_mode, world_pos.x, world_pos.y)
					if placed:
						sound.play_sound("order_click")
					return
					
				# Click destroyed bridge to rebuild?
				var clicked_b = Pathfinding.get_bridge_at_world(sim.map, world_pos.x, world_pos.y, 16.0)
				if not clicked_b.is_empty() and clicked_b["status"] == "destroyed":
					sim.rebuild_bridge(clicked_b["id"], "player")
					return
					
				# Start drag selection
				is_dragging_select = true
				drag_start_world = world_pos
				renderer.is_dragging_selection = true
				renderer.selection_box = Rect2(world_pos, Vector2.ZERO)
			else:
				if is_dragging_select:
					is_dragging_select = false
					renderer.is_dragging_selection = false
					var sel_rect = Rect2(
						min(drag_start_world.x, world_pos.x),
						min(drag_start_world.y, world_pos.y),
						abs(world_pos.x - drag_start_world.x),
						abs(world_pos.y - drag_start_world.y)
					)
					var sel_count = sim.select_units_in_box(sel_rect, Input.is_key_pressed(KEY_SHIFT))
					if sel_count > 0:
						sound.play_sound("order_click")
					
		# Right Click: Command Order (Move, Attack, Demolish) or Cancel Targeting/Build/Attack-Move Mode
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if sim.commander_targeting_power != "":
				sim.commander_targeting_power = ""
				return
			if sim.build_mode != "none":
				sim.build_mode = "none"
				return
			if sim.attack_move_mode:
				sim.attack_move_mode = false
				return
			var world_pos = get_global_mouse_position()
			var shift = Input.is_key_pressed(KEY_SHIFT)
			var issued = sim.issue_player_command(world_pos.x, world_pos.y, shift)
			if issued:
				sound.play_sound("order_click")
			else:
				# If no combat units were selected, set base Rally Point!
				sim.set_player_rally_point(world_pos.x, world_pos.y)

	elif event is InputEventMouseMotion:
		var world_pos = get_global_mouse_position()
		renderer.hover_world_pos = world_pos
		
		# Middle mouse drag panning
		if is_dragging_pan:
			target_camera_pos -= event.relative / target_zoom.x
			var map_w = sim.map.get("width", 3456.0)
			var map_h = sim.map.get("height", 1920.0)
			target_camera_pos.x = clamp(target_camera_pos.x, 200.0, map_w - 200.0)
			target_camera_pos.y = clamp(target_camera_pos.y, 200.0, map_h - 200.0)
			base_camera_pos = target_camera_pos
			
		if is_dragging_select:
			var sel_rect = Rect2(
				min(drag_start_world.x, world_pos.x),
				min(drag_start_world.y, world_pos.y),
				abs(world_pos.x - drag_start_world.x),
				abs(world_pos.y - drag_start_world.y)
			)
			renderer.selection_box = sel_rect
