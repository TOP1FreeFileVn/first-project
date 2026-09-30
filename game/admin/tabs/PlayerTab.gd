extends "res://game/admin/tabs/AdminTab.gd"

# Cheats on the local save for testing: currencies, castle and workshop, troops, levels,
# time travel, preset profiles, one snapshot slot and a log. Any change here marks the
# save as "cheated" so balance feedback from it can be taken with a grain of salt.

const LOG_PATH := "user://admin_log.txt"
const SNAPSHOT_PATH := "user://admin_snapshot.json"
const PRESETS := {
	"Người mới": {},
	"Giữa game": {"gold": 3000, "gems": 200, "castle": 4, "troop_level": 6, "stars": 1, "workshop": [2, 1, 1], "levels": 5, "level_stars": [3, 3, 2, 2]},
	"Cuối game": {"gold": 20000, "gems": 1000, "castle": 8, "troop_level": 14, "stars": 2, "workshop": [4, 3, 4], "levels": 10, "level_stars": [3, 3, 3, 3, 3, 2, 2, 2]},
}

var _reset_armed := false


func build() -> void:
	if PlayerData.cheated:
		var flag := section("")
		note("Save này ĐÃ DÙNG CHEAT (sảnh hiện nhãn CHEAT).", flag, UiKit.WARN)
		flag.add_child(small_button("BỎ ĐÁNH DẤU", func():
			PlayerData.cheated = false
			PlayerData._commit(), false, 200))

	var money := section("Tiền")
	number(money, "Vàng", PlayerData.gold, 0, 99999999, 100, true, false, func(v): _cheat("vàng = %d" % v, func(): PlayerData.gold = v))
	number(money, "Kim cương", PlayerData.gems, 0, 9999999, 10, true, false, func(v): _cheat("kim cương = %d" % v, func(): PlayerData.gems = v))
	var quick := HFlowContainer.new()
	quick.add_theme_constant_override("h_separation", 6)
	for amount in [1000, 10000, 100000]:
		quick.add_child(small_button("+%s vàng" % UiKit.format_number(amount), func(): _cheat("+%d vàng" % amount, func(): PlayerData.gold += amount), false, 170))
	quick.add_child(small_button("+500 KC", func(): _cheat("+500 kim cương", func(): PlayerData.gems += 500), false, 150))
	money.add_child(quick)

	var castle := section("Thành & Xưởng")
	number(castle, "Cấp thành", PlayerData.castle_level, 1, PlayerData.castle_max_level(), 1, true, false,
		func(v): _cheat("cấp thành = %d" % v, func(): PlayerData.castle_level = v))
	for id in Economy.WORKSHOP_ORDER:
		number(castle, Economy.WORKSHOP[id]["name"], PlayerData.workshop_level(id), 0, Economy.WORKSHOP[id]["max"], 1, true, false,
			func(v): _cheat("%s = %d" % [id, v], func(): PlayerData.workshop[id] = v))

	var team_box := section("Đội hình (%d ô)" % PlayerData.team_slots())
	var names := []
	for id in PlayerData.battle_team():
		names.append(PlayerData.TROOPS[id].display_name)
	note(", ".join(names), team_box, UiKit.GOLD_TEXT)
	team_box.add_child(small_button("ĐỘI MẠNH NHẤT", func(): _cheat("đội = mạnh nhất", func(): PlayerData.team = PlayerData.auto_team()), false, 240))

	var troops := section("Lính")
	for id in PlayerData.TROOP_ORDER:
		var t: Dictionary = PlayerData.troop(id)
		var head := UiKit.hbox(8)
		head.add_child(UiKit.troop_portrait(PlayerData.TROOPS[id], 48))
		head.add_child(UiKit.label(PlayerData.TROOPS[id].display_name, 19))
		var unlock := CheckBox.new()
		unlock.text = "Mở khoá"
		unlock.button_pressed = t["unlocked"]
		unlock.focus_mode = Control.FOCUS_NONE
		unlock.toggled.connect(func(on): _cheat("%s mở khoá = %s" % [id, on], func(): t["unlocked"] = on))
		head.add_child(unlock)
		troops.add_child(head)
		number(troops, "   Cấp", t["level"], 1, 999, 1, true, false, func(v): _cheat("%s cấp = %d" % [id, v], func(): t["level"] = v))
		number(troops, "   Sao", t["stars"], 1, Economy.MAX_STARS, 1, true, false, func(v): _cheat("%s sao = %d" % [id, v], func(): t["stars"] = v))
		number(troops, "   Thẻ", t["cards"], 0, 99999, 1, true, false, func(v): _cheat("%s thẻ = %d" % [id, v], func(): t["cards"] = v))

	var levels := section("Màn chơi")
	number(levels, "Số màn đã mở", PlayerData.unlocked_levels, 1, PlayerData.LEVELS.size(), 1, true, false,
		func(v): _cheat("màn mở = %d" % v, func(): PlayerData.unlocked_levels = v))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	for i in PlayerData.LEVELS.size():
		var pair := UiKit.vbox(2)
		pair.add_child(UiKit.label("Màn %d ★" % (i + 1), 15))
		pair.add_child(cell(PlayerData.stars_for(i), func(v): _cheat("sao màn %d = %d" % [i + 1, v], func():
			if v <= 0:
				PlayerData.level_stars.erase(i)
			else:
				PlayerData.level_stars[i] = clampi(v, 1, 3)), 90, true))
		grid.add_child(pair)
	levels.add_child(grid)

	var time := section("Tua thời gian")
	note("Đẩy mốc tuần tra và rương gỗ về quá khứ, như thể đã trôi qua N giờ.", time)
	var time_row := HFlowContainer.new()
	time_row.add_theme_constant_override("h_separation", 6)
	for hours in [1, 4, 8, 24]:
		time_row.add_child(small_button("+%dh" % hours, func(): _cheat("tua %d giờ" % hours, func():
			PlayerData.patrol_last_claim -= hours * 3600
			PlayerData.free_chest_at -= hours * 3600
			if hours >= 24:
				PlayerData.patrol_quick_day -= 1), false, 110))
	time.add_child(time_row)

	var profiles := section("Hồ sơ")
	var preset_row := HFlowContainer.new()
	preset_row.add_theme_constant_override("h_separation", 6)
	for preset_name in PRESETS:
		preset_row.add_child(small_button(preset_name, func(): _cheat("nạp hồ sơ " + preset_name, func(): _apply_preset(PRESETS[preset_name])), false, 170))
	profiles.add_child(preset_row)
	var snap_row := UiKit.hbox(6)
	snap_row.add_child(small_button("CHỤP HỒ SƠ", _snapshot, false, 200))
	var restore := small_button("KHÔI PHỤC", _restore_snapshot, false, 200)
	restore.disabled = not FileAccess.file_exists(SNAPSHOT_PATH)
	snap_row.add_child(restore)
	profiles.add_child(snap_row)
	var reset := small_button("CHẠM 2 LẦN ĐỂ XOÁ SAVE" if _reset_armed else "XOÁ SAVE", _on_reset, true, 360)
	profiles.add_child(reset)

	var log_box := section("Nhật ký cheat (mới nhất trên cùng)")
	var lines := _read_log()
	note("Chưa có." if lines.is_empty() else "\n".join(lines.slice(0, 12)), log_box, Color(1, 1, 1, 0.75))


