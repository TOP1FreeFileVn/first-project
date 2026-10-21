extends Node

# Review harness: renders current production pages with a disposable in-memory fixture.
const OUT := "res://docs/ui_review/2026-10-19/screens"
const HeroCat = preload("res://game/core/HeroCat.gd")
var _home: Control
var _geometry := {}


func _ready() -> void:
	get_window().size = Vector2i(720, 1280)
	print("UI_REVIEW_USER_DIR ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
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
	for id in ["giao", "dai_bac", "katana", "riu"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "katana"]
	PlayerData.patrol_last_claim = PlayerData.now() - 3 * 3600
	PlayerData.login_claimed = 3
	PlayerData.login_day = PlayerData.today() - 1
	_home = load("res://game/menu/Home.tscn").instantiate()
	add_child(_home)
	for entry in [[2, "01_lobby"], [0, "02_shop"], [1, "03_hero"], [3, "04_troops"], [4, "05_summon"]]:
		_home.select_tab(entry[0], false)
		await _capture(entry[1])
	_home.select_tab(1, false)
	var equipped: String = HeroCat.equipped_uid(PlayerData.hero_cat, "weapon")
	_home._pages[1]._open_detail(equipped)
	await _capture("06_equipment_detail")
	_close_popup()
	await get_tree().process_frame
	var spare: Array = HeroCat.spare(PlayerData.hero_cat)
	if not spare.is_empty():
		_home._pages[1]._open_detail(spare[0])
		await _capture("07_equipment_compare")
		_close_popup()
		await get_tree().process_frame
	_home.select_tab(3, false)
	_home._pages[3]._open_detail("katana")
	await _capture("08_troop_detail")
	_close_popup()
	await get_tree().process_frame
	_home.select_tab(2, false)
	for popup in ["events", "login", "quests"]:
		match popup:
			"events": _home.MetaPopups.open_events(_home)
			"login": _home.MetaPopups.open_login(_home)
			"quests": _home.MetaPopups.open_quests(_home)
		await _capture("09_" + popup)
		_close_popup()
		await get_tree().process_frame
	_home._pages[2]._go(1)
	await _capture("10_locked_stage")
	_home.open_page(load("res://game/menu/pages/CastlePage.gd"))
	await _capture("13_castle")
	var file := FileAccess.open(OUT + "/geometry.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(_geometry, "\t"))
	file.close()
	print("UI_REVIEW_COMPLETE ", _geometry.size(), " screens")
	get_tree().quit()


func _capture(key: String) -> void:
	await get_tree().create_timer(0.25).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png(OUT + "/" + key + ".png")
	print("UI_REVIEW_CAPTURE ", key, " ", image.get_size(), " result=", result)
	var controls: Array = []
	_collect(_home, controls)
	_geometry[key] = controls


func _collect(node: Node, output: Array) -> void:
	if node is Control:
		var control := node as Control
		if not control.is_visible_in_tree():
			return
		var rect := control.get_global_rect()
		var minimum := control.get_combined_minimum_size()
		var item := {"path": str(_home.get_path_to(control)), "type": control.get_class(),
			"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
			"minimum": [minimum.x, minimum.y], "clip": control.clip_contents,
			"variation": str(control.theme_type_variation)}
		if control is Label or control is Button:
			item["text"] = control.text
			item["font_size"] = control.get_theme_font_size("font_size")
		if control is BaseButton:
			item["disabled"] = control.disabled
		output.append(item)
	for child in node.get_children():
		_collect(child, output)


func _close_popup() -> void:
	for child in _home.get_children():
		if child is CanvasLayer and child.name == "TroopUpgradeLayer":
			child.queue_free()
		elif child is ColorRect and child.mouse_filter == Control.MOUSE_FILTER_STOP:
			child.queue_free()
