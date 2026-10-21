extends Control

# Isolated review scene: original menu screenshots and original icons, no game writes.
# Mouse/touch opens a two-flap carton; keys 1..5 select the matching menu.
const OUT := "res://docs/design/2026-10-21/shoebox-nav-demo"
const ASSETS := "res://docs/design/2026-10-21/bottom-nav-options"
const NAMES := ["Cửa hàng", "Anh hùng", "Chiến", "Lính", "Triệu hồi"]
const IDS := ["shop", "hero", "battle", "troops", "summon"]
const NAV_Y := 538.0
const INK := Color("65482f")

class BoxState:
	extends RefCounted
	var lid := 0.0
	var lift := 0.0
	var weight := 1.0
	var press := 1.0
	var rect := Rect2()
	var motion: Tween
	var pressing: Tween

var _font: Font
var _icons: Array[Texture2D] = []
var _backgrounds: Array[Texture2D] = []
var _background_edges: Array[Color] = []
var _art: Dictionary = {}
var _carton: Dictionary = {}
var _boxes: Array[BoxState] = []
var _active := 2
var _pressed := -1
var _checks: Array = []
var _captures: Array = []
var _failures := 0


func _ready() -> void:
	PlayerData.persist = false
	get_window().size = Vector2i(360, 640)
	get_window().content_scale_size = Vector2i(360, 640)
	get_window().title = "Mẫu mới — Carton hai cánh | Bấm tab hoặc phím 1–5"
	if not "--capture" in OS.get_cmdline_user_args():
		var desktop := DisplayServer.screen_get_usable_rect()
		get_window().position = desktop.position + (desktop.size - get_window().size) / 2
		get_window().always_on_top = true
		get_window().grab_focus()
	_font = load("res://game/ui/fonts/PaytoneOne-Regular.ttf")
	_carton = JSON.parse_string(FileAccess.get_file_as_string(OUT.path_join("art-v3/carton-motion.json")))
	for layer in ["box-front", "box-inside", "nav-shelf"]:
		var svg := FileAccess.get_file_as_string(OUT.path_join("art-v3/%s.svg" % layer))
		var raster := Image.new()
		var error := raster.load_svg_from_string(svg, 4.0)
		assert(error == OK, "Shared carton SVG must rasterize: " + layer)
		_art[layer] = ImageTexture.create_from_image(raster)
	for i in IDS.size():
		_icons.append(_png(ASSETS.path_join("balanced-%s.png" % IDS[i])))
		var path := OUT.path_join("clean-%s.png" % IDS[i])
		var source := Image.load_from_file(ProjectSettings.globalize_path(path))
		_backgrounds.append(ImageTexture.create_from_image(source))
		_background_edges.append(source.get_pixel(2, 537))
		_boxes.append(BoxState.new())
	_boxes[_active].lid = 1.0
	_boxes[_active].lift = 1.0
	_boxes[_active].weight = 1.32
	_layout()
	if "--capture" in OS.get_cmdline_user_args():
		_capture_review.call_deferred()


func _png(path: String) -> Texture2D:
	return ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path)))


func _process(_delta: float) -> void:
	_layout()
	queue_redraw()


func _layout() -> void:
	var total := 0.0
	for box in _boxes:
		total += box.weight
	var x := 5.0
	for box in _boxes:
		var width := 338.0 * box.weight / total
		box.rect = Rect2(x, NAV_Y + 3.0, width, 99.0)
		x += width + 3.0


