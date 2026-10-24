extends RefCounted

## Review catalog only. These proposed prices are not registered store products;
## selecting a pack must not charge the player or grant currency.
const PRICING_STATUS := "proposal"
const PAYMENT_INTEGRATED := false
const GEM_PACKS := [
	{"id": "gems_80", "name": "Gói 120 kim cương", "gems": 120, "price_vnd": 19000, "art_level": 1},
	{"id": "gems_400", "name": "Gói 600 kim cương", "gems": 600, "price_vnd": 89000, "art_level": 2},
	{"id": "gems_1000", "name": "Gói 1.500 kim cương", "gems": 1500, "price_vnd": 199000, "art_level": 3},
	{"id": "gems_2200", "name": "Gói 3.300 kim cương", "gems": 3300, "price_vnd": 399000, "art_level": 4},
	{"id": "gems_4600", "name": "Gói 6.900 kim cương", "gems": 6900, "price_vnd": 799000, "art_level": 5},
	{"id": "gems_10000", "name": "Gói 15.000 kim cương", "gems": 15000, "price_vnd": 1599000, "art_level": 6},
]


## Callers receive their own copy so UI state cannot modify the catalog.
static func gem_packs() -> Array:
	return GEM_PACKS.duplicate(true)


static func gem_pack(pack_id: String) -> Dictionary:
	for pack in GEM_PACKS:
		if str(pack["id"]) == pack_id:
			return pack.duplicate(true)
	return {}


static func format_vnd(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	while digits.length() > 3:
		grouped = "." + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + grouped + "đ"
