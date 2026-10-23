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

	# Summon: gems -> items + stones; x10 has an epic.
	pd.gems = 1000
	var bag_before: int = pd.hero_cat["bag"].size()
	var stones_before: int = pd.forge_stones
	var ten: Array = pd.summon(10)
	_check(ten.size() == 10, "x10 summon gives 10 results")
	_check(ten.any(func(r): return r["rarity"] >= 2), "x10 holds an epic or better")
	_check(pd.hero_cat["bag"].size() == bag_before + 10, "10 items added to the bag")
	_check(pd.forge_stones == stones_before + 10 * HeroCat.SUMMON_STONES, "each pull adds stones")
	_check(pd.gems == 1000 - HeroCat.SUMMON_COST[10], "x10 costs %d gems" % HeroCat.SUMMON_COST[10])
	var free: Array = pd.summon(1)
	_check(free.size() == 1 and pd.gems == 1000 - HeroCat.SUMMON_COST[10], "first x1 of the day is free")

	# Pity: the 60th pull is legendary.
	pd.summon_pity = HeroCat.SUMMON_PITY - 1
	pd.gems = 1000
	var pity: Array = pd.summon(1)
	_check(pity[0]["rarity"] == 3, "pity pull is legendary")

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

	# Meta rewards: stones and items.
	var got: Dictionary = pd.grant({"stones": 25, "item": 2})
	_check(got["stones"] == 25 and got["items"].size() == 1, "grant() gives stones and an item")

	print("EQUIP_SUMMARY fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
