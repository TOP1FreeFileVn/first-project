extends "res://game/admin/tabs/AdminTab.gd"

# Balance checks without leaving the game: run the bot N times on a level with a chosen
# upgrade profile, and compare the gold a player earns with the gold the expected
# upgrades cost, level by level.

const LineChart = preload("res://game/admin/widgets/LineChart.gd")
# Upgrades a player is expected to have before playing level n: [castle, troop level, stars].
const EXPECTED := [[1, 1, 1], [1, 2, 1], [2, 3, 1], [3, 4, 1], [4, 5, 1], [4, 7, 1], [5, 8, 1], [6, 10, 2], [7, 12, 2], [8, 14, 2]]

var level_index := 0
var use_current := false
var castle := 3
var troop_level := 4
var stars := 1
var workshop := 0
var runs := 3
var speed := 4.0
var patrol_hours := 1.0
var main_troops := 3

var _progress: Label
var _results_box: VBoxContainer
var _last_results: Array = []


func build() -> void:
	var runner := section("Chạy bot")
	note("Bot ghép gear ngay lập tức nên chơi giỏi hơn người; tỉ lệ thắng của bot là mức trần.", runner)
	var level_row := HFlowContainer.new()
	level_row.add_theme_constant_override("h_separation", 6)
	for i in PlayerData.LEVELS.size():
		var b := small_button(str(i + 1), func():
			level_index = i
			_suggest(i)
			rebuild(), i == level_index, 60)
		level_row.add_child(b)
	runner.add_child(level_row)
	var current := CheckBox.new()
	current.text = "Dùng hồ sơ người chơi hiện tại"
	current.button_pressed = use_current
	current.focus_mode = Control.FOCUS_NONE
	current.toggled.connect(func(on):
		use_current = on
		rebuild())
	runner.add_child(current)
	if not use_current:
		number(runner, "Cấp thành", castle, 1, Economy.CASTLE.size(), 1, true, false, func(v): castle = v)
		number(runner, "Cấp lính (tất cả)", troop_level, 1, 99, 1, true, false, func(v): troop_level = v)
		number(runner, "Sao lính", stars, 1, Economy.MAX_STARS, 1, true, false, func(v): stars = v)
		number(runner, "Cấp xưởng (cả 3)", workshop, 0, 5, 1, true, false, func(v): workshop = v)
	number(runner, "Số trận", runs, 1, 50, 1, true, false, func(v): runs = v)
	number(runner, "Tốc độ (x)", speed, 1, 8, 1, true, false, func(v): speed = v)
	var buttons := UiKit.hbox(8)
	var run := small_button("CHẠY", _run, false, 180)
	run.disabled = panel.sim.running
	buttons.add_child(run)
	var stop := small_button("DỪNG", func(): panel.sim.cancel(), true, 140)
	stop.disabled = not panel.sim.running
	buttons.add_child(stop)
	var play := small_button("TỰ CHƠI MÀN NÀY", func():
		panel.dispose()
		panel.home.start_battle(level_index), false, 250)
	buttons.add_child(play)
	runner.add_child(buttons)
	_progress = UiKit.label("", 17, UiKit.GOLD_TEXT)
	runner.add_child(_progress)
	_results_box = UiKit.vbox(4)
	runner.add_child(_results_box)
	_show_results(_last_results)

	_build_economy()


func _suggest(index: int) -> void:
	var e: Array = EXPECTED[mini(index, EXPECTED.size() - 1)]
	castle = e[0]
	troop_level = e[1]
	stars = e[2]


func _run() -> void:
	var profile := {} if use_current else {"castle": castle, "troop_level": troop_level, "stars": stars, "workshop": [workshop, mini(workshop, 4), workshop]}
	_last_results = []
	var sim = panel.sim
	if not sim.progress.is_connected(_on_progress):
		sim.progress.connect(_on_progress)
		sim.finished.connect(_on_finished)
	sim.start(level_index, profile, runs, speed)
	rebuild()
	_progress.text = "Đang chạy màn %d..." % (level_index + 1)


func _on_progress(done: int, total: int, last: Dictionary) -> void:
	_last_results.append(last)
	if is_instance_valid(_progress):
		_progress.text = "Đã chạy %d/%d trận" % [done, total]
		_show_results(_last_results)


