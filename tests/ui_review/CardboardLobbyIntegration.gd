extends Node

# Production integration review. Run with an isolated APPDATA/LOCALAPPDATA profile.
# The fixture stays in RAM; this harness never starts a battle or changes game saves.
const OUT := "res://docs/ui_review/2026-10-20/approved-integration"
const HOME = preload("res://game/menu/Home.tscn")
const HeroCat = preload("res://game/core/HeroCat.gd")
const SIZES := [Vector2i(720, 1280), Vector2i(450, 800), Vector2i(360, 640)]

var _home
var _world
var _world_id := 0
var _actor_id := 0
var _checks: Array = []
var _captures: Array = []
var _failures := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	print("CARDBOARD_LOBBY_USER_DIR ", OS.get_user_data_dir())
	PlayerData.persist = false
	PlayerData._reset()
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
	_world = _home.get("_lobby_world")
	_check(is_instance_valid(_world), "persistent_world_created")
	if not is_instance_valid(_world):
		_finish()
		return
	_check(_world.has_method("get_review_state"), "review_state_available")
	if not _world.has_method("get_review_state"):
		_finish()
		return
	_world_id = _world.get_instance_id()
	_actor_id = int(_state().get("actor_id", 0))
	_check(_actor_id != 0, "moving_actor_created")
	await _check_refresh()
	for requested in SIZES:
		get_window().size = requested
		await _settle()
		_check(_state().get("front_only", false), "front_pose_only", requested)
		_check(_state().get("active", false) and _world.is_visible_in_tree(), "battle_world_visible_active", requested)
		_check(_uniform_scale(_state().get("world_scale", Vector2.ONE)), "uniform_world_scale", requested)
		await _capture("lobby", requested)
		await _check_levels(requested)
		await _check_shop_round_trip(requested)
		await _check_castle_round_trip(requested)
		await _check_login_rail(requested)
	await _check_hero_preview(SIZES[-1])
	_finish()


func _state() -> Dictionary:
	return _world.call("get_review_state") if is_instance_valid(_world) else {}


func _same_entities() -> bool:
	return is_instance_valid(_world) and _home.get("_lobby_world") == _world and _world.get_instance_id() == _world_id and int(_state().get("actor_id", 0)) == _actor_id


func _check_refresh() -> void:
	await get_tree().create_timer(0.25).timeout
	var before := _state()
	PlayerData.gold += 13
	PlayerData.changed.emit()
	await get_tree().process_frame
	var after := _state()
	_check(_same_entities(), "resource_refresh_preserves_world_actor")
	_check(float(after.get("clock", -1.0)) >= float(before.get("clock", 0.0)), "resource_refresh_does_not_restart_clock")
	var before_position: Vector2 = before.get("position", Vector2.ZERO)
	var after_position: Vector2 = after.get("position", Vector2.ZERO)
	_check(before_position.distance_to(after_position) < 80.0, "resource_refresh_preserves_motion_continuity")
	PlayerData.castle_level = 4
	PlayerData.changed.emit()
	await get_tree().process_frame
	_check(_same_entities() and int(_state().get("castle_level", -1)) == 4, "castle_tier_updates_without_replacing_actor")
	PlayerData.castle_level = 3
	PlayerData.changed.emit()
	await _settle()


func _check_levels(requested: Vector2i) -> void:
	var page = _home._pages[_home.BATTLE_TAB]
	var selected: int = page._selected
	var next: Button = page.find_child("LobbyNext", true, false)
	var tapped := await _tap(next)
	await _settle()
	_check(tapped and page._selected == selected + 1, "real_click_next_level", requested)
	var cta: Button = page.find_child("LobbyBattleButton", true, false)
	_check(cta != null and cta.is_visible_in_tree() and cta.disabled, "locked_stage_cta_visible_disabled", requested)
	if requested == SIZES[1]:
		await _capture("locked", requested)
	var prev: Button = page.find_child("LobbyPrev", true, false)
	tapped = await _tap(prev)
	await _settle()
	_check(tapped and page._selected == selected, "real_click_previous_level", requested)
	cta = page.find_child("LobbyBattleButton", true, false)
	_check(cta != null and cta.is_visible_in_tree() and not cta.disabled and not cta.pressed.get_connections().is_empty(), "unlocked_cta_enabled_connected_without_starting_battle", requested)
	_check(_same_entities(), "level_changes_preserve_world_actor", requested)


func _check_shop_round_trip(requested: Vector2i) -> void:
	var tapped := await _tap(_nav_button(_home.SHOP_TAB))
	await _settle()
	_check(tapped and _home._current == _home.SHOP_TAB, "real_click_shop_nav", requested)
	_check(not _state().get("active", true) and not _world.is_visible_in_tree(), "world_hidden_paused_in_shop", requested)
	var before: float = _state().get("clock", -1.0)
	await get_tree().create_timer(0.20).timeout
	_check(is_equal_approx(float(_state().get("clock", -2.0)), before), "shop_hidden_clock_stays_paused", requested)
	if requested == SIZES[1]:
		await _capture("shop", requested)
	tapped = await _tap(_nav_button(_home.BATTLE_TAB))
	await _settle()
	_check(tapped and _home._current == _home.BATTLE_TAB and _same_entities(), "real_click_battle_nav_resumes_same_actor", requested)
	_check(_state().get("active", false) and not is_equal_approx(float(_state().get("clock", -1.0)), before), "battle_clock_resumes", requested)


