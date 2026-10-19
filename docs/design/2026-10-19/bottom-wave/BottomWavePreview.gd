extends Node

# Disposable review only: production UI and saved player progress are untouched.
const Ui = preload("res://game/ui/Ui.gd")
const OUT := "res://docs/design/2026-10-19/bottom-wave"
var home: Control

func _ready() -> void:
	get_window().size = Vector2i(720, 1280)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	PlayerData.castle_level = 3
	home = load("res://game/menu/Home.tscn").instantiate()
	add_child(home)
	home.select_tab(2, false)
	await capture("00-current")
	var footer: PanelContainer = home.find_child("SelectedNavFooter", true, false)
	var style := StyleBoxTexture.new()
	style.texture = svg_texture("selected-footer-wave.svg")
	style.expand_margin_top = 8
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 0
	footer.add_theme_stylebox_override("panel", style)
	await capture("01-footer-wave")
	home._nav_holder.hide()
	var dock := build_dock()
	home.add_child(dock)
	await capture("02-dock-wave")
	home.open_page(load("res://game/menu/pages/CastlePage.gd"))
	await capture("03-castle-dock-wave")
	print("BOTTOM_WAVE_PREVIEW_COMPLETE")
	get_tree().quit()

func svg_texture(file_name: String) -> ImageTexture:
	var image := Image.new()
	var result := image.load_svg_from_string(FileAccess.get_file_as_string(OUT + "/" + file_name), 2.0)
	assert(result == OK)
	return ImageTexture.create_from_image(image)

func build_dock() -> Control:
	var root := Control.new()
	root.name = "BottomWaveDraft"
	root.position = Vector2(0, 1112)
	root.size = Vector2(720, 168)
	root.theme = Ui.THEME
	root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var bg := TextureRect.new()
	bg.texture = svg_texture("dock-wave.svg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size = root.size
	root.add_child(bg)
	var names := ["tab_shop", "tab_cat", "tab_battle", "tab_army", "tab_summon"]
	for i in range(5):
		var selected := i == 2
		var icon_size := 102.0 if selected else 88.0
		var ic := Ui.icon(names[i], icon_size)
		ic.position = Vector2(72 + i * 144 - icon_size / 2, 17 if selected else 52)
		root.add_child(ic)
		if i in [0, 1, 3]:
			Ui.dot(ic, Vector2(-14, 0))
	var caption := Ui.label("Chiến", "LabelDark", 24)
	caption.add_theme_color_override("font_color", Color("583f21"))
	caption.add_theme_constant_override("outline_size", 0)
	caption.position = Vector2(276, 130)
	caption.size = Vector2(168, 36)
	root.add_child(caption)
	return root

func capture(key: String) -> void:
	await get_tree().create_timer(0.3).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(OUT + "/" + key + ".png")
	assert(result == OK)
	print("BOTTOM_WAVE_CAPTURE ", key)
