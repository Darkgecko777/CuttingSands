extends Control
## Neon Sepia study. Run this scene with F6. It is not part of the play shell.

const AMBER := Color(1.0, 0.82, 0.42, 1.0)
const BONE := Color(0.93, 0.86, 0.72, 1.0)

@onready var _tabs: Array[Button] = [%CargoTab, %MapTab, %RumoursTab]
@onready var _yards: Array[Button] = [%HouseYard, %MarketYard, %OutyardYard]
@onready var _yard_line: Label = %YardLine
@onready var _lit: StyleBox = %CargoTab.get_theme_stylebox("normal").duplicate()
@onready var _dim: StyleBox = %MapTab.get_theme_stylebox("normal").duplicate()


func _ready() -> void:
	for button in _tabs:
		button.pressed.connect(_pick_tab.bind(button))
	%HouseYard.pressed.connect(_pick_yard.bind(%HouseYard, "House yard"))
	%MarketYard.pressed.connect(_pick_yard.bind(%MarketYard, "Market"))
	%OutyardYard.pressed.connect(_pick_yard.bind(%OutyardYard, "Outyard"))
	_pick_tab(%CargoTab)
	_pick_yard(%MarketYard, "Market")


func _pick_tab(selected: Button) -> void:
	_mark(selected, _tabs)


func _pick_yard(selected: Button, line: String) -> void:
	_mark(selected, _yards)
	_yard_line.text = line


func _mark(selected: Button, group: Array[Button]) -> void:
	for button in group:
		var on := button == selected
		button.add_theme_stylebox_override("normal", _lit if on else _dim)
		button.add_theme_color_override("font_color", AMBER if on else BONE)
