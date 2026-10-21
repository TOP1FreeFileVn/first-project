extends Node

# Native production lobby fixture; no player save is written.
const HOME = preload("res://game/menu/Home.tscn")
const OUT := "res://docs/ui_review/2026-10-21/castle-bubble"
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
const BASE_LEVEL := 3

var _home
var _world
var _world_id := 0
var _actor_ids: Array = []
var _bubble_id := 0
var _hint_id := 0
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
	PlayerData.castle_level = BASE_LEVEL
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.gold = 2400
	PlayerData.gems = 260
	get_window().size = SIZES[0]
	_home = HOME.instantiate()
	add_child(_home)
	_home.select_tab(_home.BATTLE_TAB, false)
	await _settle()
	_world = _home.get("_lobby_world")
	var bubble := _bubble()
	var hint := _hint()
	_check(is_instance_valid(_world), "persistent_world_created")
	_check(bubble != null, "native_castle_bubble_created")
	_check(hint != null and hint.has_method("get_review_state"), "animated_castle_hint_created")
	if not is_instance_valid(_world) or bubble == null or hint == null or not hint.has_method("get_review_state"):
		_finish()
		return
	_world_id = _world.get_instance_id()
	_actor_ids = _world.get_review_state().get("actor_ids", []).duplicate()
	_bubble_id = bubble.get_instance_id()
	_hint_id = hint.get_instance_id()
	_check(_home._side_shortcuts.size() == 3 and not _home._side_shortcuts.has("castle") and _home.find_child("CastleShortcut", true, false) == null, "three_event_shortcuts_without_castle_rail")
	for requested in SIZES:
		get_window().size = requested
		await _fixture(BASE_LEVEL, 2400)
		await _check_swipe(requested, "before_upgrade")
		await _check_rich(requested)
		await _check_exact_funds(requested)
		await _check_no_funds(requested)
		await _check_max(requested)
		await _check_details(requested)
		await _check_swipe(requested, "after_details")
		await _check_tab_round_trip(requested)
		await _check_troop_hints(requested)
	_finish()


func _bubble() -> Button:
	return _home.find_child("LobbyCastleBubble", true, false) as Button if is_instance_valid(_home) else null


func _details_upgrade() -> Button:
	return _home._overlay_page.find_child("CastleDetailsUpgrade", true, false) as Button if _home._overlay_page != null else null


func _hint() -> Control:
	return _home.find_child("CastleUpgradeHint", true, false) as Control if is_instance_valid(_home) else null


func _quiet_arrow() -> Control:
	return _bubble().find_child("CastleQuietArrow", false, false) as Control if _bubble() != null else null


func _same_entities() -> bool:
	return is_instance_valid(_world) and _home.get("_lobby_world") == _world and _world.get_instance_id() == _world_id and _world.get_review_state().get("actor_ids", []) == _actor_ids


func _same_controls() -> bool:
	return _bubble() != null and _bubble().get_instance_id() == _bubble_id and _hint() != null and _hint().get_instance_id() == _hint_id


func _fixture(level: int, gold: int) -> void:
	_home.close_page()
	_home.select_tab(_home.BATTLE_TAB, false)
	PlayerData.castle_level = level
	PlayerData.gold = gold
	PlayerData.changed.emit()
	_motion(Vector2(710, 1050))
	await _settle()


