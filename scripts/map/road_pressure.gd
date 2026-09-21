class_name RoadPressure
extends RefCounted

const WEATHER_TERMS := ["Clear", "Heat", "Wind", "Sandstorm"]
# Hood order matches WEATHER_TERMS. Clear never leaks.
const LEAK_CHANCE: Array[float] = [0.0, 0.25, 0.20, 0.40]
const LEAK_UNITS: Array[int] = [0, 1, 1, 2]


static func seed_pressures() -> void:
	GameState.LINK_WEATHER = {}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var weather_by_country: Dictionary = {}
	for key in GameState.LINK_DAYS.keys():
		var parts: PackedStringArray = str(key).split("|")
		if parts.size() < 2:
			continue
		var country := _country_key(str(parts[0]), str(parts[1]))
		if not weather_by_country.has(country):
			weather_by_country[country] = _roll_weather(rng)
		GameState.LINK_WEATHER[key] = int(weather_by_country[country])


static func weather(from_id: String, to_id: String) -> int:
	return clampi(int(GameState.LINK_WEATHER.get(GameState._link_key(from_id, to_id), 0)), 0, 3)


static func weather_term(from_id: String, to_id: String) -> String:
	return WEATHER_TERMS[weather(from_id, to_id)]


static func route_words(from_id: String, to_id: String) -> String:
	return weather_term(from_id, to_id)


static func extra_days(from_id: String, to_id: String) -> int:
	var w := weather(from_id, to_id)
	if w <= 0:
		return 0
	if w <= 2:
		return 1
	return 2


static func resolve_hop(from_id: String, to_id: String) -> String:
	var note := "The road was %s." % weather_term(from_id, to_id).to_lower()
	var loss := _leak_rack(weather(from_id, to_id))
	if not loss.is_empty():
		note = "%s %s" % [note, loss]
	GameState.road_note = note
	if not loss.is_empty():
		GameState.inventory_changed.emit()
	return note


# Undirected region pair. Both directions of an edge share one term.
static func _country_key(a: String, b: String) -> String:
	var ra := str(GameState.CITIES.get(a, {}).get("region", a))
	var rb := str(GameState.CITIES.get(b, {}).get("region", b))
	return ra + "|" + rb if ra < rb else rb + "|" + ra


static func _roll_weather(rng: RandomNumberGenerator) -> int:
	var roll := rng.randf()
	if roll < 0.40:
		return 0
	if roll < 0.70:
		return 1
	if roll < 0.90:
		return 2
	return 3


static func _leak_rack(w: int) -> String:
	if w <= 0 or w >= LEAK_UNITS.size():
		return ""
	var units := LEAK_UNITS[w]
	if units <= 0 or LEAK_CHANCE[w] <= 0.0:
		return ""
	var roomy: Array[String] = []
	var any_stock: Array[String] = []
	for good_id in GameState.inventory.keys():
		var have := int(GameState.inventory[good_id])
		if have <= 0:
			continue
		var gid := str(good_id)
		any_stock.append(gid)
		if have >= units:
			roomy.append(gid)
	var pool: Array[String] = roomy if not roomy.is_empty() else any_stock
	if pool.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if rng.randf() >= LEAK_CHANCE[w]:
		return ""
	var pick: String = pool[rng.randi_range(0, pool.size() - 1)]
	var held := int(GameState.inventory[pick])
	var cut := mini(units, held)
	GameState.inventory[pick] = held - cut
	return "Lost %d %s." % [cut, WorldBook.good_name(pick)]
