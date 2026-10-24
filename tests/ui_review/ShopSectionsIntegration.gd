extends Node

## Serialized Home + production ShopPage. All accounts remain isolated and nonpersistent.
const OUT := "res://docs/ui_review/2026-10-24/shop-sections"
const HomeScene = preload("res://game/menu/Home.tscn")
const ShopCatalog = preload("res://game/core/ShopCatalog.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
var _home: Control
var _checks := 0
var _failures: Array = []
var _captures: Array = []
var _layouts: Array = []
var _selections: Array = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	AudioServer.set_bus_mute(0, true)
	get_tree().create_timer(80.0).timeout.connect(func():
		push_error("Shop sections integration timed out")
		get_tree().quit(2))
	for dimensions in SIZES:
		await _fresh_home(dimensions)
		_check_layout(dimensions)
		await _snap("shop-top", dimensions)
		await _scroll_to(_item("ShopSection_supply"))
		_check(_visible_inside_content(_item("ShopSection_supply")), "Supply section title is reachable at " + str(dimensions))
		await _snap("supply-section", dimensions)
		await _scroll_to(_item("ShopSection_gems"))
		_check(_visible_inside_content(_item("ShopSection_gems")), "Gem section title is reachable at " + str(dimensions))
		await _snap("gem-packs-top", dimensions)
		var packs: Array = ShopCatalog.gem_packs()
		await _pack_pointer(packs[0], dimensions, "first")
		await _scroll_bottom()
		await _snap("gem-packs-bottom", dimensions)
		await _pack_pointer(packs[-1], dimensions, "last")
		await _gem_shortcut_pointer(dimensions)
		_check_navigation(dimensions)
	_check(not PlayerData.persist, "Review never persists player changes")
	var report := {"checks": _checks, "failures": _failures, "captures": _captures,
		"layouts": _layouts, "selections": _selections, "catalog": ShopCatalog.gem_packs(),
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"scope": "Production Home/Shop; centered section placards; unchanged chest purchases; six proposed gem packs; actual first/last pack pointers and dismiss; no payment or currency grants."}
	var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("SHOP_SECTIONS_INTEGRATION_COMPLETE checks=", _checks, " captures=", _captures.size(), " failures=", _failures)
	_home.queue_free()
	await _settle()
	get_tree().quit.call_deferred(0 if _failures.is_empty() else 1)


func _fresh_home(dimensions: Vector2i) -> void:
	if is_instance_valid(_home):
		_home.queue_free()
		await _settle()
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.tutorial_done = true
	PlayerData.gold = 1800
	PlayerData.gems = 2400
	PlayerData.fast_chest = false
	get_window().size = dimensions
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.SHOP_TAB, false)
	await _settle()
	_check(_shop().get_script().resource_path == "res://game/menu/pages/ShopPage.gd", "Normal production ShopPage is used without injection")


func _shop() -> Control:
	return _home._pages[_home.SHOP_TAB]


func _item(title: String) -> Control:
	return _shop().find_child(title, true, false) as Control


