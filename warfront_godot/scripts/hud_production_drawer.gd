class_name HUDProductionDrawer
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const UnitPortraits = preload("res://scripts/unit_portraits.gd")

var current_category: String = "barracks"
var category_buttons: Dictionary = {}
var category_containers: Dictionary = {}

var facility_buttons: Dictionary = {}
var facility_info_labels: Dictionary = {}
var unit_cards: Dictionary = {}
var unit_queue_labels: Dictionary = {}
var unit_cost_labels: Dictionary = {}

var rally_banners: Dictionary = {}
var progress_bars: Dictionary = {}

var on_queue_unit: Callable
var on_cancel_unit: Callable
var on_place_structure: Callable
var on_set_rally_mode: Callable

func build_production_drawer(parent: Control, p_on_queue: Callable, p_on_cancel: Callable, p_on_place: Callable, p_on_rally: Callable) -> void:
	on_queue_unit = p_on_queue
	on_cancel_unit = p_on_cancel
	on_place_structure = p_on_place
	on_set_rally_mode = p_on_rally

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 3)
	parent.add_child(root_vbox)

	# 1. Six Military Branch Switcher Tabs
	var tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 3)
	root_vbox.add_child(tab_bar)

	var cat_defs = [
		{"id": "defense", "label": "[ 1. دفاعات ]", "color": Color("#84cc16")},
		{"id": "barracks", "label": "[ 2. مشاة ]", "color": Color("#22c55e")},
		{"id": "war_factory", "label": "[ 3. مدرعات ]", "color": Color("#f59e0b")},
		{"id": "airfield", "label": "[ 4. طيران ]", "color": Color("#38bdf8")},
		{"id": "shipyard", "label": "[ 5. أسطول ]", "color": Color("#06b6d4")},
		{"id": "missile_plant", "label": "[ 6. صواريخ ]", "color": Color("#ef4444")}
	]

	for c in cat_defs:
		var btn = Button.new()
		btn.text = c["label"]
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(90, 24)
		btn.add_theme_font_size_override("font_size", 10)
		_apply_tab_style(btn, c["id"] == current_category)
		var cat_id = c["id"]
		btn.pressed.connect(func(): switch_category(cat_id))
		tab_bar.add_child(btn)
		category_buttons[cat_id] = btn

	# 2. Main Deck Display Panel
	var deck_panel = PanelContainer.new()
	var d_style = StyleBoxFlat.new()
	d_style.bg_color = Color(0.06, 0.08, 0.06, 0.96)
	d_style.border_color = Color("#3e4733")
	d_style.border_width_left = 1
	d_style.border_width_right = 1
	d_style.border_width_top = 1
	d_style.border_width_bottom = 2
	d_style.corner_radius_top_left = 3
	d_style.corner_radius_top_right = 3
	d_style.corner_radius_bottom_left = 3
	d_style.corner_radius_bottom_right = 3
	d_style.content_margin_left = 5
	d_style.content_margin_right = 5
	d_style.content_margin_top = 4
	d_style.content_margin_bottom = 4
	deck_panel.add_theme_stylebox_override("panel", d_style)
	root_vbox.add_child(deck_panel)

	# Container for each category
	for c in cat_defs:
		var cat_box = VBoxContainer.new()
		cat_box.add_theme_constant_override("separation", 3)
		cat_box.visible = (c["id"] == current_category)
		deck_panel.add_child(cat_box)
		category_containers[c["id"]] = cat_box
		
		if c["id"] == "defense":
			_build_defense_deck(cat_box)
		else:
			_build_production_branch_deck(cat_box, c["id"])

func _apply_tab_style(btn: Button, active: bool) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.24, 0.16, 0.95) if active else Color(0.08, 0.10, 0.08, 0.8)
	sb.border_color = Color("#84cc16") if active else Color("#2e3828")
	sb.border_width_bottom = 2 if active else 1
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", Color("#f8fafc") if active else Color("#88947f"))

