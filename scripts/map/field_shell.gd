extends Control

const MAP_NODES_PATH := "res://data/world/map_nodes.json"
const MAP_SCENE := "res://scenes/map/map.tscn"
const CARAVAN_SPRITE := "res://Assets/sprites/prototype_caravan_icon.png"
const MAP_SIZE := Vector2(1920, 1080)
const VIEW_SIZE := Vector2(1200, 800)
const MAX_WATCH := 30.0
const MIN_WATCH := 6.0
const GOLD := Color(0.92, 0.78, 0.45, 1)
const MUTED := Color(0.75, 0.62, 0.42, 1)
const INK := Color(0.85, 0.78, 0.66, 1)

enum Catalog { CARAVANS, AGENTS, SETTLEMENTS, REPORTS }

@onready var house_label: Label = %HouseLabel
@onready var status_label: Label = %StatusLabel
@onready var day_label: Label = %DayLabel
@onready var catalog_list: VBoxContainer = %CatalogList
@onready var catalog_title: Label = %CatalogTitle
@onready var map_clip: Control = %MapClip
@onready var map_layer: Control = %MapLayer
@onready var markers_layer: Control = %Markers
@onready var context_title: Label = %ContextTitle
@onready var context_meta: Label = %ContextMeta
@onready var context_body: Label = %ContextBody
@onready var context_actions: VBoxContainer = %ContextActions
@onready var market_box: VBoxContainer = %MarketBox

var _nodes: Dictionary = {}
var _category: int = Catalog.CARAVANS
var _selected_kind: String = "caravan"
var _selected_id: String = GameState.PLAYER_CARAVAN_ID
var _dragging := false
var _drag_last := Vector2.ZERO
var _cat_buttons: Dictionary = {}
var _paths: Dictionary = {}
var _max_path_len := 1.0
var _wagon: Sprite2D
var _follow: PathFollow2D
var _hop_tween: Tween


func _ready() -> void:
	_nodes = _load_nodes()
	_ingest_paths()
	_style_dead_desk()
	_wire_catalog_rail()
	_build_markers()
	_make_wagon()
	_refresh_header()
	_set_category(Catalog.CARAVANS)
	_center_on_city(GameState.current_city_id)
	GameState.scrubstone_changed.connect(_on_economy)
	GameState.inventory_changed.connect(_on_economy)
	GameState.location_changed.connect(_on_location_changed)
	map_clip.gui_input.connect(_on_map_gui_input)
	map_clip.resized.connect(_clamp_map)


func _style_dead_desk() -> void:
	for path in ["%HouseDeskButton", "%IntelButton", "%LettersButton"]:
		var btn: Button = get_node_or_null(path)
		if btn:
			btn.disabled = true
			btn.tooltip_text = "Not in this slice"


func _wire_catalog_rail() -> void:
	_cat_buttons = {
		Catalog.CARAVANS: %CatCaravans,
		Catalog.AGENTS: %CatAgents,
		Catalog.SETTLEMENTS: %CatSettlements,
		Catalog.REPORTS: %CatReports,
	}
	for cat in _cat_buttons.keys():
		_cat_buttons[cat].toggle_mode = true
		_cat_buttons[cat].pressed.connect(_set_category.bind(cat))


