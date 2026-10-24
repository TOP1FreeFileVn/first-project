extends Node

# Checks the Balance layer: every shipped formula must give exactly what the old
# hard-coded code gave, and editing / undo / import / export must behave.
# Run: Godot --headless --path . res://tests/BalanceTest.tscn

const Economy = preload("res://game/core/Economy.gd")
const Content = preload("res://game/core/Content.gd")

var _failures := 0
var _checks := 0


func _ready() -> void:
	_check_formulas_match_old_code()
	_check_editing()
	_check_crit()
	print("BalanceTest: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _check_formulas_match_old_code() -> void:
	for level in range(1, 31):
		_eq("level_cost %d" % level, Economy.level_cost(level), roundi(50.0 * pow(1.35, level - 1)))
		for stars in range(1, 6):
			_eq("troop_multiplier %d/%d" % [level, stars], Economy.troop_multiplier(level, stars), (1.0 + 0.08 * (level - 1)) * pow(1.12, stars - 1))
	for tier in range(1, 6):
		_eq("tier %d" % tier, Economy.tier_multiplier(tier), pow(1.75, tier - 1))
		for base in [2.6, 4.5, 6.0]:
			for bonus in [0.0, 0.05, 0.25]:
				_eq("spawn %s/%d/%s" % [base, tier, bonus], Economy.spawn_interval(base, tier, bonus), base * pow(0.92, tier - 1) / (1.0 + bonus))
	for power in [0.9, 1.5, 2.0, 3.0]:
		for wave in range(0, 8):
			_eq("enemy %s/%d" % [power, wave], Economy.enemy_multiplier(power, wave), power * (1.0 + 0.2 * wave))
	for damage in range(0, 51):
		_eq("siege %d" % damage, Economy.siege_damage(damage), damage * 0.35)
	# Between-wave shop economy (replaced summon cost and meat regen).
	for wave in range(1, 9):
		for bonus in range(0, 6):
			_eq("income %d/%d" % [wave, bonus], Economy.round_income(wave, bonus), 5 + wave + bonus)
	for meat in range(0, 21):
		_eq("interest %d" % meat, Economy.interest(meat), mini(floori(meat / 5.0), 3))
	_eq("interest rounds down", Economy.interest(4.9), 0)
	for rarity in 4:
		_eq("price %d" % rarity, Economy.shop_price(rarity), [2, 3, 4, 6][rarity])
		_eq("price t2 %d" % rarity, Economy.shop_price(rarity, 2), roundi([2, 3, 4, 6][rarity] * 2.5))
	_eq("refund common t1", Economy.sell_refund(0, 1), 1)
	_eq("refund common t3", Economy.sell_refund(0, 3), 6)
	_eq("refund legend t1", Economy.sell_refund(3, 1), 4)
	_eq("odds w1", Economy.shop_odds(1), [80.0, 20.0, 0.0, 0.0])
	_eq("odds w4", Economy.shop_odds(4), [60.0, 32.0, 8.0, 0.0])
	_eq("odds w9", Economy.shop_odds(9), [35.0, 35.0, 22.0, 8.0])
	var old_workshop := {"meat_regen": [120, 1.6], "start_meat": [100, 1.8], "master_gear": [150, 1.6]}
	for id in old_workshop:
		for level in range(0, 6):
			_eq("workshop %s %d" % [id, level], Economy.workshop_cost(id, level), roundi(old_workshop[id][0] * pow(old_workshop[id][1], level)))
	for index in range(0, 10):
		for stars in range(1, 6):
			_eq("win %d/%d" % [index, stars], Economy.win_gold(index, stars), 60 + 40 * (index + 1) + 20 * stars)
	for waves in range(0, 9):
		_eq("loss %d" % waves, Economy.loss_gold(waves), 15 * waves)
	for cleared in range(0, 11):
		_eq("patrol %d" % cleared, Economy.patrol_rate(cleared), 60.0 + 60.0 * cleared)
	for i in range(0, 101):
		var ratio := i / 100.0
		_eq("stars %s" % ratio, Economy.battle_stars(ratio), 3 if ratio >= 0.8 else (2 if ratio >= 0.45 else 1))
	_eq("castle table", Economy.CASTLE.size(), 10)
	_eq("max stars", Economy.MAX_STARS, 5)
	_eq("gift", Economy.FIRST_CLEAR_GIFT[0], "giao")


func _check_editing() -> void:
	var saved_overrides: Dictionary = Balance.overrides.duplicate(true)
	Balance.overrides = {}
	Balance._rebuild()

	_ok("rejects game calls", Balance.set_formula("level_cost", "OS.get_name()") != "")
	_ok("rejects unknown var", Balance.set_formula("level_cost", "gold * 2") != "")
	_ok("rejects below min", Balance.set_formula("level_cost", "0 - level") != "")
	_ok("rejects division by zero", Balance.set_formula("level_cost", "1.0 / (level - 1)") != "")
	_ok("rejects assignment", Balance.set_formula("level_cost", "level = 3") != "")
	_ok("rejects trailing tokens", Balance.set_formula("level_cost", "level * 2 level") != "")
	_ok("rejects trailing number", Balance.set_formula("level_cost", "min(level, 3) 7") != "")
	_ok("rejects unbalanced", Balance.set_formula("level_cost", "(level * 2") != "")
	_ok("rejects extra paren", Balance.set_formula("level_cost", "level * 2 )") != "")
	_ok("rejects if/else", Balance.set_formula("level_cost", "3 if level > 1 else 1") != "")
	_ok("rejects var as call", Balance.set_formula("level_cost", "level(2)") != "")
	_eq("accepts logic", Balance.set_formula("level_cost", "10 + 5 * int(level > 3 and not (level > 20))"), "")
	_eq("logic value", Economy.level_cost(7), 15)
	Balance.undo()
	_eq("accepts valid", Balance.set_formula("level_cost", "level * 100"), "")
	_eq("valid formula applies", Economy.level_cost(7), 700)
	_ok("marked changed", Balance.is_formula_changed("level_cost"))
	Balance.undo()
	_eq("undo restores", Economy.level_cost(7), 303)

	Balance.set_value("elite_hp_mult", 9.0)
	_eq("value applies", Economy.ELITE_HP_MULT, 9.0)
	var exported := Balance.export_json()
	Balance.reset_all()
	_eq("reset", Economy.ELITE_HP_MULT, 5.0)
	_eq("import", Balance.import_json(exported), "")
	_eq("import restores", Economy.ELITE_HP_MULT, 9.0)
	_ok("import rejects junk", Balance.import_json("{\"x\": 1}") != "")

	var warrior: Resource = load("res://game/data/troops/warrior.tres")
	Balance.set_troop_stat("warrior", "max_hp", 999.0)
	_eq("troop override", warrior.max_hp, 999.0)
	Balance.set_level_prop(0, "enemy_power", 7.5)
	_eq("level override", PlayerData.level_data(0).enemy_power, 7.5)
	Balance.reset_all()
	_eq("troop reverts", warrior.max_hp, 85.0)
	_eq("level reverts", PlayerData.level_data(0).enemy_power, 0.9)

	Balance.overrides = saved_overrides
	Balance._rebuild()
	Balance.dirty = false


# Critical hits: sane numbers on every troop, never on healers or supports, and the
# average multiplier matches chance x bonus.
func _check_crit() -> void:
	for id in PlayerData.TROOPS:
		var t: Resource = PlayerData.TROOPS[id]
		_ok("%s crit chance in 0-1" % id, t.crit_chance >= 0.0 and t.crit_chance <= 1.0)
		_ok("%s crit mult >= 1" % id, t.crit_mult >= 1.0)
		if t.role == 2 or t.role == 3:
			_eq("%s never crits" % id, t.crit_factor(), 1.0)
	var assassin: Resource = PlayerData.TROOPS["assassin"]
	_eq("assassin crit factor", assassin.crit_factor(), 1.0 + 0.25 * (2.0 - 1.0))
	# The assassin is the critting enemy; cat soldiers have their own crit tuning.
	_ok("assassin crits most among enemies", PlayerData.TROOPS.values().filter(func(t): return t.id in Content.ENEMY_ORDER).all(func(t): return t.crit_chance <= assassin.crit_chance))


func _eq(name: String, actual, expected) -> void:
	_checks += 1
	var same: bool = is_equal_approx(float(actual), float(expected)) if (actual is float or expected is float) else actual == expected
	if not same:
		_failures += 1
		print("FAIL %s: got %s, expected %s" % [name, actual, expected])


func _ok(name: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL %s" % name)
