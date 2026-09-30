extends Node

# Screenshots of the in-battle guidance: the first-battle tutorial steps on level 1 and
# the new-cell card on levels 11 and 15.
# Run (windowed): Godot --path . res://tests/CoachShots.tscn -- --shot-dir=C:/some/folder

var _dir := ""
var _battle
var _step := 0
var _wait := 1.2


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			_dir = arg.get_slice("=", 1)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.unlocked_levels = PlayerData.LEVELS.size()
	PlayerData.castle_level = 6
	_open(1)


func _open(level: int) -> void:
	if _battle != null:
		_battle.queue_free()
	PlayerData.select_level(level - 1)
	_battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(_battle)


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/coach_%s.png" % [_dir, name])


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = 0.8
	match _step:
		0:
			_shot("1_buy")
			_battle.buy(1)
		1:
			_shot("2_turn")
			var coach = _battle.hud._root.get_children().filter(func(c): return c is Control and c.has_method("_advance"))[0]
			coach._advance()
		2:
			_shot("3_merge")
			_open(11)
			_wait = 1.2
		3:
			_shot("4_tiles_rock")
			PlayerData.seen_tiles = ["rock"]
			_open(14)
			_wait = 1.2
		4:
			_shot("5_tiles_rust_gold")
			_open(15)
			_wait = 1.2
		5:
			_shot("6_tiles_ice")
			get_tree().quit()
	_step += 1
