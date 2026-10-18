extends SceneTree

# Render a local SVG directly, without editor imports or a window.
# Godot --headless --path . --script res://tools/ui/render_svg_png.gd -- INPUT.svg OUTPUT.png
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("Expected INPUT.svg OUTPUT.png")
		quit(1)
		return
	var content := FileAccess.get_file_as_string(args[0])
	var image := Image.new()
	var result := image.load_svg_from_string(content, 2.0)
	if result != OK:
		push_error("SVG render failed: %s" % result)
		quit(1)
		return
	image.resize(image.get_width() / 2, image.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	result = image.save_png(args[1])
	if result != OK:
		push_error("PNG save failed: %s" % result)
		quit(1)
		return
	print("Saved ", args[1])
	quit()
