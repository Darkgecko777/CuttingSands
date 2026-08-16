extends Control

## Title screen for Trader of the Cutting Sands.
## Sand: fine golden translucent grains, full-height left emission, gust pulses.

@onready var new_game_button: TextureButton = %NewGameButton
@onready var continue_button: TextureButton = %ContinueButton
@onready var options_button: TextureButton = %OptionsButton
@onready var exit_button: TextureButton = %ExitButton
@onready var sand_particles: GPUParticles2D = %SandParticles
@onready var dust_haze: GPUParticles2D = %DustHaze

const AMBIENT_RATIO := 0.35
const GUST_PEAK_RATIO := 1.0
const SAND_SPEED_MIN := 320.0
const SAND_SPEED_MAX := 520.0
const DUST_SPEED_MIN := 240.0
const DUST_SPEED_MAX := 400.0
const GUST_SPEED_MULT := 1.35

var _noise: FastNoiseLite
var _gust_active: bool = false
var _gust_elapsed: float = 0.0
var _gust_duration: float = 1.0
var _time_to_next_gust: float = 1.0
var _sand_mat: ParticleProcessMaterial
var _dust_mat: ParticleProcessMaterial


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	new_game_button.grab_focus()

	if sand_particles == null or dust_haze == null:
		push_error("TitleScreen: particle nodes missing (%SandParticles / %DustHaze)")
		return

	_sand_mat = sand_particles.process_material as ParticleProcessMaterial
	_dust_mat = dust_haze.process_material as ParticleProcessMaterial
	if _sand_mat == null or _dust_mat == null:
		push_error("TitleScreen: process_material is not a ParticleProcessMaterial")
		return

	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.35

	sand_particles.emitting = true
	dust_haze.emitting = true
	sand_particles.restart()
	dust_haze.restart()

	_apply_gust_strength(0.0)
	_time_to_next_gust = randf_range(0.5, 1.5)


func _process(delta: float) -> void:
	if _sand_mat == null:
		return

	var t := Time.get_ticks_msec() * 0.001
	var wind_y := _noise.get_noise_1d(t * 0.4) * 0.12
	_sand_mat.direction = Vector3(1.0, wind_y, 0.0).normalized()
	if _dust_mat:
		_dust_mat.direction = Vector3(1.0, wind_y * 1.2, 0.0).normalized()

	if _gust_active:
		_gust_elapsed += delta
		var u := clampf(_gust_elapsed / _gust_duration, 0.0, 1.0)
		_apply_gust_strength(sin(u * PI))
		if _gust_elapsed >= _gust_duration:
			_end_gust()
	else:
		_time_to_next_gust -= delta
		if _time_to_next_gust <= 0.0:
			_start_gust()


func _start_gust() -> void:
	_gust_active = true
	_gust_elapsed = 0.0
	_gust_duration = randf_range(0.9, 2.2)
	if _sand_mat:
		if randf() < 0.4:
			_sand_mat.gravity = Vector3(0.0, randf_range(45.0, 75.0), 0.0)
		else:
			_sand_mat.gravity = Vector3(0.0, randf_range(22.0, 40.0), 0.0)


func _end_gust() -> void:
	_gust_active = false
	_apply_gust_strength(0.0)
	if _sand_mat:
		_sand_mat.gravity = Vector3(0.0, 32.0, 0.0)
	_time_to_next_gust = randf_range(1.2, 3.5)


func _apply_gust_strength(strength: float) -> void:
	sand_particles.amount_ratio = lerpf(AMBIENT_RATIO, GUST_PEAK_RATIO, strength)
	dust_haze.amount_ratio = lerpf(AMBIENT_RATIO * 0.8, GUST_PEAK_RATIO * 0.9, strength)

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
