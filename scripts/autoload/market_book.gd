class_name MarketBook
extends RefCounted


static func seed_all() -> void:
	GameState.market_stock.clear()
	for city_id in GameState.CITIES.keys():
		if not GameState.settlement_has_market(city_id):
			continue
		var stocks: Dictionary = {}
		for good_id in GameState.GOODS.keys():
			var hops := hops_to_producer(city_id, str(good_id))
			var stock := GameState.STOCK_BASE - hops * 4
			if hops == 0:
				stock += GameState.PRODUCER_STOCK_BONUS
			stocks[good_id] = max(2, stock)
		GameState.market_stock[city_id] = stocks


static func hops_between(from_id: String, to_id: String) -> int:
	if from_id == to_id:
		return 0
	if GameState.ROUTES.is_empty():
		return 3
	var visited: Dictionary = {from_id: true}
	var queue: Array = [[from_id, 0]]
	while not queue.is_empty():
		var node: Array = queue.pop_front()
		var here: String = node[0]
		var dist: int = node[1]
		for nxt in GameState.ROUTES.get(here, []):
			var neighbor := str(nxt)
			if visited.has(neighbor):
				continue
			if neighbor == to_id:
				return dist + 1
			visited[neighbor] = true
			queue.append([neighbor, dist + 1])
	return 6


static func hops_to_producer(city_id: String, good_id: String) -> int:
	return hops_between(city_id, GameState.get_producer_id(good_id))


static func stock(good_id: String, city_id: String = "") -> int:
	var cid := GameState.current_city_id if city_id.is_empty() else city_id
	return int(GameState.market_stock.get(cid, {}).get(good_id, 0))


static func local_price(good_id: String, city_id: String = "") -> int:
	var cid := GameState.current_city_id if city_id.is_empty() else city_id
	var base: int = int(GameState.GOODS.get(good_id, {}).get("base_price", 10))
	return max(1, base + hops_to_producer(cid, good_id) * GameState.PRICE_PER_HOP + (GameState.STOCK_TARGET - stock(good_id, cid)))


static func sell_price(good_id: String, city_id: String = "") -> int:
	return max(1, int(round(local_price(good_id, city_id) * GameState.SELL_SPREAD)))
