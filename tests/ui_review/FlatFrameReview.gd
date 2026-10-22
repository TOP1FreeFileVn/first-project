extends Node

# Native production screens after flattening frames, with raised action art preserved.
const HOME = preload("res://game/menu/Home.tscn")
const Ui = preload("res://game/ui/Ui.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const OUT := "res://docs/ui_review/2026-10-22/flat-frames"
const SIZES := [Vector2i(450, 800), Vector2i(360, 640)]

var _home
var _size := Vector2i.ZERO
var _checks: Array = []
var _captures: Array = []
var _frames: Array = []
var _failed := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	_check_button_art()
	for requested in SIZES:
		_size = requested
		_fixture()
		get_window().size = requested
		_home = HOME.instantiate()
		add_child(_home)
		_home.select_tab(_home.BATTLE_TAB, false)
		await _settle()
		await _review("home")
		for target in [[_home.HERO_TAB, "hero"], [_home.SHOP_TAB, "shop"], [_home.TROOPS_TAB, "troops"], [_home.SUMMON_TAB, "summon"]]:
			_check(await _tap(_nav_button(target[0])), "native_navigation_" + target[1])
			await _settle()
			_check(_home._current == target[0], "selected_page_" + target[1])
			await _review(target[1])
			if target[1] == "shop":
				_check(await _tap(_home.find_child("ShopRates", true, false)), "native_shop_rates_tap")
				await _settle()
				_check(_surface() != null, "shop_rates_sheet_opens")
				await _review("shop-rates")
				await _close_popup("shop-rates")
		_check(await _tap(_nav_button(_home.BATTLE_TAB)), "native_return_to_home")
		await _settle()
		for key in ["login", "quests", "events"]:
			var shortcut: Button = _home._side_shortcuts[key]
			_check(await _tap(shortcut), "native_shortcut_" + key)
			await _settle()
			_check(_surface() != null and _home.active_menu_context() == key, "shortcut_opens_correct_context_" + key)
			await _review(key)
			if key == "events":
				var go := _button_text(_surface(), "Thu" if PlayerData.patrol_alert() else "Đi")
				_check(await _tap(go), "native_event_patrol_action")
				await _settle()
				_check(_home._overlay_page != null and _home._overlay_page.get_script().resource_path.ends_with("PatrolPage.gd"), "event_opens_patrol_page")
				await _review("patrol")
				var back := _button_method(_home._overlay, _home, "close_page")
				_check(await _tap(back), "native_patrol_back")
				await _settle()
				_check(_home._overlay == null, "patrol_back_closes_page")
			else:
				await _close_popup(key)
		_check(await _tap(_home.find_child("SettingsButton", true, false)), "native_settings_tap")
		await _settle()
		_check(_surface() != null and _home.active_menu_context() == "settings", "settings_opens")
		await _review("settings")
		var fast: CheckBox = _first_checkbox(_surface())
		var before := PlayerData.fast_chest
		_check(await _tap(fast), "native_settings_checkbox")
		await _settle()
		_check(PlayerData.fast_chest != before, "settings_toggle_still_changes_preference")
		await _close_popup("settings")
		var profile: Node = _home.find_child("ProfileButton", true, false)
		var profile_hit: Button
		for child in profile.get_children():
			if child is Button:
				profile_hit = child
		_check(await _tap(profile_hit), "native_profile_tap")
		await _settle()
		_check(_surface() != null and _home.active_menu_context() == "profile", "profile_opens")
		await _review("profile")
		await _close_popup("profile")
		_home.queue_free()
		await get_tree().process_frame
	_check_button_art()
	_finish()


func _fixture() -> void:
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.tutorial_done = true
	PlayerData.gold = 50000
	PlayerData.gems = 3000
	PlayerData.castle_level = PlayerData.castle_max_level()
	PlayerData.patrol_last_claim = PlayerData.now() - 3600
	for id in PlayerData.TROOP_ORDER:
		PlayerData.troops[id] = {"unlocked": true, "level": 7, "stars": 3, "cards": 100}
	PlayerData.team = ["kiem", "riu", "dao", "cung", "no"]
	var equipped := ["kiem_go", "mu_hiep_si", "giap_rong", "giay_gio"]
	var state := {"equipped": {}, "bag": {}, "next": 1}
	for id in HeroCat.ITEMS:
		var uid := HeroCat.add_item(state, id)
		if equipped.has(id):
			state.equipped[HeroCat.ITEMS[id].slot] = uid
	PlayerData.hero_cat = state


func _review(context: String) -> void:
	var count := 0
	var textures: Dictionary = {}
	var asymmetric_flat := 0
	var shadowed_flat := 0
	for panel: PanelContainer in _home.find_children("*", "PanelContainer", true, false):
		if not panel.is_visible_in_tree() or not panel.get_global_rect().intersects(get_viewport().get_visible_rect()):
			continue
		var style := panel.get_theme_stylebox("panel")
		if style is StyleBoxEmpty:
			continue
		count += 1
		if style is StyleBoxFlat:
			if style.shadow_size > 0 and style.shadow_color.a > 0:
				shadowed_flat += 1
			if style.border_width_bottom != style.border_width_top:
				asymmetric_flat += 1
		elif style is StyleBoxTexture and style.texture != null:
			textures[style.texture.resource_path] = true
		_frames.append({"context": context, "window": [_size.x, _size.y], "node": str(panel.get_path()),
			"rect": _rect(panel.get_global_rect()), "style": style.get_class(),
			"texture": style.texture.resource_path if style is StyleBoxTexture and style.texture != null else ""})
	_check(shadowed_flat == 0, context + "_runtime_flat_frames_no_drop_shadow")
	_check(asymmetric_flat == 0, context + "_runtime_frame_top_bottom_border_equal")
	if context not in ["home"]:
		_check(count > 0, context + "_actual_production_frames_present")
	var surface := _surface()
	if surface != null:
		var section: Control
		for child in surface.find_children("*", "Control", true, false):
			if child.has_meta("menu_section_context"):
				section = child
				break
		_check(section != null, context + "_popup_uses_shared_frame")
		if section != null:
			_check(get_viewport().get_visible_rect().grow(1).encloses(section.get_global_rect()), context + "_popup_frame_inside_viewport")
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var name := "%s_%dx%d.png" % [context, _size.x, _size.y]
	_check(image.get_size() == _size and image.save_png(OUT.path_join(name)) == OK, "native_capture_" + context)
	_captures.append({"file": name, "context": context, "window": [_size.x, _size.y], "frame_count": count, "textures": textures.keys()})


func _check_button_art() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(OUT.path_join("button-art-before.json")))
	_check(data is Dictionary and data.size() == 18, "eighteen_action_button_baselines_available")
	if data is Dictionary:
		for path in data:
			_check(FileAccess.get_sha256("res://" + path) == data[path], "raised_button_art_unchanged_" + path.get_file())
	for type in ["Button", "BtnBlue", "BtnGreen", "BtnYellow", "BtnRed"]:
		var normal: StyleBox = Ui.THEME.get_stylebox("normal", type)
		var pressed: StyleBox = Ui.THEME.get_stylebox("pressed", type)
		_check(normal is StyleBoxTexture and pressed is StyleBoxTexture and normal.texture != pressed.texture, "action_button_keeps_distinct_raised_and_pressed_art_" + type)


