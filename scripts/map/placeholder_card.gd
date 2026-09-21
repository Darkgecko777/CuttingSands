class_name PlaceholderCard
extends CanvasLayer

signal picked(choice_id: String)

const GOLD := Color(0.92, 0.78, 0.45, 1)
const INK := Color(0.93, 0.86, 0.72, 1)

var _root: Control
var _dim: ColorRect
var _center: CenterContainer
var _panel: PanelContainer
var _title: Label
var _body: Label
var _box: VBoxContainer


func _ready() -> void:
	layer = 40
	visible = false
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_dim = ColorRect.new()
	_dim.color = Color(0.05, 0.04, 0.03, 0.78)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_dim)
	_center = CenterContainer.new()
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_center)
	get_viewport().size_changed.connect(_fit_screen)
	_fit_screen()
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(440, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 1)
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	_panel.add_theme_stylebox_override("panel", style)
	_center.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	_panel.add_child(col)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", GOLD)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_title)
	_body = Label.new()
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_theme_font_size_override("font_size", 20)
	_body.add_theme_color_override("font_color", INK)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_body)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	col.add_child(_box)


func present(title: String, body: String, choices: Array) -> void:
	_fit_screen()
	_fit_width()
	_title.text = title
	_body.text = body
	for child in _box.get_children():
		child.queue_free()
	for raw in choices:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = raw
		var disabled := bool(choice.get("disabled", false))
		var btn := Button.new()
		btn.text = str(choice.get("text", "Continue"))
		btn.disabled = disabled
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_color_override("font_color", GOLD)
		btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.45, 0.32, 1))
		if not disabled:
			btn.pressed.connect(_pick.bind(str(choice.get("id", ""))))
		_box.add_child(btn)
	visible = true


func dismiss() -> void:
	visible = false


func _fit_width() -> void:
	var room := get_viewport().get_visible_rect().size.x - 80.0
	var wide := clampf(room, 280.0, 480.0)
	_panel.custom_minimum_size = Vector2(wide, 0)
	_title.custom_minimum_size = Vector2(wide - 56.0, 0)
	_body.custom_minimum_size = Vector2(wide - 56.0, 0)


func _fit_screen() -> void:
	var view := get_viewport().get_visible_rect().size
	_place(_root, view)
	_place(_dim, view)
	_place(_center, view)


func _place(node: Control, view: Vector2) -> void:
	node.position = Vector2.ZERO
	node.size = view


func _pick(choice_id: String) -> void:
	picked.emit(choice_id)
