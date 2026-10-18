extends Node

# Drags a troop card onto a team slot with real (simulated) mouse events.
# Run (windowed): Godot --path . res://tests/DragTest.tscn

var _home
var _page
var _t := 0.0
var _step := 0
var _from := Vector2.ZERO
var _to := Vector2.ZERO


func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.castle_level = 3
	for id in ["giao", "dai_bac", "katana", "riu"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "katana"]
	_home = load("res://game/menu/Home.tscn").instantiate()
	add_child(_home)


func _process(delta: float) -> void:
	_t += delta
	match _step:
		0:
			if _t < 1.0:
				return
			_home.select_tab(3, false)
			_step = 1
			_t = 0.0
		1:
			if _t < 0.5:
				return
			_page = _home._pages[3]
			var card := _find_card("Thợ mỏ")
			print("card: ", card, " slots: ", _page._slots.size())
			_from = card.get_global_rect().get_center()
			_to = _page._slots[1].get_global_rect().get_center()
			print("from ", _from, " to ", _to)
			_mouse_move(_from)
			_mouse_button(_from, true)
			_step = 2
			_t = 0.0
		2:
			if _t < 0.05:
				return
			print("after press: press_id=", _page._press_id, " ghost=", _page._ghost)
			for i in 10:
				_mouse_move(_from.lerp(_to, (i + 1) / 10.0))
			print("touchscreen: ", DisplayServer.is_touchscreen_available())
			_step = 3
			_t = 0.0
		3:
			if _t < 0.2:
				return
			print("before drop: ghost=", _page._ghost)
			_mouse_button(_to, false)
			_step = 4
			_t = 0.0
		4:
			if _t < 0.3:
				return
			print("team now: ", PlayerData.battle_team())
			get_tree().quit()


func _find_card(text: String) -> Control:
	var stack: Array = [_page]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Button and node.get_parent() is GridContainer:
			for label in node.find_children("*", "Label", true, false):
				if label.text == text:
					return node
		stack.append_array(node.get_children())
	return null


func _mouse_move(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = get_tree().root.get_final_transform() * at
	e.global_position = e.position
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)


func _mouse_button(at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.position = get_tree().root.get_final_transform() * at
	e.global_position = e.position
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	Input.parse_input_event(e)
