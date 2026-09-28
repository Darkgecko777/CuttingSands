extends Control

const MUTED := Color(0.75, 0.62, 0.42, 1)
const WordDeskScript = preload("res://scripts/map/word_desk.gd")
const CardScript = preload("res://scripts/map/placeholder_card.gd")

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
@onready var smash_btn: Button = %SmashBtn

var _mode: int = Mode.NONE
var _yard: int = Yard.MARKET
var _selected_kind: String = "caravan"
var _selected_id: String = GameState.PLAYER_CARAVAN_ID
var _inspect_good_id: String = ""
var _outyard_dest: String = ""
var _restock_note: String = ""
var _commission_note: String = ""
var _cat_buttons: Dictionary = {}
var _map := MapWell.new()
var _desk := MarketDesk.new()
var _word = WordDeskScript.new()
var _card: PlaceholderCard
var _card_kind: String = ""
var _card_ticket: String = ""
var _card_step: int = 0
var _card_steps: int = 0


func _ready() -> void:
	_desk.on_changed = _on_draft_changed
	_desk.on_inspect = _inspect_good
	_word.on_pick = _on_word_pick
	_card = CardScript.new()
	add_child(_card)
	_card.picked.connect(_on_card_pick)
	_map.setup(self, map_clip, map_layer, markers_layer)
	smash_btn.pressed.connect(_on_smash_from_bar)
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
	_dress_shell()
	place_banner.pressed.connect(_enter_yard.bind(Yard.NONE))
	house_btn.pressed.connect(_enter_yard.bind(Yard.HOUSE))
	market_btn.pressed.connect(_enter_yard.bind(Yard.MARKET))
	outyard_btn.pressed.connect(_enter_yard.bind(Yard.OUTYARD))
	var pause := get_node_or_null("/root/PauseMenu")
	if pause and pause.has_node("%GearButton"):
		pause.get_node("%GearButton").visible = false


func _dress_shell() -> void:
	var top := house_label.get_parent() as HBoxContainer
	if top and top.get_node_or_null("Crest") == null:
		var mark := TextureRect.new()
		mark.name = "Crest"
		mark.texture = InstrumentStyle.crest()
		mark.custom_minimum_size = Vector2(28, 28)
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(mark)
		top.move_child(mark, 0)
	for label in [house_label, place_label, day_label, weather_pip]:
		InstrumentStyle.face(label, false, 16)
	InstrumentStyle.face(status_label, false, 16)
	InstrumentStyle.face(left_title, true, 18)
	InstrumentStyle.face(context_title, true, 18)
	InstrumentStyle.face(context_meta, false, 14)
	InstrumentStyle.face(banner_caption, false, 18)
	house_label.add_theme_color_override("font_color", InstrumentStyle.AMBER)
	var top_bar := top.get_parent().get_parent() as PanelContainer
	if top_bar:
		top_bar.add_theme_stylebox_override("panel", InstrumentStyle.bar())
	var bottom := place_banner.get_parent().get_parent() as PanelContainer
	if bottom:
		bottom.add_theme_stylebox_override("panel", InstrumentStyle.bar())
	for button in _cat_buttons.values():
		button.custom_minimum_size = Vector2(112, 56)
		InstrumentStyle.toggle(button)
	InstrumentStyle.place(place_banner)
	place_banner.add_theme_font_size_override("font_size", 26)
	place_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for button in [house_btn, market_btn, outyard_btn]:
		InstrumentStyle.toggle(button)
	smash_btn.custom_minimum_size.y = 56
	InstrumentStyle.action(smash_btn)
	gear_button.text = ""
	gear_button.icon = InstrumentStyle.gear()
	gear_button.expand_icon = true
	gear_button.custom_minimum_size = Vector2(56, 56)
	InstrumentStyle.action(gear_button)


