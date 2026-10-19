extends Node

const OUT := "res://docs/ui_review/2026-10-19/shop-header-order"
const HomeScene = preload("res://game/menu/Home.tscn")
const WINDOW_SIZES := [Vector2i(450, 800), Vector2i(360, 640)]
const DESIGN_SIZE := Vector2(720, 1280)

var _home: Control
var _captures: Array = []
var _checks: Array = []
var _failures := 0


func _ready() -> void:
	print("SHOP_HEADER_ORDER_USER_DIR ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 4
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	get_window().size = WINDOW_SIZES[0]
	_home = HomeScene.instantiate()
	add_child(_home)
	for window_size in WINDOW_SIZES:
		get_window().size = window_size
		_home.select_tab(_home.BATTLE_TAB, false)
		await _settle()
		var suffix := "_%dx%d" % [window_size.x, window_size.y]
		await _switch(_home.SHOP_TAB, "nav_shop" + suffix)
		await _capture("shop" + suffix)
		await _popup_round_trip("ProfileButton", "Hồ sơ", "profile" + suffix)
		await _popup_round_trip("SettingsButton", "Cài đặt", "settings" + suffix)
		for node_name in ["GoldButton", "GemsButton"]:
			var button := _direct_button(_home.find_child(node_name, true, false))
			var tapped := await _tap(button)
			_record(node_name + "_shifted_hit" + suffix, tapped and _home._current == _home.SHOP_TAB)
		await _switch(_home.BATTLE_TAB, "nav_battle" + suffix)
		await _capture("battle" + suffix)
		await _switch(_home.SHOP_TAB, "nav_shop_return" + suffix)
	_write_json("manifest.json", {"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"native_render": true, "captures": _captures, "checks": _checks, "failures": _failures})
	print("SHOP_HEADER_ORDER_COMPLETE ", _captures.size(), " native images; ", _checks.size(), " checks; failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _switch(index: int, check_name: String) -> void:
	var bar: Control = _home._nav_holder.get_child(_home._nav_holder.get_child_count() - 1)
	var tapped := await _tap(_direct_button(bar.get_child(index)))
	await _settle()
	_record(check_name, tapped and _home._current == index)
	var shop: bool = index == _home.SHOP_TAB
	var header: Control = _home.find_child("Header", true, false)
	var roof: Control = _home.find_child("ShopAwning", true, false)
	var sign: Control = _home.find_child("ShopSign", true, false)
	_record(check_name + "_header_position", is_equal_approx(header.position.y, 104.0 if shop else 0.0))
	_record(check_name + "_roof_sign_visibility", roof.is_visible_in_tree() == shop and sign.is_visible_in_tree() == shop)
	_record(check_name + "_content_position", is_equal_approx(_home._content.position.y, 216.0 if shop else 112.0))


func _popup_round_trip(node_name: String, title: String, key: String) -> void:
	var target: Control = _home.find_child(node_name, true, false)
	var tapped := await _tap(target if target is Button else _direct_button(target))
	await _settle()
	var popup := _active_popup()
	_record(key + "_actual_hit_opens_popup", tapped and popup != null and _contains_label(popup, title))
	if popup == null:
		return
	tapped = await _tap(_close_button(popup))
	await get_tree().process_frame
	_record(key + "_actual_close_returns_to_shop", tapped and not is_instance_valid(popup) and _home._current == _home.SHOP_TAB)
	if is_instance_valid(popup):
		popup.queue_free()
		await get_tree().process_frame


func _capture(key: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	_record(key + "_native_size", shot.get_size() == get_window().size)
	_check(shot.save_png(OUT + "/" + key + ".png") == OK, "Save screenshot: " + key)
	var controls := {}
	for node_name in ["Header", "ProfileButton", "GoldButton", "GemsButton", "SettingsButton", "ShopAwning", "ShopSign", "ShopRates"]:
		var node: Node = _home.find_child(node_name, true, false)
		if node is Control:
			controls[node_name] = _geometry(node)
		else:
			_record(key + "_missing_" + node_name, false)
	controls["content"] = _geometry(_home._content)
	controls["nav"] = _geometry(_home._nav_holder)
	var shop: Control = _home._pages[_home.SHOP_TAB]
	controls["offers"] = []
	for offer in shop._offers.get_children():
		controls.offers.append(_geometry(offer))
	if _home._current == _home.SHOP_TAB:
		var roof: Control = _home.find_child("ShopAwning", true, false)
		var header: Control = _home.find_child("Header", true, false)
		_record(key + "_header_below_roof", is_equal_approx(header.get_global_rect().position.y, roof.get_global_rect().end.y))
		_record(key + "_offers_keep_y307", is_equal_approx(shop._offers.get_child(0).get_global_rect().position.y, 307.0))
		var scroll := shop.body.get_parent().get_parent() as ScrollContainer
		var scrollbar := scroll.get_v_scroll_bar()
		controls["scroll"] = {"visible": scrollbar.is_visible_in_tree(), "max_value": scrollbar.max_value,
			"page": scrollbar.page, "value": scrollbar.value}
		_record(key + "_no_scrollbar", not scrollbar.is_visible_in_tree() and scrollbar.max_value <= scrollbar.page + 0.1)
		for index in shop._offers.get_child_count():
			var offer: Control = shop._offers.get_child(index)
			_record(key + "_offer_%d_fits" % index, Rect2(Vector2(0, 216), Vector2(720, 904)).encloses(offer.get_global_rect()))
	var record := {"file": key + ".png", "actual": [shot.get_width(), shot.get_height()],
		"selected_tab": _home._current, "controls": controls}
	_captures.append(record)
	print("SHOP_HEADER_ORDER_CAPTURE ", key, " native=", shot.get_size())


func _geometry(control: Control) -> Dictionary:
	var rect := control.get_global_rect()
	return {"name": control.name, "visible": control.is_visible_in_tree(),
		"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]}


func _active_popup() -> Control:
	for child in _home.get_children():
		if child is ColorRect and child.mouse_filter == Control.MOUSE_FILTER_STOP:
			return child
	return null


func _contains_label(node: Node, title: String) -> bool:
	if node is Label and node.text == title:
		return true
	for child in node.get_children():
		if _contains_label(child, title):
			return true
	return false


func _direct_button(node: Node) -> Button:
	if node == null:
		return null
	for child in node.get_children():
		if child is Button:
			return child
	return null


func _close_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.custom_minimum_size == Vector2(68, 68):
			return child
		var found := _close_button(child)
		if found != null:
			return found
	return null


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
	await get_tree().create_timer(0.22).timeout
	await get_tree().process_frame


func _record(check_name: String, passed: bool) -> void:
	_checks.append({"name": check_name, "passed": passed})
	_check(passed, check_name)
	print("SHOP_HEADER_ORDER_CHECK ", check_name, " ", "PASS" if passed else "FAIL")


func _check(passed: bool, message: String) -> void:
	if not passed:
		_failures += 1
		push_error(message)


func _write_json(file_name: String, data: Dictionary) -> void:
	var file := FileAccess.open(OUT + "/" + file_name, FileAccess.WRITE)
	if file == null:
		_check(false, "Write manifest: " + file_name)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
