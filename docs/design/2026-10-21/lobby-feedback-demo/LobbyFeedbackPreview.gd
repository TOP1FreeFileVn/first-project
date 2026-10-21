extends Control

## Review-only: both panels instantiate the current Home; proposals stay in memory.
const HOME := preload("res://game/menu/Home.tscn")
const UI := preload("res://game/ui/Ui.gd")
const META := preload("res://game/menu/popups/MetaPopups.gd")
const CASTLE := preload("res://game/menu/pages/CastlePage.gd")
const FONT := preload("res://game/ui/fonts/PaytoneOne-Regular.ttf")
const BASE := "res://docs/design/2026-10-21/lobby-feedback-demo"
const OUT := BASE + "/native"
const TITLES := ["Quà 7 ngày", "Nhiệm vụ", "Sự kiện", "Thành"]
const ICONS := ["checkin", "quest", "event", "castle"]
const ANIMATIONS := ["lật trang lịch", "bật dấu tích", "phất cờ", "mở cửa thành"]

var _homes: Array = []
var _views: Array[SubViewport] = []
var _shortcuts: Array[Button] = []
var _variants: Array[Texture2D] = []
var _status: Label
var _proposal_title: Label
var _variant := 0
var _busy := false
var _captures: Array = []
var _checks: Array = []


func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	PlayerData.gold = 2400
	PlayerData.gems = 260
	get_window().title = "Demo UI — Triệu hồi & 4 nút sảnh"
	get_window().content_scale_size = Vector2i(820, 810)
	get_window().size = Vector2i(820, 810)
	get_window().min_size = Vector2i(615, 608)
	if not "--capture" in OS.get_cmdline_user_args():
		var desktop := DisplayServer.screen_get_usable_rect()
		var fit := minf(1.0, minf((desktop.size.x - 40.0) / 820.0, (desktop.size.y - 40.0) / 810.0))
		get_window().size = Vector2i(Vector2(820, 810) * fit)
		get_window().position = desktop.position + (desktop.size - get_window().size) / 2
		get_window().grab_focus()
	var bg := ColorRect.new()
	bg.color = Color("f1e8d8")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_text("Triệu hồi & phản hồi sảnh", Vector2(20, 10), Vector2(780, 36), 24)
	_text("Hiện tại", Vector2(20, 52), Vector2(360, 26), 18)
	_proposal_title = _text("Đề xuất · Cổng mèo", Vector2(440, 52), Vector2(360, 26), 18)
	_variants.append(_svg(BASE + "/art/summon-portal.svg"))
	_variants.append(_svg(BASE + "/art/summon-invitation.svg"))
	_make_home(Vector2(20, 82), false)
	_make_home(Vector2(440, 82), true)
	_action("A · Cổng mèo", Vector2(20, 735), Vector2(170, 42), func(): _choose_variant(0))
	_action("B · Thư mời", Vector2(200, 735), Vector2(170, 42), func(): _choose_variant(1))
	_action("Thử 4 nút", Vector2(440, 735), Vector2(170, 42), _play_all)
	_action("Về sảnh", Vector2(620, 735), Vector2(180, 42), _reset_lobbies)
	_status = _text("Bấm giữ hoặc Tab/Enter để thử. Bấm hộp Triệu hồi để xem icon mở. Esc về sảnh.", Vector2(20, 784), Vector2(780, 24), 12)
	if "--capture" in OS.get_cmdline_user_args():
		_capture_review.call_deferred()


func _svg(path: String) -> Texture2D:
	var raster := Image.new()
	var error := raster.load_svg_from_string(FileAccess.get_file_as_string(path))
	assert(error == OK, "SVG proposal failed: " + path)
	raster.generate_mipmaps()
	return ImageTexture.create_from_image(raster)


