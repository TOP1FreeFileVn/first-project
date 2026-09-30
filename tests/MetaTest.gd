extends Node

# Logic checks for heroes, the summon event, the 7-day gift, daily quests, the profile and
# saving them. Never touches the real save.
# Run: Godot --headless --path . res://tests/MetaTest.tscn

const Heroes = preload("res://game/core/Heroes.gd")
const Meta = preload("res://game/core/Meta.gd")

var _checks := 0
var _failed := 0


func _ready() -> void:
	PlayerData.persist = false
	_test_heroes()
	_test_summon_rates()
	_test_summon_rules()
	_test_login()
	_test_quests()
	_test_profile_and_save()
	print("MetaTest: %d checks, %d failed" % [_checks, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		print("FAIL: ", what)


func _test_heroes() -> void:
	PlayerData._reset()
	_check(PlayerData.leader() == Heroes.STARTER, "new save leads with the starter hero")
	_check(is_equal_approx(PlayerData.core_hp_multiplier(), PlayerData.castle_stats()["hp"] * 1.15), "starter gives +15% castle HP")
	_check(PlayerData.hero_damage_multiplier() == 1.0, "starter gives no damage")
	PlayerData.gold = 100000
	_check(PlayerData.hero_level_up("iron"), "hero levels up with gold")
	_check(PlayerData.hero_state("iron")["level"] == 2, "level is 2")
	PlayerData.heroes["iron"]["level"] = 10
	_check(PlayerData.hero_level_cost("iron") == -1, "level capped by stars")
	PlayerData.heroes["iron"]["shards"] = 10
	_check(PlayerData.hero_star_up("iron"), "star up with shards")
	_check(PlayerData.hero_level_cost("iron") > 0, "star up lifts the cap")
	_check(not PlayerData.hero_unlock("storm"), "can't unlock without shards")
	PlayerData.heroes["storm"]["shards"] = Heroes.UNLOCK_SHARDS
	_check(PlayerData.hero_unlock("storm"), "unlock with 30 shards")
	PlayerData.select_hero("storm")
	_check(is_equal_approx(PlayerData.hero_damage_multiplier(), 1.18), "storm gives +18% damage")
	_check(PlayerData.core_hp_multiplier() == PlayerData.castle_stats()["hp"], "only the leader's buff counts")
	_check(not PlayerData.add_hero("storm"), "duplicate is not new")
	_check(PlayerData.hero_state("storm")["shards"] == Heroes.DUPLICATE_SHARDS, "duplicate becomes shards")
	PlayerData.select_hero("sage")
	_check(PlayerData.leader() == "storm", "can't lead with a hero you don't own")


func _test_summon_rates() -> void:
	PlayerData._reset()
	PlayerData.gems = 10000000
	var counts := {}
	var pulls := 20000
	var featured := PlayerData.summon_featured()
	var featured_hits := 0
	for i in pulls / 10:
		for result in PlayerData.summon(10):
			var key: String = result["type"]
			if key == "hero":
				key = "hero_%d" % Heroes.HEROES[result["id"]]["rarity"]
				if result["id"] == featured:
					featured_hits += 1
			counts[key] = counts.get(key, 0) + 1
	var rate := featured_hits * 100.0 / pulls
	print("  summon %d pulls: featured %.2f%%, %s" % [pulls, rate, counts])
	# 1.5% base; the pity at 50 fires about half the time, so about 2.9% overall.
	_check(rate > 2.0 and rate < 3.5, "featured rate with pity about 2.9%% (%.2f)" % rate)
	_check(counts.get("gold", 0) > pulls * 0.4, "gold is the most common result")
	PlayerData._reset()
	PlayerData.gems = 1000000
	var longest := 0
	var since := 0
	for i in 3000:
		var result: Dictionary = PlayerData.summon(1)[0]
		since += 1
		if result["type"] == "hero" and result["id"] == featured:
			longest = maxi(longest, since)
			since = 0
	_check(longest <= Heroes.SUMMON_PITY, "pity: never more than %d pulls without the featured hero (%d)" % [Heroes.SUMMON_PITY, longest])


func _test_summon_rules() -> void:
	PlayerData._reset()
	PlayerData.gems = 0
	_check(PlayerData.summon_cost(1) == 0, "first pull of the day is free")
	_check(PlayerData.summon(1).size() == 1, "free pull works with no gems")
	_check(not PlayerData.summon_free_ready(), "free pull used")
	_check(PlayerData.summon(1).is_empty(), "no gems, no second pull")
	_check(PlayerData.quest_count("summon") == 1, "summon counts for the quest")
	PlayerData.gems = 270
	var results := PlayerData.summon(10)
	_check(results.size() == 10 and PlayerData.gems == 0, "ten-pull costs 270")
	_check(results.any(func(r): return r["type"] == "hero"), "ten-pull has a hero")


func _test_login() -> void:
	PlayerData._reset()
	var gold := PlayerData.gold
	_check(PlayerData.login_can_claim(), "day 1 claimable")
	var got := PlayerData.claim_login()
	_check(got["gold"] == 300 and PlayerData.gold == gold + 300, "day 1 gives 300 gold")
	_check(not PlayerData.login_can_claim(), "only once a day")
	_check(PlayerData.claim_login().is_empty(), "second claim refused")
	for day in range(2, 8):
		PlayerData.login_day -= 1
		PlayerData.claim_login()
	_check(PlayerData.owns_hero("sage"), "day 7 gives the sage hero")
	_check(PlayerData.login_cycles == 1 and PlayerData.frame_unlocked("gold"), "full week unlocks the gold frame")
	PlayerData.login_day -= 1
	_check(PlayerData.login_progress() == 0, "a new cycle starts the next day")
	got = PlayerData.claim_login()
	_check(got["gold"] == 300 and PlayerData.login_claimed == 1, "cycle restarts at day 1")


func _test_quests() -> void:
	PlayerData._reset()
	_check(PlayerData.quest_done("login"), "login quest completes itself")
	_check(not PlayerData.quest_done("win"), "win quest not done")
	PlayerData.gold = 100000
	PlayerData.level_up("warrior")
	PlayerData.level_up("warrior")
	_check(PlayerData.quest_done("upgrade"), "two upgrades complete the quest")
	var gems := PlayerData.gems
	PlayerData.free_chest_at = 0
	PlayerData.open_chest("wood")
	_check(PlayerData.quest_done("chest"), "opening a chest counts")
	PlayerData.claim_quest("chest")
	_check(PlayerData.gems == gems + 5, "chest quest pays 5 gems")
	_check(PlayerData.claim_quest("chest").is_empty(), "no double claim")
	PlayerData.claim_quest("login")
	_check(PlayerData.quest_points() == 40 and PlayerData.milestone_ready(0), "40 points reach the first chest")
	_check(not PlayerData.claim_milestone(0).is_empty() and PlayerData.claim_milestone(0).is_empty(), "milestone once")
	PlayerData.quest_day -= 1
	_check(PlayerData.quest_points() == 0 and not PlayerData.milestone_claimed(0), "quests reset on a new day")


func _test_profile_and_save() -> void:
	PlayerData._reset()
	_check(PlayerData.avatar_unlocked("10") and not PlayerData.avatar_unlocked("11"), "rows 1-2 open, row 3 locked")
	PlayerData.set_avatar("25")
	_check(PlayerData.avatar == "1", "locked avatar refused")
	PlayerData.set_avatar("hero:iron")
	_check(PlayerData.avatar == "hero:iron", "owned hero as avatar")
	_check(not PlayerData.frame_unlocked("royal"), "royal frame needs a legendary hero")
	PlayerData.set_player_name("  Người Chơi Rất Dài Tên Quá  ")
	_check(PlayerData.player_name.length() <= 16, "name trimmed to 16")
	PlayerData.heroes["valor"]["owned"] = true
	PlayerData.heroes["valor"]["stars"] = 3
	PlayerData.hero = "valor"
	PlayerData.summon_pity = 17
	PlayerData.login_claimed = 4
	PlayerData.track("win", 2)
	var data := PlayerData.to_dict()
	var text := JSON.stringify(data)
	PlayerData._reset()
	PlayerData.from_dict(JSON.parse_string(text))
	_check(PlayerData.leader() == "valor" and PlayerData.hero_state("valor")["stars"] == 3, "heroes survive a save")
	_check(PlayerData.summon_pity == 17 and PlayerData.login_claimed == 4, "summon and login survive a save")
	_check(PlayerData.quest_count("win") == 2, "quest progress survives a save")
	_check(PlayerData.avatar == "hero:iron", "avatar survives a save")
	# A save from before heroes existed gets the starter.
	var old := PlayerData.to_dict()
	old.erase("heroes")
	PlayerData.from_dict(old)
	_check(PlayerData.leader() == Heroes.STARTER, "old saves get the starter hero")
