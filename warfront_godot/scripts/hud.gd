class_name GameHUD
extends CanvasLayer

const Simulation = preload("res://scripts/simulation.gd")
const Constants = preload("res://scripts/constants.gd")
const HUDTopBar = preload("res://scripts/hud_top_bar.gd")
const HUDDossier = preload("res://scripts/hud_dossier.gd")
const HUDActionBar = preload("res://scripts/hud_action_bar.gd")
const HUDMinimap = preload("res://scripts/hud_minimap.gd")
const HUDModal = preload("res://scripts/hud_modal.gd")
const HUDCommanderBar = preload("res://scripts/hud_commander_bar.gd")

signal train_requested(kind: String)
signal bridge_rebuild_requested()
signal select_all_requested()
signal center_hq_requested()
signal minimap_pan_requested(world_pos: Vector2)
signal restart_requested()
signal theater_change_requested(theater_id: String)
signal audio_toggle_requested(muted: bool)
signal pause_toggled()
signal commander_power_requested(power_id: String)
signal place_structure_requested(kind: String)

var sim: Simulation = null

var top_bar: HUDTopBar = HUDTopBar.new()
var dossier: HUDDossier = HUDDossier.new()
var action_bar: HUDActionBar = HUDActionBar.new()
var commander_bar: HUDCommanderBar = HUDCommanderBar.new()
var minimap: HUDMinimap = HUDMinimap.new()
var modal: HUDModal = HUDModal.new()
var minimap_control: Control = null

var banner_panel: PanelContainer = null
var banner_label: Label = null
var banner_timer: float = 0.0

func setup(simulation: Simulation) -> void:
	sim = simulation
	sim.event_pushed.connect(_on_event_pushed)
	build_tactical_hud()

func _on_event_pushed(key: String, _tone: String) -> void:
	var arabic_events = {
		"rig_captured": "تمت السيطرة على حقل نفط!",
		"rig_lost": "تحذير: العدو استولى على حقل نفط!",
		"bridge_destroyed": "تم تفجير الجسر! انقطعت إمدادات العدو",
		"bridge_rebuilt": "تم إصلاح الجسر واستعادة خط الإمداد",
		"truck_ambushed": "كمين ناجح: تم تدمير شاحنة إمداد للعدو!",
		"unit_promoted": "ترقية وحدة إلى رتبة متقدمة!",
		"not_enough_oil": "احتياطي النفط غير كافٍ!",
		"power_on_cooldown": "القدرة التكتيكية قيد الإعداد والتجهيز!",
		"airstrike_inbound": "غارة جوية نفاثة خارقة في طريقها للهدف!",
		"barrage_firing": "قصف مدفعي تمهيدي كثيف ينهال على الهدف!",
		"recon_active": "مسح استطلاع راداري نشط في المنطقة!",
		"supply_dropped": "تم إسقاط براميل إمداد عاجلة بالمظلات!",
		"salvage_collected": "تم جمع غنائم نفط خام وإضافتها للاحتياطي!",
		"directive_assigned": "أوامر تكتيكية جديدة صادرة من القيادة!",
		"directive_complete": "إنجاز المهمة التكتيكية! تم صرف مكافأة النفط",
		"phase_escalation": "تحذير: تصعيد المعركة! العدو ينشر قواته الهجومية",
		"phase_total_war": "إنذار أحمر: دخول مرحلة الاشتباك الشامل والحسم!",
		"invalid_placement": "موقع غير صالح للإنشاء! يجب البناء داخل نطاق القاعدة بعيداً عن العوائق",
		"structure_placed": "بدء أعمال التدعيم والإنشاء في الموقع المحدد!",
		"structure_ready": "اكتمل البناء! المنشأة الهندسية دخلت الخدمة العملياتية فوراً",
		"victory": "انتصار حاسم! سقط المقر القيادي للعدو",
		"defeat": "هزيمة! تدمر المقر القيادي لقواتك"
	}
	var msg = arabic_events.get(key, key.replace("_", " ").to_upper())
	if banner_panel != null and banner_label != null:
		banner_label.text = "⚡ [ إشعار تكتيكي ]  " + msg
		banner_panel.visible = true
		banner_timer = 3.5

