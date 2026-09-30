extends Node

# Checks the master pin drive geometry with the real constants: through a whole pass the
# pin tip must stay in the middle of a tooth gap of the neighbour it drives, and its
# rounded tip must fit the gap with room to spare (so it never cuts into a tooth).
# Run: Godot --headless --path . res://tests/PinMeshTest.tscn

const GearBoard = preload("res://game/battle/GearBoard.gd")
const Gear = preload("res://game/battle/Gear.gd")
const Core = preload("res://game/battle/Core.gd")
# Tooth profile from CogDraw.draw_cog, as fractions of a pitch.
const GAP_CENTRE := 0.8
const GAP_AT_ROOT := 0.4
const GAP_AT_TIP := 0.76

var _failures := 0


func _ready() -> void:
	var board = GearBoard.new()
	var pitch := TAU / Gear.TEETH
	var reach: float = GearBoard.PIN_REACH
	var entry: float = GearBoard.PIN_ENTRY
	for dir in GearBoard.PUSH_DIRS:
		var gear_pos := Vector2(dir[0]) * GearBoard.CELL
		for i in 21:
			var offset := entry - i * (2.0 * entry / 20.0)
			var phase: float = board._rest_phase + GearBoard._pin_progress(offset) * pitch
			var tip := Vector2.from_angle(dir[1] + offset) * reach - gear_pos
			# All master neighbours share the even-cell angle (= phase).
			var at := fposmod(tip.angle() - phase, pitch) / pitch
			_check(absf(at - GAP_CENTRE) < 0.01, "dir %s offset %.2f: tip at %.3f of a pitch" % [dir[0], offset, at])
			var depth := clampf((tip.length() - Gear.INNER) / (Gear.OUTER - Gear.INNER), 0.0, 1.0)
			var gap_width := lerpf(GAP_AT_ROOT, GAP_AT_TIP, depth) * pitch * tip.length()
			_check(gap_width > 2.0 * Core.PIN_TIP + 2.0, "dir %s offset %.2f: gap %.1f px for tip %.1f px" % [dir[0], offset, gap_width, 2.0 * Core.PIN_TIP])
	board.free()
	_check_separate_trains()
	print("PinMeshTest: %d failures" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


# A gear above the master and one to its left touch only diagonally, so they are two
# trains: while the pin drives the upper one the left one must stand still, and the other
# way round. A gear joining the two makes one train that both passes turn.
func _check_separate_trains() -> void:
	var board = GearBoard.new()
	add_child(board)
	var troop: Resource = PlayerData.TROOPS["warrior"]
	var up = board.add_gear(troop, 1, GearBoard.MASTER_CELL + Vector2i(0, -1))
	var left = board.add_gear(troop, 1, GearBoard.MASTER_CELL + Vector2i(-1, 0))
	_check(up.chain != left.chain, "diagonal gears are separate trains")
	var moved_together := 0
	var moved_alone := 0
	for i in 400:
		var up_before: int = up.turns
		var left_before: int = left.turns
		var up_live: bool = board._driving.has(up.chain)
		var left_live: bool = board._driving.has(left.chain)
		board._advance_drive(0.02)
		if (up.turns != up_before or up_live) and (left.turns != left_before or left_live):
			moved_together += 1
		elif up.turns != up_before or left.turns != left_before:
			moved_alone += 1
	_check(moved_together == 0, "separate trains never turn at the same time (%d frames did)" % moved_together)
	_check(moved_alone > 0 and up.turns > 0 and left.turns > 0, "each train is driven on its own pass (up %d, left %d)" % [up.turns, left.turns])
	# Bridge them through the top-left corner cell: one train now.
	board.add_gear(troop, 1, GearBoard.MASTER_CELL + Vector2i(-1, -1))
	_check(up.chain == left.chain, "a gear touching both joins them into one train")
	_check(up.turns == left.turns, "joined train is in step (%d vs %d)" % [up.turns, left.turns])
	board.queue_free()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		print("FAIL " + what)