func switch_category(cat_id: String) -> void:
	current_category = cat_id
	for id in category_buttons.keys():
		_apply_tab_style(category_buttons[id], id == cat_id)
		category_containers[id].visible = (id == cat_id)

func _build_defense_deck(parent: VBoxContainer) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)
	
	var def_specs = ["turret", "missile_battery", "sandbag_wall", "repair_depot", "refinery_silo"]
	for kind in def_specs:
		var spec = Constants.BUILDING_SPECS.get(kind, {})
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(98, 72)
		btn.focus_mode = Control.FOCUS_NONE
		_style_card_button(btn)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(vbox)
		
		var title = Label.new()
		title.text = spec.get("name", kind)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 9)
		title.add_theme_color_override("font_color", spec.get("role_color", Color("#e4e4e7")))
		vbox.add_child(title)
		
		var cost_lbl = Label.new()
		cost_lbl.text = "OIL: %d" % spec.get("cost", 100)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 9)
		cost_lbl.add_theme_color_override("font_color", Color("#facc15"))
		vbox.add_child(cost_lbl)
		
		var k_copy = kind
		btn.pressed.connect(func(): on_place_structure.call(k_copy))
		hbox.add_child(btn)
		facility_buttons[kind] = btn

func _build_production_branch_deck(parent: VBoxContainer, cat_id: String) -> void:
	var cat_info = Constants.PRODUCTION_CATEGORIES.get(cat_id, {})
	var facility_kind = cat_info.get("structure", "")
	var f_spec = Constants.BUILDING_SPECS.get(facility_kind, {})
	
	# Top Facility Status & Rally Bar
	var top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	parent.add_child(top_bar)
	
	# Facility Blueprint Placement Button
	var f_btn = Button.new()
	f_btn.custom_minimum_size = Vector2(160, 28)
	f_btn.focus_mode = Control.FOCUS_NONE
	f_btn.text = "+ %s (%d OIL)" % [f_spec.get("name", facility_kind), f_spec.get("cost", 200)]
	f_btn.add_theme_font_size_override("font_size", 9)
	f_btn.add_theme_color_override("font_color", Color("#ffd659"))
	var f_copy = facility_kind
	f_btn.pressed.connect(func(): on_place_structure.call(f_copy))
	top_bar.add_child(f_btn)
	facility_buttons[facility_kind] = f_btn
	
	# Facility Count & Speed Multiplier
	var count_lbl = Label.new()
	count_lbl.text = "BUILT: 0  (1.0x)"
	count_lbl.add_theme_font_size_override("font_size", 9)
	count_lbl.add_theme_color_override("font_color", Color("#86efac"))
	top_bar.add_child(count_lbl)
	facility_info_labels[cat_id] = count_lbl
	
	# Rally Waypoint Status & Action Button
	var rally_btn = Button.new()
	rally_btn.text = "[ SET RALLY POINT // حدد نقطة الانطلاق ]"
	rally_btn.focus_mode = Control.FOCUS_NONE
	rally_btn.custom_minimum_size = Vector2(170, 24)
	rally_btn.add_theme_font_size_override("font_size", 9)
	var cat_copy = cat_id
	rally_btn.pressed.connect(func(): on_set_rally_mode.call(cat_copy))
	top_bar.add_child(rally_btn)
	rally_banners[cat_id] = rally_btn
	
	# Production Progress Bar
	var p_bar = ProgressBar.new()
	p_bar.custom_minimum_size = Vector2(100, 14)
	p_bar.show_percentage = false
	p_bar.max_value = 1.0
	p_bar.value = 0.0
	top_bar.add_child(p_bar)
	progress_bars[cat_id] = p_bar

	# Lower Row: Trainable Units Deck
	var units_hbox = HBoxContainer.new()
	units_hbox.add_theme_constant_override("separation", 6)
	parent.add_child(units_hbox)
	
	for u_kind in cat_info.get("units", []):
		var u_spec = Constants.UNIT_SPECS.get(u_kind, {})
		var u_card = Button.new()
		u_card.custom_minimum_size = Vector2(105, 54)
		u_card.focus_mode = Control.FOCUS_NONE
		_style_card_button(u_card)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		u_card.add_child(vbox)
		
		# Name & Role
		var u_name = Label.new()
		u_name.text = u_spec.get("name", u_kind)
		u_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		u_name.add_theme_font_size_override("font_size", 9)
		u_name.add_theme_color_override("font_color", u_spec.get("role_color", Color("#f8fafc")))
		vbox.add_child(u_name)
		
		# Cost & Queue Count
		var cost_lbl = Label.new()
		cost_lbl.text = "OIL: %d" % u_spec.get("cost", 80)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 9)
		cost_lbl.add_theme_color_override("font_color", Color("#facc15"))
		vbox.add_child(cost_lbl)
		unit_cost_labels[u_kind] = cost_lbl
		
		var q_lbl = Label.new()
		q_lbl.text = ""
		q_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q_lbl.add_theme_font_size_override("font_size", 9)
		q_lbl.add_theme_color_override("font_color", Color("#38bdf8"))
		vbox.add_child(q_lbl)
		unit_queue_labels[u_kind] = q_lbl
		
		var uk_copy = u_kind
		u_card.pressed.connect(func(): on_queue_unit.call(uk_copy))
		u_card.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				on_cancel_unit.call(uk_copy)
		)
		units_hbox.add_child(u_card)
		unit_cards[u_kind] = u_card

