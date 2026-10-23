extends Node

# Background music. play("lobby") / play("battle") crossfade between tracks; the battle
# track has a second "drive" layer (bass and soft drums) that set_intensity() fades in
# while a wave is fighting, so the music thickens instead of cutting to a new song.
# duck() dips the music for a big moment (a legendary reveal).
#
# Tracks are the placeholder loops from tools/audio/make_music.py (game/audio/music/*.wav).
# Dropping a downloaded <name>.ogg next to them replaces that track; a replaced battle
# track plays without the generated drive layer, which would not fit it.
# See game/audio/music/README.md.

const DIR := "res://game/audio/music/"
const FADE := 1.0
## Music sits well under the effects.
const BASE_DB := -6.0
const SILENT_DB := -60.0

var _main: Array[AudioStreamPlayer] = []
var _drive: Array[AudioStreamPlayer] = []
var _active := 0
var _track := ""
var _intensity := 0.0
var _duck := 0.0
var _tweens := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		_main.append(_player())
		_drive.append(_player())

func _player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.volume_db = SILENT_DB
	add_child(player)
	return player

## Switches to a track ("lobby", "battle"); does nothing if it is already playing.
func play(track: String) -> void:
	if track == _track:
		return
	_track = track
	var stream := _load(track)
	var old := _active
	_active = 1 - _active
	_fade(_main[old], SILENT_DB, true)
	_fade(_drive[old], SILENT_DB, true)
	if stream == null:
		return
	_main[_active].stream = stream
	_main[_active].play()
	_drive[_active].stop()
	var drive: AudioStream = null if _is_custom(track) else _load(track + "_drive")
	if drive != null:
		_drive[_active].stream = drive
		_drive[_active].play()
	_apply()

## 0 = calm (shop break), 1 = fighting. Fades the drive layer.
func set_intensity(value: float) -> void:
	_intensity = clampf(value, 0.0, 1.0)
	_apply()

## Dips the music by `db` for `seconds`, then brings it back.
func duck(seconds := 1.2, db := 10.0) -> void:
	_duck = db
	_apply(0.15)
	get_tree().create_timer(seconds, true, false, true).timeout.connect(func():
		_duck = 0.0
		_apply(0.8))

## Re-reads the saved music toggle.
func refresh() -> void:
	_apply(0.3)

func _apply(time := FADE) -> void:
	var on := PlayerData.music_on
	var level := BASE_DB - _duck if on else SILENT_DB
	_fade(_main[_active], level, false, time)
	var drive_level := SILENT_DB
	if on and _intensity > 0.0:
		drive_level = level + linear_to_db(_intensity)
	_fade(_drive[_active], drive_level, false, time)

func _fade(player: AudioStreamPlayer, db: float, stop_after: bool, time := FADE) -> void:
	var old: Tween = _tweens.get(player)
	if old != null and old.is_valid():
		old.kill()
	var tween := create_tween()
	tween.tween_property(player, "volume_db", db, time)
	if stop_after:
		tween.tween_callback(player.stop)
	_tweens[player] = tween

func _is_custom(track: String) -> bool:
	return ResourceLoader.exists(DIR + track + ".ogg")

## The generated WAVs loop through their import settings; downloaded tracks should be
## imported with Loop on (Import dock) so they repeat.
func _load(track: String) -> AudioStream:
	for ext in [".ogg", ".mp3", ".wav"]:
		if ResourceLoader.exists(DIR + track + ext):
			return load(DIR + track + ext)
	return null
