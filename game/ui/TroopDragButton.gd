extends Button

## A tap keeps the normal Button action. Mouse drags use Godot's native drag
## threshold; a touch must be held before moving, so a quick swipe can scroll.
## The page owns troop rules, preview artwork, drop feedback and persistence.
signal drag_started(data: Variant)
signal drag_finished(succeeded: bool)

const TOUCH_HOLD_SECONDS := 0.32
const TOUCH_MOVE_THRESHOLD := 12.0

var troop_id := ""
var source := "roster"
var cat := ""
## Signatures match Control's native drag forwarding, except the optional
## preview provider receives the data returned by drag_data_provider.
var drag_data_provider: Callable
var drag_preview_provider: Callable
var drop_allowed: Callable
var drop_receiver: Callable

var _touch_id := -1
var _touch_origin := Vector2.ZERO
var _touch_position := Vector2.ZERO
var _touch_elapsed := 0.0
var _touch_cancelled := false
var _touch_scroll: ScrollContainer
var _touch_scroll_start := 0.0
var _drag_owned := false
var _owns_signal_block := false
var _signals_were_blocked := false
var _finished_pending := false
var _finished_success := false


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	set_process(false)


func _get_drag_data(at_position: Vector2) -> Variant:
	# Native mouse emulation must not turn a mobile roster swipe into a drag.
	# Touch drags start explicitly after a hold in _input().
	if disabled or _touch_id >= 0:
		return null
	var data: Variant = _make_drag_data(at_position)
	if data == null:
		return null
	var preview := _make_drag_preview(data)
	if preview != null:
		set_drag_preview(preview)
	_begin_drag(data)
	return data


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return bool(drop_allowed.call(at_position, data)) if drop_allowed.is_valid() else false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if drop_receiver.is_valid():
		drop_receiver.call(at_position, data)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_id < 0 and not disabled and is_visible_in_tree() and _contains_touch(event.position):
				_touch_id = event.index
				_touch_origin = event.position
				_touch_position = event.position
				_touch_elapsed = 0.0
				_touch_cancelled = false
				_touch_scroll = _nearest_scroll()
				_touch_scroll_start = float(_touch_scroll.scroll_vertical) if _touch_scroll != null else 0.0
				set_process(true)
		elif event.index == _touch_id:
			_touch_id = -1
			set_process(false)
			if _touch_cancelled or _drag_owned or event.canceled:
				_block_click()
			_restore_after_gesture.call_deferred()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_touch_position = event.position
		if _drag_owned:
			return
		if _touch_cancelled:
			_scroll_touch()
			return
		if _touch_position.distance_to(_touch_origin) >= TOUCH_MOVE_THRESHOLD:
			if _touch_elapsed < TOUCH_HOLD_SECONDS:
				# Apply the swipe explicitly: platforms without a physical touch
				# device do not always turn emulated mouse motion into scrolling.
				_touch_cancelled = true
				_block_click()
				_scroll_touch()
			else:
				_start_touch_drag()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_restore_after_gesture.call_deferred()


func _process(delta: float) -> void:
	_touch_elapsed += delta


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _drag_owned:
		_finished_success = get_viewport().gui_is_drag_successful()
		_finished_pending = true
		_drag_owned = false
		# A release click is still being dispatched when this notification occurs.
		# Restore signals after that input pass, rather than opening detail too.
		_restore_after_gesture.call_deferred()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_touch_id = -1
		_touch_cancelled = false
		set_process(false)
		if not _drag_owned:
			_restore_after_gesture.call_deferred()


func _contains_touch(viewport_position: Vector2) -> bool:
	var local_position := get_global_transform_with_canvas().affine_inverse() * viewport_position
	if not Rect2(Vector2.ZERO, size).has_point(local_position):
		return false
	# Cards still exist above/below a scrolled viewport; they must not capture a
	# gesture over the fixed team or navigation after moving behind that clip.
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents:
			var clipped: Vector2 = ancestor.get_global_transform_with_canvas().affine_inverse() * viewport_position
			if not Rect2(Vector2.ZERO, ancestor.size).has_point(clipped):
				return false
		ancestor = ancestor.get_parent()
	return true


func _make_drag_data(at_position: Vector2) -> Variant:
	if drag_data_provider.is_valid():
		return drag_data_provider.call(at_position)
	if troop_id.is_empty():
		return null
	return {"kind": "troop", "troop_id": troop_id, "source": source, "cat": cat}


func _nearest_scroll() -> ScrollContainer:
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			return ancestor as ScrollContainer
		ancestor = ancestor.get_parent()
	return null


func _scroll_touch() -> void:
	if not is_instance_valid(_touch_scroll):
		return
	var scroll_inverse := _touch_scroll.get_global_transform_with_canvas().affine_inverse()
	var distance := (scroll_inverse * _touch_position).y - (scroll_inverse * _touch_origin).y
	# Anchor to the press rather than accumulating motion, so any platform's
	# own mouse emulation cannot double the gesture's travel.
	_touch_scroll.scroll_vertical = roundi(_touch_scroll_start - distance)
	get_viewport().set_input_as_handled()


func _make_drag_preview(data: Variant) -> Control:
	if drag_preview_provider.is_valid():
		return drag_preview_provider.call(data) as Control
	return null


func _start_touch_drag() -> void:
	var local_position := get_global_transform_with_canvas().affine_inverse() * _touch_position
	var data: Variant = _make_drag_data(local_position)
	if data == null:
		_touch_cancelled = true
		_block_click()
		return
	var preview := _make_drag_preview(data)
	_begin_drag(data)
	# Godot's default emulate_mouse_from_touch supplies motion/release and uses
	# the same native drop targets as a mouse drag. The hold only gates its start.
	force_drag(data, preview)


func _begin_drag(data: Variant) -> void:
	_drag_owned = true
	set_pressed_no_signal(false)
	drag_started.emit(data)
	_block_click()


func _block_click() -> void:
	if not _owns_signal_block:
		_signals_were_blocked = is_blocking_signals()
		_owns_signal_block = true
		set_block_signals(true)


func _restore_after_gesture() -> void:
	if _drag_owned or _touch_id >= 0:
		return
	if _owns_signal_block and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Escape can cancel a native drag before the pointer is released.
		return
	if _owns_signal_block:
		set_block_signals(_signals_were_blocked)
		_owns_signal_block = false
	_touch_cancelled = false
	_touch_scroll = null
	if _finished_pending:
		_finished_pending = false
		drag_finished.emit(_finished_success)
