extends Node

# Run through the production Home scene with a disposable APPDATA/LOCALAPPDATA profile.
# This fixture stays in RAM and never routes into battle or purchases equipment.
const HOME = preload("res://game/menu/Home.tscn")
const CASTLE_PAGE = preload("res://game/menu/pages/CastlePage.gd")
const OUT := "res://docs/ui_review/2026-10-21/carton-nav"
const NAMES := ["shop", "hero", "battle", "troops", "summon"]
const SIZES := [Vector2i(360, 640), Vector2i(720, 1280)]

var _out := OUT
var _caption_review := false
var _home
var _bar: Control
var _bar_id := 0
var _cell_ids: Array = []
var _checks: Array = []
var _captures: Array = []
var _pending_images: Array = []
var _failures := 0


func _ready() -> void:
	_caption_review = "--caption-review" in OS.get_cmdline_user_args()
	if _caption_review:
		_out = OUT + "-caption"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	get_window().size = SIZES[0]
	_home = HOME.instantiate()
	add_child(_home)
	_home.select_tab(_home.BATTLE_TAB, false)
	await _settle()
	_bar = _home.get("_nav_bar")
	_check(is_instance_valid(_bar), "persistent_carton_bar_created")
	if not is_instance_valid(_bar):
		_finish()
		return
	_check(_bar.has_method("get_review_state"), "component_review_state_available")
	if not _bar.has_method("get_review_state"):
		_finish()
		return
	_bar_id = _bar.get_instance_id()
	_check(_bar.get_child_count() >= 5, "five_persistent_tab_wrappers")
	if _bar.get_child_count() < 5:
		_finish()
		return
	for index in 5:
		_cell_ids.append(_bar.get_child(index).get_instance_id())
		_check(_nav_button(index) != null, "direct_native_button_%d" % index)
	_check(_state().get("selected", -1) == _home.BATTLE_TAB, "initial_battle_selection")
	_check_page_selection()
	if _caption_review:
		await _capture_caption_review()
		_finish()
		return
	await _check_motion()
	await _check_rapid_and_retap()
	await _check_data_and_badges()
	await _check_overlay_and_modal()
	for requested in SIZES:
		get_window().size = requested
		await _settle()
		for index in 5:
			await _tap(_nav_button(index))
			await _settle()
			_check(_home._current == index, "pointer_selects_%s" % NAMES[index], requested)
			_check(_same_entities(), "selection_preserves_bar_and_cells_%s" % NAMES[index], requested)
			_check_page_selection(requested)
			_check_bounds(requested)
			if requested == SIZES[0] or index == _home.BATTLE_TAB:
				await _capture(NAMES[index], requested)
	_finish()


func _capture_caption_review() -> void:
	# Diagnostic captures only. Judge real glyph pixels in these native images;
	# caption_ink metadata is recorded to aid inspection, not asserted against itself.
	for requested in [Vector2i(360, 640), Vector2i(450, 800)]:
		get_window().size = requested
		await _settle()
		for index in 5:
			_home.select_tab(index, false)
			await get_tree().process_frame
			await _capture(NAMES[index], requested)


func _state() -> Dictionary:
	return _bar.call("get_review_state")


func _cell(index: int) -> Dictionary:
	var cells: Array = _state().get("cells", [])
	return cells[index] if index < cells.size() else {}


func _same_entities() -> bool:
	if not is_instance_valid(_bar) or _home.get("_nav_bar") != _bar or _bar.get_instance_id() != _bar_id:
		return false
	for index in 5:
		if _bar.get_child(index).get_instance_id() != _cell_ids[index]:
			return false
	return true


func _check_motion() -> void:
	_home.select_tab(_home.BATTLE_TAB, false)
	await _settle()
	var button := _nav_button(_home.SHOP_TAB)
	var at := button.get_global_rect().get_center()
	_pointer(at, true)
	await _wait(0.085)
	_check(float(_cell(_home.SHOP_TAB).get("press", 1.0)) < 0.99, "native_pointer_down_compresses_carton")
	_check(_home._current == _home.BATTLE_TAB, "pointer_down_does_not_select_before_release")
	await _capture("press", SIZES[0])
	_pointer(at, false)
	var start := Time.get_ticks_usec()
	await get_tree().process_frame
	_check(_home._current == _home.SHOP_TAB, "native_pointer_release_selects_shop")
	_check(_same_entities(), "release_keeps_component_and_cell_instances")
	for target_ms in [25, 100, 220]:
		# Sample after drawing: process_frame is emitted before Tween updates.
		# Save PNGs only after the review so encoding cannot stall this timeline.
		await _wait_until(start + target_ms * 1000)
		await _capture("opening_%03dms" % target_ms, SIZES[0], {"release_start_usec": start, "requested_elapsed_ms": target_ms})
		var incoming := _cell(_home.SHOP_TAB)
		var outgoing := _cell(_home.BATTLE_TAB)
		if target_ms == 25:
			_check(float(incoming.get("lid", -1.0)) > 0.0 and float(incoming.get("lid", 1.0)) < 1.0, "opening_has_intermediate_flap_phase")
		if target_ms == 100:
			_check(float(incoming.get("lift", -1.0)) > 0.0 and float(incoming.get("lift", 1.0)) < 1.2, "icon_lifts_during_opening")
			_check(float(outgoing.get("lift", 1.0)) < 1.0, "outgoing_icon_recedes_before_closing")
			_check(float(outgoing.get("lid", 0.0)) > 0.0 and float(outgoing.get("lid", 1.0)) < 1.0, "outgoing_flaps_close_through_intermediate_phase")
	await _settle()
	_check_settled(_home.SHOP_TAB, "opening_settles")
	_check(_same_entities(), "opening_does_not_rebuild_nav")


