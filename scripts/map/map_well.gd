class_name MapWell
extends RefCounted

const MAP_NODES_PATH := "res://data/world/map_nodes.json"
const MAP_SCENE := "res://scenes/map/map.tscn"
const CARAVAN_SPRITE := "res://Assets/sprites/prototype_caravan_icon.png"
const REF_SIZE := Vector2(1920, 1080)
const VIEW_SIZE := Vector2(1200, 800)
const ZOOM_MIN := 1.0
const ZOOM_MAX := 2.0
const ZOOM_DEFAULT := 1.5
const ZOOM_STEP := 0.1
const GOLD := Color(0.92, 0.78, 0.45, 1)
const INK := Color(0.85, 0.78, 0.66, 1)
const CHIP := Vector2(12, 12)
const CHIP_PLAYER := Vector2(14, 14)
const CHIP_ROAD := Vector2(24, 24)
const CHIP_ROAD_PLAYER := Vector2(26, 26)
const CHIP_CAP := 4
const CHIP_RING := Color(0.98, 0.93, 0.78, 1)
const SLICE_SECS := 4.0

var shell: Node
var map_clip: Control
var map_layer: Control
var markers_layer: Control
var chips_layer: Control
var nodes: Dictionary = {}
var paths: Dictionary = {}
var max_path_len := 1.0
var wagon: Sprite2D
var hop_tween: Tween
var chips_enlarged := false
var hop_from := ""
var hop_to := ""
var zoom := ZOOM_DEFAULT
var plate_size := REF_SIZE
var res_scale := 1.0
var content: Control
var dragging := false
var drag_last := Vector2.ZERO
var selected_kind := "caravan"
var selected_id := ""


func setup(host: Node, clip: Control, layer: Control, markers: Control) -> void:
	shell = host
	map_clip = clip
	map_layer = layer
	markers_layer = markers
	selected_id = GameState.PLAYER_CARAVAN_ID
	nodes = _load_nodes()
	_fit_plate()
	_ensure_chips_layer()
	_ingest_paths()
	_build_markers()
	_make_wagon()
	apply_zoom(Vector2.ZERO, false)
	center_on_city(GameState.caravan_city(GameState.PLAYER_CARAVAN_ID))
	map_clip.gui_input.connect(on_gui_input)
	map_clip.resized.connect(clamp_map)


