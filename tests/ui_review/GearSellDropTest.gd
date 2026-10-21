extends Node

# Production battle review with native mouse input; all fixture state stays in RAM.
const BATTLE = preload("res://game/battle/Battle.tscn")
const Economy = preload("res://game/core/Economy.gd")
const OUT := "res://docs/ui_review/2026-10-21/gear-sell-drop"
const SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]

var _battle
var _board
var _hud
var _skill_troop: Resource
var _size := Vector2i.ZERO
var _checks: Array = []
var _captures: Array = []
var _failed := 0
var _pointer := Vector2.ZERO
var _held := false
var _hud_clicks: Array = []
var _watched: Dictionary = {}
var _output_dir := OUT
var _capacity_only := false


func _ready() -> void:
	_capacity_only = "--wallet-capacity-only" in OS.get_cmdline_user_args()
	if _capacity_only:
		_output_dir = OUT.path_join("wallet-capacity")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	var sizes: Array = [Vector2i(360, 640)] if _capacity_only else SIZES
	for requested in sizes:
		_size = requested
		get_window().size = requested
		_battle = BATTLE.instantiate()
		add_child(_battle)
		_board = _battle.board
		_hud = _battle.hud
		_board.set_process(false)
		_battle.core.max_meat = 1000
		_battle.core.meat = 10
		for gear in _board.gears.values():
			if gear.is_skill():
				_skill_troop = gear.troop
		await _settle()
		_check(_skill_troop != null, "fixture_has_real_weapon_skill_gear")
		var api_ok: bool = _board.has_method("dragged_gear") and _board.has_method("drag_can_sell") and _board.has_method("drag_over_sell_zone")
		_check(api_ok, "drag_read_api_available")
		if api_ok and _skill_troop != null:
			if not _capacity_only:
				await _sale_case()
				await _invalid_case()
				await _skill_case()
				await _merge_case()
				await _swap_case()
				await _hud_release_case()
				await _cancel_case()
			await _wallet_capacity_case(true)
			await _wallet_capacity_case(false)
		_battle.queue_free()
		await get_tree().process_frame
	_finish()


func _sale_case() -> void:
	var gears: Array = await _fixture([
		{"id": "kiem", "tier": 3, "cell": Vector2i(1, 0)},
		{"id": "cung", "tier": 1, "cell": Vector2i(3, 0)},
	])
	var gear = gears[0]
	var cell: Vector2i = gear.cell
	var refund: int = Economy.sell_refund(gear.troop.rarity, gear.tier)
	var ready: Button = _hud.get("_ready_button")
	var zone: Control = _hud.get("_sell_zone")
	_check(not zone.visible, "sell_zone_hidden_idle")
	_check(ready.visible and not ready.disabled, "ready_visible_enabled_idle")
	_check(ready.get_global_rect().is_equal_approx(_battle.SELL_RECT), "ready_uses_full_bottom_area_idle")
	_check(_battle.SELL_RECT == Rect2(16, 1196, 688, 76), "temporary_sell_rect_full_width")
	await _capture("idle")
	var coins: float = _battle.core.meat
	var count: int = _board.gears.size()
	await _begin_drag(gear)
	_check(_board.call("drag_can_sell"), "ordinary_drag_can_sell")
	await _move_to(Vector2(360, 1140))
	_check(zone.visible and zone.is_visible_in_tree(), "sell_zone_shown_during_ordinary_drag")
	_check(not ready.visible or ready.disabled, "ready_inactive_while_dragging")
	_check(not _board.call("drag_over_sell_zone"), "drag_outside_target_not_hovered")
	await _capture("drag")
	await _move_to(_battle.SELL_RECT.get_center())
	_check(_board.call("drag_over_sell_zone"), "target_hover_detected_from_native_motion")
	_check(zone.visible, "sell_zone_remains_visible_on_hover")
	var refund_label: Label = zone.find_child("SellRefund", true, false)
	_check(refund_label != null and refund_label.text.contains(str(refund)), "hover_displays_exact_refund")
	await _capture("hover")
	await _release(_battle.SELL_RECT.get_center())
	_check(not _board.is_dragging() and _board.call("dragged_gear") == null, "release_clears_drag")
	_check(_board.gears.size() == count - 1 and not _board.gears.has(cell), "drop_removes_exactly_one_gear")
	_check(is_equal_approx(_battle.core.meat, coins + refund), "sale_pays_exact_refund_once")
	_check(not zone.visible and ready.visible and not ready.disabled, "sale_restores_idle_controls")
	_check(_battle.phase == "shop" and _hud_clicks.is_empty(), "sell_release_does_not_click_ready_or_other_hud")
	await _release(_battle.SELL_RECT.get_center())
	_check(is_equal_approx(_battle.core.meat, coins + refund) and _board.gears.size() == count - 1, "duplicate_release_cannot_sell_twice")


