class_name SimArmorPhysics
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func resolve_armor_impact(sim, target: Dictionary, p: Dictionary) -> Dictionary:
	var base_dmg = p.get("damage", 25.0)
	var p_vel = Vector2(p.get("vx", 1.0), p.get("vy", 0.0)).normalized()
	var t_angle = target.get("angle", 0.0)
	var hull_fwd = Vector2(cos(t_angle), sin(t_angle))
	
	# Angle between projectile flight direction and hull forward facing
	# -p_vel is the vector pointing from target towards attacker
	var incoming_dir = -p_vel
	var cos_angle = hull_fwd.dot(incoming_dir)
	var angle_rad = acos(clamp(cos_angle, -1.0, 1.0))
	var angle_deg = rad_to_deg(angle_rad)
	
	var is_heavy_armor = target.get("kind", "") in ["tank", "behemoth", "river_gunboat", "turret"]
	var is_shell = p.get("kind", "") in ["shell", "bullet"]
	
	# 1. Frontal Armor & Glancing Ricochet Check
	if is_heavy_armor and is_shell:
		# Frontal arc is within 45 degrees of nose
		if angle_deg <= 48.0:
			# Glancing angle check (hitting at a shallow oblique angle)
			var hull_normal = Vector2(-hull_fwd.y, hull_fwd.x)
			var normal_dot = abs(hull_normal.dot(incoming_dir))
			# High normal_dot means bullet hit glancing off the side/sloped glacis
			if normal_dot > 0.45 or (target["kind"] == "behemoth" and base_dmg < 40.0):
				# Ricochet confirmed!
				_trigger_ricochet(sim, target, p, hull_fwd, incoming_dir)
				return {
					"ricochet": true,
					"damage": round(base_dmg * 0.10), # Only 10% chip damage
					"rear_hit": false
				}
				
	# 2. Rear Armor Penetration Check (Engine Deck)
	if is_heavy_armor and angle_deg >= 132.0:
		_trigger_rear_penetration(sim, target, p)
		return {
			"ricochet": false,
			"damage": round(base_dmg * 1.40), # +40% critical damage
			"rear_hit": true
		}
		
	# 3. Standard Impact
	return {
		"ricochet": false,
		"damage": base_dmg,
		"rear_hit": false
	}

static func _trigger_ricochet(sim, target: Dictionary, p: Dictionary, hull_fwd: Vector2, inc_dir: Vector2) -> void:
	var tx = target["x"]
	var ty = target["y"]
	# Deflection bounce angle
	var deflect_dir = inc_dir.bounce(hull_fwd).normalized()
	sim.spawn_burst(tx, ty, "spark", 14, Color("#fef08a"), 95.0)
	sim.spawn_particle("spark", tx, ty, deflect_dir.x * 120.0, deflect_dir.y * 120.0, 3.0, 1.0, 0.4, Color("#ffffff"))
	sim.sound_triggered.emit("shot") # ricochet clang
	sim.spawn_floating_text(tx, ty - target.get("radius", 16.0) - 14.0, "[ RICOCHET // ارتداد القذيفة ]", Color("#e2e8f0"), 1.2)

static func _trigger_rear_penetration(sim, target: Dictionary, p: Dictionary) -> void:
	var tx = target["x"]
	var ty = target["y"]
	sim.spawn_burst(tx, ty, "smoke", 8, Color("#18181b"), 55.0)
	sim.spawn_burst(tx, ty, "fire", 10, Color("#ef4444"), 80.0)
	sim.camera_trauma = min(1.0, sim.camera_trauma + 0.16)
	sim.spawn_floating_text(tx, ty - target.get("radius", 16.0) - 14.0, "[ REAR PENETRATION // اختراق الدرع الخلفي ]", Color("#ef4444"), 1.3)
