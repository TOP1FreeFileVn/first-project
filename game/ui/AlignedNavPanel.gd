extends PanelContainer

# Keep both frame edges on actual screen pixels when the design canvas is scaled.
# Layout and hit areas remain in design coordinates; only the skin's draw bounds move.
var _face: StyleBoxTexture


func _ready() -> void:
	_face = get_theme_stylebox("panel").duplicate() as StyleBoxTexture
	add_theme_stylebox_override("panel", _face)
	set_notify_transform(true)
	get_viewport().size_changed.connect(_align_edges)
	_align_edges()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_RESIZED:
		_align_edges()


func _align_edges() -> void:
	if _face == null or not is_inside_tree():
		return
	var scale_x := absf(get_viewport().get_stretch_transform().x.x)
	if is_zero_approx(scale_x):
		return
	var bounds := get_global_rect()
	var left := roundf(bounds.position.x * scale_x) / scale_x
	var right := roundf(bounds.end.x * scale_x) / scale_x
	var left_margin := bounds.position.x - left
	var right_margin := right - bounds.end.x
	if not is_equal_approx(_face.expand_margin_left, left_margin):
		_face.expand_margin_left = left_margin
	if not is_equal_approx(_face.expand_margin_right, right_margin):
		_face.expand_margin_right = right_margin
