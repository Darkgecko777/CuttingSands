extends Node2D
## Three-layer sandstorm: heavy / main / fine. Shared gust envelope, independent pools.
## 1920x1080. Stream wrap keeps grains in the airflow.

const VIEW_W := 1920.0
const VIEW_H := 1080.0
const FLOOR_Y := 1180.0
const BED_THICKNESS := 24.0
const BED_SPAWN_TOP := FLOOR_Y - BED_THICKNESS
const BED_SPAWN_BOTTOM := FLOOR_Y - 1.0

const WIND_NOISE_FREQ := 0.07
const GUST_THRESHOLD := 0.2

# Shared base forces; each layer multiplies these
const BASE_GRAVITY := 55.0
const BASE_WIND := 920.0
const BASE_LIFT := 920.0
const BASE_UNSTICK := 320.0
const BASE_SWIRL := 240.0

class Layer:
	var name: String
	var count: int
	var pos: PackedVector2Array
	var vel: PackedVector2Array
	var multi: MultiMeshInstance2D
	var detail: FastNoiseLite
	# Multipliers vs base
	var wind_mul: float
	var lift_mul: float
	var gravity_mul: float
	var swirl_mul: float
	var gust_mul: float  # response to shared envelope
	var quad_size: float
	var modulate: Color
	var air_drag: float
	var bed_fraction: float  # 0..1 start in hidden bed
	var height_bias: float  # shift stream spawn upward (-) or down (+)


var _layers: Array[Layer] = []
var _noise: FastNoiseLite
var _time: float = 0.0
var _sim_ms: float = 0.0
var _total_count: int = 0

@onready var _perf_label: Label = get_parent().get_node_or_null("SandPerfLabel") as Label


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = WIND_NOISE_FREQ

	# Heavy: lower, slower, larger, lags the storm slightly
	_layers.append(_make_layer({
		"name": "heavy",
		"count": 220,
		"wind_mul": 0.55,
		"lift_mul": 0.65,
		"gravity_mul": 1.25,
		"swirl_mul": 0.55,
		"gust_mul": 0.85,
		"quad_size": 4.5,
		"modulate": Color(0.95, 0.82, 0.52, 0.9),
		"air_drag": 0.28,
		"bed_fraction": 0.7,
		"height_bias": 80.0,
		"seed_off": 11,
	}))
	# Main: core stream (current character)
	_layers.append(_make_layer({
		"name": "main",
		"count": 400,
		"wind_mul": 1.0,
		"lift_mul": 1.0,
		"gravity_mul": 1.0,
		"swirl_mul": 1.0,
		"gust_mul": 1.0,
		"quad_size": 3.0,
		"modulate": Color(1.0, 0.9, 0.62, 0.85),
		"air_drag": 0.18,
		"bed_fraction": 0.45,
		"height_bias": 0.0,
		"seed_off": 29,
	}))
	# Fine: high, fast, faint wisps
	_layers.append(_make_layer({
		"name": "fine",
		"count": 280,
		"wind_mul": 1.35,
		"lift_mul": 1.25,
		"gravity_mul": 0.7,
		"swirl_mul": 1.5,
		"gust_mul": 1.15,
		"quad_size": 2.0,
		"modulate": Color(1.0, 0.94, 0.72, 0.55),
		"air_drag": 0.12,
		"bed_fraction": 0.2,
		"height_bias": -120.0,
		"seed_off": 47,
	}))

	for layer in _layers:
		_total_count += layer.count
		_init_layer_particles(layer)
		_setup_layer_mesh(layer)

	set_process(true)


func _make_layer(cfg: Dictionary) -> Layer:
	var L := Layer.new()
	L.name = cfg["name"]
	L.count = cfg["count"]
	L.wind_mul = cfg["wind_mul"]
	L.lift_mul = cfg["lift_mul"]
	L.gravity_mul = cfg["gravity_mul"]
	L.swirl_mul = cfg["swirl_mul"]
	L.gust_mul = cfg["gust_mul"]
	L.quad_size = cfg["quad_size"]
	L.modulate = cfg["modulate"]
	L.air_drag = cfg["air_drag"]
	L.bed_fraction = cfg["bed_fraction"]
	L.height_bias = cfg["height_bias"]
	L.detail = FastNoiseLite.new()
	L.detail.seed = randi() + int(cfg["seed_off"])
	L.detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	L.detail.frequency = 0.28
	L.pos = PackedVector2Array()
	L.vel = PackedVector2Array()
	L.pos.resize(L.count)
	L.vel.resize(L.count)
	return L


func _init_layer_particles(L: Layer) -> void:
	var bed_n := int(L.count * L.bed_fraction)
	for i in L.count:
		if i < bed_n:
			L.pos[i] = Vector2(randf() * VIEW_W, randf_range(BED_SPAWN_TOP, BED_SPAWN_BOTTOM))
			L.vel[i] = Vector2(randf_range(-6.0, 6.0), 0.0)
		else:
			var y0 := randf_range(120.0, 1000.0) + L.height_bias
			y0 = clampf(y0, 60.0, FLOOR_Y - 10.0)
			L.pos[i] = Vector2(randf() * VIEW_W, y0)
			L.vel[i] = Vector2(randf_range(40.0, 180.0) * L.wind_mul, randf_range(-40.0, 20.0))


