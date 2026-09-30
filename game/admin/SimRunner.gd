extends Node

# Plays levels with the balance bot inside a hidden SubViewport at high speed. The real
# profile is snapshotted first and restored afterwards; the test profile never saves.

signal progress(done: int, total: int, last: Dictionary)
signal finished(results: Array)

const Bot = preload("res://game/admin/Bot.gd")
const Economy = preload("res://game/core/Economy.gd")
const BattleScene = preload("res://game/battle/Battle.tscn")
const RUN_TIMEOUT := 900.0

var running := false

var _viewport: SubViewport
var _battle
var _clock := 0.0
var _runs := 0
var _results: Array = []
var _snapshot := {}
var _saved_level := 0
var _saved_persist := true
var _level_index := 0


## `profile` is {"castle", "troop_level", "stars", "workshop": [...]} or {} to use the
## player's current profile.
func start(level_index: int, profile: Dictionary, runs: int, speed: float) -> void:
	if running:
		return
	running = true
	_results.clear()
	_runs = runs
	_level_index = level_index
	_snapshot = PlayerData.to_dict()
	_saved_level = PlayerData.current_level
	_saved_persist = PlayerData.persist
	PlayerData.persist = false
	if not profile.is_empty():
		PlayerData._reset()
		PlayerData.castle_level = clampi(profile["castle"], 1, PlayerData.castle_max_level())
		for id in PlayerData.TROOP_ORDER:
			PlayerData.troops[id] = {"unlocked": true, "level": profile["troop_level"], "stars": profile["stars"], "cards": 0}
		PlayerData.team = PlayerData.auto_team()
		var workshop: Array = profile.get("workshop", [0, 0, 0])
		for i in workshop.size():
			PlayerData.workshop[Economy.WORKSHOP_ORDER[i]] = workshop[i]
	PlayerData.unlocked_levels = PlayerData.LEVELS.size()
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(720, 1280)
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)
	Engine.time_scale = speed
	_next_run()


func cancel() -> void:
	if running:
		_finish()


func _next_run() -> void:
	if _results.size() >= _runs:
		_finish()
		return
	PlayerData.select_level(_level_index)
	_battle = BattleScene.instantiate()
	_viewport.add_child(_battle)
	_clock = 0.0


func _process(delta: float) -> void:
	if not running or _battle == null:
		return
	Bot.step(_battle)
	_clock += delta
	var phase: String = _battle.phase
	if phase == "won" or phase == "lost" or _clock > RUN_TIMEOUT:
		var result := {
			"won": phase == "won",
			"hp_ratio": _battle.core.hp / _battle.core.max_hp,
			"wave": _battle.waves.wave_index + 1,
			"waves": _battle.level.waves.size(),
			"time": _clock,
			"timeout": _clock > RUN_TIMEOUT,
		}
		_results.append(result)
		_battle.queue_free()
		_battle = null
		progress.emit(_results.size(), _runs, result)
		_next_run.call_deferred()


func _finish() -> void:
	if _battle != null:
		_battle.queue_free()
		_battle = null
	if _viewport != null:
		_viewport.queue_free()
		_viewport = null
	Engine.time_scale = 1.0
	PlayerData.from_dict(_snapshot)
	PlayerData.current_level = _saved_level
	PlayerData.persist = _saved_persist
	running = false
	PlayerData.changed.emit()
	finished.emit(_results.duplicate())
