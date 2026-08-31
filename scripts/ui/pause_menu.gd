extends CanvasLayer

## Global menu. Gear stays on every screen. Esc and the gear open the same overlay.

const FRONT_SCENES := [
	"res://scenes/ui/title_screen.tscn",
	"res://scenes/ui/house_select.tscn",
]

@onready var dimmer: ColorRect = %Overlay
@onready var panel_root: Control = %Center
@onready var gear_button: Button = %GearButton
@onready var resume_button: Button = %ResumeButton
@onready var options_button: Button = %OptionsButton
@onready var title_button: Button = %TitleButton
@onready var quit_button: Button = %QuitButton

var menu_open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = true
	_set_menu_open(false)
	gear_button.pressed.connect(_on_gear)
	resume_button.pressed.connect(close)
	options_button.pressed.connect(_on_options)
	title_button.pressed.connect(_on_title)
	quit_button.pressed.connect(_on_quit)
	options_button.disabled = true
	options_button.tooltip_text = "Not in this slice"


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if menu_open:
		close()
	else:
		open()
	get_viewport().set_input_as_handled()


func _is_front_menu() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return true
	return scene.scene_file_path in FRONT_SCENES


func _on_gear() -> void:
	if menu_open:
		close()
	else:
		open()


func open() -> void:
	_set_menu_open(true)
	title_button.visible = not _is_front_menu()
	resume_button.text = "Close" if _is_front_menu() else "Resume"
	if not _is_front_menu():
		get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	_set_menu_open(false)
	get_tree().paused = false


func _set_menu_open(is_open: bool) -> void:
	menu_open = is_open
	dimmer.visible = is_open
	panel_root.visible = is_open
	gear_button.visible = true


func _on_options() -> void:
	pass


func _on_title() -> void:
	close()
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")


func _on_quit() -> void:
	get_tree().quit()
