class_name SightBook
extends RefCounted

## Player knowledge of goods and stalls. Almanac is free. Assay is here-and-now.
## Memory is last assay. Live remote numbers never live here.


static func reset() -> void:
	GameState.memory = {}
	stamp_city(GameState.current_city_id)
	var home := GameState.current_city_id
	WordBook.add_slip(home, "", "House primer. %s stalls are an assay while you stand them." % WorldBook.settlement_name(home), 5, "assay")


static func stamp_city(city_id: String) -> void:
	if city_id.is_empty() or not GameState.CITIES.has(city_id):
		return
	if not WorldBook.settlement_has_market(city_id):
		return
	if not GameState.memory.has(city_id):
		GameState.memory[city_id] = {}
	var row: Dictionary = GameState.memory[city_id]
	for good_id in GameState.GOODS.keys():
		var gid := str(good_id)
		var stock := MarketBook.stock(gid, city_id)
		row[gid] = {
			"day": GameState.day,
			"buy": MarketBook.local_price(gid, city_id),
			"sell": MarketBook.sell_price(gid, city_id),
			"stock": stock,
			"band": band_for(stock),
		}


static func on_depart(city_id: String) -> void:
	stamp_city(city_id)


static func on_arrival(city_id: String) -> void:
	var seen_before := GameState.memory.has(city_id)
	var prior: Dictionary = GameState.memory.get(city_id, {}).duplicate(true)
	stamp_city(city_id)
	WordBook.mint_arrival(city_id, seen_before, prior)


static func band_for(stock: int) -> String:
	if stock >= 18:
		return "glut"
	if stock >= 10:
		return "fair"
	return "thin"


static func band_label(band: String) -> String:
	match band:
		"glut":
			return "glut"
		"thin":
			return "thin"
		_:
			return "fair"


static func is_assay(city_id: String) -> bool:
	return city_id == GameState.current_city_id and not GameState.is_on_road() and WorldBook.settlement_has_market(city_id)


static func note(city_id: String, good_id: String) -> Dictionary:
	var raw: Variant = GameState.memory.get(city_id, {}).get(good_id, {})
	return raw if typeof(raw) == TYPE_DICTIONARY else {}


static func almanac(good_id: String) -> Dictionary:
	var rec: Dictionary = GameState.GOODS.get(good_id, {})
	return {
		"id": good_id,
		"name": WorldBook.good_name(good_id),
		"category": str(rec.get("category", "good")),
		"size": CargoMath.size_of(good_id),
		"mass": CargoMath.mass_of(good_id),
		"producer": WorldBook.producer_id(good_id),
		"blurb": str(rec.get("blurb", "")),
	}
