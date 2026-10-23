extends Node

# Test scene: a real battle that starts its first wave right away, with a few gears so cats
# of several classes come out. For recording the rigged cats fighting:
#   Godot --path . res://tests/ui/BattleRigPreview.tscn --write-movie out.avi --fixed-fps 30 --quit-after 600

const BATTLE := preload("res://game/battle/Battle.tscn")
const TROOPS := ["kiem", "cung", "gay_phep", "giao", "katana"]

func _ready() -> void:
	var battle = BATTLE.instantiate()
	add_child(battle)
	await get_tree().process_frame
	await get_tree().process_frame
	for id in TROOPS:
		if PlayerData.TROOPS.has(id) and not battle.board.is_full():
			battle.board.place_new(PlayerData.TROOPS[id], 2)
	battle.hud._shop_panel.visible = false
	battle.start_wave()
