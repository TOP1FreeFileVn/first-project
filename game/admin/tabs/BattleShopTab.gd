extends "res://game/admin/tabs/AdminTab.gd"

# The between-wave shop: slots, prices by rarity, reroll, refund, tier-2 offers and the
# rarity odds table by wave, plus a 1,000-shop simulation for a chosen wave with the
# player's current team (same roll code as the battle).

const ShopRoller = preload("res://game/battle/ShopRoller.gd")
const SIM_COUNT := 1000
# [key, label, min, max, step, is_int]
const FIELDS := [
	["slots", "Số ô trong shop", 1, 8, 1, true],
	["reroll_cost", "Giá đổi shop (xu)", 0, 20, 1, true],
	["free_rerolls", "Lượt đổi miễn phí mỗi lượt nghỉ", 0, 10, 1, true],
	["reroll_step", "Giá đổi tăng thêm mỗi lần", 0, 10, 1, true],
	["sell_refund", "Bán gear: hoàn bao nhiêu phần giá trị", 0, 1, 0.05, false],
	["tier2_from_wave", "Gear bậc 2 xuất hiện từ đợt", 1, 20, 1, true],
	["tier2_chance", "Mỗi ô: xác suất là bậc 2", 0, 1, 0.05, false],
	["tier2_price_mult", "Giá bậc 2 = giá bậc 1 ×", 1, 10, 0.1, false],
]

var _sim_wave := 1
var _sim_text := ""


func build() -> void:
	var spec: Dictionary = Economy.BATTLE_SHOP
	var box := section("Shop giữa các đợt")
	note("Thu nhập mỗi đợt và lãi là 2 công thức 'round_income' và 'interest' ở tab Công thức. Túi xu tối đa nằm ở bảng Thành.", box)
	for f in FIELDS:
		var key: String = f[0]
		number(box, f[1], float(spec.get(key, 0)), f[2], f[3], f[4], f[5], false, func(v): _set_value(key, v))
	var income := []
	for wave in range(1, 9):
		income.append("đợt %d: +%d" % [wave, Economy.round_income(wave, 0)])
	note("Thu nhập (chưa tính Két xu, lãi): " + " · ".join(income), box, UiKit.GOLD_TEXT)

	var prices := section("Giá gear bậc 1 theo độ hiếm (xu)")
	var price_list: Array = spec.get("prices", [2, 3, 4, 6])
	for r in mini(price_list.size(), Economy.RARITY_NAMES.size()):
		number(prices, Economy.RARITY_NAMES[r], price_list[r], 0, 100, 1, true, false, func(v):
			var updated: Array = Economy.BATTLE_SHOP.get("prices", []).duplicate()
			updated[r] = v
			_set_value("prices", updated))
	note("Bán hoàn: giá × 2^(bậc−1) × phần hoàn, tối thiểu 1.", prices)

	_build_odds()
	_build_sim()


func _build_odds() -> void:
	var box := section("Tỉ lệ độ hiếm theo đợt")
	note("Mỗi dòng áp dụng từ đợt 'Từ' trở đi. Là trọng số tương đối; độ hiếm mà đội không có sẽ bị bỏ qua.", box)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	grid.add_child(UiKit.label("Từ đợt", 14, UiKit.GOLD_TEXT))
	for r in Economy.RARITY_NAMES.size():
		grid.add_child(UiKit.label(Economy.RARITY_NAMES[r], 14, Economy.RARITY_COLORS[r]))
	grid.add_child(UiKit.label("", 14))
	var odds: Array = Economy.BATTLE_SHOP.get("odds", [])
	for i in odds.size():
		var row: Dictionary = odds[i]
		grid.add_child(cell(row["from"], func(v): _set_odds(i, "from", -1, maxi(1, v)), 90, true))
		for r in Economy.RARITY_NAMES.size():
			var weights: Array = row["weights"]
			grid.add_child(cell(weights[r] if r < weights.size() else 0.0, func(v): _set_odds(i, "weights", r, maxf(0.0, v)), 100))
		var remove := small_button("✕", func():
			var updated: Array = Economy.BATTLE_SHOP["odds"].duplicate(true)
			updated.remove_at(i)
			_set_value("odds", updated), true, 48)
		remove.disabled = odds.size() <= 1
		grid.add_child(remove)
	box.add_child(grid)
	box.add_child(small_button("+ THÊM DÒNG", func():
		var updated: Array = Economy.BATTLE_SHOP.get("odds", []).duplicate(true)
		var last: Dictionary = updated.back().duplicate(true) if not updated.is_empty() else {"from": 0, "weights": [100, 0, 0, 0]}
		last["from"] = int(last["from"]) + 2
		updated.append(last)
		_set_value("odds", updated), false, 220))


