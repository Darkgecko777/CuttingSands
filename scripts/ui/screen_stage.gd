extends Control
## Location frame. screen_stage.tscn is the block, primitives only.
## screen_sample.tscn is the same frame wearing Assets/UI/stage.
## Placement constants are the screen. Slots and keys are docs/UI_Review.md.

@export var sample_art := false

const STAGE := "res://Assets/UI/stage/"
const CHART := "res://Assets/map/cutting_sands_map_advanced.png"
const STOPS_PATH := "res://data/world/settlements.json"

const BANNER_H := 56
const BOOK_H := 148
const BOTTOM_H := 136
const BANNER_MARGIN_X := 22
const BANNER_MARGIN_Y := 12
const TAB_W := 62
const TAB_H := 118
const TAB_HOT := 24
const TAB_OVERLAP := 36
const TAB_GAP := 14
const TAB_SHIFT := 150

const PAPER := Color(0.77, 0.71, 0.59, 1)
const LEATHER := Color(0.24, 0.16, 0.11, 1)
const INK := Color(0.17, 0.14, 0.11, 1)
const INK_SOFT := Color(0.17, 0.14, 0.11, 0.55)
const WAX := Color(0.55, 0.23, 0.16, 1)
const PEWTER := Color(0.42, 0.40, 0.37, 1)
const LOC_FALLBACK := Color(0.46, 0.36, 0.26, 1)
const ROAD_FALLBACK := Color(0.30, 0.24, 0.18, 1)
const ON_WAX := Color(0.93, 0.86, 0.74, 1)

const TAGS: Array = [
	{"label": "Cargo", "mark": "mark_carry.png"},
	{"label": "Character", "mark": "mark_person.png"},
	{"label": "Agents", "mark": "mark_posted.png"},
	{"label": "Rumours", "mark": "mark_heard.png"},
	{"label": "Map", "mark": "mark_chart.png"},
]

var _stops: Array = []
var _stop := 0
var _tab := -1
var _yard := 1
var _road := false

var _ground_tex: TextureRect
var _ground_flat: ColorRect
var _place: Label
var _sky: Label
var _well: Control
var _well_body: Control
var _hint: Label
var _book: Control
var _shadow: TextureRect
var _top_banner: Control
var _bottom_banner: Control
var _tab_row: Control
var _tabs: Array[Button] = []
var _yards: Array[Button] = []


func _ready() -> void:
	_read_stops()
	_build_ground()
	_build_well()
	_build_banner(true)
	_build_banner(false)
	_build_tabs()
	_build_book()
	_stack_frame()
	_apply_stop()
	call_deferred("_layout_tabs")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_tabs()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var key := int(key_event.keycode)
	if key >= int(KEY_1) and key <= int(KEY_5):
		_toggle_tab(key - int(KEY_1))
	elif key == int(KEY_R):
		_road = not _road
		_apply_stop()
	elif key == int(KEY_BRACKETLEFT):
		_step_stop(-1)
	elif key == int(KEY_BRACKETRIGHT):
		_step_stop(1)


func _read_stops() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(STOPS_PATH))
	if typeof(raw) != TYPE_DICTIONARY:
		_stops = [{"id": "kharun", "name": "Kharûn", "type": "city"}]
		return
	var book: Dictionary = raw
	for id in book.keys():
		var row: Dictionary = book[id]
		_stops.append({
			"id": str(id),
			"name": str(row.get("name", id)),
			"type": str(row.get("type", "")),
		})
	for i in _stops.size():
		if str(_stops[i]["id"]) == "kharun":
			_stop = i
			return


func _build_ground() -> void:
	_ground_flat = ColorRect.new()
	_ground_flat.color = LOC_FALLBACK
	_ground_flat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ground_flat.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ground_flat)
	_ground_tex = TextureRect.new()
	_ground_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ground_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ground_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_ground_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ground_tex.visible = false
	add_child(_ground_tex)


func _build_well() -> void:
	_well = Control.new()
	_well.set_anchors_preset(Control.PRESET_FULL_RECT)
	_well.offset_top = BANNER_MARGIN_Y + BANNER_H + BOOK_H
	_well.offset_bottom = -(BANNER_MARGIN_Y + BOTTOM_H)
	_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_well)
	_well_body = Control.new()
	_well_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_well_body.offset_left = 24
	_well_body.offset_top = TAB_H + TAB_HOT - TAB_OVERLAP + 8
	_well_body.offset_right = -24
	_well_body.offset_bottom = -12
	_well_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_well.add_child(_well_body)
	_hint = _label("", 14, false)
	_hint.add_theme_color_override("font_color", Color(ON_WAX, 0.85))
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_left = 28
	_hint.offset_top = -48
	_hint.offset_bottom = -22
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_well.add_child(_hint)


