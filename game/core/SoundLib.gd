extends Node

# Every sound effect in the game, synthesised once at startup (the art packs ship no
# audio): tones, noise bursts and little arpeggios in the style of 8-bit sfx tools, so no
# files and no licences are needed. play("name") picks a free voice, jitters the pitch a
# little so repeated sounds don't grate, and skips a sound that played a moment ago
# (forty soldiers hitting at once would otherwise be a wall of noise).

const RATE := 22050
const VOICES := 16
## Milliseconds before the same sound may play again.
const MIN_GAP := {"hit": 55, "arrow": 60, "death": 70, "pop": 45, "jump": 60, "heal": 150,
	"click": 30, "wall": 120, "place": 40, "flip": 40}

var _streams := {}
# Filled by _build() (on a worker thread), then handed over to _streams.
var _built := {}
var _task := -1
var _players: Array = []
var _next := 0
var _last := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	# Synthesis takes about a second, so it runs off the main thread; sounds asked for
	# before it finishes are simply skipped.
	_task = WorkerThreadPool.add_task(_build_async)


# Quitting while the sounds are still being made must wait for the worker.
func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func _build_async() -> void:
	var built := _build()
	_set_streams.call_deferred(built)


func _set_streams(built: Dictionary) -> void:
	_streams = built


## Plays a sound. `volume_db` adjusts loudness, `jitter` the random pitch spread.
func play(name: String, volume_db := 0.0, jitter := 0.06) -> void:
	if not PlayerData.sound_on or not _streams.has(name):
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
	player.stream = _streams[name]
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	player.play()


func has_sound(name: String) -> bool:
	return _streams.has(name)


# --- The sounds ---------------------------------------------------------------------------

## Synthesises every sound. Returns name -> AudioStreamWAV.
func _build() -> Dictionary:
	_built = {}
	# UI
	_add("click", _tone(0.045, 1400, 900, "square", 0.001, 2.0, 0.16))
	_add("coin", _mix(_seq([[1319, 0.05], [1760, 0.16]], "sine", 0.32), _seq([[1319, 0.05], [1760, 0.16]], "tri", 0.12)))
	_add("reward", _mix(_seq([[784, 0.06], [988, 0.06], [1319, 0.2]], "sine", 0.3), _seq([[1568, 0.06], [1976, 0.06], [2637, 0.2]], "sine", 0.08)))
	# Battle shop and gears
	_add("buy", _mix(_seq([[988, 0.06], [1319, 0.16]], "square", 0.14), _seq([[988, 0.06], [1319, 0.16]], "sine", 0.22)))
	_add("sell", _seq([[784, 0.07], [523, 0.14]], "tri", 0.3))
	_add("reroll", _mix(_noise(0.2, 700, 4500, 1.0, 0.22, 0.04), _tone(0.2, 500, 950, "tri", 0.02, 1.0, 0.1)))
	_add("place", _mix(_tone(0.1, 170, 70, "sine", 0.002, 1.5, 0.55), _noise(0.05, 1500, 400, 2.0, 0.2)))
	_add("merge", _mix(_seq([[523, 0.06], [659, 0.06], [784, 0.06], [1047, 0.22]], "square", 0.15),
		_seq([[1047, 0.06], [1319, 0.06], [1568, 0.06], [2093, 0.22]], "sine", 0.1)))
	_add("wave", _horn())
	# Combat
	_add("hit", _mix(_noise(0.07, 3500, 500, 2.0, 0.3), _tone(0.05, 230, 110, "square", 0.001, 2.0, 0.1)))
	_add("arrow", _mix(_noise(0.14, 1200, 5000, 1.2, 0.3, 0.03), _tone(0.1, 900, 500, "sine", 0.01, 1.5, 0.1)))
	_add("death", _tone(0.15, 440, 170, "square", 0.002, 1.5, 0.3))
	_add("pop", _mix(_tone(0.1, 320, 80, "sine", 0.001, 1.5, 0.35), _noise(0.05, 2500, 800, 2.0, 0.12)))
	_add("explosion", _mix(_noise(0.6, 2600, 150, 1.4, 0.45, 0.002), _tone(0.45, 95, 38, "sine", 0.002, 1.2, 0.35)))
	_add("heal", _seq([[880, 0.06], [1175, 0.06], [1568, 0.16]], "sine", 0.14))
	_add("wall", _mix(_tone(0.12, 110, 60, "sine", 0.001, 1.5, 0.4), _noise(0.08, 900, 300, 2.0, 0.2)))
	_add("hero", _mix(_horn(), _seq([[784, 0.1], [1047, 0.3]], "tri", 0.15)))
	# Results
	_add("victory", _mix(_seq([[523, 0.12], [659, 0.12], [784, 0.12], [1047, 0.12], [784, 0.1], [1047, 0.6]], "square", 0.16),
		_seq([[262, 0.36], [392, 0.22], [523, 0.62]], "tri", 0.22)))
	_add("defeat", _mix(_seq([[392, 0.22], [330, 0.22], [262, 0.7]], "tri", 0.26), _seq([[196, 0.44], [131, 0.7]], "saw", 0.06)))
	_add("jump", _tone(0.13, 280, 720, "sine", 0.005, 1.0, 0.2))
	# Chests and summons
	_add("thud", _mix(_tone(0.22, 125, 45, "sine", 0.001, 1.3, 0.7), _noise(0.12, 700, 200, 1.5, 0.3)))
	_add("chest_open", _mix(_noise(0.35, 3200, 400, 1.3, 0.35, 0.002),
		_delay(_seq([[1047, 0.05], [1319, 0.05], [1568, 0.05], [2093, 0.3]], "sine", 0.2), 0.05)))
	_add("flip", _noise(0.08, 1800, 6500, 1.5, 0.2, 0.01))
	_add("rare", _seq([[784, 0.08], [988, 0.08], [1175, 0.3]], "tri", 0.24))
	_add("epic", _mix(_chord([659, 831, 988], 0.8, "tri", 0.12), _delay(_seq([[1319, 0.06], [1661, 0.06], [1976, 0.3]], "sine", 0.12), 0.1)))
	_add("legend", _mix(_lowpass(_chord([523, 659, 784, 1047], 1.4, "saw", 0.08), 2500),
		_mix(_chord([523, 659, 784], 1.4, "tri", 0.1), _delay(_seq([[1568, 0.07], [2093, 0.07], [2637, 0.07], [3136, 0.4]], "sine", 0.1), 0.15))))
	_add("charge", _mix(_tone(1.1, 180, 900, "square", 0.3, 0.3, 0.07, 0.02), _noise(1.1, 400, 5000, 0.2, 0.12, 0.8)))
	return _built


