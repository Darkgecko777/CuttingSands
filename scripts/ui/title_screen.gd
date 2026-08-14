extends Control

## Title screen for Trader of the Cutting Sands.
## Uses custom button sprites. New Game → house select, Exit → quit.
## Continue and Options are placeholders for now.

@onready var new_game_button: TextureButton = %NewGameButton
@onready var continue_button: TextureButton = %ContinueButton
@onready var options_button: TextureButton = %OptionsButton
@onready var exit_button: TextureButton = %ExitButton


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# Ensure mouse is visible and focused on menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	# Go to merchant house selection
	get_tree().change_scene_to_file("res://scenes/ui/house_select.tscn")


func _on_continue_pressed() -> void:
	# Placeholder — save/load will be implemented later
	print("Continue pressed (not yet implemented)")


func _on_options_pressed() -> void:
	# Placeholder — options menu will be implemented later
	print("Options pressed (not yet implemented)")


func _on_exit_pressed() -> void:
	get_tree().quit()
