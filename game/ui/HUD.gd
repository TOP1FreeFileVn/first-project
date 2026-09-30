extends CanvasLayer

# Battle HUD built in code: top status bar, the between-wave shop panel, the READY
# button, toast messages and the end-of-level panel with rewards. Styled through UiKit.

const UiKit = preload("res://game/ui/UiKit.gd")
const Economy = preload("res://game/core/Economy.gd")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const Coach = preload("res://game/ui/Coach.gd")

const INFO := UiKit.INFO
const WARN := UiKit.WARN
const LEAVE_CONFIRM_TIME := 2.0
const SHOP_POS := Vector2(20, 150)
const CARD_SIZE := Vector2(124, 196)

var battle

var _hp_bar: ProgressBar
var _hp_label: Label
var _wave_label: Label
var _meat_label: Label
var _meat_bar: ProgressBar
var _speed_button: Button
var _ready_button: Button
var _root: Control
var _shop_panel: PanelContainer
var _shop_box: VBoxContainer
var _shop_tween: Tween
var _cards: Array = []
var _shown_phase := ""
var _sell_zone: PanelContainer
var _message: Label
var _message_tween: Tween
var _end_panel: PanelContainer
var _end_box: VBoxContainer
var _leave_armed_until := 0.0


func bind(p_battle) -> void:
	battle = p_battle
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiKit.make_theme()
	add_child(root)
	_root = root
	_build_top_bar(root)
	_build_shop(root)
	_build_controls(root)
	_build_message(root)
	# Tutorial and new-tile guidance, above the shop but under the result panel.
	var coach = Coach.new()
	coach.setup(self, battle)
	root.add_child(coach)
	_build_end_panel(root)


func show_message(text: String, color := INFO) -> void:
	_message.text = text
	_message.add_theme_color_override("font_color", color)
	if _message_tween:
		_message_tween.kill()
	_message.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(2.6)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.5)


