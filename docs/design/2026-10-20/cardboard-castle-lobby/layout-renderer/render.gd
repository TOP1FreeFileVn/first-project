extends SceneTree

func _initialize() -> void:
	var folder := ProjectSettings.globalize_path("res://..").simplify_path()
	for asset: String in ["base-island", "hero-cat"]:
		var image := Image.new()
		var result := image.load_svg_from_string(FileAccess.get_file_as_string(folder + "/" + asset + ".svg"), 1.0)
		if result != OK:
			quit(1)
			return
		if image.save_png(folder + "/" + asset + ".png") != OK:
			quit(1)
			return
		print("LOBBY_LAYER_RENDERED ", asset, " ", image.get_size())
	quit()
