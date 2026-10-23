extends Node

# Native Home integration: real arrow/tab input, actual exported level textures,
# unchanged persistent courtyard and cats, and a disposable in-memory profile.
const OUT := "res://docs/ui_review/2026-10-23/lobby-regional-titles-all15"
const ART := "res://game/assets/lobby/map-titles/"
const SLUGS := [
	"dong-co", "doi-da", "phao-dai-do", "rung-thong", "hem-nui",
	"lang-bo-hoang", "dam-lay", "thanh-da-den", "cong-phao-dai", "vua-do",
	"ben-cang", "rung-suong", "doi-cuu", "mo-vang", "cau-da",
]
var _home
var _page
var _world
var _world_id := 0
var _actor_ids := {}
var _checks: Array = []
var _shots: Array = []
var _failures: Array = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false
	PlayerData.music_on = false
	PlayerData.castle_level = 3
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.unlocked_levels = 15
	get_window().size = Vector2i(450, 800)
	_home = load("res://game/menu/Home.tscn").instantiate()
	add_child(_home)
	_home.select_tab(_home.BATTLE_TAB, false)
	_page = _home._pages[_home.BATTLE_TAB]
	_page._selected = 0
	_page.refresh()
	await _settle()
	_world = _home._lobby_world
	_world_id = _world.get_instance_id()
	for key in _world._actors:
		_actor_ids[key] = _world._actors[key]["root"].get_instance_id()
	for index in range(15):
		_check_level(index)
		await _capture("home-%02d" % (index + 1), index)
		if index < 14:
			var clicked := await _tap(_page.find_child("LobbyNext", true, false) as Button)
			await _settle()
			_check("next-arrow-%02d" % (index + 1), clicked and _page._selected == index + 1)
	await _tab_round_trip()
	var clicked_back := await _tap(_page.find_child("LobbyPrev", true, false) as Button)
	await _settle()
	_check("native-previous-arrow", clicked_back and _page._selected == 13)
	var clicked_next := await _tap(_page.find_child("LobbyNext", true, false) as Button)
	await _settle()
	_check("native-next-after-previous", clicked_next and _page._selected == 14)
	PlayerData.gold += 1
	PlayerData.changed.emit()
	await _settle()
	_check_level(14)
	get_window().size = Vector2i(360, 640)
	await _settle()
	_check_level(14)
	await _capture("home-15-small", 14)
	get_window().size = Vector2i(450, 800)
	await _settle()
	await _finish()


func _expected(index: int) -> String:
	return ART.path_join("%02d-%s.png" % [index + 1, SLUGS[index]])


func _same_actors() -> bool:
	if not is_instance_valid(_world) or _home._lobby_world != _world or _world.get_instance_id() != _world_id:
		return false
	for key in _actor_ids:
		if not is_instance_valid(_world._actors[key]["root"]) or _world._actors[key]["root"].get_instance_id() != _actor_ids[key]:
			return false
	return _actor_ids.size() == 3


