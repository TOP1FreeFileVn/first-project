extends Node

# Capture production Home/Battle on a disposable player, including a live wave.
const OUT := "res://docs/ui_review/2026-10-22/battle-cardboard-castle"
var _label := "after"
var _battle
var _shots: Array = []
var _layer_checks: Dictionary = {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):
			_label = arg.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false
	PlayerData.castle_level = 4
	PlayerData.gold = 2400
	for id in ["giao", "thuoc"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "thuoc"]
	PlayerData.unlocked_levels = 3
	PlayerData.select_level(2)
	seed(22)
	get_window().size = Vector2i(450, 800)
	var home = load("res://game/menu/Home.tscn").instantiate()
	add_child(home)
	home.select_tab(home.BATTLE_TAB, false)
	await _settle()
	await _capture("lobby")
	home.queue_free()
	await get_tree().process_frame
	_battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(_battle)
	for item in [["cung", 2], ["kiem", 2], ["giao", 1], ["thuoc", 1]]:
		_battle.board.place_new(PlayerData.TROOPS[item[0]], item[1])
	_battle.core.meat = 9.0
	_battle.shop_changed.emit()
	await _settle()
	await _capture("prepare")
	if _label.begins_with("layers-"):
		await _check_layering()
		await _check_gear_drag()
	get_window().size = Vector2i(360, 640)
	await _settle()
	await _capture("prepare")
	_battle.start_wave()
	await get_tree().create_timer(7.0).timeout
	await _capture("fight")
	get_window().size = Vector2i(450, 800)
	await _settle()
	await _capture("fight")
	var hp_before: float = _battle.core.hp
	_battle.core.take_damage(1.0)
	await get_tree().process_frame
	await _capture("hit")
	var checks := {
		"real_battle": _battle.get_script().resource_path == "res://game/battle/Battle.gd",
		"castle_still_takes_damage": _battle.core.hp < hp_before,
		"board_still_accepts_game_input": _battle.accepts_input(),
		"same_deployment_line": _battle.WALL_Y == 700.0 and _battle.DEPLOY_Y == 664.0,
		"same_gear_origin": _battle.board.position == Vector2(60, 760),
		"no_save_write": not PlayerData.persist,
	}
	checks.merge(_layer_checks)
	var data := {"label": _label, "checks": checks, "screenshots": _shots,
		"scope": "Full opaque castle facade in front of units, clear gateway and unchanged cardboard gear table/gameplay."}
	var file := FileAccess.open(OUT.path_join(_label + "-manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	var failed := checks.values().has(false)
	print("BattleCardboardCastleReview: ", "FAIL" if failed else "PASS", " ", checks)
	get_tree().quit(1 if failed else 0)


func _check_layering() -> void:
	# GPU probes cross the same wall/gate as actual units. Assert visible pixels,
	# rather than merely checking the z-index written in the implementation.
	# The shop popup covers this wall while preparing; hide only its CanvasLayer
	# so these samples measure actor occlusion rather than the popup's panel.
	_battle.hud.hide()
	var probes: Array[Node2D] = []
	for x in [136.0, 280.0, 360.0, 580.0]:
		var probe := Node2D.new()
		probe.position = Vector2(x, 700)
		probe.draw.connect(func(): probe.draw_rect(Rect2(-8, -140, 16, 210), Color.MAGENTA))
		_battle.units_layer.add_child(probe)
		probes.append(probe)
	await _settle()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	_layer_checks["upper_gate_occludes_units"] = not _probe_visible(image, Vector2(280, 670))
	_layer_checks["gate_crown_occludes_units"] = not _probe_visible(image, Vector2(360, 640))
	_layer_checks["left_tower_occludes_units"] = not _probe_visible(image, Vector2(136, 650))
	_layer_checks["right_tower_occludes_units"] = not _probe_visible(image, Vector2(580, 650))
	_layer_checks["above_battlements_keeps_units_visible"] = _probe_visible(image, Vector2(280, 580))
	_layer_checks["low_wall_occludes_units"] = not _probe_visible(image, Vector2(280, 705))
	_layer_checks["upper_aperture_keeps_units_visible"] = _probe_visible(image, Vector2(360, 670))
	_layer_checks["open_gate_does_not_occlude_units"] = _probe_visible(image, Vector2(360, 705))
	await _capture("depth-probes")
	for probe in probes:
		probe.queue_free()
	await _settle()
	await _capture("castle-occlusion")
	_battle.hud.show()
	await _settle()


func _check_gear_drag() -> void:
	var board = _battle.board
	var gear = null
	for candidate in board.gears.values():
		if not candidate.is_skill():
			gear = candidate
			break
	var target := Vector2i(-1, -1)
	for cell in board.open_order():
		if board.is_placeable(cell) and not board.gears.has(cell):
			target = cell
			break
	if gear == null or target == Vector2i(-1, -1):
		_layer_checks["gear_drag_fixture_available"] = false
		return
	var source: Vector2i = gear.cell
	var start: Vector2 = gear.global_position
	_mouse_button(start, true)
	await get_tree().process_frame
	_layer_checks["native_gear_press_starts_drag"] = board.dragged_gear() == gear
	var end: Vector2 = board.to_global(board.cell_center(target))
	var motion := InputEventMouseMotion.new()
	motion.position = get_tree().root.get_final_transform() * end
	motion.global_position = motion.position
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await get_tree().process_frame
	await get_tree().process_frame
	_layer_checks["native_gear_motion_follows_pointer"] = gear.global_position.distance_to(end) < 1.0
	await _capture("gear-drag")
	_mouse_button(end, false)
	await _settle()
	_layer_checks["native_gear_drop_moves_to_empty_cell"] = not board.is_dragging() and board.gears.get(target) == gear and gear.cell == target
	# Return the fixture to its original arrangement through the same input path.
	_mouse_button(end, true)
	await get_tree().process_frame
	var origin: Vector2 = board.to_global(board.cell_center(source))
	_mouse_button(origin, false)
	await _settle()
	_layer_checks["native_gear_return_restores_board"] = not board.is_dragging() and board.gears.get(source) == gear


func _mouse_button(world: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = get_tree().root.get_final_transform() * world
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)


func _probe_visible(image: Image, world: Vector2) -> bool:
	var pixel := get_tree().root.get_final_transform() * world
	var color := image.get_pixel(floori(pixel.x), floori(pixel.y))
	return color.r > 0.9 and color.b > 0.9 and color.g < 0.1


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout


func _capture(key: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := OUT.path_join("%s-%s_%dx%d.png" % [_label, key, image.get_width(), image.get_height()])
	image.save_png(ProjectSettings.globalize_path(path))
	_shots.append(path)
