extends Node

# Regression checks for the battle/economy fixes, in RAM (no save):
#   splash hits every foe in range; the victory chest is queued at reward time and saved;
#   a lone enemy healer goes for the wall; a merge keeps the max_alive cap; the hero skill
#   needs a living hero; a x10 summon's epic guarantee leaves no stray unlock.
# Run: Godot --headless --path . res://tests/BattleFixesTest.tscn

const Projectile = preload("res://game/battle/Projectile.gd")

var _fails := 0

func _check(ok: bool, what: String) -> void:
	print(("FIX_OK " if ok else "FIX_FAIL ") + what)
	if not ok:
		_fails += 1

func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	var battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(battle)
	await get_tree().process_frame
	battle.phase = "fight"

	# 1. Splash: five weak foes in one spot all die from one shell.
	for i in 5:
		battle._spawn_enemy("pawn", false)
	for u in battle.enemy_units:
		u.position = Vector2(360, 300)
		u.hp = 1.0
	var shell = load("res://game/battle/Projectile.tscn").instantiate() if ResourceLoader.exists("res://game/battle/Projectile.tscn") else Projectile.new()
	shell.battle = battle
	shell.team = 0
	shell.damage = 50.0
	shell.splash_radius = 80.0
	shell.point = Vector2(360, 300)
	shell.position = Vector2(360, 300)
	battle.projectiles.add_child(shell)
	shell._travel = 99999.0
	shell._start = Vector2(360, 300)
	shell._fly_bomb(0.016)
	await get_tree().process_frame
	_check(battle.enemy_units.size() == 0, "a shell kills every foe in its splash (left: %d)" % battle.enemy_units.size())

	# 3. A lone enemy healer attacks the wall; with a fighter beside it, it hangs back.
	battle._spawn_enemy("monk", false)
	var monk = battle.enemy_units[-1]
	_check(monk._attacks_wall(), "a lone enemy healer goes for the wall")
	battle._spawn_enemy("warrior", false)
	_check(not monk._attacks_wall(), "with a fighter beside it the healer hangs back")
	for u in battle.enemy_units.duplicate():
		u.queue_free()
	battle.enemy_units.clear()

	# 5. Hero skill needs a living hero.
	battle._spawn_enemy("pawn", false)
	var gear = null
	for g in battle.board.gears.values():
		if g.troop.id.begins_with("skill:"):
			gear = g
	if gear != null:
		battle.hero_unit = null
		_check(not battle.cast_hero_skill(gear), "no skill while the hero has fallen")
		battle._spawn_hero()
		_check(battle.cast_hero_skill(gear), "the living hero casts its skill")
		battle.hero_unit.hp = 1.0
		battle._spawn_hero()
		_check(is_equal_approx(battle.hero_unit.hp, battle.hero_unit.max_hp), "a standing hero is healed when the next wave starts")

	# 4. Merge keeps the cap: two gears' cats count against the merged one.
	var a = battle.board.place_new(PlayerData.TROOPS["kiem"], 1)
	var b = battle.board.place_new(PlayerData.TROOPS["kiem"], 1)
	if a != null and b != null:
		for g in [a, b]:
			for i in 3:
				g._alive.append(battle.spawn_player_unit(PlayerData.TROOPS["kiem"], 1, Vector2(360, 600)))
		b.adopt_units(a)
		var alive: int = b._alive.filter(func(u): return u != null and is_instance_valid(u)).size()
		_check(alive >= PlayerData.TROOPS["kiem"].max_alive, "a merged gear counts both gears' cats (%d)" % alive)

	# 2. Victory chest is queued when rewards are granted, and survives a save.
	PlayerData.victory_chest_in_tests = true
	var reward: Dictionary = PlayerData.grant_battle_rewards(true, 3, 3)
	_check(not PlayerData.pending_chest.is_empty() and PlayerData.pending_chest["cards"].size() == reward["cards"].size(), "the chest is queued with the rewards")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(PlayerData.to_dict()))
	PlayerData.pending_chest = {}
	PlayerData.from_dict(saved)
	_check(not PlayerData.pending_chest.is_empty(), "the queued chest survives a save")
	PlayerData.from_dict({})
	_check(PlayerData.pending_chest.is_empty(), "an old save without a chest loads cleanly")
	PlayerData.victory_chest_in_tests = false

	# 6. x10 guarantee: no unlocked troop without a card behind it.
	PlayerData._reset()
	var bad := 0
	for run in 200:
		PlayerData.gems = 100000
		PlayerData.summon_free_day = PlayerData.today()
		var results: Array = PlayerData.summon(10)
		_check(results.any(func(r): return r["rarity"] >= 2), "x10 holds an epic") if run == 0 else null
		for id in PlayerData.TROOP_ORDER:
			var t: Dictionary = PlayerData.troops[id]
			if t["unlocked"] and t["cards"] < 0:
				bad += 1
	_check(bad == 0, "x10 summons never leave negative cards")
	print("BattleFixesTest: fails=%d" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
