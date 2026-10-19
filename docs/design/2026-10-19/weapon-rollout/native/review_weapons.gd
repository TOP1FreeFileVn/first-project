extends SceneTree
## Disposable native review. Reads PNGs at runtime; never changes production art.

const IDS := [
	"kiem", "riu", "dao", "katana", "cung", "no", "sung", "dai_bac",
	"gay_phep", "thuoc", "sach_phep", "dua_phep", "giao", "cu_kiem", "chuy", "bua",
]
const VIEW_SIZE := Vector2i(1120, 820)
var rollout_dir := ""
var project_dir := ""
var allow_partial := false
var native_font: FontFile
var results: Array[Dictionary] = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--rollout-dir="):
			rollout_dir = arg.trim_prefix("--rollout-dir=").replace("\\", "/")
		elif arg.begins_with("--project-dir="):
			project_dir = arg.trim_prefix("--project-dir=").replace("\\", "/")
		elif arg == "--allow-partial":
			allow_partial = true
	assert(not rollout_dir.is_empty(), "Pass --rollout-dir=<absolute path>")
	assert(not project_dir.is_empty(), "Pass --project-dir=<absolute path>")
	call_deferred("_review")


func _label(parent: Control, value: String, position: Vector2, size: int = 18) -> void:
	var label := Label.new()
	label.text = value
	label.position = position
	label.add_theme_font_override("font", native_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("583f21"))
	parent.add_child(label)


func _texture(parent: Control, im: Image, position: Vector2, target_size: Vector2) -> void:
	var texture := ImageTexture.create_from_image(im)
	assert(texture.get_size() == Vector2(im.get_size()))
	var rect := TextureRect.new()
	rect.texture = texture
	rect.position = position
	rect.size = target_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(rect)


func _review() -> void:
	root.size = VIEW_SIZE
	root.content_scale_size = VIEW_SIZE
	native_font = FontFile.new()
	assert(native_font.load_dynamic_font(project_dir.path_join("game/ui/fonts/PaytoneOne-Regular.ttf")) == OK)
	var background := ColorRect.new()
	background.color = Color("d8e5df")
	background.size = Vector2(VIEW_SIZE)
	root.add_child(background)
	_label(background, "WEAPON SET / NATIVE GODOT REVIEW", Vector2(20, 8), 24)
	_label(background, "Unit 128 x 120 / icon 48 x 48 / no production changes", Vector2(20, 40), 12)
	var failures: Array[String] = []
	for index in IDS.size():
		var id: String = IDS[index]
		var origin := Vector2(16 + (index % 4) * 276, 70 + (index / 4) * 184)
		var tile := ColorRect.new()
		tile.color = Color("edf1e7")
		tile.position = origin
		tile.size = Vector2(264, 174)
		background.add_child(tile)
		_label(tile, id, Vector2(10, 5), 17)
		var unit_path := rollout_dir.path_join("processed/unit_" + id + ".png")
		var icon_path := rollout_dir.path_join("processed/icon_w_" + id + "_48.png")
		if not FileAccess.file_exists(unit_path) or not FileAccess.file_exists(icon_path):
			failures.append(id + ": missing unit or icon")
			_label(tile, "MISSING", Vector2(12, 64), 15)
			continue
		var unit := Image.new()
		var icon := Image.new()
		assert(unit.load(unit_path) == OK, id + " unit load failed")
		assert(icon.load(icon_path) == OK, id + " icon load failed")
		assert(unit.get_size() == Vector2i(768, 720), id + " source canvas")
		assert(icon.get_size() == Vector2i(48, 48), id + " icon canvas")
		assert(unit.get_format() == Image.FORMAT_RGBA8, id + " unit alpha format")
		assert(icon.get_format() == Image.FORMAT_RGBA8, id + " icon alpha format")
		unit.resize(128, 120, Image.INTERPOLATE_LANCZOS)
		assert(unit.save_png(rollout_dir.path_join("native/review_unit_" + id + "_128.png")) == OK)
		_texture(tile, unit, Vector2(8, 40), Vector2(128, 120))
		_texture(tile, icon, Vector2(184, 76), Vector2(48, 48))
		_label(tile, "128 x 120", Vector2(12, 155), 10)
		_label(tile, "48 px", Vector2(189, 131), 10)
		results.append({"id": id, "unit_loaded": true, "icon_loaded": true,
			"unit_canvas": [768, 720], "unit_native_resize": [128, 120], "icon_canvas": [48, 48]})
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	assert(not screenshot.is_empty(), "Native viewport capture is empty")
	assert(screenshot.save_png(rollout_dir.path_join("native/review_godot_preview.png")) == OK)
	var report := {"engine": Engine.get_version_info(), "loaded": results.size(),
		"expected": IDS.size(), "failures": failures, "items": results,
		"screenshot": "native/review_godot_preview.png", "production_modified": false}
	var file := FileAccess.open(rollout_dir.path_join("native/review_native_status.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("WEAPON_ROLLOUT_NATIVE_REVIEW ", results.size(), "/", IDS.size(), " ", failures)
	quit(0 if failures.is_empty() or allow_partial else 1)
