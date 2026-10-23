extends SceneTree

func _init() -> void:
	var base := "res://docs/design/2026-10-23/diamond-icons/"
	DirAccess.make_dir_recursive_absolute(base + "godot")
	for kind in ["brilliant", "cushion", "crystal"]:
		for size in [24, 32]:
			var name := "diamond-%s-%d" % [kind, size]
			var svg := FileAccess.get_file_as_string(base + "svg/" + name + ".svg")
			var raster := Image.new()
			var error := raster.load_svg_from_string(svg, 2.0)
			if error != OK:
				push_error("Diamond SVG render failed: " + name)
				quit(1)
				return
			raster.resize(size, size, Image.INTERPOLATE_LANCZOS)
			if raster.save_png(base + "godot/" + name + ".png") != OK:
				quit(1)
				return
	print("DIAMOND_NATIVE_RENDER_OK: 3 variants at 24px and 32px")
	quit()
