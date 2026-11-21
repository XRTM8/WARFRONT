class_name SimCommander
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")

static func init_commander_state(sim) -> void:
	sim.commander_powers = {
		"airstrike": 0.0,
		"artillery_barrage": 0.0,
		"recon_drone": 0.0,
		"supply_drop": 0.0
	}
	sim.enemy_commander_powers = {
		"airstrike": 35.0,
		"artillery_barrage": 25.0
	}
	sim.salvage_crates.clear()
	sim.active_airstrikes.clear()
	sim.active_barrages.clear()
	sim.active_recon_sweeps.clear()
	sim.battle_phase = "recon"
	sim.active_directive.clear()
	sim.directive_cycle_timer = 3.0
	sim.commander_targeting_power = ""

static func update_commander(sim, dt: float) -> void:
	# 1. Update Cooldown Timers
	for p in sim.commander_powers:
		sim.commander_powers[p] = max(0.0, sim.commander_powers[p] - dt)
	for p in sim.enemy_commander_powers:
		sim.enemy_commander_powers[p] = max(0.0, sim.enemy_commander_powers[p] - dt)

	# 2. Strategic Escalation Phases
	_update_escalation_phases(sim)

	# 3. Update Active Airstrikes (Supersonic Jet Flybys & Bombing Runs)
	_update_airstrikes(sim, dt)

	# 4. Update Active Off-Map Artillery Barrages
	_update_barrages(sim, dt)

	# 5. Update Active Recon Drone Sweeps
	_update_recon_sweeps(sim, dt)

	# 6. Update Salvage Crates & Ground Pickups
	_update_salvage(sim, dt)

	# 7. Update Dynamic Tactical Directives
	_update_directives(sim, dt)

# ------------------------------------------------------------------------------
# 1. Escalation Phases (Pacing & Threat Levels)
# ------------------------------------------------------------------------------

static func _update_escalation_phases(sim) -> void:
	var phq = sim.map["playerHQ"]
	var ehq = sim.map["enemyHQ"]
	var hq_critical = (phq["hp"] < phq["maxHp"] * 0.45) or (ehq["hp"] < ehq["maxHp"] * 0.45)
	
	if sim.battle_phase == "recon" and (sim.elapsed_seconds >= 85.0 or hq_critical):
		sim.battle_phase = "escalation"
		sim.sound_triggered.emit("siren")
		sim.push_event("phase_escalation", "warn")
	elif sim.battle_phase == "escalation" and (sim.elapsed_seconds >= 190.0 or hq_critical):
		sim.battle_phase = "total_war"
		sim.sound_triggered.emit("siren")
		sim.push_event("phase_total_war", "warn")

# ------------------------------------------------------------------------------
# 2. Commander Power Trigger Execution
# ------------------------------------------------------------------------------

static func call_commander_power(sim, power_id: String, target_world: Vector2, faction: String = "player") -> bool:
	if not Constants.COMMANDER_POWERS.has(power_id):
		return false
		
	var spec = Constants.COMMANDER_POWERS[power_id]
	if faction == "player":
		if sim.commander_powers.get(power_id, 0.0) > 0.0:
			sim.push_event("power_on_cooldown", "warn")
			return false
		if sim.player_oil < spec["cost"]:
			sim.push_event("not_enough_oil", "warn")
			return false
		sim.player_oil -= spec["cost"]
		sim.commander_powers[power_id] = spec["cooldown"]
	else:
		if sim.enemy_oil < spec["cost"]:
			return false
		sim.enemy_oil -= spec["cost"]
		sim.enemy_commander_powers[power_id] = spec["cooldown"]

	if power_id == "airstrike":
		_trigger_airstrike(sim, target_world, faction)
	elif power_id == "artillery_barrage":
		_trigger_barrage(sim, target_world, faction)
	elif power_id == "recon_drone":
		_trigger_recon(sim, target_world, faction)
	elif power_id == "supply_drop":
		_trigger_supply_drop(sim, target_world, faction)

	return true

# ------------------------------------------------------------------------------
# 3. Tactical Strikes Implementation
# ------------------------------------------------------------------------------

static func _trigger_airstrike(sim, target_world: Vector2, faction: String) -> void:
	var angle = randf_range(-0.25, 0.25) if faction == "player" else PI + randf_range(-0.25, 0.25)
	var dir = Vector2(cos(angle), sin(angle))
	var start_pos = target_world - dir * 650.0
	var end_pos = target_world + dir * 650.0
	
	sim.active_airstrikes.push_back({
		"faction": faction,
		"target_pos": target_world,
		"start_pos": start_pos,
		"end_pos": end_pos,
		"dir": dir,
		"progress": 0.0,
		"duration": 0.95,
		"bombs_dropped": 0
	})
	sim.sound_triggered.emit("airstrike_jet")
	sim.push_event("airstrike_inbound", "good" if faction == "player" else "warn")