func _add(name: String, samples: PackedFloat32Array) -> void:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	_built[name] = stream


# --- Synthesis ----------------------------------------------------------------------------

## One voice sliding from f0 to f1 Hz. `decay` shapes the fade (higher = snappier).
func _tone(length: float, f0: float, f1: float, wave: String, attack := 0.005, decay := 1.0, volume := 0.5, vibrato := 0.0) -> PackedFloat32Array:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		var freq: float = lerpf(f0, f1, k) * (1.0 + vibrato * sin(TAU * 6.0 * t))
		phase += freq / RATE
		var cycle := fmod(phase, 1.0)
		var v := 0.0
		match wave:
			"sine":
				v = sin(TAU * phase)
			"square":
				v = 0.6 if cycle < 0.5 else -0.6
			"saw":
				v = 2.0 * cycle - 1.0
			"tri":
				v = 4.0 * absf(cycle - 0.5) - 1.0
		out[i] = v * _envelope(t, k, attack, decay) * volume
	return out


## Filtered noise whose cutoff sweeps from c0 to c1 Hz.
func _noise(length: float, c0: float, c1: float, decay := 1.0, volume := 0.5, attack := 0.001) -> PackedFloat32Array:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		var a := 1.0 - exp(-TAU * lerpf(c0, c1, k) / RATE)
		y += a * (randf_range(-1.0, 1.0) - y)
		out[i] = y * 1.8 * _envelope(t, k, attack, decay) * volume
	return out


func _envelope(t: float, k: float, attack: float, decay: float) -> float:
	return minf(1.0, t / maxf(attack, 0.0001)) * pow(1.0 - k, decay)


## Notes one after another: [[freq, seconds], ...].
func _seq(notes: Array, wave: String, volume: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for note in notes:
		out.append_array(_tone(note[1], note[0], note[0], wave, 0.004, 0.8, volume))
	return out


func _chord(freqs: Array, length: float, wave: String, volume: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for f in freqs:
		out = _mix(out, _tone(length, f, f, wave, 0.01, 1.2, volume, 0.004))
	return out


## A two-voice war horn with a little vibrato.
func _horn() -> PackedFloat32Array:
	var low := _lowpass(_tone(0.75, 196, 200, "saw", 0.08, 0.7, 0.22, 0.012), 1400)
	var fifth := _lowpass(_tone(0.75, 294, 299, "saw", 0.12, 0.7, 0.12, 0.012), 1400)
	return _mix(low, fifth)


func _lowpass(samples: PackedFloat32Array, cutoff: float) -> PackedFloat32Array:
	var a := 1.0 - exp(-TAU * cutoff / RATE)
	var y := 0.0
	var out := samples.duplicate()
	for i in out.size():
		y += a * (out[i] - y)
		out[i] = y
	return out


func _delay(samples: PackedFloat32Array, seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	out.append_array(samples)
	return out


## Sums two sounds, as long as the longer one.
func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := a.duplicate() if a.size() >= b.size() else b.duplicate()
	var other := b if a.size() >= b.size() else a
	for i in other.size():
		out[i] += other[i]
	return out
