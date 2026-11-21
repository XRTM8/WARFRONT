class_name SimCombat
extends RefCounted

const Constants = preload("res://scripts/constants.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")

static func award_unit_xp(sim, unit: Dictionary, amount: float) -> bool:
	if not unit["alive"] or unit["kind"] == "truck" or amount <= 0.0:
		return false
	unit["xp"] += amount
	
	var target_rank = unit["rank"]
	for i in range(Constants.VETERANCY_RANKS.size() - 1, 0, -1):
		if unit["xp"] >= Constants.VETERANCY_RANKS[i]["xpRequired"]:
			target_rank = Constants.VETERANCY_RANKS[i]["rank"]
			break
			
	if target_rank <= unit["rank"]:
		return false
		
	var spec = Constants.UNIT_SPECS[unit["kind"]]
	var next_rank_spec = Constants.VETERANCY_RANKS[target_rank]
	var prev_max_hp = unit["maxHp"]
	var next_max_hp = round(spec["hp"] * next_rank_spec["hpMultiplier"])
	var next_damage = round(spec["damage"] * next_rank_spec["damageMultiplier"])
	
	unit["rank"] = target_rank
	unit["maxHp"] = next_max_hp
	unit["damage"] = next_damage
	var heal_bonus = (next_max_hp - prev_max_hp) + round(spec["hp"] * 0.18)
	unit["hp"] = min(unit["maxHp"], unit["hp"] + heal_bonus)
	unit["promoFlash"] = 0.7
	sim.spawn_particle("ring", unit["x"], unit["y"], 0.0, 0.0, unit["radius"], unit["radius"] + 28.0, 0.42, Color("#ffd659"))
	
	var rank_tag = "[R-%d]" % target_rank
	sim.spawn_floating_text(unit["x"], unit["y"] - unit["radius"] - 16.0, "%s %s" % [rank_tag, next_rank_spec["badgeLabel"]], Color("#ffd659"), 1.5)
	sim.spawn_burst(unit["x"], unit["y"], "spark", 10, Color("#ffe37d"), 75.0)
	
	if unit["faction"] == "player":
		sim.sound_triggered.emit("promotion")
		if sim.phase == "playing":
			sim.push_event("unit_promoted", "good")
		sim.notify_directive("promote_veteran")
	return true

static func fire_projectile(sim, attacker: Dictionary, target_pos: Vector2) -> void:
	var pr_kind = "bullet"
	if attacker["kind"] == "behemoth":
		pr_kind = "shell"
		sim.sound_triggered.emit("behemoth_cannon")
		sim.camera_trauma = min(1.0, sim.camera_trauma + 0.14)
	elif attacker["kind"] == "tank":
		pr_kind = "shell"
		sim.sound_triggered.emit("cannon")
	elif attacker["kind"] == "artillery":
		pr_kind = "shell"
		sim.sound_triggered.emit("cannon")
	elif attacker["kind"] == "helicopter":
		pr_kind = "bullet"
		sim.sound_triggered.emit("rapid_fire")
	else:
		sim.sound_triggered.emit("shot")
		
	var start_pos = Vector2(attacker["x"], attacker["y"])
	var dir = (target_pos - start_pos).normalized()
	var total_dist = start_pos.distance_to(target_pos)
	var speed = 480.0 if pr_kind == "bullet" else 360.0
	
	# Eject brass shell casing to the side
	var t_ang = attacker.get("turretAngle", dir.angle())
	var c_ang = t_ang - PI * 0.5 + randf_range(-0.25, 0.25)
	var c_vel = Vector2(cos(c_ang), sin(c_ang)) * randf_range(30.0, 65.0)
	sim.spawn_particle("casing", start_pos.x, start_pos.y, c_vel.x, c_vel.y, 2.0, 2.0, 0.55, Color("#fde047"))
	
	var bridge_bonus = 1.0
	if Constants.UNIT_SPECS.has(attacker.get("kind", "")):
		bridge_bonus = Constants.UNIT_SPECS[attacker["kind"]].get("bridgeBonus", 1.0)
	
	sim.projectiles.push_back({
		"id": sim.next_projectile_id,
		"sourceUnitId": attacker.get("id", -1),
		"faction": attacker["faction"],
		"kind": pr_kind,
		"x": start_pos.x,
		"y": start_pos.y,
		"startX": start_pos.x,
		"startY": start_pos.y,
		"totalDist": total_dist,
		"vx": dir.x * speed,
		"vy": dir.y * speed,
		"targetX": target_pos.x,
		"targetY": target_pos.y,
		"damage": attacker["damage"],
		"bridgeMultiplier": bridge_bonus,
		"life": 1.5
	})
	sim.next_projectile_id += 1

