class_name HUDModal
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

var parent_canvas: CanvasLayer = null
var pause_panel: PanelContainer = null
var debrief_panel: PanelContainer = null
var theater_panel: PanelContainer = null
var help_panel: PanelContainer = null

var is_paused: bool = false
var audio_muted: bool = false

var on_resume: Callable
var on_restart: Callable
var on_theater_selected: Callable
var on_toggle_audio: Callable

func setup(
	canvas: CanvasLayer,
	resume_cb: Callable,
	restart_cb: Callable,
	theater_cb: Callable,
	audio_cb: Callable
) -> void:
	parent_canvas = canvas
	on_resume = resume_cb
	on_restart = restart_cb
	on_theater_selected = theater_cb
	on_toggle_audio = audio_cb
	
	_build_pause_modal()
	_build_debrief_modal()
	_build_theater_modal()
	_build_help_modal()

func toggle_pause() -> void:
	is_paused = not is_paused
	pause_panel.visible = is_paused
	if not is_paused:
		theater_panel.visible = false
		help_panel.visible = false

func show_debrief(sim) -> void:
	if debrief_panel == null or sim == null:
		return
	is_paused = true
	debrief_panel.visible = true
	_update_debrief_stats(sim)

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

# ------------------------------------------------------------------------------
# 1. Tactical Pause Modal
# ------------------------------------------------------------------------------

