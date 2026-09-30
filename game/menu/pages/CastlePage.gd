extends "res://game/menu/pages/MenuPage.gd"

# Castle level (HP, max meat, open gear cells, team slots) and the three workshop upgrades.

const GridPreview = preload("res://game/menu/widgets/GridPreview.gd")


func build() -> void:
	title("Thành")
	var level := PlayerData.castle_level
	var max_level := PlayerData.castle_max_level()
	var now: Dictionary = PlayerData.castle_stats()
	var next: Dictionary = Economy.CASTLE[level] if level < max_level else now

	var castle := panel(10)
	var castle_art := UiKit.icon(SpriteLib.texture("Buildings/Blue Buildings/Castle.png"), 170)
	castle_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	castle.add_child(castle_art)
	var heading := UiKit.label("Cấp thành %d / %d" % [level, max_level], 26, UiKit.GOLD_TEXT)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	castle.add_child(heading)

	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 30)
	stats.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stat_row(stats, "Máu thành", "x%.2f" % now["hp"], "x%.2f" % next["hp"], level < max_level)
	_stat_row(stats, "Kho thịt tối đa", str(now["meat"]), str(next["meat"]), level < max_level)
	_stat_row(stats, "Ô đặt gear", str(now["cells"]), str(next["cells"]), level < max_level)
	_stat_row(stats, "Ô đội hình", str(Economy.team_slots(level)), str(Economy.team_slots(mini(level + 1, max_level))), level < max_level)
	castle.add_child(stats)

	var preview := GridPreview.new()
	preview.open_now = now["cells"]
	preview.open_next = next["cells"]
	castle.add_child(preview)
	var legend := UiKit.label("Xanh: ô đang mở · Vàng: ô mở thêm ở cấp sau", 14)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	castle.add_child(legend)

	var cost := PlayerData.castle_upgrade_cost()
	var upgrade := UiKit.button("", Vector2(360, 80), func(): PlayerData.upgrade_castle())
	upgrade.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	upgrade.add_theme_font_size_override("font_size", 24)
	if cost < 0:
		upgrade.text = "THÀNH ĐÃ TỐI ĐA"
		upgrade.disabled = true
	else:
		upgrade.text = "NÂNG THÀNH  %s" % UiKit.format_number(cost)
		upgrade.icon = SpriteLib.texture(UiKit.COIN)
		upgrade.add_theme_constant_override("icon_max_width", 34)
		upgrade.disabled = PlayerData.gold < cost
	castle.add_child(upgrade)

	body.add_child(UiKit.ribbon("Xưởng", 22, UiKit.Ribbon.YELLOW))
	for id in Economy.WORKSHOP_ORDER:
		_workshop_row(id)


func has_alert() -> bool:
	return PlayerData.can_improve_castle()


func _stat_row(grid: GridContainer, name: String, now: String, next: String, has_next: bool) -> void:
	grid.add_child(UiKit.label(name, 19))
	grid.add_child(UiKit.label(now + ("  →  " + next if has_next and next != now else ""), 19, UiKit.INFO))


func _workshop_row(id: String) -> void:
	var spec: Dictionary = Economy.WORKSHOP[id]
	var level := PlayerData.workshop_level(id)
	var box := panel(6)
	var row := UiKit.hbox(12)
	box.add_child(row)
	var info := UiKit.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label("%s  (%d/%d)" % [spec["name"], level, spec["max"]], 21))
	var effect: String = spec["desc"] % PlayerData.workshop_value(id)
	if level < spec["max"]:
		effect += "  →  " + spec["desc"] % PlayerData.workshop_value(id, level + 1)
	var effect_label := UiKit.label(effect, 16, UiKit.INFO)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(effect_label)
	row.add_child(info)
	var cost := PlayerData.workshop_cost(id)
	var b := UiKit.button("", Vector2(170, 64), func(): PlayerData.upgrade_workshop(id))
	if cost < 0:
		b.text = "TỐI ĐA"
		b.disabled = true
	else:
		b.text = UiKit.format_number(cost)
		b.icon = SpriteLib.texture(UiKit.COIN)
		b.add_theme_constant_override("icon_max_width", 28)
		b.disabled = PlayerData.gold < cost
	row.add_child(b)
