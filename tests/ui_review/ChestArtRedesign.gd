extends Node

# Native art review plus the real production Shop and ChestOpening renderer.
# Run with a workspace-owned APPDATA/LOCALAPPDATA and a real rendering driver.
const OUT := "res://docs/design/2026-10-21/chest-redesign"
const ChestArt = preload("res://game/ui/ChestArt.gd")
const Before = preload("res://docs/design/2026-10-21/chest-redesign/ChestArtBefore.gd")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const DrawnIcon = preload("res://game/ui/DrawnIcon.gd")
const HomeScene = preload("res://game/menu/Home.tscn")
const KINDS := ["wood", "silver", "gold"]
var _failures: Array = []
var _captures: Array = []
var _checks := 0
var _home: Control
var _opening: Control


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	get_tree().create_timer(40.0).timeout.connect(func():
		push_error("Chest art review timed out")
		get_tree().quit(1))
	await _board("before-after-native.png", Vector2i(1200, 940), _comparison)
	await _board("opening-states-native.png", Vector2i(1200, 600), _states)
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.SHOP_TAB, false)
	for dimensions in [Vector2i(720, 1280), Vector2i(360, 640)]:
		get_window().size = dimensions
		await get_tree().process_frame
		await get_tree().process_frame
		await _production_size(dimensions)
	_check(not PlayerData.persist, "Review never persists player changes")
	var report := {"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"actual_chest_widths": [26, 56, 94, 250], "shop_control": [104, 104],
		"captures": _captures, "checks": _checks, "failures": _failures,
		"contract": "Unchanged style_for/draw API; real drop/wait/open/card animation; separate transformed lid."}
	var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("CHEST_ART_REDESIGN_COMPLETE checks=", _checks, " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if not _failures.is_empty() else 0)


func _production_size(dimensions: Vector2i) -> void:
	var suffix := "%dx%d" % [dimensions.x, dimensions.y]
	await get_tree().process_frame
	await _capture("shop-" + suffix + ".png", dimensions)
	var shop_icons := _chest_icons(_home._pages[_home.SHOP_TAB])
	_check(shop_icons.size() == 3, "Shop has three chest controls")
	var shot := get_viewport().get_texture().get_image()
	var scale := dimensions.x / 720.0
	for i in shop_icons.size():
		var icon: Control = shop_icons[i]
		_check(icon.size == Vector2(104, 104), "Shop chest control remains 104 px")
		var region := Rect2(icon.get_global_rect().position * scale, icon.size * scale)
		shot.get_region(Rect2i(region)).save_png(OUT + "/shop-icon-" + KINDS[i] + "-" + suffix + ".png")
	_opening = ChestOpening.new()
	_opening.setup("Rương Gỗ", ChestArt.TINTS.wood, {"gold": 83, "cards": {"kiem": 2}}, [], false)
	_opening.attach(_home)
	await get_tree().create_timer(1.35).timeout
	_check(_opening._stage == "wait", "Actual opening reaches wait after drop")
	await _capture("actual-wait-" + suffix + ".png", dimensions)
	_opening._on_tap()
	await get_tree().create_timer(0.52).timeout
	_check(_opening._stage == "open" and _opening.lid_offset.y < 0 and _opening.mouth > 0,
		"Actual opening moves separate lid and lights mouth")
	await _capture("actual-open-" + suffix + ".png", dimensions)
	while _opening._stage == "open":
		await get_tree().process_frame
	_check(_opening._stage == "card", "Actual opening reaches card reveal")
	await get_tree().create_timer(0.65).timeout
	await _capture("actual-card-" + suffix + ".png", dimensions)
	_check(_opening.lid_alpha == 0.0 and _opening.mouth > 0, "Card reveal keeps body and mouth after lid fades")
	_opening.get_parent().queue_free()
	await get_tree().process_frame


func _board(file: String, dimensions: Vector2i, painter: Callable) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var canvas := Node2D.new()
	viewport.add_child(canvas)
	canvas.draw.connect(func(): painter.call(canvas))
	canvas.queue_redraw()
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	_check(picture.get_size() == dimensions, file + " native dimensions")
	_check(picture.save_png(OUT + "/" + file) == OK, file + " saved")
	_captures.append({"file": file, "size": [dimensions.x, dimensions.y]})
	viewport.queue_free()
	await get_tree().process_frame


func _text(ci: CanvasItem, text: String, position: Vector2, font_size := 19, color := Color("583f21")) -> void:
	ci.draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _comparison(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1200, 940), Color("dce9df"))
	_text(ci, "CHEST REDESIGN / native Godot render, equal input widths", Vector2(24, 35), 23)
	for i in 3:
		var x := 200.0 + i * 400.0
		_text(ci, KINDS[i].to_upper(), Vector2(x - 40, 77), 22)
		_text(ci, "BEFORE / 250 px", Vector2(x - 85, 115))
		Before.draw(ci, Vector2(x, 225), 250.0, Before.STYLES[KINDS[i]])
		_text(ci, "AFTER / 250 px", Vector2(x - 85, 382))
		ChestArt.draw(ci, Vector2(x, 470), 250.0, ChestArt.STYLES[KINDS[i]])
		for entry in [[94.0, 640.0], [56.0, 755.0], [26.0, 840.0]]:
			var w: float = entry[0]
			var y: float = entry[1]
			_text(ci, "%d px" % w, Vector2(x - 130, y + 9), 17)
			ChestArt.draw(ci, Vector2(x, y), w, ChestArt.STYLES[KINDS[i]])
	_text(ci, "Warm main contour / broad rounded construction / two straps / one paw lock / material-relative seams", Vector2(24, 916), 20)


func _states(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1200, 600), Color("253f50"))
	var paper := Color("f4e7c4")
	_text(ci, "Lid, bands and paint stay together; base and lock remain fixed at the seam", Vector2(24, 38), 23, paper)
	for i in 3:
		var at := Vector2(200 + 400 * i, 380)
		var offset := Vector2(35, -130) if i == 1 else Vector2.ZERO
		var rotation := 0.38 if i == 1 else 0.0
		var lid_alpha := 0.0 if i == 2 else 1.0
		var mouth := Color("ffe5a0") if i > 0 else Color.TRANSPARENT
		ChestArt.draw(ci, at, 250, ChestArt.STYLES.gold, 1.0, offset, rotation, lid_alpha, mouth)
		_text(ci, ["WAIT / 250 px", "OPEN / flying lid", "CARD / body remains"][i], Vector2(at.x - 100, 540), 21, paper)


func _chest_icons(node: Node) -> Array:
	var result: Array = []
	if node.get_script() == DrawnIcon and node.kind == DrawnIcon.Kind.CHEST:
		result.append(node)
	for child in node.get_children():
		result.append_array(_chest_icons(child))
	return result


func _capture(file: String, dimensions: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	_check(shot.get_size() == dimensions, file + " native dimensions")
	_check(shot.save_png(OUT + "/" + file) == OK, file + " saved")
	_captures.append({"file": file, "size": [dimensions.x, dimensions.y]})


func _check(ok: bool, description: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(description)
		push_error(description)
