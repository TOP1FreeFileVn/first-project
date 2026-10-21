extends SceneTree
func _initialize() -> void:
	var folder := ProjectSettings.globalize_path("res://..").simplify_path()
	var svg := FileAccess.get_file_as_string(folder + "/staff-refined.svg")
	var im := Image.new()
	if im.load_svg_from_string(svg, 3.0) != OK:
		quit(1)
		return
	im.save_png(folder + "/processed/staff-refined-layer.png")
	im.resize(256, 240, Image.INTERPOLATE_LANCZOS)
	im.save_png(folder + "/processed/staff-refined-native.png")
	print("STAFF_RENDER_OK")
	quit()
