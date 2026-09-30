extends Node2D

const PICK_RADIUS = 80.0

var units: Array = []
var selected_units: Array = []

func _ready():
	units = get_tree().get_nodes_in_group("units")

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_at(get_global_mouse_position(), event.shift_pressed)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_issue_move_order(get_global_mouse_position())
		return

	if event.is_action_pressed("attack"):
		for unit in selected_units:
			unit.command_attack()

func _select_at(position: Vector2, additive: bool):
	var closest_unit: Node2D
	var closest_distance = PICK_RADIUS * PICK_RADIUS

	for unit in units:
		var distance = unit.global_position.distance_squared_to(position)
		if distance < closest_distance:
			closest_unit = unit
			closest_distance = distance

	if not additive:
		_clear_selection()

	if closest_unit == null:
		return

	if selected_units.has(closest_unit):
		if additive:
			selected_units.erase(closest_unit)
			closest_unit.set_selected(false)
	else:
		selected_units.append(closest_unit)
		closest_unit.set_selected(true)

func _issue_move_order(destination: Vector2):
	if selected_units.is_empty():
		return

	var formation_center = Vector2.ZERO
	for unit in selected_units:
		formation_center += unit.global_position
	formation_center /= selected_units.size()

	for unit in selected_units:
		var formation_offset = unit.global_position - formation_center
		unit.command_move(destination + formation_offset)

func _clear_selection():
	for unit in selected_units:
		unit.set_selected(false)
	selected_units.clear()