func _check_rich(requested: Vector2i) -> void:
	await _fixture(BASE_LEVEL, 2400)
	var button := _bubble()
	var hint := _hint()
	var cost := PlayerData.castle_upgrade_cost()
	_check(button.is_visible_in_tree() and not button.disabled, "funded_castle_bubble_enabled", requested)
	_check(hint.is_visible_in_tree() and hint.is_processing(), "funded_hint_visible_animated", requested)
	var scales: Array[float] = []
	for sample in 4:
		scales.append(float(hint.call("get_review_state").get("visual_scale", 1.0)))
		await _wait(0.15)
	_check(float(scales.max()) - float(scales.min()) > 0.025, "hint_scale_changes_over_time", requested)
	_check(hint.mouse_filter == Control.MOUSE_FILTER_IGNORE and not hint.clip_contents, "hint_does_not_take_pointer_or_clip", requested)
	var ratio := Vector2(requested) / get_viewport().get_visible_rect().size
	var pixels := button.get_global_rect().size * ratio
	_check(pixels.x >= 44.0 and pixels.y >= 44.0, "castle_bubble_native_target_at_least_44px", requested)
	await _capture("rich", requested)
	var old_gold: int = PlayerData.gold
	var old_clock: float = _world.get_review_state().get("clock", 0.0)
	var at := button.get_global_rect().get_center()
	_pointer(at, true)
	await get_tree().process_frame
	_check(PlayerData.castle_level == BASE_LEVEL and PlayerData.gold == old_gold and _home._overlay == null, "bubble_pointer_down_does_not_spend_or_open", requested)
	_pointer(at, false)
	await _settle()
	_check(_home._overlay_page != null and PlayerData.castle_level == BASE_LEVEL and PlayerData.gold == old_gold, "bubble_release_opens_review_without_spending", requested)
	var upgrade := _details_upgrade()
	_check(upgrade != null and not upgrade.disabled, "funded_review_upgrade_enabled", requested)
	if upgrade == null:
		return
	await _capture("funded-review", requested)
	await _tap(upgrade)
	await _settle()
	_check(PlayerData.castle_level == BASE_LEVEL + 1 and PlayerData.gold == old_gold - cost, "native_review_upgrade_spends_exact_cost_once", requested)
	var label := _home.find_child("LobbyCastleLevel", true, false) as Label
	_check(label != null and label.text.contains(str(BASE_LEVEL + 1)), "live_castle_level_label_updates", requested)
	_check(int(_world.get_review_state().get("castle_level", -1)) == BASE_LEVEL + 1, "world_castle_level_updates", requested)
	_check(_same_entities() and float(_world.get_review_state().get("clock", 0.0)) >= old_clock, "upgrade_preserves_world_actors_and_clock", requested)
	_check(_same_controls(), "upgrade_preserves_native_control_identity", requested)
	await _close_details()
	await _capture("upgraded", requested)


func _check_exact_funds(requested: Vector2i) -> void:
	await _fixture(BASE_LEVEL, 0)
	var cost := PlayerData.castle_upgrade_cost()
	PlayerData.gold = cost
	PlayerData.changed.emit()
	await _settle()
	_check(not _bubble().disabled and _hint().is_visible_in_tree() and _hint().is_processing(), "exact_funds_enable_bubble_hint", requested)
	await _tap(_bubble())
	await _settle()
	_check(PlayerData.gold == cost and PlayerData.castle_level == BASE_LEVEL, "exact_funds_bubble_opens_without_spending", requested)
	var upgrade := _details_upgrade()
	_check(upgrade != null and not upgrade.disabled, "exact_funds_review_upgrade_enabled", requested)
	if upgrade == null:
		return
	await _tap(upgrade)
	await _settle()
	_check(PlayerData.castle_level == BASE_LEVEL + 1 and PlayerData.gold == 0, "exact_funds_native_upgrade_leaves_zero_gold", requested)
	_check(_details_upgrade() != null and _details_upgrade().disabled, "spent_funds_disable_next_review_upgrade", requested)
	await _close_details()
	_check(not _bubble().disabled and not _hint().is_visible_in_tree() and not _hint().is_processing() and _quiet_arrow() != null and _quiet_arrow().is_visible_in_tree(), "spent_funds_keep_review_bubble_and_stop_hint_pulse", requested)


func _check_no_funds(requested: Vector2i) -> void:
	# Workshops remain affordable at 120; that must not activate the castle hint.
	await _fixture(BASE_LEVEL, 120)
	_check(PlayerData.can_improve_castle(), "fixture_has_affordable_workshop", requested)
	_check(not _bubble().disabled and not _hint().is_visible_in_tree() and not _hint().is_processing() and _quiet_arrow() != null and _quiet_arrow().is_visible_in_tree(), "unaffordable_castle_bubble_static_despite_workshop", requested)
	await _capture("no-funds", requested)
	await _tap(_bubble())
	await _settle()
	var upgrade := _details_upgrade()
	_check(upgrade != null and upgrade.disabled and PlayerData.castle_level == BASE_LEVEL and PlayerData.gold == 120, "unfunded_bubble_opens_disabled_review_without_spending", requested)
	await _tap(upgrade)
	await _settle()
	_check(PlayerData.castle_level == BASE_LEVEL and PlayerData.gold == 120, "disabled_native_review_upgrade_never_spends", requested)
	await _close_details()
	PlayerData.gold = 2400
	PlayerData.changed.emit()
	await _settle()
	_check(not _bubble().disabled and _hint().is_visible_in_tree() and _hint().is_processing() and _same_controls(), "funding_refresh_restores_same_hint_controls", requested)
	var old_gold: int = PlayerData.gold
	var at := _bubble().get_global_rect().get_center()
	_pointer(at, true)
	await get_tree().process_frame
	_motion(at + Vector2(200, 0), true)
	await get_tree().process_frame
	_pointer(at + Vector2(200, 0), false)
	await _settle()
	_check(_home._overlay == null and PlayerData.castle_level == BASE_LEVEL and PlayerData.gold == old_gold, "pointer_drag_off_bubble_cancels_review_and_spend", requested)


