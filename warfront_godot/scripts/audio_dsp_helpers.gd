class_name AudioDSPHelpers
extends RefCounted

const SAMPLE_RATE: int = 44100

static func apply_lowpass(samples: PackedFloat32Array, cutoff_hz: float) -> PackedFloat32Array:
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

static func build_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	
	var bytes = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var s = samples[i]
		s = clampf(s, -1.0, 1.0)
		s = s * (1.5 - 0.5 * s * s) # Soft saturation
		s = clampf(s, -0.98, 0.98)
		var int_val = int(round(s * 32767.0))
		bytes.encode_s16(i * 2, int_val)
		
	wav.data = bytes
	return wav
