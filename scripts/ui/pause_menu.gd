extends CanvasLayer

## Global in-game menu. Esc toggles it on city desk and map; hidden on title/house select.

const FRONT_SCENES := [
	"res://scenes/ui/title_screen.tscn",
	"res://scenes/ui/house_select.tscn",
]

@onready var overlay: ColorRect = %Overlay
@onready var resume_button: Button = %ResumeButton
@onready var options_button: Button = %OptionsButton
@onready var title_button: Button = %TitleButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	resume_button.pressed.connect(close)
	options_button.pressed.connect(_on_options)
	title_button.pressed.connect(_on_title)
	quit_button.pressed.connect(_on_quit)
	options_button.disabled = true
	options_button.tooltip_text = "Not in this slice"


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _is_front_menu():
		return
	if visible:
		close()
	else:
		open()
	get_viewport().set_input_as_handled()


func _is_front_menu() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return true
	return scene.scene_file_path in FRONT_SCENES


func open() -> void:
	if _is_front_menu():
		return
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _on_options() -> void:
	pass


func _on_title() -> void:
	close()
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")


func _on_quit() -> void:
	get_tree().quit()
