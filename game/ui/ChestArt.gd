extends RefCounted

# A broad, soft chest in the same flat, warm-ink family as the cats. The lid
# remains a separate local drawing, hinged on the seam for ChestOpening's flight.
# One construction serves the 26 px reward symbol and 250 px opening prop.
const INK := Color("583f21")
const STYLES := {
	"wood": {"body": Color("dda565"), "dark": Color("b98145"), "light": Color("f5cc88"),
		"band": Color("a5b1a2"), "band_light": Color("d3dbc5"), "band_ink": Color("6d7c65"),
		"paw": Color("66755e"), "planks": true, "gem": false},
	"silver": {"body": Color("83b9d1"), "dark": Color("5e94af"), "light": Color("b5deeb"),
		"band": Color("dce5dd"), "band_light": Color("f6f5df"), "band_ink": Color("93aaa7"),
		"paw": Color("608da2"), "planks": false, "gem": false},
	"gold": {"body": Color("ef8270"), "dark": Color("cf5e52"), "light": Color("ffb397"),
		"band": Color("ffd16a"), "band_light": Color("ffe9a1"), "band_ink": Color("cc963e"),
		"paw": Color("5baeb5"), "planks": false, "gem": true},
}
# Keep the existing callers' tint-to-kind mapping, independent of the new paint.
const TINTS := {"wood": Color("a0673a"), "silver": Color("aeb8c2"), "gold": Color("e8b93c")}
const BASE_H := 0.37
const LID_H := 0.29


static func style_for(tint: Color) -> Dictionary:
	var best := "wood"
	var best_distance := INF
	for kind in TINTS:
		var t: Color = TINTS[kind]
		var d := Vector3(t.r - tint.r, t.g - tint.g, t.b - tint.b).length()
		if d < best_distance:
			best_distance = d
			best = kind
	return STYLES[best]


## `seam` remains the animation origin. Only the lid and its bands move/rotate;
## the mouth, lock and body stay on the base during the existing opening tween.
static func draw(ci: CanvasItem, seam: Vector2, w: float, style: Dictionary, alpha := 1.0,
		lid_offset := Vector2.ZERO, lid_rotation := 0.0, lid_alpha := 1.0, mouth := Color(0, 0, 0, 0)) -> void:
	var shadow := _ellipse(seam + Vector2(0, w * 0.393), Vector2(w * 0.445, w * 0.037))
	ci.draw_colored_polygon(shadow, Color(INK, alpha * 0.15))
	var open := mouth.a > 0.0
	if open:
		_draw_mouth(ci, seam, w, style, alpha, mouth)
	_draw_base(ci, seam, w, style, alpha)
	if lid_alpha > 0.0:
		ci.draw_set_transform(seam + lid_offset, lid_rotation, Vector2.ONE)
		_draw_lid(ci, w, style, alpha * lid_alpha)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_lock(ci, seam, w, style, alpha, open)


static func _c(s: Dictionary, key: String, alpha: float) -> Color:
	return Color(s[key], alpha)


static func _curve(start: Vector2, segments: Array) -> PackedVector2Array:
	var result := PackedVector2Array([start])
	var from := start
	for segment in segments:
		var c1: Vector2 = segment[0]
		var c2: Vector2 = segment[1]
		var to: Vector2 = segment[2]
		for i in range(1, 9):
			var t := i / 8.0
			var u := 1.0 - t
			result.append(from * u * u * u + c1 * 3.0 * u * u * t + c2 * 3.0 * u * t * t + to * t * t * t)
		from = to
	return result


