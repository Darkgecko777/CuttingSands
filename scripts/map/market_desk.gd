class_name MarketDesk
extends RefCounted

const MUTED := Color(0.75, 0.62, 0.42, 1)
const GHOST := Color(0.86, 0.28, 0.22, 1)

var buy_draft: Dictionary = {}
var sell_draft: Dictionary = {}
var on_changed: Callable


func clear() -> void:
	buy_draft.clear()
	sell_draft.clear()
	_notify()


func count(table: Dictionary) -> int:
	var total := 0
	for good_id in table.keys():
		total += int(table[good_id])
	return total


func buy_cost() -> int:
	var cost := 0
	for good_id in buy_draft.keys():
		cost += GameState.get_local_price(str(good_id)) * int(buy_draft[good_id])
	return cost


func sell_gain() -> int:
	var gain := 0
	for good_id in sell_draft.keys():
		gain += GameState.get_sell_price(str(good_id)) * int(sell_draft[good_id])
	return gain


func preview_used() -> int:
	return GameState.cargo_used() - count(sell_draft) + count(buy_draft)


func can_stage_buy(good_id: String) -> bool:
	if GameState.is_on_road() or not GameState.settlement_has_market(GameState.current_city_id):
		return false
	var staged := int(buy_draft.get(good_id, 0))
	if GameState.get_market_stock(good_id) - staged <= 0:
		return false
	if GameState.scrubstone < buy_cost() + GameState.get_local_price(good_id):
		return false
	return preview_used() + 1 <= GameState.caravan_capacity


func can_stage_sell(good_id: String) -> bool:
	if GameState.is_on_road() or not GameState.settlement_has_market(GameState.current_city_id):
		return false
	return int(GameState.inventory.get(good_id, 0)) - int(sell_draft.get(good_id, 0)) > 0


func stage_plus(good_id: String) -> void:
	if int(sell_draft.get(good_id, 0)) > 0:
		_nudge(sell_draft, good_id, -1)
	elif can_stage_buy(good_id):
		_nudge(buy_draft, good_id, 1)
	else:
		return
	_notify()


func stage_minus(good_id: String) -> void:
	if int(buy_draft.get(good_id, 0)) > 0:
		_nudge(buy_draft, good_id, -1)
	elif can_stage_sell(good_id):
		_nudge(sell_draft, good_id, 1)
	else:
		return
	_notify()


func commit_buys() -> void:
	for good_id in buy_draft.keys():
		GameState.buy(str(good_id), int(buy_draft[good_id]))
	buy_draft.clear()
	_notify()


func commit_sells() -> void:
	for good_id in sell_draft.keys():
		GameState.sell(str(good_id), int(sell_draft[good_id]))
	sell_draft.clear()
	_notify()


func render(box: VBoxContainer) -> void:
	for child in box.get_children():
		child.queue_free()
	var buy_n := count(buy_draft)
	var sell_n := count(sell_draft)
	var deal := Label.new()
	deal.text = "Buy %d · %ds    Sell %d · %ds    Net %+d" % [buy_n, buy_cost(), sell_n, sell_gain(), sell_gain() - buy_cost()]
	deal.add_theme_color_override("font_color", GHOST if buy_n + sell_n > 0 else MUTED)
	deal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(deal)
	var actions := HBoxContainer.new()
	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.disabled = buy_n <= 0
	buy_btn.pressed.connect(commit_buys)
	actions.add_child(buy_btn)
	var sell_btn := Button.new()
	sell_btn.text = "Sell"
	sell_btn.disabled = sell_n <= 0
	sell_btn.pressed.connect(commit_sells)
	actions.add_child(sell_btn)
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.disabled = buy_n + sell_n <= 0
	clear_btn.pressed.connect(clear)
	actions.add_child(clear_btn)
	box.add_child(actions)
	for good_id in GameState.GOODS.keys():
		box.add_child(_row(str(good_id)))


func empty_note(box: VBoxContainer, text: String) -> void:
	var note := Label.new()
	note.text = text
	note.add_theme_color_override("font_color", MUTED)
	box.add_child(note)


func _row(good_id: String) -> HBoxContainer:
	var staged_buy := int(buy_draft.get(good_id, 0))
	var staged_sell := int(sell_draft.get(good_id, 0))
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = GameState.get_good_name(good_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var price := Label.new()
	price.text = "%d/%d" % [GameState.get_local_price(good_id), GameState.get_sell_price(good_id)]
	row.add_child(price)
	var stock := Label.new()
	stock.text = "M%d Y%d" % [GameState.get_market_stock(good_id) - staged_buy + staged_sell, int(GameState.inventory.get(good_id, 0)) - staged_sell + staged_buy]
	row.add_child(stock)
	var ghost := Label.new()
	if staged_buy > 0:
		ghost.text = "+%d" % staged_buy
	elif staged_sell > 0:
		ghost.text = "−%d" % staged_sell
	else:
		ghost.text = ""
	ghost.custom_minimum_size = Vector2(28, 0)
	ghost.add_theme_color_override("font_color", GHOST)
	row.add_child(ghost)
	var plus := Button.new()
	plus.text = "+"
	plus.disabled = not can_stage_buy(good_id) and staged_sell <= 0
	plus.pressed.connect(stage_plus.bind(good_id))
	row.add_child(plus)
	var minus := Button.new()
	minus.text = "−"
	minus.disabled = not can_stage_sell(good_id) and staged_buy <= 0
	minus.pressed.connect(stage_minus.bind(good_id))
	row.add_child(minus)
	return row


func _nudge(table: Dictionary, good_id: String, delta: int) -> void:
	var qty: int = int(table.get(good_id, 0)) + delta
	if qty <= 0:
		table.erase(good_id)
	else:
		table[good_id] = qty


func _notify() -> void:
	if on_changed.is_valid():
		on_changed.call()