func _check_max(requested: Vector2i) -> void:
	var maximum := PlayerData.castle_max_level()
	await _fixture(maximum, 100000)
	_check(not _bubble().disabled and not _hint().is_visible_in_tree() and not _hint().is_processing() and _quiet_arrow() != null and _quiet_arrow().is_visible_in_tree(), "max_level_keeps_static_review_bubble", requested)
	await _capture("max", requested)
	await _tap(_bubble())
	await _settle()
	var upgrade := _details_upgrade()
	_check(upgrade != null and upgrade.disabled and PlayerData.castle_level == maximum and PlayerData.gold == 100000, "max_level_bubble_opens_disabled_review_without_spending", requested)
	await _tap(upgrade)
	await _settle()
	_check(PlayerData.castle_level == maximum and PlayerData.gold == 100000, "max_level_native_review_click_cannot_spend", requested)
	await _close_details()


func _check_details(requested: Vector2i) -> void:
	# The removed rail must not strand the Xưởng when no castle upgrade is available.
	await _fixture(PlayerData.castle_max_level(), 0)
	await _tap_at(Vector2(360, 450))
	await _settle()
	var page = _home._overlay_page
	_check(page != null and page.get_script().resource_path.ends_with("CastlePage.gd"), "native_castle_art_click_opens_details_at_max_without_gold", requested)
	if page == null:
		return
	_check(_contains_text(page, "Xưởng"), "castle_art_details_preserve_workshop_access", requested)
	_check(not _bubble().is_visible_in_tree() and not _hint().is_visible_in_tree() and not _hint().is_processing(), "details_hide_castle_bubble_and_stop_hint", requested)
	await _capture("castle-details", requested)
	await _close_details()
	_check(_home._overlay == null and _bubble().is_visible_in_tree() and _same_entities() and _same_controls(), "native_details_back_restores_persistent_lobby", requested)


func _check_swipe(requested: Vector2i, suffix: String) -> void:
	var page = _home._pages[_home.BATTLE_TAB]
	var original: int = page._selected
	var from := Vector2(470, 470)
	var to := Vector2(250, 470)
	_motion(from)
	_pointer(from, true)
	await get_tree().process_frame
	for i in range(1, 6):
		_motion(from.lerp(to, float(i) / 5.0), true)
		await get_tree().process_frame
	_pointer(to, false)
	await _settle()
	_check(page._selected == original + 1 and _home._overlay == null, "native_swipe_over_castle_changes_stage_without_details_" + suffix, requested)
	var prev := page.find_child("LobbyPrev", true, false) as Button
	await _tap(prev)
	await _settle()
	_check(page._selected == original and _same_entities(), "native_previous_restores_stage_" + suffix, requested)
	# A vertical courtyard drag is not a request to inspect the castle.
	var vertical_start := Vector2(360, 450)
	_motion(vertical_start)
	_pointer(vertical_start, true)
	await get_tree().process_frame
	_motion(vertical_start + Vector2(0, 60), true)
	await get_tree().process_frame
	_pointer(vertical_start + Vector2(0, 60), false)
	await _settle()
	_check(page._selected == original and _home._overlay == null, "native_vertical_drag_does_not_open_castle_" + suffix, requested)


