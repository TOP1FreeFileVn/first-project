extends Node

## Run after the normal editor import:
## godot --headless --path . res://tools/ui/verify_currency_art.tscn
## Checks the production loader, including its size selection and plural aliases.
## Run as a scene so Ui's normal autoload dependencies initialize first.
const Ui = preload("res://game/ui/Ui.gd")
const OUTPUT := "res://output/currency-art-qa/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var checked := 0
	for icon_name in ["coin", "coins", "gem", "gems", "power"]:
		for requested_size in [24, 32, 48, 64, 96, 128]:
			var native_size: int = 32 if requested_size <= 32 else requested_size
			var suffix := "" if native_size == 128 else "_%d" % native_size
			var expected := "res://game/ui/art/icon_%s%s.svg" % [icon_name, suffix]
			var texture: Texture2D = Ui.icon_tex(icon_name, requested_size)
			if texture == null or texture.resource_path != expected:
				push_error("Accepted art loader mismatch: %s at %d; expected %s" % [icon_name, requested_size, expected])
				get_tree().quit(1)
				return
			if texture.get_width() != native_size or texture.get_height() != native_size:
				push_error("Accepted art viewport mismatch: " + expected)
				get_tree().quit(1)
				return
			var raster := texture.get_image()
			if raster == null or raster.get_used_rect().size == Vector2i.ZERO:
				push_error("Accepted art raster is empty: " + expected)
				get_tree().quit(1)
				return
			if icon_name in ["coin", "gem", "power"] and requested_size in [24, 32, 48]:
				if requested_size != native_size:
					raster.resize(requested_size, requested_size, Image.INTERPOLATE_LANCZOS)
				if raster.save_png(OUTPUT + "%s-%d.png" % [icon_name, requested_size]) != OK:
					push_error("Could not save native art review: " + icon_name)
					get_tree().quit(1)
					return
			checked += 1
	print("APPROVED_CURRENCY_NATIVE_OK: %d loader checks; 9 review PNGs" % checked)
	get_tree().quit()
