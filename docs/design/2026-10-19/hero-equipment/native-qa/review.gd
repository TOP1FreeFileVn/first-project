extends SceneTree
## Isolated runtime image/texture review. No main-game autoloads or profile writes.

const POSES := ["melee", "ranged", "magic", "heavy"]
const GEAR := ["helmet", "armor", "gloves", "boots", "amulet"]
const VIEW_SIZE := Vector2i(1120, 1040)
var folder := ""
var project_dir := ""
var native_font: FontFile
var loaded: Array[Dictionary] = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-dir="):
			folder = arg.trim_prefix("--review-dir=").replace("\\", "/")
		elif arg.begins_with("--project-dir="):
			project_dir = arg.trim_prefix("--project-dir=").replace("\\", "/")
	assert(not folder.is_empty() and not project_dir.is_empty())
	call_deferred("_review")


func _label(parent: Control, value: String, position: Vector2, font_size: int = 16) -> void:
	var label := Label.new()
	label.text = value
	label.position = position
	label.add_theme_font_override("font", native_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("583f21"))
	parent.add_child(label)


func _texture(parent: Control, im: Image, position: Vector2) -> void:
	var texture := ImageTexture.create_from_image(im)
	assert(texture.get_size() == Vector2(im.get_size()))
	var rect := TextureRect.new()
	rect.texture = texture
	rect.position = position
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(rect)


func _panel(parent: Control, position: Vector2, panel_size: Vector2) -> ColorRect:
	var panel := ColorRect.new()
	panel.color = Color("edf1e7")
	panel.position = position
	panel.size = panel_size
	parent.add_child(panel)
	return panel


func _image(filename: String, expected: Vector2i) -> Image:
	var image := Image.new()
	assert(image.load(folder.path_join("processed/" + filename + ".png")) == OK, filename)
	assert(image.get_size() == expected, filename + " dimensions")
	assert(image.get_format() == Image.FORMAT_RGBA8, filename + " alpha format")
	loaded.append({"asset": filename, "size": [expected.x, expected.y], "rgba": true})
	return image


func _review() -> void:
	root.size = VIEW_SIZE
	root.content_scale_size = VIEW_SIZE
	native_font = FontFile.new()
	assert(native_font.load_dynamic_font(project_dir.path_join("game/ui/fonts/PaytoneOne-Regular.ttf")) == OK)
	var background := ColorRect.new()
	background.color = Color("d8e5df")
	background.size = Vector2(VIEW_SIZE)
	root.add_child(background)
	_label(background, "HERO EQUIPMENT / NATIVE GODOT REVIEW", Vector2(20, 8), 24)
	_label(background, "Fixed body and five worn layers / four carry references / not attack animations", Vector2(20, 42), 13)
	for index in POSES.size():
		var pose: String = POSES[index]
		var panel := _panel(background, Vector2(16 + index * 276, 76), Vector2(264, 438))
		_label(panel, pose, Vector2(10, 6), 19)
		var unit := _image("hero_" + pose, Vector2i(768, 720))
		var full := unit.duplicate()
		full.resize(256, 240, Image.INTERPOLATE_LANCZOS)
		_texture(panel, full, Vector2(4, 34))
		unit.resize(128, 120, Image.INTERPOLATE_LANCZOS)
		assert(unit.save_png(folder.path_join("native-qa/hero_" + pose + "_128_godot.png")) == OK)
		_texture(panel, unit, Vector2(8, 294))
		_label(panel, "256 x 240", Vector2(160, 284), 11)
		_label(panel, "128 x 120", Vector2(152, 345), 12)
	_label(background, "FIVE ISOLATED ITEM ICONS / 96 PX + 48 PX", Vector2(20, 530), 19)
	for index in GEAR.size():
		var id: String = GEAR[index]
		var panel := _panel(background, Vector2(16 + index * 220, 568), Vector2(208, 176))
		_label(panel, id, Vector2(10, 6), 17)
		_texture(panel, _image("icon_" + id + "_96", Vector2i(96, 96)), Vector2(8, 42))
		_texture(panel, _image("icon_" + id + "_48", Vector2i(48, 48)), Vector2(142, 66))
		_label(panel, "96 px", Vector2(36, 145), 11)
		_label(panel, "48 px", Vector2(146, 122), 11)
	_label(background, "FIXED FULL-CANVAS LAYERS / ALL SHOWN AT 128 X 120", Vector2(20, 764), 19)
	for index in GEAR.size():
		var id: String = GEAR[index]
		var panel := _panel(background, Vector2(16 + index * 220, 804), Vector2(208, 184))
		_label(panel, id, Vector2(10, 6), 17)
		var layer := _image("layer_" + id, Vector2i(768, 720))
		layer.resize(128, 120, Image.INTERPOLATE_LANCZOS)
		_texture(panel, layer, Vector2(40, 44))
	_label(background, "Runtime PNG loading + native Lanczos resize + ImageTexture upload + viewport capture", Vector2(20, 1004), 13)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	assert(not screenshot.is_empty())
	assert(screenshot.save_png(folder.path_join("native-qa/godot-preview.png")) == OK)
	var file := FileAccess.open(folder.path_join("native-qa/status.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine": Engine.get_version_info(), "loaded_assets": loaded,
		"asset_count": loaded.size(), "expected_asset_count": 19, "screenshot": "native-qa/godot-preview.png",
		"production_modified": false, "attack_animation_implemented": false}, "\t"))
	file.close()
	assert(loaded.size() == 19)
	print("HERO_EQUIPMENT_NATIVE_REVIEW_OK ", loaded.size(), "/19")
	quit()
