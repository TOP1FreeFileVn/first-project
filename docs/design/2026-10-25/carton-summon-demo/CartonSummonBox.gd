extends Node2D

# Isolated storyboard actor. Origin is the centre of the box's bottom edge.
# Front face: 260 x 150 px. Closed bounds: (-133, -197) .. (133, 3).
# Fully open flaps extend to about +/-202 and y=-269. Cat reaches y=-337.
# Parent owns all timing, audio and surrounding smoke / light effects.
const INK := Color("583f21")
const SEAM := Color("ad7d47")
const BOARD := Color("dfb575")
const BOARD_LIGHT := Color("efd09a")
const BOARD_SIDE := Color("c99a5e")
const TAPE := Color("f8e0ad")
const RARITY_COLORS := [Color("b8e8cf"), Color("9ed9ee"), Color("d3acf2"), Color("ffe29a")]
const FRONT_LEFT := Vector2(-130, -150)
const FRONT_RIGHT := Vector2(130, -150)
const REAR_LEFT := Vector2(-108, -194)
const REAR_RIGHT := Vector2(108, -194)

var lid := 0.0
var paw := 0.0
var paw_curl := 0.0
var paw_press := 0.0
## Lateral wrist sway in pixels; the curled toes remain attached to the lid.
var paw_sway := 0.0
var glow := 0.0
var rarity := 0
var cat_rise := 0.0
var tint := Color.WHITE
var fur := Color("eaba74")
var wiggle := 0.0
var reveal := false
var cat_texture: Texture2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, wiggle * 0.035, Vector2.ONE)
	var opening := _opening()
	var left := _flap_points(-1, opening)
	var right := _flap_points(1, opening)
	# Rear wall and the one real opening. Material regions stay broad and flat.
	_panel([FRONT_LEFT, REAR_LEFT, REAR_RIGHT, FRONT_RIGHT], Color("987046"), 6.0, 3.0)
	_panel([Vector2(-116, -151), Vector2(-101, -181), Vector2(101, -181), Vector2(116, -151)], Color("79563d"), 0.0, 2.0)
	_line(Vector2(-105, -185), Vector2(105, -185), Color("c19a67"), 3.0)
	# The far/right flap stays behind the reaching paw.
	_draw_flap(right, 1, opening)
	if glow > 0.001 and opening > 0.005:
		var color: Color = RARITY_COLORS[clampi(rarity, 0, 3)]
		var alpha := clampf(glow, 0.0, 1.0)
		_panel([Vector2(-91, -155), Vector2(-74, -210), Vector2(74, -210), Vector2(91, -155)], Color(color, alpha * 0.19), 0.0, 8.0)
		_ellipse(Vector2(0, -163), Vector2(91, 15), Color(color, alpha * 0.65), 0.0)
	_draw_reaching_paw(opening)
	# The pushed flap covers the paw where it makes contact; its hinge stays fixed.
	_draw_flap(left, -1, opening)
	_draw_cat()
	_draw_front()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _opening() -> float:
	# The first toe parts the seam slightly before the parent's full opening begins.
	return maxf(clampf(lid, 0.0, 1.0), clampf(paw, 0.0, 1.0) * 0.055 * (1.0 - clampf(lid, 0.0, 1.0)))


func _flap_points(side: int, opening: float) -> PackedVector2Array:
	var angle := opening * 2.12
	var front := FRONT_LEFT if side < 0 else FRONT_RIGHT
	var rear := REAR_LEFT if side < 0 else REAR_RIGHT
	var inward := float(-side)
	var front_free := front + Vector2(inward * 130.0 * cos(angle), -88.0 * sin(angle))
	var rear_free := rear + Vector2(inward * 108.0 * cos(angle), -73.0 * sin(angle))
	return PackedVector2Array([front, rear, rear_free, front_free])


