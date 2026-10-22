extends RefCounted

# The one hero cat and its equipment (design sheet, tab Change: one hero with many weapons;
# hero gear separate from soldier gear). PLACEHOLDER NUMBERS until the sheet's Hero&Weapon
# tab is filled: every value here is invented to make the screen and the loop work, and is
# meant to be replaced from the sheet.
#
# Four slots. The weapon decides the hero's attack style, its skill and the two soldier
# classes it pairs with; helmet, armour and boots add stats. Items level up with gold.
# The save keeps {"equipped": {slot: uid}, "bag": {uid: {"id", "level"}}, "next": uid}
# in PlayerData.hero_cat. Removed equipment is retained in a separate retired_items archive.

const TroopData = preload("res://game/data/TroopData.gd")

## Left column top→bottom, then right column top→bottom on the screen.
const SLOTS := ["weapon", "helmet", "armor", "boots"]
const SLOT_NAMES := {"weapon": "Vũ khí", "helmet": "Mũ", "armor": "Giáp", "boots": "Giày"}
## Category glyphs are separate from item art, including empty-slot placeholders.
const SLOT_ICONS := {"weapon": "slot_weapon", "helmet": "slot_helmet", "armor": "slot_armor", "boots": "slot_boots"}
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
	"giay_co": {"slot": "boots", "name": "Giày Cỏ", "icon": "eq_boots", "rarity": 0, "stats": {"hp": 120, "def": 4}},
	"giay_gio": {"slot": "boots", "name": "Giày Gió", "icon": "eq_boots", "rarity": 1, "stats": {"hp": 180, "atk": 8}},
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
const STARTER_BAG := ["cung_san", "giay_co", "mu_sat", "gay_sao"]


static func new_state() -> Dictionary:
	var state := {"equipped": {}, "bag": {}, "retired_items": {}, "next": 1}
	for id in STARTER_EQUIPPED:
		var uid := add_item(state, id)
		state["equipped"][ITEMS[id]["slot"]] = uid
	for id in STARTER_BAG:
		add_item(state, id)
	return state


## Loads only supported equipment into active play. Old items keep their UID and level
## in the save archive, so removing a slot never silently deletes its item records.
static func restore_state(saved: Dictionary) -> Dictionary:
	var state := {"equipped": {}, "bag": {}, "retired_items": {}, "next": int(saved.get("next", 1))}
	for collection in ["retired_items", "bag"]:
		var records = saved.get(collection, {})
		if not records is Dictionary:
			continue
		for key in records:
			if not records[key] is Dictionary:
				continue
			var uid := str(key)
			var record: Dictionary = records[key].duplicate(true)
			record["id"] = str(record.get("id", ""))
			record["level"] = int(record.get("level", 1))
			if collection == "bag" and ITEMS.has(record["id"]):
				state["bag"][uid] = record
			else:
				state["retired_items"][uid] = record
	var equipped = saved.get("equipped", {})
	if equipped is Dictionary:
		for slot in SLOTS:
			var uid := str(equipped.get(slot, ""))
			var definition := def(state, uid)
			if not definition.is_empty() and definition["slot"] == slot:
				state["equipped"][slot] = uid
	state["next"] = _next_uid(state)
	return state


## Both active and retired records reserve their numeric UIDs.
static func _next_uid(state: Dictionary) -> int:
	var next := maxi(1, int(state.get("next", 1)))
	for collection in ["bag", "retired_items"]:
		for key in state.get(collection, {}):
			var uid := str(key)
			if uid.is_valid_int():
				next = maxi(next, int(uid) + 1)
	return next


## Puts a supported level-1 item in the bag; returns an empty UID for removed items.
static func add_item(state: Dictionary, id: String) -> String:
	if not ITEMS.has(id):
		return ""
	var next := _next_uid(state)
	var uid := str(next)
	state["next"] = next + 1
	state["bag"][uid] = {"id": id, "level": 1}
	return uid


static func item(state: Dictionary, uid: String) -> Dictionary:
	return state["bag"].get(uid, {})


static func def(state: Dictionary, uid: String) -> Dictionary:
	var it := item(state, uid)
	return ITEMS.get(it.get("id", ""), {})


static func equipped_uid(state: Dictionary, slot: String) -> String:
	if not SLOTS.has(slot):
		return ""
	return str(state["equipped"].get(slot, ""))


static func is_equipped(state: Dictionary, uid: String) -> bool:
	return state["equipped"].values().has(uid)


## Bag items not worn, best first (rarity, then level).
static func spare(state: Dictionary) -> Array:
	var uids := []
	for uid in state["bag"]:
		if not def(state, uid).is_empty() and not is_equipped(state, uid):
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
	var definition := def(state, uid)
	if it.is_empty() or definition.is_empty() or it["level"] >= MAX_LEVEL:
		return -1
	var rarity: int = definition["rarity"]
	return roundi((40 + 25 * it["level"]) * (1.0 + 0.5 * rarity))


static func tone(rarity: int) -> String:
	return ["green", "blue", "purple", "orange"][clampi(rarity, 0, 3)]
