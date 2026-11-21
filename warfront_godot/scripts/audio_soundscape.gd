class_name AudioSoundscape
extends RefCounted

const Helpers = preload("res://scripts/audio_dsp_helpers.gd")

static func synth_distant_thunder() -> AudioStreamWAV:
	var dur = 1.4
	var count = int(dur * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	var brown = 0.0
	for i in range(count):
		var t = float(i) / float(Helpers.SAMPLE_RATE)
		var env = exp(-t * 2.8) * min(1.0, t * 18.0)
		var white = randf_range(-1.0, 1.0)
		brown = (brown + (0.04 * white)) / 1.04
		# Sub-bass rumble (35-55 Hz)
		var rumble = sin(TAU * 42.0 * t) * 0.4
		raw[i] = (brown * 0.7 + rumble) * env * 0.85
		
	var filtered = Helpers.apply_lowpass(raw, 250.0)
	return Helpers.build_wav(filtered)

static func synth_radio_transmission() -> AudioStreamWAV:
	var dur = 0.45
	var count = int(dur * Helpers.SAMPLE_RATE)
	var raw = PackedFloat32Array()
	raw.resize(count)
	
	for i in range(count):
		var t = float(i) / float(Helpers.SAMPLE_RATE)
		var env = 1.0 if (t > 0.05 and t < dur - 0.05) else (t / 0.05 if t <= 0.05 else (dur - t) / 0.05)
		# Narrow bandpass squelch & tactical tone burst
		var white = randf_range(-1.0, 1.0) * 0.25
		var beeps = sin(TAU * 1200.0 * t) * 0.15 + sin(TAU * 880.0 * t) * 0.1
		raw[i] = (white + beeps) * env * 0.45
		
	var filtered = Helpers.apply_lowpass(raw, 2400.0)
	return Helpers.build_wav(filtered)

