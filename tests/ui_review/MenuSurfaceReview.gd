extends Node

# Native coverage for CanvasLayer menu surfaces not exercised by the tab fixture.
const HOME = preload("res://game/menu/Home.tscn")
const Ui = preload("res://game/ui/Ui.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const SummonOpening = preload("res://game/ui/SummonOpening.gd")
const CastlePage = preload("res://game/menu/pages/CastlePage.gd")
const OUT := "res://docs/ui_review/2026-10-21/menu-surface-review"
const SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]

var _home: Control
var _checks: Array = []
var _captures: Array = []
var _failed := 0
var _size := Vector2i.ZERO


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.castle_level = 3
	PlayerData.gold = 2400
	PlayerData.gems = 260
	_home = HOME.instantiate()
	add_child(_home)
	for requested in SIZES:
		_size = requested
		get_window().size = requested
		_home.select_tab(_home.BATTLE_TAB, false)
		await _settle()
		await _admin_case()
		await _chest_case()
		await _summon_case()
		await _nested_sheet_case()
		await _page_opening_case()
	await _teardown_case()
	await _non_home_case()
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"checks": _checks, "captures": _captures, "failures": _failed}, "\t"))
	file.close()
	print("MENU_SURFACE_REVIEW_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failed)
	get_tree().quit(1 if _failed else 0)


func _admin_case() -> void:
	var panel = _home.open_admin()
	await _settle()
	_check(_home.active_menu_context() == "admin", "admin_registers_home_context")
	_check(not _home._lobby_world.get_review_state().active, "admin_pauses_courtyard")
	var bg: ColorRect = panel.find_child("AdminPatternBackground", false, false)
	_check(bg != null and bg.is_visible_in_tree(), "admin_has_visible_canvas_layer_pattern")
	if bg != null:
		_check(bg.mouse_filter == Control.MOUSE_FILTER_IGNORE, "admin_pattern_ignores_mouse")
		_check(bg.get_global_rect().is_equal_approx(panel.get_global_rect()), "admin_pattern_fills_surface")
		var mat: ShaderMaterial = bg.material
		_check(mat.get_shader_parameter("sky").is_equal_approx(Ui.menu_pattern_color("admin")), "admin_pattern_matches_palette")
	await _capture("admin-formulas", {"context": _home.active_menu_context()})
	_check(await _tap(_button_text(panel, "")), "native_admin_close")
	await _settle()
	_check(_home.active_menu_context() == "battle" and _home._lobby_world.get_review_state().active, "admin_close_restores_courtyard")


func _chest_case() -> void:
	var before := _player_snapshot()
	var opening := ChestOpening.new()
	opening.setup("Rương Gỗ", Color("a0673a"), {"gold": 83, "blueprints": {"weapon": 2, "boots": 1}, "items": [{"id": "kiem_go", "uid": "r1", "rarity": 0}, {"id": "mu_sat", "uid": "r2", "rarity": 1}]}, [], false)
	opening.attach(_home)
	await get_tree().create_timer(0.85).timeout
	_check(_home.active_menu_context() == "shop", "chest_from_battle_uses_shop_pattern")
	_check(not _home._lobby_world.get_review_state().active, "chest_pauses_courtyard")
	_check(_home._pattern_backdrop.visible, "chest_pattern_visible")
	_check(not _home._header.visible and not _home._nav_holder.visible and not _home._content.visible, "chest_hides_underlying_menu_chrome")
	await _capture("chest-wait", {"context": _home.active_menu_context(), "dim": opening.dim})
	_check(await _tap(opening._skip), "native_chest_skip")
	await get_tree().create_timer(0.45).timeout
	_check(opening._stage == "summary", "chest_skip_reaches_summary")
	await _capture("chest-summary", {"context": _home.active_menu_context(), "dim": opening.dim})
	_check(await _tap(opening.find_child("ChestDoneButton", true, false)), "native_chest_done")
	await _settle()
	_check(not is_instance_valid(opening), "chest_layer_freed")
	_check(_home.active_menu_context() == "battle" and _home._lobby_world.get_review_state().active, "chest_close_restores_courtyard")
	_check(_home._header.visible and _home._nav_holder.visible and _home._content.visible, "chest_close_restores_menu_chrome")
	_check(_player_snapshot() == before, "chest_presentation_does_not_grant_or_charge")


func _summon_case() -> void:
	var before := _player_snapshot()
	_home.select_tab(_home.SHOP_TAB, false)
	await _settle()
	var opening := SummonOpening.new()
	opening.setup([{"type": "card", "id": "kiem", "rarity": 0, "new": false}])
	opening.attach(_home)
	await get_tree().create_timer(0.32).timeout
	_check(_home.active_menu_context() == "summon", "summon_over_shop_uses_violet_pattern")
	_check(_home._pattern_backdrop.visible, "summon_pattern_visible")
	_check(not _home._header.visible and not _home._nav_holder.visible and not _home._content.visible and not _home._shop_awning.visible, "summon_hides_underlying_shop_chrome")
	await _capture("summon-charge", {"context": _home.active_menu_context(), "dim": opening.dim})
	_check(await _tap(opening._skip), "native_summon_skip")
	await _settle()
	_check(opening._stage == "done", "summon_skip_reaches_done")
	await _capture("summon-done", {"context": _home.active_menu_context(), "dim": opening.dim})
	_check(await _tap(_button_text(opening, "XONG")), "native_summon_done")
	await _settle()
	_check(not is_instance_valid(opening), "summon_layer_freed")
	_check(_home.active_menu_context() == "shop" and _home._pattern_backdrop.visible, "summon_close_restores_shop")
	_check(_home._shop_awning.visible, "summon_close_restores_shop_awning")
	_check(_home._header.visible and _home._nav_holder.visible and _home._content.visible, "summon_close_restores_menu_chrome")
	_check(_player_snapshot() == before, "summon_presentation_does_not_grant_or_charge")


func _nested_sheet_case() -> void:
	_home.select_tab(_home.HERO_TAB, false)
	await _settle()
	var first := UiKit.sheet_popup(_home, 520, "Cài đặt")
	first.add_child(UiKit.ink("Menu surface review", 22))
	var second := UiKit.sheet_popup(first, 460, "Hồ sơ")
	second.add_child(UiKit.ink("Nested sheet", 22))
	await _settle()
	_check(_home.active_menu_context() == "profile", "nested_sheet_ancestor_registration")
	UiKit.close_popup(first)
	await _settle()
	_check(_home.active_menu_context() == "hero", "parent_free_releases_nested_surface_contexts")
	_check(_home._menu_surfaces.is_empty(), "nested_surfaces_leave_no_stale_records")


func _page_opening_case() -> void:
	_home.open_page(CastlePage)
	await _settle()
	var page: Control = _home._overlay
	var opening := ChestOpening.new()
	opening.setup("Rương Gỗ", Color("a0673a"), {"gold": 83, "cards": {}}, [], true)
	opening.attach(_home)
	await _settle()
	_check(_home.active_menu_context() == "shop" and not page.visible, "opening_hides_underlying_overlay_page")
	_check(await _tap(opening.find_child("ChestDoneButton", true, false)), "native_overlay_page_chest_done")
	await _settle()
	_check(_home.active_menu_context() == "castle" and page.visible and not _home._content.visible, "opening_close_restores_overlay_page")
	_home.close_page()
	await _settle()
	_check(_home.active_menu_context() == "hero" and _home._content.visible, "overlay_page_close_restores_base_tab")


func _teardown_case() -> void:
	var opening := SummonOpening.new()
	opening.setup([{"type": "card", "id": "kiem", "rarity": 0, "new": false}])
	opening.attach(_home)
	await _settle()
	_home.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not is_instance_valid(_home) and not is_instance_valid(opening), "freeing_home_frees_canvas_layer_surface")


