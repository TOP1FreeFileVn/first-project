extends Node

# Every effect is a short original WAV in one soft, wooden style (felt mallets, kalimba,
# Rhodes, round gongs, dark breathy noise) so effects, music and jingles share a key and feel:
#   game/audio/ui     button taps    tools/audio/make_ui_taps.py
#   game/audio/gear   gear board     tools/audio/make_gear_sfx.py
#   game/audio/jingle battle cues    tools/audio/make_jingles.py
#   game/audio/sfx    everything else tools/audio/make_sfx.py
# play("name") picks a free voice, jitters the pitch a little so repeated sounds don't
# grate, and skips a sound that played a moment ago (forty soldiers hitting at once would
# otherwise be a wall of noise).

const VOICES := 16
const UI_TAPS := [
	preload("res://game/audio/ui/ui_tap_01.wav"),
	preload("res://game/audio/ui/ui_tap_02.wav"),
	preload("res://game/audio/ui/ui_tap_03.wav"),
]
const SOUNDS := {
	"gear_pick": preload("res://game/audio/gear/gear_pick.wav"),
	"gear_place": preload("res://game/audio/gear/gear_place.wav"),
	"gear_back": preload("res://game/audio/gear/gear_back.wav"),
	"merge": preload("res://game/audio/gear/gear_merge.wav"),
	"battle_start": preload("res://game/audio/jingle/battle_start.wav"),
	"wave": preload("res://game/audio/jingle/wave.wav"),
	"victory": preload("res://game/audio/jingle/victory.wav"),
	"defeat": preload("res://game/audio/jingle/defeat.wav"),
	"coin": preload("res://game/audio/sfx/coin.wav"),
	"reward": preload("res://game/audio/sfx/reward.wav"),
	"buy": preload("res://game/audio/sfx/buy.wav"),
	"sell": preload("res://game/audio/sfx/sell.wav"),
	"reroll": preload("res://game/audio/sfx/reroll.wav"),
	"hit": preload("res://game/audio/sfx/hit.wav"),
	"arrow": preload("res://game/audio/sfx/arrow.wav"),
	"death": preload("res://game/audio/sfx/death.wav"),
	"pop": preload("res://game/audio/sfx/pop.wav"),
	"explosion": preload("res://game/audio/sfx/explosion.wav"),
	"heal": preload("res://game/audio/sfx/heal.wav"),
	"wall": preload("res://game/audio/sfx/wall.wav"),
	"hero": preload("res://game/audio/sfx/hero.wav"),
	"jump": preload("res://game/audio/sfx/jump.wav"),
	"thud": preload("res://game/audio/sfx/thud.wav"),
	"charge": preload("res://game/audio/sfx/charge.wav"),
	"chest_open": preload("res://game/audio/sfx/chest_open.wav"),
	"flip": preload("res://game/audio/sfx/flip.wav"),
	"rare": preload("res://game/audio/sfx/rare.wav"),
	"epic": preload("res://game/audio/sfx/epic.wav"),
	"legend": preload("res://game/audio/sfx/legend.wav"),
	"pet": preload("res://game/audio/sfx/pet.wav"),
}
## Milliseconds before the same sound may play again.
const MIN_GAP := {"hit": 55, "arrow": 60, "death": 70, "pop": 45, "jump": 60, "heal": 150,
	"click": 30, "wall": 120, "flip": 40, "coin": 50, "pet": 250,
	"gear_pick": 40, "gear_place": 40, "gear_back": 40}

var _players: Array = []
var _next := 0
var _ui_tap_index := 0
var _last := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)

## Plays a sound. `volume_db` adjusts loudness, `jitter` the random pitch spread.
## `pitch` sets the base pitch_scale (e.g. heavier or brighter by gear tier).
func play(name: String, volume_db := 0.0, jitter := 0.06, pitch := 1.0) -> void:
	if not PlayerData.sound_on or not (name == "click" or SOUNDS.has(name)):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(name, -100000)) < int(MIN_GAP.get(name, 0)):
		return
	_last[name] = now
	var player: AudioStreamPlayer = null
	for candidate in _players:
		if not candidate.playing:
			player = candidate
			break
	if player == null:
		player = _players[_next]
		_next = (_next + 1) % _players.size()
	if name == "click":
		player.stream = UI_TAPS[_ui_tap_index]
		_ui_tap_index = (_ui_tap_index + 1) % UI_TAPS.size()
		jitter = minf(jitter, 0.018)
	else:
		player.stream = SOUNDS[name]
	player.volume_db = volume_db
	player.pitch_scale = pitch + randf_range(-jitter, jitter)
	player.play()


func has_sound(name: String) -> bool:
	return name == "click" or SOUNDS.has(name)
