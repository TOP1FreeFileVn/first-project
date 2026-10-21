extends Node

# Actual Home/Hero screen, deterministic complete equipment bag, native mouse taps.
const HOME = preload("res://game/menu/Home.tscn")
const HeroCat = preload("res://game/core/HeroCat.gd")
const OUT := "res://docs/ui_review/2026-10-21/equipment-icon-layout"
const SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]
const EQUIPPED := ["kiem_go", "mu_hiep_si", "giap_rong", "gang_bac", "giay_gio", "bua_ngoc"]

var _home
var _page
var _size := Vector2i.ZERO
var _uids: Dictionary = {}
var _checks: Array = []
var _geometry: Array = []
var _captures: Array = []
var _images: Dictionary = {}
var _failed := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	_check_held_files()
	for requested in SIZES:
		_size = requested
		_fixture()
		get_window().size = requested
		_home = HOME.instantiate()
		add_child(_home)
		_home.select_tab(_home.BATTLE_TAB, false)
		await _settle()
		_check(await _tap(_nav_button(_home.HERO_TAB)), "native_hero_navigation_tap")
		await _settle()
		_page = _home._pages[_home.HERO_TAB]
		_check(_home._current == _home.HERO_TAB and _page.visible, "actual_hero_page_selected")
		_check(HeroCat.SLOTS.size() == 6 and not HeroCat.SLOTS.has("ring"), "six_gameplay_slots_amulet_only")
		_check(PlayerData.hero_cat.equipped.size() == 6 and HeroCat.spare(PlayerData.hero_cat).size() == 11, "six_equipped_eleven_spare_fixture")
		_review_art(_page, "hero_initial", 17)
		await _capture("hero-all-items")
		var scroll := _bag_scroll()
		if scroll != null:
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
			await _settle()
			await _capture("bag-bottom")
			scroll.scroll_vertical = 0
			await _settle()
		await _upgrade_equipped()
		await _equip_spare()
		_home.queue_free()
		await get_tree().process_frame
	_check_held_files()
	_finish()


func _fixture() -> void:
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 50000
	var state := {"equipped": {}, "bag": {}, "next": 1}
	_uids.clear()
	var index := 0
	for id in HeroCat.ITEMS:
		var uid := HeroCat.add_item(state, id)
		state.bag[uid].level = 1 + (index % 12)
		_uids[id] = uid
		if EQUIPPED.has(id):
			state.equipped[HeroCat.ITEMS[id].slot] = uid
		index += 1
	PlayerData.hero_cat = state


func _upgrade_equipped() -> void:
	var uid: String = _uids.kiem_go
	var held: Texture2D = SpriteLib.hero_cat_texture(PlayerData.hero_cat)
	var held_id := held.get_instance_id()
	var before: int = HeroCat.item(PlayerData.hero_cat, uid).level
	var gold_before: int = PlayerData.gold
	var cost := HeroCat.upgrade_cost(PlayerData.hero_cat, uid)
	_check(await _tap(_card_button(uid)), "native_equipped_card_opens_detail")
	await _settle()
	_check(_detail_visible() and _page._detail_uid == uid, "equipped_detail_targets_correct_uid")
	if not _detail_visible():
		return
	_review_art(_page._detail, "equipped_detail", 1)
	await _capture("equipped-detail")
	_check(await _tap(_button_text(_page._detail, "Nâng cấp")), "native_upgrade_action_tap")
	await _settle()
	_check(HeroCat.item(PlayerData.hero_cat, uid).level == before + 1, "upgrade_changes_one_item_level")
	_check(PlayerData.gold == gold_before - cost, "upgrade_spends_exact_gold")
	_check(SpriteLib.hero_cat_texture(PlayerData.hero_cat).get_instance_id() == held_id, "upgrade_preserves_original_held_hero_texture")
	_review_art(_page, "after_upgrade", 17)
	_check(await _tap(_popup_close()), "native_detail_close_tap")
	await _settle()
	_check(not _detail_visible(), "equipped_detail_closes")


func _equip_spare() -> void:
	var uid: String = _uids.katana_nguyet
	var old_uid := HeroCat.equipped_uid(PlayerData.hero_cat, "weapon")
	_check(await _tap(_card_button(uid)), "native_spare_card_opens_comparison")
	await _settle()
	_check(_detail_visible() and _page._detail_uid == uid, "spare_detail_targets_correct_uid")
	if not _detail_visible():
		return
	_review_art(_page._detail, "comparison_detail", 2)
	await _capture("comparison-detail")
	_check(await _tap(_button_text(_page._detail, "Trang bị")), "native_equip_action_tap")
	await _settle()
	_check(HeroCat.equipped_uid(PlayerData.hero_cat, "weapon") == uid, "equip_switches_weapon_uid")
	_check(HeroCat.spare(PlayerData.hero_cat).has(old_uid) and not HeroCat.spare(PlayerData.hero_cat).has(uid), "equip_returns_previous_weapon_to_bag")
	_check(not _detail_visible(), "equip_closes_comparison")
	_check(SpriteLib.hero_cat_texture(PlayerData.hero_cat).resource_path.ends_with("hero_cat_katana.png"), "equip_uses_existing_katana_hero_art")
	_review_art(_page, "after_equip", 17)
	await _capture("after-equip")


