extends RefCounted

# Selected B strongboxes. Source-preserving raster layers share one seam frame;
# the body and lock stay fixed while the actual lid moves independently.
const Metadata = preload("res://game/ui/art/chests/strongbox-b/assets.gd")
const ASSET_ROOT := "res://game/ui/art/chests/strongbox-b/"
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
const AUTHOR_WIDTH := 208.0
static var _textures: Dictionary = {}


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


static func asset_for(kind: String) -> Dictionary:
	return Metadata.DATA["tiers"][kind]


static func textures_for(kind: String) -> Dictionary:
	if not _textures.has(kind):
		var layers: Dictionary = {}
		for layer in ["closed", "body", "lid", "latch"]:
			layers[layer] = load(ASSET_ROOT + kind + "/" + layer + ".png")
		_textures[kind] = layers
	return _textures[kind]


## seam and offset remain in caller coordinates; rotation remains radians.
## Closed art uses the intact source; opening uses its aligned extracted parts.
static func draw(ci: CanvasItem, seam: Vector2, w: float, style: Dictionary, alpha := 1.0,
		lid_offset := Vector2.ZERO, lid_rotation := 0.0, lid_alpha := 1.0, mouth := Color(0, 0, 0, 0)) -> void:
	if w <= 0.0 or alpha <= 0.0:
		return
	var opened := mouth.a > 0.0 or lid_offset.length_squared() > 0.001 or absf(lid_rotation) > 0.001 or lid_alpha < 0.999
	var kind: String = style.get("kind", "wood")
	var data := asset_for(kind)
	var layers := textures_for(kind)
	var values: Array = data["texture_rect"]
	var frame := Rect2(values[0], values[1], values[2], values[3])
	var tint := Color(1.0, 1.0, 1.0, alpha)
	var scale := Vector2.ONE * (w / AUTHOR_WIDTH)
	# DrawnIcon also appears on standalone CanvasItems outside Home's filtering.
	if ci.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR:
		ci.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ci.draw_set_transform(seam, 0.0, scale)
	if not opened:
		ci.draw_texture_rect(layers["closed"], frame, false, tint)
	else:
		_draw_mouth(ci, data, style, alpha, mouth)
		ci.draw_texture_rect(layers["body"], frame, false, tint)
		# Complete the newly exposed body rim; the fixed clasp occludes its centre.
		var rim_width: float = data["main_width"]
		ci.draw_line(Vector2(-AUTHOR_WIDTH * 0.48, 0), Vector2(AUTHOR_WIDTH * 0.48, 0),
			Color(INK, alpha), rim_width, true)
		if lid_alpha > 0.0:
			ci.draw_set_transform(seam + lid_offset, lid_rotation, scale)
			ci.draw_texture_rect(layers["lid"], frame, false, Color(1, 1, 1, alpha * lid_alpha))
		ci.draw_set_transform(seam, 0.0, scale)
		ci.draw_texture_rect(layers["latch"], frame, false, tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_mouth(ci: CanvasItem, data: Dictionary, style: Dictionary,
		alpha: float, light: Color) -> void:
	var values: Array = data["cavity_rect"]
	var rect := Rect2(values[0], values[1], values[2], values[3])
	var rim := StyleBoxFlat.new()
	rim.bg_color = Color(INK, alpha)
	rim.set_corner_radius_all(12)
	rim.anti_aliasing = true
	ci.draw_style_box(rim, rect)
	var inside := StyleBoxFlat.new()
	var cavity: Color = style["cavity"]
	inside.bg_color = Color(cavity.lerp(Color(light, 1.0), light.a), alpha)
	inside.set_corner_radius_all(8)
	inside.anti_aliasing = true
	ci.draw_style_box(inside, rect.grow(-float(data["main_width"])))
