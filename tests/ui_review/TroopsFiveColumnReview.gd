extends Node

# Production roster, native viewport input, and a disposable in-memory player.
# Fixtures exercise the existing 1/2/3-star progression without changing balance
# data, save files, or the production maximum.
const HOME = preload("res://game/menu/Home.tscn")
const OUT := "res://docs/ui_review/2026-10-22/troops-five-column"
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
const HINT_NAMES := ["TroopLevelReady", "TroopStarReady"]

var _home
var _page
var _checks: Array = []
var _captures: Array = []
var _failures := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
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
		_check_collection(requested, "all")
		_check_card_contents(requested)
		await _check_marker_motion(requested)
		await _capture("all-top", requested)
		_page._scroll.scroll_vertical = 100000
		await _settle()
		_check(_page._scroll.scroll_vertical > 0, "collection_scrolls_to_remaining_troops", requested)
		await _capture("all-bottom", requested)
		await _check_modal(requested)
		await _check_filters(requested)
		await _check_unfunded(requested)
		await _check_locked(requested)
	_finish()


func _fixture() -> void:
	await _back()
	PlayerData.castle_level = PlayerData.castle_max_level()
	PlayerData.gold = 1000000
	PlayerData.gems = 260
	for i in PlayerData.TROOP_ORDER.size():
		var id: String = PlayerData.TROOP_ORDER[i]
		var stars := 1 + i % PlayerData.Economy.MAX_STARS
		PlayerData.troops[id] = {"unlocked": true, "level": stars * PlayerData.Economy.LEVELS_PER_STAR - 1, "stars": stars, "cards": 0}
	PlayerData.troops.riu.level = 20
	PlayerData.troops.sach_phep.level = 20
	PlayerData.team = ["kiem", "riu", "dao", "cung", "no"]
	_page._swap_id = ""
	_page._filter = -1
	PlayerData.changed.emit()
	await _settle()
	_page._scroll.scroll_vertical = 0
	await _settle()


func _grid() -> GridContainer:
	return _page.find_child("TroopGrid", true, false) as GridContainer


func _card(id: String) -> Button:
	return _page.find_child("TroopCard_" + id, true, false) as Button


func _hint(card: Control) -> Control:
	for candidate: Node in card.find_children("*", "Control", true, false):
		if str(candidate.name) in HINT_NAMES:
			return candidate as Control
	return null


func _check_collection(requested: Vector2i, key: String) -> void:
	var grid := _grid()
	_check(grid != null, "collection_exists_" + key, requested)
	if grid == null:
		return
	var rows: Dictionary = {}
	var scroll_rect: Rect2 = _page._scroll.get_global_rect()
	var cards: Array[Control] = []
	for child in grid.get_children():
		var card := child as Control
		cards.append(card)
		var rect := card.get_global_rect()
		var row := roundi(rect.position.y)
		rows[row] = int(rows.get(row, 0)) + 1
		_check(rect.position.x >= scroll_rect.position.x and rect.end.x <= scroll_rect.end.x + 1.0, "card_stays_within_horizontal_scroll_bounds_" + key + "_" + str(card.name), requested)
		for previous in cards.slice(0, cards.size() - 1):
			_check(not rect.grow(-1).intersects(previous.get_global_rect().grow(-1)), "cards_do_not_overlap_" + key + "_" + str(card.name) + "_" + str(previous.name), requested)
	var row_counts: Array = rows.values()
	_check(cards.size() == PlayerData.TROOP_ORDER.size() if key == "all" else true, "all_sixteen_collection_cards_present_" + key, requested)
	_check(row_counts.size() > 0 and int(row_counts[0]) == mini(5, cards.size()), "first_rendered_row_has_five_cards_" + key, requested)
	for i in maxi(row_counts.size() - 1, 0):
		_check(row_counts[i] == 5, "complete_rendered_row_has_five_cards_" + key + "_" + str(i), requested)
	_check(grid.get_global_rect().size.x <= scroll_rect.size.x, "five_column_grid_has_no_horizontal_overflow_" + key, requested)


