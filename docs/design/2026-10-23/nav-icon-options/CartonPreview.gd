extends Node

## Reuse the production control; change only its injected icon textures.
const CartonNav := preload("res://game/ui/CartonNav.gd")
const ROOT := "res://docs/design/2026-10-23/nav-icon-options/"
const TABS := [["tab_shop", "Cửa hàng"], ["tab_cat", "Anh hùng"], ["tab_battle", "Chiến"], ["tab_army", "Lính"], ["tab_summon", "Triệu hồi"]]

func _ready() -> void:
	PlayerData.persist = false
	PlayerData.sound_on = false
	DirAccess.make_dir_recursive_absolute(ROOT + "context/")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 220)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var back := ColorRect.new()
	back.color = Color("eee4d2")
	back.size = Vector2(720, 220)
	viewport.add_child(back)
	for id in ["A", "B", "C", "D"]:
		var icons: Array[Texture2D] = []
		for key in ["shop", "hero", "battle"]:
			var im := Image.new()
			if im.load_svg_from_string(FileAccess.get_file_as_string(ROOT + "svg/" + id + "-" + key + "-200.svg"), 2.0) != OK:
				get_tree().quit(1)
				return
			im.generate_mipmaps()
			icons.append(ImageTexture.create_from_image(im))
		icons.append(CartonNav.DEFAULT_ICONS[3])
		icons.append(CartonNav.DEFAULT_ICONS[4])
		var nav := CartonNav.new()
		nav.configure(TABS, 0, [], icons)
		nav.position = Vector2(0, 12)
		nav.size = Vector2(720, 204)
		viewport.add_child(nav)
		for active in 3:
			nav.set_selected(active, false)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var capture := viewport.get_texture().get_image()
			capture.save_png(ROOT + "context/" + id + "-" + str(active) + ".png")
		nav.queue_free()
		await get_tree().process_frame
	print("CartonPreview: 12 production-control captures; production icons unchanged; save writes disabled.")
	get_tree().quit()
