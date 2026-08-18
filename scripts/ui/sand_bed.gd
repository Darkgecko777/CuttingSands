extends Node2D
## Three-layer sandstorm: heavy / main / fine. Shared gust envelope, independent pools.
## Procedural soft grain textures + per-layer variation + subtle sun shimmer on main layer.
## 1920x1080. Stream wrap keeps grains in the airflow.

const VIEW_W := 1920.0
const VIEW_H := 1080.0
const FLOOR_Y := 1180.0
const BED_THICKNESS := 24.0
const BED_SPAWN_TOP := FLOOR_Y - BED_THICKNESS
const BED_SPAWN_BOTTOM := FLOOR_Y - 1.0

# Macro/micro wind (option 1): multi-second held targets + small flutter
const MACRO_HOLD_MIN := 4.0
const MACRO_HOLD_MAX := 7.0
const MACRO_LERP_TIME := 1.2
const MACRO_TARGET_MIN := 0.28
const MACRO_TARGET_MAX := 0.85
const MACRO_DEEP_CALM_CHANCE := 0.12   # rare true lulls
const MACRO_DEEP_CALM_MAX := 0.08
const MICRO_AMP := 0.15               # ±15% flutter around macro
const MICRO_NOISE_FREQ := 0.11

# Shared base forces; each layer multiplies these
const BASE_GRAVITY := 28.0
const BASE_WIND := 980.0
const BASE_LIFT := 900.0
const BASE_UNSTICK := 360.0
const BASE_SWIRL := 520.0  # stronger rotational energy for visible eddies

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
	var shimmer: bool = false  # sun-reflection shimmer on this layer
	var y_prefer_min: float  # soft band — particles pulled back if outside
	var y_prefer_max: float


var _layers: Array[Layer] = []
var _noise: FastNoiseLite
var _time: float = 0.0
var _sim_ms: float = 0.0
var _total_count: int = 0
var _shimmer_noise: FastNoiseLite

