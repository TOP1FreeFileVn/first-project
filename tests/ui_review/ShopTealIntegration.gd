extends Node

## Uses the serialized production Home and normal ShopPage without demo injection.
const OUT := "res://docs/ui_review/2026-10-24/shop-teal"
const HomeScene = preload("res://game/menu/Home.tscn")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const Economy = preload("res://game/core/Economy.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
var _home: Control
var _checks := 0
var _failures: Array = []
var _captures: Array = []
var _layouts: Array = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	_reset_account()
	AudioServer.set_bus_mute(0, true)
	get_tree().create_timer(85.0).timeout.connect(func():
		push_error("Shop teal integration timed out")
		get_tree().quit(2))
	await _fresh_home()
	for dimensions in SIZES:
		get_window().size = dimensions
		await _settle()
		_check_layout(dimensions)
		await _snap("shop", dimensions)
	await _data_states()
	await _gem_pack_scroll()
	await _pattern_context()
	await _rates_pointer()
	await _purchase_pointer()
	_check(not PlayerData.persist, "Fixture does not persist player changes")
	var report := {"checks": _checks, "failures": _failures, "captures": _captures,
		"layouts": _layouts, "profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"scope": "Production Home.tscn and normal ShopPage; selected teal surfaces; actual pointer rates/purchase; live account states; preserved navigation."}
	var report_file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report, "\t"))
	print("SHOP_TEAL_INTEGRATION_COMPLETE checks=", _checks, " captures=", _captures.size(), " failures=", _failures)
	_home.queue_free()
	await _settle()
	get_tree().quit.call_deferred(0 if _failures.is_empty() else 1)


func _reset_account() -> void:
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.tutorial_done = true
	PlayerData.fast_chest = false
	PlayerData.gold = 1800
	PlayerData.gems = 240
	PlayerData.gold_chest_pity = 3


func _fresh_home() -> void:
	if is_instance_valid(_home):
		_home.queue_free()
		await _settle()
	_reset_account()
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.SHOP_TAB, false)
	await _settle()
	_check(_shop().get_script().resource_path == "res://game/menu/pages/ShopPage.gd", "Normal production ShopPage is active without injection")


func _shop() -> Control:
	return _home._pages[_home.SHOP_TAB]


func _item(title: String) -> Control:
	return _shop().find_child(title, true, false) as Control


