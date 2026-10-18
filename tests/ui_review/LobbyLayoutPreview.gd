extends Node

# Production Home at native window sizes. Geometry uses both the 720x1280 design
# canvas and the actual screenshot pixels, so the small renders can be inspected directly.
# Shortcut input routing is covered separately by EventIconsPreview (22 real-click routes).
const OUT := "res://docs/ui_review/2026-10-19/lobby-layout"
const HomeScene = preload("res://game/menu/Home.tscn")
const DESIGN_SIZE := Vector2(720, 1280)
const WINDOW_SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]
const PROFILES := [
	{"name": "normal", "gold": 2400, "gems": 260, "cheated": false},
	{"name": "stress", "gold": 100000397, "gems": 9998139, "cheated": true},
]
const SHORTCUT_NAMES := ["LoginShortcut", "QuestsShortcut", "EventsShortcut", "CastleShortcut"]
const HEADER_NAMES := [
	"Header", "HeaderRow", "ProfileButton", "AvatarFrame", "GoldButton", "CurrencyGold",
	"GemsButton", "CurrencyGems", "HeaderTools", "HeaderActions", "SettingsButton", "CheatLabel",
]
const LOBBY_NAMES := [
	"LobbyTitle", "LobbyIsland", "LobbyStage", "LobbyPager", "LobbyRewards",
	"LobbyBattleButton", "LobbyBattleContent", "BattleActionBlock",
]

var _home: Control
var _battle: Control
var _captures: Array = []
var _failures := 0


