extends SceneTree


func _initialize() -> void:
	var assets := {
		"icon_chest_96": "chest",
		"btn_yellow": "button-yellow-source",
		"btn_red": "button-red-source",
		"icon_back_32": "back-icon",
	}
	for source in assets:
		var image := Image.new()
		var svg := FileAccess.get_file_as_string("res://game/ui/skin/%s.svg" % source)
		var result := image.load_svg_from_string(svg, 2.0)
		if result != OK:
			push_error("Unable to render existing SVG: %s" % source)
			quit(result)
			return
		result = image.save_png("res://docs/design/2026-10-21/menu-frame-proposal/%s.png" % assets[source])
		if result != OK:
			quit(result)
			return
	quit(0)
