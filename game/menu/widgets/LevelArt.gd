extends Control

# The picture of one level on the level select: a Tiny Swords island on water, dressed
# per level (trees, sheep, rocks, the enemy's buildings) with that level's enemies idling
# in front and clouds drifting over. Locked levels are dimmed (the page draws the lock).

const TILE := 32.0
const TILESET := "Terrain/Tileset/Tilemap_color%d.png"
const WATER := "Terrain/Tileset/Water Background color.png"
const TREE := "Terrain/Resources/Wood/Trees/Tree%d.png"
const BUSH := "Terrain/Decorations/Bushes/Bushe%d.png"
const SHEEP := "Terrain/Resources/Meat/Sheep/Sheep_Idle.png"
const WATER_ROCK := "Terrain/Decorations/Rocks in the Water/Water Rocks_0%d.png"
const CLOUD := "Terrain/Decorations/Clouds/Clouds_0%d.png"

# Per level: grass colour (tileset 1-5), island in tiles [left, top, right, bottom], a
# tint for the whole scene, and props [kind, x, y] placed in the 560x440 card.
const THEMES := [
	# 1 Đồng Cỏ: open meadow, sheep, a couple of red houses.
	{"tiles": 1, "island": [1, 2, 16, 13], "tint": Color(1, 1, 1), "props": [
		["tree1", 80, 150], ["tree2", 470, 140], ["bush1", 150, 330], ["bush2", 420, 350],
		["sheep", 230, 300], ["sheep", 300, 330], ["house_red1", 380, 190], ["house_red2", 450, 230], ["rock1", 110, 380]]},
	# 2 Đồi Đá: rocky hill with gold.
	{"tiles": 2, "island": [1, 2, 16, 13], "tint": Color(1, 0.98, 0.94), "props": [
		["gold1", 120, 200], ["gold3", 170, 230], ["rock2", 250, 170], ["rock3", 90, 330], ["rock1", 460, 360],
		["tree3", 480, 150], ["tower_red", 400, 200], ["bush3", 320, 360], ["water_rock1", 20, 90]]},
	# 3 Pháo Đài Đỏ: the red castle.
	{"tiles": 3, "island": [1, 2, 16, 13], "tint": Color(1, 0.96, 0.94), "props": [
		["castle_red", 330, 200], ["tower_red", 190, 190], ["tower_red", 470, 190], ["tree1", 70, 170],
		["bush1", 110, 360], ["rock2", 460, 380]]},
	# 4 Rừng Thông: a forest.
	{"tiles": 3, "island": [1, 2, 16, 13], "tint": Color(0.92, 1, 0.92), "props": [
		["tree1", 70, 140], ["tree2", 140, 120], ["tree3", 210, 150], ["tree4", 400, 130], ["tree1", 470, 150],
		["tree2", 90, 260], ["tree4", 490, 280], ["tree3", 430, 360], ["tree1", 110, 380], ["house_red3", 300, 180], ["bush4", 250, 370]]},
	# 5 Hẻm Núi: narrow pass between rock piles.
	{"tiles": 2, "island": [3, 2, 14, 13], "tint": Color(0.97, 0.95, 0.9), "props": [
		["rock3", 120, 160], ["rock2", 110, 250], ["rock4", 130, 340], ["rock1", 440, 170], ["rock3", 450, 260], ["rock2", 440, 350],
		["tower_red", 290, 180], ["water_rock2", 40, 380], ["water_rock3", 520, 120]]},
	# 6 Làng Bỏ Hoang: dry grass, stumps, empty houses.
	{"tiles": 4, "island": [1, 2, 16, 13], "tint": Color(1, 0.94, 0.86), "props": [
		["house_red1", 140, 190], ["house_red2", 230, 170], ["house_red3", 420, 190], ["stump1", 320, 300], ["stump2", 110, 330],
		["stump3", 470, 340], ["bush2", 380, 380], ["rock1", 250, 380]]},
	# 7 Đầm Lầy: murky ground with ponds.
	{"tiles": 4, "island": [1, 2, 16, 13], "tint": Color(0.86, 0.95, 0.86), "props": [
		["pond", 130, 330], ["pond", 440, 280], ["water_rock1", 110, 320], ["water_rock4", 450, 270], ["duck", 150, 340],
		["tree3", 80, 160], ["tree4", 490, 160], ["bush1", 280, 380], ["tower_red", 300, 170]]},
	# 8 Thành Đá Đen: the black castle at dusk.
	{"tiles": 5, "island": [1, 2, 16, 13], "tint": Color(0.82, 0.84, 0.95), "props": [
		["castle_black", 300, 200], ["tower_black", 160, 190], ["tower_black", 450, 190], ["rock3", 90, 360], ["rock2", 480, 370], ["tree4", 70, 170]]},
	# 9 Cổng Pháo Đài: the fortress gate.
	{"tiles": 5, "island": [1, 2, 16, 13], "tint": Color(0.86, 0.84, 0.92), "props": [
		["barracks_black", 290, 190], ["tower_black", 170, 180], ["tower_black", 420, 180], ["archery_black", 480, 250],
		["rock1", 100, 370], ["gold2", 110, 250]]},
	# 10 Vua Đỏ: the red king's castle under a red sky.
	{"tiles": 1, "island": [1, 2, 16, 13], "tint": Color(1, 0.84, 0.8), "props": [
		["castle_red", 290, 190], ["tower_red", 150, 180], ["tower_red", 440, 180], ["barracks_red", 470, 260],
		["tree2", 70, 160], ["rock3", 110, 380]]},
	# 11 Bến Cảng: a harbour, rocks in the water, a duck.
	{"tiles": 1, "island": [2, 2, 15, 13], "tint": Color(0.95, 1, 1.05), "props": [
		["house_red1", 170, 180], ["house_red2", 250, 160], ["tower_red", 420, 180], ["water_rock1", 30, 120], ["water_rock2", 520, 150],
		["water_rock3", 40, 360], ["water_rock4", 525, 380], ["duck", 510, 300], ["bush2", 330, 380], ["tree1", 110, 240]]},
	# 12 Rừng Sương: a misty forest.
	{"tiles": 3, "island": [1, 2, 16, 13], "tint": Color(0.8, 0.88, 0.96), "props": [
		["tree4", 70, 140], ["tree3", 150, 120], ["tree4", 230, 140], ["tree3", 390, 120], ["tree4", 470, 140], ["tree3", 80, 260],
		["tree4", 480, 270], ["tree3", 120, 380], ["tree4", 440, 380], ["house_black1", 300, 170]]},
	# 13 Đồi Cừu: sheep on a green hill.
	{"tiles": 1, "island": [1, 2, 16, 13], "tint": Color(1, 1, 0.95), "props": [
		["sheep", 150, 250], ["sheep", 230, 230], ["sheep", 400, 250], ["sheep", 470, 300], ["sheep", 120, 370],
		["house_red3", 300, 170], ["bush1", 80, 170], ["bush3", 480, 160], ["tree2", 520, 380]]},
	# 14 Mỏ Vàng: the gold mine.
	{"tiles": 2, "island": [1, 2, 16, 13], "tint": Color(1, 0.96, 0.88), "props": [
		["gold1", 110, 190], ["gold2", 170, 230], ["gold3", 420, 200], ["gold1", 480, 240], ["gold2", 90, 360],
		["rock2", 250, 160], ["rock3", 470, 370], ["tower_red", 330, 190], ["stump1", 230, 380]]},
	# 15 Cầu Đá: a narrow stone bridge between rock piles.
	{"tiles": 2, "island": [4, 2, 13, 13], "tint": Color(0.92, 0.92, 0.98), "props": [
		["rock3", 170, 150], ["rock2", 160, 260], ["rock4", 170, 370], ["rock3", 400, 150], ["rock1", 410, 260], ["rock2", 400, 370],
		["tower_black", 290, 170], ["water_rock1", 40, 200], ["water_rock2", 520, 260], ["water_rock3", 60, 380]]},
]
# Where the level's enemies stand (card coordinates), front to back.
const ENEMY_SPOTS := [Vector2(190, 330), Vector2(270, 345), Vector2(350, 330), Vector2(430, 340)]
const BOSS_SPOT := Vector2(300, 285)

