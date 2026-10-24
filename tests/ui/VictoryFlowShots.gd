extends Node

# The victory flow on the real scenes, in RAM (no save): win a battle -> result panel with
# confetti (no chest yet) -> back to the lobby -> the victory chest opens first.
# Run (windowed): Godot --path . --resolution 450x800 res://tests/ui/VictoryFlowShots.tscn -- <out_dir>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://victory_flow"
	DirAccess.make_dir_recursive_absolute(out)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	# persist=false normally skips the chest; this test wants the real flow.
	PlayerData.victory_chest_in_tests = true
	var battle = load("res://game/battle/Battle.tscn").instantiate()
	get_tree().root.add_child.call_deferred(battle)
	await get_tree().create_timer(0.5).timeout
	battle.phase = "fight"
	battle._on_all_waves_cleared()
	await get_tree().create_timer(0.7).timeout
	await _shot(out, "1-confetti")
	await get_tree().create_timer(1.6).timeout
	await _shot(out, "2-result")
	var chest: Dictionary = PlayerData.pending_chest
	print("VICTORY_FLOW pending_cards=%d chest_in_battle=%s" % [chest.get("cards", {}).size(), _find(battle, "ChestOpening")])
	battle.queue_free()
	var home = load("res://game/menu/Home.tscn").instantiate()
	get_tree().root.add_child(home)
	await get_tree().create_timer(1.2).timeout
	await _shot(out, "3-lobby-chest")
	print("VICTORY_FLOW lobby_chest=%s pending_after=%d" % [_find(home, "ChestOpening"), PlayerData.pending_chest.size()])
	get_tree().quit()

func _find(node: Node, script_name: String) -> bool:
	for child in node.get_children():
		var script: Script = child.get_script()
		if script != null and script.resource_path.ends_with(script_name + ".gd"):
			return true
		if _find(child, script_name):
			return true
	return false

func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
