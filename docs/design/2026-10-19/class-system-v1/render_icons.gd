extends SceneTree

func _init() -> void:
	var directory := "res://docs/design/2026-10-19/class-system-v1/"
	for key in ["infantry", "ranged", "mage", "cavalry"]:
		for prefix in ["glyph-", "class-"]:
			var source: String = directory + prefix + key + ".svg"
			if not FileAccess.file_exists(source):
				continue
			var img := Image.new()
			if img.load_svg_from_string(FileAccess.get_file_as_string(source), 4.0) != OK:
				push_error("Cannot render " + source)
				quit(1)
				return
			if img.save_png(directory + prefix + key + ".png") != OK:
				quit(1)
				return
	print("Rendered class icons at 4x")
	quit()
