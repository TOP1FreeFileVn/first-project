extends SceneTree

const ROOT := "res://docs/design/2026-10-23/nav-icon-options/"

func _init() -> void:
	var raw := OS.get_cmdline_user_args().has("--raw")
	var source := ROOT + ("raw-svg/" if raw else "svg/")
	var target := ROOT + ("raw-png/" if raw else "png/")
	DirAccess.make_dir_recursive_absolute(target)
	var count := 0
	for file in DirAccess.get_files_at(source):
		if not file.ends_with(".svg"):
			continue
		var im := Image.new()
		var error := im.load_svg_from_string(FileAccess.get_file_as_string(source + file), 2.0)
		if error != OK:
			push_error("Failed SVG: " + file)
			quit(1)
			return
		im.resize(im.get_width() / 2, im.get_height() / 2, Image.INTERPOLATE_LANCZOS)
		if im.save_png(target + file.get_basename() + ".png") != OK:
			quit(1)
			return
		count += 1
	print("Rendered ", count, " nav icon SVGs.")
	quit()