func _draw_flap(points: PackedVector2Array, side: int, opening: float) -> void:
	var fill := BOARD_LIGHT if side < 0 else Color("e3bd80")
	_panel(points, fill, 6.0, 3.5)
	# Each half of the torn top tape belongs to its flap and follows its hinge.
	var tape := PackedVector2Array([
		points[0].lerp(points[3], 0.87), points[1].lerp(points[2], 0.87),
		points[2], points[3],
	])
	_panel(tape, TAPE, 0.0, 1.0)
	_line(points[0].lerp(points[3], 0.84), points[1].lerp(points[2], 0.84), Color("c49b62"), 2.5)
	# One quieter fold belongs to the broad board, not an outline around each fill.
	_line(points[0].lerp(points[1], 0.15), points[0].lerp(points[1], 0.85), SEAM, 2.5)
	if opening < 0.018:
		_line(points[2], points[3], SEAM, 3.0)


func paw_contact_point() -> Vector2:
	# Contact is the midpoint of the left flap's free edge. The paw releases once
	# the flap reaches its first lift, rather than stretching into a long arm.
	var flap := _flap_points(-1, minf(_opening(), 0.38))
	return flap[2].lerp(flap[3], 0.57)


func _draw_reaching_paw(opening: float) -> void:
	var reach := clampf(paw, 0.0, 1.0)
	if reach < 0.005:
		return
	var curl := clampf(paw_curl, 0.0, 1.0)
	var press := clampf(paw_press, 0.0, 1.0)
	var sway := clampf(paw_sway, -3.0, 3.0)
	var contact := paw_contact_point()
	if opening > 0.38:
		contact = contact.lerp(Vector2(-45, -202), inverse_lerp(0.38, 1.0, opening))
	var at := Vector2(-5, -123).lerp(contact + Vector2(11, 17), reach)
	var base := Vector2(-24, -102)
	var rotation := (at - base).angle() + PI / 2.0
	var squash := Vector2(1.0 + press * 0.12, 1.0 - press * 0.16)
	# Squash about the point touching the lid, not about the palm's centre.
	var local_contact := Vector2(0, -21.0 + curl * 5.0)
	at -= (local_contact * (squash - Vector2.ONE)).rotated(rotation)
	at.x += sway * (1.0 - curl * 0.85)
	# The arm overlaps well inside the palm. Merge the actual filled geometry,
	# then stroke ONLY its outside boundary. There is no separate wrist ring,
	# hidden seam stroke, or patch painted over an anatomical join.
	var wrist := at + (Vector2(0, 12) * squash).rotated(rotation)
	var silhouette := _paw_union(base, wrist, sway, at, rotation, squash, curl)
	_paint_paw(silhouette, fur, INK, 4.2)
	draw_set_transform(at.rotated(wiggle * 0.035), rotation + wiggle * 0.035, squash)
	# The reference is an egg-shaped kitten sole, not a hand: four very shallow
	# scallops follow its top arc, with a full rounded lower half and no thumb.
	_paint_paw(_paw_pad(), Color("f2b9c8"), Color("c58c9a"), 1.7)
	var beans := [Vector2(-22, -10.5), Vector2(-10, -20), Vector2(10, -20), Vector2(22, -10.5)]
	for i in beans.size():
		var toe: Vector2 = beans[i]
		toe.y += curl * (2.0 if i == 0 or i == 3 else 3.5)
		var bean_angle: float = [-0.36, -0.12, 0.12, 0.36][i]
		var bean := PackedVector2Array()
		var radii := Vector2(4.0 + press * 0.2, 6.5 - curl * 0.8)
		for j in 32:
			bean.append(toe + (Vector2.from_angle(j * TAU / 32.0) * radii).rotated(bean_angle))
		_paint_paw(bean, Color("f2b9c8"), Color("c58c9a"), 1.4)
	draw_set_transform(Vector2.ZERO, wiggle * 0.035, Vector2.ONE)


func _paw_union(base: Vector2, wrist: Vector2, sway: float, at: Vector2, rotation: float, squash: Vector2, curl: float) -> PackedVector2Array:
	var sole := PackedVector2Array()
	for point in _paw_sole(curl):
		sole.append(at + (point * squash).rotated(rotation))
	var arm := _forearm_polygon(base, wrist, sway)
	if arm.is_empty():
		return sole
	var unified := Geometry2D.merge_polygons(arm, sole)
	# The wrist endpoint is inside the sole, with a broad overlap at every pose.
	# Both inputs are solid simple polygons; their union is one outside contour.
	assert(unified.size() == 1, "The kitten forepaw must have one continuous silhouette.")
	return unified[0]


