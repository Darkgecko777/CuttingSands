class_name StreamFade
extends RefCounted

## Linear-amplitude fade on one player. Survives scene changes when ticked by AudioManager.

var player: AudioStreamPlayer
var from_amp: float = 1.0
var to_amp: float = 0.0
var elapsed: float = 0.0
var duration: float = 1.0
var stop_when_done: bool = false
var restore_db: float = 0.0


func _init(
		p: AudioStreamPlayer,
		p_to_amp: float,
		p_duration: float,
		p_stop: bool = false,
		p_restore_db: float = 0.0
	) -> void:
	player = p
	to_amp = clampf(p_to_amp, 0.0, 1.0)
	duration = maxf(0.05, p_duration)
	stop_when_done = p_stop
	restore_db = p_restore_db
	from_amp = _amp_of(p)


func tick(delta: float) -> bool:
	if player == null:
		return true
	elapsed += delta
	var u := clampf(elapsed / duration, 0.0, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	var amp := lerpf(from_amp, to_amp, u)
	player.volume_db = linear_to_db(maxf(amp, 0.0001))
	if u < 1.0:
		return false
	if stop_when_done:
		player.stop()
	player.volume_db = restore_db
	return true


static func _amp_of(p: AudioStreamPlayer) -> float:
	if p == null:
		return 0.0
	return clampf(db_to_linear(p.volume_db), 0.0, 1.0)
