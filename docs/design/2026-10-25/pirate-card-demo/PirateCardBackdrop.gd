extends Control

## Review-only pirate identity card. Artwork stays behind the original portrait,
## level, class, stars and caption; the production page is unchanged.
const Economy = preload("res://game/core/Economy.gd")
const CANVAS := Vector2(160, 150)
const INK := Color("583f21")
const WOOD := Color("d7ae78")
const WOOD_LIGHT := Color("edcb92")
const WOOD_DARK := Color("bb8c59")
const WOOD_INK := Color("805c38")
const SKY := Color("c9eae2")
const SEA_LIGHT := Color("7bc9c6")

var rarity := 1:
	set(value):
		rarity = clampi(value, 0, 3)
		queue_redraw()

var fighting := false:
	set(value):
		fighting = value
		queue_redraw()

var compact := false
var contact_y := 106.0
var single_contact := false


func _init() -> void:
	name = "PirateCardBackdrop"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	draw_set_transform(Vector2.ZERO, 0, size / CANVAS)
	# The ship frame is painted by rarity. Its broad colour band stays legible
	# at four-column phone size, inside the same 4px structural brown contour.
	var rim: Color = Economy.RARITY_COLORS[rarity]
	_box(Rect2(2, 2, 156, 146), rim, 12)
	var upper := _style(rim.lightened(0.18), 10)
	upper.corner_radius_bottom_left = 0
	upper.corner_radius_bottom_right = 0
	draw_style_box(upper, Rect2(4, 4, 152, 20))
	_box(Rect2(13, 13, 134, 124), SKY, 5)

	# Broad calm areas read at the native four-column card size.
	_cloud(Vector2(105, 30))
	# Sea horizon is level and shares the deck's eye-height / vanishing y.
	var sea := _style(SEA_LIGHT, 5)
	sea.corner_radius_top_left = 0
	sea.corner_radius_top_right = 0
	draw_style_box(sea, Rect2(13, 60, 134, 77))
	_pirate_mast()
	_ship_deck()
	# The entire boat fits inside the scene. Stars and name remain overlays
	# at the frame foot; there is no separate footer or oversized deck panel.

	# An inner structural edge contains the scene; equipment state never
	# replaces the rarity paint. No shadows or extra fine decoration.
	var inner_edge := _style(Color.TRANSPARENT, 5)
	inner_edge.draw_center = false
	inner_edge.border_color = INK
	inner_edge.set_border_width_all(2)
	draw_style_box(inner_edge, Rect2(13, 13, 134, 124))
	var edge := _style(Color.TRANSPARENT, 12)
	edge.draw_center = false
	edge.border_color = INK
	edge.set_border_width_all(4)
	draw_style_box(edge, Rect2(2, 2, 156, 146))


func _ship_deck() -> void:
	# A closed hull, rather than an edge-to-edge fragment of a larger ship.
	# Both stern (22,85) and bow (138,76), including their strokes, fit inside
	# the inner frame with visible breathing room.
	var rear_rim := _curve(Vector2(22, 85), Vector2(60, 99), Vector2(111, 98), Vector2(138, 76))
	var hull := rear_rim.duplicate()
	hull.append_array(_curve(Vector2(138, 76), Vector2(136, 103), Vector2(125, 121), Vector2(111, 126)))
	hull.append_array(_curve(Vector2(111, 126), Vector2(80, 133), Vector2(41, 125), Vector2(29, 108)))
	hull.append_array(_curve(Vector2(29, 108), Vector2(24, 99), Vector2(22, 91), Vector2(22, 85)))
	draw_colored_polygon(hull, WOOD)
	draw_polyline(hull, WOOD_INK, 4, true)
	# The deck has one continuous wood colour. Only its geometry and a pair
	# of subdued seams convey depth: no contrasting centre-plank trapezoid.
	var front_rim := _curve(Vector2(22, 85), Vector2(40, 118), Vector2(114, 123), Vector2(138, 76))
	var deck := rear_rim.duplicate()
	for i in range(front_rim.size() - 1, -1, -1):
		deck.append(front_rim[i])
	draw_colored_polygon(deck, WOOD)
	draw_line(Vector2(65, 96), Vector2(59, 108), WOOD_DARK, 2, true)
	draw_line(Vector2(96, 96), Vector2(103, 109), WOOD_DARK, 2, true)
	# One continuous rim turns around the two tips and closes the near side.
	var rim := rear_rim.duplicate()
	for i in range(front_rim.size() - 1, -1, -1):
		rim.append(front_rim[i])
	draw_polyline(rim, WOOD_INK, 5, true)
	draw_polyline(rim, WOOD_LIGHT, 2, true)
	# Contact hugs actual silhouette bottoms (105px feet / 106px robe),
	# not an arbitrary pedestal or an outlined circle under the character.
	if single_contact:
		_contact(Vector2(80, contact_y), 34)
	else:
		_contact(Vector2(64, contact_y), 18)
		_contact(Vector2(97, contact_y), 18)


func _contact(at: Vector2, width: float) -> void:
	var half := width * 0.5
	var footprint := PackedVector2Array([
		at + Vector2(-half, -0.6), at + Vector2(-half + 3, -1.2),
		at + Vector2(half - 3, -1.2), at + Vector2(half, -0.6),
		at + Vector2(half - 2, 1.0), at + Vector2(0, 1.6),
		at + Vector2(-half + 2, 1.0),
	])
	draw_colored_polygon(footprint, Color(0.39, 0.25, 0.12, 0.35))


func _pirate_mast() -> void:
	# One unmistakable pirate flag. The small pale sail was removed because
	# at roster size it read as a second flag instead of a ship sail.
	draw_line(Vector2(29, 20), Vector2(29, 96), WOOD_INK, 7, true)
	draw_line(Vector2(29, 21), Vector2(29, 95), WOOD, 3, true)
	# The black pirate flag is a single high-contrast motif, not trim.
	var flag := PackedVector2Array([
		Vector2(32, 21), Vector2(64, 21), Vector2(60, 31),
		Vector2(64, 41), Vector2(32, 41), Vector2(32, 21),
	])
	var flag_color := Color("3e4845")
	draw_colored_polygon(flag, flag_color)
	draw_polyline(flag, INK, 2.5, true)
	var ivory := Color("fff0cf")
	draw_line(Vector2(39, 26), Vector2(55, 37), ivory, 2, true)
	draw_line(Vector2(39, 37), Vector2(55, 26), ivory, 2, true)
	draw_circle(Vector2(47, 29), 5, ivory)
	draw_rect(Rect2(44, 32, 6, 4), ivory)
	draw_circle(Vector2(45, 29), 1.3, flag_color)
	draw_circle(Vector2(49, 29), 1.3, flag_color)


func _cloud(at: Vector2) -> void:
	var color := Color("e5f3e7")
	draw_circle(at + Vector2(-9, 2), 5, color)
	draw_circle(at + Vector2(-1, -2), 7, color)
	draw_circle(at + Vector2(8, 1), 5, color)
	draw_rect(Rect2(at + Vector2(-9, 0), Vector2(17, 7)), color)


func _box(rect: Rect2, color: Color, radius: int) -> void:
	draw_style_box(_style(color, radius), rect)


func _style(color: Color, radius: int) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.set_corner_radius_all(radius)
	result.anti_aliasing = true
	return result


func _curve(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(25):
		var t := float(i) / 24.0
		var inverse := 1.0 - t
		points.append(inverse * inverse * inverse * a + 3 * inverse * inverse * t * b + 3 * inverse * t * t * c + t * t * t * d)
	return points
