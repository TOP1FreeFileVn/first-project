extends RefCounted

# The one hero cat and its equipment (design sheet, tab Change: one hero with many weapons;
# hero gear separate from soldier gear). PLACEHOLDER NUMBERS until the sheet's Hero&Weapon
# tab is filled: every value here is invented to make the screen and the loop work, and is
# meant to be replaced from the sheet.
#
# Six slots. The weapon decides the hero's attack style, its skill and the two soldier
# classes it pairs with; the other five add HP / attack / armour. Items level up with gold.
# The save keeps {"equipped": {slot: uid}, "bag": {uid: {"id", "level"}}, "next": uid}
# in PlayerData.hero_cat.

const TroopData = preload("res://game/data/TroopData.gd")

## Left column top→bottom, then right column top→bottom on the screen.
const SLOTS := ["weapon", "helmet", "armor", "gloves", "boots", "amulet"]
const SLOT_NAMES := {"weapon": "Vũ khí", "helmet": "Mũ", "armor": "Giáp", "gloves": "Găng", "boots": "Giày", "amulet": "Bùa"}
const SLOT_ICONS := {"weapon": "w_kiem", "helmet": "eq_helmet", "armor": "eq_armor", "gloves": "eq_gloves", "boots": "eq_boots", "amulet": "eq_amulet"}
const STAT_NAMES := {"hp": "Máu", "atk": "Công", "def": "Giáp"}
const STAT_ICONS := {"hp": "heart", "atk": "w_kiem", "def": "eq_armor"}

## The cat's own stats before gear.
const BASE := {"hp": 1200, "atk": 90, "def": 30}
## Each item level adds this share of the item's level-1 stats.
const PER_LEVEL := 0.12
const MAX_LEVEL := 20

const INF := TroopData.Klass.INFANTRY
const RNG := TroopData.Klass.RANGED
const MAG := TroopData.Klass.MAGE
const CAV := TroopData.Klass.CAVALRY

## id -> slot, name, icon, rarity (0-3), stats at level 1; weapons add `pairs` (two soldier
## classes), `skill` and `range` (melee / ranged attack).
const ITEMS := {
	"kiem_go": {"slot": "weapon", "name": "Kiếm Gỗ", "icon": "hero_w_kiem", "rarity": 0, "stats": {"atk": 40},
		"pairs": [INF, CAV], "range": "Cận chiến", "skill": "Chém xoáy: mỗi 8 giây chém vòng tròn quanh mèo."},
	"cung_san": {"slot": "weapon", "name": "Cung Săn", "icon": "hero_w_cung", "rarity": 1, "stats": {"atk": 52},
		"pairs": [RNG, MAG], "range": "Đánh xa", "skill": "Mưa tên: mỗi 10 giây bắn 8 mũi tên xuống đám đông."},
	"gay_sao": {"slot": "weapon", "name": "Gậy Sao", "icon": "hero_w_gay_phep", "rarity": 2, "stats": {"atk": 75},
		"pairs": [MAG, RNG], "range": "Đánh xa", "skill": "Sao băng: mỗi 12 giây gọi sao rơi gây sát thương lan."},
	"riu_lua": {"slot": "weapon", "name": "Rìu Lửa", "icon": "hero_w_riu", "rarity": 2, "stats": {"atk": 82},
		"pairs": [INF, CAV], "range": "Cận chiến", "skill": "Chẻ lửa: đòn thứ 4 đốt cháy mục tiêu."},
	"katana_nguyet": {"slot": "weapon", "name": "Katana Nguyệt", "icon": "hero_w_katana", "rarity": 3, "stats": {"atk": 115},
		"pairs": [INF, CAV], "range": "Cận chiến", "skill": "Trảm nguyệt: lướt qua hàng địch, chém mọi kẻ trên đường."},
	"mu_da": {"slot": "helmet", "name": "Mũ Da", "icon": "eq_helmet", "rarity": 0, "stats": {"hp": 160, "def": 6}},
	"mu_sat": {"slot": "helmet", "name": "Mũ Sắt", "icon": "eq_helmet", "rarity": 1, "stats": {"hp": 240, "def": 10}},
	"mu_hiep_si": {"slot": "helmet", "name": "Mũ Hiệp Sĩ", "icon": "eq_helmet", "rarity": 2, "stats": {"hp": 360, "def": 15}},
	"giap_vai": {"slot": "armor", "name": "Áo Vải", "icon": "eq_armor", "rarity": 0, "stats": {"hp": 220, "def": 10}},
	"giap_xich": {"slot": "armor", "name": "Giáp Xích", "icon": "eq_armor", "rarity": 1, "stats": {"hp": 330, "def": 16}},
	"giap_rong": {"slot": "armor", "name": "Giáp Vảy Rồng", "icon": "eq_armor", "rarity": 3, "stats": {"hp": 640, "def": 30}},
	"gang_da": {"slot": "gloves", "name": "Găng Da", "icon": "eq_gloves", "rarity": 0, "stats": {"atk": 12}},
	"gang_bac": {"slot": "gloves", "name": "Găng Bạc", "icon": "eq_gloves", "rarity": 2, "stats": {"atk": 26, "def": 6}},
	"giay_co": {"slot": "boots", "name": "Giày Cỏ", "icon": "eq_boots", "rarity": 0, "stats": {"hp": 120, "def": 4}},
	"giay_gio": {"slot": "boots", "name": "Giày Gió", "icon": "eq_boots", "rarity": 1, "stats": {"hp": 180, "atk": 8}},
	"bua_go": {"slot": "amulet", "name": "Bùa Gỗ", "icon": "eq_amulet", "rarity": 0, "stats": {"atk": 8, "hp": 80}},
	"bua_ngoc": {"slot": "amulet", "name": "Bùa Ngọc", "icon": "eq_amulet", "rarity": 2, "stats": {"atk": 20, "hp": 200}},
}

