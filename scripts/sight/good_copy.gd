class_name GoodCopy
extends RefCounted

## Tooltip and context prose from SightBook. Never prints a live remote price.


static func almanac_lines(good_id: String) -> PackedStringArray:
	var info := SightBook.almanac(good_id)
	var lines: PackedStringArray = []
	lines.append(str(info["name"]))
	lines.append("%s  ·  %d cell  ·  %d mass" % [str(info["category"]).capitalize(), info["size"], info["mass"]])
	var home := str(info["producer"])
	if not home.is_empty() and WorldBook.good_letter(good_id).is_empty() and not WorldBook.is_shared_good(good_id):
		lines.append("Home: %s" % WorldBook.settlement_name(home))
	var blurb := str(info["blurb"])
	if not blurb.is_empty() and WorldBook.good_letter(good_id).is_empty():
		lines.append(blurb)
	return lines


static func stall_tooltip(good_id: String) -> String:
	var city_id := GameState.current_city_id
	var lines := almanac_lines(good_id)
	if SightBook.stall_is_live(city_id):
		lines.append("Here: buy %d  ·  sell %d  ·  stall %d" % [
			MarketBook.local_price(good_id, city_id),
			MarketBook.sell_price(good_id, city_id),
			MarketBook.stock(good_id, city_id),
		])
	else:
		lines.append_array(_memory_lines(city_id, good_id))
	lines.append_array(_word_lines(city_id, good_id))
	lines.append_array(_ledger_lines(good_id))
	return "\n".join(lines)


static func wagon_tooltip(good_id: String) -> String:
	var lines := almanac_lines(good_id)
	lines.append("On the rack.")
	var here := GameState.current_city_id
	if SightBook.stall_is_live(here):
		lines.append("This stall: buy %d  ·  sell %d." % [
			MarketBook.local_price(good_id, here),
			MarketBook.sell_price(good_id, here),
		])
	else:
		lines.append_array(_memory_lines(here, good_id))
	lines.append_array(_word_lines(here, good_id))
	lines.append_array(_ledger_lines(good_id))
	return "\n".join(lines)


static func remote_tooltip(city_id: String, good_id: String) -> String:
	var lines := almanac_lines(good_id)
	lines.append_array(_memory_lines(city_id, good_id))
	lines.append_array(_word_lines(city_id, good_id))
	if lines.size() <= SightBook.almanac(good_id).size():
		lines.append("No rumour.")
	lines.append_array(_ledger_lines(good_id))
	return "\n".join(lines)


static func context_block(good_id: String, city_id: String = "") -> String:
	var cid := GameState.current_city_id if city_id.is_empty() else city_id
	if SightBook.stall_is_live(cid):
		return stall_tooltip(good_id)
	return remote_tooltip(cid, good_id)


static func _memory_lines(city_id: String, good_id: String) -> PackedStringArray:
	var note := SightBook.note(city_id, good_id)
	var lines: PackedStringArray = []
	if note.is_empty():
		return lines
	var place := WorldBook.settlement_name(city_id)
	var age := WordBook.age_text(int(note.get("day", GameState.day)))
	lines.append("Last walk at %s, Day %d (%s): buy %d, stall %s." % [
		place,
		int(note.get("day", 1)),
		age,
		int(note.get("buy", 0)),
		SightBook.band_label(str(note.get("band", "fair"))),
	])
	return lines


static func _ledger_lines(good_id: String) -> PackedStringArray:
	var row: Dictionary = GameState.price_ledger.get(good_id, {})
	var lines: PackedStringArray = []
	if row.is_empty():
		return lines
	var low := int(row.get("lowest_buy_price", 0))
	var high := int(row.get("highest_sell_price", 0))
	var low_town := WorldBook.settlement_name(str(row.get("lowest_buy_node_id", "")))
	var high_town := WorldBook.settlement_name(str(row.get("highest_sell_node_id", "")))
	if low > 0 and not low_town.is_empty():
		lines.append("Lowest buy  %d  %s" % [low, low_town])
	if high > 0 and not high_town.is_empty():
		lines.append("Highest sale  %d  %s" % [high, high_town])
	return lines


static func _word_lines(city_id: String, good_id: String) -> PackedStringArray:
	var rumour := WordBook.latest_for(city_id, good_id)
	var lines: PackedStringArray = []
	if rumour.is_empty():
		return lines
	var stars := WordBook.stars_text(int(rumour.get("stars", 1)))
	var source := str(rumour.get("source", "rumour")).capitalize()
	lines.append("%s %s  “%s”  %s." % [
		source,
		stars,
		str(rumour.get("text", "")),
		WordBook.age_text(int(rumour.get("minted_day", GameState.day))),
	])
	return lines
