extends "res://docs/design/2026-10-24/hero-surface-review/HeroSurfaceReview.gd"

## A new composition after the three enclosing panels were rejected.
## Reuses production controls, but the hero is placed directly on the page.
const Ui = preload("res://game/ui/Ui.gd")
var _open_background: ColorRect
var design_slug := "open"


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
	_variant = 3
	for requested in SIZES:
		_size = requested
		get_window().size = requested
		_page.refresh()
		_apply_surface(3)
		await _settle()
		_audit_open()
		await _capture(design_slug)
	_size = Vector2i(450, 800)
	for weapon in WEAPONS:
		PlayerData.hero_cat.equipped.weapon = _uids[weapon]
		_page.refresh()
		_apply_surface(3)
		await _settle()
		_audit_open()
		var preview: Control = _page.find_child("HeroPreview", true, false)
		var rig: Node2D = preview.rig
		_check(rig.animation == "idle" and rig.has_animation("idle"), weapon + "_idle_loaded")
		var start_time: float = rig._time
		var prior: Array = rig._world.duplicate()
		var moved := false
		for frame in 12:
			await _capture("%s-%s-idle-%02d" % [design_slug, weapon, frame])
			await get_tree().create_timer(0.1).timeout
			await RenderingServer.frame_post_draw
			for bone in mini(prior.size(), rig._world.size()):
				var before_pose: Transform2D = prior[bone]
				moved = moved or not before_pose.is_equal_approx(rig._world[bone])
			_check(_hero_clear_of_ui(), weapon + "_idle_frame_clear_%d" % frame)
		_check(rig._time > start_time + 0.8 and moved, weapon + "_naturally_animated_bones")
	_home.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	PlayerData.from_dict(before)
	PlayerData.persist = persist_before
	HOME_SCRIPT.last_tab = tab_before
	_check(_save_hash() == save_before, "player_save_unchanged")
	var file := FileAccess.open(OUT.path_join(design_slug + "-review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope": "Review-only equipment composition: " + design_slug, "captures": _captures, "checks": _checks, "failures": _failed}, "\t"))
	file.close()
	print("HERO_%s_REVIEW_COMPLETE checks=" % design_slug.to_upper(), _checks.size(), " captures=", _captures.size(), " failures=", _failed)
	get_tree().quit(1 if _failed else 0)


func _apply_surface(_unused: int) -> void:
	# Home updates shared backdrop visibility each second. This proposal uses
	# a separate review-only surface so its color remains stable through idle.
	_home._hero_backdrop.modulate.a = 0.0
	if not is_instance_valid(_open_background):
		_open_background = Ui.pattern_bg(Color("405361"))
		_open_background.name = "OpenHeroReviewBackground"
		_home.add_child(_open_background)
		_home.move_child(_open_background, _home._hero_backdrop.get_index() + 1)
		_open_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material: ShaderMaterial = _open_background.material
	material.set_shader_parameter("sky", Color("405361"))
	material.set_shader_parameter("pattern_strength", 0.12)
	material.set_shader_parameter("top_light", 1.13)
	material.set_shader_parameter("bottom_light", 0.82)
	material.set_shader_parameter("tile_px", 360.0)
	var previous: PanelContainer = _page.find_child("HeroPaperboardFolder", true, false)
	var surface := _empty_panel(Vector4(18, 16, 18, 12))
	_replace_panel(previous, surface)
	var old_bag: PanelContainer = _page.find_child("HeroPaperboardInventory", true, false)
	_replace_panel(old_bag, _empty_panel(Vector4(18, 0, 18, 8)))
	var stage: Control = _page.find_child("HeroPreviewStage", true, false)
	stage.custom_minimum_size.y = 288
	for child in stage.get_children():
		if child is Label:
			child.hide()
	var preview: Control = stage.find_child("HeroPreview", true, false)
	preview.custom_minimum_size = Vector2(312, 244)
	preview.size = Vector2(312, 244)
	preview.offset_top = -8
	preview.offset_bottom = 236
	var old_plaque: PanelContainer = stage.find_child("HeroCombatPower", true, false)
	var plaque := _empty_panel(Vector4(4, 0, 4, 0))
	_replace_panel(old_plaque, plaque)
	plaque.custom_minimum_size.y = 48
	var holder: Control = plaque.get_parent()
	holder.offset_top = -48
	var power: HBoxContainer = plaque.get_child(0)
	var seal: PanelContainer = power.get_child(0)
	_replace_panel(seal, _empty_panel(Vector4.ZERO))
	var power_value: Label = power.get_child(1)
	power_value.add_theme_font_size_override("font_size", 40)
	var totals: HBoxContainer = _page.find_child("EquipmentStat_hp", true, false).get_parent()
	(totals.get_parent() as PanelContainer).add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for child in totals.get_children():
		if child is VSeparator:
			child.hide()
	for label: Label in surface.find_children("*", "Label", true, false):
		var in_card := false
		for side_name in ["HeroEquipmentLeft", "HeroEquipmentRight"]:
			in_card = in_card or _page.find_child(side_name, true, false).is_ancestor_of(label)
		if not in_card:
			label.add_theme_color_override("font_color", Color("fff0d5"))
			label.add_theme_color_override("font_outline_color", Color("27313b"))
			label.add_theme_constant_override("outline_size", 3)
	# Inventory resource counts also use the light text already in production.
	var scroll: Control = _page.find_child("HeroInventoryScroll", true, false)
	_check(scroll != null, "inventory_scroll_preserved")


func _empty_panel(margins: Vector4) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxEmpty.new()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, margins[side])
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _audit_open() -> void:
	_check(_hero_clear_of_ui(), "larger_hero_clear_of_equipment_and_power")
	var scroll: Control = _page.find_child("HeroInventoryScroll", true, false)
	_check(scroll.size.y >= 120, "usable_inventory_height")
	_check(_page.find_children("HeroPreview", "", true, false).size() == 1, "single_hero_preview")


func _hero_clear_of_ui() -> bool:
	var preview: Control = _page.find_child("HeroPreview", true, false)
	var rig: Node2D = preview.rig
	var bounds := Rect2()
	var started := false
	for slot: Dictionary in rig._slots:
		if not slot.shown:
			continue
		var rect: Rect2 = slot.rect
		var transform: Transform2D = rig.get_global_transform() * rig._world[slot.bone]
		for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			var point: Vector2 = transform * corner
			bounds = bounds.expand(point) if started else Rect2(point, Vector2.ZERO)
			started = true
	for name in ["HeroEquipmentLeft", "HeroEquipmentRight", "HeroCombatPower"]:
		var node: Control = _page.find_child(name, true, false)
		if node.get_global_rect().intersects(bounds):
			return false
	return started
