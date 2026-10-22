extends Node

## Narrow review of production frames, with no visual overrides or save writes.
const HOME = preload("res://game/menu/Home.tscn")
const HeroCat = preload("res://game/core/HeroCat.gd")
const OUT := "res://docs/design/2026-10-23/weapon-frame-options/integration"
const SIZES := [Vector2i(450, 800), Vector2i(360, 640)]
const WORN := ["kiem_go", "mu_hiep_si", "giap_rong", "giay_gio"]

var _home
var _page
var _size := Vector2i.ZERO
var _uids: Dictionary = {}
var _checks: Array = []
var _captures: Array = []
var _frames: Array = []
var _failures := 0
var _save_before := ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	_save_before = _save_hash()
	for requested in SIZES:
		_size = requested
		_fixture(false)
		await _mount()
		_audit("fresh", 7)
		var empty: TextureRect = _page.find_child("EmptyEquipmentSymbol", true, false)
		_check(empty != null and empty.texture.resource_path.get_file().begins_with("icon_slot_boots"), "fresh_empty_slot_retains_dedicated_boots_glyph")
		await _capture("fresh")
		await _unmount()
		_fixture(true)
		await _mount()
		_audit("full", 13)
		_audit_grid()
		await _capture("full-bag")
		await _detail()
		await _unmount()
	_check(not PlayerData.persist and _save_before == _save_hash(), "no_player_save_write")
	var report := {"scope": "Actual production Home/Hero equipment frames, no visual overrides; fresh and all-item inventory at two native window sizes.",
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist, "save_before": _save_before, "save_after": _save_hash(),
		"checks": _checks, "captures": _captures, "frames": _frames, "failures": _failures}
	var file := FileAccess.open(OUT.path_join("review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("EQUIPMENT_FRAMES_REVIEW_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _fixture(full: bool) -> void:
	PlayerData._reset()
	PlayerData.persist = false
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false
	_uids.clear()
	if not full:
		return
	PlayerData.gold = 50000
	var state := {"equipped": {}, "bag": {}, "retired_items": {}, "next": 1}
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


func _audit(context: String, expected: int) -> void:
	var arts: Array[Node] = _page.find_children("EquipmentArt", "TextureRect", true, false)
	var frames_ok := arts.size() == expected
	var art_ok := arts.size() == expected
	for art: TextureRect in arts:
		var card: Control = art.get_parent()
		var panel: PanelContainer = card.get_child(0)
		var variant := str(panel.theme_type_variation)
		var tone := variant.trim_prefix("CardEquipment").to_lower()
		var style := panel.get_theme_stylebox("panel")
		var texture_style := style as StyleBoxTexture
		var path := texture_style.texture.resource_path if texture_style != null and texture_style.texture != null else ""
		frames_ok = frames_ok and variant.begins_with("CardEquipment") and path.get_file() == "card_equipment_" + tone + ".svg"
		frames_ok = frames_ok and texture_style != null and texture_style.texture.get_size() == Vector2(124, 124)
		var card_rect := card.get_global_rect()
		var art_rect := art.get_global_rect()
		var ratio := 0.68 if art.texture.resource_path.get_file().begins_with("icon_hero_w_") or art.texture.resource_path.get_file().begins_with("icon_w_") else 0.78
		art_ok = art_ok and art.texture.resource_path.begins_with("res://game/ui/art/") and art.texture.resource_path.ends_with(".png")
		art_ok = art_ok and art_rect.get_center().distance_to(card_rect.get_center()) < 0.05 and card_rect.encloses(art_rect)
		art_ok = art_ok and absf(art_rect.size.x / card_rect.size.x - ratio) < 0.01
		_frames.append({"context": context, "window": [_size.x, _size.y], "variant": variant, "source": path,
			"art": art.texture.resource_path, "card": _rect(card_rect), "art_rect": _rect(art_rect)})
	_check(frames_ok, context + "_all_cards_use_production_CardEquipment_SVGs")
	_check(art_ok, context + "_production_item_art_centered_and_fitted")


func _audit_grid() -> void:
	var found := false
	var fit := false
	for grid: GridContainer in _page.find_children("*", "GridContainer", true, false):
		if grid.columns != 5 or grid.get_child_count() != 9:
			continue
		found = true
		var children := grid.get_children()
		var y: float = children[0].get_global_rect().position.y
		fit = true
		for index in 5:
			fit = fit and absf(children[index].get_global_rect().position.y - y) < 0.05
		fit = fit and children[5].get_global_rect().position.y > y
		var left: float = children[0].get_global_rect().position.x
		var right: float = children[4].get_global_rect().end.x
		fit = fit and left >= 0 and right <= _page.size.x
	_check(found and fit, "full_inventory_five_cards_per_row_within_page")


func _detail() -> void:
	var uid: String = _uids.cung_san
	var target := _card_button(uid)
	for scroll: ScrollContainer in _page.find_children("*", "ScrollContainer", true, false):
		if target != null and scroll.is_ancestor_of(target):
			scroll.ensure_control_visible(target)
	await _settle()
	_check(await _tap(target), "native_card_opens_bow_comparison")
	await _settle()
	var visible: bool = _page._detail != null and is_instance_valid(_page._detail) and _page._detail.is_visible_in_tree()
	_check(visible and _page._detail_uid == uid, "comparison_targets_bow")
	if visible:
		var detail_art: Array[Node] = _page._detail.find_children("EquipmentArt", "TextureRect", true, false)
		var cards_ok := detail_art.size() == 2
		for art: TextureRect in detail_art:
			var panel: PanelContainer = art.get_parent().get_child(0)
			cards_ok = cards_ok and str(panel.theme_type_variation).begins_with("CardEquipment")
		_check(cards_ok, "comparison_also_uses_two_production_equipment_frames")
		await _capture("bow-comparison")


func _card_button(uid: String) -> Button:
	for button: Button in _page.find_children("*", "Button", true, false):
		for connection in button.get_signal_connection_list("pressed"):
			var callback: Callable = connection.callable
			if callback.get_object() == _page and callback.get_method() == "_open_detail" and callback.get_bound_arguments().has(uid):
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
	_captures.append({"file": filename, "window": [_size.x, _size.y]})


func _save_hash() -> String:
	return FileAccess.get_sha256(PlayerData.SAVE_PATH) if FileAccess.file_exists(PlayerData.SAVE_PATH) else "absent"


func _rect(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _check(passed: bool, label: String) -> void:
	_checks.append({"name": label, "passed": passed, "window": [_size.x, _size.y]})
	if not passed:
		_failures += 1
		push_error("EQUIPMENT_FRAMES_REVIEW_FAIL " + label + " " + str(_size))
