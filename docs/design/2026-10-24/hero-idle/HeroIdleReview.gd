extends Node

## Checks the actual Home/Hero page with disposable, nonpersistent inventory data.
## No replacement artwork, animation seeking, manual process calls or layout overrides.
const HOME = preload("res://game/menu/Home.tscn")
const HOME_SCRIPT = preload("res://game/menu/Home.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const OUT := "res://docs/design/2026-10-24/hero-idle/native"
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
const WEAPONS := ["kiem_go", "cung_san", "gay_sao", "riu_lua", "katana_nguyet"]
const WORN := ["kiem_go", "mu_hiep_si", "giap_rong", "giay_gio"]
const FAMILIES := {"kiem_go": "melee", "cung_san": "ranged", "gay_sao": "magic", "riu_lua": "heavy", "katana_nguyet": "katana", "": "bare"}

var _home
var _page
var _size := Vector2i.ZERO
var _uids: Dictionary = {}
var _checks: Array = []
var _captures: Array = []
var _samples: Array = []
var _failures := 0
var _before: Dictionary = {}
var _save_before := ""
var _persist_before := true
var _tab_before := 2


func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_before = PlayerData.to_dict().duplicate(true)
	_persist_before = PlayerData.persist
	_tab_before = HOME_SCRIPT.last_tab
	PlayerData.persist = false
	_save_before = _save_hash()
	for requested in SIZES:
		_size = requested
		_fixture()
		await _mount()
		await _idle_progress()
		for id in WEAPONS:
			if id == "kiem_go":
				continue
			await _equip(id)
		PlayerData.hero_cat.equipped.erase("weapon")
		_page.refresh()
		await _settle()
		_audit("bare")
		await _capture("bare")
		await _unmount()
	_check(not PlayerData.persist and _save_before == _save_hash(), "review_never_writes_save")
	PlayerData.from_dict(_before)
	HOME_SCRIPT.last_tab = _tab_before
	_check(PlayerData.to_dict() == _before, "original_in_memory_state_restored")
	PlayerData.persist = _persist_before
	_finish()


func _fixture() -> void:
	PlayerData._reset()
	PlayerData.persist = false
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false
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
	_check(_home._current == _home.HERO_TAB and _page.is_visible_in_tree(), "production_hero_page_visible")
	_audit("sword")


func _unmount() -> void:
	_home.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_home = null
	_page = null


func _stage() -> Control:
	return _page.find_child("HeroPreviewStage", true, false) as Control


func _rigs() -> Array[Node]:
	var found: Array[Node] = []
	var stage := _stage()
	if stage == null:
		return found
	for node: Node in stage.find_children("*", "", true, false):
		if node.has_method("load_skeleton") and node.has_method("has_animation"):
			found.append(node)
	return found


func _audit(label: String) -> void:
	var stage := _stage()
	var rigs := _rigs()
	_check(stage != null and rigs.size() == 1, label + "_one_real_spine_rig_in_stage")
	if stage == null or rigs.size() != 1:
		return
	var rig: Node2D = rigs[0]
	var preview := stage.find_child("HeroPreview", true, false) as Control
	var uid := HeroCat.equipped_uid(PlayerData.hero_cat, "weapon")
	var definition := HeroCat.def(PlayerData.hero_cat, uid)
	var id: String = PlayerData.hero_cat.bag.get(uid, {}).get("id", "") if not definition.is_empty() else ""
	var expected: String = FAMILIES.get(id, "bare")
	_check(preview != null and preview.get("rig") == rig and preview.get("family") == expected, label + "_equipped_weapon_updates_preview_family_" + expected)
	_check(rig.get("skeleton_file") == "res://game/assets/hero/%s/%s.json" % [expected, expected], label + "_uses_production_family_spine_asset")
	var bones: Array = rig.get("_bones")
	var slots: Array = rig.get("_slots")
	_check(rig.is_visible_in_tree() and not bones.is_empty() and not slots.is_empty(), label + "_rig_has_visible_loaded_parts")
	_check(rig.get("animation") == "idle" and rig.has_animation("idle") and rig.length("idle") > 0.0, label + "_plays_authored_idle")
	var bounds := _painted_bounds(rig)
	_check(bounds.has_area() and stage.get_global_rect().grow(1.0).encloses(bounds), label + "_painted_rig_fits_stage")
	for name in ["HeroEquipmentLeft", "HeroEquipmentRight"]:
		var side := _page.find_child(name, true, false) as Control
		_check(side != null and not side.get_global_rect().intersects(bounds), label + "_clear_of_" + name)
	var scroll := _page.find_child("HeroInventoryScroll", true, false) as Control
	_check(scroll != null and scroll.size.y >= 120.0, label + "_inventory_retains_usable_height")
	var platform_free := true
	for image: TextureRect in stage.find_children("*", "TextureRect", true, false):
		if image.texture != null:
			platform_free = platform_free and not image.texture.resource_path.contains("platform")
	_check(platform_free, label + "_no_retired_circle_platform")
	_samples.append({"label": label, "window": [_size.x, _size.y], "skeleton": rig.get("skeleton_file"),
		"family": expected, "animation": rig.get("animation"), "time": rig.get("_time"), "stage": _rect(stage.get_global_rect()),
		"painted_bounds": _rect(bounds), "parts": slots.size(), "bones": bones.size()})


func _idle_progress() -> void:
	var rigs := _rigs()
	if rigs.size() != 1:
		_check(false, "idle_has_rig_for_motion_sampling")
		return
	var rig: Node2D = rigs[0]
	var prior_time: float = rig.get("_time")
	var prior_pose: Array = rig.get("_world").duplicate()
	var moving := false
	await _capture("idle-0")
	for index in range(1, 16):
		await get_tree().create_timer(0.1).timeout
		await RenderingServer.frame_post_draw
		var pose: Array = rig.get("_world")
		for bone in mini(pose.size(), prior_pose.size()):
			var a: Transform2D = pose[bone]
			var b: Transform2D = prior_pose[bone]
			moving = moving or not a.is_equal_approx(b)
		if index % 5 == 0:
			_audit("idle-" + str(index))
		await _capture("idle-" + str(index))
	_check(float(rig.get("_time")) > prior_time + 0.5, "idle_time_advances_without_manual_seeking")
	_check(moving, "authored_idle_changes_bone_pose_in_natural_frames")


func _painted_bounds(rig: Node2D) -> Rect2:
	var world: Array = rig.get("_world")
	var bounds := Rect2()
	var started := false
	for slot: Dictionary in rig.get("_slots"):
		if not slot.get("shown", false) or int(slot.bone) >= world.size():
			continue
		var image: Image = slot.texture.get_image()
		if image == null:
			continue
		var used := image.get_used_rect()
		if not used.has_area():
			continue
		var rect: Rect2 = slot.rect
		var image_size := Vector2(image.get_size())
		var painted := Rect2(rect.position + Vector2(used.position) / image_size * rect.size, Vector2(used.size) / image_size * rect.size)
		var transform: Transform2D = rig.get_global_transform() * world[int(slot.bone)]
		for corner in [painted.position, Vector2(painted.end.x, painted.position.y), painted.end, Vector2(painted.position.x, painted.end.y)]:
			var point: Vector2 = transform * corner
			bounds = bounds.expand(point) if started else Rect2(point, Vector2.ZERO)
			started = true
	return bounds


func _equip(id: String) -> void:
	var target := _card_button(str(_uids[id]))
	for scroll: ScrollContainer in _page.find_children("*", "ScrollContainer", true, false):
		if target != null and scroll.is_ancestor_of(target):
			scroll.ensure_control_visible(target)
	await _settle()
	_check(await _tap(target), id + "_native_item_card_tap")
	await _settle()
	var equip: Button = null
	if _page._detail != null and is_instance_valid(_page._detail):
		for button: Button in _page._detail.find_children("*", "Button", true, false):
			if button.text == "Trang bị":
				equip = button
			for caption: Label in button.find_children("*", "Label", true, false):
				if caption.text == "Trang bị":
					equip = button
	_check(await _tap(equip), id + "_native_equip_button_tap")
	await _settle()
	_check(HeroCat.equipped_uid(PlayerData.hero_cat, "weapon") == str(_uids[id]), id + "_equipped_in_actual_player_state")
	_audit(id)
	await _capture("weapon-" + id)


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
	var native: Vector2 = get_tree().root.get_final_transform() * button.get_global_rect().get_center()
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
	_captures.append({"file": filename, "window": [_size.x, _size.y], "equipped": PlayerData.hero_cat.equipped.duplicate()})


func _save_hash() -> String:
	return FileAccess.get_sha256(PlayerData.SAVE_PATH) if FileAccess.file_exists(PlayerData.SAVE_PATH) else "absent"


func _rect(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _check(passed: bool, label: String) -> void:
	_checks.append({"name": label, "passed": passed, "window": [_size.x, _size.y]})
	if not passed:
		_failures += 1
		push_error("HERO_IDLE_REVIEW_FAIL " + label + " " + str(_size))


func _finish() -> void:
	var file := FileAccess.open(OUT.path_join("review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope": "Production Home/Hero; natural Spine idle motion; native equip actions; rig and inventory bounds at two phone sizes.",
		"profile": OS.get_user_data_dir(), "checks": _checks, "captures": _captures, "samples": _samples,
		"save_before": _save_before, "save_after": _save_hash(), "failures": _failures}, "\t"))
	file.close()
	print("HERO_IDLE_REVIEW_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