func _on_finished(results: Array) -> void:
	_last_results = results
	if is_inside_tree():
		rebuild()
		_progress.text = "Xong %d trận màn %d." % [results.size(), level_index + 1]


func _show_results(results: Array) -> void:
	if _results_box == null:
		return
	for child in _results_box.get_children():
		child.queue_free()
	if results.is_empty():
		return
	var wins := 0
	var hp_sum := 0.0
	var lost_waves := {}
	for r in results:
		if r["won"]:
			wins += 1
			hp_sum += r["hp_ratio"]
		else:
			lost_waves[r["wave"]] = lost_waves.get(r["wave"], 0) + 1
	var summary := "Thắng %d/%d (%d%%)" % [wins, results.size(), roundi(100.0 * wins / results.size())]
	if wins > 0:
		summary += " · máu thành còn TB %d%%" % roundi(100.0 * hp_sum / wins)
	if not lost_waves.is_empty():
		var worst: int = lost_waves.keys()[0]
		for w in lost_waves:
			if lost_waves[w] > lost_waves[worst]:
				worst = w
		summary += " · thua nhiều nhất ở đợt %d" % worst
	_results_box.add_child(UiKit.label(summary, 18, Color("7fd66b") if wins * 2 >= results.size() else UiKit.WARN))
	for i in results.size():
		var r: Dictionary = results[i]
		var line := "#%d  %s  đợt %d/%d  thành %d%%  %ds" % [i + 1, "THẮNG" if r["won"] else ("HẾT GIỜ" if r["timeout"] else "THUA"), r["wave"], r["waves"], roundi(r["hp_ratio"] * 100.0), roundi(r["time"])]
		_results_box.add_child(UiKit.label(line, 15))


func _build_economy() -> void:
	var box := section("Đường cong kinh tế")
	note("'Cần' = vàng để đạt mức nâng cấp dự kiến trước màn đó (thành + %d lính chủ lực). 'Có' = vàng thắng lần đầu 3★ các màn trước + tuần tra. Đường 'cần' vượt 'có' là chỗ người chơi phải cày." % main_troops, box)
	number(box, "Giờ tuần tra mỗi màn", patrol_hours, 0, 24, 0.5, false, false, func(v):
		patrol_hours = v
		rebuild())
	number(box, "Số lính chủ lực", main_troops, 1, 5, 1, true, false, func(v):
		main_troops = v
		rebuild())
	var need_points := []
	var have_points := []
	var rows := []
	var have := 0.0
	for n in PlayerData.LEVELS.size():
		var e: Array = EXPECTED[mini(n, EXPECTED.size() - 1)]
		var need := 0.0
		for c in range(1, mini(e[0], Economy.CASTLE.size())):
			need += Economy.CASTLE[c]["cost"]
		for l in range(1, e[1]):
			need += Economy.level_cost(l) * main_troops
		if n > 0:
			have += Economy.win_gold(n - 1, 3) * Economy.FIRST_CLEAR_GOLD_MULT + Economy.patrol_rate(n - 1) * patrol_hours
		need_points.append(Vector2(n + 1, need))
		have_points.append(Vector2(n + 1, have))
		rows.append([n + 1, need, have])
	var chart = LineChart.new()
	chart.set_series([
		{"points": need_points, "color": Color("ff8a7a"), "dashed": false},
		{"points": have_points, "color": Color("7fd66b"), "dashed": false},
	], "màn")
	box.add_child(chart)
	box.add_child(UiKit.label("Đỏ = cần · Xanh = có", 15))
	var table := GridContainer.new()
	table.columns = 4
	table.add_theme_constant_override("h_separation", 26)
	for h in ["Màn", "Cần", "Có", "Chênh"]:
		table.add_child(UiKit.label(h, 15, UiKit.GOLD_TEXT))
	for r in rows:
		table.add_child(UiKit.label(str(r[0]), 15))
		table.add_child(UiKit.label(UiKit.format_number(roundi(r[1])), 15))
		table.add_child(UiKit.label(UiKit.format_number(roundi(r[2])), 15))
		var gap: int = roundi(r[2] - r[1])
		table.add_child(UiKit.label(("+" if gap >= 0 else "") + UiKit.format_number(gap), 15, Color("7fd66b") if gap >= 0 else UiKit.WARN))
	box.add_child(table)
