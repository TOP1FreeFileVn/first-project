extends Node

# Checks the two battle rules from the design talk (2026-10-18):
#  - cá: living cat soldiers eat fish by rarity and never exceed the basket;
#  - the hero's skill gear sits on the board, charges while it turns and casts in a fight.
# Prints PASS/FAIL lines and quits. Run: Godot --path . res://tests/FishSkillTest.tscn [-- --out=C:/x.png]

const CAP := 3
var _battle
var _time := 0.0
var _peak := 0
var _out := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.castle_level = 4
	PlayerData.unlocked_levels = 3
	PlayerData.select_level(2)
	_battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(_battle)
	var troops := PlayerData.TROOPS
	for id in ["kiem", "kiem", "cung", "gay_phep"]:
		_battle.board.place_new(troops[id], 2)
	_battle.fish_cap = CAP
	var skill_gears: Array = _battle.board.gears.values().filter(func(g): return g.is_skill())
	print("PASS: skill gear on the board (%s)" % skill_gears[0].troop.display_name if skill_gears.size() == 1 else "FAIL: %d skill gears" % skill_gears.size())
	Engine.time_scale = 2.0
	_battle.start_wave()


func _process(delta: float) -> void:
	_time += delta
	_peak = maxi(_peak, _battle.fish_used())
	if _time > 10.0:  # 20 game seconds at x2
		print("PASS: fish used peaked at %d of %d" % [_peak, CAP] if _peak <= CAP else "FAIL: fish used %d > %d" % [_peak, CAP])
		print("PASS: hero skill cast %d times" % _battle.skill_casts if _battle.skill_casts > 0 else "FAIL: hero skill never cast")
		if _out != "":
			get_viewport().get_texture().get_image().save_png(_out)
		Engine.time_scale = 1.0
		get_tree().quit()