func _build_pause_modal() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.custom_minimum_size = Vector2(340, 380)
	pause_panel.position = Vector2(-170, -190)
	
	var style = _create_military_panel_style()
	pause_panel.add_theme_stylebox_override("panel", style)
	pause_panel.visible = false
	parent_canvas.add_child(pause_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	pause_panel.add_child(vbox)
	
	# Header
	var title = Label.new()
	title.text = "⏸️ غرفة العمليات التكتيكية"
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
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Buttons
	var resume_btn = _create_menu_button("▶ استئناف المعركة", Color("#73d65e"))
	resume_btn.pressed.connect(func():
		toggle_pause()
		if on_resume.is_valid():
			on_resume.call()
	)
	vbox.add_child(resume_btn)
	
	var restart_btn = _create_menu_button("[ RESTART // إعادة تشغيل العملية ]", Color("#fde047"))
	restart_btn.pressed.connect(func():
		hide_all()
		if on_restart.is_valid():
			on_restart.call()
	)
	vbox.add_child(restart_btn)
	
	var theater_btn = _create_menu_button("[ THEATER // اختيار مسرح العمليات ]", Color("#38bdf8"))
	theater_btn.pressed.connect(func():
		pause_panel.visible = false
		theater_panel.visible = true
	)
	vbox.add_child(theater_btn)
	
	var help_btn = _create_menu_button("[ MANUAL // دليل التحكم الميداني ]", Color("#e4e4e7"))
	help_btn.pressed.connect(func():
		pause_panel.visible = false
		help_panel.visible = true
	)
	vbox.add_child(help_btn)
	
	var audio_btn = _create_menu_button("[ AUDIO // نظام الصوت الميداني ]", Color("#a1a1aa"))
	audio_btn.pressed.connect(func():
		audio_muted = not audio_muted
		audio_btn.text = "[ AUDIO: MUTED // الصوت معطل ]" if audio_muted else "[ AUDIO: ACTIVE // الصوت مفعل ]"
		if on_toggle_audio.is_valid():
			on_toggle_audio.call(audio_muted)
	)
	vbox.add_child(audio_btn)

# ------------------------------------------------------------------------------
# 2. Mission Debriefing (Victory / Defeat Modal)
# ------------------------------------------------------------------------------

var debrief_title_label: Label = null
var debrief_status_label: Label = null
var debrief_stats_vbox: VBoxContainer = null

func _build_debrief_modal() -> void:
	debrief_panel = PanelContainer.new()
	debrief_panel.set_anchors_preset(Control.PRESET_CENTER)
	debrief_panel.custom_minimum_size = Vector2(400, 420)
	debrief_panel.position = Vector2(-200, -210)
	
	var style = _create_military_panel_style()
	debrief_panel.add_theme_stylebox_override("panel", style)
	debrief_panel.visible = false
	parent_canvas.add_child(debrief_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	debrief_panel.add_child(vbox)
	
	debrief_title_label = Label.new()
	debrief_title_label.text = "تقرير انتهاء المعركة"
	debrief_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debrief_title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(debrief_title_label)
	
	debrief_status_label = Label.new()
	debrief_status_label.text = ""
	debrief_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debrief_status_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(debrief_status_label)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	debrief_stats_vbox = VBoxContainer.new()
	debrief_stats_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(debrief_stats_vbox)
	
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	var play_again_btn = _create_menu_button("[ DEPLOY AGAIN // خوض المعركة مجدداً ]", Color("#73d65e"))
	play_again_btn.pressed.connect(func():
		hide_all()
		if on_restart.is_valid():
			on_restart.call()
	)
	vbox.add_child(play_again_btn)
	
	var change_th_btn = _create_menu_button("[ CHANGE THEATER // مسرح عمليات آخر ]", Color("#38bdf8"))
	change_th_btn.pressed.connect(func():
		debrief_panel.visible = false
		theater_panel.visible = true
	)
	vbox.add_child(change_th_btn)

func _update_debrief_stats(sim) -> void:
	for c in debrief_stats_vbox.get_children():
		c.queue_free()
		
	var is_vic = sim.outcome == "victory"
	if is_vic:
		debrief_title_label.text = "[ VICTORY // انتصار حاسم ]"
		debrief_title_label.add_theme_color_override("font_color", Color("#73d65e"))
		debrief_status_label.text = "تم سحق قيادة العدو وتأمين السيطرة التامة على المنشآت النفطية!"
		debrief_status_label.add_theme_color_override("font_color", Color("#a3e635"))
	else:
		debrief_title_label.text = "[ DEFEAT // انتكاسة تكتيكية ]"
		debrief_title_label.add_theme_color_override("font_color", Color("#ef4444"))
		debrief_status_label.text = "تم اختراق وتدمير المقر القيادي لقواتك وسقوط قطاع النفط!"
		debrief_status_label.add_theme_color_override("font_color", Color("#fca5a5"))
		
	var mins = int(sim.elapsed_seconds / 60.0)
	var secs = int(fmod(sim.elapsed_seconds, 60.0))
	var time_str = "%02d:%02d" % [mins, secs]
	
	var owned_rigs = 0
	for r in sim.map.get("rigs", []):
		if r["owner"] == "player":
			owned_rigs += 1
			
	var player_kills = 0
	var player_vets = 0
	for u in sim.units:
		if u["faction"] == "player":
			player_kills += u["kills"]
			if u["rank"] > 0:
				player_vets += 1
				
	var stat_rows = [
		{ "label": "[TIME] مدة الاشتباك", "val": time_str },
		{ "label": "[SUPPLY] إجمالي الوقود المستخرج", "val": "%d BBL" % sim.player_oil_delivered },
		{ "label": "[HOSTILES] آليات العدو المدمرة", "val": "%d آليات" % player_kills },
		{ "label": "[CONVOYS] قوافل العدو المعترضة", "val": "%d شاحنات" % sim.enemy_trucks_destroyed },
		{ "label": "[OILFIELDS] حقول النفط المحررة", "val": "%d / %d آبار" % [owned_rigs, sim.map.get("rigs", []).size()] },
		{ "label": "[BRIDGES] الجسور المفجرة والمرممة", "val": "%d جسور" % sim.bridges_destroyed_by_player },
		{ "label": "[OFFICERS] الضباط والمخضرمون", "val": "%d رتب نخبة" % player_vets }
	]
	
	for row in stat_rows:
		var hbox = HBoxContainer.new()
		var l_lbl = Label.new()
		l_lbl.text = row["label"]
		l_lbl.add_theme_color_override("font_color", Color("#b5ac94"))
		l_lbl.add_theme_font_size_override("font_size", 10)
		hbox.add_child(l_lbl)
		
		var sp = Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(sp)
		
		var v_lbl = Label.new()
		v_lbl.text = row["val"]
		v_lbl.add_theme_color_override("font_color", Color("#f4f4f5"))
		v_lbl.add_theme_font_size_override("font_size", 10)
		hbox.add_child(v_lbl)
		debrief_stats_vbox.add_child(hbox)

# ------------------------------------------------------------------------------
# 3. Theater Selection Modal
# ------------------------------------------------------------------------------

func _build_theater_modal() -> void:
	theater_panel = PanelContainer.new()
	theater_panel.set_anchors_preset(Control.PRESET_CENTER)
	theater_panel.custom_minimum_size = Vector2(460, 360)
	theater_panel.position = Vector2(-230, -180)
	
	var style = _create_military_panel_style()
	theater_panel.add_theme_stylebox_override("panel", style)
	theater_panel.visible = false
	parent_canvas.add_child(theater_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	theater_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "[ THEATERS // اختيار مسرح العمليات الاستراتيجي ]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#38bdf8"))
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var theaters = [
		{
			"id": "kirkuk",
			"name": "مسرح كركوك (Kirkuk Oilfields)",
			"desc": "صحراء شاسعة، ثروة نفطية ضخمة، نهر عريض مع 4 جسور استراتيجية ومخاضات وعرة.",
			"color": Color("#eab308")
		},
		{
			"id": "suez",
			"name": "مسرح قناة السويس (Suez Canal)",
			"desc": "ممر مائي بحري محوري، جسور متحركة حاسمة، وتنافس شرس على خطوط الإمداد الساحلية.",
			"color": Color("#38bdf8")
		},
		{
			"id": "newyork",
			"name": "مسرح نيو يورك (New York Front)",
			"desc": "أرصفة خرسانية ومضايق نهرية متفرعة، قتال شوارع مكثف وسرعة اشتباك عالية.",
			"color": Color("#a3e635")
		}
	]
	
	for th in theaters:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 64)
		btn.text = "%s\n%s" % [th["name"], th["desc"]]
		btn.add_theme_font_size_override("font_size", 9)
		var th_id = th["id"]
		btn.pressed.connect(func():
			hide_all()
			if on_theater_selected.is_valid():
				on_theater_selected.call(th_id)
		)
		vbox.add_child(btn)
		
	var back_btn = _create_menu_button("رجوع إلى القائمة", Color("#a1a1aa"))
	back_btn.pressed.connect(func():
		theater_panel.visible = false
		pause_panel.visible = true
	)
	vbox.add_child(back_btn)

