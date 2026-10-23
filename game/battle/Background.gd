extends Node2D

# Regional ground stays separate from the castle, actors and gear table.
# Levels without regional art keep the original woodland field and edge props.
const SIZE := Vector2(720, 1280)
const FIELD_RECT := Rect2(0, 0, 720, 740)
const FIELD := preload("res://game/ui/skin/battle_map_field.svg")
const TREE := preload("res://game/ui/skin/battle_map_tree.svg")
const PINE := preload("res://game/ui/skin/battle_map_pine.svg")
const BUSH := preload("res://game/ui/skin/battle_map_bush.svg")
const ROCK := preload("res://game/ui/skin/battle_map_rock.svg")
const CastleTiers := preload("res://game/menu/lobby/CastleTiers.gd")
# The castle's look follows its upgrade tier (two castle levels each), like the lobby.
# Art: docs/design/2026-10-23/battle-flat-gate (shared gate, baseline and footprint).
const CASTLE_DIR := "res://game/assets/battle/cardboard-castle/"
const CASTLE_REARS := [
	preload(CASTLE_DIR + "tier-1-rear.svg"), preload(CASTLE_DIR + "tier-2-rear.svg"), preload(CASTLE_DIR + "tier-3-rear.svg"),
	preload(CASTLE_DIR + "tier-4-rear.svg"), preload(CASTLE_DIR + "tier-5-rear.svg"),
]
const CASTLE_FACADES := [
	preload(CASTLE_DIR + "tier-1-facade.svg"), preload(CASTLE_DIR + "tier-2-facade.svg"), preload(CASTLE_DIR + "tier-3-facade.svg"),
	preload(CASTLE_DIR + "tier-4-facade.svg"), preload(CASTLE_DIR + "tier-5-facade.svg"),
]
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
var _castle_rear: Texture2D
var _castle_facade: Texture2D
var _regional_field: Texture2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_core = get_parent().get_node("Core")
	var tier := CastleTiers.tier_for(PlayerData.castle_level)
	_castle_rear = CASTLE_REARS[tier - 1]
	_castle_facade = CASTLE_FACADES[tier - 1]
	_castle_front = Node2D.new()
	_castle_front.name = "CastleForeground"
	_castle_front.z_index = 2
	_castle_front.draw.connect(_draw_castle_front)
	add_child(_castle_front)
	_add_flags(tier)


func setup(level: Resource) -> void:
	# Battle assigns its level after child _ready methods have finished.
	_regional_field = level.battlefield
	queue_redraw()


func _process(_delta: float) -> void:
	# Share the core's existing brief damage flash without another HP/timer system.
	if is_instance_valid(_core) and _castle_tint != _core.modulate:
		_castle_tint = _core.modulate
		queue_redraw()
		_castle_front.queue_redraw()


func _draw() -> void:
	draw_texture_rect(FIELD, Rect2(Vector2.ZERO, SIZE), false)
	if _regional_field != null:
		draw_texture_rect(_regional_field, FIELD_RECT, false)
	else:
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
	draw_texture_rect(_castle_rear, Rect2(origin, CASTLE_SIZE), false, _castle_tint)


func _draw_castle_front() -> void:
	var origin := Vector2(0, get_parent().WALL_Y - CASTLE_WALL_OFFSET)
	_castle_front.draw_texture_rect(_castle_facade, Rect2(origin, CASTLE_SIZE), false, _castle_tint)

# Waving flag cloths on the tier's poles. Battlemented tiers' tower flags stand behind
# units like their poles; the keep flag and roof flags ride above the wall.
func _add_flags(tier: int) -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(CASTLE_DIR + "tiers.json"))
	if not data is Dictionary:
		return
	var origin := Vector2(0, get_parent().WALL_Y - CASTLE_WALL_OFFSET)
	var i := 0
	for a in data["tiers"].get(str(tier), []):
		var flag: Node2D = CastleTiers.make_flag(Vector2(a["x"], a["y"]), bool(a["big"]), i, float(data["flag_pad"]))
		flag.position += origin
		var behind: bool = tier < 3 and not bool(a["big"])
		(self if behind else _castle_front).add_child(flag)
		i += 1
