extends TextureButton
## Reusable menu button: shared plate texture + Label text (Bona Nova SC).
## Hover / press use light scale feedback; plate art stays consistent.

@export var button_text: String = "BUTTON":
	set(value):
		button_text = value
		_apply_text()

@export var font_size: int = 28

@onready var _label: Label = $Label

var _tween: Tween
var _base_scale := Vector2.ONE

const HOVER_SCALE := 1.05
const PRESS_SCALE := 0.96
const TWEEN_SEC := 0.12

const GOLD := Color(0.91, 0.78, 0.42, 1.0)
const GOLD_DIM := Color(0.75, 0.62, 0.32, 1.0)
const SHADOW := Color(0.08, 0.05, 0.02, 0.85)


func _ready() -> void:
	_base_scale = scale
	pivot_offset = size * 0.5
	# Recalc pivot when laid out
	resized.connect(_on_resized)
	_on_resized()

	_apply_text()
	_apply_font_style()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

	if disabled:
		_label.modulate = Color(0.55, 0.5, 0.42, 0.85)


func _on_resized() -> void:
	pivot_offset = size * 0.5


func _apply_text() -> void:
	if _label:
		_label.text = button_text
	elif has_node("Label"):
		$Label.text = button_text


func _apply_font_style() -> void:
	if _label == null:
		return
	var font := load("res://Assets/fonts/BonaNovaSC-Bold.ttf") as Font
	if font:
		_label.add_theme_font_override("font", font)
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", GOLD)
	_label.add_theme_color_override("font_shadow_color", SHADOW)
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)


func set_label_text(text: String) -> void:
	button_text = text


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _tween_scale(target: Vector2) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", target, TWEEN_SEC)


func _on_mouse_entered() -> void:
	if disabled:
		return
	_tween_scale(_base_scale * HOVER_SCALE)
	if _label:
		_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.55, 1.0))


func _on_mouse_exited() -> void:
	_tween_scale(_base_scale)
	if _label and not disabled:
		_label.add_theme_color_override("font_color", GOLD)


func _on_button_down() -> void:
	if disabled:
		return
	_tween_scale(_base_scale * PRESS_SCALE)
	if _label:
		_label.add_theme_color_override("font_color", GOLD_DIM)


func _on_button_up() -> void:
	if disabled:
		return
	if is_hovered():
		_tween_scale(_base_scale * HOVER_SCALE)
		if _label:
			_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.55, 1.0))
	else:
		_tween_scale(_base_scale)
		if _label:
			_label.add_theme_color_override("font_color", GOLD)
