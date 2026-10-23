extends SceneTree

# Opens the battle at each castle tier and saves a screenshot per tier.
# Godot --path . --resolution 450x800 --script res://tools/ui/capture_battle_castle.gd -- <out_dir>
# Restores the player's castle level and does not save it.

const BATTLE := "res://game/battle/Battle.tscn"

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://battle_castle"
	DirAccess.make_dir_recursive_absolute(out)
	await process_frame
	var data = root.get_node("PlayerData")
	var keep: int = data.castle_level
	for level in [1, 3, 5, 7, 9]:
		data.castle_level = level
		var battle = load(BATTLE).instantiate()
		root.add_child(battle)
		for _i in 30:
			await process_frame
		# The break-time shop sheet covers the wall; hide it for the shot.
		var hud = battle.get("hud")
		if hud and hud.get("_shop_panel"):
			hud._shop_panel.visible = false
		for _i in 3:
			await process_frame
		root.get_texture().get_image().save_png(out.path_join("battle-tier-%d.png" % ((level + 1) / 2)))
		battle.queue_free()
		await process_frame
	data.castle_level = keep
	quit()
