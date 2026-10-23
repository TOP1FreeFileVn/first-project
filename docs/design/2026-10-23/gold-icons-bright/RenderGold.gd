extends SceneTree

func _init() -> void:
	var base := "res://docs/design/2026-10-23/gold-icons-bright/"
	DirAccess.make_dir_recursive_absolute(base + "godot")
	for kind in ["classic", "tilted", "stack"]:
		for size in [24, 32]:
			var name := "gold-%s-%d" % [kind, size]
			var svg := FileAccess.get_file_as_string(base + "svg/" + name + ".svg")
			var raster := Image.new()
			if raster.load_svg_from_string(svg, 2.0) != OK:
				push_error("Gold SVG render failed: " + name)
				quit(1)
				return
			raster.resize(size, size, Image.INTERPOLATE_LANCZOS)
			if raster.save_png(base + "godot/" + name + ".png") != OK:
				quit(1)
				return
	print("BRIGHT_GOLD_NATIVE_RENDER_OK: 3 variants at24/32px")
	quit()
