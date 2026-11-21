class_name RenderUnits
extends RefCounted

const Constants = preload("res://scripts/constants.gd")

static func draw_unit(canvas: CanvasItem, default_font: Font, u: Dictionary, sim_time: float) -> void:
	var pos = Vector2(round(u["x"]), round(u["y"]))
	var is_player = u.get("faction") == "player"
	var custom_col = u.get("color")
	var body_main: Color
	var body_dark: Color
	var body_light: Color
	if custom_col != null and custom_col is Color:
		body_main = custom_col
		body_dark = custom_col.darkened(0.35)
		body_light = custom_col.lightened(0.35)
	else:
		body_main = Color("#5d8a47") if is_player else Color("#b8423b")
		body_dark = Color("#375429") if is_player else Color("#732622")
		body_light = Color("#8ac26b") if is_player else Color("#e3726b")
	var flash = u["hitFlash"] > 0.0

	# 1. Selection 4-corner tactical brackets & breathing pulse
	if u["selected"]:
		var pulse = sin(sim_time * 6.0) * 1.2
		var r = u["radius"] + 7.0 + pulse
		var k = 6.0
		var b_col = Color("#a8f07e")
		# Top-left
		canvas.draw_line(pos + Vector2(-r, -r + k), pos + Vector2(-r, -r), b_col, 2.0)
		canvas.draw_line(pos + Vector2(-r, -r), pos + Vector2(-r + k, -r), b_col, 2.0)
		# Top-right
		canvas.draw_line(pos + Vector2(r - k, -r), pos + Vector2(r, -r), b_col, 2.0)
		canvas.draw_line(pos + Vector2(r, -r), pos + Vector2(r, -r + k), b_col, 2.0)
		# Bottom-right
		canvas.draw_line(pos + Vector2(r, r - k), pos + Vector2(r, r), b_col, 2.0)
		canvas.draw_line(pos + Vector2(r, r), pos + Vector2(r - k, r), b_col, 2.0)
		# Bottom-left
		canvas.draw_line(pos + Vector2(-r + k, r), pos + Vector2(-r, r), b_col, 2.0)
		canvas.draw_line(pos + Vector2(-r, r), pos + Vector2(-r, r - k), b_col, 2.0)
		# Subtle tactical ground disc
		canvas.draw_arc(pos, r * 0.9, 0, TAU, 16, Color(0.66, 0.94, 0.49, 0.25), 1.0)

	# 2. Ground drop shadow
	if u["kind"] == "helicopter":
		canvas.draw_circle(pos + Vector2(14, 20), 14.0, Color(0, 0, 0, 0.28))
	else:
		canvas.draw_circle(pos + Vector2(2, 4), u["radius"] * 0.82, Color(0, 0, 0, 0.35))

	# 3. Unit Chassis (Rotated by Movement Heading)
	var chassis_angle = u["angle"] if u["kind"] != "turret" else 0.0
	canvas.draw_set_transform(pos, chassis_angle, Vector2.ONE)

	# Tactical Reverse Warning Chevrons behind chassis
	if u.get("is_reversing", false):
		var rev_col = Color("#f59e0b")
		var pulse_x = fmod(sim_time * 20.0, 8.0)
		canvas.draw_line(Vector2(-u["radius"] - 6.0 - pulse_x, -5), Vector2(-u["radius"] - 11.0 - pulse_x, 0), rev_col, 2.0)
		canvas.draw_line(Vector2(-u["radius"] - 11.0 - pulse_x, 0), Vector2(-u["radius"] - 6.0 - pulse_x, 5), rev_col, 2.0)

	if u["kind"] == "truck":
		# Physical Oil Supply Truck
		canvas.draw_rect(Rect2(-16, -11, 32, 22), Color("#141412"))
		# Flatbed cargo bay with wood/steel deck
		canvas.draw_rect(Rect2(-14, -9, 18, 18), Color.WHITE if flash else Color("#383733"))
		# Driver Cab
		canvas.draw_rect(Rect2(5, -9, 10, 18), Color.WHITE if flash else body_main)
		canvas.draw_rect(Rect2(9, -7, 3, 14), Color("#60a5fa")) # Windshield
		# Headlights
		canvas.draw_rect(Rect2(14, -8, 2, 3), Color("#fef08a"))
		canvas.draw_rect(Rect2(14, 5, 2, 3), Color("#fef08a"))
		
		# Visible oil barrels in cargo bed
		var loaded = u.get("cargoOil", 0.0) > 0.0
		var barrel_col = Color("#f59e0b") if loaded else Color("#222220")
		var barrel_rim = Color("#fbbf24") if loaded else Color("#3f3f46")
		for bx in [-12, -7, -2]:
			canvas.draw_rect(Rect2(bx, -7, 4, 5), barrel_rim)
			canvas.draw_rect(Rect2(bx + 1, -6, 2, 3), barrel_col)
			canvas.draw_rect(Rect2(bx, 2, 4, 5), barrel_rim)
			canvas.draw_rect(Rect2(bx + 1, 3, 2, 3), barrel_col)
	elif u["kind"] == "scout":
		# 4 Rubber offroad tires with steel hubcaps
		canvas.draw_rect(Rect2(-12, -11, 7, 4), Color("#121210"))
		canvas.draw_rect(Rect2(5, -11, 7, 4), Color("#121210"))
		canvas.draw_rect(Rect2(-12, 7, 7, 4), Color("#121210"))
		canvas.draw_rect(Rect2(5, 7, 7, 4), Color("#121210"))
		# Hubcaps
		canvas.draw_rect(Rect2(-10, -10, 3, 2), Color("#4b4d45"))
		canvas.draw_rect(Rect2(7, -10, 3, 2), Color("#4b4d45"))
		canvas.draw_rect(Rect2(-10, 8, 3, 2), Color("#4b4d45"))
		canvas.draw_rect(Rect2(7, 8, 3, 2), Color("#4b4d45"))
		# Humvee Boxy Armor Body
		canvas.draw_rect(Rect2(-12, -8, 24, 16), Color("#141512"))
		canvas.draw_rect(Rect2(-11, -7, 22, 14), Color.WHITE if flash else body_main)
		# Hood bevel & Windshield
		canvas.draw_rect(Rect2(4, -5, 4, 10), Color.WHITE if flash else body_light)
		canvas.draw_rect(Rect2(1, -5, 3, 10), Color("#60a5fa"))
	elif u["kind"] == "tank":
		# Caterpillar tracks (outer black rim)
		canvas.draw_rect(Rect2(-16, -13, 32, 6), Color("#141412"))
		canvas.draw_rect(Rect2(-16, 7, 32, 6), Color("#141412"))
		# Animated track link ridges that roll with movement!
		var roll = fmod(u.get("treadAccum", 0.0) * 0.8, 4.0)
		var tx = -14.0 + roll
		while tx <= 14.0:
			canvas.draw_rect(Rect2(tx, -13, 2, 6), Color("#32332c"))
			canvas.draw_rect(Rect2(tx, 7, 2, 6), Color("#32332c"))
			tx += 4.0
		# Road wheels inside tracks
		for wx in [-10, -4, 2, 8]:
			canvas.draw_rect(Rect2(wx, -12, 3, 4), Color("#4b4d45"))
			canvas.draw_rect(Rect2(wx, 8, 3, 4), Color("#4b4d45"))
		# Sloped armor glacis & rear engine deck
		canvas.draw_rect(Rect2(-14, -9, 28, 18), Color.WHITE if flash else body_dark)
		canvas.draw_rect(Rect2(-11, -7, 22, 14), Color.WHITE if flash else body_main)
		# Bevel highlight on frontal armor
		canvas.draw_rect(Rect2(9, -7, 2, 14), Color.WHITE if flash else body_light)
		# Rear engine exhaust vents
		canvas.draw_rect(Rect2(-14, -5, 2, 10), Color("#121310"))
	elif u["kind"] == "behemoth":
		# Super-heavy quad caterpillar tracks
		canvas.draw_rect(Rect2(-20, -16, 40, 7), Color("#121210"))
		canvas.draw_rect(Rect2(-20, 9, 40, 7), Color("#121210"))
		var roll = fmod(u.get("treadAccum", 0.0) * 0.8, 4.0)
		var tx = -18.0 + roll
		while tx <= 18.0:
			canvas.draw_rect(Rect2(tx, -16, 2, 7), Color("#32332c"))
			canvas.draw_rect(Rect2(tx, 9, 2, 7), Color("#32332c"))
			tx += 4.0
		# Road wheels
		for wx in [-14, -7, 0, 7, 14]:
			canvas.draw_rect(Rect2(wx, -15, 3, 5), Color("#4b4d45"))
			canvas.draw_rect(Rect2(wx, 10, 3, 5), Color("#4b4d45"))
		# Reinforced wide super-heavy hull
		canvas.draw_rect(Rect2(-17, -11, 34, 22), Color.WHITE if flash else body_dark)
		canvas.draw_rect(Rect2(-14, -9, 28, 18), Color.WHITE if flash else body_main)
		# Frontal sloped armor bevel & reactive armor plates
		canvas.draw_rect(Rect2(11, -9, 3, 18), Color.WHITE if flash else body_light)
		canvas.draw_rect(Rect2(8, -8, 2, 7), Color("#27272a"))
		canvas.draw_rect(Rect2(8, 1, 2, 7), Color("#27272a"))
		# Rear heavy exhaust manifold
		canvas.draw_rect(Rect2(-17, -6, 3, 12), Color("#0f0f0d"))
	elif u["kind"] == "helicopter":
		# Attack Gunship Fuselage
		canvas.draw_rect(Rect2(-16, -6, 32, 12), Color.WHITE if flash else body_main)
		canvas.draw_rect(Rect2(-12, -5, 24, 10), Color.WHITE if flash else body_dark)
		# Tandem Cockpit Canopy Glass
		canvas.draw_rect(Rect2(4, -4, 8, 8), Color("#38bdf8"))
		canvas.draw_rect(Rect2(5, -3, 6, 2), Color.WHITE)
		# Twin Stub Wings with Rocket Pods
		canvas.draw_rect(Rect2(-2, -14, 6, 28), body_dark)
		canvas.draw_rect(Rect2(0, -15, 4, 3), Color("#f59e0b"))
		canvas.draw_rect(Rect2(0, 12, 4, 3), Color("#f59e0b"))
		# Tail Boom and Vertical Fin
		canvas.draw_rect(Rect2(-24, -3, 10, 6), body_main)
		canvas.draw_rect(Rect2(-26, -5, 4, 10), body_dark)
		# Spinning Anti-Torque Tail Rotor
		var tail_phase = fmod(sim_time * 45.0, TAU)
		var tail_rotor_len = sin(tail_phase) * 6.0
		canvas.draw_line(Vector2(-25, -tail_rotor_len), Vector2(-25, tail_rotor_len), Color("#e4e4e7"), 1.5)
	elif u["kind"] == "artillery":
		# Heavy 6-Wheel Tracked Carrier Chassis
		canvas.draw_rect(Rect2(-16, -11, 32, 22), Color("#141412"))
		canvas.draw_rect(Rect2(-14, -9, 28, 18), Color.WHITE if flash else body_dark)
		canvas.draw_rect(Rect2(6, -8, 7, 16), Color.WHITE if flash else body_main)
		canvas.draw_rect(Rect2(9, -6, 2, 12), Color("#60a5fa")) # Cab windshield
	elif u["kind"] == "engineer":
		# Heavy Engineer Vehicle with Front Dozer Blade
		canvas.draw_rect(Rect2(-12, -9, 24, 18), Color("#141412"))
		canvas.draw_rect(Rect2(-10, -7, 20, 14), Color.WHITE if flash else body_main)
		# Heavy Bulldozer Blade with Yellow/Black Safety Warning Chevrons
		canvas.draw_rect(Rect2(6, -8, 5, 16), Color("#141412"))
		canvas.draw_rect(Rect2(7, -7, 3, 14), Color("#f59e0b"))
		canvas.draw_rect(Rect2(7, -5, 3, 3), Color("#18181b"))
		canvas.draw_rect(Rect2(7, 2, 3, 3), Color("#18181b"))
		# Rear Crane Arm
		canvas.draw_rect(Rect2(-8, -4, 10, 8), body_dark)
	elif u["kind"] == "turret":
		# Heavy Fortified Concrete Bunker Base
		var f_col = Color("#11120f")
		var c_main = Color.WHITE if flash else Color("#484a42")
		var c_light = Color.WHITE if flash else Color("#61645a")
		var c_dark = Color.WHITE if flash else Color("#32342d")
		
		# Foundation drop shadow & outer rim
		canvas.draw_rect(Rect2(-18, -18, 36, 36), f_col)
		canvas.draw_rect(Rect2(-16, -16, 32, 32), c_dark)
		canvas.draw_rect(Rect2(-14, -14, 28, 28), c_main)
		# Top concrete lip bevel highlight
		canvas.draw_rect(Rect2(-14, -14, 28, 2), c_light)
		canvas.draw_rect(Rect2(-14, -14, 2, 28), c_light)

		# Heavy steel turret azimuth race ring
		canvas.draw_circle(Vector2.ZERO, 12.0, Color("#151613"))
		canvas.draw_circle(Vector2.ZERO, 10.5, body_dark)
		canvas.draw_circle(Vector2.ZERO, 9.0, Color("#11120f"))

		# Directional armored observation embrasures (vision slits)
		canvas.draw_rect(Rect2(-15, -2, 3, 4), Color("#0a0a08")) # West
		canvas.draw_rect(Rect2(12, -2, 3, 4), Color("#0a0a08"))  # East
		canvas.draw_rect(Rect2(-2, -15, 4, 3), Color("#0a0a08")) # North
		canvas.draw_rect(Rect2(-2, 12, 4, 3), Color("#0a0a08"))  # South

		# Heavy foundation anchor bolts with steel washers
		for cx in [-13, 11]:
			for cy in [-13, 11]:
				canvas.draw_rect(Rect2(cx, cy, 3, 3), Color("#151613"))
				canvas.draw_rect(Rect2(cx + 1, cy + 1, 1, 1), Color("#8e9285"))

		# Yellow/Black caution hazard striping on bunker apron
		canvas.draw_rect(Rect2(-10, 11, 20, 3), Color("#f59e0b"))
		canvas.draw_rect(Rect2(-7, 11, 3, 3), Color("#151613"))
		canvas.draw_rect(Rect2(0, 11, 3, 3), Color("#151613"))
		canvas.draw_rect(Rect2(7, 11, 3, 3), Color("#151613"))

	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# 4. Rotating Turret & Weapons
	if u["kind"] != "truck":
		canvas.draw_set_transform(pos, u["turretAngle"], Vector2.ONE)
		var kick = int(round(u["recoil"] * 4.0))
		if u["kind"] == "tank":
			# Main Cannon Barrel with Muzzle Brake & Kick
			canvas.draw_rect(Rect2(4 - kick, -3, 19, 6), Color("#141412"))
			canvas.draw_rect(Rect2(5 - kick, -2, 17, 4), body_light)
			# Muzzle brake collar
			canvas.draw_rect(Rect2(20 - kick, -4, 3, 8), Color("#1a1a17"))
			# Turret Bustle & Mantlet
			canvas.draw_rect(Rect2(-9, -8, 17, 16), Color("#141412"))
			canvas.draw_rect(Rect2(-8, -7, 15, 14), body_dark)
			canvas.draw_rect(Rect2(-6, -5, 11, 10), body_main)
			# Commander Hatch / Cupola
			canvas.draw_rect(Rect2(-3, -4, 4, 4), body_light)
			# Antenna
			canvas.draw_rect(Rect2(-6, -6, 2, 2), Color("#d1d5db"))
		elif u["kind"] == "behemoth":
			# Massive Angular Turret Bustle
			canvas.draw_rect(Rect2(-13, -11, 25, 22), Color("#141412"))
			canvas.draw_rect(Rect2(-12, -10, 23, 20), body_dark)
			canvas.draw_rect(Rect2(-9, -8, 17, 16), body_main)
			# Commander's Cupola & Optics
			canvas.draw_rect(Rect2(-4, -5, 5, 5), body_light)
			canvas.draw_rect(Rect2(-8, -8, 2, 3), Color("#38bdf8"))
			# DUAL Heavy 152mm Cannons side-by-side with recoil!
			canvas.draw_rect(Rect2(6 - kick, -7, 22, 5), Color("#141412"))
			canvas.draw_rect(Rect2(7 - kick, -6, 20, 3), body_light)
			canvas.draw_rect(Rect2(24 - kick, -8, 3, 7), Color("#1a1a17"))
			canvas.draw_rect(Rect2(6 - kick, 2, 22, 5), Color("#141412"))
			canvas.draw_rect(Rect2(7 - kick, 3, 20, 3), body_light)
			canvas.draw_rect(Rect2(24 - kick, 1, 3, 7), Color("#1a1a17"))
		elif u["kind"] == "helicopter":
			# Chin-mounted 30mm Gatling Gun (Aims with turret angle)
			canvas.draw_rect(Rect2(8 - kick, -2, 10, 4), Color("#181916"))
			canvas.draw_rect(Rect2(9 - kick, -1, 8, 2), Color("#71717a"))
			# Main Rotor Mast
			canvas.draw_circle(Vector2.ZERO, 3.5, Color("#27272a"))
			# High-Speed Spinning 4-Blade Rotor
			var r_angle = fmod(sim_time * 36.0, TAU)
			canvas.draw_circle(Vector2.ZERO, 25.0, Color(1, 1, 1, 0.08))
			for b_idx in range(4):
				var b_rad = r_angle + float(b_idx) * (PI * 0.5)
				var b_vec = Vector2(cos(b_rad), sin(b_rad))
				canvas.draw_line(Vector2.ZERO, b_vec * 24.0, Color("#d4d4d8"), 2.0)
				canvas.draw_circle(b_vec * 24.0, 1.5, Color("#f59e0b"))
		elif u["kind"] == "artillery":
			# Armored Rocket Launcher Pod with 3 Launcher Guide Tubes
			canvas.draw_rect(Rect2(-13 - kick, -8, 20, 16), Color("#181816"))
			canvas.draw_rect(Rect2(-12 - kick, -7, 18, 14), Color("#27272a"))
			# 3 Golden Rocket Warheads / Tubes
			canvas.draw_rect(Rect2(-10 - kick, -5, 15, 3), Color("#f59e0b"))
			canvas.draw_rect(Rect2(-10 - kick, -1, 15, 3), Color("#f59e0b"))
			canvas.draw_rect(Rect2(-10 - kick, 3, 15, 3), Color("#f59e0b"))
			# Exhaust backblast manifold
			canvas.draw_rect(Rect2(-13 - kick, -6, 2, 12), Color("#111110"))
		elif u["kind"] == "scout":
			# 50 Cal Pintle Machine Gun
			canvas.draw_rect(Rect2(0 - kick, -2, 13, 4), Color("#181916"))
			canvas.draw_rect(Rect2(1 - kick, -1, 11, 2), Color("#71717a"))
			canvas.draw_rect(Rect2(-4, -4, 8, 8), body_dark)
			canvas.draw_rect(Rect2(-3, -3, 6, 6), body_light)
		elif u["kind"] == "turret":
			# Twin Heavy Fluted Autocannon Barrels with Heat Vents & Muzzle Brakes
			# Barrel 1 (Port)
			canvas.draw_rect(Rect2(3 - kick, -6, 18, 4), Color("#141512"))
			canvas.draw_rect(Rect2(4 - kick, -5, 16, 2), Color("#71717a"))
			canvas.draw_rect(Rect2(7 - kick, -6, 2, 4), Color("#141512"))
			canvas.draw_rect(Rect2(12 - kick, -6, 2, 4), Color("#141512"))
			canvas.draw_rect(Rect2(18 - kick, -7, 3, 6), Color("#1f201c"))

			# Barrel 2 (Starboard)
			canvas.draw_rect(Rect2(3 - kick, 2, 18, 4), Color("#141512"))
			canvas.draw_rect(Rect2(4 - kick, 3, 16, 2), Color("#71717a"))
			canvas.draw_rect(Rect2(7 - kick, 2, 2, 4), Color("#141512"))
			canvas.draw_rect(Rect2(12 - kick, 2, 2, 4), Color("#141512"))
			canvas.draw_rect(Rect2(18 - kick, 1, 3, 6), Color("#1f201c"))

			# Heavy Armored Gun Mantlet & Side Ammo Boxes
			canvas.draw_rect(Rect2(-9, -10, 18, 20), Color("#141512"))
			canvas.draw_rect(Rect2(-8, -9, 16, 18), body_dark)
			canvas.draw_rect(Rect2(-6, -7, 12, 14), body_main)
			canvas.draw_rect(Rect2(-6, -7, 12, 2), body_light)

			# Armored Ammo Feed Canisters (Flanking)
			canvas.draw_rect(Rect2(-4, -11, 8, 3), Color("#27272a"))
			canvas.draw_rect(Rect2(-4, 8, 8, 3), Color("#27272a"))

			# Central Commander Optic & FLIR Targeting Lens
			canvas.draw_rect(Rect2(-3, -3, 6, 6), Color("#141512"))
			canvas.draw_rect(Rect2(-2, -2, 4, 4), body_light)
			canvas.draw_rect(Rect2(0, -1, 2, 2), Color("#ef4444") if not is_player else Color("#38bdf8"))
		canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		
		# Visceral muzzle blast at barrel tip
		if u["recoil"] > 0.05:
			draw_muzzle_flash(canvas, u)

	# 5. Stranded Supply Truck Hazard Sign
	if u["kind"] == "truck" and u["truckState"] == "stranded":
		var bob = sin(sim_time * 7.0) * 2.0
		canvas.draw_rect(Rect2(pos.x - 8, pos.y - 28 + bob, 16, 15), Color("#1a120a"))
		canvas.draw_rect(Rect2(pos.x - 8, pos.y - 28 + bob, 16, 15), Color("#f59e0b"), false, 1.5)
		canvas.draw_rect(Rect2(pos.x - 1.5, pos.y - 25 + bob, 3, 6), Color("#f59e0b"))
		canvas.draw_rect(Rect2(pos.x - 1.5, pos.y - 17 + bob, 3, 3), Color("#f59e0b"))

	# 6. Promotion Glow Ring
	if u["promoFlash"] > 0.0:
		var p_col = Color("#ffd659")
		p_col.a = min(1.0, u["promoFlash"] / 0.7)
		canvas.draw_arc(pos, u["radius"] + 9.0 + (1.0 - u["promoFlash"] / 0.7) * 8.0, 0, TAU, 24, p_col, 2.5)

	# 7. Unit HP Bar & XP Bar
	if u["hp"] < u["maxHp"] or u["selected"]:
		var pct = max(0.0, u["hp"] / u["maxHp"])
		var bw = 26.0
		canvas.draw_rect(Rect2(pos.x - bw / 2.0 - 1, pos.y - u["radius"] - 11, bw + 2, 5), Color(0.05, 0.06, 0.04, 0.85))
		canvas.draw_rect(Rect2(pos.x - bw / 2.0, pos.y - u["radius"] - 10, round(bw * pct), 3), Color("#73d65e") if is_player else Color("#ef5350"))
		# XP progress for selected
		if u["selected"] and u["kind"] != "truck" and u["rank"] < 3:
			var cur_floor = Constants.VETERANCY_RANKS[u["rank"]]["xpRequired"]
			var next_req = Constants.VETERANCY_RANKS[u["rank"] + 1]["xpRequired"]
			var xp_pct = max(0.0, min(1.0, (u["xp"] - cur_floor) / float(max(1, next_req - cur_floor))))
			canvas.draw_rect(Rect2(pos.x - bw / 2.0 - 1, pos.y - u["radius"] - 6, bw + 2, 3), Color(0.05, 0.06, 0.04, 0.85))
			canvas.draw_rect(Rect2(pos.x - bw / 2.0, pos.y - u["radius"] - 5, round(bw * xp_pct), 1.5), Color("#f2be42"))

	# 8. Military Insignia Rank Badge (Chevrons / Gold Star)
	if u["rank"] > 0:
		draw_rank_badge(canvas, default_font, pos.x + u["radius"] + 2, pos.y - u["radius"] - 10, u["rank"])