func _load_nodes() -> Dictionary:
	if not FileAccess.file_exists(MAP_NODES_PATH):
		return {}
	var file := FileAccess.open(MAP_NODES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			dragging = mouse.pressed
			drag_last = mouse.position
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			_nudge_zoom(ZOOM_STEP, mouse.position)
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			_nudge_zoom(-ZOOM_STEP, mouse.position)
	elif event is InputEventMouseMotion and dragging:
		map_layer.position += event.position - drag_last
		drag_last = event.position
		clamp_map()


func center_on_selected() -> void:
	if selected_kind == "settlement":
		center_on_city(selected_id)
	elif selected_kind == "caravan":
		if GameState.is_on_road():
			focus_hop_mid()
		else:
			center_on_city(GameState.caravan_city(selected_id))


func center_on_city(city_id: String) -> void:
	var pos: Dictionary = nodes.get(city_id, {})
	if pos.is_empty():
		clamp_map()
		return
	var point := Vector2(float(pos.get("x", 0)), float(pos.get("y", 0)))
	var view := map_clip.size if map_clip.size.x >= 8.0 else VIEW_SIZE
	var cam := _cam_scale()
	map_layer.scale = Vector2(cam, cam)
	map_layer.position = Vector2(view.x * 0.5, view.y * 0.5) - point * zoom
	clamp_map()


func show_atlas() -> void:
	chips_enlarged = false
	hide_wagon()
	_show_chips(true)
	var view := map_clip.size if map_clip.size.x >= 8.0 else VIEW_SIZE
	if plate_size.x < 1.0 or plate_size.y < 1.0:
		clamp_map()
		return
	var fit := minf(view.x / plate_size.x, view.y / plate_size.y)
	zoom = clampf(fit * maxf(res_scale, 0.01), 0.2, ZOOM_MAX)
	apply_zoom(Vector2.ZERO, false)
	paint_chips()


func clamp_map() -> void:
	var view := map_clip.size if map_clip.size.x >= 8.0 else VIEW_SIZE
	var pos := map_layer.position
	var scaled := plate_size * _cam_scale()
	pos.x = clampf(pos.x, view.x - scaled.x, 0.0) if scaled.x > view.x else (view.x - scaled.x) * 0.5
	pos.y = clampf(pos.y, view.y - scaled.y, 0.0) if scaled.y > view.y else (view.y - scaled.y) * 0.5
	map_layer.position = pos


func _cam_scale() -> float:
	return zoom / maxf(res_scale, 0.01)


func _nudge_zoom(delta: float, pivot: Vector2) -> void:
	zoom = clampf(zoom + delta, ZOOM_MIN, ZOOM_MAX)
	apply_zoom(pivot, true)


func apply_zoom(pivot: Vector2, toward_cursor: bool) -> void:
	var cam := _cam_scale()
	var old_scale := map_layer.scale.x if map_layer.scale.x > 0.01 else cam
	if toward_cursor:
		var world := (pivot - map_layer.position) / old_scale
		map_layer.scale = Vector2(cam, cam)
		map_layer.position = pivot - world * cam
	else:
		map_layer.scale = Vector2(cam, cam)
	clamp_map()


func _fit_plate() -> void:
	var plate := map_layer.get_node_or_null("MapImage") as TextureRect
	plate_size = REF_SIZE
	res_scale = 1.0
	if plate and plate.texture:
		plate_size = plate.texture.get_size()
		plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		plate.position = Vector2.ZERO
		plate.size = plate_size
		plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if plate_size.x > 1.0:
		res_scale = plate_size.x / REF_SIZE.x
	map_layer.size = plate_size
	content = map_layer.get_node_or_null("Content") as Control
	if content == null:
		content = Control.new()
		content.name = "Content"
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_layer.add_child(content)
	content.position = Vector2.ZERO
	content.scale = Vector2(res_scale, res_scale)
	if markers_layer.get_parent() != content:
		markers_layer.reparent(content)


func _ingest_paths() -> void:
	paths.clear()
	max_path_len = 1.0
	if not ResourceLoader.exists(MAP_SCENE):
		return
	var packed := load(MAP_SCENE) as PackedScene
	if packed == null:
		return
	var dummy: Node = packed.instantiate()
	map_layer.add_child(dummy)
	for child in dummy.get_children():
		if not (child is Path2D):
			continue
		var path_node: Path2D = child
		var curve: Curve2D = path_node.curve
		if curve == null or curve.point_count < 2:
			continue
		var key := _path_key_from_name(path_node.name)
		if key.is_empty():
			continue
		max_path_len = maxf(max_path_len, curve.get_baked_length())
		var start: Vector2 = curve.get_point_position(0)
		var finish: Vector2 = curve.get_point_position(curve.point_count - 1)
		dummy.remove_child(path_node)
		content.add_child(path_node)
		paths[key] = {"path": path_node, "a": _city_near(start), "b": _city_near(finish)}
	dummy.queue_free()


func _path_key_from_name(route_name: String) -> String:
	var n := route_name
	if n.begins_with("Route_"):
		n = n.substr(6)
	var parts := n.split("_")
	if parts.size() < 2:
		return ""
	return GameState._link_key(_norm_place(parts[0]), _norm_place(parts[1]))


func _norm_place(part: String) -> String:
	var s := part.to_lower()
	if s == "torvern":
		return "torven"
	if s == "sarnsrest" or s == "sarn":
		return "sarns_rest"
	return s


func _city_near(point: Vector2) -> String:
	var best := ""
	var best_d := INF
	for city_id in nodes.keys():
		var d := _node_pos(city_id).distance_to(point)
		if d < best_d:
			best_d = d
			best = city_id
	return best


func _node_pos(city_id: String) -> Vector2:
	var pos: Dictionary = nodes.get(city_id, {})
	if pos.is_empty():
		return Vector2.ZERO
	return Vector2(float(pos.get("x", 0)), float(pos.get("y", 0)))


func _make_wagon() -> void:
	wagon = Sprite2D.new()
	wagon.texture = load(CARAVAN_SPRITE)
	wagon.centered = true
	wagon.visible = false
	wagon.z_index = 10
	content.add_child(wagon)


func _route_for(a: String, b: String) -> Dictionary:
	var record: Variant = paths.get(GameState._link_key(a, b), {})
	return record if typeof(record) == TYPE_DICTIONARY else {}


func _sample_route(from_id: String, to_id: String, progress: float) -> Vector2:
	var route := _route_for(from_id, to_id)
	var path: Path2D = route.get("path") as Path2D
	var t := clampf(progress, 0.0, 1.0)
	if path and path.curve and path.curve.get_baked_length() > 0.0:
		var start_r := 0.0 if str(route.get("a", "")) == from_id else 1.0
		var end_r := 1.0 - start_r
		var ratio := lerpf(start_r, end_r, t)
		return path.curve.sample_baked(ratio * path.curve.get_baked_length())
	return _node_pos(from_id).lerp(_node_pos(to_id), t)


func caravan_map_pos(caravan_id: String) -> Vector2:
	var record: Dictionary = GameState.get_caravan(caravan_id)
	if record.is_empty():
		return _node_pos(GameState.current_city_id)
	if str(record.get("status", "idle")) != "transit":
		return _node_pos(str(record.get("at", GameState.current_city_id)))
	var t := GameState.player_visual_progress() if caravan_id == GameState.PLAYER_CARAVAN_ID else float(record.get("progress", 0.0))
	return _sample_route(str(record.get("from", "")), str(record.get("to", "")), t)


func pause_watch() -> void:
	if hop_tween and hop_tween.is_valid() and hop_tween.is_running():
		hop_tween.pause()


func resume_watch() -> void:
	chips_enlarged = true
	_show_chips(true)
	if wagon:
		wagon.visible = GameState.is_on_road()
	if GameState.is_on_road():
		focus_hop_mid()
		wagon.position = caravan_map_pos(GameState.PLAYER_CARAVAN_ID)
	if hop_tween and hop_tween.is_valid() and not hop_tween.is_running():
		hop_tween.play()


func focus_hop_mid(from_id: String = "", to_id: String = "") -> void:
	if not from_id.is_empty():
		hop_from = from_id
	if not to_id.is_empty():
		hop_to = to_id
	if hop_from.is_empty() or hop_to.is_empty():
		hop_from = str(GameState.transit.get("from", hop_from))
		hop_to = str(GameState.transit.get("to", hop_to))
	if hop_from.is_empty() or hop_to.is_empty():
		return
	zoom = ZOOM_DEFAULT
	var point := _node_pos(hop_from).lerp(_node_pos(hop_to), 0.5)
	var view := map_clip.size if map_clip.size.x >= 8.0 else VIEW_SIZE
	var cam := _cam_scale()
	map_layer.scale = Vector2(cam, cam)
	map_layer.position = Vector2(view.x * 0.5, view.y * 0.5) - point * cam
	clamp_map()


func play_hop(from_id: String, to_id: String) -> void:
	if hop_tween:
		hop_tween.kill()
	chips_enlarged = true
	wagon.visible = true
	if wagon.get_parent() != content:
		wagon.reparent(content)
	GameState.watch_lerp = 0.0
	GameState.pending_watch_hours = 0
	wagon.position = caravan_map_pos(GameState.PLAYER_CARAVAN_ID)
	focus_hop_mid(from_id, to_id)
	_show_chips(true)
	shell._show_transit_panel()
	_run_watch_tween()


func _run_watch_tween() -> void:
	if hop_tween:
		hop_tween.kill()
	var slice := GameState.travel_slice_hours()
	if slice <= 0:
		shell._complete_hop()
		return
	GameState.pending_watch_hours = slice
	GameState.watch_lerp = 0.0
	wagon.visible = true
	wagon.position = caravan_map_pos(GameState.PLAYER_CARAVAN_ID)
	paint_chips()
	hop_tween = shell.create_tween()
	hop_tween.tween_method(_on_watch_progress, 0.0, 1.0, _slice_seconds(slice))
	hop_tween.finished.connect(_on_watch_finished, CONNECT_ONE_SHOT)


func _on_watch_progress(t: float) -> void:
	GameState.watch_lerp = t
	if wagon:
		wagon.position = caravan_map_pos(GameState.PLAYER_CARAVAN_ID)
	if chips_layer and chips_layer.visible:
		paint_chips()


func _on_watch_finished() -> void:
	var slice := GameState.pending_watch_hours
	GameState.advance_hours(slice)
	if GameState.player_remaining_hours() <= 0:
		shell._complete_hop()
		return
	_run_watch_tween()
	shell._refresh_header()


func skip_hop() -> void:
	if hop_tween:
		hop_tween.kill()
	var slice := GameState.travel_slice_hours()
	if slice <= 0:
		shell._complete_hop()
		return
	GameState.advance_hours(slice)
	if GameState.player_remaining_hours() <= 0:
		shell._complete_hop()
		return
	_run_watch_tween()
	if int(shell.get("_mode")) != 0:
		pause_watch()
		if int(shell.get("_mode")) == 2:
			show_atlas()
	shell._refresh_header()


func _slice_seconds(h: int) -> float:
	return clampf(SLICE_SECS * (float(h) / float(GameState.HOURS_PER_WATCH)), 1.5, 5.0)


func hide_wagon() -> void:
	chips_enlarged = false
	if wagon:
		wagon.visible = false


func _build_markers() -> void:
	for child in markers_layer.get_children():
		child.queue_free()
	for city_id in nodes.keys():
		var pos: Dictionary = nodes[city_id]
		var btn := Button.new()
		btn.name = city_id
		btn.custom_minimum_size = Vector2(22, 22)
		btn.position = Vector2(float(pos.get("x", 0)), float(pos.get("y", 0))) - Vector2(11, 11)
		btn.focus_mode = Control.FOCUS_NONE
		btn.tooltip_text = GameState.get_settlement_name(city_id)
		btn.text = GameState.get_settlement_name(city_id).substr(0, 1).to_upper()
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_marker_pressed.bind(city_id))
		markers_layer.add_child(btn)
	paint_markers()


