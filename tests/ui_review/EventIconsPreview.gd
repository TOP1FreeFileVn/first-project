extends Node

# Real Home at both native render sizes, with input routed through actual hit targets.
# Run through event-icons-plan.json so the saved player profile is isolated too.
const OUT := "res://docs/ui_review/2026-10-19/event-icons"
const Ui = preload("res://game/ui/Ui.gd")
const Meta = preload("res://game/core/Meta.gd")
const HomeScene = preload("res://game/menu/Home.tscn")
const WINDOW_SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]
const ICON_SIZES := [32, 48, 64, 96, 128]
const ICONS := ["tab_shop", "rail_checkin", "rail_quest", "rail_event", "rail_castle", "rail_patrol", "rail_online", "rail_limited"]

@export var output_dir := OUT
@export var routes_only := false

var _home: Control
var _failures := 0
var _captures: Array = []
var _routes: Array = []


func _ready() -> void:
	print("EVENT_ICONS_USER_DIR ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	PlayerData.troops["kiem"]["level"] = 6
	PlayerData.troops["kiem"]["cards"] = 12
	for id in ["giao", "katana", "riu"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "katana"]
	PlayerData.patrol_last_claim = PlayerData.now() - 3 * 3600
	PlayerData.login_claimed = 3
	PlayerData.login_day = PlayerData.today() - 1
	get_window().size = WINDOW_SIZES[0]
	_home = HomeScene.instantiate()
	add_child(_home)
	for size in WINDOW_SIZES:
		get_window().size = size
		await get_tree().process_frame
		await get_tree().process_frame
		_home.select_tab(_home.BATTLE_TAB, false)
		await _capture("lobby", size)
		await _events_round_trip(size)
		await _events_paid_round_trip(size)
		await _popup_shortcut_round_trip("LoginShortcut", "Quà 7 ngày", "login", size)
		await _popup_shortcut_round_trip("QuestsShortcut", "Nhiệm vụ hằng ngày", "quests", size)
		await _castle_round_trip(size)
		var shop_button := _nav_button(_home.SHOP_TAB)
		var tapped := await _tap(shop_button)
		_record_route("shop_tab", tapped and _home._current == _home.SHOP_TAB, size)
		if _home._current == _home.SHOP_TAB:
			await _capture("shop", size)
	if not routes_only:
		_save_icon_sheet()
		_save_comparison_sheet()
	var manifest := {
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"output_dir": output_dir, "routes_only": routes_only,
		"captures": _captures, "routes": _routes,
		"failures": _failures,
	}
	if not routes_only:
		manifest["sheet"] = {"file": "icon_sizes_32_48_64_96_128.png", "columns": ICON_SIZES,
			"rows": ICONS, "native_pixels": true}
		manifest["comparison"] = {"file": "before_after_icons.png", "columns": ["before", "after"],
			"rows": ICONS, "native_size": 128}
	var file := FileAccess.open(output_dir + "/manifest.json", FileAccess.WRITE)
	if file == null:
		_failures += 1
		push_error("Could not write event icon capture manifest")
	else:
		file.store_string(JSON.stringify(manifest, "\t"))
		file.close()
	print("EVENT_ICONS_COMPLETE ", _captures.size(), " screens; ", _routes.size(), " routes; failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _events_round_trip(size: Vector2i, page := "events", route := "events") -> void:
	var shortcut := _named_shortcut("EventsShortcut", "Sự kiện")
	var tapped := await _tap(shortcut)
	await get_tree().create_timer(0.2).timeout
	var overlay := _active_popup()
	var opened := tapped and overlay != null and _contains_label(overlay, "Sự kiện") and _contains_label(overlay, "Tuần tra")
	_record_route(route + "_shortcut_opens_events", opened, size)
	if overlay == null:
		return
	await _capture(page, size)
	var close := _close_button(overlay)
	tapped = await _tap(close, Vector2(0.3, 0.8))
	await get_tree().process_frame
	_record_route(route + "_close_returns_to_lobby", tapped and not is_instance_valid(overlay) and _home._current == _home.BATTLE_TAB, size)
	# A routing failure should not leave a popup covering the following capture.
	if is_instance_valid(overlay):
		overlay.queue_free()
		await get_tree().process_frame


func _events_paid_round_trip(size: Vector2i) -> void:
	# Cover the paid summon branch and the widest seven-check login track in RAM only.
	var old_free_day: int = PlayerData.summon_free_day
	var old_login_claimed: int = PlayerData.login_claimed
	var old_login_day: int = PlayerData.login_day
	PlayerData.summon_free_day = PlayerData.today()
	PlayerData.login_claimed = Meta.LOGIN_REWARDS.size()
	PlayerData.login_day = PlayerData.today()
	_home._update_tabs()
	await _events_round_trip(size, "events_paid", "events_paid")
	PlayerData.summon_free_day = old_free_day
	PlayerData.login_claimed = old_login_claimed
	PlayerData.login_day = old_login_day
	_home._update_tabs()


func _popup_shortcut_round_trip(shortcut_name: String, title: String, route: String, size: Vector2i) -> void:
	var tapped := await _tap(_named_shortcut(shortcut_name, title))
	await get_tree().create_timer(0.2).timeout
	var overlay := _active_popup()
	_record_route(route + "_shortcut_opens_popup", tapped and overlay != null and _contains_label(overlay, title), size)
	if overlay == null:
		return
	tapped = await _tap(_close_button(overlay), Vector2(0.3, 0.8))
	await get_tree().process_frame
	_record_route(route + "_close_returns_to_lobby", tapped and not is_instance_valid(overlay) and _home._current == _home.BATTLE_TAB, size)
	if is_instance_valid(overlay):
		overlay.queue_free()
		await get_tree().process_frame


func _castle_round_trip(size: Vector2i) -> void:
	var tapped := await _tap(_named_shortcut("CastleShortcut", "Thành"))
	await get_tree().create_timer(0.2).timeout
	var page: Control = _home._overlay_page
	var opened := tapped and page != null and _contains_label(page, "Thành") and _contains_label(page, "Máu thành")
	_record_route("castle_shortcut_opens_castle", opened, size)
	var overlay: Control = _home._overlay
	if overlay == null:
		return
	tapped = await _tap(_direct_button(overlay))
	await get_tree().process_frame
	_record_route("castle_back_returns_to_lobby", tapped and _home._overlay == null and _home._side.visible and _home._current == _home.BATTLE_TAB, size)
	if _home._overlay != null:
		_home.close_page()
		await get_tree().process_frame


func _named_shortcut(node_name: String, fallback_caption: String) -> Button:
	var wrapper: Node = _home._side.find_child(node_name, true, false)
	return _direct_button(wrapper) if wrapper != null else _shortcut_button(_home._side, fallback_caption)


func _tap(button: Button, point := Vector2(0.5, 0.5)) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var rect := button.get_global_rect()
	var at := rect.position + rect.size * point
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		click.global_position = at
		# get_global_rect() already measured UI coordinates; do not stretch them twice.
		get_viewport().push_input(click, true)
		await get_tree().process_frame
	return received[0]


func _nav_button(index: int) -> Button:
	var bar: Control = _home._nav_holder.get_child(0)
	var cell := bar.get_child(index)
	for child in cell.get_children():
		if child is Button:
			return child
	return null


func _shortcut_button(node: Node, caption: String) -> Button:
	# The hit button is a sibling of the illustrated content inside its wrapper.
	if node is Control and node.is_visible_in_tree() and _contains_label(node, caption):
		for child in node.get_children():
			if child is Button and child.is_visible_in_tree():
				return child
	for child in node.get_children():
		var found := _shortcut_button(child, caption)
		if found != null:
			return found
	return null


func _direct_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree():
			return child
	return null


func _contains_label(node: Node, caption: String) -> bool:
	if node is Label and node.text == caption:
		return true
	for child in node.get_children():
		if _contains_label(child, caption):
			return true
	return false


func _active_popup() -> Control:
	for child in _home.get_children():
		if child is ColorRect and child.mouse_filter == Control.MOUSE_FILTER_STOP:
			return child
	return null


func _close_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.custom_minimum_size == Vector2(68, 68):
			return child
		var found := _close_button(child)
		if found != null:
			return found
	return null


func _record_route(name: String, passed: bool, size: Vector2i) -> void:
	_routes.append({"name": name, "passed": passed, "window": [size.x, size.y]})
	if not passed:
		_failures += 1
	print("EVENT_ICONS_ROUTE ", name, " ", size, " ", "PASS" if passed else "FAIL")


func _capture(page: String, requested: Vector2i) -> void:
	if routes_only:
		return
	await get_tree().create_timer(0.2).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var key := "%s_%dx%d" % [page, requested.x, requested.y]
	if shot.get_size() != requested:
		_failures += 1
		push_error("Native capture size mismatch: %s expected %s, got %s" % [key, requested, shot.get_size()])
	_save(shot, key + ".png")
	var nav_height := int(round(160.0 * shot.get_width() / 720.0))
	var crop := Rect2i(0, shot.get_height() - nav_height, shot.get_width(), nav_height)
	_save(shot.get_region(crop), key + "_nav.png")
	_captures.append({"page": page, "file": key + ".png", "nav": key + "_nav.png",
		"requested": [requested.x, requested.y], "actual": [shot.get_width(), shot.get_height()],
		"window": [get_window().size.x, get_window().size.y],
		"state": {"summon_free_ready": PlayerData.summon_free_ready(),
			"login_claimed": PlayerData.login_progress(), "login_can_claim": PlayerData.login_can_claim()}})
	print("EVENT_ICONS_CAPTURE ", key, " native=", shot.get_size())


func _save_icon_sheet() -> void:
	var cell := 144
	var sheet := Image.create(cell * ICON_SIZES.size(), cell * ICONS.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("e9dfcd"))
	for row in ICONS.size():
		for col in ICON_SIZES.size():
			var size: int = ICON_SIZES[col]
			var texture := Ui.icon_tex(ICONS[row], size)
			if texture == null:
				_failures += 1
				push_error("Missing icon variant: %s/%d" % [ICONS[row], size])
				continue
			var icon := texture.get_image()
			if icon.is_compressed():
				icon.decompress()
			icon.convert(Image.FORMAT_RGBA8)
			if icon.get_size() != Vector2i(size, size):
				_failures += 1
				push_error("Icon variant is not native %dpx: %s" % [size, ICONS[row]])
			var at := Vector2i(col * cell + (cell - icon.get_width()) / 2, row * cell + (cell - icon.get_height()) / 2)
			sheet.blend_rect(icon, Rect2i(Vector2i.ZERO, icon.get_size()), at)
	_save(sheet, "icon_sizes_32_48_64_96_128.png")


func _save_comparison_sheet() -> void:
	var cell := 144
	var sheet := Image.create(cell * 2, cell * ICONS.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("e9dfcd"))
	for row in ICONS.size():
		var old_source := FileAccess.get_file_as_string(OUT + "/before/icon_%s.svg" % ICONS[row])
		var old_icon := Image.new()
		var error := old_icon.load_svg_from_string(old_source)
		var texture := Ui.icon_tex(ICONS[row], 128)
		if error != OK or texture == null:
			_failures += 1
			push_error("Could not compare icon %s" % ICONS[row])
			continue
		var new_icon := texture.get_image()
		for col in 2:
			var icon: Image = old_icon if col == 0 else new_icon
			if icon.is_compressed():
				icon.decompress()
			icon.convert(Image.FORMAT_RGBA8)
			if icon.get_size() != Vector2i(128, 128):
				_failures += 1
				push_error("Comparison icon must be native 128px: %s/%d" % [ICONS[row], col])
				continue
			var at := Vector2i(col * cell + 8, row * cell + 8)
			sheet.blend_rect(icon, Rect2i(Vector2i.ZERO, icon.get_size()), at)
	_save(sheet, "before_after_icons.png")


func _save(image: Image, name: String) -> void:
	var result := image.save_png(output_dir + "/" + name)
	if result != OK:
		_failures += 1
		push_error("Could not save %s: %d" % [name, result])
