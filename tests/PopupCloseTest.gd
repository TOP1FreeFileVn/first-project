extends Node

# Opens the lobby's settings popup and clicks its close button through the viewport, at the
# button's lower-left part (where the window used to swallow taps). Prints PASS or FAIL and
# saves a shot. Run (windowed): Godot --path . res://tests/PopupCloseTest.tscn -- --out=C:/file.png

var _out := ""
var _close_pressed := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
	PlayerData.persist = false
	PlayerData._reset()
	var home = load("res://game/menu/Home.tscn").instantiate()
	add_child(home)
	await get_tree().create_timer(0.5).timeout
	home._open_settings()
	await get_tree().create_timer(0.5).timeout
	var overlay: Control = home.get_child(home.get_child_count() - 1)
	var close: Button = _find_close(overlay)
	close.pressed.connect(func(): _close_pressed = true)
	if _out != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_out)
	var rect := close.get_global_rect()
	var at := rect.position + Vector2(rect.size.x * 0.3, rect.size.y * 0.8)
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		click.global_position = at
		# The point was measured from the UI. Do not transform it again as a
		# window-space event when the project viewport is stretched.
		get_viewport().push_input(click, true)
		await get_tree().process_frame
	await get_tree().process_frame
	var passed := _close_pressed and not is_instance_valid(overlay)
	if passed:
		print("PASS: close button received the click and closed the popup")
	else:
		print("FAIL: popup still open" if is_instance_valid(overlay) else "FAIL: close button did not receive the click")
	get_tree().quit(0 if passed else 1)


func _find_close(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.custom_minimum_size == Vector2(68, 68):
			return child
		var found := _find_close(child)
		if found != null:
			return found
	return null
