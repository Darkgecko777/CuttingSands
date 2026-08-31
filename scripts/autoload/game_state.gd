extends Node

signal scrubstone_changed(new_amount: int)
signal inventory_changed
signal location_changed(city_id: String)
signal catalog_changed

const DATA_HOUSES := "res://data/world/houses.json"
const DATA_GOODS := "res://data/world/goods.json"
const DATA_SETTLEMENTS := "res://data/world/settlements.json"
const DATA_ROUTES := "res://data/world/routes.json"
const STARTING_SCRUBSTONE := 500
const STARTING_CAPACITY := 16
const SELL_SPREAD := 0.85
const PRICE_PER_HOP := 5
const STOCK_TARGET := 16
const STOCK_BASE := 20
const PRODUCER_STOCK_BONUS := 12
const PLAYER_CARAVAN_ID := "player_caravan"
const PLAYER_CARAVAN_NAME := "House Caravan"
const CARAVAN_SPEED := 1.0

var selected_house_id: String = "house_kharun"
var current_city_id: String = "kharun"
var focused_caravan_id: String = PLAYER_CARAVAN_ID
var scrubstone: int = STARTING_SCRUBSTONE
var caravan_capacity: int = STARTING_CAPACITY
var day: int = 1
var agents: Array = []
var reports: Array = []
var LINK_DAYS: Dictionary = {}
var transit: Dictionary = {}
var inventory: Dictionary = {}
var market_stock: Dictionary = {}
var HOUSES: Dictionary = {}
var CITIES: Dictionary = {}
var GOODS: Dictionary = {}
var ROUTES: Dictionary = {}
var caravans: Dictionary = {}
var pending_travel_to: String = ""


func _ready() -> void:
	_load_world()
	_reset_player_cargo()
	_seed_all_markets()
	_spawn_player_caravan(current_city_id)


func _load_world() -> void:
	HOUSES = _load_json_dict(DATA_HOUSES)
	GOODS = _load_json_dict(DATA_GOODS)
	CITIES = _load_json_dict(DATA_SETTLEMENTS)
	_load_routes(_load_json_dict(DATA_ROUTES).get("links", []))
	if HOUSES.is_empty():
		HOUSES = {"house_kharun": {"name": "House Kharûn", "home": "kharun", "short_desc": "Scrubstone, contracts, quiet leverage.", "available": true}}
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
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _load_routes(links: Array) -> void:
	ROUTES = {}
	LINK_DAYS = {}
	for link in links:
		var a := ""
		var b := ""
		var days := 1
		if typeof(link) == TYPE_ARRAY and link.size() >= 2:
			a = str(link[0])
			b = str(link[1])
			if link.size() >= 3:
				days = int(link[2])
		elif typeof(link) == TYPE_DICTIONARY:
			a = str(link.get("from", ""))
			b = str(link.get("to", ""))
			days = int(link.get("days", 1))
		else:
			continue
		if a.is_empty() or b.is_empty() or a == b:
			continue
		if not ROUTES.has(a):
			ROUTES[a] = []
		if not ROUTES.has(b):
			ROUTES[b] = []
		if b not in ROUTES[a]:
			ROUTES[a].append(b)
		if a not in ROUTES[b]:
			ROUTES[b].append(a)
		LINK_DAYS[_link_key(a, b)] = max(1, days)


func _link_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


func _empty_cargo() -> Dictionary:
	var cargo: Dictionary = {}
	for good_id in GOODS.keys():
		cargo[good_id] = 0
	if cargo.has("water"):
		cargo["water"] = 2
	if cargo.has("grain"):
		cargo["grain"] = 3
	return cargo


func _spawn_player_caravan(at_city: String) -> void:
	var city_id := at_city if CITIES.has(at_city) else "kharun"
	caravans[PLAYER_CARAVAN_ID] = {
		"id": PLAYER_CARAVAN_ID,
		"name": PLAYER_CARAVAN_NAME,
		"owner": "house",
		"house_id": selected_house_id,
		"status": "idle",
		"at": city_id,
		"from": "",
		"to": "",
		"days": 0,
		"progress": 0.0,
		"speed": CARAVAN_SPEED,
		"capacity": STARTING_CAPACITY,
		"cargo": inventory,
	}
	focused_caravan_id = PLAYER_CARAVAN_ID
	_sync_player_views()


func _sync_player_views() -> void:
	var wagon: Dictionary = get_caravan(PLAYER_CARAVAN_ID)
	if wagon.is_empty():
		return
	inventory = wagon.get("cargo", inventory)
	caravan_capacity = int(wagon.get("capacity", STARTING_CAPACITY))
	if str(wagon.get("status", "idle")) == "transit":
		current_city_id = str(wagon.get("from", current_city_id))
		transit = {
			"from": str(wagon.get("from", "")),
			"to": str(wagon.get("to", "")),
			"days": int(wagon.get("days", 1)),
		}
	else:
		current_city_id = str(wagon.get("at", current_city_id))
		transit = {}


