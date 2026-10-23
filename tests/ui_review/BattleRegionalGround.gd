extends Node

# Exercises the actual Battle scene and level resources with a disposable profile.
# No script overrides, art substitutions, baked UI, or writes to the real save.
const OUT := "res://docs/ui_review/2026-10-23/battle-regions-all15"
const BATTLE := "res://game/battle/Battle.tscn"
const REGIONS := "res://game/assets/battle/regions/"
const SLUGS := [
	"dong-co", "doi-da", "phao-dai-do", "rung-thong", "hem-nui",
	"lang-bo-hoang", "dam-lay", "thanh-da-den", "cong-phao-dai", "vua-do",
	"ben-cang", "rung-suong", "doi-cuu", "mo-vang", "cau-da",
]
var _shots: Array = []
var _resource_checks: Array = []
var _transitions: Array = []
var _failures: Array = []
var _battle


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	get_window().size = Vector2i(450, 800)
	PlayerData.persist = false
	_configure_player()
	for index in range(15):
		await _review_level(index)
	await _review_transitions()
	await _finish()


func _configure_player() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	# An experienced disposable player has already acknowledged tile tips. Keep
	# the genuine combat HUD visible without an onboarding panel over the art.
	PlayerData.seen_tiles = ["rock", "gold", "rust", "ice"]
	PlayerData.sound_on = false
	PlayerData.music_on = false
	PlayerData.castle_level = 4
	PlayerData.gold = 2400
	for id in ["giao", "thuoc"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "thuoc"]
	PlayerData.unlocked_levels = 15


func _expected(index: int) -> String:
	return REGIONS.path_join("%02d-%s.png" % [index + 1, SLUGS[index]])


func _create_battle(index: int) -> void:
	PlayerData.select_level(index)
	seed(20261023)
	_battle = load(BATTLE).instantiate()
	# This controller stays as a root sibling while the real battle owns scene
	# navigation. restart()/next_level() therefore reload Battle.tscn itself.
	get_tree().root.add_child(_battle)
	get_tree().current_scene = _battle
	await get_tree().process_frame
	await get_tree().process_frame


func _checks(index: int) -> Dictionary:
	var background: Node2D = _battle.get_node("Background")
	var field = _battle.level.get("battlefield")
	var bound = background.get("_regional_field")
	var expected := _expected(index)
	var direct_dependency := false
	for dependency in ResourceLoader.get_dependencies(PlayerData.LEVELS[index]):
		if str(dependency).ends_with(expected) and expected != "":
			direct_dependency = true
	var storage_property := false
	for prop in _battle.level.get_property_list():
		if prop["name"] == "battlefield":
			storage_property = (int(prop["usage"]) & PROPERTY_USAGE_STORAGE) != 0
	var checks := {
		"real_battle_script": _battle.get_script().resource_path == "res://game/battle/Battle.gd",
		"real_background_script": background.get_script().resource_path == "res://game/battle/Background.gd",
		"correct_level_selection": PlayerData.current_level == index and _battle.level == PlayerData.level_data(index),
		"exported_texture_property": storage_property,
		"background_bound_to_level": bound == field,
		"castle_foreground_preserved": background.get_node_or_null("CastleForeground") != null,
		"deployment_lines_preserved": _battle.WALL_Y == 700.0 and _battle.DEPLOY_Y == 664.0,
		"gear_origin_preserved": _battle.board.position == Vector2(60, 760),
		"save_disabled": not PlayerData.persist,
	}
	checks["correct_regional_texture"] = field is Texture2D and field.resource_path == expected
	checks["regional_size_720x740"] = field is Texture2D and field.get_size() == Vector2(720, 740)
	checks["direct_packable_resource_dependency"] = direct_dependency
	return checks


func _record_checks(label: String, checks: Dictionary) -> void:
	for key: String in checks:
		if not checks[key]:
			_failures.append(label + ": " + key)


