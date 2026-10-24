extends Node

# Screenshots of Blueprints in RAM (no save): the hero page's counts and an item at a
# breakthrough.  Godot --path . --resolution 450x800 res://tests/ui/BlueprintShots.tscn -- <out_dir>

const HOME := preload("res://game/menu/Home.tscn")
const HeroCat := preload("res://game/core/HeroCat.gd")

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://blueprint_shots"
	DirAccess.make_dir_recursive_absolute(out)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.forge_stones = 400
	PlayerData.gold = 2400
	PlayerData.blueprints = {"weapon": 3, "helmet": 12, "armor": 6, "boots": 0}
	# Wear a rare bow at level 10: its next level is a breakthrough needing 5 weapon blueprints.
	var bow: String = HeroCat.add_item(PlayerData.hero_cat, "cung_san")
	PlayerData.hero_cat["bag"][bow]["level"] = 10
	PlayerData.hero_cat_equip(bow)
	var home = HOME.instantiate()
	add_child(home)
	await get_tree().create_timer(0.6).timeout
	home.select_tab(home.HERO_TAB, false)
	await get_tree().create_timer(0.8).timeout
	await _shot(out, "1-hero-page")
	home._pages[home.HERO_TAB]._open_detail(bow)
	await get_tree().create_timer(0.6).timeout
	await _shot(out, "2-breakthrough")
	get_tree().quit()

func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
