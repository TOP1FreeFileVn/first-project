extends Node

## Review only: runtime overrides on the real Hero screen; never saves a profile.
const HOME = preload("res://game/menu/Home.tscn")
const HOME_SCRIPT = preload("res://game/menu/Home.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const Ui = preload("res://game/ui/Ui.gd")
const OUT := "res://docs/design/2026-10-23/equipment-badge-demo"
const WORN := ["kiem_go", "mu_hiep_si", "giap_rong", "giay_gio"]
var _home
var _page
var _measurements: Array = []
var _out := OUT
var _boots_source: Texture2D


func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-directory="):
			_out = argument.trim_prefix("--output-directory=")
		elif argument.begins_with("--boots-glyph="):
			var glyph := Image.new()
			var error := glyph.load_svg_from_string(FileAccess.get_file_as_string(argument.trim_prefix("--boots-glyph=")))
			if error != OK:
				push_error("Could not render review boots glyph")
				get_tree().quit(1)
				return
			_boots_source = ImageTexture.create_from_image(glyph)
	var original: Dictionary = PlayerData.to_dict().duplicate(true)
	var original_persist: bool = PlayerData.persist
	var original_tab: int = HOME_SCRIPT.last_tab
	PlayerData.persist = false
	PlayerData.tutorial_done = true
	var state := {"equipped": {}, "bag": {}, "retired_items": {}, "next": 1}
	for id in HeroCat.ITEMS:
		var uid := HeroCat.add_item(state, id)
		if WORN.has(id):
			state.equipped[HeroCat.ITEMS[id].slot] = uid
	PlayerData.hero_cat = state
	PlayerData.gold = 50000
	for dimensions in [Vector2i(360, 640), Vector2i(450, 800), Vector2i(720, 1280)]:
		get_window().size = dimensions
		HOME_SCRIPT.last_tab = HOME_SCRIPT.HERO_TAB
		_home = HOME.instantiate()
		add_child(_home)
		await _settle()
		_page = _home._pages[_home.HERO_TAB]
		_pad_inventory()
		await _settle()
		_center_badges()
		await _settle()
		await RenderingServer.frame_post_draw
		var capture := get_viewport().get_texture().get_image()
		capture.save_png(_out.path_join("demo_%dx%d.png" % [dimensions.x, dimensions.y]))
		if dimensions.x == 720:
			for slot in HeroCat.SLOTS:
				var uid := HeroCat.equipped_uid(state, slot)
				for art in _page.find_children("EquipmentArt", "TextureRect", true, false):
					var card: Control = art.get_parent()
					if card.get_meta("equipment_uid", "") == uid:
						var rect := card.get_global_rect().grow(12)
						capture.get_region(Rect2i(rect)).save_png(_out.path_join("card_" + slot + ".png"))
		_home.queue_free()
		await get_tree().process_frame
	PlayerData.from_dict(original)
	PlayerData.persist = original_persist
	HOME_SCRIPT.last_tab = original_tab
	var report := FileAccess.open(_out.path_join("geometry.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({"scope": "Review-only runtime overrides; no production changes or save writes", "badge_overhang": 8, "measurements": _measurements}, "\t"))
	report.close()
	print("BADGE_PREVIEW_COMPLETE")
	get_tree().quit()


func _pad_inventory() -> void:
	var grid := _page.find_child("HeroInventoryGrid", true, false) as GridContainer
	if grid == null:
		return
	var scroll := grid.get_parent()
	scroll.remove_child(grid)
	# The overhang remains visible even on the first row/column of the scroll.
	var edge := Ui.margin(8, 8, 8, 8)
	edge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	edge.add_child(grid)
	scroll.add_child(edge)


func _center_badges() -> void:
	for frame in _page.find_children("EquipmentCategoryBadge", "PanelContainer", true, false):
		var card: Control = frame.get_parent()
		var badge: TextureRect = card.get_node("SlotBadge")
		var uid: String = card.get_meta("equipment_uid")
		var item := HeroCat.def(PlayerData.hero_cat, uid)
		var source := Ui.tex("icon_" + HeroCat.SLOT_ICONS[item.slot])
		if item.slot == "boots" and _boots_source != null:
			source = _boots_source
		var bounds := source.get_image().get_used_rect()
		if not bounds.has_area():
			continue
		var cropped := AtlasTexture.new()
		cropped.atlas = source
		cropped.region = bounds
		cropped.filter_clip = true
		badge.texture = cropped
		frame.position = Vector2(-8, -8)
		var glyph_size: float = frame.size.x - 12.0
		badge.custom_minimum_size = Vector2.ONE * glyph_size
		badge.size = badge.custom_minimum_size
		badge.position = frame.position + (frame.size - badge.size) * 0.5
		_measurements.append({"slot": item.slot, "rarity": item.rarity,
			"source_alpha_bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y],
			"center_error": badge.get_rect().get_center().distance_to(frame.get_rect().get_center())})


func _settle() -> void:
	await get_tree().create_timer(0.12).timeout
	await get_tree().process_frame
	await get_tree().process_frame
