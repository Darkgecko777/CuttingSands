extends Control

## Title screen: lower-third reservoir + discrete gust cohorts.
## Reservoir = sparse sand always present.
## Gust = short emit window with shared forces, then emitting stops so that cohort finishes together.

@onready var new_game_button: TextureButton = %NewGameButton
@onready var continue_button: TextureButton = %ContinueButton
@onready var options_button: TextureButton = %OptionsButton
@onready var exit_button: TextureButton = %ExitButton
@onready var sand_reservoir: GPUParticles2D = %SandReservoir
@onready var sand_gust: GPUParticles2D = %SandGust

const RESERVOIR_RATIO := 0.35

const GUST_EMIT_MIN := 0.28
const GUST_EMIT_MAX := 0.55
const GUST_GAP_MIN := 1.8
const GUST_GAP_MAX := 4.0

const GUST_SPEED_MIN := 480.0
const GUST_SPEED_MAX := 780.0
const GUST_GRAVITY := 4.0
const GUST_STIR_GRAVITY := -55.0
const GUST_TURB_STRENGTH := 6.0
const GUST_TURB_INFLUENCE := 0.32

var _noise: FastNoiseLite
var _gust_mat: ParticleProcessMaterial
var _reservoir_mat: ParticleProcessMaterial

var _gust_emitting: bool = false
var _emit_time_left: float = 0.0
var _gap_time_left: float = 1.2
var _emit_total: float = 0.4


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	new_game_button.grab_focus()

	if sand_reservoir == null or sand_gust == null:
		push_error("TitleScreen: missing SandReservoir / SandGust")
		return

	_reservoir_mat = sand_reservoir.process_material as ParticleProcessMaterial
	_gust_mat = sand_gust.process_material as ParticleProcessMaterial
	if _gust_mat == null:
		push_error("TitleScreen: gust process_material missing")
		return

	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.35

	sand_reservoir.emitting = true
	sand_reservoir.amount_ratio = RESERVOIR_RATIO
	sand_reservoir.restart()

	sand_gust.emitting = false
	sand_gust.amount_ratio = 1.0

	_gust_emitting = false
	_gap_time_left = randf_range(0.8, 1.6)


func _process(delta: float) -> void:
	if _gust_mat == null:
		return

	var t := Time.get_ticks_msec() * 0.001
	var wind_y := _noise.get_noise_1d(t * 0.3) * 0.08
	if _reservoir_mat:
		_reservoir_mat.direction = Vector3(1.0, wind_y * 0.5, 0.0).normalized()

	if _gust_emitting:
		_emit_time_left -= delta
		# First third of emit: upward stir; rest: near-weightless wind carry
		var u := 1.0 - clampf(_emit_time_left / maxf(_emit_total, 0.001), 0.0, 1.0)
		if u < 0.35:
			_gust_mat.gravity = Vector3(0.0, GUST_STIR_GRAVITY, 0.0)
		else:
			_gust_mat.gravity = Vector3(0.0, GUST_GRAVITY, 0.0)

		if _emit_time_left <= 0.0:
			# Stop birthing — cohort already in flight finishes on its own lifetime
			sand_gust.emitting = false
			_gust_emitting = false
			_gap_time_left = randf_range(GUST_GAP_MIN, GUST_GAP_MAX)
	else:
		_gap_time_left -= delta
		if _gap_time_left <= 0.0:
			_begin_gust_cohort()


func _begin_gust_cohort() -> void:
	_emit_total = randf_range(GUST_EMIT_MIN, GUST_EMIT_MAX)
	_emit_time_left = _emit_total

	# Shared wind locked for this cohort
	var wy := _noise.get_noise_1d(Time.get_ticks_msec() * 0.001) * 0.12
	_gust_mat.direction = Vector3(1.0, wy, 0.0).normalized()
	_gust_mat.initial_velocity_min = GUST_SPEED_MIN
	_gust_mat.initial_velocity_max = GUST_SPEED_MAX
	_gust_mat.gravity = Vector3(0.0, GUST_STIR_GRAVITY, 0.0)
	_gust_mat.turbulence_noise_strength = GUST_TURB_STRENGTH
	_gust_mat.turbulence_influence_min = GUST_TURB_INFLUENCE * 0.55
	_gust_mat.turbulence_influence_max = GUST_TURB_INFLUENCE
	_gust_mat.tangential_accel_min = -90.0
	_gust_mat.tangential_accel_max = 90.0

	sand_gust.restart()
	sand_gust.emitting = true
	_gust_emitting = true


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/house_select.tscn")


func _on_continue_pressed() -> void:
	print("Continue pressed (not yet implemented)")


func _on_options_pressed() -> void:
	print("Options pressed (not yet implemented)")


func _on_exit_pressed() -> void:
	get_tree().quit()
