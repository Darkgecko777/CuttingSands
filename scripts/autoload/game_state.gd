extends Node

signal scrubstone_changed(new_amount: int)
signal inventory_changed
signal location_changed(city_id: String)
signal catalog_changed

const STARTING_SCRUBSTONE := 500
const STARTING_CAPACITY := 16
const STARTING_MASS := 36
const SELL_SPREAD := 0.85
const PRICE_PER_HOP := 5
const STOCK_TARGET := 16
const STOCK_BASE := 20
const PRODUCER_STOCK_BONUS := 12
const PLAYER_CARAVAN_ID := "player_caravan"
const PLAYER_CARAVAN_NAME := "House Caravan"
const CARAVAN_SPEED := 1.0
const HOURS_PER_WATCH := 3
const WATCHES_PER_DAY := 8
const HOURS_PER_DAY := 24
const MARKET_LAST_WATCH := 5
const WATCH_NAMES: PackedStringArray = [
	"",
	"Dawn",
	"Morning",
	"Heat",
	"Afternoon",
	"Dusk",
	"First night",
	"Deep night",
	"Predawn",
]

var selected_house_id: String = "house_kharun"
var current_city_id: String = "kharun"
var focused_caravan_id: String = PLAYER_CARAVAN_ID
var scrubstone: int = STARTING_SCRUBSTONE
var caravan_capacity: int = STARTING_CAPACITY
var caravan_mass_capacity: int = STARTING_MASS
var day: int = 1
var hours: int = 0
var watch_lerp: float = 0.0
var pending_watch_hours: int = 0
var agents: Array = []
var reports: Array = []
var rumours: Array = []
var rumour_seq: int = 0
var socialized_day: int = 0
var exp: int = 0
var memory: Dictionary = {}
var LINK_DAYS: Dictionary = {}
var LINK_WEATHER: Dictionary = {}
var road_note: String = ""
var transit: Dictionary = {}
var inventory: Dictionary = {}
var market_stock: Dictionary = {}
var HOUSES: Dictionary = {}
var CITIES: Dictionary = {}
var GOODS: Dictionary = {}
var ROUTES: Dictionary = {}
var STRING_ROSTER: Dictionary = {}
var string_tokens: Dictionary = {}
var caravans: Dictionary = {}
var pending_travel_to: String = ""
var price_ledger: Dictionary = {}
var standing: Dictionary = {}
var presence: Dictionary = {}
var door_hold: Dictionary = {}
var COMMISSIONS: Dictionary = {}


func _ready() -> void:
	WorldBook.load_world()
	CargoHold.reset_player()
	MarketBook.seed_all()
	DoorBook.seed()
	StringBook.seed_all()
	CaravanLog.spawn_player(current_city_id)
	WordBook.reset()
	RumourBook.reset()
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
	DoorBook.seed()
	StringBook.seed_all()
	hours = 0
	day = 1
	watch_lerp = 0.0
	pending_watch_hours = 0
	agents.clear()
	price_ledger.clear()
	WordBook.reset()
	RumourBook.reset()
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


func hop_hours(from_id: String, to_id: String) -> int:
	return hop_days(from_id, to_id) * HOURS_PER_DAY


func is_on_road() -> bool:
	return caravan_status(PLAYER_CARAVAN_ID) == "transit" or not transit.is_empty()


func watch_index() -> int:
	return (hours % HOURS_PER_DAY) / HOURS_PER_WATCH + 1


func hour_into_watch() -> int:
	return hours % HOURS_PER_WATCH


func watch_name(index: int = -1) -> String:
	var w := watch_index() if index < 1 else clampi(index, 1, WATCHES_PER_DAY)
	if w < 1 or w >= WATCH_NAMES.size():
		return ""
	return WATCH_NAMES[w]


func stalls_open() -> bool:
	return watch_index() <= MARKET_LAST_WATCH


func clock_label() -> String:
	return "Day %d · %s" % [day, watch_name()]


func format_stamp(at_hours: int) -> String:
	var h := maxi(0, at_hours)
	var d := h / HOURS_PER_DAY + 1
	var w := (h % HOURS_PER_DAY) / HOURS_PER_WATCH + 1
	return "day %d · %s" % [d, watch_name(w)]


func stamp_after(add_hours: int) -> String:
	return format_stamp(hours + maxi(0, add_hours))


func remainder_hours() -> int:
	return HOURS_PER_WATCH - hour_into_watch()


func wait_span_hours(span: int) -> int:
	var extra := 0
	if span == 1:
		extra = 4 * HOURS_PER_WATCH
	elif span == 2:
		extra = 8 * HOURS_PER_WATCH
	return remainder_hours() + extra


