extends Node

# Dedicated production screen, native pointer input and disposable RAM fixtures.
const HOME = preload("res://game/menu/Home.tscn")
const OUT := "res://docs/ui_review/2026-10-22/troop-upgrade-screen"
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
const MARKERS := ["TroopLevelReady", "TroopStarReady", "TroopInTeam"]

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
		await _check_upgrades(requested)
		await _check_insufficient(requested)
		await _check_capped_and_max(requested)
		await _check_locked(requested)
		await _check_roster_restore(requested)
		await _check_team_flow(requested)
		await _check_support_long_text(requested)
	_finish()


func _fixture() -> void:
	await _back()
	PlayerData.castle_level = 6
	PlayerData.gold = 100000
	PlayerData.gems = 260
	for id in PlayerData.TROOP_ORDER:
		PlayerData.troops[id] = {"unlocked": true, "level": 1, "stars": 1, "cards": 0}
	PlayerData.troops.kiem.level = 7
	PlayerData.troops.kiem.stars = 3
	PlayerData.team = ["kiem", "riu", "dao", "cung", "no"]
	_page._swap_id = ""
	_page._filter = -1
	PlayerData.changed.emit()
	await _settle()
	_page._scroll.scroll_vertical = 0
	await _settle()


func _screen() -> Control:
	return _home.find_child("TroopUpgradeScreen", true, false) as Control


func _layer() -> CanvasLayer:
	return _home.find_child("TroopUpgradeLayer", true, false) as CanvasLayer


func _node(node_name: String) -> Control:
	return _screen().find_child(node_name, true, false) as Control if _screen() != null else null


func _primary() -> Button:
	return _node("TroopUpgradePrimary") as Button


func _open(id: String, requested: Vector2i, key: String) -> bool:
	var card := _page.find_child("TroopCard_" + id, true, false) as Button
	if card != null:
		_page._scroll.ensure_control_visible(card)
		await _settle()
	await _tap(card)
	await _settle()
	var valid := _screen() != null and _layer() != null
	_check(valid and _page._detail_id == id, "native_card_opens_screen_" + key, requested)
	return valid


func _check_upgrades(requested: Vector2i) -> void:
	PlayerData.troops.dao.cards = 30
	PlayerData.changed.emit()
	await _settle()
	if not await _open("dao", requested, "funded"):
		return
	_check(_layer().layer == 20 and not _home._header.is_visible_in_tree() and not _home._nav_holder.is_visible_in_tree() and not _page.is_visible_in_tree(), "dedicated_layer_hides_lobby_chrome_and_roster", requested)
	_check(_screen().get_global_rect().encloses(get_viewport().get_visible_rect()), "dedicated_screen_covers_logical_viewport", requested)
	var hidden_markers := true
	for marker: Node in _page.find_children("*", "Control", true, false):
		if str(marker.name) in MARKERS:
			hidden_markers = hidden_markers and not (marker as Control).is_visible_in_tree()
	_check(hidden_markers, "underlying_upgrade_arrows_and_team_checks_not_visible", requested)
	_check_layout(requested, "funded")
	await _capture("level-ready", requested)
	var old_gold: int = PlayerData.gold
	var old_level: int = PlayerData.troop("dao").level
	var cost := PlayerData.level_up_cost("dao")
	var stats_before := _all_text(_node("TroopUpgradeStats"))
	_check(_primary() != null and not _primary().disabled, "funded_level_primary_enabled", requested)
	await _tap(_primary())
	await _settle()
	_check(PlayerData.troop("dao").level == old_level + 1 and PlayerData.gold == old_gold - cost, "native_level_upgrade_spends_exactly_once", requested)
	_check(_screen() != null and _all_text(_node("TroopUpgradeStats")) != stats_before, "level_upgrade_refreshes_current_and_next_stats", requested)
	_check(_node("TroopUpgradeFeedback") != null and not _all_text(_node("TroopUpgradeFeedback")).is_empty(), "level_upgrade_has_visible_feedback", requested)
	await _capture("after-level-up", requested)
	await _tap(_node("TroopUpgradeStarTab") as Button)
	await _settle()
	var old_cards: int = PlayerData.troop("dao").cards
	var old_stars: int = PlayerData.troop("dao").stars
	var old_cap := PlayerData.level_cap("dao")
	var star_cost := PlayerData.star_up_cost("dao")
	old_gold = PlayerData.gold
	_check(_primary() != null and not _primary().disabled, "funded_star_mode_primary_enabled", requested)
	await _capture("star-ready", requested)
	await _tap(_primary())
	await _settle()
	_check(PlayerData.troop("dao").stars == old_stars + 1 and PlayerData.troop("dao").cards == old_cards - star_cost and PlayerData.gold == old_gold, "native_star_upgrade_spends_cards_once_without_gold", requested)
	_check(PlayerData.level_cap("dao") > old_cap, "star_upgrade_increases_level_cap", requested)
	await _capture("after-star-up", requested)
	await _back()
	_check(_screen() == null and _layer() == null and _page.is_visible_in_tree() and _home._header.is_visible_in_tree() and _home._nav_holder.is_visible_in_tree(), "native_back_frees_whole_layer_and_restores_lobby", requested)
	await _check_resumed_hint(requested)


