extends Control

const MUTED := Color(0.75, 0.62, 0.42, 1)
const WordDeskScript = preload("res://scripts/map/word_desk.gd")

enum Mode { NONE, CARGO, MAP, WORD }
enum Yard { NONE, HOUSE, MARKET, OUTYARD }

@onready var house_label: Label = %HouseLabel
@onready var place_label: Label = %PlaceLabel
@onready var status_label: Label = %StatusLabel
@onready var day_label: Label = %DayLabel
@onready var weather_pip: Label = %WeatherPip
@onready var gear_button: Button = %GearButton
@onready var rack_grid: GridContainer = %RackGrid
@onready var map_clip: Control = %MapClip
@onready var map_layer: Control = %MapLayer
@onready var markers_layer: Control = %Markers
@onready var split_host: HBoxContainer = %SplitHost
@onready var left_pane: PanelContainer = %LeftPane
@onready var right_pane: PanelContainer = %RightPane
@onready var left_title: Label = %LeftTitle
@onready var left_box: VBoxContainer = %LeftBox
@onready var context_title: Label = %ContextTitle
@onready var context_meta: Label = %ContextMeta
@onready var context_body: Label = %ContextBody
@onready var market_box: VBoxContainer = %MarketBox
@onready var place_banner: Button = %PlaceBanner
@onready var house_btn: Button = %HouseBtn
@onready var market_btn: Button = %MarketBtn
@onready var outyard_btn: Button = %OutyardBtn
@onready var banner_caption: Label = %BannerCaption
@onready var context_actions: HBoxContainer = %ContextActions

var _mode: int = Mode.NONE
var _yard: int = Yard.MARKET
var _selected_kind: String = "caravan"
var _selected_id: String = GameState.PLAYER_CARAVAN_ID
var _inspect_good_id: String = ""
var _outyard_dest: String = ""
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
	_set_mode(Mode.NONE)
	GameState.scrubstone_changed.connect(_on_economy)
	GameState.inventory_changed.connect(_on_economy)
	GameState.location_changed.connect(_on_location_changed)
	_try_pending_travel()


func _wire_shell() -> void:
	_cat_buttons = {Mode.CARGO: %CatWagon, Mode.MAP: %CatMap, Mode.WORD: %CatWord}
	for mode in _cat_buttons.keys():
		_cat_buttons[mode].toggle_mode = true
		_cat_buttons[mode].pressed.connect(_toggle_mode.bind(mode))
	gear_button.pressed.connect(_on_gear)
	place_banner.pressed.connect(_enter_yard.bind(Yard.NONE))
	house_btn.pressed.connect(_enter_yard.bind(Yard.HOUSE))
	market_btn.pressed.connect(_enter_yard.bind(Yard.MARKET))
	outyard_btn.pressed.connect(_enter_yard.bind(Yard.OUTYARD))
	var pause := get_node_or_null("/root/PauseMenu")
	if pause and pause.has_node("%GearButton"):
		pause.get_node("%GearButton").visible = false


func _on_gear() -> void:
	var pause := get_node_or_null("/root/PauseMenu")
	if pause and pause.has_method("open"):
		pause.open()


func _mode_label(mode: int) -> String:
	match mode:
		Mode.CARGO:
			return "Cargo"
		Mode.MAP:
			return "Map"
		Mode.WORD:
			return "Rumours"
		_:
			return ""


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
	_refresh_place_bar()
	ZoneStyle.paint(left_pane, _yard, GameState.is_on_road())
	ZoneStyle.paint(right_pane, _yard, GameState.is_on_road())


func _on_economy(_arg: Variant = null) -> void:
	_refresh_header()
	_fill_rack()
	if _mode == Mode.NONE or _mode == Mode.CARGO:
		_show_caravan()


func _on_draft_changed() -> void:
	_refresh_header()
	_fill_rack()
	if _yard == Yard.MARKET and _mode == Mode.NONE:
		_show_market_yard()


