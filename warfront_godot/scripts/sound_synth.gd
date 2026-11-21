class_name SoundSynth
extends Node

const SAMPLE_RATE: int = 44100
const POOL_SIZE: int = 16

var _sounds: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _player_cursor: int = 0

func _ready() -> void:
	initialize()

func initialize() -> void:
	if _sounds.size() > 0:
		return
	# 1. Initialize Polyphonic AudioStreamPlayer Voice Pool
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.push_back(p)
		
	# 2. Pre-render All Studio-Grade Procedural Military Audio Buffers
	_generate_all_sounds()

func play_sound(sfx_name: String) -> void:
	if not is_inside_tree() or not _sounds.has(sfx_name):
		return
		
	var stream: AudioStreamWAV = _sounds[sfx_name]
	var player = _players[_player_cursor]
	_player_cursor = (_player_cursor + 1) % POOL_SIZE
	
	player.stream = stream
	# Natural subtle pitch randomization (prevents machine-gun fatigue)
	if sfx_name == "rapid_fire" or sfx_name == "shot" or sfx_name == "cannon":
		player.pitch_scale = randf_range(0.96, 1.04)
	elif sfx_name == "explosion" or sfx_name == "behemoth_cannon":
		player.pitch_scale = randf_range(0.94, 1.05)
	else:
		player.pitch_scale = 1.0
		
	player.play()

# ------------------------------------------------------------------------------
# Audio Generation Engine (16-bit PCM / 44.1 kHz / Band-limited / IIR Filtered)
# ------------------------------------------------------------------------------

func _generate_all_sounds() -> void:
	_sounds["cannon"] = _synth_cannon()
	_sounds["behemoth_cannon"] = _synth_behemoth_cannon()
	_sounds["rapid_fire"] = _synth_rapid_fire()
	_sounds["shot"] = _synth_shot()
	_sounds["explosion"] = _synth_explosion(false)
	_sounds["bridge_collapse"] = _synth_bridge_collapse()
	_sounds["ricochet"] = _synth_ricochet()
	_sounds["oil_deposit"] = _synth_oil_deposit()
	_sounds["promotion"] = _synth_promotion()
	_sounds["capture"] = _synth_capture()
	_sounds["order_move"] = _synth_order_move()
	_sounds["order_attack"] = _synth_order_attack()
	_sounds["unit_select"] = _synth_unit_select()
	_sounds["order_click"] = _synth_order_move()
	_sounds["victory"] = _synth_victory()
	_sounds["defeat"] = _synth_defeat()
	_sounds["airstrike_jet"] = _synth_airstrike_jet()
	_sounds["siren"] = _synth_siren()
	_sounds["salvage_pickup"] = _synth_salvage_pickup()
	_sounds["recon_ping"] = _synth_recon_ping()
	_sounds["unit_ready"] = _synth_unit_ready()
	_sounds["structure_placed"] = _synth_capture()
	_sounds["order_stop"] = _synth_order_stop()
	_sounds["order_hold"] = _synth_order_hold()
	_sounds["order_retreat"] = _synth_order_retreat()

func _synth_cannon() -> AudioStreamWAV:
	# T-72 125mm Main Battle Tank Cannon
	var duration = 0.30
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-11.0 * t)
		var sub_freq = 130.0 * (1.0 - (float(i) / float(count)) * 0.72)
		var sub = sin(t * sub_freq * TAU) * 0.55 * env
		var noise = (randf() * 2.0 - 1.0) * env * 0.65
		raw[i] = sub + noise
		
	var filtered = _apply_lowpass(raw, 520.0)
	for i in range(min(count, int(0.012 * SAMPLE_RATE))):
		var click = (randf() * 2.0 - 1.0) * (1.0 - float(i) / (0.012 * SAMPLE_RATE)) * 0.35
		filtered[i] += click
		
	return _build_wav(filtered)

func _synth_behemoth_cannon() -> AudioStreamWAV:
	# Dual 152mm Heavy Siege Rail Cannons
	var duration = 0.50
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env1 = exp(-7.5 * t)
		var env2 = exp(-7.5 * max(0.0, t - 0.08))
		var sub1 = sin(t * 88.0 * TAU) * 0.75 * env1
		var sub2 = sin(max(0.0, t - 0.08) * 72.0 * TAU) * 0.65 * env2
		var blast = (randf() * 2.0 - 1.0) * (env1 * 0.7 + env2 * 0.5)
		raw[i] = sub1 + sub2 + blast
		
	var filtered = _apply_lowpass(raw, 440.0)
	return _build_wav(filtered)

