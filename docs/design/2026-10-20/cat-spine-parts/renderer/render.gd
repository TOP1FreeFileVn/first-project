extends SceneTree

func render_file(source: String, destination: String) -> bool:
	var image := Image.new()
	if image.load_svg_from_string(FileAccess.get_file_as_string(source), 3.0) != OK:
		push_error("Failed SVG: " + source)
		return false
	return image.save_png(destination) == OK

func _initialize() -> void:
	var folder := ProjectSettings.globalize_path("res://..").simplify_path()
	var project := folder.path_join("../../../..").simplify_path()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("manifest.json")))
	for cat: String in data.cats:
		var source_dir := folder.path_join(data.cats[cat].directory)
		var out := folder.path_join("png").path_join(cat)
		DirAccess.make_dir_recursive_absolute(out)
		if not render_file(project.path_join(data.cats[cat].source), out.path_join("original.png")):
			quit(1)
			return
		for asset: String in DirAccess.get_files_at(source_dir):
			if asset.ends_with(".svg") and not render_file(source_dir.path_join(asset), out.path_join(asset.get_basename()+".png")):
				quit(1)
				return
		print("RENDERED ", cat)
	quit()