func _build_banner(top: bool) -> void:
	var banner := Control.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if top:
		_top_banner = banner
	else:
		_bottom_banner = banner
	banner.offset_left = BANNER_MARGIN_X
	banner.offset_right = -BANNER_MARGIN_X
	if top:
		banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
		banner.offset_left = BANNER_MARGIN_X
		banner.offset_right = -BANNER_MARGIN_X
		banner.offset_top = BANNER_MARGIN_Y
		banner.offset_bottom = BANNER_MARGIN_Y + BANNER_H
	else:
		banner.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		banner.offset_left = BANNER_MARGIN_X
		banner.offset_right = -BANNER_MARGIN_X
		banner.offset_top = -(BANNER_MARGIN_Y + BOTTOM_H)
		banner.offset_bottom = -BANNER_MARGIN_Y
	add_child(banner)
	var file := "banner_top.png" if top else "banner_bottom.png"
	_paint_band(banner, file, PAPER, true)
	if top:
		_build_facts(banner)
	else:
		_build_yards(banner)


func _build_facts(banner: Control) -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_top = 12
	row.offset_right = -12
	row.offset_bottom = -10
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	banner.add_child(row)
	row.add_child(_mark_slot("mark_patron.png", Vector2(18, 18), "K"))
	_place = _label("", 16, true)
	row.add_child(_place)
	row.add_child(_spacer())
	row.add_child(_fact("mark_clock.png", "Day 12"))
	row.add_child(_fact("mark_purse.png", "120"))
	row.add_child(_fact("mark_burden.png", "4 / 16   12 / 36"))
	var sky_row := _fact("mark_sky.png", "")
	_sky = sky_row.get_child(1) as Label
	row.add_child(sky_row)
	row.add_child(_round_seal())


func _build_yards(banner: Control) -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 28
	center.offset_bottom = -26
	banner.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 36)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(row)
	for yard_name in ["House", "Market", "Outyard"]:
		var btn := Button.new()
		btn.text = yard_name
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(168, 58)
		btn.add_theme_font_override("font", InstrumentStyle.bold())
		btn.add_theme_font_size_override("font_size", 16)
		_bare(btn)
		var index := _yards.size()
		btn.pressed.connect(_select_yard.bind(index))
		_yards.append(btn)
		row.add_child(btn)


func _stack_frame() -> void:
	# The rod covers the rolled top of each scroll.
	move_child(_shadow, 3)
	move_child(_tab_row, 4)
	move_child(_book, 5)
	move_child(_top_banner, 6)
	move_child(_bottom_banner, 7)


func _build_book() -> void:
	var top := BANNER_MARGIN_Y + BANNER_H
	_shadow = TextureRect.new()
	_shadow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_shadow.offset_left = 40
	_shadow.offset_right = -40
	_shadow.offset_top = top + BOOK_H - 8
	_shadow.offset_bottom = top + BOOK_H + 20
	_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shadow.stretch_mode = TextureRect.STRETCH_SCALE
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow.texture = _load_tex(STAGE + "rod_shadow.png")
	add_child(_shadow)
	_book = Control.new()
	var book := _book
	book.set_anchors_preset(Control.PRESET_TOP_WIDE)
	book.offset_left = 0
	book.offset_right = 0
	book.offset_top = top
	book.offset_bottom = top + BOOK_H
	book.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(book)
	_paint_band(book, "rod.png", LEATHER, false)


