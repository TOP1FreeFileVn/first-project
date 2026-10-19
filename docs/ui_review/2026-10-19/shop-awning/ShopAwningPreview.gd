extends Node

# Native production pages and input smoke checks, with a disposable RAM-only player.
const OUT := "res://docs/ui_review/2026-10-19/shop-awning"
const HomeScene = preload("res://game/menu/Home.tscn")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const Economy = preload("res://game/core/Economy.gd")
const DESIGN_SIZE := Vector2(720, 1280)

var _home: Control
var _captures: Array = []
var _checks: Array = []
var _failures := 0


func _ready() -> void:
	print("SHOP_AWNING_USER_DIR ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.fast_chest = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 4
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	get_window().size = Vector2i(450, 800)
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.BATTLE_TAB, false)
	await _settle()
	_record("awning_hidden_on_initial_battle", not _awning_visible())
	for tween in get_tree().get_processed_tweens():
		tween.pause()
	_home.process_mode = Node.PROCESS_MODE_DISABLED
	await _capture("battle_450x800")
	await _motion_review()
	_home.process_mode = Node.PROCESS_MODE_INHERIT
	await _switch(_home.SHOP_TAB, "nav_shop_450")
	await _capture("shop_450x800")
	await _switch(_home.BATTLE_TAB, "nav_battle_450")
	get_window().size = Vector2i(360, 640)
	await get_tree().process_frame
	await get_tree().process_frame
	await _switch(_home.SHOP_TAB, "nav_shop_360")
	await _capture("shop_360x640")
	await _smoke_free_chest()
	await _smoke_exchange()
	await _switch(_home.BATTLE_TAB, "nav_battle_360")
	_write_json("manifest.json", {
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"design_size": [720, 1280], "native_render": true,
		"captures": _captures, "checks": _checks, "failures": _failures,
	})
	print("SHOP_AWNING_COMPLETE ", _captures.size(), " native captures; ", _checks.size(), " checks; failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _motion_review() -> void:
	var start := Time.get_ticks_msec()
	var initial_geometry: Dictionary = _captures[0].controls
	for index in range(1, 4):
		var remaining := start + index * 1000 - Time.get_ticks_msec()
		if remaining > 0:
			await get_tree().create_timer(remaining / 1000.0).timeout
		await _capture("battle_motion_%02d_450x800" % index)
		_record("motion_%d_geometry_static" % index, _captures[-1].controls == initial_geometry)
	var first := Image.load_from_file(OUT + "/battle_450x800.png")
	var last := Image.load_from_file(OUT + "/battle_motion_03_450x800.png")
	_record("real_time_sky_moves_over_three_seconds", first.get_data() != last.get_data())


func _switch(index: int, check_name: String) -> void:
	var tapped := await _tap(_nav_button(index))
	await _settle()
	_record(check_name, tapped and _home._current == index)
	var should_show: bool = index == _home.SHOP_TAB
	_record(check_name + "_awning_visibility", _awning_visible() == should_show)
	var sky: Control = _home.find_child("MenuBackground", true, false)
	var pattern: Control = _home.find_child("ShopBackground", true, false)
	_record(check_name + "_background_visibility", sky.visible == (not should_show) and pattern.visible == should_show)


func _smoke_free_chest() -> void:
	var shop: Control = _home._pages[_home.SHOP_TAB]
	var gold_before: int = PlayerData.gold
	var gems_before: int = PlayerData.gems
	var cards_before := _total_cards()
	var unlocked_before := _unlocked_count()
	seed(20261019)
	var tapped := await _tap(shop._wood_button)
	await get_tree().create_timer(0.45).timeout
	var opening := _find_opening(_home)
	_record("free_chest_actual_click_opens_summary", tapped and opening != null and opening._stage == "summary")
	var reward: Dictionary = Economy.CHESTS["wood"]
	var bonus: Array = reward["bonus_gold"]
	var gold_delta: int = PlayerData.gold - gold_before
	# The first card of a locked troop is consumed to unlock it (PlayerData.add_cards).
	var received_cards := _total_cards() - cards_before + _unlocked_count() - unlocked_before
	_record("free_chest_grants_expected_cards_once", received_cards == int(reward.cards))
	_record("free_chest_grants_gold_in_range", gold_delta >= int(bonus[0]) and gold_delta <= int(bonus[1]))
	_record("free_chest_keeps_gems", PlayerData.gems == gems_before)
	_record("free_chest_sets_cooldown", PlayerData.free_chest_seconds_left() > 0 and shop._wood_button.disabled)
	if opening == null:
		return
	var gold_after: int = PlayerData.gold
	var cards_after := _total_cards()
	var done: Button = opening.find_child("ChestDoneButton", true, false)
	tapped = await _tap(done)
	await get_tree().process_frame
	_record("chest_done_actual_click_closes", tapped and not is_instance_valid(opening))
	_record("chest_done_keeps_granted_rewards", PlayerData.gold == gold_after and _total_cards() == cards_after)
	if is_instance_valid(opening):
		opening.get_parent().queue_free()
		await get_tree().process_frame


func _smoke_exchange() -> void:
	var shop: Control = _home._pages[_home.SHOP_TAB]
	var offers: VBoxContainer = shop._offers
	var exchange: Button = _first_button(offers.get_child(offers.get_child_count() - 1))
	var gold_before: int = PlayerData.gold
	var gems_before: int = PlayerData.gems
	var cards_before := _total_cards()
	var tapped := await _tap(exchange)
	await get_tree().process_frame
	_record("exchange_actual_click_spends_gems", tapped and PlayerData.gems == gems_before - Economy.EXCHANGE_GEMS)
	_record("exchange_actual_click_grants_gold", PlayerData.gold == gold_before + Economy.EXCHANGE_GOLD)
	_record("exchange_preserves_cards", _total_cards() == cards_before)


func _total_cards() -> int:
	var total := 0
	for state in PlayerData.troops.values():
		total += int(state.cards)
	return total


func _unlocked_count() -> int:
	var total := 0
	for state in PlayerData.troops.values():
		if state.unlocked:
			total += 1
	return total


func _find_opening(node: Node) -> Control:
	if node is ChestOpening:
		return node
	for child in node.get_children():
		var found := _find_opening(child)
		if found != null:
			return found
	return null


func _awning_visible() -> bool:
	var awning: Control = _home.find_child("ShopAwning", true, false)
	return awning != null and awning.is_visible_in_tree()


func _capture(key: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var expected: Vector2i = get_window().size
	_record(key + "_native_size", shot.get_size() == expected)
	_check(shot.save_png(OUT + "/" + key + ".png") == OK, "Save screenshot: " + key)
	var controls := {}
	for node_name in ["Header", "ShopAwning", "ShopBackground", "MenuBackground"]:
		var node: Node = _home.find_child(node_name, true, false)
		if node is Control:
			controls[node_name] = _geometry(node)
		else:
			_record(key + "_required_" + node_name, false)
	var shop: Control = _home._pages[_home.SHOP_TAB]
	controls["first_offer"] = _geometry(shop._offers.get_child(0))
	controls["wood_button"] = _geometry(shop._wood_button)
	controls["nav"] = _geometry(_home._nav_holder)
	controls["offers"] = []
	for offer in shop._offers.get_children():
		controls.offers.append(_geometry(offer))
	if _home._current == _home.SHOP_TAB:
		var scroll := shop.body.get_parent().get_parent() as ScrollContainer
		var bar := scroll.get_v_scroll_bar()
		controls["scroll"] = {"max_value": bar.max_value, "page": bar.page,
			"value": bar.value, "bar_visible": bar.is_visible_in_tree()}
		_record(key + "_shop_has_no_vertical_scroll", not bar.is_visible_in_tree() and bar.max_value <= bar.page + 0.1)
		var awning: Control = _home.find_child("ShopAwning", true, false)
		var header: Control = _home.find_child("Header", true, false)
		var first_offer: Control = shop._offers.get_child(0)
		if awning != null:
			_record(key + "_awning_below_header", awning.get_global_rect().position.y >= header.get_global_rect().end.y - 0.1)
			_record(key + "_awning_above_first_offer", awning.get_global_rect().end.y <= first_offer.get_global_rect().position.y + 0.1)
			_record(key + "_awning_inside_canvas", Rect2(Vector2.ZERO, DESIGN_SIZE).encloses(awning.get_global_rect()))
		for index in shop._offers.get_child_count():
			var offer: Control = shop._offers.get_child(index)
			var visible_rect := Rect2(Vector2(0, 112), Vector2(720, 1008))
			_record(key + "_offer_%d_inside_content" % index, visible_rect.encloses(offer.get_global_rect()))
	var record := {"file": key + ".png", "actual": [shot.get_width(), shot.get_height()],
		"selected_tab": _home._current, "elapsed_ms": Time.get_ticks_msec(), "controls": controls}
	_captures.append(record)
	print("SHOP_AWNING_CAPTURE ", key, " native=", shot.get_size())


func _geometry(control: Control) -> Dictionary:
	var rect := control.get_global_rect()
	var result := {"name": control.name, "visible": control.is_visible_in_tree(),
		"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]}
	if control is Button:
		result["text"] = control.text
		result["disabled"] = control.disabled
	if control.material is ShaderMaterial:
		var material := control.material as ShaderMaterial
		result["shader"] = material.shader.resource_path
		if material.shader.resource_path.ends_with("pattern_scroll.gdshader"):
			result["sky"] = str(material.get_shader_parameter("sky"))
	return result


func _nav_button(index: int) -> Button:
	var bar: Control = _home._nav_holder.get_child(_home._nav_holder.get_child_count() - 1)
	return _first_button(bar.get_child(index))


func _first_button(node: Node) -> Button:
	if node is Button:
		return node
	for child in node.get_children():
		var found := _first_button(child)
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
	await get_tree().create_timer(0.28).timeout
	await get_tree().process_frame


func _record(check_name: String, passed: bool) -> void:
	_checks.append({"name": check_name, "passed": passed})
	_check(passed, check_name)
	print("SHOP_AWNING_CHECK ", check_name, " ", "PASS" if passed else "FAIL")


func _check(passed: bool, message: String) -> void:
	if not passed:
		_failures += 1
		push_error(message)


func _write_json(file_name: String, data: Dictionary) -> void:
	var file := FileAccess.open(OUT + "/" + file_name, FileAccess.WRITE)
	if file == null:
		_check(false, "Could not write shop awning JSON: " + file_name)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
