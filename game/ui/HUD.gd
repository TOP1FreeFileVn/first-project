extends CanvasLayer

# Battle HUD in the game skin (game/ui/Ui.gd + the SVG theme): top status (leave, level plaque,
# speed; castle HP bar, wave pill, coins), the between-wave shop sheet with rarity offer cards,
# READY along the bottom, replaced by a sell drop target during a gear drag;
# a toast pill and the result sheet.
# Layout follows Figma UI-013 (field on top, board below). In battle, xu (the sheet's Coin)
# buys gears; cá is the army's food: living cats fill the basket (the sheet's Population).

const UiKit = preload("res://game/ui/UiKit.gd")
const Ui = preload("res://game/ui/Ui.gd")
const Economy = preload("res://game/core/Economy.gd")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const Coach = preload("res://game/ui/Coach.gd")

const INFO := Color("fff2c2")
const WARN := Color("ff9c8a")
const LEAVE_CONFIRM_TIME := 2.0
const SHOP_POS := Vector2(20, 150)
const CARD_SIZE := Vector2(150, 200)
## Rarity index → card tone.
const TONES := ["green", "blue", "purple", "orange"]

var battle

var _hp_bar: ProgressBar
var _hp_label: Label
var _wave_label: Label
var _wave_bar: ProgressBar
var _coin_label: Label
var _coin_bar: ProgressBar
var _fish_label: Label
var _speed_button: Button
var _ready_button: Button
var _root: Control
var _shop_panel: PanelContainer
var _shop_box: VBoxContainer
var _shop_tween: Tween
var _cards: Array = []
var _shown_phase := ""
var _sell_zone: Panel
var _sell_headline: Label
var _sell_instruction: Label
var _sell_refund: Label
var _sell_face: StyleBoxFlat
var _sell_hover_face: StyleBoxFlat
var _message_box: PanelContainer
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
	root.theme = Ui.THEME
	root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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
	_message_box.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(2.6)
	_message_tween.tween_property(_message_box, "modulate:a", 0.0, 0.5)


## Pixel-art troop portrait kept crisp inside the smooth skin.
func _portrait(troop: Resource, size: float, color := "Blue") -> TextureRect:
	var p := UiKit.troop_portrait(troop, size, color)
	if not SpriteLib.is_cat(troop.unit_key):
		p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return p


func _tone(rarity: int) -> String:
	return TONES[clampi(rarity, 0, TONES.size() - 1)]


