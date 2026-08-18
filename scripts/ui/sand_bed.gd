extends Node2D
## Five-layer sandstorm with macro/micro wind. Shared gust envelope, recycled pools.
## Unified golden-brown desert grain; size and motion distinguish layers.
## 1920x1080. Stream wrap keeps grains in the airflow.

const VIEW_W := 1920.0
const VIEW_H := 1080.0
const FLOOR_Y := 1180.0
const BED_THICKNESS := 24.0
const BED_SPAWN_TOP := FLOOR_Y - BED_THICKNESS
const BED_SPAWN_BOTTOM := FLOOR_Y - 1.0

const MACRO_HOLD_MIN := 2.2
const MACRO_HOLD_MAX := 4.0
const MACRO_LERP_TIME := 1.0
const MACRO_TARGET_MIN := 0.18
const MACRO_TARGET_MAX := 0.72
const MACRO_DEEP_CALM_CHANCE := 0.10
const MACRO_DEEP_CALM_MAX := 0.06
const MICRO_AMP := 0.12
const MICRO_NOISE_FREQ := 0.11
const MACRO_START_RAMP := 2.5

const BASE_GRAVITY := 28.0
const BASE_WIND := 980.0
const BASE_LIFT := 900.0
const BASE_UNSTICK := 360.0
const BASE_SWIRL := 520.0

class Layer:
	var name: String
	var count: int
	var pos: PackedVector2Array
	var vel: PackedVector2Array
	var multi: MultiMeshInstance2D
	var detail: FastNoiseLite
	var wind_mul: float
	var lift_mul: float
	var gravity_mul: float
	var swirl_mul: float
	var gust_mul: float
	var quad_size: float
	var modulate: Color
	var air_drag: float
	var bed_fraction: float
	var height_bias: float
	var shimmer: bool = false
	var y_prefer_min: float
	var y_prefer_max: float


var _layers: Array[Layer] = []
var _noise: FastNoiseLite
var _time: float = 0.0
var _sim_ms: float = 0.0
var _total_count: int = 0
var _shimmer_noise: FastNoiseLite
var _grain_tex: ImageTexture

var _macro_current: float = 0.0
var _macro_target: float = 0.0
var _macro_from: float = 0.0
var _macro_hold_left: float = 0.0
var _macro_lerp_t: float = 1.0
var _micro_noise: FastNoiseLite

