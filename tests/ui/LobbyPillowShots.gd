extends Node

# Screenshots of the tabby's pillow stop on the real Home lobby, in RAM (no save): hopping
# up, kneading, napping on the cushion, hopping down. Prints LOBBY_PILLOW states.
# Run (windowed): Godot --path . res://tests/ui/LobbyPillowShots.tscn -- <out_dir>

const HOME := preload("res://game/menu/Home.tscn")

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://pillow_shots"
	DirAccess.make_dir_recursive_absolute(out)
	PlayerData.persist = false
	var home = HOME.instantiate()
	add_child(home)
	home.select_tab(home.BATTLE_TAB, false)
	for _i in 10:
		await get_tree().process_frame
	var lobby = home.get("_lobby_world")
	var start := _route_time(lobby, "pillow")
	var play: float = lobby.TABBY_ROUTE[-1][1]
	for shot in [["1-hop-up", 0.22], ["2-knead", 1.2], ["3-nap", 5.0], ["4-hop-down", play - 0.22]]:
		lobby._clock = start + shot[1]
		lobby.set_process(false)
		lobby._pose()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var cat: Dictionary = lobby._actors["tabby"]
		print("LOBBY_PILLOW %s state=%s anim=%s parent=%s" % [shot[0], cat.state, cat.pose.animation, cat.root.get_parent().get_parent().name])
		get_viewport().get_texture().get_image().save_png(out.path_join(shot[0] + ".png"))
	get_tree().quit()

func _route_time(lobby, toy: String) -> float:
	var t := 0.0
	var at: Vector2 = lobby.GATE
	for stop in lobby.TABBY_ROUTE:
		var to: Vector2 = lobby.GATE if stop[0] == "" else lobby.TOYS[stop[0]].spot
		t += at.distance_to(to) / lobby.WALK_SPEED
		if stop[0] == toy:
			return t
		t += stop[1]
		at = to
	return 0.0
