extends Node

# Screenshots of the hero cat's lobby round on the real Home screen, in RAM (no save):
# one shot per stop (pose, train, look, ...) and one of its tap reaction.
# Run (windowed): Godot --path . --resolution 450x800 res://tests/ui/LobbyHeroShots.tscn -- <out_dir>

const HOME := preload("res://game/menu/Home.tscn")

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://lobby_hero"
	DirAccess.make_dir_recursive_absolute(out)
	PlayerData.persist = false
	var home = HOME.instantiate()
	add_child(home)
	home.select_tab(home.BATTLE_TAB, false)
	for _i in 10:
		await get_tree().process_frame
	var lobby = home.get("_lobby_world")
	var t := 0.0
	var at: Vector2 = lobby.HERO_ROUTE[-1][0]
	var i := 0
	for stop in lobby.HERO_ROUTE:
		t += at.distance_to(stop[0]) / lobby.HERO_WALK_SPEED
		lobby._clock = t + stop[2] * 0.4
		await get_tree().create_timer(0.35).timeout
		var hero: Dictionary = lobby._actors["hero"]
		print("LOBBY_HERO %d %s anim=%s at=%s" % [i, stop[1], hero.pose.animation, hero.position])
		get_viewport().get_texture().get_image().save_png(out.path_join("%d-%s.png" % [i, stop[1]]))
		t += stop[2]
		at = stop[0]
		i += 1
	# Tap it.
	var hero: Dictionary = lobby._actors["hero"]
	var screen: Vector2 = lobby._world.get_global_transform() * (hero.position + Vector2(0, -40))
	lobby.pet_at(screen)
	await get_tree().create_timer(0.4).timeout
	print("LOBBY_HERO tap anim=%s" % hero.pose.animation)
	get_viewport().get_texture().get_image().save_png(out.path_join("tap.png"))
	get_tree().quit()
