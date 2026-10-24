extends PanelContainer

## Review-only speech bubble. One continuous brown contour, without a drop shadow.
var fill := Color("684334")
var contour := Color("583f21")
var tail_side := "left"
var tail_ratio := 0.54


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 20
	empty.content_margin_right = 20
	empty.content_margin_top = 13
	empty.content_margin_bottom = 13
	add_theme_stylebox_override("panel", empty)
	resized.connect(queue_redraw)


func _draw() -> void:
	var edge := 2.5
	var left := edge
	var right := size.x - edge
	var top := edge
	var bottom := size.y - edge
	var radius := minf(17.0, size.y * 0.2)
	var points := PackedVector2Array()
	_arc(points, Vector2(right - radius, top + radius), radius, -PI / 2.0, 0.0)
	if tail_side == "right":
		var y := clampf(size.y * tail_ratio, radius + 18, size.y - radius - 18)
		points.append(Vector2(right, y - 13))
		points.append(Vector2(right + 16, y + 5))
		points.append(Vector2(right, y + 16))
	_arc(points, Vector2(right - radius, bottom - radius), radius, 0.0, PI / 2.0)
	if tail_side == "bottom":
		var x := clampf(size.x * tail_ratio, radius + 20, size.x - radius - 20)
		points.append(Vector2(x + 18, bottom))
		points.append(Vector2(x - 5, bottom + 15))
		points.append(Vector2(x - 11, bottom))
	_arc(points, Vector2(left + radius, bottom - radius), radius, PI / 2.0, PI)
	if tail_side == "left":
		var y := clampf(size.y * tail_ratio, radius + 18, size.y - radius - 18)
		points.append(Vector2(left, y + 16))
		points.append(Vector2(left - 16, y + 5))
		points.append(Vector2(left, y - 13))
	_arc(points, Vector2(left + radius, top + radius), radius, PI, PI * 1.5)
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, contour, 5.0, true)


func _arc(points: PackedVector2Array, center: Vector2, radius: float, from: float, to: float) -> void:
	for index in range(9):
		var angle := lerpf(from, to, float(index) / 8.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
