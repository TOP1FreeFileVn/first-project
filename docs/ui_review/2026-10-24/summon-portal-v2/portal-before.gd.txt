extends Node2D

# Shared summon artwork: the banner keeps a quiet portal, while the opening feeds
# energy into the same seal. Bursts stay local so cards and controls remain legible.
const INK := Color("583f21")
const LILAC := Color("ae8bd5")
const CREAM := Color("fff0c7")
const MINT := Color("b8e8d9")
const FLOOR := Vector2(0, 150)

var energy := 0.0
var opacity := 1.0
var accent := LILAC
var ambient := false
var elapsed := 0.0
var _bursts: Array[Dictionary] = []


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	elapsed += delta
	for burst in _bursts:
		burst["age"] += delta
	_bursts = _bursts.filter(func(burst: Dictionary): return burst["age"] < burst["duration"])
	queue_redraw()


func pulse(at: Vector2, color: Color, strength := 1.0) -> void:
	if _bursts.size() >= 8:
		_bursts.pop_front()
	_bursts.append({"at": at, "color": color, "strength": clampf(strength, 0.3, 2.2),
		"age": 0.0, "duration": 0.8})
	queue_redraw()


func clear_bursts() -> void:
	_bursts.clear()
	queue_redraw()


func _draw() -> void:
	if opacity <= 0.001:
		return
	var power := clampf(energy, 0.0, 1.0)
	var breathe := sin(elapsed * 1.7) * 0.5 + 0.5
	var hue := LILAC.lerp(accent, power * 0.7)
	var radius := 229.0 + power * 12.0 + breathe * 2.0
	# The broad, solid material planes give the portal a place in the cat world.
	_disc(FLOOR + Vector2(0, 10), Vector2(radius + 8, 72), Color("715579"), 6.0)
	_disc(FLOOR, Vector2(radius + 8, 72), hue.darkened(0.18), 6.0)
	_disc(FLOOR - Vector2(0, 3), Vector2(radius - 17, 56), Color("655174"), 0.0)
	_stroke(_ellipse(FLOOR - Vector2(0, 3), Vector2(radius - 33, 47)), _ink(hue.lightened(0.25)), 4.0)
	# Open, rounded cream tracks replace a collection of thin geometric symbols.
	var turn := elapsed * (0.20 + power * 0.65)
	for i in 4:
		var angle := turn + i * TAU / 4.0
		_stroke(_ellipse(FLOOR, Vector2(radius - 10, 62), angle, angle + 0.66), _ink(CREAM), 7.0)
		var at := FLOOR + Vector2(cos(angle + 0.8) * (radius - 10), sin(angle + 0.8) * 62)
		draw_circle(at, 4.0, _ink(MINT))
	# A single large paw makes the ritual belong to these cats.
	_paw(FLOOR - Vector2(0, 4), 0.78, 0.40, hue.lightened(0.42))
	for i in 6:
		var angle := -turn * 0.7 + i * TAU / 6.0
		var at := FLOOR + Vector2(cos(angle) * 163, sin(angle) * 37)
		_star(at, 6.0, 0.0, _ink(CREAM, 0.8))
	# Quiet ambient flecks stay below the featured cats. Charged motes spiral in
	# towards the floating source card rather than shooting through the whole screen.
	var amount := 7 if ambient else 16
	for i in amount:
		var seed := float(i)
		var t := fposmod(elapsed * (0.22 + power * 0.52) + seed * 0.618, 1.0)
		var alpha := sin(t * PI) * (0.36 if ambient else 0.3 + power * 0.7)
		var angle := seed * 2.4 + t * 3.5 + elapsed * 0.3
		var r := lerpf(200.0, 32.0, t) if not ambient else 210.0
		var at := Vector2(cos(angle) * r, 145.0 - t * (95.0 if ambient else 230.0))
		at.y += sin(angle) * (18.0 if ambient else 45.0 * (1.0 - t))
		var tint := CREAM if i % 3 == 0 else MINT if i % 3 == 1 else hue.lightened(0.35)
		if i % 3 == 0:
			_star(at, 7.0 + power * 3.0, elapsed * 0.2 + seed, _ink(tint, alpha))
		else:
			draw_circle(at, 3.5 + power * 2.0, _ink(tint, alpha))
	if not ambient and power > 0.01:
		for i in 3:
			var angle := -elapsed * (0.5 + power * 2.0) + i * TAU / 3.0
			var r := 119.0 - power * 23.0
			var at := Vector2(cos(angle) * r, sin(angle) * r * 0.62 - 8)
			_star(at, 8.0 + power * 5.0, angle, _ink(CREAM, power))
	for burst in _bursts:
		_draw_burst(burst)


