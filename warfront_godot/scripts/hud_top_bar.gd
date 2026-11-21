class_name HUDTopBar
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const HardwareDisplayManager = preload("res://scripts/hardware_display_manager.gd")

var oil_num_label: Label = null
var rigs_val_label: Label = null
var trucks_val_label: Label = null
var bridges_val_label: Label = null
var veterans_val_label: Label = null
var veterans_container: HBoxContainer = null
var fps_badge_btn: Button = null

var player_hp_pct_label: Label = null
var enemy_hp_pct_label: Label = null
var player_hp_bar: ProgressBar = null
var enemy_hp_bar: ProgressBar = null

var momentum_label: Label = null
var momentum_bar: ProgressBar = null

func build_top_bar(parent: CanvasLayer, on_pause_cb: Callable = Callable(), on_graphics_cb: Callable = Callable()) -> void:
	var top_margin = MarginContainer.new()
	top_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_margin.add_theme_constant_override("margin_left", 14)
	top_margin.add_theme_constant_override("margin_right", 14)
	top_margin.add_theme_constant_override("margin_top", 10)
	parent.add_child(top_margin)
	
	var top_layout = HBoxContainer.new()
	top_layout.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_margin.add_child(top_layout)
	
	# Logistics Cluster (Styled Bezel)
	var log_panel = PanelContainer.new()
	var log_style = StyleBoxFlat.new()
	log_style.bg_color = Color(0.09, 0.11, 0.08, 0.94)
	log_style.border_color = Color("#444e38")
	log_style.border_width_left = 1
	log_style.border_width_right = 1
	log_style.border_width_top = 1
	log_style.border_width_bottom = 2
	log_style.content_margin_left = 14
	log_style.content_margin_right = 14
	log_style.content_margin_top = 6
	log_style.content_margin_bottom = 6
	log_panel.add_theme_stylebox_override("panel", log_style)
	top_layout.add_child(log_panel)
	
	var log_box = HBoxContainer.new()
	log_box.add_theme_constant_override("separation", 18)
	log_panel.add_child(log_box)
	
	# Hero Oil Group
	var oil_box = HBoxContainer.new()
	oil_box.add_theme_constant_override("separation", 8)
	log_box.add_child(oil_box)
	
	var oil_icon = Label.new()
	oil_icon.text = "[BBL]"
	oil_icon.add_theme_color_override("font_color", Color("#f59e0b"))
	oil_icon.add_theme_font_size_override("font_size", 12)
	oil_box.add_child(oil_icon)
	
	var oil_vbox = VBoxContainer.new()
	oil_vbox.add_theme_constant_override("separation", 0)
	oil_box.add_child(oil_vbox)
	
	var oil_title = Label.new()
	oil_title.text = "النفط"
	oil_title.add_theme_color_override("font_color", Color("#b5ac94"))
	oil_title.add_theme_font_size_override("font_size", 10)
	oil_vbox.add_child(oil_title)
	
	oil_num_label = Label.new()
	oil_num_label.text = "260"
	oil_num_label.add_theme_color_override("font_color", Color("#f4c04e"))
	oil_num_label.add_theme_font_size_override("font_size", 20)
	oil_vbox.add_child(oil_num_label)
	
	# Separator
	var sep = VSeparator.new()
	log_box.add_child(sep)
	
	# Rigs
	var rigs_box = VBoxContainer.new()
	rigs_box.add_theme_constant_override("separation", 0)
	log_box.add_child(rigs_box)
	var rigs_title = Label.new()
	rigs_title.text = "الآبار"
	rigs_title.add_theme_color_override("font_color", Color("#9e9681"))
	rigs_title.add_theme_font_size_override("font_size", 10)
	rigs_box.add_child(rigs_title)
	rigs_val_label = Label.new()
	rigs_val_label.text = "1/6"
	rigs_val_label.add_theme_color_override("font_color", Color("#e9e3d2"))
	rigs_val_label.add_theme_font_size_override("font_size", 13)
	rigs_box.add_child(rigs_val_label)
	
	# Convoys / Trucks
	var trk_box = VBoxContainer.new()
	trk_box.add_theme_constant_override("separation", 0)
	log_box.add_child(trk_box)
	var trk_title = Label.new()
	trk_title.text = "الشاحنات"
	trk_title.add_theme_color_override("font_color", Color("#9e9681"))
	trk_title.add_theme_font_size_override("font_size", 10)
	trk_box.add_child(trk_title)
	trucks_val_label = Label.new()
	trucks_val_label.text = "1"
	trucks_val_label.add_theme_color_override("font_color", Color("#e9e3d2"))
	trucks_val_label.add_theme_font_size_override("font_size", 13)
	trk_box.add_child(trucks_val_label)
	
	# Bridges
	var brg_box = VBoxContainer.new()
	brg_box.add_theme_constant_override("separation", 0)
	log_box.add_child(brg_box)
	var brg_title = Label.new()
	brg_title.text = "الجسور"
	brg_title.add_theme_color_override("font_color", Color("#9e9681"))
	brg_title.add_theme_font_size_override("font_size", 10)
	brg_box.add_child(brg_title)
	bridges_val_label = Label.new()
	bridges_val_label.text = "3/3"
	bridges_val_label.add_theme_color_override("font_color", Color("#8bd46a"))
	bridges_val_label.add_theme_font_size_override("font_size", 13)
	brg_box.add_child(bridges_val_label)
	
	# Veterans
	veterans_container = HBoxContainer.new()
	veterans_container.visible = false
	log_box.add_child(veterans_container)
	var vet_box = VBoxContainer.new()
	vet_box.add_theme_constant_override("separation", 0)
	veterans_container.add_child(vet_box)
	var vet_title = Label.new()
	vet_title.text = "المخضرمون"
	vet_title.add_theme_color_override("font_color", Color("#9e9681"))
	vet_title.add_theme_font_size_override("font_size", 10)
	vet_box.add_child(vet_title)
	veterans_val_label = Label.new()
	veterans_val_label.text = "0"
	veterans_val_label.add_theme_color_override("font_color", Color("#ffd659"))
	veterans_val_label.add_theme_font_size_override("font_size", 13)
	vet_box.add_child(veterans_val_label)

	# Spacer
	var mid_spacer = Control.new()
	mid_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_layout.add_child(mid_spacer)

	# Tactical Combat Momentum / Adrenaline Cluster
	var mom_panel = PanelContainer.new()
	var mom_style = StyleBoxFlat.new()
	mom_style.bg_color = Color(0.11, 0.09, 0.06, 0.92)
	mom_style.border_color = Color("#b45309")
	mom_style.border_width_left = 1
	mom_style.border_width_right = 1
	mom_style.border_width_top = 1
	mom_style.border_width_bottom = 2
	mom_style.content_margin_left = 12
	mom_style.content_margin_right = 12
	mom_style.content_margin_top = 5
	mom_style.content_margin_bottom = 5
	mom_panel.add_theme_stylebox_override("panel", mom_style)
	top_layout.add_child(mom_panel)
	
	var mom_box = VBoxContainer.new()
	mom_box.add_theme_constant_override("separation", 2)
	mom_panel.add_child(mom_box)
	
	momentum_label = Label.new()
	momentum_label.text = "[ COMBAT MOMENTUM // زحف الحماسة ]"
	momentum_label.add_theme_color_override("font_color", Color("#f59e0b"))
	momentum_label.add_theme_font_size_override("font_size", 10)
	mom_box.add_child(momentum_label)
	
	momentum_bar = ProgressBar.new()
	momentum_bar.custom_minimum_size = Vector2(100, 8)
	momentum_bar.max_value = 100.0
	momentum_bar.value = 0.0
	momentum_bar.show_percentage = false
	mom_box.add_child(momentum_bar)

	# Spacer 2
	var mid_spacer2 = Control.new()
	mid_spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_layout.add_child(mid_spacer2)

	# Center Command Integrity Cluster
	var hq_panel = PanelContainer.new()
	var hq_style = StyleBoxFlat.new()
	hq_style.bg_color = Color(0.09, 0.11, 0.08, 0.9)
	hq_style.border_color = Color("#3a432f")
	hq_style.border_width_left = 1
	hq_style.border_width_right = 1
	hq_style.border_width_top = 1
	hq_style.border_width_bottom = 2
	hq_style.content_margin_left = 14
	hq_style.content_margin_right = 14
	hq_style.content_margin_top = 6
	hq_style.content_margin_bottom = 6
	hq_panel.add_theme_stylebox_override("panel", hq_style)
	top_layout.add_child(hq_panel)
	
	var hq_box = HBoxContainer.new()
	hq_box.add_theme_constant_override("separation", 14)
	hq_panel.add_child(hq_box)
	
	# Player HQ
	var phq_box = HBoxContainer.new()
	phq_box.add_theme_constant_override("separation", 6)
	hq_box.add_child(phq_box)
	var phq_title = Label.new()
	phq_title.text = "القيادة"
	phq_title.add_theme_color_override("font_color", Color("#8bd46a"))
	phq_title.add_theme_font_size_override("font_size", 11)
	phq_box.add_child(phq_title)
	player_hp_bar = ProgressBar.new()
	player_hp_bar.custom_minimum_size = Vector2(80, 8)
	player_hp_bar.value = 100
	player_hp_bar.show_percentage = false
	phq_box.add_child(player_hp_bar)
	player_hp_pct_label = Label.new()
	player_hp_pct_label.text = "100%"
	player_hp_pct_label.add_theme_font_size_override("font_size", 10)
	phq_box.add_child(player_hp_pct_label)
	
	var dot_lbl = Label.new()
	dot_lbl.text = "·"
	dot_lbl.add_theme_color_override("font_color", Color("#5e6850"))
	hq_box.add_child(dot_lbl)
	
	# Enemy HQ
	var ehq_box = HBoxContainer.new()
	ehq_box.add_theme_constant_override("separation", 6)
	hq_box.add_child(ehq_box)
	var ehq_title = Label.new()
	ehq_title.text = "قيادة العدو"
	ehq_title.add_theme_color_override("font_color", Color("#ea6862"))
	ehq_title.add_theme_font_size_override("font_size", 11)
	ehq_box.add_child(ehq_title)
	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.custom_minimum_size = Vector2(80, 8)
	enemy_hp_bar.value = 100
	enemy_hp_bar.show_percentage = false
	ehq_box.add_child(enemy_hp_bar)
	enemy_hp_pct_label = Label.new()
	enemy_hp_pct_label.text = "100%"
	enemy_hp_pct_label.add_theme_font_size_override("font_size", 10)
	ehq_box.add_child(enemy_hp_pct_label)

	fps_badge_btn = Button.new()
	fps_badge_btn.text = "[ 120 FPS // 120Hz ]"
	fps_badge_btn.custom_minimum_size = Vector2(136, 28)
	fps_badge_btn.add_theme_font_size_override("font_size", 9)
	var f_style = StyleBoxFlat.new()
	f_style.bg_color = Color(0.08, 0.12, 0.08, 0.95)
	f_style.border_color = Color("#22c55e")
	f_style.border_width_left = 1
	f_style.border_width_right = 1
	f_style.border_width_top = 1
	f_style.border_width_bottom = 2
	f_style.corner_radius_top_left = 3
	f_style.corner_radius_top_right = 3
	f_style.corner_radius_bottom_left = 3
	f_style.corner_radius_bottom_right = 3
	fps_badge_btn.add_theme_stylebox_override("normal", f_style)
	if on_graphics_cb.is_valid():
		fps_badge_btn.pressed.connect(on_graphics_cb)
	top_layout.add_child(fps_badge_btn)

	if on_pause_cb.is_valid():
		var pause_btn = Button.new()
		pause_btn.text = "[ ESC // إيقاف ]"
		pause_btn.custom_minimum_size = Vector2(85, 28)
		pause_btn.add_theme_font_size_override("font_size", 10)
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color(0.12, 0.14, 0.11, 0.95)
		p_style.border_color = Color("#556b2f")
		p_style.border_width_left = 1
		p_style.border_width_right = 1
		p_style.border_width_top = 1
		p_style.border_width_bottom = 2
		p_style.corner_radius_top_left = 3
		p_style.corner_radius_top_right = 3
		p_style.corner_radius_bottom_left = 3
		p_style.corner_radius_bottom_right = 3
		pause_btn.add_theme_stylebox_override("normal", p_style)
		pause_btn.pressed.connect(on_pause_cb)
		top_layout.add_child(pause_btn)