func _draw() -> void:
	var factor := get_viewport_rect().size / Vector2(360, 640)
	draw_set_transform(Vector2.ZERO, 0.0, factor)
	if _backgrounds.is_empty():
		return
	draw_texture_rect(_backgrounds[_active], Rect2(0, 0, 360, 640), false)
	# A shared shallow backboard ties all five cartons together.
	draw_texture_rect(_art["nav-shelf"], Rect2(0, 570, 360, 70), false)
	for i in _boxes.size():
		if i != _active:
			_draw_box(i)
	_draw_box(_active)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_box(index: int) -> void:
	var box := _boxes[index]
	var origin := box.rect.position
	var width := box.rect.size.x
	var center := Vector2(width * 0.5, 67)
	var factor := get_viewport_rect().size / Vector2(360, 640)
	var offset := (origin + center - center * box.press) * factor
	draw_set_transform(offset, 0.0, factor * box.press)
	var phase := box.lid
	var full_rect := Rect2(0, 0, width, 100)
	draw_texture_rect(_art["box-inside"], full_rect, false, Color(1, 1, 1, phase))
	_draw_flap("left", phase, width)
	_draw_flap("right", phase, width)
	draw_texture_rect(_art["box-front"], full_rect, false)
	var lift := box.lift
	var icon_size := 36.0 + 8.0 * lift
	var icon_center := Vector2(width * 0.5, 77.0 - 35.0 * lift)
	var tex := _icons[index]
	var ratio := Vector2(tex.get_width(), tex.get_height())
	ratio *= icon_size / maxf(ratio.x, ratio.y)
	draw_texture_rect(tex, Rect2(icon_center - ratio * 0.5, ratio), false)
	if index == 3:
		var dot := icon_center + Vector2(ratio.x * 0.38, -ratio.y * 0.36)
		draw_circle(dot, 3.5, Color("ed7154"), true, -1.0, true)
		draw_arc(dot, 3.5, 0, TAU, 24, INK, 1.0, true)
	# Drawing the identical front again makes the emerging icon pass behind its lip.
	draw_texture_rect(_art["box-front"], full_rect, false, Color(1, 1, 1, phase))
	if index == _active:
		var text_scale := _caption_scale(index, width)
		var label_width := _font.get_string_size(NAMES[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x * text_scale
		draw_set_transform(offset, 0.0, factor * box.press * text_scale)
		draw_string(_font, Vector2((width - label_width) * 0.5, 89) / text_scale, NAMES[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
	draw_set_transform(Vector2.ZERO, 0.0, factor)


func _flap_points(side: String, phase: float, width: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var closed: Array = _carton[side + "_closed"]
	var opened: Array = _carton[side + "_open"]
	for i in closed.size():
		var from := Vector2(closed[i][0], closed[i][1])
		var to := Vector2(opened[i][0], opened[i][1])
		var point := from.lerp(to, phase)
		points.append(Vector2(point.x * width / 100.0, point.y))
	return points


func _draw_flap(side: String, phase: float, width: float) -> void:
	var points := _flap_points(side, phase, width)
	# As a flap turns edge-on its projected quad can become degenerate. Two
	# explicit triangles preserve the shared vertices without failed triangulation.
	for triangle in [PackedVector2Array([points[0], points[1], points[2]]), PackedVector2Array([points[0], points[2], points[3]])]:
		if absf((triangle[1] - triangle[0]).cross(triangle[2] - triangle[0])) > 0.01:
			draw_colored_polygon(triangle, Color(_carton["flap_fill"]))
	var contour := points.duplicate()
	contour.append(points[0])
	# JSON stroke is authored on the 100px canvas; retain its weight at screen size.
	var stroke := float(_carton["stroke_width"]) * width / 100.0
	draw_polyline(contour, Color(_carton["outline"]), stroke, true)
	var crease_start := points[0].lerp(points[1], 0.15).lerp(points[3].lerp(points[2], 0.15), 0.10)
	var crease_end := points[0].lerp(points[1], 0.15).lerp(points[3].lerp(points[2], 0.15), 0.90)
	draw_line(crease_start, crease_end, Color(_carton["flap_fold"]), 0.8, true)
	var shine_from := points[1].lerp(points[0], 0.18).lerp(points[2].lerp(points[3], 0.18), 0.18)
	var shine_to := points[1].lerp(points[0], 0.18).lerp(points[2].lerp(points[3], 0.18), 0.80)
	draw_line(shine_from, shine_to, Color(_carton["flap_highlight"]), 0.8, true)


func _caption_scale(index: int, width: float) -> float:
	var source_width := _font.get_string_size(NAMES[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	return minf(12.5 / 13.0, (width * 0.88 - 2.0) / source_width)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.keycode - KEY_1
		if index >= 0 and index < 5:
			_select(index)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2 = event.position * Vector2(360, 640) / get_viewport_rect().size
		if event.pressed:
			_pressed = _hit(point)
			if _pressed >= 0:
				_press(_pressed, 0.94, 0.06)
		elif _pressed >= 0:
			var index := _pressed
			_pressed = -1
			_press(index, 1.0, 0.1)
			if _hit(point) == index:
				_select(index)


func _hit(point: Vector2) -> int:
	for i in _boxes.size():
		if _boxes[i].rect.has_point(point):
			return i
	return -1


func _press(index: int, value: float, duration: float) -> void:
	var box := _boxes[index]
	if box.pressing:
		box.pressing.kill()
	box.pressing = create_tween()
	box.pressing.tween_property(box, "press", value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _select(index: int) -> void:
	if index == _active:
		# A repeated tap never restarts or interrupts the existing open transition.
		return
	_active = index
	for i in _boxes.size():
		var box := _boxes[i]
		if box.motion:
			box.motion.kill()
		box.motion = create_tween().set_parallel(true)
		box.motion.tween_property(box, "weight", 1.32 if i == index else 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		if i == index:
			box.motion.tween_property(box, "lid", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			box.motion.tween_property(box, "lift", 1.0, 0.22).set_delay(0.065).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			box.motion.tween_property(box, "lift", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			box.motion.tween_property(box, "lid", 0.0, 0.16).set_delay(0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _capture_review() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_flap_checks()
	await _wait(0.2)
	await _capture("native-battle")
	_check(_active == 2, "initial_battle_selected")
	var point := _boxes[0].rect.get_center()
	_tap_event(point, true)
	await _wait(0.08)
	_check(absf(_boxes[0].press - 0.94) < 0.002, "pointer_down_compresses_60ms")
	await _capture("native-press")
	_tap_event(point, false)
	await _wait(0.075)
	var opening_motion := _boxes[0].motion
	var opening_phase := _boxes[0].lid
	_select(0)
	_check(_boxes[0].motion == opening_motion and _boxes[0].lid == opening_phase, "active_retap_preserves_inflight_open")
	await _capture("native-opening-075ms")
	await _wait(0.09)
	await _capture("native-opening-165ms")
	await _wait(0.18)
	await _capture("native-shop")
	_settled_checks("shop", 0)
	for index in [1, 3, 4]:
		_select(index)
		await _wait(0.34)
		await _capture("native-" + IDS[index])
		_settled_checks(IDS[index], index)
	# Rapid changes retarget the existing five states rather than recreate nodes.
	for index in [0, 4, 1, 2, 3, 0, 2]:
		_select(index)
		await _wait(0.035)
	await _wait(0.4)
	_settled_checks("rapid_clicks", 2)
	await _capture("native-rapid-settled")
	_select(2)
	await _wait(0.32)
	_settled_checks("active_retap", 2)
	var file := FileAccess.open(OUT.path_join("native-qa.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"native_render": true, "production_modified": false, "save_persistence": PlayerData.persist,
		"viewport": [get_viewport_rect().size.x, get_viewport_rect().size.y], "checks": _checks,
		"captures": _captures, "failures": _failures}, "\t"))
	file.close()
	print("SHOEBOX_NATIVE_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures else 0)


func _settled_checks(label: String, index: int) -> void:
	_check(_active == index and _boxes.size() == 5, label + "_five_persistent_boxes")
	var previous_right := 0.0
	for i in _boxes.size():
		var box := _boxes[i]
		var wanted := 1.0 if i == index else 0.0
		_check(absf(box.lid - wanted) < 0.002 and absf(box.lift - wanted) < 0.002, label + "_phases_" + str(i))
		_check(box.rect.position.x >= previous_right and box.rect.end.x <= 355.01 and box.rect.end.y <= 640.01, label + "_bounds_" + str(i))
		_check(box.rect.size.x >= 63.0, label + "_touch_width_" + str(i))
		var flap_bounds_ok := true
		for side in ["left", "right"]:
			for point in _flap_points(side, box.lid, box.rect.size.x):
				var global_point: Vector2 = box.rect.position + point
				flap_bounds_ok = flap_bounds_ok and global_point.x >= 0 and global_point.x <= 360 and global_point.y >= 0 and global_point.y <= 640
		_check(flap_bounds_ok, label + "_flaps_inside_viewport_" + str(i))
		var icon_size := 36.0 + 8.0 * box.lift
		var icon_y := 77.0 - 35.0 * box.lift
		_check(icon_size < box.rect.size.x and icon_y - icon_size * 0.5 >= 0 and icon_y + icon_size * 0.5 <= 100, label + "_icon_bounds_" + str(i))
		if i == index:
			var text_width := _font.get_string_size(NAMES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x * _caption_scale(i, box.rect.size.x)
			_check(text_width <= box.rect.size.x * 0.88 - 1.99, label + "_caption_fits")
		if i > 0:
			var prior := _boxes[i - 1]
			var body_gap := box.rect.position.x + box.rect.size.x * 0.03 - (prior.rect.position.x + prior.rect.size.x * 0.97)
			_check(body_gap < 8.0 and body_gap >= 3.0, label + "_tight_body_gap_" + str(i))
		previous_right = box.rect.end.x


func _flap_checks() -> void:
	for phase in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var left := _flap_points("left", phase, 100)
		var right := _flap_points("right", phase, 100)
		var bounds_ok := true
		var mirrored := true
		for i in left.size():
			bounds_ok = bounds_ok and left[i].x >= -4 and left[i].x <= 104 and right[i].x >= -4 and right[i].x <= 104
			mirrored = mirrored and absf(left[i].x + right[i].x - 100) < 0.001 and absf(left[i].y - right[i].y) < 0.001
		_check(bounds_ok, "carton_wings_bounded_overhang_" + str(phase))
		_check(mirrored, "carton_wings_mirror_" + str(phase))
		var hinge_top := Vector2(_carton["left_closed"][0][0], _carton["left_closed"][0][1])
		var hinge_back := Vector2(_carton["left_closed"][3][0], _carton["left_closed"][3][1])
		_check(left[0] == hinge_top and left[3] == hinge_back, "carton_fixed_hinges_" + str(phase))
	_check(not _art.has("lid-open") and not _art.has("lid-closed"), "carton_has_no_rear_lid")
	_check(_art.has("nav-shelf") and _art["nav-shelf"].get_width() == 1440 and _art["nav-shelf"].get_height() == 280, "shared_nav_shelf_rasterized_4x")
	_check(Rect2(0, 0, 360, 640).encloses(Rect2(0, 570, 360, 70)), "shared_nav_shelf_inside_viewport")


func _check(value: bool, label: String) -> void:
	_checks.append({"name": label, "pass": value})
	if not value:
		_failures += 1
		push_error("Shoebox review: " + label)


func _tap_event(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point * get_viewport_rect().size / Vector2(360, 640)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	Input.parse_input_event(event)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	await get_tree().process_frame


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := OUT.path_join(label + ".png")
	var result := get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	_check(result == OK, label + "_saved")
	_captures.append(path)
