extends Control

# A dedicated training screen. Only the information area scrolls; the selected
# troop, upgrade mode and confirmation remain visible on a phone.
signal team_requested(id: String)

const Ui = preload("res://game/ui/Ui.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const Economy = preload("res://game/core/Economy.gd")
const Cats = preload("res://game/data/Cats.gd")
const INK := Color("583f21")
const MUTED := Color("6b563b")
const GAIN := Color("32663b")
const RARITY_TONES := [Color("82c96e"), Color("74bce7"), Color("b98be8"), Color("f5b967")]

var troop_id := ""
var mode := "level"
var _layer: CanvasLayer
var _hero: VBoxContainer
var _content: VBoxContainer
var _scroll: ScrollContainer
var _footer: VBoxContainer
var _gold: Label
var _level_tab: Button
var _star_tab: Button
var _feedback: Label
var _refresh_pending := false
var _feedback_tween: Tween
var _celebrate := false


func attach(host: Control, id: String) -> void:
	troop_id = id
	if PlayerData.is_unlocked(id) and PlayerData.level_up_cost(id) < 0 and PlayerData.star_up_cost(id) >= 0:
		mode = "star"
	_layer = CanvasLayer.new()
	_layer.name = "TroopUpgradeLayer"
	_layer.layer = 20
	host.add_child(_layer)
	_layer.add_child(self)
	Ui.register_menu_surface(host, _layer, "troops")


func _ready() -> void:
	name = "TroopUpgradeScreen"
	Ui.setup_root(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var margin := Ui.margin(24, 20, 24, 24)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layout := Ui.vbox(16)
	margin.add_child(layout)

	var header := Ui.hbox(16)
	var back := Ui.button("", "Red", Vector2(76, 76), 26, "back")
	back.name = "TroopUpgradeBack"
	back.tooltip_text = "Quay lại danh sách lính"
	back.pressed.connect(close)
	header.add_child(back)
	var title := _text("Nâng cấp lính", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var wallet := Ui.hbox(8)
	wallet.add_child(Ui.icon("coin", 32))
	_gold = _text("", 24)
	wallet.add_child(_gold)
	header.add_child(wallet)
	layout.add_child(header)

	_hero = Ui.vbox(2)
	_hero.name = "TroopUpgradeHero"
	layout.add_child(_hero)

	var tabs := Ui.hbox(12)
	for tab_mode in ["level", "star"]:
		var tab := Ui.button("Nâng cấp" if tab_mode == "level" else "Lên sao", "Tab", Vector2(0, 72), 26)
		tab.name = "TroopUpgradeLevelTab" if tab_mode == "level" else "TroopUpgradeStarTab"
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(_choose_mode.bind(tab_mode))
		tabs.add_child(tab)
		if tab_mode == "level":
			_level_tab = tab
		else:
			_star_tab = tab
	layout.add_child(tabs)

	_scroll = ScrollContainer.new()
	_scroll.name = "TroopUpgradeScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size.y = 100
	layout.add_child(_scroll)
	_content = Ui.vbox(18)
	_content.name = "TroopUpgradeContent"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)

	_footer = Ui.vbox(6)
	var footer_panel := Ui.menu_panel("troops", "Well", _footer)
	footer_panel.name = "TroopUpgradeActionDock"
	layout.add_child(footer_panel)
	_feedback = _text("", 22, GAIN)
	_feedback.name = "TroopUpgradeFeedback"
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.custom_minimum_size.y = 32
	# Space is reserved so a confirmation never shifts the action under a finger.
	layout.add_child(_feedback)
	PlayerData.changed.connect(_queue_refresh)
	_refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if is_instance_valid(_layer):
		_layer.queue_free()


func _queue_refresh() -> void:
	if _refresh_pending:
		return
	_refresh_pending = true
	_refresh.call_deferred()


func _refresh() -> void:
	_refresh_pending = false
	var troop: Resource = PlayerData.TROOPS[troop_id]
	var state: Dictionary = PlayerData.troop(troop_id)
	_gold.text = UiKit.format_number(PlayerData.gold)
	for box in [_hero, _content, _footer]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
	_build_hero(troop, state)
	for pair in [[_level_tab, "level"], [_star_tab, "star"]]:
		var tab: Button = pair[0]
		var selected: bool = pair[1] == mode
		tab.theme_type_variation = "BtnYellow" if selected else "BtnTab"
		tab.add_theme_constant_override("outline_size", 0)
		for color in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			tab.add_theme_color_override(color, INK)
		tab.disabled = not state.unlocked
	_build_stats(troop, state)
	_build_footer(state)
	if _celebrate:
		_celebrate = false
		_animate_portrait.call_deferred()


func _build_hero(troop: Resource, state: Dictionary) -> void:
	var stage := Control.new()
	stage.name = "TroopUpgradeStage"
	stage.custom_minimum_size.y = 202
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.add_child(stage)
	var halo := Panel.new()
	var halo_style := StyleBoxFlat.new()
	halo_style.bg_color = RARITY_TONES[troop.rarity].lerp(Color("d5dfba"), 0.25)
	halo_style.bg_color.a = 0.6 if state.unlocked else 0.3
	halo_style.set_corner_radius_all(104)
	halo_style.anti_aliasing = true
	halo.add_theme_stylebox_override("panel", halo_style)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(halo)
	halo.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	halo.offset_left = -104
	halo.offset_right = 104
	halo.offset_top = -96
	halo.offset_bottom = 96
	var portrait: Control = UiKit.troop_portrait(troop, 208, SpriteLib.player_color(1 + 2 * (state.stars - 1)))
	if not state.unlocked:
		portrait.modulate = Color.BLACK
		var silhouette := Control.new()
		silhouette.custom_minimum_size = Vector2(208, 208)
		silhouette.add_child(portrait)
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var question := _text("?", 92, Color("fff0d3"))
		question.name = "TroopUpgradeLockedQuestion"
		question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		silhouette.add_child(question)
		question.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		portrait = silhouette
	portrait.name = "TroopUpgradePortrait"
	var center := Ui.center(portrait)
	stage.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var badges := Ui.vbox(6)
	badges.position = Vector2(0, 4)
	stage.add_child(badges)
	var rarity := Ui.menu_tag(Economy.RARITY_NAMES[troop.rarity])
	rarity.scale = Vector2.ONE * 0.8
	var rarity_slot := Control.new()
	rarity_slot.custom_minimum_size = Vector2(160, 48)
	rarity_slot.add_child(rarity)
	badges.add_child(rarity_slot)
	badges.add_child(_text(troop.KLASS_NAMES[troop.klass], 22))
	var cards := Ui.hbox(6, BoxContainer.ALIGNMENT_BEGIN)
	cards.add_child(Ui.icon("troop_star", 24))
	cards.add_child(_text("%d thẻ" % state.cards, 22))
	badges.add_child(cards)

	var heading := _text(troop.display_name, 32)
	heading.name = "TroopUpgradeName"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hero.add_child(heading)
	var world := _text("Bản thể ở " + Cats.WORLD_NAMES.get(Cats.world_of(troop_id), ""), 21, MUTED)
	world.name = "TroopUpgradeWorld"
	world.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hero.add_child(world)
	var rank := Ui.hbox(10)
	var level := _text("Cấp %d / %d" % [state.level, PlayerData.level_cap(troop_id)] if state.unlocked else "Chưa mở khóa", 23)
	level.name = "TroopUpgradeLevel"
	badges.add_child(level)
	var stars := Ui.hbox(0)
	stars.name = "TroopUpgradeStars"
	if state.unlocked:
		for i in state.stars:
			stars.add_child(Ui.icon("troop_star", 34))
	rank.add_child(stars)
	_hero.add_child(rank)
	var desc := _text(troop.description, 22, MUTED)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hero.add_child(desc)


func _build_stats(troop: Resource, state: Dictionary) -> void:
	if not state.unlocked:
		var locked := _text("Triệu hồi lính hoặc thắng trận để nhận thẻ và mở khóa lính này.", 26)
		locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(Ui.menu_panel("troops", "Board", locked))
		_build_ability(troop)
		return
	var level_cost := PlayerData.level_up_cost(troop_id)
	var star_cost := PlayerData.star_up_cost(troop_id)
	var has_next := level_cost >= 0 if mode == "level" else star_cost >= 0
	var mult: float = PlayerData.troop_multiplier(troop_id)
	var next_mult := mult
	if has_next:
		next_mult = Economy.troop_multiplier(state.level + (1 if mode == "level" else 0), state.stars + (1 if mode == "star" else 0))
	var stats := Ui.vbox(10)
	stats.name = "TroopUpgradeStats"
	var heading := Ui.hbox(8)
	var title := _text("Chỉ số", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(_text("Sau nâng cấp" if mode == "level" else "Sau lên sao", 20, GAIN))
	stats.add_child(heading)
	var values := GridContainer.new()
	values.columns = 2
	values.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	values.add_theme_constant_override("h_separation", 14)
	values.add_theme_constant_override("v_separation", 12)
	_stat_tile(values, "Máu", "%.1f" % (troop.max_hp * mult), "+%.1f" % (troop.max_hp * (next_mult - mult)) if has_next else "", "heart")
	if troop.role != 3:
		_stat_tile(values, "Hồi máu" if troop.role == 2 else "Sát thương", "%.1f" % (troop.damage * mult), "+%.1f" % (troop.damage * (next_mult - mult)) if has_next else "", "paw" if troop.role == 2 else "w_kiem")
	_stat_tile(values, "Giới hạn cấp" if mode == "star" else "Cấp lính", str(PlayerData.level_cap(troop_id)) if mode == "star" else str(state.level), "→ %d" % ((state.stars + 1) * Economy.LEVELS_PER_STAR if mode == "star" else state.level + 1) if has_next else "Tối đa", "troop_star" if mode == "star" else "badge_up")
	_stat_tile(values, "Sinh lính", "%.1f giây" % troop.spawn_interval, "", "tab_army")
	stats.add_child(values)
	_content.add_child(Ui.menu_panel("troops", "Board", stats))
	_build_ability(troop)

	var details := GridContainer.new()
	details.columns = 2
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("h_separation", 20)
	details.add_theme_constant_override("v_separation", 12)
	if troop.role != 3:
		_detail_item(details, "Tầm đánh", "%d" % troop.attack_range)
		_detail_item(details, "Hồi chiêu", "%.1f giây" % troop.attack_cooldown)
	_detail_item(details, "Tốc chạy", "%d" % troop.move_speed)
	_detail_item(details, "Trên chiến trường", "Tối đa %d lính" % troop.max_alive)
	if troop.crit_factor() > 1.0:
		_detail_item(details, "Chí mạng", "%d%% · ×%s" % [roundi(troop.crit_chance * 100.0), String.num(troop.crit_mult, 2)])
	_content.add_child(details)


func _stat_tile(grid: GridContainer, caption: String, current: String, gain: String, icon_name: String) -> void:
	var box := Ui.vbox(2)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Ui.hbox(6, BoxContainer.ALIGNMENT_BEGIN)
	title.add_child(Ui.icon(icon_name, 26))
	title.add_child(_text(caption, 20, MUTED))
	box.add_child(title)
	var row := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	row.add_child(_text(current, 28))
	row.add_child(_text(gain, 24, GAIN))
	box.add_child(row)
	grid.add_child(box)


func _detail_item(grid: GridContainer, title: String, value: String) -> void:
	var box := Ui.vbox(0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_text(title, 20, MUTED))
	var number := _text(value, 23)
	number.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(number)
	grid.add_child(box)


func _build_ability(troop: Resource) -> void:
	if troop.ability_text.is_empty():
		return
	var box := Ui.vbox(8)
	box.add_child(_text("Kỹ năng", 26))
	var text := _text(troop.ability_text, 23)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	_content.add_child(Ui.menu_panel("troops", "Well", box))


func _build_footer(state: Dictionary) -> void:
	var cost := PlayerData.level_up_cost(troop_id) if mode == "level" else PlayerData.star_up_cost(troop_id)
	var available: int = PlayerData.gold if mode == "level" else state.cards
	var hint := ""
	var action := "NÂNG CẤP" if mode == "level" else "LÊN SAO"
	if not state.unlocked:
		hint = "Thu thập thẻ lính từ Triệu hồi và rương chiến thắng"
		action = "CHƯA MỞ KHÓA"
	elif cost < 0:
		if mode == "level" and state.stars < Economy.MAX_STARS:
			hint = "Lên sao để mở thêm %d cấp lính" % Economy.LEVELS_PER_STAR
			action = "CẦN LÊN SAO"
		else:
			hint = "Lính đã đạt cấp tối đa" if mode == "level" else "Đã đạt số sao tối đa"
			action = "CẤP TỐI ĐA" if mode == "level" else "SAO TỐI ĐA"
	else:
		if mode == "level":
			hint = "Cấp %d  →  Cấp %d" % [state.level, state.level + 1]
		else:
			hint = "%d sao  →  %d sao · Mở giới hạn cấp %d" % [state.stars, state.stars + 1, (state.stars + 1) * Economy.LEVELS_PER_STAR]
		var resource := Ui.hbox(8)
		resource.name = "TroopUpgradeResource"
		resource.add_child(Ui.icon("coin" if mode == "level" else "troop_star", 28))
		resource.add_child(_text("Cần %s xu" % UiKit.format_number(cost) if mode == "level" else "%d / %d thẻ" % [state.cards, cost], 24))
		resource.add_child(_text("· Thiếu %s" % UiKit.format_number(cost - available), 20, Color("994d35")) if available < cost else _text("· Đủ nâng cấp", 20, GAIN))
		_footer.add_child(resource)
	var actions := Ui.hbox(12)
	var primary := Ui.button(action, "Green", Vector2(0, 96), 26)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.name = "TroopUpgradePrimary"
	primary.disabled = not state.unlocked or cost < 0 or available < cost
	primary.pressed.connect(_upgrade)
	actions.add_child(primary)
	var in_team: bool = PlayerData.in_team(troop_id)
	# Another version of this cat in the team: joining swaps it out.
	var same := PlayerData.team_same_cat(troop_id)
	var join := "THAY BẢN THỂ" if same != "" and not in_team else "VÀO ĐỘI"
	var team := Ui.button("RỜI ĐỘI" if in_team else join, "Yellow", Vector2(0, 96), 26)
	team.name = "TroopUpgradeTeam"
	team.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team.disabled = not state.unlocked or (in_team and PlayerData.battle_team().size() <= 1)
	team.tooltip_text = "Đội phải còn ít nhất 1 lính" if in_team and team.disabled else ""
	team.pressed.connect(func():
		if PlayerData.in_team(troop_id):
			PlayerData.remove_from_team(troop_id)
		else:
			team_requested.emit(troop_id))
	actions.add_child(team)
	_footer.add_child(actions)
	var note := _text(hint, 21, MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer.add_child(note)


func _choose_mode(chosen: String) -> void:
	if chosen == mode:
		return
	mode = chosen
	_scroll.scroll_vertical = 0
	_refresh()


func _upgrade() -> void:
	var upgraded: bool = PlayerData.level_up(troop_id) if mode == "level" else PlayerData.star_up(troop_id)
	if not upgraded:
		return
	_celebrate = true
	_feedback.text = "Đã lên cấp %d!" % PlayerData.troop(troop_id).level if mode == "level" else "Đã lên %d sao!" % PlayerData.troop(troop_id).stars
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback.modulate.a = 1.0
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(1.4)
	_feedback_tween.tween_property(_feedback, "modulate:a", 0.0, 0.3)


func _animate_portrait() -> void:
	var portrait := find_child("TroopUpgradePortrait", true, false) as Control
	if portrait == null:
		return
	portrait.pivot_offset = portrait.size / 2.0
	var tween := portrait.create_tween()
	tween.tween_property(portrait, "scale", Vector2.ONE * 1.06, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(portrait, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func _text(caption: String, font_size: int, color := INK) -> Label:
	var label := Ui.label(caption, "LabelDark", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 0)
	return label
