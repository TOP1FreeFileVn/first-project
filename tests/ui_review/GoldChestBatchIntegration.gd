extends Node

## Production-only proof for the selected A gold offer and atomic x1/x10 actions.
const OUT := "res://docs/ui_review/2026-10-24/gold-chest-batch"
const HomeScene = preload("res://game/menu/Home.tscn")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const DrawnIcon = preload("res://game/ui/DrawnIcon.gd")
const Economy = preload("res://game/core/Economy.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
var _home: Control
var _checks := 0
var _failures: Array = []
var _captures: Array = []
var _layouts: Array = []
var _purchases: Array = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	_reset_account()
	AudioServer.set_bus_mute(0, true)
	get_tree().create_timer(85.0).timeout.connect(func():
		push_error("Gold chest batch integration timed out")
		get_tree().quit(2))
	await _fresh_home()
	for dimensions in SIZES:
		get_window().size = dimensions
		await _fund(2400)
		_check_layout(dimensions)
		_check_availability(true, true, "funded")
		await _snap("funded", dimensions)
		await _fund(_gem_price() * 10 - 1)
		_check_availability(true, false, "one gem short of x10")
		await _snap("x1-only", dimensions)
		if dimensions == SIZES[1]:
			await _blocked_batch_pointer()
		await _fund(0)
		_check_availability(false, false, "insufficient gems")
		await _snap("insufficient", dimensions)
	await _fresh_home()
	await _rates_pointer()
	await _purchase_pointer(1)
	await _purchase_pointer(10)
	_check(not PlayerData.persist, "Review never persists account changes")
	var report := {"checks": _checks, "failures": _failures, "captures": _captures,
		"layouts": _layouts, "purchases": _purchases,
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"scope": "Serialized production Home and normal ShopPage, selected A gold card only, preserved supply cards and navigation, real pointer x1/x10 purchases and aggregated ChestOpening summary."}
	var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("GOLD_CHEST_BATCH_COMPLETE checks=", _checks, " captures=", _captures.size(), " failures=", _failures)
	_home.queue_free()
	await _settle()
	get_tree().quit.call_deferred(0 if _failures.is_empty() else 1)


func _reset_account() -> void:
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.tutorial_done = true
	PlayerData.fast_chest = false
	PlayerData.gold = 1800
	PlayerData.gems = 2400
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
	_check(_shop().get_script().resource_path == "res://game/menu/pages/ShopPage.gd", "Normal production ShopPage is used without demo injection")


func _shop() -> Control:
	return _home._pages[_home.SHOP_TAB]


func _item(title: String) -> Control:
	return _shop().find_child(title, true, false) as Control


func _gem_price() -> int:
	return int(Economy.CHESTS["gold"]["gems"])


func _fund(amount: int) -> void:
	PlayerData.gems = amount
	PlayerData.changed.emit()
	await _settle()
	_check(_home._gem_label.text == UiKit.format_number(amount), "Shared header reflects current gem balance")


func _check_layout(dimensions: Vector2i) -> void:
	var records: Array = []
	for title in ["FeaturedChest", "GoldRewardBubble", "GoldOpen", "GoldOpenTen", "GoldMaterials", "GoldGuarantee", "ShopRates", "SupplyChestGrid", "SupplyChest_wood", "SupplyChest_silver", "WoodOpen", "SilverOpen", "GemPackGrid"]:
		var node := _item(title)
		_check(node != null, title + " exists at " + str(dimensions))
		if node == null:
			continue
		var rect := node.get_global_rect()
		_check(rect.position.x >= -1.0 and rect.end.x <= _home.size.x + 1.0,
			title + " stays inside the horizontal viewport at " + str(dimensions))
		if title in ["GoldOpen", "GoldOpenTen"]:
			_check(_home._content.get_global_rect().grow(1.0).encloses(rect), title + " is fully visible above navigation")
		records.append({"node": title, "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	var grid := _item("SupplyChestGrid") as GridContainer
	_check(grid != null and grid.columns == 2 and grid.get_child_count() == 2, "Existing two-column wood/silver supply grid is preserved")
	_check(_item("GemExchange") == null, "Retired diamond-to-gold exchange is absent")
	for kind in ["wood", "silver"]:
		var card := _item("SupplyChest_" + kind) as PanelContainer
		if card == null:
			continue
		var style := card.get_theme_stylebox("panel") as StyleBoxTexture
		_check(style != null and style.texture != null and style.texture.resource_path == "res://game/ui/skin/menu/shop_teal_supply.svg", kind + " keeps the existing teal supply card art")
		var arts := _chest_icons(card)
		_check(arts.size() == 1 and arts[0].size == Vector2(160, 160), kind + " keeps the existing compact chest artwork")
		var rewards := _item(kind.capitalize() + "Reward") as Label
		_check(rewards != null and rewards.text.contains(str(int(Economy.CHESTS[kind]["items"]))), kind + " keeps its current item reward copy")
	_check(_home._nav_holder.is_visible_in_tree(), "Existing bottom navigation remains visible")
	_check(_home._nav_bar.get_script().resource_path == "res://game/ui/CartonNav.gd", "Existing CartonNav is retained")
	var nav_rect: Rect2 = _home._nav_holder.get_global_rect()
	_check(is_equal_approx(nav_rect.end.y, _home.size.y), "Navigation remains at the screen bottom")
	_check(_home._content.clip_contents and _home._content.get_global_rect().end.y <= nav_rect.position.y + 1.0, "Shop content stays clipped above navigation")
	_layouts.append({"size": [dimensions.x, dimensions.y], "nodes": records})


func _check_availability(single: bool, batch: bool, label: String) -> void:
	var one := _item("GoldOpen") as Button
	var ten := _item("GoldOpenTen") as Button
	_check(one != null and one.disabled != single, label + ": x1 availability matches funds")
	_check(ten != null and ten.disabled != batch, label + ": x10 availability matches funds")
	_check((_item("WoodOpen") as Button).disabled == false, label + ": free wood action remains available")
	_check((_item("SilverOpen") as Button).disabled == false, label + ": funded silver action remains available")
	if not batch and single and ten != null:
		_check(PlayerData.gems == _gem_price() * 10 - 1, "x10 is unavailable exactly one gem below its full price")


func _rates_pointer() -> void:
	var before: int = _home._menu_surfaces.size()
	var action := _item("ShopRates") as Button
	_check(action != null and not action.disabled, "Rates are available before buying")
	if action == null:
		return
	await _tap(action)
	await _settle()
	_check(_home._menu_surfaces.size() == before + 1, "Real pointer opens production rates sheet")
	await _snap("rates-sheet", SIZES[1])


func _blocked_batch_pointer() -> void:
	var before: int = PlayerData.gems
	var action := _item("GoldOpenTen") as Button
	if action == null:
		return
	await _tap(action)
	await _settle()
	_check(PlayerData.gems == before and _find_opening(_home) == null, "Disabled x10 pointer at 1199 gems neither charges nor opens a chest")
	_check(not (_item("GoldOpen") as Button).disabled, "Blocking x10 at 1199 leaves x1 available")


func _purchase_pointer(count: int) -> void:
	await _fresh_home()
	var before_gems: int = PlayerData.gems
	var before_gold: int = PlayerData.gold
	var before_items: int = PlayerData.hero_cat["bag"].size()
	var before_stones: int = PlayerData.forge_stones
	var before_plans := _blueprints_total()
	var before_pity: int = PlayerData.gold_chest_pity
	var action := _item("GoldOpenTen" if count == 10 else "GoldOpen") as Button
	_check(action != null and not action.disabled, "Gold x%d action is funded before purchase" % count)
	if action == null:
		return
	await _tap(action)
	await get_tree().create_timer(1.4).timeout
	var expected_items := int(Economy.CHESTS["gold"]["items"]) * count
	var expected_cost := _gem_price() * count
	_check(PlayerData.gems == before_gems - expected_cost, "Actual x%d pointer charges exactly %d gems once" % [count, expected_cost])
	_check(PlayerData.gold == before_gold, "Gold purchase does not consume the separate gold balance")
	_check(PlayerData.hero_cat["bag"].size() == before_items + expected_items, "x%d grants exactly %d inventory items" % [count, expected_items])
	_check(PlayerData.gold_chest_pity == (before_pity + count) % Economy.GOLD_CHEST_PITY, "x%d advances pity once per chest" % count)
	_check(_home._gem_label.text == UiKit.format_number(PlayerData.gems), "Shared gem header reflects the actual purchase")
	var opening := _find_opening(_home)
	_check(opening != null and opening.is_visible_in_tree(), "x%d starts the real ChestOpening" % count)
	if opening == null:
		return
	var loot: Dictionary = opening._loot
	_check(loot.get("items", []).size() == expected_items and opening._order.size() == expected_items, "x%d opening contains all aggregated equipment" % count)
	_check(expected_items == 60 if count == 10 else expected_items == 6, "Production gold reward remains six items per chest")
	var title: String = str(Economy.CHESTS["gold"]["name"]) + (" ×10" if count == 10 else "")
	_check(opening._chest_name == title and _has_label(opening._title, title), "x%d opening title identifies the purchased count" % count)
	_check(opening._stage == "wait", "x%d uses the normal wait-for-tap opening stage" % count)
	_check(PlayerData.forge_stones - before_stones == int(loot.get("stones", 0)), "x%d grants its combined stones once" % count)
	var stones: Array = Economy.CHESTS["gold"]["stones"]
	_check(int(loot.get("stones", 0)) >= int(stones[0]) * count and int(loot.get("stones", 0)) <= int(stones[1]) * count, "x%d combined stones stay inside per-chest bounds" % count)
	_check(_blueprints_total() - before_plans == int(HeroCat.CHEST_BLUEPRINTS["gold"]) * count, "x%d grants the unchanged per-chest blueprint total" % count)
	_check(_loot_blueprints_total(loot) == int(HeroCat.CHEST_BLUEPRINTS["gold"]) * count, "x%d opening carries the complete combined blueprint total" % count)
	await _snap("actual-x%d-opening" % count, SIZES[1])
	await _tap_at(opening.get_global_rect().position + ChestOpening.CHEST_AT)
	if count == 10:
		_check(await _await_stage(opening, "summary", 4.0), "x10 normal chest burst goes straight to the combined summary without individual flips")
	else:
		_check(await _await_stage(opening, "card", 4.0), "x1 keeps the normal individual equipment reveal after its burst")
		await _snap("actual-x1-card", SIZES[1])
		await _tap(opening._skip)
	await get_tree().create_timer(0.95).timeout
	_check(opening._stage == "summary", "x%d reaches the complete reward summary" % count)
	var grid := opening.find_child("ChestRewardGrid", true, false) as GridContainer
	_check(grid != null and grid.get_child_count() == expected_items, "x%d summary retains every granted item" % count)
	var buttons := opening.find_child("ChestSummaryButtons", true, false) as Control
	_check(buttons != null and opening.get_global_rect().encloses(buttons.get_global_rect()), "x%d summary keeps actions inside the visible screen" % count)
	_check(PlayerData.gems == before_gems - expected_cost and PlayerData.hero_cat["bag"].size() == before_items + expected_items, "Skipping x%d does not charge or grant again" % count)
	await _snap("actual-x%d-summary" % count, SIZES[1])
	if count == 10:
		var scroll := opening.find_child("ChestSummaryScroll", true, false) as ScrollContainer
		if scroll != null:
			scroll.scroll_vertical = 100000
			await _settle()
			_check(scroll.scroll_vertical > 0, "All sixty equipment rewards remain reachable by scrolling the summary")
			_check(buttons != null and opening.get_global_rect().encloses(buttons.get_global_rect()), "x10 summary actions remain visible after scrolling all rewards")
			await _snap("actual-x10-summary-scrolled", SIZES[1])
	_purchases.append({"count": count, "cost": expected_cost, "items": expected_items, "stones": loot.get("stones", 0), "blueprints": _blueprints_total() - before_plans, "title": title})
	# A repeated request while the opening owns the screen must never buy twice.
	var paid_balance: int = PlayerData.gems
	var granted_items: int = PlayerData.hero_cat["bag"].size()
	_shop()._open("gold", 1)
	_check(PlayerData.gems == paid_balance and PlayerData.hero_cat["bag"].size() == granted_items,
		"x%d active opening rejects duplicate purchases without charge or rewards" % count)
	var done := opening.find_child("ChestDoneButton", true, false) as Button
	_check(done != null, "x%d summary has a real close action" % count)
	if done != null:
		await _tap(done)
		await _settle()
		_check(_find_opening(_home) == null, "x%d close removes its opening overlay" % count)
		await _tap(_item("GoldOpen") as Button)
		await _settle()
		_check(PlayerData.gems == paid_balance - _gem_price() and PlayerData.hero_cat["bag"].size() == granted_items + int(Economy.CHESTS["gold"]["items"]),
			"x%d close restores the next real purchase exactly once" % count)
		_check(_find_opening(_home) != null, "x%d subsequent purchase starts a fresh opening" % count)


func _await_stage(opening: Control, target: String, timeout: float) -> bool:
	var deadline := Time.get_ticks_msec() + roundi(timeout * 1000.0)
	while opening._stage != target and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return opening._stage == target


func _blueprints_total() -> int:
	var total := 0
	for value in PlayerData.blueprints.values():
		total += int(value)
	return total


func _loot_blueprints_total(loot: Dictionary) -> int:
	var total := 0
	for value in loot.get("blueprints", {}).values():
		total += int(value)
	return total


func _has_label(root: Node, value: String) -> bool:
	if root is Label and root.text == value:
		return true
	for child in root.get_children():
		if _has_label(child, value):
			return true
	return false


func _find_opening(root: Node) -> Control:
	if root.get_script() == ChestOpening:
		return root as Control
	for child in root.get_children():
		var found := _find_opening(child)
		if found != null:
			return found
	return null


func _chest_icons(root: Node) -> Array:
	var result: Array = []
	if root.get_script() == DrawnIcon and root.kind == DrawnIcon.Kind.CHEST:
		result.append(root)
	for child in root.get_children():
		result.append_array(_chest_icons(child))
	return result


func _tap(button: Button) -> void:
	await _tap_at(button.get_global_rect().get_center())


func _tap_at(at: Vector2) -> void:
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
	_check(shot.get_size() == dimensions, filename + " uses native window dimensions")
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
