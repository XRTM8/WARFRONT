class_name HUDActionBar
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const UnitPortraits = preload("res://scripts/unit_portraits.gd")

var build_buttons: Dictionary = {}
var cost_labels: Dictionary = {}
var card_contents: Dictionary = {}
var card_styles: Dictionary = {}

var building_buttons: Dictionary = {}
var building_cost_labels: Dictionary = {}
var building_card_contents: Dictionary = {}
var building_card_styles: Dictionary = {}

var rebuild_btn: Button = null
var rebuild_cost_label: Label = null
var rebuild_content: Control = null

var tab_units_btn: Button = null
var tab_buildings_btn: Button = null
var units_box: HBoxContainer = null
var buildings_box: HBoxContainer = null
var current_tab: String = "units"

func build_action_bar(parent: Control, on_train: Callable, on_rebuild: Callable, on_place_structure: Callable) -> void:
	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 3)
	parent.add_child(root_vbox)

	# 1. Sleek Military Category Switcher Tabs
	var tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 4)
	root_vbox.add_child(tab_bar)

	tab_units_btn = _create_tab_button("🪖 تشكيلات القوات الميدانية [1-6]", true)
	tab_buildings_btn = _create_tab_button("🏗️ الإنشاءات والقواعد الهندسية [F1-F6]", false)
	tab_bar.add_child(tab_units_btn)
	tab_bar.add_child(tab_buildings_btn)

	# 2. Main Deck Panel
	var cards_panel = PanelContainer.new()
	var cards_style = StyleBoxFlat.new()
	cards_style.bg_color = Color(0.07, 0.09, 0.06, 0.96)
	cards_style.border_color = Color("#3e4733")
	cards_style.border_width_left = 1
	cards_style.border_width_right = 1
	cards_style.border_width_top = 1
	cards_style.border_width_bottom = 2
	cards_style.corner_radius_top_left = 3
	cards_style.corner_radius_top_right = 3
	cards_style.corner_radius_bottom_left = 3
	cards_style.corner_radius_bottom_right = 3
	cards_style.content_margin_left = 6
	cards_style.content_margin_right = 6
	cards_style.content_margin_top = 6
	cards_style.content_margin_bottom = 6
	cards_panel.add_theme_stylebox_override("panel", cards_style)
	root_vbox.add_child(cards_panel)

	# Tab Deck Containers
	units_box = HBoxContainer.new()
	units_box.add_theme_constant_override("separation", 6)
	cards_panel.add_child(units_box)

	buildings_box = HBoxContainer.new()
	buildings_box.add_theme_constant_override("separation", 6)
	buildings_box.visible = false
	cards_panel.add_child(buildings_box)

	# Connect tab click callbacks
	tab_units_btn.pressed.connect(func(): _switch_tab("units"))
	tab_buildings_btn.pressed.connect(func(): _switch_tab("buildings"))

	# A. Populate Units Deck
	var unit_cards = [
		{
			"kind": "scout",
			"hotkey": "1",
			"name": "همفي استطلاع",
			"role_tag": "استطلاع وسرعة",
			"role_color": Color("#38bdf8"),
			"cost": 60
		},
		{
			"kind": "tank",
			"hotkey": "2",
			"name": "دبابة قتالية",
			"role_tag": "مدرعات قتالية",
			"role_color": Color("#84cc16"),
			"cost": 140
		},
		{
			"kind": "behemoth",
			"hotkey": "3",
			"name": "دبابة الفيلق",
			"role_tag": "درع فائق وحصار",
			"role_color": Color("#f59e0b"),
			"cost": 240
		},
		{
			"kind": "artillery",
			"hotkey": "4",
			"name": "راجمة صواريخ",
			"role_tag": "قصف صاروخي",
			"role_color": Color("#fb923c"),
			"cost": 185
		},
		{
			"kind": "helicopter",
			"hotkey": "5",
			"name": "مروحية صقر",
			"role_tag": "دعم جوي وتطويق",
			"role_color": Color("#06b6d4"),
			"cost": 215
		},
		{
			"kind": "engineer",
			"hotkey": "6",
			"name": "مهندس قتالي",
			"role_tag": "هندسة وتفخيخ",
			"role_color": Color("#eab308"),
			"cost": 75
		}
	]

	for card in unit_cards:
		var btn = _create_tactical_card(card, build_buttons, cost_labels, card_contents, card_styles)
		var k = card["kind"]
		btn.pressed.connect(func(): on_train.call(k))
		units_box.add_child(btn)

	# B. Populate Base Construction Deck
	var structure_cards = [
		{
			"kind": "war_factory",
			"hotkey": "F1",
			"name": "مصنع حربي",
			"role_tag": "تصنيع مدرعات",
			"role_color": Color("#f59e0b"),
			"cost": Constants.BUILDING_SPECS["war_factory"]["cost"]
		},
		{
			"kind": "repair_depot",
			"hotkey": "F2",
			"name": "ورشة صيانة",
			"role_tag": "ترميم ميداني",
			"role_color": Color("#38bdf8"),
			"cost": Constants.BUILDING_SPECS["repair_depot"]["cost"]
		},
		{
			"kind": "refinery_silo",
			"hotkey": "F3",
			"name": "صومعة تكرير",
			"role_tag": "تكرير وخزن نفط",
			"role_color": Color("#eab308"),
			"cost": Constants.BUILDING_SPECS["refinery_silo"]["cost"]
		},
		{
			"kind": "turret",
			"hotkey": "F4",
			"name": "برج دفاعي",
			"role_tag": "دفاع أوتوماتيكي",
			"role_color": Color("#9ca3af"),
			"cost": Constants.BUILDING_SPECS["turret"]["cost"]
		},
		{
			"kind": "missile_battery",
			"hotkey": "F5",
			"name": "دفاع صاروخي",
			"role_tag": "صواريخ موجهة",
			"role_color": Color("#f43f5e"),
			"cost": Constants.BUILDING_SPECS["missile_battery"]["cost"]
		},
		{
			"kind": "sandbag_wall",
			"hotkey": "F6",
			"name": "سواتر وخنادق",
			"role_tag": "تحصينات ترابية",
			"role_color": Color("#a1a1aa"),
			"cost": Constants.BUILDING_SPECS["sandbag_wall"]["cost"]
		}
	]

	for card in structure_cards:
		var btn = _create_tactical_card(card, building_buttons, building_cost_labels, building_card_contents, building_card_styles)
		var k = card["kind"]
		btn.pressed.connect(func(): on_place_structure.call(k))
		buildings_box.add_child(btn)

	# Contextual Bridge Rebuild Card (shared in Units Deck)
	var bridge_card_spec = {
		"kind": "bridge",
		"hotkey": "B",
		"name": "إصلاح الجسر",
		"role_tag": "ترميم خط الإمداد",
		"role_color": Color("#34d399"),
		"cost": 110
	}
	rebuild_btn = _create_tactical_card(bridge_card_spec, build_buttons, cost_labels, card_contents, card_styles)
	rebuild_cost_label = cost_labels.get("bridge")
	rebuild_content = card_contents.get("bridge")
	rebuild_btn.pressed.connect(func(): on_rebuild.call())
	units_box.add_child(rebuild_btn)