func _check_insufficient(requested: Vector2i) -> void:
	await _fixture()
	PlayerData.gold = PlayerData.level_up_cost("dao") - 1
	PlayerData.changed.emit()
	await _settle()
	if not await _open("dao", requested, "insufficient"):
		return
	var old_gold: int = PlayerData.gold
	_check(_primary() != null and _primary().disabled, "insufficient_gold_disables_level_primary", requested)
	await _tap(_primary())
	await _settle()
	_check(PlayerData.gold == old_gold and PlayerData.troop("dao").level == 1, "disabled_level_primary_cannot_spend", requested)
	await _tap(_node("TroopUpgradeStarTab") as Button)
	await _settle()
	_check(_primary() != null and _primary().disabled, "insufficient_cards_disables_star_primary", requested)
	await _tap(_primary())
	await _settle()
	_check(PlayerData.troop("dao").cards == 0 and PlayerData.troop("dao").stars == 1, "disabled_star_primary_cannot_spend", requested)
	await _capture("insufficient-cards", requested)
	await _back()


func _check_capped_and_max(requested: Vector2i) -> void:
	await _fixture()
	PlayerData.troops.dao.level = PlayerData.level_cap("dao")
	PlayerData.troops.dao.cards = PlayerData.star_up_cost("dao")
	PlayerData.changed.emit()
	await _settle()
	if not await _open("dao", requested, "capped"):
		return
	var old_gold: int = PlayerData.gold
	var old_stars: int = PlayerData.troop("dao").stars
	_check(_primary() != null and not _primary().disabled, "capped_with_cards_defaults_to_available_star_upgrade", requested)
	await _capture("capped-star-default", requested)
	await _tap(_primary())
	await _settle()
	_check(PlayerData.troop("dao").stars == old_stars + 1 and PlayerData.gold == old_gold, "capped_default_primary_upgrades_star_without_gold", requested)
	await _tap(_node("TroopUpgradeLevelTab") as Button)
	await _settle()
	_check(_primary() != null and not _primary().disabled, "new_star_unlocks_level_mode_again", requested)
	await _back()
	PlayerData.troops.dao.stars = 3
	PlayerData.troops.dao.level = PlayerData.level_cap("dao")
	PlayerData.changed.emit()
	await _settle()
	if not await _open("dao", requested, "maximum"):
		return
	_check(_primary() != null and _primary().disabled, "max_level_primary_disabled", requested)
	await _tap(_node("TroopUpgradeStarTab") as Button)
	await _settle()
	_check(_primary() != null and _primary().disabled, "max_stars_primary_disabled", requested)
	await _capture("maximum", requested)
	await _back()


func _check_locked(requested: Vector2i) -> void:
	await _fixture()
	PlayerData.troops.katana.unlocked = false
	PlayerData.changed.emit()
	await _settle()
	if not await _open("katana", requested, "locked"):
		return
	_check(_primary() == null or _primary().disabled or not _primary().is_visible_in_tree(), "locked_troop_has_no_spend_action", requested)
	var team := _node("TroopUpgradeTeam") as Button
	_check(team == null or team.disabled or not team.is_visible_in_tree(), "locked_troop_cannot_join_team", requested)
	_check(_all_text(_screen()).to_lower().contains("mở khóa"), "locked_screen_explains_unlock_state", requested)
	var question := _node("TroopUpgradeLockedQuestion") as Label
	var portrait := _node("TroopUpgradePortrait")
	_check(question != null and question.is_visible_in_tree() and question.text == "?", "locked_silhouette_has_visible_question_mark", requested)
	if question != null and portrait != null:
		var ink := question.get_theme_color("font_color")
		var ancestor: Node = question
		while ancestor != null:
			if ancestor is CanvasItem:
				ink *= (ancestor as CanvasItem).modulate
			ancestor = ancestor.get_parent()
		_check(ink.get_luminance() > 0.6 and question.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and question.get_global_rect().get_center().distance_to(portrait.get_global_rect().get_center()) < 2.0, "locked_question_stays_light_and_centered_over_black_art", requested)
	_check_layout(requested, "locked")
	await _capture("locked", requested)
	await _back()


