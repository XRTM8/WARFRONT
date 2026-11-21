class_name HardwareDisplayManager
extends RefCounted

signal display_settings_changed(settings: Dictionary)
signal fps_limit_changed(fps: int)

static var instance = null

# Current Applied Configuration
var current_preset: String = "high"
var current_fps_limit: int = 120
var current_vsync_mode: String = "adaptive"
var current_window_mode: String = "windowed"
var show_fps_overlay: bool = true

var hardware_info: Dictionary = {}
var active_settings: Dictionary = {}

func _init() -> void:
	instance = self
	detect_hardware_capabilities()
	auto_detect_and_apply()

static func get_instance():
	if instance == null:
		instance = load("res://scripts/hardware_display_manager.gd").new()
	return instance

func detect_hardware_capabilities() -> Dictionary:
	var screen_idx = 0
	var screen_size = Vector2i(1280, 720)
	var screen_hz = 60.0
	
	if DisplayServer.get_name() != "headless":
		screen_size = DisplayServer.screen_get_size(screen_idx)
		var detected_hz = DisplayServer.screen_get_refresh_rate(screen_idx)
		if detected_hz > 0.0:
			screen_hz = detected_hz
			
	var gpu_name = RenderingServer.get_video_adapter_name()
	if gpu_name.is_empty():
		gpu_name = "Hardware Accelerated Rasterizer"
		
	var lower_gpu = gpu_name.to_lower()
	var gpu_vendor = "Standard Vendor"
	if "nvidia" in lower_gpu or "geforce" in lower_gpu or "rtx" in lower_gpu or "gtx" in lower_gpu:
		gpu_vendor = "NVIDIA"
	elif "amd" in lower_gpu or "radeon" in lower_gpu or "rx " in lower_gpu:
		gpu_vendor = "AMD"
	elif "intel" in lower_gpu or "arc" in lower_gpu:
		gpu_vendor = "Intel"
	elif "apple" in lower_gpu:
		gpu_vendor = "Apple"
		
	var cpu_cores = OS.get_processor_count()
	var cpu_name = OS.get_processor_name()
	if cpu_name.is_empty():
		cpu_name = "Multi-Core System Processor"
		
	# Determine Hardware Profile Tier
	var tier = "medium"
	var is_dedicated_gpu = (gpu_vendor in ["NVIDIA", "AMD"] or "arc" in lower_gpu or "discrete" in lower_gpu)
	
	if is_dedicated_gpu and cpu_cores >= 8:
		tier = "ultra"
	elif is_dedicated_gpu or cpu_cores >= 6:
		tier = "high"
	elif cpu_cores >= 4:
		tier = "medium"
	else:
		tier = "low"
		
	hardware_info = {
		"gpu_name": gpu_name,
		"gpu_vendor": gpu_vendor,
		"cpu_cores": cpu_cores,
		"cpu_name": cpu_name,
		"screen_size": screen_size,
		"monitor_hz": screen_hz,
		"device_tier": tier,
		"is_high_refresh": (screen_hz >= 119.0)
	}
	return hardware_info

func auto_detect_and_apply() -> Dictionary:
	if hardware_info.is_empty():
		detect_hardware_capabilities()
		
	var tier = hardware_info.get("device_tier", "high")
	apply_quality_preset(tier)
	
	# If display is high-refresh (120Hz/144Hz/240Hz), automatically lock to 120+ FPS
	var mon_hz = hardware_info.get("monitor_hz", 60.0)
	if mon_hz >= 119.0:
		apply_fps_limit(int(round(mon_hz)))
		apply_vsync_mode("adaptive")
	else:
		apply_fps_limit(120) # Unlock 120 FPS by default for smooth responsiveness
		apply_vsync_mode("mailbox")
		
	return active_settings

func apply_fps_limit(target_fps: int) -> void:
	# target_fps: -1 = Auto Hz, 0 = Uncapped, 60, 120, 144, 240
	if target_fps == -1:
		var hz = hardware_info.get("monitor_hz", 60.0)
		current_fps_limit = int(round(hz)) if hz > 45.0 else 60
	else:
		current_fps_limit = target_fps
		
	Engine.max_fps = current_fps_limit
	fps_limit_changed.emit(current_fps_limit)

func apply_vsync_mode(mode: String) -> void:
	current_vsync_mode = mode
	if DisplayServer.get_name() == "headless":
		return
		
	match mode:
		"adaptive":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
		"mailbox":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)
		"enabled":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		"disabled":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		_:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

func apply_quality_preset(preset_name: String) -> Dictionary:
	current_preset = preset_name
	
	match preset_name:
		"low":
			active_settings = {
				"preset": "low",
				"particle_multiplier": 0.50,
				"directional_shadows": false,
				"dynamic_muzzle_lights": false,
				"atmospheric_motes": false,
				"water_dynamics": "low",
				"crt_vignette": false,
				"debris_lifetime_mult": 0.50
			}
		"medium":
			active_settings = {
				"preset": "medium",
				"particle_multiplier": 0.80,
				"directional_shadows": true,
				"dynamic_muzzle_lights": true,
				"atmospheric_motes": false,
				"water_dynamics": "medium",
				"crt_vignette": true,
				"debris_lifetime_mult": 0.80
			}
		"high":
			active_settings = {
				"preset": "high",
				"particle_multiplier": 1.00,
				"directional_shadows": true,
				"dynamic_muzzle_lights": true,
				"atmospheric_motes": true,
				"water_dynamics": "high",
				"crt_vignette": true,
				"debris_lifetime_mult": 1.00
			}
		"ultra":
			active_settings = {
				"preset": "ultra",
				"particle_multiplier": 1.40,
				"directional_shadows": true,
				"dynamic_muzzle_lights": true,
				"atmospheric_motes": true,
				"water_dynamics": "ultra",
				"crt_vignette": true,
				"debris_lifetime_mult": 1.30
			}
		_:
			active_settings = apply_quality_preset("high")
			
	display_settings_changed.emit(active_settings)
	return active_settings

func apply_window_mode(mode: String) -> void:
	current_window_mode = mode
	if DisplayServer.get_name() == "headless":
		return
		
	match mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func get_diagnostics() -> Dictionary:
	var current_fps = Engine.get_frames_per_second()
	var frame_time_ms = (1000.0 / max(1.0, float(current_fps)))
	
	return {
		"current_fps": current_fps,
		"frame_time_ms": frame_time_ms,
		"target_fps": current_fps_limit,
		"monitor_hz": hardware_info.get("monitor_hz", 60.0),
		"quality_preset": current_preset,
		"vsync_mode": current_vsync_mode,
		"gpu_name": hardware_info.get("gpu_name", "GPU"),
		"cpu_cores": hardware_info.get("cpu_cores", 4),
		"screen_size": hardware_info.get("screen_size", Vector2i(1280, 720)),
		"show_overlay": show_fps_overlay
	}
