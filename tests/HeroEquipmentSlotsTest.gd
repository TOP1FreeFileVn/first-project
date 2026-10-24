extends Node

# Focused regression for retiring hand/necklace equipment without losing save records.
const HeroCat = preload("res://game/core/HeroCat.gd")
const REMOVED := ["gang_da", "gang_bac", "bua_go", "bua_ngoc"]
var _checks := 0
var _failed := 0


func _ready() -> void:
	PlayerData.persist = false
	_check_new_profile()
	_check_legacy_profile()
	print("HeroEquipmentSlotsTest: %d checks, %d failed" % [_checks, _failed])
	get_tree().quit(1 if _failed else 0)


func _check_new_profile() -> void:
	_check(HeroCat.SLOTS == ["weapon", "helmet", "armor", "boots"], "four active equipment families")
	_check(HeroCat.ITEMS.size() == 17, "catalog holds 17 items (every slot has all four rarities)")
	var state := HeroCat.new_state()
	_check(state.bag.size() == 7 and state.equipped.size() == 3, "new profile keeps three worn and four spare items")
	_check(state.retired_items.is_empty(), "new profile has no retired equipment")
	for uid in state.bag:
		_check(HeroCat.ITEMS.has(state.bag[uid].id), "new profile only grants supported items " + uid)
	for id in REMOVED:
		var before := state.duplicate(true)
		_check(HeroCat.add_item(state, id) == "", "cannot grant retired item " + id)
		_check(state == before, "rejected grant keeps state and UID sequence " + id)
	_check(HeroCat.add_item(state, "unknown_item") == "", "cannot grant unknown equipment")
	_check(HeroCat.restore_state(state) == state, "current new profile restore is idempotent")


func _check_legacy_profile() -> void:
	var legacy := {
		"equipped": {"weapon": "1", "helmet": "2", "armor": "3", "boots": "4", "gloves": "5", "amulet": "6"},
		"bag": {
			"1": {"id": "kiem_go", "level": 8},
			"2": {"id": "mu_sat", "level": 5},
			"3": {"id": "giap_xich", "level": 4},
			"4": {"id": "giay_gio", "level": 3},
			"5": {"id": "gang_bac", "level": 17},
			"6": {"id": "bua_ngoc", "level": 19},
			"7": {"id": "gang_da", "level": 6},
			"8": {"id": "bua_go", "level": 11},
			"9": {"id": "katana_nguyet", "level": 9},
		},
		"retired_items": {"40": {"id": "bua_go", "level": 12}},
		"next": 42,
	}
	var original := legacy.duplicate(true)
	PlayerData.from_dict({"gold": 12345, "hero_cat": legacy})
	var state: Dictionary = PlayerData.hero_cat
	_check(legacy == original, "load does not mutate source snapshot")
	_check(state.bag.size() == 5 and state.equipped.size() == 4, "legacy active inventory contains only four supported families")
	_check(state.retired_items.size() == 5, "worn and spare retired records join existing archive")
	_check(state.next == 42, "valid existing next UID is preserved")
	_check(not state.equipped.has("gloves") and not state.equipped.has("amulet"), "removed equipped slots do not survive migration")
	for uid in ["1", "2", "3", "4", "9"]:
		_check(state.bag[uid] == original.bag[uid], "supported UID and level preserved " + uid)
	for uid in ["5", "6", "7", "8"]:
		_check(state.retired_items[uid] == original.bag[uid] and not state.bag.has(uid), "retired UID and level archived " + uid)
	_check(state.retired_items["40"] == original.retired_items["40"], "existing archive preserved")
	_check(HeroCat.spare(state) == ["9"], "archive is excluded from visible spare inventory")
	_check(PlayerData.hero_cat_stats() == {"hp": 2227, "atk": 174, "def": 67}, "only supported worn equipment contributes stats")
	_check(HeroCat.weapon_skill(state).get("weapon") == "kiem_go", "weapon skill survives migration")
	_check(PlayerData.gold == 12345, "migration leaves currency unchanged")
	for uid in ["5", "6", "7", "8", "40", "missing"]:
		var before := state.duplicate(true)
		_check(HeroCat.def(state, uid).is_empty(), "retired or absent UID has no active definition " + uid)
		_check(HeroCat.upgrade_cost(state, uid) == -1, "retired or absent UID cannot be upgraded " + uid)
		PlayerData.hero_cat_equip(uid)
		_check(not PlayerData.hero_cat_upgrade(uid), "upgrade action rejects retired or absent UID " + uid)
		_check(state == before and PlayerData.gold == 12345, "rejected actions keep inventory and currency " + uid)
	_check(HeroCat.equipped_uid(legacy, "gloves") == "" and HeroCat.equipped_uid(legacy, "amulet") == "", "removed slot lookups reject even an unmigrated state")
	var unsafe := legacy.duplicate(true)
	unsafe.bag["10"] = {"id": "future_unknown_item", "level": 3}
	_check(HeroCat.spare(unsafe) == ["9"], "spare ignores unsupported definitions before migration")
	_check(HeroCat.upgrade_cost(unsafe, "10") == -1, "upgrade cost safely rejects unsupported definitions before migration")
	var serialized: String = JSON.stringify(PlayerData.to_dict())
	PlayerData.from_dict(JSON.parse_string(serialized))
	_check(PlayerData.hero_cat == state, "profile JSON roundtrip preserves all active and archived records")
	_check(HeroCat.restore_state(PlayerData.hero_cat) == state, "repeated archive migration is idempotent")
	var allocated := HeroCat.add_item(PlayerData.hero_cat, "mu_da")
	_check(allocated == "42" and PlayerData.hero_cat.next == 43, "next grant retains existing reserved sequence")
	_check(PlayerData.hero_cat.retired_items == state.retired_items, "new grant preserves retired archive")
	var colliding := legacy.duplicate(true)
	colliding.next = 5
	var repaired := HeroCat.restore_state(colliding)
	_check(repaired.next == 41, "stale next UID advances beyond active and retired records")
	_check(HeroCat.add_item(repaired, "giay_co") == "41", "new grant never collides with archived UIDs")
	_check(repaired.retired_items["40"] == original.retired_items["40"], "collision repair keeps highest archived UID intact")
	_check(not PlayerData.persist, "test never writes player save")


func _check(value: bool, description: String) -> void:
	_checks += 1
	if not value:
		_failed += 1
		push_error(description)