static func update_projectiles(sim, dt: float) -> void:
	for i in range(sim.projectiles.size() - 1, -1, -1):
		var p = sim.projectiles[i]
		p["life"] -= dt
		p["x"] += p["vx"] * dt
		p["y"] += p["vy"] * dt
		
		var arrived = Vector2(p["x"], p["y"]).distance_to(Vector2(p["targetX"], p["targetY"])) < 14.0
		if arrived or p["life"] <= 0.0:
			detonate_projectile(sim, p)
			sim.projectiles.remove_at(i)

static func detonate_projectile(sim, p: Dictionary) -> void:
	var is_rocket = p["kind"] == "rocket"
	var is_shell = p["kind"] == "shell"
	var radius = 28.0 if is_rocket else (22.0 if is_shell else 10.0)
	
	if is_rocket:
		sim.spawn_burst(p["x"], p["y"], "fire", 16, Color("#ff7a22"), 110.0)
		sim.spawn_burst(p["x"], p["y"], "smoke", 12, Color("#2a2622"), 65.0)
		sim.spawn_particle("ring", p["x"], p["y"], 0.0, 0.0, 10.0, 66.0, 0.32, Color("#ffbe55"))
		sim.add_crater(p["x"], p["y"], 18.0, false)
		sim.camera_trauma = min(1.0, sim.camera_trauma + 0.35)
		sim.sound_triggered.emit("explosion")
	elif is_shell:
		sim.spawn_burst(p["x"], p["y"], "fire", 10, Color("#ffaa38"), 80.0)
		sim.spawn_burst(p["x"], p["y"], "spark", 8, Color("#ffe399"), 95.0)
		sim.spawn_particle("ring", p["x"], p["y"], 0.0, 0.0, 6.0, 44.0, 0.25, Color("#ffaa44"))
		sim.add_crater(p["x"], p["y"], 11.0, false)
		sim.camera_trauma = min(1.0, sim.camera_trauma + 0.22)
		sim.sound_triggered.emit("explosion")
	else:
		sim.spawn_burst(p["x"], p["y"], "spark", 4, Color("#ffe28a"), 55.0)
	
	var attacker_unit = null
	for u in sim.units:
		if u["id"] == p["sourceUnitId"]:
			attacker_unit = u
			break
			
	# Damage hostile units
	for u in sim.units:
		if u["alive"] and sim.are_hostile(p, u):
			var d = Vector2(u["x"], u["y"]).distance_to(Vector2(p["x"], p["y"]))
			if d <= radius + u["radius"]:
				damage_unit(sim, u, p["damage"], attacker_unit)
				
	# Damage hostile HQs
	var all_hqs = sim.map.get("hqs", [sim.map["enemyHQ"], sim.map["playerHQ"]])
	for hq in all_hqs:
		if sim.are_hostile(p, hq):
			if Vector2(p["x"], p["y"]).distance_to(Vector2(hq["x"], hq["y"])) < radius + 40.0:
				var dealt = min(hq["hp"], p["damage"])
				hq["hp"] = max(0.0, hq["hp"] - p["damage"])
				hq["hitFlash"] = 0.08
				sim.spawn_floating_text(hq["x"], hq["y"] - 32.0, "-%d" % int(round(dealt)), Color("#ef4444"), 0.8)
		
	# Damage bridge if hit
	var bridge = Pathfinding.get_bridge_at_world(sim.map, p["x"], p["y"], radius * 0.65)
	if not bridge.is_empty() and bridge["status"] == "intact":
		damage_bridge(sim, bridge, p["damage"] * p["bridgeMultiplier"], p["faction"], attacker_unit)

