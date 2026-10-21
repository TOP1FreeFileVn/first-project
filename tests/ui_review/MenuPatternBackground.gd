extends Node

# Real Home routes and shared fullscreen pattern; RAM fixture and isolated profile.
const HOME = preload("res://game/menu/Home.tscn")
const Ui = preload("res://game/ui/Ui.gd")
const MetaPopups = preload("res://game/menu/popups/MetaPopups.gd")
const CastlePage = preload("res://game/menu/pages/CastlePage.gd")
const OUT := "res://docs/ui_review/2026-10-21/menu-pattern-background"
const SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]
const TABS := {0: "shop", 1: "hero", 3: "troops", 4: "summon"}

var _home
var _world
var _pattern: ColorRect
var _size := Vector2i.ZERO
var _world_id := 0
var _actor_ids: Array = []
var _pattern_id := 0
var _checks: Array = []
var _captures: Array = []
var _motions: Array = []
var _colors: Dictionary = {}
var _failed := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	PlayerData.login_claimed = 3
	PlayerData.login_day = PlayerData.today() - 1
	PlayerData.patrol_last_claim = PlayerData.now() - 3 * 3600
	_home = HOME.instantiate()
	add_child(_home)
	_world = _home.get("_lobby_world")
	_pattern = _home.find_child("MenuPatternBackground", false, false)
	_check(_home.has_method("active_menu_context") and _home.has_method("register_menu_surface"), "background_context_api_available")
	_check(_pattern != null, "persistent_pattern_node_created")
	if _pattern == null or not _home.has_method("active_menu_context"):
		_finish()
		return
	_world_id = _world.get_instance_id()
	_actor_ids = _state().actor_ids.duplicate()
	_pattern_id = _pattern.get_instance_id()
	for requested in SIZES:
		_size = requested
		get_window().size = requested
		_home.select_tab(_home.BATTLE_TAB, false)
		await _settle()
		_check_context("battle", "initial_battle")
		await _capture("battle-before")
		for tab in TABS:
			await _tab_round_trip(tab, TABS[tab])
		for context in ["castle", "login", "quests", "events", "patrol"]:
			await _surface_round_trip(context, false)
		for context in ["profile", "settings"]:
			await _header_popup_round_trip(context, "battle")
		await _stacked_surface_case()
		_check(await _tap(_nav_button(_home.SHOP_TAB)), "native_shop_entry_for_overlay_routes")
		await _settle()
		_check_context("shop", "shop_base")
		for context in ["castle", "login", "quests", "events", "patrol"]:
			await _surface_round_trip(context, true)
		for context in ["profile", "settings"]:
			await _header_popup_round_trip(context, "shop")
		await _events_login_transition()
		await _capture("shop-restored")
		_check(await _tap(_nav_button(_home.BATTLE_TAB)), "native_battle_return_after_shop_routes")
		await _settle()
		_check_context("battle", "final_battle")
		await _capture("battle-after")
	var distinct: Dictionary = {}
	for context in _colors:
		distinct[_colors[context]] = true
	_check(distinct.size() >= 4, "menu_contexts_have_distinct_suitable_color_families")
	_home.queue_free()
	await get_tree().process_frame
	await _combat_probe()
	_finish()


func _tab_round_trip(tab: int, context: String) -> void:
	_check(await _tap(_nav_button(tab)), "native_nav_to_" + context)
	await _settle()
	_check_context(context, context + "_tab")
	await _assert_paused(context + "_tab")
	await _capture(context)
	if context == "hero":
		await _pattern_motion()
	_check(await _tap(_nav_button(_home.BATTLE_TAB)), "native_nav_return_from_" + context)
	await _settle()
	_check_context("battle", "battle_after_" + context)


func _surface_round_trip(context: String, over_shop: bool) -> void:
	var base := "shop" if over_shop else "battle"
	if context == "patrol":
		await _open_events(over_shop)
		var hub := _active_popup()
		_check(hub != null, base + "_events_hub_available_for_patrol")
		if hub == null:
			return
		_check(await _tap(_row_button(hub, "Tuần tra")), base + "_native_events_to_patrol")
	elif over_shop:
		match context:
			"castle": _home.open_page(CastlePage)
			"login": MetaPopups.open_login(_home)
			"quests": MetaPopups.open_quests(_home)
			"events": MetaPopups.open_events(_home)
	elif context == "castle":
		_check(await _tap_castle_art(), "native_battle_illustration_to_castle")
	else:
		var names := {"login": "LoginShortcut", "quests": "QuestsShortcut", "events": "EventsShortcut"}
		_check(await _tap(_direct_button(_home._side.find_child(names[context], true, false))), "native_battle_rail_to_" + context)
	await _settle()
	_check_context(context, base + "_overlay_" + context)
	await _assert_paused(base + "_overlay_" + context)
	if context == "castle" or context == "patrol":
		_check(_home._overlay != null and _home._overlay_page != null, base + "_page_overlay_exists_" + context)
		_check(not _home._content.visible, base + "_page_overlay_hides_underlying_content_" + context)
	if not over_shop or context == "castle" or context == "patrol":
		await _capture(base + "-" + context)
	var close: Button = _direct_button(_home._overlay) if context == "castle" or context == "patrol" else _close_button(_active_popup())
	_check(await _tap(close), base + "_native_close_or_back_" + context)
	await _settle()
	_check_context(base, base + "_restored_after_" + context)
	if over_shop:
		_check(_awning_visible() and is_equal_approx(_home._header.position.y, _home.SHOP_AWNING_SIZE.y), "shop_awning_header_restored_after_" + context)
	else:
		var before: float = _state().clock
		await get_tree().create_timer(0.12).timeout
		_check(float(_state().clock) > before, "courtyard_resumes_after_" + context)


