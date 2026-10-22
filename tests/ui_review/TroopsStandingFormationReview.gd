extends Node

# Focused regression proof for the production standing formation. All pointer
# actions enter through the native viewport; fixtures live only in RAM.
const HOME = preload("res://game/menu/Home.tscn")
const OUT := "res://docs/ui_review/2026-10-22/troops-standing-formation"
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]

var _home
var _page
var _checks: Array = []
var _captures: Array = []
var _layouts: Array = []
var _failures := 0
var _out := OUT


func _ready() -> void:
	if "--layout-only" in OS.get_cmdline_user_args():
		_out = "res://docs/ui_review/2026-10-22/troop-level-labels"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.tutorial_done = true
	get_window().size = SIZES[0]
	_home = HOME.instantiate()
	add_child(_home)
	_home.select_tab(_home.TROOPS_TAB, false)
	_page = _home._pages[_home.TROOPS_TAB]
	await _settle()
	for requested in SIZES:
		get_window().size = requested
		await _fixture()
		# First image is available before the longer interaction checks.
		await _capture("full-five", requested)
		_check_formation(requested, "full-five")
		_check_collection(requested)
		if "--layout-only" in OS.get_cmdline_user_args():
			continue
		await _check_detail(requested)
		await _check_swap_mode(requested)
		await _check_drags(requested)
		await _check_capacity(requested, 3)
		await _check_capacity(requested, 4)
	_finish()


func _fixture() -> void:
	await _back()
	PlayerData.castle_level = PlayerData.castle_max_level()
	PlayerData.gold = 100000
	PlayerData.gems = 260
	for id in PlayerData.TROOP_ORDER:
		PlayerData.troops[id] = {"unlocked": true, "level": 1, "stars": 3, "cards": 0}
	var levels := [7, 12, 18, 20, 30]
	var team := ["kiem", "riu", "dao", "cung", "no"]
	for i in team.size():
		PlayerData.troops[team[i]].level = levels[i]
	PlayerData.team = team
	_page._swap_id = ""
	_page._filter = -1
	PlayerData.changed.emit()
	await _settle()
	_page._scroll.scroll_vertical = 0
	await _settle()


func _slot(index: int) -> Control:
	return _page.find_child("TeamSlot_%d" % index, true, false) as Control


func _portrait(slot: Control) -> TextureRect:
	if slot == null:
		return null
	for candidate: Node in slot.find_children("*", "TextureRect", true, false):
		if str(candidate.name) in ["TeamTroopPortrait", "TeamPortrait", "TroopPortrait"]:
			return candidate as TextureRect
	return null


func _level(slot: Control) -> Label:
	if slot == null:
		return null
	return slot.find_child("TeamTroopLevel", true, false) as Label


func _check_formation(requested: Vector2i, key: String) -> void:
	var view := get_viewport().get_visible_rect()
	var ratio := Vector2(requested) / view.size
	var previous: Control
	var team: Array = PlayerData.battle_team()
	var records: Array = []
	var top_y := -1.0
	for index in 5:
		var slot := _slot(index)
		_check(slot != null, key + "_slot_exists_" + str(index), requested)
		if slot == null:
			continue
		var rect := slot.get_global_rect()
		_check(view.encloses(rect) and _page._team_panel.get_global_rect().encloses(rect), key + "_slot_within_team_and_viewport_" + str(index), requested)
		if top_y < 0:
			top_y = rect.position.y
		_check(absf(rect.position.y - top_y) <= 1.0, key + "_single_row_" + str(index), requested)
		if previous != null:
			_check(not rect.grow(-1).intersects(previous.get_global_rect().grow(-1)), key + "_slots_do_not_overlap_" + str(index), requested)
		previous = slot
		var record := {"index": index, "rect": _rect(rect), "native_size": [rect.size.x * ratio.x, rect.size.y * ratio.y]}
		if index < PlayerData.team_slots():
			_check(slot is Button and rect.size.x * ratio.x >= 44.0 and rect.size.y * ratio.y >= 44.0, key + "_interactive_native_touch_area_at_least_44px_" + str(index), requested)
		if index >= team.size():
			records.append(record)
			continue
		var portrait := _portrait(slot)
		var level := _level(slot)
		_check(portrait != null and portrait.texture != null and portrait.is_visible_in_tree(), key + "_visible_cat_" + str(index), requested)
		_check(level != null and level.is_visible_in_tree() and level.text == "Lv %d" % PlayerData.troop(team[index]).level, key + "_level_prefix_before_number_" + str(index), requested)
		var extra_labels := false
		for label: Node in slot.find_children("*", "Label", true, false):
			if label != level and (label as Label).is_visible_in_tree() and not str(label.text).is_empty():
				extra_labels = true
		_check(not extra_labels and slot.find_child("TeamTroopName", true, false) == null, key + "_no_names_or_other_captions_" + str(index), requested)
		var no_field := slot.find_child("TroopRarityField", true, false) == null and slot.find_child("TroopRarityBackground", true, false) == null
		_check(no_field and _transparent_face(slot as Button), key + "_transparent_slot_without_card_or_rarity_background_" + str(index), requested)
		var no_ground := true
		for child: Node in slot.find_children("*", "", true, false):
			var child_name := str(child.name).to_lower()
			if child_name.contains("ground") or child_name.contains("halo") or child_name.contains("circle") or child_name.contains("shadow"):
				no_ground = false
		_check(no_ground, key + "_no_ground_circle_or_halo_node_" + str(index), requested)
		if portrait != null and level != null:
			var art_rect := portrait.get_global_rect()
			var level_rect := level.get_global_rect()
			_check(rect.grow(1).encloses(art_rect) and rect.grow(1).encloses(level_rect), key + "_art_and_level_fit_transparent_slot_" + str(index), requested)
			_check(absf(art_rect.get_center().x - level_rect.get_center().x) <= 2.0 and level.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, key + "_level_centered_below_cat_" + str(index), requested)
			_check(level_rect.position.y >= art_rect.end.y - 1.0, key + "_level_clears_cat_" + str(index), requested)
			record["portrait"] = _rect(art_rect)
			record["level"] = _rect(level_rect)
			record["level_text"] = level.text
		records.append(record)
	_layouts.append({"key": key, "window": [requested.x, requested.y], "slots": records})
	var panel_text := _all_text(_page._team_panel)
	_check(panel_text.contains("%d/%d" % [team.size(), PlayerData.team_slots()]) and panel_text.contains(_page.UiKit.format_number(PlayerData.team_power())), key + "_formation_count_and_power_preserved", requested)


