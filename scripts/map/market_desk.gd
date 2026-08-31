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


func wagon_units() -> Array:
	var units: Array = []
	for good_id in GameState.GOODS.keys():
		var gid := str(good_id)
		var keep: int = maxi(0, int(GameState.inventory.get(gid, 0)) - int(sell_draft.get(gid, 0)))
		for _i in keep:
			units.append({"id": gid, "ghost": false})
		for _j in int(buy_draft.get(gid, 0)):
			units.append({"id": gid, "ghost": true})
	return units


func sell_units() -> Array:
	var units: Array = []
	for good_id in GameState.GOODS.keys():
		var gid := str(good_id)
		for _i in int(sell_draft.get(gid, 0)):
			units.append({"id": gid, "ghost": true})
	return units


func preview_cells() -> int:
	return CargoMath.cells_in(GameState.inventory) - CargoMath.cells_in(sell_draft) + CargoMath.cells_in(buy_draft)


func preview_mass() -> int:
	return CargoMath.mass_in(GameState.inventory) - CargoMath.mass_in(sell_draft) + CargoMath.mass_in(buy_draft)


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


func staged_count() -> int:
	return buy_count() + sell_count()


func buy_count() -> int:
	return _count(buy_draft)


func sell_count() -> int:
	return _count(sell_draft)


func can_stage_buy(good_id: String) -> bool:
	if GameState.is_on_road() or not GameState.settlement_has_market(GameState.current_city_id):
		return false
	var staged: int = int(buy_draft.get(good_id, 0))
	if GameState.get_market_stock(good_id) - staged <= 0:
		return false
	if GameState.scrubstone < buy_cost() + GameState.get_local_price(good_id):
		return false
	if preview_cells() + CargoMath.size_of(good_id) > GameState.caravan_capacity:
		return false
	return preview_mass() + CargoMath.mass_of(good_id) <= GameState.caravan_mass_capacity


func can_stage_sell(good_id: String) -> bool:
	if GameState.is_on_road() or not GameState.settlement_has_market(GameState.current_city_id):
		return false
	return int(GameState.inventory.get(good_id, 0)) - int(sell_draft.get(good_id, 0)) > 0


func on_wagon_click(good_id: String, ghost: bool) -> void:
	if ghost:
		_nudge(buy_draft, good_id, -1)
	elif can_stage_sell(good_id):
		_nudge(sell_draft, good_id, 1)
	else:
		return
	_notify()


func on_sell_click(good_id: String, _ghost: bool) -> void:
	if int(sell_draft.get(good_id, 0)) <= 0:
		return
	_nudge(sell_draft, good_id, -1)
	_notify()


func stage_buy(good_id: String) -> void:
	if not can_stage_buy(good_id):
		return
	_nudge(buy_draft, good_id, 1)
	_notify()


func clear_buys() -> void:
	buy_draft.clear()
	_notify()


func clear_sells() -> void:
	sell_draft.clear()
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
	var buy_n: int = buy_count()
	var sell_n: int = sell_count()
	var deal := Label.new()
	deal.text = "Buy %d · %ds    Sell %d · %ds    Net %+d" % [buy_n, buy_cost(), sell_n, sell_gain(), sell_gain() - buy_cost()]
	deal.add_theme_color_override("font_color", GHOST if buy_n + sell_n > 0 else MUTED)
	deal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(deal)
	var stock_title := Label.new()
	stock_title.text = "Stall"
	stock_title.add_theme_color_override("font_color", MUTED)
	box.add_child(stock_title)
	for good_id in GameState.GOODS.keys():
		box.add_child(_stock_row(str(good_id)))
	var sell_title := Label.new()
	sell_title.text = "To sell"
	sell_title.add_theme_color_override("font_color", MUTED)
	box.add_child(sell_title)
	var sell_grid := GridContainer.new()
	sell_grid.columns = 4
	box.add_child(sell_grid)
	WagonRackView.fill(sell_grid, sell_units(), on_sell_click)
	var sell_actions := HBoxContainer.new()
	sell_actions.add_child(_action("Sell", sell_n <= 0, commit_sells))
	sell_actions.add_child(_action("Clear", sell_n <= 0, clear_sells))
	box.add_child(sell_actions)


func empty_note(box: VBoxContainer, text: String) -> void:
	var note := Label.new()
	note.text = text
	note.add_theme_color_override("font_color", MUTED)
	box.add_child(note)


func _stock_row(good_id: String) -> HBoxContainer:
	var staged_buy: int = int(buy_draft.get(good_id, 0))
	var row := HBoxContainer.new()
	var mark := Label.new()
	mark.text = GameState.get_good_name(good_id).substr(0, 1)
	mark.custom_minimum_size = Vector2(22, 0)
	row.add_child(mark)
	var name_label := Label.new()
	name_label.text = GameState.get_good_name(good_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var meta := Label.new()
	meta.text = "%ds  M%d" % [GameState.get_local_price(good_id), GameState.get_market_stock(good_id) - staged_buy]
	row.add_child(meta)
	var plus := Button.new()
	plus.text = "+"
	plus.disabled = not can_stage_buy(good_id)
	plus.pressed.connect(stage_buy.bind(good_id))
	row.add_child(plus)
	return row


func _action(text: String, disabled: bool, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.disabled = disabled
	btn.pressed.connect(cb)
	return btn


func _count(table: Dictionary) -> int:
	var total := 0
	for good_id in table.keys():
		total += int(table[good_id])
	return total


func _nudge(table: Dictionary, good_id: String, delta: int) -> void:
	var qty: int = int(table.get(good_id, 0)) + delta
	if qty <= 0:
		table.erase(good_id)
	else:
		table[good_id] = qty


func _notify() -> void:
	if on_changed.is_valid():
		on_changed.call()