func _create_tab_button(title: String, active: bool) -> Button:
	var btn = Button.new()
	btn.text = title
	btn.custom_minimum_size = Vector2(160, 24)
	_style_tab_btn(btn, active)
	return btn

func _style_tab_btn(btn: Button, active: bool) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.11, 0.98) if active else Color(0.05, 0.07, 0.05, 0.85)
	style.border_color = Color("#eab308") if active else Color("#2f3629")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 2 if active else 1
	style.border_width_bottom = 0
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_color_override("font_color", Color("#ffd659") if active else Color("#8d9f6e"))
	btn.add_theme_font_size_override("font_size", 10)

func _switch_tab(tab: String) -> void:
	current_tab = tab
	if units_box != null:
		units_box.visible = (tab == "units")
	if buildings_box != null:
		buildings_box.visible = (tab == "buildings")
	if tab_units_btn != null:
		_style_tab_btn(tab_units_btn, tab == "units")
	if tab_buildings_btn != null:
		_style_tab_btn(tab_buildings_btn, tab == "buildings")

func _create_tactical_card(card: Dictionary, btn_dict: Dictionary, lbl_dict: Dictionary, content_dict: Dictionary, style_dict: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(92, 118)
	btn.flat = true
	
	# Styles
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.08, 0.10, 0.07, 0.95)
	style_normal.border_color = Color("#3e4733")
	style_normal.border_width_left = 1
	style_normal.border_width_right = 1
	style_normal.border_width_top = 1
	style_normal.border_width_bottom = 2
	style_normal.corner_radius_top_left = 2
	style_normal.corner_radius_top_right = 2
	style_normal.corner_radius_bottom_left = 2
	style_normal.corner_radius_bottom_right = 2
	style_dict[card["kind"]] = style_normal
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.12, 0.16, 0.10, 0.98)
	style_hover.border_color = Color("#eab308")
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 2
	style_hover.corner_radius_top_left = 2
	style_hover.corner_radius_top_right = 2
	style_hover.corner_radius_bottom_left = 2
	style_hover.corner_radius_bottom_right = 2
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.05, 0.07, 0.05, 0.98)
	style_pressed.border_color = Color("#854d0e")
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_top = 2
	style_pressed.border_width_bottom = 2
	
	var style_disabled = StyleBoxFlat.new()
	style_disabled.bg_color = Color(0.05, 0.06, 0.05, 0.85)
	style_disabled.border_color = Color("#242720")
	style_disabled.border_width_left = 1
	style_disabled.border_width_right = 1
	style_disabled.border_width_top = 1
	style_disabled.border_width_bottom = 1
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_stylebox_override("focus", style_normal)

	# Inner Content Container
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	btn.add_child(margin)
	content_dict[card["kind"]] = margin

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	# 1. Header Bar: Hotkey Badge & Cost
	var header_box = HBoxContainer.new()
	header_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header_box)

	var hotkey_lbl = Label.new()
	hotkey_lbl.text = "[%s]" % card["hotkey"]
	hotkey_lbl.add_theme_color_override("font_color", Color("#ffd659"))
	hotkey_lbl.add_theme_font_size_override("font_size", 9)
	header_box.add_child(hotkey_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_box.add_child(spacer)

	var cost_lbl = Label.new()
	cost_lbl.text = "%d 🛢️" % card["cost"]
	cost_lbl.add_theme_color_override("font_color", Color("#fde047"))
	cost_lbl.add_theme_font_size_override("font_size", 10)
	header_box.add_child(cost_lbl)
	lbl_dict[card["kind"]] = cost_lbl

	# 2. Vehicle / Structure Schematic Blueprint
	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(84, 46)
	tex_rect.texture = UnitPortraits.get_portrait(card["kind"], 84, 46)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(tex_rect)

	# 3. Name
	var name_lbl = Label.new()
	name_lbl.text = card["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Color("#f4f4f5"))
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# 4. Role / Category Chip
	var chip_panel = PanelContainer.new()
	chip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip_style = StyleBoxFlat.new()
	var role_col: Color = card["role_color"]
	chip_style.bg_color = Color(role_col.r, role_col.g, role_col.b, 0.16)
	chip_style.border_color = Color(role_col.r, role_col.g, role_col.b, 0.45)
	chip_style.border_width_left = 1
	chip_style.border_width_right = 1
	chip_style.border_width_top = 1
	chip_style.border_width_bottom = 1
	chip_style.corner_radius_top_left = 2
	chip_style.corner_radius_top_right = 2
	chip_style.corner_radius_bottom_left = 2
	chip_style.corner_radius_bottom_right = 2
	chip_style.content_margin_left = 2
	chip_style.content_margin_right = 2
	chip_style.content_margin_top = 1
	chip_style.content_margin_bottom = 1
	chip_panel.add_theme_stylebox_override("panel", chip_style)
	vbox.add_child(chip_panel)

	var chip_lbl = Label.new()
	chip_lbl.text = card["role_tag"]
	chip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_lbl.add_theme_color_override("font_color", role_col)
	chip_lbl.add_theme_font_size_override("font_size", 8)
	chip_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_panel.add_child(chip_lbl)

	btn_dict[card["kind"]] = btn
	return btn

func update(sim) -> void:
	if sim == null:
		return

	# Update Unit Cards
	for kind in build_buttons:
		if not Constants.UNIT_SPECS.has(kind):
			continue
		var btn: Button = build_buttons[kind]
		var cost = Constants.UNIT_SPECS[kind]["cost"]
		var can_afford = sim.player_oil >= cost
		btn.disabled = not can_afford
		
		if cost_labels.has(kind):
			var lbl: Label = cost_labels[kind]
			lbl.add_theme_color_override("font_color", Color("#fde047") if can_afford else Color("#ef4444"))
			
		if card_contents.has(kind):
			var c: Control = card_contents[kind]
			c.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_afford else Color(0.65, 0.65, 0.65, 0.65)

	# Update Base Construction Cards
	for kind in building_buttons:
		if not Constants.BUILDING_SPECS.has(kind):
			continue
		var b_btn: Button = building_buttons[kind]
		var b_cost = Constants.BUILDING_SPECS[kind]["cost"]
		var can_afford = sim.player_oil >= b_cost
		b_btn.disabled = not can_afford

		# Active placement highlight (gold outline when in build mode)
		if building_card_styles.has(kind):
			var st: StyleBoxFlat = building_card_styles[kind]
			if sim.build_mode == kind:
				st.border_color = Color("#fde047")
				st.border_width_left = 2
				st.border_width_right = 2
				st.border_width_top = 2
				st.border_width_bottom = 2
			else:
				st.border_color = Color("#3e4733")
				st.border_width_left = 1
				st.border_width_right = 1
				st.border_width_top = 1
				st.border_width_bottom = 2
		
		if building_cost_labels.has(kind):
			var lbl: Label = building_cost_labels[kind]
			lbl.add_theme_color_override("font_color", Color("#fde047") if can_afford else Color("#ef4444"))
			
		if building_card_contents.has(kind):
			var c: Control = building_card_contents[kind]
			c.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_afford else Color(0.65, 0.65, 0.65, 0.65)
		
	# Update Bridge Rebuild Card
	if rebuild_btn != null:
		var has_broken_bridge = false
		for b in sim.map.get("bridges", []):
			if b["status"] == "destroyed":
				has_broken_bridge = true
				break
		var can_rebuild = sim.player_oil >= Constants.BRIDGE_REBUILD_COST and has_broken_bridge
		rebuild_btn.disabled = not can_rebuild
		
		if rebuild_cost_label != null:
			rebuild_cost_label.add_theme_color_override("font_color", Color("#fde047") if can_rebuild else Color("#ef4444"))
		if rebuild_content != null:
			rebuild_content.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_rebuild else Color(0.65, 0.65, 0.65, 0.65)