func _invalid_case() -> void:
	var gears: Array = await _fixture([{"id": "kiem", "tier": 1, "cell": Vector2i(1, 0)}])
	var gear = gears[0]
	var cell: Vector2i = gear.cell
	var coins: float = _battle.core.meat
	await _begin_drag(gear)
	await _move_to(Vector2(360, 680))
	await _release(Vector2(360, 680))
	_check(_board.gears.get(cell) == gear and gear.position.is_equal_approx(_board.cell_center(cell)), "invalid_drop_returns_to_original_cell")
	_check(is_equal_approx(_battle.core.meat, coins), "invalid_drop_has_no_refund")
	_check(not _board.is_dragging() and not _hud.get("_sell_zone").visible, "invalid_drop_hides_target")
	_check(_battle.phase == "shop" and _hud_clicks.is_empty(), "invalid_drop_does_not_trigger_hud")


func _skill_case() -> void:
	var gears: Array = await _fixture([{"id": "skill", "tier": 1, "cell": Vector2i(1, 1)}])
	var gear = gears[0]
	var cell: Vector2i = gear.cell
	var coins: float = _battle.core.meat
	await _begin_drag(gear)
	_check(not _board.call("drag_can_sell"), "weapon_skill_drag_cannot_sell")
	_check(not _hud.get("_sell_zone").visible, "skill_drag_never_shows_sell_zone")
	var ready: Button = _hud.get("_ready_button")
	_check(not ready.visible or ready.disabled, "skill_drag_cannot_activate_ready")
	await _move_to(_battle.SELL_RECT.get_center())
	_check(not _hud.get("_sell_zone").visible, "skill_hover_keeps_sell_zone_hidden")
	await _release(_battle.SELL_RECT.get_center())
	_check(_board.gears.get(cell) == gear and gear.position.is_equal_approx(_board.cell_center(cell)), "skill_drop_returns_to_original_cell")
	_check(is_equal_approx(_battle.core.meat, coins) and _board.gears.size() == 1, "skill_cannot_be_sold_or_refunded")
	_check(_battle.phase == "shop" and _hud_clicks.is_empty(), "skill_release_does_not_click_ready")


func _merge_case() -> void:
	var gears: Array = await _fixture([
		{"id": "kiem", "tier": 1, "cell": Vector2i(1, 0)},
		{"id": "kiem", "tier": 1, "cell": Vector2i(2, 0)},
	])
	var source = gears[0]
	var target = gears[1]
	var target_cell: Vector2i = target.cell
	var coins: float = _battle.core.meat
	await _begin_drag(source)
	await _move_to(_cell_point(target_cell))
	await _release(_cell_point(target_cell))
	_check(_board.gears.size() == 1 and _board.gears.get(target_cell) == target and target.tier == 2, "ordinary_drag_merge_still_works")
	_check(is_equal_approx(_battle.core.meat, coins) and not _hud.get("_sell_zone").visible, "merge_does_not_sell_and_hides_target")
	_check(_battle.phase == "shop" and _hud_clicks.is_empty(), "merge_does_not_trigger_hud")