func _open_events(over_shop: bool) -> void:
	if over_shop:
		MetaPopups.open_events(_home)
	else:
		_check(await _tap(_direct_button(_home._side.find_child("EventsShortcut", true, false))), "native_battle_events_for_transition")
	await _settle()
	_check_context("events", "events_transition_source")


func _header_popup_round_trip(context: String, base: String) -> void:
	var target: Node = _home._header.find_child("ProfileButton" if context == "profile" else "SettingsButton", true, false)
	var button: Button = target if target is Button else _direct_button(target)
	_check(await _tap(button), base + "_native_header_to_" + context)
	await _settle()
	_check_context(context, base + "_header_popup_" + context)
	await _assert_paused(base + "_header_popup_" + context)
	await _capture(base + "-" + context)
	_check(await _tap(_close_button(_active_popup())), base + "_native_header_popup_close_" + context)
	await _settle()
	_check_context(base, base + "_restored_after_header_popup_" + context)
	if base == "shop":
		_check(_awning_visible() and is_equal_approx(_home._header.position.y, _home.SHOP_AWNING_SIZE.y), "shop_awning_header_restored_after_" + context)
	else:
		var before: float = _state().clock
		await get_tree().create_timer(0.12).timeout
		_check(float(_state().clock) > before, "courtyard_resumes_after_" + context)


func _events_login_transition() -> void:
	await _open_events(true)
	var hub := _active_popup()
	_check(hub != null, "shop_events_hub_available_for_login_transition")
	if hub == null:
		return
	_check(await _tap(_row_button(hub, "Quà 7 ngày")), "native_shop_events_to_login_transition")
	await _settle()
	_check_context("login", "new_login_context_survives_old_events_queued_exit")
	_check(await _tap(_close_button(_active_popup())), "native_transitioned_login_close")
	await _settle()
	_check_context("shop", "shop_restored_after_events_login_transition")


func _stacked_surface_case() -> void:
	var first := Node.new()
	var second := Node.new()
	var inherited := Node.new()
	_home.add_child(first)
	_home.register_menu_surface(first, "quests")
	_home.add_child(second)
	_home.register_menu_surface(second, "events")
	_home.add_child(inherited)
	_home.register_menu_surface(inherited, "")
	await _settle()
	_check_context("events", "top_surface_inherits_active_context")
	first.queue_free()
	await _settle()
	_check_context("events", "older_surface_exit_preserves_top_context")
	inherited.queue_free()
	second.queue_free()
	await _settle()
	_check_context("battle", "last_surface_exit_restores_courtyard")


func _check_context(expected: String, label: String) -> void:
	_check(_home.active_menu_context() == expected, label + "_semantic_context")
	_check(_pattern.get_instance_id() == _pattern_id and _home.find_children("MenuPatternBackground", "ColorRect", true, false).size() == 1, label + "_one_persistent_pattern")
	_check(_pattern.get_global_rect().is_equal_approx(_home.get_global_rect()), label + "_fullscreen_header_content_nav_coverage")
	_check(_pattern.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + "_pattern_does_not_intercept_input")
	_check(_pattern.get_index() < _home._header.get_index() and _pattern.get_index() < _home._nav_holder.get_index(), label + "_pattern_behind_header_and_nav")
	_check(_world.get_instance_id() == _world_id and _state().actor_ids == _actor_ids, label + "_courtyard_actor_identity_preserved")
	if expected == "battle":
		_check(not _pattern.visible and _state().active and _world.visible, label + "_courtyard_visible_pattern_hidden")
		_check(not _awning_visible(), label + "_no_shop_awning_in_battle")
	else:
		_check(_pattern.visible and not _state().active and not _world.visible, label + "_pattern_visible_courtyard_paused_hidden")
		var material: ShaderMaterial = _pattern.material
		_check(material != null and material.shader.resource_path.ends_with("pattern_scroll.gdshader"), label + "_scrolling_shop_pattern_shader")
		if material != null:
			var actual: Color = material.get_shader_parameter("sky")
			var intended: Color = Ui.menu_pattern_color(expected)
			_check(actual.is_equal_approx(intended), label + "_context_palette_applied")
			_colors[expected] = actual.to_html(false)


func _assert_paused(label: String) -> void:
	var clock: float = _state().clock
	await get_tree().create_timer(0.15).timeout
	_check(is_equal_approx(float(_state().clock), clock), label + "_courtyard_clock_paused")


