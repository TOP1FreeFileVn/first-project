extends Node2D

# Static battlefield backdrop drawn once: grass tiles, the rubble wall between the field
# and the fortress, and scenery kept to the edges so it never hides units or gears.

const GRASS := Rect2(64, 64, 64, 64)
const SIZE := Vector2(720, 1280)
const TREES := [Vector2(18, 250), Vector2(704, 360), Vector2(14, 560), Vector2(708, 640)]
const BUSHES := [Vector2(40, 420), Vector2(690, 520), Vector2(120, 700), Vector2(600, 180)]


func _draw() -> void:
	var wall_y: float = get_parent().WALL_Y
	var grass := SpriteLib.texture("Terrain/Tileset/Tilemap_color1.png")
	for x in range(0, int(SIZE.x), 64):
		for y in range(0, int(SIZE.y), 64):
			draw_texture_rect_region(grass, Rect2(x, y, 64, 64), GRASS)
	# Darker ground below the wall marks the fortress.
	draw_rect(Rect2(0, wall_y, SIZE.x, SIZE.y - wall_y), Color(0.12, 0.2, 0.1, 0.25))

	for i in range(0, 22):
		var rock := SpriteLib.texture("Terrain/Decorations/Rocks/Rock%d.png" % (i % 4 + 1))
		_draw_centered(rock, Rect2(0, 0, 64, 64), Vector2(12 + i * 33.5, wall_y), 0.6)
	var tower := SpriteLib.texture("Buildings/Blue Buildings/Tower.png")
	_draw_centered(tower, Rect2(0, 0, 128, 256), Vector2(28, wall_y - 30), 0.4)
	_draw_centered(tower, Rect2(0, 0, 128, 256), Vector2(692, wall_y - 30), 0.4)

	var red_tower := SpriteLib.texture("Buildings/Red Buildings/Tower.png")
	_draw_centered(red_tower, Rect2(0, 0, 128, 256), Vector2(60, 150), 0.4)
	_draw_centered(red_tower, Rect2(0, 0, 128, 256), Vector2(660, 150), 0.4)

	var tree := SpriteLib.texture("Terrain/Resources/Wood/Trees/Tree1.png")
	for spot in TREES:
		_draw_centered(tree, Rect2(0, 0, 256, 256), spot, 0.45)
	var bush := SpriteLib.texture("Terrain/Decorations/Bushes/Bushe1.png")
	for spot in BUSHES:
		_draw_centered(bush, Rect2(0, 0, 128, 128), spot, 0.45)


func _draw_centered(texture: Texture2D, region: Rect2, center: Vector2, scale_factor: float) -> void:
	var size := region.size * scale_factor
	draw_texture_rect_region(texture, Rect2(center - size / 2.0, size), region)
