class_name HUDModal
extends RefCounted

const HUDModalCommon = preload("res://scripts/hud_modal_common.gd")
const HUDModalDebrief = preload("res://scripts/hud_modal_debrief.gd")
const HUDModalManual = preload("res://scripts/hud_modal_manual.gd")
const HUDModalLobby = preload("res://scripts/hud_modal_lobby.gd")

var parent_canvas: CanvasLayer = null
var pause_panel: PanelContainer = null
var debrief_panel: PanelContainer = null
var theater_panel: PanelContainer = null
var help_panel: PanelContainer = null
var match_setup_panel: PanelContainer = null

var is_paused: bool = false
var audio_muted: bool = false

var selected_theater: String = "basra"
var selected_mode: String = "2v2"
var selected_faction: String = "vanguard"

var on_resume: Callable
var on_restart: Callable
var on_theater_selected: Callable
var on_toggle_audio: Callable
var on_match_start: Callable

var _debrief_dict: Dictionary = {}
var _lobby_dict: Dictionary = {}

func setup(
	canvas: CanvasLayer,
	resume_cb: Callable,
	restart_cb: Callable,
	theater_cb: Callable,
	audio_cb: Callable,
	match_cb: Callable = Callable()
) -> void:
	parent_canvas = canvas
	on_resume = resume_cb
	on_restart = restart_cb
	on_theater_selected = theater_cb
	on_toggle_audio = audio_cb
	on_match_start = match_cb
	
	_build_pause_modal()
	
	_debrief_dict = HUDModalDebrief.build_debrief_modal(
		parent_canvas,
		func():
			hide_all()
			if on_restart.is_valid():
				on_restart.call(),
		func():
			if debrief_panel != null:
				debrief_panel.visible = false
			if theater_panel != null:
				theater_panel.visible = true
	)
	debrief_panel = _debrief_dict["panel"]
	
	theater_panel = HUDModalManual.build_theater_modal(
		parent_canvas,
		func(th_id: String):
			hide_all()
			if on_theater_selected.is_valid():
				on_theater_selected.call(th_id),
		func():
			if theater_panel != null:
				theater_panel.visible = false
			if pause_panel != null:
				pause_panel.visible = true
	)
	
	help_panel = HUDModalManual.build_help_modal(
		parent_canvas,
		func():
			if help_panel != null:
				help_panel.visible = false
			if pause_panel != null:
				pause_panel.visible = true
	)
	
	_lobby_dict = HUDModalLobby.build_match_setup_modal(
		parent_canvas,
		selected_theater,
		selected_mode,
		selected_faction,
		func(th: String, mode: String, fac: String):
			hide_all()
			selected_theater = th
			selected_mode = mode
			selected_faction = fac
			if on_match_start.is_valid():
				on_match_start.call(th, mode, fac),
		func():
			if match_setup_panel != null:
				match_setup_panel.visible = false
			if pause_panel != null:
				pause_panel.visible = true
	)
	match_setup_panel = _lobby_dict["panel"]

func toggle_pause() -> void:
	is_paused = not is_paused
	if pause_panel != null:
		pause_panel.visible = is_paused
	if not is_paused:
		if theater_panel != null:
			theater_panel.visible = false
		if help_panel != null:
			help_panel.visible = false
		if match_setup_panel != null:
			match_setup_panel.visible = false

func show_debrief(sim) -> void:
	if debrief_panel == null or sim == null:
		return
	is_paused = true
	debrief_panel.visible = true
	HUDModalDebrief.update_debrief_stats(sim, _debrief_dict)

func hide_all() -> void:
	is_paused = false
	if pause_panel != null:
		pause_panel.visible = false
	if debrief_panel != null:
		debrief_panel.visible = false
	if theater_panel != null:
		theater_panel.visible = false
	if help_panel != null:
		help_panel.visible = false
	if match_setup_panel != null:
		match_setup_panel.visible = false

func _build_pause_modal() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.custom_minimum_size = Vector2(340, 380)
	pause_panel.position = Vector2(-170, -190)
	
	var style = HUDModalCommon.create_military_panel_style()
	pause_panel.add_theme_stylebox_override("panel", style)
	pause_panel.visible = false
	parent_canvas.add_child(pause_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	pause_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "[ OPERATIONS COMMAND // غرفة العمليات التكتيكية ]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#ffd659"))
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "[ المعركة متوقفة مؤقتاً // TACTICAL PAUSE ]"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("#8e9681"))
	subtitle.add_theme_font_size_override("font_size", 9)
	vbox.add_child(subtitle)
	
	vbox.add_child(HSeparator.new())
	
	var resume_btn = HUDModalCommon.create_menu_button("[ RESUME // استئناف المعركة ]", Color("#73d65e"))
	resume_btn.pressed.connect(func():
		toggle_pause()
		if on_resume.is_valid():
			on_resume.call()
	)
	vbox.add_child(resume_btn)

	var match_setup_btn = HUDModalCommon.create_menu_button("[ MATCH SETUP // إعداد معركة مخصصة وتحديد الفرق ]", Color("#38bdf8"))
	match_setup_btn.pressed.connect(func():
		pause_panel.visible = false
		if match_setup_panel != null:
			match_setup_panel.visible = true
	)
	vbox.add_child(match_setup_btn)
	
	var restart_btn = HUDModalCommon.create_menu_button("[ RESTART // إعادة تشغيل العملية ]", Color("#fde047"))
	restart_btn.pressed.connect(func():
		hide_all()
		if on_restart.is_valid():
			on_restart.call()
	)
	vbox.add_child(restart_btn)
	
	var theater_btn = HUDModalCommon.create_menu_button("[ THEATER // اختيار مسرح العمليات ]", Color("#38bdf8"))
	theater_btn.pressed.connect(func():
		pause_panel.visible = false
		theater_panel.visible = true
	)
	vbox.add_child(theater_btn)
	
	var help_btn = HUDModalCommon.create_menu_button("[ MANUAL // دليل التحكم الميداني ]", Color("#e4e4e7"))
	help_btn.pressed.connect(func():
		pause_panel.visible = false
		help_panel.visible = true
	)
	vbox.add_child(help_btn)
	
	var audio_btn = HUDModalCommon.create_menu_button("[ AUDIO // نظام الصوت الميداني ]", Color("#a1a1aa"))
	audio_btn.pressed.connect(func():
		audio_muted = not audio_muted
		audio_btn.text = "[ AUDIO: MUTED // الصوت معطل ]" if audio_muted else "[ AUDIO: ACTIVE // الصوت مفعل ]"
		if on_toggle_audio.is_valid():
			on_toggle_audio.call(audio_muted)
	)
	vbox.add_child(audio_btn)