## `reward` comes from PlayerData.grant_battle_rewards().
func show_end(won: bool, stars: int, detail: String, reward: Dictionary) -> void:
	for child in _end_box.get_children():
		child.queue_free()
	_end_box.add_child(Ui.center(Ui.title_plaque("CHIẾN THẮNG!" if won else "THÀNH THẤT THỦ", "", 28)))
	if won:
		var star_row := Ui.hbox(6)
		for i in 3:
			star_row.add_child(Ui.icon("star" if i < stars else "star_off", 64 if i == 1 else 52))
		_end_box.add_child(star_row)
	_end_box.add_child(Ui.label(detail, "LabelDark", 19))

	var heading := Ui.label("Phần thưởng" + (" · Lần đầu x2!" if reward.get("first_clear", false) else ""), "LabelDark", 21)
	_end_box.add_child(heading)
	var loot := Ui.hbox(22)
	for item in [["coin", reward.get("gold", 0)], ["gem", reward.get("gems", 0)]]:
		if item[1] > 0 or item[0] == "coin":
			var c := Ui.hbox(6)
			c.add_child(Ui.icon(item[0], 40))
			c.add_child(Ui.label(UiKit.format_number(item[1]), "LabelDark", 24))
			loot.add_child(c)
	if reward.get("stones", 0) > 0:
		# Forge Stones for the hero cat's equipment.
		var st := Ui.hbox(6)
		st.add_child(UiKit.forge_stone_icon(40))
		st.add_child(Ui.label(UiKit.format_number(reward["stones"]), "LabelDark", 24))
		loot.add_child(st)
	_end_box.add_child(Ui.panel("Well", loot))
	var cards: Dictionary = reward.get("cards", {})
	if not cards.is_empty():
		var card_row := Ui.hbox(10)
		for id in cards:
			var troop: Resource = PlayerData.TROOPS[id]
			var card := Ui.panel("CardUnit" + _tone(troop.rarity).capitalize())
			var col := Ui.vbox(0)
			col.add_child(Ui.center(_portrait(troop, 60)))
			col.add_child(Ui.label("x%d" % cards[id], "LabelSmall", 17))
			card.add_child(col)
			card_row.add_child(card)
		_end_box.add_child(card_row)
	if reward.get("gift", "") != "":
		_end_box.add_child(Ui.label("Mở khoá lính mới: %s!" % PlayerData.TROOPS[reward["gift"]].display_name, "LabelDark", 19))

	var buttons := Ui.hbox(10)
	var home := Ui.button("Về sảnh", "Red", Vector2(160, 70), 22)
	home.pressed.connect(func(): battle.go_home())
	buttons.add_child(home)
	var again := Ui.button("Chơi lại", "Blue", Vector2(160, 70), 22)
	again.pressed.connect(func(): battle.restart())
	buttons.add_child(again)
	if won and PlayerData.has_next_level():
		var next := Ui.button("Màn tiếp", "Yellow", Vector2(170, 70), 22)
		next.pressed.connect(func(): battle.next_level())
		buttons.add_child(next)
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
	var total: int = battle.waves.total()
	_wave_label.text = "Đợt %d/%d" % [battle.wave_number(), total]
	_wave_bar.value = float(battle.wave_number() - 1) / maxf(total, 1.0)
	var whole := floori(core.meat)
	_coin_label.text = "%d/%d" % [whole, core.max_meat]
	_coin_bar.value = core.meat / maxf(core.max_meat, 1.0)
	var used: int = battle.fish_used()
	_fish_label.text = "%d/%d" % [used, battle.fish_cap]
	_fish_label.add_theme_color_override("font_color", UiKit.WARN if used >= battle.fish_cap else Color.WHITE)
	_update_sell_target()
	if battle.phase == "shop":
		_ready_button.text = "Sẵn sàng  ▶  Đợt %d" % battle.wave_number()
		_ready_button.disabled = battle.board.is_dragging()
	elif battle.phase == "fight":
		_ready_button.text = "Đang đánh · còn %d địch" % (battle.enemy_units.size() + battle.waves.pending())
		_ready_button.disabled = true
	else:
		_ready_button.text = "Hết trận"
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


## Two rows on the field, no band: [leave · level plaque · speed], [castle HP · wave · coins].
func _build_top_bar(root: Control) -> void:
	var rows := Ui.vbox(4)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rows)
	rows.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	rows.offset_left = 12
	rows.offset_right = -12
	rows.offset_top = 6

	var top := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	rows.add_child(top)
	var leave := Ui.button("", "Red", Vector2(64, 56), 0, "back")
	leave.pressed.connect(_on_leave_pressed)
	top.add_child(leave)
	var plaque := Ui.title_plaque(battle.level.display_name, "", 21)
	top.add_child(plaque)
	top.add_child(Ui.spacer())
	_speed_button = Ui.button("x1", "Blue", Vector2(80, 56), 22)
	_speed_button.pressed.connect(_toggle_speed)
	top.add_child(_speed_button)

	var stats := Ui.hbox(10, BoxContainer.ALIGNMENT_BEGIN)
	rows.add_child(stats)
	# Castle HP: heart + red bar with the number on it.
	var hp := Ui.hbox(4)
	hp.add_child(Ui.icon("heart", 40))
	_hp_bar = ProgressBar.new()
	_hp_bar.theme_type_variation = "BarHpRed"
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(170, 30)
	_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hp_label = Ui.label("", "LabelTiny", 17)
	_hp_bar.add_child(_hp_label)
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp.add_child(_hp_bar)
	stats.add_child(hp)
	# Wave: crossed swords + "Đợt n/N" over a thin progress bar.
	var wave := Ui.hbox(4)
	wave.add_child(Ui.icon("tab_battle", 40))
	var wave_col := Ui.vbox(2)
	_wave_label = Ui.label("", "LabelSmall", 19)
	wave_col.add_child(_wave_label)
	_wave_bar = ProgressBar.new()
	_wave_bar.theme_type_variation = "BarExp"
	_wave_bar.show_percentage = false
	_wave_bar.max_value = 1.0
	_wave_bar.custom_minimum_size = Vector2(110, 12)
	wave_col.add_child(_wave_bar)
	wave.add_child(wave_col)
	stats.add_child(wave)
	stats.add_child(Ui.spacer())
	# Coins (shop money) with how full the purse is.
	var coin := Ui.hbox(4)
	coin.add_child(Ui.icon("coin", 40))
	var coin_col := Ui.vbox(2)
	_coin_label = Ui.label("", "LabelSmall", 19)
	coin_col.add_child(_coin_label)
	_coin_bar = ProgressBar.new()
	_coin_bar.theme_type_variation = "BarExp"
	_coin_bar.show_percentage = false
	_coin_bar.max_value = 1.0
	_coin_bar.custom_minimum_size = Vector2(80, 12)
	coin_col.add_child(_coin_bar)
	coin.add_child(coin_col)
	stats.add_child(coin)
	# Fish basket: food eaten by the living cats / basket size.
	var fish := Ui.hbox(4)
	fish.add_child(Ui.icon("fish", 40))
	_fish_label = Ui.label("", "LabelSmall", 19)
	fish.add_child(_fish_label)
	stats.add_child(fish)


