class_name HUDMinimap
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

const MINIMAP_WIDTH: float = 186.0
const MINIMAP_HEIGHT: float = 110.0

var minimap_control: Control = null

func build_minimap(parent: Control, on_select_all: Callable, on_center_hq: Callable) -> Control:
	var minimap_frame = PanelContainer.new()
	var mini_style = StyleBoxFlat.new()
	mini_style.bg_color = Color(0.07, 0.09, 0.06, 0.96)
	mini_style.border_color = Color("#48523b")
	mini_style.border_width_left = 1
	mini_style.border_width_right = 1
	mini_style.border_width_top = 1
	mini_style.border_width_bottom = 2
	mini_style.content_margin_left = 4
	mini_style.content_margin_right = 4
	mini_style.content_margin_top = 4
	mini_style.content_margin_bottom = 4
	minimap_frame.add_theme_stylebox_override("panel", mini_style)
	parent.add_child(minimap_frame)
	
	var mini_vbox = VBoxContainer.new()
	mini_vbox.add_theme_constant_override("separation", 3)
	minimap_frame.add_child(mini_vbox)
	
	minimap_control = Control.new()
	minimap_control.custom_minimum_size = Vector2(MINIMAP_WIDTH, MINIMAP_HEIGHT)
	mini_vbox.add_child(minimap_control)
	
	var mini_btn_box = HBoxContainer.new()
	mini_btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	mini_btn_box.add_theme_constant_override("separation", 10)
	mini_vbox.add_child(mini_btn_box)
	
	var select_all_btn = Button.new()
	select_all_btn.text = "[Q] كل الوحدات"
	select_all_btn.add_theme_font_size_override("font_size", 9)
	select_all_btn.pressed.connect(on_select_all)
	mini_btn_box.add_child(select_all_btn)
	
	var center_hq_btn = Button.new()
	center_hq_btn.text = "[H] القيادة"
	center_hq_btn.add_theme_font_size_override("font_size", 9)
	center_hq_btn.pressed.connect(on_center_hq)
	mini_btn_box.add_child(center_hq_btn)
	
	return minimap_control

static func draw_minimap(canvas: Control, sim, camera: Camera2D, vp_size: Vector2) -> void:
	if sim == null or sim.map.is_empty():
		return
	var map = sim.map
	var pal = Constants.THEATER_PALETTES.get(map["theater"], Constants.THEATER_PALETTES["kirkuk"])
	var sx = MINIMAP_WIDTH / map["width"]
	var sy = MINIMAP_HEIGHT / map["height"]
	
	# Background
	canvas.draw_rect(Rect2(0, 0, MINIMAP_WIDTH, MINIMAP_HEIGHT), pal["groundB"])
	
	# Terrain Topography (Meandering River, Island, Ford, Mesas)
	var tw = Constants.TILE_SIZE * sx
	var th = Constants.TILE_SIZE * sy
	for r in range(map["rows"]):
		for c in range(map["cols"]):
			var tile = map["tiles"][r * map["cols"] + c]
			if tile == "water":
				canvas.draw_rect(Rect2(c * tw, r * th, tw + 0.6, th + 0.6), pal["waterDeep"])
			elif tile == "ford":
				canvas.draw_rect(Rect2(c * tw, r * th, tw + 0.6, th + 0.6), pal.get("ford", Color("#326177")))
			elif tile == "rock" or tile == "cliff":
				canvas.draw_rect(Rect2(c * tw, r * th, tw + 0.6, th + 0.6), pal.get("rockFace", Color("#4e3d29")))
			elif tile == "concrete":
				canvas.draw_rect(Rect2(c * tw, r * th, tw + 0.6, th + 0.6), pal["concrete"])
		
	# Bridges
	for b in map["bridges"]:
		var b_col = Color("#8bd46a") if b["status"] == "intact" else Color("#ef4444")
		var bw = b.get("width", 64.0)
		var bh = b.get("height", 32.0)
		canvas.draw_rect(Rect2((b["x"] - bw / 2.0) * sx, (b["y"] - bh / 2.0) * sy, max(6.0, bw * sx), max(4.0, bh * sy)), b_col)
		
	# Oil Rigs
	for rig in map["rigs"]:
		var r_col = Color("#7ce063") if rig["owner"] == "player" else (Color("#ef5350") if rig["owner"] == "enemy" else Color("#f0c45c"))
		canvas.draw_rect(Rect2(rig["x"] * sx - 2.5, rig["y"] * sy - 2.5, 5, 5), r_col)
		
	# HQs (Supports multi-HQ arrays on large maps)
	var hqs_list = map.get("hqs", [])
	if hqs_list.size() > 0:
		for hq in hqs_list:
			var sid = hq.get("slot_id", 0)
			var hq_col = Constants.SLOT_DEFAULT_COLORS[sid % Constants.SLOT_DEFAULT_COLORS.size()]
			canvas.draw_rect(Rect2(hq["x"] * sx - 3.5, hq["y"] * sy - 3.5, 7, 7), hq_col)
	else:
		var phq = map["playerHQ"]
		var ehq = map["enemyHQ"]
		canvas.draw_rect(Rect2(phq["x"] * sx - 3.5, phq["y"] * sy - 3.5, 7, 7), Color("#62d94e"))
		canvas.draw_rect(Rect2(ehq["x"] * sx - 3.5, ehq["y"] * sy - 3.5, 7, 7), Color("#f2554e"))
	
	# Units
	for u in sim.units:
		if not u["alive"]:
			continue
		var u_col: Color
		if u.has("color") and u["color"] is Color:
			u_col = u["color"]
		elif u["kind"] == "truck":
			u_col = Color("#f5c249")
		elif u["faction"] == "player":
			u_col = Color("#b7ff9e")
		else:
			u_col = Color("#ff8c85")
		canvas.draw_rect(Rect2(u["x"] * sx - 1.5, u["y"] * sy - 1.5, 3, 3), u_col)
		canvas.draw_rect(Rect2(u["x"] * sx - 1, u["y"] * sy - 1, 2, 2), u_col)

	# Active Tactical Radar Sweep Beam
	var sweep_angle = fmod(sim.sim_time * 2.4, TAU)
	var sweep_center = Vector2(MINIMAP_WIDTH * 0.5, MINIMAP_HEIGHT * 0.5)
	var sweep_end = sweep_center + Vector2(cos(sweep_angle), sin(sweep_angle)) * 110.0
	canvas.draw_line(sweep_center, sweep_end, Color(0.35, 0.85, 0.25, 0.35), 1.5)

	# Dynamic Camera Viewport Rectangle on Minimap
	if camera != null:
		var size = vp_size / camera.zoom
		var cx = (camera.position.x - size.x * 0.5) * sx
		var cy = (camera.position.y - size.y * 0.5) * sy
		var cw = size.x * sx
		var ch = size.y * sy
		canvas.draw_rect(Rect2(cx, cy, cw, ch), Color(0.96, 0.93, 0.85, 0.85), false, 1.25)

static func handle_input(event: InputEvent, map: Dictionary, on_pan: Callable) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var click_pos = event.position
		var world_x = (click_pos.x / MINIMAP_WIDTH) * map["width"]
		var world_y = (click_pos.y / MINIMAP_HEIGHT) * map["height"]
		on_pan.call(Vector2(world_x, world_y))