func _check_castle_round_trip(requested: Vector2i) -> void:
	var tapped := await _tap_castle_art()
	await _settle()
	_check(tapped and _home._overlay != null and _home._overlay_page != null, "real_click_castle_illustration", requested)
	if _home._overlay == null:
		return
	_check(not _state().get("active", true) and not _world.is_visible_in_tree(), "world_hidden_paused_under_castle_page", requested)
	var before: float = _state().get("clock", -1.0)
	await get_tree().create_timer(0.20).timeout
	_check(is_equal_approx(float(_state().get("clock", -2.0)), before), "castle_overlay_clock_stays_paused", requested)
	tapped = await _tap(_direct_button(_home._overlay))
	await _settle()
	_check(tapped and _home._overlay == null and _home._side.is_visible_in_tree(), "real_click_castle_back", requested)
	_check(_same_entities() and _state().get("active", false), "castle_close_resumes_same_world", requested)


func _check_login_rail(requested: Vector2i) -> void:
	var wrapper: Node = _home._side.find_child("LoginShortcut", true, false)
	var tapped := await _tap(_direct_button(wrapper))
	await _settle()
	var popup := _active_popup()
	_check(tapped and popup != null, "real_click_login_rail", requested)
	if popup == null:
		return
	var close := _popup_close(popup)
	tapped = await _tap(close, Vector2(0.3, 0.8))
	await _settle()
	_check(tapped and not is_instance_valid(popup), "real_click_login_close", requested)


func _check_hero_preview(requested: Vector2i) -> void:
	var tapped := await _tap(_nav_button(_home.HERO_TAB))
	await _settle()
	_check(tapped and _home._current == _home.HERO_TAB, "real_click_hero_nav", requested)
	_check(not _state().get("active", true) and not _world.is_visible_in_tree(), "world_hidden_on_hero_page", requested)
	await _capture("hero", requested)
	var page = _home._pages[_home.HERO_TAB]
	var uid: String = HeroCat.equipped_uid(PlayerData.hero_cat, "weapon")
	_check(not uid.is_empty(), "fixture_has_equipped_weapon")
	if not uid.is_empty():
		page._open_detail(uid)
		await _settle()
		_check(_active_popup() != null, "equipment_detail_opens")
		await _capture("equipment-detail", requested)
		var popup := _active_popup()
		if popup != null:
			await _tap(_popup_close(popup))
			await _settle()


func _uniform_scale(value: Vector2) -> bool:
	return value.x > 0.0 and is_equal_approx(value.x, value.y)


func _nav_button(index: int) -> Button:
	if _home._nav_holder.get_child_count() == 0:
		return null
	var bar: Control = _home._nav_holder.get_child(0)
	if index >= bar.get_child_count():
		return null
	return _direct_button(bar.get_child(index))


func _direct_button(node: Node) -> Button:
	if node is Button:
		return node
	if node == null:
		return null
	for child in node.get_children():
		if child is Button:
			return child
	return null


func _active_popup() -> Control:
	for child in _home.get_children():
		if child is ColorRect and child.mouse_filter == Control.MOUSE_FILTER_STOP:
			return child
	return null


func _popup_close(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.custom_minimum_size == Vector2(68, 68):
			return child
		var found := _popup_close(child)
		if found != null:
			return found
	return null


func _tap_castle_art() -> bool:
	var stage: Control = _home._pages[_home.BATTLE_TAB]._stage
	var at := Vector2(360, 450)
	if stage == null or not stage.is_visible_in_tree() or not stage.get_global_rect().has_point(at):
		return false
	var received := [false]
	var observe := func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			received[0] = true
	stage.gui_input.connect(observe)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	stage.gui_input.disconnect(observe)
	return received[0]


func _tap(button: Button, point := Vector2(0.5, 0.5)) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var rect := button.get_global_rect()
	var at := rect.position + rect.size * point
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	return received[0]


func _settle() -> void:
	await get_tree().create_timer(0.24).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _check(passed: bool, name: String, requested := Vector2i.ZERO) -> void:
	_checks.append({"name": name, "passed": passed, "window": [requested.x, requested.y]})
	if not passed:
		_failures += 1
		push_error("CARDBOARD_LOBBY_FAIL " + name + " " + str(requested))
	print("CARDBOARD_LOBBY_CHECK ", name, " ", requested, " ", passed)


func _capture(name: String, requested: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var key := "%s_%dx%d" % [name, requested.x, requested.y]
	_check(shot != null and shot.get_size() == requested, "native_capture_size_" + key, requested)
	if shot == null:
		return
	_check(shot.save_png(OUT.path_join(key + ".png")) == OK, "capture_saved_" + key, requested)
	_captures.append({"file": key + ".png", "window": [requested.x, requested.y], "world": _json_state(_state())})


func _json_state(state: Dictionary) -> Dictionary:
	var value := state.duplicate(true)
	for key in value:
		if value[key] is Vector2:
			value[key] = [value[key].x, value[key].y]
	return value


func _finish() -> void:
	var result := {"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"scope": "Production Home integration, real UI clicks, RAM fixture; no battle start.",
		"checks": _checks, "captures": _captures, "failures": _failures,
		"persistent_world_id": _world_id, "moving_actor_id": _actor_id}
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result, "\t"))
		file.close()
	else:
		_failures += 1
	print("CARDBOARD_LOBBY_INTEGRATION_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
