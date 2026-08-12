extends Control

## Title screen for Trader of the Cutting Sands.
## Handles Start (loads main scene), Options (placeholder), and Exit.

@onready var start_button: Button = %StartButton
@onready var options_button: Button = %OptionsButton
@onready var exit_button: Button = %ExitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	# Ensure mouse is visible and focused on menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	start_button.grab_focus()


func _on_start_pressed() -> void:
	# Transition to the first main scene
	get_tree().change_scene_to_file("res://scenes/main/main_game.tscn")


func _on_options_pressed() -> void:
	# Placeholder — options menu will be implemented later
	print("Options pressed (not yet implemented)")


func _on_exit_pressed() -> void:
	get_tree().quit()
