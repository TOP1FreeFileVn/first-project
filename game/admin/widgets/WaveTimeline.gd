extends Control

# One wave's spawn schedule as ticks on a time axis, coloured by troop; elites are tall.

const COLORS := {"pawn": Color("c8a070"), "warrior": Color("5aa9e6"), "archer": Color("7fd66b"), "lancer": Color("ffb35c"), "monk": Color("c28bff")}

var groups: Array = []


func _init() -> void:
	custom_minimum_size = Vector2(0, 40)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var end := 1.0
	for g in groups:
		end = maxf(end, float(g.get("start", 0.0)) + float(g.get("interval", 1.0)) * (int(g["count"]) - 1))
	var left := 8.0
	var width := size.x - 70.0
	draw_line(Vector2(left, 28), Vector2(left + width, 28), Color(1, 1, 1, 0.3), 2.0)
	for g in groups:
		var color: Color = COLORS.get(g["troop"], Color.WHITE)
		var elite: bool = g.get("elite", false)
		for i in int(g["count"]):
			var t := float(g.get("start", 0.0)) + float(g.get("interval", 1.0)) * i
			var x := left + t / end * width
			draw_line(Vector2(x, 28), Vector2(x, 6 if elite else 16), color, 5.0 if elite else 3.0)
	draw_string(font, Vector2(left + width + 6, 33), "%ds" % ceili(end), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.7))
