extends RefCounted

# The heroes (Tướng): one leads the team, buffs the whole battle and fights in it as a big
# unit (see Battle._spawn_hero). Each hero fights like its base troop ("troop") with far
# higher stats, and looks like it recoloured by game/ui/recolor.gdshader (hue shift of the
# blue team colour, then saturation / brightness), drawn larger, with a waving cape in its
# own colour and an aura. Also the hero summon event.

const ORDER := ["valor", "storm", "ember", "sage", "iron", "shadow"]

## rarity: 1 rare, 2 epic, 3 legendary (Economy.RARITY_NAMES / RARITY_COLORS).
## hue/sat/val: recolour of the team colour. buff: what the hero improves (see bonus()).
const HEROES := {
	"valor": {"name": "Hiệp Sĩ Bạch Kim", "unit": "Warrior", "troop": "warrior", "cape": Color("d9434f"), "rarity": 3, "hue": 0.0, "sat": 0.12, "val": 1.35,
		"buff": "hp", "base": 20.0, "per_level": 1.0, "text": "+%s%% máu cho mọi lính",
		"story": "Hiệp sĩ trong bộ giáp bạch kim, chưa từng lùi một bước."},
	"storm": {"name": "Thương Thần Bão Tố", "unit": "Lancer", "troop": "lancer", "cape": Color("f2c14e"), "rarity": 3, "hue": -0.1, "sat": 1.4, "val": 1.15,
		"buff": "damage", "base": 18.0, "per_level": 1.0, "text": "+%s%% sát thương cho mọi lính",
		"story": "Mũi thương của hắn nhanh như tia chớp."},
	"ember": {"name": "Xạ Thủ Hoả Ngục", "unit": "Archer", "troop": "fire_archer", "cape": Color("3b2b3e"), "rarity": 2, "hue": 0.45, "sat": 1.3, "val": 1.1,
		"buff": "spawn", "base": 12.0, "per_level": 0.6, "text": "+%s%% tốc độ sinh lính",
		"story": "Cung thủ đến từ vùng núi lửa, thúc quân ra trận không ngơi nghỉ."},
	"sage": {"name": "Hiền Giả Lục Diệp", "unit": "Monk", "troop": "monk", "cape": Color("e8d9a8"), "rarity": 2, "hue": -0.27, "sat": 1.1, "val": 1.05,
		"buff": "income", "base": 2.0, "per_level": 0.2, "text": "+%s thịt thu nhập mỗi đợt",
		"story": "Người giữ rừng, biết cách nuôi quân bằng lộc của đất."},
	"iron": {"name": "Đội Trưởng Thép", "unit": "Guard", "troop": "guard", "cape": Color("3f7fd9"), "rarity": 1, "hue": 0.0, "sat": 0.0, "val": 0.9,
		"buff": "core", "base": 15.0, "per_level": 1.0, "text": "+%s%% máu thành",
		"story": "Người lính già canh cổng thành đã ba mươi năm."},
	"shadow": {"name": "Sát Thủ Bóng Đêm", "unit": "PawnKnife", "troop": "assassin", "cape": Color("1c1c2a"), "rarity": 1, "hue": 0.17, "sat": 1.2, "val": 0.65,
		"buff": "damage", "base": 8.0, "per_level": 0.5, "text": "+%s%% sát thương cho mọi lính",
		"story": "Không ai thấy hắn đến, chỉ thấy quân địch ngã xuống."},
}
const STARTER := "iron"

const MAX_STARS := 5
const LEVELS_PER_STAR := 10
## Shards to go from n stars to n+1.
const STAR_SHARDS := [10, 20, 40, 80]
const UNLOCK_SHARDS := 30
const DUPLICATE_SHARDS := 20

# --- Summon event -----------------------------------------------------------------------
const WEEK := 604800
const SUMMON_COST := {1: 30, 10: 270}
const SUMMON_PITY := 50
## [result, weight %]; see summon() in PlayerData.
const SUMMON_TABLE := [
	["featured", 1.5], ["legendary", 1.0], ["epic", 6.0], ["rare", 15.0],
	["featured_shards", 8.0], ["shards", 20.0], ["gold", 48.5],
]
const SUMMON_GOLD := 250
const FEATURED_SHARDS := 5
const RANDOM_SHARDS := 3
## Heroes that take turns as the featured hero, one per week.
const FEATURED_POOL := ["storm", "ember", "valor", "sage"]


static func level_cost(level: int) -> int:
	return roundi(200.0 * pow(1.22, level - 1))


## A hero's HP and damage as multiples of its base troop (at level 1 of that troop).
static func hp_mult(level: int, stars: int) -> float:
	return (4.5 + 0.3 * (level - 1)) * (1.0 + 0.3 * (stars - 1))


static func damage_mult(level: int, stars: int) -> float:
	return (2.5 + 0.15 * (level - 1)) * (1.0 + 0.3 * (stars - 1))


static func bonus(id: String, level: int, stars: int) -> float:
	var hero: Dictionary = HEROES[id]
	return hero["base"] * (1.0 + 0.25 * (stars - 1)) + hero["per_level"] * (level - 1)


static func bonus_text(id: String, level: int, stars: int) -> String:
	var value := bonus(id, level, stars)
	var shown := str(floori(value)) if HEROES[id]["buff"] == "income" else ("%.0f" % value if is_equal_approx(value, roundf(value)) else "%.1f" % value)
	return HEROES[id]["text"] % shown


static func featured_for(week: int) -> String:
	return FEATURED_POOL[posmod(week, FEATURED_POOL.size())]


static func of_rarity(rarity: int) -> Array:
	var ids := []
	for id in ORDER:
		if HEROES[id]["rarity"] == rarity:
			ids.append(id)
	return ids