static func draw_muzzle_flash(canvas: CanvasItem, u: Dictionary) -> void:
	var pos = Vector2(u["x"], u["y"])
	var ang = u["turretAngle"]
	var forward = Vector2(cos(ang), sin(ang))
	var normal = Vector2(-sin(ang), cos(ang))
	var rec = u["recoil"]
	
	if u["kind"] == "behemoth":
		var flash_rad = 14.0 * rec
		var tip_top = pos + forward * (27.0 - rec * 4.0) + normal * 4.5
		var tip_bot = pos + forward * (27.0 - rec * 4.0) - normal * 4.5
		canvas.draw_circle(tip_top, flash_rad * 0.5, Color.WHITE)
		canvas.draw_circle(tip_top, flash_rad, Color(1.0, 0.72, 0.15, rec * 0.95))
		canvas.draw_circle(tip_bot, flash_rad * 0.5, Color.WHITE)
		canvas.draw_circle(tip_bot, flash_rad, Color(1.0, 0.72, 0.15, rec * 0.95))
		canvas.draw_line(tip_top, tip_top + forward * (flash_rad * 2.0), Color("#ffe699"), 2.5)
		canvas.draw_line(tip_bot, tip_bot + forward * (flash_rad * 2.0), Color("#ffe699"), 2.5)
	elif u["kind"] == "helicopter":
		var tip = pos + forward * (16.0 - rec * 2.0)
		var flash_rad = 9.0 * rec
		canvas.draw_circle(tip, flash_rad * 0.45, Color.WHITE)
		canvas.draw_circle(tip, flash_rad, Color(1.0, 0.85, 0.25, rec * 0.9))
	elif u["kind"] == "tank":
		var tip = pos + forward * (23.0 - rec * 4.0)
		var flash_rad = 12.0 * rec
		canvas.draw_circle(tip, flash_rad * 0.45, Color.WHITE)
		canvas.draw_circle(tip, flash_rad, Color(1.0, 0.72, 0.15, rec * 0.95))
		canvas.draw_line(tip, tip + forward * (flash_rad * 1.8), Color("#ffe699"), 2.5)
	elif u["kind"] == "artillery":
		var tip = pos + forward * 14.0
		var back_tip = pos - forward * 12.0
		var flash_rad = 14.0 * rec
		# Backblast rocket exhaust flame
		canvas.draw_circle(back_tip, flash_rad * 0.75, Color(1.0, 0.42, 0.1, rec * 0.85))
		# Front muzzle ignition
		canvas.draw_circle(tip, flash_rad * 0.9, Color(1.0, 0.82, 0.25, rec * 0.95))
		canvas.draw_circle(tip, flash_rad * 0.4, Color.WHITE)
	elif u["kind"] == "turret":
		var tip = pos + forward * (18.0 - rec * 3.0)
		var flash_rad = 8.0 * rec
		# Twin barrels muzzle flashes
		canvas.draw_circle(tip + normal * 2.5, flash_rad * 0.4, Color.WHITE)
		canvas.draw_circle(tip + normal * 2.5, flash_rad, Color(1.0, 0.75, 0.18, rec * 0.9))
		canvas.draw_circle(tip - normal * 2.5, flash_rad * 0.4, Color.WHITE)
		canvas.draw_circle(tip - normal * 2.5, flash_rad, Color(1.0, 0.75, 0.18, rec * 0.9))
	elif u["kind"] == "scout":
		var tip = pos + forward * (13.0 - rec * 2.0)
		var flash_rad = 7.0 * rec
		canvas.draw_circle(tip, flash_rad * 0.4, Color.WHITE)
		canvas.draw_circle(tip, flash_rad, Color(1.0, 0.82, 0.22, rec * 0.9))

