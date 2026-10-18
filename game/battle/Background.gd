extends Node2D

# Flat, original woodland art shares the cats' rounded brown line. Keep the
# middle quiet for units and the lower warm board clear for gear interactions.
const SIZE := Vector2(720, 1280)
const FIELD := preload("res://game/ui/skin/battle_map_field.svg")
const TREE := preload("res://game/ui/skin/battle_map_tree.svg")
const PINE := preload("res://game/ui/skin/battle_map_pine.svg")
const BUSH := preload("res://game/ui/skin/battle_map_bush.svg")
const ROCK := preload("res://game/ui/skin/battle_map_rock.svg")
const CASTLE_WALL := preload("res://game/ui/skin/battle_castle_wall.svg")

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


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


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

	var wall_y: float = get_parent().WALL_Y
	# The castle art's top walk is 76 px down the SVG. Its walk therefore stays
	# on the existing battle line at y=700; collision and deployment are unchanged.
	draw_texture_rect(CASTLE_WALL, Rect2(0, wall_y - 76.0, SIZE.x, 152), false)
