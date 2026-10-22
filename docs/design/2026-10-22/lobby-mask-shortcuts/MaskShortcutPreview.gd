extends Node

## Approved study runner: inspect the real Home instance without replacing UI.
const HOME = preload("res://game/menu/Home.tscn")
const OUT := "res://docs/design/2026-10-22/lobby-mask-shortcuts/native"
const FEATURES := {
	"login": [0, "Quà 7 ngày", "rail_checkin"],
	"quests": [1, "Nhiệm vụ", "rail_quest"],
	"events": [2, "Sự kiện", "rail_event"],
}
var _home
var _window_size := Vector2i(450, 800)
var _captures: Array = []
var _checks: Array = []
var _failed := 0
var _mask_rails: Array[PanelContainer] = []


func _ready() -> void:
	PlayerData.persist = false
	get_window().title = "Demo · Icon sảnh không khung"
	if "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
		for requested in [Vector2i(450, 800), Vector2i(360, 640)]:
			_window_size = requested
			await _mount()
			_review_shortcuts()
			await _capture("production")
			await _review_feedback()
			_home.queue_free()
			await get_tree().process_frame
		var report := {"production": true, "persist": PlayerData.persist,
			"checks": _checks, "failed": _failed, "captures": _captures}
		var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
		print("MASK_SHORTCUT_DEMO checks=%d captures=%d failed=%d" % [_checks.size(), _captures.size(), _failed])
		get_tree().quit(1 if _failed > 0 else 0)
	else:
		await _mount()
		_review_shortcuts()
		var desktop := DisplayServer.screen_get_usable_rect()
		get_window().position = desktop.position + (desktop.size - get_window().size) / 2
		get_window().grab_focus()


func _mount() -> void:
	PlayerData._reset()
	PlayerData.persist = false
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	get_window().size = _window_size
	_home = HOME.instantiate()
	add_child(_home)
	_home.select_tab(_home.BATTLE_TAB, false)
	await _settle()


func _review_shortcuts() -> void:
	_mask_rails.clear()
	for key in FEATURES:
		var shortcut: Button = _home._side_shortcuts[key]
		_check(shortcut.custom_minimum_size == Vector2(108, 128), key + "_original_hit_size")
		_check(shortcut.get_script().resource_path == "res://game/ui/LobbyShortcut.gd", key + "_production_component")
		var rail: PanelContainer = shortcut.get_parent().get_parent()
		if rail not in _mask_rails:
			var mask: StyleBoxFlat = rail.get_theme_stylebox("panel")
			_check(mask.border_width_left == 0 and mask.border_width_right == 0 and mask.shadow_size == 0,
				"shared_mask_has_no_outline_or_shadow")
			_mask_rails.append(rail)
	_check(_mask_rails.size() == 2, "one_shared_mask_per_column")


func _review_feedback() -> void:
	var shortcut: Button = _home._side_shortcuts.login
	var point: Vector2 = get_tree().root.get_final_transform() * shortcut.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await get_tree().create_timer(0.18).timeout
	await _capture("focus")
	_check(shortcut.get_review_state().focus > 0.9, "native_hover_response")
	_pointer(point, true)
	await get_tree().create_timer(0.09).timeout
	await _capture("pressed")
	_check(shortcut.get_review_state().holding and shortcut.get_review_state().press > 0.9, "native_press_response")
	_pointer(point, false)
	await get_tree().create_timer(0.07).timeout
	await _capture("release")
	await get_tree().create_timer(0.28).timeout
	_check(_home.active_menu_context() == "login", "native_release_opens_login")
	_check(not PlayerData.persist, "demo_never_persists")


func _pointer(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)


func _settle() -> void:
	await get_tree().create_timer(0.25).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var picture := get_viewport().get_texture().get_image()
	var filename := "%s_%dx%d.png" % [label, _window_size.x, _window_size.y]
	_check(picture.get_size() == _window_size, label + "_native_size")
	_check(picture.save_png(OUT + "/" + filename) == OK, label + "_saved")
	var shortcuts := {}
	for key in FEATURES:
		var button: Button = _home._side_shortcuts[key]
		var rect := button.get_global_rect()
		shortcuts[key] = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	_captures.append({"file": filename, "window": [_window_size.x, _window_size.y], "shortcuts": shortcuts})


func _check(ok: bool, label: String) -> void:
	_checks.append({"check": label, "passed": ok, "window": [_window_size.x, _window_size.y]})
	if not ok:
		_failed += 1
		push_error("MASK_SHORTCUT_DEMO_FAIL " + label)