var level_index := 0
var locked := false
var enemy_ids: Array = []

var _theme: Dictionary
var _props: Node2D
var _clouds: Array = []


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_theme = THEMES[clampi(level_index, 0, THEMES.size() - 1)]
	_props = Node2D.new()
	_props.y_sort_enabled = true
	add_child(_props)
	for prop in _theme["props"]:
		_add_prop(prop[0], Vector2(prop[1], prop[2]))
	_add_enemies()
	for i in 2:
		_add_cloud(i)
	modulate = _theme["tint"] * (Color(0.35, 0.35, 0.4) if locked else Color.WHITE)


func _process(delta: float) -> void:
	for cloud in _clouds:
		cloud.position.x += delta * cloud.get_meta("speed")
		if cloud.position.x > size.x + 160:
			cloud.position.x = -160


func _draw() -> void:
	var water := SpriteLib.texture(WATER)
	draw_texture_rect(water, Rect2(Vector2.ZERO, size), true)
	var tiles := SpriteLib.texture(TILESET % _theme["tiles"])
	var island: Array = _theme["island"]
	# Only the island's size in tiles matters; it is always centred on the card.
	var origin := (size - Vector2(island[2] - island[0] + 1, island[3] - island[1] + 1) * TILE) / 2.0
	for row in range(island[1], island[3] + 1):
		for col in range(island[0], island[2] + 1):
			var src_col := 0 if col == island[0] else (2 if col == island[2] else 1)
			var src_row := 0 if row == island[1] else (2 if row == island[3] else 1)
			var at := origin + Vector2(col - island[0], row - island[1]) * TILE
			draw_texture_rect_region(tiles, Rect2(at, Vector2(TILE, TILE)), Rect2(src_col * 64, src_row * 64, 64, 64))
	for prop in _theme["props"]:
		if prop[0] == "pond":
			var center := Vector2(prop[1], prop[2])
			draw_set_transform(center, 0.0, Vector2(1.0, 0.5))
			draw_circle(Vector2.ZERO, 58.0, Color("2f6f7a"))
			draw_circle(Vector2.ZERO, 52.0, Color("4a9aa6"))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _add_prop(kind: String, at: Vector2) -> void:
	if kind == "pond":
		return
	var node: Node2D
	if kind.begins_with("tree"):
		node = _anim(TREE % int(kind.substr(4)), 0.5, 6.0, -48, 192)
	elif kind.begins_with("bush"):
		node = _anim(BUSH % int(kind.substr(4)), 0.5, 8.0, -18)
	elif kind == "sheep":
		node = _anim(SHEEP, 0.55, 8.0, -14)
	elif kind == "duck":
		node = _anim("Terrain/Decorations/Rubber Duck/Rubber duck.png", 0.9, 4.0, -4)
	elif kind.begins_with("water_rock"):
		node = _anim(WATER_ROCK % int(kind.substr(10)), 0.6, 8.0, 0)
	else:
		node = _still(_still_path(kind), 0.5)
	node.position = at
	_props.add_child(node)


