extends Control

## Five persistent carton tabs. Home owns page changes and calls set_selected().
signal tab_pressed(index: int)

const FONT := preload("res://game/ui/fonts/PaytoneOne-Regular.ttf")
const CAPTION_FONT_SIZE := 52
const CAPTION_VISIBLE_SIZE := 12.5
const FRONT := preload("res://game/ui/skin/carton_nav/box-front.svg")
const TAPE := preload("res://game/ui/skin/carton_nav/box-tape.svg")
const INSIDE := preload("res://game/ui/skin/carton_nav/box-inside.svg")
const SHELF := preload("res://game/ui/skin/carton_nav/nav-shelf.svg")
const DEFAULT_ICONS: Array[Texture2D] = [
	preload("res://game/ui/skin/carton_nav/shop.png"),
	preload("res://game/ui/skin/carton_nav/hero.png"),
	preload("res://game/ui/skin/carton_nav/battle.png"),
	preload("res://game/ui/skin/carton_nav/troops.svg"),
	preload("res://game/ui/skin/carton_nav/summon.svg"),
]
# Export-safe geometry from skin/carton_nav/carton-motion.json and the approved
# docs/design/2026-10-21/shoebox-nav-demo/art-v3/carton-motion.json prototype.
const LEFT_CLOSED := [Vector2(3, 61), Vector2(50, 61), Vector2(50, 49), Vector2(29, 49)]
const LEFT_OPEN := [Vector2(3, 61), Vector2(-4, 48), Vector2(22, 36), Vector2(29, 49)]
const OUTLINE := Color("715032")
const INK := Color("65482f")
const FLAP := Color("edcc96")
const FOLD := Color("b98c57")
const HIGHLIGHT := Color("f5d7a6")
# Rest the cartons on the shelf's top plane, leaving its wooden front edge visible.
const CARTON_ART_OFFSET := Vector2(0, -5)

class CellState:
	extends RefCounted
	var lid := 0.0
	var lift := 0.0
	var weight := 1.0
	var press := 1.0
	var rect := Rect2()
	var motion: Tween
	var pressing: Tween
	var wrapper: Control
	var button: Button

var selected := -1
var _tabs: Array = []
var _badges: Array = []
var _icons: Array[Texture2D] = []
var _cells: Array[CellState] = []
var _caption_ink: Array[Rect2] = []


func _init() -> void:
	custom_minimum_size = Vector2(0, 204)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)


## Call before adding the bar to the tree. No child is rebuilt on selection.
func configure(tabs: Array, initial: int, badges: Array, icons: Array[Texture2D] = []) -> void:
	assert(_cells.is_empty(), "Configure CartonNav once before adding it to the tree")
	_tabs = tabs.duplicate(true)
	_badges = badges.duplicate()
	_icons = icons.duplicate() if icons.size() == tabs.size() else DEFAULT_ICONS.duplicate()
	for i in mini(5, _tabs.size()):
		_caption_ink.append(_measure_caption_ink(str(_tabs[i][1])))
		var cell := CellState.new()
		cell.wrapper = Control.new()
		cell.wrapper.name = "CartonCell" + str(i)
		cell.wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cell.wrapper)
		cell.button = Button.new()
		cell.button.name = "NavButton"
		cell.button.flat = true
		cell.button.tooltip_text = str(_tabs[i][1])
		cell.button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cell.button.set_meta("tab_index", i)
		for style in ["normal", "hover", "pressed", "focus", "disabled"]:
			cell.button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
		cell.wrapper.add_child(cell.button)
		cell.button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cell.button.button_down.connect(_press.bind(i, 0.94, 0.06))
		cell.button.button_up.connect(_press.bind(i, 1.0, 0.10))
		cell.button.mouse_exited.connect(_press.bind(i, 1.0, 0.10))
		cell.button.focus_exited.connect(_press.bind(i, 1.0, 0.10))
		cell.button.gui_input.connect(_button_input.bind(i))
		cell.button.pressed.connect(_pressed.bind(i))
		_cells.append(cell)
	set_selected(initial, false)


func _ready() -> void:
	_layout()
	visibility_changed.connect(_visibility_changed)
	get_window().focus_exited.connect(_cancel_presses)
	queue_redraw()


func _exit_tree() -> void:
	set_process(false)
	# A tween holds its property target. Release both references when Home exits
	# during a transition instead of waiting for a frame that will never run.
	for cell in _cells:
		if cell.motion:
			cell.motion.kill()
			cell.motion = null
		if cell.pressing:
			cell.pressing.kill()
			cell.pressing = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not _cells.is_empty():
		_layout()
		queue_redraw()


func _process(_delta: float) -> void:
	_layout()
	queue_redraw()
	var moving := false
	for cell in _cells:
		moving = moving or (cell.motion != null and cell.motion.is_running()) or (cell.pressing != null and cell.pressing.is_running())
	if not moving:
		set_process(false)


