extends RefCounted

# The lobby's side popups: Events hub, 7-day login gift, daily quests and the player
# profile (name, avatar, frame). Each is a contextual sheet that rebuilds
# its content after a claim or a choice.

const UiKit = preload("res://game/ui/UiKit.gd")
const Ui = preload("res://game/ui/Ui.gd")
const Economy = preload("res://game/core/Economy.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const Meta = preload("res://game/core/Meta.gd")
const DrawnIcon = preload("res://game/ui/DrawnIcon.gd")
const PatrolPage = preload("res://game/menu/pages/PatrolPage.gd")
const SummonPage = preload("res://game/menu/pages/SummonPage.gd")

const OK_GREEN := Color("7fd66b")
const STATUS_INK := Color("286b33")
const GOLD_INK := Color("80541d")


static func _clear(box: VBoxContainer) -> void:
	while box.get_child_count() > 1:
		var child := box.get_child(1)
		box.remove_child(child)
		child.queue_free()


static func _note(text: String, size := 16, color := UiKit.INFO) -> Label:
	var l := UiKit.ink(text, size)
	if color != UiKit.INFO:
		l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Reward icons retain their art; their amounts read directly on the menu face.
static func _paper_rewards(reward: Dictionary, font_size := 18) -> HBoxContainer:
	var row := UiKit.reward_row(reward, font_size)
	for amount: Label in row.find_children("*", "Label", true, false):
		amount.add_theme_color_override("font_color", UiKit.INK)
		amount.add_theme_constant_override("outline_size", 0)
	return row


## Short text for what a grant() gave, for toasts.
static func got_text(got: Dictionary) -> String:
	var parts := []
	if got.get("gold", 0) > 0:
		parts.append("%s vàng" % UiKit.format_number(got["gold"]))
	if got.get("gems", 0) > 0:
		parts.append("%d kim cương" % got["gems"])
	var cards := 0
	for id in got.get("cards", {}):
		cards += got["cards"][id]
	if cards > 0:
		parts.append("%d thẻ lính" % cards)
	if got.get("stones", 0) > 0:
		parts.append("%d đá rèn" % got["stones"])
	for id in got.get("items", []):
		parts.append(HeroCat.ITEMS[id]["name"])
	return "Nhận: " + ", ".join(parts)


# --- Events hub ---------------------------------------------------------------------------
# Layout pattern UI-068 (layout.md): one main banner for the featured event, then a list of
# the other timed events. Each row keeps the same columns: drawn icon | name + progress |
# one action button (green "Nhận/Thu" when something is waiting, blue "Đi" otherwise).

const EVENT_ICON := 76.0
const EVENT_BUTTON := Vector2(140, 68)


static func open_events(home: Control) -> void:
	var box := UiKit.sheet_popup(home, 660, "Sự kiện")
	box.add_child(_summon_banner(home, box))
	var list := Ui.vbox(8)

	var stored := PlayerData.patrol_stored()
	var capacity := PlayerData.patrol_capacity()
	list.add_child(_event_row("rail_patrol", "Tuần tra", _value_bar("BarItem", stored, capacity, "coin"),
		"Thu" if PlayerData.patrol_alert() else "Đi", PlayerData.patrol_alert(), func():
			UiKit.close_popup(box)
			home.open_page(PatrolPage)))

	list.add_child(_event_row("rail_checkin", "Quà 7 ngày", _login_track(),
		"Nhận" if PlayerData.login_can_claim() else "Xem", PlayerData.login_can_claim(), func():
			UiKit.close_popup(box)
			open_login(home)))

	var points := PlayerData.quest_points()
	var goal: int = Meta.QUEST_MILESTONES.back()["points"]
	for milestone in Meta.QUEST_MILESTONES:
		if points < milestone["points"]:
			goal = milestone["points"]
			break
	list.add_child(_event_row("rail_quest", "Nhiệm vụ hằng ngày", _value_bar("BarExp", points, goal, "star"),
		"Nhận" if PlayerData.quest_alert() else "Đi", PlayerData.quest_alert(), func():
			UiKit.close_popup(box)
			open_quests(home)))
	box.add_child(Ui.menu_section("events", "Sự kiện khác", list))


## The featured event: a purple card as wide as the window, a legendary item on a glow at
## the left, the title and pity in the middle, the summon button at the right.
static func _summon_banner(home: Control, box: VBoxContainer) -> Control:
	var free := PlayerData.summon_free_ready()
	var root := Control.new()
	root.custom_minimum_size = Vector2(0, 196)
	var card := Ui.panel("CardUnitPurple")
	root.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := Ui.hbox(12, BoxContainer.ALIGNMENT_BEGIN)
	card.add_child(row)

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(128, 0)
	var glow := Ui.icon("badge_flower", 128)
	glow.modulate = Color(1, 1, 1, 0.35)
	Ui.pin(stage, glow, Vector2(-64, -66), Control.PRESET_CENTER)
	var best := UiKit.troop_portrait(PlayerData.TROOPS["katana"], 140)
	Ui.pin(stage, best, Vector2(-70, -78), Control.PRESET_CENTER)
	row.add_child(stage)

	var text := Ui.vbox(4, BoxContainer.ALIGNMENT_CENTER)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Ui.label("Triệu hồi Lính", "", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.custom_minimum_size.y = 36
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(title)
	var star := Ui.label("Thẻ lính: mở khoá và lên sao", "LabelSmall", 18)
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	star.custom_minimum_size.y = 27
	star.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	star.add_theme_constant_override("outline_size", 3)
	text.add_child(star)
	var pity := Ui.counter("rail_online", "Còn %d lượt ra Huyền thoại" % PlayerData.summon_pity_left())
	pity.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	text.add_child(pity)
	row.add_child(text)

	var go: Button
	if free:
		go = Ui.cost_button("Triệu hồi", "Miễn phí", "tab_summon", "Yellow", Vector2(156, 104))
	else:
		go = Ui.button("Xem", "Yellow", Vector2(156, 84), 24)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func():
		UiKit.close_popup(box)
		home.open_page(SummonPage))
	row.add_child(go)
	if free:
		Ui.dot(go, Vector2(-22, -10))
		go.ready.connect(func(): Ui.pulse(go, 0.04, 1.4))
	var tag := UiKit.tag("Nổi bật", Color("ffb938"))
	root.add_child(tag)
	tag.position = Vector2(14, -14)
	return root


## One row: icon column, name + its progress, the action button column.
static func _event_row(icon_name: String, title: String, progress: Control, action: String, ready: bool, on_press: Callable) -> Control:
	var row := Ui.hbox(12, BoxContainer.ALIGNMENT_BEGIN)
	var picture := Ui.icon(icon_name, EVENT_ICON)
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if ready:
		Ui.dot(picture, Ui.RAIL_BADGE_AT)
	row.add_child(picture)
	var middle := Ui.vbox(6, BoxContainer.ALIGNMENT_CENTER)
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Ui.label(title, "LabelDark", 22)
	name_label.add_theme_color_override("font_color", UiKit.INK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.custom_minimum_size.y = 32
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	middle.add_child(name_label)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(progress)
	row.add_child(middle)
	var button := Ui.button(action, "Green" if ready else "Blue", EVENT_BUTTON, 22)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(on_press)
	row.add_child(button)
	var inset := Ui.margin(0, 6, 0, 6)
	inset.custom_minimum_size.y = 116
	inset.add_child(row)
	return inset


## A bar with "value/max" on it and an icon in front.
static func _value_bar(variation: String, value: int, maximum: int, icon_name: String) -> Control:
	var line := Ui.hbox(6, BoxContainer.ALIGNMENT_BEGIN)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(Ui.icon(icon_name, 28))
	var bar := ProgressBar.new()
	bar.theme_type_variation = variation
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 28)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.max_value = maxi(maximum, 1)
	bar.value = mini(value, maximum)
	var amount := Ui.label("%s/%s" % [UiKit.format_number(value), UiKit.format_number(maximum)], "LabelTiny", 16)
	amount.add_theme_constant_override("outline_size", 3)
	bar.add_child(amount)
	amount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.add_child(bar)
	return line


## Seven day marks: ticked days claimed, today's a star, the rest grey.
static func _login_track() -> Control:
	var line := Ui.hbox(4, BoxContainer.ALIGNMENT_BEGIN)
	var claimed := PlayerData.login_progress()
	for day in 7:
		var mark: String = "badge_check" if day < claimed else ("star" if day == claimed and PlayerData.login_can_claim() else "star_off")
		line.add_child(Ui.icon(mark, 28))
	var day_label := Ui.label("Ngày %d/7" % mini(claimed + 1, 7), "LabelDark", 16)
	day_label.add_theme_color_override("font_color", UiKit.INK)
	line.add_child(day_label)
	return line


# --- 7-day login --------------------------------------------------------------------------

static func open_login(home: Control) -> void:
	var box := UiKit.dark_popup(home, 660, "Quà 7 ngày")
	_fill_login(home, box)


static func _fill_login(home: Control, box: VBoxContainer) -> void:
	_clear(box)
	box.add_child(_note("Đăng nhập mỗi ngày để nhận quà. Ngày 7 nhận một trang bị Sử thi!"))
	var claimed := PlayerData.login_progress()
	var ready := PlayerData.login_can_claim()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for day in 6:
		grid.add_child(_login_card(day, claimed, ready, Vector2(184, 150)))
	box.add_child(grid)
	var last := _login_card(6, claimed, ready, Vector2(0, 150))
	last.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(last)
	var claim := UiKit.button("NHẬN QUÀ NGÀY %d" % (claimed + 1) if ready else "Quay lại vào ngày mai", Vector2(380, 80), func():
		var got := PlayerData.claim_login()
		if not got.is_empty():
			UiKit.toast(home, got_text(got))
			_fill_login(home, box))
	claim.disabled = not ready
	claim.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(claim)


static func _login_card(day: int, claimed: int, ready: bool, card_size: Vector2) -> Control:
	var done := day < claimed
	var today := day == claimed and ready
	var card := Ui.menu_panel("login", "Board" if today else "Well")
	card.custom_minimum_size = card_size
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := UiKit.vbox(4)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(column)
	var title := UiKit.ink("NGÀY %d" % (day + 1), 18)
	if today:
		title.add_theme_color_override("font_color", GOLD_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var reward: Dictionary = Meta.LOGIN_REWARDS[day]
	if reward.has("item"):
		var rarity := int(reward["item"])
		var row := UiKit.hbox(14)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var face := Ui.gear_card("eq_armor", HeroCat.SLOT_ICONS["armor"], HeroCat.tone(rarity), "?", 84.0)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(face)
		var text := UiKit.vbox(0)
		var item_name := UiKit.ink("Trang bị ngẫu nhiên", 22)
		item_name.add_theme_color_override("font_color", Economy.RARITY_COLORS[rarity].darkened(0.45))
		text.add_child(item_name)
		text.add_child(UiKit.ink("Phẩm " + Economy.RARITY_NAMES[rarity], 16))
		row.add_child(text)
		column.add_child(row)
	else:
		column.add_child(_paper_rewards(reward, 22))
	if done:
		var tick := UiKit.ink("✓ ĐÃ NHẬN", 15)
		tick.add_theme_color_override("font_color", STATUS_INK)
		tick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(tick)
		card.modulate = Color(0.75, 0.75, 0.75)
	elif today:
		var now_label := UiKit.ink("HÔM NAY", 15)
		now_label.add_theme_color_override("font_color", GOLD_INK)
		now_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(now_label)
		# A gentle pulse on today's gift.
		card.resized.connect(func(): card.pivot_offset = card.size / 2.0)
		card.pivot_offset = card_size / 2.0
		var pulse := card.create_tween().set_loops()
		pulse.tween_property(card, "scale", Vector2(1.04, 1.04), 0.5).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(card, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	return card


# --- Daily quests -------------------------------------------------------------------------

static func open_quests(home: Control) -> void:
	var box := UiKit.dark_popup(home, 680, "Nhiệm vụ hằng ngày")
	_fill_quests(home, box)


static func _fill_quests(home: Control, box: VBoxContainer) -> void:
	_clear(box)
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	var local := PlayerData.now() + bias * 60
	var left := 86400 - posmod(local, 86400)
	box.add_child(_note("Làm mới sau " + UiKit.format_time(left)))
	box.add_child(_activity_bar(home, box))
	for quest in Meta.QUESTS:
		box.add_child(_quest_row(home, box, quest))


# Activity points with the three milestone chests along the bar.
static func _activity_bar(home: Control, box: VBoxContainer) -> Control:
	var total: int = Meta.QUEST_MILESTONES[-1]["points"]
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(0, 116)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var points := PlayerData.quest_points()
	var label := UiKit.ink("Năng động: %d" % points, 18)
	label.position = Vector2(0, 0)
	panel.add_child(label)
	var bar := UiKit.bar(UiKit.GOLD_TEXT, Vector2(0, 16))
	bar.anchor_right = 1.0
	bar.offset_left = 20
	bar.offset_right = -35
	bar.offset_top = 70
	bar.offset_bottom = 86
	bar.max_value = total
	bar.value = points
	panel.add_child(bar)
	var tints := [Color("a0673a"), Color("aeb8c2"), Color("e8b93c")]
	for i in Meta.QUEST_MILESTONES.size():
		var need: int = Meta.QUEST_MILESTONES[i]["points"]
		var ratio := float(need) / total
		var chest := Button.new()
		chest.focus_mode = Control.FOCUS_NONE
		chest.custom_minimum_size = Vector2(70, 70)
		chest.size = Vector2(70, 70)
		chest.anchor_left = ratio
		chest.anchor_right = ratio
		chest.offset_left = 20.0 - 55.0 * ratio - 35.0
		chest.offset_right = chest.offset_left + 70.0
		chest.offset_top = 6
		chest.offset_bottom = 76
		for state in ["normal", "hover", "pressed", "disabled"]:
			chest.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var icon := UiKit.drawn(DrawnIcon.Kind.CHEST, 62)
		icon.tint = tints[i]
		icon.position = Vector2(4, 0)
		icon.size = Vector2(62, 62)
		chest.add_child(icon)
		var index := i
		if PlayerData.milestone_claimed(i):
			chest.modulate = Color(0.5, 0.5, 0.5)
		elif PlayerData.milestone_ready(i):
			chest.pivot_offset = Vector2(35, 35)
			var wobble := chest.create_tween().set_loops()
			wobble.tween_property(chest, "rotation", 0.12, 0.12)
			wobble.tween_property(chest, "rotation", -0.12, 0.12)
			wobble.tween_property(chest, "rotation", 0.0, 0.12)
			wobble.tween_interval(0.6)
		chest.pressed.connect(func():
			var got := PlayerData.claim_milestone(index)
			if got.is_empty():
				var words := _reward_words(Meta.QUEST_MILESTONES[index]["reward"])
				UiKit.toast(home, "Đã nhận rồi" if PlayerData.milestone_claimed(index) else "Cần %d điểm · %s" % [need, words])
			else:
				UiKit.toast(home, got_text(got))
				_fill_quests(home, box))
		panel.add_child(chest)
		var mark := UiKit.ink(str(need), 15)
		mark.anchor_left = ratio
		mark.anchor_right = ratio
		mark.offset_left = 20.0 - 55.0 * ratio - 20.0
		mark.offset_right = mark.offset_left + 40.0
		mark.offset_top = 90
		mark.offset_bottom = 116
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(mark)
	return panel


static func _reward_words(reward: Dictionary) -> String:
	var parts := []
	if reward.has("gold"):
		parts.append("%s vàng" % UiKit.format_number(reward["gold"]))
	if reward.has("gems"):
		parts.append("%d kim cương" % reward["gems"])
	if reward.has("stones"):
		parts.append("%d đá rèn" % reward["stones"])
	return ", ".join(parts)


static func _quest_row(home: Control, box: VBoxContainer, quest: Dictionary) -> Control:
	var id: String = quest["id"]
	var count := PlayerData.quest_count(id)
	var done := PlayerData.quest_done(id)
	var claimed := PlayerData.quest_is_claimed(id)
	var row := Ui.menu_panel("quests", "Well")
	var content := UiKit.hbox(12)
	row.add_child(content)
	var text := UiKit.vbox(4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var heading := UiKit.ink(quest["text"], 19)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(heading)
	var progress := UiKit.hbox(8)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bar := UiKit.bar(OK_GREEN if done else Color("5aa9e6"), Vector2(160, 12))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = quest["goal"]
	bar.value = count
	progress.add_child(bar)
	progress.add_child(UiKit.ink("%d/%d" % [count, quest["goal"]], 15))
	progress.add_child(UiKit.ink("+%d điểm" % Meta.QUEST_POINTS, 15))
	text.add_child(progress)
	content.add_child(text)
	content.add_child(_paper_rewards(quest["reward"], 18))
	var button: Button
	if claimed:
		button = UiKit.button("ĐÃ NHẬN", Vector2(120, 56), func(): pass)
		button.disabled = true
	elif done:
		button = UiKit.button("NHẬN", Vector2(120, 56), func():
			var got := PlayerData.claim_quest(id)
			UiKit.toast(home, got_text(got))
			_fill_quests(home, box), true)
	else:
		button = UiKit.button("ĐI", Vector2(120, 56), func():
			UiKit.close_popup(box)
			_go_to(home, id))
	button.add_theme_font_size_override("font_size", 17)
	content.add_child(button)
	if claimed:
		row.modulate = Color(0.7, 0.7, 0.7)
	return row


static func _go_to(home: Control, quest_id: String) -> void:
	match quest_id:
		"win":
			home.select_tab(home.BATTLE_TAB)
		"chest":
			home.select_tab(home.SHOP_TAB)
		"upgrade":
			home.select_tab(home.TROOPS_TAB)
		"patrol":
			home.open_page(PatrolPage)
		"summon":
			home.open_page(SummonPage)


# --- Profile ------------------------------------------------------------------------------

static func open_profile(home: Control) -> void:
	var box := UiKit.dark_popup(home, 680, "Hồ sơ")
	_fill_profile(home, box)


static func _fill_profile(home: Control, box: VBoxContainer) -> void:
	_clear(box)
	var top := UiKit.hbox(16)
	top.add_child(UiKit.avatar(120))
	var right := UiKit.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_row := UiKit.hbox(8)
	var name_edit := LineEdit.new()
	name_edit.text = PlayerData.player_name
	name_edit.max_length = 16
	name_edit.custom_minimum_size = Vector2(300, 52)
	name_edit.add_theme_font_size_override("font_size", 24)
	var edit_style := UiKit.card_style(UiKit.FRAME_BROWN, Color(0.03, 0.04, 0.06, 0.95))
	name_edit.add_theme_stylebox_override("normal", edit_style)
	name_edit.add_theme_stylebox_override("focus", UiKit.card_style(UiKit.GOLD_TEXT, Color(0.03, 0.04, 0.06, 0.95)))
	name_row.add_child(name_edit)
	var save := UiKit.button("LƯU", Vector2(100, 52), func():
		PlayerData.set_player_name(name_edit.text)
		UiKit.toast(home, "Đã đổi tên thành %s" % PlayerData.player_name))
	save.add_theme_font_size_override("font_size", 17)
	name_row.add_child(save)
	right.add_child(name_row)
	var stars := 0
	for index in PlayerData.level_stars:
		stars += PlayerData.level_stars[index]
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 24)
	var entries := [
		["Màn đã qua", "%d/%d" % [PlayerData.levels_cleared(), PlayerData.LEVELS.size()]],
		["Tổng sao", "%d ★" % stars],
		["Sức mạnh đội", UiKit.format_number(PlayerData.team_power())],
		["Trang bị", "%d món" % PlayerData.hero_cat["bag"].size()],
	]
	for entry in entries:
		stats.add_child(UiKit.ink(entry[0], 16))
		stats.add_child(UiKit.ink(entry[1], 18))
	right.add_child(stats)
	top.add_child(right)
	box.add_child(top)

	box.add_child(UiKit.ink("Ảnh đại diện", 20))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in range(1, Meta.AVATAR_COUNT + 1):
		grid.add_child(_avatar_choice(home, box, str(i), "Qua %d màn" % Meta.avatar_need(i)))
	box.add_child(grid)

	box.add_child(UiKit.ink("Khung", 20))
	var frames := UiKit.hbox(10)
	for id in Meta.FRAME_ORDER:
		frames.add_child(_frame_choice(home, box, id))
	box.add_child(frames)


static func _avatar_choice(home: Control, box: VBoxContainer, value: String, need: String) -> Control:
	var unlocked := PlayerData.avatar_unlocked(value)
	var choice := Button.new()
	choice.custom_minimum_size = Vector2(90, 90)
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "disabled"]:
		choice.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var picture := UiKit.avatar(86, value, PlayerData.frame if value == PlayerData.avatar else "wood")
	picture.anchor_left = 0.5
	picture.anchor_right = 0.5
	picture.offset_left = -43
	picture.offset_right = 43
	picture.offset_top = 2
	picture.offset_bottom = 88
	choice.add_child(picture)
	if value == PlayerData.avatar:
		var tick := UiKit.label("✓", 22, OK_GREEN)
		tick.anchor_left = 1.0
		tick.anchor_right = 1.0
		tick.offset_left = -26
		tick.offset_right = 0
		tick.offset_top = -4
		choice.add_child(tick)
	if not unlocked:
		picture.modulate = Color(0.3, 0.3, 0.35)
		var lock := UiKit.drawn(DrawnIcon.Kind.LOCK, 34)
		lock.anchor_left = 0.5
		lock.anchor_right = 0.5
		lock.offset_left = -17
		lock.offset_right = 17
		lock.offset_top = 19
		lock.offset_bottom = 53
		choice.add_child(lock)
		var text := UiKit.label(need, 12, UiKit.WARN)
		text.anchor_right = 1.0
		text.offset_top = 64
		text.offset_bottom = 84
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choice.add_child(text)
	choice.pressed.connect(func():
		if unlocked:
			PlayerData.set_avatar(value)
			_fill_profile(home, box)
		else:
			UiKit.toast(home, "Chưa mở: " + need))
	return choice


static func _frame_choice(home: Control, box: VBoxContainer, id: String) -> Control:
	var frame: Dictionary = Meta.FRAMES[id]
	var unlocked := PlayerData.frame_unlocked(id)
	var choice := Button.new()
	choice.custom_minimum_size = Vector2(140, 150)
	choice.focus_mode = Control.FOCUS_NONE
	var style := UiKit.card_style(UiKit.GOLD_TEXT if PlayerData.frame == id else UiKit.FRAME_BROWN)
	for state in ["normal", "hover", "pressed"]:
		choice.add_theme_stylebox_override(state, style)
	var column := UiKit.vbox(2)
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 6
	column.offset_right = -6
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice.add_child(column)
	var picture := UiKit.avatar(76, PlayerData.avatar, id)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(picture)
	var name_label := UiKit.label(frame["name"], 17, frame["color"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	var need := UiKit.label("Đang dùng" if PlayerData.frame == id else (frame["need"] if not unlocked else "Chọn"), 12, OK_GREEN if unlocked else UiKit.WARN)
	need.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(need)
	if not unlocked:
		picture.modulate = Color(0.35, 0.35, 0.4)
	choice.pressed.connect(func():
		if unlocked:
			PlayerData.set_frame(id)
			_fill_profile(home, box)
		else:
			UiKit.toast(home, "Chưa mở: " + frame["need"]))
	return choice
