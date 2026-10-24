extends Node

# Native production review. Results are supplied directly, never rolled or granted.
# run.ps1 launches each window size with an isolated profile and -- --size=WIDTHxHEIGHT.
const HOME = preload("res://game/menu/Home.tscn")
const SummonOpening = preload("res://game/ui/SummonOpening.gd")
const SummonPortal = preload("res://game/ui/SummonPortal.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const OUT := "res://docs/ui_review/2026-10-24/summon-vfx"
const DEFAULT_SIZES := [Vector2i(450, 800), Vector2i(360, 640)]

var _home: Control
var _size := Vector2i.ZERO
var _checks: Array = []
var _captures: Array = []
var _failures := 0
var _again_calls := 0
var _size_started := 0
var _record := false
var _recording := false
var _record_clock := 0.0
var _record_index := 0
var _record_dir := ""
var _output_dir := OUT
var _frames_root := "res://tmp/summon-vfx-frames"
var _portal_strip := false
var _portal_recording := {}


func _ready() -> void:
	seed(241024)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 900
	PlayerData.castle_level = 3
	_home = HOME.instantiate()
	add_child(_home)
	var sizes: Array = DEFAULT_SIZES.duplicate()
	for arg in OS.get_cmdline_user_args():
		if arg == "--record":
			_record = true
		if arg == "--portal-strip":
			_portal_strip = true
		if arg.begins_with("--out="):
			_output_dir = arg.trim_prefix("--out=")
		if arg.begins_with("--frames="):
			_frames_root = arg.trim_prefix("--frames=")
		if arg.begins_with("--size="):
			var dimensions := arg.trim_prefix("--size=").split("x")
			if dimensions.size() == 2:
				sizes = [Vector2i(int(dimensions[0]), int(dimensions[1]))]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	for requested in sizes:
		_size = requested
		_size_started = Time.get_ticks_msec()
		get_window().size = requested
		await _wait(0.3)
		_home.select_tab(_home.SUMMON_TAB, false)
		await _wait(0.3)
		await _capture("banner")
		await _natural_case(10)
		await _natural_case(1)
		await _skip_case(false)
		await _skip_case(true)
		await _skip_charge_case()
		await _quick_tap_case()
		await _non_home_case()
		if _portal_strip:
			await _capture_portal_states()
		_check(_again_calls == 0, "presentation_never_invokes_summon_again")
		_check(Time.get_ticks_msec() - _size_started < 55000, "review_finishes_under_55_seconds")
		_write_manifest()
	print("SUMMON_VFX_REVIEW_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures else 0)


func _process(delta: float) -> void:
	if not _recording:
		return
	_record_clock += delta
	if _record_clock >= 1.0 / 12.0:
		_record_clock = fmod(_record_clock, 1.0 / 12.0)
		_record_frame()


func _record_frame() -> void:
	await RenderingServer.frame_post_draw
	if not _recording:
		return
	var image := get_viewport().get_texture().get_image()
	image.save_png(_record_dir.path_join("frame-%04d.png" % _record_index))
	_record_index += 1


func _results(count: int, special_first := false) -> Array:
	var ids := ["kiem", "no", "sach_phep", "bua", "giao", "riu", "cung", "thuoc", "gay_phep", "kiem"]
	if special_first:
		ids = ["bua", "kiem", "no", "sach_phep", "giao", "riu", "cung", "thuoc", "gay_phep", "kiem"]
	var results: Array = []
	for index in count:
		var id: String = ids[index]
		var troop: Resource = PlayerData.TROOPS[id]
		# One newly unlocked ordinary troop also exercises its mandatory showcase.
		results.append({"type": "card", "id": id, "rarity": troop.rarity, "new": index == 0})
	return results


func _open(results: Array) -> Control:
	var opening := SummonOpening.new()
	opening.setup(results, func(): _again_calls += 1)
	opening.attach(_home)
	return opening


func _natural_case(count: int) -> void:
	var before := _snapshot()
	var prefix := "x%d" % count
	_home.select_tab(_home.SUMMON_TAB, false)
	await _wait(0.12)
	var opening := _open(_results(count))
	if _record and count == 10:
		_record_dir = _frames_root.path_join("%dx%d" % [_size.x, _size.y])
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_record_dir))
		_record_index = 0
		_record_clock = 0.0
		_recording = true
	await _wait(0.35)
	_check(opening._stage == "charge", prefix + "_charge_visible")
	_check(_home.active_menu_context() == "summon", prefix + "_summon_context")
	_check(not _home._header.visible and not _home._nav_holder.visible and not _home._content.visible,
		prefix + "_opening_hides_underlying_chrome")
	await _capture(prefix + "-charge", opening)
	if await _wait_stage(opening, "burst", 4.0):
		await _wait(0.1)
		await _capture(prefix + "-burst", opening)
	if await _wait_stage(opening, "reveal", 3.0):
		await _wait(0.12)
		await _capture(prefix + "-reveal", opening)
	if count == 10 and await _wait_special(opening, 6.0):
		await _wait(0.12)
		await _capture(prefix + "-special", opening)
	if await _wait_stage(opening, "showcase", 12.0):
		await _wait(0.4)
		await _capture(prefix + "-showcase", opening)
	var deadline := Time.get_ticks_msec() + 8000
	while opening._stage != "done" and Time.get_ticks_msec() < deadline:
		await _wait(0.6)
		opening._on_tap()
	_check(opening._stage == "done", prefix + "_natural_flow_reaches_done")
	if opening._stage != "done":
		opening.skip()
	await _wait(0.15)
	_assert_results(opening, count, prefix + "_natural_done")
	await _capture(prefix + "-done", opening)
	_recording = false
	_check(_snapshot() == before, prefix + "_presentation_keeps_rewards_and_currency_unchanged")
	await _close(opening, "summon", prefix)
	_check(_snapshot() == before, prefix + "_close_keeps_rewards_and_currency_unchanged")


