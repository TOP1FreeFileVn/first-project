extends Node

# Runs entirely on detached PlayerData instances with persistence disabled:
# Godot --headless --path . res://tests/GoldChestBatchTest.tscn
# In-memory chest fixtures isolate otherwise masked pity/bonus cases; no balance file changes.
const PlayerState = preload("res://game/core/PlayerData.gd")
const Economy = preload("res://game/core/Economy.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")

class CommonRollPlayer:
	extends "res://game/core/PlayerData.gd"

	func _roll_gear_rarity() -> int:
		return 0

var _checks: int = 0
var _failures: int = 0
var _commits: int = 0


func _ready() -> void:
	print("GOLD_BATCH_START")
	await get_tree().process_frame
	_test_current_batch()
	_test_single_compatibility()
	_test_rejections()
	_test_pity_and_bonus_fixture()
	print("GOLD_BATCH_SUMMARY checks=%d failed=%d" % [_checks, _failures])
	get_tree().quit(1 if _failures else 0)


func _player(common_rolls: bool = false) -> PlayerState:
	var pd: PlayerState = CommonRollPlayer.new() if common_rolls else PlayerState.new()
	pd.persist = false
	pd._reset()
	pd.quest_day = PlayerState.today()
	pd.quest_progress = {"login": 1, "chest": 3}
	pd.changed.connect(func(): _commits += 1)
	return pd


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print(("GOLD_BATCH_OK " if ok else "GOLD_BATCH_FAIL ") + message)


func _sum(values: Dictionary) -> int:
	var total: int = 0
	for key in values:
		total += int(values[key])
	return total


func _merge(into: Dictionary, loot: Dictionary) -> void:
	into["items"].append_array(loot["items"])
	into["gold"] += loot["gold"]
	for slot in loot.get("blueprints", {}):
		into["blueprints"][slot] = int(into["blueprints"].get(slot, 0)) + int(loot["blueprints"][slot])


func _test_current_batch() -> void:
	var pd = _player(true)
	var chest: Dictionary = Economy.CHESTS["gold"]
	var item_count: int = int(chest.get("items", 1))
	pd.gold = int(chest["gold"]) * 10
	pd.gems = int(chest["gems"]) * 10
	pd.gold_chest_pity = maxi(0, Economy.GOLD_CHEST_PITY - 2)
	for slot in HeroCat.SLOTS:
		pd.blueprints[slot] = 7
	# Retired equipment also reserves its UID; batch rewards must not reuse one.
	pd.hero_cat["retired_items"]["9000"] = {"id": "bua_go", "level": 5}
	var before: Dictionary = pd.to_dict()
	_check(pd.can_open_chest("gold", 10), "exact full price permits ten gold chests")
	_commits = 0
	seed(791432)
	var batch: Dictionary = pd.open_chest("gold", 10)
	var after_batch: Dictionary = pd.to_dict()
	_check(_commits == 1, "batch emits one changed/commit after all grants")
	_check(batch.get("chests", 0) == 10, "batch exposes ten-chest metadata")
	_check(batch["items"].size() == item_count * 10, "ten chests grant ten times the current item count")
	_check(pd.gems == 0, "batch spends the exact current gem price times ten")
	_check(pd.gold == int(batch["gold"]), "gold price and bonus are applied once per chest")
	_check(pd.quest_progress["chest"] == 13, "daily chest progress increases by ten, not one")
	_check(pd.free_chest_at == int(before["shop"]["free_chest_at"]), "gold batch does not consume the wood cooldown")
	_check(pd.troops == before["troops"] and not batch.has("cards"), "equipment chests do not grant or mutate troop cards")
	_check(pd.hero_cat["bag"].size() == before["hero_cat"]["bag"].size() + item_count * 10, "every returned item was added to the bag")
	var seen: Dictionary = {}
	var unique: bool = true
	var matching: bool = true
	for item in batch["items"]:
		var uid: String = str(item["uid"])
		unique = unique and not seen.has(uid) and not before["hero_cat"]["bag"].has(uid) and not before["hero_cat"]["retired_items"].has(uid)
		seen[uid] = true
		matching = matching and HeroCat.item(pd.hero_cat, uid).get("id", "") == item["id"] and HeroCat.ITEMS[item["id"]]["rarity"] == item["rarity"]
	_check(unique, "batch UIDs are unique and never collide with active or retired equipment")
	_check(matching, "returned item IDs/rarities match their granted inventory records")
	var floor_rarity: int = int(chest.get("min_rare", 0))
	var minimum: int = mini(int(chest.get("min_count", 1)), item_count) if floor_rarity > 0 else 0
	for chest_index in 10:
		var at_floor: int = 0
		for index in range(chest_index * item_count, (chest_index + 1) * item_count):
			if int(batch["items"][index]["rarity"]) >= floor_rarity:
				at_floor += 1
		_check(at_floor >= minimum, "gold chest %d keeps its own current rarity guarantee" % (chest_index + 1))
	var plans_range: Array = chest.get("blueprints", [0, 0])
	var batch_plans: int = _sum(batch.get("blueprints", {}))
	_check(batch_plans >= int(plans_range[0]) * 10 and batch_plans <= int(plans_range[1]) * 10, "blueprints stay within ten independent current ranges")
	var blueprint_deltas_match: bool = true
	for slot in HeroCat.SLOTS:
		blueprint_deltas_match = blueprint_deltas_match and pd.blueprints[slot] == int(before["blueprints"][slot]) + int(batch.get("blueprints", {}).get(slot, 0))
	_check(blueprint_deltas_match, "per-slot returned blueprints match inventory increments")

	# Same seed and starting profile must produce exactly ten ordinary x1 rolls.
	pd.from_dict(before)
	seed(791432)
	_commits = 0
	var singles: Dictionary = {"items": [], "gold": 0, "blueprints": {}}
	for i in 10:
		_merge(singles, pd.open_chest("gold"))
	var comparable: Dictionary = batch.duplicate(true)
	comparable.erase("chests")
	_check(comparable == singles, "seeded batch loot equals ten independent x1 opens exactly")
	_check(pd.to_dict() == after_batch, "batch profile equals ten singles, including pity and quest progress")
	_check(_commits == 10, "ordinary x1 opens still commit individually")
	pd.free()


