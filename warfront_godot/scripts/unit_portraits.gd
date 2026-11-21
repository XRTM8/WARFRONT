class_name UnitPortraits
extends RefCounted

static var _cache: Dictionary = {}

static func get_portrait(kind: String, width: int = 88, height: int = 48) -> ImageTexture:
	var cache_key = "%s_%d_%d" % [kind, width, height]
	if _cache.has(cache_key):
		return _cache[cache_key]
		
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# 1. Tactical CRT Green/Black Background
	img.fill(Color(0.06, 0.08, 0.06, 0.96))
	
	# 2. Blueprint Tactical Grid Lines
	var grid_col = Color(0.14, 0.20, 0.13, 0.45)
	for gx in range(0, width, 8):
		for gy in range(height):
			img.set_pixel(gx, gy, grid_col)
	for gy in range(0, height, 8):
		for gx in range(width):
			img.set_pixel(gx, gy, grid_col)
			
	# 3. Corner Reticles / Frame
	var frame_col = Color(0.25, 0.34, 0.23, 0.75)
	for i in range(5):
		# Top-Left
		img.set_pixel(i, 0, frame_col)
		img.set_pixel(0, i, frame_col)
		# Top-Right
		img.set_pixel(width - 1 - i, 0, frame_col)
		img.set_pixel(width - 1, i, frame_col)
		# Bottom-Left
		img.set_pixel(i, height - 1, frame_col)
		img.set_pixel(0, height - 1 - i, frame_col)
		# Bottom-Right
		img.set_pixel(width - 1 - i, height - 1, frame_col)
		img.set_pixel(width - 1, height - 1 - i, frame_col)

	# 4. Draw Schematic based on kind
	var b_main = Color("#62714c")
	var b_dark = Color("#3b442e")
	var b_light = Color("#8d9f6e")
	var tread_dark = Color("#1e201a")
	var tread_mid = Color("#373b30")
	var steel = Color("#717669")
	var glass = Color("#38bdf8")
	var amber = Color("#f59e0b")
	
	match kind:
		"scout":
			# 4x4 Rugged Recon Buggy / Humvee
			# Wheels
			fill_circle(img, 20, 36, 6, tread_dark)
			fill_circle(img, 20, 36, 3, steel)
			fill_circle(img, 64, 36, 6, tread_dark)
			fill_circle(img, 64, 36, 3, steel)
			# Chassis & Armor
			fill_rect(img, 14, 25, 56, 9, b_main)
			fill_rect(img, 14, 32, 56, 3, b_dark)
			fill_rect(img, 52, 27, 20, 6, b_light) # Sloped hood
			# Armored Cabin
			fill_rect(img, 26, 17, 28, 9, b_main)
			fill_rect(img, 38, 19, 14, 6, glass)
			fill_rect(img, 42, 20, 8, 2, Color.WHITE) # Glass glint
			# Heavy Bullbar
			fill_rect(img, 72, 28, 3, 9, steel)
			draw_line(img, 68, 35, 74, 32, steel)
			# 50-Cal Pintle Machine Gun
			fill_rect(img, 34, 13, 4, 4, b_dark) # Gun mount
			fill_rect(img, 36, 11, 18, 3, steel) # Barrel
			fill_rect(img, 52, 10, 3, 5, tread_dark) # Muzzle brake
			fill_rect(img, 32, 12, 4, 4, tread_dark) # Ammo box
			# Antenna
			draw_line(img, 18, 24, 15, 8, Color("#a1a1aa"))
			img.set_pixel(15, 8, amber)
			
		"tank":
			# T-72 Main Battle Tank
			# Caterpillar Tracks
			fill_rect(img, 10, 33, 62, 10, tread_dark)
			for wx in [16, 26, 36, 46, 56, 66]:
				fill_circle(img, wx, 38, 4, tread_mid)
				img.set_pixel(wx, 38, steel)
			# Sloped Glacis Hull
			fill_rect(img, 12, 25, 58, 9, b_dark)
			fill_rect(img, 14, 23, 52, 5, b_main)
			fill_rect(img, 54, 23, 14, 3, b_light)
			# Reactive Armor (ERA) tiles
			for ex in [18, 26, 34, 42, 50]:
				fill_rect(img, ex, 24, 6, 3, Color("#778a5e"))
			# Low-Profile Turret
			fill_rect(img, 26, 15, 26, 9, b_dark)
			fill_rect(img, 28, 14, 22, 6, b_main)
			fill_rect(img, 30, 14, 18, 2, b_light)
			# Commander Cupola & Hatch
			fill_rect(img, 30, 11, 7, 3, b_light)
			img.set_pixel(34, 12, glass)
			# Long 125mm Smoothbore Cannon
			fill_rect(img, 48, 16, 34, 3, steel)
			fill_rect(img, 62, 15, 5, 5, b_dark) # Bore evacuator
			fill_rect(img, 80, 15, 3, 5, tread_dark) # Muzzle brake
			
		"behemoth":
			# Behemoth Super-Heavy Quad-Track Siege Tank
			# Massive Reinforced Tracks
			fill_rect(img, 6, 32, 70, 12, tread_dark)
			for wx in [12, 22, 32, 42, 52, 62, 70]:
				fill_circle(img, wx, 38, 4, Color("#262923"))
				img.set_pixel(wx, 38, Color("#8e9485"))
			# Heavy Armored Glacis with Mudguards
			fill_rect(img, 8, 24, 66, 9, b_dark)
			fill_rect(img, 10, 22, 62, 6, b_main)
			fill_rect(img, 56, 22, 16, 4, b_light)
			# Massive Angular Turret Bustle
			fill_rect(img, 20, 10, 36, 13, b_dark)
			fill_rect(img, 22, 9, 32, 10, b_main)
			fill_rect(img, 24, 9, 28, 2, b_light)
			# Twin Heavy 152mm Cannons
			# Barrel 1 (Upper)
			fill_rect(img, 52, 10, 32, 3, steel)
			fill_rect(img, 80, 9, 4, 5, tread_dark) # Heavy Brake 1
			# Barrel 2 (Lower)
			fill_rect(img, 52, 16, 32, 3, steel)
			fill_rect(img, 80, 15, 4, 5, tread_dark) # Heavy Brake 2
			# FLIR Optical Pod
			fill_rect(img, 38, 7, 6, 3, b_dark)
			img.set_pixel(42, 8, Color("#ef4444"))
			# Smoke grenade dischargers
			draw_line(img, 22, 10, 19, 6, steel)
			draw_line(img, 24, 10, 21, 6, steel)
			
		"artillery":
			# MLRS Rocket Launcher Carrier
			# Tracked Carrier Base
			fill_rect(img, 10, 33, 62, 10, tread_dark)
			for wx in [16, 28, 40, 52, 64]:
				fill_circle(img, wx, 38, 4, tread_mid)
			# Armored Driver Cab at Front
			fill_rect(img, 52, 22, 20, 12, b_main)
			fill_rect(img, 62, 24, 8, 4, glass)
			fill_rect(img, 12, 26, 42, 8, b_dark)
			# Elevated Rocket Launcher Box (Tilted)
			fill_rect(img, 14, 11, 36, 12, Color("#2b2f27"))
			fill_rect(img, 16, 12, 32, 9, Color("#3f4539"))
			# 3 Golden Guided Rockets Peeking Out
			fill_rect(img, 46, 12, 4, 2, amber)
			fill_rect(img, 46, 15, 4, 2, amber)
			fill_rect(img, 46, 18, 4, 2, amber)
			# Hydraulic Lift Cylinder
			draw_line(img, 24, 26, 28, 22, steel)
			# Exhaust backblast deflector
			fill_rect(img, 12, 14, 2, 8, tread_dark)
			
		"helicopter":
			# Desert Falcon Attack Gunship
			# Fuselage
			fill_rect(img, 18, 22, 46, 9, b_main)
			fill_rect(img, 22, 29, 38, 3, b_dark)
			# Tandem Cockpit Glass Canopy
			fill_rect(img, 44, 18, 18, 6, glass)
			fill_rect(img, 48, 19, 12, 2, Color.WHITE)
			# Chin 30mm Gatling Gun
			fill_rect(img, 62, 29, 14, 3, steel)
			fill_rect(img, 73, 28, 3, 5, tread_dark)
			# Stub Weapon Wings with Missile Pod
			fill_rect(img, 34, 26, 10, 3, b_dark)
			fill_rect(img, 36, 28, 8, 4, steel)
			fill_rect(img, 42, 29, 3, 2, amber) # Rocket tips
			# Tail Boom & Vertical Stabilizer
			draw_line(img, 18, 25, 4, 23, b_main)
			fill_rect(img, 4, 15, 4, 11, b_main)
			# Spinning Tail Rotor
			draw_line(img, 3, 14, 3, 26, Color("#d4d4d8"))
			# Main Rotor Mast & Spinning Blur Disc
			fill_rect(img, 36, 16, 4, 6, tread_dark)
			fill_rect(img, 8, 14, 64, 2, Color(1, 1, 1, 0.45))
			fill_circle(img, 38, 15, 2, Color("#d4d4d8"))
			
		"engineer":
			# Combat Engineering Vehicle
			# Heavy Tracks
			fill_rect(img, 14, 33, 54, 10, tread_dark)
			for wx in [20, 32, 44, 56]:
				fill_circle(img, wx, 38, 4, tread_mid)
			# Armored Cab & Body
			fill_rect(img, 16, 21, 46, 13, b_main)
			fill_rect(img, 44, 23, 12, 5, glass)
			# Heavy Bulldozer Blade with Yellow/Black Chevrons
			fill_rect(img, 66, 20, 6, 22, Color("#18181b"))
			fill_rect(img, 68, 22, 3, 18, amber)
			fill_rect(img, 68, 24, 3, 3, Color("#18181b"))
			fill_rect(img, 68, 32, 3, 3, Color("#18181b"))
			# Hydraulic Push Arm
			draw_line(img, 58, 32, 66, 29, steel)
			# Rear Folded Telescopic Crane Arm
			draw_line(img, 20, 21, 38, 14, steel)
			draw_line(img, 38, 14, 38, 18, Color("#a1a1aa"))
			# Amber Flashing Light on Cab
			fill_circle(img, 40, 19, 2, amber)
			
		"turret":
			# Automated Fortified Defense Bunker
			# Concrete Base with Chamfered Corners
			fill_rect(img, 14, 32, 60, 11, Color("#44483e"))
			fill_rect(img, 16, 30, 56, 3, Color("#5e6356"))
			for bx in [18, 68]:
				fill_rect(img, bx, 35, 3, 3, tread_dark) # Anchor bolts
			# Bunker Core with Armored Vision Slits
			fill_rect(img, 20, 22, 48, 10, b_dark)
			fill_rect(img, 22, 20, 44, 4, b_main)
			fill_rect(img, 30, 24, 7, 2, Color("#0f110c"))
			fill_rect(img, 51, 24, 7, 2, Color("#0f110c"))
			# Armored Turret Mantlet & Azimuth Race
			fill_rect(img, 28, 14, 28, 9, b_dark)
			fill_rect(img, 30, 13, 24, 5, b_main)
			# Twin Heavy Fluted Autocannons
			fill_rect(img, 50, 13, 26, 3, steel) # Upper
			fill_rect(img, 72, 12, 3, 5, tread_dark)
			fill_rect(img, 50, 18, 26, 3, steel) # Lower
			fill_rect(img, 72, 17, 3, 5, tread_dark)
			# FLIR Optics
			fill_rect(img, 38, 10, 5, 3, tread_dark)
			img.set_pixel(41, 11, Color("#38bdf8"))
			
		"truck":
			# Crude Oil Logistics Tanker
			# Wheels
			fill_circle(img, 20, 36, 5, tread_dark)
			fill_circle(img, 32, 36, 5, tread_dark)
			fill_circle(img, 66, 36, 5, tread_dark)
			# Heavy Semi Cab
			fill_rect(img, 54, 20, 20, 15, b_main)
			fill_rect(img, 62, 22, 10, 5, glass)
			fill_rect(img, 55, 12, 3, 10, steel) # Chrome exhaust stack
			# Large Cylindrical Oil Tank Trailer
			fill_rect(img, 12, 18, 42, 15, Color("#262823"))
			fill_rect(img, 14, 16, 38, 3, Color("#42473d"))
			# NFPA Hazard Diamond (Red/Yellow)
			fill_rect(img, 28, 23, 6, 6, Color("#dc2626"))
			fill_rect(img, 29, 24, 4, 4, amber)
			# Catwalk & ladder
			draw_line(img, 14, 16, 50, 16, steel)
			
		"bridge":
			# Tactical Bridge Engineering Action
			# River Water & Foam Waves
			fill_rect(img, 6, 36, 76, 8, Color("#1e3a47"))
			for fx in [10, 26, 42, 58]:
				fill_rect(img, fx, 38, 8, 1, Color("#60a5fa"))
			# Warren-Truss Bridge Girder Structure
			fill_rect(img, 8, 24, 72, 3, steel) # Top chord
			fill_rect(img, 8, 34, 72, 3, steel) # Deck chord
			# Vertical & Diagonal Braces
			for bx in [12, 28, 44, 60]:
				draw_line(img, bx, 34, bx + 8, 24, steel)
				draw_line(img, bx + 8, 24, bx + 16, 34, steel)
				draw_line(img, bx + 8, 24, bx + 8, 34, Color("#52525b"))
			# Crossed Engineering Wrench & Spanner
			draw_line(img, 36, 12, 52, 28, Color("#fef08a"))
			draw_line(img, 52, 12, 36, 28, Color("#fef08a"))
			# Welding Arc Spark Flash
			fill_circle(img, 44, 20, 3, Color("#ffffff"))
			fill_circle(img, 44, 20, 5, Color(1, 0.9, 0.3, 0.6))

		"war_factory":
			# Heavy Industrial Vehicle Factory & Assembly Line
			# Foundation & concrete apron
			fill_rect(img, 8, 34, 72, 10, Color("#363a32"))
			fill_rect(img, 10, 32, 68, 3, Color("#4b5044"))
			# Main Factory Hall (Industrial Olive & Steel)
			fill_rect(img, 12, 18, 52, 15, b_dark)
			fill_rect(img, 14, 16, 48, 3, b_main)
			# Sawtooth Factory Roof with Skylight Glazing
			draw_line(img, 14, 16, 26, 9, steel)
			draw_line(img, 26, 9, 26, 16, glass)
			draw_line(img, 28, 16, 40, 9, steel)
			draw_line(img, 40, 9, 40, 16, glass)
			draw_line(img, 42, 16, 54, 9, steel)
			draw_line(img, 54, 9, 54, 16, glass)
			# Heavy Rollup Garage Bay Door with Warning Stripes
			fill_rect(img, 22, 24, 24, 10, Color("#1f241a"))
			for sy in [25, 28, 31]:
				draw_line(img, 23, sy, 45, sy, Color("#3f4438"))
			# Overhead Heavy Gantry Crane (Industrial Yellow)
			fill_rect(img, 58, 10, 4, 23, amber)
			draw_line(img, 48, 10, 68, 10, amber)
			draw_line(img, 54, 10, 54, 18, steel) # Cable
			fill_rect(img, 52, 18, 5, 4, Color("#fde047")) # Crane block
			# Twin Exhaust Smokestacks
			fill_rect(img, 68, 14, 5, 19, Color("#272a24"))
			fill_circle(img, 70, 10, 3, Color(0.8, 0.8, 0.8, 0.4))
			fill_circle(img, 72, 6, 4, Color(0.7, 0.7, 0.7, 0.25))

		"repair_depot":
			# Armored Maintenance Hangar & Turntable Repair Bay
			# Heavy Octagonal Reinforced Foundation
			fill_rect(img, 10, 34, 68, 10, Color("#2e3428"))
			# Turntable Pad (Steel floor plates)
			fill_circle(img, 44, 32, 16, Color("#3f4538"))
			fill_circle(img, 44, 32, 12, Color("#262a22"))
			fill_circle(img, 44, 32, 4, steel)
			# Yellow & Black Chevron Ring around Turntable
			for a_step in range(0, 12):
				var ang = a_step * PI / 6.0
				var px = int(44 + cos(ang) * 14)
				var py = int(32 + sin(ang) * 14 * 0.5)
				img.set_pixel(px, py, amber if a_step % 2 == 0 else Color("#18181b"))
			# Overhead Articulated Hydraulic Robotic Service Arm
			draw_line(img, 20, 34, 24, 18, steel)
			draw_line(img, 24, 18, 38, 20, steel)
			draw_line(img, 38, 20, 43, 27, Color("#38bdf8"))
			# Electric Welding Arc Flash (Cyan/White)
			fill_circle(img, 43, 27, 2, Color.WHITE)
			fill_circle(img, 43, 27, 5, Color(0.2, 0.75, 1.0, 0.55))
			# Tool Shelves & Diagnostic Console
			fill_rect(img, 64, 22, 10, 12, b_dark)
			fill_rect(img, 66, 24, 6, 4, glass) # Monitor
			img.set_pixel(68, 25, Color("#4ade80")) # Green readout trace

		"refinery_silo":
			# Crude Oil Cracking Silo & Pressurized Storage Spheres
			# Concrete Pad with Bund Wall
			fill_rect(img, 10, 36, 68, 8, Color("#3a3e35"))
			fill_rect(img, 8, 34, 72, 3, Color("#4f5549"))
			# Spherical Horton Storage Tank 1 (Left)
			fill_circle(img, 28, 24, 12, Color("#444b3e"))
			fill_circle(img, 27, 23, 10, Color("#5a6252"))
			fill_circle(img, 25, 21, 3, Color("#808a75")) # Sphere specular highlight
			draw_line(img, 22, 33, 20, 37, steel) # Stilt legs
			draw_line(img, 34, 33, 36, 37, steel)
			# Spherical Horton Storage Tank 2 (Right)
			fill_circle(img, 56, 24, 11, Color("#444b3e"))
			fill_circle(img, 55, 23, 9, Color("#5a6252"))
			fill_circle(img, 53, 21, 3, Color("#808a75"))
			draw_line(img, 51, 33, 49, 37, steel)
			draw_line(img, 61, 33, 63, 37, steel)
			# Interconnecting Industrial High-Pressure Pipe Manifold
			fill_rect(img, 38, 26, 8, 3, steel)
			fill_rect(img, 41, 16, 3, 18, steel)
			# Gas Flare Stack with Open Flame
			draw_line(img, 42, 16, 42, 6, steel)
			fill_circle(img, 42, 5, 2, amber)
			fill_circle(img, 42, 4, 1, Color("#ffffff"))
			fill_circle(img, 42, 3, 2, Color(1.0, 0.4, 0.1, 0.6)) # Flame glow

		"missile_battery":
			# Tactical Surface-to-Air / Ground Guided Missile Battery
			# Fortified Concrete Emplacement
			fill_rect(img, 12, 34, 64, 10, Color("#3a3a38"))
			fill_rect(img, 14, 32, 60, 3, Color("#545452"))
			# Rotating Turntable Ring & Azimuth Pedestal
			fill_rect(img, 32, 26, 24, 7, b_dark)
			# Angled Missile Launcher Quad Pod (45 degree elevation)
			fill_rect(img, 24, 16, 34, 11, b_main)
			# 4 Guided Missile Canisters / Rockets with White/Red Warheads
			for my in [18, 22]:
				# Launcher Rails
				draw_line(img, 26, my + 3, 58, my - 6, steel)
				# Missiles
				draw_line(img, 30, my + 1, 56, my - 6, Color("#e4e4e7"))
				# Red Warhead Tips
				img.set_pixel(57, my - 7, Color("#ef4444"))
				img.set_pixel(58, my - 7, Color("#fca5a5"))
			# Tracking Radar Radome
			fill_circle(img, 22, 16, 5, Color("#d4d4d8"))
			fill_rect(img, 20, 20, 4, 7, steel)
			# Hydraulic Elevation Ram
			draw_line(img, 40, 26, 48, 20, steel)

		"sandbag_wall":
			# Heavy Fortified Earthen Sandbag Revetment & Trench
			# Trench dirt berm
			fill_rect(img, 8, 32, 72, 12, Color("#423a2b"))
			# Tier 1 (Bottom Course of Sandbags)
			for sbx in range(10, 72, 8):
				fill_rect(img, sbx, 34, 7, 5, Color("#8c7e63"))
				fill_rect(img, sbx + 1, 35, 5, 3, Color("#ab9a7a"))
			# Tier 2 (Middle Course)
			for sbx in range(14, 68, 8):
				fill_rect(img, sbx, 28, 7, 5, Color("#7a6c53"))
				fill_rect(img, sbx + 1, 29, 5, 3, Color("#9b8a6a"))
			# Tier 3 (Top Course)
			for sbx in range(18, 64, 8):
				fill_rect(img, sbx, 22, 7, 5, Color("#695c45"))
				fill_rect(img, sbx + 1, 23, 5, 3, Color("#8c7c5d"))
			# Razor / Barbed Wire Concertina Coil along Crest
			for cx in range(16, 68, 6):
				draw_line(img, cx, 19, cx + 3, 16, steel)
				draw_line(img, cx + 3, 16, cx + 6, 19, steel)
				draw_line(img, cx + 6, 19, cx + 3, 22, steel)
				draw_line(img, cx + 3, 22, cx, 19, steel)
			# Wooden Revetment Pickets & Stakes
			draw_line(img, 12, 24, 12, 38, Color("#57452d"))
			draw_line(img, 72, 24, 72, 38, Color("#57452d"))
			
	var tex = ImageTexture.create_from_image(img)
	_cache[cache_key] = tex
	return tex

static func fill_rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	var iw = img.get_width()
	var ih = img.get_height()
	var rx = clamp(x, 0, iw)
	var ry = clamp(y, 0, ih)
	var rw = clamp(x + w, 0, iw) - rx
	var rh = clamp(y + h, 0, ih) - ry
	if rw > 0 and rh > 0:
		img.fill_rect(Rect2i(rx, ry, rw, rh), col)

static func draw_line(img: Image, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	var dx = abs(x1 - x0)
	var dy = -abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy
	var w = img.get_width()
	var h = img.get_height()
	while true:
		if x0 >= 0 and x0 < w and y0 >= 0 and y0 < h:
			img.set_pixel(x0, y0, col)
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

static func fill_circle(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	var w = img.get_width()
	var h = img.get_height()
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy <= r * r:
				var px = cx + dx
				var py = cy + dy
				if px >= 0 and px < w and py >= 0 and py < h:
					img.set_pixel(px, py, col)