func get_caravan(caravan_id: String) -> Dictionary:
	var record: Variant = caravans.get(caravan_id, {})
	return record if typeof(record) == TYPE_DICTIONARY else {}


func list_caravans() -> Array:
	var items: Array = []
	for caravan_id in caravans.keys():
		var record: Dictionary = get_caravan(caravan_id)
		if record.is_empty():
			continue
		items.append({
			"kind": "caravan",
			"id": str(record.get("id", caravan_id)),
			"name": str(record.get("name", caravan_id)),
		})
	return items


func caravan_status(caravan_id: String) -> String:
	return str(get_caravan(caravan_id).get("status", "idle"))


func caravan_city(caravan_id: String) -> String:
	var wagon: Dictionary = get_caravan(caravan_id)
	if wagon.is_empty():
		return current_city_id
	if str(wagon.get("status", "idle")) == "transit":
		return str(wagon.get("from", current_city_id))
	return str(wagon.get("at", current_city_id))


func set_caravan_progress(caravan_id: String, progress: float) -> void:
	if not caravans.has(caravan_id):
		return
	caravans[caravan_id]["progress"] = clampf(progress, 0.0, 1.0)


func is_adjacent(a: String, b: String) -> bool:
	return b in ROUTES.get(a, [])


func neighbors_of(city_id: String) -> Array:
	var raw: Variant = ROUTES.get(city_id, [])
	return raw if typeof(raw) == TYPE_ARRAY else []


func hop_days(from_id: String, to_id: String) -> int:
	if not is_adjacent(from_id, to_id):
		return 0
	return max(1, int(ceil(float(LINK_DAYS.get(_link_key(from_id, to_id), 1)) / max(CARAVAN_SPEED, 0.1))))


func is_on_road() -> bool:
	return caravan_status(PLAYER_CARAVAN_ID) == "transit" or not transit.is_empty()


func begin_hop(to_id: String) -> bool:
	return begin_hop_for(PLAYER_CARAVAN_ID, to_id)


func begin_hop_for(caravan_id: String, to_id: String) -> bool:
	var wagon: Dictionary = get_caravan(caravan_id)
	if wagon.is_empty() or str(wagon.get("status", "idle")) == "transit":
		return false
	var from_id := str(wagon.get("at", ""))
	var days := hop_days(from_id, to_id)
	if days <= 0:
		return false
	wagon["status"] = "transit"
	wagon["from"] = from_id
	wagon["to"] = to_id
	wagon["days"] = days
	wagon["progress"] = 0.0
	pending_travel_to = ""
	if caravan_id == PLAYER_CARAVAN_ID:
		_sync_player_views()
	return true


func finish_hop() -> bool:
	return finish_hop_for(PLAYER_CARAVAN_ID)


func finish_hop_for(caravan_id: String) -> bool:
	var wagon: Dictionary = get_caravan(caravan_id)
	if wagon.is_empty() or str(wagon.get("status", "idle")) != "transit":
		return false
	var to_id := str(wagon.get("to", ""))
	var days := int(wagon.get("days", 1))
	wagon["status"] = "idle"
	wagon["at"] = to_id
	wagon["from"] = ""
	wagon["to"] = ""
	wagon["days"] = 0
	wagon["progress"] = 0.0
	day += days
	if caravan_id == PLAYER_CARAVAN_ID:
		_sync_player_views()
		return travel_to(to_id)
	return CITIES.has(to_id)


func _reset_player_cargo() -> void:
	inventory = _empty_cargo()
	if caravans.has(PLAYER_CARAVAN_ID):
		caravans[PLAYER_CARAVAN_ID]["cargo"] = inventory
		caravans[PLAYER_CARAVAN_ID]["capacity"] = caravan_capacity


func _seed_all_markets() -> void:
	market_stock.clear()
	for city_id in CITIES.keys():
		if not settlement_has_market(city_id):
			continue
		var stocks: Dictionary = {}
		for good_id in GOODS.keys():
			var hops := hops_to_producer(city_id, good_id)
			var stock := STOCK_BASE - hops * 4
			if hops == 0:
				stock += PRODUCER_STOCK_BONUS
			stocks[good_id] = max(2, stock)
		market_stock[city_id] = stocks


