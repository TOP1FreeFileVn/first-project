extends Node

const OUT := "res://docs/design/2026-10-19/bottom-wave"
var home: Control

func _ready() -> void:
	get_window().size = Vector2i(720, 1280)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	home = load("res://game/menu/Home.tscn").instantiate()
	add_child(home)
	home.select_tab(0, false)
	await capture("04-shop-current")
	var footer: PanelContainer = home.find_child("SelectedNavFooter", true, false)
	var image := Image.new()
	var result := image.load_svg_from_string(FileAccess.get_file_as_string(OUT + "/selected-footer-wave.svg"), 2.0)
	assert(result == OK)
	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(image)
	style.expand_margin_top = 8
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 0
	footer.add_theme_stylebox_override("panel", style)
	await capture("05-shop-footer-wave")
	print("SHOP_FOOTER_WAVE_PREVIEW_COMPLETE")
	get_tree().quit()

func capture(key: String) -> void:
	await get_tree().create_timer(0.3).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(OUT + "/" + key + ".png")
	assert(result == OK)
	print("SHOP_FOOTER_CAPTURE ", key)
