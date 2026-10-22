extends SceneTree

# Rasterize the six production SVG files directly. No editor import or game save.
const BASE := "res://docs/design/2026-10-22/gear-options/godot"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASE))
	var sheet := Image.create(768, 128, false, Image.FORMAT_RGBA8)
	var results := {}
	var index := 0
	for tone in ["tier_1", "tier_2", "tier_3", "tier_4", "tier_5", "idle"]:
		var source_path: String = "res://game/ui/skin/battle_cog_%s.svg" % tone
		var image := Image.new()
		var error := image.load_svg_from_string(FileAccess.get_file_as_string(source_path), 2.0)
		if error != OK:
			push_error("Cannot rasterize production B gear: " + tone)
			quit(1)
			return
		image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		image.save_png(BASE.path_join("B-production-" + tone + ".png"))
		sheet.blit_rect(image, Rect2i(0, 0, 128, 128), Vector2i(index * 128, 0))
		results[tone] = {"source": source_path, "size": [128, 128], "renderer": "Godot SVG rasterizer"}
		index += 1
	sheet.save_png(BASE.path_join("B-production-palette-raw.png"))
	var file := FileAccess.open(BASE.path_join("B-production-palette-render.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	print("Rendered all six production B palette SVGs without editor import.")
	quit()