func _surface() -> Control:
	for i in range(_home._menu_surfaces.size() - 1, -1, -1):
		var value = _home._menu_surfaces[i].node
		if is_instance_valid(value) and not value.is_queued_for_deletion() and value is Control and value != _home._overlay:
			return value
	return null


func _close_popup(context: String) -> void:
	var surface := _surface()
	var close: Button
	if surface != null:
		for button: Button in surface.find_children("*", "Button", true, false):
			if button.custom_minimum_size == Vector2(68, 68):
				close = button
				break
	_check(await _tap(close), "native_popup_close_" + context)
	await _settle()
	_check(_surface() == null, "popup_closes_" + context)


func _first_checkbox(scope: Node) -> CheckBox:
	if scope == null:
		return null
	for button: CheckBox in scope.find_children("*", "CheckBox", true, false):
		return button
	return null


func _button_text(scope: Node, caption: String) -> Button:
	if scope == null:
		return null
	for button: Button in scope.find_children("*", "Button", true, false):
		if button.text == caption:
			return button
		for text: Label in button.find_children("*", "Label", true, false):
			if text.text == caption:
				return button
	return null


func _button_method(scope: Node, object: Object, method: String) -> Button:
	if scope == null:
		return null
	for button: Button in scope.find_children("*", "Button", true, false):
		for connection in button.get_signal_connection_list("pressed"):
			var action: Callable = connection.callable
			if action.get_object() == object and action.get_method() == method:
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
	var point := get_tree().root.get_final_transform() * button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await get_tree().process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
	return received[0]


func _settle() -> void:
	await get_tree().create_timer(0.34).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _rect(value: Rect2) -> Array:
	return [value.position.x, value.position.y, value.size.x, value.size.y]


func _check(ok: bool, label: String) -> void:
	_checks.append({"name": label, "passed": ok, "window": [_size.x, _size.y]})
	if not ok:
		_failed += 1
		push_error("FLAT_FRAME_REVIEW_FAIL " + label + " " + str(_size))


func _finish() -> void:
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"checks": _checks, "captures": _captures, "frames": _frames, "failures": _failed}, "\t"))
	file.close()
	print("FLAT_FRAME_REVIEW_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failed)
	get_tree().quit(1 if _failed > 0 else 0)