func _mark_toggle(btn: Button) -> void:
	var hot := btn.button_pressed and not btn.disabled
	btn.add_theme_color_override("font_color", InstrumentStyle.AMBER if hot else InstrumentStyle.BONE)


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
	day_label.text = GameState.clock_label()
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
	call_deferred("_apply_economy_view")


func _apply_economy_view() -> void:
	if not is_inside_tree():
		return
	_refresh_header()
	if GameState.is_on_road():
		return
	_fill_rack()
	if _mode == Mode.NONE:
		_show_caravan()


func _on_draft_changed() -> void:
	call_deferred("_apply_draft_view")


func _apply_draft_view() -> void:
	if not is_inside_tree():
		return
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
	var watch := on_road and _mode == Mode.NONE
	var atlas := _mode == Mode.MAP
	var map_only := watch or atlas
	split_host.visible = not map_only
	map_clip.visible = map_only
	if _mode == Mode.CARGO:
		left_pane.size_flags_stretch_ratio = 1.5
		right_pane.size_flags_stretch_ratio = 1.0
	else:
		left_pane.size_flags_stretch_ratio = 1.0
		right_pane.size_flags_stretch_ratio = 1.0
	if atlas:
		_map.pause_watch()
		_map.show_atlas()
	elif watch:
		_map.resume_watch()
	elif on_road:
		_map.pause_watch()


func _set_mode(mode: int) -> void:
	_mode = mode
	for key in _cat_buttons.keys():
		_cat_buttons[key].set_pressed_no_signal(key == mode)
		_mark_toggle(_cat_buttons[key])
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
	var in_market := _yard == Yard.MARKET and not GameState.is_on_road() and GameState.stalls_open()
	var click := Callable()
	if in_market:
		click = _desk.on_wagon_click
	WagonRackView.fill(rack_grid, _desk.wagon_units(), click, _inspect_good)
	WagonDealBar.sync(rack_grid, in_market and _mode != Mode.WORD, _desk)


func _inspect_good(good_id: String) -> void:
	_inspect_good_id = good_id
	if _mode == Mode.WORD:
		return
	context_body.text = GoodCopy.context_block(good_id)
	if _mode == Mode.CARGO:
		context_title.text = WorldBook.good_name(good_id)
		context_meta.text = "Selected"
	_sync_convert(good_id)


func _sync_convert(good_id: String) -> void:
	var in_hold := _mode == Mode.CARGO or (_mode == Mode.NONE and _yard == Yard.MARKET and GameState.stalls_open())
	smash_btn.visible = in_hold
	smash_btn.set_meta("good_id", good_id)
	smash_btn.disabled = not in_hold or good_id.is_empty() or not CargoHold.can_convert(good_id)


func _on_smash_from_bar() -> void:
	_on_smash_to_rations(str(smash_btn.get_meta("good_id", "")))


func _on_smash_to_rations(good_id: String) -> void:
	if not CargoHold.convert(good_id):
		return
	if _mode == Mode.CARGO:
		call_deferred("_show_cargo_tab")
	elif _mode == Mode.NONE and _yard == Yard.MARKET:
		call_deferred("_show_market_yard")


func _clear_lists() -> void:
	for child in left_box.get_children():
		child.queue_free()
	for child in market_box.get_children():
		child.queue_free()
	for child in context_actions.get_children():
		child.queue_free()
	smash_btn.visible = false


func _show_word() -> void:
	_clear_lists()
	rack_grid.visible = false
	left_title.text = "Rumours"
	_word.render(left_box, context_title, context_meta, context_body)


