class_name AudioUI
extends RefCounted

const Helpers = preload("res://scripts/audio_dsp_helpers.gd")

static func synth_oil_deposit() -> AudioStreamWAV:
	# Heavy Hydraulic Oil Valve Clunk & Flow Chime
	var duration = 0.26
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = exp(-14.0 * t)
		var thud = sin(t * 85.0 * TAU) * 0.7 * env
		var chime = sin(t * 680.0 * TAU) * 0.35 * exp(-18.0 * t)
		raw[i] = thud + chime
		
	return Helpers.build_wav(raw)

static func synth_promotion() -> AudioStreamWAV:
	# Regal Military Trumpet Fanfare Chord (Bb major triad)
	var duration = 0.42
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	var notes = [
		{ "freq": 466.0, "start": 0.0, "len": 0.14 },
		{ "freq": 587.0, "start": 0.09, "len": 0.14 },
		{ "freq": 698.0, "start": 0.18, "len": 0.15 },
		{ "freq": 932.0, "start": 0.27, "len": 0.15 }
	]
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var val = 0.0
		for n in notes:
			if t >= n["start"] and t < n["start"] + n["len"]:
				var dt = t - n["start"]
				var env = exp(-12.0 * dt)
				var brass = sin(dt * n["freq"] * TAU) + sin(dt * n["freq"] * 2.0 * TAU) * 0.4 + sin(dt * n["freq"] * 3.0 * TAU) * 0.18
				val += brass * env * 0.28
		raw[i] = val
		
	return Helpers.build_wav(raw)

static func synth_capture() -> AudioStreamWAV:
	# Tactical Strategic Objective Securing Fanfare
	var duration = 0.35
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = exp(-8.0 * t)
		var freq = 440.0 if t < 0.12 else (554.37 if t < 0.24 else 659.25)
		var chord = sin(t * freq * TAU) * 0.6 * env
		raw[i] = chord
		
	return Helpers.build_wav(raw)

static func synth_order_move() -> AudioStreamWAV:
	# Low Soft Tactical Move Acknowledge Blip
	var duration = 0.07
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = exp(-45.0 * t)
		var blip = sin(t * 880.0 * TAU) * 0.5 * env
		raw[i] = blip
		
	return Helpers.build_wav(raw)

static func synth_order_attack() -> AudioStreamWAV:
	# Urgent Staccato Attack Order Click
	var duration = 0.09
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = exp(-35.0 * t)
		var tone = sin(t * 1174.66 * TAU) * 0.55 * env
		raw[i] = tone
		
	return Helpers.build_wav(raw)

static func synth_unit_select() -> AudioStreamWAV:
	# Clean Military HUD Interface Selection Click
	var duration = 0.04
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = exp(-90.0 * t)
		var val = sin(t * 1400.0 * TAU) * 0.45 * env
		raw[i] = val
		
	return Helpers.build_wav(raw)

static func synth_victory() -> AudioStreamWAV:
	# Triumphant Cinematic Brass Fanfare
	var duration = 1.40
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	var chords = [
		{ "freq": 523.25, "start": 0.0, "len": 0.35 }, # C5
		{ "freq": 659.25, "start": 0.30, "len": 0.35 }, # E5
		{ "freq": 783.99, "start": 0.60, "len": 0.40 }, # G5
		{ "freq": 1046.50, "start": 0.90, "len": 0.50 } # C6
	]
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var val = 0.0
		for c in chords:
			if t >= c["start"] and t < c["start"] + c["len"]:
				var dt = t - c["start"]
				var env = exp(-4.5 * dt)
				var tone = sin(dt * c["freq"] * TAU) * 0.5 + sin(dt * (c["freq"] * 2.0) * TAU) * 0.25
				val += tone * env * 0.4
		raw[i] = val
		
	return Helpers.build_wav(raw)

