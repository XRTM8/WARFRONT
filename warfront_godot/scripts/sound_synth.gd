class_name SoundSynth
extends Node

const Helpers = preload("res://scripts/audio_dsp_helpers.gd")
const Weapons = preload("res://scripts/audio_weapons.gd")
const Impacts = preload("res://scripts/audio_impacts.gd")
const Comms = preload("res://scripts/audio_comms.gd")
const UI = preload("res://scripts/audio_ui.gd")

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
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.push_back(p)
		
	_generate_all_sounds()

func play_sound(sfx_name: String) -> void:
	if not is_inside_tree() or not _sounds.has(sfx_name):
		return
		
	var stream: AudioStreamWAV = _sounds[sfx_name]
	var player = _players[_player_cursor]
	_player_cursor = (_player_cursor + 1) % POOL_SIZE
	
	player.stream = stream
	if sfx_name in ["rapid_fire", "shot", "cannon"]:
		player.pitch_scale = randf_range(0.96, 1.04)
	elif sfx_name in ["explosion", "behemoth_cannon"]:
		player.pitch_scale = randf_range(0.94, 1.05)
	else:
		player.pitch_scale = 1.0
		
	player.play()

func _generate_all_sounds() -> void:
	# 1. Weapon Ballistics
	_sounds["cannon"] = Weapons.synth_cannon()
	_sounds["behemoth_cannon"] = Weapons.synth_behemoth_cannon()
	_sounds["rapid_fire"] = Weapons.synth_rapid_fire()
	_sounds["shot"] = Weapons.synth_shot()
	_sounds["hydra_salvo"] = Weapons.synth_hydra_salvo()

	# 2. Impacts & Destructions
	_sounds["explosion"] = Impacts.synth_explosion(false)
	_sounds["bridge_collapse"] = Impacts.synth_bridge_collapse()
	_sounds["ricochet"] = Impacts.synth_ricochet()
	_sounds["turret_crash"] = Impacts.synth_turret_crash()
	_sounds["mine_detonate"] = Impacts.synth_mine_detonate()

	# 3. Comms, Radio & Flybys
	_sounds["airstrike_jet"] = Comms.synth_airstrike_jet()
	_sounds["siren"] = Comms.synth_siren()
	_sounds["recon_ping"] = Comms.synth_recon_ping()
	_sounds["war_horn"] = Comms.synth_war_horn()
	_sounds["cargo_flyby"] = Comms.synth_cargo_flyby()
	_sounds["radio_in"] = Comms.synth_radio_squawk()
	_sounds["bark_roger"] = Comms.synth_bark_roger()
	_sounds["bark_retreat"] = Comms.synth_bark_retreat()

	# 4. Tactical UI, Objectives & Orders
	_sounds["oil_deposit"] = UI.synth_oil_deposit()
	_sounds["promotion"] = UI.synth_promotion()
	_sounds["capture"] = UI.synth_capture()
	_sounds["structure_placed"] = UI.synth_capture()
	_sounds["order_move"] = UI.synth_order_move()
	_sounds["order_click"] = UI.synth_order_move()
	_sounds["order_attack"] = UI.synth_order_attack()
	_sounds["order_stop"] = UI.synth_order_stop()
	_sounds["order_hold"] = UI.synth_order_hold()
	_sounds["order_retreat"] = UI.synth_order_retreat()
	_sounds["unit_select"] = UI.synth_unit_select()
	_sounds["unit_ready"] = UI.synth_unit_ready()
	_sounds["salvage_pickup"] = UI.synth_salvage_pickup()
	_sounds["multi_kill"] = UI.synth_multi_kill()
	_sounds["victory"] = UI.synth_victory()
	_sounds["defeat"] = UI.synth_defeat()

# Backward-compatibility delegates for test runner & direct calls
func _synth_cannon() -> AudioStreamWAV: return Weapons.synth_cannon()
func _synth_behemoth_cannon() -> AudioStreamWAV: return Weapons.synth_behemoth_cannon()
func _synth_rapid_fire() -> AudioStreamWAV: return Weapons.synth_rapid_fire()
func _synth_shot() -> AudioStreamWAV: return Weapons.synth_shot()
func _synth_explosion(heavy: bool = false) -> AudioStreamWAV: return Impacts.synth_explosion(heavy)
func _synth_bridge_collapse() -> AudioStreamWAV: return Impacts.synth_bridge_collapse()
func _synth_ricochet() -> AudioStreamWAV: return Impacts.synth_ricochet()
func _apply_lowpass(raw: PackedFloat32Array, cutoff: float) -> PackedFloat32Array: return Helpers.apply_lowpass(raw, cutoff)
func _build_wav(raw: PackedFloat32Array) -> AudioStreamWAV: return Helpers.build_wav(raw)
