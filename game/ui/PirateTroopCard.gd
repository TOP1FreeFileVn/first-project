extends Control

## The accepted pirate ship is split around the cat: rear rigging/sails,
## portrait, then the original near hull/rail. All artwork ignores input.
const Economy = preload("res://game/core/Economy.gd")
const REAR = preload("res://game/ui/art/pirate_ship_rear.svg")
const FRONT = preload("res://game/ui/art/pirate_ship_front.svg")
const CANVAS := Vector2(160, 150)
const SHIP_RECT := Rect2(2, 4, 156, 136.5)
const INK := Color("583f21")
const SKY := Color("c9eae2")
const SEA := Color("7bc9c6")

var troop_id := ""
var front_only := false
var rarity := 0
var unlocked := true
var fighting := false
var _pressed := false


func _init() -> void:
	name = "PirateTroopCard"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)


func _process(_delta: float) -> void:
	var button := get_parent() as BaseButton
	var pressed := button != null and button.is_pressed()
	if pressed != _pressed:
		_pressed = pressed
		self_modulate = Color(0.91, 0.91, 0.91) if pressed else Color.WHITE


func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	draw_set_transform(Vector2.ZERO, 0, size / CANVAS)
	var art_tint := Color.WHITE if unlocked else Color(0.75, 0.73, 0.70)
	if front_only:
		draw_texture_rect(FRONT, SHIP_RECT, false, art_tint)
		return
	var rim: Color = Economy.RARITY_COLORS[clampi(rarity, 0, 3)]
	if not unlocked:
		rim = rim.lerp(Color("b6ada0"), 0.35)
	draw_style_box(_face(rim, 12), Rect2(2, 2, 156, 146))
	var top := _face(rim.lightened(0.18), 10)
	top.corner_radius_bottom_left = 0
	top.corner_radius_bottom_right = 0
	draw_style_box(top, Rect2(4, 4, 152, 20))
	draw_style_box(_face(SKY if unlocked else SKY.lerp(Color("ccc7ba"), 0.45), 5), Rect2(13, 13, 134, 124))
	var sea := _face(SEA if unlocked else SEA.lerp(Color("b7b4a8"), 0.45), 5)
	sea.corner_radius_top_left = 0
	sea.corner_radius_top_right = 0
	draw_style_box(sea, Rect2(13, 60, 134, 77))
	_cloud(Vector2(124, 38))
	draw_texture_rect(REAR, SHIP_RECT, false, art_tint)
	# Pixel-fitted to the current 60px portrait. The front hull occludes
	# contact at the near rail; no platform or ring is placed under the cat.
	if unlocked:
		if troop_id == "dai_bac":
			_contact(Vector2(70, 99), 23)
		else:
			_contact(Vector2(59, 98.5), 13)
			_contact(Vector2(82, 98.5), 13)
	var inside := _face(Color.TRANSPARENT, 5)
	inside.draw_center = false
	inside.border_color = INK
	inside.set_border_width_all(2)
	draw_style_box(inside, Rect2(13, 13, 134, 124))
	var outside := _face(Color.TRANSPARENT, 12)
	outside.draw_center = false
	outside.border_color = INK
	outside.set_border_width_all(4)
	draw_style_box(outside, Rect2(2, 2, 156, 146))


func _cloud(at: Vector2) -> void:
	var color := Color("e5f3e7")
	if not unlocked:
		color = color.lerp(Color("ccc7ba"), 0.45)
	draw_circle(at + Vector2(-7, 1), 4, color)
	draw_circle(at + Vector2(0, -2), 6, color)
	draw_circle(at + Vector2(7, 1), 4, color)
	draw_rect(Rect2(at + Vector2(-7, 0), Vector2(14, 5)), color)


func _contact(at: Vector2, width: float) -> void:
	var half := width * 0.5
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-half, -0.7), at + Vector2(half, -0.7),
		at + Vector2(half - 2, 1), at + Vector2(0, 1.5),
		at + Vector2(-half + 2, 1),
	]), Color(0.39, 0.25, 0.12, 0.35))


func _face(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	return style
