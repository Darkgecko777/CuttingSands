extends Node2D
## Persistent sand bed: floor at screen bottom, balanced gravity vs noise gusts.
## 1920x1080 scene space. Texture polish deferred.

const COUNT := 200
const VIEW_W := 1920.0
const VIEW_H := 1080.0

# Floor = bottom of the view; thin rest/spawn band on that floor
const FLOOR_Y := 1076.0
const BED_THICKNESS := 14.0
const BED_SPAWN_TOP := FLOOR_Y - BED_THICKNESS
const BED_SPAWN_BOTTOM := FLOOR_Y - 1.0
# Above this, height-scaled gravity kicks in harder
const AIR_REF_Y := 900.0

# Force balance: gravity must lose to a medium gust for a readable lift time
const GRAVITY_BASE := 180.0
const GRAVITY_HEIGHT_SCALE := 1.2
const AIR_DRAG := 0.35
const FLOOR_DRAG_CALM := 4.5
const FLOOR_DRAG_WIND := 0.8
const FLOOR_FRICTION_CALM := 5.0

const WIND_MAX := 640.0
const LIFT_MAX := 420.0
const SWIRL_MAX := 160.0

const WIND_NOISE_FREQ := 0.07
const WIND_DETAIL_FREQ := 0.3
const GUST_THRESHOLD := 0.22

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
		_vel[i] = Vector2(randf_range(-6.0, 6.0), 0.0)

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
	_multi.modulate = Color(1.0, 0.9, 0.62, 0.85)
	add_child(_multi)

	for i in COUNT:
		_write_instance(i)


func _write_instance(i: int) -> void:
	var xf := Transform2D(0.0, _pos[i])
	_multi.multimesh.set_instance_transform_2d(i, xf)
	var height_01 := clampf((FLOOR_Y - _pos[i].y) / maxf(FLOOR_Y - AIR_REF_Y, 1.0), 0.0, 1.0)
	var a := lerpf(0.9, 0.5, height_01)
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
	var spatial_t := _time * 0.45

	for i in COUNT:
		var p := _pos[i]
		var v := _vel[i]

		var height_01 := clampf((FLOOR_Y - p.y) / maxf(FLOOR_Y - AIR_REF_Y, 1.0), 0.0, 1.0)
		var on_floor := p.y >= FLOOR_Y - 2.0

		# Gravity: mild on bed, stronger only when well above
		var g := GRAVITY_BASE * (1.0 + height_01 * GRAVITY_HEIGHT_SCALE)
		v.y += g * delta

		# Local variation so the bed peels in patches
		var local := _detail.get_noise_2d(p.x * 0.012, spatial_t)
		local = local * 0.5 + 0.5
		var local_gust := gust * lerpf(0.4, 1.0, local)

		# Wind + lift: lift strongest near floor (peel the bed)
		var peel := 1.0 - height_01 * 0.5
		v.x += WIND_MAX * local_gust * delta
		v.y -= LIFT_MAX * local_gust * peel * delta

		# Swirl while airborne / gusty
		if local_gust > 0.05:
			var swirl := _detail.get_noise_2d(p.x * 0.025 + 40.0, p.y * 0.02 + spatial_t)
			v.x += swirl * SWIRL_MAX * 0.4 * local_gust * delta
			v.y += swirl * SWIRL_MAX * local_gust * delta

		# Drag: calm floor sticks; windy floor can slide; air is light
		var drag: float
		if on_floor:
			if local_gust < 0.12:
				drag = FLOOR_DRAG_CALM + FLOOR_FRICTION_CALM
			else:
				drag = FLOOR_DRAG_WIND
		else:
			drag = AIR_DRAG
		v *= maxf(0.0, 1.0 - drag * delta)

		p += v * delta

		# Floor constraint (true bottom band)
		if p.y > FLOOR_Y:
			p.y = FLOOR_Y
			if v.y > 0.0:
				v.y = 0.0
			if local_gust < 0.12:
				v.x *= 0.9

		# Soft ceiling bias only near top of frame
		if p.y < 120.0:
			v.y += 400.0 * delta

		# Wrap right → left into thin bed band
		if p.x > VIEW_W + 6.0:
			p.x = randf_range(-6.0, 20.0)
			p.y = randf_range(BED_SPAWN_TOP, BED_SPAWN_BOTTOM)
			v = Vector2(randf_range(0.0, 30.0), randf_range(-20.0, 5.0))
		elif p.x < -50.0:
			p.x = VIEW_W + randf_range(-20.0, 6.0)
			p.y = randf_range(BED_SPAWN_TOP, BED_SPAWN_BOTTOM)
			v *= 0.2

		_pos[i] = p
		_vel[i] = v
		_write_instance(i)


func _gust_strength(t: float) -> float:
	var n := _noise.get_noise_1d(t * 10.0)
	var d := _detail.get_noise_1d(t * 22.0) * 0.25
	var s := (n + d + 1.0) * 0.5
	if s < GUST_THRESHOLD:
		return 0.0
	var u := (s - GUST_THRESHOLD) / (1.0 - GUST_THRESHOLD)
	# Slightly punchier peaks so lift visibly beats gravity
	return clampf(u * u * 1.25, 0.0, 1.0)


func _update_perf_label() -> void:
	if _perf_label == null:
		return
	_perf_label.text = "sand: %d | sim: %.2f ms | fps: %d | gust: %.2f" % [
		COUNT,
		_sim_ms,
		Engine.get_frames_per_second(),
		_gust_strength(_time)
	]


func get_sim_ms() -> float:
	return _sim_ms