func _skip_case(during_special: bool) -> void:
	var label := "skip-special" if during_special else "skip-flight"
	_home.select_tab(_home.SHOP_TAB, false)
	await _wait(0.2)
	var before := _snapshot()
	var opening := _open(_results(10, during_special))
	var reached := false
	if during_special:
		reached = await _wait_special(opening, 6.0)
	else:
		reached = await _wait_stage(opening, "burst", 4.0)
		await _wait(0.09)
	_check(reached, label + "_target_phase_reached")
	await _capture(label + "-before", opening)
	_check(await _tap(opening._skip), label + "_native_skip_input")
	await get_tree().process_frame
	_assert_results(opening, 10, label + "_immediate")
	# Repeated input must leave one stable set of result buttons.
	opening.skip()
	opening.skip()
	await _wait(1.05)
	_assert_results(opening, 10, label + "_after_motion_settles")
	await _capture(label + "-done", opening)
	_check(_snapshot() == before, label + "_does_not_grant_or_charge")
	await _close(opening, "shop", label)
	_check(_snapshot() == before, label + "_close_does_not_grant_or_charge")


func _skip_charge_case() -> void:
	var before := _snapshot()
	var opening := _open(_results(10))
	await _wait(0.1)
	_check(opening._stage == "charge", "skip-charge_initial_charge")
	_check(await _tap(opening._skip), "skip-charge_native_skip_input")
	_assert_results(opening, 10, "skip-charge_immediate")
	opening.skip()
	await _wait(1.05)
	_assert_results(opening, 10, "skip-charge_after_motion_settles")
	await _capture("skip-charge-done", opening)
	await _close(opening, "shop", "skip-charge")
	_check(_snapshot() == before, "skip-charge_does_not_grant_or_charge")


func _quick_tap_case() -> void:
	var before := _snapshot()
	var opening := _open(_results(10, true))
	await _wait(0.08)
	opening._on_tap()
	_check(opening._stage == "burst", "quick-tap_charge_advances_to_burst")
	_check(opening._cards.size() == 10, "quick-tap_burst_deals_exactly_ten_cards")
	opening._on_tap()
	_check(opening._stage == "reveal", "quick-tap_burst_advances_to_reveal")
	_assert_home_positions(opening, "quick-tap_burst_cancels_card_flight")
	if await _wait_special(opening, 3.0):
		var next_before: int = opening._next
		var guard_before: float = opening._special_until
		opening._on_tap()
		_check(opening._stage == "reveal" and opening._next == next_before,
			"quick-tap_rare_tease_holds_reveal")
		_check(opening._special_until == guard_before and opening._time < opening._special_until,
			"quick-tap_rare_tease_preserves_input_guard")
		await _capture("quick-tap-rare-tease", opening)
	opening.skip()
	await _wait(0.1)
	_assert_results(opening, 10, "quick-tap_done")
	await _close(opening, "shop", "quick-tap")
	_check(_snapshot() == before, "quick-tap_does_not_grant_or_charge")