## `reward` comes from PlayerData.grant_battle_rewards().
func show_end(won: bool, stars: int, detail: String, reward: Dictionary) -> void:
	for child in _end_box.get_children():
		child.queue_free()
	var title := UiKit.ink("CHIẾN THẮNG!" if won else "THÀNH ĐÃ THẤT THỦ", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_box.add_child(title)
	if won:
		var star_label := UiKit.label("★".repeat(stars) + "☆".repeat(3 - stars), 48, UiKit.GOLD_TEXT)
		star_label.add_theme_color_override("font_outline_color", UiKit.INK)
		star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_end_box.add_child(star_label)
	var detail_label := UiKit.ink(detail, 18)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_box.add_child(detail_label)

	var heading := UiKit.ink("Phần thưởng" + (" · Lần đầu x2!" if reward.get("first_clear", false) else ""), 20)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_box.add_child(heading)
	var loot := UiKit.hbox(18)
	loot.alignment = BoxContainer.ALIGNMENT_CENTER
	loot.add_child(UiKit.price("gold", reward.get("gold", 0), 22, true))
	if reward.get("gems", 0) > 0:
		loot.add_child(UiKit.price("gems", reward["gems"], 22, true))
	_end_box.add_child(loot)
	var cards: Dictionary = reward.get("cards", {})
	if not cards.is_empty():
		var card_row := UiKit.hbox(10)
		card_row.alignment = BoxContainer.ALIGNMENT_CENTER
		for id in cards:
			var card := UiKit.vbox(0)
			card.add_child(UiKit.troop_portrait(PlayerData.TROOPS[id], 56))
			var count := UiKit.ink("x%d" % cards[id], 16)
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			card.add_child(count)
			card_row.add_child(card)
		_end_box.add_child(card_row)
	if reward.get("gift", "") != "":
		var gift := UiKit.ink("Mở khoá lính mới: %s!" % PlayerData.TROOPS[reward["gift"]].display_name, 18)
		gift.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_end_box.add_child(gift)

	var buttons := UiKit.hbox(10)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_child(UiKit.button("VỀ SẢNH", Vector2(150, 58), func(): battle.go_home(), true))
	buttons.add_child(UiKit.button("CHƠI LẠI", Vector2(150, 58), func(): battle.restart()))
	if won and PlayerData.has_next_level():
		buttons.add_child(UiKit.button("MÀN TIẾP", Vector2(150, 58), func(): battle.next_level()))
	_end_box.add_child(buttons)
	_end_panel.visible = true
	# The victory chest opens on top of the result panel; the simulator (no persist) and
	# "fast chest" players just see the cards listed above.
	if won and not cards.is_empty() and PlayerData.persist and not PlayerData.fast_chest:
		var opening = ChestOpening.new()
		opening.setup(Economy.CHESTS["victory"]["name"], Color("8a5a2b"), {"cards": cards, "gold": 0}, reward.get("new", []))
		opening.attach(self)


func _process(_delta: float) -> void:
	if battle == null:
		return
	var core = battle.core
	_hp_bar.max_value = core.max_hp
	_hp_bar.value = core.hp
	_hp_label.text = "%d" % ceili(core.hp)
	_wave_label.text = "Đợt %d/%d" % [battle.wave_number(), battle.waves.total()]
	var whole := floori(core.meat)
	_meat_label.text = "%d/%d" % [whole, core.max_meat]
	_meat_bar.value = core.meat / maxf(core.max_meat, 1.0)
	_sell_zone.modulate = Color(1.3, 1.3, 1.3) if battle.board.is_dragging() else Color(1, 1, 1, 0.7)
	if battle.phase == "shop":
		_ready_button.text = "SẴN SÀNG ▶ ĐỢT %d" % battle.wave_number()
		_ready_button.disabled = false
	elif battle.phase == "fight":
		_ready_button.text = "ĐANG ĐÁNH · còn %d địch" % (battle.enemy_units.size() + battle.waves.pending())
		_ready_button.disabled = true
	else:
		_ready_button.text = "HẾT TRẬN"
		_ready_button.disabled = true
	if battle.phase != _shown_phase:
		_shown_phase = battle.phase
		_show_shop(battle.phase == "shop")
	_speed_button.text = "x%d" % roundi(Engine.time_scale)


func _on_leave_pressed() -> void:
	if not battle.accepts_input():
		battle.go_home()
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < _leave_armed_until:
		battle.go_home()
	else:
		_leave_armed_until = now + LEAVE_CONFIRM_TIME
		show_message("Chạm lần nữa để rời trận (không nhận thưởng)", WARN)


func _build_top_bar(root: Control) -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 104)
	var style := UiKit.dark_style(0)
	style.set_border_width_all(0)
	style.border_width_bottom = 3
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	bar.add_theme_stylebox_override("panel", style)
	root.add_child(bar)
	var rows := UiKit.vbox(2)
	bar.add_child(rows)

	# Row 1: leave, level name, game speed.
	var top := UiKit.hbox()
	rows.add_child(top)
	var leave := UiKit.button("", Vector2(48, 44), _on_leave_pressed)
	leave.icon = SpriteLib.texture(UiKit.UI + "Icons/Icon_08.png")
	leave.expand_icon = true
	top.add_child(leave)
	top.add_child(UiKit.ribbon(battle.level.display_name, 18))
	top.add_child(UiKit.spacer())
	_speed_button = UiKit.button("x1", Vector2(64, 44), _toggle_speed)
	top.add_child(_speed_button)

	# Row 2: castle HP, wave, meat.
	var stats := UiKit.hbox()
	rows.add_child(stats)
	stats.add_child(UiKit.icon(SpriteLib.cozy(UiKit.COZY_HEART) if UiKit.is_cozy() else SpriteLib.texture("Buildings/Blue Buildings/Castle.png"), 34 if UiKit.is_cozy() else 40))
	_hp_bar = UiKit.bar(Color("e2574c"), Vector2(170, 16))
	stats.add_child(_hp_bar)
	_hp_label = UiKit.label("", 18)
	_hp_label.custom_minimum_size.x = 38
	stats.add_child(_hp_label)
	stats.add_child(UiKit.gap(4))
	stats.add_child(UiKit.icon(SpriteLib.texture(UiKit.UI + "Icons/Icon_05.png"), 32))
	_wave_label = UiKit.label("", 19)
	_wave_label.custom_minimum_size.x = 92
	stats.add_child(_wave_label)
	stats.add_child(UiKit.gap(4))
	stats.add_child(UiKit.icon(SpriteLib.texture(UiKit.MEAT), 36))
	var meat_box := UiKit.vbox(2)
	meat_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_meat_label = UiKit.label("", 19)
	meat_box.add_child(_meat_label)
	_meat_bar = UiKit.bar(Color("f2b35c"), Vector2(64, 7))
	_meat_bar.max_value = 1.0
	meat_box.add_child(_meat_bar)
	stats.add_child(meat_box)