func _non_home_case() -> void:
	var host := Control.new()
	add_child(host)
	var opening := ChestOpening.new()
	opening.setup("Rương Gỗ", Color("a0673a"), {"gold": 83, "cards": {}}, [], true)
	opening.attach(host)
	await _settle()
	_check(not opening._menu_pattern and is_equal_approx(opening.dim, 0.92), "non_home_chest_preserves_legacy_dim_fallback")
	opening._close()
	await _settle()
	var summon := SummonOpening.new()
	summon.setup([{"type": "card", "id": "kiem", "rarity": 0, "new": false}])
	summon.attach(host)
	await get_tree().create_timer(0.32).timeout
	_check(not summon._menu_pattern and is_equal_approx(summon.dim, 0.9), "non_home_summon_preserves_legacy_dim_fallback")
	host.queue_free()
	await get_tree().process_frame


func _player_snapshot() -> Dictionary:
	return {"gold": PlayerData.gold, "gems": PlayerData.gems, "troops": PlayerData.troops.duplicate(true)}


func _button_text(scope: Node, text: String) -> Button:
	for button: Button in scope.find_children("*", "Button", true, false):
		if button.text == text and button.is_visible_in_tree():
			return button
	return null


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
	await get_tree().create_timer(0.24).timeout
	await get_tree().process_frame


func _capture(label: String, data: Dictionary) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var filename := "%s_%dx%d.png" % [label, _size.x, _size.y]
	_check(image.get_size() == _size, "native_capture_size_" + label)
	_check(image.save_png(OUT.path_join(filename)) == OK, "capture_saved_" + label)
	data.merge({"file": filename, "window": [_size.x, _size.y]})
	_captures.append(data)


func _check(passed: bool, label: String) -> void:
	_checks.append({"name": label, "passed": passed, "window": [_size.x, _size.y]})
	if not passed:
		_failed += 1
		push_error("MENU_SURFACE_REVIEW_FAIL " + label)
