extends Node

# Production Home/TroopsPage validation. All profile changes are isolated and in RAM.
const HomeScene = preload("res://game/menu/Home.tscn")
const Economy = preload("res://game/core/Economy.gd")
const OUT := "res://docs/ui_review/2026-10-19/troops-compact"
const DESIGN_SIZE := Vector2(720, 1280)
const SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]
const FILTER_NAMES := ["all", "common", "rare", "epic", "legendary"]

@export var native_width := 720
@export var output_dir := OUT
@export var require_rarity_field := false
@export var scenario_name := ""
@export var level_in_corner := true

var _home: Control
var _page: Control
var _captures: Array = []
var _routes: Array = []
var _failures: Array = []
var _scenario := ""
var _native := Vector2i.ZERO
var _filter_audio_checked := false


func _ready() -> void:
	_filter_audio_checked = scenario_name == "late"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	get_window().size = Vector2i(native_width, native_width * 16 / 9)
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(3, false)
	_page = _home._pages[3]
	for native in SIZES:
		if native.x != native_width:
			continue
		_native = native
		get_window().size = native
		await _settle()
		for scenario in ["starter", "late"]:
			if scenario_name != "" and scenario != scenario_name:
				continue
			_scenario = scenario
			_setup_state(scenario)
			await _settle()
			for filter_index in range(5):
				var rarity := filter_index - 1
				var button := _filter_button(rarity)
				var inspect_audio := not _filter_audio_checked
				if inspect_audio:
					await get_tree().create_timer(0.04).timeout
				var tap_index_before: int = SoundLib._ui_tap_index
				var received := await _tap(button)
				await _settle()
				_record("filter_" + FILTER_NAMES[filter_index], received and _page._filter == rarity)
				if inspect_audio:
					_record("filter_click_audio_once", received and SoundLib.has_sound("click")
						and SoundLib._ui_tap_index == (tap_index_before + 1) % SoundLib.UI_TAPS.size())
					_filter_audio_checked = true
				await _capture(FILTER_NAMES[filter_index])
			await _tap(_filter_button(-1))
			await _settle()
			await _scroll_to_end()
			await _capture("all_scrolled")
			_page._scroll.scroll_vertical = 0
			await _settle()
			await _detail_routes()
			await _drag_routes()
	var suffix := "_" + scenario_name if scenario_name != "" else ""
	_write_json("manifest_%d%s.json" % [native_width, suffix], {"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"native_render": true, "design_size": [720, 1280], "captures": _captures,
		"routes": _routes, "failures": _failures, "failure_count": _failures.size()})
	print("TROOPS_COMPACT_COMPLETE ", _captures.size(), " native screens; ", _routes.size(), " routes; failures=", _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)


