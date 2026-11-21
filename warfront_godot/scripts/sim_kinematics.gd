class_name SimKinematics
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func update_unit_kinematics(u: Dictionary, dt: float) -> void:
	if not u.get("alive", true):
		return
		
	var kind = u.get("kind", "")
	
	# 1. Turret Slew Rate (Mechanical Rotation Speed)
	_update_turret_slew(u, dt, kind)
	
	# 2. Chassis Suspension Bobbing & Braking Inertia
	_update_suspension(u, dt, kind)
	
	# 3. Aircraft Aerodynamic Banking
	if u.get("is_air", false):
		_update_aircraft_banking(u, dt)

static func _update_turret_slew(u: Dictionary, dt: float, kind: String) -> void:
	var target_ang = u.get("targetTurretAngle", u.get("turretAngle", 0.0))
	var cur_ang = u.get("turretAngle", 0.0)
	
	# Speeds in radians per second
	var slew_speed = 3.5
	if kind == "behemoth":
		slew_speed = 1.85 # Heavy armor slow turn
	elif kind == "tank":
		slew_speed = 3.2
	elif kind in ["artillery", "sam_launcher", "river_gunboat"]:
		slew_speed = 2.4
	elif kind in ["scout", "patrol_boat", "helicopter"]:
		slew_speed = 6.5 # Fast pintle mount
	elif kind == "turret":
		slew_speed = 4.2
		
	u["turret_speed"] = slew_speed
	
	# Angular difference with wrapping (-PI to PI)
	var diff = fposmod(target_ang - cur_ang + PI, TAU) - PI
	var max_step = slew_speed * dt
	if abs(diff) <= max_step:
		u["turretAngle"] = target_ang
	else:
		u["turretAngle"] = cur_ang + sign(diff) * max_step

static func _update_suspension(u: Dictionary, dt: float, kind: String) -> void:
	var cur_speed = u.get("speed", 0.0)
	var is_moving = u.get("targetPos") != null
	var prev_moving = u.get("was_moving", false)
	var cur_pitch = u.get("suspensionPitch", 0.0)
	
	# Detect sudden braking or start of acceleration
	if prev_moving and not is_moving:
		# Sudden brake: Nose dips forward
		cur_pitch = -0.16 if kind in ["tank", "behemoth"] else -0.22
	elif not prev_moving and is_moving:
		# Acceleration surge: Nose kicks up
		cur_pitch = 0.12 if kind in ["tank", "behemoth"] else 0.18
		
	# Recoil kick pitch when firing main cannon
	if u.get("recoil", 0.0) > 0.15:
		cur_pitch += 0.14 * (u["recoil"] / 0.4)
		
	# Smoothly return suspension to neutral level with spring damping
	cur_pitch = lerpf(cur_pitch, 0.0, 8.0 * dt)
	u["suspensionPitch"] = cur_pitch
	u["was_moving"] = is_moving

static func _update_aircraft_banking(u: Dictionary, dt: float) -> void:
	var cur_angle = u.get("angle", 0.0)
	var prev_angle = u.get("prev_flight_angle", cur_angle)
	var ang_diff = fposmod(cur_angle - prev_angle + PI, TAU) - PI
	var turn_rate = ang_diff / max(0.001, dt)
	
	# Roll banking angle (in radians, up to 0.6 rad ~ 35 degrees)
	var target_roll = clamp(turn_rate * 0.35, -0.62, 0.62)
	var cur_roll = u.get("rollAngle", 0.0)
	u["rollAngle"] = lerpf(cur_roll, target_roll, 9.0 * dt)
	u["prev_flight_angle"] = cur_angle