func _build_tabs() -> void:
	_tab_row = Control.new()
	_tab_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var book_bottom := BANNER_MARGIN_Y + BANNER_H + BOOK_H
	_tab_row.offset_top = book_bottom - TAB_OVERLAP
	_tab_row.offset_bottom = book_bottom - TAB_OVERLAP + TAB_H + TAB_HOT
	_tab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tab_row)
	for i in TAGS.size():
		var spec: Dictionary = TAGS[i]
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.flat = true
		_bare(btn)
		var index := i
		btn.pressed.connect(_toggle_tab.bind(index))
		_tab_row.add_child(btn)
		_tabs.append(btn)
		var leather := ColorRect.new()
		leather.name = "Leather"
		leather.color = LEATHER
		leather.mouse_filter = Control.MOUSE_FILTER_IGNORE
		leather.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.add_child(leather)
		var body := _load_tex(STAGE + "tab_body.png")
		if body:
			var rect := TextureRect.new()
			rect.name = "Body"
			rect.texture = body
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_SCALE
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			btn.add_child(rect)
			leather.visible = false
		var mark := TextureRect.new()
		mark.name = "Mark"
		var mark_tex := _load_tex(STAGE + str(spec["mark"]))
		mark.texture = mark_tex
		mark.visible = mark_tex != null
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.set_anchors_preset(Control.PRESET_CENTER_TOP)
		mark.offset_left = -14
		mark.offset_right = 14
		mark.offset_top = 34
		mark.offset_bottom = 62
		btn.add_child(mark)
		var word := _label(str(spec["label"]), 12, true)
		word.add_theme_color_override("font_color", INK)
		word.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		word.offset_top = -28
		word.offset_bottom = -6
		word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.add_child(word)


func _layout_tabs() -> void:
	if _tab_row == null or _tab_row.size.x < 1.0:
		return
	var total := TAGS.size() * TAB_W + (TAGS.size() - 1) * TAB_GAP
	var x := (_tab_row.size.x - total) * 0.5 + TAB_SHIFT
	for i in _tabs.size():
		var btn := _tabs[i]
		var hot := i == _tab
		btn.position = Vector2(x, 0)
		btn.size = Vector2(TAB_W, TAB_H + (TAB_HOT if hot else 0))
		x += TAB_W + TAB_GAP
		var body := btn.get_node_or_null("Body") as TextureRect
		if body:
			var hot_tex := _load_tex(STAGE + "tab_body_hot.png") if hot else null
			body.texture = hot_tex if hot_tex else _load_tex(STAGE + "tab_body.png")


func _apply_stop() -> void:
	var stop: Dictionary = _stops[_stop]
	var place_name := str(stop["name"])
	_place.text = "Bound for %s" % place_name if _road else place_name
	_sky.text = "Clear" if _road else ""
	var file := "ground_road.png" if _road else "grounds/%s.png" % str(stop["id"])
	var tex := _load_tex(STAGE + file)
	if tex == null and not _road:
		tex = _load_tex(STAGE + "ground_location.png")
	_ground_tex.texture = tex
	_ground_tex.visible = tex != null
	_ground_flat.visible = tex == null
	_ground_flat.color = ROAD_FALLBACK if _road else LOC_FALLBACK
	var house := str(stop["type"]) == "city" or str(stop["id"]) == "ghorath"
	if not house and _yard == 0:
		_yard = 1
	_yards[0].visible = house
	_paint_yards()
	_layout_tabs()
	_fill_well()
	var kind := "Sample" if sample_art else "Block"
	_hint.text = "%s · %s    [ ] stop    R road    1–5 tag, again to close" % [kind, place_name]


func _fill_well() -> void:
	for child in _well_body.get_children():
		child.queue_free()
	if _tab < 0:
		return
	if _tab == 4:
		var plate := TextureRect.new()
		plate.set_anchors_preset(Control.PRESET_FULL_RECT)
		plate.offset_left = 12
		plate.offset_right = -12
		plate.offset_top = TAB_H + TAB_HOT - TAB_OVERLAP + 6
		plate.offset_bottom = -8
		plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.texture = _load_tex(CHART)
		_well.add_child(plate)
		return
	if _tab == 0:
		var columns := HBoxContainer.new()
		columns.set_anchors_preset(Control.PRESET_FULL_RECT)
		columns.add_theme_constant_override("separation", 48)
		_well_body.add_child(columns)
		columns.add_child(_region("Hold"))
		columns.add_child(_region("Note"))
		return
	var spec: Dictionary = TAGS[_tab]
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_well_body.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	center.add_child(column)
	var title := _label(str(spec["label"]), 22, true)
	title.add_theme_color_override("font_color", ON_WAX)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var aside := "Placed. Not in play." if _tab == 1 or _tab == 2 else "A list in this space."
	var note := _label(aside, 14, false)
	note.add_theme_color_override("font_color", Color(ON_WAX, 0.75))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(note)


func _region(title: String) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	var heading := _label(title, 18, true)
	heading.add_theme_color_override("font_color", ON_WAX)
	box.add_child(heading)
	var note := _label("Open space. No frame.", 14, false)
	note.add_theme_color_override("font_color", Color(ON_WAX, 0.75))
	box.add_child(note)
	return box