func _setup_state(scenario: String) -> void:
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 100000577
	PlayerData.gems = 9998159
	PlayerData.sound_on = true
	PlayerData.castle_level = 1 if scenario == "starter" else 6
	for id in ["kiem", "riu", "gay_phep", "cung", "chuy"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["gay_phep", "cung", "chuy"]
	if scenario == "late":
		for id in ["katana", "dai_bac", "thuoc"]:
			PlayerData.troops[id]["unlocked"] = true
		PlayerData.team = ["gay_phep", "cung", "chuy", "katana", "thuoc"]
	PlayerData.troops["kiem"]["level"] = PlayerData.level_cap("kiem")
	PlayerData.troops["kiem"]["cards"] = PlayerData.star_up_cost("kiem")
	PlayerData.troops["riu"]["cards"] = 3
	_page._filter = -1
	_page._swap_id = ""
	_page.refresh()
	_page._scroll.scroll_vertical = 0
	_home._update_header()


func _filter_button(rarity: int) -> Button:
	var named := _page.find_child("TroopFilter_%d" % rarity, true, false) as Button
	if named != null:
		return named
	return _button_text(_page._top, "Tất cả" if rarity < 0 else Economy.RARITY_NAMES[rarity])


func _capture(label: String) -> void:
	await _settle()
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var key := "%s_%s_%dx%d" % [_scenario, label, _native.x, _native.y]
	_check(shot.get_size() == _native, "Native image size: " + key)
	_check(shot.save_png(output_dir + "/" + key + ".png") == OK, "Image saved: " + key)
	var grid := _page.find_child("TroopGrid", true, false) as GridContainer
	var record := {"key": key, "file": key + ".png", "filter": _page._filter,
		"native_size": [_native.x, _native.y], "castle": PlayerData.castle_level,
		"team": PlayerData.battle_team(), "slots": PlayerData.team_slots(), "cards": []}
	record["top_labels"] = _label_geometry(_page._top)
	if require_rarity_field:
		var filters: Array = []
		for rarity in range(-1, 4):
			var filter := _filter_button(rarity)
			if filter != null:
				filters.append(_geometry(filter))
				var style := filter.get_theme_stylebox("normal")
				var available := filter.size.x - style.content_margin_left - style.content_margin_right
				var font_size := filter.get_theme_font_size("font_size")
				var text_width := filter.get_theme_font("font").get_string_size(
					filter.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				_check(text_width <= available + 1.0, "Filter text fits: " + key + "/" + filter.text)
		record["filters"] = filters
	_check(grid != null, "TroopGrid exists: " + key)
	if grid != null:
		_check(grid.columns == 4, "Four grid columns: " + key)
		record["grid"] = _geometry(grid)
		var expected := 0
		for id in PlayerData.TROOP_ORDER:
			if _page._filter < 0 or PlayerData.rarity_of(id) == _page._filter:
				expected += 1
		_check(grid.get_child_count() == expected, "Filter count: " + key)
		var width := -1.0
		var scroll_rect: Rect2 = _page._scroll.get_global_rect()
		for child in grid.get_children():
			var card := child as Button
			if card == null:
				_check(false, "Grid child is a troop button: " + key)
				continue
			if width < 0.0:
				width = card.size.x
			_check(absf(card.size.x - width) <= 1.0, "Equal card widths: " + key)
			var rect := card.get_global_rect()
			_check(rect.position.x >= scroll_rect.position.x and rect.end.x <= scroll_rect.end.x + 1.0,
				"Card stays in scroll width: " + key + "/" + str(card.name))
			var id := str(card.name).trim_prefix("TroopCard_")
			var info := {"id": id, "card": _geometry(card)}
			if PlayerData.TROOPS.has(id):
				_check(_page._filter < 0 or PlayerData.rarity_of(id) == _page._filter,
					"Card belongs to filter: " + key + "/" + id)
				info["unlocked"] = PlayerData.is_unlocked(id)
				info["in_team"] = PlayerData.in_team(id)
				info["rarity"] = PlayerData.rarity_of(id)
				for marker in ["TroopStarReady", "TroopLevelReady", "TroopInTeam"]:
					var found := card.find_child(marker, true, false) as Control
					info[marker] = _geometry(found) if found != null else {"missing": true}
			var name_label := card.find_child("TroopName", true, false) as Label
			_check(name_label != null, "Card name label exists: " + key + "/" + id)
			if name_label != null:
				info["name"] = _geometry(name_label)
				_check(not name_label.text.begins_with("Mèo "), "Short troop name: " + key + "/" + id)
				_check(_name_fits(name_label), "Complete name fits: " + key + "/" + id)
				_check(rect.grow(1.0).encloses(name_label.get_global_rect()), "Name inside card: " + key + "/" + id)
			var field := card.find_child("TroopRarityField", true, false) as Control
			if require_rarity_field:
				_check(field != null, "Rarity field exists: " + key + "/" + id)
			if field != null:
				info["TroopRarityField"] = _geometry(field)
				if require_rarity_field:
					_check(field.has_meta("rarity") and int(field.get_meta("rarity", -1)) == PlayerData.rarity_of(id),
						"Rarity field matches troop rarity: " + key + "/" + id)
				_check(rect.grow(1.0).encloses(field.get_global_rect()), "Rarity field inside card: " + key + "/" + id)
				var backing := field.find_child("TroopRarityBackground", true, false) as Control
				if backing != null:
					info["TroopRarityBackground"] = _geometry(backing)
					_check(field.get_global_rect().grow(1.0).encloses(backing.get_global_rect()),
						"Rarity background inside field: " + key + "/" + id)
				if name_label != null:
					_check(field.get_global_rect().end.y <= name_label.get_global_rect().position.y + 1.0,
						"Rarity field ends before name: " + key + "/" + id)
			for node_name in ["TroopLevel", "TroopPortrait"]:
				var node := card.find_child(node_name, true, false) as Control
				if node_name != "TroopLevel" or PlayerData.is_unlocked(id):
					_check(node != null, node_name + " exists: " + key + "/" + id)
				if node != null:
					info[node_name] = _geometry(node)
					_check(rect.grow(1.0).encloses(node.get_global_rect()), node_name + " inside card: " + key + "/" + id)
					if node_name == "TroopPortrait" and field != null:
						_check(field.get_global_rect().grow(1.0).encloses(node.get_global_rect()),
							"Portrait inside rarity field: " + key + "/" + id)
			for node_name in ["TroopStars", "TroopCardDetails"]:
				var node := card.find_child(node_name, true, false) as Control
				if node != null:
					info[node_name] = _geometry(node)
					_check(rect.grow(1.0).encloses(node.get_global_rect()), node_name + " inside card: " + key + "/" + id)
			var details := card.find_child("TroopCardDetails", true, false) as Control
			if details != null:
				for node_name in ["TroopName", "TroopLevel", "TroopStars"]:
					if level_in_corner and node_name == "TroopLevel":
						continue
					var node := card.find_child(node_name, true, false) as Control
					if node != null:
						_check(details.get_global_rect().grow(1.0).encloses(node.get_global_rect()),
							node_name + " inside card details: " + key + "/" + id)
			if level_in_corner:
				_check_corner_level(card, field, name_label, key, id)
			record.cards.append(info)
		if _page._filter == -1:
			_check_marker("kiem", "TroopStarReady")
			_check_marker("riu", "TroopLevelReady")
			_check_marker("gay_phep", "TroopInTeam")
		var slots: Array = []
		for i in range(5):
			var slot := _page.find_child("TeamSlot_%d" % i, true, false) as Control
			_check(slot != null, "Team slot exists: " + key + "/" + str(i))
			if slot != null:
				slots.append(_geometry(slot))
				if require_rarity_field:
					_check_slot_labels(slot, key)
		record["team_slots"] = slots
	_captures.append(record)
	_write_json(key + "_geometry.json", record)
	print("TROOPS_COMPACT_CAPTURE ", key)


func _name_fits(label: Label) -> bool:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var lines := label.get_line_count()
	if label.max_lines_visible > 0 and label.max_lines_visible < lines:
		return false
	if label.get_visible_line_count() < lines:
		return false
	if font.get_height(font_size) * lines > label.size.y + 2.0:
		return false
	if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
		return font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= label.size.x + 1.0
	for word in label.text.split(" "):
		if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x + 1.0:
			return false
	return true


func _check_corner_level(card: Control, field: Control, name_label: Label, key: String, id: String) -> void:
	if name_label != null:
		_check(name_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER,
			"Footer name centered: " + key + "/" + id)
	var stars := card.find_child("TroopStars", true, false) as Control
	if stars != null:
		_check(absf(stars.get_global_rect().get_center().x - card.get_global_rect().get_center().x) <= 1.0,
			"Footer stars centered: " + key + "/" + id)
	var level := card.find_child("TroopLevel", true, false) as Label
	if not PlayerData.is_unlocked(id):
		_check(level == null, "Locked troop has no level badge: " + key + "/" + id)
		return
	if level == null or field == null:
		return
	var rect := level.get_global_rect()
	var card_rect := card.get_global_rect()
	var field_rect := field.get_global_rect()
	_check(field_rect.grow(1.0).encloses(rect), "Corner level inside rarity field: " + key + "/" + id)
	_check(rect.get_center().x > card_rect.get_center().x and rect.position.y < field_rect.get_center().y
		and absf(field_rect.end.x - rect.end.x) <= 1.0,
		"Level placed in top-right corner: " + key + "/" + id)
	_check(_name_fits(level), "Corner level text fits: " + key + "/" + id)
	for node_name in ["TroopPortrait", "TroopName", "TroopInTeam", "TroopStarReady", "TroopLevelReady"]:
		var other := card.find_child(node_name, true, false) as Control
		if other != null:
			_check(not rect.intersects(other.get_global_rect()), "Corner level clears " + node_name + ": " + key + "/" + id)


func _check_marker(id: String, marker: String) -> void:
	var card := _page.find_child("TroopCard_" + id, true, false)
	var found: Control = card.find_child(marker, true, false) if card != null else null
	_check(found != null and found.is_visible_in_tree(), marker + " shown on " + id)


func _detail_routes() -> void:
	var received := await _tap(_page.find_child("TroopCard_kiem", true, false) as Button)
	await _settle()
	_record("tap_troop_opens_detail", received and is_instance_valid(_page._detail_screen) and _page._detail_id == "kiem")
	if is_instance_valid(_page._detail_screen):
		await get_tree().create_timer(0.14).timeout
		var old_stars: int = PlayerData.troop("kiem")["stars"]
		var old_cards: int = PlayerData.troop("kiem")["cards"]
		var star_cost := PlayerData.star_up_cost("kiem")
		var star_tab_received := await _tap(_detail_button("TroopUpgradeStarTab"))
		await _settle()
		var star_received := await _tap(_detail_button("TroopUpgradePrimary"))
		await _settle()
		_record("detail_star_upgrade", star_tab_received and star_received and PlayerData.troop("kiem")["stars"] == old_stars + 1
			and PlayerData.troop("kiem")["cards"] == old_cards - star_cost)
		var old_level: int = PlayerData.troop("kiem")["level"]
		var old_gold: int = PlayerData.gold
		var level_cost := PlayerData.level_up_cost("kiem")
		var level_tab_received := await _tap(_detail_button("TroopUpgradeLevelTab"))
		await _settle()
		var level_received := await _tap(_detail_button("TroopUpgradePrimary"))
		await _settle()
		_record("detail_level_upgrade", level_tab_received and level_received and PlayerData.troop("kiem")["level"] == old_level + 1
			and PlayerData.gold == old_gold - level_cost)
		await _close_detail("upgrade_detail_close")
	var locked_card := _page.find_child("TroopCard_dao", true, false) as Button
	var locked_received := await _tap(locked_card)
	await _settle()
	_record("locked_troop_opens_detail", locked_received and is_instance_valid(_page._detail_screen) and _page._detail_id == "dao")
	if is_instance_valid(_page._detail_screen):
		await get_tree().create_timer(0.14).timeout
		var primary := _detail_button("TroopUpgradePrimary")
		_record("locked_detail_has_no_upgrade", primary != null and primary.disabled)
		await _close_detail("locked_detail_close")


func _detail_button(node_name: String) -> Button:
	if not is_instance_valid(_page._detail_screen):
		return null
	return _page._detail_screen.find_child(node_name, true, false) as Button


func _close_detail(route: String) -> void:
	var screen: Control = _page._detail_screen
	var layer := screen.get_parent()
	var received := await _tap(_detail_button("TroopUpgradeBack"))
	await _settle()
	_record(route, received and not is_instance_valid(layer) and not is_instance_valid(_page._detail_screen))
	if is_instance_valid(layer):
		layer.queue_free()
		await _settle()


func _drag_routes() -> void:
	_page._scroll.scroll_vertical = 0
	await _settle()
	var old_team: Array = PlayerData.battle_team().duplicate()
	var from := _page.find_child("TeamSlot_0", true, false) as Control
	var target := _page.find_child("TeamSlot_1", true, false) as Control
	var sent := await _drag(from, target)
	var expected := old_team.duplicate()
	expected[0] = old_team[1]
	expected[1] = old_team[0]
	_record("drag_team_slots_swaps", sent and PlayerData.battle_team() == expected)
	var card := _page.find_child("TroopCard_riu", true, false) as Control
	target = _page.find_child("TeamSlot_0", true, false) as Control
	var roster_sent := await _drag(card, target)
	_record("drag_roster_to_team_replaces", roster_sent and PlayerData.battle_team()[0] == "riu")
	_record("drag_does_not_open_detail", not is_instance_valid(_page._detail_screen))


func _drag(source: Control, target: Control) -> bool:
	if source == null or target == null:
		return false
	var begin := source.get_global_rect().get_center()
	var end := target.get_global_rect().get_center()
	await _mouse_button(begin, true)
	await _motion(begin + Vector2(24, 0), Vector2(24, 0), true)
	await get_tree().process_frame
	await _motion(end, end - begin, true)
	await get_tree().process_frame
	var ghost_started: bool = is_instance_valid(_page._ghost)
	await _mouse_button(end, false)
	await _settle()
	return ghost_started


func _scroll_to_end() -> void:
	var at: Vector2 = _page._scroll.get_global_rect().get_center()
	var bar: VScrollBar = _page._scroll.get_v_scroll_bar()
	# The roster can grow as card spacing or the collection changes.
	for i in range(40):
		if _page._scroll.scroll_vertical >= bar.max_value - bar.page - 1:
			break
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_WHEEL_DOWN
			event.pressed = pressed
			event.position = at
			event.global_position = at
			get_viewport().push_input(event, true)
		await get_tree().process_frame
	var limit := bar.max_value - bar.page
	_record("wheel_reaches_collection_end", limit > 0 and _page._scroll.scroll_vertical >= limit - 1)


func _tap(button: Button) -> bool:
	if button == null or not is_instance_valid(button) or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var at := button.get_global_rect().get_center()
	await _mouse_button(at, true)
	if require_rarity_field and str(button.name).begins_with("TroopCard_"):
		var pressed_field := button.find_child("TroopRarityField", true, false) as Control
		_check(button.button_pressed and pressed_field != null and pressed_field.is_visible_in_tree(),
			"Rarity field visible while troop button pressed: " + str(button.name))
	await _mouse_button(at, false)
	return received[0]


func _mouse_button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	get_viewport().push_input(event, true)
	await get_tree().process_frame


func _motion(at: Vector2, relative: Vector2, held: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	get_viewport().push_input(event, true)
	await get_tree().process_frame


func _button_text(node: Node, value: String, prefix := false) -> Button:
	if node is Button and (node.text.begins_with(value) if prefix else node.text == value):
		return node
	for child in node.get_children():
		var found := _button_text(child, value, prefix)
		if found != null:
			return found
	return null


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _geometry(control: Control) -> Dictionary:
	var rect := control.get_global_rect()
	var scale := float(_native.x) / DESIGN_SIZE.x
	var info := {"name": str(control.name), "design_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"native_rect": [rect.position.x * scale, rect.position.y * scale, rect.size.x * scale, rect.size.y * scale],
		"visible": control.is_visible_in_tree(), "theme_type_variation": control.theme_type_variation}
	if control is TextureRect and control.texture != null:
		info["texture"] = control.texture.resource_path
	if control is PanelContainer:
		var panel_style := control.get_theme_stylebox("panel")
		if panel_style is StyleBoxFlat:
			info["fill_color"] = panel_style.bg_color.to_html()
		elif panel_style is StyleBoxTexture and panel_style.texture != null:
			info["texture"] = panel_style.texture.resource_path
	for meta_key in ["rarity", "tone", "rarity_color", "fill_color", "locked"]:
		if control.has_meta(meta_key):
			var value: Variant = control.get_meta(meta_key)
			info["meta_" + meta_key] = value.to_html() if value is Color else value
	if control is Label:
		info["text"] = control.text
		info["font_size_design"] = control.get_theme_font_size("font_size")
		info["font_size_native"] = control.get_theme_font_size("font_size") * scale
		info["line_count"] = control.get_line_count()
		info["visible_line_count"] = control.get_visible_line_count()
		info["outline_design"] = control.get_theme_constant("outline_size")
		info.merge(_font_info(control, control.text))
	if control is Button:
		info["text"] = control.text
		info["font_size_design"] = control.get_theme_font_size("font_size")
		info["font_size_native"] = control.get_theme_font_size("font_size") * scale
		info.merge(_font_info(control, control.text))
	return info


func _font_info(control: Control, text: String) -> Dictionary:
	var font := control.get_theme_font("font")
	var result := {"font_name": font.get_font_name(), "font_class": font.get_class(),
		"font_resource": font.resource_path, "vietnamese_chars": {}}
	if font is FontVariation and font.base_font != null:
		result["base_font_name"] = font.base_font.get_font_name()
		result["base_font_resource"] = font.base_font.resource_path
	for index in range(text.length()):
		var code := text.unicode_at(index)
		if not ((code >= 0x00c0 and code <= 0x024f) or (code >= 0x1e00 and code <= 0x1eff)):
			continue
		var character := text.substr(index, 1)
		var coverage := {"codepoint": code, "font_has_char": font.has_char(code)}
		if font is FontVariation and font.base_font != null:
			coverage["base_font_has_char"] = font.base_font.has_char(code)
		result.vietnamese_chars[character] = coverage
	return result


func _label_geometry(node: Node) -> Array:
	var labels: Array = []
	if node is Label:
		labels.append(_geometry(node))
	for child in node.get_children():
		labels.append_array(_label_geometry(child))
	return labels


func _check_slot_labels(slot: Control, key: String, node: Node = null) -> void:
	if node == null:
		node = slot
	if node is Label:
		_check(_name_fits(node), "Team slot label fits: " + key + "/" + node.text)
		if str(node.name) == "TeamTroopName":
			_check(node.get_line_count() == 1, "Team troop name stays on one line: " + key + "/" + node.text)
		_check(slot.get_global_rect().grow(1.0).encloses(node.get_global_rect()),
			"Team slot label inside slot: " + key + "/" + node.text)
	for child in node.get_children():
		_check_slot_labels(slot, key, child)


func _record(route: String, passed: bool) -> void:
	_routes.append({"route": route, "scenario": _scenario, "native_size": [_native.x, _native.y], "passed": passed})
	_check(passed, route)


func _check(passed: bool, message: String) -> void:
	if passed:
		return
	var reason := "%s %s %dx%d: %s" % [_scenario, _page._filter, _native.x, _native.y, message]
	_failures.append(reason)
	push_error(reason)


func _write_json(file_name: String, value: Dictionary) -> void:
	var file := FileAccess.open(output_dir + "/" + file_name, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t"))
	file.close()
