extends Control

const MUTED := Color(0.75, 0.62, 0.42, 1)
const WordDeskScript = preload("res://scripts/map/word_desk.gd")

enum Mode { WAGON, MAP, WORD }
enum Yard { NONE, HOUSE, MARKET }

@onready var house_label: Label = %HouseLabel
@onready var place_label: Label = %PlaceLabel
@onready var status_label: Label = %StatusLabel
@onready var day_label: Label = %DayLabel
@onready var weather_pip: Label = %WeatherPip
@onready var gear_button: Button = %GearButton
@onready var wagon_rack: Control = %WagonRack
@onready var rack_grid: GridContainer = %RackGrid
@onready var map_clip: Control = %MapClip
@onready var map_layer: Control = %MapLayer
@onready var markers_layer: Control = %Markers
@onready var context_pane: PanelContainer = %ContextPane
@onready var context_title: Label = %ContextTitle
@onready var context_meta: Label = %ContextMeta
@onready var context_body: Label = %ContextBody
@onready var context_actions: HBoxContainer = %ContextActions
@onready var market_box: VBoxContainer = %MarketBox

var _mode: int = Mode.WAGON
var _yard: int = Yard.NONE
var _selected_kind: String = "caravan"
var _selected_id: String = GameState.PLAYER_CARAVAN_ID
var _inspect_good_id: String = ""
var _cat_buttons: Dictionary = {}
var _map := MapWell.new()
var _desk := MarketDesk.new()
var _word = WordDeskScript.new()


func _ready() -> void:
	_desk.on_changed = _on_draft_changed
	_desk.on_inspect = _inspect_good
	_word.on_pick = _on_word_pick
	_map.setup(self, map_clip, map_layer, markers_layer)
	_wire_shell()
	_refresh_header()
	_set_mode(Mode.WAGON)
	GameState.scrubstone_changed.connect(_on_economy)
	GameState.inventory_changed.connect(_on_economy)
	GameState.location_changed.connect(_on_location_changed)
	_try_pending_travel()


func _wire_shell() -> void:
	_cat_buttons = {Mode.WAGON: %CatWagon, Mode.MAP: %CatMap, Mode.WORD: %CatWord}
	for mode in _cat_buttons.keys():
		_cat_buttons[mode].toggle_mode = true
		_cat_buttons[mode].pressed.connect(_set_mode.bind(mode))
	gear_button.pressed.connect(_on_gear)
	var pause := get_node_or_null("/root/PauseMenu")
	if pause and pause.has_node("%GearButton"):
		pause.get_node("%GearButton").visible = false


func _on_gear() -> void:
	var pause := get_node_or_null("/root/PauseMenu")
	if pause and pause.has_method("open"):
		pause.open()


func _mode_label(mode: int) -> String:
	match mode:
		Mode.WAGON:
			return "Wagon"
		Mode.MAP:
			return "Map"
		_:
			return "Rumours"


func _rack_title() -> Label:
	return wagon_rack.get_node_or_null("RackMargin/RackVBox/RackTitle") as Label


func _refresh_header() -> void:
	house_label.text = GameState.get_house_name()
	if GameState.is_on_road():
		place_label.text = "Bound for %s" % GameState.get_settlement_name(str(GameState.transit.get("to", "")))
	else:
		place_label.text = GameState.get_city_name()
	var net := _desk.sell_gain() - _desk.buy_cost()
	if _desk.staged_count() > 0:
		status_label.text = "Scrubstone %d (%+d)    Cells %d/%d    Mass %d/%d" % [GameState.scrubstone, net, _desk.preview_cells(), GameState.caravan_capacity, _desk.preview_mass(), GameState.caravan_mass_capacity]
	else:
		status_label.text = "Scrubstone %d    Cells %d/%d    Mass %d/%d" % [GameState.scrubstone, GameState.cargo_used(), GameState.caravan_capacity, GameState.cargo_mass(), GameState.caravan_mass_capacity]
	day_label.text = "Day %d" % GameState.day
	if GameState.is_on_road():
		var dest := str(GameState.transit.get("to", ""))
		var origin := str(GameState.transit.get("from", GameState.current_city_id))
		weather_pip.text = RoadPressure.weather_term(origin, dest) if RoadPressure.weather(origin, dest) > 0 else ""
	else:
		weather_pip.text = ""
	var title := _rack_title()
	if title:
		title.text = ZoneStyle.rack_title(_yard, GameState.is_on_road())
	ZoneStyle.paint(context_pane, _yard, GameState.is_on_road())


func _on_economy(_arg: Variant = null) -> void:
	_refresh_header()
	_fill_rack()
	if _mode == Mode.WAGON:
		_show_caravan()


