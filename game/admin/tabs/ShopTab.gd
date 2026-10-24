extends "res://game/admin/tabs/AdminTab.gd"

# Troop-card rarity weights (victory chest), every chest's contents and price, and a
# 1,000-chest simulation that shows what those numbers actually hand out (the player's
# save is not touched). Shop chests hold hero-cat equipment + Forge Stones; the victory
# chest after a won battle holds troop cards.

const HeroCat = preload("res://game/core/HeroCat.gd")
## Shop chests (equipment). min_rare is a rarity floor, min_count how many items get it.
const ITEM_FIELDS := [["items", "Số trang bị", 0, 50, 1], ["gold", "Giá vàng", 0, 1000000, 50], ["gems", "Giá kim cương", 0, 100000, 5],
	["min_rare", "Chắc chắn phẩm ≥ (0 Thường … 3 Huyền thoại)", 0, 3, 1], ["min_count", "… cho N món", 0, 50, 1]]
## The victory chest (troop cards).
const CARD_FIELDS := [["cards", "Số thẻ", 0, 500, 1], ["min_rare", "Chắc chắn ≥ N thẻ Hiếm", 0, 100, 1]]
const SIM_COUNT := 1000

var _sim_kind := "gold"
var _sim_text := ""


func build() -> void:
	var rarity := section("Tỉ lệ độ hiếm của thẻ (rương chiến thắng)")
	var weights: Array = Balance.section("rarity_weights")
	var total := 0.0
	for w in weights:
		total += w
	for i in mini(weights.size(), Economy.RARITY_NAMES.size()):
		number(rarity, "%s (%.1f%%)" % [Economy.RARITY_NAMES[i], 100.0 * weights[i] / maxf(total, 0.001)], weights[i], 0, 1000, 1, false, false, func(v):
			var updated: Array = Balance.section("rarity_weights").duplicate()
			updated[i] = v
			Balance.set_section("rarity_weights", updated))
	if weights.size() < Economy.RARITY_NAMES.size():
		rarity.add_child(small_button("+ THÊM %s" % Economy.RARITY_NAMES[weights.size()].to_upper(), func():
			var updated: Array = Balance.section("rarity_weights").duplicate()
			updated.append(0.4)
			Balance.set_section("rarity_weights", updated), false, 300))
	note("Là trọng số tương đối; % được tính tự động. Có thể nhập số lẻ (vd 0.4).", rarity)

	var chests: Dictionary = Balance.section("chests")
	for kind in chests:
		var spec: Dictionary = chests[kind]
		var cards: bool = spec.has("cards")
		var box := section(spec["name"] + ("  (thẻ lính, sau trận thắng)" if cards else "  (trang bị + bản vẽ)"))
		for f in (CARD_FIELDS if cards else ITEM_FIELDS):
			number(box, f[1], spec.get(f[0], 1 if f[0] == "min_count" else 0), f[2], f[3], f[4], true, false, func(v): _set_chest(kind, f[0], v))
		if not cards:
			number(box, "Bản vẽ tối thiểu", spec["blueprints"][0], 0, 100000, 1, true, false, func(v): _set_range(kind, "blueprints", 0, v))
			number(box, "Bản vẽ tối đa", spec["blueprints"][1], 0, 100000, 1, true, false, func(v): _set_range(kind, "blueprints", 1, v))
		number(box, "Vàng thưởng tối thiểu", spec["bonus_gold"][0], 0, 100000, 10, true, false, func(v): _set_bonus(kind, 0, v))
		number(box, "Vàng thưởng tối đa", spec["bonus_gold"][1], 0, 100000, 10, true, false, func(v): _set_bonus(kind, 1, v))

	var sim := section("Mở thử %s rương" % UiKit.format_number(SIM_COUNT))
	var kinds := HFlowContainer.new()
	kinds.add_theme_constant_override("h_separation", 6)
	for kind in chests:
		kinds.add_child(small_button(chests[kind]["name"], func():
			_sim_kind = kind
			rebuild(), kind == _sim_kind, 200))
	sim.add_child(kinds)
	sim.add_child(small_button("MỞ THỬ", _simulate, false, 200))
	if _sim_text != "":
		note(_sim_text, sim, Color.WHITE)