func _cheat(what: String, change: Callable) -> void:
	change.call()
	var file := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
	if file != null:
		file.seek_end()
		file.store_line("%s  %s" % [Time.get_datetime_string_from_system(false, true).replace("T", " "), what])
	PlayerData.commit_cheat()
	toast("Cheat: " + what)


func _read_log() -> Array:
	if not FileAccess.file_exists(LOG_PATH):
		return []
	var lines := FileAccess.get_file_as_string(LOG_PATH).strip_edges().split("\n")
	lines.reverse()
	return Array(lines)


func _apply_preset(preset: Dictionary) -> void:
	PlayerData._reset()
	if preset.is_empty():
		return
	PlayerData.gold = preset["gold"]
	PlayerData.gems = preset["gems"]
	PlayerData.castle_level = mini(preset["castle"], PlayerData.castle_max_level())
	for id in PlayerData.TROOP_ORDER:
		PlayerData.troops[id] = {"unlocked": true, "level": preset["troop_level"], "stars": preset["stars"], "cards": 0}
	PlayerData.team = PlayerData.auto_team()
	for i in Economy.WORKSHOP_ORDER.size():
		PlayerData.workshop[Economy.WORKSHOP_ORDER[i]] = preset["workshop"][i]
	PlayerData.unlocked_levels = mini(preset["levels"], PlayerData.LEVELS.size())
	for i in preset["level_stars"].size():
		PlayerData.level_stars[i] = preset["level_stars"][i]


func _snapshot() -> void:
	var file := FileAccess.open(SNAPSHOT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(PlayerData.to_dict()))
	toast("Đã chụp hồ sơ hiện tại.")
	rebuild()


func _restore_snapshot() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(SNAPSHOT_PATH))
	if data is Dictionary:
		_cheat("khôi phục hồ sơ đã chụp", func(): PlayerData.from_dict(data))


func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		rebuild()
		get_tree().create_timer(3.0).timeout.connect(func():
			_reset_armed = false
			if is_inside_tree():
				rebuild())
		return
	_reset_armed = false
	PlayerData.reset_progress()
	toast("Đã xoá save.")