func _on_location_changed(_city_id: String) -> void:
	_desk.clear()
	_inspect_good_id = ""
	_outyard_dest = ""
	_yard = Yard.MARKET
	_mode = Mode.NONE
	_refresh_header()
	_map.paint_markers()
	_refresh_context()
	_fill_rack()
	_map.center_on_city(GameState.current_city_id)


func _toggle_mode(mode: int) -> void:
	if _mode == mode:
		_set_mode(Mode.NONE)
	else:
		_set_mode(mode)


func _apply_well() -> void:
	var on_road := GameState.is_on_road()
	var map_only := on_road or _mode == Mode.MAP
	split_host.visible = not map_only
	map_clip.visible = map_only
	if _mode == Mode.CARGO:
		left_pane.size_flags_stretch_ratio = 1.5
		right_pane.size_flags_stretch_ratio = 1.0
	else:
		left_pane.size_flags_stretch_ratio = 1.0
		right_pane.size_flags_stretch_ratio = 1.0
	if map_only and not on_road:
		_map.show_atlas()


func _set_mode(mode: int) -> void:
	_mode = mode
	for key in _cat_buttons.keys():
		_cat_buttons[key].set_pressed_no_signal(key == mode)
	_apply_well()
	if mode == Mode.CARGO:
		_select_item("caravan", GameState.PLAYER_CARAVAN_ID)
		_fill_rack()
		_show_cargo_tab()
	elif mode == Mode.WORD:
		_show_word()
	elif mode == Mode.MAP:
		_refresh_header()
	else:
		_refresh_context()
	_map.clamp_map()
	_refresh_header()


func _fill_rack() -> void:
	var in_market := _yard == Yard.MARKET and not GameState.is_on_road()
	var click := Callable()
	if in_market:
		click = _desk.on_wagon_click
	WagonRackView.fill(rack_grid, _desk.wagon_units(), click, _inspect_good)
	WagonDealBar.sync(rack_grid, in_market and _mode != Mode.WORD, _desk)


func _inspect_good(good_id: String) -> void:
	_inspect_good_id = good_id
	if _mode == Mode.WORD or GameState.is_on_road():
		return
	context_body.text = GoodCopy.context_block(good_id)
	if _mode == Mode.CARGO:
		context_title.text = WorldBook.good_name(good_id)
		context_meta.text = "Selected"


func _clear_lists() -> void:
	for child in left_box.get_children():
		child.queue_free()
	for child in market_box.get_children():
		child.queue_free()
	for child in context_actions.get_children():
		child.queue_free()


func _show_word() -> void:
	_clear_lists()
	rack_grid.visible = false
	left_title.text = "Slips"
	_word.render(left_box, context_title, context_meta, context_body)
	var rec := WordBook.slip(_word.selected_id)
	var city_id := str(rec.get("city_id", ""))
	if not city_id.is_empty():
		_map.center_on_city(city_id)


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
	if _mode != Mode.MAP and _mode != Mode.WORD and _mode != Mode.CARGO:
		_refresh_context()
	_map.center_on_selected()


func _refresh_context() -> void:
	if _mode == Mode.WORD:
		_show_word()
		return
	if _mode == Mode.CARGO:
		_show_cargo_tab()
		return
	if _mode == Mode.MAP:
		return
	match _selected_kind:
		"caravan":
			_show_caravan()
		"settlement":
			_show_settlement(_selected_id)
		_:
			_show_empty()
	_refresh_header()


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
		Yard.OUTYARD:
			_show_outyard()
		_:
			_show_city_yards()