func _on_marker_pressed(city_id: String) -> void:
	shell._set_mode(shell.Mode.MAP)
	shell._select_item("settlement", city_id)


func paint_markers() -> void:
	for btn in markers_layer.get_children():
		if not btn is Button:
			continue
		var city_id := btn.name
		var here := city_id == GameState.current_city_id and not GameState.is_on_road()
		var selected := selected_kind == "settlement" and selected_id == city_id
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(11)
		box.set_border_width_all(2)
		if here:
			box.bg_color = Color(0.72, 0.52, 0.18, 0.95)
			box.border_color = Color(0.95, 0.82, 0.40, 1)
			btn.add_theme_color_override("font_color", Color(0.12, 0.08, 0.04, 1))
		elif selected:
			box.bg_color = Color(0.28, 0.20, 0.10, 0.95)
			box.border_color = GOLD
			btn.add_theme_color_override("font_color", GOLD)
		else:
			box.bg_color = Color(0.16, 0.11, 0.07, 0.88)
			box.border_color = Color(0.55, 0.42, 0.24, 1)
			btn.add_theme_color_override("font_color", INK)
		btn.add_theme_stylebox_override("normal", box)
		btn.add_theme_stylebox_override("hover", box)
		btn.add_theme_stylebox_override("pressed", box)
	if chips_layer and chips_layer.visible:
		paint_chips()


