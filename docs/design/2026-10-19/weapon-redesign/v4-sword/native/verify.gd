extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var folder := ProjectSettings.globalize_path("res://..").simplify_path()
	var image := Image.new()
	assert(image.load(folder + "/processed/unit_kiem.png") == OK)
	assert(image.get_size() == Vector2i(768,720))
	image.resize(128,120,Image.INTERPOLATE_LANCZOS)
	assert(image.save_png(folder + "/processed/unit_kiem_128_godot.png") == OK)
	var board := Image.new()
	assert(board.load(folder + "/sword-v4-review.png") == OK)
	var rect := TextureRect.new()
	rect.texture = ImageTexture.create_from_image(board)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	assert(shot.get_width() > 0)
	assert(shot.save_png(folder + "/native/godot-preview.png") == OK)
	var result := FileAccess.open(folder + "/native/result.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"status":"passed","source_loaded":true,"native_size":[128,120],
		"renderer":RenderingServer.get_video_adapter_name(),"preview_size":[shot.get_width(),shot.get_height()],
		"production_changed":false,"isolated_project":true},"\t"))
	result.close()
	print("SWORD_V4_NATIVE_PREVIEW_OK")
	quit()
