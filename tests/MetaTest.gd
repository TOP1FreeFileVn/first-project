extends Node

# Logic checks for the hero cat's equipment, the equipment summon, the 7-day gift, daily
# quests, the profile and saving them. Never touches the real save.
# Run: Godot --headless --path . res://tests/MetaTest.tscn
# (Deeper equipment economy checks: tests/EquipmentEconomyTest.gd.)

const HeroCat = preload("res://game/core/HeroCat.gd")
const Meta = preload("res://game/core/Meta.gd")

var _checks := 0
var _failed := 0


func _ready() -> void:
	PlayerData.persist = false
	_test_hero_cat()
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


func _test_hero_cat() -> void:
	PlayerData._reset()
	# The starter kit's HP raises the castle; troops and the castle share no leader buff now.
	_check(PlayerData.core_hp_multiplier() > PlayerData.castle_stats()["hp"], "starter gear raises castle HP")
	_check(PlayerData.round_income_bonus() == 0 and is_equal_approx(PlayerData.spawn_speed_multiplier(), 1.0), "no income/spawn buff without workshop")
	var weapon := HeroCat.equipped_uid(PlayerData.hero_cat, "weapon")
	PlayerData.gold = 0
	PlayerData.forge_stones = 0
	_check(not PlayerData.hero_cat_upgrade(weapon), "no stones, no level")
	PlayerData.forge_stones = 1000
	PlayerData.gold = 1000
	_check(PlayerData.hero_cat_upgrade(weapon), "levels with Forge Stones")
	_check(HeroCat.item(PlayerData.hero_cat, weapon)["level"] == 2, "level is 2")
	_check(PlayerData.gold > 900, "an equipment level costs little gold (%d left)" % PlayerData.gold)


func _test_summon_rates() -> void:
	PlayerData._reset()
	PlayerData.gems = 10000000
	var counts := [0, 0, 0, 0]
	var pulls := 20000
	# Inventory and persistence are checked separately. Discard rate samples so
	# these simulations keep a bounded bag while preserving real summon/pity logic.
	for i in pulls / 10:
		for result in PlayerData.summon(10):
			counts[result["rarity"]] += 1
			PlayerData.hero_cat["bag"].erase(result["uid"])
	var legendary: float = counts[3] * 100.0 / pulls
	print("  summon %d pulls by rarity: %s (legendary %.2f%%)" % [pulls, counts, legendary])
	_check(counts[0] > counts[1] and counts[1] > counts[2] and counts[2] > counts[3], "rarer items come less often")
	# 1.5% base plus the 60-pull pity.
	_check(legendary > 1.4 and legendary < 3.5, "legendary rate with pity about 2%% (%.2f)" % legendary)
	PlayerData._reset()
	PlayerData.gems = 1000000
	var longest := 0
	var since := 0
	for i in 3000:
		var result: Dictionary = PlayerData.summon(1)[0]
		since += 1
		if result["rarity"] >= 3:
			longest = maxi(longest, since)
			since = 0
		PlayerData.hero_cat["bag"].erase(result["uid"])
	_check(longest <= HeroCat.SUMMON_PITY, "pity: never more than %d pulls without a legendary (%d)" % [HeroCat.SUMMON_PITY, longest])


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
	_check(results.any(func(r): return r["rarity"] >= 2), "ten-pull has an epic or better")


func _test_login() -> void:
	PlayerData._reset()
	var gold := PlayerData.gold
	_check(PlayerData.login_can_claim(), "day 1 claimable")
	var got := PlayerData.claim_login()
	_check(got["gold"] == 300 and PlayerData.gold == gold + 300, "day 1 gives 300 gold")
	_check(not PlayerData.login_can_claim(), "only once a day")
	_check(PlayerData.claim_login().is_empty(), "second claim refused")
	var bag: int = PlayerData.hero_cat["bag"].size()
	for day in range(2, 8):
		PlayerData.login_day -= 1
		PlayerData.claim_login()
	_check(PlayerData.hero_cat["bag"].size() == bag + 1, "day 7 gives an item")
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
	PlayerData.level_up(PlayerData.STARTER_TROOPS[0])
	PlayerData.forge_stones = 100
	PlayerData.hero_cat_upgrade(HeroCat.equipped_uid(PlayerData.hero_cat, "weapon"))
	_check(PlayerData.quest_done("upgrade"), "a troop and an equipment upgrade complete the quest")
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
	_check(not PlayerData.frame_unlocked("royal"), "royal frame needs a legendary item")
	HeroCat.add_item(PlayerData.hero_cat, "katana_nguyet")
	_check(PlayerData.frame_unlocked("royal"), "a legendary item unlocks the royal frame")
	PlayerData.set_player_name("  Người Chơi Rất Dài Tên Quá  ")
	_check(PlayerData.player_name.length() <= 16, "name trimmed to 16")
	PlayerData.forge_stones = 321
	PlayerData.summon_pity = 17
	PlayerData.login_claimed = 4
	PlayerData.track("win", 2)
	var data := PlayerData.to_dict()
	var text := JSON.stringify(data)
	PlayerData._reset()
	PlayerData.from_dict(JSON.parse_string(text))
	_check(PlayerData.forge_stones == 321, "Forge Stones survive a save")
	_check(PlayerData.summon_pity == 17 and PlayerData.login_claimed == 4, "summon and login survive a save")
	_check(PlayerData.quest_count("win") == 2, "quest progress survives a save")
	_check(PlayerData.hero_cat["bag"].values().any(func(it): return it["id"] == "katana_nguyet"), "equipment survives a save")