func _pattern_motion() -> void:
	var saved: Array = []
	var paused_timers: Array = []
	for child in _home.get_children():
		# Home refreshes shared chrome once per second. Pause that refresh while
		# isolating the shader so changing UI visibility cannot count as motion.
		if child is Timer:
			paused_timers.append({"node": child, "paused": child.paused})
			child.paused = true
		if child != _pattern and (child is CanvasItem or child is CanvasLayer):
			saved.append({"node": child, "visible": child.visible})
			child.visible = false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var before := get_viewport().get_texture().get_image()
	await get_tree().create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var after := get_viewport().get_texture().get_image()
	var changed := _changed_fraction(before, after)
	_check(changed > 0.01, "bare_pattern_pixels_move_over_time")
	var a := "pattern-motion-start_%dx%d.png" % [_size.x, _size.y]
	var b := "pattern-motion-end_%dx%d.png" % [_size.x, _size.y]
	before.save_png(OUT.path_join(a))
	after.save_png(OUT.path_join(b))
	_motions.append({"window": [_size.x, _size.y], "interval_seconds": 0.7, "changed_fraction": changed, "before": a, "after": b})
	for item in saved:
		if is_instance_valid(item.node):
			item.node.visible = item.visible
	for item in paused_timers:
		if is_instance_valid(item.node):
			item.node.paused = item.paused
	await get_tree().process_frame


func _changed_fraction(a: Image, b: Image) -> float:
	var step := maxi(1, a.get_width() / 90)
	var changed := 0
	var total := 0
	for y in range(0, a.get_height(), step):
		for x in range(0, a.get_width(), step):
			var first := a.get_pixel(x, y)
			var second := b.get_pixel(x, y)
			if maxf(absf(first.r - second.r), maxf(absf(first.g - second.g), absf(first.b - second.b))) > 0.006:
				changed += 1
			total += 1
	return float(changed) / maxf(total, 1.0)


func _combat_probe() -> void:
	var packed: PackedScene = load("res://game/battle/Battle.tscn")
	var battle = packed.instantiate()
	add_child(battle)
	await get_tree().process_frame
	_check(battle.get_node("Background").get_script().resource_path == "res://game/battle/Background.gd", "combat_keeps_original_background_script")
	_check(_pattern_count(battle) == 0, "combat_scene_has_no_menu_pattern_material")
	_check(battle.phase == "shop", "combat_probe_never_starts_wave")
	battle.queue_free()
	await get_tree().process_frame


func _pattern_count(node: Node) -> int:
	var count := 0
	if node is CanvasItem and node.material is ShaderMaterial and node.material.shader != null:
		if node.material.shader.resource_path.ends_with("pattern_scroll.gdshader"):
			count += 1
	for child in node.get_children():
		count += _pattern_count(child)
	return count


func _state() -> Dictionary:
	return _world.get_review_state()


func _awning_visible() -> bool:
	var awning: CanvasItem = _home.find_child("ShopAwning", true, false)
	return awning != null and awning.is_visible_in_tree()


func _nav_button(index: int) -> Button:
	var bar: Node = _home._nav_holder.get_child(0)
	return _direct_button(bar.get_child(index))


func _direct_button(node: Node) -> Button:
	if node == null:
		return null
	if node is Button and node.is_visible_in_tree():
		return node
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree():
			return child
	return null


func _active_popup() -> Control:
	for child in _home.get_children():
		if child is ColorRect and child.mouse_filter == Control.MOUSE_FILTER_STOP and child.is_visible_in_tree():
			return child
	return null


func _close_button(scope: Node) -> Button:
	if scope == null:
		return null
	for button: Button in scope.find_children("*", "Button", true, false):
		if button.custom_minimum_size == Vector2(68, 68):
			return button
	return null


func _row_button(scope: Node, title: String) -> Button:
	for label: Label in scope.find_children("*", "Label", true, false):
		if label.text == title:
			var row: Node = label.get_parent().get_parent()
			var found := _direct_button(row)
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


func _tap(button: Button) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var native := get_tree().root.get_final_transform() * button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = native
	motion.global_position = native
	Input.parse_input_event(motion)
	await get_tree().process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = native
		event.global_position = native
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
	return received[0]


func _settle() -> void:
	await get_tree().create_timer(0.22).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var filename := "%s_%dx%d.png" % [label, _size.x, _size.y]
	_check(image.get_size() == _size, "native_capture_size_" + label)
	_check(image.save_png(OUT.path_join(filename)) == OK, "capture_saved_" + label)
	_captures.append({"file": filename, "window": [_size.x, _size.y], "context": _home.active_menu_context()})


func _check(ok: bool, label: String) -> void:
	_checks.append({"name": label, "passed": ok, "window": [_size.x, _size.y]})
	if not ok:
		_failed += 1
		push_error("MENU_PATTERN_BACKGROUND_FAIL " + label + " " + str(_size))


func _finish() -> void:
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"checks": _checks, "captures": _captures, "motion": _motions, "context_colors": _colors, "failures": _failed}, "\t"))
	file.close()
	print("MENU_PATTERN_BACKGROUND_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " motion_pairs=", _motions.size(), " failures=", _failed)
	get_tree().quit(1 if _failed > 0 else 0)
