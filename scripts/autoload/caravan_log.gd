class_name CaravanLog
extends RefCounted


static func spawn_player(at_city: String) -> void:
	var city_id := at_city if GameState.CITIES.has(at_city) else "kharun"
	GameState.caravans[GameState.PLAYER_CARAVAN_ID] = {
		"id": GameState.PLAYER_CARAVAN_ID,
		"name": GameState.PLAYER_CARAVAN_NAME,
		"owner": "house",
		"house_id": GameState.selected_house_id,
		"status": "idle",
		"at": city_id,
		"from": "",
		"to": "",
		"days": 0,
		"progress": 0.0,
		"speed": GameState.CARAVAN_SPEED,
		"capacity": GameState.STARTING_CAPACITY,
		"cargo": GameState.inventory,
	}
	GameState.focused_caravan_id = GameState.PLAYER_CARAVAN_ID
	sync_player()


static func record(caravan_id: String) -> Dictionary:
	var raw: Variant = GameState.caravans.get(caravan_id, {})
	return raw if typeof(raw) == TYPE_DICTIONARY else {}


static func sync_player() -> void:
	var wagon: Dictionary = record(GameState.PLAYER_CARAVAN_ID)
	if wagon.is_empty():
		return
	GameState.inventory = wagon.get("cargo", GameState.inventory)
	GameState.caravan_capacity = int(wagon.get("capacity", GameState.STARTING_CAPACITY))
	if str(wagon.get("status", "idle")) == "transit":
		GameState.current_city_id = str(wagon.get("from", GameState.current_city_id))
		GameState.transit = {
			"from": str(wagon.get("from", "")),
			"to": str(wagon.get("to", "")),
			"days": int(wagon.get("days", 1)),
		}
	else:
		GameState.current_city_id = str(wagon.get("at", GameState.current_city_id))
		GameState.transit = {}


static func is_adjacent(a: String, b: String) -> bool:
	return b in GameState.ROUTES.get(a, [])


static func neighbors_of(city_id: String) -> Array:
	var raw: Variant = GameState.ROUTES.get(city_id, [])
	return raw if typeof(raw) == TYPE_ARRAY else []


static func hop_days(from_id: String, to_id: String) -> int:
	if not is_adjacent(from_id, to_id):
		return 0
	return max(1, int(ceil(float(GameState.LINK_DAYS.get(GameState._link_key(from_id, to_id), 1)) / max(GameState.CARAVAN_SPEED, 0.1))))


static func begin_hop_for(caravan_id: String, to_id: String) -> bool:
	var wagon: Dictionary = record(caravan_id)
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
	GameState.pending_travel_to = ""
	if caravan_id == GameState.PLAYER_CARAVAN_ID:
		sync_player()
	return true


static func finish_hop_for(caravan_id: String) -> bool:
	var wagon: Dictionary = record(caravan_id)
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
	GameState.day += days
	if caravan_id == GameState.PLAYER_CARAVAN_ID:
		sync_player()
		return GameState.travel_to(to_id)
	return GameState.CITIES.has(to_id)
