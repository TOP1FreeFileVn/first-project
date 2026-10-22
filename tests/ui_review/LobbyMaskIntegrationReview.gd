extends Node

# Verify the real Home and production shortcuts, with no demo substitution.
const HOME = preload("res://game/menu/Home.tscn")
const OUT := "res://docs/ui_review/2026-10-22/lobby-mask-integration"
const SIZES := [Vector2i(450, 800), Vector2i(360, 640)]
const RAIL_NAMES := ["LobbyShortcutRailLeft", "LobbyShortcutRailRight"]
const KEYS := ["login", "quests", "events"]

var _home
var _size := Vector2i.ZERO
var _checks: Array = []
var _captures: Array = []
var _interaction_states: Array = []
var _failed := 0
var _rail_ids: Dictionary = {}
var _shortcut_ids: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	for requested in SIZES:
		_size = requested
		_fixture()
		get_window().size = requested
		_home = HOME.instantiate()
		add_child(_home)
		_home.select_tab(_home.BATTLE_TAB, false)
		await _settle()
		_remember_nodes()
		_check_rails("initial")
		_check_action_layout("initial")
		await _capture("home")
		await _review_feedback()
		_check(_home.active_menu_context() == "login", "native_login_destination")
		await _capture("login")
		await _close_popup("login")
		for key in ["quests", "events"]:
			_check(await _tap(_home._side_shortcuts[key]), "native_" + key + "_shortcut_tap")
			await _settle()
			_check(_home.active_menu_context() == key and _surface() != null, "native_" + key + "_destination")
			await _capture(key)
			await _close_popup(key)
		var login: Button = _home._side_shortcuts.login
		_check(login.get_review_state().alert, "initial_login_badge_ready")
		PlayerData.login_day = PlayerData.today()
		PlayerData.changed.emit()
		await _settle()
		_check(not login.get_review_state().alert, "badge_refresh_updates_alert")
		_check_rails("badge-refresh")
		await _capture("badge-refresh")
		_check(await _tap(_nav_button(_home.SHOP_TAB)), "native_shop_tab_roundtrip_out")
		await _settle()
		_check(_home._current == _home.SHOP_TAB and not _home._side.is_visible_in_tree(), "shop_hides_shortcut_columns")
		_check(await _tap(_nav_button(_home.BATTLE_TAB)), "native_battle_tab_roundtrip_back")
		await _settle()
		_check(_home._side.is_visible_in_tree() and _home.active_menu_context() == "battle", "battle_restores_shortcut_columns")
		_check_rails("tab-roundtrip")
		_check_action_layout("tab-roundtrip")
		await _capture("tab-roundtrip")
		_check(not PlayerData.persist, "review_never_persists")
		_home.queue_free()
		await get_tree().process_frame
	_finish()


func _fixture() -> void:
	PlayerData._reset()
	PlayerData.persist = false
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.login_claimed = 0
	PlayerData.login_day = PlayerData.today() - 1


func _remember_nodes() -> void:
	_rail_ids.clear()
	_shortcut_ids.clear()
	for name in RAIL_NAMES:
		var rail: Node = _home.find_child(name, true, false)
		if rail != null:
			_rail_ids[name] = rail.get_instance_id()
	for key in KEYS:
		_shortcut_ids[key] = _home._side_shortcuts[key].get_instance_id()


func _check_rails(context: String) -> void:
	for name in RAIL_NAMES:
		var rail: PanelContainer = _home.find_child(name, true, false)
		_check(rail != null and rail.is_visible_in_tree(), context + "_visible_" + name)
		if rail == null:
			continue
		_check(rail.get_instance_id() == _rail_ids.get(name, -1), context + "_same_fixed_rail_" + name)
		var style := rail.get_theme_stylebox("panel")
		_check(style is StyleBoxFlat, context + "_shared_flat_mask_" + name)
		if style is StyleBoxFlat:
			_check(style.bg_color.is_equal_approx(Color("3f493f", 0.48)), context + "_approved_mask_color_" + name)
			_check(style.border_width_left == 0 and style.border_width_right == 0 and style.border_width_top == 0 and style.border_width_bottom == 0 and style.shadow_size == 0, context + "_no_mask_outline_or_shadow_" + name)
		var column := rail.get_child(0) as VBoxContainer
		_check(column != null and column.get_theme_constant("separation") == 0, context + "_continuous_compact_column_" + name)
		if column != null:
			_check(column.get_child_count() == (2 if name.ends_with("Left") else 1), context + "_correct_group_count_" + name)
	for key in KEYS:
		var shortcut: Button = _home._side_shortcuts[key]
		_check(shortcut.get_script().resource_path == "res://game/ui/LobbyShortcut.gd", context + "_production_shortcut_script_" + key)
		_check(shortcut.get_instance_id() == _shortcut_ids[key], context + "_same_native_shortcut_" + key)
		_check(shortcut.custom_minimum_size == Vector2(108, 128), context + "_preserved_native_hit_target_" + key)
		_check(shortcut.ICON_RECT == Rect2(12, 2, 84, 84) and shortcut.CAPTION_SIZE == 20.0, context + "_approved_icon_caption_scale_" + key)


