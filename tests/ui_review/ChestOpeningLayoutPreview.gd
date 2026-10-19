extends Node

# Real chest summary over Home/Shop, rendered at the actual two window sizes.
# The loot is granted before attach(), matching ShopPage. All player changes stay in RAM.
const OUT := "res://docs/ui_review/2026-10-19/chest-layout"
const HomeScene = preload("res://game/menu/Home.tscn")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const DESIGN_SIZE := Vector2(720, 1280)
const WINDOW_SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]
const REQUIRED_NAMES := [
	"ChestTitle", "ChestSummaryHost", "ChestSummary", "ChestSummaryButtons", "ChestDoneButton",
]
const OPTIONAL_NAMES := [
	"ChestSummaryScroll", "ChestSummaryRewards", "ChestRewardGrid", "ChestViewTroopsButton",
	"ChestSummaryGold", "ChestSummaryFresh",
]

var _home: Control
var _opening: Control
var _captures: Array = []
var _routes: Array = []
var _failures := 0


func _ready() -> void:
	print("CHEST_LAYOUT_USER_DIR ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	get_window().size = WINDOW_SIZES[0]
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.SHOP_TAB, false)
	for window_size in WINDOW_SIZES:
		get_window().size = window_size
		await get_tree().process_frame
		await get_tree().process_frame
		for scenario in _scenarios():
			await _run_scenario(scenario, window_size)
	_write_json("manifest.json", {
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"design_size": [720, 1280], "native_render": true,
		"captures": _captures, "routes": _routes, "failures": _failures,
	})
	print("CHEST_LAYOUT_COMPLETE ", _captures.size(), " screens; ", _routes.size(), " routes; failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _scenarios() -> Array:
	var eight := {}
	var many := {}
	for i in PlayerData.TROOP_ORDER.size():
		var id: String = PlayerData.TROOP_ORDER[i]
		many[id] = i + 1
		if i < 8:
			eight[id] = i + 1
	return [
		{"name": "fast_two", "cards": {"giao": 1, "kiem": 2}, "gold": 83,
			"new_ids": [], "fast": true, "callback": true, "action": "done"},
		{"name": "skip_eight", "cards": eight, "gold": 135,
			"new_ids": ["katana"], "fast": false, "callback": true, "action": "view"},
		{"name": "many_new", "cards": many, "gold": 1234567,
			"new_ids": many.keys(), "fast": true, "callback": true, "action": "done"},
		{"name": "gold_only", "cards": {}, "gold": 83,
			"new_ids": [], "fast": true, "callback": false, "action": "done"},
	]


func _run_scenario(scenario: Dictionary, window_size: Vector2i) -> void:
	var loot := {"gold": scenario.gold, "cards": scenario.cards}
	# Mirror the state after the shop has granted the loot, then ensure presentation
	# and either exit route preserve it without charging/granting again.
	PlayerData.gold += scenario.gold
	for id in scenario.cards:
		PlayerData.troops[id]["cards"] += scenario.cards[id]
		PlayerData.troops[id]["unlocked"] = true
	var granted := _player_snapshot()
	_home._update_header()
	var callbacks := [0, 0]
	var callback := Callable()
	if scenario.callback:
		callback = func():
			callbacks[0] += 1
			_home.select_tab(_home.TROOPS_TAB, false)
	_opening = ChestOpening.new()
	_opening.setup("Rương Gỗ", Color("a0673a"), loot, scenario.new_ids, scenario.fast, callback)
	_opening.closed.connect(func(): callbacks[1] += 1)
	_opening.attach(_home)
	await get_tree().process_frame
	if not scenario.fast:
		var tapped := await _tap(_opening._skip)
		_record_route(scenario.name + "_skip_to_summary", tapped and _opening._stage == "summary", window_size)
	# Allow each staggered card to settle before geometry/screenshot capture.
	await get_tree().create_timer(0.30 + maxf(scenario.cards.size() - 1, 0) * 0.05).timeout
	await _capture(scenario, window_size)
	if scenario.name == "many_new":
		await _scroll_rewards_to_end(scenario, window_size)
	_record_route(scenario.name + "_presentation_preserves_granted_loot", _player_snapshot() == granted, window_size)
	var exit_name := "ChestViewTroopsButton" if scenario.action == "view" else "ChestDoneButton"
	var button: Button = _opening.find_child(exit_name, true, false)
	var tapped := await _tap(button)
	await get_tree().process_frame
	var expected_callback := 1 if scenario.action == "view" else 0
	var exited: bool = tapped and not is_instance_valid(_opening) and callbacks[1] == 1 and callbacks[0] == expected_callback
	if not exited:
		print("CHEST_EXIT_DETAILS ", scenario.name, " tapped=", tapped, " alive=", is_instance_valid(_opening), " callbacks=", callbacks)
	if scenario.action == "view":
		exited = exited and _home._current == _home.TROOPS_TAB
	_record_route(scenario.name + "_" + scenario.action + "_closes_once", exited, window_size)
	_record_route(scenario.name + "_exit_preserves_granted_loot", _player_snapshot() == granted, window_size)
	if is_instance_valid(_opening):
		var layer := _opening.get_parent()
		layer.queue_free()
		await get_tree().process_frame
	_home.select_tab(_home.SHOP_TAB, false)


func _scroll_rewards_to_end(scenario: Dictionary, window_size: Vector2i) -> void:
	var scroll: ScrollContainer = _opening.find_child("ChestSummaryScroll", true, false)
	var at := scroll.get_global_rect().get_center()
	for i in 8:
		for pressed in [true, false]:
			var wheel := InputEventMouseButton.new()
			wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
			wheel.pressed = pressed
			wheel.position = at
			wheel.global_position = at
			get_viewport().push_input(wheel, true)
		await get_tree().process_frame
	var limit := scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page
	_record_route("many_new_wheel_reaches_end", limit > 0 and scroll.scroll_vertical >= limit - 1, window_size)
	var gold: Control = _opening.find_child("ChestSummaryGold", true, false)
	var fresh: Control = _opening.find_child("ChestSummaryFresh", true, false)
	var viewport_rect := scroll.get_global_rect()
	_record_route("many_new_gold_and_new_troops_visible", viewport_rect.encloses(gold.get_global_rect()) and viewport_rect.encloses(fresh.get_global_rect()), window_size)
	var scrolled := scenario.duplicate()
	scrolled.name = "many_new_scrolled"
	await _capture(scrolled, window_size)


func _player_snapshot() -> Dictionary:
	return {"gold": PlayerData.gold, "gems": PlayerData.gems, "troops": PlayerData.troops.duplicate(true)}


func _capture(scenario: Dictionary, requested: Vector2i) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var key := "%s_%dx%d" % [scenario.name, requested.x, requested.y]
	_check(shot.get_size() == requested, "Native chest capture mismatch: " + key)
	var error := shot.save_png(OUT + "/" + key + ".png")
	_check(error == OK, "Could not save chest capture: " + key)
	var render_scale := Vector2(shot.get_width(), shot.get_height()) / DESIGN_SIZE
	var controls := {}
	for node_name in REQUIRED_NAMES + OPTIONAL_NAMES:
		var node: Node = _opening.find_child(node_name, true, false)
		if node is Control:
			controls[node_name] = _control_geometry(node, render_scale)
		else:
			controls[node_name] = {"missing": true}
			if REQUIRED_NAMES.has(node_name):
				_check(false, "Missing chest control: " + node_name)
	var grid: Node = _opening.find_child("ChestRewardGrid", true, false)
	var card_geometry := []
	if grid != null:
		for holder in grid.get_children():
			var record := _control_geometry(holder, render_scale)
			if holder.get_child_count() > 0 and holder.get_child(0) is Control:
				var card: Control = holder.get_child(0)
				record["card"] = _control_geometry(card, render_scale)
				record["card_scale"] = [card.scale.x, card.scale.y]
			card_geometry.append(record)
	var checks := _layout_checks(controls, scenario, card_geometry)
	var record := {
		"file": key + ".png", "requested": [requested.x, requested.y],
		"actual": [shot.get_width(), shot.get_height()],
		"scenario": scenario, "stage": _opening._stage,
		"controls": controls, "cards": card_geometry, "layout_checks": checks,
	}
	_captures.append(record)
	_write_json(key + "_geometry.json", record)
	print("CHEST_LAYOUT_CAPTURE ", key, " native=", shot.get_size(), " cards=", card_geometry.size())


func _layout_checks(controls: Dictionary, scenario: Dictionary, cards: Array) -> Dictionary:
	var checks := {}
	for node_name in ["ChestSummary", "ChestSummaryButtons", "ChestDoneButton"]:
		if controls.get(node_name, {}).has("design_rect"):
			var rect := _array_rect(controls[node_name].design_rect)
			checks[node_name + "_inside_viewport"] = Rect2(Vector2.ZERO, DESIGN_SIZE).encloses(rect)
	var view_present: bool = controls.get("ChestViewTroopsButton", {}).has("design_rect")
	checks["callback_button_matches_setup"] = view_present == scenario.callback
	checks["card_count_matches_loot"] = cards.size() == scenario.cards.size()
	if controls.get("ChestSummary", {}).has("design_rect"):
		var rect := _array_rect(controls.ChestSummary.design_rect)
		checks["summary_horizontal_center"] = absf(rect.get_center().x - DESIGN_SIZE.x / 2.0) <= 1.0
		checks["summary_vertical_center"] = absf(rect.get_center().y - DESIGN_SIZE.y / 2.0) <= 1.0
	# Exact vertical centering and whitespace are recorded without baking aesthetic
	# thresholds into the fixture, so a reviewer can compare short and scrollable loot.
	for check_name in checks:
		_check(checks[check_name], scenario.name + ": " + check_name)
	return checks


func _control_geometry(control: Control, render_scale: Vector2) -> Dictionary:
	var rect := control.get_global_rect()
	var data := {
		"name": control.name, "type": control.get_class(), "visible": control.is_visible_in_tree(),
		"design_rect": _rect_array(rect),
		"render_rect": _rect_array(Rect2(rect.position * render_scale, rect.size * render_scale)),
		"minimum_size": [control.get_combined_minimum_size().x, control.get_combined_minimum_size().y],
		"scale": [control.scale.x, control.scale.y],
	}
	if control is Label:
		data["text"] = control.text
		data["font_size"] = control.get_theme_font_size("font_size")
	if control is Button:
		data["text"] = control.text
		data["disabled"] = control.disabled
	if control is ScrollContainer:
		data["scroll_vertical"] = control.scroll_vertical
		data["vertical_max"] = control.get_v_scroll_bar().max_value
		data["vertical_page"] = control.get_v_scroll_bar().page
	return data


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


func _record_route(route_name: String, passed: bool, window_size: Vector2i) -> void:
	_routes.append({"name": route_name, "passed": passed, "window": [window_size.x, window_size.y]})
	_check(passed, route_name + " " + str(window_size))
	print("CHEST_LAYOUT_ROUTE ", route_name, " ", window_size, " ", "PASS" if passed else "FAIL")


func _check(passed: bool, message: String) -> void:
	if not passed:
		_failures += 1
		push_error(message)


func _rect_array(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _array_rect(values: Array) -> Rect2:
	return Rect2(values[0], values[1], values[2], values[3])


func _write_json(file_name: String, data: Dictionary) -> void:
	var file := FileAccess.open(OUT + "/" + file_name, FileAccess.WRITE)
	if file == null:
		_check(false, "Could not write chest review JSON: " + file_name)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
