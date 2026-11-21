class_name HUDCommanderBar
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

var power_buttons: Dictionary = {}
var cooldown_labels: Dictionary = {}
var cost_labels: Dictionary = {}

var directive_panel: PanelContainer = null
var directive_title: Label = null
var directive_desc: Label = null
var directive_timer_label: Label = null
var directive_reward_label: Label = null

var phase_badge_label: Label = null

func build_commander_bar(parent: Control, on_power_requested: Callable) -> void:
	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 4)
	parent.add_child(root_vbox)
	
	# --- Top Row: Phase Badge + Commander Powers Tray + Directive Banner ---
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 8)
	root_vbox.add_child(top_hbox)
	
	# 1. Strategic Escalation Phase Badge
	var phase_panel = PanelContainer.new()
	var ph_style = StyleBoxFlat.new()
	ph_style.bg_color = Color(0.08, 0.10, 0.08, 0.95)
	ph_style.border_color = Color("#556b2f")
	ph_style.border_width_left = 1
	ph_style.border_width_right = 1
	ph_style.border_width_top = 1
	ph_style.border_width_bottom = 2
	ph_style.corner_radius_top_left = 2
	ph_style.corner_radius_top_right = 2
	ph_style.corner_radius_bottom_left = 2
	ph_style.corner_radius_bottom_right = 2
	ph_style.content_margin_left = 8
	ph_style.content_margin_right = 8
	ph_style.content_margin_top = 3
	ph_style.content_margin_bottom = 3
	phase_panel.add_theme_stylebox_override("panel", ph_style)
	top_hbox.add_child(phase_panel)
	
	phase_badge_label = Label.new()
	phase_badge_label.text = "⚔️ مرحلة الاستطلاع"
	phase_badge_label.add_theme_color_override("font_color", Color("#86efac"))
	phase_badge_label.add_theme_font_size_override("font_size", 10)
	phase_panel.add_child(phase_badge_label)
	
	# 2. Commander Powers Buttons Tray
	var powers_panel = PanelContainer.new()
	var pow_style = StyleBoxFlat.new()
	pow_style.bg_color = Color(0.06, 0.08, 0.06, 0.96)
	pow_style.border_color = Color("#3e4733")
	pow_style.border_width_left = 1
	pow_style.border_width_right = 1
	pow_style.border_width_top = 1
	pow_style.border_width_bottom = 2
	pow_style.corner_radius_top_left = 2
	pow_style.corner_radius_top_right = 2
	pow_style.corner_radius_bottom_left = 2
	pow_style.corner_radius_bottom_right = 2
	pow_style.content_margin_left = 4
	pow_style.content_margin_right = 4
	pow_style.content_margin_top = 2
	pow_style.content_margin_bottom = 2
	powers_panel.add_theme_stylebox_override("panel", pow_style)
	top_hbox.add_child(powers_panel)
	
	var pow_hbox = HBoxContainer.new()
	pow_hbox.add_theme_constant_override("separation", 6)
	powers_panel.add_child(pow_hbox)
	
	var powers_order = ["airstrike", "artillery_barrage", "recon_drone", "supply_drop"]
	var power_icons = {
		"airstrike": "✈️",
		"artillery_barrage": "🚀",
		"recon_drone": "📡",
		"supply_drop": "📦"
	}
	
	for p_id in powers_order:
		var spec = Constants.COMMANDER_POWERS[p_id]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(98, 28)
		btn.text = "%s [%s] %s" % [power_icons[p_id], spec["hotkey"], spec["name"].split(" ")[0]]
		btn.add_theme_font_size_override("font_size", 9)
		
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = Color(0.10, 0.13, 0.09, 0.95)
		b_style.border_color = Color("#4d583b")
		b_style.border_width_left = 1
		b_style.border_width_right = 1
		b_style.border_width_top = 1
		b_style.border_width_bottom = 1
		b_style.corner_radius_top_left = 2
		b_style.corner_radius_top_right = 2
		b_style.corner_radius_bottom_left = 2
		b_style.corner_radius_bottom_right = 2
		btn.add_theme_stylebox_override("normal", b_style)
		
		var pow_id = p_id
		btn.pressed.connect(func(): on_power_requested.call(pow_id))
		pow_hbox.add_child(btn)
		power_buttons[p_id] = btn
		
	# 3. Dynamic Field Directive Banner
	directive_panel = PanelContainer.new()
	var dir_style = StyleBoxFlat.new()
	dir_style.bg_color = Color(0.08, 0.09, 0.06, 0.95)
	dir_style.border_color = Color("#ca8a04")
	dir_style.border_width_left = 1
	dir_style.border_width_right = 1
	dir_style.border_width_top = 1
	dir_style.border_width_bottom = 2
	dir_style.corner_radius_top_left = 2
	dir_style.corner_radius_top_right = 2
	dir_style.corner_radius_bottom_left = 2
	dir_style.corner_radius_bottom_right = 2
	dir_style.content_margin_left = 8
	dir_style.content_margin_right = 8
	dir_style.content_margin_top = 2
	dir_style.content_margin_bottom = 2
	directive_panel.add_theme_stylebox_override("panel", dir_style)
	top_hbox.add_child(directive_panel)
	
	var dir_hbox = HBoxContainer.new()
	dir_hbox.add_theme_constant_override("separation", 6)
	directive_panel.add_child(dir_hbox)
	
	directive_title = Label.new()
	directive_title.text = "📋 الأوامر التكتيكية: جارٍ استقبال التوجيهات..."
	directive_title.add_theme_color_override("font_color", Color("#fef08a"))
	directive_title.add_theme_font_size_override("font_size", 9)
	dir_hbox.add_child(directive_title)
	
	directive_timer_label = Label.new()
	directive_timer_label.text = ""
	directive_timer_label.add_theme_color_override("font_color", Color("#94a3b8"))
	directive_timer_label.add_theme_font_size_override("font_size", 9)
	dir_hbox.add_child(directive_timer_label)

