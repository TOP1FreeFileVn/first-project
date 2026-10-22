extends RefCounted

# Approved low-lid chest: broad flat boards, brass corner shoes and a cat latch.
# Native draw data is exported from the exact canvas proposal, never reauthored.
const Paths = preload("res://game/ui/art_sources/ChestPaths.gd")
const INK := Color("583f21")
const STYLES := {
	"wood": {"kind": "wood", "body": Color("eca966"), "dark": Color("d88f4f"), "light": Color("eca966"), "inset": Color("f3b879"),
		"band": Color("f3c56b"), "band_light": Color("f3c56b"), "band_ink": Color("ba853c"),
		"grain": Color("b87941"), "surface": Color("b87941"), "band_fold": Color("dca743"), "cavity": Color("704c2c"),
		"paw": Color("ba853c"), "planks": true, "gem": false},
	"silver": {"kind": "silver", "body": Color("8ec4da"), "dark": Color("72abc4"), "light": Color("8ec4da"), "inset": Color("add7e3"),
		"band": Color("dce5dd"), "band_light": Color("dce5dd"), "band_ink": Color("8ba4a0"),
		"grain": Color("6097ae"), "surface": Color("6097ae"), "band_fold": Color("b8cbc7"), "cavity": Color("547c8d"),
		"paw": Color("8ba4a0"), "planks": false, "gem": false},
	"gold": {"kind": "gold", "body": Color("f28c77"), "dark": Color("da705e"), "light": Color("f28c77"), "inset": Color("f59c83"),
		"band": Color("ffd16a"), "band_light": Color("ffd16a"), "band_ink": Color("c99740"),
		"grain": Color("bf6551"), "surface": Color("bf6551"), "band_fold": Color("eab64e"), "cavity": Color("965749"),
		"paw": Color("c99740"), "planks": false, "gem": false},
}
# Existing reward and shop tints still select the same tiers.
const TINTS := {"wood": Color("a0673a"), "silver": Color("aeb8c2"), "gold": Color("e8b93c")}
const BASE_H := 88.0 / 208.0
const LID_H := 62.0 / 208.0
const AUTHOR_WIDTH := 208.0
static var _geometry: Dictionary = {}


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


## seam and offset remain in caller coordinates; rotation remains radians.
## Body and latch stay fixed; lid and its corner caps share one flight transform.
static func draw(ci: CanvasItem, seam: Vector2, w: float, style: Dictionary, alpha := 1.0,
		lid_offset := Vector2.ZERO, lid_rotation := 0.0, lid_alpha := 1.0, mouth := Color(0, 0, 0, 0)) -> void:
	if w <= 0.0 or alpha <= 0.0:
		return
	var opened := mouth.a > 0.0 or lid_offset.length_squared() > 0.001 or absf(lid_rotation) > 0.001 or lid_alpha < 0.999
	var tier := "gold_" if style.get("kind", "wood") == "gold" else "basic_"
	var key := tier + ("small" if w < 48.0 else "full") + ("_open" if opened else "_closed")
	var layers := _layers(key)
	var scale := Vector2.ONE * (w / AUTHOR_WIDTH)
	ci.draw_set_transform(seam, 0.0, scale)
	if opened:
		_draw_layer(ci, layers["mouth"], style, alpha, mouth)
	_draw_layer(ci, layers["body"], style, alpha)
	if lid_alpha > 0.0:
		ci.draw_set_transform(seam + lid_offset, lid_rotation, scale)
		_draw_layer(ci, layers["lid"], style, alpha * lid_alpha)
	ci.draw_set_transform(seam, 0.0, scale)
	_draw_layer(ci, layers["latch"], style, alpha)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _layers(key: String) -> Dictionary:
	if _geometry.has(key):
		return _geometry[key]
	var layers: Dictionary = {}
	for layer in Paths.DATA[key]:
		var ops: Array = []
		for source in Paths.DATA[key][layer]:
			var op: Dictionary = source.duplicate()
			for field in ["points", "joins"]:
				var points := PackedVector2Array()
				for point in source[field]:
					points.append(Vector2(point[0], point[1]))
				op[field] = points
			ops.append(op)
		layers[layer] = ops
	_geometry[key] = layers
	return layers


static func _ink(style: Dictionary, role: String, alpha: float) -> Color:
	return Color(INK if role == "ink" else style[role], alpha)


static func _draw_layer(ci: CanvasItem, ops: Array, style: Dictionary, alpha: float,
		fill_overlay := Color(0, 0, 0, 0)) -> void:
	for op in ops:
		if (op["fill"] == "grain" or op["stroke"] == "grain") and not style["planks"]:
			continue
		var points: PackedVector2Array = op["points"]
		if not op["fill"].is_empty():
			ci.draw_colored_polygon(points, _ink(style, op["fill"], alpha))
			if fill_overlay.a > 0.0:
				# Animation light stays behind the exposed opening's main contour.
				ci.draw_colored_polygon(points, Color(fill_overlay, fill_overlay.a * alpha))
		if not op["stroke"].is_empty():
			var ink := _ink(style, op["stroke"], alpha)
			var width: float = op["width"]
			ci.draw_polyline(points, ink, width, true)
			# Godot polylines use sharp joins; authored joins/caps are rounded.
			for point in op["joins"]:
				ci.draw_circle(point, width * 0.5, ink, true, -1.0, true)