func _check_layout(dimensions: Vector2i) -> void:
	_check(_item("GemExchange") == null and _item("GemExchangeAction") == null, "Diamond-to-gold exchange is absent from the entire production Shop tree")
	for copy in _shop().find_children("*", "Label", true, false):
		_check(not copy.text.contains("Đổi kim cương"), "No retired exchange heading remains")
	var sections: Array = []
	for id in ["premium", "supply", "gems"]:
		var section := _item("ShopSection_" + id)
		_check(section != null, "Section placard exists: " + id)
		if section == null:
			continue
		var heading := section.find_child("SectionTitle", true, false) as Label
		_check(heading != null and heading.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, id + " section title uses centered text")
		if heading != null:
			_check(absf(heading.get_global_rect().get_center().x - section.get_global_rect().get_center().x) <= 2.0, id + " title is centered on its placard")
		_check(absf(section.get_global_rect().get_center().x - _shop().size.x / 2.0) <= 10.0, id + " placard is centered in shop width")
		_check(_inside_horizontal(section), id + " section stays within viewport")
		sections.append({"id": id, "rect": _rect_values(section.get_global_rect())})
	_check(_item("ShopSection_premium").get_global_rect().position.y < _item("ShopSection_supply").get_global_rect().position.y, "Premium chests precede supply chests")
	_check(_item("ShopSection_supply").get_global_rect().position.y < _item("ShopSection_gems").get_global_rect().position.y, "Supply chests precede gem packs")
	for title in ["FeaturedChest", "GoldRewardBubble", "GoldOpen", "GoldOpenTen", "GoldMaterials", "GoldGuarantee", "ShopRates", "SupplyChestGrid", "SupplyChest_wood", "SupplyChest_silver", "WoodOpen", "SilverOpen", "GemPackGrid"]:
		var node := _item(title)
		_check(node != null, "Preserved or new production node exists: " + title)
		if node != null:
			_check(_inside_horizontal(node), title + " remains within horizontal viewport")
	var supplies := _item("SupplyChestGrid") as GridContainer
	_check(supplies != null and supplies.columns == 2 and supplies.get_child_count() == 2, "Wood and Silver retain their existing two-column supply layout")
	for id in ["wood", "silver"]:
		var panel := _item("SupplyChest_" + id) as PanelContainer
		var style := panel.get_theme_stylebox("panel") as StyleBoxTexture
		_check(style != null and style.texture.resource_path == "res://game/ui/skin/menu/shop_teal_supply.svg", id + " retains its approved supply artwork")
	_check(not (_item("GoldOpen") as Button).disabled and not (_item("GoldOpenTen") as Button).disabled, "Funded Gold x1/x10 actions remain available")
	var grid := _item("GemPackGrid") as GridContainer
	var packs: Array = ShopCatalog.gem_packs()
	_check(grid != null and grid.columns == 3 and grid.get_child_count() == 6, "Six gem packs are arranged in three columns and two rows")
	_check(packs.size() == 6, "Display catalog has exactly six proposed packs")
	var illustration_paths: Array = []
	for pack in packs:
		var id := str(pack["id"])
		var card := _item("GemPack_" + id)
		var amount := _item("GemPackAmount_" + id) as Label
		var action := _item("GemPackBuy_" + id) as Button
		_check(card != null and _inside_horizontal(card), "Gem pack card fits the viewport: " + id)
		_check(card != null and not bool(card.get_meta("purchase_integrated", true)), "Gem pack correctly declares payment integration unavailable: " + id)
		_check(amount != null and amount.text.contains(UiKit.format_number(int(pack["gems"]))), "Gem pack states its proposed amount: " + id)
		_check(action != null and action.text == ShopCatalog.format_vnd(int(pack["price_vnd"])), "Gem pack states its proposed price: " + id)
		_check(action != null and not action.disabled, "Gem pack details can be selected: " + id)
		var illustration := _item("GemPackIllustration_" + id) as TextureRect
		_check(illustration != null and illustration.texture != null, "Gem pack uses its own generated illustration: " + id)
		if illustration != null and illustration.texture != null:
			var path := illustration.texture.resource_path
			_check(not path.is_empty() and not illustration_paths.has(path), "Gem illustration is a distinct asset rather than reused gem clusters: " + id)
			_check(card.get_global_rect().grow(1.0).encloses(illustration.get_global_rect()), "Generated illustration stays within its pack card: " + id)
			illustration_paths.append(path)
	_check(illustration_paths.size() == 6, "All six pack illustrations have unique texture paths")
	if grid != null and grid.get_child_count() == 6:
		for index in 6:
			var card := grid.get_child(index) as Control
			var first_row := grid.get_child(index % 3) as Control
			var row_start := grid.get_child(0 if index < 3 else 3) as Control
			_check(is_equal_approx(card.get_global_rect().position.x, first_row.get_global_rect().position.x), "Pack column is aligned: " + str(index))
			_check(is_equal_approx(card.get_global_rect().position.y, row_start.get_global_rect().position.y), "Pack row is aligned: " + str(index))
	_check_navigation(dimensions)
	_layouts.append({"size": [dimensions.x, dimensions.y], "sections": sections, "gem_grid": _rect_values(grid.get_global_rect())})