func update(sim) -> void:
	if sim == null:
		return
		
	# 1. Update Phase Badge
	if phase_badge_label != null:
		if sim.battle_phase == "recon":
			phase_badge_label.text = "⚔️ مرحلة الاستطلاع والانتشار"
			phase_badge_label.add_theme_color_override("font_color", Color("#86efac"))
		elif sim.battle_phase == "escalation":
			phase_badge_label.text = "⚠️ مرحلة التصعيد وحرب الإمداد"
			phase_badge_label.add_theme_color_override("font_color", Color("#fde047"))
		elif sim.battle_phase == "total_war":
			phase_badge_label.text = "🚨 مرحلة الاشتباك الشامل والحسم"
			phase_badge_label.add_theme_color_override("font_color", Color("#f87171"))

	# 2. Update Commander Powers
	for p_id in power_buttons:
		var btn: Button = power_buttons[p_id]
		var spec = Constants.COMMANDER_POWERS[p_id]
		var cd = sim.commander_powers.get(p_id, 0.0)
		var can_afford = sim.player_oil >= spec["cost"]
		var is_ready = cd <= 0.0
		
		btn.disabled = not (can_afford and is_ready)
		if is_ready:
			btn.text = "%s [%s] %d🛢️" % [spec["name"].split(" ")[0], spec["hotkey"], spec["cost"]]
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_afford else Color(0.7, 0.7, 0.7, 0.7)
		else:
			btn.text = "⏳ %01.0fs" % cd
			btn.modulate = Color(0.6, 0.6, 0.6, 0.5)

	# 3. Update Directive
	if directive_panel != null:
		if sim.active_directive.is_empty():
			directive_title.text = "📋 الأوامر: بانتظار تعليمات القيادة الميدانية..."
			directive_timer_label.text = ""
		else:
			var d = sim.active_directive
			directive_title.text = "🎯 %s (+%d🛢️)" % [d["title"], d["reward_oil"]]
			directive_timer_label.text = "⏳ %02d ث" % int(d["time_limit"])