func _refresh_place_bar() -> void:
	var on_road := GameState.is_on_road()
	var city_id := GameState.caravan_city(GameState.PLAYER_CARAVAN_ID)
	if on_road:
		place_banner.text = "Bound for %s" % GameState.get_settlement_name(str(GameState.transit.get("to", "")))
		banner_caption.text = "On the road  ·  %s" % RoadPressure.route_words(str(GameState.transit.get("from", "")), str(GameState.transit.get("to", "")))
	else:
		place_banner.text = GameState.get_settlement_name(city_id)
		match _yard:
			Yard.MARKET:
				banner_caption.text = "Market  ·  %s" % GameState.get_settlement_name(city_id)
			Yard.HOUSE:
				banner_caption.text = "House %s" % GameState.get_house_name()
			Yard.OUTYARD:
				banner_caption.text = "Outyard  ·  roads from %s" % GameState.get_settlement_name(city_id)
			_:
				banner_caption.text = GameState.get_settlement_name(city_id)
	place_banner.disabled = on_road
	house_btn.disabled = on_road or not WorldBook.settlement_has_house_yard(city_id)
	market_btn.disabled = on_road or not GameState.settlement_has_market(city_id)
	outyard_btn.disabled = on_road
	house_btn.set_pressed_no_signal(not on_road and _yard == Yard.HOUSE)
	market_btn.set_pressed_no_signal(not on_road and _yard == Yard.MARKET)
	outyard_btn.set_pressed_no_signal(not on_road and _yard == Yard.OUTYARD)


