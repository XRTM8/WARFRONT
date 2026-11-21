class_name HUDDossier
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const UnitPortraits = preload("res://scripts/unit_portraits.gd")

var dossier_panel: PanelContainer = null
var portrait_rect: TextureRect = null
var title_label: Label = null
var rank_label: Label = null
var role_chip_label: Label = null
var hp_bar: ProgressBar = null
var hp_label: Label = null
var stats_grid: HBoxContainer = null
var stat_dmg_label: Label = null
var stat_rng_label: Label = null
var stat_spd_label: Label = null
var stat_kills_label: Label = null
var status_hint_label: Label = null

func build_dossier(parent: Control) -> void:
	dossier_panel = PanelContainer.new()
	var dos_style = StyleBoxFlat.new()
	dos_style.bg_color = Color(0.07, 0.09, 0.06, 0.96)
	dos_style.border_color = Color("#3e4733")
	dos_style.border_width_left = 1
	dos_style.border_width_right = 1
	dos_style.border_width_top = 1
	dos_style.border_width_bottom = 2
	dos_style.corner_radius_top_left = 3
	dos_style.corner_radius_top_right = 3
	dos_style.corner_radius_bottom_left = 3
	dos_style.corner_radius_bottom_right = 3
	dos_style.content_margin_left = 8
	dos_style.content_margin_right = 8
	dos_style.content_margin_top = 6
	dos_style.content_margin_bottom = 6
	dossier_panel.add_theme_stylebox_override("panel", dos_style)
	dossier_panel.custom_minimum_size = Vector2(248, 118)
	parent.add_child(dossier_panel)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 8)
	dossier_panel.add_child(main_hbox)
	
	# Left: Large Tactical Unit Portrait
	var portrait_frame = PanelContainer.new()
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.04, 0.05, 0.04, 0.95)
	p_style.border_color = Color("#2e3626")
	p_style.border_width_left = 1
	p_style.border_width_right = 1
	p_style.border_width_top = 1
	p_style.border_width_bottom = 1
	portrait_frame.add_theme_stylebox_override("panel", p_style)
	portrait_frame.custom_minimum_size = Vector2(88, 106)
	main_hbox.add_child(portrait_frame)
	
	portrait_rect = TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(84, 102)
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.add_child(portrait_rect)
	
	# Right: Telemetry & Dossier Info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	main_hbox.add_child(info_vbox)
	
	# Header (Unit Name + Rank)
	var title_box = HBoxContainer.new()
	title_box.add_theme_constant_override("separation", 4)
	info_vbox.add_child(title_box)
	
	title_label = Label.new()
	title_label.text = "غرفة العمليات المشتركة"
	title_label.add_theme_color_override("font_color", Color("#f4f4f5"))
	title_label.add_theme_font_size_override("font_size", 11)
	title_box.add_child(title_label)
	
	var t_spacer = Control.new()
	t_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_child(t_spacer)
	
	rank_label = Label.new()
	rank_label.text = ""
	rank_label.add_theme_color_override("font_color", Color("#ffd659"))
	rank_label.add_theme_font_size_override("font_size", 9)
	title_box.add_child(rank_label)
	
	# Role Tag
	role_chip_label = Label.new()
	role_chip_label.text = "توجيهات العمليات الميدانية"
	role_chip_label.add_theme_color_override("font_color", Color("#84cc16"))
	role_chip_label.add_theme_font_size_override("font_size", 9)
	info_vbox.add_child(role_chip_label)
	
	# Health Bar
	var hp_vbox = VBoxContainer.new()
	hp_vbox.add_theme_constant_override("separation", 1)
	info_vbox.add_child(hp_vbox)
	
	var hp_header = HBoxContainer.new()
	hp_vbox.add_child(hp_header)
	
	var hp_title = Label.new()
	hp_title.text = "درع الهيكل (HP)"
	hp_title.add_theme_color_override("font_color", Color("#a1a1aa"))
	hp_title.add_theme_font_size_override("font_size", 8)
	hp_header.add_child(hp_title)
	
	var hp_sp = Control.new()
	hp_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_header.add_child(hp_sp)
	
	hp_label = Label.new()
	hp_label.text = "100%"
	hp_label.add_theme_color_override("font_color", Color("#73d65e"))
	hp_label.add_theme_font_size_override("font_size", 8)
	hp_header.add_child(hp_label)
	
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(130, 6)
	hp_bar.show_percentage = false
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color("#73d65e")
	hp_fill.corner_radius_top_left = 1
	hp_fill.corner_radius_top_right = 1
	hp_fill.corner_radius_bottom_left = 1
	hp_fill.corner_radius_bottom_right = 1
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_vbox.add_child(hp_bar)
	
	# Stats Grid (Dmg, Rng, Spd, Kills)
	stats_grid = HBoxContainer.new()
	stats_grid.add_theme_constant_override("separation", 6)
	info_vbox.add_child(stats_grid)
	
	stat_dmg_label = _create_stat_badge("⚔️", "44")
	stats_grid.add_child(stat_dmg_label)
	
	stat_rng_label = _create_stat_badge("🎯", "220")
	stats_grid.add_child(stat_rng_label)
	
	stat_spd_label = _create_stat_badge("⚡", "74")
	stats_grid.add_child(stat_spd_label)
	
	stat_kills_label = _create_stat_badge("🎖️", "0")
	stats_grid.add_child(stat_kills_label)
	
	# Status Hint
	status_hint_label = Label.new()
	status_hint_label.text = "اسحب بالماوس للتحديد · زر أيمن للأمر"
	status_hint_label.add_theme_color_override("font_color", Color("#71717a"))
	status_hint_label.add_theme_font_size_override("font_size", 8)
	info_vbox.add_child(status_hint_label)

