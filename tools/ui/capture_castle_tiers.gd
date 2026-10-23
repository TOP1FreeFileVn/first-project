extends SceneTree

# Opens Home at each castle tier and saves a lobby screenshot per tier.
# Godot --path . --script res://tools/ui/capture_castle_tiers.gd -- <out_dir>
# Restores the player's castle level and does not save it.

const HOME := "res://game/menu/Home.tscn"

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://castle_tiers"
	DirAccess.make_dir_recursive_absolute(out)
	await process_frame
	var data = root.get_node("PlayerData")
	var keep: int = data.castle_level
	var home = load(HOME).instantiate()
	root.add_child(home)
	for _i in 10:
		await process_frame
	var lobby = home.find_child("CardboardLobby", true, false)
	for level in [1, 3, 5, 7, 9]:
		data.castle_level = level
		lobby.sync_castle_level()
		for _i in 20:
			await process_frame
		var img := root.get_texture().get_image()
		img.save_png(out.path_join("tier-%d.png" % ((level + 1) / 2)))
	data.castle_level = keep
	quit()
