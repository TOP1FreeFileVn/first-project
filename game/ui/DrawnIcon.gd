extends Control

# Small icons the art pack doesn't have (gem, padlock, alert dot, chest, crown, gift,
# quest scroll, event flag, summon portal), drawn as polygons.

const ChestArt = preload("res://game/ui/ChestArt.gd")

enum Kind { GEM, LOCK, DOT, CHEST, CROWN, GIFT, SCROLL, FLAG, PORTAL, SHARD }

var kind := Kind.GEM
## Body colour for CHEST, crystal colour for SHARD.
var tint := Color("a0673a")


static func draw_gem(ci: CanvasItem, center: Vector2, radius: float) -> void:
	var top := center + Vector2(0, -radius)
	var bottom := center + Vector2(0, radius)
	var left := center + Vector2(-radius * 0.85, -radius * 0.25)
	var right := center + Vector2(radius * 0.85, -radius * 0.25)
	ci.draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), Color("4fd6e8"))
	ci.draw_colored_polygon(PackedVector2Array([top, center + Vector2(0, -radius * 0.25), left]), Color("b6f4fb"))
	ci.draw_colored_polygon(PackedVector2Array([right, bottom, center + Vector2(0, -radius * 0.25)]), Color("2b93b8"))
	ci.draw_polyline(PackedVector2Array([top, right, bottom, left, top]), Color("123447"), 2.0, true)


static func draw_lock(ci: CanvasItem, center: Vector2, size: float) -> void:
	var body := Rect2(center + Vector2(-size * 0.4, -size * 0.05), Vector2(size * 0.8, size * 0.6))
	ci.draw_arc(center + Vector2(0, -size * 0.05), size * 0.26, PI, TAU, 16, Color("2a2f33"), size * 0.16, true)
	ci.draw_arc(center + Vector2(0, -size * 0.05), size * 0.26, PI, TAU, 16, Color("c9cfd4"), size * 0.08, true)
	ci.draw_rect(body, Color("2a2f33"))
	ci.draw_rect(body.grow(-size * 0.06), Color("e8b93c"))
	ci.draw_circle(body.get_center() + Vector2(0, -size * 0.04), size * 0.08, Color("3b2b1e"))


## Gold crown with three points, sitting on `base` (bottom centre).
static func draw_crown(ci: CanvasItem, base: Vector2, width: float) -> void:
	var h := width * 0.62
	var l := base.x - width / 2.0
	var points := PackedVector2Array([
		Vector2(l, base.y), Vector2(l, base.y - h * 0.55), Vector2(l + width * 0.25, base.y - h * 0.3),
		Vector2(base.x, base.y - h), Vector2(l + width * 0.75, base.y - h * 0.3), Vector2(l + width, base.y - h * 0.55),
		Vector2(l + width, base.y)])
	var outline := points.duplicate()
	outline.append(points[0])
	ci.draw_colored_polygon(points, Color("ffc93c"))
	ci.draw_rect(Rect2(l, base.y - h * 0.22, width, h * 0.22), Color("e09a1a"))
	ci.draw_polyline(outline, Color("3b2b1e"), maxf(1.5, width * 0.07), true)
	ci.draw_circle(Vector2(base.x, base.y - h * 0.11), width * 0.08, Color("e0405a"))


static func draw_chest(ci: CanvasItem, center: Vector2, size: float, body: Color) -> void:
	# The chest is a bit taller below the seam than above, so the seam sits above centre.
	ChestArt.draw(ci, center - Vector2(0, size * 0.05), size, ChestArt.style_for(body))


const OUTLINE := Color("24170e")


static func _outlined(ci: CanvasItem, points: PackedVector2Array, fill: Color, width: float) -> void:
	var loop := points.duplicate()
	loop.append(points[0])
	ci.draw_polyline(loop, OUTLINE, width, true)
	ci.draw_colored_polygon(points, fill)


static func _box(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])


## Red gift box with a gold ribbon and bow.
static func draw_gift(ci: CanvasItem, c: Vector2, r: float) -> void:
	var w := r * 0.12
	var body := Rect2(c + Vector2(-r * 0.8, -r * 0.15), Vector2(r * 1.6, r * 0.95))
	var lid := Rect2(c + Vector2(-r * 0.92, -r * 0.45), Vector2(r * 1.84, r * 0.34))
	_outlined(ci, _box(body), Color("d9434f"), w)
	ci.draw_rect(Rect2(body.position + Vector2(body.size.x * 0.62, 0), Vector2(body.size.x * 0.38, body.size.y)), Color("a92f3c"))
	_outlined(ci, _box(lid), Color("ee5a64"), w)
	ci.draw_rect(Rect2(c + Vector2(-r * 0.15, -r * 0.45), Vector2(r * 0.3, r * 1.25)), Color("ffcc4d"))
	ci.draw_rect(Rect2(c + Vector2(-r * 0.15, -r * 0.45), Vector2(r * 0.08, r * 1.25)), Color("fff0a8"))
	for side in [-1, 1]:
		var loop := PackedVector2Array([c + Vector2(0, -r * 0.47), c + Vector2(side * r * 0.62, -r * 0.95), c + Vector2(side * r * 0.72, -r * 0.62)])
		_outlined(ci, loop, Color("ffcc4d"), w)
	ci.draw_circle(c + Vector2(0, -r * 0.5), r * 0.16, OUTLINE)
	ci.draw_circle(c + Vector2(0, -r * 0.5), r * 0.1, Color("ffcc4d"))


