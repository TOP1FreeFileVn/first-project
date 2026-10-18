extends Node

# Checks the master pin drive geometry with the real constants: through a whole pass the
# pin tip must stay in the middle of a tooth gap of the neighbour it drives, and its
# rounded tip must fit the gap with room to spare (so it never cuts into a tooth).
# Run: Godot --headless --path . res://tests/PinMeshTest.tscn

const GearBoard = preload("res://game/battle/GearBoard.gd")
const Gear = preload("res://game/battle/Gear.gd")
const Core = preload("res://game/battle/Core.gd")
const CogDraw = preload("res://game/battle/CogDraw.gd")
const COG_SOURCE := "res://game/ui/skin/battle_cog_tier_1.svg"
const CURVE_STEPS := 8
const GAP_CENTRE := 0.8

var _failures := 0


func _ready() -> void:
	# Read the production SVG, rather than checking an ideal wedge that can miss the
	# bottom of a notch, a wide shoulder, or the painted outline.
	var shape := _read_contour()
	if not shape.is_empty():
		_check_drawn_clearance(shape)
	_check_separate_trains()
	print("PinMeshTest: %d failures" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _read_contour() -> Dictionary:
	var source := FileAccess.get_file_as_string(COG_SOURCE)
	var path_re := RegEx.new()
	path_re.compile('<path\\s+d="([^"]+)"[^>]*stroke-width="([0-9.]+)"')
	var path_match := path_re.search(source)
	_check(path_match != null, "production SVG has a stroked outer contour")
	if path_match == null:
		return {}
	var token_re := RegEx.new()
	token_re.compile('[A-Za-z]|[-+]?[0-9]+(?:\\.[0-9]+)?(?:[eE][-+]?[0-9]+)?')
	var tokens: Array[String] = []
	for token in token_re.search_all(path_match.get_string(1)):
		tokens.append(token.get_string())
	var points := PackedVector2Array()
	var cursor := 0
	var at := Vector2.ZERO
	var curve_error := 0.0
	var scale := Gear.OUTER / CogDraw.COG_DESIGN_OUTER
	while cursor < tokens.size():
		var command := tokens[cursor]
		cursor += 1
		if command == "M" or command == "L":
			at = Vector2(float(tokens[cursor]), float(tokens[cursor + 1]))
			cursor += 2
			points.append((at - Vector2(64, 64)) * scale)
		elif command == "Q":
			var control := Vector2(float(tokens[cursor]), float(tokens[cursor + 1]))
			var end := Vector2(float(tokens[cursor + 2]), float(tokens[cursor + 3]))
			cursor += 4
			# Maximum distance between a quadratic and its sampled chords.
			curve_error = maxf(curve_error, (at - 2.0 * control + end).length() * scale / (4.0 * CURVE_STEPS * CURVE_STEPS))
			for step in range(1, CURVE_STEPS + 1):
				var t := float(step) / CURVE_STEPS
				var point := at * (1.0 - t) * (1.0 - t) + 2.0 * control * t * (1.0 - t) + end * t * t
				points.append((point - Vector2(64, 64)) * scale)
			at = end
		elif command != "Z":
			_check(false, "unsupported production contour command: " + command)
			return {}
	return {"points": points, "ink": float(path_match.get_string(2)) * scale, "error": curve_error}


func _check_drawn_clearance(shape: Dictionary) -> void:
	var board = GearBoard.new()
	var pitch := TAU / Gear.TEETH
	var reach: float = GearBoard.PIN_REACH
	var entry: float = GearBoard.PIN_ENTRY
	var points: PackedVector2Array = shape["points"]
	var pin_ink: float = Core.PIN_TIP + CogDraw.PIN_INK_OUTSET
	var minimum_pin_gap := INF
	_check(Gear.TEETH % 4 == 0, "four master neighbours share the same gap phase")
	for dir in GearBoard.PUSH_DIRS:
		var gear_pos := Vector2(dir[0]) * GearBoard.CELL
		for i in 81:
			var offset := entry - i * (2.0 * entry / 80.0)
			var phase: float = board._rest_phase + GearBoard._pin_progress(offset) * pitch
			var tip := Vector2.from_angle(dir[1] + offset) * reach - gear_pos
			# All master neighbours share the even-cell angle (= phase).
			var at := fposmod(tip.angle() - phase, pitch) / pitch
			_check(absf(at - GAP_CENTRE) < 0.01, "dir %s offset %.2f: tip at %.3f of a pitch" % [dir[0], offset, at])
			var local_tip := tip.rotated(-phase)
			_check(not Geometry2D.is_point_in_polygon(local_tip, points), "pin centre stays outside the cog fill")
			var distance := INF
			for edge in points.size():
				distance = minf(distance, local_tip.distance_to(Geometry2D.get_closest_point_to_segment(local_tip, points[edge - 1], points[edge])))
			var gap: float = distance - pin_ink - shape["ink"] * 0.5 - shape["error"]
			minimum_pin_gap = minf(minimum_pin_gap, gap)
	_check(minimum_pin_gap >= 1.5, "rounded SVG leaves pin ink 1.5px clearance (%.3fpx)" % minimum_pin_gap)
	# Sample a complete tooth cycle with the real opposite-parity phase. Test edge
	# intersections as well as distance, so broad tabs cannot pass through each other.
	var minimum_neighbour_gap := INF
	for step in 121:
		var phase := pitch * step / 120.0
		var left := _rotate_contour(points, board.gear_angle(Vector2i(0, 0), phase))
		var right := _rotate_contour(points, board.gear_angle(Vector2i(1, 0), phase), Vector2(GearBoard.CELL, 0))
		var distance := _contour_distance(left, right)
		minimum_neighbour_gap = minf(minimum_neighbour_gap, distance - shape["ink"] - shape["error"] * 2.0)
	_check(minimum_neighbour_gap >= 0.5, "adjacent SVG outlines stay separated through a tooth cycle (%.3fpx)" % minimum_neighbour_gap)
	print("PinMeshTest painted clearance: pin=%.3fpx neighbours=%.3fpx" % [minimum_pin_gap, minimum_neighbour_gap])
	board.free()


func _rotate_contour(points: PackedVector2Array, angle: float, shift := Vector2.ZERO) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point.rotated(angle) + shift)
	return result


func _contour_distance(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var minimum := INF
	for i in a.size():
		# Edges outside this contact strip are more than 10px from the other wheel.
		if maxf(a[i - 1].x, a[i].x) < GearBoard.CELL * 0.5 - 15.0:
			continue
		for j in b.size():
			if minf(b[j - 1].x, b[j].x) > GearBoard.CELL * 0.5 + 15.0:
				continue
			if Geometry2D.segment_intersects_segment(a[i - 1], a[i], b[j - 1], b[j]) != null:
				return 0.0
			minimum = minf(minimum, a[i - 1].distance_to(Geometry2D.get_closest_point_to_segment(a[i - 1], b[j - 1], b[j])))
			minimum = minf(minimum, a[i].distance_to(Geometry2D.get_closest_point_to_segment(a[i], b[j - 1], b[j])))
			minimum = minf(minimum, b[j - 1].distance_to(Geometry2D.get_closest_point_to_segment(b[j - 1], a[i - 1], a[i])))
			minimum = minf(minimum, b[j].distance_to(Geometry2D.get_closest_point_to_segment(b[j], a[i - 1], a[i])))
	return minimum


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
