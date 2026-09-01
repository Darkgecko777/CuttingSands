extends Control

## Title screen for Caravans of the Cutting Sands.
## Sand bed is handled by SandBed child (persistent CPU pool).
## Menu buttons are MenuButton instances (panel + Bona Nova SC text).
## Continue and Options stay visible but inert for this slice.

@onready var new_game_button: TextureButton = $CenterRoot/MainColumn/MenuPanel/ButtonColumn/NewGameButton
@onready var continue_button: TextureButton = $CenterRoot/MainColumn/MenuPanel/ButtonColumn/ContinueButton
@onready var options_button: TextureButton = $CenterRoot/MainColumn/MenuPanel/ButtonColumn/OptionsButton
@onready var exit_button: TextureButton = $CenterRoot/MainColumn/MenuPanel/ButtonColumn/ExitButton


func _ready() -> void:
	AudioManager.resume_wind()
	new_game_button.pressed.connect(_on_new_game_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	continue_button.disabled = true
	continue_button.tooltip_text = "No save in this slice"
	options_button.disabled = true
	options_button.tooltip_text = "Not in this slice"

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/house_select.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
