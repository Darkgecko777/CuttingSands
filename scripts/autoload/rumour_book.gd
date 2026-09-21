class_name RumourBook
extends RefCounted

## Expedition tickets. Stars are payoff mass. Stall notes stay in WordBook.


static func reset() -> void:
	GameState.rumours.clear()
	GameState.rumour_seq = 0
	GameState.socialized_day = 0
	GameState.exp = 0


static func tickets() -> Array:
	return GameState.rumours


static func ticket(ticket_id: String) -> Dictionary:
	for row in GameState.rumours:
		if str(row.get("id", "")) == ticket_id:
			return row
	return {}


static func can_socialize() -> bool:
	return GameState.socialized_day != GameState.day


static func spend_socialize() -> void:
	GameState.socialized_day = GameState.day


static func has_improvable() -> bool:
	for row in GameState.rumours:
		if int(row.get("stars", 1)) < 5:
			return true
	return false


static func improvable() -> Array:
	var rows: Array = []
	for row in GameState.rumours:
		if int(row.get("stars", 1)) < 5:
			rows.append(row)
	return rows


static func here_tickets(city_id: String) -> Array:
	var rows: Array = []
	for row in GameState.rumours:
		if str(row.get("origin_id", "")) == city_id:
			rows.append(row)
	return rows


static func mint(here: String) -> Dictionary:
	var origin := _pick_origin(here)
	var edges := _path_edges(here, origin)
	var hops := edges.size()
	GameState.rumour_seq += 1
	var rec := {
		"id": "ticket_%d" % GameState.rumour_seq,
		"origin_id": origin,
		"stars": _starting_stars(hops),
		"expires_on": GameState.day + _floor_days(edges),
		"verified": false,
	}
	GameState.rumours.push_front(rec)
	return rec


static func improve(ticket_id: String) -> Dictionary:
	var rec := ticket(ticket_id)
	if rec.is_empty() or int(rec.get("stars", 1)) >= 5:
		return rec
	rec["stars"] = int(rec.get("stars", 1)) + 1
	return rec


static func burn(ticket_id: String) -> void:
	for i in GameState.rumours.size():
		if str(GameState.rumours[i].get("id", "")) == ticket_id:
			GameState.rumours.remove_at(i)
			return


static func expire() -> void:
	var kept: Array = []
	for row in GameState.rumours:
		if int(row.get("expires_on", 0)) >= GameState.day:
			kept.append(row)
	GameState.rumours = kept


static func cards_for(stars: int) -> int:
	return mini(3, clampi(stars, 1, 5))


static func country_term(city_id: String) -> String:
	var worst := 0
	for raw in GameState.neighbors_of(city_id):
		worst = maxi(worst, RoadPressure.weather(city_id, str(raw)))
	return RoadPressure.WEATHER_TERMS[clampi(worst, 0, 3)]


static func grant(stars: int) -> Dictionary:
	var rank := clampi(stars, 1, 5)
	var coin := 8 * rank
	var qty := rank
	var good_id := "rations"
	var kept := 0
	GameState.scrubstone += coin
	for _i in qty:
		if not _room_for(good_id):
			break
		GameState.inventory[good_id] = int(GameState.inventory.get(good_id, 0)) + 1
		kept += 1
	GameState.exp += rank
	GameState.scrubstone_changed.emit(GameState.scrubstone)
	GameState.inventory_changed.emit()
	return {"coin": coin, "good_id": good_id, "kept": kept, "lost": qty - kept, "exp": rank}


static func stars_text(stars: int) -> String:
	return WordBook.stars_text(stars)


static func life_text(rec: Dictionary) -> String:
	return "holds through day %d" % int(rec.get("expires_on", GameState.day))


static func _pick_origin(here: String) -> String:
	var local: Array = []
	var far: Array = []
	for raw in GameState.CITIES.keys():
		var node := str(raw)
		if not WorldBook.settlement_is_dock(node):
			continue
		var hops := 0 if node == here else _path_edges(here, node).size()
		if node != here and hops <= 0:
			continue
		if hops <= 1:
			local.append(node)
		else:
			far.append(node)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if not local.is_empty() and (far.is_empty() or rng.randf() < 0.7):
		return str(local[rng.randi_range(0, local.size() - 1)])
	if not far.is_empty():
		return str(far[rng.randi_range(0, far.size() - 1)])
	return here


static func _starting_stars(hops: int) -> int:
	if hops <= 1:
		return 2 + (randi() % 2)
	return 1


# Hop count, or the base walk if an edge is longer than a day, plus one pad from the worst term.
static func _floor_days(edges: Array) -> int:
	var hops := edges.size()
	var base := 0
	var pad := 0
	for edge in edges:
		if typeof(edge) != TYPE_ARRAY or edge.size() < 2:
			continue
		var a := str(edge[0])
		var b := str(edge[1])
		base += maxi(1, int(GameState.LINK_DAYS.get(GameState._link_key(a, b), 1)))
		pad = maxi(pad, RoadPressure.extra_days(a, b))
	return maxi(hops, base) + pad


static func _path_edges(here: String, origin: String) -> Array:
	if here.is_empty() or origin.is_empty() or here == origin:
		return []
	var prev := {here: ""}
	var queue: Array = [here]
	while not queue.is_empty():
		var at := str(queue.pop_front())
		if at == origin:
			break
		for raw in GameState.ROUTES.get(at, []):
			var nxt := str(raw)
			if prev.has(nxt):
				continue
			prev[nxt] = at
			queue.append(nxt)
	if not prev.has(origin):
		return []
	var nodes: Array = []
	var walk := origin
	while not walk.is_empty():
		nodes.push_front(walk)
		walk = str(prev.get(walk, ""))
	var edges: Array = []
	for i in range(1, nodes.size()):
		edges.append([str(nodes[i - 1]), str(nodes[i])])
	return edges


static func _room_for(good_id: String) -> bool:
	if CargoMath.cells_in(GameState.inventory) + CargoMath.size_of(good_id) > GameState.caravan_capacity:
		return false
	return CargoMath.mass_in(GameState.inventory) + CargoMath.mass_of(good_id) <= GameState.caravan_mass_capacity
