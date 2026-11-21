class_name HUDModalDebrief
extends RefCounted

const HUDModalCommon = preload("res://scripts/hud_modal_common.gd")

static func build_debrief_modal(parent_canvas: CanvasLayer, on_restart: Callable, on_change_theater: Callable) -> Dictionary:
	var debrief_panel = PanelContainer.new()
	debrief_panel.set_anchors_preset(Control.PRESET_CENTER)
	debrief_panel.custom_minimum_size = Vector2(400, 420)
	debrief_panel.position = Vector2(-200, -210)
	
	var style = HUDModalCommon.create_military_panel_style()
	debrief_panel.add_theme_stylebox_override("panel", style)
	debrief_panel.visible = false
	parent_canvas.add_child(debrief_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	debrief_panel.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "تقرير انتهاء المعركة"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_lbl)
	
	var status_lbl = Label.new()
	status_lbl.text = ""
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(status_lbl)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(stats_vbox)
	
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	var play_again_btn = HUDModalCommon.create_menu_button("[ DEPLOY AGAIN // خوض المعركة مجدداً ]", Color("#73d65e"))
	play_again_btn.pressed.connect(on_restart)
	vbox.add_child(play_again_btn)
	
	var change_th_btn = HUDModalCommon.create_menu_button("[ CHANGE THEATER // مسرح عمليات آخر ]", Color("#38bdf8"))
	change_th_btn.pressed.connect(on_change_theater)
	vbox.add_child(change_th_btn)
	
	return {
		"panel": debrief_panel,
		"title_label": title_lbl,
		"status_label": status_lbl,
		"stats_vbox": stats_vbox
	}

static func update_debrief_stats(sim, debrief_dict: Dictionary) -> void:
	var stats_vbox: VBoxContainer = debrief_dict.get("stats_vbox", null)
	var title_lbl: Label = debrief_dict.get("title_label", null)
	var status_lbl: Label = debrief_dict.get("status_label", null)
	if stats_vbox == null or title_lbl == null or status_lbl == null:
		return

	for c in stats_vbox.get_children():
		c.queue_free()
		
	var is_vic = sim.outcome == "victory"
	if is_vic:
		title_lbl.text = "[ VICTORY // انتصار حاسم ]"
		title_lbl.add_theme_color_override("font_color", Color("#73d65e"))
		status_lbl.text = "تم سحق قيادة العدو وتأمين السيطرة التامة على المنشآت النفطية!"
		status_lbl.add_theme_color_override("font_color", Color("#a3e635"))
	else:
		title_lbl.text = "[ DEFEAT // انتكاسة تكتيكية ]"
		title_lbl.add_theme_color_override("font_color", Color("#ef4444"))
		status_lbl.text = "تم اختراق وتدمير المقر القيادي لقواتك وسقوط قطاع النفط!"
		status_lbl.add_theme_color_override("font_color", Color("#fca5a5"))
		
	var mins = int(sim.elapsed_seconds / 60.0)
	var secs = int(fmod(sim.elapsed_seconds, 60.0))
	var time_str = "%02d:%02d" % [mins, secs]
	
	var owned_rigs = 0
	for r in sim.map.get("rigs", []):
		if r["owner"] == "player":
			owned_rigs += 1
			
	var player_kills = 0
	var player_vets = 0
	for u in sim.units:
		if u["faction"] == "player":
			player_kills += u["kills"]
			if u["rank"] > 0:
				player_vets += 1
				
	var stat_rows = [
		{ "label": "[TIME] مدة الاشتباك", "val": time_str },
		{ "label": "[SUPPLY] إجمالي الوقود المستخرج", "val": "%d BBL" % sim.player_oil_delivered },
		{ "label": "[HOSTILES] آليات العدو المدمرة", "val": "%d آليات" % player_kills },
		{ "label": "[CONVOYS] قوافل العدو المعترضة", "val": "%d شاحنات" % sim.enemy_trucks_destroyed },
		{ "label": "[OILFIELDS] حقول النفط المحررة", "val": "%d / %d آبار" % [owned_rigs, sim.map.get("rigs", []).size()] },
		{ "label": "[BRIDGES] الجسور المفجرة والمرممة", "val": "%d جسور" % sim.bridges_destroyed_by_player },
		{ "label": "[OFFICERS] الضباط والمخضرمون", "val": "%d رتب نخبة" % player_vets }
	]
	
	for row in stat_rows:
		var hbox = HBoxContainer.new()
		var l_lbl = Label.new()
		l_lbl.text = row["label"]
		l_lbl.add_theme_color_override("font_color", Color("#b5ac94"))
		l_lbl.add_theme_font_size_override("font_size", 10)
		hbox.add_child(l_lbl)
		
		var sp = Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(sp)
		
		var v_lbl = Label.new()
		v_lbl.text = row["val"]
		v_lbl.add_theme_color_override("font_color", Color("#f4f4f5"))
		v_lbl.add_theme_font_size_override("font_size", 10)
		hbox.add_child(v_lbl)
		stats_vbox.add_child(hbox)