func update(sim) -> void:
	if sim == null or sim.map.is_empty():
		return
		
	# Update Realtime Telemetry Badge (120 FPS / Hz / Preset)
	if fps_badge_btn != null and is_instance_valid(fps_badge_btn):
		var mgr = HardwareDisplayManager.get_instance()
		if not mgr.show_fps_overlay:
			fps_badge_btn.visible = false
		else:
			fps_badge_btn.visible = true
			var fps = Engine.get_frames_per_second()
			var hz_str = "%dHz" % int(round(mgr.hardware_info.get("monitor_hz", 60.0)))
			fps_badge_btn.text = "[ %d FPS // %s %s ]" % [fps, hz_str, mgr.current_preset.to_upper()]
		
	# 1. Update Hero Oil Count
	if oil_num_label != null:
		oil_num_label.text = str(sim.player_oil)
		
	# 2. Update Rigs
	if rigs_val_label != null:
		var owned_rigs = 0
		for r in sim.map["rigs"]:
			if r["owner"] == "player":
				owned_rigs += 1
		rigs_val_label.text = "%d/%d" % [owned_rigs, sim.map["rigs"].size()]
		
	# 3. Update Convoys
	if trucks_val_label != null:
		var trucks_count = 0
		var stranded = 0
		for u in sim.units:
			if u["alive"] and u["faction"] == "player" and u["kind"] == "truck":
				trucks_count += 1
				if u["truckState"] == "stranded":
					stranded += 1
		if stranded > 0:
			trucks_val_label.text = "%d (ALERT: %d STRANDED)" % [trucks_count, stranded]
			trucks_val_label.add_theme_color_override("font_color", Color("#f59e0b"))
		else:
			trucks_val_label.text = str(trucks_count)
			trucks_val_label.add_theme_color_override("font_color", Color("#e9e3d2"))
			
	# 4. Update Bridges
	if bridges_val_label != null:
		var intact = 0
		for b in sim.map["bridges"]:
			if b["status"] == "intact":
				intact += 1
		bridges_val_label.text = "%d/%d" % [intact, sim.map["bridges"].size()]
		bridges_val_label.add_theme_color_override("font_color", Color("#f0a83a") if intact < sim.map["bridges"].size() else Color("#8bd46a"))

	# 5. Update Veterans
	if veterans_val_label != null:
		var vets = 0
		for u in sim.units:
			if u["alive"] and u["faction"] == "player" and u["rank"] > 0:
				vets += 1
		veterans_val_label.text = str(vets)
		if veterans_container != null:
			veterans_container.visible = vets > 0
			
	# 6. Update HQs HP Bars
	var phq = sim.map["playerHQ"]
	var ehq = sim.map["enemyHQ"]
	var p_pct = int(round((phq["hp"] / phq["maxHp"]) * 100.0))
	var e_pct = int(round((ehq["hp"] / ehq["maxHp"]) * 100.0))
	if player_hp_bar != null:
		player_hp_bar.value = p_pct
	if player_hp_pct_label != null:
		player_hp_pct_label.text = "%d%%" % p_pct
	if enemy_hp_bar != null:
		enemy_hp_bar.value = e_pct
	if enemy_hp_pct_label != null:
		enemy_hp_pct_label.text = "%d%%" % e_pct

	# 7. Update Combat Momentum
	if momentum_bar != null:
		momentum_bar.value = sim.combat_momentum
		if sim.combat_surge_active:
			momentum_label.text = "[ TACTICAL SURGE ACTIVE // عاصفة القتال: +20% DMG ]"
			momentum_label.add_theme_color_override("font_color", Color("#fbbf24"))
		else:
			momentum_label.text = "[ COMBAT MOMENTUM // زحف الحماسة: %d%% ]" % int(round(sim.combat_momentum))
			momentum_label.add_theme_color_override("font_color", Color("#f59e0b"))
