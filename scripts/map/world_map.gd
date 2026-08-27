extends Control

## Full-screen painted map with settlement markers.
## Travel is instant for now; risk and time come later.

const MAP_NODES_PATH := "res://data/world/map_nodes.json"
const MARKER_SIZE := Vector2(28, 28)

@onready var markers_layer: Control = %Markers
@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var info_name: Label = %InfoName
@onready var info_meta: Label = %InfoMeta
@onready var info_desc: Label = %InfoDesc
@onready var travel_button: Button = %TravelButton
@onready var info_panel: PanelContainer = %InfoPanel

var _nodes: Dictionary = {}
var _selected_id: String = ""
var _markers: Dictionary = {}


func _ready() -> void:
	_nodes = _load_nodes()
	_build_markers()
	back_button.pressed.connect(_on_back_pressed)
	travel_button.pressed.connect(_on_travel_pressed)
	_select_settlement(GameState.current_city_id)
	GameState.location_changed.connect(_on_location_changed)


func _load_nodes() -> Dictionary:
	if not FileAccess.file_exists(MAP_NODES_PATH):
		return {}
	var file := FileAccess.open(MAP_NODES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _build_markers() -> void:
	for child in markers_layer.get_children():
		child.queue_free()
	_markers.clear()

	for city_id in _nodes.keys():
		var pos: Dictionary = _nodes[city_id]
		var btn := Button.new()
		btn.name = city_id
		btn.custom_minimum_size = MARKER_SIZE
		btn.position = Vector2(float(pos.get("x", 0)), float(pos.get("y", 0))) - MARKER_SIZE * 0.5
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.tooltip_text = GameState.get_settlement_name(city_id)
		btn.text = _mark_letter(city_id)
		btn.add_theme_font_size_override("font_size", 12)
		_apply_marker_style(btn, city_id == GameState.current_city_id)
		btn.pressed.connect(_on_marker_pressed.bind(city_id))
		markers_layer.add_child(btn)
		_markers[city_id] = btn


func _mark_letter(city_id: String) -> String:
	var city_name := GameState.get_settlement_name(city_id)
	if city_name.is_empty():
		return "?"
	return city_name.substr(0, 1).to_upper()


func _apply_marker_style(btn: Button, is_here: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.set_corner_radius_all(14)
	normal.set_border_width_all(2)
	if is_here:
		normal.bg_color = Color(0.72, 0.52, 0.18, 0.95)
		normal.border_color = Color(0.95, 0.82, 0.40, 1)
		btn.add_theme_color_override("font_color", Color(0.12, 0.08, 0.04, 1))
	else:
		normal.bg_color = Color(0.16, 0.11, 0.07, 0.88)
		normal.border_color = Color(0.55, 0.42, 0.24, 1)
		btn.add_theme_color_override("font_color", Color(0.92, 0.82, 0.62, 1))
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.28, 0.20, 0.10, 0.95)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)


func _on_marker_pressed(city_id: String) -> void:
	_select_settlement(city_id)


func _select_settlement(city_id: String) -> void:
	_selected_id = city_id
	for id in _markers.keys():
		var btn: Button = _markers[id]
		btn.button_pressed = (id == city_id)
		_apply_marker_style(btn, id == GameState.current_city_id)

	var city: Dictionary = GameState.CITIES.get(city_id, {})
	var city_name := GameState.get_settlement_name(city_id)
	info_name.text = city_name
	var kind := str(city.get("type", "settlement")).capitalize().replace("_", " ")
	var market_line := "Market" if GameState.settlement_has_market(city_id) else "No market"
	info_meta.text = "%s  ·  %s" % [kind, market_line]
	info_desc.text = str(city.get("short_desc", ""))
	info_panel.visible = not city_name.is_empty()

	var here := city_id == GameState.current_city_id
	travel_button.visible = not city_id.is_empty()
	travel_button.disabled = here
	travel_button.text = "You are here" if here else "Travel here"

	title_label.text = "Map  ·  %s" % GameState.get_city_name()


func _on_travel_pressed() -> void:
	if _selected_id.is_empty():
		return
	if GameState.travel_to(_selected_id):
		_select_settlement(_selected_id)


func _on_location_changed(_city_id: String) -> void:
	_select_settlement(GameState.current_city_id)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/city_hub.tscn")