func _check_level(index: int) -> void:
	var prefix := "stage-%02d-" % (index + 1)
	var level: Resource = PlayerData.level_data(index)
	var panel := _page.find_child("LobbyTitlePanel", true, false) as Control
	var backdrop := _page.find_child("LobbyTitleBackdrop", true, false) as TextureRect
	var title := _page.find_child("LobbyTitle", true, false) as Label
	_check(prefix + "real-home-page", _home.get_script().resource_path == "res://game/menu/Home.gd" and _page.get_script().resource_path == "res://game/menu/pages/BattlePage.gd")
	_check(prefix + "page-selected", _page._selected == index and _home._current == _home.BATTLE_TAB)
	_check(prefix + "separate-live-title-label", title != null and title.is_visible_in_tree() and title.text == level.display_name)
	_check(prefix + "courtyard-and-cats-persist", _same_actors() and _world.is_visible_in_tree() and _world._active)
	_check(prefix + "save-disabled", not PlayerData.persist)
	if title != null:
		_check(prefix + "title-centered", title.get_global_rect().get_center().distance_to(Vector2(360, 181)) < 0.1 and title.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and title.vertical_alignment == VERTICAL_ALIGNMENT_CENTER)
		_check(prefix + "approved-font-colors", title.get_theme_font_size("font_size") == 28 and title.get_theme_color("font_color") == Color.WHITE and title.get_theme_color("font_outline_color") == Color("583f21") and title.get_theme_constant("outline_size") == 3)
	_check(prefix + "panel-present", panel != null and panel.is_visible_in_tree())
	_check(prefix + "background-texture-present", backdrop != null and backdrop.is_visible_in_tree())
	if panel != null:
		var rect := panel.get_global_rect()
		_check(prefix + "approved-panel-rect", rect.position.distance_to(Vector2(122, 128)) < 0.1 and rect.size.distance_to(Vector2(476, 106)) < 0.1)
		_check(prefix + "banner-clear-of-castle-bubble", not rect.intersects(_home._castle_bubble.get_global_rect()))
	if backdrop != null:
		var backdrop_rect := backdrop.get_global_rect()
		_check(prefix + "flat-backdrop-rect", backdrop_rect.position.distance_to(Vector2(122, 136)) < 0.1 and backdrop_rect.size.distance_to(Vector2(476, 90)) < 0.1)
		var field = level.get("lobby_banner")
		_check(prefix + "texture-bound-to-selected-level", field is Texture2D and field.resource_path == _expected(index) and backdrop.texture == field)
		_check(prefix + "texture-size", field is Texture2D and field.get_size() == Vector2(476, 90))
		var direct_dependency := false
		for dependency in ResourceLoader.get_dependencies(PlayerData.LEVELS[index]):
			if str(dependency).ends_with(_expected(index)):
				direct_dependency = true
		_check(prefix + "packable-level-dependency", direct_dependency)
	var prev := _page.find_child("LobbyPrev", true, false) as Button
	var next := _page.find_child("LobbyNext", true, false) as Button
	_check(prefix + "matching-arrow-buttons", prev != null and next != null and prev.size.distance_to(Vector2(70, 62)) < 0.1 and next.size.distance_to(Vector2(70, 62)) < 0.1 and absf(prev.get_global_rect().get_center().y - next.get_global_rect().get_center().y) < 0.1)
	_check(prefix + "pager-boundaries", prev != null and next != null and prev.disabled == (index == 0) and next.disabled == (index == 14))


func _tab_round_trip() -> void:
	var selected: int = _page._selected
	var clicked_shop := await _tap(_home._nav_bar._cells[_home.SHOP_TAB].button)
	await _settle()
	_check("native-shop-tab", clicked_shop and _home._current == _home.SHOP_TAB and not _world._active and not _world.is_visible_in_tree())
	var clicked_battle := await _tap(_home._nav_bar._cells[_home.BATTLE_TAB].button)
	await _settle()
	_check("native-battle-tab-restores-stage", clicked_battle and _home._current == _home.BATTLE_TAB and _page._selected == selected and _same_actors())
	_check_level(selected)


func _tap(button: Button) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var at := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	return received[0]


func _settle() -> void:
	await get_tree().create_timer(0.28).timeout
	await get_tree().process_frame
	await get_tree().process_frame


func _check(label: String, passed: bool) -> void:
	_checks.append({"name": label, "passed": passed})
	if not passed:
		_failures.append(label)
		push_error("LOBBY_REGIONAL_TITLE_FAIL " + label)


func _capture(label: String, index: int) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var expected_size := Vector2i(360, 640) if label.ends_with("small") else Vector2i(450, 800)
	var path := OUT.path_join(label + ".png")
	_check(label + "-capture-size", image.get_size() == expected_size)
	_check(label + "-capture-saved", image.save_png(ProjectSettings.globalize_path(path)) == OK)
	_shots.append({"stage": index + 1, "path": path, "background": _expected(index), "window": [expected_size.x, expected_size.y]})
	print("LOBBY_REGIONAL_TITLE_CAPTURE ", label)


func _finish() -> void:
	_check("no-save-file-created", not FileAccess.file_exists(PlayerData.SAVE_PATH))
	_home.queue_free()
	for player in MusicLib.get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	var report := {
		"scope": "Actual Home, all 15 selected brown-stroked regional map title textures at 476x90 inside the unchanged 476x106 holder, native arrow and tab navigation, persistent courtyard and three cat actors. Separate live label over background art.",
		"user_data_dir": OS.get_user_data_dir(), "no_save_file_created": not FileAccess.file_exists(PlayerData.SAVE_PATH),
		"failures": _failures, "checks": _checks, "screenshots": _shots,
	}
	var file := FileAccess.open(OUT.path_join("review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("LOBBY_REGIONAL_TITLE_REVIEW ", "PASS" if _failures.is_empty() else "FAIL", " ", _shots.size(), " captures; ", _failures)
	get_tree().quit(0 if _failures.is_empty() else 1)
