class_name InstrumentStyle
extends RefCounted
## Wordless double-rule parchment plates. The engine sets every word.

const BONE := Color(0.93, 0.86, 0.72, 1)
const AMBER := Color(1.0, 0.82, 0.42, 1)
const MUTED := Color(0.62, 0.52, 0.38, 1)
const GROUND := Color(0.07, 0.045, 0.03, 1)
const BAR := Color(0.09, 0.055, 0.035, 1)
const BRASS := Color(0.62, 0.46, 0.24, 1)

const PLATE_MARGIN := 12
const FRAME_MARGIN := 16
const CELL_MARGIN := 12

const _QUIET := preload("res://Assets/UI/instrument/plate_quiet.png")
const _HOT := preload("res://Assets/UI/instrument/plate_hot.png")
const _PRESSED := preload("res://Assets/UI/instrument/plate_pressed.png")
const _FRAME := preload("res://Assets/UI/instrument/frame_panel.png")
const _CELL := preload("res://Assets/UI/instrument/cell_empty.png")
const _CREST := preload("res://Assets/UI/instrument/crest.png")
const _GEAR := preload("res://Assets/UI/instrument/icon_gear.png")
const _BOLD := preload("res://Assets/fonts/BonaNovaSC-Bold.ttf")
const _REG := preload("res://Assets/fonts/BonaNovaSC-Regular.ttf")


static func crest() -> Texture2D:
	return _CREST


static func gear() -> Texture2D:
	return _GEAR


static func bold() -> Font:
	return _BOLD


static func regular() -> Font:
	return _REG


static func face(label: Label, title: bool, size: int) -> void:
	label.add_theme_font_override("font", _BOLD if title else _REG)
	label.add_theme_font_size_override("font_size", size)
	if title:
		label.add_theme_color_override("font_color", AMBER)


static func action(btn: Button) -> void:
	_plate(btn, false)
	if btn.custom_minimum_size.y < 56.0:
		btn.custom_minimum_size.y = 56.0


static func toggle(btn: Button) -> void:
	_plate(btn, true)


static func place(btn: Button) -> void:
	var plate := _tex(_QUIET, PLATE_MARGIN, 10)
	btn.add_theme_stylebox_override("normal", plate)
	btn.add_theme_stylebox_override("hover", _tex(_HOT, PLATE_MARGIN, 10))
	btn.add_theme_stylebox_override("pressed", plate)
	btn.add_theme_stylebox_override("disabled", plate)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_type(btn, true)


static func row(btn: Button, hot: bool) -> void:
	var normal := _flat(hot)
	var hover := _flat(true)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("disabled", _flat(false))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_type(btn, hot)


static func cell(btn: Button) -> void:
	var plate := _tex(_CELL, CELL_MARGIN, 2)
	btn.add_theme_stylebox_override("normal", plate)
	btn.add_theme_stylebox_override("hover", plate)
	btn.add_theme_stylebox_override("pressed", plate)
	btn.add_theme_stylebox_override("disabled", plate)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_font_override("font", _REG)
	btn.add_theme_font_size_override("font_size", 11)


static func frame() -> StyleBoxTexture:
	return _tex(_FRAME, FRAME_MARGIN, 18)


static func bar() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = BAR
	box.border_color = BRASS
	box.set_border_width_all(1)
	box.content_margin_left = 8
	box.content_margin_top = 6
	box.content_margin_right = 8
	box.content_margin_bottom = 6
	return box


static func _plate(btn: Button, selected_is_hot: bool) -> void:
	var quiet := _tex(_QUIET, PLATE_MARGIN, 8)
	var hot := _tex(_HOT, PLATE_MARGIN, 8)
	var pressed := _tex(_PRESSED, PLATE_MARGIN, 8)
	btn.add_theme_stylebox_override("normal", quiet)
	btn.add_theme_stylebox_override("hover", hot)
	btn.add_theme_stylebox_override("pressed", hot if selected_is_hot else pressed)
	btn.add_theme_stylebox_override("hover_pressed", hot)
	btn.add_theme_stylebox_override("disabled", quiet)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_type(btn, false)


static func _type(btn: Button, hot: bool) -> void:
	btn.add_theme_font_override("font", _BOLD)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", AMBER if hot else BONE)
	btn.add_theme_color_override("font_hover_color", AMBER)
	btn.add_theme_color_override("font_pressed_color", AMBER)
	btn.add_theme_color_override("font_disabled_color", MUTED)


static func _tex(texture: Texture2D, margin: int, pad: int) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = margin
	box.texture_margin_top = margin
	box.texture_margin_right = margin
	box.texture_margin_bottom = margin
	box.content_margin_left = pad
	box.content_margin_top = pad
	box.content_margin_right = pad
	box.content_margin_bottom = pad
	return box


static func _flat(hot: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.22, 0.14, 0.08, 1) if hot else Color(0.11, 0.07, 0.045, 0.94)
	box.border_color = Color(0.85, 0.64, 0.32, 1) if hot else BRASS
	box.set_border_width_all(1)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box
