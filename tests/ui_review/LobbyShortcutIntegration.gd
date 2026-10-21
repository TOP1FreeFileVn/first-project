extends Node

# Production Home, native input, disposable profile. No claims, purchases or battle.
const HOME = preload("res://game/menu/Home.tscn")
const OUT := "res://docs/ui_review/2026-10-21/lobby-shortcut-integration"
const KEYS := ["login", "quests", "events"]
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
var _home
var _buttons: Array[Button] = []
var _ids: Array = []
var _activations := [0, 0, 0]
var _checks: Array = []
var _captures: Array = []
var _images: Array = []
var _failures := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.tutorial_done = true
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.gold = 2400
	PlayerData.gems = 260
	get_window().size = SIZES[0]
	_home = HOME.instantiate()
	add_child(_home)
	_home.select_tab(_home.BATTLE_TAB, false)
	await _settle()
	for index in KEYS.size():
		var button := _home._side.find_child(KEYS[index].to_pascal_case() + "Shortcut", true, false) as Button
		_check(button != null and button.has_method("get_review_state"), "native_shortcut_created_" + KEYS[index])
		if button == null or not button.has_method("get_review_state"):
			_finish()
			return
		_buttons.append(button)
		_ids.append(button.get_instance_id())
		button.connect("activated", _record_activation.bind(index))
	await _check_refresh()
	await _check_cancellations()
	await _check_pending_guards()
	await _check_keyboard()
	for requested in SIZES:
		get_window().size = requested
		await _reset_lobby()
		await _capture("idle", requested)
		for index in KEYS.size():
			await _check_route(index, requested)
	_finish()


func _record_activation(_kind: int, index: int) -> void:
	_activations[index] += 1


func _state(index: int) -> Dictionary:
	return _buttons[index].call("get_review_state")


func _same_buttons() -> bool:
	for index in KEYS.size():
		if not is_instance_valid(_buttons[index]) or _buttons[index].get_instance_id() != _ids[index]:
			return false
		if _home._side_shortcuts.get(KEYS[index]) != _buttons[index]:
			return false
	return true


func _surfaces() -> Array:
	var found: Array = []
	for entry in _home._menu_surfaces:
		var node = entry.node
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			found.append(entry)
	return found


func _destination(index: int) -> bool:
	var context: String = KEYS[index]
	var matches := 0
	for entry in _surfaces():
		if entry.context == context:
			matches += 1
	return matches == 1 and _surfaces().size() == 1


func _check_route(index: int, requested: Vector2i) -> void:
	await _reset_lobby()
	var button := _buttons[index]
	var at := button.get_global_rect().get_center()
	var before: int = _activations[index]
	_motion(at)
	_pointer(at, true)
	await _wait(0.090)
	_check(float(_state(index).get("press", 0.0)) > 0.85 and float(_state(index).get("visual_scale", 1.0)) < 0.96, "pointer_depresses_" + KEYS[index], requested)
	_check(_surfaces().is_empty(), "press_does_not_route_" + KEYS[index], requested)
	await _capture("press_" + KEYS[index], requested)
	_pointer(at, false)
	await _wait(0.085)
	await RenderingServer.frame_post_draw
	var progress := float(_state(index).get("effect_progress", 1.0))
	_check(progress > 0.0 and progress < 1.0, "release_has_local_motion_" + KEYS[index], requested)
	_check(_surfaces().is_empty(), "destination_waits_for_feedback_" + KEYS[index], requested)
	await _capture("feedback_" + KEYS[index], requested)
	await _wait(0.280)
	_check(_activations[index] == before + 1, "release_activates_once_" + KEYS[index], requested)
	_check(_destination(index), "opens_correct_destination_" + KEYS[index], requested)
	_check(_same_buttons(), "destination_preserves_shortcuts_" + KEYS[index], requested)
	await _capture("destination_" + KEYS[index], requested)
	# Close through the native registered menu's close/back button, without claims.
	var entries := _surfaces()
	if not entries.is_empty():
		await _tap(_popup_close(entries[0].node))
	await _settle()
	_check(_surfaces().is_empty() and _home._overlay == null and _home._side.is_visible_in_tree(), "native_close_restores_lobby_" + KEYS[index], requested)
	_check(_same_buttons(), "close_preserves_shortcuts_" + KEYS[index], requested)
	_check_bounds(requested)


func _check_refresh() -> void:
	var states: Array = []
	for index in KEYS.size():
		states.append(bool(_state(index).get("alert", false)))
	PlayerData.gold += 1
	PlayerData.changed.emit()
	_home.call("_on_tick")
	await get_tree().process_frame
	_check(_same_buttons(), "data_refresh_preserves_three_native_buttons")
	var expected := [PlayerData.login_can_claim(), PlayerData.quest_alert(), PlayerData.patrol_alert()]
	for index in KEYS.size():
		_check(bool(_state(index).get("alert", false)) == expected[index], "live_badge_matches_data_" + KEYS[index])
		_buttons[index].call("set_alert", not expected[index])
		_check(bool(_state(index).get("alert", false)) != expected[index], "badge_can_update_without_rebuild_" + KEYS[index])
		_buttons[index].call("set_alert", expected[index])
	_check(_same_buttons(), "badge_setters_preserve_identity")


