extends RefCounted

# Game-facing view of the balance numbers. The values live in Balance (balance.json plus
# admin overrides); Balance calls refresh() whenever they change, so callers keep using
# the familiar Economy.NAME / Economy.func() without knowing where numbers come from.
# (Static vars keep their UPPER_CASE names from when they were constants.)

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

const RARITY_NAMES := ["Thường", "Hiếm", "Sử thi", "Huyền thoại"]
const RARITY_COLORS := [Color("b9c3cc"), Color("5aa9e6"), Color("c28bff"), Color("ffb938")]
const WORKSHOP_ORDER := ["meat_regen", "start_meat", "master_gear"]
const CHEST_ORDER := ["wood", "silver", "gold"]
# Troop card gifted on first clear of a level (level index -> troop id).
const FIRST_CLEAR_GIFT := {0: "giao", 1: "riu", 2: "no", 4: "thuoc", 6: "cu_kiem", 11: "dao", 14: "sung"}
# Team slots when a castle row predates the "team" column.
const DEFAULT_TEAM_SLOTS := 3

static var RARITY_WEIGHTS: Array = []
static var STAR_CARD_COST: Array = []
static var MAX_STARS := 3
static var LEVELS_PER_STAR := 10
static var SPARE_CARD_GOLD := 20
static var CASTLE: Array = []
static var WORKSHOP: Dictionary = {}
static var CHESTS: Dictionary = {}
## In-battle shop: slots, prices by rarity, reroll, refund, tier-2 offers, odds by wave.
static var BATTLE_SHOP: Dictionary = {}
static var FREE_CHEST_COOLDOWN := 0
static var GOLD_CHEST_PITY := 10
static var EXCHANGE_GEMS := 20
static var EXCHANGE_GOLD := 500
static var FIRST_CLEAR_GOLD_MULT := 2.0
static var FIRST_THREE_STAR_GEMS := 10
static var PATROL_MAX_HOURS := 8.0
static var PATROL_QUICK_HOURS := 2.0
static var PATROL_QUICK_FREE := 2
static var PATROL_QUICK_GEMS := 20
static var START_GEMS := 30
static var ELITE_HP_MULT := 5.0
static var ELITE_DAMAGE_MULT := 1.8
static var KILL_MEAT := 0.35
static var ELITE_KILL_MEAT := 3.0
static var MAX_PLAYER_UNITS := 60
## Fish the basket holds: every living cat soldier takes fish_cost() of it.
static var FISH_CAP := 28


static func refresh(balance) -> void:
	RARITY_WEIGHTS = balance.section("rarity_weights")
	STAR_CARD_COST = balance.section("star_card_cost")
	MAX_STARS = STAR_CARD_COST.size() + 1
	CASTLE = balance.section("castle")
	WORKSHOP = balance.section("workshop")
	CHESTS = balance.section("chests")
	BATTLE_SHOP = balance.section("battle_shop")
	LEVELS_PER_STAR = int(balance.value("levels_per_star"))
	SPARE_CARD_GOLD = int(balance.value("spare_card_gold"))
	FREE_CHEST_COOLDOWN = roundi(balance.value("free_chest_hours") * 3600.0)
	GOLD_CHEST_PITY = int(balance.value("gold_chest_pity"))
	EXCHANGE_GEMS = int(balance.value("exchange_gems"))
	EXCHANGE_GOLD = int(balance.value("exchange_gold"))
	FIRST_CLEAR_GOLD_MULT = float(balance.value("first_clear_gold_mult"))
	FIRST_THREE_STAR_GEMS = int(balance.value("first_three_star_gems"))
	PATROL_MAX_HOURS = float(balance.value("patrol_max_hours"))
	PATROL_QUICK_HOURS = float(balance.value("patrol_quick_hours"))
	PATROL_QUICK_FREE = int(balance.value("patrol_quick_free"))
	PATROL_QUICK_GEMS = int(balance.value("patrol_quick_gems"))
	START_GEMS = int(balance.value("start_gems"))
	ELITE_HP_MULT = float(balance.value("elite_hp_mult"))
	ELITE_DAMAGE_MULT = float(balance.value("elite_damage_mult"))
	KILL_MEAT = float(balance.value("kill_meat"))
	ELITE_KILL_MEAT = float(balance.value("elite_kill_meat"))
	MAX_PLAYER_UNITS = int(balance.value("max_player_units"))
	FISH_CAP = int(balance.value("fish_cap"))


