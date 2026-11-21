class_name AudioImpacts
extends RefCounted

const Helpers = preload("res://scripts/audio_dsp_helpers.gd")

static func synth_explosion(_heavy: bool = false) -> AudioStreamWAV:
	# High-Explosive Ordnance Detonation with Sub-Bass Rumble
	var duration = 0.75
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env_initial = exp(-12.0 * t) * 0.85
		var env_tail = exp(-3.2 * t) * 0.65
		var sub = sin(t * 48.0 * TAU) * env_tail
		var debris_noise = (randf() * 2.0 - 1.0) * (env_initial + env_tail * 0.5)
		raw[i] = sub + debris_noise
		
	var filtered = Helpers.apply_lowpass(raw, 320.0)
	return Helpers.build_wav(filtered)

static func synth_bridge_collapse() -> AudioStreamWAV:
	# Tectonic Steel-Concrete Bridge Destruction
	var duration = 1.10
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = exp(-2.4 * t)
		var rumble = sin(t * 34.0 * TAU) * 0.7 * env
		var groan = sin(t * 115.0 * TAU + sin(t * 18.0 * TAU) * 3.0) * 0.35 * env
		var debris = (randf() * 2.0 - 1.0) * 0.75 * env
		raw[i] = rumble + groan + debris
		
	var filtered = Helpers.apply_lowpass(raw, 280.0)
	return Helpers.build_wav(filtered)

static func synth_ricochet() -> AudioStreamWAV:
	# Sloped Armor High-Velocity Ballistic Deflection
	var duration = 0.18
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = exp(-20.0 * t)
		var freq = 2400.0 - (float(i) / float(count)) * 1600.0
		var ping = sin(t * freq * TAU) * 0.75 * env
		var spark = (randf() * 2.0 - 1.0) * 0.25 * env
		raw[i] = ping + spark
		
	return Helpers.build_wav(raw)

static func synth_turret_crash() -> AudioStreamWAV:
	# Heavy Flying Turret Ground Slam & Scraping Crunch
	var duration = 0.45
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env_impact = exp(-14.0 * t)
		var env_scrape = exp(-8.0 * t)
		var thud = sin(t * 78.0 * TAU) * env_impact * 0.8
		var metal_ring = sin(t * 380.0 * TAU) * exp(-18.0 * t) * 0.4
		var crunch = (randf() * 2.0 - 1.0) * env_scrape * 0.55
		raw[i] = thud + metal_ring + crunch
		
	var filtered = Helpers.apply_lowpass(raw, 850.0)
	return Helpers.build_wav(filtered)

static func synth_mine_detonate() -> AudioStreamWAV:
	# Heavy Anti-Tank Landmine Crack & Shockwave
	var duration = 0.42
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var crack = exp(-26.0 * t) * (randf() * 2.0 - 1.0) * 0.85
		var sub = sin(t * 68.0 * TAU) * exp(-10.0 * t) * 0.75
		var hollow = sin(t * 280.0 * TAU) * exp(-18.0 * t) * 0.3
		raw[i] = crack + sub + hollow
		
	var filtered = Helpers.apply_lowpass(raw, 920.0)
	return Helpers.build_wav(filtered)