func _draw_burst(burst: Dictionary) -> void:
	var t: float = burst["age"] / burst["duration"]
	var strength: float = burst["strength"]
	var at: Vector2 = burst["at"]
	var tint: Color = burst["color"]
	var ease := 1.0 - pow(1.0 - t, 3.0)
	var fade := pow(1.0 - t, 1.5)
	var radius := lerpf(22.0, 185.0 * strength, ease)
	_stroke(_ellipse(at, Vector2(radius, radius * 0.66)), _ink(tint.lightened(0.25), fade * 0.8), 8.0 * fade + 1.0)
	for i in 18:
		var angle := i * TAU / 18.0 - 0.2
		var distance := radius * (0.65 + (i % 3) * 0.2)
		var point := at + Vector2.from_angle(angle) * distance
		point.y += 44.0 * t * t
		var color := CREAM if i % 3 == 0 else tint if i % 3 == 1 else MINT
		if i % 2 == 0:
			_star(point, (8.0 + (i % 3) * 3.0) * strength * fade, angle + t, _ink(color, fade))
		else:
			var direction := Vector2.from_angle(angle)
			draw_line(point, point + direction * 18.0 * fade * strength, _ink(color, fade), 5.0 * fade + 1.0, true)


func _ink(color: Color, alpha := 1.0) -> Color:
	return Color(color, color.a * alpha * opacity)


func _disc(at: Vector2, radii: Vector2, fill: Color, width: float) -> void:
	var points := _ellipse(at, radii)
	draw_colored_polygon(points, _ink(fill))
	if width > 0.0:
		_stroke(points, _ink(INK), width)


func _ellipse(at: Vector2, radii: Vector2, start := 0.0, end := TAU) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := maxi(8, ceili(absf(end - start) / TAU * 72.0))
	for i in steps + 1:
		var angle := lerpf(start, end, float(i) / steps)
		points.append(at + Vector2(cos(angle), sin(angle)) * radii)
	return points


func _stroke(points: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(points, color, width, true)
	# Canvas polylines have square ends; these explicit caps keep the shared art round.
	draw_circle(points[0], width * 0.5, color)
	draw_circle(points[-1], width * 0.5, color)


func _star(at: Vector2, radius: float, rotation: float, color: Color) -> void:
	# Fading bursts eventually shrink below the raster grid. Godot's polygon
	# triangulator treats those near-coincident vertices as a degenerate polygon.
	if radius < 0.75 or color.a < 0.01:
		return
	var points := PackedVector2Array()
	for i in 8:
		var direction := Vector2.from_angle(rotation - PI / 2.0 + i * TAU / 8.0)
		points.append(at + direction * radius * (1.0 if i % 2 == 0 else 0.32))
	draw_colored_polygon(points, color)


func _paw(at: Vector2, paw_scale: float, flatten: float, color: Color) -> void:
	var pad := PackedVector2Array()
	for point: Vector2 in [Vector2(-42, 20), Vector2(-39, 5), Vector2(-23, -6), Vector2(-13, -22),
		Vector2(0, -27), Vector2(13, -22), Vector2(23, -6), Vector2(39, 5), Vector2(42, 20),
		Vector2(31, 31), Vector2(13, 30), Vector2(0, 24), Vector2(-13, 30), Vector2(-31, 31)]:
		pad.append(at + point * Vector2(paw_scale, paw_scale * flatten))
	pad.append(pad[0])
	draw_colored_polygon(pad, _ink(color))
	_stroke(pad, _ink(INK, 0.7), 3.5)
	for toe: Vector2 in [Vector2(-50, -29), Vector2(-21, -57), Vector2(21, -57), Vector2(50, -29)]:
		_disc(at + toe * Vector2(paw_scale, paw_scale * flatten), Vector2(12, 17 * flatten) * paw_scale, color, 2.5)