func _load_nodes() -> Dictionary:
	if not FileAccess.file_exists(MAP_NODES_PATH):
		return {}
	var file := FileAccess.open(MAP_NODES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _refresh_header() -> void:
	house_label.text = GameState.get_house_name()
	status_label.text = "Scrubstone %d    Cargo %d/%d" % [GameState.scrubstone, GameState.cargo_used(), GameState.caravan_capacity]
	day_label.text = "Day %d" % GameState.day


func _on_economy(_arg: Variant = null) -> void:
	_refresh_header()
	if _selected_kind == "caravan":
		_show_caravan()


func _on_location_changed(_city_id: String) -> void:
	_refresh_header()
	_refresh_catalog()
	_paint_markers()
	_refresh_context()
	_center_on_city(GameState.current_city_id)


func _set_category(cat: int) -> void:
	_category = cat
	for key in _cat_buttons.keys():
		_cat_buttons[key].button_pressed = (key == cat)
	match cat:
		Catalog.CARAVANS: catalog_title.text = "Caravans"
		Catalog.AGENTS: catalog_title.text = "Agents"
		Catalog.SETTLEMENTS: catalog_title.text = "Settlements"
		Catalog.REPORTS: catalog_title.text = "Reports"
	_refresh_catalog()
	if cat == Catalog.CARAVANS:
		_select_item("caravan", GameState.PLAYER_CARAVAN_ID)


func _refresh_catalog() -> void:
	for child in catalog_list.get_children():
		child.queue_free()
	var items: Array = _catalog_items()
	if items.is_empty():
		var empty := Label.new()
		empty.text = "None yet"
		empty.add_theme_color_override("font_color", MUTED)
		catalog_list.add_child(empty)
		return
	for item in items:
		var btn := Button.new()
		btn.text = str(item.get("name", item.get("id", "?")))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.toggle_mode = true
		var kind := str(item.get("kind", ""))
		var item_id := str(item.get("id", ""))
		btn.button_pressed = (_selected_kind == kind and _selected_id == item_id)
		btn.pressed.connect(_select_item.bind(kind, item_id))
		catalog_list.add_child(btn)


func _catalog_items() -> Array:
	var items: Array = []
	match _category:
		Catalog.CARAVANS:
			items.append({"kind": "caravan", "id": GameState.PLAYER_CARAVAN_ID, "name": GameState.PLAYER_CARAVAN_NAME})
		Catalog.AGENTS:
			for agent in GameState.agents:
				if typeof(agent) == TYPE_DICTIONARY:
					items.append(agent)
		Catalog.SETTLEMENTS:
			for city_id in GameState.CITIES.keys():
				items.append({"kind": "settlement", "id": city_id, "name": GameState.get_settlement_name(city_id)})
		Catalog.REPORTS:
			for report in GameState.reports:
				if typeof(report) == TYPE_DICTIONARY:
					items.append(report)
	return items


func _select_item(kind: String, item_id: String) -> void:
	_selected_kind = kind
	_selected_id = item_id
	_refresh_catalog()
	_paint_markers()
	_refresh_context()
	if kind == "settlement":
		_center_on_city(item_id)
	elif kind == "caravan":
		_center_on_city(GameState.current_city_id if not GameState.is_on_road() else str(GameState.transit.get("from", GameState.current_city_id)))


func _refresh_context() -> void:
	match _selected_kind:
		"caravan": _show_caravan()
		"settlement": _show_settlement(_selected_id)
		_: _show_empty()


func _clear_actions() -> void:
	for child in context_actions.get_children():
		child.queue_free()
	for child in market_box.get_children():
		child.queue_free()


func _show_caravan() -> void:
	if GameState.is_on_road():
		_show_transit_panel()
		return
	_clear_actions()
	var city_id := GameState.current_city_id
	context_title.text = GameState.PLAYER_CARAVAN_NAME
	context_meta.text = "At %s" % GameState.get_settlement_name(city_id)
	context_body.text = "Cargo %d / %d" % [GameState.cargo_used(), GameState.caravan_capacity]
	if GameState.settlement_has_market(city_id):
		_build_market()
	else:
		var note := Label.new()
		note.text = "No market at this stop."
		note.add_theme_color_override("font_color", MUTED)
		market_box.add_child(note)


func _show_settlement(city_id: String) -> void:
	_clear_actions()
	var city: Dictionary = GameState.CITIES.get(city_id, {})
	context_title.text = GameState.get_settlement_name(city_id)
	var kind := str(city.get("type", "settlement")).capitalize().replace("_", " ")
	var market_line := "Market" if GameState.settlement_has_market(city_id) else "No market"
	context_meta.text = "%s  ·  %s" % [kind, market_line]
	context_body.text = str(city.get("short_desc", city.get("desc", "")))
	if GameState.is_on_road():
		context_body.text += "\nOn the road to %s." % GameState.get_settlement_name(str(GameState.transit.get("to", "")))
		var skip := Button.new()
		skip.text = "Skip travel"
		skip.pressed.connect(_skip_hop)
		context_actions.add_child(skip)
		return
	var here := city_id == GameState.current_city_id
	var travel := Button.new()
	if here:
		travel.text = "You are here"
		travel.disabled = true
	elif GameState.is_adjacent(GameState.current_city_id, city_id):
		travel.text = "Travel here  ·  %d day" % GameState.hop_days(GameState.current_city_id, city_id)
		travel.pressed.connect(_on_travel.bind(city_id))
	else:
		travel.text = "No direct road"
		travel.disabled = true
	context_actions.add_child(travel)


func _show_empty() -> void:
	_clear_actions()
	context_title.text = catalog_title.text
	context_meta.text = ""
	context_body.text = "Nothing in this list yet."


func _on_travel(city_id: String) -> void:
	if not GameState.begin_hop(city_id):
		return
	_play_hop(str(GameState.transit.get("from", "")), city_id)


func _build_market() -> void:
	for good_id in GameState.GOODS.keys():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label := Label.new()
		name_label.text = GameState.get_good_name(good_id)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var price := Label.new()
		price.text = "%ds" % GameState.get_local_price(good_id)
		row.add_child(price)
		var stock := Label.new()
		stock.text = "M%d / Y%d" % [GameState.get_market_stock(good_id), GameState.inventory.get(good_id, 0)]
		row.add_child(stock)
		var buy := Button.new()
		buy.text = "+"
		buy.disabled = not GameState.can_buy(good_id)
		buy.pressed.connect(_on_buy.bind(good_id))
		row.add_child(buy)
		var sell := Button.new()
		sell.text = "-"
		sell.disabled = not GameState.can_sell(good_id)
		sell.pressed.connect(_on_sell.bind(good_id))
		row.add_child(sell)
		market_box.add_child(row)


func _on_buy(good_id: String) -> void:
	GameState.buy(good_id)
	_show_caravan()


func _on_sell(good_id: String) -> void:
	GameState.sell(good_id)
	_show_caravan()


func _build_markers() -> void:
	for child in markers_layer.get_children():
		child.queue_free()
	for city_id in _nodes.keys():
		var pos: Dictionary = _nodes[city_id]
		var btn := Button.new()
		btn.name = city_id
		btn.custom_minimum_size = Vector2(22, 22)
		btn.position = Vector2(float(pos.get("x", 0)), float(pos.get("y", 0))) - Vector2(11, 11)
		btn.focus_mode = Control.FOCUS_NONE
		btn.tooltip_text = GameState.get_settlement_name(city_id)
		btn.text = GameState.get_settlement_name(city_id).substr(0, 1).to_upper()
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_marker_pressed.bind(city_id))
		markers_layer.add_child(btn)
	_paint_markers()