func _review_art(scope: Node, context: String, expected: int) -> void:
	var arts := scope.find_children("EquipmentArt", "TextureRect", true, false)
	_check(arts.size() == expected, context + "_expected_card_count")
	var icons: Dictionary = {}
	for art: TextureRect in arts:
		var card: Control = art.get_parent()
		var rect := card.get_global_rect()
		var alpha := _alpha_rect(art)
		var path: String = art.texture.resource_path if art.texture != null else ""
		var key := _icon_key(path)
		icons[key] = true
		_check(art.texture != null and alpha.size.x > 0 and alpha.size.y > 0, context + "_loaded_nonempty_art_" + key)
		_check(rect.grow(-1.0).encloses(alpha), context + "_visible_art_inside_card_" + key)
		_check(rect.grow(0.01).encloses(art.get_global_rect()), context + "_art_control_inside_card_" + key)
		_check(alpha.position.y >= rect.position.y + rect.size.y * 0.24, context + "_art_clears_top_caption_row_" + key)
		var level: Label = card.find_child("EquipmentLevel", false, false)
		var badge: TextureRect = card.find_child("SlotBadge", false, false)
		_check(level != null and badge != null, context + "_level_and_slot_badge_preserved_" + key)
		_geometry.append({"context": context, "window": [_size.x, _size.y], "texture": path,
			"card": _rect_array(rect), "art_control": _rect_array(art.get_global_rect()), "visible_alpha": _rect_array(alpha)})
	if expected == 17:
		_check(icons.size() == 10, context + "_all_ten_unique_icons_present")


func _alpha_rect(art: TextureRect) -> Rect2:
	if art.texture == null:
		return Rect2()
	var image := _image(art.texture)
	var source := Vector2(image.get_size())
	var factor := minf(art.size.x / source.x, art.size.y / source.y)
	var offset := (art.size - source * factor) * 0.5
	var used := Rect2(image.get_used_rect())
	var local := Rect2(offset + used.position * factor, used.size * factor)
	return Rect2(art.get_global_transform() * local.position, local.size * art.get_global_transform().get_scale())


func _image(texture: Texture2D) -> Image:
	var key := texture.resource_path
	if not _images.has(key):
		var value := texture.get_image()
		if value.is_compressed():
			value.decompress()
		_images[key] = value
	return _images[key]


func _check_held_files() -> void:
	var path := OUT.path_join("held-hero-before.json")
	var hashes = JSON.parse_string(FileAccess.get_file_as_string(path).trim_prefix(String.chr(0xFEFF)))
	_check(hashes is Dictionary and hashes.size() == 6, "held_hero_baseline_six_files_available")
	if hashes is Dictionary:
		for file in hashes:
			_check(FileAccess.get_sha256("res://" + file) == hashes[file], "original_held_hero_file_unchanged_" + file.get_file())


func _card_button(uid: String) -> Button:
	for node: Button in _page.find_children("*", "Button", true, false):
		for connection in node.get_signal_connection_list("pressed"):
			var callback: Callable = connection.callable
			if callback.get_object() == _page and callback.get_method() == "_open_detail" and callback.get_bound_arguments().has(uid):
				return node
	return null


func _button_text(scope: Node, text: String) -> Button:
	for node: Button in scope.find_children("*", "Button", true, false):
		if node.text == text:
			return node
		for label: Label in node.find_children("*", "Label", true, false):
			if label.text == text:
				return node
	return null


func _detail_visible() -> bool:
	return _page._detail != null and is_instance_valid(_page._detail) and _page._detail.is_visible_in_tree()


func _popup_close() -> Button:
	if not _detail_visible():
		return null
	var overlay: Node = _page._detail.get_meta("overlay")
	for node: Button in overlay.find_children("*", "Button", true, false):
		if node.custom_minimum_size == Vector2(68, 68):
			return node
	return null


func _bag_scroll() -> ScrollContainer:
	for node: ScrollContainer in _page.find_children("*", "ScrollContainer", true, false):
		if node.find_child("EquipmentArt", true, false) != null:
			return node
	return null


func _nav_button(index: int) -> Button:
	var bar: Node = _home._nav_holder.get_child(0)
	for node in bar.get_child(index).get_children():
		if node is Button:
			return node
	return null


func _tap(button: Button) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var point := button.get_global_rect().get_center()
	var native := get_tree().root.get_final_transform() * point
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
	_check(image.get_size() == _size, "native_capture_size_" + label)
	_check(image.save_png(OUT.path_join(filename)) == OK, "capture_saved_" + label)
	_captures.append({"file": filename, "window": [_size.x, _size.y]})


func _rect_array(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _icon_key(path: String) -> String:
	var key := path.get_file().get_basename()
	for suffix in ["_32", "_48", "_64", "_96"]:
		if key.ends_with(suffix):
			return key.trim_suffix(suffix)
	return key


func _check(ok: bool, label: String) -> void:
	_checks.append({"name": label, "passed": ok, "window": [_size.x, _size.y]})
	if not ok:
		_failed += 1
		push_error("EQUIPMENT_ICON_LAYOUT_FAIL " + label + " " + str(_size))


func _finish() -> void:
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"checks": _checks, "captures": _captures, "geometry": _geometry, "failures": _failed}, "\t"))
	file.close()
	print("EQUIPMENT_ICON_LAYOUT_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failed)
	get_tree().quit(1 if _failed > 0 else 0)
