class_name AudioComms
extends RefCounted

const Helpers = preload("res://scripts/audio_dsp_helpers.gd")

static func synth_airstrike_jet() -> AudioStreamWAV:
	# Supersonic Jet Fighter Flyby with Doppler Frequency Drop & Turbine Roar
	var duration = 0.85
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var progress = float(i) / float(count)
		var freq = 680.0 * (1.0 - progress * 0.68)
		var amp = sin(progress * PI)
		var tone = sin(t * freq * TAU) * 0.35
		var sub = sin(t * (freq * 0.5) * TAU) * 0.4
		var white_noise = (randf() * 2.0 - 1.0) * 0.55
		raw[i] = (tone + sub + white_noise) * amp
		
	var filtered = Helpers.apply_lowpass(raw, 750.0)
	return Helpers.build_wav(filtered)

static func synth_siren() -> AudioStreamWAV:
	# Air-Raid / Escalation Warning Siren
	var duration = 0.60
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var mod = sin(t * 7.0 * TAU) * 120.0
		var freq = 580.0 + mod
		var env = min(1.0, t * 12.0) * (1.0 - (float(i) / float(count)) * 0.4)
		var val = sin(t * freq * TAU) * 0.65 + sin(t * (freq * 2.0) * TAU) * 0.2
		raw[i] = val * env
		
	return Helpers.build_wav(raw)

static func synth_recon_ping() -> AudioStreamWAV:
	# Radar / Sonar Sweep Pulse Chirp
	var duration = 0.32
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var progress = float(i) / float(count)
		var freq = 1200.0 + progress * 600.0
		var env = exp(-8.0 * t)
		var val = sin(t * freq * TAU) * env * 0.55 + sin(t * (freq * 1.5) * TAU) * env * 0.2
		raw[i] = val
		
	return Helpers.build_wav(raw)

static func synth_war_horn() -> AudioStreamWAV:
	# Epic Brass War-Horn Fanfare for Combat Surge
	var duration = 0.85
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var attack = min(1.0, t / 0.08)
		var decay = exp(-2.8 * t)
		var env = attack * decay
		var vib = sin(t * 5.5 * TAU) * 0.015
		
		var f1 = (220.0 + vib * 220.0) * TAU
		var f2 = (330.0 + vib * 330.0) * TAU
		var f3 = (440.0 + vib * 440.0) * TAU
		var f4 = (554.0 + vib * 554.0) * TAU
		
		var s = sin(t * f1) * 0.45 + sin(t * f2) * 0.35 + sin(t * f3) * 0.25 + sin(t * f4) * 0.15
		s = s + s * s * 0.2
		raw[i] = s * env * 0.7
		
	var filtered = Helpers.apply_lowpass(raw, 1100.0)
	return Helpers.build_wav(filtered)

static func synth_cargo_flyby() -> AudioStreamWAV:
	# Deep Turboprop Cargo Aircraft Flyby Drone
	var duration = 0.90
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var env = sin(clampf(t / duration, 0.0, 1.0) * PI)
		var pitch_shift = 1.08 - (t / duration) * 0.16
		var prop1 = sin(t * 72.0 * pitch_shift * TAU) * 0.5
		var prop2 = sin(t * 144.0 * pitch_shift * TAU) * 0.35
		var prop3 = sin(t * 216.0 * pitch_shift * TAU) * 0.2
		var flutter = 0.8 + 0.2 * sin(t * 22.0 * TAU)
		raw[i] = (prop1 + prop2 + prop3) * flutter * env * 0.7
		
	var filtered = Helpers.apply_lowpass(raw, 650.0)
	return Helpers.build_wav(filtered)

static func synth_radio_squawk() -> AudioStreamWAV:
	# Tactical VHF Radio Squelch & Mic-Key Click
	var duration = 0.11
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var click = sin(t * 2600.0 * TAU) * exp(-85.0 * t) * 0.7
		var hiss = (randf() * 2.0 - 1.0) * sin(clampf(t / duration, 0.0, 1.0) * PI) * 0.35
		var hum = sin(t * 120.0 * TAU) * 0.12
		raw[i] = click + hiss + hum
		
	var filtered = Helpers.apply_lowpass(raw, 3200.0)
	return Helpers.build_wav(filtered)

static func synth_bark_roger() -> AudioStreamWAV:
	# Procedural Formant Vocal Bark: "RO-GER" over Combat Tactical Radio
	var duration = 0.32
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var vocal = 0.0
		var glottal = (fmod(t * 120.0, 1.0) - 0.5) * 2.0
		
		# Syllable 1: "RO" (0 to 0.15s) - F1: 520Hz, F2: 1050Hz
		if t < 0.15:
			var env1 = sin((t / 0.15) * PI)
			var f1 = sin(t * 520.0 * TAU) * 0.45
			var f2 = sin(t * 1050.0 * TAU) * 0.35
			vocal = glottal * (f1 + f2) * env1
		# Syllable 2: "GER" (0.16s to 0.31s) - F1: 440Hz, F2: 1750Hz
		elif t >= 0.16 and t < 0.31:
			var t_s2 = t - 0.16
			var env2 = sin((t_s2 / 0.15) * PI)
			var f1 = sin(t * 440.0 * TAU) * 0.4
			var f2 = sin(t * 1750.0 * TAU) * 0.45
			vocal = glottal * (f1 + f2) * env2
			
		var rf_noise = (randf() * 2.0 - 1.0) * 0.08
		raw[i] = vocal * 0.85 + rf_noise
		
	var filtered = Helpers.apply_lowpass(raw, 2800.0)
	return Helpers.build_wav(filtered)

static func synth_bark_retreat() -> AudioStreamWAV:
	# Procedural Formant Vocal Bark: "FALL-BACK" over Combat Tactical Radio
	var duration = 0.35
	var count = int(duration * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / Helpers.SAMPLE_RATE
		var vocal = 0.0
		var glottal = (fmod(t * 135.0, 1.0) - 0.5) * 2.0
		
		# Syllable 1: "FALL" (0 to 0.17s) - F1: 650Hz, F2: 1150Hz
		if t < 0.17:
			var env1 = sin((t / 0.17) * PI)
			var f1 = sin(t * 650.0 * TAU) * 0.5
			var f2 = sin(t * 1150.0 * TAU) * 0.3
			vocal = glottal * (f1 + f2) * env1
		# Syllable 2: "BACK" (0.18s to 0.34s) - F1: 720Hz, F2: 1800Hz
		elif t >= 0.18 and t < 0.34:
			var t_s2 = t - 0.18
			var env2 = sin((t_s2 / 0.16) * PI)
			var f1 = sin(t * 720.0 * TAU) * 0.45
			var f2 = sin(t * 1800.0 * TAU) * 0.4
			vocal = glottal * (f1 + f2) * env2
			
		var rf_noise = (randf() * 2.0 - 1.0) * 0.09
		raw[i] = vocal * 0.85 + rf_noise
		
	var filtered = Helpers.apply_lowpass(raw, 2700.0)
	return Helpers.build_wav(filtered)