func _on_word_pick(rumour_id: String) -> void:
	_word.selected_id = rumour_id
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
	if not WorldBook.settlement_is_dock(GameState.current_city_id):
		_yard = Yard.NONE
		_show_landmark()
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
	var dock := not on_road and WorldBook.settlement_is_dock(city_id)
	var house_here := dock and WorldBook.settlement_has_house_yard(city_id)
	var market_live := dock and GameState.stalls_open()
	house_btn.visible = house_here or (on_road and WorldBook.settlement_has_house_yard(city_id))
	market_btn.visible = on_road or dock
	outyard_btn.visible = on_road or dock
	house_btn.disabled = not house_here
	market_btn.disabled = not market_live
	outyard_btn.disabled = not dock
	house_btn.set_pressed_no_signal(house_here and _yard == Yard.HOUSE)
	market_btn.set_pressed_no_signal(market_live and _yard == Yard.MARKET)
	outyard_btn.set_pressed_no_signal(dock and _yard == Yard.OUTYARD)
	_mark_toggle(house_btn)
	_mark_toggle(market_btn)
	_mark_toggle(outyard_btn)
	if on_road:
		_ensure_skip()


func _show_city_yards() -> void:
	_clear_lists()
	rack_grid.visible = false
	left_title.text = GameState.get_city_name()
	var note := Label.new()
	if WorldBook.settlement_has_house_yard(GameState.caravan_city(GameState.PLAYER_CARAVAN_ID)):
		note.text = "House, Market, or Outyard."
	else:
		note.text = "Market or Outyard."
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


func _with_road_note(body: String) -> String:
	if GameState.road_note.is_empty():
		return body
	return GameState.road_note + "\n\n" + body


func _show_market_yard() -> void:
	_clear_lists()
	rack_grid.visible = true
	left_title.text = "Cargo"
	var city_id := GameState.caravan_city(GameState.PLAYER_CARAVAN_ID)
	context_title.text = "Market"
	var door_line := DoorBook.stall_line(city_id)
	context_meta.text = door_line if not door_line.is_empty() else GameState.get_settlement_name(city_id)
	if not GameState.settlement_has_market(city_id):
		context_body.text = _with_road_note("No market at this stop.")
		_desk.empty_note(market_box, "No market at this stop.")
	elif not GameState.stalls_open():
		context_body.text = _with_road_note("Stalls closed until Dawn.")
		_desk.empty_note(market_box, "Stalls closed until Dawn.")
	else:
		if _inspect_good_id.is_empty():
			context_body.text = _with_road_note("Buy and sell against the hold.")
		else:
			context_body.text = _with_road_note(GoodCopy.context_block(_inspect_good_id, city_id))
		_desk.render(market_box)
	_fill_rack()
	_sync_convert(_inspect_good_id)


func _show_house_yard() -> void:
	_clear_lists()
	rack_grid.visible = false
	var city_id := GameState.caravan_city(GameState.PLAYER_CARAVAN_ID)
	if not WorldBook.settlement_has_house_yard(city_id):
		_yard = Yard.NONE
		_show_city_yards()
		return
	left_title.text = "Standing"
	var seat := WorldBook.seat_house(city_id)
	for raw in GameState.HOUSES.keys():
		var house_id := str(raw)
		var line := Label.new()
		line.text = "%s  %d" % [DoorBook.short_name(house_id), DoorBook.standing_of(house_id)]
		if house_id == GameState.selected_house_id:
			line.text += "  ·  home"
		line.add_theme_color_override("font_color", MUTED)
		left_box.add_child(line)
	if GameState.is_home_seat(city_id):
		var apartment := Button.new()
		apartment.text = "Apartment"
		apartment.disabled = true
		apartment.custom_minimum_size = Vector2(0, 56)
		InstrumentStyle.action(apartment)
		left_box.add_child(apartment)
	context_title.text = WorldBook.house_name(seat)
	context_meta.text = "standing %d" % DoorBook.standing_of(seat)
	var body := "This board is closed."
	if DoorBook.board_open(city_id):
		var rows := DoorBook.jobs_at(city_id)
		if rows.is_empty():
			body = "No commissions posted."
		else:
			body = "The house keeps the lot and pays the wage."
			_add_commission_buttons(market_box, city_id, rows)
	if not _commission_note.is_empty():
		body = _commission_note + "\n\n" + body
		_commission_note = ""
	context_body.text = body


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
	_sync_convert(_inspect_good_id)


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
		context_body.text = "Weather on the roads from here. Not a forecast."
	var neighbors: Array = []
	for raw_neighbor in GameState.neighbors_of(city_id):
		var hop_dest := str(raw_neighbor)
		if WorldBook.settlement_is_dock(hop_dest):
			neighbors.append(hop_dest)
	if neighbors.is_empty():
		var none := Label.new()
		none.text = "No marked road from this stop."
		none.add_theme_color_override("font_color", MUTED)
		left_box.add_child(none)
	else:
		for neighbor in neighbors:
			var dest := str(neighbor)
			var road := Button.new()
			road.text = "%s  ·  %s  ·  %s" % [GameState.get_settlement_name(dest), RoadPressure.route_words(city_id, dest), GameState.stamp_after(GameState.hop_hours(city_id, dest))]
			road.alignment = HORIZONTAL_ALIGNMENT_LEFT
			road.custom_minimum_size = Vector2(0, 56)
			road.toggle_mode = true
			road.button_pressed = dest == _outyard_dest
			InstrumentStyle.toggle(road)
			_mark_toggle(road)
			road.pressed.connect(_pick_hop.bind(dest))
			left_box.add_child(road)
	_paint_hop_detail(city_id)
	if not _restock_note.is_empty():
		context_body.text = _restock_note + "\n\n" + context_body.text
		_restock_note = ""
	_add_restock(market_box)
	_add_rumour_verbs(market_box)
	_add_wait_buttons(market_box)


