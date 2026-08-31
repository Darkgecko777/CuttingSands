class_name WagonDealBar
extends RefCounted


static func sync(from: Control, in_market: bool, desk: MarketDesk) -> void:
	var host := _rack_host(from)
	var row := host.get_node_or_null("WagonDeal")
	if not in_market:
		if row:
			row.queue_free()
		return
	if row == null:
		row = HBoxContainer.new()
		row.name = "WagonDeal"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		row.offset_left = 12
		row.offset_right = -12
		row.offset_top = -52
		row.offset_bottom = -10
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		host.add_child(row)
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
	return from if from.get_parent() == null else from.get_parent()
