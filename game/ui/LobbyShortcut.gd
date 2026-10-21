extends Button

## Native lobby shortcut feedback. Home owns feature routes and click sounds.
## configure() before adding it to the tree; activated is emitted once per native press.
signal activated(kind: int)

const BASE_SIZE := Vector2(108, 128)
const FONT := preload("res://game/ui/fonts/PaytoneOne-Regular.ttf")
const FONT_SOURCE := 52
const INK := Color("583f21")
const PAPER := Color("fff0d3")
const FRAMES: Array[Texture2D] = [
	preload("res://game/ui/skin/shortcut_peach.svg"),
	preload("res://game/ui/skin/shortcut_sage.svg"),
	preload("res://game/ui/skin/shortcut_lavender.svg"),
	preload("res://game/ui/skin/shortcut_sand.svg"),
]

var _kind := 0
var _title := ""
var _icon: Texture2D
var _alert := false
var _caption_ink := Rect2()
var _press_amount := 0.0
var _hover_lift := 0.0
var _highlight := 0.0
var _effect_progress := 1.0
var _pointer_over := false
var _holding := false
var _activation_blocked := false
var _face_tween: Tween
var _intent_tween: Tween
var _effect_tween: Tween
var _rim := StyleBoxFlat.new()
var _shadow := StyleBoxFlat.new()


func _init() -> void:
	custom_minimum_size = BASE_SIZE
	size = BASE_SIZE
	flat = true
	focus_mode = Control.FOCUS_ALL
	action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		_rim.set("corner_radius_" + corner, 22)
		_shadow.set("corner_radius_" + corner, 19)
	_rim.bg_color = Color("f3d188")
	_rim.border_color = Color("a27640")
	_rim.set_border_width_all(2)
	_shadow.bg_color = Color(0.24, 0.17, 0.09, 0.20)
	set_process(false)


func configure(kind: int, title: String, icon: Texture2D, alert: bool) -> void:
	_kind = clampi(kind, 0, 3)
	_title = title
	_icon = icon
	_alert = alert
	tooltip_text = title
	_caption_ink = _measure_caption(title)
	queue_redraw()


func set_alert(enabled: bool) -> void:
	if _alert == enabled:
		return
	_alert = enabled
	queue_redraw()


func _ready() -> void:
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)
	focus_entered.connect(_update_intent)
	focus_exited.connect(_focus_left)
	button_down.connect(_button_down)
	button_up.connect(_button_up)
	pressed.connect(_activated)
	get_window().focus_exited.connect(_window_focus_left)
	_update_intent()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.canceled:
		_cancel_press()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_press()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree() and not is_visible_in_tree():
		_reset_visual_state()


func _window_focus_left() -> void:
	_reset_visual_state()


