extends Node
## Persistent audio manager (scene-based players).
## Fades tick here so they outlive title / house-select / play scene swaps.

const WIND_BASE_DB := -12.0
const WIND_GUST_DB_RANGE := 14.0
const WIND_PITCH_MIN := 0.96
const WIND_PITCH_RANGE := 0.10
const WIND_FADE_OUT := 2.2

@onready var _music_player: AudioStreamPlayer = $MusicPlayer
@onready var _ambient_player: AudioStreamPlayer = $AmbientPlayer

var _sfx_players: Array[AudioStreamPlayer] = []
var _wind_active: bool = false
var _wind_fading: bool = false
var _fades: Array[StreamFade] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for child in get_children():
		if child is AudioStreamPlayer and child.name.begins_with("SFXPlayer"):
			_sfx_players.append(child)
			child.process_mode = Node.PROCESS_MODE_ALWAYS

	_ambient_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS

	var stream := _ambient_player.stream
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD

	if _ambient_player.stream and not _ambient_player.playing:
		_ambient_player.play()

	_wind_active = _ambient_player.stream != null
	print("[AudioManager] ready | playing=", _ambient_player.playing,
		" autoplay=", _ambient_player.autoplay,
		" bus=", _ambient_player.bus,
		" stream=", _ambient_player.stream)


func _process(delta: float) -> void:
	if _fades.is_empty():
		return
	var still: Array[StreamFade] = []
	for fade in _fades:
		if fade.tick(delta):
			if fade.player == _ambient_player:
				_wind_fading = false
				_wind_active = fade.player != null and fade.player.playing
		else:
			still.append(fade)
	_fades = still


func set_wind_intensity(gust: float) -> void:
	if not _wind_active or _wind_fading or _ambient_player == null:
		return
	if _ambient_player.stream and not _ambient_player.playing:
		_ambient_player.play()
	gust = clampf(gust, 0.0, 1.0)
	_ambient_player.volume_db = WIND_BASE_DB + gust * WIND_GUST_DB_RANGE
	_ambient_player.pitch_scale = WIND_PITCH_MIN + gust * WIND_PITCH_RANGE


func fade_out_wind(duration: float = WIND_FADE_OUT) -> void:
	if _ambient_player == null:
		return
	_wind_active = false
	_wind_fading = true
	_drop_fades_for(_ambient_player)
	if not _ambient_player.playing:
		_wind_fading = false
		return
	_fades.append(StreamFade.new(_ambient_player, 0.0, duration, true, WIND_BASE_DB))


func stop_wind() -> void:
	_drop_fades_for(_ambient_player)
	_wind_fading = false
	_wind_active = false
	if _ambient_player and _ambient_player.playing:
		_ambient_player.stop()
	if _ambient_player:
		_ambient_player.volume_db = WIND_BASE_DB


func resume_wind() -> void:
	if _ambient_player == null or _ambient_player.stream == null:
		return
	_drop_fades_for(_ambient_player)
	_wind_fading = false
	_wind_active = true
	_ambient_player.volume_db = WIND_BASE_DB
	_ambient_player.pitch_scale = WIND_PITCH_MIN
	if not _ambient_player.playing:
		_ambient_player.play()


func fade_out_music(duration: float = 1.6) -> void:
	if _music_player == null:
		return
	_drop_fades_for(_music_player)
	if not _music_player.playing:
		return
	_fades.append(StreamFade.new(_music_player, 0.0, duration, true, 0.0))


func play_music(stream: AudioStream, fade_in := 0.0) -> void:
	if stream == null or _music_player == null:
		return
	_drop_fades_for(_music_player)
	_music_player.stream = stream
	if fade_in <= 0.0:
		_music_player.volume_db = 0.0
		_music_player.play()
		return
	_music_player.volume_db = linear_to_db(0.0001)
	_music_player.play()
	_fades.append(StreamFade.new(_music_player, 1.0, fade_in, false, 0.0))


func stop_music(fade_out := 0.0) -> void:
	if _music_player == null:
		return
	if fade_out <= 0.0:
		_drop_fades_for(_music_player)
		_music_player.stop()
		return
	fade_out_music(fade_out)


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


func _drop_fades_for(player: AudioStreamPlayer) -> void:
	var keep: Array[StreamFade] = []
	for fade in _fades:
		if fade.player != player:
			keep.append(fade)
	_fades = keep
