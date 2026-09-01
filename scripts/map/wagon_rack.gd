class_name WagonRackView
extends RefCounted

const GOLD := Color(0.92, 0.78, 0.45, 1)
const MUTED := Color(0.75, 0.62, 0.42, 1)
const GHOST := Color(0.86, 0.28, 0.22, 1)


static func fill(grid: GridContainer, units: Array, on_unit: Callable, on_inspect: Callable = Callable()) -> void:
	for child in grid.get_children():
		child.queue_free()
	var packed: int = 0
	for unit in units:
		var rec: Dictionary = unit
		var good_id := str(rec.get("id", ""))
		var ghost := bool(rec.get("ghost", false))
		var span: int = CargoMath.size_of(good_id)
		for part in span:
			grid.add_child(_cell(good_id, ghost, part == 0, on_unit, on_inspect))
			packed += 1
	for _i in maxi(0, GameState.caravan_capacity - packed):
		grid.add_child(_empty())


static func _cell(good_id: String, ghost: bool, head: bool, on_unit: Callable, on_inspect: Callable) -> Button:
	var cell := Button.new()
	cell.custom_minimum_size = Vector2(72, 52)
	cell.text = GameState.get_good_name(good_id)
	cell.tooltip_text = GoodCopy.wagon_tooltip(good_id)
	var color := GHOST if ghost else GOLD
	cell.add_theme_color_override("font_color", color)
	cell.add_theme_color_override("font_hover_color", color)
	if on_inspect.is_valid():
		cell.mouse_entered.connect(on_inspect.bind(good_id))
	if head and on_unit.is_valid():
		cell.pressed.connect(on_unit.bind(good_id, ghost))
	else:
		cell.disabled = not head
		cell.focus_mode = Control.FOCUS_NONE
	return cell


static func _empty() -> Label:
	var cell := Label.new()
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cell.custom_minimum_size = Vector2(72, 52)
	cell.text = "—"
	cell.add_theme_color_override("font_color", MUTED)
	return cell
