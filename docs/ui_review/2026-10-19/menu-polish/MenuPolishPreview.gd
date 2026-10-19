extends Node

# Targeted native production capture; this runs in the MCP client's isolated profile.
const OUT := "res://docs/ui_review/2026-10-19/menu-polish"
const HomeScene = preload("res://game/menu/Home.tscn")
const BattleScene = preload("res://game/battle/Battle.tscn")
const DESIGN_SIZE := Vector2(720, 1280)
const WINDOW_SIZES := [Vector2i(720, 1280), Vector2i(450, 800), Vector2i(360, 640)]

var _home: Control
var _lobby: Control
var _battle
var _captures: Array = []
var _routes: Array = []
var _failures := 0


func _ready() -> void:
	print("MENU_POLISH_USER_DIR ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	for window_size in WINDOW_SIZES:
		_setup_player()
		get_window().size = window_size
		await get_tree().process_frame
		await _lobby_review(window_size)
		await _battle_review(window_size)
	_write_json("manifest.json", {
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"design_size": [720, 1280], "native_render": true,
		"captures": _captures, "routes": _routes, "failures": _failures,
	})
	print("MENU_POLISH_COMPLETE ", _captures.size(), " screens; ", _routes.size(), " routes; failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _setup_player() -> void:
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 4
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	PlayerData.troops["kiem"]["level"] = 6
	PlayerData.troops["kiem"]["cards"] = 12
	for id in ["giao", "thuoc", "katana", "riu"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "thuoc"]
	PlayerData.patrol_last_claim = PlayerData.now() - 3 * 3600
	PlayerData.login_claimed = 3
	PlayerData.login_day = PlayerData.today() - 1


func _lobby_review(window_size: Vector2i) -> void:
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.BATTLE_TAB, false)
	_lobby = _home._pages[_home.BATTLE_TAB]
	await _settle()
	await _capture("lobby", window_size, _home, _lobby_geometry())
	var before: int = _lobby._selected
	var pager := _lobby.find_child("LobbyPager", true, false)
	var tapped := await _tap(pager.get_child(0))
	await _settle()
	_record_route("pager_previous", tapped and _lobby._selected == before - 1, window_size)
	pager = _lobby.find_child("LobbyPager", true, false)
	tapped = await _tap(pager.get_child(pager.get_child_count() - 1))
	await _settle()
	_record_route("pager_next", tapped and _lobby._selected == before, window_size)
	if window_size == Vector2i(450, 800):
		await _all_nav_states(window_size)
	_home.queue_free()
	await get_tree().process_frame


func _all_nav_states(window_size: Vector2i) -> void:
	for target in [[_home.HERO_TAB, "hero"], [_home.TROOPS_TAB, "troops"], [_home.SHOP_TAB, "shop"], [4, "summon"]]:
		var tapped := await _tap(_nav_button(target[0]))
		await _settle()
		_record_route("nav_opens_" + target[1], tapped and _home._current == target[0], window_size)
		await _capture(target[1], window_size, _home, _page_geometry(target[1]))
	var tapped := await _tap(_nav_button(_home.BATTLE_TAB))
	await _settle()
	_record_route("nav_returns_to_lobby", tapped and _home._current == _home.BATTLE_TAB, window_size)
	_home.open_page(load("res://game/menu/pages/CastlePage.gd"))
	await _settle()
	await _capture("castle_overlay", window_size, _home, _page_geometry("castle"))
	var back: Button
	for child in _home._overlay.get_children():
		if child is Button:
			back = child
			break
	tapped = await _tap(back)
	await get_tree().process_frame
	_record_route("castle_back_returns_to_lobby", tapped and _home._overlay == null and _home._current == _home.BATTLE_TAB, window_size)


func _nav_button(index: int) -> Button:
	var bar: Control = _home._nav_holder.get_child(_home._nav_holder.get_child_count() - 1)
	var cell: Control = bar.get_child(index)
	for child in cell.get_children():
		if child is Button:
			return child
	return null


func _page_geometry(kind: String) -> Dictionary:
	var controls := {"navigation": _geometry(_home._nav_holder)}
	var background := _home.find_child("MenuBackground", true, false)
	if background is Control:
		controls["background"] = _geometry(background)
	if _home._overlay != null:
		controls["overlay_background"] = _geometry(_home._overlay)
	return {"kind": kind, "selected_tab": _home._current, "controls": controls}


func _battle_review(window_size: Vector2i) -> void:
	seed(20261019)
	_battle = BattleScene.instantiate()
	add_child(_battle)
	for item in [["cung", 2], ["kiem", 2], ["giao", 1], ["thuoc", 1]]:
		_battle.board.place_new(PlayerData.TROOPS[item[0]], item[1])
	_battle.core.meat = 9.0
	_battle.shop_changed.emit()
	await _settle()
	await _capture("battle_prepare", window_size, _battle.hud._root, _battle_geometry())
	var tapped := await _tap(_shop_lock())
	await _settle()
	_record_route("shop_lock", tapped and _battle.shop_locked, window_size)
	await _capture("battle_locked", window_size, _battle.hud._root, _battle_geometry())
	tapped = await _tap(_shop_lock())
	await _settle()
	_record_route("shop_unlock", tapped and not _battle.shop_locked, window_size)
	tapped = await _tap(_battle.hud._ready_button)
	await get_tree().process_frame
	_record_route("ready_starts_wave", tapped and _battle.phase == "fight" and _battle.hud._ready_button.disabled, window_size)
	await _capture("battle_wave_started", window_size, _battle.hud._root, _battle_geometry())
	_battle.queue_free()
	await get_tree().process_frame


func _shop_lock() -> Button:
	for candidate_name in ["BattleShopLockButton", "ShopLockButton", "ShopLock"]:
		var named: Node = _battle.hud._shop_box.find_child(candidate_name, true, false)
		if named is Button:
			return named
	return _lock_descendant(_battle.hud._shop_box)


func _lock_descendant(node: Node) -> Button:
	if node is Button and node.text.to_lower().contains("kho"):
		return node
	for child in node.get_children():
		var found := _lock_descendant(child)
		if found != null:
			return found
	return null


func _lobby_geometry() -> Dictionary:
	var controls := {}
	for node_name in ["LobbyPager", "LobbyBattleButton", "LobbyBattleContent", "LobbyRewards", "BattleActionBlock"]:
		var node := _lobby.find_child(node_name, true, false)
		if node is Control:
			controls[node_name] = _geometry(node)
		else:
			_check(false, "Missing lobby control: " + node_name)
	var pager := _lobby.find_child("LobbyPager", true, false)
	if pager != null:
		controls["previous"] = _geometry(pager.get_child(0))
		controls["next"] = _geometry(pager.get_child(pager.get_child_count() - 1))
	controls["navigation"] = _geometry(_home._nav_holder)
	var background := _home.find_child("MenuBackground", true, false)
	if background is Control:
		controls["background"] = _geometry(background)
	return {"kind": "lobby", "selected_level": _lobby._selected, "controls": controls}


func _battle_geometry() -> Dictionary:
	var controls := {
		"sell": _geometry(_battle.hud._sell_zone),
		"ready": _geometry(_battle.hud._ready_button),
		"shop": _geometry(_battle.hud._shop_panel),
	}
	var lock := _shop_lock()
	if lock != null:
		controls["shop_lock"] = _geometry(lock)
	else:
		_check(false, "Missing shop lock button")
	var sell_rect: Rect2 = _battle.hud._sell_zone.get_global_rect()
	var ready_rect: Rect2 = _battle.hud._ready_button.get_global_rect()
	_check(not sell_rect.intersects(ready_rect), "Sell and Ready overlap")
	return {"kind": "battle", "phase": _battle.phase, "shop_locked": _battle.shop_locked, "controls": controls}


func _geometry(control: Control) -> Dictionary:
	var rect := control.get_global_rect()
	var data := {"name": control.name, "type": control.get_class(),
		"visible": control.is_visible_in_tree(), "rect": _rect_array(rect),
		"minimum": [control.get_combined_minimum_size().x, control.get_combined_minimum_size().y],
		"children": []}
	if control is Label or control is Button:
		data["text"] = control.text
		data["font_size"] = control.get_theme_font_size("font_size")
		data["text_width"] = control.get_theme_font("font").get_string_size(control.text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, data.font_size).x
	if control is Button:
		data["disabled"] = control.disabled
	for child in control.get_children():
		if child is Control and child.is_visible_in_tree():
			data.children.append(_geometry(child))
	return data


func _capture(key: String, requested: Vector2i, root: Control, geometry: Dictionary) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var file_key := "%s_%dx%d" % [key, requested.x, requested.y]
	_check(shot.get_size() == requested, "Native screenshot size: " + file_key)
	_check(shot.save_png(OUT + "/" + file_key + ".png") == OK, "Save screenshot: " + file_key)
	var footer_top := 1178.0 if geometry.kind == "battle" else 1080.0
	var native_footer_top := roundi(footer_top * shot.get_height() / DESIGN_SIZE.y)
	var footer_file := file_key + "_footer.png"
	_check(shot.get_region(Rect2i(0, native_footer_top, shot.get_width(), shot.get_height() - native_footer_top)).save_png(
		OUT + "/" + footer_file) == OK, "Save native footer crop: " + file_key)
	var essential_bounds := {}
	for name_key in geometry.controls:
		var item: Dictionary = geometry.controls[name_key]
		if not item.visible:
			continue
		var values: Array = item.rect
		var rect := Rect2(values[0], values[1], values[2], values[3])
		var in_bounds := Rect2(Vector2(-1, -1), DESIGN_SIZE + Vector2(2, 2)).encloses(rect)
		essential_bounds[name_key] = in_bounds
		_check(in_bounds, file_key + " control inside canvas: " + name_key)
	var all_visible: Array = []
	_collect_visible(root, all_visible)
	var record := {"file": file_key + ".png", "footer": footer_file, "requested": [requested.x, requested.y],
		"actual": [shot.get_width(), shot.get_height()], "native_render": true,
		"geometry": geometry, "essential_bounds": essential_bounds, "visible_controls": all_visible}
	_captures.append(record)
	_write_json(file_key + "_geometry.json", record)
	print("MENU_POLISH_CAPTURE ", file_key, " native=", shot.get_size())


func _collect_visible(node: Node, output: Array) -> void:
	if node is Control:
		if not node.is_visible_in_tree():
			return
		var record := _geometry(node)
		record.erase("children")
		record["path"] = str(node.get_path())
		output.append(record)
	for child in node.get_children():
		_collect_visible(child, output)


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
	await get_tree().create_timer(0.25).timeout
	await get_tree().process_frame


func _record_route(route_name: String, passed: bool, window_size: Vector2i) -> void:
	_routes.append({"name": route_name, "passed": passed, "window": [window_size.x, window_size.y]})
	_check(passed, route_name + " " + str(window_size))
	print("MENU_POLISH_ROUTE ", route_name, " ", window_size, " ", "PASS" if passed else "FAIL")


func _check(passed: bool, message: String) -> void:
	if not passed:
		_failures += 1
		push_error(message)


func _rect_array(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _write_json(file_name: String, data: Dictionary) -> void:
	var file := FileAccess.open(OUT + "/" + file_name, FileAccess.WRITE)
	if file == null:
		_check(false, "Could not write menu polish JSON: " + file_name)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
