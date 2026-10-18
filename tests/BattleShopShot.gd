extends Node

# A screenshot of the between-wave shop with a few gears already on the board, for
# documents. Run (windowed): Godot --path . res://tests/BattleShopShot.tscn -- --out=C:/file.png

var _out := ""
var _battle
var _time := 0.0
## With --fight the wave starts and the shot is taken mid-battle.
var _fight := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
		if arg == "--fight":
			_fight = true
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.castle_level = 4
	for id in ["giao", "thuoc"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "thuoc"]
	PlayerData.unlocked_levels = 3
	PlayerData.select_level(2)
	_battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(_battle)
	var troops := PlayerData.TROOPS
	_battle.board.place_new(troops["cung"], 2)
	_battle.board.place_new(troops["kiem"], 2)
	_battle.board.place_new(troops["giao"], 1)
	_battle.board.place_new(troops["thuoc"], 1)
	_battle.core.meat = 9.0
	_battle.shop_changed.emit()
	if _fight:
		_battle.start_wave()


func _process(delta: float) -> void:
	_time += delta
	if _time > (9.0 if _fight else 1.2):
		get_viewport().get_texture().get_image().save_png(_out)
		get_tree().quit()