static func _update_airstrikes(sim, dt: float) -> void:
	for i in range(sim.active_airstrikes.size() - 1, -1, -1):
		var strike = sim.active_airstrikes[i]
		strike["progress"] += dt / strike["duration"]
		var prog = strike["progress"]
		var tgt: Vector2 = strike["target_pos"]
		var dir: Vector2 = strike["dir"]
		
		# Drop 3 clustered penetrating ordnance
		var drop_thresholds = [0.38, 0.50, 0.62]
		for b_idx in range(drop_thresholds.size()):
			if prog >= drop_thresholds[b_idx] and strike["bombs_dropped"] <= b_idx:
				strike["bombs_dropped"] = b_idx + 1
				var offset_dist = (float(b_idx) - 1.0) * 44.0
				var bx = tgt.x + dir.x * offset_dist + randf_range(-12, 12)
				var by = tgt.y + dir.y * offset_dist + randf_range(-12, 12)
				
				# Detonation effects
				sim.spawn_burst(bx, by, "fire", 26, Color("#ff6818"), 145.0)
				sim.spawn_burst(bx, by, "smoke", 18, Color("#1f1c19"), 85.0)
				sim.spawn_particle("ring", bx, by, 0.0, 0.0, 10.0, 75.0, 0.35, Color("#ffbe55"))
				sim.add_crater(bx, by, 20.0, false)
				sim.camera_trauma = min(1.0, sim.camera_trauma + 0.42)
				sim.sound_triggered.emit("explosion")
				
				# Damage hostile units
				var opp_faction = "enemy" if strike["faction"] == "player" else "player"
				for u in sim.units:
					if u["alive"] and u["faction"] == opp_faction:
						var d = Vector2(u["x"], u["y"]).distance_to(Vector2(bx, by))
						if d <= 95.0 + u["radius"]:
							sim.damage_unit(u, 170.0)
				
				# Damage bridge if hit
				var bridge = Pathfinding.get_bridge_at_world(sim.map, bx, by, 48.0)
				if not bridge.is_empty() and bridge["status"] == "intact":
					sim.damage_bridge(bridge, 220.0, strike["faction"])

		if prog >= 1.0:
			sim.active_airstrikes.remove_at(i)

static func _trigger_barrage(sim, target_world: Vector2, faction: String) -> void:
	sim.active_barrages.push_back({
		"faction": faction,
		"target_pos": target_world,
		"shells_left": 6,
		"timer": 0.35,
		"interval": 0.32,
		"radius": 125.0
	})
	sim.sound_triggered.emit("order_attack")
	sim.push_event("barrage_firing", "good" if faction == "player" else "warn")

static func _update_barrages(sim, dt: float) -> void:
	for i in range(sim.active_barrages.size() - 1, -1, -1):
		var bar = sim.active_barrages[i]
		bar["timer"] -= dt
		if bar["timer"] <= 0.0 and bar["shells_left"] > 0:
			bar["shells_left"] -= 1
			bar["timer"] = bar["interval"]
			
			var ang = randf() * TAU
			var rad = randf() * bar["radius"]
			var sx = bar["target_pos"].x + cos(ang) * rad
			var sy = bar["target_pos"].y + sin(ang) * rad
			
			sim.spawn_burst(sx, sy, "fire", 18, Color("#ff8822"), 115.0)
			sim.spawn_burst(sx, sy, "spark", 12, Color("#ffe28a"), 110.0)
			sim.spawn_particle("ring", sx, sy, 0.0, 0.0, 8.0, 55.0, 0.28, Color("#ffaa44"))
			sim.add_crater(sx, sy, 14.0, false)
			sim.camera_trauma = min(1.0, sim.camera_trauma + 0.25)
			sim.sound_triggered.emit("explosion")
			
			var opp_faction = "enemy" if bar["faction"] == "player" else "player"
			for u in sim.units:
				if u["alive"] and u["faction"] == opp_faction:
					if Vector2(u["x"], u["y"]).distance_to(Vector2(sx, sy)) <= 48.0 + u["radius"]:
						sim.damage_unit(u, 85.0)
						
		if bar["shells_left"] <= 0 and bar["timer"] <= 0.0:
			sim.active_barrages.remove_at(i)

