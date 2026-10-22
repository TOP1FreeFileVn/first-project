extends Button

## A speech bubble above the castle. Opening it never spends currency.
const Ui = preload("res://game/ui/Ui.gd")
const UpgradeHint = preload("res://game/ui/UpgradeHint.gd")
const INK := Color("583f21")
const FACE := Color("fff0d3")

var _hint: Control
var _quiet_arrow: TextureRect
var _caption: Label
var _face := StyleBoxFlat.new()


func _init() -> void:
	custom_minimum_size = Vector2(96, 108)
	size = custom_minimum_size
	clip_contents = false
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_face.bg_color = FACE
	_face.border_color = INK
	_face.set_border_width_all(3)
	_face.set_corner_radius_all(16)
	_face.corner_detail = 10
	_hint = UpgradeHint.new()
	_hint.name = "CastleUpgradeHint"
	_hint.custom_minimum_size = Vector2(56, 56)
	_hint.size = _hint.custom_minimum_size
	_hint.position = Vector2(20, -2)
	_hint.z_index = 2
	add_child(_hint)
	_quiet_arrow = Ui.icon("badge_up", 56)
	_quiet_arrow.name = "CastleQuietArrow"
	_quiet_arrow.position = Vector2(20, -2)
	_quiet_arrow.modulate = Color(0.68, 0.68, 0.68, 0.70)
	_quiet_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_quiet_arrow)
	_caption = Ui.label("", "LabelDark", 18)
	_caption.name = "LobbyCastleLevel"
	_caption.add_theme_color_override("font_color", INK)
	_caption.add_theme_constant_override("outline_size", 0)
	_caption.position = Vector2(3, 58)
	_caption.size = Vector2(90, 28)
	add_child(_caption)


func _ready() -> void:
	for event in [mouse_entered, mouse_exited, button_down, button_up, focus_entered, focus_exited]:
		event.connect(queue_redraw)


func configure(level: int, can_upgrade: bool) -> void:
	_caption.text = "Cấp %d" % level
	_hint.visible = can_upgrade
	_quiet_arrow.visible = not can_upgrade
	tooltip_text = "Xem thông tin lâu đài · Cấp %d" % level
	queue_redraw()


func _draw() -> void:
	var engaged := is_hovered() or has_focus()
	_face.bg_color = Color("f4dfa9") if is_pressed() else (Color("fff7df") if engaged else FACE)
	_face.border_color = Color("94703b") if engaged else INK
	# Draw one continuous-looking rim: the filled tail covers the panel's lower edge.
	draw_style_box(_face, Rect2(3, 16, 90, 72))
	var tail := PackedVector2Array([Vector2(35, 85), Vector2(47, 102), Vector2(64, 85)])
	draw_colored_polygon(tail, _face.bg_color)
	draw_polyline(tail, _face.border_color, 3.0, true)
