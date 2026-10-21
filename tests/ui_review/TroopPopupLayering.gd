extends Node

# Real production roster + popup, disposable RAM state and native pointer input.
const HOME = preload("res://game/menu/Home.tscn")
const OUT := "res://docs/ui_review/2026-10-21/troop-popup-layering"
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
const MARKERS := ["TroopLevelReady", "TroopStarReady", "TroopInTeam"]

var _home
var _page
var _checks: Array = []
var _captures: Array = []
var _comparisons: Array = []
var _failures := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.tutorial_done = true
	PlayerData.castle_level = 6
	PlayerData.gold = 100000
	PlayerData.gems = 260
	for id in PlayerData.TROOP_ORDER:
		PlayerData.troops[id] = {"unlocked": PlayerData.TROOP_ORDER.find(id) < 8, "level": 1, "stars": 1, "cards": 0}
	PlayerData.troops.kiem.level = 7
	PlayerData.troops.kiem.stars = 3
	PlayerData.troops.riu.stars = 3
	PlayerData.team = ["kiem", "riu", "dao", "cung", "no"]
	get_window().size = SIZES[0]
	_home = HOME.instantiate()
	add_child(_home)
	_home.select_tab(_home.TROOPS_TAB, false)
	_page = _home._pages[_home.TROOPS_TAB]
	await _settle()
	_check(PlayerData.battle_team().size() == 5, "fixture_has_five_teamed_troops")
	for requested in SIZES:
		get_window().size = requested
		await _settle()
		await _review_size(requested)
	_finish()


func _review_size(requested: Vector2i) -> void:
	var markers: Array[Control] = []
	_collect_markers(_page, markers)
	_check(markers.size() >= 13, "eight_upgrade_arrows_and_five_team_checks", requested)
	var local_layers := true
	var leads_check := true
	for marker in markers:
		local_layers = local_layers and marker.z_index == 0
		if str(marker.name) != "TroopInTeam":
			var card := marker.get_parent() as Control
			var check := card.find_child("TroopInTeam", false, false) as Control
			leads_check = leads_check and marker.position.y < 0.0
			if check != null:
				leads_check = leads_check and marker.position.x < check.position.x
	_check(local_layers, "roster_decorations_stay_on_card_layer_zero", requested)
	_check(leads_check, "upgrade_arrow_leads_team_check_and_crosses_card_top", requested)
	await _capture("roster-before", requested)
	var dao := _page.find_child("TroopCard_dao", true, false) as Button
	_check(dao != null and dao.is_visible_in_tree(), "dao_native_card_available", requested)
	await _tap(dao)
	await _settle()
	var popup := _popup()
	_check(popup != null and _page._detail_id == "dao", "native_dao_card_opens_detail_popup", requested)
	if popup == null:
		return
	var panel := _primary_panel(popup)
	_check(panel != null, "opaque_popup_panel_found", requested)
	if panel == null:
		return
	_freeze(markers)
	await get_tree().process_frame
	var opaque := panel.get_global_rect().grow(-40.0)
	var regions: Array[Rect2] = []
	var arrow_regions := 0
	var check_regions := 0
	for marker in markers:
		var ink := marker.get_global_rect()
		if marker.has_method("get_review_state"):
			ink = marker.call("get_review_state").get("ink_rect", ink)
		var covered := ink.intersection(opaque)
		if covered.size.x >= 4.0 and covered.size.y >= 4.0:
			regions.append(covered)
			if str(marker.name) == "TroopInTeam":
				check_regions += 1
			else:
				arrow_regions += 1
	_check(arrow_regions > 0 and check_regions > 0, "opaque_popup_covers_real_arrow_and_check_ink_regions", requested)
	var fixed := await _capture("popup-fixed", requested)
	for marker in markers:
		marker.hide()
	await get_tree().process_frame
	var hidden := await _capture("popup-markers-hidden-reference", requested)
	var fixed_diff := _compare_regions(fixed, hidden, regions)
	_check(int(fixed_diff.pixels) > 100 and int(fixed_diff.changed) == 0, "opaque_popup_pixels_identical_with_underlying_markers_hidden", requested)
	# Negative control reproduces the old runtime layering without editing production.
	for marker in markers:
		marker.show()
		marker.z_index = 1 if str(marker.name) == "TroopInTeam" else 8
	_freeze(markers)
	await get_tree().process_frame
	var raised := await _capture("negative-control-raised-markers", requested)
	var raised_diff := _compare_regions(raised, hidden, regions)
	_check(int(raised_diff.changed) > 20, "negative_control_detects_old_markers_drawing_through_popup", requested)
	for marker in markers:
		marker.z_index = 0
	_freeze(markers)
	await get_tree().process_frame
	var restored := await _capture("popup-restored", requested)
	var restored_diff := _compare_regions(restored, hidden, regions)
	_check(int(restored_diff.changed) == 0, "restored_card_layers_again_match_opaque_popup_reference", requested)
	var region_data: Array = []
	for region in regions:
		region_data.append([region.position.x, region.position.y, region.size.x, region.size.y])
	_comparisons.append({"window": [requested.x, requested.y], "arrow_regions": arrow_regions, "check_regions": check_regions, "logical_regions": region_data, "fixed_vs_hidden": fixed_diff, "raised_vs_hidden": raised_diff, "restored_vs_hidden": restored_diff})
	# Only actual native upgrade and close buttons are used after the pixel comparison.
	var upgrade := _level_button(popup)
	_check(upgrade != null and not upgrade.disabled, "native_level_upgrade_available_inside_popup", requested)
	if upgrade != null:
		var scroll := _page._detail_box.get_parent() as ScrollContainer
		if scroll != null:
			scroll.ensure_control_visible(upgrade)
		await _settle()
		var old_gold: int = PlayerData.gold
		var old_level: int = PlayerData.troop("dao").level
		var cost := PlayerData.level_up_cost("dao")
		await _tap(upgrade)
		await _settle()
		_check(PlayerData.troop("dao").level == old_level + 1 and PlayerData.gold == old_gold - cost, "native_popup_upgrade_still_levels_once_and_spends_exact_cost", requested)
		await _capture("popup-after-native-upgrade", requested)
	await _tap(_close_button(popup))
	await _settle()
	_check(_popup() == null, "native_close_button_returns_to_roster", requested)
	var fresh: Array[Control] = []
	_collect_markers(_page, fresh)
	var active_hint: Control
	var restored_layers := true
	for marker in fresh:
		restored_layers = restored_layers and marker.z_index == 0
		if marker.has_method("get_review_state") and marker.is_visible_in_tree():
			active_hint = marker
	_check(restored_layers and active_hint != null and active_hint.is_processing(), "returned_roster_has_normal_layers_and_running_upgrade_hint", requested)
	if active_hint != null:
		var scales: Array[float] = []
		for sample in 4:
			scales.append(float(active_hint.call("get_review_state").get("visual_scale", 1.0)))
			await _wait(0.15)
		_check(float(scales.max()) - float(scales.min()) > 0.025, "upgrade_hint_pulses_after_popup_upgrade_and_close", requested)
	await _capture("roster-after", requested)


