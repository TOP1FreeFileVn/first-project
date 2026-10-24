extends RefCounted

# The one hero cat and its equipment (design sheet, tab Change: one hero with many weapons;
# hero gear separate from soldier gear). PLACEHOLDER NUMBERS until the sheet's Hero&Weapon
# tab is filled: every value here is invented to make the screen and the loop work, and is
# meant to be replaced from the sheet.
#
# Four slots. The weapon decides the hero's attack style, its skill and the two soldier
# classes it pairs with (they hit harder while it is worn); helmet, armour and boots add
# stats (hp -> castle HP, def -> less damage to the wall, atk -> the hero's skill).
#
# Economy, kept apart from the troops so the two never fight over one currency:
#   source  - chests (balance.json "chests": items + Forge Stones) and Forge Stones from
#             battles and the patrol;
#   level   - Forge Stones (đá rèn) plus a little gold (upgrade_cost / upgrade_gold);
#   cap     - an item's rarity sets its max level (LEVEL_CAP: 10/20/30/40);
#   break   - levels 10, 20 and 30 are breakthroughs that also need Blueprints (bản vẽ) of
#             the item's slot (BREAK_BLUEPRINTS). Blueprints come from boss levels, Silver and
#             Gold chests, the daily quest milestones and salvaging items of that slot;
#   rarity  - three identical items of one rarity fuse into the next rarity (fuse()), which
#             is what raises the cap;
#   spare   - an unworn item salvages back into Forge Stones (salvage_value()).
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
## Max level by rarity (common, rare, epic, legendary); MAX_LEVEL is the highest of them.
const LEVEL_CAP := [10, 20, 30, 40]
const MAX_LEVEL := 40
## Going past these levels is a breakthrough: Blueprints of the item's slot, as well as stones.
const BREAK_BLUEPRINTS := {10: 5, 20: 15, 30: 40}
## Blueprints a salvaged item returns (of its own slot), by rarity.
const SALVAGE_BLUEPRINTS := [0, 1, 3, 8]
## Blueprints a won boss level gives (random slot), and a Silver / Gold chest gives.
const BOSS_BLUEPRINTS := 3
const CHEST_BLUEPRINTS := {"silver": 2, "gold": 6}

## A weapon adds this much damage to the two soldier classes it pairs with (and +1 per 10 levels).
const PAIR_DAMAGE_PCT := 8.0
## Each point of armour (def) takes this share off a blow to the wall, capped.
const DEF_BLOCK := 0.002
const DEF_BLOCK_MAX := 0.4

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
	"mu_rong": {"slot": "helmet", "name": "Mũ Rồng", "icon": "eq_helmet", "rarity": 3, "stats": {"hp": 520, "def": 22}},
	"giap_bac": {"slot": "armor", "name": "Giáp Bạc", "icon": "eq_armor", "rarity": 2, "stats": {"hp": 470, "def": 22}},
	"giay_bao": {"slot": "boots", "name": "Giày Bão", "icon": "eq_boots", "rarity": 2, "stats": {"hp": 260, "atk": 14}},
	"giay_than": {"slot": "boots", "name": "Giày Thần Tốc", "icon": "eq_boots", "rarity": 3, "stats": {"hp": 380, "atk": 22}},
}

# --- Rarity odds: the troop summon (tab "Triệu hồi") and chest equipment rolls share them ---
const SUMMON_COST := {1: 30, 10: 270}
## Rarity odds in %, common → legendary. A x10 summon always holds at least one epic card.
const SUMMON_RARITY := [62.0, 28.0, 8.5, 1.5]
## Summon pulls without a legendary card before the next one is guaranteed.
const SUMMON_PITY := 60

