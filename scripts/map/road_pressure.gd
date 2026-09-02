class_name RoadPressure
extends RefCounted

const WEATHER_TERMS := ["Clear", "Heat", "Wind", "Sandstorm"]
const HEAT_TERMS := ["Quiet", "Watched", "Active"]
const TITHE_RATE := 0.10
const TITHE_CHANCE := [0.10, 0.30, 0.55]


static func seed_pressures() -> void:
	GameState.LINK_WEATHER = {}
	GameState.LINK_HEAT = {}
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
		GameState.LINK_HEAT[key] = _roll_heat(rng)


static func weather(from_id: String, to_id: String) -> int:
	return clampi(int(GameState.LINK_WEATHER.get(GameState._link_key(from_id, to_id), 0)), 0, 3)


static func heat(from_id: String, to_id: String) -> int:
	return clampi(int(GameState.LINK_HEAT.get(GameState._link_key(from_id, to_id), 0)), 0, 2)


static func weather_term(from_id: String, to_id: String) -> String:
	return WEATHER_TERMS[weather(from_id, to_id)]


static func heat_term(from_id: String, to_id: String) -> String:
	return HEAT_TERMS[heat(from_id, to_id)]


static func route_words(from_id: String, to_id: String) -> String:
	return "%s · %s" % [weather_term(from_id, to_id), heat_term(from_id, to_id)]


static func extra_days(from_id: String, to_id: String) -> int:
	var w := weather(from_id, to_id)
	if w <= 0:
		return 0
	if w <= 2:
		return 1
	return 2


static func resolve_hop(from_id: String, to_id: String) -> String:
	var w := weather(from_id, to_id)
	var note := "The road was %s, the artery %s." % [weather_term(from_id, to_id).to_lower(), heat_term(from_id, to_id).to_lower()]
	if w >= 3:
		note = "Sandstorm on the hop. The wagon took the long way."
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if rng.randf() > TITHE_CHANCE[heat(from_id, to_id)]:
		GameState.road_note = note
		return note
	var cut := _take_tithe()
	if cut.is_empty():
		GameState.road_note = note
		return note
	note = "A marked tithe on a %s road. %s" % [heat_term(from_id, to_id), cut]
	GameState.road_note = note
	return note


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


static func _roll_heat(rng: RandomNumberGenerator) -> int:
	var roll := rng.randf()
	if roll < 0.50:
		return 0
	if roll < 0.82:
		return 1
	return 2


static func _take_tithe() -> String:
	var purse := GameState.scrubstone
	var take_coin := purse > 0
	if take_coin and CargoHold.cells() > 0:
		take_coin = randf() < 0.5
	if take_coin and purse > 0:
		var cut: int = maxi(1, int(floor(float(purse) * TITHE_RATE)))
		cut = mini(cut, purse)
		GameState.scrubstone -= cut
		GameState.scrubstone_changed.emit(GameState.scrubstone)
		return "They took %d scrubstone." % cut
	var choices: Array[String] = []
	for good_id in GameState.inventory.keys():
		if int(GameState.inventory[good_id]) > 0:
			choices.append(str(good_id))
	if choices.is_empty():
		return ""
	var good_id: String = choices[randi() % choices.size()]
	var have: int = int(GameState.inventory[good_id])
	var cut_u: int = maxi(1, int(floor(float(have) * TITHE_RATE)))
	cut_u = mini(cut_u, have)
	GameState.inventory[good_id] = have - cut_u
	GameState.inventory_changed.emit()
	return "They took %d %s." % [cut_u, WorldBook.good_name(good_id)]
