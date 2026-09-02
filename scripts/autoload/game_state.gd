extends Node

signal scrubstone_changed(new_amount: int)
signal inventory_changed
signal location_changed(city_id: String)
signal catalog_changed

const STARTING_SCRUBSTONE := 500
const STARTING_CAPACITY := 24
const STARTING_MASS := 36
const SELL_SPREAD := 0.85
const PRICE_PER_HOP := 5
const STOCK_TARGET := 16
const STOCK_BASE := 20
const PRODUCER_STOCK_BONUS := 12
const PLAYER_CARAVAN_ID := "player_caravan"
const PLAYER_CARAVAN_NAME := "House Caravan"
const CARAVAN_SPEED := 1.0

var selected_house_id: String = "house_kharun"
var current_city_id: String = "kharun"
var focused_caravan_id: String = PLAYER_CARAVAN_ID
var scrubstone: int = STARTING_SCRUBSTONE
var caravan_capacity: int = STARTING_CAPACITY
var caravan_mass_capacity: int = STARTING_MASS
var day: int = 1
var agents: Array = []
var reports: Array = []
var memory: Dictionary = {}
var LINK_DAYS: Dictionary = {}
var LINK_WEATHER: Dictionary = {}
var LINK_HEAT: Dictionary = {}
var road_note: String = ""
var transit: Dictionary = {}
var inventory: Dictionary = {}
var market_stock: Dictionary = {}
var HOUSES: Dictionary = {}
var CITIES: Dictionary = {}
var GOODS: Dictionary = {}
var ROUTES: Dictionary = {}
var caravans: Dictionary = {}
var pending_travel_to: String = ""


func _ready() -> void:
	WorldBook.load_world()
	CargoHold.reset_player()
	MarketBook.seed_all()
	CaravanLog.spawn_player(current_city_id)
	WordBook.reset()
	SightBook.reset()


func start_new_run(house_id: String) -> void:
	selected_house_id = house_id
	var house: Dictionary = HOUSES.get(house_id, {})
	current_city_id = str(house.get("home", house.get("home_city", "kharun")))
	scrubstone = STARTING_SCRUBSTONE
	caravan_capacity = STARTING_CAPACITY
	caravan_mass_capacity = STARTING_MASS
	focused_caravan_id = PLAYER_CARAVAN_ID
	pending_travel_to = ""
	road_note = ""
	RoadPressure.seed_pressures()
	CargoHold.reset_player()
	MarketBook.seed_all()
	day = 1
	agents.clear()
	WordBook.reset()
	CaravanLog.spawn_player(current_city_id)
	SightBook.reset()
	scrubstone_changed.emit(scrubstone)
	inventory_changed.emit()
	location_changed.emit(current_city_id)
	catalog_changed.emit()


func _link_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


func get_caravan(caravan_id: String) -> Dictionary:
	return CaravanLog.record(caravan_id)


func list_caravans() -> Array:
	var items: Array = []
	for caravan_id in caravans.keys():
		var rec: Dictionary = get_caravan(caravan_id)
		if rec.is_empty():
			continue
		items.append({"kind": "caravan", "id": str(rec.get("id", caravan_id)), "name": str(rec.get("name", caravan_id))})
	return items


func caravan_status(caravan_id: String) -> String:
	return str(get_caravan(caravan_id).get("status", "idle"))


func caravan_city(caravan_id: String) -> String:
	var wagon: Dictionary = get_caravan(caravan_id)
	if wagon.is_empty():
		return current_city_id
	if str(wagon.get("status", "idle")) == "transit":
		return str(wagon.get("from", current_city_id))
	return str(wagon.get("at", current_city_id))


func set_caravan_progress(caravan_id: String, progress: float) -> void:
	if caravans.has(caravan_id):
		caravans[caravan_id]["progress"] = clampf(progress, 0.0, 1.0)


func is_adjacent(a: String, b: String) -> bool:
	return CaravanLog.is_adjacent(a, b)


func neighbors_of(city_id: String) -> Array:
	return CaravanLog.neighbors_of(city_id)


func hop_days(from_id: String, to_id: String) -> int:
	return CaravanLog.hop_days(from_id, to_id)


func is_on_road() -> bool:
	return caravan_status(PLAYER_CARAVAN_ID) == "transit" or not transit.is_empty()


func begin_hop(to_id: String) -> bool:
	return CaravanLog.begin_hop_for(PLAYER_CARAVAN_ID, to_id)


func begin_hop_for(caravan_id: String, to_id: String) -> bool:
	return CaravanLog.begin_hop_for(caravan_id, to_id)


func finish_hop() -> bool:
	return CaravanLog.finish_hop_for(PLAYER_CARAVAN_ID)


func finish_hop_for(caravan_id: String) -> bool:
	return CaravanLog.finish_hop_for(caravan_id)


func settlement_has_market(city_id: String) -> bool:
	return WorldBook.settlement_has_market(city_id)


func hops_to_producer(city_id: String, good_id: String) -> int:
	return MarketBook.hops_to_producer(city_id, good_id)


func hops_between(from_id: String, to_id: String) -> int:
	return MarketBook.hops_between(from_id, to_id)


func cargo_used() -> int:
	return CargoHold.cells()


func cargo_mass() -> int:
	return CargoHold.mass()


func cargo_free() -> int:
	return max(0, caravan_capacity - cargo_used())


func get_house_name() -> String:
	return WorldBook.house_name(selected_house_id)


func get_city_name() -> String:
	return get_settlement_name(current_city_id)


func get_settlement_name(city_id: String) -> String:
	return WorldBook.settlement_name(city_id)


func travel_to(city_id: String) -> bool:
	if city_id.is_empty() or not CITIES.has(city_id):
		return false
	if caravans.has(PLAYER_CARAVAN_ID) and str(get_caravan(PLAYER_CARAVAN_ID).get("status", "idle")) != "transit":
		caravans[PLAYER_CARAVAN_ID]["at"] = city_id
	if city_id == current_city_id:
		location_changed.emit(city_id)
		inventory_changed.emit()
		return true
	current_city_id = city_id
	location_changed.emit(city_id)
	inventory_changed.emit()
	return true


func get_city_desc() -> String:
	var city: Dictionary = CITIES.get(current_city_id, {})
	return str(city.get("short_desc", city.get("desc", "")))


func get_good_name(good_id: String) -> String:
	return WorldBook.good_name(good_id)


func get_good_mark(good_id: String) -> String:
	return WorldBook.good_mark(good_id)


func get_producer_id(good_id: String) -> String:
	return WorldBook.producer_id(good_id)


func get_producer_name(good_id: String) -> String:
	return get_settlement_name(get_producer_id(good_id))


func get_market_stock(good_id: String, city_id: String = "") -> int:
	return MarketBook.stock(good_id, city_id)


func get_local_price(good_id: String, city_id: String = "") -> int:
	return MarketBook.local_price(good_id, city_id)


func get_sell_price(good_id: String, city_id: String = "") -> int:
	return MarketBook.sell_price(good_id, city_id)


func can_buy(good_id: String, amount: int = 1) -> bool:
	return CargoHold.can_buy(good_id, amount)


func buy(good_id: String, amount: int = 1) -> bool:
	return CargoHold.buy(good_id, amount)


func can_sell(good_id: String, amount: int = 1) -> bool:
	return CargoHold.can_sell(good_id, amount)


func sell(good_id: String, amount: int = 1) -> bool:
	return CargoHold.sell(good_id, amount)
