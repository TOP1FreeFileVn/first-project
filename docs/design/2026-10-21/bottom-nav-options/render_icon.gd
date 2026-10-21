extends SceneTree


func _initialize() -> void:
	var assets := {
		"icon_tab_shop": "icon-shop",
		"icon_tab_cat": "icon-hero",
		"icon_tab_battle": "icon-battle",
		"icon_tab_army": "icon-troops",
		"icon_tab_summon": "icon-summon",
	}
	for source in assets:
		var image := Image.new()
		var svg := FileAccess.get_file_as_string("res://game/ui/skin/%s.svg" % source)
		var result := image.load_svg_from_string(svg, 4.0)
		if result != OK:
			push_error("Unable to render existing SVG: %s" % source)
			quit(result)
			return
		result = image.save_png("res://docs/design/2026-10-21/bottom-nav-options/%s.png" % assets[source])
		if result != OK:
			quit(result)
			return
	quit(0)
