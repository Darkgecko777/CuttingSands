class_name MarketDesk
extends RefCounted

const MUTED := Color(0.75, 0.62, 0.42, 1)


static func build_stall(box: VBoxContainer, on_buy: Callable, on_sell: Callable) -> void:
	for good_id in GameState.GOODS.keys():
		var row := HBoxContainer.new()
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
		buy.pressed.connect(on_buy.bind(good_id))
		row.add_child(buy)
		var sell := Button.new()
		sell.text = "-"
		sell.disabled = not GameState.can_sell(good_id)
		sell.pressed.connect(on_sell.bind(good_id))
		row.add_child(sell)
		box.add_child(row)


static func empty_note(box: VBoxContainer, text: String) -> void:
	var note := Label.new()
	note.text = text
	note.add_theme_color_override("font_color", MUTED)
	box.add_child(note)
