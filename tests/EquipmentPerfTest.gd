extends Node

# Times the equipment hot paths with a big bag, in RAM (no save):
#   Godot --path . res://tests/EquipmentPerfTest.tscn -- [bag_size]
# Prints PERF lines: opening 10 gold chests, the hero page build, and a rebuild.

const HeroCat = preload("res://game/core/HeroCat.gd")
const HOME := preload("res://game/menu/Home.tscn")

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var bag := int(args[0]) if args.size() > 0 else 300
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	for i in bag:
		HeroCat.add_item(PlayerData.hero_cat, HeroCat.ITEMS.keys()[i % HeroCat.ITEMS.size()])
	var home = HOME.instantiate()
	add_child(home)
	await get_tree().process_frame
	PlayerData.gems = 100000
	var t := Time.get_ticks_usec()
	PlayerData.open_chest("gold", 10)
	print("PERF open_chest x10 (bag %d): %.1f ms" % [bag, (Time.get_ticks_usec() - t) / 1000.0])
	t = Time.get_ticks_usec()
	var alert := PlayerData.hero_alert()
	print("PERF hero_alert: %.1f ms (%s)" % [(Time.get_ticks_usec() - t) / 1000.0, alert])
	t = Time.get_ticks_usec()
	home.select_tab(home.HERO_TAB, false)
	print("PERF hero page build: %.1f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
	await get_tree().process_frame
	t = Time.get_ticks_usec()
	await get_tree().process_frame
	print("PERF first frame after build: %.1f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
	t = Time.get_ticks_usec()
	home._pages[home.HERO_TAB].refresh()
	print("PERF hero page rebuild: %.1f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
	print("PERF bag items now: %d" % PlayerData.hero_cat["bag"].size())
	# The x10 gold chest summary (60 items).
	var loot: Dictionary = PlayerData.open_chest("gold", 10)
	var opening = load("res://game/ui/ChestOpening.gd").new()
	opening.setup("Rương Vàng ×10", Color("f2c14e"), loot, [], true)
	opening.attach(home)
	await get_tree().process_frame
	t = Time.get_ticks_usec()
	opening._show_summary()
	print("PERF chest summary x10 (%d items): %.1f ms" % [loot["items"].size(), (Time.get_ticks_usec() - t) / 1000.0])
	t = Time.get_ticks_usec()
	await get_tree().process_frame
	print("PERF first summary frame: %.1f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
	get_tree().quit()
