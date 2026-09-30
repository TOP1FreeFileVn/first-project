extends Control

# Miniature of the 6x4 gear grid for the Castle page: master cell, cells open at the
# current castle level, and the cells the next level would add.

const GearBoard = preload("res://game/battle/GearBoard.gd")
const CogDraw = preload("res://game/battle/CogDraw.gd")
const DrawnIcon = preload("res://game/ui/DrawnIcon.gd")
const CELL := 44.0

var open_now := 0
var open_next := 0


func _init() -> void:
	custom_minimum_size = Vector2(GearBoard.COLS, GearBoard.ROWS) * CELL
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var order := GearBoard.open_order()
	var state := {}
	for i in order.size():
		state[order[i]] = 1 if i < open_now else (2 if i < open_next else 0)
	for y in GearBoard.ROWS:
		for x in GearBoard.COLS:
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell) * CELL + Vector2(2, 2), Vector2(CELL - 4, CELL - 4))
			var center := rect.get_center()
			if cell == GearBoard.MASTER_CELL:
				draw_rect(rect, Color(0.2, 0.25, 0.3))
				CogDraw.draw_orb(self, center, 10.0, -PI / 2.0, 19.0, 3.0)
				continue
			match state.get(cell, 0):
				1:
					draw_rect(rect, Color("5d8a4a"))
				2:
					draw_rect(rect, Color("c9a14a"))
					draw_rect(rect, Color("ffe89a"), false, 2.0)
				_:
					draw_rect(rect, Color(0.12, 0.14, 0.15))
					DrawnIcon.draw_lock(self, center, 16.0)