func _build_controls(root: Control) -> void:
	var sell_rect: Rect2 = battle.SELL_RECT
	_sell_zone = PanelContainer.new()
	_sell_zone.position = sell_rect.position
	_sell_zone.size = sell_rect.size
	_sell_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sell_zone.add_theme_stylebox_override("panel", UiKit.button_style("SmallRedSquareButton_Regular.png"))
	var sell_text := UiKit.label("BÁN\nkéo gear vào", 15)
	sell_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sell_zone.add_child(sell_text)
	root.add_child(_sell_zone)

	_ready_button = UiKit.button("", Vector2(520, 80), func(): battle.start_wave())
	_ready_button.position = Vector2(182, 1194)
	_ready_button.add_theme_font_size_override("font_size", 26)
	root.add_child(_ready_button)


func _build_message(root: Control) -> void:
	_message = UiKit.label("", 21)
	_message.position = Vector2(30, 116)
	_message.size = Vector2(660, 40)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var style := UiKit.dark_style(8)
	style.set_border_width_all(0)
	style.content_margin_top = 4
	style.content_margin_bottom = 6
	_message.add_theme_stylebox_override("normal", style)
	_message.modulate.a = 0.0
	root.add_child(_message)


func _build_end_panel(root: Control) -> void:
	_end_panel = PanelContainer.new()
	_end_panel.custom_minimum_size = Vector2(560, 0)
	_end_panel.add_theme_stylebox_override("panel", UiKit.paper_style())
	root.add_child(_end_panel)
	_end_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_end_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_end_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_end_box = UiKit.vbox(10)
	_end_panel.add_child(_end_box)
	_end_panel.visible = false


func _toggle_speed() -> void:
	Engine.time_scale = 1.0 if Engine.time_scale > 1.5 else 2.0


# --- Between-wave shop ------------------------------------------------------------------

