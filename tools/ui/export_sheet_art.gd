extends SceneTree

# Renders the sprites listed in tools/ui/sheet_art.txt ("<sheet id> <skin svg name>" per line)
# to docs/sheet_art/<sheet id>.png, 160 px wide, for the design sheet's image column
# (tab "Lính · Quái · Trang bị (ảnh)": Insert → Image → Image in cell).
# Run: Godot --headless --path . --script res://tools/ui/export_sheet_art.gd

const WIDTH := 160.0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/sheet_art"))
	var count := 0
	for line in FileAccess.get_file_as_string("res://tools/ui/sheet_art.txt").split("\n", false):
		var parts := line.strip_edges().split(" ")
		var svg := FileAccess.get_file_as_bytes("res://game/ui/skin/%s.svg" % parts[1])
		var probe := Image.new()
		probe.load_svg_from_buffer(svg, 1.0)
		var image := Image.new()
		image.load_svg_from_buffer(svg, WIDTH / probe.get_width())
		image.save_png("res://docs/sheet_art/%s.png" % parts[0])
		count += 1
	print("Saved %d PNGs to docs/sheet_art" % count)
	quit()
