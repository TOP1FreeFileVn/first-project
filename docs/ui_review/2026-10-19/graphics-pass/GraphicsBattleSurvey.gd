extends Node

# Production battle UI rendered using a disposable review fixture.
# tools/review/mcp_ui_review.mjs provides isolated APPDATA/LOCALAPPDATA.
const OUT := "res://docs/ui_review/2026-10-19/graphics-pass/screens"
var _battle


func _ready() -> void:
	get_window().size = Vector2i(720, 1280)
	print("BATTLE_REVIEW_USER_DIR ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.castle_level = 4
	for id in ["giao", "thuoc"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "thuoc"]
	PlayerData.unlocked_levels = 3
	PlayerData.select_level(2)
	seed(20261019)
	_battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(_battle)
	var troops: Dictionary = PlayerData.TROOPS
	_battle.board.place_new(troops["cung"], 2)
	_battle.board.place_new(troops["kiem"], 2)
	_battle.board.place_new(troops["giao"], 1)
	_battle.board.place_new(troops["thuoc"], 1)
	_battle.core.meat = 9.0
	_battle.shop_changed.emit()
	await get_tree().create_timer(1.0).timeout
	await _capture("11_battle_shop")
	_battle.start_wave()
	await get_tree().create_timer(5.0).timeout
	await _capture("12_battle_fight")
	print("BATTLE_REVIEW_COMPLETE")
	get_tree().quit()


func _capture(key: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png(OUT + "/" + key + ".png")
	print("BATTLE_REVIEW_CAPTURE ", key, " ", image.get_size(), " result=", result,
		" phase=", _battle.phase, " enemies=", _battle.enemy_units.size(),
		" allies=", _battle.player_units.size())