func _check_rapid_and_retap() -> void:
	for index in [_home.HERO_TAB, _home.TROOPS_TAB, _home.SUMMON_TAB, _home.BATTLE_TAB]:
		await _tap(_nav_button(index))
		await _wait(0.025)
	await _settle()
	_check(_home._current == _home.BATTLE_TAB and _state().get("selected", -1) == _home.BATTLE_TAB, "rapid_pointer_switch_last_tab_wins")
	_check_settled(_home.BATTLE_TAB, "rapid_switch_settles_without_stranded_flaps")
	await _tap(_nav_button(_home.SHOP_TAB))
	await _wait(0.075)
	var before := _cell(_home.SHOP_TAB)
	await _tap(_nav_button(_home.SHOP_TAB))
	var after := _cell(_home.SHOP_TAB)
	_check(float(after.get("lid", -1.0)) >= float(before.get("lid", 0.0)), "same_tab_retap_does_not_restart_flaps")
	_check(float(after.get("lift", -1.0)) >= float(before.get("lift", 0.0)), "same_tab_retap_does_not_restart_icon_lift")
	await _settle()
	_check_settled(_home.SHOP_TAB, "same_tab_retap_settles")
	_check(_same_entities(), "rapid_switch_and_retap_preserve_instances")


func _check_data_and_badges() -> void:
	var before := _state()
	PlayerData.gold += 17
	PlayerData.changed.emit()
	_home.call("_on_tick")
	await get_tree().process_frame
	_check(_same_entities(), "data_and_tick_refresh_preserve_bar_and_cells")
	_check(_state().get("selected", -1) == before.get("selected", -2), "data_refresh_preserves_selection")
	for index in 5:
		var expected: bool = index != _home._current and _home._pages[index].has_alert()
		_check(bool(_cell(index).get("badge", false)) == expected, "production_badge_matches_page_%s" % NAMES[index])
	_bar.call("set_badges", [1, 4])
	# Read this direct component mutation synchronously: Home's periodic production
	# refresh deliberately restores the real badge set on the next timer tick.
	_check(bool(_cell(1).get("badge", false)) and bool(_cell(4).get("badge", false)), "badge_update_reuses_cells")
	_check(_same_entities(), "badge_update_preserves_instances")
	# Restore the production badge set directly; Home may cache the unchanged key.
	var production: Array = []
	for index in 5:
		if index != _home._current and _home._pages[index].has_alert():
			production.append(index)
	_bar.call("set_badges", production)
	_home.select_tab(_home.HERO_TAB, true)
	await _wait(0.070)
	var phase := float(_cell(_home.HERO_TAB).get("lid", 0.0))
	PlayerData.gold += 1
	PlayerData.changed.emit()
	await get_tree().process_frame
	_check(float(_cell(_home.HERO_TAB).get("lid", -1.0)) >= phase, "data_refresh_during_motion_does_not_restart_opening")
	await _settle()
	_check(_same_entities(), "data_refresh_during_motion_preserves_instances")


func _check_overlay_and_modal() -> void:
	_home.select_tab(_home.BATTLE_TAB, false)
	_home.open_page(CASTLE_PAGE)
	await _settle()
	_check(_home._overlay != null and _bar.is_visible_in_tree(), "page_overlay_keeps_carton_navigation_available")
	await _tap(_nav_button(_home.HERO_TAB))
	await _settle()
	_check(_home._overlay == null and _home._current == _home.HERO_TAB, "carton_tab_closes_overlay_and_selects_page")
	_check(_same_entities(), "overlay_close_preserves_cartons")
	var modal := CanvasLayer.new()
	modal.name = "CartonReviewModal"
	_home.add_child(modal)
	var blocker := ColorRect.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(blocker)
	_home.register_menu_surface(modal, "hero")
	await get_tree().process_frame
	_check(not _bar.is_visible_in_tree() and not _home._nav_holder.visible, "registered_full_screen_modal_hides_carton_nav")
	modal.queue_free()
	await _settle()
	_check(_bar.is_visible_in_tree() and _home._nav_holder.visible, "modal_close_restores_same_carton_nav")
	_check(_same_entities(), "modal_visibility_cycle_preserves_instances")


