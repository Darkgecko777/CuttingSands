class_name WagonDealBar
extends RefCounted


static func sync(from: Control, in_market: bool, desk: MarketDesk) -> void:
	var box := from.get_parent()
	if box == null:
		return
	var rack := _rack_host(from)
	if rack:
		rack.clip_contents = false
	if box is Control:
		(box as Control).clip_contents = false
	var row := box.get_node_or_null("WagonDeal")
	if not in_market:
		if row:
			row.queue_free()
		return
	if row == null:
		row = HBoxContainer.new()
		row.name = "WagonDeal"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.custom_minimum_size = Vector2(0, 40)
		box.add_child(row)
	for child in row.get_children():
		child.queue_free()
	var buy_n: int = desk.buy_count()
	row.add_child(DealStyle.button("Buy", buy_n <= 0, desk.commit_buys))
	row.add_child(DealStyle.button("Clear", buy_n <= 0, desk.clear_buys))


static func _rack_host(from: Control) -> Control:
	var node: Node = from
	while node:
		if node.name == "WagonRack" and node is Control:
			return node
		node = node.get_parent()
	return null