static func synth_defeat() -> AudioStreamWAV:
	# Somber Low Resonance Brass Dirge
	var duration = 1.20
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	var notes = [
		{ "freq": 220.0, "start": 0.0, "len": 0.4 }, # A3
		{ "freq": 196.0, "start": 0.35, "len": 0.4 }, # G3
		{ "freq": 174.61, "start": 0.70, "len": 0.5 } # F3
	]
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var val = 0.0
		for n in notes:
			if t >= n["start"] and t < n["start"] + n["len"]:
				var dt = t - n["start"]
				var env = exp(-6.0 * dt)
				var tone = sin(dt * n["freq"] * TAU) + sin(dt * (n["freq"] * 1.5) * TAU) * 0.25
				val += tone * env * 0.25
		raw[i] = val
		
	return Helpers.build_wav(raw)

static func synth_salvage_pickup() -> AudioStreamWAV:
	# Crisp Metal Clink & Oil Cargo Collection Chime
	var duration = 0.22
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env1 = exp(-22.0 * t)
		var env2 = exp(-14.0 * max(0.0, t - 0.04))
		var tone1 = sin(t * 987.77 * TAU) * env1 * 0.6 # B5
		var tone2 = sin(max(0.0, t - 0.04) * 1318.51 * TAU) * env2 * 0.5 # E6
		var click = (randf() * 2.0 - 1.0) * exp(-90.0 * t) * 0.35
		raw[i] = tone1 + tone2 + click
		
	return Helpers.build_wav(raw)

static func synth_unit_ready() -> AudioStreamWAV:
	# Tactical Military Comm Squelch & Ready Chime
	var duration = 0.28
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env1 = exp(-18.0 * t)
		var env2 = exp(-12.0 * max(0.0, t - 0.08))
		var tone1 = sin(t * 880.0 * TAU) * env1 * 0.45
		var tone2 = sin(max(0.0, t - 0.08) * 1320.0 * TAU) * env2 * 0.55
		var squelch = (randf() * 2.0 - 1.0) * exp(-50.0 * t) * 0.15
		raw[i] = tone1 + tone2 + squelch
		
	return Helpers.build_wav(raw)

static func synth_order_stop() -> AudioStreamWAV:
	# Hydraulic Air-Brake Release & Gear Clamp
	var duration = 0.22
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var hiss_env = exp(-14.0 * t)
		var hiss = (randf() * 2.0 - 1.0) * hiss_env * 0.4
		var clamp_thud = sin(t * 160.0 * TAU) * exp(-28.0 * t) * 0.6
		var metal_click = (randf() * 2.0 - 1.0) * exp(-70.0 * t) * 0.3
		raw[i] = hiss + clamp_thud + metal_click
		
	var filtered = Helpers.apply_lowpass(raw, 2400.0)
	return Helpers.build_wav(filtered)

static func synth_order_hold() -> AudioStreamWAV:
	# Heavy Armored Brace & Mechanical Lock Clank
	var duration = 0.25
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = exp(-20.0 * t)
		var ring1 = sin(t * 520.0 * TAU) * env * 0.5
		var ring2 = sin(t * 780.0 * TAU) * env * 0.35
		var sub = sin(t * 110.0 * TAU) * exp(-12.0 * t) * 0.7
		raw[i] = ring1 + ring2 + sub
		
	return Helpers.build_wav(raw)

static func synth_order_retreat() -> AudioStreamWAV:
	# Tactical Retreat Alert Pip & Turbine Reverse
	var duration = 0.34
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var pip1 = sin(t * 1560.0 * TAU) * exp(-24.0 * t) * 0.5
		var t2 = max(0.0, t - 0.08)
		var pip2 = sin(t2 * 1170.0 * TAU) * exp(-20.0 * t2) * 0.55
		var turbine = sin(t * (300.0 + t * 400.0) * TAU) * exp(-6.0 * t) * 0.35
		raw[i] = pip1 + pip2 + turbine
		
	return Helpers.build_wav(raw)

static func synth_multi_kill() -> AudioStreamWAV:
	# High-Tech Tactical Multi-Kill Intercom Tone
	var duration = 0.28
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var pip1 = sin(t * 880.0 * TAU) * exp(-22.0 * t) * 0.5
		var t2 = max(0.0, t - 0.08)
		var pip2 = sin(t2 * 1320.0 * TAU) * exp(-18.0 * t2) * 0.6
		var radio_hiss = (randf() * 2.0 - 1.0) * exp(-12.0 * t) * 0.08
		raw[i] = pip1 + pip2 + radio_hiss
		
	return Helpers.build_wav(raw)
