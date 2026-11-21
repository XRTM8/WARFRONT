class_name SimAI
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")

static func update_enemy_ai(sim, dt: float) -> void:
	# 1. Update any active enemy engineers (repairing destroyed bridges)
	for u in sim.units:
		if u["alive"] and u["faction"] == "enemy" and u["kind"] == "engineer":
			_update_enemy_engineer(sim, u)

	# 2. Strategic decision tick
	sim.ai_decision_timer -= dt
	if sim.ai_decision_timer <= 0.0:
		sim.ai_decision_timer = randf_range(3.2, 5.0)
		sim.ai_wave_count += 1
		
		var ehq = sim.map["enemyHQ"]
		var phq = sim.map["playerHQ"]
		
		# --- STRATEGY A: Engineer Bridge Repair Order ---
		var destroyed_bridges: Array[Dictionary] = []
		for b in sim.map["bridges"]:
			if b["status"] == "destroyed":
				destroyed_bridges.append(b)
				
		var alive_enemy_engineers = 0
		for u in sim.units:
			if u["alive"] and u["faction"] == "enemy" and u["kind"] == "engineer":
				alive_enemy_engineers += 1
				
		var eng_spec = Constants.UNIT_SPECS["engineer"]
		if destroyed_bridges.size() > 0 and alive_enemy_engineers == 0 and sim.enemy_oil >= (eng_spec["cost"] + 30):
			sim.enemy_oil -= eng_spec["cost"]
			var eng = sim.spawn_unit("enemy", "engineer", ehq["x"] - 70.0, ehq["y"] + randf_range(-30, 30))
			var target_b = destroyed_bridges[0]
			eng["targetPos"] = Vector2(target_b["x"], target_b["y"])
			eng["targetBridgeId"] = target_b["id"]
			eng["stance"] = "move"
			return

		# --- STRATEGY B: Forward Fortification (Turrets) ---
		var turret_cost = Constants.UNIT_SPECS["turret"]["cost"]
		if sim.enemy_oil >= 200:
			var enemy_turrets = 0
			for u in sim.units:
				if u["alive"] and u["faction"] == "enemy" and u["kind"] == "turret":
					enemy_turrets += 1
			if enemy_turrets < 2:
				var fort_pos = Vector2(ehq["x"] - 180.0, ehq["y"] + (100.0 if enemy_turrets == 0 else -100.0))
				sim.enemy_oil -= turret_cost
				sim.spawn_unit("enemy", "turret", fort_pos.x, fort_pos.y)
				sim.spawn_burst(fort_pos.x, fort_pos.y, "spark", 10, Color("#f3c363"), 70.0)
				sim.sound_triggered.emit("unit_ready")

		# --- STRATEGY C: Tactical Target Assessment ---
		var target_pos = Vector2(phq["x"], phq["y"])
		var candidate_targets: Array[Dictionary] = []
		
		# Check if any enemy rig is currently threatened by player units
		var threatened_rig: Dictionary = {}
		for r in sim.map["rigs"]:
			if r["owner"] == "enemy":
				var r_vec = Vector2(r["x"], r["y"])
				for pu in sim.units:
					if pu["alive"] and pu["faction"] == "player" and Vector2(pu["x"], pu["y"]).distance_to(r_vec) < 180.0:
						threatened_rig = r
						break
				if not threatened_rig.is_empty():
					break
					
		if not threatened_rig.is_empty():
			target_pos = Vector2(threatened_rig["x"], threatened_rig["y"])
		else:
			for r in sim.map["rigs"]:
				if r["owner"] != "enemy":
					candidate_targets.append(r)
					
			if candidate_targets.size() > 0:
				candidate_targets.sort_custom(func(a, b):
					var d_a = Vector2(ehq["x"], ehq["y"]).distance_to(Vector2(a["x"], a["y"]))
					var d_b = Vector2(ehq["x"], ehq["y"]).distance_to(Vector2(b["x"], b["y"]))
					if a["id"] == "rig_island":
						d_a -= 450.0
					if b["id"] == "rig_island":
						d_b -= 450.0
					return d_a < d_b
				)
				target_pos = Vector2(candidate_targets[0]["x"], candidate_targets[0]["y"])

		# --- STRATEGY D: Hostile Tactical Commander Strikes ---
		if sim.battle_phase != "recon" and sim.enemy_oil >= 180:
			if sim.enemy_commander_powers.get("artillery_barrage", 0.0) <= 0.0:
				for pu in sim.units:
					if pu["alive"] and pu["faction"] == "player" and pu["kind"] != "helicopter":
						var p_pos = Vector2(pu["x"], pu["y"])
						var nearby_count = 0
						for other in sim.units:
							if other["alive"] and other["faction"] == "player" and Vector2(other["x"], other["y"]).distance_to(p_pos) < 130.0:
								nearby_count += 1
						if nearby_count >= 2:
							sim.call_commander_power("artillery_barrage", p_pos, "enemy")
							break

		# --- STRATEGY E: Combined Arms Wave Formation ---
		var is_wave_surge = (sim.ai_wave_count % 3 == 0) and (sim.enemy_oil >= 160)
		if is_wave_surge:
			_spawn_combined_arms_wave(sim, ehq, target_pos)
		else:
			_spawn_reinforcement(sim, ehq, target_pos)

