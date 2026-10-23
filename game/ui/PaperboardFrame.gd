extends PanelContainer

## Flat paperboard surfaces for the approved hero equipment screen. The panel
## owns its native layout margins; only the background is custom drawn.
const INK := Color("583f21")
const KRAFT := Color("dfbb87")
const RARITIES := {
	"green": Color("abd08c"), "blue": Color("91c8dd"),
	"purple": Color("c1a4e2"), "orange": Color("efba7d"),
}
const BADGE_RARITIES := {
	"green": Color("5b813e"), "blue": Color("347f9d"),
	"purple": Color("8659ac"), "orange": Color("b56c33"),
}

var kind := "folder":
	set(value):
		kind = value
		_configure_margins()
		queue_redraw()
var tone := "green"
var heading := "TRANG BỊ"
var grain: Texture2D


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_configure_margins()
	resized.connect(queue_redraw)


func _configure_margins() -> void:
	var box := StyleBoxEmpty.new()
	var margins := Vector4(18, 46, 18, 12)
	match kind:
		"hero": margins = Vector4(18, 16, 18, 12)
		"bag": margins = Vector4(18, 0, 18, 8)
		"plaque": margins = Vector4(12, 6, 12, 6)
		"card", "halo", "background", "badge", "power_icon": margins = Vector4.ZERO
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_content_margin(side, margins[side])
	add_theme_stylebox_override("panel", box)


func _flat(fill: Color, border := 0, radius := 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = INK
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	return box


func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	match kind:
		"hero":
			draw_style_box(_flat(KRAFT, 4), Rect2(Vector2.ZERO, size))
			if grain != null:
				draw_texture_rect(grain, Rect2(Vector2.ONE * 4, size - Vector2.ONE * 8), true)
		"folder":
			var body := _flat(KRAFT, 4, 16)
			body.corner_radius_top_left = 0
			draw_style_box(body, Rect2(0, 28, size.x, size.y - 28))
			var tab := _flat(KRAFT, 4, 14)
			tab.border_width_bottom = 0
			tab.corner_radius_bottom_left = 0
			tab.corner_radius_bottom_right = 0
			draw_style_box(tab, Rect2(0, 0, 220, 40))
			# Join the tab to the folder without a doubled edge below the title.
			draw_rect(Rect2(4, 28, 212, 16), KRAFT)
			if grain != null:
				draw_texture_rect(grain, Rect2(14, 44, size.x - 28, size.y - 58), true)
			draw_string(get_theme_font("font", "Label"), Vector2(20, 27), heading,
				HORIZONTAL_ALIGNMENT_LEFT, 190, 20, INK)
		"bag", "background":
			draw_rect(Rect2(Vector2.ZERO, size), Color("79583e"))
			if grain != null:
				draw_texture_rect(grain, Rect2(Vector2.ZERO, size), true)
			if kind == "bag":
				draw_line(Vector2.ZERO, Vector2(size.x, 0), INK, 4)
		"card":
			var cut := size.x * 0.11
			var outer := PackedVector2Array([Vector2.ZERO, Vector2(size.x - cut, 0),
				Vector2(size.x, cut), size, Vector2(cut, size.y), Vector2(0, size.y - cut)])
			draw_colored_polygon(outer, INK)
			var inset := 3.2
			var inner := PackedVector2Array([Vector2(inset, inset), Vector2(size.x - cut - 1, inset),
				Vector2(size.x - inset, cut + 1), size - Vector2.ONE * inset,
				Vector2(cut + 1, size.y - inset), Vector2(inset, size.y - cut - 1)])
			draw_colored_polygon(inner, Color("d8ae77"))
			draw_rect(Rect2(Vector2.ONE * 9.2, size - Vector2.ONE * 18.4), RARITIES.get(tone, Color("cbbda5")))
		"badge":
			draw_style_box(_flat(Color("f9e8bf"), 2, 4), Rect2(Vector2.ZERO, size))
			draw_style_box(_flat(BADGE_RARITIES.get(tone, Color("79583e")), 0, 2),
				Rect2(Vector2.ONE * 4, size - Vector2.ONE * 8))
		"plaque":
			draw_style_box(_flat(Color("f9e8bf"), 3, 12), Rect2(Vector2.ZERO, size))
		"power_icon":
			draw_style_box(_flat(Color("e8bd73"), 0, 22), Rect2(Vector2.ZERO, size))
		"halo":
			var points := PackedVector2Array()
			for i in 48:
				var angle := TAU * i / 48.0
				points.append(size * 0.5 + Vector2(cos(angle) * size.x * 0.5, sin(angle) * size.y * 0.5))
			draw_colored_polygon(points, Color("f0d7aa"))
