class_name WordBook
extends RefCounted

## Dated slips. Stars mark claim quality. Assay walks are five stars.


static func reset() -> void:
	GameState.reports.clear()


static func all_slips() -> Array:
	return GameState.reports


static func slip(slip_id: String) -> Dictionary:
	for row in GameState.reports:
		if str(row.get("id", "")) == slip_id:
			return row
	return {}


static func add_slip(city_id: String, good_id: String, text: String, stars: int, source: String) -> Dictionary:
	var rec := {
		"id": "slip_%d" % GameState.reports.size(),
		"city_id": city_id,
		"good_id": good_id,
		"text": text,
		"stars": clampi(stars, 1, 5),
		"minted_day": GameState.day,
		"source": source,
		"resolved": source == "assay",
	}
	GameState.reports.push_front(rec)
	return rec


static func mint_arrival(city_id: String, seen_before: bool, prior: Dictionary) -> void:
	var place := WorldBook.settlement_name(city_id)
	if not WorldBook.settlement_has_market(city_id):
		add_slip(city_id, "", "No stall at %s. Quiet halt." % place, 5, "assay")
		return
	if not seen_before:
		add_slip(city_id, "", "First stall walk in %s." % place, 5, "assay")
		return
	var moved: Array = []
	for good_id in GameState.GOODS.keys():
		var gid := str(good_id)
		var old_band := str(prior.get(gid, {}).get("band", ""))
		var now_band := str(SightBook.note(city_id, gid).get("band", ""))
		if not old_band.is_empty() and old_band != now_band:
			moved.append(gid)
	if moved.is_empty():
		add_slip(city_id, "", "Quiet since you were last here.", 5, "assay")
		return
	if moved.size() == 1:
		var gid: String = moved[0]
		var band := str(SightBook.note(city_id, gid).get("band", "fair"))
		add_slip(city_id, gid, "%s %s is %s." % [place, WorldBook.good_name(gid), SightBook.band_label(band)], 5, "assay")
		return
	add_slip(city_id, "", "Stalls have moved in %s since the last walk." % place, 5, "assay")


static func stars_text(stars: int) -> String:
	var n := clampi(stars, 0, 5)
	return "★".repeat(n) + "☆".repeat(5 - n)


static func age_text(minted_day: int) -> String:
	var age := maxi(0, GameState.day - minted_day)
	if age <= 0:
		return "today"
	if age == 1:
		return "1 day old"
	return "%d days old" % age


static func latest_for(city_id: String, good_id: String) -> Dictionary:
	for row in GameState.reports:
		if str(row.get("city_id", "")) != city_id:
			continue
		var gid := str(row.get("good_id", ""))
		if gid.is_empty() or gid == good_id:
			return row
	return {}
