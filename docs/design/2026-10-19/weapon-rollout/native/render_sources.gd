extends SceneTree

const KEYS := [
	"kiem", "riu", "dao", "katana", "cung", "no", "sung", "dai_bac",
	"gay_phep", "thuoc", "sach_phep", "dua_phep", "giao", "cu_kiem", "chuy", "bua",
]


func _initialize() -> void:
	var folder := ProjectSettings.globalize_path("res://docs/design/2026-10-19/weapon-rollout/sources")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sources-dir="):
			folder = arg.trim_prefix("--sources-dir=").replace("\\", "/")
	var files: Array[String] = []
	for key in KEYS:
		files.append("cat_" + key)
	files.append("front-paw")
	for key in files:
		var path := folder.path_join(key)
		var image := Image.new()
		assert(image.load_svg_from_string(FileAccess.get_file_as_string(path + ".svg"), 3.0) == OK, key)
		assert(image.get_size() == Vector2i(768, 720), key)
		assert(image.save_png(path + ".png") == OK, key)
		print("UNARMED_NINE_PX_RENDERED ", key, " ", image.get_size())
	print("UNARMED_NINE_PX_RENDER_COMPLETE ", files.size())
	quit()