func _check_tab_round_trip(requested: Vector2i) -> void:
	await _fixture(BASE_LEVEL, 2400)
	_home.select_tab(_home.SHOP_TAB, false)
	await _settle()
	_check(not _bubble().is_visible_in_tree() and not _hint().is_visible_in_tree() and not _hint().is_processing(), "shop_hides_castle_prompt_and_stops_motion", requested)
	_home.select_tab(_home.BATTLE_TAB, false)
	await _settle()
	_check(_bubble().is_visible_in_tree() and _hint().is_visible_in_tree() and _hint().is_processing() and _same_controls() and _same_entities(), "battle_return_resumes_same_castle_prompt_and_world", requested)
	await _capture("return-to-battle", requested)


func _check_troop_hints(requested: Vector2i) -> void:
	await _fixture(BASE_LEVEL, 2400)
	_home.select_tab(_home.TROOPS_TAB, false)
	await _settle()
	var page = _home._pages[_home.TROOPS_TAB]
	var hints: Array[Control] = []
	_collect_troop_hints(page, hints)
	_check(not hints.is_empty(), "troop_upgrade_hints_created", requested)
	var overflowing := false
	var all_large := true
	var all_passive := true
	for hint in hints:
		var card := hint.get_parent() as Control
		if card != null:
			var state: Dictionary = hint.call("get_review_state")
			var ink: Rect2 = state.get("ink_rect", Rect2())
			overflowing = overflowing or ink.position.y < card.get_global_rect().position.y
		all_large = all_large and hint.size.x >= 48.0 and hint.size.y >= 48.0
		all_passive = all_passive and hint.mouse_filter == Control.MOUSE_FILTER_IGNORE
	_check(overflowing and all_large and all_passive, "troop_arrows_large_overflowing_and_pointer_passive", requested)
	await _capture("troops-hints", requested)
	_home.select_tab(_home.BATTLE_TAB, false)
	await _settle()


func _collect_troop_hints(node: Node, found: Array[Control]) -> void:
	for child in node.get_children():
		if child is Control and str(child.name) in ["TroopLevelReady", "TroopStarReady"]:
			found.append(child)
		_collect_troop_hints(child, found)


func _close_details() -> void:
	await _tap(_direct_button(_home._overlay))
	await _settle()


func _contains_text(node: Node, wanted: String) -> bool:
	if node is Label and node.text.contains(wanted):
		return true
	for child in node.get_children():
		if _contains_text(child, wanted):
			return true
	return false


func _direct_button(node: Node) -> Button:
	if node == null:
		return null
	if node is Button:
		return node
	for child in node.get_children():
		if child is Button:
			return child
	return null


func _tap(button: Button) -> void:
	if button == null or not button.is_visible_in_tree():
		return
	await _tap_at(button.get_global_rect().get_center())


func _tap_at(at: Vector2) -> void:
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


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _settle() -> void:
	await _wait(0.30)
	await get_tree().process_frame


func _check(passed: bool, key: String, requested := Vector2i.ZERO) -> void:
	_checks.append({"key": key, "passed": passed, "window": [requested.x, requested.y]})
	if not passed:
		_failures += 1
		push_error("LOBBY_CASTLE_FAIL " + key)
	print("LOBBY_CASTLE_CHECK ", key, " ", passed)


func _capture(key: String, requested: Vector2i) -> void:
	# Park outside every action so a navigation hover caption never covers the art.
	_motion(Vector2(710, 1050))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var name := "%s_%dx%d" % [key, requested.x, requested.y]
	_check(shot != null and shot.get_size() == requested, "capture_dimensions_" + name)
	if shot == null:
		return
	_images.append({"image": shot, "name": name})
	var state: Dictionary = _hint().call("get_review_state").duplicate(true)
	state.erase("hit_rect")
	state.erase("ink_rect")
	_captures.append({"file": name + ".png", "castle_level": PlayerData.castle_level, "gold": PlayerData.gold, "cost": PlayerData.castle_upgrade_cost(), "bubble_enabled": not _bubble().disabled, "quiet_arrow_visible": _quiet_arrow() != null and _quiet_arrow().is_visible_in_tree(), "hint": state, "context": _home.active_menu_context()})


func _finish() -> void:
	for entry in _images:
		_check(entry.image.save_png(OUT.path_join(entry.name + ".png")) == OK, "capture_saved_" + entry.name)
	_images.clear()
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"persist": PlayerData.persist, "profile": OS.get_user_data_dir(), "checks": _checks, "captures": _captures, "failures": _failures}, "\t"))
		file.close()
	print("LOBBY_CASTLE_INTEGRATION_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
