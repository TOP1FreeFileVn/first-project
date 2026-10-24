extends Node

## Review-only alternatives for the outer hero surface. Production equipment
## cards, art, fonts, animation component and bottom navigation are reused.
const HOME = preload("res://game/menu/Home.tscn")
const HOME_SCRIPT = preload("res://game/menu/Home.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const SURFACE = preload("res://docs/design/2026-10-24/hero-surface-review/HeroSurface.gd")
const OUT := "res://docs/design/2026-10-24/hero-surface-review/native"
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
const WEAPONS := ["kiem_go", "cung_san", "gay_sao", "riu_lua"]
const INKS := [Color("354e50"), Color("654d3b"), Color("54485f")]
const PLAQUES := [Color("edf3e9"), Color("fbf1dc"), Color("f2edf7")]

var _home
var _page
var _uids := {}
var _captures: Array = []
var _checks: Array = []
var _failed := 0
var _variant := 0
var _size := Vector2i.ZERO


func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var before := PlayerData.to_dict().duplicate(true)
	var persist_before: bool = PlayerData.persist
	var tab_before: int = HOME_SCRIPT.last_tab
	PlayerData.persist = false
	var save_before := _save_hash()
	_fixture()
	_home = HOME.instantiate()
	add_child(_home)
	_home.select_tab(_home.HERO_TAB, false)
	_page = _home._pages[_home.HERO_TAB]
	for requested in SIZES:
		_size = requested
		get_window().size = requested
		for variant in 3:
			_variant = variant
			_page.refresh()
			_apply_surface(variant)
			await _settle()
			_check(_page.is_visible_in_tree(), "production_hero_page_visible")
			_check(_page.find_children("HeroPreview", "", true, false).size() == 1, "one_animated_hero")
			await _capture("surface-%d" % variant)
	_size = Vector2i(450, 800)
	_variant = 0
	for weapon in WEAPONS:
		PlayerData.hero_cat.equipped.weapon = _uids[weapon]
		_page.refresh()
		_apply_surface(0)
		await _settle()
		var preview: Control = _page.find_child("HeroPreview", true, false)
		var rig: Node2D = preview.rig
		_check(rig.animation == "idle" and rig.has_animation("idle"), weapon + "_idle_loaded")
		var start_time: float = rig._time
		var start_pose: Array = rig._world.duplicate()
		var moved := false
		for frame in 12:
			await _capture("%s-idle-%02d" % [weapon, frame])
			await get_tree().create_timer(0.1).timeout
			await RenderingServer.frame_post_draw
			for bone in mini(start_pose.size(), rig._world.size()):
				var prior: Transform2D = start_pose[bone]
				moved = moved or not prior.is_equal_approx(rig._world[bone])
		_check(rig._time > start_time + 0.8 and moved, weapon + "_bones_move_in_natural_idle")
	_home.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	PlayerData.from_dict(before)
	PlayerData.persist = persist_before
	HOME_SCRIPT.last_tab = tab_before
	_check(_save_hash() == save_before, "player_save_unchanged")
	var file := FileAccess.open(OUT.path_join("review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope": "Review-only outer surface alternatives; actual production hero, cards and navigation.", "captures": _captures, "checks": _checks, "failures": _failed}, "\t"))
	file.close()
	print("HERO_SURFACE_REVIEW_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failed)
	get_tree().quit(1 if _failed else 0)


func _fixture() -> void:
	PlayerData._reset()
	PlayerData.persist = false
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false
	var state := {"equipped": {}, "bag": {}, "retired_items": {}, "next": 1}
	for id in HeroCat.ITEMS:
		var uid := HeroCat.add_item(state, id)
		_uids[id] = uid
		if id in ["kiem_go", "mu_hiep_si", "giap_rong", "giay_gio"]:
			state.equipped[HeroCat.ITEMS[id].slot] = uid
	PlayerData.hero_cat = state


func _apply_surface(variant: int) -> void:
	var previous: PanelContainer = _page.find_child("HeroPaperboardFolder", true, false)
	var surface := SURFACE.new()
	surface.variant = variant
	surface.grain = previous.grain
	_replace_panel(previous, surface)
	# One continuous information strip instead of a ruled table.
	var stat: Control = _page.find_child("EquipmentStat_hp", true, false)
	var totals: HBoxContainer = stat.get_parent()
	var stat_panel: PanelContainer = totals.get_parent()
	stat_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for child in totals.get_children():
		if child is VSeparator:
			child.hide()
	var old_plaque: PanelContainer = _page.find_child("HeroCombatPower", true, false)
	var plaque := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PLAQUES[variant]
	style.border_color = INKS[variant]
	style.set_border_width_all(2)
	style.set_corner_radius_all(10 if variant != 1 else 5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	plaque.add_theme_stylebox_override("panel", style)
	_replace_panel(old_plaque, plaque)
	for label: Label in surface.find_children("*", "Label", true, false):
		var inside_card := false
		for side_name in ["HeroEquipmentLeft", "HeroEquipmentRight"]:
			var side: Node = _page.find_child(side_name, true, false)
			inside_card = inside_card or side.is_ancestor_of(label)
		if not inside_card:
			label.add_theme_color_override("font_color", INKS[variant])


func _replace_panel(previous: PanelContainer, replacement: PanelContainer) -> void:
	var parent := previous.get_parent()
	var index := previous.get_index()
	replacement.name = previous.name
	replacement.custom_minimum_size = previous.custom_minimum_size
	replacement.size_flags_horizontal = previous.size_flags_horizontal
	replacement.size_flags_vertical = previous.size_flags_vertical
	parent.remove_child(previous)
	for child in previous.get_children():
		previous.remove_child(child)
		replacement.add_child(child)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	previous.queue_free()


func _settle() -> void:
	await get_tree().create_timer(0.18).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var filename := "%s_%dx%d.png" % [label, _size.x, _size.y]
	_check(image.get_size() == _size and image.save_png(OUT.path_join(filename)) == OK, "capture_" + label)
	var surface: Control = _page.find_child("HeroPaperboardFolder", true, false)
	var stage: Control = _page.find_child("HeroPreviewStage", true, false)
	_captures.append({"file": filename, "variant": _variant, "window": [_size.x, _size.y], "surface": _rect(surface.get_global_rect()), "stage": _rect(stage.get_global_rect())})


func _rect(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _save_hash() -> String:
	return FileAccess.get_sha256(PlayerData.SAVE_PATH) if FileAccess.file_exists(PlayerData.SAVE_PATH) else "absent"


func _check(passed: bool, label: String) -> void:
	_checks.append({"label": label, "passed": passed})
	if not passed:
		_failed += 1
		push_error("HERO_SURFACE_REVIEW_FAIL " + label)