static func damage_unit(sim, u: Dictionary, amount: float, attacker: Variant = null) -> void:
	if not u["alive"]:
		return
		
	# Combat Surge dynamic modifiers
	if u["faction"] == "player" and sim.combat_surge_active:
		amount *= 0.82 # 18% defensive armor reinforcement in surge
	if attacker != null and attacker.get("faction", "") == "player" and sim.combat_surge_active:
		amount *= 1.20 # 20% offensive damage amplification in surge
		
	var applied = min(u["hp"], max(0.0, amount))
	u["hp"] -= amount
	u["hitFlash"] = 0.065
	
	# Floating damage number with critical hit flair
	if amount >= 40.0:
		sim.spawn_floating_text(u["x"], u["y"] - u["radius"] - 8.0, "-[%d CRIT]" % int(round(amount)), Color("#ef4444"), 0.85)
		sim.spawn_burst(u["x"], u["y"], "spark", 7, Color("#fde047"), 85.0)
	else:
		sim.spawn_floating_text(u["x"], u["y"] - u["radius"] - 6.0, "-%d" % int(round(amount)), Color("#fca5a5"), 0.7)
		sim.spawn_burst(u["x"], u["y"], "spark", 3, Color("#ffe28a"), 50.0)
	
	if attacker != null and attacker.get("alive", false) and applied > 0.0:
		award_unit_xp(sim, attacker, applied * Constants.XP_PER_DAMAGE)
		
	if u["hp"] <= 0.0:
		u["hp"] = 0.0
		u["alive"] = false
		var is_truck = u["kind"] == "truck"
		var is_heavy = u["kind"] == "tank" or u["kind"] == "behemoth" or u["kind"] == "artillery" or u["kind"] == "turret"
		
		# Add persistent smoking battlefield wreckage
		sim.add_wreck(u["kind"], u["x"], u["y"], u["angle"])
		
		# Catastrophic Ammo Rack Detonation (Flying Turret Physics)
		if (u["kind"] == "tank" or u["kind"] == "behemoth" or u["kind"] == "artillery"):
			var is_overkill = (amount > 45.0)
			if is_overkill or randf() < 0.42:
				sim.flying_turrets.push_back({
					"x": u["x"],
					"y": u["y"],
					"z": 0.0,
					"vx": randf_range(-35.0, 35.0),
					"vy": randf_range(-35.0, 35.0),
					"vz": randf_range(160.0, 230.0),
					"angle": u.get("turretAngle", 0.0),
					"v_rot": randf_range(-8.0, 8.0),
					"kind": u["kind"],
					"gravity": 320.0,
					"faction": u["faction"],
					"life": 3.0
				})
				sim.spawn_particle("ring", u["x"], u["y"], 0.0, 0.0, 10.0, 65.0, 0.35, Color("#ffffff"))
				sim.camera_trauma = min(1.0, sim.camera_trauma + 0.35)
				sim.spawn_floating_text(u["x"], u["y"] - 22.0, "[ AMMO DETONATION // تفجير ذخائر ]", Color("#f59e0b"), 1.25)
		
		# Secondary Chain Explosions for volatile vehicles
		if is_truck or (is_heavy and randf() < 0.35):
			for other in sim.units:
				if other["id"] != u["id"] and other["alive"] and other["kind"] == "truck":
					var dist_sq = Vector2(u["x"], u["y"]).distance_squared_to(Vector2(other["x"], other["y"]))
					if dist_sq < 2304.0: # within 48px
						damage_unit(sim, other, 70.0, attacker)
		
		if is_truck:
			sim.spawn_burst(u["x"], u["y"], "fire", 24, Color("#ff6818"), 140.0)
			sim.spawn_burst(u["x"], u["y"], "oil", 16, Color("#141210"), 95.0)
			sim.spawn_burst(u["x"], u["y"], "debris", 10, Color("#3f3f46"), 110.0)
			sim.spawn_particle("ring", u["x"], u["y"], 0.0, 0.0, 8.0, 60.0, 0.38, Color("#ff9c33"))
			sim.add_crater(u["x"], u["y"], 22.0, true)
			sim.camera_trauma = min(1.0, sim.camera_trauma + 0.4)
			sim.sound_triggered.emit("explosion")
			if u["faction"] == "enemy":
				sim.enemy_trucks_destroyed += 1
				sim.push_event("truck_ambushed", "good")
				sim.spawn_salvage(u["x"] - 14.0, u["y"] + 6.0, 35)
				sim.spawn_salvage(u["x"] + 14.0, u["y"] - 6.0, 35)
				sim.notify_directive("ambush_truck")
		else:
			sim.spawn_burst(u["x"], u["y"], "fire", 18 if is_heavy else 10, Color("#ff8628"), 110.0)
			sim.spawn_burst(u["x"], u["y"], "smoke", 14 if is_heavy else 7, Color("#262422"), 75.0)
			sim.spawn_burst(u["x"], u["y"], "debris", 12 if is_heavy else 6, Color("#3f3f46"), 125.0)
			sim.spawn_particle("ring", u["x"], u["y"], 0.0, 0.0, 8.0, 52.0 if is_heavy else 36.0, 0.3, Color("#ffaa44"))
			sim.add_crater(u["x"], u["y"], 16.0 if is_heavy else 11.0, false)
			sim.camera_trauma = min(1.0, sim.camera_trauma + (0.45 if is_heavy else 0.25))
			sim.sound_triggered.emit("explosion")
			if is_heavy:
				sim.hitstop_timer = 0.045
				if u["faction"] == "enemy":
					sim.notify_directive("destroy_heavy")
		
		# Record Player Kill for Multi-kill combos & adrenaline momentum
		if u["faction"] == "enemy":
			sim.record_player_kill(u["kind"], Vector2(u["x"], u["y"]))
		
		if attacker != null and attacker.get("alive", false):
			attacker["kills"] += 1
			var kill_xp = Constants.XP_KILL_HEAVY if is_heavy else Constants.XP_KILL_LIGHT
			award_unit_xp(sim, attacker, kill_xp)

