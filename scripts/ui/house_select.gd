extends Control

## Merchant House selection screen.
## Demo locks the player to a single available house.

signal house_selected(house_id: String)

const HOUSES := [
	{
		"id": "A",
		"name": "House A",
		"flavour": "Steel, contracts, quiet leverage",
		"available": true
	},
	{
		"id": "B",
		"name": "House B",
		"flavour": "Water rights and long memory",
		"available": false
	},
	{
		"id": "C",
		"name": "House C",
		"flavour": "Spice routes and soft power",
		"available": false
	},
	{
		"id": "D",
		"name": "House D",
		"flavour": "Salvage, secrets, second chances",
		"available": false
	},
	{
		"id": "E",
		"name": "House E",
		"flavour": "Old blood, older debts",
		"available": false
	}
]

@onready var cards_container: HBoxContainer = %CardsContainer
@onready var confirm_button: Button = %ConfirmButton
@onready var back_button: Button = %BackButton
@onready var subtitle_label: Label = %SubtitleLabel

var selected_house_id: String = ""
var card_buttons: Array[Button] = []


func _ready() -> void:
	_build_cards()
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	confirm_button.disabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _build_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	card_buttons.clear()

	for house in HOUSES:
		var card := _create_card(house)
		cards_container.add_child(card)
		card_buttons.append(card)


func _create_card(house: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(160, 220)
	btn.toggle_mode = true
	btn.button_group = null  # we manage selection ourselves

	# Visual style
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.18, 0.12, 0.08, 1)
	style_normal.border_color = Color(0.45, 0.32, 0.18, 1)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(6)
	style_normal.content_margin_left = 12
	style_normal.content_margin_right = 12
	style_normal.content_margin_top = 16
	style_normal.content_margin_bottom = 16

	var style_hover := style_normal.duplicate()
	style_hover.bg_color = Color(0.25, 0.17, 0.10, 1)
	style_hover.border_color = Color(0.7, 0.5, 0.28, 1)

	var style_pressed := style_normal.duplicate()
	style_pressed.bg_color = Color(0.32, 0.22, 0.12, 1)
	style_pressed.border_color = Color(0.9, 0.7, 0.35, 1)
	style_pressed.set_border_width_all(3)

	var style_disabled := style_normal.duplicate()
	style_disabled.bg_color = Color(0.12, 0.10, 0.09, 1)
	style_disabled.border_color = Color(0.25, 0.22, 0.18, 1)

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_stylebox_override("focus", style_pressed)

	# Content
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	# Big letter
	var letter := Label.new()
	letter.text = house.id
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.add_theme_font_size_override("font_size", 48)
	letter.add_theme_color_override("font_color", Color(0.92, 0.78, 0.45, 1) if house.available else Color(0.4, 0.35, 0.3, 1))
	letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(letter)

	# Name
	var name_label := Label.new()
	name_label.text = house.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 1) if house.available else Color(0.45, 0.4, 0.35, 1))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	# Flavour
	var flavour := Label.new()
	flavour.text = house.flavour
	flavour.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavour.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavour.add_theme_font_size_override("font_size", 12)
	flavour.add_theme_color_override("font_color", Color(0.7, 0.6, 0.45, 1) if house.available else Color(0.35, 0.32, 0.28, 1))
	flavour.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(flavour)

	# Status
	var status := Label.new()
	if house.available:
		status.text = "Available"
		status.add_theme_color_override("font_color", Color(0.55, 0.85, 0.5, 1))
	else:
		status.text = "Locked in Demo"
		status.add_theme_color_override("font_color", Color(0.55, 0.4, 0.3, 1))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 12)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(status)

	# Behaviour
	if house.available:
		btn.pressed.connect(_on_card_pressed.bind(house.id, btn))
	else:
		btn.disabled = true
		btn.tooltip_text = "Available in the full game"

	return btn


func _on_card_pressed(house_id: String, card: Button) -> void:
	selected_house_id = house_id
	confirm_button.disabled = false

	# Visual selection: only one pressed at a time
	for b in card_buttons:
		b.button_pressed = (b == card)


func _on_confirm_pressed() -> void:
	if selected_house_id.is_empty():
		return
	# For now we just store it in a simple autoload-friendly way via meta or a temporary global.
	# Later this will feed into a proper GameState.
	print("Selected House: ", selected_house_id)
	get_tree().change_scene_to_file("res://scenes/main/main_game.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