static func _placed(points: PackedVector2Array, at: Vector2, scale: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:
		result.append(at + p * scale)
	return result


static func _ellipse(at: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 32:
		points.append(at + Vector2(cos(i * TAU / 32.0), sin(i * TAU / 32.0)) * radii)
	return points


static func _rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	var centers := [rect.position + Vector2(r, r), Vector2(rect.end.x - r, rect.position.y + r),
		rect.end - Vector2(r, r), Vector2(rect.position.x + r, rect.end.y - r)]
	for corner in 4:
		for i in 7:
			var angle := PI + corner * PI * 0.5 + i * PI / 12.0
			points.append(centers[corner] + Vector2.from_angle(angle) * r)
	return points


static func _stroke(ci: CanvasItem, points: PackedVector2Array, color: Color, width: float, closed := true) -> void:
	var loop := points.duplicate()
	if closed:
		loop.append(points[0])
	ci.draw_polyline(loop, color, width, true)


static func _line(ci: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float) -> void:
	ci.draw_line(from, to, color, width, true)
	ci.draw_circle(from, width * 0.5, color, true, -1.0, true)
	ci.draw_circle(to, width * 0.5, color, true, -1.0, true)


static func _draw_mouth(ci: CanvasItem, seam: Vector2, w: float, s: Dictionary, a: float, light: Color) -> void:
	# A soft oval cavity, behind the fixed front wall; no rectangular black slot.
	var rim := _ellipse(seam + Vector2(0, -w * 0.018), Vector2(w * 0.452, w * 0.072))
	ci.draw_colored_polygon(rim, _c(s, "band", a))
	_stroke(ci, rim, Color(INK, a), w * 0.03)
	var inside := _ellipse(seam + Vector2(0, -w * 0.025), Vector2(w * 0.389, w * 0.039))
	ci.draw_colored_polygon(inside, _c(s, "dark", a))
	ci.draw_colored_polygon(inside, Color(light, light.a * a))


static func _draw_base(ci: CanvasItem, seam: Vector2, w: float, s: Dictionary, a: float) -> void:
	var shape := _placed(_curve(Vector2(-0.435, 0), [
		[Vector2(-0.18, -0.005), Vector2(0.18, -0.005), Vector2(0.435, 0)],
		[Vector2(0.48, 0), Vector2(0.491, 0.035), Vector2(0.49, 0.092)],
		[Vector2(0.492, 0.21), Vector2(0.48, 0.30), Vector2(0.45, 0.34)],
		[Vector2(0.424, 0.374), Vector2(0.35, 0.37), Vector2(0.28, 0.37)],
		[Vector2(0.10, 0.38), Vector2(-0.10, 0.38), Vector2(-0.28, 0.37)],
		[Vector2(-0.35, 0.37), Vector2(-0.424, 0.374), Vector2(-0.45, 0.34)],
		[Vector2(-0.48, 0.30), Vector2(-0.492, 0.21), Vector2(-0.49, 0.092)],
		[Vector2(-0.491, 0.035), Vector2(-0.48, 0), Vector2(-0.435, 0)],
	]), seam, w)
	ci.draw_colored_polygon(shape, _c(s, "body", a))
	# Single broad lower rail; the center stays a generous uninterrupted fill.
	var rail := _rounded(Rect2(seam + Vector2(-w * 0.456, w * 0.294), Vector2(w * 0.912, w * 0.064)), w * 0.028)
	ci.draw_colored_polygon(rail, _c(s, "dark", a))
	if s["planks"] and w >= 48.0:
		# Open-ended grain explains wood without boxing every plank in dark ink.
		_line(ci, seam + Vector2(-w * 0.44, w * 0.184), seam + Vector2(-w * 0.085, w * 0.184), _c(s, "dark", a), w * 0.011)
		_line(ci, seam + Vector2(w * 0.16, w * 0.238), seam + Vector2(w * 0.435, w * 0.238), _c(s, "dark", a), w * 0.011)
	for x in [-0.31, 0.31]:
		var band := _rounded(Rect2(seam + Vector2(w * (x - 0.061), w * 0.009), Vector2(w * 0.122, w * 0.342)), w * 0.027)
		ci.draw_colored_polygon(band, _c(s, "band", a))
		# Material-colored contact edge, subordinate to the main outer contour.
		if w >= 48.0:
			_line(ci, seam + Vector2(w * (x + 0.061), w * 0.035), seam + Vector2(w * (x + 0.061), w * 0.315), _c(s, "band_ink", a), w * 0.012)
			_line(ci, seam + Vector2(w * (x - 0.032), w * 0.075), seam + Vector2(w * (x - 0.032), w * 0.225), _c(s, "band_light", a), w * 0.026)
	_stroke(ci, shape, Color(INK, a), w * 0.035)


static func _dome_y(x: float, w: float) -> float:
	var t := clampf(absf(x) / (w * 0.5), 0.0, 1.0)
	return -w * (0.04 + 0.25 * sqrt(maxf(0.0, 1.0 - pow(t, 4.0))))


static func _draw_lid(ci: CanvasItem, w: float, s: Dictionary, a: float) -> void:
	var shape := PackedVector2Array()
	for i in 65:
		# Concentrate samples at the shoulders, where a uniform x step facets
		# the round contour most visibly at the 250 px opening size.
		var x := -cos(i * PI / 64.0) * w * 0.5
		shape.append(Vector2(x, _dome_y(x, w)))
	shape.append_array(_placed(_curve(Vector2(0.5, -0.04), [
		[Vector2(0.503, -0.005), Vector2(0.485, 0), Vector2(0.455, 0)],
		[Vector2(0.2, 0.008), Vector2(-0.2, 0.008), Vector2(-0.455, 0)],
		[Vector2(-0.485, 0), Vector2(-0.503, -0.005), Vector2(-0.5, -0.04)],
	]), Vector2.ZERO, w).slice(1))
	ci.draw_colored_polygon(shape, _c(s, "body", a))
	# Broad paint inset follows the puffed dome instead of a glossy shine stripe.
	var inset := _rounded(Rect2(Vector2(-w * 0.235, -w * 0.245), Vector2(w * 0.47, w * 0.105)), w * 0.045)
	ci.draw_colored_polygon(inset, _c(s, "light", a))
	for x in [-0.31, 0.31]:
		var band := PackedVector2Array([Vector2(w * (x - 0.061), -w * 0.025)])
		for i in 9:
			var bx: float = w * (x - 0.061 + 0.122 * i / 8.0)
			band.append(Vector2(bx, _dome_y(bx, w)))
		band.append(Vector2(w * (x + 0.061), -w * 0.025))
		ci.draw_colored_polygon(band, _c(s, "band", a))
		if w >= 48.0:
			_line(ci, Vector2(w * (x + 0.061), _dome_y(w * (x + 0.061), w) + w * 0.012), Vector2(w * (x + 0.061), -w * 0.06), _c(s, "band_ink", a), w * 0.012)
			_line(ci, Vector2(w * (x - 0.032), -w * 0.22), Vector2(w * (x - 0.032), -w * 0.105), _c(s, "band_light", a), w * 0.026)
	var lip := _rounded(Rect2(Vector2(-w * 0.487, -w * 0.06), Vector2(w * 0.974, w * 0.059)), w * 0.026)
	ci.draw_colored_polygon(lip, _c(s, "band", a))
	# One shared seam across the lid, rather than outlines around each band patch.
	_line(ci, Vector2(-w * 0.445, -w * 0.061), Vector2(w * 0.445, -w * 0.061), _c(s, "band_ink", a), w * 0.012)
	_stroke(ci, shape, Color(INK, a), w * 0.035)


static func _draw_lock(ci: CanvasItem, seam: Vector2, w: float, s: Dictionary, a: float, open: bool) -> void:
	var top := 0.0 if open else -0.057
	var plate := _rounded(Rect2(seam + Vector2(-w * 0.106, w * top), Vector2(w * 0.212, w * (0.19 - top))), w * 0.049)
	ci.draw_colored_polygon(plate, _c(s, "band", a))
	_stroke(ci, plate, Color(INK, a), w * 0.026)
	# The paw is the only ornament: a functional, generously sized lock emblem.
	var center := seam + Vector2(0, w * 0.09)
	var paw := _placed(_curve(Vector2(-0.049, 0.022), [
		[Vector2(-0.053, 0.001), Vector2(-0.026, -0.002), Vector2(-0.017, -0.02)],
		[Vector2(-0.007, -0.037), Vector2(0.007, -0.037), Vector2(0.017, -0.02)],
		[Vector2(0.026, -0.002), Vector2(0.053, 0.001), Vector2(0.049, 0.022)],
		[Vector2(0.045, 0.047), Vector2(0.018, 0.032), Vector2(0, 0.035)],
		[Vector2(-0.018, 0.032), Vector2(-0.045, 0.047), Vector2(-0.049, 0.022)],
	]), center, w)
	ci.draw_colored_polygon(paw, _c(s, "paw", a))
	for toe in [Vector2(-0.052, -0.023), Vector2(-0.021, -0.049), Vector2(0.021, -0.049), Vector2(0.052, -0.023)]:
		ci.draw_circle(center + toe * w, w * 0.017, _c(s, "paw", a), true, -1.0, true)
