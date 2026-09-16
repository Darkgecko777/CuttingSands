class_name StringBook
extends RefCounted

const LOT := 2
const HOP_MAX := 2


static func seed_all() -> void:
	GameState.string_tokens.clear()
	var roster: Dictionary = GameState.STRING_ROSTER
	var purse := int(roster.get("purse", GameState.STARTING_SCRUBSTONE))
	var rows: Variant = roster.get("tokens", [])
	if typeof(rows) != TYPE_ARRAY:
		return
	for raw in rows:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = raw
		var house_id := str(row.get("house_id", ""))
		var chair := int(row.get("chair", -1))
		if house_id == GameState.selected_house_id and chair == 0:
			continue
		var node_id := str(row.get("node_id", ""))
		if not WorldBook.settlement_has_market(node_id) or MarketBook.market_size(node_id) <= 0:
			continue
		var token_id := str(row.get("id", ""))
		if token_id.is_empty():
			token_id = "%s_%d" % [house_id, chair]
		GameState.string_tokens[token_id] = {
			"id": token_id,
			"house_id": house_id,
			"chair": chair,
			"node_id": node_id,
			"purse": purse,
			"cargo": _empty_cargo(),
			"bound_for": "",
			"trip_good": "",
		}


static func tick_all() -> void:
	var ids: Array = GameState.string_tokens.keys()
	ids.sort()
	for token_id in ids:
		var token: Dictionary = GameState.string_tokens[token_id]
		if token.is_empty():
			continue
		_tick_one(token)


static func ids_at(node_id: String) -> Array:
	var out: Array = []
	for token_id in GameState.string_tokens.keys():
		var token: Dictionary = GameState.string_tokens[token_id]
		if str(token.get("node_id", "")) == node_id:
			out.append(str(token_id))
	out.sort()
	return out


static func _tick_one(token: Dictionary) -> void:
	var here := str(token.get("node_id", ""))
	if here.is_empty() or not WorldBook.settlement_has_market(here):
		return
	var bound_for := str(token.get("bound_for", ""))
	var trip_good := str(token.get("trip_good", ""))
	var held := _held(token, trip_good)
	if not bound_for.is_empty() and here == bound_for:
		if held > 0:
			_sell(token, trip_good, held)
		token["bound_for"] = ""
		token["trip_good"] = ""
		return
	if held > 0 and not bound_for.is_empty():
		_step_toward(token, bound_for)
		return
	if CargoMath.cells_in(token.get("cargo", {})) > 0:
		return
	var trip := _best_trip(token, here)
	if trip.is_empty():
		return
	var good_id := str(trip.get("good", ""))
	var dest := str(trip.get("dest", ""))
	var units := int(trip.get("units", 0))
	if not _buy(token, good_id, units):
		return
	token["trip_good"] = good_id
	token["bound_for"] = dest
	if dest != here:
		_step_toward(token, dest)


static func _best_trip(token: Dictionary, here: String) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -1.0
	var best_hops := 99
	var best_good := ""
	var best_dest := ""
	var dests := _market_ids()
	for raw_good in GameState.GOODS.keys():
		var good_id := str(raw_good)
		var local_p := MarketBook.local_price(good_id, here)
		var have := MarketBook.stock(good_id, here)
		if local_p <= 0 or have <= 0:
			continue
		var units := _max_buy(token, good_id, local_p, have)
		if units <= 0:
			continue
		for dest in dests:
			if dest == here:
				continue
			var hops := MarketBook.hops_between(here, dest)
			if hops < 1 or hops > HOP_MAX:
				continue
			var dest_p := MarketBook.local_price(good_id, dest)
			var spread := dest_p - local_p
			if not _spread_ok(local_p, spread):
				continue
			var score := float(spread * units) / float(hops)
			var take := false
			if score > best_score:
				take = true
			elif is_equal_approx(score, best_score):
				if hops < best_hops:
					take = true
				elif hops == best_hops and (good_id < best_good or (good_id == best_good and dest < best_dest)):
					take = true
			if not take:
				continue
			best_score = score
			best_hops = hops
			best_good = good_id
			best_dest = dest
			best = {"good": good_id, "dest": dest, "units": units}
	return best