func _still_path(kind: String) -> String:
	if kind.begins_with("rock"):
		return "Terrain/Decorations/Rocks/Rock%d.png" % int(kind.substr(4))
	if kind.begins_with("gold"):
		return "Terrain/Resources/Gold/Gold Stones/Gold Stone %d.png" % int(kind.substr(4))
	if kind.begins_with("stump"):
		return "Terrain/Resources/Wood/Trees/Stump %d.png" % int(kind.substr(5))
	# Buildings: "<building>_<colour>[n]", e.g. castle_red, house_red2, tower_black.
	var parts := kind.split("_")
	var colour := "Red" if parts[1].begins_with("red") else "Black"
	var building := parts[0].capitalize()
	if building == "House":
		building += parts[1].right(1) if parts[1].right(1).is_valid_int() else "1"
	return "Buildings/%s Buildings/%s.png" % [colour, building]


func _anim(path: String, scale_by: float, fps: float, lift: float, frame_width := 0) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.strip_frames(path, fps, frame_width)
	sprite.scale = Vector2(scale_by, scale_by)
	sprite.offset = Vector2(0, lift / scale_by)
	sprite.frame = randi() % sprite.sprite_frames.get_frame_count("default")
	sprite.play("default")
	return sprite


# Buildings and stones: anchored at their base so y-sorting reads right.
func _still(path: String, scale_by: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = SpriteLib.texture(path)
	sprite.scale = Vector2(scale_by, scale_by)
	sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.42)
	return sprite


func _add_enemies() -> void:
	var boss := ""
	var regular := []
	for id in enemy_ids:
		if PlayerData.TROOPS[id].rarity >= 3:
			boss = id
		else:
			regular.append(id)
	for i in mini(regular.size(), ENEMY_SPOTS.size()):
		_add_unit(regular[regular.size() - 1 - i], ENEMY_SPOTS[i], false)
	if boss != "":
		_add_unit(boss, BOSS_SPOT, true)


func _add_unit(id: String, at: Vector2, boss: bool) -> void:
	var troop: Resource = PlayerData.TROOPS[id]
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.unit_frames(troop.unit_key, "Black" if boss else "Red")
	sprite.offset = Vector2(0, -SpriteLib.foot_offset(troop.unit_key))
	var s: float = 0.5 * troop.sprite_scale * (1.5 if boss else 1.0)
	sprite.scale = Vector2(s, s)
	sprite.modulate = troop.tint
	sprite.flip_h = at.x > size.x / 2.0 if size.x > 0.0 else false
	sprite.position = at
	sprite.frame = randi() % 4
	sprite.play("idle")
	_props.add_child(sprite)


func _add_cloud(i: int) -> void:
	var cloud := Sprite2D.new()
	cloud.texture = SpriteLib.texture(CLOUD % (1 + (level_index + i * 3) % 8))
	cloud.scale = Vector2(0.45, 0.45)
	cloud.modulate = Color(1, 1, 1, 0.75)
	cloud.position = Vector2(80 + i * 300 + level_index * 37 % 120, 40 + i * 26)
	cloud.set_meta("speed", 8.0 + i * 5.0)
	add_child(cloud)
	_clouds.append(cloud)
