class_name WordDesk
extends RefCounted

const MUTED := Color(0.75, 0.62, 0.42, 1)
const GOLD := Color(0.92, 0.78, 0.45, 1)

var selected_id: String = ""
var on_pick: Callable = Callable()


func render(box: VBoxContainer, title: Label, meta: Label, body: Label) -> void:
	for child in box.get_children():
		child.queue_free()
	var slips: Array = WordBook.all_slips()
	if slips.is_empty():
		title.text = "Rumours"
		meta.text = ""
		body.text = "No word yet. Walk a stall. Arrival notes collect here."
		var note := Label.new()
		note.text = "No word yet"
		note.add_theme_color_override("font_color", MUTED)
		box.add_child(note)
		return
	if selected_id.is_empty() or WordBook.slip(selected_id).is_empty():
		selected_id = str(slips[0].get("id", ""))
	_paint_selected(title, meta, body)
	var head := Label.new()
	head.text = "Slips"
	head.add_theme_color_override("font_color", MUTED)
	box.add_child(head)
	for row in slips:
		box.add_child(_row(row))


func _paint_selected(title: Label, meta: Label, body: Label) -> void:
	var rec := WordBook.slip(selected_id)
	if rec.is_empty():
		title.text = "Rumours"
		meta.text = ""
		body.text = ""
		return
	var city_id := str(rec.get("city_id", ""))
	var good_id := str(rec.get("good_id", ""))
	title.text = WorldBook.settlement_name(city_id) if not city_id.is_empty() else "Rumours"
	var bits: PackedStringArray = [WordBook.stars_text(int(rec.get("stars", 1)))]
	bits.append(WordBook.age_text(int(rec.get("minted_day", GameState.day))))
	if not good_id.is_empty():
		bits.append(WorldBook.good_name(good_id))
	meta.text = "  ·  ".join(bits)
	body.text = str(rec.get("text", ""))
	if not good_id.is_empty():
		body.text += "\n\n" + GoodCopy.context_block(good_id, city_id)


func _row(rec: Dictionary) -> Button:
	var btn := Button.new()
	var city_id := str(rec.get("city_id", ""))
	var good_id := str(rec.get("good_id", ""))
	var label := WorldBook.settlement_name(city_id)
	if not good_id.is_empty():
		label += "  ·  " + WorldBook.good_name(good_id)
	btn.text = "%s  %s" % [WordBook.stars_text(int(rec.get("stars", 1))), label]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_color_override("font_color", GOLD)
	btn.tooltip_text = str(rec.get("text", ""))
	var slip_id := str(rec.get("id", ""))
	btn.pressed.connect(_select.bind(slip_id))
	return btn


func _select(slip_id: String) -> void:
	selected_id = slip_id
	if on_pick.is_valid():
		on_pick.call(slip_id)
