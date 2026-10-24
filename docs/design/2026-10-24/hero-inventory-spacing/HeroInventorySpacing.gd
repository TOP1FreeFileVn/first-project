extends "res://docs/design/2026-10-23/equipment-ui-integration/ReviewEquipmentIntegration.gd"

## Actual production controls and authored idle, without visual overrides.
const WEAPON_CASES := [["kiem_go", "melee"], ["cung_san", "ranged"], ["gay_sao", "magic"], ["riu_lua", "heavy"]]
const EXPECTED_MASK_OFFSET := 12.0
const EXPECTED_BAG_HEIGHT := 576.0 + EXPECTED_MASK_OFFSET
var _idle_samples: Array = []


func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	_out = "res://docs/design/2026-10-24/hero-inventory-spacing/native"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	_original_state = PlayerData.to_dict().duplicate(true)
	_original_persist = PlayerData.persist
	_original_tab = HOME_SCRIPT.last_tab
	PlayerData.persist = false
	_save_before = _save_hash()
	for requested in SIZES:
		_size = requested
		_fixture("full")
		await _mount()
		_check(HeroCat.ITEMS.size() == 17 and HeroCat.spare(PlayerData.hero_cat).size() == 13, "production_seventeen_items_thirteen_spares")
		_audit_spacing("full")
		await _capture("full-three-rows")
		print("HERO_SPACING_CAPTURE_READY ", _out.path_join("full-three-rows_%dx%d.png" % [_size.x, _size.y]))
		var preview_id: int = _page.find_child("HeroPreview", true, false).get_instance_id()
		for weapon in WEAPON_CASES:
			PlayerData.hero_cat.equipped.weapon = _uids[weapon[0]]
			_page.refresh()
			await _settle()
			_check(_page.find_child("HeroPreview", true, false).get_instance_id() == preview_id, weapon[0] + "_preview_instance_preserved")
			await _sample_idle(weapon[0], weapon[1])
		await _audit_fuse()
		_check_native_nav("after_spacing_review")
		await _unmount()
	_check(not PlayerData.persist and _save_before == _save_hash(), "no_player_save_write_during_review")
	PlayerData.from_dict(_original_state)
	HOME_SCRIPT.last_tab = _original_tab
	_check(PlayerData.to_dict() == _original_state, "original_in_memory_profile_restored")
	_check(_save_before == _save_hash(), "profile_restore_never_writes_save")
	PlayerData.persist = _original_persist
	_finish()


