extends Node2D

# Brief flat-vector accents for the illustrated chest. Keep the centre open so
# the paw lock, lid and reward card remain visible throughout the burst.
var effect := "dust"
var tint := Color.WHITE
var _age := 0.0
var _duration := 0.5


func setup(kind: String, color: Color) -> void:
	effect = kind
	tint = color
	_duration = 0.50 if kind == "dust" else 0.58


func _process(delta: float) -> void:
	_age += delta
	if _age >= _duration:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var t := clampf(_age / _duration, 0.0, 1.0)
	var spread := 1.0 - pow(1.0 - t, 3.0)
	var fade := pow(1.0 - t, 1.4)
	if effect == "dust":
		var paint := Color("f5d9ad").lerp(tint, 0.3)
		paint.a = tint.a * fade * 0.60
		for i in 4:
			var side := -1.0 if i < 2 else 1.0
			var step := float(i % 2)
			var at := Vector2(side * (5.0 + spread * (12.0 + step * 11.0)), -spread * (7.0 + step * 8.0))
			draw_circle(at, (7.0 + step * 3.0) * (0.5 + spread * 0.5), paint, true, -1.0, true)
		return
	var paint := tint
	paint.a *= fade * 0.85
	for i in 7:
		var angle := TAU * float(i) / 7.0 - PI * 0.5
		var at := Vector2.from_angle(angle) * (28.0 + spread * (24.0 + float(i % 3) * 9.0))
		var radius := (5.0 + float(i % 3) * 2.0) * sin(PI * pow(t, 0.55))
		if radius < 0.05:
			continue
		var points := PackedVector2Array()
		for j in 48:
			var a := TAU * float(j) / 48.0
			points.append(at + Vector2(pow(absf(cos(a)), 3.0) * signf(cos(a)), pow(absf(sin(a)), 3.0) * signf(sin(a))) * radius)
		draw_colored_polygon(points, paint)