func _process(delta: float) -> void:
	if banner_timer > 0.0:
		banner_timer -= delta
		if banner_timer <= 0.0 and banner_panel != null:
			banner_panel.visible = false
			
	if sim == null or sim.map.is_empty():
		return
		
	# Check Mission Debriefing trigger on victory/defeat
	if sim.phase == "gameover" and modal.debrief_panel != null and not modal.debrief_panel.visible:
		modal.show_debrief(sim)

	top_bar.update(sim)
	action_bar.update(sim)
	commander_bar.update(sim)
	dossier.update(sim)
	
	if minimap_control != null:
		minimap_control.queue_redraw()

func toggle_pause() -> void:
	modal.toggle_pause()
	pause_toggled.emit()

func build_tactical_hud() -> void:
	# 1. Top Bar
	top_bar.build_top_bar(self, func(): toggle_pause())

	# 2. Event Notification Banner (Tactical Toast Badge)
	var banner_container = PanelContainer.new()
	banner_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_container.position = Vector2(-200, 52)
	banner_container.custom_minimum_size = Vector2(400, 32)
	var ban_style = StyleBoxFlat.new()
	ban_style.bg_color = Color(0.07, 0.09, 0.06, 0.94)
	ban_style.border_color = Color("#eab308")
	ban_style.border_width_left = 2
	ban_style.border_width_right = 2
	ban_style.border_width_top = 1
	ban_style.border_width_bottom = 1
	ban_style.corner_radius_top_left = 3
	ban_style.corner_radius_top_right = 3
	ban_style.corner_radius_bottom_left = 3
	ban_style.corner_radius_bottom_right = 3
	ban_style.content_margin_left = 12
	ban_style.content_margin_right = 12
	ban_style.content_margin_top = 4
	ban_style.content_margin_bottom = 4
	banner_container.add_theme_stylebox_override("panel", ban_style)
	banner_container.visible = false
	add_child(banner_container)
	banner_panel = banner_container

	banner_label = Label.new()
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_color_override("font_color", Color("#fef08a"))
	banner_label.add_theme_font_size_override("font_size", 12)
	banner_container.add_child(banner_label)

	# 3. Bottom Dock Area
	var bottom_margin = MarginContainer.new()
	bottom_margin.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom_margin.add_theme_constant_override("margin_left", 12)
	bottom_margin.add_theme_constant_override("margin_right", 12)
	bottom_margin.add_theme_constant_override("margin_bottom", 10)
	add_child(bottom_margin)
	
	var bottom_layout = HBoxContainer.new()
	bottom_layout.alignment = BoxContainer.ALIGNMENT_BEGIN
	bottom_layout.add_theme_constant_override("separation", 8)
	bottom_margin.add_child(bottom_layout)

	# Left Tactical Deck (Commander Powers Tray above Unit Action Cards)
	var left_deck = VBoxContainer.new()
	left_deck.add_theme_constant_override("separation", 6)
	bottom_layout.add_child(left_deck)

	# Commander Powers & Directives Tray
	commander_bar.build_commander_bar(
		left_deck,
		func(pow_id: String): commander_power_requested.emit(pow_id)
	)

	# Action Cards Dock
	action_bar.build_action_bar(
		left_deck,
		func(kind: String): train_requested.emit(kind),
		func(): bridge_rebuild_requested.emit(),
		func(kind: String): place_structure_requested.emit(kind)
	)

	# Spacer
	var bot_spacer = Control.new()
	bot_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_layout.add_child(bot_spacer)

	# Tactical Dossier Card
	dossier.build_dossier(bottom_layout)

	# Interactive Tactical Minimap Frame
	minimap_control = minimap.build_minimap(
		bottom_layout,
		func(): select_all_requested.emit(),
		func(): center_hq_requested.emit()
	)
	minimap_control.draw.connect(_on_minimap_draw)
	minimap_control.gui_input.connect(_on_minimap_input)

	# 4. Tactical Operations Modal (Pause, Debriefing, Theater, Field Manual)
	modal.setup(
		self,
		func(): pause_toggled.emit(),
		func(): restart_requested.emit(),
		func(th_id: String): theater_change_requested.emit(th_id),
		func(muted: bool): audio_toggle_requested.emit(muted)
	)

func _on_minimap_draw() -> void:
	if sim == null or sim.map.is_empty():
		return
	var cam = get_viewport().get_camera_2d() if get_viewport() != null else null
	var vp_size = get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(1280, 720)
	HUDMinimap.draw_minimap(minimap_control, sim, cam, vp_size)

func _on_minimap_input(event: InputEvent) -> void:
	if sim == null or sim.map.is_empty():
		return
	HUDMinimap.handle_input(event, sim.map, func(pos: Vector2): minimap_pan_requested.emit(pos))
