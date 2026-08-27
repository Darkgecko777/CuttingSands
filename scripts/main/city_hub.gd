extends Control

## Main city interaction hub.
## Tabs: Market (functional), Caravan, Intelligence, City

@onready var city_label: Label = %CityLabel
@onready var house_label: Label = %HouseLabel
@onready var gold_label: Label = %GoldLabel
@onready var tab_container: TabContainer = %TabContainer
@onready var market_list: VBoxContainer = %MarketList
@onready var city_desc_label: Label = %CityDescLabel
@onready var news_label: Label = %NewsLabel


func _ready() -> void:
	_ensure_map_button()
	_refresh_header()
	_build_market()
	_setup_placeholders()

	GameState.scrubstone_changed.connect(_on_scrubstone_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.location_changed.connect(_on_location_changed)


func _refresh_header() -> void:
	city_label.text = GameState.get_city_name()
	house_label.text = GameState.get_house_name()
	gold_label.text = "Scrubstone: %d   Cargo: %d/%d" % [
		GameState.scrubstone,
		GameState.cargo_used(),
		GameState.caravan_capacity,
	]


func _on_scrubstone_changed(_new_amount: int) -> void:
	_refresh_header()
	_refresh_market_buttons()


func _on_inventory_changed() -> void:
	_refresh_header()
	_refresh_market_buttons()


func _ensure_map_button() -> void:
	if has_node("%MapButton"):
		%MapButton.pressed.connect(_on_map_pressed)
		return
	var parent := gold_label.get_parent()
	var btn := Button.new()
	btn.name = "MapButton"
	btn.unique_name_in_owner = true
	btn.text = "Map"
	btn.custom_minimum_size = Vector2(72, 0)
	parent.add_child(btn)
	parent.move_child(btn, gold_label.get_index())
	btn.pressed.connect(_on_map_pressed)


func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map/world_map.tscn")


func _on_location_changed(_city_id: String) -> void:
	_refresh_header()
	_build_market()
	_setup_placeholders()


func _build_market() -> void:
	for child in market_list.get_children():
		child.queue_free()

	for good_id in GameState.GOODS.keys():
		var row := _create_market_row(good_id)
		market_list.add_child(row)
	_refresh_market_buttons()


func _create_market_row(good_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 36)

	var name_label := Label.new()
	name_label.text = GameState.get_good_name(good_id)
	name_label.custom_minimum_size = Vector2(100, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var price_label := Label.new()
	price_label.name = "PriceLabel"
	price_label.text = "%d s" % GameState.get_local_price(good_id)
	price_label.custom_minimum_size = Vector2(70, 0)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(price_label)

	var market_stock_label := Label.new()
	market_stock_label.name = "MarketStockLabel"
	market_stock_label.text = "Mkt: %d" % GameState.get_market_stock(good_id)
	market_stock_label.custom_minimum_size = Vector2(70, 0)
	row.add_child(market_stock_label)

	var stock_label := Label.new()
	stock_label.name = "StockLabel"
	stock_label.text = "You: %d" % GameState.inventory.get(good_id, 0)
	stock_label.custom_minimum_size = Vector2(70, 0)
	row.add_child(stock_label)

	var buy_btn := Button.new()
	buy_btn.name = "BuyButton"
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(60, 0)
	buy_btn.pressed.connect(_on_buy.bind(good_id))
	row.add_child(buy_btn)

	var sell_btn := Button.new()
	sell_btn.name = "SellButton"
	sell_btn.text = "Sell"
	sell_btn.custom_minimum_size = Vector2(60, 0)
	sell_btn.pressed.connect(_on_sell.bind(good_id))
	row.add_child(sell_btn)

	row.set_meta("good_id", good_id)
	return row


func _refresh_market_buttons() -> void:
	for row in market_list.get_children():
		if not row.has_meta("good_id"):
			continue
		var good_id: String = row.get_meta("good_id")
		var price_label: Label = row.get_node_or_null("PriceLabel")
		var market_stock_label: Label = row.get_node_or_null("MarketStockLabel")
		var stock_label: Label = row.get_node_or_null("StockLabel")
		var buy_btn: Button = row.get_node_or_null("BuyButton")
		var sell_btn: Button = row.get_node_or_null("SellButton")

		if price_label:
			price_label.text = "%d s" % GameState.get_local_price(good_id)
		if market_stock_label:
			market_stock_label.text = "Mkt: %d" % GameState.get_market_stock(good_id)
		if stock_label:
			stock_label.text = "You: %d" % GameState.inventory.get(good_id, 0)
		if buy_btn:
			buy_btn.disabled = not GameState.can_buy(good_id)
		if sell_btn:
			sell_btn.disabled = not GameState.can_sell(good_id)


func _on_buy(good_id: String) -> void:
	GameState.buy(good_id)


func _on_sell(good_id: String) -> void:
	GameState.sell(good_id)


func _setup_placeholders() -> void:
	city_desc_label.text = GameState.get_city_desc()
	news_label.text = "Local reports are quiet for now. Rumour and pressure systems will live here."
