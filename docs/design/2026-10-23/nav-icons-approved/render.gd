extends SceneTree

const ROOT := "res://docs/design/2026-10-23/nav-icons-approved/"

func _init() -> void:
	var jobs := [
		[ROOT + "hero-source.svg", ROOT + "hero.png", 1.0],
		[ROOT + "shop-original-source.svg", ROOT + "shop-original-full.png", 4.0],
		[ROOT + "shop-source.svg", ROOT + "shop-fish-full.png", 4.0],
	]
	for job in jobs:
		var im := Image.new()
		var supersample := 2.0 if str(job[0]).ends_with("hero-source.svg") else 1.0
		var error := im.load_svg_from_string(FileAccess.get_file_as_string(job[0]), job[2] * supersample)
		if error != OK:
			push_error("SVG render failed: " + str(job[0]))
			quit(1)
			return
		if supersample > 1.0:
			im.resize(im.get_width() / 2, im.get_height() / 2, Image.INTERPOLATE_LANCZOS)
		if im.save_png(job[1]) != OK:
			quit(1)
			return
	# Inspect the generated shared tab icons at their native dimensions too.
	DirAccess.make_dir_recursive_absolute(ROOT + "shared-tab-review/")
	for family in ["shop", "cat"]:
		for size in [32, 48, 64, 96, 128]:
			var suffix := "" if size == 128 else "_" + str(size)
			var path: String = "res://game/ui/skin/icon_tab_" + family + suffix + ".svg"
			var image := Image.new()
			if image.load_svg_from_string(FileAccess.get_file_as_string(path), 2.0) != OK:
				quit(1)
				return
			image.resize(size, size, Image.INTERPOLATE_LANCZOS)
			image.save_png(ROOT + "shared-tab-review/" + family + "-" + str(size) + ".png")
	print("Rendered approved helmet and original/fish shop sources.")
	quit()
