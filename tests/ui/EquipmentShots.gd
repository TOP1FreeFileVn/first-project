extends Node

# Screenshots of the equipment economy screens, in RAM (no save):
#   Godot --path . --resolution 450x800 res://tests/ui/EquipmentShots.tscn -- <out_dir>
# summon tab, a x10 result, the hero cat page with a fuse ready, an item's detail.

const HOME := preload("res://game/menu/Home.tscn")
const HeroCat := preload("res://game/core/HeroCat.gd")

var _out := "user://equipment_shots"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gems = 600
	PlayerData.gold = 2400
	PlayerData.forge_stones = 140
	# Two spare copies of the worn helmet, so a fuse is ready.
	var helmet: String = HeroCat.item(PlayerData.hero_cat, HeroCat.equipped_uid(PlayerData.hero_cat, "helmet"))["id"]
	HeroCat.add_item(PlayerData.hero_cat, helmet)
	HeroCat.add_item(PlayerData.hero_cat, helmet)
	var home = HOME.instantiate()
	add_child(home)
	await _wait(0.6)
	home.select_tab(home.SUMMON_TAB, false)
	await _wait(0.8)
	await _shot("1-summon-tab")
	var page = home._pages[home.SUMMON_TAB]
	page._summon(10)
	await _wait(0.4)
	# The opening sits on its own CanvasLayer under Home; skip to the results, shoot, close it.
	var opening: Node = home.find_children("*", "Control", true, false).filter(func(c): return c.has_method("skip") and c.has_signal("closed")).back()
	opening.skip()
	await _wait(1.2)
	await _shot("2-summon-x10")
	opening.get_parent().queue_free()
	await _wait(0.3)
	home.select_tab(home.HERO_TAB, false)
	await _wait(0.8)
	await _shot("3-hero-page")
	var hero_page = home._pages[home.HERO_TAB]
	hero_page._open_detail(HeroCat.equipped_uid(PlayerData.hero_cat, "helmet"))
	await _wait(0.6)
	await _shot("4-item-detail")
	get_tree().quit()

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
