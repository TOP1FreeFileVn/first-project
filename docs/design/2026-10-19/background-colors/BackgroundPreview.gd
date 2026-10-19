extends Node

# Native runtime color study only; production art, scripts, and saves stay unchanged.
const Ui = preload("res://game/ui/Ui.gd")
const OUT := "res://docs/design/2026-10-19/background-colors"
const STUDIES := [
	["current", "6fa3e0", 1.0],
	["blue-gray", "9bb5c4", 0.3125],
	["sage", "a0b8a3", 0.25],
]
var home: Control
var backdrop: ColorRect

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
	PlayerData.troops["kiem"]["level"] = 6
	PlayerData.troops["kiem"]["cards"] = 12
	for id: String in ["giao", "dai_bac", "katana", "riu"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "katana"]
	home = load("res://game/menu/Home.tscn").instantiate()
	add_child(home)
	backdrop = home.get_child(0) as ColorRect
	assert(backdrop != null and backdrop.material is ShaderMaterial)
	var mat := backdrop.material as ShaderMaterial
	mat.set_shader_parameter("speed", Vector2.ZERO)
	for study: Array in STUDIES:
		mat.set_shader_parameter("sky", Color(study[1]))
		mat.set_shader_parameter("tile", faded_tile(study[2]))
		for page: Array in [[2, "lobby"], [3, "troops"], [0, "shop"]]:
			home.select_tab(page[0], false)
			await capture(study[0] + "-" + page[1])
	print("BACKGROUND_PREVIEW_COMPLETE")
	get_tree().quit()

func faded_tile(factor: float) -> ImageTexture:
	var image := Ui.tex("bg_tile").get_image()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			pixel.a *= factor
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

func capture(key: String) -> void:
	await get_tree().create_timer(0.2).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(OUT + "/" + key + ".png")
	assert(result == OK)
	print("BACKGROUND_CAPTURE ", key)
