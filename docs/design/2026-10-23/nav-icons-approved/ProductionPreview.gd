extends Node

const Nav := preload("res://game/ui/CartonNav.gd")
const OUT := "res://docs/design/2026-10-23/nav-icons-approved/context/"
const TABS := [["tab_shop", "Cửa hàng"], ["tab_cat", "Anh hùng"], ["tab_battle", "Chiến"], ["tab_army", "Lính"], ["tab_summon", "Triệu hồi"]]

func _ready() -> void:
	PlayerData.persist = false
	PlayerData.sound_on = false
	DirAccess.make_dir_recursive_absolute(OUT)
	for width in [720, 360]:
		var factor := float(width) / 720.0
		var viewport := SubViewport.new()
		viewport.size = Vector2i(width, roundi(220 * factor))
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var back := ColorRect.new()
		back.color = Color("eee4d2")
		back.size = viewport.size
		viewport.add_child(back)
		var nav := Nav.new()
		# No icon injection: these are the actual production preloads.
		nav.configure(TABS, 0, [])
		nav.position = Vector2(0, 12 * factor)
		nav.size = Vector2(width, 204 * factor)
		viewport.add_child(nav)
		for index in 3:
			nav.set_selected(index, false)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png(OUT + "%d-%d.png" % [width, index])
		viewport.queue_free()
		await get_tree().process_frame
	print("ProductionPreview: 6 native default-icon captures at 360/720 widths; no save writes.")
	get_tree().quit()