func _pick_hop(dest: String) -> void:
	_outyard_dest = dest
	_show_outyard()


func _paint_hop_detail(city_id: String) -> void:
	if _outyard_dest.is_empty():
		return
	context_title.text = GameState.get_settlement_name(_outyard_dest)
	context_meta.text = "%s  ·  %s" % [RoadPressure.route_words(city_id, _outyard_dest), GameState.stamp_after(GameState.hop_hours(city_id, _outyard_dest))]
	context_body.text = "Leave only when you confirm this road."
	var go := Button.new()
	go.text = "Take the road"
	go.custom_minimum_size = Vector2(0, 56)
	InstrumentStyle.action(go)
	go.pressed.connect(_on_travel.bind(_outyard_dest))
	market_box.add_child(go)


func _enter_yard(yard: int) -> void:
	if GameState.is_on_road():
		return
	var city_id := GameState.current_city_id
	if yard != Yard.NONE and not WorldBook.settlement_is_dock(city_id):
		return
	if yard == Yard.HOUSE and not WorldBook.settlement_has_house_yard(city_id):
		return
	if yard == Yard.MARKET and not GameState.stalls_open():
		return
	GameState.road_note = ""
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


func _show_landmark() -> void:
	_clear_lists()
	rack_grid.visible = false
	var city_id := GameState.current_city_id
	left_title.text = GameState.get_settlement_name(city_id)
	context_title.text = GameState.get_settlement_name(city_id)
	context_meta.text = "Landmark"
	context_body.text = GameState.get_city_desc()


func _add_restock(host: Node) -> void:
	var plan := CargoHold.restock_plan()
	var restock := Button.new()
	restock.text = _restock_label(plan)
	restock.custom_minimum_size = Vector2(0, 56)
	InstrumentStyle.action(restock)
	var buying := int(plan.get("water", 0)) + int(plan.get("rations", 0))
	restock.disabled = buying <= 0
	if buying > 0:
		restock.pressed.connect(_on_restock)
	host.add_child(restock)


func _restock_label(plan: Dictionary) -> String:
	var buying := int(plan.get("water", 0)) + int(plan.get("rations", 0))
	match str(plan.get("limit", "")):
		"full":
			return "Restock water and rations"
		"thin":
			return "Cellar is thin — buy what remains"
		"coin":
			if buying > 0:
				return "Not enough coin — buy what you can"
			return "Not enough coin."
		"rack":
			if buying > 0:
				return "No room — buy what fits"
			return "No room on the rack."
		"empty":
			return _empty_cellar_line(plan)
		"stocked":
			return "Water and rations are stocked."
		_:
			return "Restock water and rations"


