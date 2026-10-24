extends Node

# Everything the player owns and has unlocked, plus every rule for spending it. Menu pages
# only read from here and call these methods; Battle asks it for multipliers when a level
# starts and reports results back through grant_battle_rewards().

signal changed

const Economy = preload("res://game/core/Economy.gd")
const Content = preload("res://game/core/Content.gd")
const Meta = preload("res://game/core/Meta.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const Cats = preload("res://game/data/Cats.gd")

const SAVE_PATH := "user://save.json"
const LEGACY_SAVE_PATH := "user://progress.cfg"
const SAVE_VERSION := 1

const LEVELS := Content.LEVELS
const TROOP_ORDER := Content.TROOP_ORDER
const ENEMY_ORDER := Content.ENEMY_ORDER
## One common version each of Mướp, Bơ and Tro (see Cats.gd).
const STARTER_TROOPS := ["kiem", "cung", "gay_phep"]
## Of the pulls of one rarity, this share lands on the featured world's version.
const FEATURED_SHARE := 0.5

## id -> TroopData, filled from Content.TROOP_ORDER (the same instances Balance edits).
var TROOPS := {}

## Tools such as the balance bot turn this off so they never touch the player save.
var persist := true
var current_level := 0

var gold := 0
var gems := 0
var unlocked_levels := 1
var level_stars := {}
var troops := {}
var castle_level := 1
## Troop ids brought into battle, in slot order. The battle shop only offers these.
var team: Array = []
var workshop := {}
var free_chest_at := 0
var gold_chest_pity := 0
## Local calendar day when the shop's free daily gold was last claimed.
var shop_gold_day := -1
var patrol_last_claim := 0
var patrol_quick_left := 0
var patrol_quick_day := 0
## Settings: skip the chest-opening animation.
var fast_chest := false
## The victory chest of the last won battle, opened when the lobby shows again:
## {"cards": {troop: n}, "new": [troops]} or {} (its cards are already granted).
var pending_chest := {}
## Tests turn this on to see the victory chest flow without touching the save.
var victory_chest_in_tests := false

## True when a won battle's victory chest is kept for the lobby (not the simulator, which
## does not persist, nor "fast chest" players, who just see the cards).
func victory_chest_waits() -> bool:
	return (persist or victory_chest_in_tests) and not fast_chest
## Settings: the legacy UI skin name ("cozy"); the game skin is always on.
var ui_skin := "cozy"
## Settings: sound effects on.
var sound_on := true
var music_on := true
## Settings: volumes 0..1 (applied on top of the on/off switches).
var music_volume := 0.8
var sound_volume := 1.0
## Settings: short vibrations on mobile (merges, wins, the castle hit hard).
var vibration_on := true
## Settings: the speed a battle starts at (1 or 2).
var battle_speed := 1
## Settings: show the "CHÍ MẠNG!" text on critical hits.
var crit_text_on := true
## Settings: leaving a battle needs a second tap.
var confirm_leave := true

## Every setting, so reset_progress keeps them and the save writes them in one place.
const SETTINGS := ["fast_chest", "ui_skin", "sound_on", "music_on", "music_volume", "sound_volume",
	"vibration_on", "battle_speed", "crit_text_on", "confirm_leave"]
## The first-battle tutorial has been finished (or skipped).
var tutorial_done := false
## Special board cells the player has already been shown (see GearBoard.TILE_INFO).
var seen_tiles: Array = []
## The hero cat's equipment (HeroCat.new_state() layout).
var hero_cat: Dictionary = {}
## Set once any admin cheat touched this save, so balance feedback can be discounted.
var cheated := false
## Blueprints (bản vẽ) by equipment slot: what hero-cat equipment levels with.
var blueprints := {}
## Equipment summon: pulls since the last legendary (pity), free daily pull, total pulls.
var summon_pity := 0
var summon_free_day := -1
var summon_total := 0
## 7-day login gift: gifts claimed in this cycle (0-7), the day of the last claim, and
## how many full cycles were finished.
var login_claimed := 0
var login_day := -1
var login_cycles := 0
## Daily quests: the day they belong to, progress per quest, claimed quests and milestones.
var quest_day := -1
var quest_progress := {}
var quest_claimed: Array = []
var quest_milestones: Array = []
## Profile: name, avatar ("1".."21", the cat pictures in Meta.AVATARS) and frame.
var player_name := "Chỉ Huy"
var avatar := "1"
var frame := "wood"


func _init() -> void:
	for id in Content.ALL_TROOPS:
		TROOPS[id] = load(Content.TROOP_PATH % id)


func _ready() -> void:
	_reset()
	if not _load():
		_migrate_legacy()
	current_level = unlocked_levels - 1


static func now() -> int:
	return int(Time.get_unix_time_from_system())


## Local calendar day number (daily gifts and quests roll over at local midnight).
static func today() -> int:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	return floori((now() + bias * 60) / 86400.0)


# --- Levels ---------------------------------------------------------------------------

func level_data(index := current_level) -> Resource:
	return load(LEVELS[index])


func can_select(index: int) -> bool:
	return index >= 0 and index < unlocked_levels


func select_level(index: int) -> void:
	if can_select(index):
		current_level = index


func has_next_level() -> bool:
	return can_select(current_level + 1)


func stars_for(index: int) -> int:
	return level_stars.get(index, 0)


func levels_cleared() -> int:
	return level_stars.size()


# --- Troops ---------------------------------------------------------------------------

func troop(id: String) -> Dictionary:
	return troops[id]


func rarity_of(id: String) -> int:
	return TROOPS[id].rarity


func is_unlocked(id: String) -> bool:
	return troops[id]["unlocked"]


func level_cap(id: String) -> int:
	return troops[id]["stars"] * Economy.LEVELS_PER_STAR


func troop_multiplier(id: String) -> float:
	var t: Dictionary = troops[id]
	return Economy.troop_multiplier(t["level"], t["stars"])


## Gold to reach the next level, or -1 when capped by stars.
func level_up_cost(id: String) -> int:
	var t: Dictionary = troops[id]
	if not t["unlocked"] or t["level"] >= level_cap(id):
		return -1
	return Economy.level_cost(t["level"])


func level_up(id: String) -> bool:
	var cost := level_up_cost(id)
	if cost < 0 or gold < cost:
		return false
	gold -= cost
	troops[id]["level"] += 1
	track("upgrade")
	_commit()
	return true


## Cards to reach the next star, or -1 at max stars.
func star_up_cost(id: String) -> int:
	var t: Dictionary = troops[id]
	if not t["unlocked"] or t["stars"] >= Economy.MAX_STARS:
		return -1
	return Economy.STAR_CARD_COST[t["stars"] - 1]


func star_up(id: String) -> bool:
	var cost := star_up_cost(id)
	if cost < 0 or troops[id]["cards"] < cost:
		return false
	troops[id]["cards"] -= cost
	troops[id]["stars"] += 1
	track("upgrade")
	_commit()
	return true


func can_improve(id: String) -> bool:
	var level_cost := level_up_cost(id)
	var star_cost := star_up_cost(id)
	return (level_cost >= 0 and gold >= level_cost) or (star_cost >= 0 and troops[id]["cards"] >= star_cost)


## The first card of a locked troop unlocks it; cards beyond max stars turn into gold.
func add_cards(id: String, count: int) -> void:
	var t: Dictionary = troops[id]
	if not t["unlocked"]:
		t["unlocked"] = true
		count -= 1
		var current := battle_team()
		if not current.has(id) and current.size() < team_slots():
			current.append(id)
			team = current
	if t["stars"] >= Economy.MAX_STARS:
		gold += count * Economy.SPARE_CARD_GOLD
	else:
		t["cards"] += count


# --- Team -----------------------------------------------------------------------------

func team_slots() -> int:
	return Economy.team_slots(castle_level)


## The team as it will play: unlocked, known, one version per cat, within the slot count,
## and never empty.
func battle_team() -> Array:
	var result := []
	var cats := []
	for id in team:
		var cat := Cats.cat_of(id)
		if TROOPS.has(id) and is_unlocked(id) and not cats.has(cat) and result.size() < team_slots():
			result.append(id)
			cats.append(cat)
	if result.is_empty():
		result = auto_team()
	return result


func in_team(id: String) -> bool:
	return battle_team().has(id)


## Each cat's strongest unlocked version, strongest first, one per slot (new saves and
## the simulator).
func auto_team() -> Array:
	var ids := []
	for cat in Cats.ORDER:
		var best := ""
		for id in Cats.VERSIONS[cat]:
			if is_unlocked(id) and (best == "" or troop_power(id) > troop_power(best)):
				best = id
		if best != "":
			ids.append(best)
	ids.sort_custom(func(a, b): return troop_power(a) > troop_power(b))
	return ids.slice(0, team_slots())


## The team member that is the same cat as `id` (another version of it), or "".
func team_same_cat(id: String) -> String:
	for other in battle_team():
		if Cats.cat_of(other) == Cats.cat_of(id):
			return other
	return ""


## Adds a troop to the first free slot; another version of the same cat is swapped out
## in place. Returns false when the team is full.
func add_to_team(id: String) -> bool:
	var current := battle_team()
	if current.has(id) or not is_unlocked(id):
		return current.has(id)
	var same := team_same_cat(id)
	if same != "":
		current[current.find(same)] = id
		team = current
		_commit()
		return true
	if current.size() >= team_slots():
		return false
	current.append(id)
	team = current
	_commit()
	return true


func remove_from_team(id: String) -> bool:
	var current := battle_team()
	if not current.has(id) or current.size() <= 1:
		return false
	current.erase(id)
	team = current
	_commit()
	return true


## Puts the troop in the given slot, swapping with its old slot if it was already in the team.
func set_team_slot(index: int, id: String) -> void:
	var current := battle_team()
	if not is_unlocked(id) or index < 0 or index >= team_slots():
		return
	# Another version of the same cat steps out: this one takes its place, then moves.
	var same := team_same_cat(id)
	if same != "" and same != id:
		current[current.find(same)] = id
	var old := current.find(id)
	if index >= current.size():
		if old >= 0:
			current.remove_at(old)
		current.append(id)
	elif old >= 0:
		current[old] = current[index]
		current[index] = id
	else:
		current[index] = id
	team = current
	_commit()


## Rough fighting value of one troop at the player's level and stars: HP x damage per
## second, with supports and abilities counted by a flat bonus.
func troop_power(id: String) -> float:
	var troop: Resource = TROOPS[id]
	var mult := troop_multiplier(id)
	var dps: float = troop.damage / maxf(troop.attack_cooldown, 0.1) * troop.crit_factor()
	if troop.role == 3:
		dps = 6.0
	var bonus: float = 1.0 + 0.15 * troop.rarity
	return troop.max_hp * mult * dps * mult * bonus


func team_power() -> int:
	var total := 0.0
	for id in battle_team():
		total += troop_power(id)
	return roundi(sqrt(total) * 10.0)


# --- Castle & workshop ----------------------------------------------------------------

func castle_stats() -> Dictionary:
	return Economy.CASTLE[castle_level - 1]


func castle_max_level() -> int:
	return Economy.CASTLE.size()


func castle_upgrade_cost() -> int:
	if castle_level >= castle_max_level():
		return -1
	return Economy.CASTLE[castle_level]["cost"]


func upgrade_castle() -> bool:
	var cost := castle_upgrade_cost()
	if cost < 0 or gold < cost:
		return false
	gold -= cost
	castle_level += 1
	_commit()
	return true


func workshop_level(id: String) -> int:
	return workshop.get(id, 0)


func workshop_cost(id: String) -> int:
	var level := workshop_level(id)
	if level >= Economy.WORKSHOP[id]["max"]:
		return -1
	return Economy.workshop_cost(id, level)


func upgrade_workshop(id: String) -> bool:
	var cost := workshop_cost(id)
	if cost < 0 or gold < cost:
		return false
	gold -= cost
	workshop[id] = workshop_level(id) + 1
	_commit()
	return true


func workshop_value(id: String, level := -1) -> int:
	if level < 0:
		level = workshop_level(id)
	return level * Economy.WORKSHOP[id]["step"]


func can_improve_castle() -> bool:
	var cost := castle_upgrade_cost()
	if cost >= 0 and gold >= cost:
		return true
	for id in Economy.WORKSHOP_ORDER:
		cost = workshop_cost(id)
		if cost >= 0 and gold >= cost:
			return true
	return false


# Battle-facing modifiers.
func core_hp_multiplier() -> float:
	return castle_stats()["hp"] * (1.0 + hero_cat_stats().get("hp", 0) / CASTLE_HP_PER_PCT / 100.0)


func max_meat() -> float:
	return castle_stats()["meat"]


func unlocked_cells() -> int:
	return castle_stats()["cells"]


## Extra meat per cleared wave from the Meat Oven workshop.
func round_income_bonus() -> int:
	return workshop_value("meat_regen")


func start_meat_bonus() -> float:
	return workshop_value("start_meat")


func spawn_speed_multiplier() -> float:
	return 1.0 + workshop_value("master_gear") / 100.0


## Hero-cat HP that adds 1% castle HP (the starter kit's ~1700 HP gives about +17%).
const CASTLE_HP_PER_PCT := 100.0

## Extra damage (a multiplier) for a troop class the equipped weapon pairs with, else 1.
func class_damage_multiplier(klass: int) -> float:
	var uid := HeroCat.equipped_uid(hero_cat, "weapon")
	var d := HeroCat.def(hero_cat, uid)
	if d.is_empty() or not klass in d.get("pairs", []):
		return 1.0
	return 1.0 + (HeroCat.PAIR_DAMAGE_PCT + floorf(int(HeroCat.item(hero_cat, uid)["level"]) / 10.0)) / 100.0

## Share of each blow to the wall that the hero cat's armour blocks.
func wall_block() -> float:
	return minf(HeroCat.DEF_BLOCK_MAX, hero_cat_stats().get("def", 0) * HeroCat.DEF_BLOCK)


# --- Shop -----------------------------------------------------------------------------

func free_chest_seconds_left() -> int:
	return maxi(0, free_chest_at - now())


func can_open_chest(kind: String, count: int = 1) -> bool:
	if not kind in Economy.CHEST_ORDER or not Economy.CHESTS.has(kind):
		return false
	if count != 1 and (kind != "gold" or count != 10):
		return false
	var chest: Dictionary = Economy.CHESTS[kind]
	if kind == "wood":
		return free_chest_seconds_left() == 0
	return gold >= int(chest["gold"]) * count and gems >= int(chest["gems"]) * count


## Pays for and opens a chest. Chests hold hero-cat equipment and Blueprints (troop cards
## come from the summon tab and battles). Returns {"items": [{"id", "uid", "rarity"}],
## "blueprints": {slot: n}, "gold": n} or {} if refused. Gold supports 1 or 10 chests at the
## ordinary per-chest price. A batch keeps each chest's guarantees and pity roll.
func open_chest(kind: String, count: int = 1) -> Dictionary:
	if not can_open_chest(kind, count):
		return {}
	var chest: Dictionary = Economy.CHESTS[kind]
	# Check the full bill before granting anything; a batch never opens partially.
	gold -= int(chest["gold"]) * count
	gems -= int(chest["gems"]) * count
	if kind == "wood":
		free_chest_at = now() + Economy.FREE_CHEST_COOLDOWN
	var result := {"items": [], "gold": 0}
	for i in count:
		var loot := _grant_chest_loot(kind)
		result["items"].append_array(loot["items"])
		result["gold"] += loot["gold"]
		if loot.has("blueprints"):
			if not result.has("blueprints"):
				result["blueprints"] = {}
			for slot in loot["blueprints"]:
				result["blueprints"][slot] = int(result["blueprints"].get(slot, 0)) + int(loot["blueprints"][slot])
	if count > 1:
		result["chests"] = count
	track("chest", count)
	_commit()
	return result


## Grants one chest's ordinary roll, including its own floor and pity; caller pays
## the entire batch and commits once. Item order keeps each chest's rewards together.
func _grant_chest_loot(kind: String) -> Dictionary:
	var chest: Dictionary = Economy.CHESTS[kind]
	var guaranteed_epic := false
	if kind == "gold":
		gold_chest_pity += 1
		if gold_chest_pity >= Economy.GOLD_CHEST_PITY:
			guaranteed_epic = true
			gold_chest_pity = 0
	var rarities := []
	for i in int(chest.get("items", 1)):
		rarities.append(_roll_gear_rarity())
	# "min_rare" is the floor rarity; "min_count" (default 1) items are lifted to it.
	# The lowest rolls are lifted, so the item count never changes.
	rarities.sort()
	var floor_rarity := int(chest.get("min_rare", 0))
	if floor_rarity > 0:
		for i in mini(int(chest.get("min_count", 1)), rarities.size()):
			rarities[i] = maxi(rarities[i], floor_rarity)
	if guaranteed_epic and rarities.max() < 2:
		rarities[0] = 2
	var items := []
	for rarity in rarities:
		var id := HeroCat.random_of_rarity(rarity)
		items.append({"id": id, "uid": HeroCat.add_item(hero_cat, id), "rarity": HeroCat.ITEMS[id]["rarity"]})
	var bonus: Array = chest["bonus_gold"]
	var result := {"items": items, "gold": randi_range(bonus[0], bonus[1]) if bonus[1] > 0 else 0}
	var plans_range: Array = chest.get("blueprints", [0, 0])
	var plans := randi_range(int(plans_range[0]), int(plans_range[1]))
	if plans > 0:
		result["blueprints"] = _grant_blueprints(plans)
	gold += result["gold"]
	return result


## Equipment rarity for a chest roll, by HeroCat.SUMMON_RARITY odds.
func _roll_gear_rarity() -> int:
	var roll := randf() * 100.0
	for r in HeroCat.SUMMON_RARITY.size():
		roll -= HeroCat.SUMMON_RARITY[r]
		if roll < 0.0:
			return r
	return 0

func exchange_gems(multiplier: int = 1) -> bool:
	if multiplier not in Economy.EXCHANGE_MULTIPLIERS:
		return false
	var price: int = Economy.EXCHANGE_GEMS * multiplier
	var amount: int = Economy.EXCHANGE_GOLD * multiplier
	if price <= 0 or amount <= 0 or gems < price:
		return false
	gems -= price
	gold += amount
	_commit()
	return true


func shop_gold_available() -> bool:
	# A clock moved backwards must not make an already claimed day available again.
	return Economy.DAILY_SHOP_GOLD > 0 and shop_gold_day < today()


## Grants once per local calendar day; marking the day and gold are saved together.
func claim_shop_gold() -> int:
	if not shop_gold_available():
		return 0
	shop_gold_day = today()
	gold += Economy.DAILY_SHOP_GOLD
	_commit()
	return Economy.DAILY_SHOP_GOLD


func _roll_cards(count: int, min_rare: int, guaranteed_epic: bool) -> Dictionary:
	var rarities := []
	for i in count:
		rarities.append(_roll_rarity())
	# Chest guarantees upgrade the lowest rolls, so the total card count never changes.
	rarities.sort()
	for i in mini(min_rare, count):
		rarities[i] = maxi(rarities[i], Economy.Rarity.RARE)
	if guaranteed_epic and rarities.max() < Economy.Rarity.EPIC:
		rarities[0] = Economy.Rarity.EPIC
	var cards := {}
	for rarity in rarities:
		var id := _random_troop_of(rarity)
		cards[id] = cards.get(id, 0) + 1
	return {"cards": cards}


func _roll_rarity() -> int:
	var total := 0.0
	for weight in Economy.RARITY_WEIGHTS:
		total += weight
	var pick := randf() * total
	for rarity in Economy.RARITY_WEIGHTS.size():
		pick -= Economy.RARITY_WEIGHTS[rarity]
		if pick <= 0.0:
			return rarity
	return Economy.Rarity.COMMON


func _random_troop_of(rarity: int) -> String:
	var pool := []
	for id in TROOP_ORDER:
		if TROOPS[id].rarity == rarity:
			pool.append(id)
	# No troop of that rarity (admin edits): fall back to the next rarity down.
	if pool.is_empty():
		return _random_troop_of(rarity - 1) if rarity > 0 else TROOP_ORDER.pick_random()
	return pool.pick_random()


func _apply_loot(loot: Dictionary) -> void:
	for id in loot.get("cards", {}):
		add_cards(id, loot["cards"][id])
	gold += loot.get("gold", 0)
	gems += loot.get("gems", 0)


# --- Patrol ---------------------------------------------------------------------------

func patrol_rate() -> float:
	return Economy.patrol_rate(levels_cleared())


func patrol_capacity() -> int:
	return floori(patrol_rate() * Economy.PATROL_MAX_HOURS)


func patrol_stored() -> int:
	var hours := maxf(0.0, (now() - patrol_last_claim) / 3600.0)
	return mini(floori(patrol_rate() * hours), patrol_capacity())


## Blueprints waiting at the patrol (same hours and cap as its gold).
func patrol_blueprints() -> int:
	var hours := minf(maxf(0.0, (now() - patrol_last_claim) / 3600.0), float(Economy.PATROL_MAX_HOURS))
	return floori(HeroCat.PATROL_BLUEPRINTS_PER_HOUR * hours)

func claim_patrol() -> int:
	var amount := patrol_stored()
	_grant_blueprints(patrol_blueprints())
	gold += amount
	patrol_last_claim = now()
	if amount > 0:
		track("patrol")
	_commit()
	return amount


func quick_patrol_free_left() -> int:
	_refresh_patrol_day()
	return patrol_quick_left


func can_quick_patrol() -> bool:
	return quick_patrol_free_left() > 0 or gems >= Economy.PATROL_QUICK_GEMS


func quick_patrol() -> int:
	if not can_quick_patrol():
		return 0
	if patrol_quick_left > 0:
		patrol_quick_left -= 1
	else:
		gems -= Economy.PATROL_QUICK_GEMS
	var amount := floori(patrol_rate() * Economy.PATROL_QUICK_HOURS)
	_grant_blueprints(floori(HeroCat.PATROL_BLUEPRINTS_PER_HOUR * Economy.PATROL_QUICK_HOURS))
	gold += amount
	track("patrol")
	_commit()
	return amount


func _refresh_patrol_day() -> void:
	var day := today()
	if day != patrol_quick_day:
		patrol_quick_day = day
		patrol_quick_left = Economy.PATROL_QUICK_FREE


# --- Battle results -------------------------------------------------------------------

## Pays out a finished battle. Returns what was granted, for the end-of-battle panel:
## {"gold", "gems", "cards": {id: n}, "first_clear", "gift", "new": [ids unlocked now]}.
func grant_battle_rewards(won: bool, stars: int, waves_cleared: int) -> Dictionary:
	var reward := {"gold": 0, "gems": 0, "blueprints": {}, "cards": {}, "first_clear": false, "gift": "", "new": []}
	if not won:
		reward["gold"] = Economy.loss_gold(waves_cleared)
		gold += reward["gold"]
		if waves_cleared > 0:
			reward["blueprints"] = _grant_blueprints(HeroCat.LOSS_BLUEPRINTS)
		_commit()
		return reward
	track("win")
	var index := current_level
	var first_clear := not level_stars.has(index)
	var gold_won := Economy.win_gold(index, stars)
	if first_clear:
		gold_won = roundi(gold_won * Economy.FIRST_CLEAR_GOLD_MULT)
		reward["first_clear"] = true
		var gift: String = Economy.FIRST_CLEAR_GIFT.get(index, "")
		if gift != "":
			reward["gift"] = gift
			reward["cards"][gift] = 1
	if stars == 3 and stars_for(index) < 3:
		reward["gems"] = Economy.FIRST_THREE_STAR_GEMS
	reward["gold"] = gold_won
	var plans := floori(HeroCat.WIN_BLUEPRINTS + HeroCat.WIN_BLUEPRINTS_PER_LEVEL * index)
	if is_boss_level(index):
		plans += HeroCat.BOSS_BLUEPRINTS
	reward["blueprints"] = _grant_blueprints(plans * (2 if first_clear else 1))
	var chest: Dictionary = Economy.CHESTS["victory"]
	var chest_cards: Dictionary = _roll_cards(chest["cards"] + (1 if stars == 3 else 0), int(chest.get("min_rare", 0)), false)["cards"]
	for id in chest_cards:
		reward["cards"][id] = reward["cards"].get(id, 0) + chest_cards[id]
	level_stars[index] = maxi(stars_for(index), stars)
	unlocked_levels = maxi(unlocked_levels, mini(index + 2, LEVELS.size()))
	for id in reward["cards"]:
		if not is_unlocked(id):
			reward["new"].append(id)
	_apply_loot(reward)
	if not reward["cards"].is_empty() and victory_chest_waits():
		_queue_victory_chest(reward["cards"], reward["new"])
	_commit()
	return reward

## Adds a won battle's cards to the chest that opens in the lobby. Battles chained with
## Màn tiếp / Chơi lại add up into one chest. Saved, so quitting before the lobby keeps it.
func _queue_victory_chest(cards: Dictionary, fresh: Array) -> void:
	var all_cards: Dictionary = pending_chest.get("cards", {}).duplicate()
	for id in cards:
		all_cards[id] = int(all_cards.get(id, 0)) + int(cards[id])
	var all_new: Array = pending_chest.get("new", []).duplicate()
	for id in fresh:
		if not all_new.has(id):
			all_new.append(id)
	pending_chest = {"cards": all_cards, "new": all_new}


# --- Troop summon (bottom tab "Triệu hồi") ---------------------------------------------

func summon_free_ready() -> bool:
	return summon_free_day != today()

func summon_cost(count: int) -> int:
	if count == 1 and summon_free_ready():
		return 0
	return HeroCat.SUMMON_COST[count]

func can_summon(count: int) -> bool:
	return gems >= summon_cost(count)

func summon_pity_left() -> int:
	return HeroCat.SUMMON_PITY - summon_pity

## Pays for and rolls `count` pulls (1 or 10). Each result is a troop card:
## {"type": "card", "id", "rarity", "new"}. A x10 holds at least one epic. [] if refused.
func summon(count: int) -> Array:
	if not can_summon(count):
		return []
	var cost := summon_cost(count)
	if count == 1 and cost == 0:
		summon_free_day = today()
	gems -= cost
	var results := []
	for i in count:
		# A x10 with no epic yet makes its last pull at least epic. The rarity is raised
		# before that card is given, so nothing granted ever has to be taken back.
		var floor_rarity := 2 if count == 10 and i == count - 1 and results.all(func(r): return r["rarity"] < 2) else 0
		results.append(_summon_one(floor_rarity))
	track("summon", count)
	_commit()
	return results

func _summon_one(floor_rarity := 0) -> Dictionary:
	summon_pity += 1
	summon_total += 1
	var rarity := 3
	if summon_pity < HeroCat.SUMMON_PITY:
		var roll := randf() * 100.0
		rarity = 0
		for r in HeroCat.SUMMON_RARITY.size():
			roll -= HeroCat.SUMMON_RARITY[r]
			if roll < 0.0:
				rarity = r
				break
	return _summon_card(maxi(rarity, floor_rarity))

## The world on today's summon banner (Cats.WORLDS).
func featured_world() -> String:
	return Cats.featured_world(today())

func _summon_card(rarity: int) -> Dictionary:
	var id := _random_troop_of(rarity)
	if randf() < FEATURED_SHARE:
		for featured in Cats.world_versions(featured_world()):
			if TROOPS[featured].rarity == rarity:
				id = featured
	var real: int = TROOPS[id].rarity
	if real >= 3:
		summon_pity = 0
	var fresh: bool = not troops[id]["unlocked"]
	add_cards(id, 1)
	return {"type": "card", "id": id, "rarity": real, "new": fresh}

# --- Rewards ----------------------------------------------------------------------------

## Grants a Meta reward dictionary. Returns what was given, for display:
## {"gold", "gems", "blueprints": {slot: n}, "cards": {troop: n}, "new": [troops], "items": [ids]}.
## Reward keys: gold, gems, blueprints (n, random slots), cards (random troop cards), item (rarity).
func grant(reward: Dictionary) -> Dictionary:
	var got := {"gold": int(reward.get("gold", 0)), "gems": int(reward.get("gems", 0)),
		"cards": {}, "new": [], "items": []}
	gold += got["gold"]
	gems += got["gems"]
	if reward.has("cards"):
		var before := {}
		for id in TROOP_ORDER:
			before[id] = troops[id]["unlocked"]
		var rolled: Dictionary = _roll_cards(int(reward["cards"]), 0, false)
		got["cards"] = rolled["cards"]
		_apply_loot(rolled)
		for id in got["cards"]:
			if troops[id]["unlocked"] and not before[id]:
				got["new"].append(id)
	if reward.has("blueprints"):
		got["blueprints"] = _grant_blueprints(int(reward["blueprints"]))
	if reward.has("item"):
		# {"item": rarity}: a random hero-cat item of that rarity.
		var id := HeroCat.random_of_rarity(int(reward["item"]))
		HeroCat.add_item(hero_cat, id)
		got["items"].append(id)
	_commit()
	return got

# --- 7-day login ------------------------------------------------------------------------

func login_can_claim() -> bool:
	return login_day != today()


## Gifts shown as claimed: a finished cycle starts over once the next day's gift is ready.
func login_progress() -> int:
	return 0 if login_claimed >= Meta.LOGIN_REWARDS.size() and login_can_claim() else login_claimed


func claim_login() -> Dictionary:
	if not login_can_claim():
		return {}
	if login_claimed >= Meta.LOGIN_REWARDS.size():
		login_claimed = 0
	var got := grant(Meta.LOGIN_REWARDS[login_claimed])
	login_claimed += 1
	login_day = today()
	if login_claimed == Meta.LOGIN_REWARDS.size():
		login_cycles += 1
	_commit()
	return got


# --- Daily quests -----------------------------------------------------------------------

func _refresh_quests() -> void:
	var day := today()
	if day != quest_day:
		quest_day = day
		quest_progress = {"login": 1}
		quest_claimed = []
		quest_milestones = []


## Counts progress towards a daily quest. The caller saves (it always commits anyway).
func track(id: String, amount := 1) -> void:
	_refresh_quests()
	quest_progress[id] = int(quest_progress.get(id, 0)) + amount


func quest_count(id: String) -> int:
	_refresh_quests()
	return mini(int(quest_progress.get(id, 0)), Meta.quest(id)["goal"])


func quest_done(id: String) -> bool:
	return quest_count(id) >= Meta.quest(id)["goal"]


func quest_is_claimed(id: String) -> bool:
	_refresh_quests()
	return quest_claimed.has(id)


func claim_quest(id: String) -> Dictionary:
	if not quest_done(id) or quest_is_claimed(id):
		return {}
	quest_claimed.append(id)
	var got := grant(Meta.quest(id)["reward"])
	_commit()
	return got


func quest_points() -> int:
	_refresh_quests()
	return quest_claimed.size() * Meta.QUEST_POINTS


func milestone_ready(index: int) -> bool:
	return quest_points() >= Meta.QUEST_MILESTONES[index]["points"] and not quest_milestones.has(index)


func milestone_claimed(index: int) -> bool:
	_refresh_quests()
	return quest_milestones.has(index)


func claim_milestone(index: int) -> Dictionary:
	if not milestone_ready(index):
		return {}
	quest_milestones.append(index)
	var got := grant(Meta.QUEST_MILESTONES[index]["reward"])
	_commit()
	return got


# --- Profile ----------------------------------------------------------------------------

func avatar_unlocked(value: String) -> bool:
	return value.is_valid_int() and levels_cleared() >= Meta.avatar_need(int(value))


func set_avatar(value: String) -> void:
	if avatar_unlocked(value):
		avatar = value
		_commit()


func frame_unlocked(id: String) -> bool:
	match id:
		"silver":
			return levels_cleared() >= 3
		"gold":
			return login_cycles >= 1
		"royal":
			# Owns a legendary hero-cat item.
			for uid in hero_cat.get("bag", {}):
				if HeroCat.def(hero_cat, uid).get("rarity", 0) >= 3:
					return true
			return false
	return id == "wood"


func set_frame(id: String) -> void:
	if frame_unlocked(id):
		frame = id
		_commit()


func set_player_name(text: String) -> void:
	var clean := text.strip_edges().left(16)
	if clean != "":
		player_name = clean
		_commit()


# --- Alerts for the nav bar -----------------------------------------------------------

func any_troop_improvable() -> bool:
	for id in TROOP_ORDER:
		if can_improve(id):
			return true
	return false


func patrol_alert() -> bool:
	return patrol_stored() >= patrol_capacity() / 2.0


## Something to do on the hero cat page: an affordable level-up on a worn item, or a fuse.
func hero_alert() -> bool:
	for slot in HeroCat.SLOTS:
		var uid := HeroCat.equipped_uid(hero_cat, slot)
		if uid != "" and hero_cat_can_upgrade(uid):
			return true
	return not hero_cat_fusable().is_empty()


func quest_alert() -> bool:
	for q in Meta.QUESTS:
		if quest_done(q["id"]) and not quest_is_claimed(q["id"]):
			return true
	for i in Meta.QUEST_MILESTONES.size():
		if milestone_ready(i):
			return true
	return false


# --- Save -----------------------------------------------------------------------------

func reset_progress() -> void:
	var kept := {}
	for key in SETTINGS:
		kept[key] = get(key)
	_reset()
	for key in kept:
		set(key, kept[key])
	current_level = 0
	_commit()


func _reset() -> void:
	pending_chest = {}
	gold = 0
	gems = Economy.START_GEMS
	unlocked_levels = 1
	level_stars = {}
	troops = {}
	for id in TROOP_ORDER:
		troops[id] = {"unlocked": id in STARTER_TROOPS, "level": 1, "stars": 1, "cards": 0}
	castle_level = 1
	team = STARTER_TROOPS.duplicate()
	workshop = {}
	free_chest_at = now()
	gold_chest_pity = 0
	shop_gold_day = -1
	patrol_last_claim = now()
	patrol_quick_left = Economy.PATROL_QUICK_FREE
	patrol_quick_day = today()
	cheated = false
	fast_chest = false
	blueprints = {}
	for slot in HeroCat.SLOTS:
		blueprints[slot] = 0
	summon_pity = 0
	summon_free_day = -1
	summon_total = 0
	login_claimed = 0
	login_day = -1
	login_cycles = 0
	quest_day = -1
	quest_progress = {}
	quest_claimed = []
	quest_milestones = []
	player_name = "Chỉ Huy"
	avatar = "1"
	frame = "wood"
	tutorial_done = false
	seen_tiles = []
	hero_cat = HeroCat.new_state()


func set_ui_skin(skin: String) -> void:
	ui_skin = skin
	_commit()


func finish_tutorial() -> void:
	tutorial_done = true
	_commit()


func mark_tiles_seen(kinds: Array) -> void:
	for kind in kinds:
		if not seen_tiles.has(kind):
			seen_tiles.append(kind)
	_commit()


func set_sound(on: bool) -> void:
	sound_on = on
	_commit()


func set_music(on: bool) -> void:
	music_on = on
	_commit()

func set_fast_chest(on: bool) -> void:
	fast_chest = on
	_commit()

## Sets any setting in SETTINGS and saves (the settings sheet uses this for every row).
func set_setting(key: String, value) -> void:
	if not key in SETTINGS:
		return
	set(key, value)
	_commit()

## A short buzz on phones, when the player allows it.
func vibrate(ms := 40) -> void:
	if vibration_on and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


## Saves a change made from the admin panel (marks the save as cheated).
func commit_cheat() -> void:
	cheated = true
	_commit()


# --- Hero cat equipment (HeroCat.gd) ----------------------------------------------------

func hero_cat_stats() -> Dictionary:
	return HeroCat.total_stats(hero_cat)


## Wears `uid` in its slot; what was there goes back to the bag.
func hero_cat_equip(uid: String) -> void:
	var d := HeroCat.def(hero_cat, uid)
	if d.is_empty():
		return
	hero_cat["equipped"][d["slot"]] = uid
	_commit()


func hero_cat_can_upgrade(uid: String) -> bool:
	var cost := HeroCat.upgrade_cost(hero_cat, uid)
	return cost >= 0 and blueprints.get(HeroCat.def(hero_cat, uid)["slot"], 0) >= cost

## Levels an item with Blueprints of its slot.
func hero_cat_upgrade(uid: String) -> bool:
	if not hero_cat_can_upgrade(uid):
		return false
	var slot: String = HeroCat.def(hero_cat, uid)["slot"]
	blueprints[slot] -= HeroCat.upgrade_cost(hero_cat, uid)
	hero_cat["bag"][uid]["level"] += 1
	track("upgrade")
	_commit()
	return true

## Every fifth level (5, 10, 15) is a boss level: it pays Blueprints.
func is_boss_level(index: int) -> bool:
	return (index + 1) % 5 == 0

## Adds `count` Blueprints to random slots. Returns {slot: n} as given.
func _grant_blueprints(count: int) -> Dictionary:
	var got := {}
	for i in count:
		var slot: String = HeroCat.SLOTS.pick_random()
		blueprints[slot] = blueprints.get(slot, 0) + 1
		got[slot] = got.get(slot, 0) + 1
	return got

## Item ids with enough copies to fuse (FUSE_COUNT, a worn one counts) and a higher rarity.
func hero_cat_fusable() -> Array:
	# One pass counts copies of every id (copies() per id rescanned the bag each time).
	var counts := {}
	var order := []
	for uid in hero_cat["bag"]:
		var id: String = hero_cat["bag"][uid]["id"]
		if not HeroCat.ITEMS.has(id):
			continue
		if not counts.has(id):
			order.append(id)
		counts[id] = int(counts.get(id, 0)) + 1
	var out := []
	for id in order:
		if counts[id] >= HeroCat.FUSE_COUNT and HeroCat.fuse_target(id) != "":
			out.append(id)
	return out

## Fuses three copies of `id` into the next rarity. The new item keeps the best level and
## takes over a worn copy's slot. Returns the new uid, or "".
func hero_cat_fuse(id: String) -> String:
	if not hero_cat_fusable().has(id):
		return ""
	var target := HeroCat.fuse_target(id)
	var used: Array = HeroCat.copies(hero_cat, id).slice(-HeroCat.FUSE_COUNT)
	var level := 1
	var worn := false
	for uid in used:
		level = maxi(level, int(hero_cat["bag"][uid]["level"]))
		worn = worn or HeroCat.is_equipped(hero_cat, uid)
	for uid in used:
		hero_cat["bag"].erase(uid)
	var new_uid := HeroCat.add_item(hero_cat, target)
	hero_cat["bag"][new_uid]["level"] = mini(level, HeroCat.level_cap(hero_cat, new_uid))
	if worn:
		hero_cat["equipped"][HeroCat.ITEMS[target]["slot"]] = new_uid
	_commit()
	return new_uid

## Breaks an unworn item into Blueprints of its slot. Returns how many, or 0 if refused.
func hero_cat_salvage(uid: String) -> int:
	if HeroCat.is_equipped(hero_cat, uid) or HeroCat.item(hero_cat, uid).is_empty():
		return 0
	var plans := HeroCat.salvage_value(hero_cat, uid)
	var d := HeroCat.def(hero_cat, uid)
	blueprints[d["slot"]] = blueprints.get(d["slot"], 0) + plans
	hero_cat["bag"].erase(uid)
	_commit()
	return plans

## One-time refund for a save that still has the old Tướng heroes, counted in Forge Stone
## units (5 per shard, 1 per 40 gold spent on levels) and paid as Blueprints by from_dict.
func _legacy_hero_refund(list: Dictionary) -> int:
	var stones := 0
	var star_shards := [10, 20, 40, 80]
	for id in list:
		var h: Dictionary = list[id]
		stones += 5 * int(h.get("shards", 0))
		for lv in range(1, int(h.get("level", 1))):
			stones += roundi(200.0 * pow(1.22, lv - 1)) / 40
		for st in range(1, int(h.get("stars", 1))):
			stones += 5 * star_shards[mini(st - 1, 3)]
	return stones

func _commit() -> void:
	changed.emit()
	if persist:
		_save()


## The whole profile as plain data (what the save file holds).
func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"settings": {"fast_chest": fast_chest, "ui_skin": ui_skin, "sound": sound_on, "music": music_on,
			"music_volume": music_volume, "sound_volume": sound_volume, "vibration": vibration_on,
			"battle_speed": battle_speed, "crit_text": crit_text_on, "confirm_leave": confirm_leave},
		"cheated": cheated,
		"gold": gold,
		"gems": gems,
		"levels": {"unlocked": unlocked_levels, "stars": level_stars},
		"troops": troops,
		"castle": {"level": castle_level},
		"team": battle_team(),
		"workshop": workshop,
		"shop": {"free_chest_at": free_chest_at, "gold_chest_pity": gold_chest_pity, "daily_gold_day": shop_gold_day},
		"patrol": {"last_claim": patrol_last_claim, "quick_left": patrol_quick_left, "quick_day": patrol_quick_day},
		"blueprints": blueprints,
		"summon": {"pity": summon_pity, "free_day": summon_free_day, "total": summon_total, "kind": "equipment"},
		"login": {"claimed": login_claimed, "day": login_day, "cycles": login_cycles},
		"quests": {"day": quest_day, "progress": quest_progress, "claimed": quest_claimed, "milestones": quest_milestones},
		"profile": {"name": player_name, "avatar": avatar, "frame": frame},
		"tutorial": {"done": tutorial_done, "seen_tiles": seen_tiles},
		"pending_chest": pending_chest,
		"hero_cat": hero_cat,
	}.duplicate(true)


