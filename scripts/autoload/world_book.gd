class_name WorldBook
extends RefCounted

const DATA_HOUSES := "res://data/world/houses.json"
const DATA_GOODS := "res://data/world/goods.json"
const DATA_SETTLEMENTS := "res://data/world/settlements.json"
const DATA_ROUTES := "res://data/world/routes.json"


static func load_world() -> void:
	GameState.HOUSES = _json_dict(DATA_HOUSES)
	GameState.GOODS = _json_dict(DATA_GOODS)
	GameState.CITIES = _json_dict(DATA_SETTLEMENTS)
	_load_routes(_json_dict(DATA_ROUTES).get("links", []))
	if GameState.HOUSES.is_empty():
		GameState.HOUSES = {"house_kharun": {"name": "House Kharûn", "home": "kharun", "short_desc": "Scrubstone, contracts, quiet leverage.", "available": true}}
	if GameState.GOODS.is_empty():
		GameState.GOODS = {
			"water": {"name": "Water", "base_price": 12, "producer": "sarns_rest", "size": 3, "mass": 4},
			"grain": {"name": "Grain", "base_price": 8, "producer": "veythar", "size": 2, "mass": 1},
			"salt": {"name": "Salt", "base_price": 15, "producer": "zamath", "size": 2, "mass": 2},
			"iron": {"name": "Iron", "base_price": 28, "producer": "kharun", "size": 2, "mass": 5},
			"spices": {"name": "Spices", "base_price": 35, "producer": "ghorath", "size": 1, "mass": 1},
			"cloth": {"name": "Cloth", "base_price": 18, "producer": "thalor", "size": 1, "mass": 1},
		}


static func _json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func _load_routes(links: Array) -> void:
	GameState.ROUTES = {}
	GameState.LINK_DAYS = {}
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
		if not GameState.ROUTES.has(a):
			GameState.ROUTES[a] = []
		if not GameState.ROUTES.has(b):
			GameState.ROUTES[b] = []
		if b not in GameState.ROUTES[a]:
			GameState.ROUTES[a].append(b)
		if a not in GameState.ROUTES[b]:
			GameState.ROUTES[b].append(a)
		GameState.LINK_DAYS[GameState._link_key(a, b)] = max(1, days)


static func settlement_has_market(city_id: String) -> bool:
	var city: Dictionary = GameState.CITIES.get(city_id, {})
	if city.has("has_market"):
		return bool(city["has_market"])
	return city_id != "sarns_rest"


static func settlement_has_house_yard(city_id: String) -> bool:
	var city: Dictionary = GameState.CITIES.get(city_id, {})
	var raw: Variant = city.get("house", "")
	if raw == null:
		return false
	var seat := str(raw)
	if seat.is_empty() or seat == "null" or seat == "<null>":
		return false
	var kind := str(city.get("type", ""))
	return kind == "city" or kind == "stronghold"


static func settlement_name(city_id: String) -> String:
	return str(GameState.CITIES.get(city_id, {}).get("name", city_id.capitalize()))


static func house_name(house_id: String) -> String:
	return str(GameState.HOUSES.get(house_id, {}).get("name", "Unknown House"))


static func good_name(good_id: String) -> String:
	return str(GameState.GOODS.get(good_id, {}).get("name", good_id.capitalize()))


static func producer_id(good_id: String) -> String:
	var rec: Dictionary = GameState.GOODS.get(good_id, {})
	var listed: Variant = rec.get("producers", [])
	if typeof(listed) == TYPE_ARRAY and listed.size() > 0:
		return str(listed[0])
	return str(rec.get("producer", ""))
