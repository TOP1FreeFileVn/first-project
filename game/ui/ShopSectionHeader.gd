extends CenterContainer

## A centered carton label over a continuous shop aisle divider.
const UiKit = preload("res://game/ui/UiKit.gd")
const INK := Color("583f21")
var _band: StyleBoxFlat


func _init(title: String = "", accent := Color("edd2a0")) -> void:
	custom_minimum_size.y = 66
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band = StyleBoxFlat.new()
	_band.bg_color = Color("89634b")
	_band.border_color = INK
	_band.set_border_width_all(4)
	_band.set_corner_radius_all(8)
	_band.shadow_size = 0
	var tag := PanelContainer.new()
	tag.name = "SectionTag"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := StyleBoxFlat.new()
	skin.bg_color = accent
	skin.border_color = INK
	skin.set_border_width_all(4)
	skin.set_corner_radius_all(13)
	skin.content_margin_left = 28
	skin.content_margin_right = 28
	skin.content_margin_top = 9
	skin.content_margin_bottom = 9
	skin.shadow_size = 0
	tag.add_theme_stylebox_override("panel", skin)
	add_child(tag)
	var label := UiKit.ink(title, 28)
	label.name = "SectionTitle"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("fff6dd"))
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 4)
	tag.add_child(label)
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_style_box(_band, Rect2(0, (size.y - 34) * 0.5, size.x, 34))