func _collect_markers(node: Node, result: Array[Control]) -> void:
	for child in node.get_children():
		if child is Control and str(child.name) in MARKERS:
			result.append(child)
		_collect_markers(child, result)


func _freeze(markers: Array[Control]) -> void:
	for marker in markers:
		if marker.has_method("get_review_state"):
			marker.set_process(false)


func _popup() -> Control:
	if _page._detail_box != null and is_instance_valid(_page._detail_box):
		var overlay = _page._detail_box.get_meta("overlay", null)
		if is_instance_valid(overlay) and not overlay.is_queued_for_deletion():
			return overlay as Control
	return null


func _primary_panel(node: Node) -> PanelContainer:
	for child in node.get_children():
		if child is PanelContainer and child.has_meta("menu_panel_context"):
			return child
		var result := _primary_panel(child)
		if result != null:
			return result
	return null


func _level_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.text.begins_with("NÂNG CẤP"):
			return child
		var result := _level_button(child)
		if result != null:
			return result
	return null


func _close_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.custom_minimum_size == Vector2(68, 68):
			return child
		var result := _close_button(child)
		if result != null:
			return result
	return null


func _compare_regions(a: Image, b: Image, regions: Array[Rect2]) -> Dictionary:
	var ratio := Vector2(a.get_size()) / get_viewport().get_visible_rect().size
	var pixels := 0
	var changed := 0
	for region in regions:
		var start := Vector2i((region.position * ratio).ceil())
		var finish := Vector2i((region.end * ratio).floor())
		for y in range(maxi(0, start.y), mini(a.get_height(), finish.y)):
			for x in range(maxi(0, start.x), mini(a.get_width(), finish.x)):
				pixels += 1
				if a.get_pixel(x, y) != b.get_pixel(x, y):
					changed += 1
	return {"pixels": pixels, "changed": changed}


func _tap(button: Button) -> void:
	if button == null or not button.is_visible_in_tree():
		return
	var at := button.get_global_rect().get_center()
	_motion(at)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = at
		event.global_position = at
		get_viewport().push_input(event, true)
		await get_tree().process_frame


func _motion(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	get_viewport().push_input(event, true)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _settle() -> void:
	await _wait(0.30)
	await get_tree().process_frame


func _capture(key: String, requested: Vector2i) -> Image:
	_motion(Vector2(710, 1050))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var name := "%s_%dx%d.png" % [key, requested.x, requested.y]
	_check(shot != null and shot.get_size() == requested, "native_capture_dimensions_" + name)
	if shot != null:
		_check(shot.save_png(OUT.path_join(name)) == OK, "native_capture_saved_" + name)
		_captures.append(name)
	return shot


func _check(passed: bool, key: String, requested := Vector2i.ZERO) -> void:
	_checks.append({"key": key, "passed": passed, "window": [requested.x, requested.y]})
	if not passed:
		_failures += 1
		push_error("TROOP_POPUP_LAYERING_FAIL " + key)
	print("TROOP_POPUP_LAYERING_CHECK ", key, " ", passed)


func _finish() -> void:
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"persist": PlayerData.persist, "profile": OS.get_user_data_dir(), "checks": _checks, "captures": _captures, "comparisons": _comparisons, "failures": _failures}, "\t"))
		file.close()
	print("TROOP_POPUP_LAYERING_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
