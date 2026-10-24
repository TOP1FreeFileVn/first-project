extends RefCounted

# The four cats and their other-world versions (Limbus-style identities). Every troop
# card is one cat as it lives in one world, and a world can give a cat another class.
# The table is two orthogonal Latin squares, so:
#   - each cat has all four classes and all four rarities (one per world);
#   - each world has all four classes and all four rarities (one per cat);
#   - the 16 troops (4 classes x 4 rarities) are used exactly once.
# A team takes at most one version of each cat. The summon banner features one world a
# day: half of the pulls of a rarity land on that world's version.

const ORDER := ["muop", "tro", "tam", "bo"]
const NAMES := {"muop": "Mướp", "tro": "Tro", "tam": "Tam", "bo": "Bơ"}
const BLURBS := {
	"muop": "Mèo mướp gan dạ, luôn xông lên trước",
	"tro": "Mèo xám điềm tĩnh, ra tay rất chuẩn",
	"tam": "Mèo tam thể tinh nghịch, nghĩ ra đủ trò",
	"bo": "Mèo kem hiền lành, lo cho cả đội",
}
## Coat kind in the cat art tools (make_svgs CATS) for the art pass.
const COATS := {"muop": "tabby", "tro": "grey", "tam": "calico", "bo": "cream"}

const WORLDS := ["carton", "den_long", "co_tich", "hai_tac"]
const WORLD_NAMES := {
	"carton": "Vương Quốc Carton", "den_long": "Phố Đèn Lồng",
	"co_tich": "Rừng Cổ Tích", "hai_tac": "Đảo Hải Tặc",
}
## On the small roster cards.
const WORLD_SHORT := {"carton": "Carton", "den_long": "Đèn Lồng", "co_tich": "Cổ Tích", "hai_tac": "Hải Tặc"}

## cat -> its version (troop id) in each world, in WORLDS order.
const VERSIONS := {
	"muop": ["kiem", "sung", "dua_phep", "cu_kiem"],
	"tro": ["no", "katana", "chuy", "gay_phep"],
	"tam": ["sach_phep", "giao", "riu", "dai_bac"],
	"bo": ["bua", "thuoc", "cung", "dao"],
}

const COUNT := 4


static func cat_of(troop_id: String) -> String:
	for cat in ORDER:
		if VERSIONS[cat].has(troop_id):
			return cat
	return ""

static func world_of(troop_id: String) -> String:
	var cat := cat_of(troop_id)
	return WORLDS[VERSIONS[cat].find(troop_id)] if cat != "" else ""

static func version(cat: String, world: String) -> String:
	return VERSIONS[cat][WORLDS.find(world)]

## The four versions of one world, in cat order.
static func world_versions(world: String) -> Array:
	var out := []
	for cat in ORDER:
		out.append(version(cat, world))
	return out

## The world on the summon banner on day `day` (changes every day).
static func featured_world(day: int) -> String:
	return WORLDS[posmod(day, WORLDS.size())]

## "Mướp · Vương Quốc Carton"
static func caption(troop_id: String) -> String:
	var cat := cat_of(troop_id)
	return "%s · %s" % [NAMES[cat], WORLD_NAMES[world_of(troop_id)]] if cat != "" else ""