func _empty_cellar_line(plan: Dictionary) -> String:
	var water_short := int(plan.get("water_need", 0)) > 0
	var rations_short := int(plan.get("rations_need", 0)) > 0
	if water_short and rations_short:
		return "Cellar has no water or rations."
	if water_short:
		return "Cellar has no water."
	return "Cellar has no rations."


func _restock_bought_line(plan: Dictionary) -> String:
	var water := int(plan.get("water", 0))
	var rations := int(plan.get("rations", 0))
	if water <= 0 and rations <= 0:
		return ""
	if water > 0 and rations > 0:
		return "Bought %d water and %d rations." % [water, rations]
	if water > 0:
		return "Bought %d water." % water
	return "Bought %d rations." % rations


func _add_commission_buttons(host: Node, seat_id: String, rows: Array) -> void:
	for index in rows.size():
		if typeof(rows[index]) != TYPE_DICTIONARY:
			continue
		var job: Dictionary = rows[index]
		var good_id := str(job.get("good", ""))
		var qty := int(job.get("qty", 0))
		if good_id.is_empty() or qty <= 0:
			continue
		var home := WorldBook.seat_house(seat_id) == GameState.selected_house_id
		var wage := int(job.get("wage_home", 0)) if home else int(job.get("wage_rival", 0))
		if wage <= 0:
			wage = int(job.get("wage", 0))
		var turn := Button.new()
		turn.text = "Turn in %d %s  ·  %d" % [qty, GameState.get_good_name(good_id), wage]
		turn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		turn.custom_minimum_size = Vector2(0, 56)
		InstrumentStyle.action(turn)
		turn.disabled = int(GameState.inventory.get(good_id, 0)) < qty
		if not turn.disabled:
			turn.pressed.connect(_on_commission.bind(seat_id, index))
		host.add_child(turn)


func _on_commission(seat_id: String, index: int) -> void:
	var paid := DoorBook.turn_in(seat_id, index)
	if paid >= 0:
		_commission_note = "Wage %d. The house kept the lot." % paid


func _on_restock() -> void:
	var plan := CargoHold.restock()
	_restock_note = _restock_bought_line(plan)


func _add_rumour_verbs(host: Node) -> void:
	if GameState.is_on_road():
		return
	var social := Button.new()
	social.alignment = HORIZONTAL_ALIGNMENT_LEFT
	social.custom_minimum_size = Vector2(0, 56)
	InstrumentStyle.action(social)
	if RumourBook.can_socialize():
		social.text = "Socialize"
		social.pressed.connect(_on_socialize)
	else:
		social.text = "Socialize  ·  used today"
		social.disabled = true
	host.add_child(social)
	var rows := RumourBook.here_tickets(GameState.current_city_id)
	var expedition := Button.new()
	expedition.alignment = HORIZONTAL_ALIGNMENT_LEFT
	expedition.custom_minimum_size = Vector2(0, 56)
	InstrumentStyle.action(expedition)
	if rows.is_empty():
		expedition.text = "Expedition"
		expedition.disabled = true
	elif rows.size() == 1:
		expedition.text = "Expedition  ·  %s" % RumourBook.stars_text(int(rows[0].get("stars", 1)))
		expedition.pressed.connect(_on_expedition)
	else:
		expedition.text = "Expedition  ·  %d rumours" % rows.size()
		expedition.pressed.connect(_on_expedition)
	host.add_child(expedition)


func _on_socialize() -> void:
	if GameState.is_on_road() or not RumourBook.can_socialize() or _card.visible:
		return
	GameState.advance_hours(GameState.wait_span_hours(0))
	RumourBook.spend_socialize()
	_refresh_header()
	_card_kind = "socialize"
	var can_improve := RumourBook.has_improvable()
	_card.present("Socialize", "Choose a new rumour, or raise the stars on one you already hold.", [
		{"text": "New ticket", "id": "new"},
		{"text": "Improve existing" if can_improve else "No ticket to improve", "id": "improve", "disabled": not can_improve},
	])


