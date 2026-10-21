extends SceneTree

func _initialize() -> void:
	var folder := ProjectSettings.globalize_path("res://../../cardboard-castle-lobby-v3").simplify_path()
	var image := Image.new()
	if image.load_svg_from_string(FileAccess.get_file_as_string(folder + "/playground-clean.svg"), 1.0) != OK:
		quit(1)
		return
	if image.save_png(folder + "/playground-clean.png") != OK:
		quit(1)
		return
	print("LOBBY_PLAYGROUND_CLEAN_RENDERED ", image.get_size())
	var castle := Image.new()
	if castle.load_svg_from_string(FileAccess.get_file_as_string(folder + "/processed/castle-clean.svg"), 1.0) != OK:
		quit(1)
		return
	if castle.save_png(folder + "/processed/castle-clean.png") != OK:
		quit(1)
		return
	print("LOBBY_CASTLE_CLEAN_RENDERED ", castle.get_size())
	quit()
