class_name SimUnitAbilities
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func deploy_landmine_at(sim, faction: String, pos: Vector2) -> bool:
	var spec = Constants.VETERAN_ABILITIES["engineer"]
	if faction == "player":
		if sim.player_oil < spec["cost"]:
			sim.push_event("not_enough_oil", "warn")
			return false
		sim.player_oil -= spec["cost"]
		
	sim.landmines.push_back({
		"id": randi(),
		"x": pos.x,
		"y": pos.y,
		"faction": faction,
		"damage": spec["damage"],
		"stun_duration": spec["stun_duration"],
		"life": 220.0
	})
	sim.spawn_particle("ring", pos.x, pos.y, 0.0, 0.0, 4.0, 26.0, 0.3, Color("#22c55e"))
	sim.sound_triggered.emit("capture")
	sim.spawn_floating_text(pos.x, pos.y - 14.0, "[ AT-MINE ARMED // لغم الدروع نشط ]", Color("#84cc16"), 1.1)
	return true

static func execute_unit_ability(sim, u: Dictionary, target_pos: Vector2) -> bool:
	if not u.get("alive", false) or u.get("stunTimer", 0.0) > 0.0:
		return false
	if u.get("abilityCooldown", 0.0) > 0.0:
		return false
		
	var kind = u["kind"]
	if not Constants.VETERAN_ABILITIES.has(kind):
		return false
		
	var spec = Constants.VETERAN_ABILITIES[kind]
	if u["rank"] < spec["min_rank"]:
		return false
		
	u["abilityCooldown"] = spec["cooldown"]
	u["hitFlash"] = 0.1
	
	if kind == "tank":
		# Incendiary Piercing Shot & Napalm Patch
		u["recoil"] = 9.0
		sim.sound_triggered.emit("cannon")
		sim.camera_trauma = min(1.0, sim.camera_trauma + 0.35)
		
		var start_p = Vector2(u["x"], u["y"])
		var dir = (target_pos - start_p).normalized()
		var dist = start_p.distance_to(target_pos)
		
		sim.projectiles.push_back({
			"id": sim.next_projectile_id,
			"sourceUnitId": u["id"],
			"faction": u["faction"],
			"kind": "shell",
			"x": start_p.x,
			"y": start_p.y,
			"startX": start_p.x,
			"startY": start_p.y,
			"totalDist": dist,
			"vx": dir.x * 550.0,
			"vy": dir.y * 550.0,
			"targetX": target_pos.x,
			"targetY": target_pos.y,
			"damage": spec["damage"],
			"bridgeMultiplier": 1.5,
			"life": 1.2
		})
		sim.next_projectile_id += 1
		
		sim.napalm_patches.push_back({
			"x": target_pos.x,
			"y": target_pos.y,
			"radius": spec["napalm_radius"],
			"life": spec["napalm_duration"],
			"faction": u["faction"]
		})
		sim.spawn_burst(target_pos.x, target_pos.y, "fire", 22, Color("#ea580c"), 110.0)
		sim.spawn_floating_text(u["x"], u["y"] - 22.0, "[ INCENDIARY SHELL // قذيفة حارقة ]", Color("#f97316"), 1.2)
		return true
		
	elif kind == "behemoth":
		# Seismic Overcharge Barrage (Stun + Heavy Shockwave)
		u["recoil"] = 14.0
		sim.sound_triggered.emit("behemoth_cannon")
		sim.camera_trauma = min(1.0, sim.camera_trauma + 0.65)
		sim.spawn_particle("ring", target_pos.x, target_pos.y, 0.0, 0.0, 16.0, 110.0, 0.45, Color("#ef4444"))
		sim.add_crater(target_pos.x, target_pos.y, 22.0, false)
		sim.spawn_burst(target_pos.x, target_pos.y, "fire", 26, Color("#ff4444"), 135.0)
		sim.spawn_floating_text(target_pos.x, target_pos.y - 28.0, "[ SEISMIC IMPACT // صدمة زلزالية ]", Color("#ef4444"), 1.5)
		
		var opp = "enemy" if u["faction"] == "player" else "player"
		for target in sim.units:
			if target["alive"] and target["faction"] == opp:
				if Vector2(target["x"], target["y"]).distance_to(target_pos) <= spec["stun_radius"] + target["radius"]:
					target["stunTimer"] = spec["stun_duration"]
					target["recoil"] = 8.0
					sim.damage_unit(target, spec["damage"], u)
		return true
		
	elif kind == "helicopter":
		# Hydra Rocket Salvo (4 spiraling micro-missiles)
		sim.sound_triggered.emit("hydra_salvo")
		sim.spawn_floating_text(u["x"], u["y"] - 22.0, "[ HYDRA VOLLEY // صواريخ هايدرا ]", Color("#38bdf8"), 1.25)
		var start_p = Vector2(u["x"], u["y"])
		var dir = (target_pos - start_p).normalized()
		var dist = start_p.distance_to(target_pos)
		
		for r in range(spec["rocket_count"]):
			var side_offset = Vector2(-dir.y, dir.x) * ((float(r) - 1.5) * 9.0)
			sim.projectiles.push_back({
				"id": sim.next_projectile_id,
				"sourceUnitId": u["id"],
				"faction": u["faction"],
				"kind": "rocket",
				"x": start_p.x + side_offset.x,
				"y": start_p.y + side_offset.y,
				"startX": start_p.x,
				"startY": start_p.y,
				"totalDist": dist,
				"vx": (dir.x + randf_range(-0.12, 0.12)) * 430.0,
				"vy": (dir.y + randf_range(-0.12, 0.12)) * 430.0,
				"targetX": target_pos.x + randf_range(-16, 16),
				"targetY": target_pos.y + randf_range(-16, 16),
				"damage": spec["damage"],
				"bridgeMultiplier": 1.0,
				"life": 1.4
			})
			sim.next_projectile_id += 1
		return true
		
	elif kind == "engineer":
		return deploy_landmine_at(sim, u["faction"], Vector2(u["x"], u["y"]))
		
	return false

static func execute_selected_ability(sim, target_pos: Vector2) -> bool:
	var selected: Array[Dictionary] = []
	for u in sim.units:
		if u["alive"] and u["faction"] == "player" and u["selected"] and u["kind"] != "truck" and u["kind"] != "turret":
			selected.append(u)
	for u in selected:
		if execute_unit_ability(sim, u, target_pos):
			return true
	return false
