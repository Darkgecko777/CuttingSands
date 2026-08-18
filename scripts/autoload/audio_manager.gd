extends Node
## Persistent audio manager.
## Buses: Music, Ambient, SFX (plus Master).
## Only Ambient (wind) is wired for now; Music and SFX are ready for later use.

# --- Ambient / Wind ---
const WIND_STREAM_PATH := "res://Assets/audio/wind_sound.wav"
const WIND_BASE_DB := -18.0
const WIND_GUST_DB_RANGE := 16.0
const WIND_PITCH_MIN := 0.96
const WIND_PITCH_RANGE := 0.10

var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

var _wind_active: bool = false


func _ready() -> void:
	_music_player = _make_player("MusicPlayer", "Music")
	_ambient_player = _make_player("AmbientPlayer", "Ambient")

	for i in SFX_POOL_SIZE:
		_sfx_players.append(_make_player("SFXPlayer%d" % i, "SFX"))

	# Start the persistent wind baseline immediately
	_start_wind()


func _make_player(player_name: String, bus_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = player_name
	p.bus = bus_name
	add_child(p)
	return p


# ---------------------------------------------------------------------------
# Ambient / Wind
# ---------------------------------------------------------------------------

func _start_wind() -> void:
	var stream := load(WIND_STREAM_PATH) as AudioStream
	if stream == null:
		push_warning("AudioManager: wind stream not found at %s" % WIND_STREAM_PATH)
		return

	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD

	_ambient_player.stream = stream
	_ambient_player.volume_db = WIND_BASE_DB
	_ambient_player.pitch_scale = 1.0
	_ambient_player.play()
	_wind_active = true


## Drive ambient wind from the shared sand-gust envelope (0.0 – 1.0).
func set_wind_intensity(gust: float) -> void:
	if not _wind_active:
		return
	gust = clampf(gust, 0.0, 1.0)
	_ambient_player.volume_db = WIND_BASE_DB + gust * WIND_GUST_DB_RANGE
	_ambient_player.pitch_scale = WIND_PITCH_MIN + gust * WIND_PITCH_RANGE


func stop_wind() -> void:
	if _ambient_player.playing:
		_ambient_player.stop()
	_wind_active = false


func resume_wind() -> void:
	if not _wind_active and _ambient_player.stream:
		_ambient_player.play()
		_wind_active = true


# ---------------------------------------------------------------------------
# Music (stubs ready for later)
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# SFX (simple pool)
# ---------------------------------------------------------------------------

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
	# All busy — steal the first one
	var p := _sfx_players[0]
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	p.play()
