extends Node

# Native menu frame review. Launch with workspace-isolated APPDATA/LOCALAPPDATA;
# autoloads start before this fixture can disable persistence.
const HOME = preload("res://game/menu/Home.tscn")
const Ui = preload("res://game/ui/Ui.gd")
const MetaPopups = preload("res://game/menu/popups/MetaPopups.gd")
const CastlePage = preload("res://game/menu/pages/CastlePage.gd")
const OUT := "res://docs/ui_review/2026-10-21/menu-frame-rollout"
const SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]

var _home: Control
var _size := Vector2i.ZERO
var _checks: Array = []
var _captures: Array = []
var _geometry: Array = []
var _failed := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	for requested in SIZES:
		_size = requested
		get_window().size = requested
		_reset_fixture()
		_home = HOME.instantiate()
		add_child(_home)
		await _settle()
		for tab in [_home.SHOP_TAB, _home.HERO_TAB, _home.TROOPS_TAB, _home.SUMMON_TAB]:
			_check(await _tap(_nav_button(tab)), "native_tab_entry_" + str(tab))
			await _settle()
			var context := str(_home.active_menu_context())
			await _capture(context)
			match context:
				"shop": await _shop_probe()
				"hero": await _hero_probe()
				"summon": await _summon_probe()
		_check(await _tap(_nav_button(_home.BATTLE_TAB)), "native_return_to_battle")
		await _settle()
		_check(_home.active_menu_context() == "battle" and _home._lobby_world.visible, "cardboard_lobby_restored")
		await _capture("battle", false)
		await _castle_probe()
		await _patrol_probe()
		await _popup_probe("login")
		await _popup_probe("quests")
		await _header_probe("profile")
		await _header_probe("settings")
		await _popup_shell_probe()
		_check(_home.active_menu_context() == "battle" and _home._lobby_world.visible, "all_menu_routes_restore_lobby")
		_home.queue_free()
		await get_tree().process_frame
	await _combat_probe()
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"native_render": true, "checks": _checks, "captures": _captures,
		"geometry": _geometry, "failures": _failed}, "\t"))
	file.close()
	print("MENU_FRAME_ROLLOUT_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failed)
	get_tree().quit(1 if _failed > 0 else 0)


func _reset_fixture() -> void:
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
	PlayerData.sound_on = false


func _shop_probe() -> void:
	var page: Control = _home._pages[_home.SHOP_TAB]
	_check(_sections(page).size() == 2, "shop_featured_and_exchange_attached_titles")
	var grid := page.find_child("SupplyChestGrid", true, false) as GridContainer
	_check(grid != null and grid.columns == 2 and grid.get_child_count() == 2, "shop_supply_chests_in_two_columns")
	if grid != null and grid.get_child_count() == 2:
		var left := grid.get_child(0) as Control
		var right := grid.get_child(1) as Control
		_check(absf(left.size.x - right.size.x) <= 1, "shop_supply_cards_equal_width")
		var left_button := _text_button(left, "MỞ")
		var right_button := _text_button(right, "MỞ", true)
		_check(left_button != null and right_button != null and absf(left_button.get_global_rect().position.y - right_button.get_global_rect().position.y) <= 1, "shop_supply_actions_share_baseline")
		_original_button(right_button, "shop_silver_chest")
	_original_button(page._wood_button, "shop_open_chest")
	var rates := _text_button(page, "TỈ LỆ THẺ")
	_check(await _ensure_visible(rates), "shop_rates_reachable")
	_check(await _tap(rates), "native_shop_rates_action")
	await _settle()
	await _capture("shop-rates")
	await _close_popup("shop_rates", "shop")
	_check(await _ensure_visible(page._wood_button), "shop_supply_actions_reachable")
	await _capture("shop-supplies")
	var exchange := _text_button(page, "ĐỔI")
	_check(await _ensure_visible(exchange), "shop_exchange_reachable_by_scroll")
	_original_button(exchange, "shop_exchange")
	var gold := PlayerData.gold
	var gems := PlayerData.gems
	_check(await _tap(exchange), "native_shop_exchange_action")
	await _settle()
	_check(PlayerData.gold > gold and PlayerData.gems < gems, "shop_exchange_changes_only_fixture_currency")
	await _capture("shop-exchange")


func _hero_probe() -> void:
	var page: Control = _home._pages[_home.HERO_TAB]
	var card: Button
	for candidate: Button in page.find_children("*", "Button", true, false):
		if candidate.flat and candidate.is_visible_in_tree() and candidate.size.x > 100:
			card = candidate
			break
	_check(await _ensure_visible(card), "hero_equipment_card_reachable")
	_check(await _tap(card), "native_hero_equipment_detail")
	await _settle()
	_check(_active_popup() != null, "hero_detail_popup_present")
	await _capture("hero-detail")
	await _close_popup("hero_detail", "hero")


func _summon_probe() -> void:
	var page: Control = _home._pages[_home.SUMMON_TAB]
	var rates := _text_button(page, "XEM TỈ LỆ")
	_check(await _ensure_visible(rates), "summon_rates_reachable_by_scroll")
	_check(await _tap(rates), "native_summon_rates_action")
	await _settle()
	await _capture("summon-rates")
	await _close_popup("summon_rates", "summon")


func _castle_probe() -> void:
	_home.open_page(CastlePage)
	await _settle()
	_check(_home.active_menu_context() == "castle", "castle_context")
	_check(_home._overlay_page.find_child("CastleStage", true, false) != null, "castle_art_separate_stage")
	_check(_sections(_home._overlay_page).size() == 2, "castle_two_tagged_groups_without_nested_boards")
	await _capture("castle")
	var upgrade := _text_button(_home._overlay_page, "NÂNG THÀNH", true)
	_original_button(upgrade, "castle_upgrade")
	_check(await _ensure_visible(upgrade), "castle_upgrade_reachable")
	if upgrade != null and not upgrade.disabled:
		var before := PlayerData.castle_level
		_check(await _tap(upgrade), "native_castle_upgrade_action")
		await _settle()
		_check(PlayerData.castle_level == before + 1, "castle_upgrade_advances_one_level")
	var scroll: ScrollContainer = _home._overlay_page.get_child(0)
	var before_scroll := scroll.scroll_vertical
	await _wheel(scroll, 18)
	_check(scroll.scroll_vertical > before_scroll, "castle_workshop_reachable_by_native_scroll")
	await _capture("castle-workshop")
	for frame in _sections(_home._overlay_page):
		if str(frame.get_meta("menu_section_title", "")) != "Xưởng":
			continue
		var buttons := frame.find_children("*", "Button", true, false)
		_check(buttons.size() == 3, "workshop_three_flat_upgrade_rows")
		for index in buttons.size():
			_original_button(buttons[index], "workshop_" + str(index))
	_check(await _tap(_direct_button(_home._overlay)), "native_castle_back")
	await _settle()
	_check(_home.active_menu_context() == "battle", "castle_back_restores_battle")


func _patrol_probe() -> void:
	MetaPopups.open_events(_home)
	await _settle()
	await _capture("events")
	_check(await _tap(_row_button(_active_popup(), "Tuần tra")), "native_events_to_patrol")
	await _settle()
	_check(_home.active_menu_context() == "patrol", "patrol_context")
	await _capture("patrol")
	var claim := _text_button(_home._overlay_page, "THU HOẠCH")
	_original_button(claim, "patrol_claim")
	_check(await _ensure_visible(claim), "patrol_claim_reachable")
	var gold := PlayerData.gold
	_check(await _tap(claim), "native_patrol_claim_action")
	await _settle()
	_check(PlayerData.gold > gold and PlayerData.patrol_stored() <= 1, "patrol_claim_grants_once_and_resets_storage")
	var quick := _text_button(_home._overlay_page, "Miễn phí", true)
	if quick == null:
		quick = _text_button(_home._overlay_page, "TUẦN TRA NHANH", true)
	_check(await _ensure_visible(quick), "patrol_quick_reachable")
	var free := PlayerData.quick_patrol_free_left()
	_check(await _tap(quick), "native_quick_patrol_action")
	await _settle()
	_check(PlayerData.quick_patrol_free_left() == free - 1, "quick_patrol_consumes_one_free_use")
	_check(await _tap(_direct_button(_home._overlay)), "native_patrol_back")
	await _settle()
	_check(_home.active_menu_context() == "battle", "patrol_back_restores_battle")


func _popup_probe(context: String) -> void:
	if context == "login":
		MetaPopups.open_login(_home)
	else:
		MetaPopups.open_quests(_home)
	await _settle()
	_check(_home.active_menu_context() == context, context + "_context")
	await _capture(context)
	if context == "login":
		var claim := _text_button(_active_popup(), "NHẬN QUÀ NGÀY", true)
		_check(await _ensure_visible(claim), "login_claim_reachable")
		var before := PlayerData.login_progress()
		_check(await _tap(claim), "native_login_claim_action")
		await _settle()
		_check(PlayerData.login_progress() == before + 1, "login_claim_progresses_one_day")
	else:
		var scroll := _first_scroll(_active_popup())
		_check(scroll != null, "quests_scroll_container_available")
		if scroll != null:
			var needs_scroll := scroll.get_v_scroll_bar().max_value > scroll.size.y + 1
			await _wheel(scroll, 30)
			_check(scroll.scroll_vertical > 0 if needs_scroll else scroll.get_global_rect().grow(2).encloses(scroll.get_child(0).get_global_rect()), "quests_later_rows_reachable_or_already_visible")
			await _capture("quests-bottom")
	await _close_popup(context, "battle")


func _header_probe(context: String) -> void:
	var target: Node = _home._header.find_child("ProfileButton" if context == "profile" else "SettingsButton", true, false)
	var hit: Button = target if target is Button else _direct_button(target)
	_check(await _tap(hit), "native_header_to_" + context)
	await _settle()
	_check(_home.active_menu_context() == context, context + "_header_context")
	await _capture(context)
	if context == "profile":
		var save := _text_button(_active_popup(), "LƯU")
		_check(await _ensure_visible(save), "profile_save_reachable")
		_check(await _tap(save), "native_profile_save_action")
		await _settle()
		var scroll := _first_scroll(_active_popup())
		if scroll != null:
			await _wheel(scroll, 30)
			await _capture("profile-bottom")
	else:
		var fast := _text_button(_active_popup(), "Mở rương nhanh (bỏ hoạt ảnh)")
		_check(await _ensure_visible(fast), "settings_fast_toggle_reachable")
		var before := PlayerData.fast_chest
		_check(await _tap(fast), "native_settings_fast_toggle")
		await _settle()
		_check(PlayerData.fast_chest != before, "settings_toggle_changes_fixture_setting")
	await _close_popup(context, "battle")


func _close_popup(label: String, expected: String) -> void:
	_check(await _tap(_close_button(_active_popup())), "native_popup_close_" + label)
	await _settle()
	_check(_active_popup() == null and _home.active_menu_context() == expected, label + "_close_restores_context")


func _popup_shell_probe() -> void:
	_home._open_settings()
	await _settle()
	var overlay := _active_popup()
	var sections := _sections(overlay)
	if sections.is_empty():
		_check(false, "popup_shell_present_for_input_probe")
		return
	var section: Control = sections[0]
	var panel: Control = section.get_child(0)
	var tag: Control = section.get_child(1)
	await _click_at(panel.get_global_rect().position + Vector2(8, panel.size.y / 2))
	_check(_active_popup() == overlay, "popup_blank_panel_tap_keeps_window_open")
	await _click_at(tag.get_global_rect().get_center())
	_check(_active_popup() == overlay, "popup_tag_tap_keeps_window_open")
	await _click_at(Vector2(6, _home.size.y / 2))
	await _settle()
	_check(_active_popup() == null and _home.active_menu_context() == "battle", "popup_outside_scrim_closes_and_restores_context")


func _capture(label: String, require_sections := true) -> void:
	# Let transient feedback from the preceding verified action finish before capture.
	for attempt in 22:
		var feedback := false
		for child in _home.get_children():
			if child is Label and child.z_index == 50:
				feedback = true
		if not feedback:
			break
		await get_tree().create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var filename := "%s_%dx%d.png" % [label, _size.x, _size.y]
	_check(shot.get_size() == _size and shot.save_png(OUT.path_join(filename)) == OK, "native_capture_" + label)
	_captures.append({"file": filename, "window": [_size.x, _size.y], "context": _home.active_menu_context()})
	var sections := _sections(_home)
	if require_sections:
		_check(not sections.is_empty(), "tagged_frames_present_" + label)
	var records: Array = []
	for section in sections:
		var panel: Control = section.get_child(0)
		var tag: Control = section.get_child(1)
		var bounds: Rect2 = section.get_global_rect()
		var tag_bounds := tag.get_global_rect()
		var panel_bounds := panel.get_global_rect()
		var name := str(section.get_meta("menu_section_title", ""))
		_check(bounds.position.x >= -1 and bounds.end.x <= _home.size.x + 1, label + "_frame_within_viewport_width_" + name)
		var popup := _active_popup()
		if popup != null and popup.is_ancestor_of(section) and _nearest_section(section) == null:
			_check(_home.get_global_rect().grow(1).encloses(bounds), label + "_popup_shell_inside_viewport")
			var close := _close_button(popup)
			_check(close != null and _home.get_global_rect().grow(1).encloses(close.get_global_rect()), label + "_popup_close_inside_viewport")
		_check(bounds.grow(1).encloses(tag_bounds), label + "_tag_inside_section_" + name)
		_check(tag_bounds.position.y <= panel_bounds.position.y and tag_bounds.end.y > panel_bounds.position.y, label + "_tag_attached_to_panel_" + name)
		_check(bounds.grow(1).encloses(panel_bounds), label + "_panel_inside_section_" + name)
		if panel.get_child_count() > 0 and panel.get_child(0) is Control:
			var content: Control = panel.get_child(0)
			_check(panel_bounds.grow(1).encloses(content.get_global_rect()), label + "_content_inside_panel_" + name)
		var visible_buttons := 0
		for button: Button in panel.find_children("*", "Button", true, false):
			if button.is_visible_in_tree() and _nearest_section(button) == section:
				visible_buttons += 1
				_check(panel_bounds.grow(2).encloses(button.get_global_rect()) or _inside_scroll(button, panel), label + "_button_inside_panel_or_scroll_" + str(visible_buttons) + "_" + name)
		records.append({"title": name, "section": _rect(bounds), "panel": _rect(panel_bounds), "tag": _rect(tag_bounds), "buttons": visible_buttons})
	_geometry.append({"screen": label, "window": [_size.x, _size.y], "sections": records})


func _rect(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _sections(scope: Node) -> Array[Control]:
	var found: Array[Control] = []
	if scope == null:
		return found
	for node in scope.find_children("*", "Control", true, false):
		if node.is_visible_in_tree() and node.has_meta("menu_section_title") and node.get_child_count() >= 2:
			found.append(node)
	return found


func _nearest_section(node: Node) -> Node:
	var parent := node.get_parent()
	while parent != null:
		if parent.has_meta("menu_section_title"):
			return parent
		parent = parent.get_parent()
	return null


func _inside_scroll(node: Node, boundary: Node) -> bool:
	var parent := node.get_parent()
	while parent != boundary and parent != null:
		if parent is ScrollContainer:
			return true
		parent = parent.get_parent()
	return false


func _original_button(button: Button, label: String) -> void:
	_check(button != null, label + "_button_exists")
	if button == null:
		return
	var style := button.get_theme_stylebox("normal")
	_check(style is StyleBoxTexture and style.texture != null and style.texture.resource_path.begins_with("res://game/ui/skin/btn_"), label + "_original_button_texture")
	var variation := button.theme_type_variation if button.theme_type_variation != "" else &"Button"
	_check(button.get_theme_constant("outline_size") == Ui.THEME.get_constant("outline_size", variation), label + "_original_outline_constant")
	var font := button.get_theme_font("font")
	if font is FontVariation:
		font = font.base_font
	_check(font != null and font.resource_path.ends_with("PaytoneOne-Regular.ttf"), label + "_original_game_font")


func _combat_probe() -> void:
	var packed: PackedScene = load("res://game/battle/Battle.tscn")
	var battle = packed.instantiate()
	add_child(battle)
	await get_tree().process_frame
	_check(battle.get_node("Background").get_script().resource_path == "res://game/battle/Background.gd", "combat_keeps_original_background")
	_check(not _contains_menu_panel(battle), "combat_has_no_context_menu_frames")
	_check(battle.phase == "shop", "combat_probe_does_not_start_wave")
	battle.queue_free()
	await get_tree().process_frame


func _contains_menu_panel(node: Node) -> bool:
	if node.has_meta("menu_panel_context") or node.has_meta("menu_section_title"):
		return true
	for child in node.get_children():
		if _contains_menu_panel(child):
			return true
	return false


func _nav_button(index: int) -> Button:
	return _direct_button(_home._nav_holder.get_child(0).get_child(index))


func _direct_button(node: Node) -> Button:
	if node == null:
		return null
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree():
			return child
	return null


func _text_button(scope: Node, text: String, prefix := false) -> Button:
	if scope == null:
		return null
	for button: Button in scope.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and (button.text.begins_with(text) if prefix else button.text == text):
			return button
	return null


func _active_popup() -> Control:
	var active: Control
	for child in _home.get_children():
		if child is ColorRect and child.mouse_filter == Control.MOUSE_FILTER_STOP and child.is_visible_in_tree() and not child.is_queued_for_deletion():
			active = child
	return active


func _close_button(scope: Node) -> Button:
	if scope == null:
		return null
	for button: Button in scope.find_children("*", "Button", true, false):
		if button.custom_minimum_size == Vector2(68, 68) and button.is_visible_in_tree():
			return button
	return null


func _row_button(scope: Node, title: String) -> Button:
	if scope == null:
		return null
	for label: Label in scope.find_children("*", "Label", true, false):
		if label.text != title:
			continue
		var ancestor: Node = label.get_parent()
		while ancestor != scope and ancestor != null:
			var found := _direct_button(ancestor)
			if found != null:
				return found
			ancestor = ancestor.get_parent()
	return null


func _first_scroll(scope: Node) -> ScrollContainer:
	if scope == null:
		return null
	for node: ScrollContainer in scope.find_children("*", "ScrollContainer", true, false):
		if node.is_visible_in_tree():
			return node
	return null


func _ensure_visible(control: Control) -> bool:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return false
	var scroll: ScrollContainer
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			scroll = ancestor
			break
		ancestor = ancestor.get_parent()
	if scroll == null:
		return _home.get_global_rect().encloses(control.get_global_rect())
	for attempt in 24:
		var view := scroll.get_global_rect().grow(2)
		var rect := control.get_global_rect()
		if view.encloses(rect):
			return true
		await _wheel(scroll, 2, rect.position.y >= view.position.y)
	return false


func _tap(button: Button) -> bool:
	if button == null or not is_instance_valid(button) or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	await _click_at(button.get_global_rect().get_center())
	return received[0]


func _click_at(at: Vector2) -> void:
	var native := get_tree().root.get_final_transform() * at
	await _pointer(at)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = native
		event.global_position = native
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame


func _wheel(scroll: ScrollContainer, count: int, down := true) -> void:
	if scroll == null:
		return
	var native := get_tree().root.get_final_transform() * scroll.get_global_rect().get_center()
	await _pointer(scroll.get_global_rect().get_center())
	for index in count:
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = native
			event.global_position = native
			event.button_index = MOUSE_BUTTON_WHEEL_DOWN if down else MOUSE_BUTTON_WHEEL_UP
			event.pressed = pressed
			Input.parse_input_event(event)
			await get_tree().process_frame
	await _settle()


func _pointer(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = get_tree().root.get_final_transform() * at
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await get_tree().process_frame


func _settle() -> void:
	await get_tree().create_timer(0.22).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _check(ok: bool, label: String) -> void:
	_checks.append({"name": label, "passed": ok, "window": [_size.x, _size.y]})
	if not ok:
		_failed += 1
		push_error("MENU_FRAME_ROLLOUT_FAIL " + label + " " + str(_size))
