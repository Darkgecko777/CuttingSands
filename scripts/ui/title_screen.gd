extends Control

## Title screen for Trader of the Cutting Sands.
## Sand: sparse ambient dust + scripted sporadic gusts with noise-nudged wind.

@onready var new_game_button: TextureButton = %NewGameButton
@onready var continue_button: TextureButton = %ContinueButton
@onready var options_button: TextureButton = %OptionsButton
@onready var exit_button: TextureButton = %ExitButton
@onready var sand_particles: GPUParticles2D = %SandParticles
@onready var dust_haze: GPUParticles2D = %DustHaze

## Ambient emission when no gust is active (0–1).
const AMBIENT_RATIO := 0.12
## Peak emission during a gust (0–1).
const GUST_PEAK_RATIO := 0.95
## Base horizontal speeds written into the process material.
const SAND_SPEED_MIN := 260.0
const SAND_SPEED_MAX := 420.0
const DUST_SPEED_MIN := 180.0
const DUST_SPEED_MAX := 320.0
## Extra speed multiplier at gust peak.
const GUST_SPEED_MULT := 1.45

var _noise: FastNoiseLite
var _gust_active: bool = false
var _gust_elapsed: float = 0.0
var _gust_duration: float = 1.0
var _time_to_next_gust: float = 1.5
var _sand_mat: ParticleProcessMaterial
var _dust_mat: ParticleProcessMaterial


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	new_game_button.grab_focus()

	_sand_mat = sand_particles.process_material as ParticleProcessMaterial
	_dust_mat = dust_haze.process_material as ParticleProcessMaterial

	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.35

	# Start quiet; first gust arrives shortly.
	sand_particles.amount_ratio = AMBIENT_RATIO
	dust_haze.amount_ratio = AMBIENT_RATIO * 0.7
	_time_to_next_gust = randf_range(0.8, 2.2)


func _process(delta: float) -> void:
	# Gentle wind direction wander (shared by both systems).
	var t := Time.get_ticks_msec() * 0.001
	var wind_y := _noise.get_noise_1d(t * 0.4) * 0.12
	var wind_dir := Vector3(1.0, wind_y, 0.0).normalized()
	if _sand_mat:
		_sand_mat.direction = wind_dir
	if _dust_mat:
		_dust_mat.direction = Vector3(1.0, wind_y * 1.2, 0.0).normalized()

	if _gust_active:
		_gust_elapsed += delta
		var u := clampf(_gust_elapsed / _gust_duration, 0.0, 1.0)
		# Smooth pulse: rise and fall.
		var envelope := sin(u * PI)
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
	# Short sharp gusts and longer rolling ones.
	_gust_duration = randf_range(0.7, 1.8)
	# Slight one-shot bias so some gusts aim more downward (grains fall off bottom).
	if _sand_mat and randf() < 0.4:
		_sand_mat.gravity = Vector3(0.0, randf_range(55.0, 90.0), 0.0)
	elif _sand_mat:
		_sand_mat.gravity = Vector3(0.0, randf_range(28.0, 48.0), 0.0)


func _end_gust() -> void:
	_gust_active = false
	_apply_gust_strength(0.0)
	if _sand_mat:
		_sand_mat.gravity = Vector3(0.0, 36.0, 0.0)
	# Quiet gap between gusts.
	_time_to_next_gust = randf_range(1.6, 4.5)


func _apply_gust_strength(strength: float) -> void:
	# strength 0 = ambient, 1 = peak gust
	sand_particles.amount_ratio = lerpf(AMBIENT_RATIO, GUST_PEAK_RATIO, strength)
	dust_haze.amount_ratio = lerpf(AMBIENT_RATIO * 0.7, GUST_PEAK_RATIO * 0.85, strength)

	var speed_mult := lerpf(1.0, GUST_SPEED_MULT, strength)
	if _sand_mat:
		_sand_mat.initial_velocity_min = SAND_SPEED_MIN * speed_mult
		_sand_mat.initial_velocity_max = SAND_SPEED_MAX * speed_mult
	if _dust_mat:
		_dust_mat.initial_velocity_min = DUST_SPEED_MIN * speed_mult
		_dust_mat.initial_velocity_max = DUST_SPEED_MAX * speed_mult


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/house_select.tscn")


func _on_continue_pressed() -> void:
	print("Continue pressed (not yet implemented)")


func _on_options_pressed() -> void:
	print("Options pressed (not yet implemented)")


func _on_exit_pressed() -> void:
	get_tree().quit()