func _ensure_chips_layer() -> void:
	if chips_layer != null and is_instance_valid(chips_layer):
		return
	chips_layer = Control.new()
	chips_layer.name = "Chips"
	chips_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips_layer.z_index = 8
	chips_layer.visible = false
	content.add_child(chips_layer)


func _show_chips(on: bool) -> void:
	_ensure_chips_layer()
	chips_layer.visible = on
	if on:
		paint_chips()
	elif chips_layer:
		_clear_chips()


func _clear_chips() -> void:
	if chips_layer == null:
		return
	for child in chips_layer.get_children():
		chips_layer.remove_child(child)
		child.free()


func paint_chips() -> void:
	_ensure_chips_layer()
	_clear_chips()
	if not chips_layer.visible:
		return
	var live := chips_enlarged
	var player_here := ""
	var player_on_wire := GameState.is_on_road()
	if not player_on_wire:
		player_here = GameState.current_city_id
	for city_id in nodes.keys():
		_paint_town_chips(str(city_id), player_here == str(city_id), live)
	_paint_road_chips(player_on_wire and not live, live)


func _paint_town_chips(city_id: String, show_player: bool, live: bool) -> void:
	var npc_ids: Array = StringBook.ids_visual_at(city_id) if live else StringBook.ids_stamp_at(city_id)
	if not show_player and npc_ids.is_empty():
		return
	var slots: Array = []
	if show_player:
		slots.append({"player": true, "house_id": GameState.selected_house_id, "chair": 0})
	for token_id in npc_ids:
		var token: Dictionary = GameState.string_tokens.get(token_id, {})
		slots.append({"player": false, "house_id": str(token.get("house_id", "")), "chair": int(token.get("chair", 0))})
	var extra := 0
	if slots.size() > CHIP_CAP:
		extra = slots.size() - (CHIP_CAP - 1)
		slots.resize(CHIP_CAP - 1)
	var row := Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var x := 0.0
	for slot in slots:
		var player := bool(slot.get("player", false))
		var chip := _make_chip(str(slot.get("house_id", "")), int(slot.get("chair", 0)), player, false)
		chip.position = Vector2(x, 0)
		row.add_child(chip)
		x += (CHIP_PLAYER.x if player else CHIP.x) + 2.0
	if extra > 0:
		var more := _make_overflow(extra)
		more.position = Vector2(x, 0)
		row.add_child(more)
		x += CHIP.x
	elif x > 0.0:
		x -= 2.0
	row.position = _node_pos(city_id) + Vector2(-x * 0.5, 12.0)
	chips_layer.add_child(row)


