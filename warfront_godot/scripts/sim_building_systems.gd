class_name SimBuildingSystems
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func decommission_structure(sim, structure_id: int, faction: String = "player") -> bool:
	for i in range(sim.structures.size()):
		var s = sim.structures[i]
		if s["id"] == structure_id and s["faction"] == faction:
			var spec = Constants.BUILDING_SPECS.get(s["kind"], {})
			var cost = spec.get("cost", 100)
			var refund = int(cost * 0.50)
			
			if faction == "player":
				sim.player_oil += refund
				sim.push_event("structure_decommissioned", "normal")
				sim.spawn_floating_text(s["x"], s["y"] - 20.0, "[ REFUND // +%d OIL ]" % refund, Color("#facc15"), 1.3)
				sim.sound_triggered.emit("capture")
			else:
				sim.enemy_oil += refund
				
			sim.spawn_burst(s["x"], s["y"], "debris", 16, Color("#4b4d45"), 90.0)
			sim.structures.remove_at(i)
			return true
	return false

static func trigger_emergency_repair(sim, structure_id: int, faction: String = "player") -> bool:
	for s in sim.structures:
		if s["id"] == structure_id and s["faction"] == faction:
			var max_hp: float = s.get("maxHp", 500.0)
			var cur_hp: float = s.get("hp", max_hp)
			if cur_hp >= max_hp:
				return false
				
			var repair_cost = 35
			if faction == "player":
				if sim.player_oil < repair_cost:
					sim.push_event("not_enough_oil", "warn")
					return false
				sim.player_oil -= repair_cost
				sim.push_event("repair_started", "good")
			else:
				if sim.enemy_oil < repair_cost:
					return false
				sim.enemy_oil -= repair_cost
				
			s["hp"] = min(max_hp, cur_hp + 160.0)
			sim.spawn_burst(s["x"], s["y"], "spark", 12, Color("#38bdf8"), 70.0)
			sim.spawn_floating_text(s["x"], s["y"] - 22.0, "[ REPAIRED // +160 HP ]", Color("#38bdf8"), 1.2)
			sim.sound_triggered.emit("unit_ready")
			return true
	return false

static func update_building_damage_fx(sim, s: Dictionary, dt: float) -> void:
	var cur_hp: float = s.get("hp", 100.0)
	var max_hp: float = s.get("maxHp", 100.0)
	var ratio = cur_hp / max(1.0, max_hp)
	
	# Below 50% HP: Smoke plume
	if ratio < 0.50 and randf() < 0.16:
		var ox = randf_range(-s["width"] * 0.3, s["width"] * 0.3)
		var oy = randf_range(-s["height"] * 0.3, s["height"] * 0.3)
		sim.spawn_particle("smoke", s["x"] + ox, s["y"] + oy, randf_range(-4, 4), -18.0 - randf() * 10.0, 5.0, 16.0, 0.8, Color("#18181b"))
		
	# Below 25% HP: Structural fire sparks
	if ratio < 0.25 and randf() < 0.22:
		var ox = randf_range(-s["width"] * 0.25, s["width"] * 0.25)
		var oy = randf_range(-s["height"] * 0.25, s["height"] * 0.25)
		sim.spawn_particle("fire", s["x"] + ox, s["y"] + oy, randf_range(-8, 8), -22.0, 3.5, 6.0, 0.35, Color("#f97316"))