func _swap_case() -> void:
	var gears: Array = await _fixture([
		{"id": "kiem", "tier": 1, "cell": Vector2i(1, 0)},
		{"id": "cung", "tier": 1, "cell": Vector2i(2, 0)},
	])
	var a = gears[0]
	var b = gears[1]
	var from: Vector2i = a.cell
	var to: Vector2i = b.cell
	var coins: float = _battle.core.meat
	await _begin_drag(a)
	await _move_to(_cell_point(to))
	await _release(_cell_point(to))
	_check(_board.gears.get(from) == b and _board.gears.get(to) == a and a.cell == to and b.cell == from, "ordinary_drag_swap_still_works")
	_check(is_equal_approx(_battle.core.meat, coins) and _board.gears.size() == 2, "swap_does_not_sell_or_duplicate")
	_check(not _hud.get("_sell_zone").visible and _battle.phase == "shop" and _hud_clicks.is_empty(), "swap_restores_controls_without_hud_click")


func _hud_release_case() -> void:
	var gears: Array = await _fixture([{"id": "kiem", "tier": 1, "cell": Vector2i(1, 0)}])
	var gear = gears[0]
	var cell: Vector2i = gear.cell
	var card: Button = _hud.get("_cards")[0]
	var coins: float = _battle.core.meat
	var offer_before: Array = _battle.shop.duplicate(true)
	await _begin_drag(gear)
	await _move_to(card.get_global_rect().get_center())
	await _release(card.get_global_rect().get_center())
	_check(_board.gears.get(cell) == gear and gear.position.is_equal_approx(_board.cell_center(cell)), "release_over_shop_card_returns_dragged_gear")
	_check(_battle.shop == offer_before and is_equal_approx(_battle.core.meat, coins), "release_over_shop_card_does_not_buy")
	_check(_hud_clicks.is_empty() and _battle.phase == "shop", "no_hud_button_clickthrough_during_drag")


func _cancel_case() -> void:
	var gears: Array = await _fixture([{"id": "kiem", "tier": 1, "cell": Vector2i(1, 0)}])
	var gear = gears[0]
	var cell: Vector2i = gear.cell
	var coins: float = _battle.core.meat
	await _begin_drag(gear)
	_battle.start_wave()
	_check(_battle.phase == "shop" and _board.is_dragging(), "start_wave_rejected_while_dragging")
	await _move_to(_battle.SELL_RECT.get_center())
	_board.notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	await _settle()
	_check(not _board.is_dragging() and _board.gears.get(cell) == gear and gear.position.is_equal_approx(_board.cell_center(cell)), "focus_loss_cancels_drag_and_restores_source")
	_check(is_equal_approx(_battle.core.meat, coins) and not _hud.get("_sell_zone").visible, "focus_loss_cannot_sell_and_hides_target")
	await _release(Vector2(360, 680))
	await _begin_drag(gear)
	await _move_to(_battle.SELL_RECT.get_center())
	_battle.phase = "won"
	_board._process(0.0)
	await _settle()
	_check(not _board.is_dragging() and _board.gears.get(cell) == gear and gear.position.is_equal_approx(_board.cell_center(cell)), "ended_phase_cancels_drag_and_restores_source")
	_check(is_equal_approx(_battle.core.meat, coins) and not _hud.get("_sell_zone").visible, "ended_phase_cannot_sell_and_hides_target")
	await _release(Vector2(360, 680))
	_battle.phase = "shop"


func _wallet_capacity_case(full: bool) -> void:
	var gears: Array = await _fixture([{"id": "kiem", "tier": 3, "cell": Vector2i(1, 0)}])
	var gear = gears[0]
	var nominal: int = Economy.sell_refund(gear.troop.rarity, gear.tier)
	_battle.core.max_meat = 10.0 if full else 10.75
	_battle.core.meat = 10.0 if full else 9.8
	var before: float = _battle.core.meat
	var expected_balance: float = minf(_battle.core.max_meat, before + nominal)
	var displayed_gain := 0 if full else 1
	var prefix := "full_wallet_" if full else "fractional_capacity_"
	await _begin_drag(gear)
	await _move_to(_battle.SELL_RECT.get_center())
	var zone: Control = _hud.get("_sell_zone")
	var refund: Label = zone.find_child("SellRefund", true, false)
	var instruction: Label = zone.find_child("SellInstruction", true, false)
	_check(refund != null and refund.text == "+%d xu" % displayed_gain, prefix + "label_matches_visible_balance_gain")
	_check(nominal > displayed_gain, prefix + "fixture_refund_exceeds_capacity")
	_check(instruction != null and instruction.text.contains("Túi xu đầy" if full else "giới hạn"), prefix + "capacity_hint_visible")
	await _capture("full-wallet-hover" if full else "fractional-capacity-hover")
	await _release(_battle.SELL_RECT.get_center())
	_check(_board.gears.is_empty(), prefix + "sale_removes_one_gear")
	_check(is_equal_approx(_battle.core.meat, expected_balance), prefix + "sale_applies_only_available_capacity")
	_check(floori(_battle.core.meat) - floori(before) == displayed_gain, prefix + "sale_matches_displayed_whole_coin_gain")
	var toast: Label = _hud.get("_message")
	_check(toast.text.contains("túi xu đầy" if full else "hoàn 1 xu"), prefix + "toast_reports_received_gain")
	await _release(_battle.SELL_RECT.get_center())
	_check(is_equal_approx(_battle.core.meat, expected_balance) and _board.gears.is_empty(), prefix + "duplicate_release_cannot_pay_extra")
	_check(_battle.phase == "shop" and _hud_clicks.is_empty(), prefix + "sale_does_not_activate_hud")


