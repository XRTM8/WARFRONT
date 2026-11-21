class_name AudioWeapons
extends RefCounted

const Helpers = preload("res://scripts/audio_dsp_helpers.gd")

static func synth_cannon() -> AudioStreamWAV:
	# T-72 125mm Main Battle Tank Cannon
	var duration = 0.30
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = exp(-11.0 * t)
		var sub_freq = 130.0 * (1.0 - (float(i) / float(count)) * 0.72)
		var sub = sin(t * sub_freq * TAU) * 0.55 * env
		var noise = (randf() * 2.0 - 1.0) * env * 0.65
		raw[i] = sub + noise
		
	var filtered = Helpers.apply_lowpass(raw, 520.0)
	for i in range(min(count, int(0.012 * Helpers.SAMPLE_RATE))):
		var click = (randf() * 2.0 - 1.0) * (1.0 - float(i) / (0.012 * Helpers.SAMPLE_RATE)) * 0.35
		filtered[i] += click
		
	return Helpers.build_wav(filtered)

static func synth_behemoth_cannon() -> AudioStreamWAV:
	# Dual 152mm Heavy Siege Rail Cannons
	var duration = 0.50
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env1 = exp(-7.5 * t)
		var env2 = exp(-7.5 * max(0.0, t - 0.08))
		var sub1 = sin(t * 88.0 * TAU) * 0.75 * env1
		var sub2 = sin(max(0.0, t - 0.08) * 72.0 * TAU) * 0.65 * env2
		var blast = (randf() * 2.0 - 1.0) * (env1 * 0.7 + env2 * 0.5)
		raw[i] = sub1 + sub2 + blast
		
	var filtered = Helpers.apply_lowpass(raw, 440.0)
	return Helpers.build_wav(filtered)

static func synth_rapid_fire() -> AudioStreamWAV:
	# 30mm Autocannon Rotary Burst
	var duration = 0.12
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = exp(-35.0 * t)
		var snap = sin(t * 260.0 * TAU) * 0.45 * env
		var crack = (randf() * 2.0 - 1.0) * 0.65 * env
		raw[i] = snap + crack
		
	var filtered = Helpers.apply_lowpass(raw, 1800.0)
	return Helpers.build_wav(filtered)

static func synth_shot() -> AudioStreamWAV:
	# 12.7mm Heavy Anti-Materiel / Turret Machine Gun Shot
	var duration = 0.14
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = exp(-28.0 * t)
		var punch = sin(t * 190.0 * TAU) * 0.5 * env
		var noise = (randf() * 2.0 - 1.0) * 0.6 * env
		raw[i] = punch + noise
		
	var filtered = Helpers.apply_lowpass(raw, 1200.0)
	return Helpers.build_wav(filtered)

static func synth_hydra_salvo() -> AudioStreamWAV:
	# Quad Spiraling Hydra Micro-Missile Whistles
	var duration = 0.48
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var val = 0.0
		for r in range(4):
			var r_start = float(r) * 0.075
			if t >= r_start:
				var rt = t - r_start
				var renv = exp(-16.0 * rt)
				var rfreq = (340.0 + rt * 1800.0) * TAU
				var rwhistle = sin(rt * rfreq) * 0.35
				var rhiss = (randf() * 2.0 - 1.0) * 0.25
				val += (rwhistle + rhiss) * renv
		raw[i] = val * 0.65
		
	var filtered = Helpers.apply_lowpass(raw, 2400.0)
	return Helpers.build_wav(filtered)
