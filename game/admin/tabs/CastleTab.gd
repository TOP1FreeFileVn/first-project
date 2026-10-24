extends "res://game/admin/tabs/AdminTab.gd"

# The castle level table (HP multiplier, max meat, open gear cells, price) edited cell by
# cell with a running gold total, and the workshop upgrades.

const COLUMNS := [["hp", "Máu x", false], ["meat", "Xu", true], ["cells", "Ô gear", true], ["team", "Ô đội", true], ["cost", "Giá", true]]
const MAX_TEAM := 4
const MAX_CELLS := 23


func build() -> void:
	var table_box := section("Bảng cấp thành")
	note("Máu x nhân với máu thành gốc của màn. Ô gear tối đa %d. Ô đội = số lính mang vào trận (1–%d). Giá = vàng để lên tới cấp đó." % [MAX_CELLS, MAX_TEAM], table_box)
	var castle: Array = Balance.section("castle")
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	for h in ["Cấp", "Máu x", "Xu", "Ô gear", "Ô đội", "Giá", "Tổng"]:
		grid.add_child(UiKit.label(h, 15, UiKit.GOLD_TEXT))
	var total := 0
	for i in castle.size():
		total += int(castle[i]["cost"])
		grid.add_child(UiKit.label(str(i + 1), 17))
		for col in COLUMNS:
			var key: String = col[0]
			grid.add_child(cell(castle[i].get(key, Economy.DEFAULT_TEAM_SLOTS), func(v): _set_castle(i, key, v), 84, col[2]))
		grid.add_child(UiKit.label(UiKit.format_number(total), 15, UiKit.INFO))
	table_box.add_child(grid)
	var rows := UiKit.hbox(8)
	rows.add_child(small_button("+ THÊM CẤP", func():
		var updated: Array = Balance.section("castle").duplicate(true)
		var last: Dictionary = updated.back().duplicate()
		last["cost"] = roundi(last["cost"] * 1.35)
		last["hp"] = snappedf(last["hp"] * 1.12, 0.01)
		updated.append(last)
		Balance.set_section("castle", updated), false, 200))
	var remove := small_button("− BỚT CẤP CUỐI", func():
		var updated: Array = Balance.section("castle").duplicate(true)
		updated.pop_back()
		Balance.set_section("castle", updated), true, 240)
	remove.disabled = castle.size() <= 1
	rows.add_child(remove)
	table_box.add_child(rows)

	var workshop: Dictionary = Balance.section("workshop")
	for id in Economy.WORKSHOP_ORDER:
		var spec: Dictionary = workshop[id]
		var box := section("Xưởng: %s" % spec["name"])
		note("Giá cấp n tính bằng công thức 'Giá nâng cấp Xưởng' với base và growth dưới đây. Hiệu ứng mỗi cấp = step.", box)
		number(box, "base (giá gốc)", spec["base"], 1, 100000, 10, false, false, func(v): _set_workshop(id, "base", v))
		number(box, "growth (hệ số tăng giá)", spec["growth"], 1, 10, 0.05, false, false, func(v): _set_workshop(id, "growth", v))
		number(box, "step (hiệu ứng mỗi cấp)", spec["step"], 0, 100, 1, true, false, func(v): _set_workshop(id, "step", v))
		number(box, "max (cấp tối đa)", spec["max"], 1, 50, 1, true, false, func(v): _set_workshop(id, "max", v))
		var prices := []
		for level in spec["max"]:
			prices.append(UiKit.format_number(Economy.workshop_cost(id, level)))
		note("Giá từng cấp: " + " · ".join(prices), box, UiKit.GOLD_TEXT)


func _set_castle(index: int, key: String, v) -> void:
	var updated: Array = Balance.section("castle").duplicate(true)
	if key == "cells":
		v = clampi(v, 1, MAX_CELLS)
	elif key == "team":
		v = clampi(v, 1, MAX_TEAM)
	updated[index][key] = v
	Balance.set_section("castle", updated)


func _set_workshop(id: String, key: String, v) -> void:
	var updated: Dictionary = Balance.section("workshop").duplicate(true)
	updated[id][key] = v
	Balance.set_section("workshop", updated)
