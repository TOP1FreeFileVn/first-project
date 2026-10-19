extends Node

# Proposal textures are injected only into this disposable preview's RAM cache.
const OUT := "res://docs/design/2026-10-19/weapon-redesign/v1"
const HomeScene = preload("res://game/menu/Home.tscn")
var _home: Control
var _shots: Array = []

func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 4
	for id in PlayerData.TROOP_ORDER:
		PlayerData.troops[id]["unlocked"] = true
		PlayerData.troops[id]["level"] = 6
		PlayerData.troops[id]["stars"] = 1 + PlayerData.rarity_of(id)
		PlayerData.troops[id]["cards"] = 0
	PlayerData.team = ["kiem", "cung", "gay_phep", "giao"]
	get_window().size = Vector2i(450, 800)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "/rendered"))
	var assets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "/assets.json"))
	for item in assets.items:
		var id: String = item.id
		for variant in ["old", "new"]:
			var source := "res://game/ui/skin" if variant == "old" else OUT
			var icon_path := source + "/icon_w_" + id + ".svg" if variant == "old" else source + "/weapons/icon_w_" + id + "_256.svg"
			var unit_path := source + "/unit_" + id + ".svg" if variant == "old" else source + "/units/unit_" + id + ".svg"
			var icon := _svg(icon_path)
			if icon.get_width() != 256:
				icon.resize(256, 256, Image.INTERPOLATE_LANCZOS)
			assert(icon.save_png(OUT + "/rendered/" + variant + "_icon_" + id + ".png") == OK)
			assert(_svg(unit_path, 2.0).save_png(OUT + "/rendered/" + variant + "_unit_" + id + ".png") == OK)
		assert(_svg(OUT + "/weapons/icon_w_" + id + "_64.svg").save_png(OUT + "/rendered/new_64_" + id + ".png") == OK)
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.SHOP_TAB, false)
	await _settle()
	assert(_home.find_child("ShopSign", true, false) == null, "Shop title must be removed")
	assert(is_equal_approx(_home._header.position.y, 104.0))
	await _capture("shop_without_title_450x800")
	_home.select_tab(_home.TROOPS_TAB, false)
	await _settle()
	var page: Control = _home._pages[_home.TROOPS_TAB]
	for tween in get_tree().get_processed_tweens():
		tween.pause()
	_home.process_mode = Node.PROCESS_MODE_DISABLED
	var sky := _home._sky_backdrop.material as ShaderMaterial
	sky.set_shader_parameter("motion_speed", 0.0)
	sky.set_shader_parameter("time_offset", 5.0)
	await _capture("troops_before_450x800")
	for item in assets.items:
		var image := _svg(OUT + "/units/unit_" + str(item.id) + ".svg")
		image.resize(SpriteLib.ART_SIZE.x, SpriteLib.ART_SIZE.y, Image.INTERPOLATE_LANCZOS)
		SpriteLib._textures["tex/art:" + str(item.id)] = ImageTexture.create_from_image(image)
	page.refresh()
	await _settle()
	await _capture("troops_proposal_top_450x800")
	page._scroll.scroll_vertical = int(page._scroll.get_v_scroll_bar().max_value)
	await _settle()
	await _capture("troops_proposal_bottom_450x800")
	get_window().size = Vector2i(360, 640)
	await _settle()
	await _capture("troops_proposal_bottom_360x640")
	var manifest := FileAccess.open(OUT + "/runtime.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"status": "awaiting_review", "persist": PlayerData.persist,
		"proposal_in_ram_only": true, "weapons": assets.items.size(), "captures": _shots}, "\t"))
	manifest.close()
	print("WEAPON_REVIEW_COMPLETE 16 weapons; 5 native captures; production weapon art unchanged")
	get_tree().quit()

func _svg(path: String, scale := 1.0) -> Image:
	var image := Image.new()
	assert(image.load_svg_from_string(FileAccess.get_file_as_string(path), scale) == OK, path)
	return image

func _settle() -> void:
	await get_tree().create_timer(0.22).timeout
	await get_tree().process_frame

func _capture(key: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image.get_size() == get_window().size)
	assert(image.save_png(OUT + "/" + key + ".png") == OK)
	_shots.append({"file": key + ".png", "size": [image.get_width(), image.get_height()]})
	print("WEAPON_REVIEW_CAPTURE ", key)