func _review_level(index: int) -> void:
	await _create_battle(index)
	var checks := _checks(index)
	_record_checks("stage-%02d" % (index + 1), checks)
	_resource_checks.append({"stage": index + 1, "expected": _expected(index), "checks": checks})
	for item in [["cung", 2], ["kiem", 2], ["giao", 1], ["thuoc", 1]]:
		_battle.board.place_new(PlayerData.TROOPS[item[0]], item[1])
	_battle.core.meat = 9.0
	_battle.shop_changed.emit()
	await get_tree().process_frame
	_battle.start_wave()
	await get_tree().create_timer(4.0).timeout
	_battle.process_mode = Node.PROCESS_MODE_DISABLED
	var combat := {
		"fight_phase": _battle.phase == "fight",
		"allies_present": _battle.player_units.size() > 0,
		"enemies_present": _battle.enemy_units.size() > 0,
	}
	_record_checks("live-%02d" % (index + 1), combat)
	await _capture("live-%02d" % (index + 1), index, combat)
	if index == 14:
		get_window().size = Vector2i(360, 640)
		await _capture("live-15-small", index, combat)
		get_window().size = Vector2i(450, 800)
	await _free_battle()


func _capture(label: String, index: int, combat: Dictionary) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := OUT.path_join(label + ".png")
	var saved := image.save_png(ProjectSettings.globalize_path(path)) == OK
	var expected_size := Vector2i(360, 640) if label.ends_with("small") else Vector2i(450, 800)
	var capture_checks := {"png_saved": saved, "viewport_size": image.get_size() == expected_size}
	_record_checks(label, capture_checks)
	_shots.append({
		"stage": index + 1, "path": path, "background": _expected(index),
		"combat": combat, "capture": capture_checks,
		"allies": _battle.player_units.size(), "enemies": _battle.enemy_units.size(),
	})
	print("BATTLE_REGIONAL_CAPTURE ", label, " ", combat, " ", capture_checks)


func _review_transitions() -> void:
	await _create_battle(8)
	var old_id: int = _battle.get_instance_id()
	_battle.next_level()
	await get_tree().scene_changed
	_battle = get_tree().current_scene
	var next_checks := _checks(9)
	next_checks["next_level_created_new_battle"] = _battle.get_instance_id() != old_id
	_record_checks("next-09-to-10", next_checks)
	_transitions.append({"action": "Battle.next_level 09 to 10", "checks": next_checks})
	old_id = _battle.get_instance_id()
	_battle.restart()
	await get_tree().scene_changed
	_battle = get_tree().current_scene
	var restart_checks := _checks(9)
	restart_checks["restart_created_new_battle"] = _battle.get_instance_id() != old_id
	_record_checks("restart-10", restart_checks)
	_transitions.append({"action": "Battle.restart stage 10", "checks": restart_checks})
	old_id = _battle.get_instance_id()
	_battle.next_level()
	await get_tree().scene_changed
	_battle = get_tree().current_scene
	var extension_checks := _checks(10)
	extension_checks["next_level_created_new_battle"] = _battle.get_instance_id() != old_id
	_record_checks("next-10-to-11", extension_checks)
	_transitions.append({"action": "Battle.next_level 10 to 11", "checks": extension_checks})
	await _free_battle()
	await _create_battle(13)
	old_id = _battle.get_instance_id()
	_battle.next_level()
	await get_tree().scene_changed
	_battle = get_tree().current_scene
	var final_checks := _checks(14)
	final_checks["next_level_created_new_battle"] = _battle.get_instance_id() != old_id
	final_checks["last_stage_has_no_next_level"] = not PlayerData.has_next_level()
	_record_checks("next-14-to-15", final_checks)
	_transitions.append({"action": "Battle.next_level 14 to 15", "checks": final_checks})
	await _free_battle()


func _free_battle() -> void:
	get_tree().current_scene = null
	_battle.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _finish() -> void:
	var no_save := not FileAccess.file_exists(PlayerData.SAVE_PATH)
	_record_checks("isolated-profile", {"no_save_file_created": no_save})
	for player in MusicLib.get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	var report := {
		"scope": "Actual production Battle scene, all 15 region textures in live combat, native next-level/restart navigation through the extended stages. No script overrides.",
		"user_data_dir": OS.get_user_data_dir(), "no_save_file_created": no_save,
		"failures": _failures, "screenshots": _shots,
		"level_resources": _resource_checks, "transitions": _transitions,
	}
	var file := FileAccess.open(OUT.path_join("review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("BATTLE_REGIONAL_REVIEW ", "PASS" if _failures.is_empty() else "FAIL", " ", _shots.size(), " captures; ", _failures)
	get_tree().quit(0 if _failures.is_empty() else 1)