@onready var _perf_label: Label = get_parent().get_node_or_null("SandPerfLabel") as Label


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.05

	_micro_noise = FastNoiseLite.new()
	_micro_noise.seed = randi() + 3
	_micro_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_micro_noise.frequency = MICRO_NOISE_FREQ

	_shimmer_noise = FastNoiseLite.new()
	_shimmer_noise.seed = 91
	_shimmer_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_shimmer_noise.frequency = 0.045

	_macro_from = 0.0
	_macro_current = 0.0
	_macro_target = _pick_macro_target()
	_macro_lerp_t = 0.0
	_macro_hold_left = randf_range(MACRO_HOLD_MIN, MACRO_HOLD_MAX)

	_layers.append(_make_layer({
		"name": "heavy_low", "count": 180,
		"wind_mul": 0.55, "lift_mul": 0.35, "gravity_mul": 1.55, "swirl_mul": 0.70, "gust_mul": 0.65,
		"quad_size": 5.2, "modulate": Color(0.92, 0.72, 0.42, 1.0),
		"air_drag": 0.18, "bed_fraction": 0.75, "height_bias": 80.0, "seed_off": 11, "shimmer": false,
		"y_prefer_min": 820.0, "y_prefer_max": 1180.0,
	}))
	_layers.append(_make_layer({
		"name": "heavy_mid", "count": 170,
		"wind_mul": 0.72, "lift_mul": 0.55, "gravity_mul": 1.30, "swirl_mul": 0.95, "gust_mul": 0.80,
		"quad_size": 4.6, "modulate": Color(0.94, 0.76, 0.46, 1.0),
		"air_drag": 0.14, "bed_fraction": 0.55, "height_bias": 40.0, "seed_off": 19, "shimmer": false,
		"y_prefer_min": 620.0, "y_prefer_max": 1000.0,
	}))
	_layers.append(_make_layer({
		"name": "main", "count": 220,
		"wind_mul": 1.00, "lift_mul": 0.70, "gravity_mul": 1.05, "swirl_mul": 1.25, "gust_mul": 1.0,
		"quad_size": 3.8, "modulate": Color(0.96, 0.80, 0.50, 1.0),
		"air_drag": 0.11, "bed_fraction": 0.40, "height_bias": 0.0, "seed_off": 29, "shimmer": true,
		"y_prefer_min": 400.0, "y_prefer_max": 860.0,
	}))
	_layers.append(_make_layer({
		"name": "main_high", "count": 180,
		"wind_mul": 1.10, "lift_mul": 0.90, "gravity_mul": 0.90, "swirl_mul": 1.55, "gust_mul": 1.05,
		"quad_size": 3.4, "modulate": Color(0.97, 0.84, 0.55, 1.0),
		"air_drag": 0.09, "bed_fraction": 0.30, "height_bias": -30.0, "seed_off": 37, "shimmer": false,
		"y_prefer_min": 260.0, "y_prefer_max": 700.0,
	}))
	_layers.append(_make_layer({
		"name": "fine", "count": 190,
		"wind_mul": 1.20, "lift_mul": 1.10, "gravity_mul": 0.70, "swirl_mul": 2.10, "gust_mul": 1.10,
		"quad_size": 3.2, "modulate": Color(0.98, 0.88, 0.62, 1.0),
		"air_drag": 0.07, "bed_fraction": 0.18, "height_bias": -50.0, "seed_off": 47, "shimmer": false,
		"y_prefer_min": 100.0, "y_prefer_max": 580.0,
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
	L.shimmer = cfg.get("shimmer", false)
	L.y_prefer_min = cfg.get("y_prefer_min", 200.0)
	L.y_prefer_max = cfg.get("y_prefer_max", 1100.0)
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


func _shared_grain_texture() -> ImageTexture:
	if _grain_tex == null:
		_grain_tex = _make_grain_texture(22, 0.58, 0.30)
	return _grain_tex


func _make_grain_texture(size: int, softness: float, irregularity: float) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx := (size - 1) * 0.5
	var cy := (size - 1) * 0.5
	var max_r := cx * 0.92
	var n := FastNoiseLite.new()
	n.seed = randi()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.22
	for y in size:
		for x in size:
			var dx := (x - cx) / max_r
			var dy := (y - cy) / max_r
			var dist := sqrt(dx * dx + dy * dy)
			var angle := atan2(dy, dx)
			var nval := n.get_noise_2d(cos(angle) * 3.0, sin(angle) * 3.0)
			var radius_mod := 1.0 + nval * irregularity * 0.45
			var effective_dist := dist / maxf(radius_mod, 0.55)
			var edge := lerpf(0.55, 0.15, softness)
			var a := 0.0
			if effective_dist < 1.0:
				var t := clampf((1.0 - effective_dist) / maxf(1.0 - edge, 0.05), 0.0, 1.0)
				a = t * t * (3.0 - 2.0 * t)
				a = pow(a, lerpf(0.7, 1.6, softness))
			var warm := 0.78 + n.get_noise_2d(x * 0.4, y * 0.4) * 0.10
			img.set_pixel(x, y, Color(0.95, warm, warm * 0.55, a))
	return ImageTexture.create_from_image(img)


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
	match L.name:
		"heavy_low": L.multi.z_index = 1
		"heavy_mid": L.multi.z_index = 2
		"main": L.multi.z_index = 3
		"main_high": L.multi.z_index = 4
		"fine": L.multi.z_index = 5
	L.multi.texture = _shared_grain_texture()
	add_child(L.multi)
	for i in L.count:
		_write_instance(L, i)


func _write_instance(L: Layer, i: int) -> void:
	L.multi.multimesh.set_instance_transform_2d(i, Transform2D(0.0, L.pos[i]))
	var height_01 := clampf((FLOOR_Y - L.pos[i].y) / maxf(FLOOR_Y - 700.0, 1.0), 0.0, 1.0)
	var a := lerpf(0.95, 0.45, height_01)
	var r := 1.0
	var g := 0.90
	var b := 0.62
	if L.shimmer:
		var sn := _shimmer_noise.get_noise_2d(L.pos[i].x * 0.008 + _time * 12.0, L.pos[i].y * 0.006)
		var glint := maxf(0.0, sn)
		glint = glint * glint * 0.50
		r = minf(1.0, r + glint * 0.30)
		g = minf(1.0, g + glint * 0.22)
		b = minf(1.0, b + glint * 0.10)
		a = minf(1.0, a + glint * 0.12)
	L.multi.multimesh.set_instance_color(i, Color(r, g, b, a))


func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_time += delta
	_update_macro(delta)
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
		if local_gust > 0.06:
			var band_span := maxf(L.y_prefer_max - L.y_prefer_min, 1.0)
			var band_t := 0.0
			if p.y >= L.y_prefer_min:
				band_t = clampf((p.y - L.y_prefer_min) / band_span, 0.0, 1.0)
			var peel := band_t * lerpf(1.1, 0.35, height_01)
			v.y -= lift_max * local_gust * peel * delta
			if on_floor:
				v.y -= unstick * local_gust * delta
				if v.y > -55.0 * local_gust:
					v.y = -55.0 * local_gust - randf_range(0.0, 40.0) * local_gust
			var eddy := L.detail.get_noise_2d(p.x * 0.008 + 12.0, p.y * 0.007 + spatial_t * 0.55)
			var turb := L.detail.get_noise_2d(p.x * 0.028 - 17.0, p.y * 0.024 + spatial_t * 1.2)
			var swirl := eddy * 0.72 + turb * 0.28
			var swirl_force := swirl_max * local_gust * (0.65 + 0.45 * band_t)
			v.x += swirl * swirl_force * 0.70 * delta
			v.y += swirl * swirl_force * 1.25 * delta
			v.x += turb * swirl_force * 0.35 * delta
			v.y -= eddy * swirl_force * 0.40 * delta
		if p.y < L.y_prefer_min:
			v.y += 220.0 * delta
		elif p.y > L.y_prefer_max:
			v.y -= 55.0 * delta
		var drag: float
		if on_floor and local_gust < 0.1:
			drag = 3.5 + 4.0
		elif on_floor:
			drag = 0.35
		else:
			drag = L.air_drag
		v *= maxf(0.0, 1.0 - drag * delta)
		p += v * delta
		if p.y > FLOOR_Y:
			p.y = FLOOR_Y
			if v.y > 0.0: v.y = 0.0
			if local_gust < 0.1: v.x *= 0.88
		if p.y < 40.0: v.y += 350.0 * delta
		if p.x > VIEW_W + 6.0:
			p.x = randf_range(-6.0, 20.0)
			p.y = clampf(p.y + randf_range(-140.0, 140.0), L.y_prefer_min, L.y_prefer_max)
			v.x = maxf(abs(v.x) * 0.75, 80.0 * L.wind_mul)
			v.y *= 0.7
			v.y += randf_range(-50.0, 50.0)
		elif p.x < -50.0:
			p.x = VIEW_W + randf_range(-20.0, 6.0)
			p.y = clampf(p.y + randf_range(-140.0, 140.0), L.y_prefer_min, L.y_prefer_max)
			v.x = -maxf(abs(v.x) * 0.75, 80.0 * L.wind_mul)
			v.y *= 0.7
			v.y += randf_range(-50.0, 50.0)
		L.pos[i] = p
		L.vel[i] = v
		_write_instance(L, i)


func _pick_macro_target() -> float:
	if randf() < MACRO_DEEP_CALM_CHANCE:
		return randf_range(0.0, MACRO_DEEP_CALM_MAX)
	var a := randf_range(MACRO_TARGET_MIN, MACRO_TARGET_MAX)
	var b := randf_range(MACRO_TARGET_MIN, MACRO_TARGET_MAX)
	return (a + b) * 0.5


func _update_macro(delta: float) -> void:
	if _macro_lerp_t < 1.0:
		var lerp_dur := MACRO_LERP_TIME
		if _macro_from <= 0.001: lerp_dur = MACRO_START_RAMP
		_macro_lerp_t = minf(1.0, _macro_lerp_t + delta / lerp_dur)
		var u := _macro_lerp_t
		u = u * u * (3.0 - 2.0 * u)
		_macro_current = lerpf(_macro_from, _macro_target, u)
		return
	_macro_hold_left -= delta
	if _macro_hold_left <= 0.0:
		_macro_from = _macro_current
		_macro_target = _pick_macro_target()
		_macro_lerp_t = 0.0
		_macro_hold_left = randf_range(MACRO_HOLD_MIN, MACRO_HOLD_MAX)


func _gust_strength(t: float) -> float:
	var micro := _micro_noise.get_noise_1d(t * 8.0)
	return clampf(_macro_current * (1.0 + micro * MICRO_AMP), 0.0, 1.0)


func _update_perf_label(gust: float) -> void:
	if _perf_label == null: return
	_perf_label.text = "sand: %d (5 layers) | sim: %.2f ms | fps: %d | gust: %.2f" % [
		_total_count, _sim_ms, Engine.get_frames_per_second(), gust]
