class_name CargoHold
extends RefCounted

const RESTOCK_WATER := 2
const RESTOCK_RATIONS := 6


static func empty_cargo() -> Dictionary:
	var cargo: Dictionary = {}
	for good_id in GameState.GOODS.keys():
		cargo[good_id] = 0
	if cargo.has("water"):
		cargo["water"] = 2
	if cargo.has("speargrain"):
		cargo["speargrain"] = 3
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
	if amount <= 0 or not GameState.settlement_has_market(GameState.current_city_id) or GameState.is_on_road() or not GameState.stalls_open():
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
	MarketBook.set_stock(good_id, GameState.current_city_id, GameState.get_market_stock(good_id) - amount)
	SightBook.stamp_city(GameState.current_city_id)
	GameState.scrubstone_changed.emit(GameState.scrubstone)
	GameState.inventory_changed.emit()
	return true


static func can_sell(good_id: String, amount: int = 1) -> bool:
	return amount > 0 and GameState.settlement_has_market(GameState.current_city_id) and not GameState.is_on_road() and GameState.stalls_open() and GameState.inventory.get(good_id, 0) >= amount


static func sell(good_id: String, amount: int = 1) -> bool:
	if not can_sell(good_id, amount):
		return false
	var cid := GameState.current_city_id
	DoorBook.stamp_sale(cid, GameState.selected_house_id, good_id, amount)
	GameState.scrubstone += GameState.get_sell_price(good_id) * amount
	GameState.inventory[good_id] = GameState.inventory.get(good_id, 0) - amount
	var have := GameState.get_market_stock(good_id, cid)
	var ceiling := MarketBook.cap(cid, good_id)
	var stored := have + amount
	if ceiling > 0 and stored > ceiling:
		stored = ceiling
	MarketBook.set_stock(good_id, cid, stored)
	SightBook.stamp_city(cid)
	GameState.scrubstone_changed.emit(GameState.scrubstone)
	GameState.inventory_changed.emit()
	return true


static func can_convert(good_id: String) -> bool:
	if good_id.is_empty() or int(GameState.inventory.get(good_id, 0)) < 1:
		return false
	var yield_n := WorldBook.ration_yield(good_id)
	if yield_n <= 0:
		return false
	var next: Dictionary = GameState.inventory.duplicate()
	next[good_id] = int(next.get(good_id, 0)) - 1
	next["rations"] = int(next.get("rations", 0)) + yield_n
	if CargoMath.cells_in(next) > GameState.caravan_capacity:
		return false
	return CargoMath.mass_in(next) <= GameState.caravan_mass_capacity


static func convert(good_id: String) -> bool:
	if not can_convert(good_id):
		return false
	var yield_n := WorldBook.ration_yield(good_id)
	GameState.inventory[good_id] = int(GameState.inventory.get(good_id, 0)) - 1
	GameState.inventory["rations"] = int(GameState.inventory.get("rations", 0)) + yield_n
	GameState.inventory_changed.emit()
	return true


static func restock_plan() -> Dictionary:
	return _walk_restock(false)


static func restock() -> Dictionary:
	var plan := _walk_restock(true)
	if int(plan.get("water", 0)) + int(plan.get("rations", 0)) > 0:
		GameState.inventory_changed.emit()
	return plan


static func _walk_restock(commit: bool) -> Dictionary:
	var plan := {
		"water": 0,
		"rations": 0,
		"water_need": 0,
		"rations_need": 0,
		"limit": "shut",
	}
	if GameState.is_on_road() or not WorldBook.settlement_is_dock(GameState.current_city_id):
		return plan
	var cid := GameState.current_city_id
	var coin := GameState.scrubstone
	var used_cells := cells()
	var used_mass := mass()
	var shelf := {
		"water": GameState.get_market_stock("water", cid),
		"rations": GameState.get_market_stock("rations", cid),
	}
	var held := {
		"water": int(GameState.inventory.get("water", 0)),
		"rations": int(GameState.inventory.get("rations", 0)),
	}
	var targets := {"water": RESTOCK_WATER, "rations": RESTOCK_RATIONS}
	var blocker := ""
	for good_id in ["water", "rations"]:
		var need := maxi(0, int(targets[good_id]) - int(held[good_id]))
		plan["%s_need" % good_id] = need
		var bought := 0
		while bought < need:
			var stop := _restock_block(good_id, cid, coin, used_cells, used_mass, int(shelf[good_id]))
			if not stop.is_empty():
				if blocker.is_empty():
					blocker = stop
				break
			var price := MarketBook.local_price_at(good_id, cid, int(shelf[good_id]))
			coin -= price
			used_cells += CargoMath.size_of(good_id)
			used_mass += CargoMath.mass_of(good_id)
			shelf[good_id] = int(shelf[good_id]) - 1
			held[good_id] = int(held[good_id]) + 1
			bought += 1
			if commit:
				GameState.scrubstone = coin
				GameState.inventory[good_id] = int(held[good_id])
				MarketBook.set_stock(good_id, cid, int(shelf[good_id]))
		plan[good_id] = bought
	plan["limit"] = _restock_limit(plan, blocker)
	return plan


static func _restock_block(good_id: String, city_id: String, coin: int, used_cells: int, used_mass: int, have: int) -> String:
	if have <= 0:
		return "thin"
	var price := MarketBook.local_price_at(good_id, city_id, have)
	if price <= 0 or coin < price:
		return "coin"
	if used_cells + CargoMath.size_of(good_id) > GameState.caravan_capacity:
		return "rack"
	if used_mass + CargoMath.mass_of(good_id) > GameState.caravan_mass_capacity:
		return "rack"
	return ""


static func _restock_limit(plan: Dictionary, blocker: String) -> String:
	var need := int(plan.get("water_need", 0)) + int(plan.get("rations_need", 0))
	var got := int(plan.get("water", 0)) + int(plan.get("rations", 0))
	if need <= 0:
		return "stocked"
	if got >= need:
		return "full"
	if got <= 0:
		if blocker == "coin":
			return "coin"
		if blocker == "rack":
			return "rack"
		return "empty"
	if blocker == "coin" or blocker == "rack" or blocker == "thin":
		return blocker
	return "thin"