func _audit_spacing(context: String) -> void:
	_audit_grid(HeroCat.ITEMS.size() - WORN.size())
	var grid := _bag_grid()
	var scroll := _bag_scroll()
	var bag := _page.find_child("HeroPaperboardInventory", true, false) as Control
	var hero := _page.find_child("HeroPaperboardFolder", true, false) as Control
	var header := _page.find_child("HeroEquipmentSectionHeader", true, false) as Control
	_check(grid != null and scroll != null and bag != null and hero != null and header != null, context + "_production_sections_exist")
	if grid == null or scroll == null or bag == null or hero == null or header == null:
		return
	var scroll_rect := scroll.get_global_rect()
	var visible := true
	var bottom := 0.0
	var rows: Array[float] = []
	for card: Control in grid.get_children():
		var rect := card.get_global_rect()
		visible = visible and scroll_rect.grow(0.2).encloses(rect)
		bottom = maxf(bottom, rect.end.y)
		if rows.is_empty() or absf(rows.back() - rect.position.y) > 0.2:
			rows.append(rect.position.y)
	_check(rows.size() == 3 and visible, context + "_three_full_rows_visible_without_scrolling")
	var nav_top: float = _home._nav_holder.get_global_rect().position.y
	var content_bottom: float = _home._content.get_global_rect().end.y
	var nav_hit_top := _nav_hit_top()
	var clearance := nav_top - bottom
	_check(clearance >= 8.0 and clearance <= 24.0, context + "_last_row_close_to_nav_without_overlap")
	_check(absf(hero.get_global_rect().end.y - header.get_global_rect().position.y) < 0.2, context + "_hero_and_full_width_header_share_boundary")
	_check(absf(hero.size.y - 500.0) < 0.2 and absf(bag.size.y - EXPECTED_BAG_HEIGHT) < 0.2, context + "_hero_height_unchanged_and_inventory_extends_twelve_pixels")
	_check(absf(content_bottom - nav_top - EXPECTED_MASK_OFFSET) < 0.2, context + "_page_clip_extends_twelve_pixels_below_nav_origin")
	_check(absf(scroll_rect.end.y - (content_bottom - 8.0)) < 0.2 and scroll_rect.end.y <= nav_hit_top - 1.0, context + "_lower_scroll_clip_stays_clear_of_nav_hitboxes")
	_check(scroll.size.y >= 420.0 and scroll.scroll_vertical == 0, context + "_three_row_viewport_keeps_badge_padding")
	var page_rect: Rect2 = _page.get_global_rect()
	_check(page_rect.grow(0.2).encloses(hero.get_global_rect()) and page_rect.grow(0.2).encloses(bag.get_global_rect()), context + "_hero_and_inventory_stay_inside_page_bounds")
	_check(not scroll.get_v_scroll_bar().is_visible_in_tree(), context + "_three_rows_do_not_need_a_scrollbar")
	var style := hero.get_theme_stylebox("panel")
	var hero_rect := hero.get_global_rect()
	_geometry.append({"context": context, "window": [_size.x, _size.y], "hero": _rect(hero_rect), "inventory": _rect(bag.get_global_rect()), "header": _rect(header.get_global_rect()), "scroll": _rect(scroll_rect), "row_tops": rows, "last_card_bottom": bottom, "nav_top": nav_top, "nav_hit_top": nav_hit_top, "content_bottom": content_bottom, "mask_offset": content_bottom - nav_top, "scroll_hitbox_clearance": nav_hit_top - scroll_rect.end.y, "clearance": clearance, "hero_layout_style": style.get_class()})
	_check_native_nav(context)


func _nav_hit_top() -> float:
	var top := INF
	for index in 5:
		var button := _nav_button(index)
		if button != null:
			top = minf(top, button.get_global_rect().position.y)
	_check(is_finite(top), "original_nav_has_visible_button_hitboxes")
	return top


func _sample_idle(weapon_id: String, expected_family: String) -> void:
	var previews: Array[Node] = _page.find_children("HeroPreview", "Control", true, false)
	_check(previews.size() == 1, weapon_id + "_exactly_one_hero_preview")
	if previews.size() != 1:
		return
	var preview: Control = previews[0]
	var rig: Node2D = preview.get("rig")
	_check(rig != null and preview.get("family") == expected_family, weapon_id + "_correct_equipped_family")
	if rig == null:
		return
	_check(rig.get("animation") == "idle" and rig.has_animation("idle"), weapon_id + "_authored_idle_loaded")
	var previous_time: float = rig.get("_time")
	var previous: Array = rig.get("_world").duplicate()
	var moved := false
	for index in 4:
		await get_tree().create_timer(0.20).timeout
		await RenderingServer.frame_post_draw
		var pose: Array = rig.get("_world")
		for bone in mini(previous.size(), pose.size()):
			var a: Transform2D = previous[bone]
			var b: Transform2D = pose[bone]
			moved = moved or not a.is_equal_approx(b)
		var bounds := _painted_bounds(rig)
		var stage := _page.find_child("HeroPreviewStage", true, false) as Control
		_check(bounds.has_area() and stage.get_global_rect().grow(0.2).encloses(bounds), "%s_idle_%d_fits_stage" % [weapon_id, index])
		for target in ["HeroEquipmentLeft", "HeroEquipmentRight", "HeroCombatPower"]:
			var control := _page.find_child(target, true, false) as Control
			_check(control != null and not control.get_global_rect().intersects(bounds), "%s_idle_%d_clear_of_%s" % [weapon_id, index, target])
		_idle_samples.append({"weapon": weapon_id, "window": [_size.x, _size.y], "frame": index, "family": expected_family, "time": rig.get("_time"), "painted_bounds": _rect(bounds), "stage": _rect(stage.get_global_rect())})
		if index == 0 or index == 3:
			await _capture("%s-idle-%d" % [expected_family, index])
	_check(float(rig.get("_time")) > previous_time + 0.4 and moved, weapon_id + "_idle_advances_and_moves_without_manual_seeking")


