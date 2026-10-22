extends SceneTree

const ROOT := "res://output/cat-drive-build/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT + "png")
	for i in 96:
		var stem := "cat-%03d" % i
		var image := Image.new()
		var error := image.load_svg_from_string(FileAccess.get_file_as_string(ROOT + "svg/" + stem + ".svg"), 2.0)
		if error != OK:
			push_error("Cat drive SVG failed: " + stem)
			quit(1)
			return
		image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		error = image.save_png(ROOT + "png/" + stem + ".png")
		if error != OK:
			push_error("Cat drive PNG failed: " + stem)
			quit(1)
			return
	print("Cat drive: rendered 96 foreground poses.")
	quit()
