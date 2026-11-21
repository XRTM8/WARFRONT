class_name SimAITactics
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func update_coordinated_assault(sim, dt: float) -> void:
	if sim.phase != "playing":
		return
		
	var timer = sim.get_meta("ai_assault_timer") if sim.has_meta("ai_assault_timer") else 0.0
	timer -= dt
	if timer <= 0.0:
		timer = randf_range(28.0, 45.0)
		sim.set_meta("ai_assault_timer", timer)
		_trigger_multi_prong_assault(sim)

static func _trigger_multi_prong_assault(sim) -> void:
	var enemy_combatants: Array[Dictionary] = []
	var enemy_boats: Array[Dictionary] = []
	
	for u in sim.units:
		if not u.get("alive", true) or u.get("faction") != "enemy":
			continue
		if u.get("is_naval", false):
			enemy_boats.push_back(u)
		elif u.get("kind") != "truck":
			enemy_combatants.push_back(u)
			
	if enemy_combatants.is_empty():
		return
		
	var target_hq = sim.map["playerHQ"]
	var target_pos = Vector2(target_hq["x"], target_hq["y"])
	
	# 1. Main Armor & Infantry Ground Push
	for u in enemy_combatants:
		u["targetPos"] = target_pos
		u["guardPos"] = target_pos
		u["stance"] = "attack_move"
		
	# 2. Synchronized River Flank
	for boat in enemy_boats:
		# Boats push forward to river center or nearest bridge to cut off player reinforcements
		var river_x = sim.map["width"] * 0.5
		boat["targetPos"] = Vector2(river_x, boat["y"])
		boat["stance"] = "attack_move"
