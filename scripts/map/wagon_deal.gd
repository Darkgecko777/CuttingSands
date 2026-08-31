class_name WagonDealBar
extends RefCounted

const GOLD := Color(0.92, 0.78, 0.45, 1)
const INK := Color(0.12, 0.08, 0.05, 1)


static func sync(host: Control, in_market: bool, desk: MarketDesk) -> void:
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
	row.add_child(_bordered("Buy", buy_n <= 0, desk.commit_buys))
	row.add_child(_bordered("Clear", buy_n <= 0, desk.clear_buys))


static func _bordered(text: String, disabled: bool, cb: Callable) -> Button:
	return DealStyle.button(text, disabled, cb)
