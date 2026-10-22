extends SceneTree

const ROOT := "res://docs/design/2026-10-23/cat-two-hand-drive-v7/"

func _init() -> void:
	var rendered := 0
	for folder in ["svg", "frames"]:
		var target := ROOT + ("godot" if folder == "svg" else "frames/png")
		DirAccess.make_dir_recursive_absolute(target)
		for file in DirAccess.get_files_at(ROOT + folder):
			if not file.ends_with(".svg"):
				continue
			var im := Image.new()
			var error := im.load_svg_from_string(FileAccess.get_file_as_string(ROOT + folder + "/" + file), 2.0)
			if error != OK:
				push_error("SVG load failed: " + file)
				quit(1)
				return
			im.resize(im.get_width() / 2, im.get_height() / 2, Image.INTERPOLATE_LANCZOS)
			error = im.save_png(target + "/" + file.get_basename() + ".png")
			if error != OK:
				push_error("PNG save failed: " + file)
				quit(1)
				return
			rendered += 1
	print("Rendered ", rendered, " shared-path SVGs in Godot.")
	quit()