## Called by Battle after a wave: shows what it paid, with the meat flying to the counter.
func on_wave_cleared(index: int, income: int, interest: int) -> void:
	show_message("Xong đợt %d! +%d thịt%s" % [index + 1, income, " (lãi +%d)" % interest if interest > 0 else ""])
	var gain := UiKit.label("+%d" % (income + interest), 34, Color("ffd35c"))
	gain.add_theme_constant_override("outline_size", 8)
	gain.position = Vector2(560, 150)
	gain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(gain)
	var tween := gain.create_tween()
	tween.tween_property(gain, "position", Vector2(600, 56), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(gain, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.tween_callback(gain.queue_free)


func _build_shop(root: Control) -> void:
	_shop_panel = PanelContainer.new()
	var style: StyleBox
	if UiKit.is_cozy():
		style = UiKit.panel_style()
	else:
		var dark := UiKit.dark_style(16, Color("c9a14a"))
		dark.set_border_width_all(3)
		dark.bg_color = Color(0.05, 0.08, 0.11, 0.94)
		style = dark
	_shop_panel.add_theme_stylebox_override("panel", style)
	_shop_panel.position = SHOP_POS
	_shop_panel.size = Vector2(680, 0)
	_shop_panel.custom_minimum_size = Vector2(680, 0)
	root.add_child(_shop_panel)
	_shop_box = UiKit.vbox(10)
	_shop_panel.add_child(_shop_box)
	battle.shop_changed.connect(_refresh_shop)
	_refresh_shop()


# Rebuilt whenever the shop, the meat or the board's merge options change.
func _refresh_shop() -> void:
	for child in _shop_box.get_children():
		_shop_box.remove_child(child)
		child.queue_free()
	var number: int = battle.wave_number()
	var heading := UiKit.ribbon("LƯỢT NGHỈ · Đợt %d/%d sắp tới" % [number, battle.waves.total()], 20, UiKit.Ribbon.YELLOW)
	_shop_box.add_child(heading)

	# Next wave preview.
	var preview := UiKit.hbox(6)
	preview.alignment = BoxContainer.ALIGNMENT_CENTER
	preview.add_child(UiKit.label("Quân địch:", 16, UiKit.WARN))
	var foes: Dictionary = battle.waves.preview(number - 1)
	for id in foes:
		var portrait := UiKit.troop_portrait(PlayerData.TROOPS[id], 40, "Black" if foes[id]["elite"] else "Red")
		preview.add_child(portrait)
		preview.add_child(UiKit.label("x%d%s" % [foes[id]["count"], "★" if foes[id]["elite"] else ""], 15))
	_shop_box.add_child(preview)

	var cards := UiKit.hbox(8)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.clear()
	for slot in battle.shop.size():
		var card := _shop_card(slot)
		cards.add_child(card)
		_cards.append(card)
	_shop_box.add_child(cards)

	var tools := UiKit.hbox(10)
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	var cost: int = battle.reroll_cost()
	var reroll := UiKit.button("ĐỔI SHOP  " + ("miễn phí" if cost == 0 else "%d thịt" % cost), Vector2(250, 60), func(): battle.reroll())
	reroll.add_theme_font_size_override("font_size", 18)
	reroll.disabled = not battle.core.can_afford(cost)
	tools.add_child(reroll)
	var lock := UiKit.button("ĐÃ KHOÁ" if battle.shop_locked else "KHOÁ SHOP", Vector2(190, 60), func(): battle.toggle_lock(), battle.shop_locked)
	lock.add_theme_font_size_override("font_size", 18)
	tools.add_child(lock)
	_shop_box.add_child(tools)

	var pay: Array = battle.income_preview()
	var info := UiKit.label("Hết đợt nhận +%d thịt · lãi +%d (mỗi 5 thịt để dành = +1)" % [pay[0], pay[1]], 15, INFO)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_box.add_child(info)


func _shop_card(slot: int) -> Button:
	var offer: Dictionary = battle.shop[slot]
	var troop: Resource = PlayerData.TROOPS[offer["id"]]
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	var style := UiKit.dark_style(12, Economy.RARITY_COLORS[troop.rarity])
	style.set_border_width_all(4 if offer["tier"] > 1 else 3)
	style.bg_color = Color(0.1, 0.13, 0.17, 0.97) if troop.rarity < 3 else Color(0.2, 0.14, 0.05, 0.97)
	for state in ["normal", "hover", "pressed", "disabled"]:
		card.add_theme_stylebox_override(state, style)
	card.pressed.connect(_on_card_pressed.bind(slot))
	var column := UiKit.vbox(0)
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	if offer["sold"]:
		var sold := UiKit.label("ĐÃ MUA", 17, Color(1, 1, 1, 0.5))
		sold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(sold)
		card.disabled = true
		card.modulate = Color(1, 1, 1, 0.45)
		return card
	var rarity := UiKit.label(Economy.RARITY_NAMES[troop.rarity], 13, Economy.RARITY_COLORS[troop.rarity])
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(rarity)
	var portrait := UiKit.troop_portrait(troop, 78, SpriteLib.player_color(offer["tier"]))
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(portrait)
	var name_label := UiKit.label(troop.display_name, 15)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	column.add_child(name_label)
	if offer["tier"] > 1:
		var tier := UiKit.label("BẬC %d" % offer["tier"], 14, UiKit.GOLD_TEXT)
		tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(tier)
	var affordable: bool = battle.core.can_afford(offer["price"])
	var price := UiKit.hbox(4)
	price.alignment = BoxContainer.ALIGNMENT_CENTER
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.add_child(UiKit.icon(SpriteLib.texture(UiKit.MEAT), 26))
	price.add_child(UiKit.label(str(offer["price"]), 20, Color.WHITE if affordable else WARN))
	column.add_child(price)
	if not affordable or battle.board.is_full():
		card.modulate = Color(0.7, 0.7, 0.7)
	if battle.offer_merges(slot):
		var badge := UiKit.label("GHÉP ĐƯỢC", 12, Color("7fd66b"))
		var badge_style := UiKit.dark_style(6, Color("7fd66b"))
		badge_style.set_content_margin_all(3)
		badge.add_theme_stylebox_override("normal", badge_style)
		badge.position = Vector2(14, -12)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)
	return card


func _on_card_pressed(slot: int) -> void:
	var from: Vector2 = _cards[slot].global_position + CARD_SIZE / 2.0
	var troop: Resource = PlayerData.TROOPS[battle.shop[slot]["id"]]
	var gear = battle.buy(slot)
	if gear == null:
		return
	# A ghost of the portrait flies from the card down to the gear it became.
	var ghost := UiKit.troop_portrait(troop, 78)
	ghost.position = from - Vector2(39, 39)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "position", gear.global_position - Vector2(39, 39), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.6, 0.6), 0.3)
	tween.tween_callback(ghost.queue_free)


# The shop slides away when a wave starts and back when it ends.
func _show_shop(visible_now: bool) -> void:
	if _shop_tween:
		_shop_tween.kill()
	_shop_tween = create_tween()
	if visible_now:
		_shop_panel.visible = true
		_shop_tween.tween_property(_shop_panel, "position:y", SHOP_POS.y, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_shop_tween.tween_property(_shop_panel, "position:y", -700.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_shop_tween.tween_callback(func(): _shop_panel.visible = false)