static func damage_bridge(sim, bridge: Dictionary, amount: float, attacker_faction: String, attacker_unit: Variant = null) -> void:
	if bridge["status"] != "intact":
		return
	var applied = min(bridge["hp"], max(0.0, amount))
	bridge["hp"] -= amount
	bridge["hitFlash"] = 0.08
	
	sim.spawn_floating_text(bridge["x"], bridge["y"] - 14.0, "-%d" % int(round(amount)), Color("#f59e0b"), 0.75)
	
	if attacker_unit != null and attacker_unit.get("alive", false) and applied > 0.0:
		award_unit_xp(sim, attacker_unit, applied * Constants.XP_PER_DAMAGE * 0.6)
		
	if bridge["hp"] <= 0.0:
		bridge["hp"] = 0.0
		bridge["status"] = "destroyed"
		sim.hitstop_timer = 0.07
		sim.camera_trauma = min(1.0, sim.camera_trauma + 0.75)
		sim.spawn_burst(bridge["x"], bridge["y"], "fire", 28, Color("#ff6d1f"), 155.0)
		sim.spawn_burst(bridge["x"], bridge["y"], "debris", 22, Color("#69645b"), 140.0)
		sim.spawn_burst(bridge["x"], bridge["y"], "splash", 16, Color("#8ac7da"), 120.0)
		sim.spawn_particle("ring", bridge["x"], bridge["y"], 0.0, 0.0, 14.0, 96.0, 0.45, Color("#ffc152"))
		sim.add_crater(bridge["x"], bridge["y"], 24.0, false)
		sim.sound_triggered.emit("bridge_collapse")
		
		# Demolish any vehicle crossing the span
		for u in sim.units:
			if u["alive"] and abs(u["x"] - bridge["x"]) <= bridge["width"] * 0.5 and abs(u["y"] - bridge["y"]) <= bridge["height"] * 0.5:
				damage_unit(sim, u, u["maxHp"] + 50.0, attacker_unit)
				sim.spawn_burst(u["x"], u["y"], "splash", 12, Color("#8cc8db"), 85.0)
				
		if attacker_faction == "player":
			sim.bridges_destroyed_by_player += 1
			sim.push_event("bridge_destroyed", "good")
		if attacker_unit != null and attacker_unit.get("alive", false):
			award_unit_xp(sim, attacker_unit, Constants.XP_BRIDGE_DEMOLISH)
		sim.reroute_stranded_trucks()