func _painted_bounds(rig: Node2D) -> Rect2:
	var world: Array = rig.get("_world")
	var bounds := Rect2()
	var started := false
	for slot: Dictionary in rig.get("_slots"):
		if not slot.get("shown", false) or int(slot.bone) >= world.size():
			continue
		var image: Image = slot.texture.get_image()
		if image == null:
			continue
		var used := image.get_used_rect()
		if not used.has_area():
			continue
		var rect: Rect2 = slot.rect
		var image_size := Vector2(image.get_size())
		var painted := Rect2(rect.position + Vector2(used.position) / image_size * rect.size, Vector2(used.size) / image_size * rect.size)
		var transform: Transform2D = rig.get_global_transform() * world[int(slot.bone)]
		for corner in [painted.position, Vector2(painted.end.x, painted.position.y), painted.end, Vector2(painted.position.x, painted.end.y)]:
			var point: Vector2 = transform * corner
			bounds = bounds.expand(point) if started else Rect2(point, Vector2.ZERO)
			started = true
	return bounds


func _audit_fuse() -> void:
	var header := _page.find_child("HeroEquipmentSectionHeader", true, false) as Control
	var before := header.get_global_rect()
	var prior_scroll_height := _bag_scroll().size.y
	HeroCat.add_item(PlayerData.hero_cat, "kiem_go")
	HeroCat.add_item(PlayerData.hero_cat, "kiem_go")
	_page.refresh()
	await _settle()
	header = _page.find_child("HeroEquipmentSectionHeader", true, false) as Control
	var fuse := _page.find_child("EquipmentFuse", true, false) as Button
	var scroll := _bag_scroll()
	_check(fuse != null and fuse.is_visible_in_tree(), "fuse_state_shows_real_fuse_action")
	_check(header.get_global_rect().is_equal_approx(before), "fuse_state_header_stays_at_same_boundary")
	_check(scroll.size.y >= 124.0 and scroll.size.y < prior_scroll_height, "fuse_state_uses_scroll_space_without_overflow")
	var page_rect: Rect2 = _page.get_global_rect()
	var bag := _page.find_child("HeroPaperboardInventory", true, false) as Control
	_check(page_rect.grow(0.2).encloses(bag.get_global_rect()), "fuse_state_inventory_stays_inside_page_width")
	var cards := _bag_grid().get_children()
	if not cards.is_empty():
		scroll.ensure_control_visible(cards.back())
		await _settle()
		_check(scroll.scroll_vertical > 0 and scroll.get_global_rect().grow(0.2).encloses(cards.back().get_global_rect()), "fuse_state_last_item_reachable_by_scrolling")
	var nav_top: float = _home._nav_holder.get_global_rect().position.y
	var content_bottom: float = _home._content.get_global_rect().end.y
	_check(absf(content_bottom - nav_top - EXPECTED_MASK_OFFSET) < 0.2, "fuse_state_keeps_twelve_pixel_lower_clip_offset")
	_check(scroll.get_global_rect().end.y <= _nav_hit_top() - 1.0, "fuse_state_scroll_stays_clear_of_nav_hitboxes")
	await _capture("fuse-scroll")


func _finish() -> void:
	var report := {"scope": "Actual production hero/inventory spacing at two phone sizes; 17 real items, 13 spares in 3 visible five-column rows, four authored weapon idles, stable fuse header and reachable inventory. The inventory clip extends 12 logical pixels below the navigation origin while staying clear of its button hitboxes. No visual overrides.", "profile": OS.get_user_data_dir(), "original_persist_restored": PlayerData.persist == _original_persist, "save_before": _save_before, "save_after": _save_hash(), "checks": _checks, "captures": _captures, "geometry": _geometry, "idle_samples": _idle_samples, "failures": _failures}
	var file := FileAccess.open(_out.path_join("review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("HERO_INVENTORY_SPACING_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
