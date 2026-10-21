extends RefCounted

# Treasure chests drawn in code, one look per chest kind: a plank wood chest with iron
# bands, a steel-blue chest with silver bands, and a royal red chest with gold bands and a
# gem. Everything is drawn around the seam (where the lid meets the base) so the lid can
# fly off on its own. Shared by the shop icons and the full-screen chest opening.

const INK := Color("24170e")
const STYLES := {
	"wood": {"body": Color("a86a3c"), "dark": Color("6e4125"), "light": Color("d9985c"),
		"band": Color("59616b"), "band_light": Color("a4adb8"), "planks": true, "gem": false},
	"silver": {"body": Color("4d78a8"), "dark": Color("2c4a72"), "light": Color("86b0dc"),
		"band": Color("c8d2dc"), "band_light": Color("ffffff"), "planks": false, "gem": false},
	"gold": {"body": Color("b3313a"), "dark": Color("721a25"), "light": Color("e8676a"),
		"band": Color("f0b93a"), "band_light": Color("fff1a6"), "planks": false, "gem": true},
}
# The colours the shop used to tint each chest; style_for() maps a tint back to a kind.
const TINTS := {"wood": Color("a0673a"), "silver": Color("aeb8c2"), "gold": Color("e8b93c")}

## Base height and lid height, as fractions of the chest width.
const BASE_H := 0.46
const LID_H := 0.32


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


## Draws a whole chest of width `w` with its seam at `seam`. The lid is drawn moved by
## `lid_offset` and turned by `lid_rotation` around the seam; `mouth` (if not transparent)
## lights the open chest from inside.
static func draw(ci: CanvasItem, seam: Vector2, w: float, style: Dictionary, alpha := 1.0,
		lid_offset := Vector2.ZERO, lid_rotation := 0.0, lid_alpha := 1.0, mouth := Color(0, 0, 0, 0)) -> void:
	_draw_base(ci, seam, w, style, alpha)
	var open := mouth.a > 0.0
	if open:
		# Seen from the front, the open chest shows a thin strip of its inside above the
		# front edge: the back wall, lit by whatever is glowing in there.
		var depth := w * 0.1
		var inside := Rect2(seam + Vector2(-w / 2.0, -depth), Vector2(w, depth))
		ci.draw_rect(inside.grow(w * 0.018), Color(INK, alpha))
		ci.draw_rect(inside, _c(style, "dark", alpha).darkened(0.3))
		var lit := Rect2(seam + Vector2(-w * 0.44, -depth * 0.8), Vector2(w * 0.88, depth * 0.8))
		ci.draw_rect(lit, Color(mouth, mouth.a * alpha))
		ci.draw_rect(Rect2(seam + Vector2(-w * 0.3, -depth * 0.8), Vector2(w * 0.6, depth * 0.8)), Color(mouth.lightened(0.6), mouth.a * alpha))
		# The front edge of the box.
		ci.draw_rect(Rect2(seam + Vector2(-w / 2.0, -w * 0.012), Vector2(w, w * 0.03)), _c(style, "band", alpha))
	if lid_alpha > 0.0:
		ci.draw_set_transform(seam + lid_offset, lid_rotation, Vector2.ONE)
		_draw_lid(ci, w, style, alpha * lid_alpha)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_lock(ci, seam, w, style, alpha, open)


static func _c(style: Dictionary, key: String, alpha: float) -> Color:
	return Color(style[key], alpha)


