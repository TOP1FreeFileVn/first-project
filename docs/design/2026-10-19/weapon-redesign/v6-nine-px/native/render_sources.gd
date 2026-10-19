extends SceneTree

func _initialize() -> void:
	var folder := ProjectSettings.globalize_path("res://..").simplify_path()
	for key in ["cat_kiem","front-paw"]:
		var image := Image.new()
		assert(image.load_svg_from_string(FileAccess.get_file_as_string(folder+"/sources/"+key+".svg"),3.0)==OK)
		assert(image.save_png(folder+"/sources/"+key+".png")==OK)
	print("CAT_STROKE_SOURCES_RENDERED")
	quit()