func _test_single_compatibility() -> void:
	for kind in Economy.CHEST_ORDER:
		var pd = _player()
		var chest: Dictionary = Economy.CHESTS[kind]
		pd.gold = int(chest["gold"])
		pd.gems = int(chest["gems"])
		pd.free_chest_at = PlayerState.now()
		var before: Dictionary = pd.to_dict()
		_commits = 0
		seed(351)
		var implicit: Dictionary = pd.open_chest(kind)
		var after: Dictionary = pd.to_dict()
		_check(not implicit.is_empty() and not implicit.has("chests"), "%s x1 preserves its existing loot schema" % kind)
		_check(implicit["items"].size() == int(chest.get("items", 1)), "%s x1 keeps its current item count" % kind)
		_check(_commits == 1 and pd.quest_progress["chest"] == 4, "%s x1 tracks and commits once" % kind)
		pd.from_dict(before)
		seed(351)
		var explicit: Dictionary = pd.open_chest(kind, 1)
		_check(explicit == implicit and pd.to_dict() == after, "%s explicit count one equals the old call" % kind)
		if kind == "wood":
			_check(pd.free_chest_seconds_left() > 0, "wood x1 retains its cooldown")
			_assert_refused(pd, "wood", 1, "wood cooldown cannot be bypassed")
		pd.free()


func _assert_refused(pd, kind: String, count: int, reason: String) -> void:
	var before: Dictionary = pd.to_dict()
	_commits = 0
	_check(not pd.can_open_chest(kind, count), reason + ": preflight refuses")
	_check(pd.open_chest(kind, count).is_empty(), reason + ": no loot returned")
	_check(pd.to_dict() == before and _commits == 0, reason + ": entire profile unchanged, no commit")


func _test_rejections() -> void:
	var pd = _player()
	var chest: Dictionary = Economy.CHESTS["gold"]
	pd.gold = 100000000
	pd.gems = 100000000
	# Refusal must not even roll an expired quest day forward.
	pd.quest_day = -1
	for count in [0, -1, 2, 9, 11, 2147483647]:
		_assert_refused(pd, "gold", count, "unsupported gold count %d" % count)
	for kind in ["wood", "silver", "victory", "unknown"]:
		_assert_refused(pd, kind, 10, "unsupported batch kind %s" % kind)
	for kind in ["victory", "unknown"]:
		_assert_refused(pd, kind, 1, "non-shop chest kind %s" % kind)
	pd.gold = int(chest["gold"]) * 10
	pd.gems = int(chest["gems"]) * 10 - 1
	_assert_refused(pd, "gold", 10, "one gem short of the full batch")
	_check(pd.can_open_chest("gold"), "can afford x1 while unable to afford x10")
	pd.free()


func _test_pity_and_bonus_fixture() -> void:
	var original_chests: Dictionary = Economy.CHESTS
	Economy.CHESTS = original_chests.duplicate(true)
	var chest: Dictionary = Economy.CHESTS["gold"]
	# Current gold floor already guarantees epics, so remove it only in RAM to expose
	# the pity boundary, and force all ordinary rolls to common.
	chest["min_rare"] = 0
	chest["min_count"] = 0
	chest["gold"] = 5
	chest["bonus_gold"] = [7, 7]
	chest["blueprints"] = [3, 3]
	var item_count: int = int(chest.get("items", 1))
	var pd = _player(true)
	pd.gold = 49
	pd.gems = int(chest["gems"]) * 10
	_assert_refused(pd, "gold", 10, "full gold price required before any bonus can fund later opens")
	pd.gold = 50
	pd.gold_chest_pity = maxi(0, Economy.GOLD_CHEST_PITY - 2)
	var start_pity: int = pd.gold_chest_pity
	_commits = 0
	var batch: Dictionary = pd.open_chest("gold", 10)
	_check(batch["gold"] == 70 and pd.gold == 70, "batch aggregates ten bonus-gold payouts after the full price")
	_check(_sum(batch.get("blueprints", {})) == 30 and _sum(pd.blueprints) == 30, "batch aggregates ten blueprint payouts")
	_check(_commits == 1, "pity-crossing batch commits once")
	var expected_pity: int = start_pity
	for chest_index in 10:
		expected_pity += 1
		var triggered: bool = expected_pity >= Economy.GOLD_CHEST_PITY
		if triggered:
			expected_pity = 0
		var epics: int = 0
		for index in range(chest_index * item_count, (chest_index + 1) * item_count):
			if int(batch["items"][index]["rarity"]) >= 2:
				epics += 1
		_check(epics == (1 if triggered else 0), "batch chest %d applies pity at its individual boundary" % (chest_index + 1))
	_check(pd.gold_chest_pity == expected_pity, "pity continues after the guaranteed chest within the batch")
	pd.free()
	Economy.CHESTS = original_chests
