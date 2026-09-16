class_name MarketBook
extends RefCounted

const LOCAL_HOOK := 1.0
const BAND_FLOOR := 0.70
const BAND_CEILING := 1.45

static var _path_cache: Dictionary = {}


static func seed_all() -> void:
	_path_cache.clear()
	GameState.market_stock.clear()
	for city_id in GameState.CITIES.keys():
		var cid := str(city_id)
		var stocks: Dictionary = {}
		for good_id in GameState.GOODS.keys():
			var gid := str(good_id)
			stocks[gid] = _opening_stock(cid, gid)
		GameState.market_stock[cid] = stocks


static func _opening_stock(city_id: String, good_id: String) -> int:
	if can_mint(city_id, good_id):
		return int(floor(float(cap(city_id, good_id)) * 0.6))
	if WorldBook.is_shared_good(good_id):
		if str(GameState.CITIES.get(city_id, {}).get("type", "")) != "trading_post":
			return 0
		if not WorldBook.settlement_has_market(city_id) or market_size(city_id) <= 0:
			return 0
		return maxi(1, int(floor(float(cap(city_id, good_id)) * 0.40)))
	if not WorldBook.settlement_has_market(city_id) or market_size(city_id) <= 0:
		return 0
	var origin := WorldBook.producer_id(good_id)
	if origin.is_empty():
		return 0
	var hops := hops_between(origin, city_id)
	var sliver := 0.0
	if hops == 1:
		sliver = 0.25
	elif hops == 2:
		sliver = 0.12
	else:
		return 0
	return maxi(1, int(floor(float(cap(city_id, good_id)) * sliver)))


static func tick_day() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	tick_produce(rng)
	tick_consume(rng)


static func tick_produce(rng: RandomNumberGenerator) -> void:
	_produce_all(rng)


static func tick_consume(rng: RandomNumberGenerator) -> void:
	_consume_all(rng)


static func stock(good_id: String, city_id: String = "") -> int:
	var cid := GameState.current_city_id if city_id.is_empty() else city_id
	return int(GameState.market_stock.get(cid, {}).get(good_id, 0))


static func set_stock(good_id: String, city_id: String, units: int) -> void:
	if not GameState.market_stock.has(city_id):
		GameState.market_stock[city_id] = {}
	var row: Dictionary = GameState.market_stock[city_id]
	row[good_id] = maxi(0, units)


static func market_size(city_id: String) -> int:
	return maxi(0, int(GameState.CITIES.get(city_id, {}).get("market_size", 0)))


static func is_origin(city_id: String, good_id: String) -> bool:
	return WorldBook.producer_id(good_id) == city_id


static func can_mint(city_id: String, good_id: String) -> bool:
	if WorldBook.is_shared_good(good_id):
		var mint := WorldBook.local_mint(city_id, good_id)
		return int(mint.get("produce_max", 0)) > 0 or int(mint.get("produce_min", 0)) > 0
	return is_origin(city_id, good_id)


static func produce_mean(good_id: String, city_id: String = "") -> float:
	var lo := 0
	var hi := 0
	if WorldBook.is_shared_good(good_id) and not city_id.is_empty():
		var mint := WorldBook.local_mint(city_id, good_id)
		lo = int(mint.get("produce_min", 0))
		hi = int(mint.get("produce_max", lo))
	else:
		var rec: Dictionary = GameState.GOODS.get(good_id, {})
		lo = int(rec.get("produce_min", 0))
		hi = int(rec.get("produce_max", lo))
	if hi < lo:
		hi = lo
	return (float(lo) + float(hi)) * 0.5


static func cap(city_id: String, good_id: String) -> int:
	var mean := produce_mean(good_id, city_id)
	if mean <= 0.0:
		mean = 1.0
	var size := market_size(city_id)
	if can_mint(city_id, good_id):
		return maxi(1, int(round(mean * 8.0 * maxf(1.0, float(size) / 4.0))))
	if size <= 0:
		return 0
	return maxi(1, int(round(mean * 4.0 * maxf(1.0, float(size) / 5.0))))


static func hops_between(from_id: String, to_id: String) -> int:
	return _route_stats(from_id, to_id).x


static func hops_to_producer(city_id: String, good_id: String) -> int:
	return hops_between(WorldBook.producer_id(good_id), city_id)


static func local_price(good_id: String, city_id: String = "") -> int:
	var cid := GameState.current_city_id if city_id.is_empty() else city_id
	var rec: Dictionary = GameState.GOODS.get(good_id, {})
	var cellar := cap(cid, good_id)
	var have := stock(good_id, cid)
	var filled := 0.0 if cellar <= 0 else clampf(float(have) / float(cellar), 0.0, 1.0)
	var scarcity := lerpf(1.35, 0.70, filled)
	var quirk := _quirk(cid, good_id)
	var raw := 1
	var floor_p := 1
	var ceil_p := 1
	if WorldBook.is_shared_good(good_id):
		var base := WorldBook.local_base(cid, good_id)
		raw = maxi(1, int(round(float(base) * scarcity * LOCAL_HOOK * quirk)))
		floor_p = maxi(1, int(round(float(base) * BAND_FLOOR * quirk)))
		ceil_p = maxi(floor_p, int(round(float(base) * BAND_CEILING * quirk)))
	else:
		var base: int = int(rec.get("base_origin_price", rec.get("base_price", 10)))
		var origin := WorldBook.producer_id(good_id)
		var stats := _route_stats(origin, cid)
		var hops: int = stats.x
		var gravity: int = stats.y
		var distance := 1.0 + 0.22 * float(hops)
		var absorb := 1.0 + 0.04 * float(gravity)
		var mid := float(base) * distance * absorb * quirk
		raw = maxi(1, int(round(float(base) * scarcity * distance * absorb * LOCAL_HOOK * quirk)))
		floor_p = maxi(1, int(round(mid * BAND_FLOOR)))
		ceil_p = maxi(floor_p, int(round(mid * BAND_CEILING)))
	return clampi(raw, floor_p, ceil_p)


