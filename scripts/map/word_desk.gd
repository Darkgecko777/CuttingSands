class_name WordDesk
extends RefCounted

const MUTED := Color(0.75, 0.62, 0.42, 1)
const GOLD := Color(0.92, 0.78, 0.45, 1)

var selected_id: String = ""
var on_pick: Callable = Callable()


func render(box: VBoxContainer, title: Label, meta: Label, body: Label) -> void:
	for child in box.get_children():
		child.queue_free()
	var rows: Array = RumourBook.tickets()
	if rows.is_empty():
		title.text = "Rumours"
		meta.text = ""
		body.text = "No rumours yet. Socialize in the Outyard."
		var note := Label.new()
		note.text = "No rumours yet"
		note.add_theme_color_override("font_color", MUTED)
		box.add_child(note)
		return
	if selected_id.is_empty() or RumourBook.ticket(selected_id).is_empty():
		selected_id = str(rows[0].get("id", ""))
	_paint_selected(title, meta, body)
	var head := Label.new()
	head.text = "Rumours"
	head.add_theme_color_override("font_color", MUTED)
	box.add_child(head)
	for row in rows:
		box.add_child(_row(row))


func _paint_selected(title: Label, meta: Label, body: Label) -> void:
	var rec := RumourBook.ticket(selected_id)
	if rec.is_empty():
		title.text = "Rumours"
		meta.text = ""
		body.text = ""
		return
	var origin := str(rec.get("origin_id", ""))
	var place := WorldBook.settlement_name(origin)
	title.text = place
	meta.text = "%s  ·  %s" % [RumourBook.stars_text(int(rec.get("stars", 1))), RumourBook.life_text(rec)]
	body.text = "An expedition at %s. Walk it from that Outyard. The wagon stays in the yard." % place


func _row(rec: Dictionary) -> Button:
	var btn := Button.new()
	var place := WorldBook.settlement_name(str(rec.get("origin_id", "")))
	var ticket_id := str(rec.get("id", ""))
	btn.text = "%s  %s" % [RumourBook.stars_text(int(rec.get("stars", 1))), place]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_color_override("font_color", GOLD)
	btn.custom_minimum_size = Vector2(0, 40)
	InstrumentStyle.row(btn, ticket_id == selected_id)
	btn.tooltip_text = RumourBook.life_text(rec)
	btn.pressed.connect(_select.bind(ticket_id))
	return btn


func _select(ticket_id: String) -> void:
	selected_id = ticket_id
	if on_pick.is_valid():
		on_pick.call(ticket_id)
