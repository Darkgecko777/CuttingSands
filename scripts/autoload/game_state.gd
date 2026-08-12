extends Node

## Simple global game state for early development.
## Will be expanded later with proper save/load and systems.

signal gold_changed(new_amount: int)
signal inventory_changed

# --- Player / Run data ---
var selected_house_id: String = "A"
var current_city_id: String = "A"
var gold: int = 500

# Inventory: good_id -> quantity
var inventory: Dictionary = {
	"water": 0,
	"grain": 0,
	"salt": 0,
	"iron": 0,
	"spices": 0,
	"cloth": 0,
}

# --- Static data (placeholders) ---
const HOUSES := {
	"A": {"name": "House A", "home_city": "A", "flavour": "Steel, contracts, quiet leverage"},
	"B": {"name": "House B", "home_city": "B", "flavour": "Water rights and long memory"},
	"C": {"name": "House C", "home_city": "C", "flavour": "Spice routes and soft power"},
	"D": {"name": "House D", "home_city": "D", "flavour": "Salvage, secrets, second chances"},
	"E": {"name": "House E", "home_city": "E", "flavour": "Old blood, older debts"},
}

const CITIES := {
	"A": {"name": "City A", "desc": "A hard place of forges and ledgers."},
	"B": {"name": "City B", "desc": "Built around deep cisterns and older claims."},
	"C": {"name": "City C", "desc": "Caravan roads meet here under a thin veil of spice."},
	"D": {"name": "City D", "desc": "Salvage yards and whispered second chances."},
	"E": {"name": "City E", "desc": "Old stone, older debts, careful smiles."},
}

# Goods definition: id -> {name, base_price}
const GOODS := {
	"water":  {"name": "Water",  "base_price": 12},
	"grain":  {"name": "Grain",  "base_price": 8},
	"salt":   {"name": "Salt",   "base_price": 15},
	"iron":   {"name": "Iron",   "base_price": 28},
	"spices": {"name": "Spices", "base_price": 35},
	"cloth":  {"name": "Cloth",  "base_price": 18},
}


func start_new_run(house_id: String) -> void:
	selected_house_id = house_id
	current_city_id = HOUSES[house_id]["home_city"]
	gold = 500
	for key in inventory.keys():
		inventory[key] = 0
	# Small starting stock so the player isn't completely empty
	inventory["water"] = 2
	inventory["grain"] = 3
	gold_changed.emit(gold)
	inventory_changed.emit()


func get_house_name() -> String:
	return HOUSES.get(selected_house_id, {}).get("name", "Unknown House")


func get_city_name() -> String:
	return CITIES.get(current_city_id, {}).get("name", "Unknown City")


func get_city_desc() -> String:
	return CITIES.get(current_city_id, {}).get("desc", "")


func get_good_name(good_id: String) -> String:
	return GOODS.get(good_id, {}).get("name", good_id.capitalize())


func get_local_price(good_id: String) -> int:
	# Simple placeholder pricing. Later this will be driven by city + events.
	var base: int = GOODS.get(good_id, {}).get("base_price", 10)
	# Tiny variation by city so it already feels a bit alive
	var city_mod := current_city_id.hash() % 5 - 2
	return max(1, base + city_mod)


func can_buy(good_id: String, amount: int = 1) -> bool:
	var price := get_local_price(good_id) * amount
	return gold >= price


func buy(good_id: String, amount: int = 1) -> bool:
	if not can_buy(good_id, amount):
		return false
	var price := get_local_price(good_id) * amount
	gold -= price
	inventory[good_id] = inventory.get(good_id, 0) + amount
	gold_changed.emit(gold)
	inventory_changed.emit()
	return true


func can_sell(good_id: String, amount: int = 1) -> bool:
	return inventory.get(good_id, 0) >= amount


func sell(good_id: String, amount: int = 1) -> bool:
	if not can_sell(good_id, amount):
		return false
	# Sell at a slight discount for now (simple spread)
	var price := int(get_local_price(good_id) * 0.8) * amount
	gold += price
	inventory[good_id] = inventory.get(good_id, 0) - amount
	gold_changed.emit(gold)
	inventory_changed.emit()
	return true
