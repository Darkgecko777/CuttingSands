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

const WIND_NOISE_FREQ := 0.028  # slow variance — longer holds
const GUST_THRESHOLD := 0.28  # higher → longer true-zero calm stretches

# Shared base forces; each layer multiplies these
const BASE_GRAVITY := 28.0     # lowered alone — slower settle during zero-wind so calm feels less dead
const BASE_WIND := 980.0       # dialed back from 1280 — less perpetual streaking
const BASE_LIFT := 900.0       # matched step down
const BASE_UNSTICK := 360.0
const BASE_SWIRL := 320.0

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


var _layers: Array[Layer] = []
var _noise: FastNoiseLite
var _time: float = 0.0
var _sim_ms: float = 0.0
var _total_count: int = 0
var _shimmer_noise: FastNoiseLite

@onready var _perf_label: Label = get_parent().get_node_or_null("SandPerfLabel") as Label


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = WIND_NOISE_FREQ

	_shimmer_noise = FastNoiseLite.new()
	_shimmer_noise.seed = 91
	_shimmer_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_shimmer_noise.frequency = 0.045

	# Heavy: same shared gust, but lags, denser, only rises on stronger gusts
	_layers.append(_make_layer({
		"name": "heavy",
		"count": 220,
		"wind_mul": 0.70,
		"lift_mul": 0.75,
		"gravity_mul": 1.35,
		"swirl_mul": 0.55,
		"gust_mul": 0.70,   # needs stronger gust before it fully engages
		"quad_size": 5.0,
		"modulate": Color(1.0, 0.15, 0.1, 1.0),  # TEMP debug: solid red
		"air_drag": 0.16,   # reduced so once lifted it still travels
		"bed_fraction": 0.65,
		"height_bias": 60.0,
		"seed_off": 11,
		"shimmer": false,
	}))
	# Main: primary stream — strong when gusting, settles when calm
	_layers.append(_make_layer({
		"name": "main",
		"count": 400,
		"wind_mul": 1.05,
		"lift_mul": 1.0,
		"gravity_mul": 1.0,
		"swirl_mul": 1.05,
		"gust_mul": 1.0,
		"quad_size": 3.8,  # enlarged for readability
		"modulate": Color(0.2, 1.0, 0.25, 1.0),  # TEMP debug: solid lime
		"air_drag": 0.11,
		"bed_fraction": 0.40,
		"height_bias": 0.0,
		"seed_off": 29,
		"shimmer": true,
	}))
	# Fine: still the highest/curliest, but no longer perpetual top streak
	_layers.append(_make_layer({
		"name": "fine",
		"count": 280,
		"wind_mul": 1.20,
		"lift_mul": 1.15,
		"gravity_mul": 0.75,   # can fall during calm
		"swirl_mul": 1.55,
		"gust_mul": 1.05,      # closer to shared envelope, not over-driven
		"quad_size": 3.4,  # enlarged so soft grains remain visible
		"modulate": Color(0.15, 0.75, 1.0, 1.0),  # TEMP debug: solid cyan
		"air_drag": 0.08,      # a bit more drag so streaks die when gust drops
		"bed_fraction": 0.20,
		"height_bias": -80.0,  # less extreme top bias
		"seed_off": 47,
		"shimmer": false,
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
		"heavy":
			tex_size = 24
			soft = 0.55
			irreg = 0.35
			L.multi.z_index = 1
		"main":
			tex_size = 22
			soft = 0.62
			irreg = 0.28
			L.multi.z_index = 2
		"fine":
			tex_size = 20
			soft = 0.58  # hardened so core stays visible
			irreg = 0.22
			L.multi.z_index = 3  # draw on top of denser layers
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
			var peel := lerpf(1.15, 0.50, height_01)  # stronger peel near floor
			v.y -= lift_max * local_gust * peel * delta
			if on_floor:
				v.y -= unstick * local_gust * delta
				if v.y > -55.0 * local_gust:
					v.y = -55.0 * local_gust - randf_range(0.0, 40.0) * local_gust

			# Stronger, more rotational swirl (two noise samples for better eddy feel)
			var swirl1 := L.detail.get_noise_2d(p.x * 0.022 + 40.0, p.y * 0.018 + spatial_t)
			var swirl2 := L.detail.get_noise_2d(p.x * 0.035 - 17.0, p.y * 0.028 + spatial_t * 1.3)
			var swirl := (swirl1 * 0.65 + swirl2 * 0.35)
			v.x += swirl * swirl_max * 0.55 * local_gust * delta
			v.y += swirl * swirl_max * 1.15 * local_gust * delta

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
	# Slow time scales + higher threshold → longer true-zero calm, then clear gust pulses
	var n := _noise.get_noise_1d(t * 4.0)
	var d := _noise.get_noise_1d(t * 9.0 + 100.0) * 0.22
	var s := (n + d + 1.0) * 0.5
	if s < GUST_THRESHOLD:
		return 0.0
	var u := (s - GUST_THRESHOLD) / (1.0 - GUST_THRESHOLD)
	# Slightly steeper curve so gusts feel like distinct events, not constant haze
	return clampf(u * u * u * 1.5, 0.0, 1.0)


func _update_perf_label(gust: float) -> void:
	if _perf_label == null:
		return
	_perf_label.text = "sand: %d (3 layers) | sim: %.2f ms | fps: %d | gust: %.2f" % [
		_total_count,
		_sim_ms,
		Engine.get_frames_per_second(),
		gust,
	]
