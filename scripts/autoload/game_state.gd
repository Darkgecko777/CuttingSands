extends Node

## Global run state and early market sim.
## World tables live in res://data/world/.

signal scrubstone_changed(new_amount: int)
signal inventory_changed

const DATA_HOUSES := "res://data/world/houses.json"
const DATA_GOODS := "res://data/world/goods.json"
const DATA_SETTLEMENTS := "res://data/world/settlements.json"
const DATA_ROUTES := "res://data/world/routes.json"

const STARTING_SCRUBSTONE := 500
const STARTING_CAPACITY := 16
const SELL_SPREAD := 0.8
const PRICE_PER_HOP := 3
const STOCK_TARGET := 16
const STOCK_BASE := 20

# --- Player / Run data ---
var selected_house_id: String = "house_kharun"
var current_city_id: String = "kharun"
var scrubstone: int = STARTING_SCRUBSTONE
var caravan_capacity: int = STARTING_CAPACITY

# Inventory: good_id -> quantity
var inventory: Dictionary = {}

# Runtime market stock: city_id -> { good_id -> qty }
var market_stock: Dictionary = {}

# --- Loaded world tables ---
var HOUSES: Dictionary = {}
var CITIES: Dictionary = {}
var GOODS: Dictionary = {}
var ROUTES: Dictionary = {} # from -> Array[String]


func _ready() -> void:
	_load_world()
	_reset_player_cargo()
	_seed_all_markets()


func _load_world() -> void:
	HOUSES = _load_json_dict(DATA_HOUSES)
	GOODS = _load_json_dict(DATA_GOODS)
	CITIES = _load_json_dict(DATA_SETTLEMENTS)
	ROUTES = _build_route_graph(_load_json_dict(DATA_ROUTES).get("links", []))

	if HOUSES.is_empty():
		HOUSES = {
			"house_kharun": {
				"name": "House Kharûn",
				"home": "kharun",
				"short_desc": "Scrubstone, contracts, quiet leverage.",
				"available": true,
			}
		}
	if GOODS.is_empty():
		GOODS = {
			"water": {"name": "Water", "base_price": 12, "producer": "sarns_rest", "weight": 1},
			"grain": {"name": "Grain", "base_price": 8, "producer": "veythar", "weight": 1},
			"salt": {"name": "Salt", "base_price": 15, "producer": "zamath", "weight": 1},
			"iron": {"name": "Iron", "base_price": 28, "producer": "kharun", "weight": 1},
			"spices": {"name": "Spices", "base_price": 35, "producer": "ghorath", "weight": 1},
			"cloth": {"name": "Cloth", "base_price": 18, "producer": "thalor", "weight": 1},
		}


func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing world data: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Could not open world data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("World data is not an object: %s" % path)
		return {}
	return parsed


func _build_route_graph(links: Array) -> Dictionary:
	var graph: Dictionary = {}
	for link in links:
		if typeof(link) != TYPE_ARRAY or link.size() < 2:
			continue
		var a := str(link[0])
		var b := str(link[1])
		if not graph.has(a):
			graph[a] = []
		if not graph.has(b):
			graph[b] = []
		if b not in graph[a]:
			graph[a].append(b)
		if a not in graph[b]:
			graph[b].append(a)
	return graph


func _reset_player_cargo() -> void:
	inventory.clear()
	for good_id in GOODS.keys():
		inventory[good_id] = 0
	if inventory.has("water"):
		inventory["water"] = 2
	if inventory.has("grain"):
		inventory["grain"] = 3


func _seed_all_markets() -> void:
	market_stock.clear()
	for city_id in CITIES.keys():
		if not settlement_has_market(city_id):
			continue
		var stocks: Dictionary = {}
		for good_id in GOODS.keys():
			var hops := hops_to_producer(city_id, good_id)
			stocks[good_id] = max(2, STOCK_BASE - hops * 3)
		market_stock[city_id] = stocks


func start_new_run(house_id: String) -> void:
	selected_house_id = house_id
	var house: Dictionary = HOUSES.get(house_id, {})
	current_city_id = str(house.get("home", house.get("home_city", "kharun")))
	scrubstone = STARTING_SCRUBSTONE
	caravan_capacity = STARTING_CAPACITY
	_reset_player_cargo()
	_seed_all_markets()
	scrubstone_changed.emit(scrubstone)
	inventory_changed.emit()


