extends "res://game/admin/tabs/AdminTab.gd"

# Per-troop stats with live derived numbers (DPS, power, troops per minute), a side-by-side
# comparison of all troops, and the card cost of each star.

# [property, label, min, max, step, is_int]
const PROPS := [
	["max_hp", "Máu", 1, 5000, 5, false],
	["damage", "Sát thương (Tu sĩ: lượng hồi máu)", 0, 500, 0.5, false],
	["attack_range", "Tầm đánh (px · 100 = 1 ô gear)", 10, 600, 2, false],
	["attack_cooldown", "Hồi chiêu (giây giữa 2 đòn)", 0.1, 10, 0.05, false],
	["move_speed", "Tốc chạy (px/giây · 100 = 1 ô gear mỗi giây)", 5, 400, 5, false],
	["crit_chance", "Tỉ lệ chí mạng (0–1)", 0, 1, 0.01, false],
	["crit_mult", "Sát thương chí mạng (x)", 1, 5, 0.05, false],
	["aggro_range", "Tầm phát hiện địch (px)", 20, 1000, 10, false],
	["spawn_interval", "Gear bậc 1 sinh mỗi (giây)", 0.2, 30, 0.1, false],
	["max_alive", "Số lính tối đa mỗi gear", 1, 20, 1, true],
	["summon_weight", "Tỉ lệ ra trong shop trận (tương đối, cùng độ hiếm)", 0, 10, 0.1, false],
	["rarity", "Độ hiếm (0 Thường · 1 Hiếm · 2 Sử thi · 3 Huyền thoại)", 0, 3, 1, true],
]
# Ability numbers; what each one means depends on the ability (see TroopData.gd).
const ABILITY_PROPS := [
	["ability_value", "Kỹ năng: giá trị", 0, 1000, 0.05],
	["ability_duration", "Kỹ năng: thời gian (giây)", 0, 60, 0.1],
	["ability_cooldown", "Kỹ năng: hồi chiêu (giây)", 0, 120, 0.5],
	["ability_radius", "Kỹ năng: bán kính (px · 100 = 1 ô gear)", 0, 1000, 5],
]
const ABILITY_NAMES := ["Không", "Đào hầm", "Rèn giáp", "Ám sát", "Giơ khiên", "Tên lửa", "Nấu cá", "Bom", "Hiệu lệnh"]

## Sizes a designer can picture: a gear cell, and the enemies' walk from the top of the
## field to the wall (Battle.ENEMY_SPAWN_Y to Battle.WALL_Y).
const CELL_PX := 100.0
const FIELD_RUN_PX := 730

var _selected := "warrior"