func _assert_home_positions(opening: Control, label: String) -> void:
	var homes_ok := true
	for card: Control in opening._cards:
		homes_ok = homes_ok and card.position.distance_to(card.get_meta("home")) < 0.05
		homes_ok = homes_ok and absf(card.rotation) < 0.001
	_check(homes_ok, label)


func _non_home_case() -> void:
	var before := _snapshot()
	var host := Control.new()
	add_child(host)
	var opening := SummonOpening.new()
	opening.setup(_results(1), func(): _again_calls += 1)
	opening.attach(host)
	await _wait(0.32)
	_check(not opening._menu_pattern, "non-home_uses_fallback_background")
	_check(is_equal_approx(opening.dim, 0.9), "non-home_preserves_point_nine_dim")
	opening.skip()
	_assert_results(opening, 1, "non-home_done")
	opening._close()
	await get_tree().process_frame
	_check(not is_instance_valid(opening), "non-home_close_frees_layer")
	host.queue_free()
	_check(_snapshot() == before, "non-home_does_not_grant_or_charge")


func _assert_results(opening: Control, count: int, label: String) -> void:
	_check(opening._stage == "done", label + "_stage_done")
	_check(opening._cards.size() == count, label + "_exact_result_count")
	var transforms_ok := true
	var faces_ok := true
	for card: Control in opening._cards:
		var target_scale := Vector2.ONE * float(card.get_meta("scale"))
		transforms_ok = transforms_ok and card.position.distance_to(card.get_meta("home")) < 0.05
		transforms_ok = transforms_ok and card.scale.distance_to(target_scale) < 0.001
		transforms_ok = transforms_ok and absf(card.rotation) < 0.001
		faces_ok = faces_ok and card.get_node("Front").visible and not card.get_node("Back").visible
		faces_ok = faces_ok and is_equal_approx(card.modulate.a, 1.0)
	_check(transforms_ok, label + "_cards_stay_at_home_scale_and_rotation")
	_check(faces_ok, label + "_all_cards_face_up_and_opaque")
	_check(_buttons(opening, "XONG", false).size() == 1, label + "_one_done_button")
	_check(_buttons(opening, "LẠI x", true).size() == 1, label + "_one_again_button")
	_check(not opening._skip.visible, label + "_skip_hidden")


func _capture_portal_states() -> void:
	# A separate native surface exposes the production portal without cards or cats.
	# This is visual evidence, with no assertions about its individual drawing paths.
	var before := _snapshot()
	var layer := CanvasLayer.new()
	layer.layer = 35
	add_child(layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color("30263f")
	backdrop.size = Vector2(720, 1280)
	layer.add_child(backdrop)
	var portal := SummonPortal.new()
	portal.position = Vector2(360, 600)
	portal.set_process(false)
	layer.add_child(portal)
	var caption := UiKit.label("", 30, Color("fff0c7"))
	caption.position = Vector2(30, 220)
	caption.size = Vector2(660, 50)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(caption)
	var energies := [0.0, 0.5, 1.0]
	for index in energies.size():
		portal.energy = energies[index]
		portal.accent = Color("d7c2f4")
		portal.elapsed = 1.2
		portal.clear_bursts()
		portal.queue_redraw()
		caption.text = "ENERGY %s" % str(energies[index])
		await get_tree().process_frame
		await _capture("portal-energy-%d" % index)
	portal.energy = 0.0
	portal.accent = Color("ffb938")
	portal.pulse(Vector2(0, -65), Color("ffb938"), 1.45)
	portal._process(0.18)
	caption.text = "RELEASE"
	await get_tree().process_frame
	await _capture("portal-release")
	if _record:
		var portal_frames_dir := _frames_root.path_join("%dx%d/portal" % [_size.x, _size.y])
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(portal_frames_dir))
		portal.clear_bursts()
		portal.elapsed = 1.2
		caption.text = ""
		for frame_index in 36:
			portal.energy = clampf(float(frame_index) / 17.0, 0.0, 1.0) if frame_index < 18 else 0.0
			portal.accent = Color("d7c2f4") if frame_index < 18 else Color("ffb938")
			if frame_index == 18:
				portal.pulse(Vector2(0, -65), Color("ffb938"), 1.45)
			portal._process(1.0 / 12.0)
			await RenderingServer.frame_post_draw
			var frame := get_viewport().get_texture().get_image()
			frame.save_png(portal_frames_dir.path_join("frame-%04d.png" % frame_index))
		_portal_recording = {"directory": portal_frames_dir, "frames": 36, "fps": 12,
			"charge_frames": 18, "pulse_frame": 18, "simulated_seconds": 3.0}
	layer.queue_free()
	await get_tree().process_frame
	_check(_snapshot() == before, "portal_strip_keeps_player_data_unchanged")


