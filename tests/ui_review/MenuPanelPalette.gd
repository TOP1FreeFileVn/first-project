extends Node

# Real Home routes, native window captures and input; all player state stays in RAM.
const HOME = preload("res://game/menu/Home.tscn")
const MetaPopups = preload("res://game/menu/popups/MetaPopups.gd")
const CastlePage = preload("res://game/menu/pages/CastlePage.gd")
const OUT := "res://docs/ui_review/2026-10-21/menu-panel-palette"
const SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]

var _home: Control
var _size := Vector2i.ZERO
var _checks: Array = []
var _captures: Array = []
var _readability: Array = []
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
	for requested in SIZES:
		_size = requested
		get_window().size = requested
		await _settle()
		for tab in [_home.SHOP_TAB, _home.HERO_TAB, _home.TROOPS_TAB]:
			_check(await _tap(_nav_button(tab)), "native_tab_entry_" + str(tab))
			await _settle()
			var context := str(_home.active_menu_context())
			await _capture(context)
			if tab == _home.HERO_TAB:
				await _hero_detail()
		_check(await _tap(_nav_button(_home.BATTLE_TAB)), "native_return_to_battle")
		await _settle()
		_check(_home.active_menu_context() == "battle" and _home._lobby_world.visible, "cardboard_lobby_returns")
		_home.open_page(CastlePage)
		await _settle()
		await _capture("castle")
		var scroll: ScrollContainer = _home._overlay_page.get_child(0)
		var before := scroll.scroll_vertical
		await _wheel(scroll, 8)
		_check(scroll.scroll_vertical > before, "castle_workshop_reachable_by_native_scroll")
		await _capture("castle-workshop")
		_check(await _tap(_direct_button(_home._overlay)), "native_castle_back")
		await _settle()
		_check(_home.active_menu_context() == "battle", "castle_back_restores_context")
		MetaPopups.open_events(_home)
		await _settle()
		await _capture("events")
		_check(await _tap(_row_button(_active_popup(), "Tuần tra")), "native_events_to_patrol")
		await _settle()
		_check(_home.active_menu_context() == "patrol", "patrol_route_opens")
		await _capture("patrol")
		_check(await _tap(_direct_button(_home._overlay)), "native_patrol_back")
		await _settle()
		_check(_home.active_menu_context() == "battle" and _home._lobby_world.visible, "patrol_back_restores_lobby")
	_home.queue_free()
	await get_tree().process_frame
	await _combat_probe()
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"native_render": true, "checks": _checks, "captures": _captures,
		"readability": _readability, "failures": _failed}, "\t"))
	file.close()
	print("MENU_PANEL_PALETTE_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failed)
	get_tree().quit(1 if _failed > 0 else 0)


func _hero_detail() -> void:
	var page: Control = _home._pages[_home.HERO_TAB]
	# The first paper-doll card is the equipped sword; use its actual hit area.
	var card_button: Button
	for candidate: Button in page.find_children("*", "Button", true, false):
		if candidate.flat and candidate.is_visible_in_tree() and candidate.size.x > 100:
			card_button = candidate
			break
	_check(await _tap(card_button), "native_hero_item_opens_detail")
	await _settle()
	_check(_active_popup() != null, "hero_item_detail_available")
	await _capture("hero-detail")
	_check(await _tap(_close_button(_active_popup())), "native_hero_item_detail_close")
	await _settle()
	_check(_active_popup() == null and _home.active_menu_context() == "hero", "hero_item_close_restores_hero")


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var screenshot := get_viewport().get_texture().get_image()
	var filename := "%s_%dx%d.png" % [label, _size.x, _size.y]
	_check(screenshot.get_size() == _size and screenshot.save_png(OUT.path_join(filename)) == OK, "native_capture_" + label)
	_captures.append({"file": filename, "window": [_size.x, _size.y], "context": _home.active_menu_context()})
	var text_rows: Array = []
	var panels := 0
	for node in _home.find_children("*", "PanelContainer", true, false):
		if not node.is_visible_in_tree() or not node.has_meta("menu_panel_context"):
			continue
		panels += 1
		var style: StyleBox = node.get_theme_stylebox("panel")
		var face: Color
		if style is StyleBoxTexture and style.texture != null:
			var texture_image: Image = style.texture.get_image()
			face = texture_image.get_pixel(texture_image.get_width() / 2, texture_image.get_height() / 2) * style.modulate_color
		elif style is StyleBoxFlat:
			face = style.bg_color
		else:
			continue
		for text: Label in node.find_children("*", "Label", true, false):
			if not text.is_visible_in_tree() or text.text.is_empty() or _nearest_panel(text) != node:
				continue
			var color := text.get_theme_color("font_color")
			text_rows.append({"text": text.text, "text_color": color.to_html(), "panel_color": face.to_html(),
				"contrast": snappedf(_contrast(color, face), 0.01), "outline": text.get_theme_constant("outline_size"),
				"font_size": text.get_theme_font_size("font_size"), "kind": node.get_meta("menu_panel_kind", "")})
	_readability.append({"screen": label, "window": [_size.x, _size.y], "panels": panels, "text": text_rows})
	_check(panels > 0, "context_panels_present_" + label)


func _nearest_panel(node: Node) -> Node:
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor is BaseButton or ancestor is ProgressBar:
			return null
		if ancestor is PanelContainer:
			return ancestor
		ancestor = ancestor.get_parent()
	return null


func _contrast(a: Color, b: Color) -> float:
	var first := a.srgb_to_linear().get_luminance()
	var second := b.srgb_to_linear().get_luminance()
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)


func _combat_probe() -> void:
	var packed: PackedScene = load("res://game/battle/Battle.tscn")
	var battle = packed.instantiate()
	add_child(battle)
	await get_tree().process_frame
	_check(battle.get_node("Background").get_script().resource_path == "res://game/battle/Background.gd", "combat_uses_original_background_script")
	_check(not _contains_menu_panel(battle), "combat_has_no_context_menu_panel")
	_check(battle.phase == "shop", "combat_probe_does_not_start_wave")
	battle.queue_free()
	await get_tree().process_frame


func _contains_menu_panel(node: Node) -> bool:
	if node.has_meta("menu_panel_context"):
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
	if scope == null:
		return null
	for label: Label in scope.find_children("*", "Label", true, false):
		if label.text == title:
			return _direct_button(label.get_parent().get_parent())
	return null


func _tap(button: Button) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	await _pointer(button.get_global_rect().get_center())
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = get_tree().root.get_final_transform() * button.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
	return received[0]


func _wheel(scroll: ScrollContainer, count: int) -> void:
	await _pointer(scroll.get_global_rect().get_center())
	for i in count:
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = get_tree().root.get_final_transform() * scroll.get_global_rect().get_center()
			event.global_position = event.position
			event.button_index = MOUSE_BUTTON_WHEEL_DOWN
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
	await get_tree().create_timer(0.25).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _check(ok: bool, label: String) -> void:
	_checks.append({"name": label, "passed": ok, "window": [_size.x, _size.y]})
	if not ok:
		_failed += 1
		push_error("MENU_PANEL_PALETTE_FAIL " + label + " " + str(_size))