static func _draw_base(ci: CanvasItem, seam: Vector2, w: float, s: Dictionary, a: float) -> void:
	var bh := w * BASE_H
	var ink := Color(INK, a)
	# Ground shadow.
	ci.draw_set_transform(seam + Vector2(0, bh + w * 0.02), 0.0, Vector2(1.0, 0.18))
	ci.draw_circle(Vector2.ZERO, w * 0.62, Color(0, 0, 0, 0.35 * a))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var base := Rect2(seam + Vector2(-w / 2.0, 0), Vector2(w, bh))
	ci.draw_rect(base.grow(w * 0.018), ink)
	ci.draw_rect(base, _c(s, "body", a))
	# Light from the left, shade on the right and under the lid.
	ci.draw_rect(Rect2(base.position + Vector2(w * 0.7, 0), Vector2(w * 0.3, bh)), Color(s["dark"], 0.45 * a))
	ci.draw_rect(Rect2(base.position + Vector2(w * 0.05, bh * 0.22), Vector2(w * 0.05, bh * 0.6)), Color(s["light"], 0.7 * a))
	ci.draw_rect(Rect2(base.position, Vector2(w, bh * 0.16)), _c(s, "dark", a))
	if s["planks"]:
		for f in [0.45, 0.72]:
			var y: float = base.position.y + bh * f
			ci.draw_line(Vector2(base.position.x, y), Vector2(base.end.x, y), Color(s["dark"], 0.9 * a), maxf(1.5, w * 0.012))
	else:
		# A sunken panel between the bands.
		var inset := Rect2(base.position + Vector2(w * 0.1, bh * 0.28), Vector2(w * 0.8, bh * 0.5))
		ci.draw_rect(inset, Color(s["dark"], 0.35 * a))
		ci.draw_rect(Rect2(inset.position, Vector2(inset.size.x, maxf(1.5, w * 0.01))), Color(s["dark"], 0.8 * a))
	# Bottom rim.
	var rim := Rect2(base.position + Vector2(0, bh * 0.84), Vector2(w, bh * 0.16))
	ci.draw_rect(rim, _c(s, "band", a))
	ci.draw_rect(Rect2(rim.position, Vector2(w, maxf(1.5, w * 0.012))), _c(s, "band_light", a))
	ci.draw_line(rim.position, rim.position + Vector2(w, 0), ink, maxf(1.0, w * 0.008))
	# Vertical bands with rivets.
	for x in [-0.37, 0.23]:
		var band := Rect2(seam + Vector2(w * x, 0), Vector2(w * 0.14, bh))
		ci.draw_rect(band, _c(s, "band", a))
		ci.draw_rect(Rect2(band.position, Vector2(w * 0.03, bh)), _c(s, "band_light", a))
		ci.draw_line(band.position, band.position + Vector2(0, bh), ink, maxf(1.0, w * 0.008))
		ci.draw_line(band.position + Vector2(band.size.x, 0), band.end, ink, maxf(1.0, w * 0.008))
		for y in [0.3, 0.66]:
			_rivet(ci, band.position + Vector2(band.size.x / 2.0, bh * y), w * 0.022, s, a)


static func _dome_y(x: float, w: float, lh: float) -> float:
	# Straight sides, then a flattish top that only rounds off near the edges
	# (a superellipse rather than a half circle).
	var t := clampf(absf(x) / (w / 2.0), 0.0, 1.0)
	return -(lh * 0.6 + lh * 0.4 * pow(1.0 - pow(t, 3.0), 1.0 / 3.0))


static func _draw_lid(ci: CanvasItem, w: float, s: Dictionary, a: float) -> void:
	var lh := w * LID_H
	var ink := Color(INK, a)
	var shape := PackedVector2Array([Vector2(-w / 2.0, 0)])
	var steps := 24
	for i in steps + 1:
		var x := -w / 2.0 + w * i / steps
		shape.append(Vector2(x, _dome_y(x, w, lh)))
	shape.append(Vector2(w / 2.0, 0))
	var outline := shape.duplicate()
	outline.append(shape[0])
	ci.draw_polyline(outline, ink, w * 0.036, true)
	ci.draw_colored_polygon(shape, _c(s, "body", a))
	# Shade on the right half, a highlight along the upper left of the dome.
	var shade := PackedVector2Array([Vector2(w * 0.2, 0)])
	for i in 9:
		var x := w * 0.2 + w * 0.3 * i / 8.0
		shade.append(Vector2(x, _dome_y(x, w, lh)))
	shade.append(Vector2(w / 2.0, 0))
	ci.draw_colored_polygon(shade, Color(s["dark"], 0.45 * a))
	var shine := PackedVector2Array()
	for i in 9:
		var x := -w * 0.4 + w * 0.34 * i / 8.0
		shine.append(Vector2(x, _dome_y(x, w, lh) + lh * 0.14))
	ci.draw_polyline(shine, Color(s["light"], 0.9 * a), maxf(2.0, lh * 0.1), true)
	if s["planks"]:
		for f in [0.5]:
			var line := PackedVector2Array()
			for i in 13:
				var x := -w / 2.0 + w * i / 12.0
				line.append(Vector2(x, _dome_y(x, w, lh) * f))
			ci.draw_polyline(line, Color(s["dark"], 0.9 * a), maxf(1.5, w * 0.012), true)
	# Bands over the dome, matching the ones on the base.
	for x in [-0.37, 0.23]:
		var x0: float = w * x
		var x1: float = x0 + w * 0.14
		var band := PackedVector2Array([Vector2(x0, 0)])
		for i in 5:
			var bx: float = lerpf(x0, x1, i / 4.0)
			band.append(Vector2(bx, _dome_y(bx, w, lh)))
		band.append(Vector2(x1, 0))
		ci.draw_colored_polygon(band, _c(s, "band", a))
		ci.draw_line(Vector2(x0, 0), Vector2(x0, _dome_y(x0, w, lh)), ink, maxf(1.0, w * 0.008))
		ci.draw_line(Vector2(x1, 0), Vector2(x1, _dome_y(x1, w, lh)), ink, maxf(1.0, w * 0.008))
		ci.draw_line(Vector2(x0 + w * 0.015, -lh * 0.1), Vector2(x0 + w * 0.015, _dome_y(x0, w, lh) + lh * 0.08), _c(s, "band_light", a), w * 0.028)
		_rivet(ci, Vector2((x0 + x1) / 2.0, _dome_y((x0 + x1) / 2.0, w, lh) * 0.55), w * 0.022, s, a)
	# Lid rim.
	var rim := Rect2(Vector2(-w / 2.0, -lh * 0.2), Vector2(w, lh * 0.2))
	ci.draw_rect(rim, _c(s, "band", a))
	ci.draw_rect(Rect2(rim.position, Vector2(w, maxf(1.5, lh * 0.05))), _c(s, "band_light", a))
	ci.draw_line(rim.position, rim.position + Vector2(w, 0), ink, maxf(1.0, w * 0.008))
	if s["gem"]:
		_gem(ci, Vector2(0, -lh * 0.6), w * 0.075, a)


