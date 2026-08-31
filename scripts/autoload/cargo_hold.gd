class_name CargoHold
extends RefCounted


static func empty_cargo() -> Dictionary:
	var cargo: Dictionary = {}
	for good_id in GameState.GOODS.keys():
		cargo[good_id] = 0
	if cargo.has("water"):
		cargo["water"] = 2
	if cargo.has("grain"):
		cargo["grain"] = 3
	return cargo


static func reset_player() -> void:
	GameState.inventory = empty_cargo()
	if GameState.caravans.has(GameState.PLAYER_CARAVAN_ID):
		GameState.caravans[GameState.PLAYER_CARAVAN_ID]["cargo"] = GameState.inventory
		GameState.caravans[GameState.PLAYER_CARAVAN_ID]["capacity"] = GameState.caravan_capacity


static func cells() -> int:
	return CargoMath.cells_in(GameState.inventory)


static func mass() -> int:
	return CargoMath.mass_in(GameState.inventory)


static func can_buy(good_id: String, amount: int = 1) -> bool:
	if amount <= 0 or not GameState.settlement_has_market(GameState.current_city_id) or GameState.is_on_road():
		return false
	if GameState.get_market_stock(good_id) < amount:
		return false
	if cells() + amount * CargoMath.size_of(good_id) > GameState.caravan_capacity:
		return false
	if mass() + amount * CargoMath.mass_of(good_id) > GameState.caravan_mass_capacity:
		return false
	return GameState.scrubstone >= GameState.get_local_price(good_id) * amount


static func buy(good_id: String, amount: int = 1) -> bool:
	if not can_buy(good_id, amount):
		return false
	GameState.scrubstone -= GameState.get_local_price(good_id) * amount
	GameState.inventory[good_id] = GameState.inventory.get(good_id, 0) + amount
	GameState.market_stock[GameState.current_city_id][good_id] = GameState.get_market_stock(good_id) - amount
	GameState.scrubstone_changed.emit(GameState.scrubstone)
	GameState.inventory_changed.emit()
	return true


static func can_sell(good_id: String, amount: int = 1) -> bool:
	return amount > 0 and GameState.settlement_has_market(GameState.current_city_id) and not GameState.is_on_road() and GameState.inventory.get(good_id, 0) >= amount


static func sell(good_id: String, amount: int = 1) -> bool:
	if not can_sell(good_id, amount):
		return false
	GameState.scrubstone += GameState.get_sell_price(good_id) * amount
	GameState.inventory[good_id] = GameState.inventory.get(good_id, 0) - amount
	if not GameState.market_stock.has(GameState.current_city_id):
		GameState.market_stock[GameState.current_city_id] = {}
	GameState.market_stock[GameState.current_city_id][good_id] = GameState.get_market_stock(good_id) + amount
	GameState.scrubstone_changed.emit(GameState.scrubstone)
	GameState.inventory_changed.emit()
	return true