static func _trigger_recon(sim, target_world: Vector2, faction: String) -> void:
	sim.active_recon_sweeps.push_back({
		"faction": faction,
		"pos": target_world,
		"radius": 220.0,
		"life": 14.0,
		"maxLife": 14.0
	})
	sim.sound_triggered.emit("recon_ping")
	sim.push_event("recon_active", "good")

static func _update_recon_sweeps(sim, dt: float) -> void:
	for i in range(sim.active_recon_sweeps.size() - 1, -1, -1):
		var r = sim.active_recon_sweeps[i]
		r["life"] -= dt
		if r["life"] <= 0.0:
			sim.active_recon_sweeps.remove_at(i)

static func _trigger_supply_drop(sim, target_world: Vector2, _faction: String) -> void:
	# Air drop two heavy crude oil crates
	spawn_salvage(sim, target_world.x - 18.0, target_world.y, 80)
	spawn_salvage(sim, target_world.x + 18.0, target_world.y, 80)
	sim.spawn_burst(target_world.x, target_world.y, "smoke", 14, Color("#dcd3c1"), 60.0)
	sim.sound_triggered.emit("capture")
	sim.push_event("supply_dropped", "good")

# ------------------------------------------------------------------------------
# 4. Salvage Barrels Pickup System
# ------------------------------------------------------------------------------

static func spawn_salvage(sim, x: float, y: float, oil_amount: int) -> void:
	if sim.salvage_crates.size() > 40:
		sim.salvage_crates.pop_front()
	sim.salvage_crates.push_back({
		"id": randi(),
		"x": x,
		"y": y,
		"oil": oil_amount,
		"life": 45.0,
		"maxLife": 45.0
	})

static func _update_salvage(sim, dt: float) -> void:
	for i in range(sim.salvage_crates.size() - 1, -1, -1):
		var c = sim.salvage_crates[i]
		c["life"] -= dt
		if c["life"] <= 0.0:
			sim.salvage_crates.remove_at(i)
			continue
			
		var c_pos = Vector2(c["x"], c["y"])
		var picked = false
		for u in sim.units:
			if u["alive"] and u["kind"] != "helicopter":
				var d = Vector2(u["x"], u["y"]).distance_to(c_pos)
				if d <= 26.0:
					if u["faction"] == "player":
						sim.player_oil += c["oil"]
						sim.player_oil_delivered += c["oil"]
						sim.spawn_floating_text(c["x"], c["y"] - 14.0, "+%d 🛢️ غنائم نفط" % c["oil"], Color("#facc15"), 0.95)
						sim.sound_triggered.emit("salvage_pickup")
						sim.push_event("salvage_collected", "good")
						notify_directive_progress(sim, "ambush_truck")
					else:
						sim.enemy_oil += c["oil"]
					sim.spawn_burst(c["x"], c["y"], "spark", 8, Color("#fbbf24"), 65.0)
					picked = true
					break
		if picked:
			sim.salvage_crates.remove_at(i)

# ------------------------------------------------------------------------------
# 5. Dynamic Tactical Field Directives
# ------------------------------------------------------------------------------

static func _update_directives(sim, dt: float) -> void:
	if sim.active_directive.is_empty():
		sim.directive_cycle_timer -= dt
		if sim.directive_cycle_timer <= 0.0:
			# Pick a fitting directive
			var idx = randi() % Constants.DIRECTIVES_LIST.size()
			var template = Constants.DIRECTIVES_LIST[idx]
			sim.active_directive = {
				"id": template["id"],
				"title": template["title"],
				"desc": template["desc"],
				"reward_oil": template["reward_oil"],
				"progress": 0,
				"target_count": template["target_count"],
				"time_limit": 90.0
			}
			sim.push_event("directive_assigned", "good")
	else:
		sim.active_directive["time_limit"] -= dt
		if sim.active_directive["time_limit"] <= 0.0:
			sim.active_directive.clear()
			sim.directive_cycle_timer = 20.0

static func notify_directive_progress(sim, directive_type: String) -> void:
	if sim.active_directive.is_empty():
		return
	if sim.active_directive.get("id") == directive_type:
		sim.active_directive["progress"] += 1
		if sim.active_directive["progress"] >= sim.active_directive["target_count"]:
			var rew = sim.active_directive["reward_oil"]
			sim.player_oil += rew
			sim.sound_triggered.emit("promotion")
			sim.push_event("directive_complete", "good")
			var phq = sim.map["playerHQ"]
			sim.spawn_floating_text(phq["x"], phq["y"] - 65.0, "🏆 مكافأة الأوامر: +%d 🛢️" % rew, Color("#ffd700"), 1.25)
			sim.active_directive.clear()
			sim.directive_cycle_timer = 24.0