func _forearm_polygon(base: Vector2, wrist: Vector2, sway: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var axis := wrist - base
	if axis.length() < 34.0:
		# The entire short forearm is below the carton rim; omit it rather than
		# letting the two sides turn back across one another during withdrawal.
		return points
	var normal := Vector2(-axis.y, axis.x).normalized()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		var center := base.lerp(wrist, t) + normal * clampf(sway, -3.0, 3.0) * 0.75 * sin(t * PI)
		var width := lerpf(21.0, 23.0, smoothstep(0.0, 1.0, t))
		left.append(center - normal * width)
		right.append(center + normal * width)
	points.append_array(left)
	for i in range(right.size() - 1, -1, -1):
		points.append(right[i])
	# Both sides have strictly increasing projection along the same straight
	# axis. Their gentle sideways bend therefore cannot cross at any pose.
	return points


func _paw_sole(curl: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var toes := [-146.0, -108.0, -72.0, -34.0]
	for i in 120:
		var angle := -PI + i * TAU / 120.0
		var bump := 0.0
		for toe_angle: float in toes:
			var distance := absf(wrapf(angle - deg_to_rad(toe_angle), -PI, PI))
			bump += 4.5 * exp(-pow(distance / deg_to_rad(14.0), 4.0))
		var point := Vector2(cos(angle) * (30.5 + bump), 3.0 + sin(angle) * (34.0 + bump))
		if point.y < -10.0:
			point.y += (-point.y - 10.0) * clampf(curl, 0.0, 1.0) * 0.12
		points.append(point)
	return points


func _paw_pad() -> PackedVector2Array:
	# One soft cloud: high central dome, two broad low side lobes and a shallow
	# scallop in the bottom. It fills the lower half of the sole, not an oval dot.
	var points := PackedVector2Array([Vector2(0, -1)])
	_bezier(points, Vector2(-7, -1), Vector2(-9, 3), Vector2(-10, 7))
	_bezier(points, Vector2(-17, 4), Vector2(-23, 11), Vector2(-21, 18))
	_bezier(points, Vector2(-19, 27), Vector2(-9, 29), Vector2(-3, 26))
	_bezier(points, Vector2(-1, 25), Vector2(1, 25), Vector2(3, 26))
	_bezier(points, Vector2(9, 29), Vector2(19, 27), Vector2(21, 18))
	_bezier(points, Vector2(23, 11), Vector2(17, 4), Vector2(10, 7))
	_bezier(points, Vector2(9, 3), Vector2(7, -1), Vector2(0, -1))
	points.resize(points.size() - 1)
	for i in points.size():
		points[i] += Vector2(0, -4)
	return points


func _paint_paw(points: PackedVector2Array, fill: Color, outline: Color, width: float) -> void:
	draw_colored_polygon(points, fill)
	var contour := points.duplicate()
	contour.append(contour[0])
	draw_polyline(contour, outline, width, true)


func _bezier(points: PackedVector2Array, control_a: Vector2, control_b: Vector2, end: Vector2) -> void:
	var start := points[-1]
	for i in range(1, 11):
		var t := float(i) / 10.0
		var a := start.lerp(control_a, t)
		var b := control_a.lerp(control_b, t)
		var c := control_b.lerp(end, t)
		points.append(a.lerp(b, t).lerp(b.lerp(c, t), t))


func _draw_cat() -> void:
	if cat_texture == null or cat_rise <= 0.001:
		return
	var rise := clampf(cat_rise, 0.0, 1.0)
	var cat_size := Vector2(200, 188)
	var bottom := lerpf(72.0, -149.0, rise)
	var top := bottom - cat_size.y
	# Crop at the front rim before drawing: no body or feet can leak below the box.
	var visible_height := clampf(-146.0 - top, 0.0, cat_size.y)
	if visible_height <= 0.01:
		return
	var source_size := cat_texture.get_size()
	var source := Rect2(Vector2.ZERO, Vector2(source_size.x, source_size.y * visible_height / cat_size.y))
	draw_texture_rect_region(cat_texture, Rect2(Vector2(-cat_size.x / 2.0, top), Vector2(cat_size.x, visible_height)), source)


func _draw_front() -> void:
	_panel([FRONT_LEFT, FRONT_RIGHT, Vector2(130, -7), Vector2(123, 0), Vector2(-123, 0), Vector2(-130, -7)], BOARD, 6.0, 5.0)
	# The narrow right face and bottom fold explain the carton without shading it.
	_panel([Vector2(112, -147), Vector2(127, -147), Vector2(127, -8), Vector2(112, -3)], BOARD_SIDE, 0.0, 1.0)
	_line(Vector2(111, -138), Vector2(111, -15), SEAM, 3.0)
	_panel([Vector2(-16, -148), Vector2(16, -148), Vector2(16, -2), Vector2(-16, -2)], TAPE, 0.0, 1.5)
	# A torn tape end, two broad teeth, not scratch marks or a decorative border.
	_panel([Vector2(-16, -28), Vector2(-7, -23), Vector2(0, -29), Vector2(8, -23), Vector2(16, -28), Vector2(16, -2), Vector2(-16, -2)], Color("ecd09a"), 0.0, 1.0)
	_line(Vector2(-116, -13), Vector2(-31, -13), SEAM, 2.5)
	_line(Vector2(31, -13), Vector2(102, -13), SEAM, 2.5)
	# Printed paw delivery stamp: one calm shape with no tiny lettering.
	var stamp := Color("a47748")
	_ellipse(Vector2(-68, -74), Vector2(19, 14), stamp, 0.0)
	for toe: Vector2 in [Vector2(-88, -96), Vector2(-75, -106), Vector2(-60, -106), Vector2(-47, -96)]:
		_ellipse(toe, Vector2(6, 8), stamp, 0.0)
	_line(Vector2(53, -81), Vector2(53, -110), stamp, 4.0)
	_line(Vector2(78, -81), Vector2(78, -110), stamp, 4.0)
	for x in [53.0, 78.0]:
		_line(Vector2(x - 7, -102), Vector2(x, -111), stamp, 4.0)
		_line(Vector2(x, -111), Vector2(x + 7, -102), stamp, 4.0)
	# The front rim occludes the forearm and the lower portion of the cat.
	_line(Vector2(-124, -148), Vector2(124, -148), INK, 6.0)


func _panel(vertices: PackedVector2Array, fill: Color, width: float, radius: float, material_tint := true) -> void:
	var points := _rounded(vertices, radius)
	if points.size() < 3:
		return
	draw_colored_polygon(points, fill * tint if material_tint else fill)
	if width > 0.0:
		points.append(points[0])
		draw_polyline(points, INK, width, true)


func _line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(from, to, color, width, true)
	draw_circle(from, width * 0.5, color)
	draw_circle(to, width * 0.5, color)


func _ellipse(at: Vector2, radii: Vector2, fill: Color, width: float, material_tint := true) -> void:
	var points := PackedVector2Array()
	for i in 40:
		points.append(at + Vector2.from_angle(i * TAU / 40.0) * radii)
	_panel(points, fill, width, 0.0, material_tint)


func _rounded(vertices: PackedVector2Array, radius: float) -> PackedVector2Array:
	if radius <= 0.0:
		return vertices
	var points := PackedVector2Array()
	for i in vertices.size():
		var corner := vertices[i]
		var previous := vertices[(i - 1 + vertices.size()) % vertices.size()]
		var next := vertices[(i + 1) % vertices.size()]
		var before := corner.move_toward(previous, minf(radius, corner.distance_to(previous) * 0.2))
		var after := corner.move_toward(next, minf(radius, corner.distance_to(next) * 0.2))
		for j in 5:
			var t := float(j) / 4.0
			points.append(before.lerp(corner, t).lerp(corner.lerp(after, t), t))
	return points
