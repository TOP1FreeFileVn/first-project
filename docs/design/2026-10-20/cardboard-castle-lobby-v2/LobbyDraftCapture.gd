extends Node

# Review-only screenshot fixture. Uses an offscreen SubViewport and an isolated
# process profile; never changes the production lobby or writes a player save.
const OUT := "res://docs/design/2026-10-20/cardboard-castle-lobby-v2"
const Ui = preload("res://game/ui/Ui.gd")
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
	# Full-ground lobby concepts use a plain upcoming-level heading and no
	# carousel. Keep transparent chrome geometry unchanged for compositing.
	viewport.transparent_bg = true
	home._sky_backdrop.visible = false
	home._shop_backdrop.visible = false
	home._pages[2]._column.get_child(1).modulate.a = 0.0
	home._pages[2]._column.get_child(2).modulate.a = 0.0
	home.find_child("LobbyPager", true, false).modulate.a = 0.0
	# Preserve the original untitled overlay as a separate compositing asset.
	if not FileAccess.file_exists(OUT + "/ui-overlay-ground-lobby.png"):
		await _capture("ui-overlay-ground-lobby.png")
	var upcoming_title := Ui.label("Màn 3 · Pháo Đài Đỏ", "", 30)
	upcoming_title.name = "GroundLobbyUpcomingTitle"
	upcoming_title.theme = Ui.THEME
	upcoming_title.position = Vector2(130, 155)
	upcoming_title.size = Vector2(460, 55)
	upcoming_title.add_theme_color_override("font_color", Color.WHITE)
	upcoming_title.add_theme_color_override("font_outline_color", Color("583f21"))
	upcoming_title.add_theme_constant_override("outline_size", 3)
	home.add_child(upcoming_title)
	await _capture("ui-overlay-ground-lobby-with-title.png")
	var status := {
		"review_only": true,
		"profile": OS.get_user_data_dir(),
		"persist": PlayerData.persist,
		"size": [720, 1280],
		"stage_hidden": not stage.visible,
		"stage_rect": [stage_rect.position.x, stage_rect.position.y, stage_rect.size.x, stage_rect.size.y],
		"shader_time": 5.0,
		"outputs": ["original-lobby.png", "empty-lobby.png", "ui-overlay-ground-lobby.png", "ui-overlay-ground-lobby-with-title.png"],
		"plain_title": {"text": upcoming_title.text, "rect": [130, 155, 460, 55], "font_size": 30, "outline_size": 3},
		"transparent_overlay_hides": ["background", "stage", "title_plaque", "stars", "pager"],
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