func _set_chest(kind: String, key: String, v) -> void:
	var updated: Dictionary = Balance.section("chests").duplicate(true)
	updated[kind][key] = v
	Balance.set_section("chests", updated)


func _set_bonus(kind: String, index: int, v) -> void:
	_set_range(kind, "bonus_gold", index, v)

# Sets one end of a [min, max] pair, keeping min <= max.
func _set_range(kind: String, key: String, index: int, v) -> void:
	var updated: Dictionary = Balance.section("chests").duplicate(true)
	updated[kind][key][index] = v
	if updated[kind][key][0] > updated[kind][key][1]:
		updated[kind][key][1 - index] = v
	Balance.set_section("chests", updated)


# Rolls chests with the real roll code but never applies the loot.
func _simulate() -> void:
	var spec: Dictionary = Balance.section("chests")[_sim_kind]
	if not spec.has("cards"):
		_simulate_items(spec)
		return
	var by_rarity := []
	by_rarity.resize(Economy.RARITY_NAMES.size())
	by_rarity.fill(0)
	var by_troop := {}
	var cards_total := 0
	var pity := 0
	for i in SIM_COUNT:
		var epic := false
		if _sim_kind == "gold":
			pity += 1
			if pity >= Economy.GOLD_CHEST_PITY:
				epic = true
				pity = 0
		var cards: Dictionary = PlayerData._roll_cards(spec["cards"], spec["min_rare"], epic)["cards"]
		for id in cards:
			by_troop[id] = by_troop.get(id, 0) + cards[id]
			by_rarity[PlayerData.rarity_of(id)] += cards[id]
			cards_total += cards[id]
	var lines := ["%s × %d: %s thẻ" % [spec["name"], SIM_COUNT, UiKit.format_number(cards_total)]]
	for r in by_rarity.size():
		lines.append("%s: %.1f%%" % [Economy.RARITY_NAMES[r], 100.0 * by_rarity[r] / maxf(cards_total, 1)])
	for id in PlayerData.TROOP_ORDER:
		lines.append("%s: TB %.2f thẻ/rương" % [PlayerData.TROOPS[id].display_name, by_troop.get(id, 0) / float(SIM_COUNT)])
	var cost := "%s vàng" % UiKit.format_number(spec["gold"]) if spec["gold"] > 0 else ("%s kim cương" % spec["gems"] if spec["gems"] > 0 else "miễn phí")
	lines.append("Giá mỗi rương: %s" % cost)
	_sim_text = "\n".join(lines)
	rebuild()

# Equipment chests: rarity mix (after the min_rare/min_count guarantee) and Blueprints.
func _simulate_items(spec: Dictionary) -> void:
	var by_rarity := [0, 0, 0, 0]
	var items_total := 0
	var plans_total := 0
	for i in SIM_COUNT:
		var rarities := []
		for n in int(spec.get("items", 1)):
			rarities.append(PlayerData._roll_gear_rarity())
		rarities.sort()
		for n in mini(int(spec.get("min_count", 1)), rarities.size()):
			rarities[n] = maxi(rarities[n], int(spec.get("min_rare", 0)))
		for r in rarities:
			by_rarity[r] += 1
			items_total += 1
		plans_total += randi_range(int(spec["blueprints"][0]), int(spec["blueprints"][1]))
	var lines := ["%s × %d: %s trang bị, TB %.1f bản vẽ/rương" % [spec["name"], SIM_COUNT, UiKit.format_number(items_total), plans_total / float(SIM_COUNT)]]
	for r in by_rarity.size():
		lines.append("%s: %.1f%%" % [Economy.RARITY_NAMES[r], 100.0 * by_rarity[r] / maxf(items_total, 1)])
	var cost := "%s vàng" % UiKit.format_number(spec["gold"]) if spec["gold"] > 0 else ("%s kim cương" % spec["gems"] if spec["gems"] > 0 else "miễn phí")
	lines.append("Giá mỗi rương: %s" % cost)
	_sim_text = "
".join(lines)
	rebuild()
