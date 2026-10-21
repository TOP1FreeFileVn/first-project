extends SceneTree

func _initialize() -> void:
	var folder := ProjectSettings.globalize_path("res://..").simplify_path()
	var project := folder.path_join("../../../..").simplify_path()
	var out := folder.path_join("processed")
	DirAccess.make_dir_recursive_absolute(out)
	for asset: String in ["cat_cream", "cat_tabby", "cat_calico"]:
		var source := FileAccess.get_file_as_string(project + "/game/ui/skin/" + asset + ".svg")
		var image := Image.new()
		if image.load_svg_from_string(source, 1.0) != OK:
			quit(1)
			return
		if image.save_png(out + "/" + asset + ".png") != OK:
			quit(1)
			return
		print("LOBBY_RESIDENT_RENDERED ", asset, " ", image.get_size())
	quit()