func _check_cancellations() -> void:
	for kind in ["pointer_exit", "escape", "focus_lost", "hidden", "touch_cancel"]:
		await _reset_lobby()
		var button := _buttons[0]
		var at := button.get_global_rect().get_center()
		var before: int = _activations[0]
		_motion(at)
		if kind == "touch_cancel":
			# Register a real active touch before sending its canceled release.
			# A canceled touch with no preceding touch-down has no GUI owner.
			var touch := InputEventScreenTouch.new()
			touch.index = 0
			touch.position = at
			touch.pressed = true
			get_viewport().push_input(touch, true)
		_pointer(at, true)
		await _wait(0.080)
		match kind:
			"pointer_exit": _motion(at + Vector2(180, 0), true)
			"escape": _key(KEY_ESCAPE, true)
			"focus_lost": _home._nav_bar.get_child(2).get_child(0).grab_focus()
			"hidden": _home._side.hide()
			"touch_cancel":
				var cancel := InputEventScreenTouch.new()
				cancel.index = 0
				cancel.position = at
				cancel.pressed = false
				cancel.canceled = true
				get_viewport().push_input(cancel, true)
		await get_tree().process_frame
		_pointer(at if kind != "pointer_exit" else at + Vector2(180, 0), false)
		if kind == "escape":
			_key(KEY_ESCAPE, false)
		if kind == "hidden":
			_home._side.show()
		await _wait(0.350)
		_check(_activations[0] == before and _surfaces().is_empty(), "canceled_press_does_not_activate_" + kind)
		_check(not bool(_state(0).get("holding", true)) and absf(float(_state(0).get("press", 1.0))) < 0.001, "canceled_press_resets_visual_" + kind)
	# Window focus signal is injected explicitly; desktop focus is not stolen.
	await _reset_lobby()
	var at := _buttons[0].get_global_rect().get_center()
	_pointer(at, true)
	await _wait(0.080)
	get_window().focus_exited.emit()
	_pointer(at, false)
	await _wait(0.350)
	_check(_surfaces().is_empty() and not bool(_state(0).get("holding", true)), "window_focus_loss_resets_press_without_route")


func _check_pending_guards() -> void:
	await _reset_lobby()
	await _tap(_buttons[0])
	await _wait(0.035)
	_home.select_tab(_home.SHOP_TAB)
	await _wait(0.350)
	_check(_home._current == _home.SHOP_TAB and _surfaces().is_empty(), "tab_change_cancels_pending_shortcut_route")
	await _reset_lobby()
	await _tap(_buttons[0])
	await _tap(_buttons[1])
	await _tap(_buttons[2])
	await _wait(0.350)
	_check(_destination(0) and _surfaces().size() == 1, "rapid_shortcut_taps_open_only_first_destination")
	await _reset_lobby()


func _check_keyboard() -> void:
	await _reset_lobby()
	_buttons[1].grab_focus()
	await _wait(0.150)
	_check(_buttons[1].has_focus() and float(_state(1).get("focus", 0.0)) > 0.8, "keyboard_focus_has_visible_feedback")
	_key(KEY_ENTER, true)
	await _wait(0.080)
	_check(float(_state(1).get("press", 0.0)) > 0.8, "keyboard_enter_depresses_button")
	_key(KEY_ENTER, false)
	await _wait(0.350)
	_check(_destination(1), "keyboard_enter_opens_correct_destination")
	await _reset_lobby()


func _check_bounds(requested: Vector2i) -> void:
	var ratio := Vector2(requested) / get_viewport().get_visible_rect().size
	for index in KEYS.size():
		var pixels := _buttons[index].get_global_rect().size * ratio
		_check(pixels.x >= 44.0 and pixels.y >= 44.0, "native_target_at_least_44px_" + KEYS[index], requested)


func _reset_lobby() -> void:
	for entry in _surfaces():
		entry.node.queue_free()
	_home.close_page()
	_home.select_tab(_home.BATTLE_TAB, false)
	_motion(Vector2(350, 1100))
	for button in _buttons:
		button.release_focus()
	await _settle()


func _popup_close(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.custom_minimum_size == Vector2(68, 68):
			return child
		var found := _popup_close(child)
		if found != null:
			return found
	return null


func _tap(button: Button) -> void:
	if button == null or not button.is_visible_in_tree():
		return
	var at := button.get_global_rect().get_center()
	_motion(at)
	_pointer(at, true)
	await get_tree().process_frame
	_pointer(at, false)
	await get_tree().process_frame


func _pointer(at: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = at
	event.global_position = at
	get_viewport().push_input(event, true)


func _motion(at: Vector2, down := false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	get_viewport().push_input(event, true)


func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = down
	get_viewport().push_input(event, true)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _settle() -> void:
	await _wait(0.55)
	await get_tree().process_frame


func _check(passed: bool, key: String, requested := Vector2i.ZERO) -> void:
	_checks.append({"key": key, "passed": passed, "window": [requested.x, requested.y]})
	if not passed:
		_failures += 1
		push_error("LOBBY_SHORTCUT_FAIL " + key)
	print("LOBBY_SHORTCUT_CHECK ", key, " ", passed)


func _capture(key: String, requested: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var name := "%s_%dx%d" % [key, requested.x, requested.y]
	_check(image != null and image.get_size() == requested, "capture_dimensions_" + name)
	if image == null:
		return
	_images.append({"image": image, "name": name})
	var states: Array = []
	for index in KEYS.size():
		var state := _state(index).duplicate(true)
		state.erase("hit_rect")
		states.append(state)
	_captures.append({"file": name + ".png", "states": states, "context": _home.active_menu_context(), "surface_count": _surfaces().size()})


func _finish() -> void:
	for entry in _images:
		_check(entry.image.save_png(OUT.path_join(entry.name + ".png")) == OK, "capture_saved_" + entry.name)
	_images.clear()
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"persist": PlayerData.persist, "profile": OS.get_user_data_dir(), "checks": _checks, "captures": _captures, "failures": _failures, "shortcut_ids": _ids, "activations": _activations}, "\t"))
		file.close()
	print("LOBBY_SHORTCUT_INTEGRATION_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