func _synth_rapid_fire() -> AudioStreamWAV:
	# 30mm Autocannon Rotary Burst
	var duration = 0.12
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-35.0 * t)
		var snap = sin(t * 260.0 * TAU) * 0.45 * env
		var crack = (randf() * 2.0 - 1.0) * 0.65 * env
		raw[i] = snap + crack
		
	var filtered = _apply_lowpass(raw, 1800.0)
	return _build_wav(filtered)

func _synth_shot() -> AudioStreamWAV:
	# 12.7mm Heavy Anti-Materiel / Turret Machine Gun Shot
	var duration = 0.14
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-28.0 * t)
		var punch = sin(t * 190.0 * TAU) * 0.5 * env
		var noise = (randf() * 2.0 - 1.0) * 0.6 * env
		raw[i] = punch + noise
		
	var filtered = _apply_lowpass(raw, 1200.0)
	return _build_wav(filtered)

func _synth_explosion(_heavy: bool = false) -> AudioStreamWAV:
	# High-Explosive Ordnance Detonation with Sub-Bass Rumble
	var duration = 0.75
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env_initial = exp(-12.0 * t) * 0.85
		var env_tail = exp(-3.2 * t) * 0.65
		var sub = sin(t * 48.0 * TAU) * env_tail
		var debris_noise = (randf() * 2.0 - 1.0) * (env_initial + env_tail * 0.5)
		raw[i] = sub + debris_noise
		
	var filtered = _apply_lowpass(raw, 320.0)
	return _build_wav(filtered)

func _synth_bridge_collapse() -> AudioStreamWAV:
	# Tectonic Steel-Concrete Bridge Destruction
	var duration = 1.10
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-2.4 * t)
		var rumble = sin(t * 34.0 * TAU) * 0.7 * env
		var groan = sin(t * 115.0 * TAU + sin(t * 18.0 * TAU) * 3.0) * 0.35 * env
		var debris = (randf() * 2.0 - 1.0) * 0.75 * env
		raw[i] = rumble + groan + debris
		
	var filtered = _apply_lowpass(raw, 280.0)
	return _build_wav(filtered)

func _synth_ricochet() -> AudioStreamWAV:
	# Sloped Armor High-Velocity Ballistic Deflection
	var duration = 0.18
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-20.0 * t)
		var freq = 2400.0 - (float(i) / float(count)) * 1600.0
		var ping = sin(t * freq * TAU) * 0.75 * env
		var spark = (randf() * 2.0 - 1.0) * 0.25 * env
		raw[i] = ping + spark
		
	return _build_wav(raw)

func _synth_oil_deposit() -> AudioStreamWAV:
	# Heavy Hydraulic Oil Valve Clunk & Flow Chime
	var duration = 0.26
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-14.0 * t)
		var thud = sin(t * 85.0 * TAU) * 0.7 * env
		var chime = sin(t * 680.0 * TAU) * 0.35 * exp(-18.0 * t)
		raw[i] = thud + chime
		
	return _build_wav(raw)

func _synth_promotion() -> AudioStreamWAV:
	# Regal Military Trumpet Fanfare Chord (Bb major triad)
	var duration = 0.42
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	var notes = [
		{ "freq": 466.0, "start": 0.0, "len": 0.14 },
		{ "freq": 587.0, "start": 0.09, "len": 0.14 },
		{ "freq": 698.0, "start": 0.18, "len": 0.15 },
		{ "freq": 932.0, "start": 0.27, "len": 0.15 }
	]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var val = 0.0
		for n in notes:
			if t >= n["start"] and t < n["start"] + n["len"]:
				var dt = t - n["start"]
				var env = exp(-12.0 * dt)
				var brass = sin(dt * n["freq"] * TAU) + sin(dt * n["freq"] * 2.0 * TAU) * 0.4 + sin(dt * n["freq"] * 3.0 * TAU) * 0.18
				val += brass * env * 0.28
		raw[i] = val
		
	return _build_wav(raw)