static func _update_enemy_engineer(sim, eng: Dictionary) -> void:
	for b in sim.map["bridges"]:
		if b["status"] == "destroyed":
			var b_pos = Vector2(b["x"], b["y"])
			var eng_pos = Vector2(eng["x"], eng["y"])
			if eng_pos.distance_to(b_pos) <= 46.0:
				if sim.enemy_oil >= Constants.BRIDGE_REBUILD_COST:
					sim.rebuild_bridge(b["id"], "enemy")
					eng["targetPos"] = null
					eng["targetBridgeId"] = null
					return
			elif eng["targetPos"] == null:
				eng["targetPos"] = b_pos
				eng["targetBridgeId"] = b["id"]
				eng["stance"] = "move"

static func _spawn_combined_arms_wave(sim, ehq: Dictionary, target_pos: Vector2) -> void:
	# Heavy spearhead
	if sim.enemy_oil >= Constants.UNIT_SPECS["behemoth"]["cost"]:
		sim.enemy_oil -= Constants.UNIT_SPECS["behemoth"]["cost"]
		var beh = sim.spawn_unit("enemy", "behemoth", ehq["x"] - 90.0, ehq["y"] + randf_range(-25, 25))
		beh["targetPos"] = target_pos
		beh["stance"] = "attack"
	elif sim.enemy_oil >= Constants.UNIT_SPECS["tank"]["cost"]:
		sim.enemy_oil -= Constants.UNIT_SPECS["tank"]["cost"]
		var t = sim.spawn_unit("enemy", "tank", ehq["x"] - 80.0, ehq["y"] + randf_range(-25, 25))
		t["targetPos"] = target_pos
		t["stance"] = "attack"

	# Air or artillery fire support
	if sim.enemy_oil >= Constants.UNIT_SPECS["helicopter"]["cost"] and randf() < 0.6:
		sim.enemy_oil -= Constants.UNIT_SPECS["helicopter"]["cost"]
		var h = sim.spawn_unit("enemy", "helicopter", ehq["x"] - 70.0, ehq["y"] + randf_range(-40, 40))
		h["targetPos"] = target_pos
		h["stance"] = "attack"
	elif sim.enemy_oil >= Constants.UNIT_SPECS["artillery"]["cost"]:
		sim.enemy_oil -= Constants.UNIT_SPECS["artillery"]["cost"]
		var a = sim.spawn_unit("enemy", "artillery", ehq["x"] - 95.0, ehq["y"] + randf_range(-30, 30))
		a["targetPos"] = target_pos
		a["stance"] = "attack"

	# Fast flank scout
	if sim.enemy_oil >= Constants.UNIT_SPECS["scout"]["cost"]:
		sim.enemy_oil -= Constants.UNIT_SPECS["scout"]["cost"]
		var s = sim.spawn_unit("enemy", "scout", ehq["x"] - 65.0, ehq["y"] + randf_range(-45, 45))
		s["targetPos"] = target_pos + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		s["stance"] = "attack"

static func _spawn_reinforcement(sim, ehq: Dictionary, target_pos: Vector2) -> void:
	var roll = randf()
	if sim.enemy_oil >= Constants.UNIT_SPECS["behemoth"]["cost"] and roll < 0.18:
		sim.enemy_oil -= Constants.UNIT_SPECS["behemoth"]["cost"]
		var b_unit = sim.spawn_unit("enemy", "behemoth", ehq["x"] - 100.0, ehq["y"] + randf_range(-30, 30))
		b_unit["targetPos"] = target_pos
		b_unit["stance"] = "attack"
	elif sim.enemy_oil >= Constants.UNIT_SPECS["helicopter"]["cost"] and roll < 0.38:
		sim.enemy_oil -= Constants.UNIT_SPECS["helicopter"]["cost"]
		var heli = sim.spawn_unit("enemy", "helicopter", ehq["x"] - 80.0, ehq["y"] + randf_range(-50, 50))
		heli["targetPos"] = target_pos
		heli["stance"] = "attack"
	elif sim.enemy_oil >= Constants.UNIT_SPECS["artillery"]["cost"] and roll < 0.58:
		sim.enemy_oil -= Constants.UNIT_SPECS["artillery"]["cost"]
		var art = sim.spawn_unit("enemy", "artillery", ehq["x"] - 90.0, ehq["y"] + randf_range(-40, 40))
		art["targetPos"] = target_pos
		art["stance"] = "attack"
	elif sim.enemy_oil >= Constants.UNIT_SPECS["tank"]["cost"] and roll < 0.85:
		sim.enemy_oil -= Constants.UNIT_SPECS["tank"]["cost"]
		var t = sim.spawn_unit("enemy", "tank", ehq["x"] - 80.0, ehq["y"] + randf_range(-30, 30))
		t["targetPos"] = target_pos
		t["stance"] = "attack"
	elif sim.enemy_oil >= Constants.UNIT_SPECS["scout"]["cost"]:
		sim.enemy_oil -= Constants.UNIT_SPECS["scout"]["cost"]
		var s = sim.spawn_unit("enemy", "scout", ehq["x"] - 70.0, ehq["y"] + randf_range(-50, 50))
		s["targetPos"] = target_pos
		s["stance"] = "attack"

static func check_win_loss(sim) -> void:
	if sim.map["enemyHQ"]["hp"] <= 0.0:
		sim.phase = "gameover"
		sim.outcome = "victory"
		sim.sound_triggered.emit("victory")
		sim.push_event("victory", "good")
	elif sim.map["playerHQ"]["hp"] <= 0.0:
		sim.phase = "gameover"
		sim.outcome = "defeat"
		sim.sound_triggered.emit("defeat")
		sim.push_event("defeat", "warn")