func _check_action_layout(context: String) -> void:
	var page: Control = _home._pages[_home.BATTLE_TAB]
	var pager: Control = page.find_child("LobbyPager", true, false)
	var action: Control = page.find_child("BattleActionBlock", true, false)
	var button: Button = page.find_child("LobbyBattleButton", true, false)
	var rewards: Control = page.find_child("LobbyRewards", true, false)
	_check(pager != null and is_equal_approx(pager.get_global_rect().position.y, 150.0), context + "_stage_header_y_preserved")
	_check(action != null and action.get_parent() == page._column and page._column.offset_bottom == 0.0, context + "_lowered_action_group_in_production")
	if button != null and rewards != null:
		_check(button.get_global_rect().position.y > rewards.get_global_rect().end.y, context + "_reward_row_above_battle_button")
		_check(_home._nav_holder.get_global_rect().position.y - button.get_global_rect().end.y >= 18.0, context + "_battle_button_clears_bottom_navigation_at_pulse")


func _review_feedback() -> void:
	var shortcut: Button = _home._side_shortcuts.login
	var rail: Control = _home.find_child(RAIL_NAMES[0], true, false)
	var rail_rect := rail.get_global_rect()
	var point: Vector2 = get_tree().root.get_final_transform() * shortcut.get_global_rect().get_center()
	_motion(point)
	await get_tree().create_timer(0.18).timeout
	_interaction_states.append({"window": [_size.x, _size.y], "phase": "hover", "state": shortcut.get_review_state()})
	_check(shortcut.get_review_state().focus > 0.9, "native_hover_feedback")
	_check(rail.get_global_rect().is_equal_approx(rail_rect), "hover_keeps_shared_strip_fixed")
	await _capture("hover")
	_pointer(point, true)
	await get_tree().create_timer(0.12).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	_interaction_states.append({"window": [_size.x, _size.y], "phase": "held-press", "state": shortcut.get_review_state()})
	_check(shortcut.get_review_state().holding and shortcut.get_review_state().press > 0.9, "native_held_press_feedback")
	_check(rail.get_global_rect().is_equal_approx(rail_rect), "press_keeps_shared_strip_fixed")
	await _capture("pressed")
	_pointer(point, false)
	await get_tree().create_timer(0.07).timeout
	_interaction_states.append({"window": [_size.x, _size.y], "phase": "release", "state": shortcut.get_review_state()})
	await _capture("release")
	await _settle()


func _surface() -> Control:
	for i in range(_home._menu_surfaces.size() - 1, -1, -1):
		var node = _home._menu_surfaces[i].node
		if is_instance_valid(node) and not node.is_queued_for_deletion() and node is Control:
			return node
	return null


func _close_popup(context: String) -> void:
	var surface := _surface()
	var close: Button
	if surface != null:
		for node: Button in surface.find_children("*", "Button", true, false):
			if node.custom_minimum_size == Vector2(68, 68):
				close = node
				break
	_check(await _tap(close), "native_close_" + context)
	await _settle()
	_check(_surface() == null and _home.active_menu_context() == "battle", "native_return_from_" + context)


func _nav_button(index: int) -> Button:
	var bar: Node = _home._nav_holder.get_child(0)
	for child in bar.get_child(index).get_children():
		if child is Button:
			return child
	return null


func _tap(button: Button) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var point := get_tree().root.get_final_transform() * button.get_global_rect().get_center()
	_motion(point)
	await get_tree().process_frame
	_pointer(point, true)
	await get_tree().process_frame
	_pointer(point, false)
	await get_tree().process_frame
	return received[0]


func _motion(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)


func _pointer(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)


func _settle() -> void:
	await get_tree().create_timer(0.38).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var picture := get_viewport().get_texture().get_image()
	var name := "%s_%dx%d.png" % [label, _size.x, _size.y]
	_check(picture.get_size() == _size and picture.save_png(OUT.path_join(name)) == OK, "native_capture_" + label)
	var rails := {}
	var shortcuts := {}
	for rail_name in RAIL_NAMES:
		var rail: Control = _home.find_child(rail_name, true, false)
		if rail != null:
			rails[rail_name] = _rect(rail.get_global_rect())
	for key in KEYS:
		shortcuts[key] = _rect(_home._side_shortcuts[key].get_global_rect())
	_captures.append({"file": name, "window": [_size.x, _size.y], "rails": rails, "shortcuts": shortcuts})


func _rect(value: Rect2) -> Array:
	return [value.position.x, value.position.y, value.size.x, value.size.y]


func _check(ok: bool, label: String) -> void:
	_checks.append({"name": label, "passed": ok, "window": [_size.x, _size.y]})
	if not ok:
		_failed += 1
		push_error("LOBBY_MASK_INTEGRATION_FAIL " + label + " " + str(_size))


func _finish() -> void:
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"production_home": true, "demo_substitution": false, "checks": _checks, "captures": _captures,
		"interaction_states": _interaction_states, "failures": _failed}, "\t"))
	file.close()
	print("LOBBY_MASK_INTEGRATION_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failed)
	get_tree().quit(1 if _failed > 0 else 0)
