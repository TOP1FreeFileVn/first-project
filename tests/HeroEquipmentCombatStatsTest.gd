extends Node

# Numeric integration checks through the real equipment actions and battle scene.
# Run with an isolated user-data directory; never saves a player profile.
# Godot --headless --path . res://tests/HeroEquipmentCombatStatsTest.tscn
const HeroCat = preload("res://game/core/HeroCat.gd")
const BattleScene = preload("res://game/battle/Battle.tscn")
const UnitScene = preload("res://game/battle/Unit.tscn")
var _battle
var _checks := 0
var _failures := 0
var _changes := 0


func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.music_on = false
	PlayerData.tutorial_done = true
	PlayerData.changed.connect(func(): _changes += 1)
	var sword := _uid("kiem_go")
	var helmet := _uid("mu_da")
	var armor := _uid("giap_vai")
	var bow := _uid("cung_san")
	# Start with the same inventory but nothing equipped: bag ownership is not a bonus.
	PlayerData.hero_cat.equipped.clear()
	_check(PlayerData.hero_cat_stats() == {"hp": 1200, "atk": 90, "def": 30}, "unworn gear contributes no stats")
	_fresh_battle()
	_near(_battle.core.max_hp, 112.0, "base hero HP reaches actual castle HP")
	_near(_wall_hit(), 16.45, "base DEF reduces an actual 50-damage siege hit")

	PlayerData.hero_cat_equip(sword)
	_check(_changes == 1 and PlayerData.hero_cat_stats().atk == 130, "equip emits one refresh with ATK 90 -> 130")
	PlayerData.hero_cat_equip(helmet)
	PlayerData.hero_cat_equip(armor)
	_check(_changes == 3, "each worn piece emits one refresh")
	_check(PlayerData.hero_cat_stats() == {"hp": 1580, "atk": 130, "def": 46}, "starter equipment totals are visible immediately")
	_check(HeroCat.power(PlayerData.hero_cat_stats()) == 3172, "equipment contributes to hero combat power")
	_fresh_battle()
	_near(_battle.core.max_hp, 115.8, "worn HP raises actual castle maximum")
	_near(_wall_hit(), 15.89, "worn DEF reduces actual wall damage further")
	var sword_infantry := _soldier_damage("kiem")
	var sword_archer := _soldier_damage("cung")
	_near(_cast_damage(), 45.5, "equipped sword ATK produces 45.5 actual skill damage")
	var before := _changes
	_check(not PlayerData.hero_cat_upgrade(sword) and _changes == before, "unaffordable upgrade does not emit a refresh")
	PlayerData.blueprints.weapon = 100
	_check(PlayerData.hero_cat_upgrade(sword), "weapon upgrade succeeds with its blueprints")
	_check(_changes == before + 1 and PlayerData.hero_cat_stats().atk == 135, "upgrade refresh carries increased ATK")
	_check(HeroCat.power(PlayerData.hero_cat_stats()) == 3212, "weapon upgrade increases displayed hero power")
	_near(_cast_damage(), 47.25, "upgraded ATK increases actual skill damage without stale stat caching")

	before = _changes
	PlayerData.hero_cat_equip(bow)
	_check(_changes == before + 1 and PlayerData.hero_cat_stats().atk == 142, "weapon swap emits one refresh and replaces its ATK")
	_check(HeroCat.equipped_uid(PlayerData.hero_cat, "weapon") == bow and HeroCat.spare(PlayerData.hero_cat).has(sword), "swap replaces the slot and returns sword to bag")
	_fresh_battle()
	_check(_battle._skill.get("weapon", "") == "cung_san", "next battle uses the equipped bow skill")
	_near(_cast_damage(), 284.0, "bow's eight arrows apply 284 total damage from equipped ATK")
	var bow_infantry := _soldier_damage("kiem")
	var bow_archer := _soldier_damage("cung")
	_near(sword_infantry / bow_infantry, 1.08, "sword gives real infantry its 8 percent paired-class bonus")
	_near(bow_archer / sword_archer, 1.08, "bow transfers the 8 percent bonus to real ranged soldiers")
	_check(not PlayerData.persist, "all actions kept save persistence disabled")
	_battle.free()
	# Muting MusicLib does not stop its looping streams. Release this fixture's audio
	# before shutting down, then let the audio server and deferred frees settle.
	for library in [MusicLib, SoundLib]:
		for player in library.get_children():
			if player is AudioStreamPlayer:
				player.stop()
				player.stream = null
	await get_tree().process_frame
	await get_tree().process_frame
	print("HeroEquipmentCombatStatsTest: %d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures else 0)


func _fresh_battle() -> void:
	if is_instance_valid(_battle):
		_battle.free()
	_battle = BattleScene.instantiate()
	# Setup and real combat methods run; background simulation cannot affect measurements.
	_battle.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_battle)


func _wall_hit() -> float:
	_battle.phase = "fight"
	var before: float = _battle.core.hp
	_battle.damage_core(50.0)
	return before - _battle.core.hp


func _soldier_damage(id: String) -> float:
	var unit = _battle.spawn_player_unit(PlayerData.TROOPS[id], 1, Vector2(360, 600))
	_check(unit != null, "real battle spawns " + id)
	return float(unit.damage) if unit != null else 0.0


func _cast_damage() -> float:
	# One durable real enemy makes sword hits and the eight-arrow volley deterministic.
	for enemy in _battle.enemy_units:
		if is_instance_valid(enemy):
			enemy.free()
	_battle.enemy_units.clear()
	var enemy = UnitScene.instantiate()
	enemy.setup(_battle, PlayerData.TROOPS["pawn"], _battle.ENEMY, 1, 100.0, 1.0)
	enemy.position = Vector2(360, _battle.RALLY_Y)
	_battle.units_layer.add_child(enemy)
	_battle.enemy_units.append(enemy)
	var gears: Array = _battle.board.gears.values().filter(func(gear): return gear.is_skill())
	_check(gears.size() == 1, "exactly one equipped weapon skill gear exists")
	if gears.is_empty():
		return -1.0
	_battle.phase = "fight"
	var before: float = enemy.hp
	_check(_battle.cast_hero_skill(gears[0]), "real equipped skill casts on a living enemy")
	return before - enemy.hp


func _uid(id: String) -> String:
	for uid in PlayerData.hero_cat.bag:
		if PlayerData.hero_cat.bag[uid].id == id:
			return str(uid)
	return ""


func _near(actual: float, expected: float, reason: String) -> void:
	_check(is_equal_approx(actual, expected), "%s (%.4f, expected %.4f)" % [reason, actual, expected])


func _check(ok: bool, reason: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error(reason)