func _check_card_contents(requested: Vector2i) -> void:
	for id in PlayerData.TROOP_ORDER:
		var card := _card(id)
		if card == null:
			continue
		var rect := card.get_global_rect()
		var name_label := card.find_child("TroopName", true, false) as Label
		var level := card.find_child("TroopLevel", true, false) as Label
		var portrait := card.find_child("TroopPortrait", true, false) as Control
		var stars := card.find_child("TroopStars", true, false) as HBoxContainer
		for label: Label in [name_label, level]:
			_check(label != null, "card_label_exists_" + id + "_" + ("name" if label == name_label else "level"), requested)
			if label == null:
				continue
			var label_rect := label.get_global_rect()
			var label_key: String = id + "_" + str(label.name)
			_check(rect.grow(1).encloses(label_rect), "card_label_within_face_" + label_key, requested)
			_check(label.get_theme_color("font_color").get_luminance() > 0.9 and label.get_theme_color("font_outline_color").get_luminance() < 0.1 and label.get_theme_constant("outline_size") > 0, "card_label_white_with_black_outline_" + label_key, requested)
			_check(label.get_theme_font("font").resource_path == _page.Ui.THEME.get_font("font", "LabelDark").resource_path, "card_label_uses_game_font_" + label_key, requested)
			_check(float(label.get_line_count() * label.get_line_height()) <= label.size.y + 1.0, "card_label_lines_fit_height_" + label_key, requested)
			if label.get_line_count() <= 1:
				var text_width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
				_check(text_width <= label.size.x + 1.0, "card_single_line_text_fits_" + label_key, requested)
		if level != null:
			_check(level.get_global_rect().get_center().x < rect.get_center().x and level.get_global_rect().get_center().y < rect.get_center().y, "level_is_top_left_" + id, requested)
		if portrait != null:
			_check(rect.grow(1).encloses(portrait.get_global_rect()), "compact_portrait_fits_card_" + id, requested)
		if stars != null:
			_check(stars.get_child_count() == PlayerData.troop(id).stars, "only_earned_stars_shown_" + id, requested)
			_check(rect.grow(1).encloses(stars.get_global_rect()), "earned_star_row_fits_card_" + id, requested)
			_check(absf(stars.get_global_rect().get_center().x - rect.get_center().x) <= 2.0, "earned_star_row_is_centered_" + id, requested)
			for star: Control in stars.get_children():
				_check(rect.grow(1).encloses(star.get_global_rect()), "earned_star_is_not_clipped_" + id + "_" + str(star.name), requested)
		var hint := _hint(card)
		var member := card.find_child("TroopInTeam", true, false) as Control
		if hint != null:
			var ink: Rect2 = hint.call("get_review_state").ink_rect
			_check(ink.get_center().x > rect.get_center().x and ink.position.y < rect.position.y, "upgrade_hint_top_right_over_border_" + id, requested)
			_check(hint.mouse_filter == Control.MOUSE_FILTER_IGNORE, "upgrade_hint_does_not_steal_card_tap_" + id, requested)
		if PlayerData.in_team(id):
			_check(member != null, "equipped_troop_has_check_" + id, requested)
			if member != null:
				var member_rect := member.get_global_rect()
				_check(member_rect.get_center().x > rect.get_center().x and member_rect.get_center().y > rect.get_center().y, "equipped_check_bottom_right_" + id, requested)
				if hint != null:
					_check(not member_rect.intersects(hint.get_global_rect()), "equipped_and_upgrade_markers_do_not_overlap_" + id, requested)
		else:
			_check(member == null, "benched_troop_has_no_equipped_check_" + id, requested)


func _check_marker_motion(requested: Vector2i) -> void:
	var hint := _hint(_card("kiem"))
	_check(hint != null and hint.is_processing(), "available_upgrade_arrow_animates", requested)
	if hint == null:
		return
	var scales: Array[float] = []
	var positions: Array[float] = []
	for sample in 5:
		var state: Dictionary = hint.call("get_review_state")
		scales.append(state.visual_scale)
		positions.append(state.ink_rect.position.y)
		_check(_page._scroll.get_global_rect().encloses(state.ink_rect), "top_right_arrow_ink_is_not_clipped_sample_" + str(sample), requested)
		await get_tree().create_timer(0.16).timeout
	_check(is_equal_approx(float(scales.min()), 1.0) and is_equal_approx(float(scales.max()), 1.0), "upgrade_arrow_keeps_fixed_scale", requested)
	_check(float(positions.max()) - float(positions.min()) > 2.0, "upgrade_arrow_moves_vertically_after_compact_layout", requested)


func _check_modal(requested: Vector2i) -> void:
	var card := _card("sung")
	_page._scroll.ensure_control_visible(card)
	await _settle()
	var saved_scroll: int = _page._scroll.scroll_vertical
	await _tap(card)
	await _settle()
	var screen := _screen()
	_check(screen != null and _page._detail_id == "sung", "native_compact_card_opens_dedicated_upgrade_screen", requested)
	if screen == null:
		return
	var layer := _home.find_child("TroopUpgradeLayer", true, false) as CanvasLayer
	_check(layer != null and layer.layer == 20, "dedicated_upgrade_screen_keeps_modal_layer", requested)
	var markers_hidden := true
	for candidate: Node in _page.find_children("*", "Control", true, false):
		if str(candidate.name) in HINT_NAMES or str(candidate.name) == "TroopInTeam":
			markers_hidden = markers_hidden and not (candidate as Control).is_visible_in_tree()
	_check(markers_hidden, "roster_arrows_and_checks_stay_behind_dedicated_screen", requested)
	await _capture("card-opens-detail", requested)
	await _back()
	_check(_screen() == null and _page.is_visible_in_tree() and abs(_page._scroll.scroll_vertical - saved_scroll) <= 2, "native_back_restores_compact_roster_and_scroll", requested)
	var resumed := _hint(_card("kiem"))
	_check(resumed != null and resumed.is_processing(), "upgrade_arrow_resumes_after_modal_close", requested)


