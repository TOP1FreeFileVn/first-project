extends "res://game/admin/tabs/AdminTab.gd"

# Level settings and the wave editor: each wave's groups (troop, count, interval, start,
# elite) with a spawn timeline, plus an estimate of the enemy HP each wave brings.

const WaveTimeline = preload("res://game/admin/widgets/WaveTimeline.gd")

var _index := 0


func build() -> void:
	var picker := HFlowContainer.new()
	picker.add_theme_constant_override("h_separation", 6)
	for i in PlayerData.LEVELS.size():
		picker.add_child(small_button(str(i + 1), func():
			_index = i
			rebuild(), i == _index, 60))
	add_child(picker)

	var level: Resource = PlayerData.level_data(_index)
	var info := section("Màn %d" % (_index + 1))
	var name_row := UiKit.hbox(8)
	name_row.add_child(UiKit.label("Tên", 16))
	var name_edit := LineEdit.new()
	name_edit.text = level.display_name
	name_edit.custom_minimum_size = Vector2(0, 44)
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var commit_name := func():
		if name_edit.text.strip_edges() != "" and name_edit.text != level.display_name:
			Balance.set_level_prop(_index, "display_name", name_edit.text.strip_edges())
	name_edit.text_submitted.connect(func(_t): commit_name.call())
	name_edit.focus_exited.connect(commit_name)
	name_row.add_child(name_edit)
	info.add_child(name_row)
	for p in [["core_hp", "Máu thành gốc", 10, 10000, 10], ["enemy_power", "Sức mạnh địch", 0.1, 50, 0.05], ["start_meat", "Thịt ở lượt nghỉ đầu tiên", 0, 60, 1]]:
		var prop: String = p[0]
		number(info, p[1], level.get(prop), p[2], p[3], p[4], false, level.get(prop) != Balance.level_default(_index, prop),
			func(v): Balance.set_level_prop(_index, prop, v))

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_child(small_button("TỰ CHƠI", func():
		panel.dispose()
		panel.home.start_battle(_index), false, 150))
	actions.add_child(small_button("MÔ PHỎNG", func():
		var sim = panel.tab(6)
		sim.level_index = _index
		sim._suggest(_index)
		panel.select_tab(6), false, 150))
	actions.add_child(small_button("VỀ MẶC ĐỊNH", func():
		for prop in Balance.LEVEL_PROPS:
			if level.get(prop) != Balance.level_default(_index, prop):
				Balance.set_level_prop(_index, prop, Balance.level_default(_index, prop)), true, 200))
	add_child(actions)

	var waves: Array = level.waves
	var totals := section("Tổng quan %d đợt" % waves.size())
	for w in waves.size():
		var count := 0
		var hp := 0.0
		for g in waves[w]["groups"]:
			var troop: Resource = PlayerData.TROOPS[g["troop"]]
			var mult := Economy.enemy_multiplier(level.enemy_power, w) * (Economy.ELITE_HP_MULT if g.get("elite", false) else 1.0)
			count += int(g["count"])
			hp += int(g["count"]) * troop.max_hp * mult
		totals.add_child(UiKit.label("Đợt %d: %d quân · tổng máu ≈ %s" % [w + 1, count, UiKit.format_number(roundi(hp))], 15))

	for w in waves.size():
		_wave_editor(waves, w)
	add_child(small_button("+ THÊM ĐỢT", func():
		var updated := _copy_waves()
		var template: Dictionary = updated.back().duplicate(true) if not updated.is_empty() else {"gap": 12.0, "groups": [{"troop": "pawn", "count": 5, "interval": 1.5}]}
		updated.append(template)
		_commit(updated), false, 220))


func _wave_editor(waves: Array, w: int) -> void:
	var wave: Dictionary = waves[w]
	var box := section("Đợt %d" % (w + 1))
	var tools := UiKit.hbox(6)
	tools.add_child(small_button("↑", func(): _move_wave(w, -1), false, 56))
	tools.add_child(small_button("↓", func(): _move_wave(w, 1), false, 56))
	tools.add_child(small_button("NHÂN BẢN", func():
		var updated := _copy_waves()
		updated.insert(w + 1, updated[w].duplicate(true))
		_commit(updated), false, 150))
	var remove := small_button("XOÁ ĐỢT", func():
		var updated := _copy_waves()
		updated.remove_at(w)
		_commit(updated), true, 150)
	remove.disabled = waves.size() <= 1
	tools.add_child(remove)
	box.add_child(tools)
	var timeline = WaveTimeline.new()
	timeline.groups = wave["groups"]
	box.add_child(timeline)

	var header := UiKit.hbox(6)
	for h in [["Lính", 150], ["Số", 76], ["Giãn cách", 90], ["Bắt đầu", 90], ["Tinh nhuệ", 90]]:
		var l := UiKit.label(h[0], 14, UiKit.GOLD_TEXT)
		l.custom_minimum_size.x = h[1]
		header.add_child(l)
	box.add_child(header)
	var groups: Array = wave["groups"]
	for g in groups.size():
		box.add_child(_group_row(w, g, groups[g]))
	box.add_child(small_button("+ NHÓM", func():
		var updated := _copy_waves()
		updated[w]["groups"].append({"troop": "pawn", "count": 5, "interval": 1.5, "start": 0.0})
		_commit(updated), false, 140))


func _group_row(w: int, g: int, group: Dictionary) -> HBoxContainer:
	var row := UiKit.hbox(6)
	var troop := OptionButton.new()
	troop.custom_minimum_size = Vector2(150, 40)
	troop.focus_mode = Control.FOCUS_NONE
	for id in PlayerData.TROOP_ORDER:
		troop.add_item(PlayerData.TROOPS[id].display_name)
	troop.select(PlayerData.TROOP_ORDER.find(group["troop"]))
	troop.item_selected.connect(func(i): _set_group(w, g, "troop", PlayerData.TROOP_ORDER[i]))
	row.add_child(troop)
	row.add_child(cell(group["count"], func(v): _set_group(w, g, "count", maxi(1, v)), 76, true))
	row.add_child(cell(group.get("interval", 1.0), func(v): _set_group(w, g, "interval", maxf(0.05, v)), 90))
	row.add_child(cell(group.get("start", 0.0), func(v): _set_group(w, g, "start", maxf(0.0, v)), 90))
	var elite := CheckBox.new()
	elite.button_pressed = group.get("elite", false)
	elite.focus_mode = Control.FOCUS_NONE
	elite.custom_minimum_size.x = 60
	elite.toggled.connect(func(on): _set_group(w, g, "elite", on))
	row.add_child(elite)
	var remove := small_button("✕", func():
		var updated := _copy_waves()
		updated[w]["groups"].remove_at(g)
		_commit(updated), true, 48)
	remove.disabled = PlayerData.level_data(_index).waves[w]["groups"].size() <= 1
	row.add_child(remove)
	return row


func _set_group(w: int, g: int, key: String, v) -> void:
	var updated := _copy_waves()
	updated[w]["groups"][g][key] = v
	_commit(updated)


func _move_wave(w: int, step: int) -> void:
	var updated := _copy_waves()
	var target := w + step
	if target < 0 or target >= updated.size():
		return
	var wave = updated[w]
	updated[w] = updated[target]
	updated[target] = wave
	_commit(updated)


func _copy_waves() -> Array:
	return PlayerData.level_data(_index).waves.duplicate(true)


func _commit(waves: Array) -> void:
	Balance.set_level_prop(_index, "waves", waves)
