class_name HUDModalGraphics
extends RefCounted

const HUDModalCommon = preload("res://scripts/hud_modal_common.gd")
const HardwareDisplayManager = preload("res://scripts/hardware_display_manager.gd")

static func build_graphics_modal(parent_canvas: CanvasLayer, on_back: Callable) -> PanelContainer:
	var mgr = HardwareDisplayManager.get_instance()
	var info = mgr.hardware_info
	
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(490, 480)
	panel.position = Vector2(-245, -240)
	
	var style = HUDModalCommon.create_military_panel_style()
	panel.add_theme_stylebox_override("panel", style)
	panel.visible = false
	parent_canvas.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "[ DISPLAY & 120Hz // عتاد الرسوميات ومعدل الإطارات ]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#38bdf8"))
	title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title)
	
	# Hardware Telemetry Banner
	var hw_banner = PanelContainer.new()
	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color(0.08, 0.10, 0.08, 0.95)
	b_style.border_color = Color("#22c55e")
	b_style.border_width_left = 2
	b_style.content_margin_left = 10
	b_style.content_margin_top = 6
	b_style.content_margin_bottom = 6
	hw_banner.add_theme_stylebox_override("panel", b_style)
	vbox.add_child(hw_banner)
	
	var hw_label = Label.new()
	var gpu_txt = info.get("gpu_name", "GPU")
	var hz_txt = "%dHz" % int(round(info.get("monitor_hz", 60.0)))
	var res_txt = "%dx%d" % [info.get("screen_size", Vector2i(1280, 720)).x, info.get("screen_size", Vector2i(1280, 720)).y]
	hw_label.text = "GPU: %s\nSCREEN: %s @ %s | CPU: %d CORES [TIER: %s]" % [
		gpu_txt, res_txt, hz_txt, info.get("cpu_cores", 4), info.get("device_tier", "HIGH").to_upper()
	]
	hw_label.add_theme_font_size_override("font_size", 9)
	hw_label.add_theme_color_override("font_color", Color("#4ade80"))
	hw_banner.add_child(hw_label)
	
	# Auto Calibrate Button
	var auto_btn = HUDModalCommon.create_menu_button("[ AUTO-CALIBRATE // ضبط تلقائي ذكي حسب العتاد والشاشة ]", Color("#22c55e"), 30.0)
	auto_btn.pressed.connect(func():
		mgr.auto_detect_and_apply()
	)
	vbox.add_child(auto_btn)
	vbox.add_child(HSeparator.new())
	
	# 1. Target Framerate Row (120 FPS / Hz)
	var fps_title = Label.new()
	fps_title.text = "TARGET FRAMERATE // معدل الإطارات المستهدف:"
	fps_title.add_theme_font_size_override("font_size", 10)
	fps_title.add_theme_color_override("font_color", Color("#fbbf24"))
	vbox.add_child(fps_title)
	
	var fps_box = HBoxContainer.new()
	fps_box.add_theme_constant_override("separation", 6)
	vbox.add_child(fps_box)
	
	var fps_options = [
		{ "label": "60 FPS", "val": 60 },
		{ "label": "120 FPS", "val": 120 },
		{ "label": "144 FPS", "val": 144 },
		{ "label": "NATIVE HZ", "val": -1 },
		{ "label": "UNCAPPED", "val": 0 }
	]
	for opt in fps_options:
		var b = Button.new()
		b.text = opt["label"]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 9)
		var val = opt["val"]
		b.pressed.connect(func():
			mgr.apply_fps_limit(val)
		)
		fps_box.add_child(b)
		
	# 2. Screen Quality Preset Row
	var qual_title = Label.new()
	qual_title.text = "GRAPHICS FIDELITY // مستوى الجودة والتفاصيل:"
	qual_title.add_theme_font_size_override("font_size", 10)
	qual_title.add_theme_color_override("font_color", Color("#38bdf8"))
	vbox.add_child(qual_title)
	
	var qual_box = HBoxContainer.new()
	qual_box.add_theme_constant_override("separation", 6)
	vbox.add_child(qual_box)
	
	var presets = ["low", "medium", "high", "ultra"]
	for p in presets:
		var b = Button.new()
		b.text = p.to_upper()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 9)
		var p_name = p
		b.pressed.connect(func():
			mgr.apply_quality_preset(p_name)
		)
		qual_box.add_child(b)
		
	# 3. V-Sync Modes
	var vsync_title = Label.new()
	vsync_title.text = "V-SYNC SYCHRONIZATION // مزامنة التردد ومنع التمزق:"
	vsync_title.add_theme_font_size_override("font_size", 10)
	vsync_title.add_theme_color_override("font_color", Color("#a78bfa"))
	vbox.add_child(vsync_title)
	
	var vsync_box = HBoxContainer.new()
	vsync_box.add_theme_constant_override("separation", 6)
	vbox.add_child(vsync_box)
	
	var vsync_opts = [
		{ "label": "ADAPTIVE", "mode": "adaptive" },
		{ "label": "FAST / MAILBOX", "mode": "mailbox" },
		{ "label": "ON", "mode": "enabled" },
		{ "label": "OFF", "mode": "disabled" }
	]
	for vo in vsync_opts:
		var b = Button.new()
		b.text = vo["label"]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 9)
		var m = vo["mode"]
		b.pressed.connect(func():
			mgr.apply_vsync_mode(m)
		)
		vsync_box.add_child(b)
		
	# 4. Window Mode
	var win_box = HBoxContainer.new()
	win_box.add_theme_constant_override("separation", 6)
	vbox.add_child(win_box)
	
	var win_opts = [
		{ "label": "FULLSCREEN", "mode": "fullscreen" },
		{ "label": "BORDERLESS", "mode": "borderless" },
		{ "label": "WINDOWED", "mode": "windowed" }
	]
	for wo in win_opts:
		var b = Button.new()
		b.text = wo["label"]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 9)
		var m = wo["mode"]
		b.pressed.connect(func():
			mgr.apply_window_mode(m)
		)
		win_box.add_child(b)
		
	# 5. Live Telemetry Overlay Toggle
	var perf_btn = Button.new()
	perf_btn.text = "[ REALTIME FPS OVERLAY: ON // عداد الإطارات الفوري ]" if mgr.show_fps_overlay else "[ REALTIME FPS OVERLAY: OFF // عداد الإطارات معطل ]"
	perf_btn.add_theme_font_size_override("font_size", 9)
	perf_btn.pressed.connect(func():
		mgr.show_fps_overlay = not mgr.show_fps_overlay
		perf_btn.text = "[ REALTIME FPS OVERLAY: ON // عداد الإطارات الفوري ]" if mgr.show_fps_overlay else "[ REALTIME FPS OVERLAY: OFF // عداد الإطارات معطل ]"
	)
	vbox.add_child(perf_btn)
	vbox.add_child(HSeparator.new())
	
	# Back Button
	var back_btn = HUDModalCommon.create_menu_button("[ BACK // رجوع إلى القائمة الرئيسية ]", Color("#a1a1aa"), 30.0)
	back_btn.pressed.connect(on_back)
	vbox.add_child(back_btn)
	
	return panel
