extends Control

# Minimal line chart: several series of points on shared axes, with a light grid and
# min/max labels. Dashed series are used for "old" values next to the edited ones.

const PAD := Vector2(64, 28)

## Each: {"points": Array[Vector2], "color": Color, "dashed": bool, "label": String}
var series: Array = []
var x_label := ""


func _init() -> void:
	custom_minimum_size = Vector2(0, 260)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_series(p_series: Array, p_x_label := "") -> void:
	series = p_series
	x_label = p_x_label
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.07, 0.09, 0.9))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for s in series:
		for p in s["points"]:
			lo = lo.min(p)
			hi = hi.max(p)
	if lo.x == INF:
		return
	lo.y = minf(lo.y, 0.0)
	if is_equal_approx(hi.x, lo.x):
		hi.x = lo.x + 1.0
	if is_equal_approx(hi.y, lo.y):
		hi.y = lo.y + 1.0
	var area := Rect2(Vector2(PAD.x, 10), size - Vector2(PAD.x + 12, PAD.y + 10))
	var to_screen := func(p: Vector2) -> Vector2:
		return Vector2(area.position.x + (p.x - lo.x) / (hi.x - lo.x) * area.size.x,
			area.end.y - (p.y - lo.y) / (hi.y - lo.y) * area.size.y)

	for i in 5:
		var t := i / 4.0
		var y := area.end.y - t * area.size.y
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(1, 1, 1, 0.08))
		draw_string(font, Vector2(4, y + 5), _short(lerpf(lo.y, hi.y, t)), HORIZONTAL_ALIGNMENT_LEFT, PAD.x - 8, 13, Color(1, 1, 1, 0.6))
	draw_string(font, Vector2(area.position.x, size.y - 6), _short(lo.x), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.6))
	draw_string(font, Vector2(area.end.x - 60, size.y - 6), _short(hi.x), HORIZONTAL_ALIGNMENT_RIGHT, 60, 13, Color(1, 1, 1, 0.6))
	if x_label != "":
		draw_string(font, Vector2(area.get_center().x - 60, size.y - 6), x_label, HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color(1, 1, 1, 0.6))

	for s in series:
		var points: Array = s["points"]
		for i in range(1, points.size()):
			var a: Vector2 = to_screen.call(points[i - 1])
			var b: Vector2 = to_screen.call(points[i])
			if s.get("dashed", false):
				draw_dashed_line(a, b, s["color"], 2.0, 6.0)
			else:
				draw_line(a, b, s["color"], 3.0, true)
		if points.size() == 1:
			draw_circle(to_screen.call(points[0]), 4.0, s["color"])


static func _short(v: float) -> String:
	if absf(v) >= 1000000.0:
		return "%.1fM" % (v / 1000000.0)
	if absf(v) >= 10000.0:
		return "%.0fk" % (v / 1000.0)
	if absf(v - roundf(v)) < 0.001:
		return str(int(roundf(v)))
	return str(snappedf(v, 0.01))