# Macro wind state
var _macro_current: float = 0.45
var _macro_target: float = 0.45
var _macro_from: float = 0.45
var _macro_hold_left: float = 0.0
var _macro_lerp_t: float = 1.0  # 1 = done lerping
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

	# Start mid-range so title isn't dead on load
	_macro_target = randf_range(MACRO_TARGET_MIN, MACRO_TARGET_MAX)
	_macro_from = _macro_target
	_macro_current = _macro_target
	_macro_hold_left = randf_range(MACRO_HOLD_MIN, MACRO_HOLD_MAX)
	_macro_lerp_t = 1.0

	# 1) Heavy-low: densest grit, lowest band
	_layers.append(_make_layer({
		"name": "heavy_low",
		"count": 180,
		"wind_mul": 0.55,
		"lift_mul": 0.35,
		"gravity_mul": 1.55,
		"swirl_mul": 0.70,
		"gust_mul": 0.65,
		"quad_size": 5.2,
		"modulate": Color(1.0, 0.12, 0.08, 1.0),  # TEMP debug: deep red
		"air_drag": 0.18,
		"bed_fraction": 0.75,
		"height_bias": 80.0,
		"seed_off": 11,
		"shimmer": false,
		"y_prefer_min": 820.0,
		"y_prefer_max": 1180.0,
	}))
	# 2) Heavy-mid: same family, slightly higher, more swirl
	_layers.append(_make_layer({
		"name": "heavy_mid",
		"count": 170,
		"wind_mul": 0.72,
		"lift_mul": 0.55,
		"gravity_mul": 1.30,
		"swirl_mul": 0.95,
		"gust_mul": 0.80,
		"quad_size": 4.6,
		"modulate": Color(1.0, 0.35, 0.12, 1.0),  # TEMP debug: orange-red
		"air_drag": 0.14,
		"bed_fraction": 0.55,
		"height_bias": 40.0,
		"seed_off": 19,
		"shimmer": false,
		"y_prefer_min": 620.0,
		"y_prefer_max": 1000.0,
	}))
	# 3) Main: primary mid stream
	_layers.append(_make_layer({
		"name": "main",
		"count": 220,
		"wind_mul": 1.00,
		"lift_mul": 0.70,
		"gravity_mul": 1.05,
		"swirl_mul": 1.25,
		"gust_mul": 1.0,
		"quad_size": 3.8,
		"modulate": Color(0.15, 1.0, 0.22, 1.0),  # TEMP debug: lime
		"air_drag": 0.11,
		"bed_fraction": 0.40,
		"height_bias": 0.0,
		"seed_off": 29,
		"shimmer": true,
		"y_prefer_min": 400.0,
		"y_prefer_max": 860.0,
	}))
	# 4) Main-high: mid-upper, more curl / less gravity
	_layers.append(_make_layer({
		"name": "main_high",
		"count": 180,
		"wind_mul": 1.10,
		"lift_mul": 0.90,
		"gravity_mul": 0.90,
		"swirl_mul": 1.55,
		"gust_mul": 1.05,
		"quad_size": 3.4,
		"modulate": Color(0.4, 1.0, 0.55, 1.0),  # TEMP debug: light green
		"air_drag": 0.09,
		"bed_fraction": 0.30,
		"height_bias": -30.0,
		"seed_off": 37,
		"shimmer": false,
		"y_prefer_min": 260.0,
		"y_prefer_max": 700.0,
	}))
	# 5) Fine: highest wisps, strongest swirl
	_layers.append(_make_layer({
		"name": "fine",
		"count": 190,
		"wind_mul": 1.20,
		"lift_mul": 1.10,
		"gravity_mul": 0.70,
		"swirl_mul": 2.10,
		"gust_mul": 1.10,
		"quad_size": 3.2,
		"modulate": Color(0.15, 0.75, 1.0, 1.0),  # TEMP debug: cyan
		"air_drag": 0.07,
		"bed_fraction": 0.18,
		"height_bias": -50.0,
		"seed_off": 47,
		"shimmer": false,
		"y_prefer_min": 100.0,
		"y_prefer_max": 580.0,
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


## Procedural soft irregular grain texture.
## softness: 0 = hard edge, 1 = very soft falloff
## irregularity: 0 = perfect circle, higher = more organic shape
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

			# Irregular radius modulation
			var angle := atan2(dy, dx)
			var nval := n.get_noise_2d(cos(angle) * 3.0, sin(angle) * 3.0)
			var radius_mod := 1.0 + nval * irregularity * 0.45
			var effective_dist := dist / maxf(radius_mod, 0.55)

			# Soft alpha falloff
			var edge := lerpf(0.55, 0.15, softness)
			var a := 0.0
			if effective_dist < 1.0:
				var t := clampf((1.0 - effective_dist) / maxf(1.0 - edge, 0.05), 0.0, 1.0)
				# Smooth falloff curve
				a = t * t * (3.0 - 2.0 * t)
				# Extra softness curve
				a = pow(a, lerpf(0.7, 1.6, softness))

			# Slight warm sand tint variation inside the grain
			var warm := 0.92 + n.get_noise_2d(x * 0.4, y * 0.4) * 0.08
			var col := Color(1.0, warm, warm * 0.72, a)
			img.set_pixel(x, y, col)

	var tex := ImageTexture.create_from_image(img)
	return tex


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
	L.multi.z_index = 1  # overridden per-layer in match below
	L.multi.modulate = L.modulate

	# Generate and assign procedural grain texture for this layer
	var tex_size: int = 20
	var soft: float = 0.7
	var irreg: float = 0.25
	match L.name:
		"heavy_low":
			tex_size = 24
			soft = 0.52
			irreg = 0.38
			L.multi.z_index = 1
		"heavy_mid":
			tex_size = 22
			soft = 0.55
			irreg = 0.34
			L.multi.z_index = 2
		"main":
			tex_size = 22
			soft = 0.60
			irreg = 0.28
			L.multi.z_index = 3
		"main_high":
			tex_size = 20
			soft = 0.62
			irreg = 0.26
			L.multi.z_index = 4
		"fine":
			tex_size = 18
			soft = 0.58
			irreg = 0.22
			L.multi.z_index = 5
	L.multi.texture = _make_grain_texture(tex_size, soft, irreg)

	add_child(L.multi)

	for i in L.count:
		_write_instance(L, i)


func _write_instance(L: Layer, i: int) -> void:
	L.multi.multimesh.set_instance_transform_2d(i, Transform2D(0.0, L.pos[i]))

	# TEMP debug: full opacity, pure white instance color so layer modulate shows cleanly
	# (Heavy=red, Main=lime, Fine=cyan via L.multi.modulate)
	L.multi.multimesh.set_instance_color(i, Color(1.0, 1.0, 1.0, 1.0))


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
			# Lift only while at or below preferred band; zero lift if already above it
			var band_span := maxf(L.y_prefer_max - L.y_prefer_min, 1.0)
			var band_t := 0.0
			if p.y >= L.y_prefer_min:
				# 1 at bottom of band / floor, 0 at top of band
				band_t = clampf((p.y - L.y_prefer_min) / band_span, 0.0, 1.0)
			# Extra attenuation with screen height
			var peel := band_t * lerpf(1.1, 0.35, height_01)
			v.y -= lift_max * local_gust * peel * delta
			if on_floor:
				v.y -= unstick * local_gust * delta
				if v.y > -55.0 * local_gust:
					v.y = -55.0 * local_gust - randf_range(0.0, 40.0) * local_gust

			# Large-scale eddy (shared spatial field) + fine turbulence
			var eddy := L.detail.get_noise_2d(p.x * 0.008 + 12.0, p.y * 0.007 + spatial_t * 0.55)
			var turb := L.detail.get_noise_2d(p.x * 0.028 - 17.0, p.y * 0.024 + spatial_t * 1.2)
			var swirl := eddy * 0.72 + turb * 0.28
			# Tangential-ish push: horizontal and vertical both get real weight
			var swirl_force := swirl_max * local_gust * (0.65 + 0.45 * band_t)
			v.x += swirl * swirl_force * 0.70 * delta
			v.y += swirl * swirl_force * 1.25 * delta
			# Slight cross-coupling so eddies curve instead of only jitter
			v.x += turb * swirl_force * 0.35 * delta
			v.y -= eddy * swirl_force * 0.40 * delta

		# Soft ceiling / floor of preferred band (y-down coordinate system)
		if p.y < L.y_prefer_min:
			v.y += 220.0 * delta  # above band → push down the screen
		elif p.y > L.y_prefer_max:
			v.y -= 55.0 * delta   # below band → gentle lift back into band

		var drag: float
		if on_floor and local_gust < 0.1:
			drag = 3.5 + 4.0   # less sticky when calm so they can re-engage
		elif on_floor:
			drag = 0.35
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

		# Stream recycle — wide vertical scatter, stay inside layer band
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
	return randf_range(MACRO_TARGET_MIN, MACRO_TARGET_MAX)


func _update_macro(delta: float) -> void:
	if _macro_lerp_t < 1.0:
		_macro_lerp_t = minf(1.0, _macro_lerp_t + delta / MACRO_LERP_TIME)
		# Smoothstep
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
	# Macro already advanced in _process; micro adds ±MICRO_AMP flutter
	var micro := _micro_noise.get_noise_1d(t * 8.0)
	var flutter := 1.0 + micro * MICRO_AMP
	return clampf(_macro_current * flutter, 0.0, 1.0)


func _update_perf_label(gust: float) -> void:
	if _perf_label == null:
		return
	_perf_label.text = "sand: %d (5 layers) | sim: %.2f ms | fps: %d | gust: %.2f" % [
		_total_count,
		_sim_ms,
		Engine.get_frames_per_second(),
		gust,
	]
