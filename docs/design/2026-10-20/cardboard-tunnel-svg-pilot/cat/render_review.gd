extends SceneTree

func _initialize() -> void:
	var folder: String = OS.get_cmdline_user_args()[0]
	var out := folder.path_join("png")
	DirAccess.make_dir_recursive_absolute(out)
	for file: String in DirAccess.get_files_at(folder):
		if not file.ends_with(".svg"):
			continue
		var image := Image.new()
		if image.load_svg_from_string(FileAccess.get_file_as_string(folder.path_join(file)), 3.0) != OK:
			quit(1)
			return
		if image.save_png(out.path_join(file.get_basename()+".png")) != OK:
			quit(1)
			return
		print("REAR_RENDERED ", file)
	quit()
