extends Node

## Real ChestOpening reward cards, with all four equipment slots at every rarity.
## The fixture supplies deterministic presentation-only loot and never grants it.
const OUT := "res://docs/design/2026-10-24/hero-consistency/chest-rewards"
const HomeScene = preload("res://game/menu/Home.tscn")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const PaperboardFrame = preload("res://game/ui/PaperboardFrame.gd")
const BADGE_GLYPH = preload("res://game/ui/equipment_badge_glyph.gdshader")
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
var _checks := 0
var _failures: Array = []
var _captures: Array = []
var _cards: Array = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var original := PlayerData.to_dict().duplicate(true)
	var previous_persist: bool = PlayerData.persist
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	var home: Control = HomeScene.instantiate()
	add_child(home)
	home.select_tab(home.SHOP_TAB, false)
	await _settle()
	var unchanged := PlayerData.to_dict().duplicate(true)
	get_tree().create_timer(45.0).timeout.connect(func():
		push_error("Chest reward review timed out")
		get_tree().quit(2))
	for dimensions in SIZES:
		get_window().size = dimensions
		await _settle()
		for rarity in 4:
			var loot := {"items": []}
			for slot in HeroCat.SLOTS:
				var ids: Array = HeroCat.ids_of(slot, rarity)
				_check(not ids.is_empty(), "%s has rarity %d fixture item" % [slot, rarity])
				if not ids.is_empty():
					loot.items.append({"id": ids[0], "uid": "review-%s-%d" % [slot, rarity], "rarity": rarity})
			var opening := ChestOpening.new()
			opening.setup("Trang bị nhận được", Color("e8b93c"), loot, [], true)
			opening.attach(home)
			await get_tree().create_timer(0.9).timeout
			await _settle()
			_audit_cards(opening, rarity, dimensions)
			var filename := "rarity-%d-%dx%d.png" % [rarity, dimensions.x, dimensions.y]
			var image := get_viewport().get_texture().get_image()
			_check(image.get_size() == dimensions, filename + " native viewport size")
			_check(image.save_png(OUT + "/" + filename) == OK, filename + " saved")
			_captures.append(filename)
			opening._close()
			await _settle()
	_check(PlayerData.to_dict() == unchanged, "Reward presentation never changes inventory, currency or progression")
	_check(not PlayerData.persist, "Review does not persist")
	home.queue_free()
	await _settle()
	PlayerData.from_dict(original)
	PlayerData.persist = previous_persist
	var report := {"checks": _checks, "failures": _failures, "captures": _captures, "cards": _cards,
		"profile": OS.get_user_data_dir(), "scope": "Actual ChestOpening summary with approved shared equipment frame and filled category badges, all four slots and all rarities at native 360/450 widths; no grants or saves."}
	var file := FileAccess.open(OUT + "/review.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("CHEST_REWARD_REVIEW_COMPLETE checks=", _checks, " captures=", _captures.size(), " failures=", _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)


func _audit_cards(opening: Control, rarity: int, dimensions: Vector2i) -> void:
	var badges: Array[Node] = opening.find_children("EquipmentCategoryBadge", "Control", true, false)
	_check(badges.size() == 4, "Four reward cards have current category badges")
	for category: Control in badges:
		var card := category.get_parent() as Control
		var reward_card: Node = card
		while reward_card != null and not reward_card.has_meta("equipment_item_id"):
			reward_card = reward_card.get_parent()
		_check(reward_card != null, "Badge is inside a real equipment reward card")
		if reward_card == null:
			continue
		var item_key := "item:" + str(reward_card.get_meta("equipment_uid"))
		var items: Dictionary = opening.get("_items")
		var item: Dictionary = items.get(item_key, {})
		_check(not item.is_empty(), "Badge belongs to a real ChestOpening reward")
		if item.is_empty():
			continue
		_check(item.id == reward_card.get_meta("equipment_item_id"), "Reward card keeps the actual granted item identity")
		var definition: Dictionary = HeroCat.ITEMS[item.id]
		var slot: String = definition.slot
		var description := "%s rarity %d at %d" % [slot, rarity, dimensions.x]
		var frame: Control = card.get_child(0)
		_check(frame.get_script() == PaperboardFrame and frame.get("kind") == "card", description + " approved paperboard item frame")
		_check(frame.get("tone") == HeroCat.tone(rarity) and category.get("tone") == HeroCat.tone(rarity), description + " frame and category follow rarity")
		var glyph := card.get_node("SlotBadge") as TextureRect
		var atlas := glyph.texture as AtlasTexture
		var expected := "res://game/ui/art/equipment_badge_%s.svg" % slot
		_check(atlas != null and atlas.atlas != null and atlas.atlas.resource_path == expected, description + " approved filled symbol source")
		var material := glyph.material as ShaderMaterial
		_check(material != null and material.shader == BADGE_GLYPH, description + " filled white glyph shader")
		if material != null:
			_check(material.get_shader_parameter("accent_color") == PaperboardFrame.BADGE_ACCENTS[HeroCat.tone(rarity)], description + " interior accent follows rarity")
		_check(category.position.is_equal_approx(Vector2(-2, -2)), description + " badge protrusion retained")
		_check(glyph.get_global_rect().get_center().distance_to(category.get_global_rect().get_center()) < 0.1, description + " symbol centered in badge")
		var art := card.get_node("EquipmentArt") as TextureRect
		var art_path := "res://game/ui/art/icon_%s_96.png" % definition.icon
		_check(art.texture.resource_path == art_path, description + " item uses approved current raster art")
		_cards.append({"slot": slot, "rarity": rarity, "window": [dimensions.x, dimensions.y], "glyph": expected, "art": art.texture.resource_path})


func _settle() -> void:
	for frame in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(message)
		push_error(message)
