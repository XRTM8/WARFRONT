class_name HUDActionBar
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const HUDProductionDrawer = preload("res://scripts/hud_production_drawer.gd")

var drawer: HUDProductionDrawer = HUDProductionDrawer.new()
var build_buttons: Dictionary = {}
var cost_labels: Dictionary = {}
var building_buttons: Dictionary = {}
var on_train_callback: Callable
var on_place_callback: Callable

var current_sim = null

func build_action_bar(parent: Control, on_train: Callable, on_rebuild: Callable, on_place_structure: Callable) -> void:
	on_train_callback = on_train
	on_place_callback = on_place_structure
	
	drawer.build_production_drawer(
		parent,
		func(kind: String):
			on_train.call(kind),
		func(kind: String):
			if current_sim != null:
				var cat = Constants.UNIT_SPECS.get(kind, {}).get("category", "war_factory")
				current_sim.cancel_queued_unit("player", cat),
		func(kind: String):
			on_place_structure.call(kind),
		func(cat: String):
			if current_sim != null:
				current_sim.set_meta("rally_targeting_category", cat)
	)
	
	build_buttons = drawer.unit_cards
	cost_labels = drawer.unit_cost_labels
	building_buttons = drawer.facility_buttons

func switch_category(cat_id: String) -> void:
	drawer.switch_category(cat_id)

func update(sim) -> void:
	if sim == null:
		return
	current_sim = sim
	drawer.update_production_ui(sim)