static func draw_rank_badge(canvas: CanvasItem, default_font: Font, bx: float, by: float, rank: int) -> void:
	var w = 15.0
	var h = 14.0
	canvas.draw_rect(Rect2(bx, by, w, h), Color("#14170f"))
	var border_col = Color("#ffd95e") if rank == 3 else (Color("#e6ad38") if rank == 2 else Color("#b88b3a"))
	canvas.draw_rect(Rect2(bx, by, w, h), border_col, false, 1.5)
	
	if rank == 1:
		# Single chevron
		var p1 = Vector2(bx + 3, by + 9.5)
		var p2 = Vector2(bx + 7.5, by + 4.5)
		var p3 = Vector2(bx + 12, by + 9.5)
		canvas.draw_polyline(PackedVector2Array([p1, p2, p3]), Color("#e5b145"), 2.0)
	elif rank == 2:
		# Twin stacked chevrons
		canvas.draw_polyline(PackedVector2Array([Vector2(bx + 3, by + 7), Vector2(bx + 7.5, by + 3), Vector2(bx + 12, by + 7)]), Color("#f7ca4d"), 1.8)
		canvas.draw_polyline(PackedVector2Array([Vector2(bx + 3, by + 11), Vector2(bx + 7.5, by + 7), Vector2(bx + 12, by + 11)]), Color("#f7ca4d"), 1.8)
	elif rank == 3:
		# Triple Chevron (Master Sergeant / Senior Chief Veteran)
		canvas.draw_polyline(PackedVector2Array([Vector2(bx + 3, by + 5.5), Vector2(bx + 7.5, by + 2.5), Vector2(bx + 12, by + 5.5)]), Color("#fde047"), 1.8)
		canvas.draw_polyline(PackedVector2Array([Vector2(bx + 3, by + 9.0), Vector2(bx + 7.5, by + 6.0), Vector2(bx + 12, by + 9.0)]), Color("#fde047"), 1.8)
		canvas.draw_polyline(PackedVector2Array([Vector2(bx + 3, by + 12.5), Vector2(bx + 7.5, by + 9.5), Vector2(bx + 12, by + 12.5)]), Color("#fde047"), 1.8)