func _on_expedition() -> void:
	if GameState.is_on_road() or _card.visible:
		return
	var rows := RumourBook.here_tickets(GameState.current_city_id)
	if rows.is_empty():
		return
	if rows.size() == 1:
		_begin_expedition(str(rows[0].get("id", "")))
		return
	_card_kind = "pick_expedition"
	var choices: Array = []
	for row in rows:
		choices.append({
			"text": "%s  ·  %s" % [RumourBook.stars_text(int(row.get("stars", 1))), RumourBook.life_text(row)],
			"id": str(row.get("id", "")),
		})
	_card.present("Expedition", "More than one rumour names this yard.", choices)


func _begin_expedition(ticket_id: String) -> void:
	var rec := RumourBook.ticket(ticket_id)
	if rec.is_empty():
		return
	_card_ticket = ticket_id
	_card_steps = RumourBook.cards_for(int(rec.get("stars", 1)))
	_card_step = 0
	_card_kind = "expedition"
	_show_expedition_step()


func _show_expedition_step() -> void:
	var rec := RumourBook.ticket(_card_ticket)
	if rec.is_empty():
		_close_card()
		return
	var place := WorldBook.settlement_name(str(rec.get("origin_id", "")))
	var last := _card_step >= _card_steps - 1
	var lead := ""
	if _card_step == 0:
		var term := RumourBook.country_term(str(rec.get("origin_id", ""))).to_lower()
		lead = "You leave the wagon and walk. The country is %s." % term
	if not last:
		var title := "Further in"
		var body := "The track keeps going."
		if _card_step == 0:
			title = "Out from %s" % place
			body = lead
		_card.present(title, body, [{"text": "Continue", "id": "ok"}])
		return
	var pay := RumourBook.grant(int(rec.get("stars", 1)))
	RumourBook.burn(_card_ticket)
	var body := _payoff_body(pay)
	if not lead.is_empty():
		body = lead + "\n\n" + body
	var title := "What you carry back" if _card_steps > 1 else "Out from %s" % place
	_card.present(title, body, [{"text": "Continue", "id": "ok"}])


func _payoff_body(pay: Dictionary) -> String:
	var lines: PackedStringArray = ["+%d Scrubstone." % int(pay.get("coin", 0))]
	var good_id := str(pay.get("good_id", ""))
	var name := WorldBook.good_name(good_id)
	var kept := int(pay.get("kept", 0))
	var lost := int(pay.get("lost", 0))
	if kept > 0:
		lines.append("%d %s." % [kept, name])
	if lost > 0:
		lines.append("%d %s would not fit." % [lost, name])
	lines.append("Experience %d." % int(pay.get("exp", 0)))
	return "\n".join(lines)


func _on_card_pick(choice_id: String) -> void:
	match _card_kind:
		"socialize":
			if choice_id == "improve":
				_show_improve_picker()
			else:
				_show_minted(RumourBook.mint(GameState.current_city_id))
		"improve":
			_show_improved(RumourBook.improve(choice_id))
		"pick_expedition":
			_begin_expedition(choice_id)
		"expedition":
			if _card_step >= _card_steps - 1:
				_finish_expedition()
			else:
				_card_step += 1
				_show_expedition_step()
		_:
			_close_card()


func _show_improve_picker() -> void:
	var rows := RumourBook.improvable()
	if rows.is_empty():
		_close_card()
		return
	if rows.size() == 1:
		var bumped := RumourBook.improve(str(rows[0].get("id", "")))
		_show_improved(bumped)
		return
	_card_kind = "improve"
	var choices: Array = []
	for row in rows:
		var place := WorldBook.settlement_name(str(row.get("origin_id", "")))
		choices.append({
			"text": "%s  ·  %s  ·  %s" % [place, RumourBook.stars_text(int(row.get("stars", 1))), RumourBook.life_text(row)],
			"id": str(row.get("id", "")),
		})
	_card.present("Improve existing", "Pick a rumour. Stars rise. The life stays.", choices)