func _ready() -> void:
	print("LOBBY_LAYOUT_USER_DIR ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.cheated = false
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	PlayerData.troops["kiem"]["level"] = 6
	PlayerData.troops["kiem"]["cards"] = 12
	for id in ["giao", "katana", "riu"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "katana"]
	PlayerData.patrol_last_claim = PlayerData.now() - 3 * 3600
	PlayerData.login_claimed = 3
	PlayerData.login_day = PlayerData.today() - 1
	get_window().size = WINDOW_SIZES[0]
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.BATTLE_TAB, false)
	_battle = _home._pages[_home.BATTLE_TAB]
	for size in WINDOW_SIZES:
		get_window().size = size
		await get_tree().process_frame
		await get_tree().process_frame
		for profile in PROFILES:
			PlayerData.gold = profile.gold
			PlayerData.gems = profile.gems
			PlayerData.cheated = profile.cheated
			_home._update_header()
			for view in [{"name": "lobby", "index": 2}, {"name": "locked", "index": 3}]:
				_battle._selected = view.index
				_battle.build()
				await _capture(profile.name + "_" + view.name, size)
	var manifest := {
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"design_size": [720, 1280], "native_render": true,
		"routing_fixture": "res://tests/ui_review/EventIconsPreview.tscn",
		"captures": _captures, "failures": _failures,
	}
	_write_json("manifest.json", manifest)
	print("LOBBY_LAYOUT_COMPLETE ", _captures.size(), " screens; failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _capture(key: String, requested: Vector2i) -> void:
	await get_tree().create_timer(0.22).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var file_key := "%s_%dx%d" % [key, requested.x, requested.y]
	if shot.get_size() != requested:
		_failures += 1
		push_error("Native lobby capture mismatch: %s expected %s, got %s" % [file_key, requested, shot.get_size()])
	_save_image(shot, file_key + ".png")
	var header_height := int(round(112.0 * shot.get_height() / DESIGN_SIZE.y))
	_save_image(shot.get_region(Rect2i(0, 0, shot.get_width(), header_height)), file_key + "_header.png")
	var render_scale := Vector2(shot.get_width(), shot.get_height()) / DESIGN_SIZE
	var geometry := _geometry(render_scale)
	var state := {
		"gold": PlayerData.gold, "gems": PlayerData.gems, "cheated": PlayerData.cheated,
		"selected_level_index": _battle._selected, "unlocked_levels": PlayerData.unlocked_levels,
		"locked": not PlayerData.can_select(_battle._selected),
	}
	var record := {
		"file": file_key + ".png", "header": file_key + "_header.png",
		"requested": [requested.x, requested.y], "actual": [shot.get_width(), shot.get_height()],
		"window": [get_window().size.x, get_window().size.y],
		"state": state, "geometry": geometry,
	}
	_captures.append(record)
	_write_json(file_key + "_geometry.json", record)
	print("LOBBY_LAYOUT_CAPTURE ", file_key, " native=", shot.get_size(), " locked=", state.locked)


func _geometry(render_scale: Vector2) -> Dictionary:
	var header := {}
	for node_name in HEADER_NAMES:
		_add_named_geometry(header, node_name, render_scale)
	_add_named_geometry(header, "AdminButton", render_scale, false)
	for currency in ["CurrencyGold", "CurrencyGems"]:
		var currency_root: Node = _home.find_child(currency, true, false)
		if currency_root != null:
			var pill: Node = currency_root.find_child("CurrencyPill", true, false)
			if pill is Control:
				header[currency + "_pill"] = _control_geometry(pill, render_scale)
	# These labels are production references, independent of any semantic node naming.
	header["gold_value"] = _control_geometry(_home._gold_label, render_scale)
	header["gems_value"] = _control_geometry(_home._gem_label, render_scale)
	header["cheat_value"] = _control_geometry(_home._cheat_label, render_scale)
	var shortcuts := {}
	for node_name in SHORTCUT_NAMES:
		_add_named_geometry(shortcuts, node_name, render_scale)
		var shortcut: Node = _home.find_child(node_name, true, false)
		if shortcut != null:
			for part_name in ["ShortcutIcon", "ShortcutCaption"]:
				var part: Node = shortcut.find_child(part_name, true, false)
				if part is Control:
					shortcuts[node_name][part_name] = _control_geometry(part, render_scale)
	var lobby := {}
	for node_name in LOBBY_NAMES:
		_add_named_geometry(lobby, node_name, render_scale)
	# Include the structural roots, useful when reading the stage's transparent artwork.
	lobby["stage_root"] = _control_geometry(_battle._stage, render_scale)
	lobby["layout_root"] = _control_geometry(_battle._column, render_scale)
	lobby["navigation_root"] = _control_geometry(_home._nav_holder, render_scale)
	var gaps := {
		"island_to_pager": _vertical_gap(lobby, "LobbyIsland", "LobbyPager", render_scale.y),
		"pager_to_rewards": _vertical_gap(lobby, "LobbyPager", "LobbyRewards", render_scale.y),
		"rewards_to_cta": _vertical_gap(lobby, "LobbyRewards", "LobbyBattleButton", render_scale.y),
		"cta_to_navigation": _vertical_gap(lobby, "LobbyBattleButton", "navigation_root", render_scale.y),
	}
	return {"header": header, "shortcuts": shortcuts, "lobby": lobby,
		"header_peer_overlaps": _header_overlaps(header),
		"vertical_gaps": gaps,
		"coordinate_system": {"design_canvas": [720, 1280], "render_scale": [render_scale.x, render_scale.y]}}


func _vertical_gap(group: Dictionary, before: String, after: String, render_scale: float) -> Dictionary:
	if not group.get(before, {}).has("design_rect") or not group.get(after, {}).has("design_rect"):
		return {"missing": true}
	var first: Array = group[before]["design_rect"]
	var second: Array = group[after]["design_rect"]
	var gap: float = second[1] - first[1] - first[3]
	return {"design_pixels": gap, "render_pixels": gap * render_scale}


func _header_overlaps(header: Dictionary) -> Array:
	var names := ["ProfileButton", "GoldButton", "GemsButton", "HeaderTools"]
	var overlaps := []
	for i in names.size():
		for j in range(i + 1, names.size()):
			var first: Dictionary = header.get(names[i], {})
			var second: Dictionary = header.get(names[j], {})
			if not first.get("visible", false) or not second.get("visible", false):
				continue
			var a: Array = first.design_rect
			var b: Array = second.design_rect
			var intersection := Rect2(a[0], a[1], a[2], a[3]).intersection(Rect2(b[0], b[1], b[2], b[3]))
			if intersection.has_area():
				overlaps.append({"first": names[i], "second": names[j], "design_rect": _rect_array(intersection)})
	return overlaps


func _add_named_geometry(group: Dictionary, node_name: String, render_scale: Vector2, required := true) -> void:
	var node: Node = _home.find_child(node_name, true, false)
	if node is Control:
		group[node_name] = _control_geometry(node, render_scale)
	else:
		group[node_name] = {"missing": true, "required": required}
		if required:
			_failures += 1
			push_error("Missing named lobby control: " + node_name)


func _control_geometry(control: Control, render_scale: Vector2) -> Dictionary:
	var rect := control.get_global_rect()
	var data := {
		"name": control.name, "path": str(_home.get_path_to(control)),
		"type": control.get_class(), "visible": control.is_visible_in_tree(),
		"design_rect": _rect_array(rect),
		"render_rect": _rect_array(Rect2(rect.position * render_scale, rect.size * render_scale)),
		"minimum_size": [control.get_combined_minimum_size().x, control.get_combined_minimum_size().y],
	}
	if control is Label:
		data["text"] = control.text
		data["font_size"] = control.get_theme_font_size("font_size")
		data["text_width"] = control.get_theme_font("font").get_string_size(
			control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, data["font_size"]).x
	if control is Button:
		data["text"] = control.text
		data["disabled"] = control.disabled
	return data


func _rect_array(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _write_json(file_name: String, data: Dictionary) -> void:
	var file := FileAccess.open(OUT + "/" + file_name, FileAccess.WRITE)
	if file == null:
		_failures += 1
		push_error("Could not write lobby review JSON: " + file_name)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _save_image(shot: Image, file_name: String) -> void:
	var error := shot.save_png(OUT + "/" + file_name)
	if error != OK:
		_failures += 1
		push_error("Could not save lobby review image: " + file_name)