func _on_draft_changed() -> void:
	_refresh_header()
	_fill_rack()
	if _yard == Yard.MARKET:
		_show_market_yard()


func _on_location_changed(_city_id: String) -> void:
	_desk.clear()
	_inspect_good_id = ""
	_yard = Yard.NONE
	_refresh_header()
	_map.paint_markers()
	_refresh_context()
	_fill_rack()
	if _selected_kind == "caravan":
		_map.center_on_selected()
	else:
		_map.center_on_city(GameState.current_city_id)


func _set_mode(mode: int) -> void:
	_mode = mode
	for key in _cat_buttons.keys():
		_cat_buttons[key].button_pressed = (key == mode)
	wagon_rack.visible = (mode == Mode.WAGON)
	map_clip.visible = (mode != Mode.WAGON)
	if mode == Mode.WAGON:
		_select_item("caravan", GameState.PLAYER_CARAVAN_ID)
		_fill_rack()
	elif mode == Mode.WORD:
		_show_word()
	else:
		_refresh_context()
	_map.clamp_map()
	_refresh_header()


func _fill_rack() -> void:
	var in_market := _yard == Yard.MARKET and not GameState.is_on_road()
	var click := _desk.on_wagon_click if in_market else Callable()
	WagonRackView.fill(rack_grid, _desk.wagon_units(), click, _inspect_good)
	WagonDealBar.sync(rack_grid, in_market, _desk)


func _inspect_good(good_id: String) -> void:
	_inspect_good_id = good_id
	if _mode == Mode.WORD or GameState.is_on_road():
		return
	if _yard == Yard.MARKET:
		context_body.text = GoodCopy.context_block(good_id)


func _show_word() -> void:
	_clear_actions()
	_word.render(market_box, context_title, context_meta, context_body)
	var rec := WordBook.slip(_word.selected_id)
	var city_id := str(rec.get("city_id", ""))
	if not city_id.is_empty():
		_map.center_on_city(city_id)
	ZoneStyle.paint(context_pane, Yard.NONE, false)


func _on_word_pick(slip_id: String) -> void:
	_word.selected_id = slip_id
	_show_word()


func _select_item(kind: String, item_id: String) -> void:
	_selected_kind = kind
	_selected_id = item_id
	_map.selected_kind = kind
	_map.selected_id = item_id
	if kind == "caravan":
		GameState.focused_caravan_id = item_id
	_map.paint_markers()
	_refresh_context()
	_map.center_on_selected()


func _refresh_context() -> void:
	if _mode == Mode.WORD:
		_show_word()
		return
	match _selected_kind:
		"caravan":
			_show_caravan()
		"settlement":
			_show_settlement(_selected_id)
		_:
			_show_empty()
	_refresh_header()


func _clear_actions() -> void:
	for child in context_actions.get_children():
		child.queue_free()
	for child in market_box.get_children():
		child.queue_free()


func _show_caravan() -> void:
	if GameState.is_on_road():
		_yard = Yard.NONE
		_show_transit_panel()
		return
	match _yard:
		Yard.MARKET:
			_show_market_yard()
		Yard.HOUSE:
			_show_house_yard()
		_:
			_show_city_yards()


func _show_city_yards() -> void:
	_clear_actions()
	var city_id := GameState.caravan_city(GameState.PLAYER_CARAVAN_ID)
	context_title.text = GameState.get_settlement_name(city_id)
	context_meta.text = "Yard"
	context_body.text = GameState.get_city_desc()
	if not GameState.road_note.is_empty():
		context_body.text = GameState.road_note + "\n\n" + context_body.text
		GameState.road_note = ""
	if WorldBook.settlement_has_house_yard(city_id):
		var house := Button.new()
		house.text = "House %s" % GameState.get_house_name()
		house.pressed.connect(_enter_yard.bind(Yard.HOUSE))
		context_actions.add_child(house)
	if GameState.settlement_has_market(city_id):
		var market := Button.new()
		market.text = "Market"
		market.pressed.connect(_enter_yard.bind(Yard.MARKET))
		context_actions.add_child(market)
	_add_road_buttons(city_id)


func _show_market_yard() -> void:
	_clear_actions()
	var city_id := GameState.caravan_city(GameState.PLAYER_CARAVAN_ID)
	context_title.text = "Market"
	context_meta.text = GameState.get_settlement_name(city_id)
	context_body.text = GoodCopy.context_block(_inspect_good_id, city_id) if not _inspect_good_id.is_empty() else ""
	var back := Button.new()
	back.text = "Leave market"
	back.pressed.connect(_enter_yard.bind(Yard.NONE))
	context_actions.add_child(back)
	if GameState.settlement_has_market(city_id):
		_desk.render(market_box)
	else:
		_desk.empty_note(market_box, "No market at this stop.")