## Class counter (Tầm xa > Bộ binh > Pháp sư > Kỵ binh > Tầm xa): x2 damage.
const COUNTER_MULT := 2.0
const BEATS := {1: 0, 0: 2, 2: 3, 3: 1}


## Fish a living soldier of this rarity eats from the basket: Thường 1 ... Huyền thoại 4.
static func fish_cost(rarity: int) -> int:
	return rarity + 1


static func counter_mult(attacker_klass: int, target_klass: int) -> float:
	return COUNTER_MULT if BEATS.get(attacker_klass, -1) == target_klass else 1.0


## Troops the player can bring into a battle at a castle level (1-based).
static func team_slots(castle_level: int) -> int:
	if CASTLE.is_empty():
		return DEFAULT_TEAM_SLOTS
	var row: Dictionary = CASTLE[clampi(castle_level, 1, CASTLE.size()) - 1]
	return maxi(1, int(row.get("team", DEFAULT_TEAM_SLOTS)))


# --- Formulas (see the Formula tab of the admin panel) ---------------------------------

static func level_cost(level: int) -> int:
	return Balance.formula_int("level_cost", {"level": level})


static func troop_multiplier(level: int, stars: int) -> float:
	return Balance.formula("troop_multiplier", {"level": level, "stars": stars})


static func tier_multiplier(tier: int) -> float:
	return Balance.formula("tier_multiplier", {"tier": tier})


static func spawn_interval(base: float, tier: int, master_bonus: float) -> float:
	return Balance.formula("spawn_interval", {"base": base, "tier": tier, "master_bonus": master_bonus})


## Meat paid out when wave number `wave` (1-based) is cleared.
static func round_income(wave: int, bonus: int) -> int:
	return Balance.formula_int("round_income", {"wave": wave, "bonus": bonus})


## Extra meat for what was saved up before the income arrives.
static func interest(meat: float) -> int:
	return Balance.formula_int("interest", {"meat": floorf(meat)})


static func enemy_multiplier(power: float, wave: int) -> float:
	return Balance.formula("enemy_multiplier", {"power": power, "wave": wave})


static func siege_damage(damage: float) -> float:
	return Balance.formula("siege_damage", {"damage": damage})


## Shop price of a gear of this rarity and tier (a tier-n gear is 2^(n-1) tier-1 gears).
static func shop_price(rarity: int, tier := 1) -> int:
	var prices: Array = BATTLE_SHOP.get("prices", [2, 3, 4, 6])
	var base: float = prices[clampi(rarity, 0, prices.size() - 1)]
	if tier <= 1:
		return int(base)
	return roundi(base * float(BATTLE_SHOP.get("tier2_price_mult", 2.5)) * pow(2.0, tier - 2))


## Meat back for selling a gear: its tier-1 worth times the refund share, at least 1.
static func sell_refund(rarity: int, tier: int) -> int:
	var worth := shop_price(rarity) * pow(2.0, tier - 1)
	return maxi(1, floori(worth * float(BATTLE_SHOP.get("sell_refund", 0.75))))


## Rarity weights for the shop at wave number `wave` (1-based).
static func shop_odds(wave: int) -> Array:
	var best: Array = [1, 0, 0, 0]
	for row in BATTLE_SHOP.get("odds", []):
		if wave >= int(row["from"]):
			best = row["weights"]
	return best


static func workshop_cost(id: String, level: int) -> int:
	var spec: Dictionary = WORKSHOP[id]
	return Balance.formula_int("workshop_cost", {"base": spec["base"], "growth": spec["growth"], "level": level})


static func win_gold(level_index: int, stars: int) -> int:
	return Balance.formula_int("win_gold", {"level": level_index, "stars": stars})


static func loss_gold(waves_cleared: int) -> int:
	return Balance.formula_int("loss_gold", {"waves": waves_cleared})


static func patrol_rate(levels_cleared: int) -> float:
	return Balance.formula("patrol_rate", {"cleared": levels_cleared})


static func battle_stars(hp_ratio: float) -> int:
	return clampi(Balance.formula_int("battle_stars", {"hp_ratio": hp_ratio}), 1, 3)