## The skill gear each weapon brings into battle: it charges while it turns on the board
## (`cooldown` = production seconds) and then the hero casts it. `power` scales the hero's
## attack; `kind` picks the effect in Battle.cast_hero_skill.
const SKILLS := {
	"kiem_go": {"name": "Chém xoáy", "kind": "whirl", "cooldown": 8.0, "power": 0.35},
	"cung_san": {"name": "Mưa tên", "kind": "volley", "cooldown": 10.0, "power": 0.25},
	"gay_sao": {"name": "Sao băng", "kind": "meteor", "cooldown": 12.0, "power": 0.6},
	"riu_lua": {"name": "Chẻ lửa", "kind": "fire", "cooldown": 9.0, "power": 0.3},
	"katana_nguyet": {"name": "Trảm nguyệt", "kind": "slash", "cooldown": 14.0, "power": 0.5},
}


## The equipped weapon's id and skill, or {} with no weapon.
static func weapon_skill(state: Dictionary) -> Dictionary:
	var uid := equipped_uid(state, "weapon")
	var it := item(state, uid)
	if it.is_empty() or not SKILLS.has(it["id"]):
		return {}
	var out: Dictionary = SKILLS[it["id"]].duplicate()
	out["weapon"] = it["id"]
	out["icon"] = ITEMS[it["id"]]["icon"]
	return out


## A new profile starts with these equipped, and these in the bag.
const STARTER_EQUIPPED := ["kiem_go", "mu_da", "giap_vai"]
const STARTER_BAG := ["cung_san", "gang_da", "giay_co", "bua_go", "mu_sat", "gay_sao"]


static func new_state() -> Dictionary:
	var state := {"equipped": {}, "bag": {}, "next": 1}
	for id in STARTER_EQUIPPED:
		var uid := add_item(state, id)
		state["equipped"][ITEMS[id]["slot"]] = uid
	for id in STARTER_BAG:
		add_item(state, id)
	return state


## Puts a new level-1 item in the bag; returns its uid.
static func add_item(state: Dictionary, id: String) -> String:
	var uid := str(int(state["next"]))
	state["next"] = int(state["next"]) + 1
	state["bag"][uid] = {"id": id, "level": 1}
	return uid


static func item(state: Dictionary, uid: String) -> Dictionary:
	return state["bag"].get(uid, {})


static func def(state: Dictionary, uid: String) -> Dictionary:
	var it := item(state, uid)
	return ITEMS.get(it.get("id", ""), {})


static func equipped_uid(state: Dictionary, slot: String) -> String:
	return str(state["equipped"].get(slot, ""))


static func is_equipped(state: Dictionary, uid: String) -> bool:
	return state["equipped"].values().has(uid)


## Bag items not worn, best first (rarity, then level).
static func spare(state: Dictionary) -> Array:
	var uids := []
	for uid in state["bag"]:
		if not is_equipped(state, uid):
			uids.append(uid)
	uids.sort_custom(func(a, b):
		var ra: int = def(state, a)["rarity"]
		var rb: int = def(state, b)["rarity"]
		return ra > rb or (ra == rb and item(state, a)["level"] > item(state, b)["level"]))
	return uids


static func item_stats(state: Dictionary, uid: String, level := -1) -> Dictionary:
	var d := def(state, uid)
	if d.is_empty():
		return {}
	var lv: int = item(state, uid)["level"] if level < 0 else level
	var out := {}
	for key in d["stats"]:
		out[key] = roundi(d["stats"][key] * (1.0 + PER_LEVEL * (lv - 1)))
	return out


static func total_stats(state: Dictionary) -> Dictionary:
	var out := BASE.duplicate()
	for slot in SLOTS:
		var uid := equipped_uid(state, slot)
		if uid == "":
			continue
		var s := item_stats(state, uid)
		for key in s:
			out[key] = out.get(key, 0) + s[key]
	return out


## One number for the plaque: HP plus weighted attack and armour.
static func power(stats: Dictionary) -> int:
	return roundi(stats.get("hp", 0) + stats.get("atk", 0) * 8.0 + stats.get("def", 0) * 12.0)


## Gold for the next level, or -1 at max.
static func upgrade_cost(state: Dictionary, uid: String) -> int:
	var it := item(state, uid)
	if it.is_empty() or it["level"] >= MAX_LEVEL:
		return -1
	var rarity: int = def(state, uid)["rarity"]
	return roundi((40 + 25 * it["level"]) * (1.0 + 0.5 * rarity))


static func tone(rarity: int) -> String:
	return ["green", "blue", "purple", "orange"][clampi(rarity, 0, 3)]
