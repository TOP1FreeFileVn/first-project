extends Container

# Container keeps the attached label outside the panel without fixed content heights.
var _panel: PanelContainer
var _tag: PanelContainer


func configure(panel: PanelContainer, tag: PanelContainer) -> void:
	_panel = panel
	_tag = tag
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = panel.size_flags_horizontal
	size_flags_vertical = panel.size_flags_vertical
	add_child(_panel)
	add_child(_tag)
	_panel.minimum_size_changed.connect(_content_changed)
	_tag.minimum_size_changed.connect(_content_changed)
	_content_changed()


func _content_changed() -> void:
	update_minimum_size()
	queue_sort()


func _get_minimum_size() -> Vector2:
	if _panel == null or _tag == null:
		return Vector2.ZERO
	var panel_size := _panel.get_combined_minimum_size()
	var tag_size := _tag.get_combined_minimum_size()
	return Vector2(maxf(panel_size.x, tag_size.x + 64), panel_size.y + ceilf(tag_size.y / 2.0))


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN or _panel == null or _tag == null:
		return
	var tag_size := _tag.get_combined_minimum_size()
	var top := ceilf(tag_size.y / 2.0)
	fit_child_in_rect(_panel, Rect2(Vector2(0, top), Vector2(size.x, size.y - top)))
	fit_child_in_rect(_tag, Rect2(Vector2(32, 0), tag_size))
