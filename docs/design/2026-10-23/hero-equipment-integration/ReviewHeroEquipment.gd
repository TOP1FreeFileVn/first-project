extends Node

## Narrow production review: no replacement UI and no persisted fixture data.
const HOME = preload("res://game/menu/Home.tscn")
const HeroCat = preload("res://game/core/HeroCat.gd")
const OUT := "res://docs/design/2026-10-23/hero-equipment-integration/runtime"
const SIZES := [Vector2i(450, 800), Vector2i(360, 640)]
const WORN := ["kiem_go", "mu_hiep_si", "giap_rong", "giay_gio"]
const WEAPONS := ["kiem_go", "cung_san", "gay_sao", "riu_lua", "katana_nguyet"]

var _home
var _page
var _size := Vector2i.ZERO
var _uids: Dictionary = {}
var _checks: Array = []
var _captures: Array = []
var _resources: Array = []
var _failures := 0
var _save_before := ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	_save_before = _save_hash()
	for requested in SIZES:
		_size = requested
		_fresh_fixture()
		await _mount()
		_audit("fresh", 3, 1, 7)
		await _capture("fresh-three-worn")
		# Clear only this disposable in-memory state's equipped map.
		PlayerData.hero_cat.equipped.clear()
		_page.refresh()
		await _settle()
		_audit("empty", 0, 4, 7)
		await _capture("all-four-empty")
		await _unmount()
		_full_fixture()
		await _mount()
		_audit("all-items", 4, 0, 13)
		await _capture("full-bag-four-worn")
		await _detail_and_bow()
		if _size.x == 450:
			for id in WEAPONS:
				if id == "cung_san":
					continue # Already captured after the actual equip button.
				PlayerData.hero_cat_equip(_uids[id])
				await _settle()
				await _capture("weapon-" + id)
		await _unmount()
	_check(not PlayerData.persist and _save_before == _save_hash(), "review_did_not_write_player_save")
	var report := {"scope": "Production Home/Hero, fresh and empty slots, all 13 items, native detail/equip taps.",
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"checks": _checks, "captures": _captures, "resources": _resources, "failures": _failures}
	var file := FileAccess.open(OUT.path_join("review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("HERO_EQUIPMENT_REVIEW_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _fresh_fixture() -> void:
	PlayerData._reset()
	PlayerData.persist = false
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false


func _full_fixture() -> void:
	_fresh_fixture()
	PlayerData.gold = 50000
	var state := {"equipped": {}, "bag": {}, "retired_items": {}, "next": 1}
	_uids.clear()
	for id in HeroCat.ITEMS:
		var uid := HeroCat.add_item(state, id)
		_uids[id] = uid
		if WORN.has(id):
			state.equipped[HeroCat.ITEMS[id].slot] = uid
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
	_check(_home._current == _home.HERO_TAB and _page.visible, "production_hero_page_visible")


func _unmount() -> void:
	_home.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _audit(context: String, worn_count: int, empty_count: int, bag_count: int) -> void:
	var state: Dictionary = PlayerData.hero_cat
	_check(state.equipped.size() == worn_count and state.bag.size() == bag_count, context + "_fixture_counts")
	var cards: Array = []
	for column_name in ["HeroEquipmentLeft", "HeroEquipmentRight"]:
		var column: Node = _page.find_child(column_name, true, false)
		if column != null:
			cards.append_array(column.get_children())
	_check(cards.size() == 4, context + "_four_side_slots")
	var empty_paths: Array = []
	var worn_paths: Array = []
	var empty_ok := true
	var worn_ok := true
	for index in mini(cards.size(), HeroCat.SLOTS.size()):
		var slot: String = HeroCat.SLOTS[index]
		var uid := HeroCat.equipped_uid(state, slot)
		var art: TextureRect = cards[index].find_child("EquipmentArt", true, false)
		if uid.is_empty():
			var icons: Array[Node] = cards[index].find_children("*", "TextureRect", true, false)
			empty_ok = empty_ok and art == null and icons.size() == 1
			for icon: TextureRect in icons:
				var path := icon.texture.resource_path if icon.texture != null else ""
				empty_paths.append({"slot": slot, "texture": path})
				empty_ok = empty_ok and path.get_file().begins_with("icon_slot_" + slot)
				empty_ok = empty_ok and not path.contains("icon_eq_") and not path.contains("icon_hero_w_")
		else:
			var path := art.texture.resource_path if art != null and art.texture != null else ""
			worn_paths.append({"slot": slot, "texture": path})
			worn_ok = worn_ok and path.begins_with("res://game/ui/art/") and path.ends_with(".png")
	_check(empty_ok and empty_paths.size() == empty_count, context + "_empty_slots_use_independent_slot_icons")
	_check(worn_ok and worn_paths.size() == worn_count, context + "_worn_slots_use_production_item_pngs")
	var arts: Array[Node] = _page.find_children("EquipmentArt", "TextureRect", true, false)
	var art_ok := arts.size() == bag_count
	var paths: Array = []
	for art: TextureRect in arts:
		var path := art.texture.resource_path if art.texture != null else ""
		paths.append(path)
		art_ok = art_ok and path.begins_with("res://game/ui/art/") and path.ends_with(".png")
	_check(art_ok, context + "_all_visible_item_cards_use_production_pngs")
	_resources.append({"context": context, "window": [_size.x, _size.y],
		"empty_slots": empty_paths, "worn_slots": worn_paths, "all_item_textures": paths})


func _detail_and_bow() -> void:
	var worn_uid: String = _uids.kiem_go
	_check(await _tap(_card_button(worn_uid)), "native_worn_card_opens_detail")
	await _settle()
	_check(_detail_visible() and _page._detail_uid == worn_uid, "detail_targets_worn_item")
	if not _detail_visible():
		return
	await _capture("worn-item-detail")
	_check(await _tap(_popup_close()), "native_close_detail")
	await _settle()
	var bow_uid: String = _uids.cung_san
	var target := _card_button(bow_uid)
	for scroll: ScrollContainer in _page.find_children("*", "ScrollContainer", true, false):
		if target != null and scroll.is_ancestor_of(target):
			scroll.ensure_control_visible(target)
	await _settle()
	_check(await _tap(target), "native_spare_bow_card_opens_comparison")
	await _settle()
	_check(_detail_visible() and _page._detail_uid == bow_uid, "comparison_targets_bow")
	if not _detail_visible():
		return
	_check(await _tap(_button_text(_page._detail, "Trang bị")), "native_equip_bow_action")
	await _settle()
	_check(HeroCat.equipped_uid(PlayerData.hero_cat, "weapon") == bow_uid and not _detail_visible(), "bow_equipped_and_comparison_closed")
	_check(SpriteLib.hero_cat_texture(PlayerData.hero_cat).resource_path.ends_with("hero_cat_ranged.png"), "bow_updates_production_held_hero")
	await _capture("weapon-cung_san")


func _detail_visible() -> bool:
	return _page._detail != null and is_instance_valid(_page._detail) and _page._detail.is_visible_in_tree()


func _card_button(uid: String) -> Button:
	for button: Button in _page.find_children("*", "Button", true, false):
		for connection in button.get_signal_connection_list("pressed"):
			var callback: Callable = connection.callable
			if callback.get_object() == _page and callback.get_method() == "_open_detail" and callback.get_bound_arguments().has(uid):
				return button
	return null


func _button_text(scope: Node, caption: String) -> Button:
	for button: Button in scope.find_children("*", "Button", true, false):
		if button.text == caption:
			return button
		for label: Label in button.find_children("*", "Label", true, false):
			if label.text == caption:
				return button
	return null


func _popup_close() -> Button:
	if _detail_visible():
		var overlay: Node = _page._detail.get_meta("overlay")
		for button: Button in overlay.find_children("*", "Button", true, false):
			if button.custom_minimum_size == Vector2(68, 68):
				return button
	return null


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


func _settle() -> void:
	await get_tree().create_timer(0.24).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var filename := "%s_%dx%d.png" % [label, _size.x, _size.y]
	_check(image.get_size() == _size and image.save_png(OUT.path_join(filename)) == OK, "capture_" + label)
	_captures.append({"file": filename, "window": [_size.x, _size.y],
		"equipped": PlayerData.hero_cat.equipped.duplicate(), "hero_texture": SpriteLib.hero_cat_texture(PlayerData.hero_cat).resource_path})


func _save_hash() -> String:
	return FileAccess.get_sha256(PlayerData.SAVE_PATH) if FileAccess.file_exists(PlayerData.SAVE_PATH) else "absent"


func _check(passed: bool, label: String) -> void:
	_checks.append({"name": label, "passed": passed, "window": [_size.x, _size.y]})
	if not passed:
		_failures += 1
		push_error("HERO_EQUIPMENT_REVIEW_FAIL " + label + " " + str(_size))
