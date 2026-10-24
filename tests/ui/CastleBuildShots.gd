extends Node

# The castle upgrade's building scene in the castle page, in RAM (no save):
# cats run in, hammer, a burst, the castle stands at its new tier, cats fade away.
# Run (windowed): Godot --path . --resolution 450x800 res://tests/ui/CastleBuildShots.tscn -- <out_dir>

const CastlePage = preload("res://game/menu/pages/CastlePage.gd")

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://castle_build"
	DirAccess.make_dir_recursive_absolute(out)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.castle_level = 2   # tier 1; level 3 is tier 2, a new shape
	PlayerData.gold = 100000
	var home = load("res://game/menu/Home.tscn").instantiate()
	add_child(home)
	home.select_tab(home.BATTLE_TAB, false)
	await get_tree().create_timer(0.6).timeout
	home.open_page(CastlePage)
	await get_tree().create_timer(0.5).timeout
	var page = home._overlay_page
	var tier_before: int = page._castle_tiers._tier
	page._upgrade()
	for shot in [["1-run-in", 0.45], ["2-hammer", 1.2], ["3-hammer", 1.0], ["4-burst", 0.75], ["5-fade", 0.6], ["6-done", 1.4]]:
		await get_tree().create_timer(shot[1]).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(shot[0] + ".png"))
		page = home._overlay_page
		var build = page.find_child("CastleBuild", true, false)
		print("CASTLE_BUILD %s level=%d building=%s dust=%d" % [shot[0], PlayerData.castle_level, page._building, build._dust.size() if build != null else -1])
	print("CASTLE_BUILD tier %d -> %d" % [tier_before, home._overlay_page._castle_tiers._tier])
	get_tree().quit()
