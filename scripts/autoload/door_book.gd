class_name DoorBook
extends RefCounted

const DISTANCE_MASS := 100.0
const DAWN_DECAY := 0.9
const SHORT_LINE := 0.5
const CUT_BY_STANDING: PackedInt32Array = [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2]


static func seed() -> void:
	GameState.standing.clear()
	GameState.presence.clear()
	GameState.door_hold.clear()
	for raw in GameState.HOUSES.keys():
		var house_id := str(raw)
		GameState.standing[house_id] = 1 if house_id == GameState.selected_house_id else 0
	for raw_city in GameState.CITIES.keys():
		var node_id := str(raw_city)
		if not WorldBook.settlement_is_fluid(node_id):
			continue
		var row: Dictionary = {}
		for raw_house in GameState.HOUSES.keys():
			var house_id := str(raw_house)
			var home := WorldBook.house_home(house_id)
			var hops := MarketBook.hops_between(node_id, home)
			if hops <= 0:
				hops = 6
			row[house_id] = DISTANCE_MASS / float(hops)
		GameState.presence[node_id] = row
		_resolve(node_id)


static func decay() -> void:
	for raw in GameState.presence.keys():
		var node_id := str(raw)
		var row: Dictionary = GameState.presence[node_id]
		for house_raw in row.keys():
			row[house_raw] = float(row[house_raw]) * DAWN_DECAY
		_resolve(node_id)


static func stamp_sale(node_id: String, house_id: String, good_id: String, units: int) -> void:
	if units <= 0 or house_id.is_empty() or good_id.is_empty():
		return
	if not WorldBook.settlement_is_fluid(node_id) or not GameState.presence.has(node_id):
		return
	var have := MarketBook.stock(good_id, node_id)
	var price := MarketBook.local_price_at(good_id, node_id, have)
	var cellar := MarketBook.cap(node_id, good_id)
	var weight := 1.0
	if cellar > 0 and float(have) / float(cellar) >= SHORT_LINE:
		weight = 0.5
	var row: Dictionary = GameState.presence[node_id]
	row[house_id] = float(row.get(house_id, 0.0)) + float(units) * float(price) * weight
	_resolve(node_id)


static func door_of(node_id: String) -> String:
	if not WorldBook.settlement_is_fluid(node_id):
		return ""
	return str(GameState.door_hold.get(node_id, ""))


static func standing_of(house_id: String) -> int:
	return int(GameState.standing.get(house_id, 0))


static func score(node_id: String, house_id: String) -> float:
	var row: Variant = GameState.presence.get(node_id, {})
	if typeof(row) != TYPE_DICTIONARY:
		return 0.0
	return float(row.get(house_id, 0.0))


static func cut_percent(node_id: String) -> int:
	var house_id := door_of(node_id)
	if house_id.is_empty():
		return 0
	var rung := clampi(standing_of(house_id), 0, CUT_BY_STANDING.size() - 1)
	return int(CUT_BY_STANDING[rung])


static func apply_cut(raw: int, node_id: String, buying: bool) -> int:
	var cut := cut_percent(node_id)
	if cut <= 0 or raw <= 0:
		return raw
	var scale := (100.0 + float(cut)) / 100.0 if buying else (100.0 - float(cut)) / 100.0
	return maxi(1, int(round(float(raw) * scale)))


static func stall_line(node_id: String) -> String:
	var house_id := door_of(node_id)
	if house_id.is_empty():
		return ""
	return "Door: %s · standing %d · cut %d%%." % [short_name(house_id), standing_of(house_id), cut_percent(node_id)]


static func short_name(house_id: String) -> String:
	var name := WorldBook.house_name(house_id)
	if name.begins_with("House "):
		return name.substr(6)
	return name


static func board_open(seat_id: String) -> bool:
	var house_id := WorldBook.seat_house(seat_id)
	if house_id.is_empty():
		return false
	if house_id == GameState.selected_house_id:
		return true
	return standing_of(house_id) < 8


static func jobs_at(seat_id: String) -> Array:
	var table: Variant = GameState.COMMISSIONS.get("jobs", {})
	if typeof(table) != TYPE_DICTIONARY:
		return []
	var rows: Variant = table.get(seat_id, [])
	if typeof(rows) != TYPE_ARRAY:
		return []
	return rows


static func turn_in(seat_id: String, index: int) -> int:
	if GameState.is_on_road() or GameState.current_city_id != seat_id:
		return -1
	if not WorldBook.settlement_has_house_yard(seat_id) or not board_open(seat_id):
		return -1
	var rows := jobs_at(seat_id)
	if index < 0 or index >= rows.size() or typeof(rows[index]) != TYPE_DICTIONARY:
		return -1
	var job: Dictionary = rows[index]
	var good_id := str(job.get("good", ""))
	var qty := int(job.get("qty", 0))
	if good_id.is_empty() or qty <= 0:
		return -1
	if int(GameState.inventory.get(good_id, 0)) < qty:
		return -1
	var house_id := WorldBook.seat_house(seat_id)
	var home := house_id == GameState.selected_house_id
	var wage := int(job.get("wage_home", 0)) if home else int(job.get("wage_rival", 0))
	if wage <= 0:
		wage = int(job.get("wage", 0))
	if wage < 0:
		return -1
	GameState.inventory[good_id] = int(GameState.inventory.get(good_id, 0)) - qty
	var cap := 10 if home else 8
	var rung := standing_of(house_id)
	if rung < cap:
		GameState.standing[house_id] = rung + 1
	GameState.scrubstone += wage
	GameState.inventory_changed.emit()
	return wage


static func _resolve(node_id: String) -> void:
	var row: Variant = GameState.presence.get(node_id, {})
	if typeof(row) != TYPE_DICTIONARY or row.is_empty():
		GameState.door_hold.erase(node_id)
		return
	var best := 0.0
	var leaders: Array = []
	for raw in row.keys():
		var house_id := str(raw)
		var score := float(row[house_id])
		if leaders.is_empty() or score > best + 0.001:
			best = score
			leaders = [house_id]
		elif absf(score - best) <= 0.001:
			leaders.append(house_id)
	if leaders.size() == 1:
		GameState.door_hold[node_id] = leaders[0]
		return
	var prev := str(GameState.door_hold.get(node_id, ""))
	if not prev.is_empty() and prev in leaders:
		GameState.door_hold[node_id] = prev
		return
	var home := GameState.selected_house_id
	if home in leaders:
		GameState.door_hold[node_id] = home
		return
	leaders.sort()
	GameState.door_hold[node_id] = leaders[0]
