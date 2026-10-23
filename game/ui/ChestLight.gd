extends RefCounted

## Soft illustrated light shared by the chest seam, opening and reward reveal.
## These white masks are generated once; callers supply their own warm tint.
const WARM := Color("ffe5a6")

static var _glow_texture: Texture2D
static var _shaft_texture: Texture2D


static func glow(canvas: CanvasItem, at: Vector2, radius: Vector2, color: Color, alpha: float) -> void:
	if radius.x <= 0.0 or radius.y <= 0.0 or alpha <= 0.0 or color.a <= 0.0:
		return
	if _glow_texture == null:
		_glow_texture = _make_glow_texture()
	var tint := color
	tint.a *= clampf(alpha, 0.0, 1.0)
	canvas.draw_texture_rect(_glow_texture, Rect2(at - radius, radius * 2.0), false, tint)


static func shaft(canvas: CanvasItem, origin: Vector2, direction: Vector2, length: float, near_half_width: float, far_half_width: float, color: Color, alpha: float) -> void:
	if length <= 0.0 or near_half_width < 0.0 or far_half_width <= 0.0 or alpha <= 0.0 or color.a <= 0.0:
		return
	if direction.length_squared() < 0.000001:
		return
	if _shaft_texture == null:
		_shaft_texture = _make_shaft_texture()
	var along := direction.normalized()
	var normal := along.orthogonal()
	var distant := origin + along * length
	var points := PackedVector2Array([
		origin - normal * near_half_width,
		distant - normal * far_half_width,
		distant + normal * far_half_width,
		origin + normal * near_half_width,
	])
	# V=0 is the distant, transparent end; V=1 is the bright chest mouth.
	var uvs := PackedVector2Array([Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)])
	var tint := color
	tint.a *= clampf(alpha, 0.0, 1.0)
	canvas.draw_polygon(points, PackedColorArray([tint, tint, tint, tint]), uvs, _shaft_texture)


static func _make_glow_texture() -> Texture2D:
	const SIDE := 128
	var mask := Image.create(SIDE, SIDE, false, Image.FORMAT_RGBA8)
	for y in SIDE:
		var py := float(y) / float(SIDE - 1) * 2.0 - 1.0
		for x in SIDE:
			var px := float(x) / float(SIDE - 1) * 2.0 - 1.0
			var falloff := maxf(0.0, 1.0 - px * px - py * py)
			# One continuous mask avoids the visible rings of layered circles.
			mask.set_pixel(x, y, Color(1, 1, 1, pow(falloff, 2.6)))
	return ImageTexture.create_from_image(mask)


static func _make_shaft_texture() -> Texture2D:
	const WIDTH := 96
	const HEIGHT := 128
	var mask := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	for y in HEIGHT:
		var v := float(y) / float(HEIGHT - 1)
		var length_fade := smoothstep(0.0, 1.0, v)
		for x in WIDTH:
			var across := absf(float(x) / float(WIDTH - 1) * 2.0 - 1.0)
			var edge_fade := smoothstep(0.0, 0.32, 1.0 - across)
			mask.set_pixel(x, y, Color(1, 1, 1, length_fade * edge_fade))
	return ImageTexture.create_from_image(mask)
