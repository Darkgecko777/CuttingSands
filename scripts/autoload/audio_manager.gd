extends Node
## DEBUG BUILD — minimal ambient path to prove audio output works.
## Wind plays on Master at a fixed 0 dB. No modulation until we hear something.

const WIND_STREAM_PATH := "res://Assets/audio/wind_sound.wav"

var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

var _wind_active: bool = false
var _debug_timer: float = 0.0


func _ready() -> void:
	# Everything on Master for this diagnostic
	_music_player = _make_player("MusicPlayer", "Master")
	_ambient_player = _make_player("AmbientPlayer", "Master")

	for i in SFX_POOL_SIZE:
		_sfx_players.append(_make_player("SFXPlayer%d" % i, "Master"))

	call_deferred("_start_wind")
	set_process(true)


func _make_player(player_name: String, bus_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = player_name
	p.bus = bus_name
	add_child(p)
	return p


func _start_wind() -> void:
	var stream := load(WIND_STREAM_PATH) as AudioStream
	if stream == null:
		push_error("AudioManager: FAILED to load " + WIND_STREAM_PATH)
		return

	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD

	_ambient_player.stream = stream
	_ambient_player.volume_db = 0.0          # fixed, loud, no modulation
	_ambient_player.pitch_scale = 1.0
	_ambient_player.bus = "Master"
	_ambient_player.stream_paused = false
	_ambient_player.play()
	_wind_active = true

	print("[AudioManager] START playing=", _ambient_player.playing,
		" bus=", _ambient_player.bus,
		" vol=", _ambient_player.volume_db,
		" paused=", _ambient_player.stream_paused,
		" length=", stream.get_length())


func _process(delta: float) -> void:
	if not _wind_active or _ambient_player == null:
		return

	# Hard restart every second if it is not playing
	_debug_timer += delta
	if _debug_timer >= 1.0:
		_debug_timer = 0.0
		if not _ambient_player.playing:
			_ambient_player.play()
			print("[AudioManager] RESTART play() — was stopped")
		else:
			print("[AudioManager] OK playing=true vol=", _ambient_player.volume_db,
				" pos=", snapped(_ambient_player.get_playback_position(), 0.1))


## Kept so SandBed does not error. No-op while debugging.
func set_wind_intensity(_gust: float) -> void:
	pass


func stop_wind() -> void:
	if _ambient_player and _ambient_player.playing:
		_ambient_player.stop()
	_wind_active = false


func resume_wind() -> void:
	if _ambient_player and _ambient_player.stream:
		_ambient_player.play()
		_wind_active = true


func play_music(stream: AudioStream, fade_in := 0.0) -> void:
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = 0.0 if fade_in <= 0.0 else -40.0
	_music_player.play()
	if fade_in > 0.0:
		var tw := create_tween()
		tw.tween_property(_music_player, "volume_db", 0.0, fade_in)


func stop_music(fade_out := 0.0) -> void:
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
	var p := _sfx_players[0]
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	p.play()
