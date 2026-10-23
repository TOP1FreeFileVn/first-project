extends Node

# Checks the lobby toys and petting on the real Home screen, in RAM (no save):
#  - a real mouse click on a cat makes it play "happy";
#  - while the tabby bats the yarn / the fish, they move.
# Prints LOBBY_PLAY results, then quits. Record it with --write-movie to see it.

const HOME := preload("res://game/menu/Home.tscn")

func _ready() -> void:
	PlayerData.persist = false
	var home = HOME.instantiate()
	add_child(home)
	home.select_tab(home.BATTLE_TAB, false)
	for _i in 10:
		await get_tree().process_frame
	var lobby = home.get("_lobby_world")
	# Jump the clock to the tabby batting the yarn (route: gate 3 s, walk, yarn 5 s).
	var yarn_start := _route_time(lobby, "yarn")
	lobby._clock = yarn_start + 1.0
	await _wait(1.6)
	var yarn_moved: float = absf(lobby._yarn_roll)
	var fish_start := _route_time(lobby, "fish")
	lobby._clock = fish_start + 1.0
	await _wait(1.6)
	var fish_moved: float = absf(lobby._fish_angle) + absf(lobby._fish_speed)
	# Click the calico wherever it is.
	var cat: Dictionary = lobby._actors["calico"]
	# World point -> canvas (what gui coordinates use) -> viewport pixels (what input uses).
	var screen: Vector2 = lobby._world.get_global_transform() * (cat.position + Vector2(0, -40))
	var pixel: Vector2 = get_viewport().get_screen_transform() * get_viewport().get_canvas_transform() * screen
	lobby._petted.clear()
	await _click(pixel)
	await get_tree().process_frame
	var anim: String = cat.pose.animation
	print("LOBBY_PLAY yarn_roll=%.1f fish_motion=%.2f petted=%s anim=%s" % [yarn_moved, fish_moved, lobby._petted.has("calico"), anim])
	await _wait(1.5)
	get_tree().quit()

# Visible controls that would take a click at `p` (mouse_filter STOP/PASS), in draw order.
func _controls_at(node: Node, p: Vector2) -> Array:
	var out: Array = []
	if node is Control and node.is_visible_in_tree() and node.mouse_filter != Control.MOUSE_FILTER_IGNORE and node.get_global_rect().has_point(p):
		out.append(node)
	for child in node.get_children():
		out.append_array(_controls_at(child, p))
	return out

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

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _click(at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		e.global_position = at
		get_viewport().push_input(e)
		await get_tree().process_frame
