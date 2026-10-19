extends SceneTree
## Isolated review project: no game autoloads or profile writes.

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var folder := ProjectSettings.globalize_path("res://..").simplify_path()
	var unit := Image.new()
	assert(unit.load(folder + "/processed/hero-spear.png") == OK)
	assert(unit.get_size() == Vector2i(768, 720))
	unit.resize(128, 120, Image.INTERPOLATE_LANCZOS)
	assert(unit.save_png(folder + "/processed/hero-spear-128-godot.png") == OK)
	var board := Image.new()
	assert(board.load(folder + "/review.png") == OK)
	assert(not board.is_empty())
	root.size = board.get_size()
	root.content_scale_size = board.get_size()
	var rect := TextureRect.new()
	rect.texture = ImageTexture.create_from_image(board)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(folder + "/native/godot-preview.png") == OK)
	print("SPEAR_STROKE_NATIVE_PREVIEW_OK")
	quit()