func settlement_has_market(city_id: String) -> bool:
	var city: Dictionary = CITIES.get(city_id, {})
	if city.has("has_market"):
		return bool(city["has_market"])
	return city_id != "sarns_rest"


func hops_to_producer(city_id: String, good_id: String) -> int:
	var producer := str(GOODS.get(good_id, {}).get("producer", city_id))
	return hops_between(city_id, producer)


func hops_between(from_id: String, to_id: String) -> int:
	if from_id == to_id:
		return 0
	if ROUTES.is_empty():
		return 3
	var visited: Dictionary = {from_id: true}
	var queue: Array = [[from_id, 0]]
	while not queue.is_empty():
		var node: Array = queue.pop_front()
		var here: String = node[0]
		var dist: int = node[1]
		for nxt in ROUTES.get(here, []):
			var neighbor := str(nxt)
			if visited.has(neighbor):
				continue
			if neighbor == to_id:
				return dist + 1
			visited[neighbor] = true
			queue.append([neighbor, dist + 1])
	return 6


func cargo_used() -> int:
	var used := 0
	for good_id in inventory.keys():
		var qty: int = int(inventory[good_id])
		var weight: int = int(GOODS.get(good_id, {}).get("weight", 1))
		used += qty * weight
	return used


func cargo_free() -> int:
	return max(0, caravan_capacity - cargo_used())


func get_house_name() -> String:
	return str(HOUSES.get(selected_house_id, {}).get("name", "Unknown House"))


func get_city_name() -> String:
	return str(CITIES.get(current_city_id, {}).get("name", "Unknown City"))


func get_city_desc() -> String:
	var city: Dictionary = CITIES.get(current_city_id, {})
	return str(city.get("short_desc", city.get("desc", "")))


func get_good_name(good_id: String) -> String:
	return str(GOODS.get(good_id, {}).get("name", good_id.capitalize()))


func get_market_stock(good_id: String, city_id: String = "") -> int:
	var cid := current_city_id if city_id.is_empty() else city_id
	return int(market_stock.get(cid, {}).get(good_id, 0))


func get_local_price(good_id: String, city_id: String = "") -> int:
	var cid := current_city_id if city_id.is_empty() else city_id
	var base: int = int(GOODS.get(good_id, {}).get("base_price", 10))
	var hops := hops_to_producer(cid, good_id)
	var stock := get_market_stock(good_id, cid)
	var stock_mod := STOCK_TARGET - stock
	return max(1, base + hops * PRICE_PER_HOP + stock_mod)


func get_sell_price(good_id: String, city_id: String = "") -> int:
	return max(1, int(get_local_price(good_id, city_id) * SELL_SPREAD))


func can_buy(good_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	if not settlement_has_market(current_city_id):
		return false
	if get_market_stock(good_id) < amount:
		return false
	if cargo_used() + amount * int(GOODS.get(good_id, {}).get("weight", 1)) > caravan_capacity:
		return false
	return scrubstone >= get_local_price(good_id) * amount


func buy(good_id: String, amount: int = 1) -> bool:
	if not can_buy(good_id, amount):
		return false
	var price := get_local_price(good_id) * amount
	scrubstone -= price
	inventory[good_id] = inventory.get(good_id, 0) + amount
	market_stock[current_city_id][good_id] = get_market_stock(good_id) - amount
	scrubstone_changed.emit(scrubstone)
	inventory_changed.emit()
	return true


func can_sell(good_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	if not settlement_has_market(current_city_id):
		return false
	return inventory.get(good_id, 0) >= amount


func sell(good_id: String, amount: int = 1) -> bool:
	if not can_sell(good_id, amount):
		return false
	var price := get_sell_price(good_id) * amount
	scrubstone += price
	inventory[good_id] = inventory.get(good_id, 0) - amount
	if not market_stock.has(current_city_id):
		market_stock[current_city_id] = {}
	market_stock[current_city_id][good_id] = get_market_stock(good_id) + amount
	scrubstone_changed.emit(scrubstone)
	inventory_changed.emit()
	return true
