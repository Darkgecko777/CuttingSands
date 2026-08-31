extends Control

## City desk: the playtest home. Market, wagon, and roads live here. Map is travel only.

const MAP_SCENE := "res://scenes/map/field_shell.tscn"
const GOLD := Color(0.92, 0.78, 0.45, 1)
const MUTED := Color(0.75, 0.62, 0.42, 1)
const INK := Color(0.85, 0.78, 0.66, 1)

@onready var city_label: Label = %CityLabel
@onready var house_label: Label = %HouseLabel
@onready var day_label: Label = %DayLabel
@onready var gold_label: Label = %GoldLabel
@onready var market_list: VBoxContainer = %MarketList
@onready var city_desc_label: Label = %CityDescLabel
@onready var news_label: Label = %NewsLabel
@onready var roads_list: VBoxContainer = %RoadsList
@onready var cargo_label: Label = %CargoLabel
@onready var map_button: Button = %MapButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	map_button.pressed.connect(_on_map_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	_refresh_all()
	GameState.scrubstone_changed.connect(_on_economy)
	GameState.inventory_changed.connect(_on_economy)
	GameState.location_changed.connect(_on_location_changed)


func _refresh_all() -> void:
	_refresh_header()
	_build_market()
	_build_roads()
	_setup_city_copy()


func _refresh_header() -> void:
	city_label.text = GameState.get_city_name()
	house_label.text = GameState.get_house_name()
	day_label.text = "Day %d" % GameState.day
	gold_label.text = "Scrubstone %d" % GameState.scrubstone
	cargo_label.text = "Wagon  %d / %d" % [GameState.cargo_used(), GameState.caravan_capacity]


func _on_economy(_arg: Variant = null) -> void:
	_refresh_header()
	_refresh_market_buttons()


func _on_location_changed(_city_id: String) -> void:
	_refresh_all()


func _on_map_pressed() -> void:
	get_tree().change_scene_to_file(MAP_SCENE)


func _on_menu_pressed() -> void:
	if has_node("/root/PauseMenu"):
		PauseMenu.open()


func _setup_city_copy() -> void:
	city_desc_label.text = GameState.get_city_desc()
	if GameState.settlement_has_market(GameState.current_city_id):
		news_label.text = "Buy cheap near the producer. Sell farther out. Prices move with local stock."
	else:
		news_label.text = "No market here. Rest the wagon, then take the road."


func _build_market() -> void:
	for child in market_list.get_children():
		child.queue_free()
	if not GameState.settlement_has_market(GameState.current_city_id):
		var note := Label.new()
		note.text = "This stop has no stall. Open the map and take a road."
		note.add_theme_color_override("font_color", MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		market_list.add_child(note)
		return
	var header := _market_header_row()
	market_list.add_child(header)
	for good_id in GameState.GOODS.keys():
		market_list.add_child(_create_market_row(good_id))
	_refresh_market_buttons()


func _market_header_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for item in [["Good", 160], ["Buy", 56], ["Sell", 56], ["Stall", 56], ["Wagon", 56], ["Source", 140]]:
		var lab := Label.new()
		lab.text = item[0]
		lab.custom_minimum_size = Vector2(item[1], 0)
		lab.add_theme_color_override("font_color", MUTED)
		row.add_child(lab)
	return row


func _create_market_row(good_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(0, 36)

	var name_label := Label.new()
	name_label.text = GameState.get_good_name(good_id)
	name_label.custom_minimum_size = Vector2(160, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var buy_price := Label.new()
	buy_price.name = "BuyPrice"
	buy_price.custom_minimum_size = Vector2(56, 0)
	row.add_child(buy_price)

	var sell_price := Label.new()
	sell_price.name = "SellPrice"
	sell_price.custom_minimum_size = Vector2(56, 0)
	row.add_child(sell_price)

	var market_stock_label := Label.new()
	market_stock_label.name = "MarketStockLabel"
	market_stock_label.custom_minimum_size = Vector2(56, 0)
	row.add_child(market_stock_label)

	var stock_label := Label.new()
	stock_label.name = "StockLabel"
	stock_label.custom_minimum_size = Vector2(56, 0)
	row.add_child(stock_label)

	var source := Label.new()
	source.text = GameState.get_producer_name(good_id)
	source.custom_minimum_size = Vector2(140, 0)
	source.add_theme_color_override("font_color", MUTED)
	row.add_child(source)

	var buy_btn := Button.new()
	buy_btn.name = "BuyButton"
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(64, 0)
	buy_btn.pressed.connect(_on_buy.bind(good_id))
	row.add_child(buy_btn)

	var sell_btn := Button.new()
	sell_btn.name = "SellButton"
	sell_btn.text = "Sell"
	sell_btn.custom_minimum_size = Vector2(64, 0)
	sell_btn.pressed.connect(_on_sell.bind(good_id))
	row.add_child(sell_btn)

	row.set_meta("good_id", good_id)
	return row


func _refresh_market_buttons() -> void:
	for row in market_list.get_children():
		if not row.has_meta("good_id"):
			continue
		var good_id: String = row.get_meta("good_id")
		var buy_price: Label = row.get_node_or_null("BuyPrice")
		var sell_price: Label = row.get_node_or_null("SellPrice")
		var market_stock_label: Label = row.get_node_or_null("MarketStockLabel")
		var stock_label: Label = row.get_node_or_null("StockLabel")
		var buy_btn: Button = row.get_node_or_null("BuyButton")
		var sell_btn: Button = row.get_node_or_null("SellButton")
		if buy_price:
			buy_price.text = "%d" % GameState.get_local_price(good_id)
		if sell_price:
			sell_price.text = "%d" % GameState.get_sell_price(good_id)
		if market_stock_label:
			market_stock_label.text = str(GameState.get_market_stock(good_id))
		if stock_label:
			stock_label.text = str(GameState.inventory.get(good_id, 0))
		if buy_btn:
			buy_btn.disabled = not GameState.can_buy(good_id)
		if sell_btn:
			sell_btn.disabled = not GameState.can_sell(good_id)


func _on_buy(good_id: String) -> void:
	GameState.buy(good_id)


func _on_sell(good_id: String) -> void:
	GameState.sell(good_id)


func _build_roads() -> void:
	for child in roads_list.get_children():
		child.queue_free()
	var here := GameState.current_city_id
	var neighbors: Array = GameState.neighbors_of(here)
	if neighbors.is_empty():
		var none := Label.new()
		none.text = "No marked roads from here."
		none.add_theme_color_override("font_color", MUTED)
		roads_list.add_child(none)
		return
	for neighbor in neighbors:
		var dest := str(neighbor)
		var btn := Button.new()
		var days := GameState.hop_days(here, dest)
		btn.text = "Road to %s  ·  %d day" % [GameState.get_settlement_name(dest), days]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_take_road.bind(dest))
		roads_list.add_child(btn)


func _on_take_road(dest: String) -> void:
	GameState.pending_travel_to = dest
	get_tree().change_scene_to_file(MAP_SCENE)
