extends Node

# An isolated art study, or a live preview of the current production menu.
const OUT := "res://docs/design/2026-10-19/sky-islands-demo"
@export var live_preview := false
var home: Control
var original_backdrop: ColorRect

func _ready() -> void:
	get_window().size = Vector2i(450, 800) if live_preview else Vector2i(720, 1280)
	if live_preview:
		get_window().title = "Gear Defenders - Animated Sky"
		call_deferred("_show_live_window")
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 100003377
	PlayerData.gems = 9997469
	PlayerData.cheated = true
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	PlayerData.castle_level = 3
	PlayerData.troops["kiem"]["level"] = 6
	PlayerData.troops["kiem"]["cards"] = 12
	for id: String in ["giao", "dai_bac", "katana", "riu"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "katana"]
	home = load("res://game/menu/Home.tscn").instantiate()
	add_child(home)
	home.select_tab(2, false)
	if live_preview:
		# Keep the production sky layers and shop pattern active in the live demo.
		print("SKY_ISLANDS_LIVE_READY")
		return
	original_backdrop = home.get_child(0) as ColorRect
	assert(original_backdrop != null and original_backdrop.material is ShaderMaterial)
	(original_backdrop.material as ShaderMaterial).set_shader_parameter("motion_speed", 0.0)
	(original_backdrop.material as ShaderMaterial).set_shader_parameter("time_offset", 0.0)
	await get_tree().create_timer(0.3).timeout
	# Freeze the same native UI pose for both captures.
	for tween: Tween in get_tree().get_processed_tweens():
		tween.pause()
	await capture("current")
	var image := Image.new()
	var error := image.load_svg_from_string(FileAccess.get_file_as_string(OUT + "/background.svg"))
	assert(error == OK, "The background demo SVG must exist and render.")
	var proposed := TextureRect.new()
	proposed.name = "SkyIslandsDemoBackground"
	proposed.texture = ImageTexture.create_from_image(image)
	proposed.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	proposed.stretch_mode = TextureRect.STRETCH_SCALE
	proposed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home.add_child(proposed)
	home.move_child(proposed, 0)
	proposed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	original_backdrop.visible = false
	await capture("demo")
	print("SKY_ISLANDS_DEMO_COMPLETE")
	get_tree().quit()

func _show_live_window() -> void:
	var window := get_window()
	window.mode = Window.MODE_WINDOWED
	window.current_screen = DisplayServer.get_primary_screen()
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var available := Vector2(maxi(1, usable.size.x - 32), maxi(1, usable.size.y - 64))
	var fit := minf(1.0, minf(available.x / 450.0, available.y / 800.0))
	window.size = Vector2i(Vector2(450, 800) * fit)
	window.position = usable.position + Vector2i((Vector2(usable.size) - Vector2(window.size)) * 0.5)
	window.show()
	window.grab_focus()

func capture(key: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(OUT + "/" + key + ".png")
	assert(error == OK)
	print("SKY_ISLANDS_CAPTURE ", key)