func _synth_capture() -> AudioStreamWAV:
	# Tactical Strategic Objective Securing Fanfare
	var duration = 0.35
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-8.0 * t)
		var freq = 440.0 if t < 0.12 else (554.37 if t < 0.24 else 659.25)
		var chord = sin(t * freq * TAU) * 0.6 * env
		raw[i] = chord
		
	return _build_wav(raw)

func _synth_order_move() -> AudioStreamWAV:
	# Low Soft Tactical Move Acknowledge Blip
	var duration = 0.07
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-45.0 * t)
		var blip = sin(t * 880.0 * TAU) * 0.5 * env
		raw[i] = blip
		
	return _build_wav(raw)

func _synth_order_attack() -> AudioStreamWAV:
	# Urgent Staccato Attack Order Click
	var duration = 0.09
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-35.0 * t)
		var tone = sin(t * 1174.66 * TAU) * 0.55 * env
		raw[i] = tone
		
	return _build_wav(raw)

func _synth_unit_select() -> AudioStreamWAV:
	# Clean Military HUD Interface Selection Click
	var duration = 0.04
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-90.0 * t)
		var val = sin(t * 1400.0 * TAU) * 0.45 * env
		raw[i] = val
		
	return _build_wav(raw)

func _synth_victory() -> AudioStreamWAV:
	# Triumphant Cinematic Brass Fanfare
	var duration = 1.40
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	var chords = [
		{ "freq": 523.25, "start": 0.0, "len": 0.35 }, # C5
		{ "freq": 659.25, "start": 0.30, "len": 0.35 }, # E5
		{ "freq": 783.99, "start": 0.60, "len": 0.40 }, # G5
		{ "freq": 1046.50, "start": 0.90, "len": 0.50 } # C6
	]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var val = 0.0
		for c in chords:
			if t >= c["start"] and t < c["start"] + c["len"]:
				var dt = t - c["start"]
				var env = exp(-4.5 * dt)
				var tone = sin(dt * c["freq"] * TAU) * 0.5 + sin(dt * (c["freq"] * 2.0) * TAU) * 0.25
				val += tone * env * 0.4
		raw[i] = val
		
	return _build_wav(raw)

func _synth_defeat() -> AudioStreamWAV:
	# Somber Low Resonance Brass Dirge
	var duration = 1.20
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	var notes = [
		{ "freq": 220.0, "start": 0.0, "len": 0.4 }, # A3
		{ "freq": 196.0, "start": 0.35, "len": 0.4 }, # G3
		{ "freq": 174.61, "start": 0.70, "len": 0.5 } # F3
	]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var val = 0.0
		for n in notes:
			if t >= n["start"] and t < n["start"] + n["len"]:
				var dt = t - n["start"]
				var env = exp(-6.0 * dt)
				var tone = sin(dt * n["freq"] * TAU) + sin(dt * (n["freq"] * 1.5) * TAU) * 0.25
				val += tone * env * 0.25
		raw[i] = val
		
	return _build_wav(raw)

func _synth_airstrike_jet() -> AudioStreamWAV:
	# Supersonic Jet Fighter Flyby with Doppler Frequency Drop & Turbine Roar
	var duration = 0.85
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / float(count)
		var freq = 680.0 * (1.0 - progress * 0.68)
		var amp = sin(progress * PI)
		var tone = sin(t * freq * TAU) * 0.35
		var sub = sin(t * (freq * 0.5) * TAU) * 0.4
		var white_noise = (randf() * 2.0 - 1.0) * 0.55
		raw[i] = (tone + sub + white_noise) * amp
		
	var filtered = _apply_lowpass(raw, 750.0)
	return _build_wav(filtered)

func _synth_siren() -> AudioStreamWAV:
	# Air-Raid / Escalation Warning Siren
	var duration = 0.60
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var mod = sin(t * 7.0 * TAU) * 120.0
		var freq = 580.0 + mod
		var env = min(1.0, t * 12.0) * (1.0 - (float(i) / float(count)) * 0.4)
		var val = sin(t * freq * TAU) * 0.65 + sin(t * (freq * 2.0) * TAU) * 0.2
		raw[i] = val * env
		
	return _build_wav(raw)

