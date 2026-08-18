extends Node
## DEBUG — test generated tone, then wind with stream playback type.

const WIND_STREAM_PATH := "res://Assets/audio/wind_sound.wav"

var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

var _wind_active: bool = false
var _debug_timer: float = 0.0
var _phase: int = 0  # 0=beep test, 1=wind


func _ready() -> void:
	print("[AudioManager] Mix rate=", AudioServer.get_mix_rate())
	_music_player = _make_player("MusicPlayer", "Master")
	_ambient_player = _make_player("AmbientPlayer", "Master")
	for i in SFX_POOL_SIZE:
		_sfx_players.append(_make_player("SFXPlayer%d" % i, "Master"))

	call_deferred("_run_tests")
	set_process(true)


func _make_player(player_name: String, bus_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = player_name
	p.bus = bus_name
	add_child(p)
	return p


func _make_beep(duration_sec: float = 1.5, freq: float = 440.0) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * duration_sec)
	var data := PackedByteArray()
	data.resize(frames * 2)  # 16-bit mono
	for i in frames:
		var t := float(i) / rate
		var env := 1.0
		if t < 0.02:
			env = t / 0.02
		elif t > duration_sec - 0.05:
			env = maxf(0.0, (duration_sec - t) / 0.05)
		var sample := int(sin(t * freq * TAU) * env * 20000.0)
		sample = clampi(sample, -32767, 32767)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav


func _run_tests() -> void:
	# --- Test 1: generated beep (proves the player + WASAPI path) ---
	print("[AudioManager] === BEEP TEST ===")
	var beep := _make_beep(1.5, 523.25)  # C5
	_ambient_player.stream = beep
	_ambient_player.volume_db = 0.0
	_ambient_player.bus = "Master"
	_ambient_player.play(0.0)
	print("[AudioManager] beep after play | playing=", _ambient_player.playing,
		" pos=", _ambient_player.get_playback_position())

	await get_tree().create_timer(0.3).timeout
	print("[AudioManager] beep +0.3s | playing=", _ambient_player.playing,
		" pos=", snapped(_ambient_player.get_playback_position(), 0.01))

	await get_tree().create_timer(1.5).timeout
	print("[AudioManager] beep done | playing=", _ambient_player.playing)

	# --- Test 2: wind file, no duplicate, force stream playback ---
	print("[AudioManager] === WIND TEST ===")
	var loaded = load(WIND_STREAM_PATH)
	if loaded == null:
		push_error("Failed to load wind")
		return

	var stream: AudioStream = loaded as AudioStream
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		print("[AudioManager] wind format=", wav.format, " rate=", wav.mix_rate,
			" stereo=", wav.stereo, " data=", wav.data.size(), " loop=", wav.loop_mode)
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD

	_ambient_player.stop()
	_ambient_player.stream = stream
	_ambient_player.volume_db = 0.0
	_ambient_player.bus = "Master"

	# Prefer stream playback for long files (Godot 4.3+)
	if "playback_type" in _ambient_player:
		_ambient_player.playback_type = 1  # PLAYBACK_TYPE_STREAM
		print("[AudioManager] set playback_type=STREAM")

	_ambient_player.play(0.0)
	_wind_active = true
	_phase = 1

	print("[AudioManager] wind after play | playing=", _ambient_player.playing,
		" pos=", _ambient_player.get_playback_position())
	await get_tree().process_frame
	print("[AudioManager] wind +1f | playing=", _ambient_player.playing,
		" pos=", _ambient_player.get_playback_position())
	await get_tree().create_timer(0.5).timeout
	print("[AudioManager] wind +0.5s | playing=", _ambient_player.playing,
		" pos=", snapped(_ambient_player.get_playback_position(), 0.01))


func _process(_delta: float) -> void:
	if _phase != 1 or not _wind_active:
		return
	_debug_timer += _delta
	if _debug_timer >= 1.0:
		_debug_timer = 0.0
		print("[AudioManager] wind tick playing=", _ambient_player.playing,
			" pos=", snapped(_ambient_player.get_playback_position(), 0.01))


func set_wind_intensity(_gust: float) -> void:
	pass


func stop_wind() -> void:
	if _ambient_player:
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
	_music_player.play()


func stop_music(_fade_out := 0.0) -> void:
	_music_player.stop()


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
