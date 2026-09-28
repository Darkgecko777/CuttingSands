class_name ZoneStyle
extends RefCounted

static func paint(pane: Control, _yard: int, _on_road: bool) -> void:
	pane.add_theme_stylebox_override("panel", InstrumentStyle.frame())


static func rack_title(yard: int, on_road: bool) -> String:
	if on_road:
		return "Wagon  ·  on the road"
	if yard == 2:
		return "Wagon  ·  at the stall"
	if yard == 1:
		return "Wagon  ·  house desk"
	return "Wagon"