func _check_layout(dimensions: Vector2i) -> void:
	var records: Array = []
	var viewport_width: float = _home.size.x
	for title in ["FeaturedChest", "SupplyChestGrid", "SupplyChest_wood", "SupplyChest_silver", "GoldOpen", "GoldOpenTen", "WoodOpen", "SilverOpen", "ShopRates", "GoldRewardBubble", "GoldGuarantee", "GemPackGrid", "GoldExchangeGrid", "ShopSection_premium", "ShopSection_supply", "ShopSection_gems", "ShopSection_gold"]:
		var node := _item(title)
		_check(node != null, title + " exists at " + str(dimensions))
		if node == null:
			continue
		var rect := node.get_global_rect()
		_check(rect.position.x >= -1.0 and rect.end.x <= viewport_width + 1.0,
			title + " stays inside the horizontal viewport at " + str(dimensions))
		records.append({"node": title, "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	_check(_home._nav_holder.is_visible_in_tree(), "Bottom navigation remains visible at " + str(dimensions))
	_check(_home._nav_bar.get_script().resource_path == "res://game/ui/CartonNav.gd", "Existing CartonNav remains the bottom navigation")
	var nav_rect: Rect2 = _home._nav_holder.get_global_rect()
	_check(is_equal_approx(nav_rect.end.y, _home.size.y), "Bottom navigation stays at the screen bottom")
	_check(_home._content.clip_contents and _home._content.get_global_rect().end.y <= nav_rect.position.y + 1.0,
		"Shop scroll is clipped above preserved navigation")
	var gold_action := _item("GoldOpen") as Button
	var wood_action := _item("WoodOpen") as Button
	var silver_action := _item("SilverOpen") as Button
	_check(gold_action != null and not gold_action.disabled, "Funded gold action is available")
	_check(wood_action != null and not wood_action.disabled, "Free wood action is available")
	_check(silver_action != null and not silver_action.disabled, "Funded silver action is available")
	_layouts.append({"size": [dimensions.x, dimensions.y], "nodes": records})


func _data_states() -> void:
	PlayerData.gold = 0
	PlayerData.gems = 0
	PlayerData.changed.emit()
	await _settle()
	_check((_item("GoldOpen") as Button).disabled, "Gold purchase is disabled without gems")
	_check((_item("SilverOpen") as Button).disabled, "Silver purchase is disabled without gold")
	for title in ["GoldDeficit", "SilverDeficit"]:
		var copy := _item(title) as Label
		_check(copy != null and copy.is_visible_in_tree() and not copy.text.is_empty(), title + " explains the actual currency deficit")
		var required: int = Economy.CHESTS["gold"]["gems"] if title == "GoldDeficit" else Economy.CHESTS["silver"]["gold"]
		_check(copy != null and copy.text.contains(UiKit.format_number(required)), title + " states the exact missing amount")
	_check(_home._gold_label.text == UiKit.format_number(0) and _home._gem_label.text == UiKit.format_number(0), "Shared currency header updates after account change")
	await _snap("insufficient-funds", SIZES[1])
	PlayerData.gold = 1800
	PlayerData.gems = 240
	PlayerData.free_chest_at = PlayerData.now() + 120
	PlayerData.gold_chest_pity = Economy.GOLD_CHEST_PITY - 1
	PlayerData.changed.emit()
	await _settle()
	_check((_item("WoodOpen") as Button).disabled, "Wood action observes its free chest cooldown")
	var status := _item("WoodStatus") as Label
	_check(status != null and status.is_visible_in_tree() and not status.text.is_empty(), "Wood cooldown explains the remaining wait")
	var guarantee := _item("GoldGuarantee") as Label
	_check(guarantee != null and guarantee.text.contains(Economy.RARITY_NAMES[int(Economy.CHESTS["gold"]["min_rare"])]), "Gold offer explains the guaranteed rarity per chest")
	await _snap("cooldown-and-next-pity", SIZES[1])
	# Tick changes the time-dependent state without rebuilding the page.
	PlayerData.free_chest_at = PlayerData.now() - 1
	_shop().tick()
	_check(not (_item("WoodOpen") as Button).disabled, "Wood action re-enables on the live tick when cooldown expires")
	_check(not (_item("WoodStatus") as Label).visible, "Expired cooldown copy is hidden")


func _gem_pack_scroll() -> void:
	var scroll := _shop().get_child(0) as ScrollContainer
	var header := _item("ShopSection_gems")
	scroll.scroll_vertical += roundi(header.get_global_rect().position.y - scroll.get_global_rect().position.y)
	await _settle()
	var packs := _item("GemPackGrid") as GridContainer
	_check(scroll.scroll_vertical > 0, "The production shop scrolls to the gem packs")
	_check(packs != null and packs.columns == 3 and packs.get_child_count() == 6 and _home._content.get_global_rect().intersects(packs.get_global_rect()), "All six gem packs occupy the reachable three-column shop grid")
	_check(_home._nav_holder.is_visible_in_tree(), "Navigation remains visible after scrolling")
	await _snap("gem-packs-scrolled", SIZES[1])
	scroll.scroll_vertical = 100000
	await _settle()
	var gold := _item("GoldExchangeGrid") as GridContainer
	_check(gold != null and gold.columns == 3 and gold.get_child_count() == 6 and _home._content.get_global_rect().intersects(gold.get_global_rect()), "Daily free gold and five paid exchanges are reachable beneath the gem packs")
	scroll.scroll_vertical = 0
	await _settle()


func _pattern_context() -> void:
	var nav: Control = _home._nav_bar
	var material := _home._pattern_backdrop.material as ShaderMaterial
	_check(is_equal_approx(float(material.get_shader_parameter("pattern_strength")), 0.35), "Shop moving motifs use the selected quieter strength")
	_home.select_tab(_home.TROOPS_TAB, false)
	await _settle()
	_check(is_equal_approx(float(material.get_shader_parameter("pattern_strength")), 1.0), "Troops restores its regular pattern strength")
	_check(_home._nav_bar == nav and _home._nav_holder.is_visible_in_tree(), "Tab switch retains the same navigation control")
	_home.select_tab(_home.SHOP_TAB, false)
	await _settle()
	_check(is_equal_approx(float(material.get_shader_parameter("pattern_strength")), 0.35), "Returning to Shop restores its teal pattern strength")


func _rates_pointer() -> void:
	var before: int = _home._menu_surfaces.size()
	var action := _item("ShopRates") as Button
	_check(action != null and not action.disabled, "Rates control is available before purchasing")
	if action == null:
		return
	await _tap(action)
	await _settle()
	_check(_home._menu_surfaces.size() == before + 1, "Actual pointer opens the production rates sheet")
	_check(_home._nav_holder.is_visible_in_tree(), "Rates sheet preserves the bottom navigation")
	await _snap("rates-sheet", SIZES[1])


func _purchase_pointer() -> void:
	# A fresh production Home removes the rates sheet before the purchase test.
	await _fresh_home()
	var before: int = PlayerData.gems
	var action := _item("GoldOpen") as Button
	_check(action != null and not action.disabled, "Gold action is funded before the real pointer test")
	if action == null:
		return
	await _tap(action)
	await get_tree().create_timer(1.4).timeout
	_check(PlayerData.gems == before - 120, "One actual pointer purchase spends exactly the unchanged 120 gems")
	_check(_home._gem_label.text == UiKit.format_number(PlayerData.gems), "Shared header reflects the charged currency")
	var opening := _find_opening(_home)
	_check(opening != null and opening.is_visible_in_tree(), "Actual gold purchase opens the production ChestOpening")
	if opening != null:
		_check(opening._stage == "wait", "Gold opening reaches its normal wait-for-tap stage")
	await _snap("actual-gold-opening", SIZES[1])


func _find_opening(root: Node) -> Control:
	if root.get_script() == ChestOpening:
		return root as Control
	for child in root.get_children():
		var found := _find_opening(child)
		if found != null:
			return found
	return null


func _tap(button: Button) -> void:
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