func _check_roster_restore(requested: Vector2i) -> void:
	await _fixture()
	_page._filter = PlayerData.rarity_of("riu")
	_page.refresh()
	await _settle()
	var chosen_filter: int = _page._filter
	if await _open("riu", requested, "filtered"):
		await _back()
		_check(_page._filter == chosen_filter, "back_preserves_roster_rarity_filter", requested)
	_page._filter = -1
	_page.refresh()
	await _settle()
	# The compact five-column collection now shows Sung without scrolling.
	var last_id: String = PlayerData.TROOP_ORDER.back()
	var card := _page.find_child("TroopCard_" + last_id, true, false) as Button
	_page._scroll.ensure_control_visible(card)
	await _settle()
	var chosen_scroll: int = _page._scroll.scroll_vertical
	_check(chosen_scroll > 20, "fixture_has_nonzero_roster_scroll", requested)
	if await _open(last_id, requested, "scrolled"):
		await _back()
		_check(absi(_page._scroll.scroll_vertical - chosen_scroll) <= 2 and _page._filter == -1, "back_preserves_nonzero_roster_scroll_and_filter", requested)


func _check_team_flow(requested: Vector2i) -> void:
	await _fixture()
	var original_team: Array = PlayerData.battle_team().duplicate()
	if not await _open("katana", requested, "full-team"):
		return
	await _tap(_node("TroopUpgradeTeam") as Button)
	await _settle()
	_check(_screen() == null and _layer() == null and _page._swap_id == "katana" and PlayerData.battle_team() == original_team, "full_team_join_closes_screen_into_roster_swap_flow", requested)
	await _capture("full-team-swap", requested)
	await _tap(_page.find_child("TeamSlot_0", true, false) as Button)
	await _settle()
	_check(_page._swap_id == "" and PlayerData.battle_team()[0] == "katana", "native_team_slot_completes_requested_swap", requested)
	await _fixture()
	PlayerData.team = ["dao"]
	PlayerData.changed.emit()
	await _settle()
	if not await _open("dao", requested, "last-unit"):
		return
	var team := _node("TroopUpgradeTeam") as Button
	_check(team != null and team.disabled, "last_unit_cannot_leave_team", requested)
	await _tap(team)
	await _settle()
	_check(PlayerData.battle_team() == ["dao"], "disabled_last_unit_action_preserves_team", requested)
	await _back()


func _check_support_long_text(requested: Vector2i) -> void:
	await _fixture()
	var original: Resource = PlayerData.TROOPS.sach_phep
	var support: Resource = original.duplicate(true)
	support.role = 3
	support.ability_text = "Hiệu lệnh: đồng đội trong bán kính 160 gây thêm 30% sát thương. Mỗi 5 giây, cả đội được nhận một lớp khiên bảo vệ và tăng tốc sinh lính trong 3 giây. Hiệu ứng hỗ trợ kéo dài khi mèo sách còn sống trên chiến trường."
	PlayerData.TROOPS.sach_phep = support
	PlayerData.changed.emit()
	await _settle()
	if await _open("sach_phep", requested, "support-long-text"):
		_check_layout(requested, "support-long-text")
		var stats := _all_text(_node("TroopUpgradeStats")).to_lower()
		_check(not stats.contains("sát thương") and not stats.contains("tầm đánh"), "support_stats_omit_direct_attack_rows", requested)
		_check(_all_text(_screen()).contains("Hiệu lệnh"), "long_support_ability_text_present", requested)
		await _capture("support-long-text", requested)
		await _back()
	PlayerData.TROOPS.sach_phep = original
	PlayerData.changed.emit()
	await _settle()