func _show_city_yards() -> void:
	_clear_lists()
	rack_grid.visible = false
	left_title.text = GameState.get_city_name()
	var note := Label.new()
	note.text = "House, Market, or Outyard."
	note.add_theme_color_override("font_color", MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_box.add_child(note)
	var city_id := GameState.caravan_city(GameState.PLAYER_CARAVAN_ID)
	context_title.text = GameState.get_settlement_name(city_id)
	context_meta.text = "Yard"
	context_body.text = GameState.get_city_desc()
	if not GameState.road_note.is_empty():
		context_body.text = GameState.road_note + "\n\n" + context_body.text
		GameState.road_note = ""


func _show_market_yard() -> void:
	_clear_lists()
	rack_grid.visible = true
	left_title.text = "Cargo"
	var city_id := GameState.caravan_city(GameState.PLAYER_CARAVAN_ID)
	context_title.text = "Market"
	context_meta.text = GameState.get_settlement_name(city_id)
	if _inspect_good_id.is_empty():
		context_body.text = "Buy and sell against the hold."
	else:
		context_body.text = GoodCopy.context_block(_inspect_good_id, city_id)
	if GameState.settlement_has_market(city_id):
		_desk.render(market_box)
	else:
		_desk.empty_note(market_box, "No market at this stop.")
	_fill_rack()


func _show_house_yard() -> void:
	_clear_lists()
	rack_grid.visible = false
	var city_id := GameState.caravan_city(GameState.PLAYER_CARAVAN_ID)
	if not WorldBook.settlement_has_house_yard(city_id):
		_yard = Yard.NONE
		_show_city_yards()
		return
	left_title.text = "Desk"
	var mark := Label.new()
	mark.text = "House mark and letters wait here."
	mark.add_theme_color_override("font_color", MUTED)
	mark.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_box.add_child(mark)
	context_title.text = "House %s" % GameState.get_house_name()
	context_meta.text = GameState.get_settlement_name(city_id)
	context_body.text = "Standing and letters wait. This desk is the mark, not the town."


func _show_cargo_tab() -> void:
	_clear_lists()
	rack_grid.visible = true
	left_title.text = "Hold"
	context_title.text = "Item"
	if _inspect_good_id.is_empty():
		context_meta.text = "Select a good"
		context_body.text = "The hold is the string's mass and cells. Pick a unit."
	else:
		context_meta.text = WorldBook.good_name(_inspect_good_id)
		context_body.text = GoodCopy.context_block(_inspect_good_id)
	_fill_rack()


func _show_outyard() -> void:
	_clear_lists()
	rack_grid.visible = false
	var city_id := GameState.caravan_city(GameState.PLAYER_CARAVAN_ID)
	left_title.text = "Roads"
	context_title.text = "Outyard"
	context_meta.text = GameState.get_settlement_name(city_id)
	if not GameState.road_note.is_empty():
		context_body.text = GameState.road_note
		GameState.road_note = ""
	else:
		context_body.text = "Weather and heat are what this yard can see, not a forecast."
	var neighbors: Array = GameState.neighbors_of(city_id)
	if neighbors.is_empty():
		var none := Label.new()
		none.text = "No marked road from this stop."
		none.add_theme_color_override("font_color", MUTED)
		left_box.add_child(none)
	else:
		for neighbor in neighbors:
			var dest := str(neighbor)
			var road := Button.new()
			road.text = "%s  ·  %d day  ·  %s" % [GameState.get_settlement_name(dest), GameState.hop_days(city_id, dest), RoadPressure.route_words(city_id, dest)]
			road.alignment = HORIZONTAL_ALIGNMENT_LEFT
			road.custom_minimum_size = Vector2(0, 56)
			road.toggle_mode = true
			road.button_pressed = dest == _outyard_dest
			road.pressed.connect(_pick_hop.bind(dest))
			left_box.add_child(road)
	_paint_hop_detail(city_id)


func _pick_hop(dest: String) -> void:
	_outyard_dest = dest
	_show_outyard()


func _paint_hop_detail(city_id: String) -> void:
	if _outyard_dest.is_empty():
		return
	context_title.text = GameState.get_settlement_name(_outyard_dest)
	context_meta.text = "%d day  ·  %s" % [GameState.hop_days(city_id, _outyard_dest), RoadPressure.route_words(city_id, _outyard_dest)]
	context_body.text = "Leave only when you confirm this road."
	var go := Button.new()
	go.text = "Take the road"
	go.custom_minimum_size = Vector2(0, 48)
	go.pressed.connect(_on_travel.bind(_outyard_dest))
	market_box.add_child(go)


func _enter_yard(yard: int) -> void:
	_yard = yard
	_inspect_good_id = ""
	if yard != Yard.MARKET:
		_desk.clear()
	if yard != Yard.OUTYARD:
		_outyard_dest = ""
	_mode = Mode.NONE
	_fill_rack()
	_apply_well()
	_refresh_header()
	_refresh_context()


func _show_settlement(city_id: String) -> void:
	if _mode != Mode.NONE:
		return
	_clear_lists()
	rack_grid.visible = false
	left_title.text = GameState.get_settlement_name(city_id)
	var city: Dictionary = GameState.CITIES.get(city_id, {})
	context_title.text = GameState.get_settlement_name(city_id)
	context_meta.text = "%s  ·  %s" % [str(city.get("type", "settlement")).capitalize().replace("_", " "), "Market" if GameState.settlement_has_market(city_id) else "No market"]
	context_body.text = str(city.get("short_desc", city.get("desc", "")))
	if GameState.is_on_road():
		_show_transit_panel()
		return
	if city_id == GameState.current_city_id:
		_show_city_yards()


func _show_empty() -> void:
	_clear_lists()
	rack_grid.visible = false
	left_title.text = _mode_label(_mode)
	context_title.text = _mode_label(_mode)
	context_meta.text = ""
	context_body.text = ""


func _on_travel(city_id: String) -> void:
	if GameState.begin_hop(city_id):
		_desk.clear()
		_yard = Yard.NONE
		_inspect_good_id = ""
		_outyard_dest = ""
		_set_mode(Mode.MAP)
		_map.play_hop(str(GameState.transit.get("from", "")), city_id)


func _show_transit_panel() -> void:
	_clear_lists()
	var dest := str(GameState.transit.get("to", ""))
	var origin := str(GameState.transit.get("from", GameState.current_city_id))
	context_title.text = "On the road"
	context_meta.text = "Bound for %s" % GameState.get_settlement_name(dest)
	context_body.text = "%d day  ·  %s" % [int(GameState.transit.get("days", 1)), RoadPressure.route_words(origin, dest)]
	var skip := Button.new()
	skip.text = "Skip travel"
	skip.pressed.connect(_map.skip_hop)
	context_actions.add_child(skip)
	_apply_well()


func _complete_hop() -> void:
	_map.hide_wagon()
	GameState.finish_hop()
	_yard = Yard.MARKET
	_set_mode(Mode.NONE)
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