func _show_minted(rec: Dictionary) -> void:
	_card_kind = "note"
	var place := WorldBook.settlement_name(str(rec.get("origin_id", "")))
	_card.present(place, "%s\n%s" % [RumourBook.stars_text(int(rec.get("stars", 1))), RumourBook.life_text(rec)], [{"text": "Continue", "id": "ok"}])


func _show_improved(rec: Dictionary) -> void:
	_card_kind = "note"
	var place := WorldBook.settlement_name(str(rec.get("origin_id", "")))
	_card.present(place, "%s\nThe life is unchanged." % RumourBook.stars_text(int(rec.get("stars", 1))), [{"text": "Continue", "id": "ok"}])


func _close_card() -> void:
	_card.dismiss()
	_card_kind = ""
	_card_ticket = ""
	_card_step = 0
	_card_steps = 0
	_refresh_header()
	if _mode == Mode.WORD:
		_show_word()
	elif _mode == Mode.NONE and _yard == Yard.OUTYARD:
		_show_outyard()


func _finish_expedition() -> void:
	var watches := _card_steps
	_card.dismiss()
	_card_kind = ""
	_card_ticket = ""
	_card_step = 0
	_card_steps = 0
	if watches > 0:
		GameState.advance_hours(watches * GameState.HOURS_PER_WATCH)
	_refresh_header()
	_map.paint_markers()
	_map.paint_chips()
	if _mode == Mode.NONE and _yard == Yard.OUTYARD:
		_show_outyard()


func _add_wait_buttons(host: Node) -> void:
	if GameState.is_on_road():
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var labels: PackedStringArray = ["1 watch", "Half day", "Full day"]
	for i in labels.size():
		var wait := Button.new()
		wait.text = labels[i]
		wait.custom_minimum_size = Vector2(0, 56)
		wait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		InstrumentStyle.action(wait)
		wait.pressed.connect(_on_wait.bind(i))
		row.add_child(wait)
	host.add_child(row)


func _on_wait(span: int) -> void:
	if GameState.is_on_road():
		return
	GameState.road_note = ""
	_desk.clear()
	GameState.advance_hours(GameState.wait_span_hours(span))
	_refresh_header()
	_show_caravan()
	_map.paint_markers()
	_map.paint_chips()


func _on_travel(city_id: String) -> void:
	if GameState.begin_hop(city_id):
		GameState.road_note = ""
		_desk.clear()
		_yard = Yard.NONE
		_inspect_good_id = ""
		_outyard_dest = ""
		_set_mode(Mode.NONE)
		_map.play_hop(str(GameState.transit.get("from", "")), city_id)


func _show_transit_panel() -> void:
	_clear_lists()
	var dest := str(GameState.transit.get("to", ""))
	var origin := str(GameState.transit.get("from", GameState.current_city_id))
	context_title.text = "On the road"
	context_meta.text = "Bound for %s" % GameState.get_settlement_name(dest)
	context_body.text = "%s  ·  arrive %s" % [RoadPressure.route_words(origin, dest), GameState.stamp_after(GameState.eta_hours_left())]
	_apply_well()
	_ensure_skip()


func _ensure_skip() -> void:
	if not GameState.is_on_road():
		return
	for child in context_actions.get_children():
		if child is Button and str(child.text) == "Skip":
			return
	var skip := Button.new()
	skip.text = "Skip"
	skip.custom_minimum_size = Vector2(120, 56)
	InstrumentStyle.action(skip)
	skip.pressed.connect(_map.skip_hop)
	context_actions.add_child(skip)


func _complete_hop() -> void:
	if _map.hop_tween:
		_map.hop_tween.kill()
	GameState.pending_watch_hours = 0
	GameState.watch_lerp = 0.0
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