func _pack_pointer(pack: Dictionary, dimensions: Vector2i, label: String) -> void:
	var id := str(pack["id"])
	var action := _item("GemPackBuy_" + id) as Button
	_check(action != null and _visible_inside_content(action), label + " gem pack is reachable by scrolling at " + str(dimensions))
	if action == null or not _visible_inside_content(action):
		return
	var account: Dictionary = PlayerData.to_dict().duplicate(true)
	var before: int = _home._menu_surfaces.size()
	await _tap(action)
	await _settle()
	var sheet := _home.find_child("GemPackDetails", true, false) as Control
	_check(sheet != null and sheet.is_visible_in_tree(), label + " real pointer opens selected pack details")
	_check(_home._menu_surfaces.size() == before + 1, label + " selected pack uses the normal menu sheet registration")
	_check(PlayerData.to_dict() == account, label + " selecting a pack changes no player data, currency, or inventory")
	if sheet == null:
		return
	var amount := sheet.find_child("GemPackAmount", true, false) as Label
	var price := sheet.find_child("GemPackPrice", true, false) as Label
	var status := sheet.find_child("GemPackStatus", true, false) as Label
	_check(amount != null and amount.text.contains(UiKit.format_number(int(pack["gems"]))), label + " selected sheet carries the correct proposed gem amount")
	_check(price != null and price.text.contains(ShopCatalog.format_vnd(int(pack["price_vnd"]))), label + " selected sheet carries the correct proposed price")
	_check(status != null and not status.text.is_empty() and (status.text.to_lower().contains("chưa") or status.text.to_lower().contains("không")), label + " sheet honestly states that payment is not integrated")
	_check_navigation(dimensions)
	await _snap("pack-" + label + "-details", dimensions)
	var close := sheet.find_child("GemPackClose", true, false) as Button
	_check(close != null and sheet.get_global_rect().encloses(close.get_global_rect()), label + " sheet has a visible real close action")
	if close != null:
		await _tap(close)
		await _settle()
	_check(_home.find_child("GemPackDetails", true, false) == null, label + " dismiss removes selected pack sheet")
	_check(PlayerData.to_dict() == account, label + " dismiss changes no player data, currency, or inventory")
	_selections.append({"id": id, "size": [dimensions.x, dimensions.y], "price_vnd": pack["price_vnd"], "gems": pack["gems"], "player_unchanged": PlayerData.to_dict() == account})


func _check_navigation(dimensions: Vector2i) -> void:
	_check(_home._nav_holder.is_visible_in_tree(), "Original bottom navigation remains visible at " + str(dimensions))
	_check(_home._nav_bar.get_script().resource_path == "res://game/ui/CartonNav.gd", "Original CartonNav is preserved")
	var rect: Rect2 = _home._nav_holder.get_global_rect()
	_check(is_equal_approx(rect.end.y, _home.size.y), "Navigation remains at the bottom of the screen")
	_check(_home._content.clip_contents and _home._content.get_global_rect().end.y <= rect.position.y + 1.0, "Shop content is clipped above navigation")


func _gem_shortcut_pointer(dimensions: Vector2i) -> void:
	var account: Dictionary = PlayerData.to_dict().duplicate(true)
	_home.select_tab(_home.TROOPS_TAB, false)
	await _settle()
	var shortcut := _home.find_child("GemsButton", true, false) as Control
	_check(shortcut != null and shortcut.is_visible_in_tree(), "Header gem shortcut is available outside Shop")
	if shortcut == null:
		return
	await _tap(shortcut)
	await get_tree().create_timer(0.35).timeout
	await _settle()
	_check(_shop().is_visible_in_tree(), "Real header gem pointer opens the production Shop tab")
	_check(_visible_inside_content(_item("ShopSection_gems")), "Header gem shortcut focuses the gem aisle directly at " + str(dimensions))
	_check(PlayerData.to_dict() == account, "Header gem shortcut changes no player data")
	await _snap("header-gem-shortcut", dimensions)


func _scroll_to(node: Control) -> void:
	if node == null:
		return
	var scroll := _shop().get_child(0) as ScrollContainer
	scroll.scroll_vertical += roundi(node.get_global_rect().position.y - scroll.get_global_rect().position.y)
	await _settle()


func _scroll_bottom() -> void:
	var scroll := _shop().get_child(0) as ScrollContainer
	scroll.scroll_vertical = 100000
	await _settle()
	_check(scroll.scroll_vertical > 0, "Shop scroll reaches the final gem pack row")


func _visible_inside_content(node: Control) -> bool:
	return node != null and _home._content.get_global_rect().grow(1.0).encloses(node.get_global_rect())


func _inside_horizontal(node: Control) -> bool:
	var rect := node.get_global_rect()
	return rect.position.x >= -1.0 and rect.end.x <= _home.size.x + 1.0


func _rect_values(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _tap(button: Control) -> void:
	var at := button.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.pressed = down
		get_viewport().push_input(event, true)
		await get_tree().process_frame


func _snap(label: String, dimensions: Vector2i) -> void:
	await _settle()
	var shot := get_viewport().get_texture().get_image()
	var filename := "%s-%dx%d.png" % [label, dimensions.x, dimensions.y]
	_check(shot.get_size() == dimensions, filename + " is captured at native window dimensions")
	_check(shot.save_png(OUT + "/" + filename) == OK, filename + " saved")
	_captures.append(filename)


func _settle() -> void:
	for frame in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(message)
		push_error(message)
