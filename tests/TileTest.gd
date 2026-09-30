extends Node

# Checks the special board cells on real levels: rock blocks placement, ice gears don't
# mesh, rust gears pass the drive on without spawning, gold gears produce 1.5x.
# Run: Godot --headless --fixed-fps 60 --path . res://tests/TileTest.tscn

const RUN_SECONDS := 20.0

var _checks := 0
var _failed := 0
var _battle
var _stage := 0
var _time := 0.0
var _gold
var _plain
var _rust
var _after_rust


func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.castle_level = 10
	PlayerData.unlocked_levels = PlayerData.LEVELS.size()
	_check_rock_and_ice()


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		print("FAIL: ", what)


func _load(level: int):
	PlayerData.select_level(level - 1)
	var battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(battle)
	for gear in battle.board.gears.values().duplicate():
		battle.board.remove_gear(gear)
	return battle


func _check_rock_and_ice() -> void:
	# Level 11: rocks at (1,1) and (3,1), both beside the master.
	var battle = _load(11)
	var board = battle.board
	var warrior: Resource = PlayerData.TROOPS["warrior"]
	_check(not board.is_placeable(Vector2i(1, 1)), "rock cell is not placeable")
	_check(board.cell_at(board.cell_center(Vector2i(1, 1))) == board.NO_CELL, "can't drop on a rock")
	for i in 3:
		var gear = board.place_new(warrior)
		_check(board.tile(gear.cell) != "rock", "place_new skips rocks")
	battle.queue_free()

	# Level 15: ice at (2,0) and (2,2) beside the master.
	battle = _load(15)
	board = battle.board
	var on_ice = board.add_gear(warrior, 1, Vector2i(2, 0))
	var beyond = board.add_gear(warrior, 1, Vector2i(3, 0))
	_check(on_ice.powered, "ice gear beside the master turns")
	_check(not beyond.powered, "a gear touching only an ice gear doesn't turn")
	_check(on_ice.chain != beyond.chain, "ice gear isn't in its neighbour's train")
	_check(not board._would_turn(Vector2i(1, 0)) or board.tile(Vector2i(1, 0)) == "rock", "no glow next to an ice gear")
	battle.queue_free()

	# Level 14: rust at (1,1),(3,1),(2,2); gold at (0,1),(4,1). Build two trains:
	# master -> rust (3,1) -> gold (4,1), and master -> (2,0) -> (3,0) plain.
	_battle = _load(14)
	board = _battle.board
	_rust = board.add_gear(warrior, 1, Vector2i(3, 1))
	_after_rust = board.add_gear(warrior, 1, Vector2i(4, 1))
	_plain = board.add_gear(warrior, 1, Vector2i(2, 0))
	_check(_rust.powered and _after_rust.powered, "rust gear passes the drive on")
	_check(board.tile(_after_rust.cell) == "gold", "test layout: (4,1) is gold")
	_gold = _after_rust
	_battle.phase = "fight"
	_stage = 1


func _process(delta: float) -> void:
	if _stage != 1:
		return
	_time += delta
	# No enemies come; keep the gears' troops from capping out.
	for unit in _battle.player_units:
		if is_instance_valid(unit):
			unit.queue_free()
	_battle.player_units.clear()
	if _time < RUN_SECONDS:
		return
	_stage = 2
	var ratio: float = _gold.total_produced / maxf(_plain.total_produced, 0.001)
	print("  produced in %.0fs: plain %.1f, gold %.1f (x%.2f), rust %.1f" % [RUN_SECONDS, _plain.total_produced, _gold.total_produced, ratio, _rust.total_produced])
	_check(_plain.total_produced > 5.0, "plain gear produced")
	_check(absf(ratio - 1.5) < 0.2, "gold gear produces 1.5x (got %.2f)" % ratio)
	_check(_rust.total_produced == 0.0, "rust gear never produces")
	print("TileTest: %d checks, %d failed" % [_checks, _failed])
	get_tree().quit(1 if _failed > 0 else 0)
