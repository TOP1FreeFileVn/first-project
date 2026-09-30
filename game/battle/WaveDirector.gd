extends Node

# Turns a LevelData wave list into timed spawn requests. Waves no longer chain on their
# own: Battle starts each one (after the between-wave shop) and hears back when every
# enemy of it has spawned and died.

signal spawn_requested(troop_id: String, elite: bool)
signal wave_started(index: int, total: int)
signal wave_cleared(index: int)
signal all_cleared

var battle
var wave_index := -1

var _level: Resource
var _events: Array = []
var _clock := 0.0
var _running := false


func setup(level: Resource) -> void:
	_level = level


func total() -> int:
	return _level.waves.size()


func is_last() -> bool:
	return wave_index >= total() - 1


## Starts the next wave.
func start_next() -> void:
	wave_index += 1
	var wave: Dictionary = _level.waves[wave_index]
	_events.clear()
	for group in wave["groups"]:
		var start: float = group.get("start", 0.0)
		for i in int(group["count"]):
			_events.append({
				"time": start + i * float(group.get("interval", 1.0)),
				"troop": group["troop"],
				"elite": group.get("elite", false),
			})
	_events.sort_custom(func(a, b): return a["time"] < b["time"])
	_clock = 0.0
	_running = true
	wave_started.emit(wave_index, total())


func stop() -> void:
	_running = false


## Enemies still to come in the running wave.
func pending() -> int:
	return _events.size()


## Troop id -> {"count", "elite"} for a wave (the shop previews the next one).
func preview(index: int) -> Dictionary:
	var result := {}
	if index < 0 or index >= total():
		return result
	for group in _level.waves[index]["groups"]:
		var entry: Dictionary = result.get_or_add(group["troop"], {"count": 0, "elite": false})
		entry["count"] += int(group["count"])
		entry["elite"] = entry["elite"] or group.get("elite", false)
	return result


func _process(delta: float) -> void:
	if not _running:
		return
	_clock += delta
	while not _events.is_empty() and _events[0]["time"] <= _clock:
		var event: Dictionary = _events.pop_front()
		spawn_requested.emit(event["troop"], event["elite"])
	if not _events.is_empty() or not battle.enemy_units.is_empty():
		return
	_running = false
	if is_last():
		all_cleared.emit()
	else:
		wave_cleared.emit(wave_index)