func _check_page_selection(requested := Vector2i.ZERO) -> void:
	var visible_count := 0
	for index in 5:
		if _home._pages[index].visible:
			visible_count += 1
		_check(_home._pages[index].visible == (index == _home._current), "page_visibility_%s" % NAMES[index], requested)
	_check(visible_count == 1, "exactly_one_page_selected", requested)
	_check(_state().get("selected", -1) == _home._current, "bar_matches_production_selected_page", requested)


func _check_settled(index: int, prefix: String) -> void:
	for i in 5:
		var expected := 1.0 if i == index else 0.0
		var value := _cell(i)
		_check(is_equal_approx(float(value.get("lid", -1.0)), expected) and is_equal_approx(float(value.get("lift", -1.0)), expected), "%s_%s" % [prefix, NAMES[i]])
		_check(is_equal_approx(float(value.get("press", -1.0)), 1.0), "%s_press_released_%s" % [prefix, NAMES[i]])
		_check(not bool(value.get("animating", true)), "%s_motion_stopped_%s" % [prefix, NAMES[i]])


func _check_bounds(requested: Vector2i) -> void:
	var logical := get_viewport().get_visible_rect()
	var ratio := Vector2(requested) / logical.size
	var previous := Rect2()
	for index in 5:
		var button := _nav_button(index)
		if button == null:
			_check(false, "touch_button_missing_%s" % NAMES[index], requested)
			continue
		var rect := button.get_global_rect()
		var effective := rect.intersection(logical)
		var pixels := effective.size * ratio
		_check(effective.size.x > 0.0 and effective.size.y > 0.0, "touch_target_on_screen_%s" % NAMES[index], requested)
		_check(pixels.x >= 44.0 and pixels.y >= 44.0, "touch_target_at_least_44px_%s" % NAMES[index], requested)
		if index > 0:
			_check(previous.end.x <= rect.position.x + 0.1, "neighbor_touch_targets_do_not_overlap_%d" % index, requested)
		previous = rect


func _nav_button(index: int) -> Button:
	if not is_instance_valid(_bar) or index >= _bar.get_child_count():
		return null
	for child in _bar.get_child(index).get_children():
		if child is Button:
			return child
	return null


func _pointer(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	get_viewport().push_input(event, true)


func _tap(button: Button) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var at := button.get_global_rect().get_center()
	_pointer(at, true)
	await get_tree().process_frame
	_pointer(at, false)
	await get_tree().process_frame
	return received[0]


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _wait_until(deadline_usec: int) -> void:
	while Time.get_ticks_usec() < deadline_usec:
		await get_tree().process_frame


func _settle() -> void:
	await _wait(0.42)
	await get_tree().process_frame
	await get_tree().process_frame


func _check(passed: bool, name: String, requested := Vector2i.ZERO) -> void:
	_checks.append({"name": name, "passed": passed, "window": [requested.x, requested.y]})
	if not passed:
		_failures += 1
		push_error("CARTON_NAV_FAIL " + name + " " + str(requested))
	print("CARTON_NAV_CHECK ", name, " ", requested, " ", passed)


func _capture(name: String, requested: Vector2i, extra := {}) -> void:
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var key := "%s_%dx%d" % [name, requested.x, requested.y]
	_check(shot != null and shot.get_size() == requested, "native_capture_size_" + key, requested)
	if shot == null:
		return
	if extra.has("release_start_usec"):
		extra["release_elapsed_ms"] = float(Time.get_ticks_usec() - int(extra.release_start_usec)) / 1000.0
		extra.erase("release_start_usec")
	_pending_images.append({"image": shot, "key": key, "window": requested})
	_captures.append({"file": key + ".png", "window": [requested.x, requested.y], "state": _json_safe(_state()), "timing": extra})


func _json_safe(value: Variant) -> Variant:
	if value is Vector2 or value is Vector2i:
		return [value.x, value.y]
	if value is Rect2:
		return {"position": _json_safe(value.position), "size": _json_safe(value.size)}
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _json_safe(value[key])
		return result
	if value is Array:
		var result := []
		for entry in value:
			result.append(_json_safe(entry))
		return result
	return value


func _finish() -> void:
	for pending in _pending_images:
		var saved: Error = pending.image.save_png(_out.path_join(pending.key + ".png"))
		_check(saved == OK, "capture_saved_" + pending.key, pending.window)
	_pending_images.clear()
	var result := {"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"scope": "Production Home, native pointer events, RAM-only fixture; no battle or purchase.",
		"caption_review_only": _caption_review,
		"checks": _checks, "captures": _captures, "failures": _failures,
		"persistent_bar_id": _bar_id, "persistent_cell_ids": _cell_ids}
	var file := FileAccess.open(_out.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result, "\t"))
		file.close()
	else:
		_failures += 1
	print("CARTON_NAV_INTEGRATION_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
