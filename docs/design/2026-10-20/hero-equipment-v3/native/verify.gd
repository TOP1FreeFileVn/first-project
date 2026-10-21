extends SceneTree
## Isolated texture compatibility check. No production scenes or autoloads.

const HEROES := ["hero-melee", "hero-ranged", "hero-magic", "hero-heavy"]
const SOURCE_SIZE := Vector2i(768, 720)
const NATIVE_SIZE := Vector2i(128, 120)
var _folder: String

func _initialize() -> void:
	call_deferred("_verify")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _verify() -> void:
	_folder = ProjectSettings.globalize_path("res://..").simplify_path()
	var expected_profile := (_folder + "/native/profile-roaming/StudioHeroV3").simplify_path()
	var actual_profile := OS.get_user_data_dir().replace("\\", "/").simplify_path()
	if actual_profile.to_lower() != expected_profile.to_lower():
		_fail("Review user directory escaped local profile: " + actual_profile)
		return
	var report := {
		"status": "running",
		"engine_version": Engine.get_version_info().get("string", "unknown"),
		"user_data_dir": actual_profile,
		"source_size": [SOURCE_SIZE.x, SOURCE_SIZE.y],
		"native_size": [NATIVE_SIZE.x, NATIVE_SIZE.y],
		"heroes": [],
		"scope": "Isolated art compatibility review; not gameplay or equipped appearance integration."
	}
	for hero in HEROES:
		var unit := Image.new()
		var source_path: String = _folder + "/processed/" + hero + ".png"
		if unit.load(source_path) != OK:
			_fail("Cannot load " + source_path)
			return
		if unit.get_size() != SOURCE_SIZE:
			_fail("Unexpected source size for " + hero + ": " + str(unit.get_size()))
			return
		unit.resize(NATIVE_SIZE.x, NATIVE_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var target: String = "/processed/" + hero + "-128-godot.png"
		if unit.save_png(_folder + target) != OK:
			_fail("Cannot save " + target)
			return
		report["heroes"].append({"source": source_path, "native": _folder + target})
	var board := Image.new()
	if board.load(_folder + "/hero-equipment-review.png") != OK or board.is_empty():
		_fail("Cannot load hero-equipment-review.png")
		return
	root.size = board.get_size()
	root.content_scale_size = board.get_size()
	var rect := TextureRect.new()
	rect.texture = ImageTexture.create_from_image(board)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	if rendered.is_empty() or rendered.save_png(_folder + "/native/godot-review.png") != OK:
		_fail("Cannot save Godot viewport capture")
		return
	report["board_size"] = [board.get_width(), board.get_height()]
	report["viewport_capture_size"] = [rendered.get_width(), rendered.get_height()]
	report["status"] = "passed"
	var status_file := FileAccess.open(_folder + "/native/review-status.json", FileAccess.WRITE)
	if status_file == null:
		_fail("Cannot save review-status.json")
		return
	status_file.store_string(JSON.stringify(report, "\t"))
	status_file.close()
	print("HERO_EQUIPMENT_V3_NATIVE_REVIEW_OK")
	quit()
