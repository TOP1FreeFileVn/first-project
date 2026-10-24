extends Node

# Detached players only; no real save writes or purchases.
# Godot --headless --path . res://tests/ShopGoldTest.tscn
const PlayerState = preload("res://game/core/PlayerData.gd")
const Economy = preload("res://game/core/Economy.gd")

var _checks: int = 0
var _failures: int = 0
var _commits: int = 0


func _ready() -> void:
	await get_tree().process_frame
	_test_exchange_tiers()
	_test_exchange_rejections()
	_test_admin_rate()
	_test_daily_gold()
	_test_daily_save()
	print("SHOP_GOLD_SUMMARY checks=%d failed=%d" % [_checks, _failures])
	get_tree().quit(1 if _failures else 0)


func _player() -> PlayerState:
	var pd := PlayerState.new()
	pd.persist = false
	pd._reset()
	pd.changed.connect(func(): _commits += 1)
	return pd


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("SHOP_GOLD_FAIL " + message)


func _same_except_currency(before: Dictionary, after: Dictionary) -> bool:
	var expected := before.duplicate(true)
	expected["gold"] = after["gold"]
	expected["gems"] = after["gems"]
	return expected == after


func _test_exchange_tiers() -> void:
	for multiplier in Economy.EXCHANGE_MULTIPLIERS:
		var pd := _player()
		var cost: int = Economy.EXCHANGE_GEMS * multiplier
		var reward: int = Economy.EXCHANGE_GOLD * multiplier
		pd.gold = 777
		pd.gems = cost
		var before: Dictionary = pd.to_dict()
		_commits = 0
		_check(pd.exchange_gems(multiplier), "tier %d accepts exact funds" % multiplier)
		_check(pd.gems == 0 and pd.gold == 777 + reward, "tier %d exact deltas" % multiplier)
		_check(_commits == 1, "tier %d has one atomic commit" % multiplier)
		_check(_same_except_currency(before, pd.to_dict()), "tier %d preserves other account state" % multiplier)
		pd.free()
	var pd := _player()
	pd.gold = 0
	pd.gems = Economy.EXCHANGE_GEMS
	_check(pd.exchange_gems(), "legacy no-argument exchange remains valid")
	_check(pd.gold == Economy.EXCHANGE_GOLD and pd.gems == 0, "legacy exchange preserves configured rate")
	pd.free()


func _refused_exchange(pd: PlayerState, multiplier: int, message: String) -> void:
	var before: Dictionary = pd.to_dict()
	_commits = 0
	_check(not pd.exchange_gems(multiplier), message + " is refused")
	_check(pd.to_dict() == before and _commits == 0, message + " leaves full state unchanged")


func _test_exchange_rejections() -> void:
	var pd := _player()
	pd.gems = 1000000
	for multiplier in [-50, -1, 0, 2, 4, 6, 100, 2147483647]:
		_refused_exchange(pd, multiplier, "unsupported tier %d" % multiplier)
	for multiplier in Economy.EXCHANGE_MULTIPLIERS:
		pd.gems = Economy.EXCHANGE_GEMS * multiplier - 1
		_refused_exchange(pd, multiplier, "one gem short at tier %d" % multiplier)
	pd.free()


func _test_admin_rate() -> void:
	var old_price: int = Economy.EXCHANGE_GEMS
	var old_reward: int = Economy.EXCHANGE_GOLD
	var pd := _player()
	Economy.EXCHANGE_GEMS = 13
	Economy.EXCHANGE_GOLD = 333
	pd.gold = 5
	pd.gems = 65
	_check(pd.exchange_gems(5), "exchange uses current admin rate")
	_check(pd.gems == 0 and pd.gold == 1670, "admin rate scales both sides without extra bonus")
	for invalid_price in [0, -20]:
		Economy.EXCHANGE_GEMS = invalid_price
		pd.gems = 1000000
		_refused_exchange(pd, 1, "nonpositive configured gem price")
	Economy.EXCHANGE_GEMS = old_price
	for invalid_reward in [0, -500]:
		Economy.EXCHANGE_GOLD = invalid_reward
		_refused_exchange(pd, 1, "nonpositive configured gold reward")
	Economy.EXCHANGE_GOLD = old_reward
	pd.free()


func _test_daily_gold() -> void:
	var pd := _player()
	pd.gold = 777
	pd.gems = 3
	var before: Dictionary = pd.to_dict()
	_check(pd.shop_gold_available(), "fresh player can claim daily shop gold")
	_commits = 0
	_check(pd.claim_shop_gold() == Economy.DAILY_SHOP_GOLD, "daily claim reports configured reward")
	_check(pd.gold == 777 + Economy.DAILY_SHOP_GOLD and pd.gems == 3, "daily claim adds gold without spending gems")
	_check(pd.shop_gold_day == PlayerState.today(), "daily claim records local calendar day")
	_check(_commits == 1, "daily gold and day marker have one commit")
	var expected: Dictionary = before.duplicate(true)
	expected["gold"] = pd.gold
	expected["shop"]["daily_gold_day"] = PlayerState.today()
	_check(pd.to_dict() == expected, "daily claim preserves the remainder of the account")
	_check(not pd.shop_gold_available(), "same calendar day is no longer available")
	var claimed: Dictionary = pd.to_dict()
	_commits = 0
	_check(pd.claim_shop_gold() == 0, "repeat tap does not grant gold")
	_check(pd.to_dict() == claimed and _commits == 0, "repeat claim changes no state")
	pd.shop_gold_day = PlayerState.today() - 1
	_check(pd.shop_gold_available(), "a later local calendar day is eligible")
	_check(pd.claim_shop_gold() == Economy.DAILY_SHOP_GOLD, "next day's claim succeeds")
	pd.shop_gold_day = PlayerState.today() + 1
	claimed = pd.to_dict()
	_commits = 0
	_check(not pd.shop_gold_available() and pd.claim_shop_gold() == 0, "clock rollback cannot reopen daily reward")
	_check(pd.to_dict() == claimed and _commits == 0, "blocked clock rollback changes no state")
	pd.free()


func _test_daily_save() -> void:
	var pd := _player()
	pd.claim_shop_gold()
	var data: Dictionary = pd.to_dict()
	_check(data["shop"]["daily_gold_day"] == PlayerState.today(), "save includes shop daily claim marker")
	var restored := _player()
	restored.from_dict(data)
	_check(restored.to_dict() == data, "full account serialization round-trips daily claim")
	_check(not restored.shop_gold_available() and restored.claim_shop_gold() == 0, "reloading cannot claim twice")
	data["shop"].erase("daily_gold_day")
	restored.from_dict(data)
	_check(restored.shop_gold_day == -1 and restored.shop_gold_available(), "older saves get an unclaimed daily reward")
	_check(restored.free_chest_at == int(data["shop"]["free_chest_at"]), "older shop save keeps its wood chest timer")
	data.erase("shop")
	restored.from_dict(data)
	_check(restored.shop_gold_day == -1 and restored.shop_gold_available(), "saves without shop data remain compatible")
	restored.shop_gold_day = PlayerState.today()
	restored._reset()
	_check(restored.shop_gold_day == -1 and restored.shop_gold_available(), "account reset restores unclaimed daily reward")
	restored.free()
	pd.free()