func _close(opening: Control, context: String, label: String) -> void:
	var buttons := _buttons(opening, "XONG", false)
	var tapped := false
	if not buttons.is_empty():
		tapped = await _tap(buttons[0])
	_check(tapped, label + "_native_done_input")
	if not tapped and is_instance_valid(opening):
		opening._close()
	await _wait(0.2)
	_check(not is_instance_valid(opening), label + "_layer_freed")
	_check(_home.active_menu_context() == context, label + "_restores_menu_context")
	_check(_home._header.visible and _home._nav_holder.visible and _home._content.visible,
		label + "_restores_menu_chrome")
	_check(_home._shop_awning.visible == (context == "shop"), label + "_restores_shop_awning")


func _wait_stage(opening: Control, stage: String, seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while is_instance_valid(opening) and opening._stage != stage and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var reached: bool = is_instance_valid(opening) and opening._stage == stage
	_check(reached, "reached_stage_" + stage)
	return reached


func _wait_special(opening: Control, seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while is_instance_valid(opening) and Time.get_ticks_msec() < deadline:
		if opening._stage == "reveal" and opening._special_until > opening._time:
			return true
		await get_tree().process_frame
	_check(false, "reached_special_reveal")
	return false


func _buttons(scope: Node, text: String, prefix: bool) -> Array:
	var matches: Array = []
	for button: Button in scope.find_children("*", "Button", true, false):
		var matches_text := button.text.begins_with(text) if prefix else button.text == text
		if matches_text:
			matches.append(button)
	return matches


func _tap(button: Button) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
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
		"summon_pity": PlayerData.summon_pity, "summon_free_day": PlayerData.summon_free_day,
		"summon_total": PlayerData.summon_total}


func _capture(label: String, opening: Control = null) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var filename := "%s_%dx%d.png" % [label, _size.x, _size.y]
	_check(image.get_size() == _size, "capture_native_size_" + label)
	_check(image.save_png(_output_dir.path_join(filename)) == OK, "capture_saved_" + label)
	var record := {"file": filename, "window": [_size.x, _size.y]}
	if is_instance_valid(opening):
		record["stage"] = opening._stage
		record["card_count"] = opening._cards.size()
		record["time"] = opening._time
	_captures.append(record)


func _write_manifest() -> void:
	var filename := "manifest-%dx%d.json" % [_size.x, _size.y]
	var report := {"profile": OS.get_user_data_dir(), "persist": PlayerData.persist, "output_dir": _output_dir,
		"window": [_size.x, _size.y], "checks": _checks, "captures": _captures,
		"elapsed_seconds": (Time.get_ticks_msec() - _size_started) / 1000.0, "failures": _failures}
	if _record:
		report["recording"] = {"directory": _record_dir, "frames": _record_index, "fps": 12}
		if not _portal_recording.is_empty():
			report["recording"]["portal"] = _portal_recording
	var file := FileAccess.open(_output_dir.path_join(filename), FileAccess.WRITE)
	if file == null:
		_check(false, "manifest_write")
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(passed: bool, label: String) -> void:
	_checks.append({"name": label, "passed": passed, "window": [_size.x, _size.y]})
	if not passed:
		_failures += 1
		push_error("SUMMON_VFX_REVIEW_FAIL " + label)
