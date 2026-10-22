extends Node

## Review-only palette swap on the actual production Hero screen.
const HOME = preload("res://game/menu/Home.tscn")
const OUT := "res://docs/design/2026-10-23/weapon-frame-options/colors"
const SIZE := Vector2i(450, 800)
var _textures: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.path_join("context")))
	get_window().size = SIZE
	PlayerData.persist = false
	var save_before := _save_hash()
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false
	var home = HOME.instantiate()
	add_child(home)
	home.select_tab(home.HERO_TAB, false)
	await _settle()
	var page: Control = home._pages[home.HERO_TAB]
	var before := _content_snapshot(page)
	var records := _replace_frames(page)
	await _settle()
	var checks := {
		"actual_hero_page": page.get_script().resource_path == "res://game/menu/pages/HeroCatPage.gd" and page.visible,
		"fresh_profile": PlayerData.hero_cat.equipped.size() == 3 and PlayerData.hero_cat.bag.size() == 7,
		"seven_backgrounds_only": records.size() == 7,
		"art_and_labels_unchanged": before == _content_snapshot(page),
		"no_player_save_write": not PlayerData.persist and save_before == _save_hash(),
	}
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var filename := "context/natural-hero_450x800.png"
	checks["native_capture"] = image.get_size() == SIZE and image.save_png(OUT.path_join(filename)) == OK
	var file := FileAccess.open(OUT.path_join("context/review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "palette": "natural", "file": filename,
		"cards": records, "profile": OS.get_user_data_dir(), "save_before": save_before, "save_after": _save_hash(),
		"scope": "Only equipment-card backgrounds replaced in-memory. Empty slots, all art, metadata, layout and production files unchanged."}, "\t"))
	file.close()
	print("CONTEXT_COLORS_COMPLETE checks=", checks.size(), " failures=", checks.values().count(false))
	get_tree().quit(1 if checks.values().has(false) else 0)


func _replace_frames(page: Node) -> Array:
	var records: Array = []
	for art: TextureRect in page.find_children("EquipmentArt", "TextureRect", true, false):
		var card: Control = art.get_parent()
		var panel: PanelContainer = card.get_child(0)
		var tone := str(panel.theme_type_variation).trim_prefix("CardUnit").to_lower()
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var face := TextureRect.new()
		face.name = "ReviewFrameBackground"
		face.texture = _texture(tone)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_SCALE
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(face)
		card.move_child(face, 0)
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		records.append({"tone": tone, "svg": "svg/natural-%s.svg" % tone,
			"art": art.texture.resource_path, "card_rect": _rect(card.get_global_rect()),
			"art_rect": _rect(art.get_global_rect())})
	return records


func _texture(tone: String) -> Texture2D:
	if not _textures.has(tone):
		var image := Image.new()
		var error := image.load_svg_from_string(FileAccess.get_file_as_string(OUT.path_join("svg/natural-" + tone + ".svg")), 3.0)
		assert(error == OK)
		_textures[tone] = ImageTexture.create_from_image(image)
	return _textures[tone]


func _content_snapshot(page: Node) -> Array:
	var records: Array = []
	for node: Control in page.find_children("*", "Control", true, false):
		if node.name in ["EquipmentArt", "SlotBadge", "EquipmentLevel", "EquipmentUpgrade", "EmptyEquipmentSymbol"]:
			var texture_path: String = node.texture.resource_path if node is TextureRect and node.texture != null else ""
			records.append({"name": str(node.name), "rect": _rect(node.get_global_rect()), "texture": texture_path,
				"text": node.text if node is Label else "", "scale": [node.scale.x, node.scale.y], "rotation": node.rotation})
	return records


func _settle() -> void:
	await get_tree().create_timer(0.24).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _rect(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _save_hash() -> String:
	return FileAccess.get_sha256(PlayerData.SAVE_PATH) if FileAccess.file_exists(PlayerData.SAVE_PATH) else "absent"