static func sell_price(good_id: String, city_id: String = "") -> int:
	return local_price(good_id, city_id)


static func _quirk(city_id: String, good_id: String) -> float:
	var city: Dictionary = GameState.CITIES.get(city_id, {})
	var quirks: Variant = city.get("price_quirks", {})
	if typeof(quirks) != TYPE_DICTIONARY or not quirks.has(good_id):
		return 1.0
	return maxf(0.01, float(quirks[good_id]))


static func _produce_all(rng: RandomNumberGenerator) -> void:
	for city_id in GameState.CITIES.keys():
		var cid := str(city_id)
		for good_id in GameState.GOODS.keys():
			var gid := str(good_id)
			if not can_mint(cid, gid):
				continue
			var lo := 0
			var hi := 0
			if WorldBook.is_shared_good(gid):
				var mint := WorldBook.local_mint(cid, gid)
				lo = int(mint.get("produce_min", 0))
				hi = int(mint.get("produce_max", lo))
			else:
				var rec: Dictionary = GameState.GOODS.get(gid, {})
				lo = int(rec.get("produce_min", 0))
				hi = int(rec.get("produce_max", lo))
			if hi < lo:
				hi = lo
			var delta := rng.randi_range(lo, hi)
			var room := cap(cid, gid) - stock(gid, cid)
			delta = clampi(delta, 0, maxi(0, room))
			if delta > 0:
				set_stock(gid, cid, stock(gid, cid) + delta)


static func _consume_all(rng: RandomNumberGenerator) -> void:
	for city_id in GameState.CITIES.keys():
		var cid := str(city_id)
		if market_size(cid) <= 0:
			continue
		for good_id in GameState.GOODS.keys():
			var gid := str(good_id)
			var have := stock(gid, cid)
			if have <= 0:
				continue
			var rec: Dictionary = GameState.GOODS.get(gid, {})
			var want := float(market_size(cid)) * _consume_weight(gid, cid)
			var rate := float(rec.get("consume_rate", 0.08))
			var raw := want * rate * rng.randf_range(0.7, 1.3)
			var units := clampi(int(round(raw)), 0, have)
			if units > 0:
				set_stock(gid, cid, have - units)


static func _consume_weight(good_id: String, city_id: String) -> float:
	if can_mint(city_id, good_id):
		return 0.15
	var band := str(GameState.GOODS.get(good_id, {}).get("band", "industrial"))
	if band == "craft":
		band = "industrial"
	var kind := str(GameState.CITIES.get(city_id, {}).get("type", ""))
	if kind == "city" or kind == "stronghold":
		match band:
			"staple":
				return 1.0
			"prestige":
				return 0.35
			_:
				return 0.55
	if kind == "village":
		match band:
			"staple":
				return 0.7
			"prestige":
				return 0.1
			_:
				return 0.25
	if kind == "trading_post":
		match band:
			"staple":
				return 0.4
			"prestige":
				return 0.05
			_:
				return 0.15
	return 0.0


static func _route_stats(origin: String, node: String) -> Vector2i:
	if origin.is_empty() or node.is_empty():
		return Vector2i(0, 0)
	if origin == node:
		return Vector2i(0, 0)
	var key := origin + ">" + node
	if _path_cache.has(key):
		return _path_cache[key]
	if GameState.ROUTES.is_empty():
		var fallback := Vector2i(3, 0)
		_path_cache[key] = fallback
		return fallback
	var best: Dictionary = {}
	var queue: Array = [[origin, 0, 0]]
	best[origin] = Vector2i(0, 0)
	while not queue.is_empty():
		var item: Array = queue.pop_front()
		var here: String = item[0]
		var hops: int = item[1]
		var gravity: int = item[2]
		var known: Vector2i = best.get(here, Vector2i(99, 0))
		if hops > known.x or (hops == known.x and gravity < known.y):
			continue
		for nxt in GameState.ROUTES.get(here, []):
			var neighbor := str(nxt)
			var add_g := 0 if here == origin else market_size(here)
			var new_hops := hops + 1
			var new_g := gravity + add_g
			if best.has(neighbor):
				var prior: Vector2i = best[neighbor]
				if new_hops > prior.x:
					continue
				if new_hops == prior.x and new_g <= prior.y:
					continue
			best[neighbor] = Vector2i(new_hops, new_g)
			queue.append([neighbor, new_hops, new_g])
	var result: Vector2i = best.get(node, Vector2i(6, 0))
	_path_cache[key] = result
	return result