func _transparent_face(button: Button) -> bool:
	if button == null:
		return false
	var face := button.get_theme_stylebox("normal")
	if face is StyleBoxEmpty:
		return true
	if face is StyleBoxFlat:
		return face.bg_color.a == 0.0 and face.border_color.a == 0.0 and face.shadow_size == 0
	return false


func _check_collection(requested: Vector2i) -> void:
	var grid := _page.find_child("TroopGrid", true, false) as GridContainer
	_check(grid != null and grid.columns == 5 and grid.get_child_count() == PlayerData.TROOP_ORDER.size(), "collection_remains_five_columns_with_all_troops", requested)
	if grid == null:
		return
	var first_y := -1.0
	var first_row := 0
	var within := true
	for child: Control in grid.get_children():
		var rect := child.get_global_rect()
		if first_y < 0:
			first_y = rect.position.y
		if absf(rect.position.y - first_y) <= 1.0:
			first_row += 1
		within = within and rect.position.x >= _page._scroll.get_global_rect().position.x and rect.end.x <= _page._scroll.get_global_rect().end.x + 1.0
	_check(first_row == 5 and within, "collection_rendered_first_row_has_five_without_horizontal_overflow", requested)


func _check_detail(requested: Vector2i) -> void:
	await _tap(_slot(0) as Button)
	await _settle()
	_check(_screen() != null and _page._detail_id == "kiem" and not _page.is_visible_in_tree(), "native_standing_cat_tap_opens_dedicated_upgrade_screen", requested)
	await _capture("team-tap-upgrade", requested)
	await _back()
	_check(_screen() == null and _page.is_visible_in_tree() and _page._swap_id == "", "native_upgrade_back_returns_to_formation", requested)


func _check_swap_mode(requested: Vector2i) -> void:
	var original: Array = PlayerData.battle_team().duplicate()
	var card := _page.find_child("TroopCard_katana", true, false) as Button
	_page._scroll.ensure_control_visible(card)
	await _settle()
	await _tap(card)
	await _settle()
	_check(_screen() != null and _page._detail_id == "katana", "native_roster_tap_opens_swap_candidate", requested)
	if _screen() == null:
		return
	await _tap(_screen().find_child("TroopUpgradeTeam", true, false) as Button)
	await _settle()
	_check(_screen() == null and _page._swap_id == "katana" and PlayerData.battle_team() == original, "full_team_action_enters_swap_without_changing_team", requested)
	var visible_feedback := false
	for index in PlayerData.team_slots():
		visible_feedback = visible_feedback or _slot(index).modulate != Color.WHITE
	_check(visible_feedback, "swap_targets_have_visible_feedback", requested)
	await _capture("swap-target-feedback", requested)
	await _tap(_slot(1) as Button)
	await _settle()
	_check(_page._swap_id == "" and PlayerData.battle_team()[1] == "katana", "native_target_tap_replaces_requested_slot", requested)