func _build_controls(root: Control) -> void:
	var sell_rect: Rect2 = battle.SELL_RECT
	# A flat receiving area, rather than a permanent raised button.
	_sell_face = StyleBoxFlat.new()
	_sell_face.bg_color = Color("a96e5a")
	_sell_face.border_color = Color("583f21")
	_sell_face.set_border_width_all(3)
	_sell_face.set_corner_radius_all(20)
	_sell_hover_face = _sell_face.duplicate()
	_sell_hover_face.bg_color = Color("cd765c")
	_sell_hover_face.border_color = Color("ffe08b")
	_sell_zone = Panel.new()
	_sell_zone.name = "BattleSellZone"
	_sell_zone.add_theme_stylebox_override("panel", _sell_face)
	_sell_zone.position = sell_rect.position
	_sell_zone.size = sell_rect.size
	_sell_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sell_zone.visible = false
	root.add_child(_sell_zone)
	var center := Ui.center(Ui.hbox(22))
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sell_zone.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row: HBoxContainer = center.get_child(0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caption := Ui.vbox(0, BoxContainer.ALIGNMENT_CENTER)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sell_headline = Ui.label("Kéo gear vào đây để bán", "", 24)
	_sell_headline.name = "SellHeadline"
	_sell_instruction = Ui.label("Thả ngoài vùng để giữ lại", "LabelTiny", 14)
	_sell_instruction.name = "SellInstruction"
	caption.add_child(_sell_headline)
	caption.add_child(_sell_instruction)
	row.add_child(caption)
	var refund := Ui.hbox(6)
	refund.mouse_filter = Control.MOUSE_FILTER_IGNORE
	refund.add_child(Ui.icon("coin", 34))
	_sell_refund = Ui.label("", "", 24)
	_sell_refund.name = "SellRefund"
	refund.add_child(_sell_refund)
	row.add_child(refund)

	var ready_rect := sell_rect
	ready_rect.position.y += 6.0
	_ready_button = Ui.button("", "Yellow", ready_rect.size, 26)
	_ready_button.name = "BattleReadyButton"
	_raise_button_caption(_ready_button)
	_ready_button.position = ready_rect.position
	_ready_button.size = ready_rect.size
	_ready_button.pressed.connect(func(): battle.start_wave())
	root.add_child(_ready_button)


func _update_sell_target() -> void:
	var gear = battle.board.dragged_gear()
	var dragging: bool = gear != null
	_ready_button.visible = not dragging
	_sell_zone.visible = battle.accepts_input() and battle.board.drag_can_sell()
	if not _sell_zone.visible:
		return
	var hovered: bool = battle.board.drag_over_sell_zone()
	_sell_zone.add_theme_stylebox_override("panel", _sell_hover_face if hovered else _sell_face)
	_sell_headline.text = "Thả để bán gear" if hovered else "Kéo gear vào đây để bán"
	_sell_instruction.text = "Nhận lại xu ngay khi thả" if hovered else "Thả ngoài vùng để giữ lại"
	var refund := Economy.sell_refund(gear.troop.rarity, gear.tier)
	var received := floori(minf(battle.core.max_meat, battle.core.meat + refund)) - floori(battle.core.meat)
	_sell_refund.text = "+%d xu" % received
	if received < refund:
		_sell_instruction.text = "Túi xu đầy · vẫn có thể dọn gear" if received == 0 else "Xu hoàn lại giới hạn theo túi xu"


## The font's visible letters sit below its line-box centre. Raise native captions
## two pixels while retaining the skin's six-pixel movement when pressed.
func _raise_button_caption(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var face: StyleBox = Ui.THEME.get_stylebox(state, button.theme_type_variation).duplicate()
		face.content_margin_top = maxf(0.0, face.content_margin_top - 4.0)
		button.add_theme_stylebox_override(state, face)


## Toast: a dark translucent pill under the top bar.
func _build_message(root: Control) -> void:
	_message = Ui.label("", "LabelSmall", 20)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_box = Ui.panel("InfoStrip", _message)
	_message_box.position = Vector2(30, 116)
	_message_box.size = Vector2(660, 44)
	_message_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_box.modulate.a = 0.0
	root.add_child(_message_box)


func _build_end_panel(root: Control) -> void:
	_end_panel = Ui.panel("Sheet")
	_end_panel.custom_minimum_size = Vector2(580, 0)
	root.add_child(_end_panel)
	_end_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_end_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_end_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_end_box = Ui.vbox(12)
	_end_panel.add_child(_end_box)
	_end_panel.visible = false


func _toggle_speed() -> void:
	Engine.time_scale = 1.0 if Engine.time_scale > 1.5 else 2.0


# --- Between-wave shop ------------------------------------------------------------------

## Called by Battle after a wave: shows what it paid, with the coins flying to the counter.
func on_wave_cleared(index: int, income: int, interest: int) -> void:
	show_message("Xong đợt %d! +%d xu%s" % [index + 1, income, " (lãi +%d)" % interest if interest > 0 else ""])
	var gain := Ui.label("+%d" % (income + interest), "LabelTitle", 34)
	gain.add_theme_color_override("font_color", Color("ffd35c"))
	gain.position = Vector2(560, 150)
	_root.add_child(gain)
	var tween := gain.create_tween()
	tween.tween_property(gain, "position", Vector2(620, 70), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(gain, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.tween_callback(gain.queue_free)


func _build_shop(root: Control) -> void:
	_shop_panel = Ui.panel("Sheet")
	_shop_panel.position = SHOP_POS
	_shop_panel.size = Vector2(680, 0)
	_shop_panel.custom_minimum_size = Vector2(680, 0)
	root.add_child(_shop_panel)
	_shop_box = Ui.vbox(10)
	_shop_panel.add_child(_shop_box)
	battle.shop_changed.connect(_refresh_shop)
	_refresh_shop()


# Rebuilt whenever the shop, the coins or the board's merge options change.
func _refresh_shop() -> void:
	for child in _shop_box.get_children():
		_shop_box.remove_child(child)
		child.queue_free()
	var number: int = battle.wave_number()
	_shop_box.add_child(Ui.center(Ui.title_plaque("Lượt nghỉ · Đợt %d/%d sắp tới" % [number, battle.waves.total()], "", 20)))

	# Next wave preview.
	var preview := Ui.hbox(8)
	preview.add_child(Ui.label("Quân địch:", "LabelDark", 17))
	var foes: Dictionary = battle.waves.preview(number - 1)
	for id in foes:
		preview.add_child(_portrait(PlayerData.TROOPS[id], 42, "Black" if foes[id]["elite"] else "Red"))
		preview.add_child(Ui.label("x%d%s" % [foes[id]["count"], "★" if foes[id]["elite"] else ""], "LabelDark", 17))
	_shop_box.add_child(Ui.panel("Well", preview))

	var cards := Ui.hbox(10)
	_cards.clear()
	for slot in battle.shop.size():
		var card := _shop_card(slot)
		cards.add_child(card)
		_cards.append(card)
	_shop_box.add_child(cards)

	var tools := Ui.hbox(12)
	var cost: int = battle.reroll_cost()
	var reroll := Ui.cost_button("Đổi shop", "Miễn phí" if cost == 0 else str(cost), "coin", "Blue", Vector2(250, 90))
	reroll.pressed.connect(func(): battle.reroll())
	reroll.disabled = not battle.core.can_afford(cost)
	tools.add_child(reroll)
	var lock := Ui.button("Đã khoá" if battle.shop_locked else "Khoá shop", "Red" if battle.shop_locked else "Tab", Vector2(200, 76), 21, "lock")
	lock.name = "BattleShopLockButton"
	lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_raise_button_caption(lock)
	lock.pressed.connect(func(): battle.toggle_lock())
	tools.add_child(lock)
	_shop_box.add_child(tools)

	var pay: Array = battle.income_preview()
	var info := Ui.label("Hết đợt nhận +%d xu · lãi +%d (mỗi 5 xu để dành = +1)" % [pay[0], pay[1]], "LabelDark", 16)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_box.add_child(info)


## One offer: rarity card (same anatomy as every card: tier badge top, art, name, price).
func _shop_card(slot: int) -> Button:
	var offer: Dictionary = battle.shop[slot]
	var troop: Resource = PlayerData.TROOPS[offer["id"]]
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	var face := Ui.THEME.get_stylebox("panel", "CardUnit" + _tone(troop.rarity).capitalize())
	for state in ["normal", "hover", "pressed", "disabled"]:
		card.add_theme_stylebox_override(state, face)
	card.pressed.connect(_on_card_pressed.bind(slot))
	var column := Ui.vbox(0, BoxContainer.ALIGNMENT_CENTER)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if offer["sold"]:
		column.add_child(Ui.label("Đã mua", "LabelSmall", 18))
		card.disabled = true
		card.modulate = Color(1, 1, 1, 0.45)
		return card
	column.add_child(Ui.label(Economy.RARITY_NAMES[clampi(troop.rarity, 0, 3)], "LabelTiny", 14))
	column.add_child(Ui.center(_portrait(troop, 76, SpriteLib.player_color(offer["tier"]))))
	var name_label := Ui.label(troop.display_name, "LabelSmall", 16)
	name_label.clip_text = true
	column.add_child(name_label)
	if offer["tier"] > 1:
		column.add_child(Ui.label("Bậc %d" % offer["tier"], "LabelAccent", 15))
	var affordable: bool = battle.core.can_afford(offer["price"])
	var price := Ui.hbox(4)
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.add_child(Ui.icon("coin", 28))
	var amount := Ui.label(str(offer["price"]), "", 21)
	if not affordable:
		amount.add_theme_color_override("font_color", WARN)
	price.add_child(amount)
	column.add_child(price)
	if not affordable or battle.board.is_full():
		card.modulate = Color(0.72, 0.72, 0.72)
	if battle.offer_merges(slot):
		var pill := StyleBoxFlat.new()
		pill.bg_color = Color("5fd03e")
		pill.border_color = Color("583f21")
		pill.set_border_width_all(3)
		pill.set_corner_radius_all(14)
		pill.content_margin_left = 8
		pill.content_margin_right = 8
		var badge := PanelContainer.new()
		badge.add_theme_stylebox_override("panel", pill)
		badge.add_child(Ui.label("Ghép được", "LabelTiny", 14))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)
		badge.position = Vector2(10, -14)
		badge.size = Vector2(100, 28)
	return card


func _on_card_pressed(slot: int) -> void:
	var from: Vector2 = _cards[slot].global_position + CARD_SIZE / 2.0
	var troop: Resource = PlayerData.TROOPS[battle.shop[slot]["id"]]
	var gear = battle.buy(slot)
	if gear == null:
		return
	# A ghost of the portrait flies from the card down to the gear it became.
	var ghost := _portrait(troop, 78)
	ghost.position = from - Vector2(39, 39)
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