func _on_marker_pressed(city_id: String) -> void:
	_set_category(Catalog.SETTLEMENTS)
	_select_item("settlement", city_id)


func _paint_markers() -> void:
	for btn in markers_layer.get_children():
		if not btn is Button:
			continue
		var city_id := btn.name
		var here := city_id == GameState.current_city_id and not GameState.is_on_road()
		var selected := _selected_kind == "settlement" and _selected_id == city_id
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(11)
		box.set_border_width_all(2)
		if here:
			box.bg_color = Color(0.72, 0.52, 0.18, 0.95)
			box.border_color = Color(0.95, 0.82, 0.40, 1)
			btn.add_theme_color_override("font_color", Color(0.12, 0.08, 0.04, 1))
		elif selected:
			box.bg_color = Color(0.28, 0.20, 0.10, 0.95)
			box.border_color = GOLD
			btn.add_theme_color_override("font_color", GOLD)
		else:
			box.bg_color = Color(0.16, 0.11, 0.07, 0.88)
			box.border_color = Color(0.55, 0.42, 0.24, 1)
			btn.add_theme_color_override("font_color", INK)
		btn.add_theme_stylebox_override("normal", box)
		btn.add_theme_stylebox_override("hover", box)
		btn.add_theme_stylebox_override("pressed", box)


func _on_map_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mouse.pressed
			_drag_last = mouse.position
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		map_layer.position += motion.position - _drag_last
		_drag_last = motion.position
		_clamp_map()


func _center_on_city(city_id: String) -> void:
	var pos: Dictionary = _nodes.get(city_id, {})
	if pos.is_empty():
		_clamp_map()
		return
	var point := Vector2(float(pos.get("x", 0)), float(pos.get("y", 0)))
	var view := map_clip.size if map_clip.size.x >= 8.0 else VIEW_SIZE
	map_layer.position = Vector2(view.x * 0.5, view.y * 0.5) - point
	_clamp_map()


func _clamp_map() -> void:
	var view := map_clip.size if map_clip.size.x >= 8.0 else VIEW_SIZE
	var pos := map_layer.position
	pos.x = clampf(pos.x, view.x - MAP_SIZE.x, 0.0) if MAP_SIZE.x > view.x else (view.x - MAP_SIZE.x) * 0.5
	pos.y = clampf(pos.y, view.y - MAP_SIZE.y, 0.0) if MAP_SIZE.y > view.y else (view.y - MAP_SIZE.y) * 0.5
	map_layer.position = pos


func _ingest_paths() -> void:
	_paths.clear()
	_max_path_len = 1.0
	if not ResourceLoader.exists(MAP_SCENE):
		return
	var packed := load(MAP_SCENE) as PackedScene
	if packed == null:
		return
	var dummy: Node = packed.instantiate()
	map_layer.add_child(dummy)
	for child in dummy.get_children():
		if child is Path2D and child.curve != null:
			var key := _path_key_from_name(child.name)
			if key.is_empty():
				continue
			_max_path_len = maxf(_max_path_len, child.curve.get_baked_length())
			dummy.remove_child(child)
			map_layer.add_child(child)
			_paths[key] = child
	dummy.queue_free()


