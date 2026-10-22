extends Node2D

# Flat, original woodland art shares the cats' rounded brown line. Keep the
# middle quiet for units and the lower warm board clear for gear interactions.
const SIZE := Vector2(720, 1280)
const FIELD := preload("res://game/ui/skin/battle_map_field.svg")
const TREE := preload("res://game/ui/skin/battle_map_tree.svg")
const PINE := preload("res://game/ui/skin/battle_map_pine.svg")
const BUSH := preload("res://game/ui/skin/battle_map_bush.svg")
const ROCK := preload("res://game/ui/skin/battle_map_rock.svg")
const CASTLE_REAR := preload("res://game/assets/battle/cardboard-castle/rear.svg")
const CASTLE_FACADE := preload("res://game/assets/battle/cardboard-castle/facade.svg")
const GEAR_TABLE := preload("res://game/assets/battle/cardboard-board/board.svg")
const CASTLE_SIZE := Vector2(720, 240)
## Lift the flat facade 4px so its base shares the gear tray's top line.
const CASTLE_WALL_OFFSET := 184.0
# The entire opaque facade occludes units, including the upper gate and towers.
# The cat-shaped aperture stays transparent so units remain visible through it.
const GEAR_TABLE_RECT := Rect2(0, 720, 720, 480)

const TREES := [
	Rect2(-59, 182, 128, 176), Rect2(662, 133, 128, 176),
	Rect2(-70, 458, 128, 176), Rect2(667, 470, 128, 176),
]
const PINES := [Rect2(-74, 20, 128, 190), Rect2(673, 304, 128, 190)]
const BUSHES := [
	Rect2(-13, 334, 88, 56), Rect2(652, 277, 88, 56),
	Rect2(-18, 626, 88, 56), Rect2(656, 620, 88, 56),
]
const ROCKS := [Rect2(38, 419, 48, 36), Rect2(645, 386, 48, 36)]

var _core: Node2D
var _castle_tint := Color.WHITE
var _castle_front: Node2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_core = get_parent().get_node("Core")
	_castle_front = Node2D.new()
	_castle_front.name = "CastleForeground"
	_castle_front.z_index = 2
	_castle_front.draw.connect(_draw_castle_front)
	add_child(_castle_front)


func _process(_delta: float) -> void:
	# Share the core's existing brief damage flash without another HP/timer system.
	if is_instance_valid(_core) and _castle_tint != _core.modulate:
		_castle_tint = _core.modulate
		queue_redraw()
		_castle_front.queue_redraw()


func _draw() -> void:
	draw_texture_rect(FIELD, Rect2(Vector2.ZERO, SIZE), false)
	for area: Rect2 in PINES:
		draw_texture_rect(PINE, area, false)
	for area: Rect2 in TREES:
		draw_texture_rect(TREE, area, false)
	for area: Rect2 in ROCKS:
		draw_texture_rect(ROCK, area, false)
	for area: Rect2 in BUSHES:
		draw_texture_rect(BUSH, area, false)
	draw_texture_rect(GEAR_TABLE, GEAR_TABLE_RECT, false)

	var wall_y: float = get_parent().WALL_Y
	var origin := Vector2(0, wall_y - CASTLE_WALL_OFFSET)
	draw_texture_rect(CASTLE_REAR, Rect2(origin, CASTLE_SIZE), false, _castle_tint)


func _draw_castle_front() -> void:
	var origin := Vector2(0, get_parent().WALL_Y - CASTLE_WALL_OFFSET)
	_castle_front.draw_texture_rect(CASTLE_FACADE, Rect2(origin, CASTLE_SIZE), false, _castle_tint)
