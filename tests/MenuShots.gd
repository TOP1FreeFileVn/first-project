extends Node

# Screenshots every lobby tab, the team swap mode, the troop popup and each stage of a
# chest opening, on a throwaway profile (the real save is never touched).
# Run (windowed): Godot --path . res://tests/MenuShots.tscn -- --shot-dir=C:/some/folder

const ChestOpening = preload("res://game/ui/ChestOpening.gd")
# A fixed chest so the shots always show a new legendary and an epic.
const FAKE_LOOT := {"cards": {"pawn": 5, "archer": 3, "fire_archer": 2, "bomber": 1, "general": 1}, "gold": 80}
const FAKE_NEW := ["fire_archer", "general"]

const STEPS := [
	["tab", 2], ["shot", "battle"],
	["level", -1], ["wait", 0.4], ["shot", "battle_prev"], ["level", 1], ["wait", 0.4], ["level", 1], ["wait", 0.4], ["shot", "battle_locked"],
	["tab", 1], ["shot", "troops"],
	["swap", "bomber"], ["shot", "troops_swap"], ["unswap"],
	["scroll", 400], ["drag", "bomber", 1], ["wait", 0.3], ["shot", "troops_drag"], ["drop", 1], ["wait", 0.3], ["shot", "troops_dropped"],
	["filter", 3], ["shot", "troops_legend"], ["filter", -1],
	["detail", "general"], ["shot", "troop_detail"], ["close"],
	["tab", 3], ["shot", "castle"],
	["tab", 0], ["shot", "shop"],
	["fake_chest"], ["wait", 1.3], ["shot", "chest_wait"],
	["tap"], ["wait", 0.5], ["shot", "chest_windup"], ["wait", 0.42], ["shot", "chest_open"],
	["wait", 0.9], ["shot", "chest_card"],
	["last_card"], ["wait", 0.55], ["shot", "chest_tease"], ["wait", 0.75], ["shot", "chest_legend"],
	["skip"], ["wait", 0.8], ["shot", "chest_summary"], ["close_chest"],
	["chest", "gold"], ["wait", 1.0], ["tap"], ["tap"], ["tap"], ["skip"], ["wait", 0.6], ["shot", "chest_real"], ["close_chest"],
	["tab", 4], ["shot", "heroes"],
	["tab", 2], ["popup", "login"], ["shot", "login"], ["close"],
	["popup", "quests"], ["shot", "quests"], ["close"],
	["popup", "events"], ["shot", "events"], ["close"],
	["popup", "profile"], ["shot", "profile"], ["close"],
	["page", "patrol"], ["shot", "patrol"],
	["page", "summon"], ["wait", 0.3], ["shot", "summon"],
	["summon", 10], ["wait", 0.7], ["shot", "summon_charge"], ["wait", 1.2], ["shot", "summon_reveal"],
	["skip_summon"], ["wait", 0.5], ["shot", "summon_done"], ["close_chest"],
	["summon", 1], ["wait", 3.2], ["shot", "summon_single"], ["close_chest"],
]

var _home
var _dir := ""
var _step := 0
var _wait := 1.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			_dir = arg.get_slice("=", 1)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.unlocked_levels = 3
	PlayerData.level_stars = {0: 3, 1: 2}
	PlayerData.castle_level = 3
	PlayerData.troops["warrior"]["level"] = 6
	PlayerData.troops["warrior"]["cards"] = 12
	for id in ["lancer", "bomber", "general", "miner"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.troops["lancer"]["stars"] = 2
	PlayerData.troops["lancer"]["level"] = 12
	PlayerData.team = ["warrior", "archer", "lancer", "general"]
	PlayerData.workshop = {"meat_regen": 2, "start_meat": 1}
	PlayerData.patrol_last_claim = PlayerData.now() - 3 * 3600
	PlayerData.heroes["storm"]["owned"] = true
	PlayerData.heroes["storm"]["level"] = 7
	PlayerData.heroes["storm"]["stars"] = 2
	PlayerData.heroes["ember"]["shards"] = 18
	PlayerData.hero = "storm"
	PlayerData.login_claimed = 3
	PlayerData.login_day = PlayerData.today() - 1
	PlayerData.track("win", 2)
	PlayerData.track("chest")
	PlayerData.claim_quest("login")
	PlayerData.claim_quest("win")
	PlayerData.player_name = "Dang"
	PlayerData.avatar = "hero:storm"
	PlayerData.frame = "royal"
	_home = load("res://game/menu/Home.tscn").instantiate()
	add_child(_home)


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	if _step >= STEPS.size():
		get_tree().quit()
		return
	var step: Array = STEPS[_step]
	_step += 1
	_wait = 0.4
	var troops_page = _home._pages[1]
	match step[0]:
		"level":
			_home._pages[2]._go(step[1])
		"tab":
			_home.select_tab(step[1], false)
		"shot":
			get_viewport().get_texture().get_image().save_png("%s/menu_%s.png" % [_dir, step[1]])
		"swap":
			troops_page._swap_id = step[1]
			troops_page.refresh()
			_wait = 0.25
		"scroll":
			troops_page._scroll.scroll_vertical = step[1]
		"drag":
			troops_page._press_id = step[1]
			troops_page._press_slot = -1
			troops_page._start_drag()
			troops_page._move_ghost(troops_page._slots[step[2]].get_global_rect().get_center() + Vector2(20, 10))
		"drop":
			troops_page._drop(troops_page._slots[step[1]].get_global_rect().get_center())
		"unswap":
			troops_page._swap_id = ""
			troops_page.refresh()
		"filter":
			troops_page._filter = step[1]
			troops_page.refresh()
		"detail":
			troops_page._open_detail(step[1])
		"chest":
			_home._pages[0]._open(step[1])
		"fake_chest":
			var opening = ChestOpening.new()
			opening.setup("Rương Vàng", Color("e8b93c"), FAKE_LOOT, FAKE_NEW, false, func(): pass)
			opening.attach(_home)
		"tap":
			_opening()._on_tap()
			_wait = 0.1
		"last_card":
			var opening = _opening()
			opening._tween.kill()
			opening._clear_extras()
			if opening._card != null:
				opening._card.queue_free()
				opening._card = null
			opening._next = opening._order.size() - 1
			opening._next_card()
			_wait = 0.0
		"skip":
			_opening().skip()
			_wait = 0.0
		"wait":
			_wait = step[1]
		"close_chest":
			_opening().get_parent().queue_free()
		"close":
			var overlay = _home.get_child(_home.get_child_count() - 1)
			if overlay is ColorRect:
				overlay.queue_free()
		"popup":
			match step[1]:
				"login":
					_home.MetaPopups.open_login(_home)
				"quests":
					_home.MetaPopups.open_quests(_home)
				"events":
					_home.MetaPopups.open_events(_home)
				"profile":
					_home.MetaPopups.open_profile(_home)
		"page":
			_home.open_page(load("res://game/menu/pages/PatrolPage.gd") if step[1] == "patrol" else _home.SummonPage)
		"summon":
			PlayerData.gems = 5000
			_home._overlay_page._summon(step[1])
			_wait = 0.0
		"skip_summon":
			_opening().skip()
			_wait = 0.0


func _opening():
	var layer = _home.get_child(_home.get_child_count() - 1)
	return layer.get_child(0)