func _create_stat_badge(icon: String, val: String) -> Label:
	var lbl = Label.new()
	lbl.text = "%s %s" % [icon, val]
	lbl.add_theme_color_override("font_color", Color("#e4e4e7"))
	lbl.add_theme_font_size_override("font_size", 9)
	return lbl

func update(sim) -> void:
	if title_label == null or sim == null:
		return
		
	var selected_units: Array[Dictionary] = []
	for u in sim.units:
		if u["alive"] and u["faction"] == "player" and u.get("selected", false):
			selected_units.append(u)
			
	if selected_units.size() == 0:
		# Field Command Operational Status
		portrait_rect.texture = UnitPortraits.get_portrait("scout", 84, 46)
		title_label.text = "غرفة العمليات المشتركة"
		rank_label.text = ""
		role_chip_label.text = "توجيهات العمليات الميدانية"
		role_chip_label.add_theme_color_override("font_color", Color("#84cc16"))
		
		# Show allied force strength
		var active_troops = 0
		for u in sim.units:
			if u["alive"] and u["faction"] == "player":
				active_troops += 1
		hp_bar.value = 100.0
		hp_label.text = "%d وحدات" % active_troops
		stats_grid.visible = false
		status_hint_label.text = "اسحب بالماوس للتحديد · زر أيمن للتحريك"
	elif selected_units.size() == 1:
		var u = selected_units[0]
		portrait_rect.texture = UnitPortraits.get_portrait(u["kind"], 84, 46)
		
		var names = {
			"tank": "دبابة قتالية T-72",
			"behemoth": "دبابة الفيلق الثقيلة",
			"scout": "همفي استطلاع مدرع",
			"artillery": "راجمة صواريخ MLRS",
			"helicopter": "مروحية صقر هجومية",
			"engineer": "مركبة مهندس قتالي",
			"turret": "برج دفاعي حصين",
			"truck": "شاحنة إمداد نفطي"
		}
		var roles = {
			"tank": "مدرعات الخط الأمامي",
			"behemoth": "درع فائق وحصار ثقيل",
			"scout": "استطلاع ومناورة سريعة",
			"artillery": "قصف بعيد وهدم تحصينات",
			"helicopter": "تفوق ودعم جوي قريب",
			"engineer": "هندسة ومساندة لوجستية",
			"turret": "دفاعات وتحصينات ثابتة",
			"truck": "إمدادات وقود ونقل نفط"
		}
		title_label.text = names.get(u["kind"], u["kind"].to_upper())
		role_chip_label.text = roles.get(u["kind"], "وحدة قتالية")
		role_chip_label.add_theme_color_override("font_color", Color("#38bdf8"))
		
		var rank_titles = [
			"مجند",
			"★ مخضرم",
			"★★ نخبة",
			"★★★ بطل الحرب"
		]
		var r = u["rank"]
		rank_label.text = rank_titles[r] if r < rank_titles.size() else ""
		
		var pct = max(0.0, (u["hp"] / u["maxHp"]) * 100.0)
		hp_bar.value = pct
		hp_label.text = "%d/%d" % [int(round(u["hp"])), int(round(u["maxHp"]))]
		
		stats_grid.visible = true
		stat_dmg_label.text = "⚔️ %d" % int(round(u["damage"]))
		stat_rng_label.text = "🎯 %d" % int(round(u["range"]))
		stat_spd_label.text = "⚡ %d" % int(round(u["speed"]))
		stat_kills_label.text = "🎖️ %d" % u["kills"]
		
		var stance_ar = "هجوم" if u["stance"] == "attack" else ("تحرك" if u["stance"] == "move" else "دفاع")
		status_hint_label.text = "الحالة الميدانية: %s · الخبرة: %d XP" % [stance_ar, int(round(u["xp"]))]
	else:
		# Multi-selection formation
		portrait_rect.texture = UnitPortraits.get_portrait("tank", 84, 46)
		title_label.text = "المجموعة القتالية الموحدة"
		rank_label.text = "(%d وحدات)" % selected_units.size()
		role_chip_label.text = "تشكيل هجومي ودفاعي منسق"
		role_chip_label.add_theme_color_override("font_color", Color("#f59e0b"))
		
		var total_hp = 0.0
		var total_max_hp = 0.0
		var total_kills = 0
		for su in selected_units:
			total_hp += su["hp"]
			total_max_hp += su["maxHp"]
			total_kills += su["kills"]
		var avg_pct = (total_hp / max(1.0, total_max_hp)) * 100.0
		hp_bar.value = avg_pct
		hp_label.text = "%d%% متوسط الصحة" % int(round(avg_pct))
		
		stats_grid.visible = true
		stat_dmg_label.text = "⚔️ جماعي"
		stat_rng_label.text = "🎯 منسق"
		stat_spd_label.text = "⚡ مناورة"
		stat_kills_label.text = "🎖️ %d" % total_kills
		status_hint_label.text = "أوامر المجموعة: زر أيمن للتحرك المشترك أو الاشتباك"
