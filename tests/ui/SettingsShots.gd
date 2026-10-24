extends Node

# The settings sheet in the lobby and in battle, in RAM (no save): screenshots of both, and
# checks that the battle sheet pauses the fight and settings survive a save.
# Run (windowed): Godot --path . --resolution 450x800 res://tests/ui/SettingsShots.tscn -- <out_dir>

const SettingsSheet = preload("res://game/ui/SettingsSheet.gd")
const UiKit = preload("res://game/ui/UiKit.gd")

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://settings_shots"
	DirAccess.make_dir_recursive_absolute(out)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	var home = load("res://game/menu/Home.tscn").instantiate()
	add_child(home)
	await get_tree().create_timer(0.6).timeout
	home._open_settings()
	await get_tree().create_timer(0.4).timeout
	await _shot(out, "1-lobby")
	home.queue_free()
	await get_tree().process_frame
	var battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(battle)
	await get_tree().create_timer(0.6).timeout
	var box = SettingsSheet.open(battle.hud._root, true, battle)
	await get_tree().create_timer(0.4).timeout
	await _shot(out, "2-battle")
	print("SETTINGS paused=%s" % get_tree().paused)
	PlayerData.set_setting("music_volume", 0.3)
	PlayerData.set_setting("battle_speed", 2)
	PlayerData.set_setting("crit_text_on", false)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(PlayerData.to_dict()))
	PlayerData._reset()
	PlayerData.from_dict(saved)
	print("SETTINGS saved music=%.2f speed=%d crit=%s" % [PlayerData.music_volume, PlayerData.battle_speed, PlayerData.crit_text_on])
	UiKit.close_popup(box)
	await get_tree().process_frame
	await get_tree().process_frame
	print("SETTINGS resumed paused=%s" % get_tree().paused)
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().quit()

func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