func _check_layout(requested: Vector2i, key: String) -> void:
	var view := get_viewport().get_visible_rect()
	for node_name in ["TroopUpgradeBack", "TroopUpgradeLevelTab", "TroopUpgradeStarTab", "TroopUpgradePrimary", "TroopUpgradeTeam", "TroopUpgradePortrait", "TroopUpgradeStats", "TroopUpgradeResource", "TroopUpgradeScroll"]:
		if key == "locked" and node_name in ["TroopUpgradeStats", "TroopUpgradeResource"]:
			continue
		var control := _node(node_name)
		_check(control != null, "layout_node_exists_" + key + "_" + node_name, requested)
		if control != null and control.is_visible_in_tree() and control is Button:
			_check(view.encloses(control.get_global_rect()), "native_action_within_viewport_" + key + "_" + node_name, requested)
	var level_tab := _node("TroopUpgradeLevelTab")
	var star_tab := _node("TroopUpgradeStarTab")
	if level_tab != null and star_tab != null:
		_check(not level_tab.get_global_rect().grow(-1).intersects(star_tab.get_global_rect().grow(-1)), "upgrade_mode_tabs_do_not_overlap_" + key, requested)
	var scroll := _node("TroopUpgradeScroll")
	var action := _primary()
	if scroll != null and action != null and action.is_visible_in_tree():
		_check(not scroll.get_global_rect().grow(-1).intersects(action.get_global_rect().grow(-1)), "scroll_information_clears_fixed_primary_action_" + key, requested)
		var ratio := Vector2(requested) / view.size
		var pixels := action.get_global_rect().size * ratio
		_check(pixels.x >= 44.0 and pixels.y >= 44.0, "primary_native_target_at_least_44px_" + key, requested)


func _check_resumed_hint(requested: Vector2i) -> void:
	var hint: Control
	for candidate: Node in _page.find_children("*", "Control", true, false):
		if str(candidate.name) in ["TroopLevelReady", "TroopStarReady"] and (candidate as Control).is_visible_in_tree():
			hint = candidate
			break
	_check(hint != null and hint.is_processing(), "roster_upgrade_hint_resumes_naturally_after_back", requested)
	if hint != null:
		var scales: Array[float] = []
		var positions: Array[float] = []
		for sample in 4:
			var state: Dictionary = hint.call("get_review_state")
			scales.append(float(state.visual_scale))
			positions.append(state.ink_rect.position.y)
			await _wait(0.15)
		_check(is_equal_approx(float(scales.min()), 1.0) and is_equal_approx(float(scales.max()), 1.0), "returned_roster_hint_keeps_fixed_scale", requested)
		_check(float(positions.max()) - float(positions.min()) > 2.0, "returned_roster_hint_still_moves_vertically", requested)


func _all_text(node: Node) -> String:
	if node == null:
		return ""
	var result := ""
	if node is Label or node is Button or node is RichTextLabel:
		result = str(node.text)
	for child in node.get_children():
		result += "\n" + _all_text(child)
	return result.strip_edges()


func _back() -> void:
	if _screen() == null:
		return
	await _tap(_node("TroopUpgradeBack") as Button)
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


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _settle() -> void:
	await _wait(0.30)
	await get_tree().process_frame


func _capture(key: String, requested: Vector2i) -> void:
	_motion(Vector2(710, 1050))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var name := "%s_%dx%d.png" % [key, requested.x, requested.y]
	_check(shot != null and shot.get_size() == requested, "native_capture_dimensions_" + name)
	if shot != null:
		_check(shot.save_png(OUT.path_join(name)) == OK, "native_capture_saved_" + name)
		_captures.append(name)


func _check(passed: bool, key: String, requested := Vector2i.ZERO) -> void:
	_checks.append({"key": key, "passed": passed, "window": [requested.x, requested.y]})
	if not passed:
		_failures += 1
		push_error("TROOP_UPGRADE_SCREEN_FAIL " + key)
	print("TROOP_UPGRADE_SCREEN_CHECK ", key, " ", passed)


func _finish() -> void:
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"persist": PlayerData.persist, "profile": OS.get_user_data_dir(), "checks": _checks, "captures": _captures, "failures": _failures}, "\t"))
		file.close()
	print("TROOP_UPGRADE_SCREEN_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