## Replaces the whole profile (used by admin snapshots and the simulator).
func from_dict(data: Dictionary) -> void:
	_reset()
	gold = int(data.get("gold", 0))
	gems = int(data.get("gems", Economy.START_GEMS))
	cheated = bool(data.get("cheated", false))
	fast_chest = bool(data.get("settings", {}).get("fast_chest", false))
	ui_skin = str(data.get("settings", {}).get("ui_skin", "cozy"))
	sound_on = bool(data.get("settings", {}).get("sound", true))
	music_on = bool(data.get("settings", {}).get("music", true))
	var settings: Dictionary = data.get("settings", {})
	music_volume = clampf(float(settings.get("music_volume", 0.8)), 0.0, 1.0)
	sound_volume = clampf(float(settings.get("sound_volume", 1.0)), 0.0, 1.0)
	vibration_on = bool(settings.get("vibration", true))
	battle_speed = clampi(int(settings.get("battle_speed", 1)), 1, 2)
	crit_text_on = bool(settings.get("crit_text", true))
	confirm_leave = bool(settings.get("confirm_leave", true))
	var levels: Dictionary = data.get("levels", {})
	unlocked_levels = clampi(int(levels.get("unlocked", 1)), 1, LEVELS.size())
	# JSON turns int keys into strings.
	for key in levels.get("stars", {}):
		level_stars[int(key)] = int(levels["stars"][key])
	var saved_troops: Dictionary = data.get("troops", {})
	for id in TROOP_ORDER:
		if saved_troops.has(id):
			var t: Dictionary = saved_troops[id]
			# Keep stars and levels inside today's rules (an admin may have changed them).
			var stars := clampi(int(t.get("stars", 1)), 1, Economy.MAX_STARS)
			troops[id] = {
				"unlocked": bool(t.get("unlocked", false)),
				"level": clampi(int(t.get("level", 1)), 1, stars * Economy.LEVELS_PER_STAR),
				"stars": stars,
				"cards": maxi(0, int(t.get("cards", 0))),
			}
	castle_level = clampi(int(data.get("castle", {}).get("level", 1)), 1, castle_max_level())
	# Saves from before teams existed get the strongest troops they own.
	team = []
	for id in data.get("team", []):
		# Saves from before the cat soldiers name human troops; drop those.
		if str(id) in TROOP_ORDER and troops[str(id)]["unlocked"]:
			team.append(str(id))
	if team.is_empty():
		team = auto_team()
	for id in data.get("workshop", {}):
		if Economy.WORKSHOP.has(id):
			workshop[id] = int(data["workshop"][id])
	var shop: Dictionary = data.get("shop", {})
	free_chest_at = int(shop.get("free_chest_at", now()))
	gold_chest_pity = int(shop.get("gold_chest_pity", 0))
	shop_gold_day = int(shop.get("daily_gold_day", -1))
	var patrol: Dictionary = data.get("patrol", {})
	# A clock set backwards must not create negative time; clamp to now.
	patrol_last_claim = mini(int(patrol.get("last_claim", now())), now())
	patrol_quick_left = int(patrol.get("quick_left", Economy.PATROL_QUICK_FREE))
	patrol_quick_day = int(patrol.get("quick_day", 0))
	var saved_blueprints: Dictionary = data.get("blueprints", {})
	for slot in HeroCat.SLOTS:
		blueprints[slot] = int(saved_blueprints.get(slot, 0))
	# Saves from the Forge Stone era: the stones become Blueprints, spread over the slots.
	var old_stones := int(data.get("forge_stones", 0))
	var summon_data: Dictionary = data.get("summon", {})
	if summon_data.get("kind", "") == "equipment":
		summon_pity = int(summon_data.get("pity", 0))
		summon_free_day = int(summon_data.get("free_day", -1))
		summon_total = int(summon_data.get("total", 0))
	elif data.has("heroes"):
		# Saves from the old hero (Tướng) system: pay back what was put into it, once.
		old_stones += _legacy_hero_refund(data["heroes"].get("list", {}))
	var refund := old_stones / HeroCat.STONES_PER_BLUEPRINT
	for i in HeroCat.SLOTS.size():
		blueprints[HeroCat.SLOTS[i]] += refund / HeroCat.SLOTS.size() + (1 if i < refund % HeroCat.SLOTS.size() else 0)
	var login: Dictionary = data.get("login", {})
	login_claimed = clampi(int(login.get("claimed", 0)), 0, Meta.LOGIN_REWARDS.size())
	login_day = int(login.get("day", -1))
	login_cycles = int(login.get("cycles", 0))
	var quests: Dictionary = data.get("quests", {})
	quest_day = int(quests.get("day", -1))
	quest_progress = {}
	var progress: Dictionary = quests.get("progress", {})
	for key in progress:
		quest_progress[str(key)] = int(progress[key])
	quest_claimed = []
	for id in quests.get("claimed", []):
		quest_claimed.append(str(id))
	quest_milestones = []
	for index in quests.get("milestones", []):
		quest_milestones.append(int(index))
	var profile: Dictionary = data.get("profile", {})
	player_name = str(profile.get("name", "Chỉ Huy"))
	avatar = str(profile.get("avatar", "1"))
	frame = str(profile.get("frame", "wood"))
	var saved_chest = data.get("pending_chest", {})
	pending_chest = {}
	var saved_cards = saved_chest.get("cards", {}) if saved_chest is Dictionary else {}
	if saved_cards is Dictionary:
		var kept := {}
		for id in saved_cards:
			if TROOPS.has(str(id)):
				kept[str(id)] = int(saved_cards[id])
		if not kept.is_empty():
			pending_chest = {"cards": kept, "new": Array(saved_chest.get("new", [])).filter(func(id): return kept.has(str(id)))}
	var tutorial: Dictionary = data.get("tutorial", {})
	# Saves from before the tutorial existed belong to players who already know the game.
	tutorial_done = bool(tutorial.get("done", data.has("levels") and int(data.get("levels", {}).get("unlocked", 1)) > 1))
	seen_tiles = []
	for kind in tutorial.get("seen_tiles", []):
		seen_tiles.append(str(kind))
	var saved_cat = data.get("hero_cat", null)
	if saved_cat is Dictionary and saved_cat.has("bag") and saved_cat.has("equipped"):
		hero_cat = HeroCat.restore_state(saved_cat)


func _save() -> void:
	var data := to_dict()
	# Write to a temp file first so a crash mid-write can't corrupt the save.
	var temp_path := SAVE_PATH + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	DirAccess.rename_absolute(temp_path, SAVE_PATH)


func _load() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary:
		push_warning("Save file unreadable, starting fresh.")
		return false
	from_dict(data)
	return true


func _migrate_legacy() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(LEGACY_SAVE_PATH) != OK:
		return
	unlocked_levels = clampi(cfg.get_value("progress", "unlocked", 1), 1, LEVELS.size())
	var stars: Dictionary = cfg.get_value("progress", "best_stars", {})
	for key in stars:
		level_stars[int(key)] = int(stars[key])
		# Levels cleared before rewards existed still hand out their unlock gift.
		var gift: String = Economy.FIRST_CLEAR_GIFT.get(int(key), "")
		if gift != "":
			add_cards(gift, 1)
	if persist:
		_save()