func _layout() -> void:
	if _cells.is_empty() or size.x <= 0:
		return
	var total := 0.0
	for cell in _cells:
		total += cell.weight
	var x := 5.0
	var factor := size.x / 360.0
	for cell in _cells:
		var width := 338.0 * cell.weight / total
		cell.rect = Rect2(x, 3, width, 99)
		cell.wrapper.position = cell.rect.position * factor
		cell.wrapper.size = cell.rect.size * factor
		x += width + 3.0


func _pressed(index: int) -> void:
	var sound := get_node_or_null("/root/SoundLib")
	if sound:
		sound.call("play", "click")
	tab_pressed.emit(index)


func _button_input(event: InputEvent, index: int) -> void:
	if event is InputEventScreenTouch and event.canceled:
		_press(index, 1.0, 0.10)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_press(index, 1.0, 0.10)


func _press(index: int, value: float, duration: float) -> void:
	if index < 0 or index >= _cells.size():
		return
	var cell := _cells[index]
	if cell.pressing:
		cell.pressing.kill()
	if not is_inside_tree():
		cell.press = value
		return
	cell.pressing = create_tween()
	cell.pressing.tween_property(cell, "press", value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	set_process(true)


func _cancel_presses() -> void:
	for i in _cells.size():
		_press(i, 1.0, 0.10)


func _visibility_changed() -> void:
	if not is_visible_in_tree():
		_cancel_presses()


## Repeated selection keeps an in-flight animation intact.
func set_selected(index: int, animate := true) -> void:
	if index < 0 or index >= _cells.size() or index == selected:
		return
	selected = index
	for i in _cells.size():
		var cell := _cells[i]
		if cell.motion:
			cell.motion.kill()
		var active := i == selected
		if not animate or not is_inside_tree():
			cell.weight = 1.32 if active else 1.0
			cell.lid = 1.0 if active else 0.0
			cell.lift = cell.lid
			continue
		cell.motion = create_tween().set_parallel(true)
		cell.motion.tween_property(cell, "weight", 1.32 if active else 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		if active:
			cell.motion.tween_property(cell, "lid", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			cell.motion.tween_property(cell, "lift", 1.0, 0.22).set_delay(0.065).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			cell.motion.tween_property(cell, "lift", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			cell.motion.tween_property(cell, "lid", 0.0, 0.16).set_delay(0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_layout()
	queue_redraw()
	if animate and is_inside_tree():
		set_process(true)


func set_badges(badges: Array) -> void:
	_badges = badges.duplicate()
	queue_redraw()


## Read-only motion/geometry snapshot for native integration checks.
func get_review_state() -> Dictionary:
	var cells: Array = []
	for i in _cells.size():
		var cell := _cells[i]
		var ink := _caption_ink[i]
		var text_scale := _caption_scale(i, cell.rect.size.x)
		var baseline := 79.5 - ink.get_center().y * text_scale
		var ink_rect := Rect2(Vector2((cell.rect.size.x - ink.size.x * text_scale) * 0.5, baseline + ink.position.y * text_scale), ink.size * text_scale)
		cells.append({"lid": cell.lid, "lift": cell.lift, "weight": cell.weight,
			"press": cell.press, "badge": _badges.has(i),
			"animating": (cell.motion != null and cell.motion.is_running()) or (cell.pressing != null and cell.pressing.is_running()),
			"rect": cell.wrapper.get_rect(), "id": cell.wrapper.get_instance_id(),
			"button_id": cell.button.get_instance_id(), "caption_ink": ink,
			"caption_ink_rect": ink_rect, "caption_baseline": baseline,
			"caption_scale": text_scale})
	return {"selected": selected, "cells": cells}


func _measure_caption_ink(caption: String) -> Rect2:
	var text := TextLine.new()
	text.add_string(caption, FONT, CAPTION_FONT_SIZE)
	var server := TextServerManager.get_primary_interface()
	var top := INF
	var bottom := -INF
	for glyph in server.shaped_text_get_glyphs(text.get_rid()):
		var rid: RID = glyph["font_rid"]
		if not rid.is_valid():
			continue
		var font_size := Vector2i(glyph["font_size"], 0)
		var offset := server.font_get_glyph_offset(rid, font_size, glyph["index"])
		var extent := server.font_get_glyph_size(rid, font_size, glyph["index"])
		if extent.y <= 0:
			continue
		var shaped_offset: Vector2 = glyph["offset"]
		top = minf(top, shaped_offset.y + offset.y)
		bottom = maxf(bottom, shaped_offset.y + offset.y + extent.y)
	if not is_finite(top) or not is_finite(bottom):
		top = -FONT.get_ascent(CAPTION_FONT_SIZE)
		bottom = FONT.get_descent(CAPTION_FONT_SIZE)
	return Rect2(0, top, FONT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT_SIZE).x, bottom - top)


func _caption_scale(index: int, width: float) -> float:
	return minf(CAPTION_VISIBLE_SIZE / CAPTION_FONT_SIZE, (width * 0.88 - 2.0) / maxf(_caption_ink[index].size.x, 1.0))


func _draw() -> void:
	if _cells.is_empty() or size.x <= 0:
		return
	var factor := size.x / 360.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * factor)
	draw_texture_rect(SHELF, Rect2(0, 32, 360, 70), false)
	for i in _cells.size():
		if i != selected:
			_draw_cell(i, factor)
	if selected >= 0:
		_draw_cell(selected, factor)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_cell(index: int, factor: float) -> void:
	var cell := _cells[index]
	var width := cell.rect.size.x
	var pivot := Vector2(width * 0.5, 67)
	var offset := (cell.rect.position + CARTON_ART_OFFSET + pivot - pivot * cell.press) * factor
	draw_set_transform(offset, 0.0, Vector2.ONE * factor * cell.press)
	var full_rect := Rect2(0, 0, width, 100)
	draw_texture_rect(INSIDE, full_rect, false, Color(1, 1, 1, cell.lid))
	_draw_flap(false, cell.lid, width)
	_draw_flap(true, cell.lid, width)
	draw_texture_rect(FRONT, full_rect, false)
	draw_texture_rect(TAPE, full_rect, false, Color(1, 1, 1, 1.0 - clampf(cell.lid, 0.0, 1.0)))
	var icon_size := lerpf(26.0, 44.0, cell.lift)
	var icon_center := Vector2(width * 0.5, lerpf(79.5, 42.0, cell.lift))
	var icon := _icons[index]
	if icon:
		var ratio := icon.get_size()
		ratio *= icon_size / maxf(ratio.x, ratio.y)
		draw_texture_rect(icon, Rect2(icon_center - ratio * 0.5, ratio), false)
		if _badges.has(index):
			var dot := icon_center + Vector2(ratio.x * 0.38, -ratio.y * 0.36)
			draw_circle(dot, 3.5, Color("ed7154"), true, -1.0, true)
			draw_arc(dot, 3.5, 0, TAU, 24, INK, 1.0, true)
	# The icon and badge emerge from behind the same physical carton front.
	draw_texture_rect(FRONT, full_rect, false, Color(1, 1, 1, cell.lid))
	if index == selected:
		var caption := str(_tabs[index][1])
		var source_width := _caption_ink[index].size.x
		var text_scale := _caption_scale(index, width)
		var label_width := source_width * text_scale
		var baseline := 79.5 - _caption_ink[index].get_center().y * text_scale
		# The closed sticker starts at the caption center; wait until it rises out
		# of that space before revealing the active tab name.
		var caption_ink := Color(INK, smoothstep(0.45, 0.90, cell.lift))
		draw_set_transform(offset, 0.0, Vector2.ONE * factor * cell.press * text_scale)
		draw_string(FONT, Vector2((width - label_width) * 0.5, baseline) / text_scale, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT_SIZE, caption_ink)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * factor)


func _flap_points(mirror: bool, phase: float, width: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in LEFT_CLOSED.size():
		var point: Vector2 = LEFT_CLOSED[i].lerp(LEFT_OPEN[i], phase)
		if mirror:
			point.x = 100.0 - point.x
		points.append(Vector2(point.x * width / 100.0, point.y))
	return points


func _draw_flap(mirror: bool, phase: float, width: float) -> void:
	var points := _flap_points(mirror, phase, width)
	# Two triangles remain valid as a projected flap turns through edge-on.
	for triangle in [PackedVector2Array([points[0], points[1], points[2]]), PackedVector2Array([points[0], points[2], points[3]])]:
		if absf((triangle[1] - triangle[0]).cross(triangle[2] - triangle[0])) > 0.01:
			draw_colored_polygon(triangle, FLAP)
	var contour := points.duplicate()
	contour.append(points[0])
	draw_polyline(contour, OUTLINE, 1.9 * width / 100.0, true)
	var crease_top := points[0].lerp(points[1], 0.15)
	var crease_bottom := points[3].lerp(points[2], 0.15)
	draw_line(crease_top.lerp(crease_bottom, 0.10), crease_top.lerp(crease_bottom, 0.90), FOLD, 0.8, true)
	var shine_top := points[1].lerp(points[0], 0.18)
	var shine_bottom := points[2].lerp(points[3], 0.18)
	draw_line(shine_top.lerp(shine_bottom, 0.18), shine_top.lerp(shine_bottom, 0.80), HIGHLIGHT, 0.8, true)
