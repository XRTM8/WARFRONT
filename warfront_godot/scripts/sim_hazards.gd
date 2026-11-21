class_name SimHazards
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func update_hazards(sim, dt: float) -> void:
	update_flying_turrets(sim, dt)
	update_napalm_patches(sim, dt)
	update_landmines(sim, dt)

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
						sim.damage_unit(u, 45.0)
						
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
					sim.damage_unit(u, 35.0 * dt)
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
					sim.damage_unit(u, lm["damage"])
					break
					
		if triggered:
			sim.landmines.remove_at(i)
