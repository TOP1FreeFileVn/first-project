extends Node

# Production Home, isolated player profile. Shader time is frozen independently of
# the UI; the final sequence uses the real shader TIME while UI animation is paused.
const OUT := "res://docs/ui_review/2026-10-19/menu-background-motion"
const HomeScene = preload("res://game/menu/Home.tscn")
const WINDOW_SIZE := Vector2i(450, 800)
const SAMPLE_TIMES := [0.0, 5.0, 10.0]
const MOTION_FRAMES := 32
const MOTION_FPS := 8.0

var _home: Control
var _captures: Array = []
var _routes: Array = []
var _motion_frames: Array = []
var _failures := 0


func _ready() -> void:
	print("MENU_BACKGROUND_MOTION_USER_DIR ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "/motion_frames"))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 4
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	get_window().size = WINDOW_SIZE
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.BATTLE_TAB, false)
	await _settle()
	_pause_ui()
	var initial_layout := _layout()
	var foreground_reference: Image
	var backgrounds := {}
	for sample_time in SAMPLE_TIMES:
		_set_sky_time(sample_time, 0.0)
		var key := "lobby_t%02d_450x800" % int(sample_time)
		await _capture(key, {"shader_time": sample_time, "motion_speed": 0.0, "ui_paused": true})
		var sky := await _capture_background_only("background_t%02d_450x800" % int(sample_time))
		backgrounds[int(sample_time)] = sky
		var foreground := await _capture_foreground_only("foreground_t%02d_450x800" % int(sample_time))
		if foreground_reference == null:
			foreground_reference = foreground
		else:
			_record("foreground_static_at_" + str(int(sample_time)), foreground.get_data() == foreground_reference.get_data())
		_record("layout_static_at_" + str(int(sample_time)), _layout() == initial_layout)
	_record("background_changes_0_to_5", backgrounds[0].get_data() != backgrounds[5].get_data())
	_record("background_changes_5_to_10", backgrounds[5].get_data() != backgrounds[10].get_data())
	await _real_time_sequence()
	await _shop_and_castle_review(backgrounds[5])
	_write_json("manifest.json", {
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"native_size": [450, 800], "sample_times": SAMPLE_TIMES,
		"captures": _captures, "routes": _routes, "motion_frames": _motion_frames,
		"motion_fps": MOTION_FPS, "failures": _failures,
	})
	print("MENU_BACKGROUND_MOTION_COMPLETE ", _captures.size(), " captures; ", _routes.size(),
		" checks; ", _motion_frames.size(), " real-time frames; failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _pause_ui() -> void:
	for tween in get_tree().get_processed_tweens():
		tween.pause()
	_home.process_mode = Node.PROCESS_MODE_DISABLED


func _resume_ui() -> void:
	_home.process_mode = Node.PROCESS_MODE_INHERIT


func _set_sky_time(offset: float, speed: float) -> void:
	for item in _background_items():
		var material := item.material as ShaderMaterial
		if material != null and material.shader.resource_path.ends_with("menu_sky.gdshader"):
			material.set_shader_parameter("time_offset", offset)
			material.set_shader_parameter("motion_speed", speed)


func _real_time_sequence() -> void:
	_set_sky_time(0.0, 1.0)
	var start := Time.get_ticks_msec()
	for index in MOTION_FRAMES:
		var target := start + roundi(index * 1000.0 / MOTION_FPS)
		var remaining := target - Time.get_ticks_msec()
		if remaining > 0:
			await get_tree().create_timer(remaining / 1000.0).timeout
		await RenderingServer.frame_post_draw
		var shot := get_viewport().get_texture().get_image()
		var file_key := "motion_frames/frame_%03d.png" % index
		_save_image(shot, file_key)
		_motion_frames.append({"file": file_key, "elapsed_ms": Time.get_ticks_msec() - start})
	_record("real_time_sequence_has_all_frames", _motion_frames.size() == MOTION_FRAMES)
	var first := Image.load_from_file(OUT + "/" + _motion_frames[0].file)
	var last := Image.load_from_file(OUT + "/" + _motion_frames[-1].file)
	_record("real_time_shader_moves", first.get_data() != last.get_data())


func _shop_and_castle_review(lobby_background_at_five: Image) -> void:
	_resume_ui()
	var tapped := await _tap(_nav_button(_home.SHOP_TAB))
	await _settle()
	_pause_ui()
	_record("actual_nav_opens_shop", tapped and _home._current == _home.SHOP_TAB)
	var sky: Control = _home.find_child("MenuBackground", true, false)
	var pattern: Control = _home.find_child("ShopBackground", true, false)
	_record("shop_shows_old_pattern", sky != null and pattern != null and not sky.visible and pattern.visible)
	await _capture("shop_pattern_450x800", {"selected_tab": _home._current, "ui_paused": true})
	_resume_ui()
	tapped = await _tap(_nav_button(_home.BATTLE_TAB))
	await _settle()
	_pause_ui()
	_set_sky_time(5.0, 0.0)
	_record("actual_nav_returns_to_sky", tapped and _home._current == _home.BATTLE_TAB and sky.visible and not pattern.visible)
	await _capture("lobby_return_t05_450x800", {"shader_time": 5.0, "motion_speed": 0.0, "ui_paused": true})
	_resume_ui()
	_home.open_page(load("res://game/menu/pages/CastlePage.gd"))
	await _settle()
	_pause_ui()
	_set_sky_time(5.0, 0.0)
	await _capture("castle_overlay_t05_450x800", {"shader_time": 5.0, "motion_speed": 0.0, "ui_paused": true})
	var overlay_background := await _capture_background_only("castle_background_t05_450x800")
	_record("castle_overlay_background_matches_full_screen", overlay_background.get_data() == lobby_background_at_five.get_data())
	_resume_ui()
	var back: Button
	for child in _home._overlay.get_children():
		if child is Button:
			back = child
			break
	tapped = await _tap(back)
	await get_tree().process_frame
	_record("castle_actual_back_returns_to_lobby", tapped and _home._overlay == null and _home._current == _home.BATTLE_TAB)


func _background_items() -> Array[CanvasItem]:
	var output: Array[CanvasItem] = []
	_collect_backgrounds(_home, output)
	return output


func _collect_backgrounds(node: Node, output: Array[CanvasItem]) -> void:
	if _is_background(node):
		output.append(node)
	for child in node.get_children():
		_collect_backgrounds(child, output)


func _is_background(node: Node) -> bool:
	if not node is CanvasItem:
		return false
	var material := node.material as ShaderMaterial
	if material == null or material.shader == null:
		return false
	var shader_path := material.shader.resource_path
	return shader_path.ends_with("menu_sky.gdshader") or shader_path.ends_with("pattern_scroll.gdshader")


func _contains_background(node: Node) -> bool:
	if _is_background(node):
		return true
	for child in node.get_children():
		if _contains_background(child):
			return true
	return false


func _hide_foreground(node: Node, states: Array) -> void:
	for child in node.get_children():
		if child is CanvasItem:
			states.append([child, child.visible])
			if not _contains_background(child):
				child.visible = false
				continue
		_hide_foreground(child, states)


func _capture_background_only(key: String) -> Image:
	var states := []
	_hide_foreground(_home, states)
	var shot := await _capture(key, {"isolated": "background"})
	for state in states:
		state[0].visible = state[1]
	return shot


func _capture_foreground_only(key: String) -> Image:
	var states := []
	for item in _background_items():
		states.append([item, item.visible])
		item.visible = false
	var shot := await _capture(key, {"isolated": "foreground"})
	for state in states:
		state[0].visible = state[1]
	return shot


func _capture(key: String, state: Dictionary) -> Image:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	_save_image(shot, key + ".png")
	var record := {"file": key + ".png", "actual": [shot.get_width(), shot.get_height()],
		"state": state, "layout": _layout(), "backgrounds": _background_geometry()}
	_captures.append(record)
	_write_json(key + "_geometry.json", record)
	print("MENU_BACKGROUND_MOTION_CAPTURE ", key)
	return shot


func _layout() -> Array:
	var output := []
	_collect_layout(_home, output)
	return output


func _collect_layout(node: Node, output: Array) -> void:
	if node is Control and not _is_background(node):
		var rect: Rect2 = node.get_global_rect()
		var record := {"path": str(_home.get_path_to(node)), "visible": node.visible,
			"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
			"scale": [node.scale.x, node.scale.y]}
		if node is Label or node is Button:
			record["text"] = node.text
		output.append(record)
	for child in node.get_children():
		_collect_layout(child, output)


func _background_geometry() -> Array:
	var result := []
	for item in _background_items():
		var material := item.material as ShaderMaterial
		result.append({"name": item.name, "path": str(_home.get_path_to(item)),
			"visible": item.visible, "shader": material.shader.resource_path,
			"time_offset": material.get_shader_parameter("time_offset"),
			"motion_speed": material.get_shader_parameter("motion_speed")})
	return result


func _nav_button(index: int) -> Button:
	var bar: Control = _home._nav_holder.get_child(_home._nav_holder.get_child_count() - 1)
	var cell: Control = bar.get_child(index)
	for child in cell.get_children():
		if child is Button:
			return child
	return null


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
		get_viewport().push_input(click, true)
		await get_tree().process_frame
	return received[0]


func _settle() -> void:
	await get_tree().create_timer(0.28).timeout
	await get_tree().process_frame


func _save_image(shot: Image, file_name: String) -> void:
	_check(shot.get_size() == WINDOW_SIZE, "Native screenshot size: " + file_name)
	_check(shot.save_png(OUT + "/" + file_name) == OK, "Save screenshot: " + file_name)


func _record(check_name: String, passed: bool) -> void:
	_routes.append({"name": check_name, "passed": passed})
	_check(passed, check_name)
	print("MENU_BACKGROUND_MOTION_CHECK ", check_name, " ", "PASS" if passed else "FAIL")


func _check(passed: bool, message: String) -> void:
	if not passed:
		_failures += 1
		push_error(message)


func _write_json(file_name: String, data: Dictionary) -> void:
	var file := FileAccess.open(OUT + "/" + file_name, FileAccess.WRITE)
	if file == null:
		_check(false, "Could not write background review JSON: " + file_name)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