static func _spread_ok(local_p: int, spread: int) -> bool:
	if spread <= 0 or local_p <= 0:
		return false
	return spread >= maxi(2, int(round(float(local_p) * 0.15)))


static func _max_buy(token: Dictionary, good_id: String, price: int, stock: int) -> int:
	if price <= 0:
		return 0
	var cargo: Dictionary = token.get("cargo", {})
	var by_purse := int(float(int(token.get("purse", 0))) / float(price))
	var by_cells := int(float(CargoMath.cell_cap() - CargoMath.cells_in(cargo)) / float(CargoMath.size_of(good_id)))
	var by_mass := int(float(CargoMath.mass_cap() - CargoMath.mass_in(cargo)) / float(CargoMath.mass_of(good_id)))
	return clampi(mini(LOT, mini(stock, mini(by_purse, mini(by_cells, by_mass)))), 0, LOT)


static func _buy(token: Dictionary, good_id: String, units: int) -> bool:
	var here := str(token.get("node_id", ""))
	if units <= 0 or good_id.is_empty() or not WorldBook.settlement_has_market(here):
		return false
	var price := MarketBook.local_price(good_id, here)
	var cost := price * units
	if price <= 0 or int(token.get("purse", 0)) < cost:
		return false
	if MarketBook.stock(good_id, here) < units:
		return false
	var cargo: Dictionary = token.get("cargo", {})
	if CargoMath.cells_in(cargo) + units * CargoMath.size_of(good_id) > CargoMath.cell_cap():
		return false
	if CargoMath.mass_in(cargo) + units * CargoMath.mass_of(good_id) > CargoMath.mass_cap():
		return false
	token["purse"] = int(token.get("purse", 0)) - cost
	cargo[good_id] = int(cargo.get(good_id, 0)) + units
	token["cargo"] = cargo
	MarketBook.set_stock(good_id, here, MarketBook.stock(good_id, here) - units)
	return true


static func _sell(token: Dictionary, good_id: String, units: int) -> void:
	var here := str(token.get("node_id", ""))
	var cargo: Dictionary = token.get("cargo", {})
	var held := int(cargo.get(good_id, 0))
	units = clampi(units, 0, held)
	if units <= 0 or good_id.is_empty() or not WorldBook.settlement_has_market(here):
		return
	var price := MarketBook.local_price(good_id, here)
	token["purse"] = int(token.get("purse", 0)) + price * units
	cargo[good_id] = held - units
	token["cargo"] = cargo
	var have := MarketBook.stock(good_id, here)
	var stored := have + units
	var ceiling := MarketBook.cap(here, good_id)
	if ceiling > 0 and stored > ceiling:
		stored = ceiling
	MarketBook.set_stock(good_id, here, stored)


static func _step_toward(token: Dictionary, dest: String) -> void:
	var here := str(token.get("node_id", ""))
	if here == dest or dest.is_empty():
		return
	var best := ""
	var best_h := 99
	for raw in GameState.neighbors_of(here):
		var nxt := str(raw)
		if not WorldBook.settlement_has_market(nxt) or MarketBook.market_size(nxt) <= 0:
			continue
		var hops := 0 if nxt == dest else MarketBook.hops_between(nxt, dest)
		if hops < best_h or (hops == best_h and (best.is_empty() or nxt < best)):
			best_h = hops
			best = nxt
	if not best.is_empty():
		token["node_id"] = best


static func _held(token: Dictionary, good_id: String) -> int:
	if good_id.is_empty():
		return 0
	return int(token.get("cargo", {}).get(good_id, 0))


static func _empty_cargo() -> Dictionary:
	var cargo: Dictionary = {}
	for good_id in GameState.GOODS.keys():
		cargo[str(good_id)] = 0
	return cargo


static func _market_ids() -> Array:
	var out: Array = []
	for raw in GameState.CITIES.keys():
		var city_id := str(raw)
		if WorldBook.settlement_has_market(city_id) and MarketBook.market_size(city_id) > 0:
			out.append(city_id)
	out.sort()
	return out
