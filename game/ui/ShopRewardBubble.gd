extends PanelContainer

## Approved shop reward bubble: one continuous contour and a tail toward the chest.
const FILL := Color("67402e")
const INK := Color("583f21")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inset := StyleBoxEmpty.new()
	inset.content_margin_left = 20
	inset.content_margin_right = 20
	inset.content_margin_top = 13
	inset.content_margin_bottom = 13
	add_theme_stylebox_override("panel", inset)
	resized.connect(queue_redraw)


func _draw() -> void:
	var edge := 2.5
	var radius := minf(17.0, size.y * 0.2)
	var right := size.x - edge
	var bottom := size.y - edge
	var tail_y := clampf(size.y * 0.53, radius + 18, size.y - radius - 18)
	var points := PackedVector2Array()
	_arc(points, Vector2(right - radius, edge + radius), radius, -PI / 2.0, 0.0)
	_arc(points, Vector2(right - radius, bottom - radius), radius, 0.0, PI / 2.0)
	_arc(points, Vector2(edge + radius, bottom - radius), radius, PI / 2.0, PI)
	points.append(Vector2(edge, tail_y + 16))
	points.append(Vector2(edge - 16, tail_y + 5))
	points.append(Vector2(edge, tail_y - 13))
	_arc(points, Vector2(edge + radius, edge + radius), radius, PI, PI * 1.5)
	draw_colored_polygon(points, FILL)
	points.append(points[0])
	draw_polyline(points, INK, 5.0, true)


func _arc(points: PackedVector2Array, center: Vector2, radius: float, start: float, finish: float) -> void:
	for index in 9:
		var angle := lerpf(start, finish, float(index) / 8.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
