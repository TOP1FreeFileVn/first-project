extends Node

# Real production Home -> SummonPage -> PlayerData.summon -> carton presentation.
# The profile is isolated by run.ps1; no synthetic rewards are passed to the opening.
const HOME = preload("res://game/menu/Home.tscn")
const HeroCat = preload("res://game/core/HeroCat.gd")
const Economy = preload("res://game/core/Economy.gd")
const OUT := "res://docs/design/2026-10-25/carton-summon-integration/review"

var _home: Control
var _size := Vector2i(450, 800)
var _checks: Array = []
var _captures: Array = []
var _failures := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--size="):
			var dimensions := arg.trim_prefix("--size=").split("x")
			_size = Vector2i(int(dimensions[0]), int(dimensions[1]))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	get_window().size = _size
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.castle_level = 3
	PlayerData.gems = 4000
	PlayerData.gold = 2400
	PlayerData.sound_on = false
	seed(251025)
	_home = HOME.instantiate()
	add_child(_home)
	_home.select_tab(_home.SUMMON_TAB, false)
	await _wait(0.3)
	await _capture("summon-page")
	await _natural_free_legendary()
	await _paid_and_repeat()
	await _max_star_conversion()
	await _insufficient_and_close()
	_check(not PlayerData.persist, "profile_never_persists")
	var report := {"window": [_size.x, _size.y], "checks": _checks, "captures": _captures,
		"failures": _failures, "persist": PlayerData.persist, "profile": OS.get_user_data_dir(),
		"scope": "Production Home, real free/paid x1/x10, natural new legendary, skip/close/repeat, stale duplicate activation and max-star conversion"}
	var file := FileAccess.open(OUT.path_join("manifest-%dx%d.json" % [_size.x, _size.y]), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	# Flush Home timers, CanvasLayers and their bound callbacks before shutdown.
	_home.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	# Dummy audio shutdown otherwise retains the lobby WAV playback resource.
	for child in MusicLib.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await get_tree().process_frame
	await get_tree().process_frame
	await _wait(0.12)
	print("CARTON_SUMMON_INTEGRATION_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit.call_deferred(1 if _failures else 0)


func _natural_free_legendary() -> void:
	PlayerData.summon_pity = HeroCat.SUMMON_PITY - 1
	var before := _snapshot()
	var opening: Control = await _pull(1)
	if opening == null:
		return
	_check(PlayerData.gems == before["gems"], "free_x1_costs_zero")
	_check(PlayerData.summon_total == int(before["total"]) + 1, "free_x1_grants_once")
	_check(not PlayerData.summon_free_ready(), "free_x1_consumes_daily_free")
	_check(opening._results.size() == 1 and int(opening._results[0]["rarity"]) == 3, "real_pity_is_legendary")
	_check(bool(opening._results[0]["new"]), "real_first_legendary_is_new")
	_check(PlayerData.is_unlocked(opening._results[0]["id"]), "new_legendary_already_unlocked_before_animation")
	var granted := _snapshot()
	var cartons: Control = opening._cartons
	_check(cartons.get_script().resource_path.begins_with("res://game/"), "opening_uses_production_carton_stage")
	var lengths: Array = cartons._lengths[0]
	var start: float = cartons._starts[0]
	await _wait_clock(opening, start + float(lengths[0]) + float(lengths[1]) * 0.86)
	await _capture("x1-paw", opening)
	await _wait_clock(opening, start + float(lengths[0]) + float(lengths[1]) + 0.48 + 0.55)
	_check(float(cartons._glow) >= 0.9 and float(cartons._focus.cat_rise) == 0.0, "natural_gold_hold_precedes_cat")
	await _capture("x1-gold-hold", opening)
	await _wait_clock(opening, 4.5)
	await _capture("x1-exposed-wrist", opening)
	var deadline := Time.get_ticks_msec() + 14000
	while opening._stage == "carton" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(opening._stage == "showcase", "natural_new_legendary_reaches_showcase")
	await _wait(0.4)
	await _capture("x1-new-showcase", opening)
	await _finish_showcases(opening)
	_assert_done(opening, 1, "natural_x1")
	await _capture("x1-results", opening)
	_check(_snapshot() == granted, "natural_animation_does_not_regrant")
	await _close_native(opening, "natural_x1")
	_check(_snapshot() == granted, "natural_close_does_not_regrant")


func _paid_and_repeat() -> void:
	var before := _snapshot()
	var opening: Control = await _pull(10)
	if opening == null:
		return
	_assert_pull_delta(before, opening, 10, "paid_x10")
	var granted := _snapshot()
	# Freeze only the visual clock for reproducible views; all results are real.
	opening._cartons.set_process(false)
	opening._cartons.seek(0.95)
	await _capture("x10-arrived-boxes", opening)
	var selected := 0
	for index in opening._results.size():
		if int(opening._results[index]["rarity"]) >= int(opening._results[selected]["rarity"]):
			selected = index
	var lengths: Array = opening._cartons._lengths[selected]
	var start: float = opening._cartons._starts[selected]
	opening._cartons.seek(start + float(lengths[0]) + float(lengths[1]) * 0.88)
	await _capture("x10-paw", opening)
	opening._cartons.seek(start + float(lengths[0]) + float(lengths[1]) + float(lengths[2]) * 0.75)
	await _capture("x10-best-light", opening)
	_check(await _tap(opening._skip), "paid_x10_native_skip")
	opening.skip()
	opening.skip()
	await _wait(0.5)
	_assert_done(opening, 10, "paid_x10_skip")
	_check(_snapshot() == granted, "skip_repeated_does_not_regrant_or_charge")
	await _capture("x10-results", opening)
	var again := _button(opening, "LẠI x10", true)
	_check(again != null and not again.disabled, "funded_repeat_is_enabled")
	_check(await _tap(again), "native_repeat_x10_input")
	await _wait(0.15)
	var repeated := _opening()
	_check(repeated != null and repeated != opening, "repeat_replaces_old_layer")
	_check(not is_instance_valid(opening), "repeat_frees_old_opening")
	if repeated == null:
		return
	_assert_pull_delta(granted, repeated, 10, "native_repeat_x10")
	var repeated_grant := _snapshot()
	repeated.skip()
	await _wait(0.1)
	_assert_done(repeated, 10, "native_repeat_done")
	# Stress two stale activations before queue_free is flushed. Native repeat above
	# covers pointer routing; direct signals cover the old-button lifetime window.
	var stale_again := _button(repeated, "LẠI x10", true)
	_check(stale_again != null, "duplicate_repeat_target_exists")
	if stale_again != null:
		stale_again.pressed.emit()
		stale_again.pressed.emit()
	await _wait(0.15)
	var last := _opening()
	_check(_openings().size() == 1, "duplicate_repeat_creates_one_opening")
	_check(PlayerData.summon_total == int(repeated_grant["total"]) + 10, "duplicate_repeat_grants_one_batch")
	_check(PlayerData.gems == int(repeated_grant["gems"]) - HeroCat.SUMMON_COST[10], "duplicate_repeat_charges_once")
	if last != null:
		var last_grant := _snapshot()
		last.skip()
		await _wait(0.3)
		_assert_done(last, 10, "duplicate_repeat_done")
		await _close_native(last, "duplicate_repeat")
		_check(_snapshot() == last_grant, "repeat_skip_close_keeps_post_grant_data")


func _max_star_conversion() -> void:
	for id in PlayerData.troops:
		PlayerData.troops[id]["unlocked"] = true
		PlayerData.troops[id]["stars"] = Economy.MAX_STARS
	PlayerData._commit()
	await _wait(0.1)
	var before := _snapshot()
	var opening: Control = await _pull(10)
	if opening == null:
		return
	_check(PlayerData.gold == int(before["gold"]) + 10 * Economy.SPARE_CARD_GOLD, "max_star_real_x10_converts_exactly_ten_cards")
	_check(PlayerData.troops == before["troops"], "max_star_conversion_does_not_add_inventory_cards")
	_check(opening._results.all(func(result): return not result["new"]), "max_star_results_are_duplicates")
	var granted := _snapshot()
	# Exercise the normal carton completion boundary without waiting through ten
	# already-covered reveal beats. This does not roll or grant anything.
	opening._cartons.set_process(false)
	opening._cartons.complete()
	opening._cartons.finished.emit()
	await _finish_showcases(opening)
	_assert_done(opening, 10, "max_star_natural_boundary")
	_check(_snapshot() == granted, "carton_completion_and_showcase_do_not_double_convert")
	await _close_native(opening, "max_star")


func _insufficient_and_close() -> void:
	PlayerData.gems = 0
	PlayerData.summon_free_day = PlayerData.today()
	PlayerData._commit()
	await _wait(0.1)
	for count in [1, 10]:
		var button := _button(_page(), "TRIỆU HỒI x%d" % count, true)
		_check(button != null and button.disabled, "insufficient_x%d_page_disabled" % count)
	var before := _snapshot()
	_page()._summon(10)
	_check(_opening() == null and _snapshot() == before, "refused_pull_opens_nothing_and_changes_nothing")
	# Spend the exact last batch, making the result's repeat button disabled.
	PlayerData.gems = HeroCat.SUMMON_COST[10]
	PlayerData._commit()
	await _wait(0.1)
	var opening: Control = await _pull(10)
	if opening == null:
		return
	var granted := _snapshot()
	opening.skip()
	await _wait(0.1)
	var again := _button(opening, "LẠI x10", true)
	_check(again != null and again.disabled, "last_batch_disables_repeat")
	await _capture("insufficient-repeat", opening)
	await _close_native(opening, "insufficient_repeat")
	_check(_snapshot() == granted, "disabled_repeat_and_close_do_not_charge")
	# Closing a live carton must keep already-granted results too.
	PlayerData.gems = HeroCat.SUMMON_COST[1]
	PlayerData._commit()
	await _wait(0.1)
	var active: Control = await _pull(1)
	if active != null:
		var active_grant := _snapshot()
		_check(active._stage == "carton", "mid_close_occurs_during_carton")
		active._close()
		await _wait(0.2)
		_check(not is_instance_valid(active) and _openings().is_empty(), "mid_close_frees_active_layer")
		_check(_snapshot() == active_grant, "mid_close_preserves_already_granted_result")
		_check(_home.active_menu_context() == "summon" and _home._header.visible, "mid_close_restores_summon_page")


func _pull(count: int) -> Control:
	var button := _button(_page(), "TRIỆU HỒI x%d" % count, true)
	_check(button != null and not button.disabled, "x%d_page_button_ready" % count)
	_check(await _ensure_visible(button), "x%d_button_reachable" % count)
	_check(await _tap(button), "x%d_native_pull_input" % count)
	await get_tree().process_frame
	var opening := _opening()
	_check(opening != null and _openings().size() == 1, "x%d_opens_one_production_layer" % count)
	if opening != null:
		_check(opening._results.size() == count, "x%d_has_exact_real_results" % count)
		_check(_home.active_menu_context() == "summon" and not _home._header.visible and not _home._nav_holder.visible,
			"x%d_hides_underlying_home" % count)
	return opening


func _assert_pull_delta(before: Dictionary, opening: Control, count: int, label: String) -> void:
	_check(PlayerData.gems == int(before["gems"]) - HeroCat.SUMMON_COST[count], label + "_charges_exact_cost")
	_check(PlayerData.summon_total == int(before["total"]) + count, label + "_increments_total_once")
	_check(int(PlayerData.quest_progress.get("summon", 0)) == int(before["quest_raw"]) + count,
		label + "_tracks_quest_once")
	_check(opening._results.any(func(result): return int(result["rarity"]) >= 2) if count == 10 else true,
		label + "_retains_x10_epic_guarantee")
	var expected: Dictionary = before["troops"].duplicate(true)
	var expected_gold: int = before["gold"]
	var consistent := true
	for result: Dictionary in opening._results:
		var id: String = result["id"]
		var troop: Dictionary = expected[id]
		consistent = consistent and result["type"] == "card" and int(result["rarity"]) == PlayerData.TROOPS[id].rarity
		consistent = consistent and bool(result["new"]) == (not bool(troop["unlocked"]))
		if not troop["unlocked"]:
			troop["unlocked"] = true
		elif int(troop["stars"]) >= Economy.MAX_STARS:
			expected_gold += Economy.SPARE_CARD_GOLD
		else:
			troop["cards"] += 1
	_check(consistent, label + "_result_rarity_and_new_flags_match_grants")
	_check(PlayerData.troops == expected and PlayerData.gold == expected_gold, label + "_inventory_and_duplicate_gold_granted_once")


func _finish_showcases(opening: Control) -> void:
	var deadline := Time.get_ticks_msec() + 7000
	while opening._stage != "done" and Time.get_ticks_msec() < deadline:
		await _wait(0.56)
		opening._on_tap()
	_check(opening._stage == "done", "showcases_reach_done")
	if opening._stage != "done":
		opening.skip()


func _assert_done(opening: Control, count: int, label: String) -> void:
	_check(opening._stage == "done" and opening._cards.size() == count, label + "_stable_done_result_count")
	_check(_buttons(opening, "XONG", false).size() == 1 and _buttons(opening, "LẠI x", true).size() == 1,
		label + "_one_set_of_result_controls")
	_check(not opening._skip.visible, label + "_skip_hidden")
	var all_visible := true
	for card: Control in opening._cards:
		all_visible = all_visible and card.is_visible_in_tree() and is_equal_approx(card.modulate.a, 1.0)
	_check(all_visible, label + "_all_results_visible")


func _close_native(opening: Control, label: String) -> void:
	_check(await _tap(_button(opening, "XONG", false)), label + "_native_done_input")
	await _wait(0.2)
	_check(not is_instance_valid(opening) and _openings().is_empty(), label + "_layer_freed")
	_check(_home.active_menu_context() == "summon" and _home._header.visible and _home._nav_holder.visible and _home._content.visible,
		label + "_restores_page_and_home_chrome")


func _wait_clock(opening: Control, seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while opening._stage == "carton" and float(opening._cartons._clock) < seconds and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(opening._stage == "carton" and float(opening._cartons._clock) >= seconds, "natural_clock_reaches_" + str(seconds))


func _page() -> Control:
	return _home._pages[_home.SUMMON_TAB]


func _openings() -> Array:
	var found: Array = []
	for control: Control in _home.find_children("*", "Control", true, false):
		if control.get_script() != null and control.get_script().resource_path == "res://game/ui/SummonOpening.gd" and not control.is_queued_for_deletion():
			found.append(control)
	return found


func _opening() -> Control:
	var found := _openings()
	return found.back() if not found.is_empty() else null


func _buttons(scope: Node, text: String, prefix: bool) -> Array:
	var found: Array = []
	for button: Button in scope.find_children("*", "Button", true, false):
		var matches: bool = button.text.begins_with(text) if prefix else button.text == text
		if matches and button.is_visible_in_tree():
			found.append(button)
	return found


func _button(scope: Node, text: String, prefix: bool) -> Button:
	var found := _buttons(scope, text, prefix)
	return found[0] if not found.is_empty() else null


func _ensure_visible(control: Control) -> bool:
	if control == null or not control.is_visible_in_tree():
		return false
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(control)
			await get_tree().process_frame
			return ancestor.get_global_rect().grow(2).encloses(control.get_global_rect())
		ancestor = ancestor.get_parent()
	return true


func _tap(button: Button) -> bool:
	if button == null or not is_instance_valid(button) or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var at := get_tree().root.get_final_transform() * button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	await get_tree().process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
	return received[0]


func _snapshot() -> Dictionary:
	return {"gold": PlayerData.gold, "gems": PlayerData.gems, "troops": PlayerData.troops.duplicate(true),
		"team": PlayerData.team.duplicate(), "pity": PlayerData.summon_pity, "total": PlayerData.summon_total,
		"free_day": PlayerData.summon_free_day, "quest": PlayerData.quest_count("summon"),
		"quest_raw": int(PlayerData.quest_progress.get("summon", 0))}


func _capture(label: String, opening: Control = null) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var filename := "%s-%dx%d.png" % [label, _size.x, _size.y]
	_check(image.get_size() == _size and image.save_png(OUT.path_join(filename)) == OK, "native_capture_" + label)
	var record := {"file": filename}
	if is_instance_valid(opening):
		record["stage"] = opening._stage
		record["count"] = opening._results.size()
	_captures.append(record)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(passed: bool, name: String) -> void:
	_checks.append({"name": name, "passed": passed})
	if not passed:
		_failures += 1
		push_error("CARTON_SUMMON_INTEGRATION_FAIL " + name)
