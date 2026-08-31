extends Control

const MUTED := Color(0.75, 0.62, 0.42, 1)

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
@onready var context_title: Label = %ContextTitle
@onready var context_meta: Label = %ContextMeta
@onready var context_body: Label = %ContextBody
@onready var context_actions: VBoxContainer = %ContextActions
@onready var market_box: VBoxContainer = %MarketBox

var _mode: int = Mode.WAGON
var _yard: int = Yard.NONE
var _selected_kind: String = "caravan"
var _selected_id: String = GameState.PLAYER_CARAVAN_ID
var _cat_buttons: Dictionary = {}
var _map := MapWell.new()


func _ready() -> void:
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
			return "Word"


func _refresh_header() -> void:
	house_label.text = GameState.get_house_name()
	if GameState.is_on_road():
		place_label.text = "Bound for %s" % GameState.get_settlement_name(str(GameState.transit.get("to", "")))
	else:
		place_label.text = GameState.get_city_name()
	status_label.text = "Scrubstone %d    Cargo %d/%d" % [GameState.scrubstone, GameState.cargo_used(), GameState.caravan_capacity]
	day_label.text = "Day %d" % GameState.day
	weather_pip.text = ""


func _on_economy(_arg: Variant = null) -> void:
	_refresh_header()
	_fill_rack()
	if _mode == Mode.WAGON:
		_show_caravan()


func _on_location_changed(_city_id: String) -> void:
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


func _fill_rack() -> void:
	WagonRackView.fill(rack_grid)


func _show_word() -> void:
	_clear_actions()
	context_title.text = "Word"
	context_meta.text = "Nothing on the desk"
	context_body.text = "Arrival slips and rumours will land here. A report will pull the well to its subject."
	MarketDesk.empty_note(market_box, "No word yet")


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
	context_meta.text = "Yards"
	context_body.text = "The house compound and the market are rooms of this stop. Roads leave the gate."
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
	context_body.text = "Temporary stall list. Draft buy/sell comes with icons."
	var back := Button.new()
	back.text = "Leave market"
	back.pressed.connect(_enter_yard.bind(Yard.NONE))
	context_actions.add_child(back)
	if GameState.settlement_has_market(city_id):
		MarketDesk.build_stall(market_box, _on_buy, _on_sell)
	else:
		MarketDesk.empty_note(market_box, "No market at this stop.")


func _show_house_yard() -> void:
	_clear_actions()
	context_title.text = "House %s" % GameState.get_house_name()
	context_meta.text = GameState.get_settlement_name(GameState.caravan_city(GameState.PLAYER_CARAVAN_ID))
	context_body.text = "The marked compound. Standing, letters, and house credit will live here."
	var back := Button.new()
	back.text = "Leave house"
	back.pressed.connect(_enter_yard.bind(Yard.NONE))
	context_actions.add_child(back)
	MarketDesk.empty_note(market_box, "House desk later.")


func _add_road_buttons(city_id: String) -> void:
	for neighbor in GameState.neighbors_of(city_id):
		var dest := str(neighbor)
		var road := Button.new()
		road.text = "Road to %s  ·  %d day" % [GameState.get_settlement_name(dest), GameState.hop_days(city_id, dest)]
		road.pressed.connect(_on_travel.bind(dest))
		context_actions.add_child(road)


func _enter_yard(yard: int) -> void:
	_yard = yard
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
		travel.text = "Travel here  ·  %d day" % GameState.hop_days(GameState.current_city_id, city_id)
		travel.pressed.connect(_on_travel.bind(city_id))
	else:
		travel.text = "No direct road"
		travel.disabled = true
	context_actions.add_child(travel)


func _show_empty() -> void:
	_clear_actions()
	context_title.text = _mode_label(_mode)
	context_meta.text = ""
	context_body.text = "Nothing selected."


func _on_travel(city_id: String) -> void:
	if GameState.begin_hop(city_id):
		_yard = Yard.NONE
		_set_mode(Mode.MAP)
		_map.play_hop(str(GameState.transit.get("from", "")), city_id)


func _on_buy(good_id: String) -> void:
	GameState.buy(good_id)
	_show_caravan()


func _on_sell(good_id: String) -> void:
	GameState.sell(good_id)
	_show_caravan()


func _show_transit_panel() -> void:
	_clear_actions()
	var dest := str(GameState.transit.get("to", ""))
	context_title.text = GameState.PLAYER_CARAVAN_NAME
	context_meta.text = "On the road"
	context_body.text = "Bound for %s  ·  %d day" % [GameState.get_settlement_name(dest), int(GameState.transit.get("days", 1))]
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