func _path_key_from_name(route_name: String) -> String:
	var n := route_name
	if n.begins_with("Route_"):
		n = n.substr(6)
	var parts := n.split("_")
	if parts.size() < 2:
		return ""
	return GameState._link_key(_norm_place(parts[0]), _norm_place(parts[1]))


func _norm_place(part: String) -> String:
	var s := part.to_lower()
	if s == "torvern":
		return "torven"
	if s == "sarnsrest" or s == "sarn":
		return "sarns_rest"
	return s


func _make_wagon() -> void:
	_wagon = Sprite2D.new()
	_wagon.texture = load(CARAVAN_SPRITE)
	_wagon.centered = true
	_wagon.visible = false
	_wagon.z_index = 10
	map_layer.add_child(_wagon)


func _path_for(a: String, b: String) -> Path2D:
	return _paths.get(GameState._link_key(a, b), null)


func _watch_seconds(from_id: String, to_id: String) -> float:
	var path := _path_for(from_id, to_id)
	var length := 400.0
	if path and path.curve:
		length = path.curve.get_baked_length()
	else:
		var a: Dictionary = _nodes.get(from_id, {})
		var b: Dictionary = _nodes.get(to_id, {})
		if not a.is_empty() and not b.is_empty():
			length = Vector2(float(a.get("x", 0)), float(a.get("y", 0))).distance_to(Vector2(float(b.get("x", 0)), float(b.get("y", 0))))
	return clampf(MAX_WATCH * (length / _max_path_len), MIN_WATCH, MAX_WATCH)


func _play_hop(from_id: String, to_id: String) -> void:
	if _hop_tween:
		_hop_tween.kill()
	_wagon.visible = true
	var seconds := _watch_seconds(from_id, to_id)
	var path := _path_for(from_id, to_id)
	_center_on_city(from_id)
	if path and path.curve:
		if _follow:
			_follow.queue_free()
		_follow = PathFollow2D.new()
		_follow.loop = false
		_follow.rotates = true
		path.add_child(_follow)
		_wagon.reparent(_follow)
		_wagon.position = Vector2.ZERO
		var start_at_end := _path_starts_near(path, to_id)
		_follow.progress_ratio = 1.0 if start_at_end else 0.0
		_hop_tween = create_tween()
		_hop_tween.tween_property(_follow, "progress_ratio", 0.0 if start_at_end else 1.0, seconds)
		_hop_tween.finished.connect(_complete_hop)
	else:
		var a: Dictionary = _nodes.get(from_id, {})
		var b: Dictionary = _nodes.get(to_id, {})
		_wagon.reparent(map_layer)
		_wagon.position = Vector2(float(a.get("x", 0)), float(a.get("y", 0)))
		_hop_tween = create_tween()
		_hop_tween.tween_property(_wagon, "position", Vector2(float(b.get("x", 0)), float(b.get("y", 0))), seconds)
		_hop_tween.finished.connect(_complete_hop)
	_select_item("caravan", GameState.PLAYER_CARAVAN_ID)
	_show_transit_panel()


func _path_starts_near(path: Path2D, city_id: String) -> bool:
	var pos: Dictionary = _nodes.get(city_id, {})
	if pos.is_empty() or path.curve == null or path.curve.point_count == 0:
		return false
	var city := Vector2(float(pos.get("x", 0)), float(pos.get("y", 0)))
	return path.curve.get_point_position(0).distance_to(city) > path.curve.get_point_position(path.curve.point_count - 1).distance_to(city)


func _show_transit_panel() -> void:
	_clear_actions()
	var dest := str(GameState.transit.get("to", ""))
	context_title.text = GameState.PLAYER_CARAVAN_NAME
	context_meta.text = "On the road"
	context_body.text = "Bound for %s  ·  %d day" % [GameState.get_settlement_name(dest), int(GameState.transit.get("days", 1))]
	var skip := Button.new()
	skip.text = "Skip travel"
	skip.pressed.connect(_skip_hop)
	context_actions.add_child(skip)


func _skip_hop() -> void:
	if _hop_tween:
		_hop_tween.kill()
	_complete_hop()


func _complete_hop() -> void:
	if _follow:
		_wagon.reparent(map_layer)
		_follow.queue_free()
		_follow = null
	_wagon.visible = false
	GameState.finish_hop()
	_set_category(Catalog.CARAVANS)
