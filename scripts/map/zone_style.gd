class_name ZoneStyle
extends RefCounted

const YARD := Color(0.12, 0.08, 0.05, 1)
const MARKET := Color(0.18, 0.1, 0.05, 1)
const HOUSE := Color(0.08, 0.09, 0.11, 1)
const ROAD := Color(0.07, 0.06, 0.04, 1)
const GOLD := Color(0.92, 0.78, 0.45, 1)
const COOL := Color(0.62, 0.7, 0.78, 1)


static func paint(pane: Control, yard: int, on_road: bool) -> void:
	var fill := YARD
	var edge := Color(0.35, 0.26, 0.16, 1)
	if on_road:
		fill = ROAD
	elif yard == 2:
		fill = MARKET
		edge = GOLD
	elif yard == 1:
		fill = HOUSE
		edge = COOL
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(2)
	box.set_corner_radius_all(2)
	pane.add_theme_stylebox_override("panel", box)


static func rack_title(yard: int, on_road: bool) -> String:
	if on_road:
		return "Wagon  ·  on the road"
	if yard == 2:
		return "Wagon  ·  at the stall"
	if yard == 1:
		return "Wagon  ·  house desk"
	return "Wagon"
