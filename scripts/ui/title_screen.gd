extends Control

## Title screen sand: lower-third, wind-dominated gusts that stir and streak L→R with swirl.

@onready var new_game_button: TextureButton = %NewGameButton
@onready var continue_button: TextureButton = %ContinueButton
@onready var options_button: TextureButton = %OptionsButton
@onready var exit_button: TextureButton = %ExitButton
@onready var sand_particles: GPUParticles2D = %SandParticles
@onready var dust_haze: GPUParticles2D = %DustHaze

# Emission strength
const AMBIENT_RATIO := 0.2
const GUST_PEAK_RATIO := 1.0

# Horizontal wind (pixels/sec) — gust multiplies these
const SAND_SPEED_MIN := 420.0
const SAND_SPEED_MAX := 720.0
const DUST_SPEED_MIN := 300.0
const DUST_SPEED_MAX := 520.0
const GUST_SPEED_MULT := 1.55

# Gravity: ambient settles; gust nearly weightless so wind owns the motion
const GRAVITY_AMBIENT := 55.0
const GRAVITY_GUST := 6.0
const GRAVITY_STIR := -40.0  # brief upward lift at gust onset

# Turbulence: stronger in gust so paths spiral
const TURB_STRENGTH_AMBIENT := 1.2
const TURB_STRENGTH_GUST := 5.5
const TURB_INFLUENCE_AMBIENT := 0.04
const TURB_INFLUENCE_GUST := 0.28

var _noise: FastNoiseLite
var _gust_active: bool = false
var _gust_elapsed: float = 0.0
var _gust_duration: float = 1.2
var _time_to_next_gust: float = 0.8
var _sand_mat: ParticleProcessMaterial
var _dust_mat: ParticleProcessMaterial
var _stir_timer: float = 0.0


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	new_game_button.grab_focus()

	if sand_particles == null or dust_haze == null:
		push_error("TitleScreen: missing particle nodes")
		return

	_sand_mat = sand_particles.process_material as ParticleProcessMaterial
	_dust_mat = dust_haze.process_material as ParticleProcessMaterial
	if _sand_mat == null or _dust_mat == null:
		push_error("TitleScreen: process_material missing")
		return

	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.4

	sand_particles.emitting = true
	dust_haze.emitting = true
	_apply_gust_strength(0.0)
	sand_particles.restart()
	dust_haze.restart()

	_time_to_next_gust = randf_range(0.6, 1.4)


func _process(delta: float) -> void:
	if _sand_mat == null:
		return

	# Wind direction wander (mostly +X, slight vertical breathe)
	var t := Time.get_ticks_msec() * 0.001
	var wind_y := _noise.get_noise_1d(t * 0.35) * 0.1
	var dir := Vector3(1.0, wind_y, 0.0).normalized()
	_sand_mat.direction = dir
	if _dust_mat:
		_dust_mat.direction = Vector3(1.0, wind_y * 1.15, 0.0).normalized()

	# Brief upward stir at the start of each gust
	if _stir_timer > 0.0:
		_stir_timer -= delta
		if _sand_mat:
			_sand_mat.gravity = Vector3(0.0, GRAVITY_STIR, 0.0)
		if _dust_mat:
			_dust_mat.gravity = Vector3(0.0, GRAVITY_STIR * 0.7, 0.0)

	if _gust_active:
		_gust_elapsed += delta
		var u := clampf(_gust_elapsed / _gust_duration, 0.0, 1.0)
		# Fast attack, sustained body, soft release
		var envelope := sin(u * PI)
		if u < 0.15:
			envelope = maxf(envelope, u / 0.15)
		_apply_gust_strength(envelope)
		if _gust_elapsed >= _gust_duration:
			_end_gust()
	else:
		_time_to_next_gust -= delta
		if _time_to_next_gust <= 0.0:
			_start_gust()


func _start_gust() -> void:
	_gust_active = true
	_gust_elapsed = 0.0
	_gust_duration = randf_range(1.1, 2.4)
	_stir_timer = randf_range(0.18, 0.35)


func _end_gust() -> void:
	_gust_active = false
	_stir_timer = 0.0
	_apply_gust_strength(0.0)
	_time_to_next_gust = randf_range(1.5, 3.8)


func _apply_gust_strength(strength: float) -> void:
	sand_particles.amount_ratio = lerpf(AMBIENT_RATIO, GUST_PEAK_RATIO, strength)
	dust_haze.amount_ratio = lerpf(AMBIENT_RATIO * 0.7, GUST_PEAK_RATIO * 0.85, strength)

	var speed_mult := lerpf(1.0, GUST_SPEED_MULT, strength)
	if _sand_mat:
		_sand_mat.initial_velocity_min = SAND_SPEED_MIN * speed_mult
		_sand_mat.initial_velocity_max = SAND_SPEED_MAX * speed_mult
		if _stir_timer <= 0.0:
			_sand_mat.gravity = Vector3(0.0, lerpf(GRAVITY_AMBIENT, GRAVITY_GUST, strength), 0.0)
		_sand_mat.turbulence_noise_strength = lerpf(TURB_STRENGTH_AMBIENT, TURB_STRENGTH_GUST, strength)
		_sand_mat.turbulence_influence_min = lerpf(TURB_INFLUENCE_AMBIENT, TURB_INFLUENCE_GUST * 0.6, strength)
		_sand_mat.turbulence_influence_max = lerpf(TURB_INFLUENCE_AMBIENT * 1.5, TURB_INFLUENCE_GUST, strength)
		_sand_mat.tangential_accel_min = lerpf(0.0, -80.0, strength)
		_sand_mat.tangential_accel_max = lerpf(0.0, 80.0, strength)
	if _dust_mat:
		_dust_mat.initial_velocity_min = DUST_SPEED_MIN * speed_mult
		_dust_mat.initial_velocity_max = DUST_SPEED_MAX * speed_mult
		if _stir_timer <= 0.0:
			_dust_mat.gravity = Vector3(0.0, lerpf(GRAVITY_AMBIENT * 0.85, GRAVITY_GUST * 0.8, strength), 0.0)
		_dust_mat.turbulence_noise_strength = lerpf(TURB_STRENGTH_AMBIENT * 1.2, TURB_STRENGTH_GUST * 1.1, strength)
		_dust_mat.turbulence_influence_min = lerpf(TURB_INFLUENCE_AMBIENT, TURB_INFLUENCE_GUST * 0.7, strength)
		_dust_mat.turbulence_influence_max = lerpf(TURB_INFLUENCE_AMBIENT * 1.5, TURB_INFLUENCE_GUST * 1.1, strength)
		_dust_mat.tangential_accel_min = lerpf(0.0, -60.0, strength)
		_dust_mat.tangential_accel_max = lerpf(0.0, 60.0, strength)


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/house_select.tscn")


func _on_continue_pressed() -> void:
	print("Continue pressed (not yet implemented)")


func _on_options_pressed() -> void:
	print("Options pressed (not yet implemented)")


func _on_exit_pressed() -> void:
	get_tree().quit()
