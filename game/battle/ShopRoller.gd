extends RefCounted

# Draws the between-wave shop offers. Shared by Battle and the admin "Shop trận" tab's
# simulation so both roll with exactly the same rules.

const Economy = preload("res://game/core/Economy.gd")


## `pool` is the team's TroopData list, `wave` the 1-based wave the shop is for.
## Returns [{"id", "tier", "price", "sold"}].
static func roll(pool: Array, wave: int) -> Array:
	var offers := []
	if pool.is_empty():
		return offers
	var odds: Array = Economy.shop_odds(wave)
	var by_rarity := {}
	for troop in pool:
		by_rarity.get_or_add(troop.rarity, []).append(troop)
	var tier2_from := int(Economy.BATTLE_SHOP.get("tier2_from_wave", 99))
	var tier2_chance := float(Economy.BATTLE_SHOP.get("tier2_chance", 0.0))
	for i in int(Economy.BATTLE_SHOP.get("slots", 5)):
		var troop: Resource = _weighted_troop(by_rarity[_pick_rarity(odds, by_rarity)])
		var tier := 2 if wave >= tier2_from and randf() < tier2_chance else 1
		offers.append({"id": troop.id, "tier": tier, "price": Economy.shop_price(troop.rarity, tier), "sold": false})
	return offers


# Rarity by the wave's odds, limited to rarities the team actually has.
static func _pick_rarity(odds: Array, by_rarity: Dictionary) -> int:
	var total := 0.0
	for r in odds.size():
		if by_rarity.has(r):
			total += odds[r]
	if total <= 0.0:
		return by_rarity.keys().pick_random()
	var pick := randf() * total
	for r in odds.size():
		if by_rarity.has(r):
			pick -= odds[r]
			if pick <= 0.0:
				return r
	return by_rarity.keys().back()


static func _weighted_troop(troops: Array) -> Resource:
	var total := 0.0
	for troop in troops:
		total += maxf(troop.summon_weight, 0.01)
	var pick := randf() * total
	for troop in troops:
		pick -= maxf(troop.summon_weight, 0.01)
		if pick <= 0.0:
			return troop
	return troops.back()