func _synth_salvage_pickup() -> AudioStreamWAV:
	# Crisp Metal Clink & Oil Cargo Collection Chime
	var duration = 0.22
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env1 = exp(-22.0 * t)
		var env2 = exp(-14.0 * max(0.0, t - 0.04))
		var tone1 = sin(t * 987.77 * TAU) * env1 * 0.6 # B5
		var tone2 = sin(max(0.0, t - 0.04) * 1318.51 * TAU) * env2 * 0.5 # E6
		var click = (randf() * 2.0 - 1.0) * exp(-90.0 * t) * 0.35
		raw[i] = tone1 + tone2 + click
		
	return _build_wav(raw)

func _synth_recon_ping() -> AudioStreamWAV:
	# Radar / Sonar Sweep Pulse Chirp
	var duration = 0.32
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / float(count)
		var freq = 1200.0 + progress * 600.0
		var env = exp(-8.0 * t)
		var val = sin(t * freq * TAU) * env * 0.55 + sin(t * (freq * 1.5) * TAU) * env * 0.2
		raw[i] = val
		
	return _build_wav(raw)

func _synth_unit_ready() -> AudioStreamWAV:
	# Tactical Military Comm Squelch & Ready Chime (880Hz -> 1320Hz rising chime + radio gate)
	var duration = 0.28
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env1 = exp(-18.0 * t)
		var env2 = exp(-12.0 * max(0.0, t - 0.08))
		var tone1 = sin(t * 880.0 * TAU) * env1 * 0.45
		var tone2 = sin(max(0.0, t - 0.08) * 1320.0 * TAU) * env2 * 0.55
		# Radio noise burst at onset
		var squelch = (randf() * 2.0 - 1.0) * exp(-50.0 * t) * 0.15
		raw[i] = tone1 + tone2 + squelch
		
	return _build_wav(raw)

func _synth_order_stop() -> AudioStreamWAV:
	# Hydraulic Air-Brake Release & Gear Clamp
	var duration = 0.22
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var hiss_env = exp(-14.0 * t)
		var hiss = (randf() * 2.0 - 1.0) * hiss_env * 0.4
		var clamp_thud = sin(t * 160.0 * TAU) * exp(-28.0 * t) * 0.6
		var metal_click = (randf() * 2.0 - 1.0) * exp(-70.0 * t) * 0.3
		raw[i] = hiss + clamp_thud + metal_click
		
	var filtered = _apply_lowpass(raw, 2400.0)
	return _build_wav(filtered)

func _synth_order_hold() -> AudioStreamWAV:
	# Heavy Armored Brace & Mechanical Lock Clank
	var duration = 0.25
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-20.0 * t)
		var ring1 = sin(t * 520.0 * TAU) * env * 0.5
		var ring2 = sin(t * 780.0 * TAU) * env * 0.35
		var sub = sin(t * 110.0 * TAU) * exp(-12.0 * t) * 0.7
		raw[i] = ring1 + ring2 + sub
		
	return _build_wav(raw)

func _synth_order_retreat() -> AudioStreamWAV:
	# Tactical Retreat Alert Pip & Turbine Reverse
	var duration = 0.34
	var count = int(duration * SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var pip1 = sin(t * 1560.0 * TAU) * exp(-24.0 * t) * 0.5
		var t2 = max(0.0, t - 0.08)
		var pip2 = sin(t2 * 1170.0 * TAU) * exp(-20.0 * t2) * 0.55
		var turbine = sin(t * (300.0 + t * 400.0) * TAU) * exp(-6.0 * t) * 0.35
		raw[i] = pip1 + pip2 + turbine
		
	return _build_wav(raw)

# ------------------------------------------------------------------------------
# Digital Signal Processing (DSP) Filters & WAV Builder
# ------------------------------------------------------------------------------

func _apply_lowpass(samples: PackedFloat32Array, cutoff_hz: float) -> PackedFloat32Array:
	var out = PackedFloat32Array()
	out.resize(samples.size())
	var rc = 1.0 / (TAU * cutoff_hz)
	var dt = 1.0 / float(SAMPLE_RATE)
	var alpha = dt / (rc + dt)
	var prev = 0.0
	for i in range(samples.size()):
		prev = prev + alpha * (samples[i] - prev)
		out[i] = prev
	return out

func _build_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	
	var bytes = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var s = samples[i]
		s = clampf(s, -1.0, 1.0)
		s = s * (1.5 - 0.5 * s * s)
		s = clampf(s, -0.98, 0.98)
		var int_val = int(round(s * 32767.0))
		bytes.encode_s16(i * 2, int_val)
		
	wav.data = bytes
	return wav
