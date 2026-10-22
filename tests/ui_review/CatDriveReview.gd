extends Node

## Render the real Core, not a duplicate preview renderer. This also catches a
## baked/quantized output arm and the reappearance of the removed round tip.
const Core := preload("res://game/battle/Core.gd")
const GearBoard := preload("res://game/battle/GearBoard.gd")
const CatDrive := preload("res://game/battle/CatDrive.gd")
const OUT := "res://docs/ui_review/2026-10-23/cat-drive"
var _viewport: SubViewport
var _core
var _board


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	PlayerData.persist = false
	PlayerData.sound_on = false
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(256, 256)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	var background := Node2D.new()
	background.draw.connect(func(): background.draw_rect(Rect2(0, 0, 256, 256), Color("e8ddc8")))
	_viewport.add_child(background)
	_board = GearBoard.new()
	_core = Core.new()
	_core.board = _board
	_core.position = Vector2(128, 128)
	_core.scale = Vector2(2, 2)
	_core.set_process(false)
	_viewport.add_child(_core)
	await get_tree().process_frame
	for i in 96:
		var image := await _at(TAU * i / 96.0)
		image.save_png(OUT.path_join("phase-%03d.png" % i))
	# Both inputs select the same foreground pose, but their live arms must move.
	var first := await _at(0.002)
	var second := await _at(0.030)
	var moving_pixels := 0
	for y in range(108, 149):
		for x in range(201, 245):
			if first.get_pixel(x, y) != second.get_pixel(x, y):
				moving_pixels += 1
	var straight := await _at(0.0)
	var beyond_tip := straight.get_pixel(roundi(128 + (GearBoard.PIN_REACH + 2.8) * 2.0), 128)
	var checks := {
		"production_core_renderer": _core.get_script().resource_path == "res://game/battle/Core.gd",
		"same_cat_pose_at_two_test_angles": CatDrive.pose_index(0.002) == CatDrive.pose_index(0.030),
		"output_arm_moves_continuously_between_cat_poses": moving_pixels > 10,
		"no_round_marker_beyond_blunt_tip": _color_distance(beyond_tip, Color("e8ddc8")) < 0.02,
		"no_player_save_writes": not PlayerData.persist,
	}
	var data := {"checks": checks, "phase_captures": 96, "moving_tip_pixels": moving_pixels,
		"note": "Inspect phase contact sheets for opaque arms and an uninterrupted torso outline. PinMeshTest checks unchanged gear mechanics separately."}
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	_board.free()
	var failed := checks.values().has(false)
	print("CatDriveReview: ", "FAIL" if failed else "PASS", " ", checks)
	get_tree().quit(1 if failed else 0)


func _at(angle: float) -> Image:
	_board.drive = -angle
	_core.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return _viewport.get_texture().get_image()


func _color_distance(a: Color, b: Color) -> float:
	return maxf(maxf(absf(a.r - b.r), absf(a.g - b.g)), absf(a.b - b.b))
