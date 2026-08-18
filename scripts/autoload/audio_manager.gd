extends Node
## Persistent audio manager (scene-based players).
## AmbientPlayer has stream + autoplay set in the .tscn (same path as working TestWind).
## This script only ensures loop and drives intensity.

const WIND_BASE_DB := -12.0
const WIND_GUST_DB_RANGE := 14.0
const WIND_PITCH_MIN := 0.96
const WIND_PITCH_RANGE := 0.10

@onready var _music_player: AudioStreamPlayer = $MusicPlayer
@onready var _ambient_player: AudioStreamPlayer = $AmbientPlayer

var _sfx_players: Array[AudioStreamPlayer] = []
var _wind_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for child in get_children():
		if child is AudioStreamPlayer and child.name.begins_with("SFXPlayer"):
			_sfx_players.append(child)
			child.process_mode = Node.PROCESS_MODE_ALWAYS

	_ambient_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS

	# Ensure loop on the stream resource
	var stream := _ambient_player.stream
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD

	# Autoplay should already have started it; force play if needed
	if _ambient_player.stream and not _ambient_player.playing:
		_ambient_player.play()

	_wind_active = _ambient_player.stream != null
	print("[AudioManager] ready | playing=", _ambient_player.playing,
		" autoplay=", _ambient_player.autoplay,
		" bus=", _ambient_player.bus,
		" stream=", _ambient_player.stream)


func set_wind_intensity(gust: float) -> void:
	if not _wind_active or _ambient_player == null:
		return
	if _ambient_player.stream and not _ambient_player.playing:
		_ambient_player.play()
	gust = clampf(gust, 0.0, 1.0)
	_ambient_player.volume_db = WIND_BASE_DB + gust * WIND_GUST_DB_RANGE
	_ambient_player.pitch_scale = WIND_PITCH_MIN + gust * WIND_PITCH_RANGE


func stop_wind() -> void:
	if _ambient_player and _ambient_player.playing:
		_ambient_player.stop()
	_wind_active = false


func resume_wind() -> void:
	if _ambient_player and _ambient_player.stream:
		_ambient_player.play()
		_wind_active = true


func play_music(stream: AudioStream, fade_in := 0.0) -> void:
	if stream == null or _music_player == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = 0.0 if fade_in <= 0.0 else -40.0
	_music_player.play()
	if fade_in > 0.0:
		var tw := create_tween()
		tw.tween_property(_music_player, "volume_db", 0.0, fade_in)


func stop_music(fade_out := 0.0) -> void:
	if _music_player == null:
		return
	if fade_out <= 0.0:
		_music_player.stop()
		return
	var tw := create_tween()
	tw.tween_property(_music_player, "volume_db", -40.0, fade_out)
	tw.tween_callback(_music_player.stop)


func play_sfx(stream: AudioStream, volume_db := 0.0, pitch_scale := 1.0) -> void:
	if stream == null:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch_scale
			p.play()
			return
	if _sfx_players.size() > 0:
		var p := _sfx_players[0]
		p.stream = stream
		p.volume_db = volume_db
		p.pitch_scale = pitch_scale
		p.play()