func player_remaining_hours() -> int:
	if not is_on_road():
		return 0
	var wagon: Dictionary = get_caravan(PLAYER_CARAVAN_ID)
	return maxi(0, int(wagon.get("hours_total", 0)) - int(wagon.get("hours_done", 0)))


func travel_slice_hours() -> int:
	if not is_on_road():
		return 0
	return mini(remainder_hours(), player_remaining_hours())


func player_stamp_progress() -> float:
	var wagon: Dictionary = get_caravan(PLAYER_CARAVAN_ID)
	var total := float(maxi(1, int(wagon.get("hours_total", 1))))
	var done := float(int(wagon.get("hours_done", 0)))
	return clampf(done / total, 0.0, 1.0)


func player_visual_progress() -> float:
	var wagon: Dictionary = get_caravan(PLAYER_CARAVAN_ID)
	var total := float(maxi(1, int(wagon.get("hours_total", 1))))
	var done := float(int(wagon.get("hours_done", 0))) + float(pending_watch_hours) * watch_lerp
	return clampf(done / total, 0.0, 1.0)


func eta_hours_left() -> int:
	var left := float(player_remaining_hours()) - float(pending_watch_hours) * watch_lerp
	return maxi(0, int(round(left)))


func advance_days(n: int) -> void:
	if n <= 0:
		return
	advance_hours(n * HOURS_PER_DAY)


func advance_hours(n: int) -> void:
	if n <= 0:
		return
	watch_lerp = 0.0
	pending_watch_hours = 0
	for _i in n:
		hours += 1
		StringBook.advance(1)
		_advance_player_hour()
		day = hours / HOURS_PER_DAY + 1
		if hours > 0 and hours % HOURS_PER_DAY == 0:
			_dawn_pulse()
	inventory_changed.emit()


func _advance_player_hour() -> void:
	if not is_on_road():
		return
	var wagon: Dictionary = get_caravan(PLAYER_CARAVAN_ID)
	if wagon.is_empty():
		return
	wagon["hours_done"] = int(wagon.get("hours_done", 0)) + 1
	var total := maxi(1, int(wagon.get("hours_total", 1)))
	wagon["progress"] = clampf(float(int(wagon.get("hours_done", 0))) / float(total), 0.0, 1.0)
	sync_player_transit()


func sync_player_transit() -> void:
	CaravanLog.sync_player()


func _dawn_pulse() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	RumourBook.expire()
	DoorBook.decay()
	MarketBook.tick_produce(rng)
	StringBook.dawn_act()
	MarketBook.tick_consume(rng)


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


func home_city_id() -> String:
	var house: Dictionary = HOUSES.get(selected_house_id, {})
	return str(house.get("home", house.get("home_city", "")))


func is_home_seat(city_id: String = "") -> bool:
	var cid := current_city_id if city_id.is_empty() else city_id
	return cid == home_city_id() and WorldBook.settlement_has_house_yard(cid)


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
	var cid := current_city_id if city_id.is_empty() else city_id
	return DoorBook.apply_cut(MarketBook.local_price(good_id, cid), cid, true)


func get_sell_price(good_id: String, city_id: String = "") -> int:
	var cid := current_city_id if city_id.is_empty() else city_id
	return DoorBook.apply_cut(MarketBook.sell_price(good_id, cid), cid, false)


func note_stall(good_id: String, city_id: String = "") -> void:
	var cid := current_city_id if city_id.is_empty() else city_id
	if good_id.is_empty() or cid.is_empty() or not settlement_has_market(cid) or is_on_road() or not stalls_open():
		return
	var buy := get_local_price(good_id, cid)
	var sell := get_sell_price(good_id, cid)
	if buy <= 0 and sell <= 0:
		return
	if not price_ledger.has(good_id):
		price_ledger[good_id] = {
			"lowest_buy_price": buy,
			"lowest_buy_node_id": cid,
			"highest_sell_price": sell,
			"highest_sell_node_id": cid,
		}
		return
	var row: Dictionary = price_ledger[good_id]
	if buy > 0 and buy < int(row.get("lowest_buy_price", buy)):
		row["lowest_buy_price"] = buy
		row["lowest_buy_node_id"] = cid
	if sell > int(row.get("highest_sell_price", 0)):
		row["highest_sell_price"] = sell
		row["highest_sell_node_id"] = cid


func can_buy(good_id: String, amount: int = 1) -> bool:
	return CargoHold.can_buy(good_id, amount)


func buy(good_id: String, amount: int = 1) -> bool:
	return CargoHold.buy(good_id, amount)


func can_sell(good_id: String, amount: int = 1) -> bool:
	return CargoHold.can_sell(good_id, amount)


func sell(good_id: String, amount: int = 1) -> bool:
	return CargoHold.sell(good_id, amount)
