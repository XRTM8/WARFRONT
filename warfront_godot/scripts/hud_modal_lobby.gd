class_name HUDModalLobby
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const HUDModalCommon = preload("res://scripts/hud_modal_common.gd")

static func build_match_setup_modal(
	parent_canvas: CanvasLayer,
	initial_theater: String,
	initial_mode: String,
	initial_faction: String,
	on_match_start: Callable,
	on_back: Callable
) -> Dictionary:
	var state = {
		"theater": initial_theater,
		"mode": initial_mode,
		"faction": initial_faction
	}
	
	var match_setup_panel = PanelContainer.new()
	match_setup_panel.set_anchors_preset(Control.PRESET_CENTER)
	match_setup_panel.custom_minimum_size = Vector2(500, 420)
	match_setup_panel.position = Vector2(-250, -210)
	
	var style = HUDModalCommon.create_military_panel_style()
	match_setup_panel.add_theme_stylebox_override("panel", style)
	match_setup_panel.visible = false
	parent_canvas.add_child(match_setup_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	match_setup_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "[ MATCH SETUP // إعداد غرفة العمليات وتحديد الفرق ]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#38bdf8"))
	title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Summary readout
	var summary_lbl = Label.new()
	summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_lbl.add_theme_color_override("font_color", Color("#facc15"))
	summary_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(summary_lbl)
	
	var update_summary = func():
		var m_name = Constants.MATCH_PRESETS.get(state["mode"], {}).get("name", state["mode"])
		var th_name = Constants.THEATER_CONFIGS.get(state["theater"], {}).get("name", state["theater"])
		var f_name = "Coalition Vanguard" if state["faction"] == "vanguard" else "Desert Raiders"
		summary_lbl.text = "[ CONFIG // %s | %s | %s ]" % [m_name, th_name, f_name]
	update_summary.call()

	# Section 1: Mode Selection
	var mode_hdr = Label.new()
	mode_hdr.text = "[ 1. ALLIANCE MODE // نظام التحالف والاشتباك ]"
	mode_hdr.add_theme_color_override("font_color", Color("#94a3b8"))
	mode_hdr.add_theme_font_size_override("font_size", 9)
	vbox.add_child(mode_hdr)
	
	var mode_hbox = HBoxContainer.new()
	mode_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(mode_hbox)
	
	var modes = [
		{ "id": "2v2", "label": "2v2 Team Alliance" },
		{ "id": "ffa", "label": "4-Way FFA" },
		{ "id": "1v1", "label": "1v1 Classic" },
		{ "id": "1v3", "label": "1v3 Survival" }
	]
	
	var mode_buttons: Array[Button] = []
	for m in modes:
		var btn = Button.new()
		btn.text = m["label"]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 9)
		var m_id = m["id"]
		btn.pressed.connect(func():
			state["mode"] = m_id
			if m_id in ["2v2", "ffa", "1v3"] and state["theater"] == "kirkuk":
				state["theater"] = "basra"
			for b in mode_buttons:
				b.add_theme_color_override("font_color", Color("#a1a1aa"))
			btn.add_theme_color_override("font_color", Color("#38bdf8"))
			update_summary.call()
		)
		mode_buttons.push_back(btn)
		mode_hbox.add_child(btn)
	mode_buttons[0].add_theme_color_override("font_color", Color("#38bdf8"))

	# Section 2: Theater / Map Size Selection
	var th_hdr = Label.new()
	th_hdr.text = "[ 2. THEATER MAP // مسرح العمليات وحجم الخريطة ]"
	th_hdr.add_theme_color_override("font_color", Color("#94a3b8"))
	th_hdr.add_theme_font_size_override("font_size", 9)
	vbox.add_child(th_hdr)
	
	var th_hbox = HBoxContainer.new()
	th_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(th_hbox)
	
	var theaters = [
		{ "id": "basra", "label": "Basra Delta (4800x2880)" },
		{ "id": "zagros", "label": "Zagros Pass (4800x2880)" },
		{ "id": "kirkuk", "label": "Kirkuk (3456x1920)" }
	]
	
	var th_buttons: Array[Button] = []
	for t in theaters:
		var btn = Button.new()
		btn.text = t["label"]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 9)
		var t_id = t["id"]
		btn.pressed.connect(func():
			state["theater"] = t_id
			for b in th_buttons:
				b.add_theme_color_override("font_color", Color("#a1a1aa"))
			btn.add_theme_color_override("font_color", Color("#22c55e"))
			update_summary.call()
		)
		th_buttons.push_back(btn)
		th_hbox.add_child(btn)
	th_buttons[0].add_theme_color_override("font_color", Color("#22c55e"))

	# Section 3: Faction Doctrine
	var fac_hdr = Label.new()
	fac_hdr.text = "[ 3. OPERATING FACTION // عقيدة القوات الميدانية ]"
	fac_hdr.add_theme_color_override("font_color", Color("#94a3b8"))
	fac_hdr.add_theme_font_size_override("font_size", 9)
	vbox.add_child(fac_hdr)
	
	var fac_hbox = HBoxContainer.new()
	fac_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(fac_hbox)
	
	var factions = [
		{ "id": "vanguard", "label": "Coalition Vanguard (Heavy Armor / Air)" },
		{ "id": "raiders", "label": "Desert Raiders (Speed Flanking / High RoF)" }
	]
	
	var fac_buttons: Array[Button] = []
	for f in factions:
		var btn = Button.new()
		btn.text = f["label"]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 9)
		var f_id = f["id"]
		btn.pressed.connect(func():
			state["faction"] = f_id
			for b in fac_buttons:
				b.add_theme_color_override("font_color", Color("#a1a1aa"))
			btn.add_theme_color_override("font_color", Color("#f97316"))
			update_summary.call()
		)
		fac_buttons.push_back(btn)
		fac_hbox.add_child(btn)
	fac_buttons[0].add_theme_color_override("font_color", Color("#f97316"))

	vbox.add_child(HSeparator.new())
	
	# Action buttons
	var deploy_btn = HUDModalCommon.create_menu_button("[ DEPLOY OPERATION // بدء نشر القوات والاشتباك ]", Color("#4ade80"), 38.0)
	deploy_btn.pressed.connect(func():
		on_match_start.call(state["theater"], state["mode"], state["faction"])
	)
	vbox.add_child(deploy_btn)
	
	var back_to_pause_btn = HUDModalCommon.create_menu_button("[ BACK // رجوع إلى القائمة الرئيسية ]", Color("#a1a1aa"))
	back_to_pause_btn.pressed.connect(on_back)
	vbox.add_child(back_to_pause_btn)
	
	return {
		"panel": match_setup_panel,
		"state": state
	}