static func update_flying_turrets(sim, dt: float) -> void:
	for i in range(sim.flying_turrets.size() - 1, -1, -1):
		var ft = sim.flying_turrets[i]
		ft["vz"] -= ft["gravity"] * dt
		ft["z"] += ft["vz"] * dt
		ft["x"] += ft["vx"] * dt
		ft["y"] += ft["vy"] * dt
		ft["angle"] += ft["v_rot"] * dt
		ft["life"] -= dt
		
		# Trailing smoke & spark particles
		if randf() < 0.6:
			var spos = Vector2(ft["x"], ft["y"] - ft["z"])
			sim.spawn_particle("smoke", spos.x, spos.y, randf_range(-4, 4), randf_range(-4, 4), 3.0, 10.0, 0.45, Color(0.2, 0.18, 0.16, 0.8))
			sim.spawn_particle("spark", spos.x, spos.y, randf_range(-8, 8), randf_range(-8, 8), 2.0, 1.0, 0.25, Color("#f59e0b"))
			
		# Impact with ground
		if ft["z"] <= 0.0 or ft["life"] <= 0.0:
			var ix = ft["x"]
			var iy = ft["y"]
			sim.sound_triggered.emit("turret_crash")
			sim.camera_trauma = min(1.0, sim.camera_trauma + 0.32)
			sim.add_crater(ix, iy, 12.0, false)
			sim.spawn_burst(ix, iy, "debris", 12, Color("#3f3f46"), 95.0)
			sim.spawn_burst(ix, iy, "spark", 8, Color("#facc15"), 75.0)
			sim.spawn_particle("ring", ix, iy, 0.0, 0.0, 6.0, 36.0, 0.25, Color("#f59e0b"))
			sim.spawn_floating_text(ix, iy - 10.0, "[ TURRET IMPACT // ارتطام البرج ]", Color("#fbbf24"), 0.9)
			
			# Radial blast damage to nearby hostile units
			for u in sim.units:
				if u["alive"] and sim.are_hostile(ft, u):
					if Vector2(u["x"], u["y"]).distance_to(Vector2(ix, iy)) <= 32.0 + u["radius"]:
						damage_unit(sim, u, 45.0)
						
			sim.flying_turrets.remove_at(i)

static func update_napalm_patches(sim, dt: float) -> void:
	for i in range(sim.napalm_patches.size() - 1, -1, -1):
		var np = sim.napalm_patches[i]
		np["life"] -= dt
		
		# Napalm fire particles
		if randf() < 0.35:
			var ang = randf() * TAU
			var dist = randf() * np["radius"] * 0.85
			sim.spawn_particle("fire", np["x"] + cos(ang) * dist, np["y"] + sin(ang) * dist, 0.0, -18.0, 4.0, 1.0, 0.35, Color("#ea580c"))
			
		# Damage opposing units
		for u in sim.units:
			if u["alive"] and sim.are_hostile(np, u):
				if Vector2(u["x"], u["y"]).distance_to(Vector2(np["x"], np["y"])) <= np["radius"] + u["radius"]:
					damage_unit(sim, u, 35.0 * dt)
					if randf() < 0.15:
						sim.spawn_burst(u["x"], u["y"], "spark", 2, Color("#f97316"), 40.0)
						
		if np["life"] <= 0.0:
			sim.napalm_patches.remove_at(i)

static func update_landmines(sim, dt: float) -> void:
	for i in range(sim.landmines.size() - 1, -1, -1):
		var lm = sim.landmines[i]
		lm["life"] -= dt
		if lm["life"] <= 0.0:
			sim.landmines.remove_at(i)
			continue
			
		var lm_pos = Vector2(lm["x"], lm["y"])
		var triggered = false
		
		for u in sim.units:
			if u["alive"] and sim.are_hostile(lm, u) and u["kind"] != "helicopter":
				if Vector2(u["x"], u["y"]).distance_to(lm_pos) <= 20.0 + u["radius"]:
					triggered = true
					# Massive AT detonation
					sim.sound_triggered.emit("mine_detonate")
					sim.camera_trauma = min(1.0, sim.camera_trauma + 0.45)
					sim.add_crater(lm["x"], lm["y"], 16.0, false)
					sim.spawn_burst(lm["x"], lm["y"], "fire", 20, Color("#f97316"), 120.0)
					sim.spawn_burst(lm["x"], lm["y"], "debris", 14, Color("#3f3f46"), 110.0)
					sim.spawn_particle("ring", lm["x"], lm["y"], 0.0, 0.0, 8.0, 52.0, 0.32, Color("#f59e0b"))
					
					u["stunTimer"] = lm.get("stun_duration", 4.5)
					u["recoil"] = 8.0
					sim.spawn_floating_text(u["x"], u["y"] - u["radius"] - 14.0, "[ MINE DETONATION // شلل بالحركة ]", Color("#ef4444"), 1.25)
					damage_unit(sim, u, lm["damage"])
					break
					
		if triggered:
			sim.landmines.remove_at(i)

