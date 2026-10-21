extends SceneTree

func _initialize() -> void:
	var source_path = "res://docs/design/2026-10-20/hero-equipment-v3/weapons/authored/bow-refined.svg"
	var svg = FileAccess.get_file_as_string(source_path)
	var image = Image.new()
	var error = image.load_svg_from_string(svg, 3.0)
	if error != OK:
		push_error("SVG parse failed: %s" % error)
		quit(1)
		return
	var out_path = "res://docs/design/2026-10-20/hero-equipment-v3/weapons/authored/bow-refined-layer.png"
	error = image.save_png(out_path)
	if error != OK:
		push_error("PNG save failed: %s" % error)
		quit(1)
		return
	print("Authored SVG exported: ", image.get_width(), "x", image.get_height())
	quit()
