class_name DealStyle
extends RefCounted

const GOLD := Color(0.92, 0.78, 0.45, 1)
const INK := Color(0.12, 0.08, 0.05, 1)


static func button(text: String, disabled: bool, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.disabled = disabled
	btn.custom_minimum_size = Vector2(88, 32)
	btn.add_theme_color_override("font_color", GOLD)
	btn.add_theme_color_override("font_hover_color", Color(1, 0.92, 0.7, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.45, 0.32, 1))
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.16, 0.1, 0.06, 0.92)
	box.border_color = GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(2)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", box)
	var hover := box.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.24, 0.16, 0.08, 0.95)
	btn.add_theme_stylebox_override("hover", hover)
	var off := box.duplicate() as StyleBoxFlat
	off.border_color = Color(0.45, 0.35, 0.22, 1)
	off.bg_color = Color(0.1, 0.07, 0.04, 0.8)
	btn.add_theme_stylebox_override("disabled", off)
	btn.pressed.connect(cb)
	return btn
