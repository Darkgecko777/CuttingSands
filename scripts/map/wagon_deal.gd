class_name WagonDealBar
extends RefCounted


static func sync(grid: GridContainer, in_market: bool, desk: MarketDesk) -> void:
	var box := grid.get_parent()
	var row := box.get_node_or_null("WagonDeal")
	if not in_market:
		if row:
			row.queue_free()
		return
	if row == null:
		row = HBoxContainer.new()
		row.name = "WagonDeal"
		box.add_child(row)
	for child in row.get_children():
		child.queue_free()
	var buy_n: int = desk.buy_count()
	var buy := Button.new()
	buy.text = "Buy"
	buy.disabled = buy_n <= 0
	buy.pressed.connect(desk.commit_buys)
	row.add_child(buy)
	var clear := Button.new()
	clear.text = "Clear"
	clear.disabled = buy_n <= 0
	clear.pressed.connect(desk.clear_buys)
	row.add_child(clear)
