extends Node

# Screenshots of the two reward paths, in RAM (no save):
#   Godot --path . --resolution 450x800 res://tests/ui/EquipmentShots.tscn -- <out_dir>
# shop chests (equipment + Forge Stones), a gold chest's result, the troop summon tab,
# a x10 troop summon, and the troop page.

const HOME := preload("res://game/menu/Home.tscn")

var _out := "user://equipment_shots"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gems = 900
	PlayerData.gold = 2400
	var home = HOME.instantiate()
	add_child(home)
	await _wait(0.6)
	home.select_tab(home.SHOP_TAB, false)
	await _wait(0.8)
	await _shot("1-shop")
	home._pages[home.SHOP_TAB]._open("gold")
	await _results(home, "2-gold-chest")
	home.select_tab(home.SUMMON_TAB, false)
	await _wait(0.8)
	await _shot("3-summon-tab")
	home._pages[home.SUMMON_TAB]._summon(10)
	await _results(home, "4-summon-x10")
	home.select_tab(home.TROOPS_TAB, false)
	await _wait(0.8)
	await _shot("5-troops")
	get_tree().quit()

# The newest opening (on its own CanvasLayer): skip to its results, shoot, close it.
func _results(home: Node, name: String) -> void:
	await _wait(0.4)
	var openings: Array = home.find_children("*", "Control", true, false).filter(func(c): return c.has_method("skip") and c.has_signal("closed"))
	var opening: Node = openings.back()
	opening.skip()
	# Showcases wait for a tap; tap through them.
	for i in 12:
		await _wait(0.25)
		if opening.get("_stage") == "done" or opening.get("_stage") == "summary":
			break
		if opening.has_method("_on_tap"):
			opening._on_tap()
	await _wait(1.0)
	await _shot(name)
	opening.get_parent().queue_free()
	await _wait(0.3)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