func _reset_visual_state() -> void:
	_holding = false
	_activation_blocked = true
	_pointer_over = false
	_press_amount = 0.0
	_hover_lift = 0.0
	_highlight = 0.0
	_effect_progress = 1.0
	if has_focus():
		release_focus()
	for tween in [_face_tween, _intent_tween, _effect_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	_face_tween = null
	_intent_tween = null
	_effect_tween = null
	set_process(false)
	queue_redraw()


func _exit_tree() -> void:
	var window := get_window()
	if window != null and window.focus_exited.is_connected(_window_focus_left):
		window.focus_exited.disconnect(_window_focus_left)
	for tween in [_face_tween, _intent_tween, _effect_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	_face_tween = null
	_intent_tween = null
	_effect_tween = null
	set_process(false)


func _process(_delta: float) -> void:
	queue_redraw()
	if not _moving(_face_tween) and not _moving(_intent_tween) and not _moving(_effect_tween):
		set_process(false)


func _moving(tween: Tween) -> bool:
	return tween != null and tween.is_valid() and tween.is_running()


func _redraw_during_motion() -> void:
	queue_redraw()
	set_process(true)


func _mouse_entered() -> void:
	_pointer_over = true
	_update_intent()


func _mouse_exited() -> void:
	_pointer_over = false
	if _holding:
		_cancel_press()
	_update_intent()


func _focus_left() -> void:
	if _holding:
		_cancel_press()
	_update_intent()


func _update_intent() -> void:
	var engaged := not disabled and is_visible_in_tree() and (_pointer_over or has_focus())
	if _intent_tween:
		_intent_tween.kill()
	if not is_inside_tree() or not is_visible_in_tree():
		_highlight = 1.0 if engaged else 0.0
		_hover_lift = 3.0 if engaged else 0.0
		queue_redraw()
		return
	_intent_tween = create_tween().set_parallel(true)
	_intent_tween.tween_property(self, "_highlight", 1.0 if engaged else 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_intent_tween.tween_property(self, "_hover_lift", 3.0 if engaged else 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_redraw_during_motion()


func _button_down() -> void:
	if disabled:
		return
	_holding = true
	_activation_blocked = false
	if _face_tween:
		_face_tween.kill()
	_face_tween = create_tween()
	_face_tween.tween_property(self, "_press_amount", 1.0, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_redraw_during_motion()


func _button_up() -> void:
	_holding = false
	_release_face(not _activation_blocked)


func _cancel_press() -> void:
	_holding = false
	_activation_blocked = true
	_release_face(false)


func _release_face(overshoot: bool) -> void:
	if _face_tween:
		_face_tween.kill()
	if not is_inside_tree() or not is_visible_in_tree():
		_press_amount = 0.0
		queue_redraw()
		return
	_face_tween = create_tween()
	_face_tween.tween_property(self, "_press_amount", 0.0, 0.18 if overshoot else 0.10).set_trans(Tween.TRANS_BACK if overshoot else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_redraw_during_motion()


func _activated() -> void:
	if _activation_blocked or disabled or not is_visible_in_tree():
		return
	play_feedback()
	activated.emit(_kind)


## Replay the local visual response without emitting activation.
func play_feedback() -> void:
	if disabled or not is_inside_tree():
		return
	_release_face(true)
	if _effect_tween:
		_effect_tween.kill()
	_effect_progress = 0.0
	_effect_tween = create_tween()
	_effect_tween.tween_property(self, "_effect_progress", 1.0, 0.52)
	_redraw_during_motion()


func get_review_state() -> Dictionary:
	return {"kind": _kind, "holding": _holding, "press": _press_amount,
		"visual_scale": 1.0 - 0.06 * _press_amount, "focus": _highlight,
		"lift": _hover_lift, "effect_progress": _effect_progress,
		"animating": _moving(_face_tween) or _moving(_intent_tween) or _moving(_effect_tween),
		"hit_rect": get_global_rect(), "alert": _alert, "pointer_over": _pointer_over,
		"has_focus": has_focus(), "activation_blocked": _activation_blocked}


func _draw() -> void:
	var base_scale := size / BASE_SIZE
	draw_set_transform(Vector2.ZERO, 0.0, base_scale)
	draw_style_box(_shadow, Rect2(7, 12, 94, 113))
	var face_scale := 1.0 - 0.06 * _press_amount
	var face_offset := BASE_SIZE * 0.5 * (1.0 - face_scale) + Vector2(0, 4.0 * _press_amount - _hover_lift)
	draw_set_transform(face_offset * base_scale, 0.0, base_scale * face_scale)
	if _highlight > 0.001:
		_rim.bg_color.a = _highlight
		_rim.border_color.a = _highlight
		draw_style_box(_rim, Rect2(0, 0, 108, 124))
	draw_texture_rect(FRAMES[_kind], Rect2(Vector2.ZERO, BASE_SIZE), false, Color(1, 1, 1, 0.55 if disabled else 1.0))
	_draw_icon(face_offset, face_scale, base_scale)
	draw_set_transform(face_offset * base_scale, 0.0, base_scale * face_scale)
	_draw_caption(face_offset, face_scale, base_scale)
	draw_set_transform(face_offset * base_scale, 0.0, base_scale * face_scale)
	if _alert:
		draw_circle(Vector2(94, 13), 8.0, Color("e77859"), true, -1.0, true)
		draw_arc(Vector2(94, 13), 8.0, 0, TAU, 32, INK, 2.2, true)
		draw_line(Vector2(94, 8), Vector2(94, 13), PAPER, 2.0, true)
		draw_circle(Vector2(94, 16.5), 1.0, PAPER, true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_icon(face_offset: Vector2, face_scale: float, base_scale: Vector2) -> void:
	if _icon == null:
		return
	var pulse := sin(_effect_progress * PI)
	var icon_at := Vector2(18, 9)
	var icon_size := Vector2(72, 72)
	var icon_rect := Rect2(icon_at, icon_size)
	var center := icon_rect.get_center()
	var angle := 0.0
	var lift := 0.0
	if _kind == 0:
		angle = deg_to_rad(-5.0) * pulse
	elif _kind == 1:
		lift = -4.0 * pulse
	elif _kind == 3:
		lift = -2.0 * pulse
	var icon_transform := Transform2D(angle, center + Vector2(0, lift)) * Transform2D(0.0, -center)
	var face_transform := Transform2D(0.0, face_offset).scaled_local(Vector2.ONE * face_scale)
	var screen_transform := Transform2D(0.0, Vector2.ZERO).scaled_local(base_scale)
	draw_set_transform_matrix(screen_transform * face_transform * icon_transform)
	if _kind == 2:
		_draw_fluttering_banner(icon_rect, pulse)
	else:
		draw_texture_rect(_icon, icon_rect, false)
	if _effect_progress < 0.999:
		match _kind:
			0: _draw_calendar_page(pulse)
			1: _draw_quest_check(pulse)
			3: _draw_castle_door(pulse)


func _draw_calendar_page(amount: float) -> void:
	# A real page corner peels up from the printed date, then settles away.
	var shade := Color("fff5dc")
	shade.a = amount
	var edge := Color(INK, amount)
	var fold := PackedVector2Array([
		Vector2(39, 44), Vector2(76, 44),
		Vector2(76 + 5.0 * amount, 66 - 20.0 * amount), Vector2(39, 66 - 9.0 * amount),
	])
	draw_colored_polygon(fold, shade)
	var outline := fold.duplicate()
	outline.append(fold[0])
	draw_polyline(outline, edge, 1.8, true)
	draw_line(Vector2(42, 49), Vector2(69, 49 - 3.0 * amount), Color(0.72, 0.56, 0.36, amount), 1.4, true)


func _draw_quest_check(amount: float) -> void:
	# A small completion stamp is drawn as two strokes rather than a generic pulse.
	var center := Vector2(77, 63)
	draw_circle(center, 12.0, Color(PAPER, amount), true, -1.0, true)
	draw_arc(center, 12.0, 0, TAU, 32, Color(INK, amount), 1.5, true)
	var reveal := clampf(_effect_progress * 3.5, 0.0, 1.0)
	var a := Vector2(69, 63)
	var b := Vector2(75, 69)
	var c := Vector2(86, 56)
	var color := Color("57764d")
	color.a = amount
	if reveal < 0.35:
		draw_line(a, a.lerp(b, reveal / 0.35), color, 3.3, true)
	else:
		draw_line(a, b, color, 3.3, true)
		draw_line(b, b.lerp(c, (reveal - 0.35) / 0.65), color, 3.3, true)


func _draw_fluttering_banner(rect: Rect2, amount: float) -> void:
	# Keep the mounting rod fixed and let the hanging cloth move from its top edge.
	var source := _icon.get_size()
	var split := 32.0 / 128.0
	draw_texture_rect_region(_icon, Rect2(rect.position, Vector2(rect.size.x, rect.size.y * split)), Rect2(Vector2.ZERO, Vector2(source.x, source.y * split)))
	var angle := deg_to_rad(6.0) * sin(_effect_progress * TAU * 2.0) * amount
	var pivot := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * split)
	# draw_set_transform_matrix expects local drawing space, not the canvas transform.
	# Reuse the face transform directly so the untouched rod remains aligned.
	var face_scale := 1.0 - 0.06 * _press_amount
	var face_offset := BASE_SIZE * 0.5 * (1.0 - face_scale) + Vector2(0, 4.0 * _press_amount - _hover_lift)
	var face := Transform2D(0.0, face_offset).scaled_local(Vector2.ONE * face_scale)
	var screen := Transform2D(0.0, Vector2.ZERO).scaled_local(size / BASE_SIZE)
	var flutter := Transform2D(angle, pivot) * Transform2D(0.0, -pivot)
	draw_set_transform_matrix(screen * face * flutter)
	draw_texture_rect_region(_icon, Rect2(rect.position + Vector2(0, rect.size.y * split), Vector2(rect.size.x, rect.size.y * (1.0 - split))), Rect2(Vector2(0, source.y * split), Vector2(source.x, source.y * (1.0 - split))))


func _draw_castle_door(amount: float) -> void:
	var left := 45.5
	var right := 62.5
	var floor_y := 73.0
	var center := Vector2(54, 61)
	var arch := PackedVector2Array([Vector2(left, floor_y)])
	for i in 13:
		var theta := PI + float(i) / 12.0 * PI
		arch.append(center + Vector2(cos(theta), sin(theta)) * 8.5)
	arch.append(Vector2(right, floor_y))
	draw_colored_polygon(arch, Color("6d5038"))
	var outline := arch.duplicate()
	outline.append(arch[0])
	draw_polyline(outline, INK, 2.1, true)
	var leaf := 8.5 * (1.0 - 0.82 * amount)
	draw_colored_polygon(PackedVector2Array([Vector2(left, 59), Vector2(left + leaf, 55 + 4.0 * amount), Vector2(left + leaf, floor_y), Vector2(left, floor_y)]), Color("bd8f62"))
	draw_colored_polygon(PackedVector2Array([Vector2(right - leaf, 55 + 4.0 * amount), Vector2(right, 59), Vector2(right, floor_y), Vector2(right - leaf, floor_y)]), Color("bd8f62"))
	draw_line(Vector2(left + leaf, 58), Vector2(left + leaf, floor_y), INK, 1.2, true)
	draw_line(Vector2(right - leaf, 58), Vector2(right - leaf, floor_y), INK, 1.2, true)


func _draw_caption(face_offset: Vector2, face_scale: float, base_scale: Vector2) -> void:
	if _title.is_empty():
		return
	var scale_text := minf(16.0 / FONT_SOURCE, 94.0 / maxf(1.0, _caption_ink.size.x))
	var width := _caption_ink.size.x * scale_text
	var baseline := 103.5 - _caption_ink.get_center().y * scale_text
	draw_set_transform(face_offset * base_scale, 0.0, base_scale * face_scale * scale_text)
	draw_string(FONT, Vector2((108.0 - width) * 0.5, baseline) / scale_text, _title, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SOURCE, INK)


func _measure_caption(caption: String) -> Rect2:
	var line := TextLine.new()
	line.add_string(caption, FONT, FONT_SOURCE)
	var server := TextServerManager.get_primary_interface()
	var top := INF
	var bottom := -INF
	for glyph in server.shaped_text_get_glyphs(line.get_rid()):
		var rid: RID = glyph["font_rid"]
		if not rid.is_valid():
			continue
		var font_size := Vector2i(glyph["font_size"], 0)
		var offset := server.font_get_glyph_offset(rid, font_size, glyph["index"])
		var extent := server.font_get_glyph_size(rid, font_size, glyph["index"])
		if extent.y > 0:
			var shaped_offset: Vector2 = glyph["offset"]
			top = minf(top, shaped_offset.y + offset.y)
			bottom = maxf(bottom, shaped_offset.y + offset.y + extent.y)
	if not is_finite(top):
		top = -FONT.get_ascent(FONT_SOURCE)
		bottom = FONT.get_descent(FONT_SOURCE)
	return Rect2(0, top, FONT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SOURCE).x, bottom - top)
