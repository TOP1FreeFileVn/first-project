extends "res://game/admin/tabs/AdminTab.gd"

# Card rarity weights, every chest's contents and price, and a 1,000-chest simulation that
# shows what those numbers actually hand out (the player's save is not touched).

const FIELDS := [["cards", "Số thẻ", 0, 500, 1], ["gold", "Giá vàng", 0, 1000000, 50], ["gems", "Giá kim cương", 0, 100000, 5], ["min_rare", "Chắc chắn ≥ N thẻ Hiếm", 0, 100, 1]]
const SIM_COUNT := 1000

var _sim_kind := "gold"
var _sim_text := ""


func build() -> void:
	var rarity := section("Tỉ lệ độ hiếm của thẻ")
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
		var box := section(spec["name"] + ("  (thưởng sau trận thắng)" if kind == "victory" else ""))
		for f in FIELDS:
			if kind == "victory" and f[0] in ["gold", "gems"]:
				continue
			number(box, f[1], spec[f[0]], f[2], f[3], f[4], true, false, func(v): _set_chest(kind, f[0], v))
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
	var updated: Dictionary = Balance.section("chests").duplicate(true)
	updated[kind]["bonus_gold"][index] = v
	if updated[kind]["bonus_gold"][0] > updated[kind]["bonus_gold"][1]:
		updated[kind]["bonus_gold"][1 - index] = v
	Balance.set_section("chests", updated)


# Rolls chests with the real card code but never applies the loot.
func _simulate() -> void:
	var spec: Dictionary = Balance.section("chests")[_sim_kind]
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
