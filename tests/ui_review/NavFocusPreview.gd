extends Node

# Production Home, with native window renders and actual pointer input on each tab.
# The two plans isolate APPDATA/LOCALAPPDATA and never write to the player's save.
const HomeScene = preload("res://game/menu/Home.tscn")
const DESIGN_SIZE := Vector2(720, 1280)
const WINDOW_SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]
const TAB_NAMES := ["shop", "hero", "battle", "troops", "summon"]

@export var output_dir := "res://docs/ui_review/2026-10-19/nav-focus"
@export var expect_selected_footer := true

var _home: Control
var _failures := 0
var _captures: Array = []
var _routes: Array = []


func _ready() -> void:
	print("NAV_FOCUS_USER_DIR ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	PlayerData.troops["kiem"]["level"] = 6
	PlayerData.troops["kiem"]["cards"] = 12
	for id in ["giao", "katana", "riu"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "katana"]
	get_window().size = WINDOW_SIZES[0]
	_home = HomeScene.instantiate()
	add_child(_home)
	for requested in WINDOW_SIZES:
		get_window().size = requested
		await get_tree().process_frame
		await get_tree().process_frame
		for index in TAB_NAMES.size():
			var received: bool = await _tap(_nav_button(index))
			var routed: bool = received and _home._current == index
			_routes.append({"tab": TAB_NAMES[index], "native_size": [requested.x, requested.y],
				"pressed_received": received, "selected_index": _home._current, "passed": routed})
			if not routed:
				_fail("Pointer did not select tab %s at %s" % [TAB_NAMES[index], requested])
			await _capture(index, requested)
	_write_json("manifest.json", {
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"design_size": [720, 1280], "native_render": true,
		"expect_selected_footer": expect_selected_footer,
		"routes": _routes, "captures": _captures, "failures": _failures,
	})
	print("NAV_FOCUS_COMPLETE ", _captures.size(), " screens; ", _routes.size(), " pointer routes; failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _tap(button: Button) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var at := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		click.global_position = at
		# The UI rect is already in the design viewport's input coordinate system.
		get_viewport().push_input(click, true)
		await get_tree().process_frame
	return received[0]


func _nav_bar() -> Control:
	# Home queues the old bar for deletion when a tab or badge changes.
	for child in _home._nav_holder.get_children():
		if child is Control and not child.is_queued_for_deletion():
			return child
	return null


func _nav_button(index: int) -> Button:
	var bar := _nav_bar()
	if bar == null or bar.get_child_count() <= index:
		return null
	for child in bar.get_child(index).get_children():
		if child is Button:
			return child
	return null


func _first_label(node: Node) -> Label:
	if node is Label:
		return node
	for child in node.get_children():
		var found := _first_label(child)
		if found != null:
			return found
	return null


func _capture(index: int, requested: Vector2i) -> void:
	await get_tree().create_timer(0.22).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var key := "%s_%dx%d" % [TAB_NAMES[index], requested.x, requested.y]
	if shot.get_size() != requested:
		_fail("Native capture mismatch for %s: %s" % [key, shot.get_size()])
	_save_image(shot, key + ".png")
	var nav_height := int(round(174.0 * shot.get_height() / DESIGN_SIZE.y))
	_save_image(shot.get_region(Rect2i(0, shot.get_height() - nav_height,
		shot.get_width(), nav_height)), key + "_nav.png")
	var scale := Vector2(shot.get_width(), shot.get_height()) / DESIGN_SIZE
	var bar := _nav_bar()
	var selected: Control = bar.get_child(index)
	var caption: Label = selected.find_child("SelectedNavCaption", true, false) as Label
	if caption == null:
		caption = _first_label(selected)
	var footer: Control = selected.find_child("SelectedNavFooter", true, false) as Control
	if caption == null:
		_fail("Missing selected caption in " + key)
	if expect_selected_footer and footer == null:
		_fail("Missing SelectedNavFooter in " + key)
	var cells: Array = []
	for cell in bar.get_children():
		cells.append(_control_geometry(cell, scale))
	var record := {
		"tab": TAB_NAMES[index], "index": index,
		"file": key + ".png", "nav": key + "_nav.png",
		"requested": [requested.x, requested.y], "actual": [shot.get_width(), shot.get_height()],
		"window": [get_window().size.x, get_window().size.y],
		"nav_holder": _control_geometry(_home._nav_holder, scale),
		"bar": _control_geometry(bar, scale), "cells": cells,
		"selected_cell": _control_geometry(selected, scale),
		"caption": _control_geometry(caption, scale) if caption != null else {"missing": true},
		"footer": _control_geometry(footer, scale) if footer != null else {"missing": true},
		"render_scale": [scale.x, scale.y],
	}
	_captures.append(record)
	_write_json(key + "_geometry.json", record)
	print("NAV_FOCUS_CAPTURE ", key, " native=", shot.get_size())


func _control_geometry(control: Control, scale: Vector2) -> Dictionary:
	var rect := control.get_global_rect()
	var result := {
		"name": control.name, "path": str(_home.get_path_to(control)),
		"type": control.get_class(), "visible": control.is_visible_in_tree(),
		"design_rect": _rect_array(rect),
		"render_rect": _rect_array(Rect2(rect.position * scale, rect.size * scale)),
		"minimum_size": [control.get_combined_minimum_size().x, control.get_combined_minimum_size().y],
	}
	if control is Label:
		var font_size := control.get_theme_font_size("font_size")
		var text_width := control.get_theme_font("font").get_string_size(
			control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		result["text"] = control.text
		result["font_size"] = font_size
		result["outline_size"] = control.get_theme_constant("outline_size")
		result["font_color"] = control.get_theme_color("font_color").to_html()
		result["font_outline_color"] = control.get_theme_color("font_outline_color").to_html()
		result["text_width"] = text_width
		result["fits_width"] = text_width <= rect.size.x
		if text_width > rect.size.x:
			_fail("Selected caption exceeds its width: " + control.text)
	return result


func _rect_array(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _write_json(file_name: String, value: Dictionary) -> void:
	var file := FileAccess.open(output_dir + "/" + file_name, FileAccess.WRITE)
	if file == null:
		_fail("Could not write nav review JSON: " + file_name)
		return
	file.store_string(JSON.stringify(value, "\t"))
	file.close()


func _save_image(shot: Image, file_name: String) -> void:
	var error := shot.save_png(output_dir + "/" + file_name)
	if error != OK:
		_fail("Could not save nav review image: " + file_name)


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)
