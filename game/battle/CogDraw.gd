extends RefCounted

# Chunky flat disks with short broad teeth and an inset rim, in the cats' palette.
const LINE := Color("583f21")
const COG_DESIGN_OUTER := 54.0
const PIN_INK_OUTSET := 1.0
const COGS := {
	"ead5ac": preload("res://game/ui/skin/battle_cog_tier_1.svg"),
	"80bfd7": preload("res://game/ui/skin/battle_cog_tier_2.svg"),
	"b49cd6": preload("res://game/ui/skin/battle_cog_tier_3.svg"),
	"eead6c": preload("res://game/ui/skin/battle_cog_tier_4.svg"),
	"aec778": preload("res://game/ui/skin/battle_cog_tier_5.svg"),
	"aaa995": preload("res://game/ui/skin/battle_cog_idle.svg"),
}

static func draw_cog(ci: CanvasItem, center: Vector2, outer: float, _inner: float, _teeth: int, angle: float, fill: Color, _rim: Color) -> void:
	var texture: Texture2D = COGS.get(fill.to_html(false), COGS["aaa995"])
	var size := outer * 128.0 / COG_DESIGN_OUTER
	ci.draw_set_transform(center, angle)
	ci.draw_texture_rect(texture, Rect2(Vector2(-size, -size) * 0.5, Vector2(size, size)), false)
	ci.draw_set_transform(Vector2.ZERO)


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
	ci.draw_colored_polygon(arm, Color("e7a957"))
	ci.draw_polyline(outline, LINE, 3.0, true)
	ci.draw_circle(tip, tip_radius + PIN_INK_OUTSET, LINE)
	ci.draw_circle(tip, tip_radius - 1.0, Color("f6ce66"))
	ci.draw_circle(center, radius + 2.0, LINE)
	ci.draw_circle(center, radius - 2.0, Color("f6ce66"))
	ci.draw_arc(center, radius * 0.72, 0.0, TAU, 48, LINE, 2.5, true)
	# A quiet paw medallion ties the drive to the cats; it stays upright as the pin turns.
	var paw_scale := radius / 30.0
	ci.draw_circle(center + Vector2(0, 5) * paw_scale, 7.0 * paw_scale, LINE)
	for toe in [Vector2(-10, -4), Vector2(0, -10), Vector2(10, -4)]:
		ci.draw_circle(center + toe * paw_scale, 4.0 * paw_scale, LINE)
