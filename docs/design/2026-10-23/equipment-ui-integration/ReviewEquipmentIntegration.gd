extends Node

## Actual production UI; this scene changes only in-memory review fixtures.
## Run using run-review.ps1 to isolate the entire Godot user profile.
const HOME = preload("res://game/menu/Home.tscn")
const HOME_SCRIPT = preload("res://game/menu/Home.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const CARTON_NAV = preload("res://game/ui/CartonNav.gd")
const OUT := "res://docs/design/2026-10-23/equipment-ui-integration"
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
const WORN := ["kiem_go", "mu_hiep_si", "giap_rong", "giay_gio"]

var _home
var _page
var _size := Vector2i.ZERO
var _uids: Dictionary = {}
var _checks: Array = []
var _captures: Array = []
var _geometry: Array = []
var _failures := 0
var _save_before := ""
var _original_state: Dictionary = {}
var _original_persist := true
var _original_tab := 2
var _nav_id := 0


func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_original_state = PlayerData.to_dict().duplicate(true)
	_original_persist = PlayerData.persist
	_original_tab = HOME_SCRIPT.last_tab
	PlayerData.persist = false
	_save_before = _save_hash()
	for requested in SIZES:
		_size = requested
		_fixture("fresh")
		await _mount()
		_audit("fresh", 7, 3, 1)
		_check(HeroCat.spare(PlayerData.hero_cat).size() == 4, "fresh_profile_four_spare_items")
		await _capture("fresh")
		await _unmount()
		_fixture("full")
		await _mount()
		_audit("full", 13, 4, 0)
		_audit_grid(9)
		await _capture("full-bag")
		await _filters_sort()
		await _upgrade_equipped()
		await _equip_spare()
		await _rejected_api_actions()
		_check_native_nav("after_actions")
		await _unmount()
		_fixture("empty")
		await _mount()
		_audit("empty", 0, 0, 4)
		_audit_grid(0)
		await _capture("empty")
		await _unmount()
	_check(not PlayerData.persist and _save_before == _save_hash(), "no_player_save_write_during_review")
	PlayerData.from_dict(_original_state)
	HOME_SCRIPT.last_tab = _original_tab
	_check(PlayerData.to_dict() == _original_state, "original_in_memory_profile_restored")
	_check(_save_before == _save_hash(), "profile_restore_never_writes_save")
	PlayerData.persist = _original_persist
	_finish()


func _fixture(kind: String) -> void:
	PlayerData._reset()
	PlayerData.persist = false
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false
	_uids.clear()
	if kind == "fresh":
		return
	var state := {"equipped": {}, "bag": {}, "retired_items": {}, "next": 1}
	if kind == "full":
		PlayerData.gold = 50000
		var index := 0
		for id in HeroCat.ITEMS:
			var uid := HeroCat.add_item(state, id)
			_uids[id] = uid
			state.bag[uid].level = 1 + (index % 10)
			if WORN.has(id):
				state.equipped[HeroCat.ITEMS[id].slot] = uid
			index += 1
	PlayerData.hero_cat = state


func _mount() -> void:
	get_window().size = _size
	_home = HOME.instantiate()
	add_child(_home)
	_home.select_tab(_home.BATTLE_TAB, false)
	await _settle()
	_check(await _tap(_nav_button(_home.HERO_TAB)), "native_hero_tab_tap")
	await _settle()
	_page = _home._pages[_home.HERO_TAB]
	_check(_home._current == _home.HERO_TAB and _page.is_visible_in_tree(), "production_hero_page_visible")
	_nav_id = _home._nav_bar.get_instance_id()
	_check_native_nav("initial")


func _unmount() -> void:
	_home.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_home = null
	_page = null


func _audit(context: String, expected_art: int, worn: int, empty: int) -> void:
	_check(HeroCat.SLOTS == ["weapon", "helmet", "armor", "boots"], context + "_four_gameplay_slots")
	_check(PlayerData.hero_cat.equipped.size() == worn, context + "_expected_equipped_count")
	var left: Node = _page.find_child("HeroEquipmentLeft", true, false)
	var right: Node = _page.find_child("HeroEquipmentRight", true, false)
	_check(left != null and right != null and left.get_child_count() == 2 and right.get_child_count() == 2, context + "_two_slot_controls_per_side")
	_check(_page.find_children("EmptyEquipmentSymbol", "TextureRect", true, false).size() == empty, context + "_dedicated_empty_slot_symbols")
	var arts: Array[Node] = _page.find_children("EquipmentArt", "TextureRect", true, false)
	_check(arts.size() == expected_art, context + "_real_inventory_art_count")
	var fit := true
	for art: TextureRect in arts:
		var card: Control = art.get_parent()
		var card_rect := card.get_global_rect()
		var art_rect := art.get_global_rect()
		fit = fit and art.texture != null and card_rect.grow(0.1).encloses(art_rect)
		fit = fit and art_rect.get_center().distance_to(card_rect.get_center()) < 0.2
		fit = fit and art.rotation == 0.0 and art.scale == Vector2.ONE
		fit = fit and card.find_child("EquipmentLevel", false, false) != null and card.find_child("SlotBadge", false, false) != null
		_geometry.append({"context": context, "window": [_size.x, _size.y], "art": art.texture.resource_path if art.texture != null else "", "card": _rect(card_rect), "art_rect": _rect(art_rect)})
	_check(fit, context + "_item_art_fitted_centered_and_badged")
	_audit_badges(_page, context, expected_art)
	var scroll := _bag_scroll()
	_check(scroll != null and scroll.size.y >= 120.0, context + "_usable_inventory_scroll_height")
	if scroll != null and scroll.scroll_vertical == 0:
		_audit_first_bag_badge(context)
	_check_native_nav(context)


func _audit_badges(root: Node, context: String, expected_count: int) -> void:
	var badges: Array[Node] = root.find_children("EquipmentCategoryBadge", "Control", true, false)
	_check(badges.size() == expected_count, context + "_each_equipment_card_has_corner_badge")
	var protruding := true
	var centered := true
	var alpha_region := true
	var rarity_matches := true
	var boots_approved := true
	for frame: Control in badges:
		var card: Control = frame.get_parent()
		var glyph := card.get_node_or_null("SlotBadge") as TextureRect
		protruding = protruding and frame.position.distance_to(Vector2(-2, -2)) < 0.1
		centered = centered and glyph != null and glyph.get_global_rect().get_center().distance_to(frame.get_global_rect().get_center()) < 0.1
		var uid: String = str(card.get_meta("equipment_uid", ""))
		var definition := HeroCat.def(PlayerData.hero_cat, uid)
		rarity_matches = rarity_matches and not definition.is_empty() and frame.get("tone") == HeroCat.tone(int(definition.get("rarity", -1)))
		if glyph == null or glyph.texture == null:
			alpha_region = false
			continue
		var atlas := glyph.texture as AtlasTexture
		alpha_region = alpha_region and atlas != null and atlas.atlas != null and atlas.region.has_area()
		var glyph_image := glyph.texture.get_image()
		alpha_region = alpha_region and glyph_image != null and glyph_image.get_used_rect().has_area()
		if definition.get("slot", "") == "boots":
			boots_approved = boots_approved and atlas != null and atlas.atlas != null and atlas.atlas.resource_path == "res://game/ui/art/equipment_badge_boots.svg"
	_check(protruding, context + "_corner_badges_protrude_two_pixels")
	_check(centered, context + "_category_glyphs_centered_in_badges")
	_check(alpha_region, context + "_category_glyphs_have_nonempty_cropped_alpha_regions")
	_check(rarity_matches, context + "_category_badge_colors_follow_item_rarity")
	_check(boots_approved, context + "_boots_badges_use_approved_staggered_pair")


func _audit_first_bag_badge(context: String) -> void:
	var grid := _bag_grid()
	if grid == null or grid.get_child_count() == 0:
		return
	var scroll := _bag_scroll()
	var first: Control = grid.get_child(0)
	var badge := first.find_child("EquipmentCategoryBadge", true, false) as Control
	_check(badge != null and scroll != null and scroll.get_global_rect().grow(0.1).encloses(badge.get_global_rect()), context + "_first_inventory_badge_not_clipped_by_scroll")
	if scroll != null:
		var inset := first.get_global_rect().position - scroll.get_global_rect().position
		_check(inset.distance_to(Vector2(8, 8)) < 0.1, context + "_inventory_keeps_eight_pixel_badge_padding")


func _audit_grid(expected_count: int) -> void:
	var grid := _bag_grid()
	if expected_count == 0:
		_check(grid == null or grid.get_child_count() == 0, "empty_inventory_has_no_fake_cards")
		return
	_check(grid != null and grid.columns == 5, "inventory_grid_five_columns")
	if grid == null:
		return
	_check(grid.get_child_count() == expected_count, "inventory_real_filtered_item_count_" + str(expected_count))
	if expected_count < 5:
		return
	var children := grid.get_children()
	var top: float = children[0].get_global_rect().position.y
	var fit := true
	for index in 5:
		var rect: Rect2 = children[index].get_global_rect()
		fit = fit and absf(rect.position.y - top) < 0.2 and rect.position.x >= 0 and rect.end.x <= _page.size.x
	if expected_count > 5:
		fit = fit and children[5].get_global_rect().position.y > top
	_check(fit, "five_inventory_cards_fit_one_row")


func _filters_sort() -> void:
	var expected_weapons: Array = []
	var expected_gear: Array = []
	for uid in HeroCat.spare(PlayerData.hero_cat):
		if HeroCat.def(PlayerData.hero_cat, uid).slot == "weapon":
			expected_weapons.append(uid)
		else:
			expected_gear.append(uid)
	_check(await _tap(_filter_button("weapon", "Vũ khí")), "native_weapon_filter_tap")
	await _settle()
	_check(_same_members(_grid_uids(), expected_weapons), "weapon_filter_shows_only_real_spare_weapons")
	await _capture("filter-weapons")
	_check(await _tap(_filter_button("gear", "Phòng thủ")), "native_defense_filter_tap")
	await _settle()
	_check(_same_members(_grid_uids(), expected_gear), "defense_filter_shows_only_real_spare_armor")
	await _capture("filter-defense")
	_check(await _tap(_filter_button("all", "Tất cả")), "native_all_filter_tap")
	await _settle()
	_audit_grid(9)
	_check(_rarity_sorted(_grid_uids(), true), "default_sort_descending_rarity")
	_check(await _tap(_sort_button()), "native_sort_ascending_tap")
	await _settle()
	_check(_rarity_sorted(_grid_uids(), false), "sort_changes_to_ascending_rarity")
	await _capture("sort-ascending")
	_check(await _tap(_sort_button()), "native_sort_descending_tap")
	await _settle()
	_check(_rarity_sorted(_grid_uids(), true), "sort_returns_to_descending_rarity")


func _upgrade_equipped() -> void:
	var uid: String = _uids.kiem_go
	var before_level: int = HeroCat.item(PlayerData.hero_cat, uid).level
	var gold_before: int = PlayerData.gold
	var cost := HeroCat.upgrade_cost(PlayerData.hero_cat, uid)
	_check(await _tap(_card_button(uid)), "native_worn_card_opens_detail")
	await _settle()
	_check(_detail_visible() and _page._detail_uid == uid, "upgrade_popup_targets_selected_uid")
	if not _detail_visible():
		return
	_audit_badges(_page._detail, "equipped_detail", 1)
	await _capture("equipped-detail")
	_check(await _tap(_button_text(_page._detail, "Nâng cấp")), "native_upgrade_button_tap")
	await _settle()
	_check(HeroCat.item(PlayerData.hero_cat, uid).level == before_level + 1, "upgrade_increments_selected_item_once")
	_check(PlayerData.gold == gold_before - cost, "upgrade_spends_exact_cost")
	_check(_detail_visible(), "upgrade_keeps_detail_open_with_fresh_values")
	_check(await _tap(_popup_close()), "native_close_upgrade_popup")
	await _settle()
	_check(not _detail_visible(), "upgrade_popup_closed")


func _equip_spare() -> void:
	var uid: String = _uids.cung_san
	var previous := HeroCat.equipped_uid(PlayerData.hero_cat, "weapon")
	var target := _card_button(uid)
	var scroll := _bag_scroll()
	if target != null and scroll != null:
		scroll.ensure_control_visible(target)
	await _settle()
	_check(await _tap(target), "native_spare_bow_opens_comparison")
	await _settle()
	_check(_detail_visible() and _page._detail_uid == uid, "comparison_targets_selected_bow")
	if not _detail_visible():
		return
	_check(_page._detail.find_children("EquipmentArt", "TextureRect", true, false).size() == 2, "comparison_shows_worn_and_selected_art")
	_audit_badges(_page._detail, "bow_comparison", 2)
	await _capture("bow-comparison")
	_check(await _tap(_button_text(_page._detail, "Trang bị")), "native_equip_button_tap")
	await _settle()
	_check(HeroCat.equipped_uid(PlayerData.hero_cat, "weapon") == uid, "equip_changes_real_weapon_uid")
	_check(HeroCat.spare(PlayerData.hero_cat).has(previous) and not HeroCat.spare(PlayerData.hero_cat).has(uid), "equip_returns_previous_weapon_to_bag")
	_check(not _detail_visible(), "equip_closes_popup")
	_audit("after_equip", 13, 4, 0)
	await _capture("after-equip")


func _rejected_api_actions() -> void:
	var snapshot: Dictionary = PlayerData.to_dict().duplicate(true)
	PlayerData.gold = 0
	var before: Dictionary = PlayerData.hero_cat.duplicate(true)
	_check(not PlayerData.hero_cat_upgrade(_uids.kiem_go), "api_rejects_upgrade_without_gold")
	_check(PlayerData.gold == 0 and PlayerData.hero_cat == before, "rejected_upgrade_preserves_inventory_and_gold")
	PlayerData.hero_cat_equip("missing-review-uid")
	_check(PlayerData.hero_cat == before, "api_rejects_invalid_equipment_uid")
	_check(not PlayerData.hero_cat_upgrade("missing-review-uid"), "api_rejects_invalid_upgrade_uid")
	PlayerData.from_dict(snapshot)
	_check(PlayerData.to_dict() == snapshot and not PlayerData.persist, "api_test_restores_local_state_without_save")


func _check_native_nav(context: String) -> void:
	var bar: Node = _home._nav_bar
	var native: bool = bar != null and bar.get_script() == CARTON_NAV
	_check(native and bar.get_instance_id() == _nav_id, context + "_original_carton_nav_instance_retained")
	if not native:
		return
	var state: Dictionary = bar.get_review_state()
	_check(state.cells.size() == 5 and state.selected == _home.HERO_TAB, context + "_five_cartons_hero_selected")


func _bag_grid() -> GridContainer:
	return _page.find_child("HeroInventoryGrid", true, false) as GridContainer


func _bag_scroll() -> ScrollContainer:
	return _page.find_child("HeroInventoryScroll", true, false) as ScrollContainer


func _grid_uids() -> Array:
	var out: Array = []
	var grid := _bag_grid()
	if grid == null:
		return out
	for button: Button in grid.find_children("*", "Button", true, false):
		var uid := _bound_uid(button)
		if uid != "":
			out.append(uid)
	return out


func _bound_uid(button: Button) -> String:
	for connection in button.get_signal_connection_list("pressed"):
		var callback: Callable = connection.callable
		if callback.get_object() == _page and callback.get_method() == "_open_detail":
			var bound: Array = callback.get_bound_arguments()
			if not bound.is_empty():
				return str(bound[0])
	return ""


func _card_button(uid: String) -> Button:
	for button: Button in _page.find_children("*", "Button", true, false):
		if _bound_uid(button) == uid:
			return button
	return null


func _filter_button(kind: String, caption: String) -> Button:
	var named: Button = _page.find_child("EquipmentFilter_" + kind, true, false) as Button
	return named if named != null else _button_text(_page, caption)


func _sort_button() -> Button:
	var named: Button = _page.find_child("EquipmentSort", true, false) as Button
	return named if named != null else _button_text(_page, "Độ hiếm")


func _button_text(root: Node, begins: String) -> Button:
	for button: Button in root.find_children("*", "Button", true, false):
		if button.text.begins_with(begins):
			return button
		for caption: Label in button.find_children("*", "Label", true, false):
			if caption.text.begins_with(begins):
				return button
	return null


func _popup_close() -> Button:
	if not _detail_visible():
		return null
	var overlay: Node = _page._detail.get_meta("overlay")
	for button: Button in overlay.find_children("*", "Button", true, false):
		if button.custom_minimum_size == Vector2(68, 68):
			return button
	return null


func _detail_visible() -> bool:
	return _page._detail != null and is_instance_valid(_page._detail) and _page._detail.is_visible_in_tree()


func _nav_button(index: int) -> Button:
	var bar: Node = _home._nav_holder.get_child(0)
	for child in bar.get_child(index).get_children():
		if child is Button:
			return child
	return null


func _tap(button: Button) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var native := get_tree().root.get_final_transform() * button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = native
	motion.global_position = native
	Input.parse_input_event(motion)
	await get_tree().process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = native
		event.global_position = native
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
	return received[0]


func _same_members(actual: Array, expected: Array) -> bool:
	return actual.size() == expected.size() and actual.all(func(uid): return expected.has(uid))


func _rarity_sorted(uids: Array, descending: bool) -> bool:
	if uids.size() != 9:
		return false
	for index in range(1, uids.size()):
		var previous: int = HeroCat.def(PlayerData.hero_cat, uids[index - 1]).rarity
		var current: int = HeroCat.def(PlayerData.hero_cat, uids[index]).rarity
		if (descending and previous < current) or (not descending and previous > current):
			return false
	return true


func _settle() -> void:
	await get_tree().create_timer(0.24).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var filename := "%s_%dx%d.png" % [label, _size.x, _size.y]
	_check(image.get_size() == _size and image.save_png(OUT.path_join(filename)) == OK, "capture_" + label)
	_captures.append({"file": filename, "window": [_size.x, _size.y]})


func _save_hash() -> String:
	return FileAccess.get_sha256(PlayerData.SAVE_PATH) if FileAccess.file_exists(PlayerData.SAVE_PATH) else "absent"


func _rect(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _check(passed: bool, label: String) -> void:
	_checks.append({"name": label, "passed": passed, "window": [_size.x, _size.y]})
	if not passed:
		_failures += 1
		push_error("EQUIPMENT_INTEGRATION_REVIEW_FAIL " + label + " " + str(_size))


func _finish() -> void:
	var report := {"scope": "Actual production Home/Hero page, original CartonNav, nonpersistent fresh/full/empty fixtures; native mouse interaction, filter/sort, equip/upgrade and rejected API actions.",
		"profile": OS.get_user_data_dir(), "original_persist_restored": PlayerData.persist == _original_persist,
		"save_before": _save_before, "save_after": _save_hash(), "checks": _checks, "captures": _captures, "geometry": _geometry, "failures": _failures}
	var file := FileAccess.open(OUT.path_join("review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("EQUIPMENT_INTEGRATION_REVIEW_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
