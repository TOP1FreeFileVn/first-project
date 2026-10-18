extends SceneTree

# Checks icon outlines across display sizes. For each icon, one row:
#   the 128 px art shrunk to 32 (old way) | the 32, 48, 64 px variants at native size | 128.
# Run: Godot --headless --path . --script res://tools/ui/preview_icon_sizes.gd -- OUT.png [ZOOM]

const SKIN := "res://game/ui/skin/"
const NAMES := ["coin", "gem", "heart", "star", "bolt", "gear", "chest", "lock", "close", "paw", "w_kiem", "w_cung", "w_giao", "w_no"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://icon_sizes.png"
	var zoom: int = int(args[1]) if args.size() > 1 else 2
	var cols := [[32, "_old32"], [32, "_32"], [48, "_48"], [64, "_64"], [128, ""]]
	var cell := 140
	var sheet := Image.create(cols.size() * cell, NAMES.size() * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("e9d6cc"))
	for r in NAMES.size():
		for c in cols.size():
			var size: int = cols[c][0]
			var suffix: String = cols[c][1]
			var img: Image
			if suffix == "_old32":
				img = (load(SKIN + "icon_%s.svg" % NAMES[r]) as Texture2D).get_image()
				img.decompress()
				img.resize(32, 32, Image.INTERPOLATE_LANCZOS)
			else:
				img = (load(SKIN + "icon_%s%s.svg" % [NAMES[r], suffix]) as Texture2D).get_image()
				img.decompress()
			img.convert(Image.FORMAT_RGBA8)
			if size < 128:
				img.resize(size * zoom, size * zoom, Image.INTERPOLATE_NEAREST)
			var at := Vector2i(c * cell + (cell - img.get_width()) / 2, r * cell + (cell - img.get_height()) / 2)
			sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), at)
	sheet.save_png(out)
	print("Saved ", out)
	quit()
