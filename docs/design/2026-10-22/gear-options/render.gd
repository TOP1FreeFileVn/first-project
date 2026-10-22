extends SceneTree

const BASE := "res://docs/design/2026-10-22/gear-options"

func _init() -> void:
	var out := BASE.path_join("godot")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var sheet := Image.create(768, 128, false, Image.FORMAT_RGBA8)
	var results := {}
	var index := 0
	for id in ["A", "B", "C", "D", "E", "F"]:
		var source := FileAccess.get_file_as_string(BASE.path_join("svg/" + id + ".svg"))
		var image := Image.new()
		var error := image.load_svg_from_string(source, 2.0)
		if error != OK:
			push_error("Cannot render gear " + id)
			quit(1)
			return
		image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		image.save_png(out.path_join(id + ".png"))
		sheet.blit_rect(image, Rect2i(0, 0, 128, 128), Vector2i(index * 128, 0))
		results[id] = {"size": [128, 128], "renderer": "Godot SVG rasterizer"}
		index += 1
	sheet.save_png(out.path_join("silhouettes.png"))
	var file := FileAccess.open(out.path_join("render.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	print("Rendered all six gear proposals; production untouched.")
	quit()