func _text(value: String, at: Vector2, extent: Vector2, point_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size = extent
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", point_size)
	label.add_theme_color_override("font_color", Color("583f21"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _action(value: String, at: Vector2, extent: Vector2, action: Callable) -> void:
	var button := UI.button(value, "Yellow", extent, 18)
	button.theme = UI.THEME
	button.focus_mode = Control.FOCUS_ALL
	button.position = at
	button.size = extent
	button.pressed.connect(action)
	add_child(button)


func _make_home(at: Vector2, proposed: bool) -> void:
	var container := SubViewportContainer.new()
	container.position = at
	container.size = Vector2(720, 1280)
	container.scale = Vector2.ONE * 0.5
	container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	container.stretch = true
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var home = HOME.instantiate()
	viewport.add_child(home)
	home.select_tab(home.BATTLE_TAB, false)
	# The comparison keeps its lobby while carton icons are opened for inspection.
	for child in home.get_children():
		if child is Timer:
			child.stop()
	var bar = home.get("_nav_bar")
	for connection in bar.tab_pressed.get_connections():
		bar.tab_pressed.disconnect(connection["callable"])
	bar.tab_pressed.connect(_preview_tab.bind(home))
	_homes.append(home)
	_views.append(viewport)
	if not proposed:
		return
	bar.get("_icons")[4] = _variants[_variant]
	bar.queue_redraw()
	var side: Control = home.get("_side")
	for child in side.get_children():
		if child is Control:
			child.hide()
	var shortcut_script = load(BASE + "/ShortcutButton.gd")
	var positions := [Vector2(16, 140), Vector2(16, 284), Vector2(596, 140), Vector2(596, 284)]
	for i in 4:
		var button: Button = shortcut_script.new()
		button.call("configure", i, TITLES[i], load("res://game/ui/skin/icon_rail_%s.svg" % ICONS[i]), i < 3)
		button.position = positions[i]
		side.add_child(button)
		button.set_meta("demo_kind", i)
		button.connect("activated", _activate_shortcut)
		_shortcuts.append(button)


func _preview_tab(index: int, _home: Control) -> void:
	for home in _homes:
		home.get("_nav_bar").set_selected(index)
	if index == 4:
		_status.text = "Triệu hồi · chạm Chiến để đóng hộp, hoặc đổi A/B để so hình."


func _choose_variant(index: int) -> void:
	_variant = index
	var bar = _homes[1].get("_nav_bar")
	bar.get("_icons")[4] = _variants[index]
	bar.queue_redraw()
	_proposal_title.text = "Đề xuất · " + ("Cổng mèo" if index == 0 else "Thư mời")
	_preview_tab(4, _homes[1])


func _activate_shortcut(kind: int) -> void:
	if _busy:
		return
	_status.text = TITLES[kind] + " · nhấn lún → " + ANIMATIONS[kind] + " → mở nội dung"
	SoundLib.play("click")
	await get_tree().create_timer(0.26).timeout
	if not is_inside_tree():
		return
	var home = _homes[1]
	match kind:
		0: META.open_login(home)
		1: META.open_quests(home)
		2: META.open_events(home)
		3: home.open_page(CASTLE)


func _reset_lobbies() -> void:
	for home in _homes:
		for entry in home.get("_menu_surfaces").duplicate():
			var surface = entry["node"]
			if is_instance_valid(surface) and not surface.is_queued_for_deletion():
				surface.queue_free()
		for child in home.get_children():
			if child is CanvasLayer:
				child.queue_free()
		home.close_page()
		home.select_tab(home.BATTLE_TAB, false)
		home.get("_nav_bar").set_selected(2, false)
	for button in _shortcuts:
		button.call("set_demo_focus", false)
	_status.text = "Bấm giữ hoặc Tab/Enter để thử. Bấm hộp Triệu hồi để xem icon mở. Esc về sảnh."


func _play_all() -> void:
	if _busy:
		return
	_busy = true
	_reset_lobbies()
	for i in _shortcuts.size():
		_status.text = TITLES[i] + " · " + ANIMATIONS[i]
		var button := _shortcuts[i]
		button.call("set_demo_focus", true)
		button.call("set_demo_pressed", true)
		await get_tree().create_timer(0.16).timeout
		button.call("set_demo_pressed", false)
		button.call("play_feedback")
		await get_tree().create_timer(0.80).timeout
		button.call("set_demo_focus", false)
	_busy = false
	_status.text = "Đã chạy 4 phản hồi. Bạn có thể bấm từng nút để mở nội dung thật."


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A: _choose_variant(0)
			KEY_B: _choose_variant(1)
			KEY_SPACE: _play_all()
			KEY_ESCAPE: _reset_lobbies()


func _capture_review() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await get_tree().create_timer(0.65).timeout
	await _capture("idle")
	_choose_variant(0)
	await get_tree().create_timer(0.40).timeout
	await _capture("portal-open")
	_choose_variant(1)
	await get_tree().create_timer(0.15).timeout
	await _capture("invitation-open")
	_choose_variant(0)
	_reset_lobbies()
	_shortcuts[0].call("set_demo_focus", true)
	await get_tree().create_timer(0.15).timeout
	await _capture("focused")
	_shortcuts[0].call("set_demo_pressed", true)
	await get_tree().create_timer(0.12).timeout
	await _capture("pressed")
	_shortcuts[0].call("set_demo_pressed", false)
	for i in _shortcuts.size():
		_shortcuts[i].call("play_feedback")
		await get_tree().create_timer(0.10).timeout
		await _capture("feedback-" + str(i))
		await get_tree().create_timer(0.45).timeout
	_shortcuts[0].call("set_demo_focus", false)
	# Exercise actual pointer routing through the scaled SubViewportContainer.
	for i in _shortcuts.size():
		_reset_lobbies()
		await get_tree().create_timer(0.15).timeout
		var local_center: Vector2 = _shortcuts[i].get_global_rect().get_center()
		var point := Vector2(440, 82) + local_center * 0.5
		_pointer(point, true)
		await get_tree().create_timer(0.12).timeout
		var pressed_state: Dictionary = _shortcuts[i].call("get_review_state")
		_check(float(pressed_state["press"]) > 0.9, "native_pointer_depresses_%d" % i)
		_pointer(point, false)
		await get_tree().create_timer(0.45).timeout
		_check(_homes[1].active_menu_context() != "battle", "native_release_opens_destination_%d" % i)
		await _capture("destination-" + str(i))
	_reset_lobbies()
	var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures": _captures, "checks": _checks, "persist": PlayerData.persist, "proposal_only": true}, "\t"))
	get_tree().quit()


func _pointer(point: Vector2, down: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.pressed = down
	Input.parse_input_event(event)


func _check(passed: bool, key: String) -> void:
	_checks.append({"key": key, "passed": passed})
	if not passed:
		push_error("LOBBY_FEEDBACK_DEMO_FAIL " + key)


func _capture(key: String) -> void:
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var error := shot.save_png(OUT + "/" + key + ".png")
	assert(error == OK, "Capture failed: " + key)
	_captures.append(key + ".png")
	if key == "idle" or key.ends_with("open"):
		var panel := _views[1].get_texture().get_image()
		panel.save_png(OUT + "/proposal-" + key + ".png")
