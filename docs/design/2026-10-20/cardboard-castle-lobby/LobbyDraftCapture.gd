extends Node

# Review-only screenshot fixture. Uses an offscreen SubViewport and an isolated
# process profile; never changes the production lobby or writes a player save.
const OUT := "res://docs/design/2026-10-20/cardboard-castle-lobby"
var viewport: SubViewport
var home: Control

func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	PlayerData.castle_level = 3
	PlayerData.cheated = false
	viewport = SubViewport.new()
	viewport.name = "LobbyDraftViewport"
	viewport.size = Vector2i(720, 1280)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	home = load("res://game/menu/Home.tscn").instantiate()
	viewport.add_child(home)
	home.select_tab(2, false)
	var background := home.get_child(0) as ColorRect
	var shader := background.material as ShaderMaterial
	shader.set_shader_parameter("motion_speed", 0.0)
	shader.set_shader_parameter("time_offset", 5.0)
	await get_tree().create_timer(0.4).timeout
	for tween: Tween in get_tree().get_processed_tweens():
		tween.pause()
	await _capture("original-lobby.png")
	var stage: Control = home._pages[2]._stage
	var stage_rect := stage.get_global_rect()
	stage.visible = false
	await _capture("empty-lobby.png")
	var status := {
		"review_only": true,
		"profile": OS.get_user_data_dir(),
		"persist": PlayerData.persist,
		"size": [720, 1280],
		"stage_hidden": not stage.visible,
		"stage_rect": [stage_rect.position.x, stage_rect.position.y, stage_rect.size.x, stage_rect.size.y],
		"shader_time": 5.0,
		"outputs": ["original-lobby.png", "empty-lobby.png"],
		"production_code_modified": false,
	}
	var file := FileAccess.open(OUT + "/capture-status.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(status, "\t"))
	print("CARDBOARD_LOBBY_CAPTURE_COMPLETE ", JSON.stringify(status))
	get_tree().quit()

func _capture(filename: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	assert(image.get_size() == Vector2i(720, 1280))
	var error := image.save_png(OUT + "/" + filename)
	assert(error == OK)
