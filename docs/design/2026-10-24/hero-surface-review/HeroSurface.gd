extends PanelContainer

## Review-only replacement for the large surface behind the hero and four slots.
## Equipment-card faces and their rarity borders remain owned by EquipmentCard.
var variant: int = 0:
	set(value):
		variant = clampi(value, 0, 2)
		queue_redraw()
var grain: Texture2D

const BORDER := 3
const PALETTES := [
	[Color("CBDDDA"), Color("354E50"), Color("BDD0CB")],
	[Color("F0E0C3"), Color("654D3B"), Color("E6D3B0")],
	[Color("DED7E8"), Color("54485F"), Color("CEC4DA")],
]


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margins := StyleBoxEmpty.new()
	margins.content_margin_left = 18
	margins.content_margin_right = 18
	margins.content_margin_top = 16
	margins.content_margin_bottom = 12
	add_theme_stylebox_override("panel", margins)
	resized.connect(queue_redraw)


func _flat(fill: Color, radius: int, ink := Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = ink
	box.set_border_width_all(BORDER if ink.a > 0.0 else 0)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	box.anti_aliasing_size = 1.0
	return box


func _draw() -> void:
	if size.x <= 6.0 or size.y <= 6.0:
		return
	var colors: Array = PALETTES[variant]
	if variant == 1:
		_draw_cut_paper(colors[0], colors[1])
		return
	var radius := 16 if variant == 0 else 22
	var bounds := Rect2(Vector2.ZERO, size)
	draw_style_box(_flat(colors[0], radius), bounds)
	# This quiet lower surface groups the existing statistics and skill rows.
	# Its lower corners follow the outer shape; no content clipping is enabled.
	var band := _flat(colors[2], radius)
	band.corner_radius_top_left = 0
	band.corner_radius_top_right = 0
	var band_top := maxf(radius, size.y - 112.0)
	draw_style_box(band, Rect2(0, band_top, size.x, size.y - band_top))
	# A single transparent style box supplies the only enclosing outline.
	draw_style_box(_flat(Color.TRANSPARENT, radius, colors[1]), bounds)


func _draw_cut_paper(fill: Color, ink: Color) -> void:
	var edge := BORDER * 0.5
	var cut := 12.0
	var points := PackedVector2Array([
		Vector2(edge + cut, edge),
		Vector2(size.x - edge - cut, edge),
		Vector2(size.x - edge, edge + cut),
		Vector2(size.x - edge, size.y - edge - cut),
		Vector2(size.x - edge - cut, size.y - edge),
		Vector2(edge + cut, size.y - edge),
		Vector2(edge, size.y - edge - cut),
		Vector2(edge, edge + cut),
	])
	draw_colored_polygon(points, fill)
	# A small folded corner makes this the paper option without adding trim.
	var fold_start := Vector2(size.x - edge - 29.0, edge)
	var fold_end := Vector2(size.x - edge, edge + 29.0)
	var fold := PackedVector2Array([
		fold_start,
		Vector2(size.x - edge - cut, edge),
		Vector2(size.x - edge, edge + cut),
		fold_end,
	])
	draw_colored_polygon(fold, Color("E1CBA6"))
	draw_line(fold_start, fold_end, Color("B29A79"), 1.5, true)
	points.append(points[0])
	draw_polyline(points, ink, BORDER, true)