## Parchment scroll with a red seal: quests.
static func draw_scroll(ci: CanvasItem, c: Vector2, r: float) -> void:
	var w := r * 0.12
	var sheet := Rect2(c + Vector2(-r * 0.62, -r * 0.8), Vector2(r * 1.24, r * 1.55))
	_outlined(ci, _box(sheet), Color("f4dfb0"), w)
	for i in 4:
		var y := sheet.position.y + r * (0.35 + i * 0.28)
		ci.draw_line(Vector2(sheet.position.x + r * 0.2, y), Vector2(sheet.end.x - r * (0.2 if i < 3 else 0.6), y), Color("b08a5a"), maxf(1.5, r * 0.08))
	for y in [sheet.position.y, sheet.end.y]:
		var roll := Rect2(Vector2(sheet.position.x - r * 0.14, y - r * 0.13), Vector2(sheet.size.x + r * 0.28, r * 0.26))
		_outlined(ci, _box(roll), Color("d9b77a"), w)
	ci.draw_circle(c + Vector2(r * 0.38, r * 0.5), r * 0.24, OUTLINE)
	ci.draw_circle(c + Vector2(r * 0.38, r * 0.5), r * 0.18, Color("d9434f"))


## A waving banner with a star: events.
static func draw_flag(ci: CanvasItem, c: Vector2, r: float) -> void:
	var w := r * 0.12
	var pole := Rect2(c + Vector2(-r * 0.72, -r * 0.92), Vector2(r * 0.14, r * 1.84))
	_outlined(ci, _box(pole), Color("8a5a32"), w)
	ci.draw_circle(pole.position + Vector2(r * 0.07, 0), r * 0.13, Color("ffcc4d"))
	var cloth := PackedVector2Array()
	var top := -r * 0.8
	for i in 9:
		var x := -r * 0.58 + r * 1.4 * i / 8.0
		cloth.append(c + Vector2(x, top + sin(i / 8.0 * PI * 1.6) * r * 0.1))
	for i in 9:
		var x := r * 0.82 - r * 1.4 * i / 8.0
		cloth.append(c + Vector2(x, top + r * 0.95 + sin((8 - i) / 8.0 * PI * 1.6) * r * 0.1))
	_outlined(ci, cloth, Color("3f7fd9"), w)
	var star := PackedVector2Array()
	var center := c + Vector2(r * 0.12, top + r * 0.48)
	for i in 10:
		var radius := r * (0.3 if i % 2 == 0 else 0.13)
		star.append(center + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * radius)
	ci.draw_colored_polygon(star, Color("ffcc4d"))


## A glowing purple summoning ring with a star: hero summon.
static func draw_portal(ci: CanvasItem, c: Vector2, r: float, time := 0.0) -> void:
	ci.draw_circle(c, r * 0.95, OUTLINE)
	ci.draw_circle(c, r * 0.86, Color("5b2b8f"))
	ci.draw_circle(c, r * 0.62, Color("8f4fd6"))
	ci.draw_circle(c, r * 0.38, Color("d9b3ff"))
	ci.draw_arc(c, r * 0.74, time, time + PI * 1.3, 24, Color("ffe07a"), r * 0.1, true)
	ci.draw_arc(c, r * 0.74, time + PI, time + PI * 1.5, 12, Color("ffffff"), r * 0.06, true)
	var star := PackedVector2Array()
	for i in 8:
		var radius := r * (0.3 if i % 2 == 0 else 0.1)
		star.append(c + Vector2.from_angle(i * PI / 4.0) * radius)
	ci.draw_colored_polygon(star, Color.WHITE)


## A hero shard: a small faceted crystal in `color`.
static func draw_shard(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.55, -r * 0.2), c + Vector2(r * 0.3, r * 0.9),
		c + Vector2(-r * 0.3, r * 0.9), c + Vector2(-r * 0.55, -r * 0.2)])
	_outlined(ci, points, color, maxf(1.5, r * 0.14))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.55, -r * 0.2), c + Vector2(0, r * 0.1)]), color.lightened(0.45))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, r * 0.1), c + Vector2(r * 0.3, r * 0.9), c + Vector2(-r * 0.3, r * 0.9)]), color.darkened(0.3))


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	match kind:
		Kind.GEM:
			draw_gem(self, c, r * 0.9)
		Kind.LOCK:
			draw_lock(self, c, r * 1.6)
		Kind.DOT:
			draw_circle(c, r, Color("1b2a33"))
			draw_circle(c, r * 0.75, Color("ff4b4b"))
		Kind.CHEST:
			draw_chest(self, c, r * 1.8, tint)
		Kind.CROWN:
			draw_crown(self, c + Vector2(0, r * 0.6), r * 1.8)
		Kind.GIFT:
			draw_gift(self, c + Vector2(0, r * 0.1), r)
		Kind.SCROLL:
			draw_scroll(self, c, r)
		Kind.FLAG:
			draw_flag(self, c, r)
		Kind.PORTAL:
			draw_portal(self, c, r, Time.get_ticks_msec() / 400.0)
			queue_redraw()
		Kind.SHARD:
			draw_shard(self, c, r * 0.9, tint)