func build() -> void:
	var picker := HFlowContainer.new()
	picker.add_theme_constant_override("h_separation", 6)
	for id in PlayerData.TROOP_ORDER:
		var b := small_button(PlayerData.TROOPS[id].display_name, func():
			_selected = id
			rebuild(), id == _selected, 130)
		picker.add_child(b)
	add_child(picker)

	var troop: Resource = PlayerData.TROOPS[_selected]
	var stats := section("%s — chỉ số gốc (trước cấp/sao/bậc)" % troop.display_name)
	for p in PROPS:
		var prop: String = p[0]
		var current = troop.get(prop)
		number(stats, p[1], float(current), p[2], p[3], p[4], p[5], current != Balance.troop_default(_selected, prop),
			func(v): Balance.set_troop_stat(_selected, prop, v))
	if troop.ability != 0:
		var ability := section("Kỹ năng: %s" % ABILITY_NAMES[troop.ability])
		note(troop.ability_text, ability)
		for p in ABILITY_PROPS:
			var prop: String = p[0]
			var current = troop.get(prop)
			number(ability, p[1], float(current), p[2], p[3], p[4], false, current != Balance.troop_default(_selected, prop),
				func(v): Balance.set_troop_stat(_selected, prop, v))
		note("Mô tả kỹ năng (ở trên) là chữ cố định trong file lính; đổi số ở đây nhớ sửa mô tả khi ghi vào bản build.", ability, Color(1, 1, 1, 0.6))
	var dps := _dps(troop)
	note("DPS: %.2f · Sức mạnh (máu × DPS): %s · Lính/phút mỗi gear: %.1f" % [dps, UiKit.format_number(roundi(troop.max_hp * dps)), 60.0 / troop.spawn_interval], stats, UiKit.GOLD_TEXT)
	note(picture(troop), stats, Color(1, 1, 1, 0.75))

	var compare := section("So sánh %d lính (bậc 1, cấp 1)" % PlayerData.TROOP_ORDER.size())
	for metric in [["Sức mạnh (máu × DPS)", func(t): return t.max_hp * _dps(t)], ["DPS", func(t): return _dps(t)], ["Máu", func(t): return t.max_hp], ["Lính/phút mỗi gear", func(t): return 60.0 / t.spawn_interval]]:
		compare.add_child(UiKit.label(metric[0], 16, UiKit.GOLD_TEXT))
		var top := 0.0
		for id in PlayerData.TROOP_ORDER:
			top = maxf(top, metric[1].call(PlayerData.TROOPS[id]))
		for id in PlayerData.TROOP_ORDER:
			var value: float = metric[1].call(PlayerData.TROOPS[id])
			var row := UiKit.hbox(8)
			var name_label := UiKit.label(PlayerData.TROOPS[id].display_name, 15)
			name_label.custom_minimum_size.x = 130
			row.add_child(name_label)
			var bar := UiKit.bar(Color("7fd66b") if id == _selected else Color("5aa9e6"), Vector2(380, 14))
			bar.max_value = maxf(top, 0.001)
			bar.value = value
			row.add_child(bar)
			row.add_child(UiKit.label(str(snappedf(value, 0.1)), 15))
			compare.add_child(row)

	var star_box := section("Lên sao: thẻ cần cho mỗi mức")
	var costs: Array = Balance.section("star_card_cost").duplicate()
	for i in costs.size():
		number(star_box, "%d★ → %d★" % [i + 1, i + 2], costs[i], 1, 100000, 5, true, false, func(v):
			var updated: Array = Balance.section("star_card_cost").duplicate()
			updated[i] = v
			Balance.set_section("star_card_cost", updated))
	var star_buttons := UiKit.hbox(8)
	star_buttons.add_child(small_button("+ THÊM MỨC SAO", func():
		var updated: Array = Balance.section("star_card_cost").duplicate()
		updated.append(updated.back() * 3)
		Balance.set_section("star_card_cost", updated), false, 250))
	var remove := small_button("− BỚT", func():
		var updated: Array = Balance.section("star_card_cost").duplicate()
		updated.pop_back()
		Balance.set_section("star_card_cost", updated), true, 120)
	remove.disabled = costs.size() <= 1
	star_buttons.add_child(remove)
	star_box.add_child(star_buttons)
	note("Sao tối đa hiện tại: %d★ (trần cấp = sao × %d)." % [Economy.MAX_STARS, Economy.LEVELS_PER_STAR], star_box)


## The stats in words a designer can picture: seconds to cross a gear cell and the
## battlefield, hits per minute, reach in gear cells, crit odds.
static func picture(troop: Resource) -> String:
	var speed: float = maxf(troop.move_speed, 0.01)
	var text := "Hình dung (tốc độ x1): chạy 1 ô gear trong %.1f giây, từ mép trên sân tới tường (%d px) trong %.1f giây" % [CELL_PX / speed, FIELD_RUN_PX, FIELD_RUN_PX / speed]
	if troop.role != 3:
		text += " · %d đòn/phút · tầm đánh %.1f ô gear" % [roundi(60.0 / maxf(troop.attack_cooldown, 0.01)), troop.attack_range / CELL_PX]
	if troop.crit_factor() > 1.0:
		text += " · chí mạng khoảng 1 trong %d đòn gây x%.2f" % [roundi(1.0 / troop.crit_chance), troop.crit_mult]
	return text + "."


static func _dps(troop: Resource) -> float:
	return troop.damage / maxf(troop.attack_cooldown, 0.01) * troop.crit_factor()