func _paint_road_chips(show_player: bool, live: bool) -> void:
	var groups: Dictionary = {}
	for token_id in GameState.string_tokens.keys():
		var token: Dictionary = GameState.string_tokens[token_id]
		if token.is_empty() or not StringBook.is_on_wire(token):
			continue
		var parked := StringBook.visual_node(token) if live else StringBook.stamp_node(token)
		if not parked.is_empty():
			continue
		var from_id := str(token.get("from_id", ""))
		var to_id := str(token.get("to_id", ""))
		var key := GameState._link_key(from_id, to_id)
		if not groups.has(key):
			groups[key] = []
		groups[key].append({
			"player": false,
			"house_id": str(token.get("house_id", "")),
			"chair": int(token.get("chair", 0)),
			"from": from_id,
			"to": to_id,
			"t": StringBook.visual_edge_t(token) if live else StringBook.stamp_edge_t(token),
		})
	if show_player:
		var from_id := str(GameState.transit.get("from", ""))
		var to_id := str(GameState.transit.get("to", ""))
		if not from_id.is_empty() and not to_id.is_empty():
			var key := GameState._link_key(from_id, to_id)
			if not groups.has(key):
				groups[key] = []
			groups[key].append({
				"player": true,
				"house_id": GameState.selected_house_id,
				"chair": 0,
				"from": from_id,
				"to": to_id,
				"t": GameState.player_visual_progress() if live else GameState.player_stamp_progress(),
			})
	for key in groups.keys():
		var slots: Array = groups[key]
		for i in slots.size():
			_place_road_chip(slots[i], i, slots.size())


