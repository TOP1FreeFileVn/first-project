extends Control

## The team's open courtyard: scenery only, with the troop slots drawn above it.
## Layout in 672 x 320 units: cat feet at y226; captions and toggles below that.
## The shared castle keeps the same upgrade tiers and waving flags as the lobby.
const CastleTiers := preload("res://game/menu/lobby/CastleTiers.gd")
const CANVAS := Vector2(672, 320)
const SKY_COLOR := Color("c5e5e9")
const CASTLE_SCALE := 0.43
const CASTLE_GATE := Vector2(336, 170)

var _castle: Node2D
var _castle_level := -1


func _init() -> void:
	name = "FormationMeadow"
	custom_minimum_size = Vector2(0, CANVAS.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _ready() -> void:
	_castle = CastleTiers.new()
	_castle.name = "FormationCardboardCastle"
	# The distant castle stays quieter than the four foreground silhouettes.
	_castle.modulate = Color(0.96, 0.99, 0.91)
	add_child(_castle)
	resized.connect(_fit)
	PlayerData.changed.connect(sync_castle_level)
	_fit()
	sync_castle_level()


func sync_castle_level() -> void:
	set_castle_level(PlayerData.castle_level)


func set_castle_level(level: int) -> void:
	if _castle == null or level == _castle_level:
		return
	_castle_level = level
	_castle.set_level(level)


func _fit() -> void:
	if _castle != null:
		var fit := size / CANVAS
		_castle.scale = Vector2.ONE * CASTLE_SCALE * minf(fit.x, fit.y)
		_castle.position = CASTLE_GATE * fit - CastleTiers.GATE_FOOT * _castle.scale
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, size / CANVAS)
	# The page owns this scenery behind its scroll content, flush to the top and sides.
	draw_rect(Rect2(Vector2.ZERO, CANVAS), Color("c3d8a8"))
	# Sky reaches beneath the rolling horizon so there is no exposed blue seam.
	draw_rect(Rect2(0, 0, CANVAS.x, 170), SKY_COLOR)
	_cloud(Vector2(104, 57), 0.80)
	_cloud(Vector2(557, 74), 0.70)
	# Broad, soft-edged silhouettes connect the stage to the page's green field.
	# There is no enclosing board, rectangular border or individual cat platform.
	var rear := _bezier(Vector2(0, 151), Vector2(110, 96), Vector2(182, 134), Vector2(286, 124))
	rear.append_array(_bezier(Vector2(286, 124), Vector2(413, 102), Vector2(490, 90), Vector2(672, 121)))
	rear.append_array(PackedVector2Array([Vector2(672, 247), Vector2(0, 247)]))
	draw_colored_polygon(rear, Color("b3ce97"))

	var lawn := _bezier(Vector2(0, 188), Vector2(107, 166), Vector2(153, 151), Vector2(259, 167))
	lawn.append_array(_bezier(Vector2(259, 167), Vector2(428, 191), Vector2(528, 139), Vector2(672, 159)))
	lawn.append_array(PackedVector2Array([Vector2(672, 261), Vector2(0, 261)]))
	draw_colored_polygon(lawn, Color("a9c987"))
	# Fade into the existing troops backdrop before the names and controls.
	draw_polygon(PackedVector2Array([
		Vector2(0, 260), Vector2(672, 260), Vector2(672, 302), Vector2(0, 302),
	]), PackedColorArray([
		Color("a9c987"), Color("a9c987"), Color(0.663, 0.788, 0.529, 0), Color(0.663, 0.788, 0.529, 0),
	]))
	# A short footpath belongs to the gate, behind the cats rather than under all four.
	var path := _bezier(Vector2(528, 165), Vector2(520, 182), Vector2(512, 188), Vector2(486, 204))
	path.append_array(_bezier(Vector2(486, 204), Vector2(484, 208), Vector2(496, 209), Vector2(514, 205)))
	path.append_array(_bezier(Vector2(514, 205), Vector2(540, 190), Vector2(560, 184), Vector2(569, 166)))
	for i in path.size():
		path[i].x += CASTLE_GATE.x - 548.0
	draw_colored_polygon(path, Color("cfbf8e"))
	# Sparse grass, kept away from the faces and the text below their feet.
	for tuft in [Vector2(18, 206), Vector2(153, 227), Vector2(324, 217), Vector2(483, 231), Vector2(651, 211)]:
		_grass(tuft, Color("82a965"))
	for tuft in [Vector2(43, 145), Vector2(213, 154), Vector2(391, 144), Vector2(647, 142)]:
		_grass(tuft, Color("9abb7c"), 0.75)
	draw_set_transform(Vector2.ZERO)


func _cloud(at: Vector2, amount: float) -> void:
	var edge := _bezier(Vector2(-52, 10), Vector2(-62, -9), Vector2(-37, -28), Vector2(-20, -15))
	edge.append_array(_bezier(Vector2(-20, -15), Vector2(-18, -43), Vector2(18, -39), Vector2(25, -17)))
	edge.append_array(_bezier(Vector2(25, -17), Vector2(46, -25), Vector2(67, -5), Vector2(55, 10)))
	edge.append_array(_bezier(Vector2(55, 10), Vector2(32, 17), Vector2(-29, 17), Vector2(-52, 10)))
	for i in edge.size():
		edge[i] = at + edge[i] * amount
	draw_colored_polygon(edge, Color(1.0, 0.98, 0.91, 0.86))


func _grass(at: Vector2, color: Color, amount := 1.0) -> void:
	draw_polyline(PackedVector2Array([
		at + Vector2(-8, -5) * amount, at, at + Vector2(3, -11) * amount,
	]), color, 2.5 * amount, true)
	draw_line(at, at + Vector2(10, -6) * amount, color, 2.5 * amount, true)


func _bezier(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 21:
		var t := float(i) / 20.0
		var u := 1.0 - t
		points.append(a * u * u * u + b * 3.0 * u * u * t + c * 3.0 * u * t * t + d * t * t * t)
	return points