func _check_filters(requested: Vector2i) -> void:
	for rarity in 4:
		await _tap(_page.find_child("TroopFilter_%d" % rarity, true, false) as Button)
		await _settle()
		var expected := 0
		for id in PlayerData.TROOP_ORDER:
			if PlayerData.rarity_of(id) == rarity:
				expected += 1
		_check(_grid().get_child_count() == expected, "native_rarity_filter_has_correct_count_" + str(rarity), requested)
		_check_collection(requested, "rarity" + str(rarity))
		await _capture("rarity-" + str(rarity), requested)
		if rarity == 1 and expected > 0:
			await _tap(_grid().get_child(0) as Button)
			await _settle()
			await _back()
			_check(_page._filter == rarity and _grid().get_child_count() == expected, "native_detail_back_keeps_selected_rarity_filter", requested)


func _check_unfunded(requested: Vector2i) -> void:
	await _fixture()
	PlayerData.gold = 0
	PlayerData.changed.emit()
	await _settle()
	var no_hints := true
	for id in PlayerData.TROOP_ORDER:
		no_hints = no_hints and _hint(_card(id)) == null
	_check(no_hints, "no_resources_means_no_upgrade_arrows", requested)
	_check(_card("kiem").find_child("TroopInTeam", true, false) != null, "equipped_check_remains_without_upgrade_arrow", requested)
	await _capture("no-resources", requested)


func _check_locked(requested: Vector2i) -> void:
	await _fixture()
	for id in ["kiem", "cung", "sach_phep", "bua"]:
		PlayerData.troops[id].unlocked = false
	PlayerData.team = ["riu", "dao", "no"]
	PlayerData.changed.emit()
	await _settle()
	var card := _card("kiem")
	var portrait := card.find_child("TroopPortrait", true, false) as Control
	var question := card.find_child("TroopLockedQuestion", true, false) as Label
	_check(portrait != null and portrait.modulate == Color.BLACK, "locked_troop_is_black_silhouette", requested)
	_check(question != null and question.text == "?" and question.get_theme_color("font_color").get_luminance() > 0.6, "locked_troop_has_light_question_mark", requested)
	if portrait != null and question != null:
		_check(portrait.get_global_rect().get_center().distance_to(question.get_global_rect().get_center()) <= 2.0, "locked_question_is_centered_on_silhouette", requested)
	_check(_hint(card) == null and card.find_child("TroopInTeam", true, false) == null and card.find_child("TroopStars", true, false) == null, "locked_card_hides_upgrade_team_and_earned_stars", requested)
	await _capture("locked-mixed", requested)


func _screen() -> Control:
	return _home.find_child("TroopUpgradeScreen", true, false) as Control


func _back() -> void:
	if _screen() == null:
		return
	await _tap(_screen().find_child("TroopUpgradeBack", true, false) as Button)
	await _settle()


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


func _settle() -> void:
	await get_tree().create_timer(0.30).timeout
	await get_tree().process_frame


func _capture(key: String, requested: Vector2i) -> void:
	_motion(Vector2(710, 1050))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var filename := "%s_%dx%d.png" % [key, requested.x, requested.y]
	_check(shot != null and shot.get_size() == requested, "native_capture_size_" + filename)
	if shot != null:
		_check(shot.save_png(OUT.path_join(filename)) == OK, "native_capture_saved_" + filename)
		_captures.append(filename)


func _check(passed: bool, key: String, requested := Vector2i.ZERO) -> void:
	_checks.append({"key": key, "passed": passed, "window": [requested.x, requested.y]})
	if not passed:
		_failures += 1
		push_error("TROOPS_FIVE_COLUMN_FAIL " + key)
	print("TROOPS_FIVE_COLUMN_CHECK ", key, " ", passed)


func _finish() -> void:
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"persist": PlayerData.persist, "profile": OS.get_user_data_dir(), "max_stars": PlayerData.Economy.MAX_STARS, "checks": _checks, "captures": _captures, "failures": _failures}, "\t"))
		file.close()
	print("TROOPS_FIVE_COLUMN_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
