extends SceneTree

# Lays every imported skin SVG out on one sheet so the art can be checked without opening
# each file. Run: Godot --headless --path . --script res://tools/ui/preview_skin.gd -- OUT.png [PREFIX]
# PREFIX keeps only files starting with it (e.g. icon_w_ for the weapons).

const SKIN := "res://game/ui/skin/"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://skin_preview.png"
	var prefix: String = args[1] if args.size() > 1 else ""
	var files: Array[String] = []
	for f in DirAccess.get_files_at(SKIN):
		if f.ends_with(".svg") and f.begins_with(prefix):
			files.append(f)
	files.sort()
	var cell := 180
	var cols := 8
	var sheet := Image.create(cols * cell, int(ceil(files.size() / float(cols))) * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("e9d6cc"))
	for i in files.size():
		var tex: Texture2D = load(SKIN + files[i])
		var img := tex.get_image()
		img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		var scale := minf(1.0, float(cell - 12) / maxf(img.get_width(), img.get_height()))
		if scale < 1.0:
			img.resize(int(img.get_width() * scale), int(img.get_height() * scale), Image.INTERPOLATE_LANCZOS)
		var at := Vector2i((i % cols) * cell + (cell - img.get_width()) / 2, (i / cols) * cell + (cell - img.get_height()) / 2)
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), at)
	sheet.save_png(out)
	print("Saved ", out)
	quit()