func _check_drags(requested: Vector2i) -> void:
	await _fixture()
	var original: Array = PlayerData.battle_team().duplicate()
	var expected := original.duplicate()
	expected[0] = original[1]
	expected[1] = original[0]
	var started := await _drag(_slot(0), _slot(1).get_global_rect().get_center())
	_check(started and PlayerData.battle_team() == expected and _screen() == null, "native_team_drag_swaps_without_opening_detail", requested)
	var card := _page.find_child("TroopCard_katana", true, false) as Button
	_page._scroll.ensure_control_visible(card)
	await _settle()
	started = await _drag(card, _slot(0).get_global_rect().get_center())
	_check(started and PlayerData.battle_team()[0] == "katana" and _screen() == null, "native_roster_drag_replaces_team_slot", requested)
	var outside: Vector2 = _page._scroll.get_global_rect().get_center()
	started = await _drag(_slot(0), outside)
	_check(started and PlayerData.battle_team().size() == 4 and not PlayerData.in_team("katana"), "native_team_drag_outside_benches_cat", requested)
	PlayerData.team = ["dao"]
	PlayerData.changed.emit()
	await _settle()
	started = await _drag(_slot(0), outside)
	_check(started and PlayerData.battle_team() == ["dao"], "native_drag_cannot_bench_final_cat", requested)


func _check_capacity(requested: Vector2i, capacity: int) -> void:
	await _fixture()
	var castle := -1
	for level in range(1, PlayerData.castle_max_level() + 1):
		if PlayerData.Economy.team_slots(level) == capacity:
			castle = level
			break
	_check(castle > 0, "fixture_castle_capacity_exists_" + str(capacity), requested)
	if castle < 0:
		return
	PlayerData.castle_level = castle
	PlayerData.team = ["kiem", "riu"] if capacity == 3 else ["kiem", "riu", "dao"]
	PlayerData.changed.emit()
	await _settle()
	var key := "starter-%d-slots-empty-and-locked" % capacity
	# A final-unit bench rejection is transient feedback, not starter layout.
	await get_tree().create_timer(2.0).timeout
	await _capture(key, requested)
	_check_formation(requested, key)
	_check(_slot(capacity - 1) is Button and _portrait(_slot(capacity - 1)) == null, key + "_empty_open_slot_is_interactive", requested)
	var locked := _slot(capacity) as Button
	_check((locked == null or locked.disabled) and _portrait(_slot(capacity)) == null, key + "_castle_locked_slot_is_noninteractive", requested)


func _screen() -> Control:
	return _home.find_child("TroopUpgradeScreen", true, false) as Control


func _back() -> void:
	if _screen() != null:
		await _tap(_screen().find_child("TroopUpgradeBack", true, false) as Button)
		await _settle()


func _tap(button: Button) -> void:
	if button == null or not is_instance_valid(button) or not button.is_visible_in_tree():
		return
	var at := button.get_global_rect().get_center()
	await _motion(at)
	await _mouse(at, true)
	await _mouse(at, false)


func _drag(source: Control, end: Vector2) -> bool:
	if source == null or not is_instance_valid(source):
		return false
	var begin := source.get_global_rect().get_center()
	await _motion(begin)
	await _mouse(begin, true)
	await _motion(begin + Vector2(28, 0), true)
	await get_tree().process_frame
	await _motion(end, true)
	await get_tree().process_frame
	var started: bool = is_instance_valid(_page._ghost)
	await _mouse(end, false)
	await _settle()
	return started


func _mouse(at: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = at
	event.global_position = at
	get_viewport().push_input(event, true)
	await get_tree().process_frame


func _motion(at: Vector2, held := false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	get_viewport().push_input(event, true)
	await get_tree().process_frame


func _all_text(node: Node) -> String:
	var result := str(node.text) if node is Label or node is Button else ""
	for child in node.get_children():
		result += "\n" + _all_text(child)
	return result


func _rect(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _settle() -> void:
	await get_tree().create_timer(0.25).timeout
	await get_tree().process_frame


func _capture(key: String, requested: Vector2i) -> void:
	await _motion(Vector2(710, 1050))
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var file_name := "%s_%dx%d.png" % [key, requested.x, requested.y]
	_check(shot != null and shot.get_size() == requested, "native_capture_dimensions_" + file_name, requested)
	if shot != null:
		_check(shot.save_png(_out.path_join(file_name)) == OK, "native_capture_saved_" + file_name, requested)
		_captures.append(file_name)
	print("STANDING_FORMATION_CAPTURE ", file_name)


func _check(passed: bool, key: String, requested := Vector2i.ZERO) -> void:
	_checks.append({"key": key, "passed": passed, "window": [requested.x, requested.y]})
	if not passed:
		_failures += 1
		push_error("STANDING_FORMATION_FAIL " + key)
	print("STANDING_FORMATION_CHECK ", key, " ", passed)


func _finish() -> void:
	var file := FileAccess.open(_out.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"persist": PlayerData.persist, "profile": OS.get_user_data_dir(), "checks": _checks, "captures": _captures, "layouts": _layouts, "failures": _failures}, "\t"))
		file.close()
	print("STANDING_FORMATION_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