# ------------------------------------------------------------------------------
# 4. Controls Field Manual Modal
# ------------------------------------------------------------------------------

func _build_help_modal() -> void:
	help_panel = PanelContainer.new()
	help_panel.set_anchors_preset(Control.PRESET_CENTER)
	help_panel.custom_minimum_size = Vector2(440, 360)
	help_panel.position = Vector2(-220, -180)
	
	var style = _create_military_panel_style()
	help_panel.add_theme_stylebox_override("panel", style)
	help_panel.visible = false
	parent_canvas.add_child(help_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	help_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "[ FIELD MANUAL // دليل العمليات الميدانية ]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#ffd659"))
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var tips = [
		"[L-CLICK] زر الفأرة الأيسر: سحب لتحديد مجموعة قوات، أو النقر على جسر مدمر لإصلاحه.",
		"[R-CLICK] زر الفأرة الأيمن: أمر تحرك تكتيكي، أمر هجوم مباشر، أو توجيه متعاقب بالـ Shift.",
		"[KEYS 1-7] تدريب ونشر القوات والدبابات والمروحيات والمنشآت الميدانية.",
		"[KEY B] إصلاح أسرع جسر مدمر لاستعادة تدفق قوافل شاحنات النفط.",
		"[KEY Q] تحديد كافة القوات المقاتلة في الميدان بضغطة واحدة.",
		"[KEY H] توجيه الكاميرا فوراً إلى مقر القيادة العامة.",
		"[KEYS F / T] تفعيل قدرات الوحدات النخبة (قذيفة حارقة، صدمة زلزالية، صواريخ، ألغام).",
		"[PAN / ZOOM] عجلة الفأرة وأزرار W A S D للتحريك وزوم الرؤية التكتيكية.",
		"[KEY ESC] إيقاف المعركة مؤقتاً والوصول إلى لوحة التحكم والعمليات."
	]
	
	for tip in tips:
		var lbl = Label.new()
		lbl.text = tip
		lbl.add_theme_color_override("font_color", Color("#e4e4e7"))
		lbl.add_theme_font_size_override("font_size", 9)
		vbox.add_child(lbl)
		
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	var back_btn = _create_menu_button("رجوع إلى القائمة", Color("#a1a1aa"))
	back_btn.pressed.connect(func():
		help_panel.visible = false
		pause_panel.visible = true
	)
	vbox.add_child(back_btn)

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

func _create_military_panel_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.07, 0.09, 0.06, 0.98)
	s.border_color = Color("#48533b")
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 3
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	return s

func _create_menu_button(text: String, col: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 32)
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", col)
	return btn