func _fixture(specs: Array) -> Array:
	for gear in _board.gears.values():
		_board.remove_gear(gear)
	await get_tree().process_frame
	_board.tiles.clear()
	_board.open_cells.clear()
	for cell in _board.open_order():
		_board.open_cells[cell] = true
	var gears: Array = []
	for spec in specs:
		var troop: Resource = _skill_troop if spec.id == "skill" else PlayerData.TROOPS[spec.id]
		gears.append(_board.add_gear(troop, spec.tier, spec.cell))
	_battle.core.meat = 10
	_hud_clicks.clear()
	_watch_hud_buttons(_hud)
	await _settle()
	return gears


func _begin_drag(gear) -> void:
	var at: Vector2 = gear.global_position
	await _move_to(at)
	_mouse_button(at, true)
	await get_tree().process_frame
	await _move_to(at + Vector2(12, 5))
	_check(_board.is_dragging() and _board.call("dragged_gear") == gear, "native_press_motion_starts_drag")


func _cell_point(cell: Vector2i) -> Vector2:
	return _board.to_global(_board.cell_center(cell))


func _move_to(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	var transform := get_tree().root.get_final_transform()
	event.position = transform * at
	event.global_position = event.position
	event.relative = transform.basis_xform(at - _pointer)
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if _held else 0
	Input.parse_input_event(event)
	_pointer = at
	await get_tree().process_frame
	await get_tree().process_frame


func _mouse_button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = get_tree().root.get_final_transform() * at
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	_held = pressed
	Input.parse_input_event(event)


func _release(at: Vector2) -> void:
	_mouse_button(at, false)
	await _settle()


func _watch_hud_buttons(node: Node) -> void:
	if node is Button and not _watched.has(node.get_instance_id()):
		var id: int = node.get_instance_id()
		_watched[id] = true
		node.pressed.connect(func(): _hud_clicks.append(id))
	for child in node.get_children():
		_watch_hud_buttons(child)


func _settle() -> void:
	await get_tree().create_timer(0.16).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var name := "%s_%dx%d.png" % [label, _size.x, _size.y]
	_check(image.get_size() == _size, "native_capture_size_" + label)
	_check(image.save_png(_output_dir.path_join(name)) == OK, "capture_saved_" + label)
	_captures.append({"file": name, "window": [_size.x, _size.y], "dragging": _board.is_dragging(), "sell_visible": _hud.get("_sell_zone").visible})


func _check(ok: bool, label: String) -> void:
	_checks.append({"name": label, "passed": ok, "window": [_size.x, _size.y]})
	if not ok:
		_failed += 1
		push_error("GEAR_SELL_DROP_FAIL " + label + " " + str(_size))
	print("GEAR_SELL_DROP_CHECK ", label, " ", _size, " ", ok)


func _finish() -> void:
	var file := FileAccess.open(_output_dir.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"profile": OS.get_user_data_dir(), "persist": PlayerData.persist, "checks": _checks, "captures": _captures, "failures": _failed}, "\t"))
	file.close()
	print("GEAR_SELL_DROP_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failed)
	get_tree().quit(1 if _failed > 0 else 0)
