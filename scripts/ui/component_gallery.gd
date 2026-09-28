extends Control
## One generated picture at a time. Open this scene and press F6.
## Files live in Assets/UI/stage. The block stage does not load them.

const STAGE := "res://Assets/UI/stage/"
const STOPS_PATH := "res://data/world/settlements.json"
const PAPER := Color(0.77, 0.71, 0.59, 1)
const GROUND := Color(0.16, 0.11, 0.08, 1)
const INK := Color(0.93, 0.86, 0.74, 1)
const MUTED := Color(0.62, 0.52, 0.38, 1)

const PIECES: Array = [
	["Road", "ground_road.png", Vector2(640, 360)],
	["Top banner", "banner_top.png", Vector2(960, 28)],
	["Bottom banner", "banner_bottom.png", Vector2(960, 68)],
	["Rod", "rod.png", Vector2(960, 44)],
	["Short tag", "tab_body.png", Vector2(92, 118)],
	["Open tag", "tab_body_hot.png", Vector2(92, 154)],
	["Pressed tag", "tab_body_pressed.png", Vector2(92, 118)],
	["Carry", "mark_carry.png", Vector2(64, 64)],
	["Person", "mark_person.png", Vector2(64, 64)],
	["Posted eyes", "mark_posted.png", Vector2(64, 64)],
	["Heard", "mark_heard.png", Vector2(64, 64)],
	["Chart mark", "mark_chart.png", Vector2(64, 64)],
	["Patron", "mark_patron.png", Vector2(64, 64)],
	["Clock", "mark_clock.png", Vector2(64, 64)],
	["Purse", "mark_purse.png", Vector2(64, 64)],
	["Burden", "mark_burden.png", Vector2(64, 64)],
	["Sky", "mark_sky.png", Vector2(64, 64)],
	["Pause", "mark_pause.png", Vector2(64, 64)],
	["Quiet circle", "seal_round.png", Vector2(96, 96)],
	["Current circle", "seal_round_hot.png", Vector2(96, 96)],
	["Pressed circle", "seal_round_pressed.png", Vector2(96, 96)],
	["Quiet seal", "seal_rect.png", Vector2(168, 58)],
	["Current seal", "seal_rect_hot.png", Vector2(168, 58)],
	["Pressed seal", "seal_rect_pressed.png", Vector2(168, 58)],
]


func _ready() -> void:
	var ground := ColorRect.new()
	ground.color = GROUND
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ground)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	scroll.add_child(margin)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	margin.add_child(body)
	_heading(body, "Pictures")
	_note(body, "Each file in Assets/UI/stage, alone. Wide pictures are reduced. Tags, marks, and seals are at the size the sample screen uses. A paper mat sits behind the picture so a transparent edge can be seen.")
	_heading(body, "Grounds")
	_piece(body, "Test ground", "ground_location.png", Vector2(640, 360))
	for stop in _stops():
		var row: Dictionary = stop
		_piece(body, str(row["name"]), "grounds/%s.png" % str(row["id"]), Vector2(640, 360))
	for item in PIECES:
		var spec: Array = item
		if str(spec[1]).begins_with("banner"):
			if str(spec[1]) == "banner_top.png":
				_heading(body, "Banners and book")
		elif str(spec[1]) == "tab_body.png":
			_heading(body, "Tags")
		elif str(spec[1]) == "mark_carry.png":
			_heading(body, "Marks")
		elif str(spec[1]) == "seal_round.png":
			_heading(body, "Seals")
		_piece(body, str(spec[0]), str(spec[1]), spec[2])


func _stops() -> Array:
	var found: Array = []
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(STOPS_PATH))
	if typeof(raw) != TYPE_DICTIONARY:
		return [{"id": "kharun", "name": "Kharûn"}]
	var book: Dictionary = raw
	for id in book.keys():
		var row: Dictionary = book[id]
		found.append({"id": str(id), "name": str(row.get("name", id))})
	return found


func _piece(host: VBoxContainer, title: String, file_name: String, size: Vector2) -> void:
	_heading(host, title)
	_note(host, file_name)
	var tex := _load(STAGE + file_name)
	if tex == null:
		host.add_child(_missing("No %s" % file_name))
		return
	var mat := ColorRect.new()
	mat.color = PAPER
	mat.custom_minimum_size = size + Vector2(16, 16)
	mat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_left = 8
	rect.offset_top = 8
	rect.offset_right = -8
	rect.offset_bottom = -8
	mat.add_child(rect)
	host.add_child(mat)


func _missing(text: String) -> Label:
	var label := Label.new()
	label.text = text
	_face(label, false, 14)
	label.add_theme_color_override("font_color", MUTED)
	return label


func _heading(host: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	_face(label, true, 18)
	host.add_child(label)


func _note(host: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(640, 0)
	_face(label, false, 14)
	label.add_theme_color_override("font_color", INK)
	host.add_child(label)


func _face(label: Label, title: bool, size: int) -> void:
	label.add_theme_font_override("font", InstrumentStyle.bold() if title else InstrumentStyle.regular())
	label.add_theme_font_size_override("font_size", size)
	if title:
		label.add_theme_color_override("font_color", INK)


func _load(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = load(path)
	return loaded as Texture2D
