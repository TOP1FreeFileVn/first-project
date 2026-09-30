extends RefCounted

# Procedural cogwheels and the master drive orb: the art pack has no gears, so they are
# drawn as polygons.

static func draw_cog(ci: CanvasItem, center: Vector2, outer: float, inner: float, teeth: int, angle: float, fill: Color, rim: Color) -> void:
	var points := PackedVector2Array()
	var step := TAU / teeth
	for i in teeth:
		var a := angle + i * step
		points.append(center + Vector2.from_angle(a) * inner)
		points.append(center + Vector2.from_angle(a + step * 0.18) * outer)
		points.append(center + Vector2.from_angle(a + step * 0.42) * outer)
		points.append(center + Vector2.from_angle(a + step * 0.6) * inner)
	ci.draw_colored_polygon(points, fill)
	points.append(points[0])
	ci.draw_polyline(points, rim, 2.0, true)
	var hub := inner * 0.78
	ci.draw_circle(center, hub, fill.darkened(0.3))
	ci.draw_arc(center, hub, 0.0, TAU, 32, rim, 2.0, true)
	# Bolts on the hub make the spin readable even when an icon covers the middle.
	for k in 4:
		ci.draw_circle(center + Vector2.from_angle(angle + k * TAU / 4.0) * hub * 0.82, 2.5, rim)


## The master drive: a round orange hub (not a cog) with one long tapered arm (a
## trapezoid, wide at the hub, narrow at the end) at `angle`, ending in a rounded tip of
## radius `tip_radius` centred `reach` from the centre. The tip is what drives the gears.
static func draw_orb(ci: CanvasItem, center: Vector2, radius: float, angle: float, reach := 0.0, tip_radius := 0.0) -> void:
	if reach <= 0.0:
		reach = radius * 1.7
	if tip_radius <= 0.0:
		tip_radius = radius * 0.22
	var dir := Vector2.from_angle(angle)
	var side := dir.orthogonal()
	var base_half := radius * 0.5
	var root := center + dir * radius * 0.5
	var tip := center + dir * reach
	var arm := PackedVector2Array([root - side * base_half, tip - side * tip_radius, tip + side * tip_radius, root + side * base_half])
	var outline := arm.duplicate()
	outline.append(arm[0])
	ci.draw_circle(center + Vector2(0, radius * 0.1), radius, Color(0, 0, 0, 0.25))
	ci.draw_colored_polygon(arm, Color("e9861b"))
	ci.draw_polyline(outline, Color("8f4610"), 2.5, true)
	ci.draw_circle(tip, tip_radius + 1.2, Color("8f4610"))
	ci.draw_circle(tip, tip_radius - 0.2, Color("e9861b"))
	# Lit edge along one side of the arm, stopping short of the tip.
	ci.draw_line(root + side * base_half * 0.45, root.lerp(tip, 0.65) + side * lerpf(base_half, tip_radius, 0.65) * 0.35, Color("ffc75a"), 2.0, true)
	ci.draw_circle(center, radius, Color("b85d12"))
	ci.draw_circle(center, radius * 0.9, Color("e9861b"))
	ci.draw_circle(center, radius * 0.72, Color("f7a526"))
	# Soft highlight, top-left, fixed so the hub looks lit while it turns.
	ci.draw_arc(center, radius * 0.55, PI * 1.05, PI * 1.45, 16, Color(1.0, 0.9, 0.6, 0.55), radius * 0.12, true)
	ci.draw_circle(center, radius * 0.18, Color("b85d12"))
