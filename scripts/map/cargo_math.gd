class_name CargoMath
extends RefCounted


static func size_of(good_id: String) -> int:
	var rec: Dictionary = GameState.GOODS.get(good_id, {})
	return maxi(1, int(rec.get("size", 1)))


static func mass_of(good_id: String) -> int:
	var rec: Dictionary = GameState.GOODS.get(good_id, {})
	if rec.has("mass"):
		return maxi(1, int(rec.get("mass", 1)))
	return maxi(1, int(rec.get("weight", 1)))


static func cells_in(table: Dictionary) -> int:
	var used := 0
	for good_id in table.keys():
		used += size_of(str(good_id)) * int(table[good_id])
	return used


static func mass_in(table: Dictionary) -> int:
	var used := 0
	for good_id in table.keys():
		used += mass_of(str(good_id)) * int(table[good_id])
	return used