# --- Forge Stones (đá rèn) ---------------------------------------------------------------
## Stones a won battle gives: base + per level, x2 on first clear; a loss gives LOSS_STONES.
const WIN_STONES := 6
const WIN_STONES_PER_LEVEL := 2
const LOSS_STONES := 2
## Stones an hour of patrol makes (capped with the patrol).
const PATROL_STONES_PER_HOUR := 3
## A level-1 unworn item salvages for this many stones, by rarity, plus half what was spent.
const SALVAGE_STONES := [4, 10, 25, 60]
## Three identical items of the same rarity (any level) fuse into one of the next rarity.
const FUSE_COUNT := 3

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


## Max level of an item: its rarity's cap.
static func level_cap(state: Dictionary, uid: String) -> int:
	var d := def(state, uid)
	return LEVEL_CAP[d["rarity"]] if not d.is_empty() else 0

## Blueprints (of the item's slot) the next level needs: >0 only at a breakthrough.
static func breakthrough_cost(state: Dictionary, uid: String) -> int:
	var it := item(state, uid)
	return BREAK_BLUEPRINTS.get(int(it.get("level", 0)), 0) if upgrade_cost(state, uid) >= 0 else 0

## Forge Stones for the next level, or -1 at the rarity's cap.
static func upgrade_cost(state: Dictionary, uid: String) -> int:
	var it := item(state, uid)
	var definition := def(state, uid)
	if it.is_empty() or definition.is_empty() or it["level"] >= LEVEL_CAP[definition["rarity"]]:
		return -1
	var rarity: int = definition["rarity"]
	return roundi((4 + 3 * it["level"]) * (1.0 + 0.5 * rarity))

## The small gold part of a level-up (troops keep the gold economy; this stays minor).
static func upgrade_gold(state: Dictionary, uid: String) -> int:
	var it := item(state, uid)
	return -1 if upgrade_cost(state, uid) < 0 else 10 * int(it["level"])

## Stones spent to bring an item from level 1 to `level`.
static func stones_spent(rarity: int, level: int) -> int:
	var total := 0
	for lv in range(1, level):
		total += roundi((4 + 3 * lv) * (1.0 + 0.5 * rarity))
	return total

## Stones an unworn item salvages for: its rarity's base plus half the stones put into it.
static func salvage_value(state: Dictionary, uid: String) -> int:
	var d := def(state, uid)
	if d.is_empty():
		return 0
	return SALVAGE_STONES[d["rarity"]] + stones_spent(d["rarity"], item(state, uid)["level"]) / 2

## Items of `slot` with exactly `rarity` (for summon picks and fusing).
static func ids_of(slot: String, rarity: int) -> Array:
	var out := []
	for id in ITEMS:
		if (slot == "" or ITEMS[id]["slot"] == slot) and ITEMS[id]["rarity"] == rarity:
			out.append(id)
	return out

## A random item id of `rarity`; falls to the nearest lower rarity that exists in that slot.
static func random_of_rarity(rarity: int) -> String:
	for r in range(rarity, -1, -1):
		var pool := ids_of("", r)
		if not pool.is_empty():
			return pool.pick_random()
	return ITEMS.keys()[0]

## Unworn copies of `id`'s item (same id), lowest level first: the fuse candidates.
static func copies(state: Dictionary, id: String) -> Array:
	var uids := []
	for uid in state["bag"]:
		if state["bag"][uid]["id"] == id:
			uids.append(uid)
	uids.sort_custom(func(a, b): return state["bag"][a]["level"] < state["bag"][b]["level"])
	return uids

## What three copies of `id` fuse into: a same-slot item one rarity up, or "" at the top.
static func fuse_target(id: String) -> String:
	var d: Dictionary = ITEMS.get(id, {})
	if d.is_empty():
		return ""
	for r in range(d["rarity"] + 1, 4):
		var pool := ids_of(d["slot"], r)
		if not pool.is_empty():
			pool.sort()
			return pool[0]
	return ""


static func tone(rarity: int) -> String:
	return ["green", "blue", "purple", "orange"][clampi(rarity, 0, 3)]
