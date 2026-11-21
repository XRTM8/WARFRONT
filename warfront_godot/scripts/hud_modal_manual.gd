class_name HUDModalManual
extends RefCounted

const HUDModalCommon = preload("res://scripts/hud_modal_common.gd")

static func build_theater_modal(parent_canvas: CanvasLayer, on_theater_selected: Callable, on_back: Callable) -> PanelContainer:
	var theater_panel = PanelContainer.new()
	theater_panel.set_anchors_preset(Control.PRESET_CENTER)
	theater_panel.custom_minimum_size = Vector2(460, 360)
	theater_panel.position = Vector2(-230, -180)
	
	var style = HUDModalCommon.create_military_panel_style()
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
			on_theater_selected.call(th_id)
		)
		vbox.add_child(btn)
		
	var back_btn = HUDModalCommon.create_menu_button("رجوع إلى القائمة", Color("#a1a1aa"))
	back_btn.pressed.connect(on_back)
	vbox.add_child(back_btn)
	
	return theater_panel

static func build_help_modal(parent_canvas: CanvasLayer, on_back: Callable) -> PanelContainer:
	var help_panel = PanelContainer.new()
	help_panel.set_anchors_preset(Control.PRESET_CENTER)
	help_panel.custom_minimum_size = Vector2(440, 360)
	help_panel.position = Vector2(-220, -180)
	
	var style = HUDModalCommon.create_military_panel_style()
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
	
	var back_btn = HUDModalCommon.create_menu_button("رجوع إلى القائمة", Color("#a1a1aa"))
	back_btn.pressed.connect(on_back)
	vbox.add_child(back_btn)
	
	return help_panel
