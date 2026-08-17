extends Node2D
## Persistent sand bed: CPU pool, floor rest, noise-driven wind, horizontal wrap with offset.
## Designed for 1920x1080 title screen space.

const COUNT := 200
const VIEW_W := 1920.0
const VIEW_H := 1080.0

# Bed lives in lower third; floor near bottom of frame
const FLOOR_Y := 1040.0
const BED_TOP := 780.0
const BED_SPAWN_TOP := 920.0
const BED_SPAWN_BOTTOM := 1035.0

const GRAVITY_BASE := 420.0
const GRAVITY_HEIGHT_SCALE := 1.8  # extra gravity when above bed
const FLOOR_FRICTION := 8.0
const AIR_DRAG := 0.55
const FLOOR_DRAG := 6.0

const WIND_MAX := 520.0
const LIFT_MAX := 280.0
const SWIRL_MAX := 120.0

# Noise: low-freq envelope + threshold for calm periods
const WIND_NOISE_FREQ := 0.08
const WIND_DETAIL_FREQ := 0.35
const GUST_THRESHOLD := 0.18  # noise must exceed this (after remap) to blow

var _pos: PackedVector2Array = PackedVector2Array()
var _vel: PackedVector2Array = PackedVector2Array()
var _noise: FastNoiseLite
var _detail: FastNoiseLite
var _multi: MultiMeshInstance2D
var _sim_ms: float = 0.0
var _time: float = 0.0

@onready var _perf_label: Label = get_parent().get_node_or_null("SandPerfLabel") as Label


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = WIND_NOISE_FREQ

	_detail = FastNoiseLite.new()
	_detail.seed = randi() + 17
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.frequency = WIND_DETAIL_FREQ

	_pos.resize(COUNT)
	_vel.resize(COUNT)
	for i in COUNT:
		_pos[i] = Vector2(randf() * VIEW_W, randf_range(BED_SPAWN_TOP, BED_SPAWN_BOTTOM))
		_vel[i] = Vector2(randf_range(-8.0, 8.0), 0.0)

	_setup_multimesh()
	set_process(true)


func _setup_multimesh() -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(3.0, 3.0)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = COUNT

	_multi = MultiMeshInstance2D.new()
	_multi.multimesh = mm
	_multi.z_index = 1
	# Golden translucent sand
	_multi.modulate = Color(1.0, 0.9, 0.62, 0.85)
	add_child(_multi)

	for i in COUNT:
		_write_instance(i)


func _write_instance(i: int) -> void:
	var xf := Transform2D(0.0, _pos[i])
	_multi.multimesh.set_instance_transform_2d(i, xf)
	# Slight size/alpha variation by height (airborne a bit more transparent)
	var h := clampf((_pos[i].y - BED_TOP) / (FLOOR_Y - BED_TOP), 0.0, 1.0)
	var a := lerpf(0.45, 0.9, h)
	_multi.multimesh.set_instance_color(i, Color(1.0, 0.92, 0.65, a))


func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_time += delta
	_simulate(delta)
	var t1 := Time.get_ticks_usec()
	_sim_ms = (t1 - t0) / 1000.0
	_update_perf_label()


func _simulate(delta: float) -> void:
	var gust := _gust_strength(_time)
	# Spatial phase so the bed does not all lift at once
	var spatial_t := _time * 0.4

	for i in COUNT:
		var p := _pos[i]
		var v := _vel[i]

		# Height factor: 0 on floor bed, 1 high up
		var height_01 := clampf((FLOOR_Y - p.y) / (FLOOR_Y - BED_TOP), 0.0, 1.0)
		var above_bed := clampf((BED_TOP + 40.0 - p.y) / 200.0, 0.0, 1.0)

		# Gravity stronger when high
		var g := GRAVITY_BASE * (1.0 + above_bed * GRAVITY_HEIGHT_SCALE)
		v.y += g * delta

		# Local gust variation across X
		var local := _detail.get_noise_2d(p.x * 0.01, spatial_t)
		local = local * 0.5 + 0.5  # 0..1
		var local_gust := gust * lerpf(0.55, 1.0, local)

		# Wind + lift (lift stronger near bed so it peels the layer)
		var peel := 1.0 - height_01 * 0.65
		v.x += WIND_MAX * local_gust * delta
		v.y -= LIFT_MAX * local_gust * peel * delta

		# Light swirl (perpendicular nudge from noise)
		var swirl := _detail.get_noise_2d(p.x * 0.02 + 50.0, p.y * 0.02 + spatial_t)
		v.y += swirl * SWIRL_MAX * local_gust * delta
		v.x += swirl * SWIRL_MAX * 0.35 * local_gust * delta

		# Drag: heavy on floor, lighter in air
		var on_floor := p.y >= FLOOR_Y - 1.5 and v.y >= 0.0
		var drag := FLOOR_DRAG if on_floor else AIR_DRAG
		# Extra horizontal friction when calm and on floor
		if on_floor and local_gust < 0.1:
			drag += FLOOR_FRICTION
		v *= maxf(0.0, 1.0 - drag * delta)

		p += v * delta

		# Floor constraint
		if p.y > FLOOR_Y:
			p.y = FLOOR_Y
			if v.y > 0.0:
				v.y = 0.0
			v.x *= 0.85

		# Soft keep from going too high for long
		if p.y < 200.0:
			v.y += 600.0 * delta

		# Horizontal wrap with bed recycle
		if p.x > VIEW_W + 4.0:
			p.x = randf_range(-8.0, 24.0)
			p.y = randf_range(BED_SPAWN_TOP, BED_SPAWN_BOTTOM)
			v = Vector2(randf_range(-12.0, 20.0), randf_range(-10.0, 5.0))
		elif p.x < -40.0:
			p.x = VIEW_W + randf_range(-24.0, 8.0)
			p.y = randf_range(BED_SPAWN_TOP, BED_SPAWN_BOTTOM)
			v *= 0.15

		_pos[i] = p
		_vel[i] = v
		_write_instance(i)


func _gust_strength(t: float) -> float:
	# Primary low-frequency weather
	var n := _noise.get_noise_1d(t * 10.0)
	# Detail flicker
	var d := _detail.get_noise_1d(t * 25.0) * 0.2
	var raw := n + d
	# Remap roughly into 0..1 with calm floor
	var s := (raw + 1.0) * 0.5  # 0..1
	if s < GUST_THRESHOLD:
		return 0.0
	# Smooth ramp above threshold
	var u := (s - GUST_THRESHOLD) / (1.0 - GUST_THRESHOLD)
	return clampf(u * u * 1.15, 0.0, 1.0)


func _update_perf_label() -> void:
	if _perf_label == null:
		return
	_perf_label.text = "sand: %d | sim: %.2f ms | fps: %d" % [
		COUNT,
		_sim_ms,
		Engine.get_frames_per_second()
	]


func get_sim_ms() -> float:
	return _sim_ms