func _paint_yards() -> void:
	for i in _yards.size():
		var btn := _yards[i]
		var hot := i == _yard and not _road
		var style := _seal_style(hot, false)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", _seal_style(true, false))
		btn.add_theme_stylebox_override("disabled", _seal_style(false, false))
		var color := ON_WAX if hot else INK
		if _road:
			color = Color(INK, 0.45)
		btn.add_theme_color_override("font_color", color)
		btn.add_theme_color_override("font_hover_color", color)
		btn.add_theme_color_override("font_pressed_color", ON_WAX)
		btn.add_theme_color_override("font_disabled_color", Color(INK, 0.45))
		btn.disabled = _road
		btn.modulate = Color(1, 1, 1, 0.45) if _road else Color.WHITE


func _toggle_tab(index: int) -> void:
	_tab = -1 if _tab == index else index
	_layout_tabs()
	_fill_well()


func _select_yard(index: int) -> void:
	if _road:
		return
	_yard = index
	_paint_yards()


func _step_stop(delta: int) -> void:
	if _stops.is_empty():
		return
	_stop = (_stop + delta) % _stops.size()
	if _stop < 0:
		_stop += _stops.size()
	_apply_stop()


func _paint_band(host: Control, file_name: String, fallback: Color, lace: bool) -> void:
	var tex := _load_tex(STAGE + file_name)
	if tex:
		var rect := TextureRect.new()
		rect.texture = tex
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(rect)
		return
	var flat := ColorRect.new()
	flat.color = fallback
	flat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flat.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(flat)
	if lace:
		var frame := Panel.new()
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.offset_left = 16
		frame.offset_top = 12
		frame.offset_right = -16
		frame.offset_bottom = -12
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0, 0, 0, 0)
		box.border_color = Color(INK, 0.45)
		box.set_border_width_all(1)
		frame.add_theme_stylebox_override("panel", box)
		host.add_child(frame)
	var caption := _label(file_name, 12, false)
	caption.add_theme_color_override("font_color", ON_WAX if fallback == LEATHER else INK_SOFT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if lace:
		caption.set_anchors_preset(Control.PRESET_CENTER_TOP)
		caption.offset_left = -140
		caption.offset_right = 140
		caption.offset_top = 0
		caption.offset_bottom = 16
	else:
		caption.set_anchors_preset(Control.PRESET_CENTER)
	host.add_child(caption)


func _fact(mark_file: String, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_mark_slot(mark_file, Vector2(14, 14), ""))
	row.add_child(_label(text, 13, false))
	return row


func _mark_slot(file_name: String, slot: Vector2, fallback_text: String) -> Control:
	var tex := _load_tex(STAGE + file_name)
	if tex:
		var rect := TextureRect.new()
		rect.texture = tex
		rect.custom_minimum_size = slot
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return rect
	if fallback_text == "":
		return Control.new()
	var label := _label(fallback_text, 20, true)
	label.custom_minimum_size = slot
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _round_seal() -> Button:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(30, 30)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bare(btn)
	var style := _seal_style(false, true)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", _seal_style(true, true))
	btn.add_theme_stylebox_override("pressed", _seal_style(true, true))
	var mark := _load_tex(STAGE + "mark_pause.png")
	if mark:
		btn.icon = mark
		btn.expand_icon = true
	return btn


func _seal_style(hot: bool, round: bool) -> StyleBox:
	var file := "seal_round_hot.png" if hot else "seal_round.png"
	if not round:
		file = "seal_rect_hot.png" if hot else "seal_rect.png"
	var tex := _load_tex(STAGE + file)
	if tex:
		var box := StyleBoxTexture.new()
		box.texture = tex
		return box
	var flat := StyleBoxFlat.new()
	flat.bg_color = WAX if hot else PEWTER
	flat.set_corner_radius_all(28 if round else 16)
	var pad := 0 if round else 12
	flat.content_margin_left = pad
	flat.content_margin_right = pad
	flat.content_margin_top = 0 if round else 6
	flat.content_margin_bottom = 0 if round else 6
	return flat


func _spacer() -> Control:
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return space


func _label(text: String, size: int, title: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", InstrumentStyle.bold() if title else InstrumentStyle.regular())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", INK)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _bare(btn: Button) -> void:
	var empty := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state_name, empty)


func _load_tex(path: String) -> Texture2D:
	if not sample_art and path.begins_with(STAGE):
		return null
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = load(path)
	return loaded as Texture2D
