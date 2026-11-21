class_name HUDModalCommon
extends RefCounted

static func create_military_panel_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.07, 0.09, 0.06, 0.98)
	s.border_color = Color("#48533b")
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 3
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	return s

static func create_menu_button(text: String, col: Color, min_h: float = 32.0) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, min_h)
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", col)
	return btn
