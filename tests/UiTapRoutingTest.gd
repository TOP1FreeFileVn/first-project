extends Node

# Tests real UI signal routes without changing the user's saved audio preference.
const Ui = preload("res://game/ui/Ui.gd")
const UiKit = preload("res://game/ui/UiKit.gd")

var _checks := 0
var _failed := 0


func _ready() -> void:
	PlayerData.persist = false
	var previous_sound: bool = PlayerData.sound_on
	PlayerData.sound_on = true
	_check(SoundLib.has_sound("click"), "UI tap is ready before background synthesis")
	var shared := Ui.button("Test")
	add_child(shared)
	await _press_once(shared, "Ui.button routes one tap")
	var legacy := UiKit.button("Test", Vector2(180, 72), func(): pass)
	add_child(legacy)
	await _press_once(legacy, "UiKit.button routes one tap")
	var home = load("res://game/menu/Home.tscn").instantiate()
	add_child(home)
	await get_tree().process_frame
	var tab_cell: Control = home._nav_holder.get_child(0).get_child(0)
	var tab_hit: Button = tab_cell.get_child(tab_cell.get_child_count() - 1)
	await _press_once(tab_hit, "Home tab routes one tap")
	_check(home._current == home.SHOP_TAB, "tab action still selects the shop")
	home._open_settings()
	await get_tree().process_frame
	var overlay: Control = home.get_child(home.get_child_count() - 1)
	var close := _find_close(overlay)
	await _press_once(close, "popup close routes one tap")
	await get_tree().process_frame
	_check(not is_instance_valid(overlay), "popup close action still runs")
	await get_tree().create_timer(0.04).timeout
	PlayerData.sound_on = false
	var before: int = SoundLib._ui_tap_index
	shared.pressed.emit()
	_check(SoundLib._ui_tap_index == before, "saved sound toggle mutes UI taps")
	PlayerData.sound_on = true
	await get_tree().create_timer(0.04).timeout
	before = SoundLib._ui_tap_index
	shared.pressed.emit()
	shared.pressed.emit()
	_check(SoundLib._ui_tap_index == (before + 1) % SoundLib.UI_TAPS.size(), "duplicate signals in one frame produce one tap")
	PlayerData.sound_on = previous_sound
	print("UiTapRoutingTest: %d checks, %d failures" % [_checks, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _press_once(button: Button, message: String) -> void:
	await get_tree().create_timer(0.04).timeout
	var before: int = SoundLib._ui_tap_index
	button.pressed.emit()
	_check(SoundLib._ui_tap_index == (before + 1) % SoundLib.UI_TAPS.size(), message)


func _check(passed: bool, message: String) -> void:
	_checks += 1
	if not passed:
		_failed += 1
	print(("PASS: " if passed else "FAIL: ") + message)


func _find_close(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.custom_minimum_size == Vector2(68, 68):
			return child
		var found := _find_close(child)
		if found != null:
			return found
	return null
