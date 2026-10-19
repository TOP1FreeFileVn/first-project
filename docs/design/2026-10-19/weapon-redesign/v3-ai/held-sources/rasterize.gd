extends SceneTree
func _initialize():
	for source in ["res://docs/design/2026-10-19/weapon-redesign/v3-ai/held-sources/cat_kiem.svg", "res://docs/design/2026-10-19/weapon-redesign/v3-ai/held-sources/cat_riu.svg", "res://docs/design/2026-10-19/weapon-redesign/v3-ai/held-sources/cat_sung.svg", "res://docs/design/2026-10-19/weapon-redesign/v3-ai/held-sources/cat_gay_phep.svg", "res://docs/design/2026-10-19/weapon-redesign/v3-ai/held-sources/front-paw.svg"]:
		var image := Image.new()
		assert(image.load_svg_from_string(FileAccess.get_file_as_string(source), 3.0) == OK)
		assert(image.save_png(source.replace(".svg", ".png")) == OK)
	print("V3_AI_CAT_SOURCES_RENDERED")
	quit()