func _place_road_chip(slot: Dictionary, index: int, count: int) -> void:
	var player := bool(slot.get("player", false))
	var enlarged := chips_enlarged
	var size := CHIP_ROAD_PLAYER if enlarged and player else (CHIP_ROAD if enlarged else (CHIP_PLAYER if player else CHIP))
	var from_id := str(slot.get("from", ""))
	var to_id := str(slot.get("to", ""))
	var t := float(slot.get("t", 0.0))
	var pos := _sample_route(from_id, to_id, t)
	var nrm := _route_normal(from_id, to_id, t)
	var spread := float(index) - float(count - 1) * 0.5
	pos += nrm * spread * (size.x + 2.0)
	var chip := _make_chip(str(slot.get("house_id", "")), int(slot.get("chair", 0)), player, enlarged)
	chip.position = pos - size * 0.5
	chips_layer.add_child(chip)


func _route_normal(from_id: String, to_id: String, t: float) -> Vector2:
	var a := _sample_route(from_id, to_id, clampf(t - 0.02, 0.0, 1.0))
	var b := _sample_route(from_id, to_id, clampf(t + 0.02, 0.0, 1.0))
	var tangent := b - a
	if tangent.length_squared() < 0.0001:
		return Vector2(0, 1)
	return Vector2(-tangent.y, tangent.x).normalized()


func _make_chip(house_id: String, chair: int, player: bool, enlarged: bool = false) -> Control:
	var size := CHIP_PLAYER if player else CHIP
	if enlarged:
		size = CHIP_ROAD_PLAYER if player else CHIP_ROAD
	var fill := WorldBook.house_color(house_id)
	var root := ColorRect.new()
	root.custom_minimum_size = size
	root.size = size
	root.clip_contents = true
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if player:
		root.color = CHIP_RING
		var inner := ColorRect.new()
		inner.color = fill
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 1
		inner.offset_top = 1
		inner.offset_right = -1
		inner.offset_bottom = -1
		root.add_child(inner)
	else:
		root.color = fill
	var lab := Label.new()
	lab.text = "%s%d" % [WorldBook.house_mark(house_id), chair]
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.clip_text = true
	lab.add_theme_font_size_override("font_size", 12 if enlarged else 8)
	lab.add_theme_color_override("font_color", _chip_ink(fill))
	lab.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(lab)
	return root


func _make_overflow(n: int) -> Control:
	var chip := ColorRect.new()
	chip.custom_minimum_size = CHIP
	chip.size = CHIP
	chip.color = Color(0.16, 0.11, 0.07, 0.92)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lab := Label.new()
	lab.text = "+%d" % n
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_theme_font_size_override("font_size", 8)
	lab.add_theme_color_override("font_color", INK)
	lab.set_anchors_preset(Control.PRESET_FULL_RECT)
	chip.add_child(lab)
	return chip


func _chip_ink(fill: Color) -> Color:
	var lum := fill.r * 0.3 + fill.g * 0.5 + fill.b * 0.2
	if lum > 0.55:
		return Color(0.12, 0.08, 0.04, 1)
	return Color(0.95, 0.92, 0.86, 1)
