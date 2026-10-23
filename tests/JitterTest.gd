extends Node

# Crowds 14 soldiers onto one rally point, lets them spread out, then measures how much
# they still twitch: facing flips, run/idle switches and distance moved per unit. Settled
# units should stand still, and not on top of each other.
# Run: Godot --headless --fixed-fps 60 --path . res://tests/JitterTest.tscn

const SETTLE := 4.0
const MEASURE := 3.0

var _battle
var _units: Array = []
var _time := 0.0
var _last := {}
var _flips := 0
var _switches := 0
var _moved := 0.0


func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	_battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(_battle)
	var troops := ["warrior", "archer", "pawn"]
	for i in 14:
		var unit = _battle.spawn_player_unit(PlayerData.TROOPS[troops[i % 3]], 1, Vector2(360 + (i % 4) * 3, 520 + i))
		unit.rally = Vector2(360, 520)
		_units.append(unit)


func _process(delta: float) -> void:
	_time += delta
	if _time < SETTLE:
		return
	for unit in _units:
		var state := [unit.position, unit.sprite.flip_h, unit.sprite.animation]
		if _last.has(unit):
			var before: Array = _last[unit]
			_moved += (state[0] as Vector2).distance_to(before[0])
			if state[1] != before[1]:
				_flips += 1
			if state[2] != before[2]:
				_switches += 1
		_last[unit] = state
	if _time >= SETTLE + MEASURE:
		var per_unit := _moved / _units.size()
		var closest := INF
		for a in _units:
			for b in _units:
				if a != b:
					closest = minf(closest, a.position.distance_to(b.position))
		print("closest two soldiers: %.1f px (separation %.0f)" % [closest, _units[0].SEPARATION])
		print("JitterTest over %.0fs: flips %d, animation switches %d, moved %.1f px per unit" % [MEASURE, _flips, _switches, per_unit])
		var ok: bool = _flips <= 2 and _switches <= 4 and per_unit < 20.0 and closest > _units[0].SEPARATION * 0.6
		print("JitterTest: %s" % ("OK" if ok else "FAIL"))
		get_tree().quit(0 if ok else 1)
