extends SceneTree

# The hero-cat equipment economy after the old Tướng system was removed. In RAM, no save:
#   Godot --headless --path . --script res://tests/EquipmentEconomyTest.gd
# Prints EQUIP_OK / EQUIP_FAIL lines and a summary; exits 1 on any failure.

const HeroCat = preload("res://game/core/HeroCat.gd")

var _fails := 0

func _check(ok: bool, what: String) -> void:
	print(("EQUIP_OK " if ok else "EQUIP_FAIL ") + what)
	if not ok:
		_fails += 1

func _initialize() -> void:
	await process_frame
	var pd = root.get_node("PlayerData")
	pd.persist = false
	pd._reset()

	# Every slot has every rarity, so summon and fuse always have a target.
	for slot in HeroCat.SLOTS:
		for r in 4:
			_check(not HeroCat.ids_of(slot, r).is_empty() or r == 3 and slot == "weapon" and false, "item exists %s rarity %d" % [slot, r])

	# Old save with Tướng heroes -> one-time Forge Stone refund; heroes dropped.
	var old: Dictionary = pd.to_dict()
	old.erase("forge_stones")
	old["summon"] = {"pity": 12, "free_day": -1, "total": 30}
	old["heroes"] = {"list": {"iron": {"owned": true, "level": 5, "stars": 2, "shards": 14}}, "leader": "iron"}
	pd.from_dict(old)
	var refund: int = pd.forge_stones
	_check(refund > 0, "old Tướng save refunds stones (%d)" % refund)
	_check(pd.summon_pity == 0, "old hero summon pity does not carry into equipment pity")
	_check(not pd.to_dict().has("heroes"), "save no longer writes heroes")
	pd.from_dict(pd.to_dict())
	_check(pd.forge_stones == refund, "refund happens once (reload keeps %d)" % pd.forge_stones)

	# Chests: equipment + Forge Stones, no troop cards.
	pd.gems = 1000
	pd.gold = 1000
	var bag_before: int = pd.hero_cat["bag"].size()
	var stones_before: int = pd.forge_stones
	var cards_before := 0
	for id in pd.TROOP_ORDER:
		cards_before += pd.troops[id]["cards"]
	var chest: Dictionary = pd.open_chest("silver")
	_check(chest.get("items", []).size() == 3, "silver chest gives 3 items")
	_check(pd.hero_cat["bag"].size() == bag_before + 3, "the items are in the bag")
	_check(chest.get("items", []).any(func(it): return it["rarity"] >= 1), "silver chest has at least one rare")
	_check(pd.forge_stones == stones_before + chest.get("stones", 0) and chest.get("stones", 0) >= 25, "chest gives %d Forge Stones" % chest.get("stones", 0))
	var cards_after := 0
	for id in pd.TROOP_ORDER:
		cards_after += pd.troops[id]["cards"]
	_check(cards_after == cards_before and not chest.has("cards"), "chests no longer give troop cards")
	var gold_chest: Dictionary = pd.open_chest("gold")
	_check(gold_chest.get("items", []).filter(func(it): return it["rarity"] >= 2).size() >= 2, "gold chest has at least 2 epics")

	# Summon: gems -> troop cards; x10 has an epic card.
	pd.gems = 1000
	var ten: Array = pd.summon(10)
	_check(ten.size() == 10 and ten.all(func(r): return r["type"] == "card" and pd.TROOPS.has(r["id"])), "x10 summon gives 10 troop cards")
	_check(ten.any(func(r): return r["rarity"] >= 2), "x10 holds an epic or better")
	_check(ten.filter(func(r): return r["new"]).all(func(r): return pd.is_unlocked(r["id"])), "a new card unlocks its troop")
	_check(pd.gems == 1000 - HeroCat.SUMMON_COST[10], "x10 costs %d gems" % HeroCat.SUMMON_COST[10])
	var free: Array = pd.summon(1)
	_check(free.size() == 1 and pd.gems == 1000 - HeroCat.SUMMON_COST[10], "first x1 of the day is free")

	# Pity: the 60th pull is legendary.
	pd.summon_pity = HeroCat.SUMMON_PITY - 1
	pd.gems = 1000
	var pity: Array = pd.summon(1)
	_check(pity[0]["rarity"] == 3, "pity pull is a legendary troop")

	# Easier stars: up to 5, costing 3 / 6 / 12 / 24 cards.
	pd._reset()
	var t: String = pd.STARTER_TROOPS[0]
	_check(load("res://game/core/Economy.gd").MAX_STARS == 5, "five stars")
	var costs := []
	for star in range(1, 5):
		pd.troops[t]["cards"] = 100
		costs.append(pd.star_up_cost(t))
		pd.star_up(t)
	_check(costs == [3, 6, 12, 24], "star costs are 3, 6, 12, 24 (got %s)" % [costs])
	_check(pd.troops[t]["stars"] == 5 and pd.star_up_cost(t) == -1, "max at 5 stars")
	_check(pd.level_cap(t) == 50, "5 stars open level 50")

	# Upgrade costs stones, not (much) gold.
	var weapon: String = HeroCat.equipped_uid(pd.hero_cat, "weapon")
	pd.forge_stones = 1000
	pd.gold = 1000
	var lv: int = HeroCat.item(pd.hero_cat, weapon)["level"]
	var cost: int = HeroCat.upgrade_cost(pd.hero_cat, weapon)
	var gold_cost: int = HeroCat.upgrade_gold(pd.hero_cat, weapon)
	_check(pd.hero_cat_upgrade(weapon), "upgrade with stones")
	_check(HeroCat.item(pd.hero_cat, weapon)["level"] == lv + 1, "level went up")
	_check(pd.forge_stones == 1000 - cost and pd.gold == 1000 - gold_cost, "spent %d stones + %d gold" % [cost, gold_cost])
	pd.forge_stones = 0
	_check(not pd.hero_cat_upgrade(weapon), "no stones, no upgrade")

	# Fuse: 3 copies -> next rarity, keeps the worn slot.
	pd._reset()
	var worn_helmet: String = HeroCat.equipped_uid(pd.hero_cat, "helmet")
	var helmet_id: String = HeroCat.item(pd.hero_cat, worn_helmet)["id"]
	HeroCat.add_item(pd.hero_cat, helmet_id)
	HeroCat.add_item(pd.hero_cat, helmet_id)
	_check(pd.hero_cat_fusable().has(helmet_id), "3 %s are fusable" % helmet_id)
	var fused: String = pd.hero_cat_fuse(helmet_id)
	var target: String = HeroCat.fuse_target(helmet_id)
	_check(fused != "" and HeroCat.item(pd.hero_cat, fused)["id"] == target, "fused into %s" % target)
	_check(HeroCat.equipped_uid(pd.hero_cat, "helmet") == fused, "fused item is worn in place of the old one")
	_check(HeroCat.copies(pd.hero_cat, helmet_id).is_empty(), "the 3 copies are gone")

	# Salvage: unworn only.
	var spare: Array = HeroCat.spare(pd.hero_cat)
	var s0: int = pd.forge_stones
	var value: int = HeroCat.salvage_value(pd.hero_cat, spare[0])
	_check(pd.hero_cat_salvage(spare[0]) == value and pd.forge_stones == s0 + value, "salvage gives %d stones" % value)
	_check(pd.hero_cat_salvage(HeroCat.equipped_uid(pd.hero_cat, "weapon")) == 0, "worn item cannot be salvaged")

	# Battle rewards give stones; gear stats reach the battle.
	pd._reset()
	pd.current_level = 2
	var won: Dictionary = pd.grant_battle_rewards(true, 3, 5)
	_check(won.get("stones", 0) > 0 and pd.forge_stones == won["stones"], "win gives %d stones" % won.get("stones", 0))
	var lost: Dictionary = pd.grant_battle_rewards(false, 0, 2)
	_check(lost.get("stones", 0) == HeroCat.LOSS_STONES, "loss with waves gives %d stones" % HeroCat.LOSS_STONES)
	_check(pd.core_hp_multiplier() > pd.castle_stats()["hp"], "hero-cat HP raises castle HP")
	_check(pd.wall_block() > 0.0, "hero-cat armour blocks wall damage (%.3f)" % pd.wall_block())
	var pairs: Array = HeroCat.def(pd.hero_cat, HeroCat.equipped_uid(pd.hero_cat, "weapon"))["pairs"]
	_check(pd.class_damage_multiplier(pairs[0]) > 1.0, "weapon buffs its paired class")
	var other: int = 0
	while other in pairs:
		other += 1
	_check(is_equal_approx(pd.class_damage_multiplier(other), 1.0), "weapon does not buff other classes")

	# Level cap by rarity and Blueprint breakthroughs.
	pd._reset()
	var w: String = HeroCat.equipped_uid(pd.hero_cat, "weapon")    # common: cap 10
	_check(HeroCat.level_cap(pd.hero_cat, w) == 10, "a common item caps at level 10")
	pd.forge_stones = 100000
	pd.gold = 100000
	for i in 9:
		pd.hero_cat_upgrade(w)
	_check(HeroCat.item(pd.hero_cat, w)["level"] == 10 and not pd.hero_cat_upgrade(w), "common stops at 10")
	var rare_uid: String = HeroCat.add_item(pd.hero_cat, "cung_san")       # rare: cap 20
	pd.hero_cat["bag"][rare_uid]["level"] = 10
	pd.blueprints["weapon"] = 0
	_check(HeroCat.breakthrough_cost(pd.hero_cat, rare_uid) == 5, "level 10 → 11 needs 5 weapon blueprints")
	_check(not pd.hero_cat_upgrade(rare_uid), "no blueprints, no breakthrough")
	pd.blueprints["helmet"] = 99
	_check(not pd.hero_cat_upgrade(rare_uid), "other-slot blueprints do not count")
	pd.blueprints["weapon"] = 5
	_check(pd.hero_cat_upgrade(rare_uid) and pd.blueprints["weapon"] == 0, "breakthrough spends 5 weapon blueprints")
	_check(HeroCat.breakthrough_cost(pd.hero_cat, rare_uid) == 0, "ordinary levels need no blueprints")
	pd.hero_cat["bag"][rare_uid]["level"] = 20
	_check(HeroCat.upgrade_cost(pd.hero_cat, rare_uid) == -1, "a rare item caps at 20")
	# Fusing raises the cap; a fused item keeps its level within the new cap.
	for i in 3:
		HeroCat.add_item(pd.hero_cat, "giay_co")
	var copies: Array = HeroCat.copies(pd.hero_cat, "giay_co")
	for uid in copies:
		pd.hero_cat["bag"][uid]["level"] = 10
	var fused2: String = pd.hero_cat_fuse("giay_co")
	_check(HeroCat.level_cap(pd.hero_cat, fused2) == 20 and HeroCat.item(pd.hero_cat, fused2)["level"] == 10, "fused rare keeps level 10 with cap 20")
	# Sources: salvage, boss levels, chests, milestones.
	var spare_epic: String = HeroCat.add_item(pd.hero_cat, "giap_bac")
	var before_bp: int = pd.blueprints["armor"]
	pd.hero_cat_salvage(spare_epic)
	_check(pd.blueprints["armor"] == before_bp + HeroCat.SALVAGE_BLUEPRINTS[2], "salvaging an epic armour gives armour blueprints")
	pd.current_level = 4
	var boss: Dictionary = pd.grant_battle_rewards(true, 3, 5)
	var boss_total := 0
	for slot in boss.get("blueprints", {}):
		boss_total += boss["blueprints"][slot]
	_check(boss_total == HeroCat.BOSS_BLUEPRINTS * 2, "first clear of boss level 5 gives %d blueprints" % boss_total)
	pd.current_level = 2
	_check(not pd.grant_battle_rewards(true, 3, 5).has("blueprints"), "normal levels give no blueprints")
	pd.gems = 1000
	var gchest: Dictionary = pd.open_chest("gold")
	var chest_total := 0
	for slot in gchest.get("blueprints", {}):
		chest_total += gchest["blueprints"][slot]
	_check(chest_total == HeroCat.CHEST_BLUEPRINTS["gold"], "gold chest gives %d blueprints" % chest_total)
	var saved: Dictionary = pd.to_dict()
	pd._reset()
	pd.from_dict(saved)
	_check(pd.blueprints["armor"] == saved["blueprints"]["armor"], "blueprints survive a save")

	# Meta rewards: stones and items.
	var got: Dictionary = pd.grant({"stones": 25, "item": 2})
	_check(got["stones"] == 25 and got["items"].size() == 1, "grant() gives stones and an item")

	print("EQUIP_SUMMARY fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
