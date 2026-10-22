extends SceneTree

func _init() -> void:
	var out := "res://docs/design/2026-10-23/hero-slot-symbols/godot"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for slot in ["weapon", "helmet", "armor", "boots"]:
		for size in [32, 48, 64, 96]:
			var filename := "icon_slot_%s_%d" % [slot, size]
			var svg := FileAccess.get_file_as_string("res://game/ui/art/" + filename + ".svg")
			var image := Image.new()
			if image.load_svg_from_string(svg, 2.0) != OK:
				quit(1)
				return
			image.resize(size, size, Image.INTERPOLATE_LANCZOS)
			image.save_png(out.path_join(filename + ".png"))
	print("Rendered16 native equipment-slot symbols.")
	quit()
