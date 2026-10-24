extends Control

## The accepted honey-cream section strip. Two-tone is a reviewable alternative,
## with a single flat light/dark split and the same authored outer contour.
const Ui = preload("res://game/ui/Ui.gd")
const HEIGHT := 52.0
const SIDE_INSET := 28.0
const STROKE := 4
const RADIUS := 12
const INK := Color("583f21")
const TEXT := Color("503c25")
const FLAT_FILL := Color("f3d79b")
const LIGHT_FILL := Color("f8e4b7")
const DARK_FILL := Color("e8c782")

var heading := "":
	set(value):
		heading = value
		if is_instance_valid(_caption):
			_caption.text = value

var two_tone := false:
	set(value):
		two_tone = value
		queue_redraw()

var split_ratio := 0.45:
	set(value):
		split_ratio = clampf(value, 0.25, 0.55)
		queue_redraw()

var gutter := Color.TRANSPARENT:
	set(value):
		gutter = value
		queue_redraw()

var _caption: Label


func _init() -> void:
	custom_minimum_size = Vector2(0, HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_caption = Ui.label(heading, "LabelDark", 26)
	_caption.name = "SectionCaption"
	_caption.add_theme_color_override("font_color", TEXT)
	_caption.add_theme_constant_override("outline_size", 0)
	add_child(_caption)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_caption.offset_left = SIDE_INSET
	_caption.offset_right = -SIDE_INSET
	resized.connect(queue_redraw)


func face_rect() -> Rect2:
	return Rect2(SIDE_INSET, 0, maxf(0, size.x - SIDE_INSET * 2), size.y)


func _draw() -> void:
	if gutter.a > 0:
		draw_rect(Rect2(Vector2.ZERO, size), gutter)
	var rect := face_rect()
	if not rect.has_area():
		return
	var upper := _face(LIGHT_FILL if two_tone else FLAT_FILL)
	draw_style_box(upper, rect)
	if two_tone:
		var split := rect.size.y * split_ratio
		var lower := _face(DARK_FILL)
		lower.corner_radius_top_left = 0
		lower.corner_radius_top_right = 0
		draw_style_box(lower, Rect2(rect.position + Vector2(0, split), Vector2(rect.size.x, rect.size.y - split)))
	var outline := _face(Color.TRANSPARENT)
	outline.draw_center = false
	outline.border_color = INK
	outline.set_border_width_all(STROKE)
	draw_style_box(outline, rect)


func _face(color: Color) -> StyleBoxFlat:
	var face := StyleBoxFlat.new()
	face.bg_color = color
	face.set_corner_radius_all(RADIUS)
	face.anti_aliasing = true
	return face
