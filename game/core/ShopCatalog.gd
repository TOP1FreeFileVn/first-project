extends RefCounted

const Economy = preload("res://game/core/Economy.gd")

## Gem top-ups are review only. Proposed prices are not registered store products;
## selecting a pack must not charge the player or grant currency.
const PRICING_STATUS := "proposal"
const PAYMENT_INTEGRATED := false
const GEM_PACKS := [
	{"id": "gems_80", "name": "Gói 120 kim cương", "gems": 120, "price_vnd": 19000, "illustration": "res://game/ui/art/shop_gem_packs/01.png"},
	{"id": "gems_400", "name": "Gói 600 kim cương", "gems": 600, "price_vnd": 89000, "illustration": "res://game/ui/art/shop_gem_packs/02.png"},
	{"id": "gems_1000", "name": "Gói 1.500 kim cương", "gems": 1500, "price_vnd": 199000, "illustration": "res://game/ui/art/shop_gem_packs/03.png"},
	{"id": "gems_2200", "name": "Gói 3.300 kim cương", "gems": 3300, "price_vnd": 399000, "illustration": "res://game/ui/art/shop_gem_packs/04.png"},
	{"id": "gems_4600", "name": "Gói 6.900 kim cương", "gems": 6900, "price_vnd": 799000, "illustration": "res://game/ui/art/shop_gem_packs/05.png"},
	{"id": "gems_10000", "name": "Gói 15.000 kim cương", "gems": 15000, "price_vnd": 1599000, "illustration": "res://game/ui/art/shop_gem_packs/06.png"},
]


## Callers receive their own copy so UI state cannot modify the catalog.
static func gem_packs() -> Array:
	return GEM_PACKS.duplicate(true)


static func gem_pack(pack_id: String) -> Dictionary:
	for pack in GEM_PACKS:
		if str(pack["id"]) == pack_id:
			return pack.duplicate(true)
	return {}


## Gold exchanges are playable offers, using the live balance exchange rate.
static func gold_offers() -> Array:
	var offers: Array = [{"id": "daily_gold", "gold": Economy.DAILY_SHOP_GOLD, "gems": 0, "multiplier": 0, "art_level": 1}]
	for index in Economy.EXCHANGE_MULTIPLIERS.size():
		var multiplier: int = Economy.EXCHANGE_MULTIPLIERS[index]
		offers.append({"id": "gold_%d" % multiplier, "gold": Economy.EXCHANGE_GOLD * multiplier,
			"gems": Economy.EXCHANGE_GEMS * multiplier, "multiplier": multiplier, "art_level": index + 2})
	return offers


static func gold_offer(offer_id: String) -> Dictionary:
	for offer in gold_offers():
		if str(offer["id"]) == offer_id:
			return offer
	return {}


static func format_vnd(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	while digits.length() > 3:
		grouped = "." + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + grouped + "đ"