func start_new_run(house_id: String) -> void:
	selected_house_id = house_id
	var house: Dictionary = HOUSES.get(house_id, {})
	current_city_id = str(house.get("home", house.get("home_city", "kharun")))
	scrubstone = STARTING_SCRUBSTONE
	caravan_capacity = STARTING_CAPACITY
	focused_caravan_id = PLAYER_CARAVAN_ID
	pending_travel_to = ""
	_reset_player_cargo()
	_seed_all_markets()
	day = 1
	agents.clear()
	reports.clear()
	_spawn_player_caravan(current_city_id)
	scrubstone_changed.emit(scrubstone)
	inventory_changed.emit()
	location_changed.emit(current_city_id)
	catalog_changed.emit()


func settlement_has_market(city_id: String) -> bool:
	var city: Dictionary = CITIES.get(city_id, {})
	if city.has("has_market"):
		return bool(city["has_market"])
	return city_id != "sarns_rest"


func hops_to_producer(city_id: String, good_id: String) -> int:
	return hops_between(city_id, str(GOODS.get(good_id, {}).get("producer", city_id)))


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
		used += int(inventory[good_id]) * int(GOODS.get(good_id, {}).get("weight", 1))
	return used


func cargo_free() -> int:
	return max(0, caravan_capacity - cargo_used())


func get_house_name() -> String:
	return str(HOUSES.get(selected_house_id, {}).get("name", "Unknown House"))


func get_city_name() -> String:
	return get_settlement_name(current_city_id)


func get_settlement_name(city_id: String) -> String:
	return str(CITIES.get(city_id, {}).get("name", city_id.capitalize()))


func travel_to(city_id: String) -> bool:
	if city_id.is_empty() or not CITIES.has(city_id):
		return false
	if caravans.has(PLAYER_CARAVAN_ID) and str(get_caravan(PLAYER_CARAVAN_ID).get("status", "idle")) != "transit":
		caravans[PLAYER_CARAVAN_ID]["at"] = city_id
	if city_id == current_city_id:
		location_changed.emit(city_id)
		inventory_changed.emit()
		return true
	current_city_id = city_id
	location_changed.emit(city_id)
	inventory_changed.emit()
	return true


func get_city_desc() -> String:
	var city: Dictionary = CITIES.get(current_city_id, {})
	return str(city.get("short_desc", city.get("desc", "")))


func get_good_name(good_id: String) -> String:
	return str(GOODS.get(good_id, {}).get("name", good_id.capitalize()))


func get_producer_id(good_id: String) -> String:
	return str(GOODS.get(good_id, {}).get("producer", ""))


func get_producer_name(good_id: String) -> String:
	return get_settlement_name(get_producer_id(good_id))


func get_market_stock(good_id: String, city_id: String = "") -> int:
	var cid := current_city_id if city_id.is_empty() else city_id
	return int(market_stock.get(cid, {}).get(good_id, 0))


func get_local_price(good_id: String, city_id: String = "") -> int:
	var cid := current_city_id if city_id.is_empty() else city_id
	var base: int = int(GOODS.get(good_id, {}).get("base_price", 10))
	return max(1, base + hops_to_producer(cid, good_id) * PRICE_PER_HOP + (STOCK_TARGET - get_market_stock(good_id, cid)))


func get_sell_price(good_id: String, city_id: String = "") -> int:
	return max(1, int(round(get_local_price(good_id, city_id) * SELL_SPREAD)))


func can_buy(good_id: String, amount: int = 1) -> bool:
	if amount <= 0 or not settlement_has_market(current_city_id) or is_on_road():
		return false
	if get_market_stock(good_id) < amount:
		return false
	if cargo_used() + amount * int(GOODS.get(good_id, {}).get("weight", 1)) > caravan_capacity:
		return false
	return scrubstone >= get_local_price(good_id) * amount


func buy(good_id: String, amount: int = 1) -> bool:
	if not can_buy(good_id, amount):
		return false
	scrubstone -= get_local_price(good_id) * amount
	inventory[good_id] = inventory.get(good_id, 0) + amount
	market_stock[current_city_id][good_id] = get_market_stock(good_id) - amount
	scrubstone_changed.emit(scrubstone)
	inventory_changed.emit()
	return true


func can_sell(good_id: String, amount: int = 1) -> bool:
	return amount > 0 and settlement_has_market(current_city_id) and not is_on_road() and inventory.get(good_id, 0) >= amount


func sell(good_id: String, amount: int = 1) -> bool:
	if not can_sell(good_id, amount):
		return false
	scrubstone += get_sell_price(good_id) * amount
	inventory[good_id] = inventory.get(good_id, 0) - amount
	if not market_stock.has(current_city_id):
		market_stock[current_city_id] = {}
	market_stock[current_city_id][good_id] = get_market_stock(good_id) + amount
	scrubstone_changed.emit(scrubstone)
	inventory_changed.emit()
	return true