func _show_house_yard() -> void:
	_clear_actions()
	var city_id := GameState.caravan_city(GameState.PLAYER_CARAVAN_ID)
	if not WorldBook.settlement_has_house_yard(city_id):
		_yard = Yard.NONE
		_show_city_yards()
		return
	context_title.text = "House %s" % GameState.get_house_name()
	context_meta.text = GameState.get_settlement_name(city_id)
	context_body.text = "Standing and letters wait. This desk is the mark, not the town."
	var back := Button.new()
	back.text = "Leave house"
	back.pressed.connect(_enter_yard.bind(Yard.NONE))
	context_actions.add_child(back)


func _add_road_buttons(city_id: String) -> void:
	for neighbor in GameState.neighbors_of(city_id):
		var dest := str(neighbor)
		var road := Button.new()
		road.text = "Road to %s  ·  %d day  ·  %s" % [GameState.get_settlement_name(dest), GameState.hop_days(city_id, dest), RoadPressure.route_words(city_id, dest)]
		road.pressed.connect(_on_travel.bind(dest))
		context_actions.add_child(road)


func _enter_yard(yard: int) -> void:
	_yard = yard
	_inspect_good_id = ""
	if yard != Yard.MARKET:
		_desk.clear()
	_fill_rack()
	_refresh_header()
	if yard == Yard.MARKET:
		_set_mode(Mode.WAGON)
	else:
		_refresh_context()


func _show_settlement(city_id: String) -> void:
	_clear_actions()
	var city: Dictionary = GameState.CITIES.get(city_id, {})
	context_title.text = GameState.get_settlement_name(city_id)
	context_meta.text = "%s  ·  %s" % [str(city.get("type", "settlement")).capitalize().replace("_", " "), "Market" if GameState.settlement_has_market(city_id) else "No market"]
	context_body.text = str(city.get("short_desc", city.get("desc", "")))
	if GameState.is_on_road():
		context_body.text += "\nOn the road to %s." % GameState.get_settlement_name(str(GameState.transit.get("to", "")))
		var skip := Button.new()
		skip.text = "Skip travel"
		skip.pressed.connect(_map.skip_hop)
		context_actions.add_child(skip)
		return
	if city_id == GameState.current_city_id:
		_show_city_yards()
		return
	var travel := Button.new()
	if GameState.is_adjacent(GameState.current_city_id, city_id):
		travel.text = "Travel here  ·  %d day  ·  %s" % [GameState.hop_days(GameState.current_city_id, city_id), RoadPressure.route_words(GameState.current_city_id, city_id)]
		travel.pressed.connect(_on_travel.bind(city_id))
	else:
		travel.text = "No direct road"
		travel.disabled = true
	context_actions.add_child(travel)


func _show_empty() -> void:
	_clear_actions()
	context_title.text = _mode_label(_mode)
	context_meta.text = ""
	context_body.text = ""


func _on_travel(city_id: String) -> void:
	if GameState.begin_hop(city_id):
		_desk.clear()
		_yard = Yard.NONE
		_inspect_good_id = ""
		_set_mode(Mode.MAP)
		_map.play_hop(str(GameState.transit.get("from", "")), city_id)


func _show_transit_panel() -> void:
	_clear_actions()
	var dest := str(GameState.transit.get("to", ""))
	context_title.text = GameState.PLAYER_CARAVAN_NAME
	context_meta.text = "On the road"
	var origin := str(GameState.transit.get("from", GameState.current_city_id))
	context_body.text = "Bound for %s  ·  %d day  ·  %s" % [GameState.get_settlement_name(dest), int(GameState.transit.get("days", 1)), RoadPressure.route_words(origin, dest)]
	var skip := Button.new()
	skip.text = "Skip travel"
	skip.pressed.connect(_map.skip_hop)
	context_actions.add_child(skip)


func _complete_hop() -> void:
	_map.hide_wagon()
	GameState.finish_hop()
	_yard = Yard.NONE
	_set_mode(Mode.WAGON)
	_refresh_header()
	_map.paint_markers()


func _try_pending_travel() -> void:
	var dest := str(GameState.pending_travel_to)
	if dest.is_empty():
		if GameState.is_on_road():
			_show_transit_panel()
		return
	GameState.pending_travel_to = ""
	if GameState.begin_hop(dest):
		_map.play_hop(str(GameState.transit.get("from", "")), dest)