func _style_card_button(btn: Button) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.15, 0.12, 0.92)
	sb.border_color = Color("#3e4733")
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	btn.add_theme_stylebox_override("normal", sb)

func update_production_ui(sim) -> void:
	var queues = sim.get_production_queues("player")
	
	for cat in ["barracks", "war_factory", "airfield", "shipyard", "missile_plant"]:
		var cat_data = queues.get(cat, {})
		var f_kind = Constants.PRODUCTION_CATEGORIES[cat].get("structure", "")
		var count = sim.get_facility_count(f_kind, "player")
		var speed_mult = sim.get_production_speed_multiplier(cat, "player")
		
		# Update facility label
		if facility_info_labels.has(cat):
			var speed_str = "+%d%%" % int((speed_mult - 1.0) * 100.0) if speed_mult > 1.0 else "1.0x"
			facility_info_labels[cat].text = "BUILT: %d (SPEED: %s)" % [count, speed_str]
			
		# Update rally banner
		if rally_banners.has(cat):
			var r_btn = rally_banners[cat]
			var state = cat_data.get("state", "idle")
			if state == "pending_rally":
				r_btn.text = "[ ! CLICK MAP TO SET RALLY ! // حدد نقطة الانطلاق ]"
				r_btn.add_theme_color_override("font_color", Color("#ef4444"))
			elif cat_data.get("rally_point", Vector2.ZERO) != Vector2.ZERO:
				var rp = cat_data["rally_point"]
				r_btn.text = "[ RALLY: (%d, %d) ]" % [int(rp.x), int(rp.y)]
				r_btn.add_theme_color_override("font_color", Color("#38bdf8"))
			else:
				r_btn.text = "[ SET RALLY POINT // حدد نقطة الانطلاق ]"
				r_btn.add_theme_color_override("font_color", Color("#94a3b8"))
				
		# Update progress bar
		if progress_bars.has(cat):
			progress_bars[cat].value = cat_data.get("progress", 0.0)

	# Update unit cards queue counts
	for u_kind in unit_queue_labels.keys():
		var cat = Constants.UNIT_SPECS[u_kind].get("category", "war_factory")
		var cat_data = queues.get(cat, {})
		var items = cat_data.get("items", [])
		var q_count = 0
		for itm in items:
			if itm["kind"] == u_kind:
				q_count += 1
		unit_queue_labels[u_kind].text = "[ QUEUED: x%d ]" % q_count if q_count > 0 else ""