## Closed, the plate straddles the seam; open, only the hasp on the box is left.
static func _draw_lock(ci: CanvasItem, seam: Vector2, w: float, s: Dictionary, a: float, open := false) -> void:
	var ink := Color(INK, a)
	var top := 0.0 if open else -w * 0.07
	var plate := PackedVector2Array([
		seam + Vector2(-w * 0.1, top), seam + Vector2(w * 0.1, top),
		seam + Vector2(w * 0.1, w * 0.12), seam + Vector2(0, w * 0.2), seam + Vector2(-w * 0.1, w * 0.12)])
	var outline := plate.duplicate()
	outline.append(plate[0])
	ci.draw_polyline(outline, ink, w * 0.03, true)
	ci.draw_colored_polygon(plate, _c(s, "band", a))
	ci.draw_line(plate[0] + Vector2(w * 0.02, w * 0.02), plate[4] + Vector2(w * 0.02, -w * 0.01), _c(s, "band_light", a), maxf(1.5, w * 0.02))
	ci.draw_circle(seam + Vector2(0, w * 0.035), w * 0.03, ink)
	ci.draw_colored_polygon(PackedVector2Array([seam + Vector2(-w * 0.018, w * 0.04), seam + Vector2(w * 0.018, w * 0.04), seam + Vector2(0, w * 0.12)]), ink)


static func _rivet(ci: CanvasItem, at: Vector2, r: float, s: Dictionary, a: float) -> void:
	ci.draw_circle(at, r + 1.0, Color(INK, a))
	ci.draw_circle(at, r, _c(s, "band_light", a))
	ci.draw_circle(at + Vector2(r * 0.3, r * 0.3), r * 0.5, Color(s["band"], a))


static func _gem(ci: CanvasItem, at: Vector2, r: float, a: float) -> void:
	var top := at + Vector2(0, -r)
	var bottom := at + Vector2(0, r)
	var left := at + Vector2(-r * 0.85, -r * 0.2)
	var right := at + Vector2(r * 0.85, -r * 0.2)
	var shape := PackedVector2Array([top, right, bottom, left])
	var outline := shape.duplicate()
	outline.append(top)
	ci.draw_polyline(outline, Color(INK, a), maxf(2.0, r * 0.3), true)
	ci.draw_colored_polygon(shape, Color(Color("4fd6e8"), a))
	ci.draw_colored_polygon(PackedVector2Array([top, at + Vector2(0, -r * 0.2), left]), Color(Color("d4fbff"), a))
	ci.draw_colored_polygon(PackedVector2Array([right, bottom, at + Vector2(0, -r * 0.2)]), Color(Color("2b8fb8"), a))