func _setup_layer_mesh(L: Layer) -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(L.quad_size, L.quad_size)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = L.count

	L.multi = MultiMeshInstance2D.new()
	L.multi.multimesh = mm
	L.multi.z_index = 1
	L.multi.modulate = L.modulate
	add_child(L.multi)

	for i in L.count:
		_write_instance(L, i)


func _write_instance(L: Layer, i: int) -> void:
	L.multi.multimesh.set_instance_transform_2d(i, Transform2D(0.0, L.pos[i]))
	var height_01 := clampf((FLOOR_Y - L.pos[i].y) / maxf(FLOOR_Y - 700.0, 1.0), 0.0, 1.0)
	var a := lerpf(0.95, 0.4, height_01)
	L.multi.multimesh.set_instance_color(i, Color(1.0, 0.92, 0.65, a))


func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_time += delta
	var gust := _gust_strength(_time)
	for layer in _layers:
		_simulate_layer(layer, delta, gust)
	var t1 := Time.get_ticks_usec()
	_sim_ms = (t1 - t0) / 1000.0
	_update_perf_label(gust)


func _simulate_layer(L: Layer, delta: float, gust: float) -> void:
	var spatial_t := _time * 0.45
	var wind_max := BASE_WIND * L.wind_mul
	var lift_max := BASE_LIFT * L.lift_mul
	var unstick := BASE_UNSTICK * L.lift_mul
	var swirl_max := BASE_SWIRL * L.swirl_mul
	var grav := BASE_GRAVITY * L.gravity_mul
	var layer_gust := clampf(gust * L.gust_mul, 0.0, 1.0)

	for i in L.count:
		var p := L.pos[i]
		var v := L.vel[i]

		var height_01 := clampf((FLOOR_Y - p.y) / maxf(FLOOR_Y - 700.0, 1.0), 0.0, 1.0)
		var on_floor := p.y >= FLOOR_Y - 2.5

		v.y += grav * (1.0 + height_01) * delta

		var local := L.detail.get_noise_2d(p.x * 0.012, spatial_t)
		local = local * 0.5 + 0.5
		var local_gust := layer_gust * lerpf(0.35, 1.0, local)

		v.x += wind_max * local_gust * delta

		if local_gust > 0.08:
			var peel := lerpf(1.0, 0.45, height_01)
			v.y -= lift_max * local_gust * peel * delta
			if on_floor:
				v.y -= unstick * local_gust * delta
				if v.y > -40.0 * local_gust:
					v.y = -40.0 * local_gust - randf_range(0.0, 30.0) * local_gust

			var swirl := L.detail.get_noise_2d(p.x * 0.025 + 40.0, p.y * 0.02 + spatial_t)
			v.x += swirl * swirl_max * 0.45 * local_gust * delta
			v.y += swirl * swirl_max * local_gust * delta

		var drag: float
		if on_floor and local_gust < 0.1:
			drag = 5.0 + 6.0
		elif on_floor:
			drag = 0.5
		else:
			drag = L.air_drag
		v *= maxf(0.0, 1.0 - drag * delta)

		p += v * delta

		if p.y > FLOOR_Y:
			p.y = FLOOR_Y
			if v.y > 0.0:
				v.y = 0.0
			if local_gust < 0.1:
				v.x *= 0.88

		if p.y < 40.0:
			v.y += 350.0 * delta

		# Stream recycle
		if p.x > VIEW_W + 6.0:
			p.x = randf_range(-6.0, 20.0)
			p.y = clampf(p.y + randf_range(-50.0, 50.0), 40.0, FLOOR_Y)
			v.x = maxf(abs(v.x) * 0.75, 80.0 * L.wind_mul)
			v.y *= 0.85
			v.y += randf_range(-30.0, 30.0)
		elif p.x < -50.0:
			p.x = VIEW_W + randf_range(-20.0, 6.0)
			p.y = clampf(p.y + randf_range(-50.0, 50.0), 40.0, FLOOR_Y)
			v.x = -maxf(abs(v.x) * 0.75, 80.0 * L.wind_mul)
			v.y *= 0.85

		L.pos[i] = p
		L.vel[i] = v
		_write_instance(L, i)


func _gust_strength(t: float) -> float:
	var n := _noise.get_noise_1d(t * 10.0)
	var d := _noise.get_noise_1d(t * 22.0 + 100.0) * 0.25
	var s := (n + d + 1.0) * 0.5
	if s < GUST_THRESHOLD:
		return 0.0
	var u := (s - GUST_THRESHOLD) / (1.0 - GUST_THRESHOLD)
	return clampf(u * u * 1.35, 0.0, 1.0)


func _update_perf_label(gust: float) -> void:
	if _perf_label == null:
		return
	_perf_label.text = "sand: %d (3 layers) | sim: %.2f ms | fps: %d | gust: %.2f" % [
		_total_count,
		_sim_ms,
		Engine.get_frames_per_second(),
		gust,
	]
