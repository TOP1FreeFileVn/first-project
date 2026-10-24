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

func _plans(by_slot: Dictionary) -> int:
	var total := 0
	for slot in by_slot:
		total += int(by_slot[slot])
	return total

func _initialize() -> void:
	await process_frame
	var pd = root.get_node("PlayerData")
	pd.persist = false
	pd._reset()

	# Every slot has every rarity, so summon and fuse always have a target.
	for slot in HeroCat.SLOTS:
		for r in 4:
			_check(not HeroCat.ids_of(slot, r).is_empty() or r == 3 and slot == "weapon" and false, "item exists %s rarity %d" % [slot, r])

	# Old save with Tướng heroes -> one-time refund, paid as Blueprints; heroes dropped.
	var old: Dictionary = pd.to_dict()
	old["blueprints"] = {}
	old["summon"] = {"pity": 12, "free_day": -1, "total": 30}
	old["heroes"] = {"list": {"iron": {"owned": true, "level": 5, "stars": 2, "shards": 14}}, "leader": "iron"}
	pd.from_dict(old)
	var refund := _plans(pd.blueprints)
	_check(refund > 0, "old Tướng save refunds blueprints (%d)" % refund)
	_check(pd.summon_pity == 0, "old hero summon pity does not carry into equipment pity")
	_check(not pd.to_dict().has("heroes"), "save no longer writes heroes")
	pd.from_dict(pd.to_dict())
	_check(_plans(pd.blueprints) == refund, "refund happens once (reload keeps %d)" % _plans(pd.blueprints))
	# A Forge Stone era save: its stones become Blueprints spread over the slots.
	var stone_save: Dictionary = pd.to_dict()
	stone_save["blueprints"] = {}
	stone_save["forge_stones"] = 100
	pd.from_dict(stone_save)
	_check(_plans(pd.blueprints) == 100 / HeroCat.STONES_PER_BLUEPRINT and pd.blueprints["boots"] > 0, "old Forge Stones convert into %d blueprints" % _plans(pd.blueprints))
	_check(not pd.to_dict().has("forge_stones"), "save no longer writes Forge Stones")

	# Chests: equipment + Blueprints, no troop cards.
	pd.gems = 1000
	pd.gold = 1000
	var bag_before: int = pd.hero_cat["bag"].size()
	var plans_before := _plans(pd.blueprints)
	var cards_before := 0
	for id in pd.TROOP_ORDER:
		cards_before += pd.troops[id]["cards"]
	var chest: Dictionary = pd.open_chest("silver")
	_check(chest.get("items", []).size() == 3, "silver chest gives 3 items")
	_check(pd.hero_cat["bag"].size() == bag_before + 3, "the items are in the bag")
	_check(chest.get("items", []).any(func(it): return it["rarity"] >= 1), "silver chest has at least one rare")
	var silver_plans := _plans(chest.get("blueprints", {}))
	var silver_range: Array = load("res://game/core/Economy.gd").CHESTS["silver"]["blueprints"]
	_check(_plans(pd.blueprints) == plans_before + silver_plans and silver_plans >= silver_range[0] and silver_plans <= silver_range[1], "silver chest gives %d blueprints" % silver_plans)
	_check(not chest.has("stones"), "chests give no Forge Stones")
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

	# Upgrade costs Blueprints of the item's slot only.
	var weapon: String = HeroCat.equipped_uid(pd.hero_cat, "weapon")
	pd.blueprints["weapon"] = 1000
	pd.gold = 1000
	var lv: int = HeroCat.item(pd.hero_cat, weapon)["level"]
	var cost: int = HeroCat.upgrade_cost(pd.hero_cat, weapon)
	_check(cost > 0, "a level costs %d weapon blueprints" % cost)
	_check(pd.hero_cat_upgrade(weapon), "upgrade with blueprints")
	_check(HeroCat.item(pd.hero_cat, weapon)["level"] == lv + 1, "level went up")
	_check(pd.blueprints["weapon"] == 1000 - cost and pd.gold == 1000, "spent %d blueprints and no gold" % cost)
	pd.blueprints["weapon"] = 0
	pd.blueprints["helmet"] = 999
	_check(not pd.hero_cat_upgrade(weapon), "no weapon blueprints, no upgrade (other slots do not count)")

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
	var spare_slot: String = HeroCat.def(pd.hero_cat, spare[0])["slot"]
	var s0: int = pd.blueprints[spare_slot]
	var value: int = HeroCat.salvage_value(pd.hero_cat, spare[0])
	_check(pd.hero_cat_salvage(spare[0]) == value and pd.blueprints[spare_slot] == s0 + value, "salvage gives %d %s blueprints" % [value, spare_slot])
	_check(pd.hero_cat_salvage(HeroCat.equipped_uid(pd.hero_cat, "weapon")) == 0, "worn item cannot be salvaged")

	# Battle rewards give Blueprints; gear stats reach the battle.
	pd._reset()
	pd.current_level = 2
	var start_plans := _plans(pd.blueprints)
	var won: Dictionary = pd.grant_battle_rewards(true, 3, 5)
	var won_plans := _plans(won.get("blueprints", {}))
	_check(won_plans > 0 and _plans(pd.blueprints) == start_plans + won_plans, "win gives %d blueprints" % won_plans)
	var lost: Dictionary = pd.grant_battle_rewards(false, 0, 2)
	_check(_plans(lost.get("blueprints", {})) == HeroCat.LOSS_BLUEPRINTS, "loss with waves gives %d blueprints" % HeroCat.LOSS_BLUEPRINTS)
	_check(pd.core_hp_multiplier() > pd.castle_stats()["hp"], "hero-cat HP raises castle HP")
	_check(pd.wall_block() > 0.0, "hero-cat armour blocks wall damage (%.3f)" % pd.wall_block())
	var pairs: Array = HeroCat.def(pd.hero_cat, HeroCat.equipped_uid(pd.hero_cat, "weapon"))["pairs"]
	_check(pd.class_damage_multiplier(pairs[0]) > 1.0, "weapon buffs its paired class")
	var other: int = 0
	while other in pairs:
		other += 1
	_check(is_equal_approx(pd.class_damage_multiplier(other), 1.0), "weapon does not buff other classes")

	# Level cap by rarity; only fusing raises it.
	pd._reset()
	var w: String = HeroCat.equipped_uid(pd.hero_cat, "weapon")    # common: cap 10
	_check(HeroCat.level_cap(pd.hero_cat, w) == 10, "a common item caps at level 10")
	pd.blueprints["weapon"] = 100000
	for i in 9:
		pd.hero_cat_upgrade(w)
	_check(HeroCat.item(pd.hero_cat, w)["level"] == 10 and not pd.hero_cat_upgrade(w), "common stops at 10 even with blueprints left")
	_check(pd.blueprints["weapon"] == 100000 - HeroCat.blueprints_spent(0, 10), "levels 1→10 cost %d blueprints" % HeroCat.blueprints_spent(0, 10))
	var rare_uid: String = HeroCat.add_item(pd.hero_cat, "cung_san")       # rare: cap 20
	pd.hero_cat["bag"][rare_uid]["level"] = 10
	_check(pd.hero_cat_upgrade(rare_uid), "a rare item levels past 10 with plain blueprints")
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
	# Sources: salvage, boss levels, chests.
	var spare_epic: String = HeroCat.add_item(pd.hero_cat, "giap_bac")
	var before_bp: int = pd.blueprints["armor"]
	pd.hero_cat_salvage(spare_epic)
	_check(pd.blueprints["armor"] == before_bp + HeroCat.SALVAGE_BLUEPRINTS[2], "salvaging a level-1 epic armour gives %d armour blueprints" % HeroCat.SALVAGE_BLUEPRINTS[2])
	pd.current_level = 4
	var boss: Dictionary = pd.grant_battle_rewards(true, 3, 5)
	var boss_total := _plans(boss.get("blueprints", {}))
	var boss_base := floori(HeroCat.WIN_BLUEPRINTS + HeroCat.WIN_BLUEPRINTS_PER_LEVEL * 4)
	_check(boss_total == (boss_base + HeroCat.BOSS_BLUEPRINTS) * 2, "first clear of boss level 5 gives %d blueprints" % boss_total)
	pd.gems = 1000
	var gchest: Dictionary = pd.open_chest("gold")
	var chest_total := _plans(gchest.get("blueprints", {}))
	var gold_range: Array = load("res://game/core/Economy.gd").CHESTS["gold"]["blueprints"]
	_check(chest_total >= gold_range[0] and chest_total <= gold_range[1], "gold chest gives %d blueprints" % chest_total)
	var saved: Dictionary = pd.to_dict()
	pd._reset()
	pd.from_dict(saved)
	_check(pd.blueprints["armor"] == saved["blueprints"]["armor"], "blueprints survive a save")

	# Meta rewards: blueprints and items.
	var got: Dictionary = pd.grant({"blueprints": 12, "item": 2})
	_check(_plans(got.get("blueprints", {})) == 12 and got["items"].size() == 1, "grant() gives blueprints and an item")

	print("EQUIP_SUMMARY fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
