extends RefCounted

## Approved round drive. Only the cat foreground is phase-cached; the output arm
## and rear rotor use the exact pin angle every draw, including loaded slowdowns.
const ROTOR := preload("res://game/assets/battle/cat-drive/rear_disc.svg")
const CAT := preload("res://game/assets/battle/cat-drive/cat_poses.png")
const LINE := Color("583f21")
const METAL := Color("91aaae")
const FRAME_COUNT := 96
const FRAME_SIZE := 128.0
const COLUMNS := 12
const PADDING := 2.0
const STRIDE := FRAME_SIZE + 2.0 * PADDING


static func pose_index(angle: float) -> int:
	return floori(fposmod(angle, TAU) * FRAME_COUNT / TAU + 0.5) % FRAME_COUNT


static func draw_drive(ci: CanvasItem, angle: float, reach: float, tip_half_width: float) -> void:
	# SVG and live triangle share the original 100px-cell coordinates. The visual
	# tip is one blunt edge; the physical pin centre/radius stay with GearBoard.
	ci.draw_set_transform(Vector2.ZERO, angle)
	ci.draw_texture_rect(ROTOR, Rect2(-64, -64, 128, 128), false)
	var arm := PackedVector2Array([Vector2(15, -15), Vector2(reach, -tip_half_width), Vector2(reach, tip_half_width), Vector2(15, 15)])
	ci.draw_colored_polygon(arm, METAL)
	var outline := arm.duplicate()
	outline.append(arm[0])
	ci.draw_polyline(outline, LINE, 3.0, true)
	# Round joins belong to the single contour, with no separate pin marker.
	for corner in arm:
		ci.draw_circle(corner, 1.5, LINE, true, -1.0, true)
	ci.draw_set_transform(Vector2.ZERO)
	var frame := pose_index(angle)
	var origin := Vector2((frame % COLUMNS) * STRIDE + PADDING, floori(float(frame) / COLUMNS) * STRIDE + PADDING)
	ci.draw_texture_rect_region(CAT, Rect2(-64, -64, FRAME_SIZE, FRAME_SIZE), Rect2(origin, Vector2(FRAME_SIZE, FRAME_SIZE)))
