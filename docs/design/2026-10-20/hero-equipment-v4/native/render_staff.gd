extends SceneTree
func _initialize() -> void:
	var folder := ProjectSettings.globalize_path("res://..").simplify_path()
	var im := Image.new()
	if im.load_svg_from_string(FileAccess.get_file_as_string(folder + "/staff/staff-right.svg"), 3.0) != OK:
		quit(1)
		return
	im.save_png(folder + "/staff/staff-right-layer-original-tone.png")
	print("STAFF_V4_RENDER_OK")
	quit()