func _build_sim() -> void:
	var box := section("Mở thử %s shop" % UiKit.format_number(SIM_COUNT))
	var team := PlayerData.battle_team()
	var names := []
	for id in team:
		names.append(PlayerData.TROOPS[id].display_name)
	note("Đội hiện tại của hồ sơ: " + ", ".join(names), box)
	var picker := HFlowContainer.new()
	picker.add_theme_constant_override("h_separation", 6)
	for wave in range(1, 11):
		picker.add_child(small_button("Đợt %d" % wave, func():
			_sim_wave = wave
			_simulate(), wave == _sim_wave, 110))
	box.add_child(picker)
	if _sim_text != "":
		note(_sim_text, box, Color.WHITE)


# Rolls shops with the real code; nothing is bought.
func _simulate() -> void:
	var pool := []
	for id in PlayerData.battle_team():
		pool.append(PlayerData.TROOPS[id])
	var by_troop := {}
	var by_rarity := {}
	var tier2 := 0
	var shops_with_legend := 0
	var cost := 0
	var offers_total := 0
	for i in SIM_COUNT:
		var legend := false
		for offer in ShopRoller.roll(pool, _sim_wave):
			var rarity: int = PlayerData.rarity_of(offer["id"])
			by_troop[offer["id"]] = by_troop.get(offer["id"], 0) + 1
			by_rarity[rarity] = by_rarity.get(rarity, 0) + 1
			tier2 += 1 if offer["tier"] > 1 else 0
			legend = legend or rarity >= 3
			cost += offer["price"]
			offers_total += 1
		shops_with_legend += 1 if legend else 0
	var lines := ["Đợt %d · %s món" % [_sim_wave, UiKit.format_number(offers_total)]]
	for r in Economy.RARITY_NAMES.size():
		lines.append("%s: %.1f%%" % [Economy.RARITY_NAMES[r], 100.0 * by_rarity.get(r, 0) / maxf(offers_total, 1)])
	for id in PlayerData.battle_team():
		lines.append("%s: %.2f món/shop" % [PlayerData.TROOPS[id].display_name, by_troop.get(id, 0) / float(SIM_COUNT)])
	lines.append("Gear bậc 2: %.1f%% số món" % (100.0 * tier2 / maxf(offers_total, 1)))
	lines.append("Shop có ít nhất 1 Huyền thoại: %.1f%%" % (100.0 * shops_with_legend / SIM_COUNT))
	lines.append("Mua hết 1 shop: TB %.1f xu" % (cost / float(SIM_COUNT)))
	_sim_text = "\n".join(lines)
	rebuild()


func _set_value(key: String, v) -> void:
	var updated: Dictionary = Economy.BATTLE_SHOP.duplicate(true)
	updated[key] = v
	Balance.set_section("battle_shop", updated)


func _set_odds(index: int, key: String, rarity: int, v) -> void:
	var odds: Array = Economy.BATTLE_SHOP["odds"].duplicate(true)
	if key == "from":
		odds[index]["from"] = v
	else:
		var weights: Array = odds[index]["weights"]
		while weights.size() <= rarity:
			weights.append(0)
		weights[rarity] = v
	odds.sort_custom(func(a, b): return a["from"] < b["from"])
	_set_value("odds", odds)
