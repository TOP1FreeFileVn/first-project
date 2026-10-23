extends "res://game/menu/pages/MenuPage.gd"

# Selected teal/cream shop: one premium offer, compact supply cards, original
# button/chest art and unchanged Economy prices, rewards and opening behavior.
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const Ui = preload("res://game/ui/Ui.gd")
const CHEST_COLORS := {"wood": Color("a0673a"), "silver": Color("aeb8c2"), "gold": Color("e8b93c")}
const PAPER := Color("f2dcab")
const PAPER_LIGHT := Color("f8e8c5")
const BROWN := Color("583f21")
const TEXT := Color("3b2b1e")
const PURPLE := Color("69328c")
const GOLD_PANEL = preload("res://game/ui/skin/menu/shop_teal_gold.svg")
const SUPPLY_PANEL = preload("res://game/ui/skin/menu/shop_teal_supply.svg")

var _wood_button: Button
var _wood_status: Label

var _gold_action: Button
var _silver_action: Button
var _gold_deficit: Label
var _silver_deficit: Label
var _pity_copy: Label


func build() -> void:
	var margin := body.get_parent() as MarginContainer
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 26)
	body.add_theme_constant_override("separation", 16)
	_featured_chest()
	var supplies := UiKit.vbox(10)
	var heading := _copy("Rương tiếp tế", 28)
	heading.add_theme_color_override("font_color", Color("fff0ce"))
	heading.add_theme_color_override("font_outline_color", Color("352b22"))
	heading.add_theme_constant_override("outline_size", 4)
	supplies.add_child(heading)
	var grid := GridContainer.new()
	grid.name = "SupplyChestGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.add_child(_supply_card("wood"))
	grid.add_child(_supply_card("silver"))
	supplies.add_child(grid)
	body.add_child(supplies)
	_exchange_row()
	tick()


func tick() -> void:
	if _wood_button == null or not is_instance_valid(_wood_button):
		return
	var remaining := PlayerData.free_chest_seconds_left()
	_wood_button.disabled = remaining > 0
	_wood_button.text = "MIỄN PHÍ" if remaining == 0 else "CHỜ NHẬN"
	_wood_status.visible = remaining > 0
	_wood_status.text = "Còn " + UiKit.format_time(remaining) if remaining > 0 else ""
	_gold_action.disabled = not PlayerData.can_open_chest("gold")
	_silver_action.disabled = not PlayerData.can_open_chest("silver")
	var missing_gems := maxi(0, int(Economy.CHESTS["gold"]["gems"]) - PlayerData.gems)
	var missing_gold := maxi(0, int(Economy.CHESTS["silver"]["gold"]) - PlayerData.gold)
	_gold_deficit.text = "Thiếu %s kim cương" % UiKit.format_number(missing_gems) if missing_gems > 0 else ""
	_silver_deficit.text = "Thiếu %s vàng" % UiKit.format_number(missing_gold) if missing_gold > 0 else ""
	_gold_deficit.visible = missing_gems > 0
	_silver_deficit.visible = missing_gold > 0
	_pity_copy.text = "Bảo đảm ≥ Sử thi\nsau tối đa %d lượt" % PlayerData.gold_chest_pity_left()
	_pity_copy.set_meta("pity_left", PlayerData.gold_chest_pity_left())


func _featured_chest() -> void:
	var chest: Dictionary = Economy.CHESTS["gold"]
	var panel := _offer_panel(PAPER, 22, 18)
	panel.name = "FeaturedChest"
	panel.set_meta("shop_chest_kind", "gold")
	body.add_child(panel)
	var box := UiKit.vbox(8)
	panel.add_child(box)
	var row := UiKit.hbox(16)
	box.add_child(row)
	row.add_child(_chest_art("gold", 248))
	var info := UiKit.vbox(5)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	var heading := _copy(chest["name"], 30)
	heading.name = "GoldTitle"
	info.add_child(heading)
	var cards := _copy("%d thẻ lính" % chest["cards"], 34)
	cards.name = "GoldReward"
	info.add_child(cards)
	var guarantee := _copy("≥ %d thẻ Hiếm trở lên" % chest["min_rare"], 26)
	guarantee.name = "GoldGuarantee"
	guarantee.add_theme_color_override("font_color", Color("355f86"))
	info.add_child(guarantee)
	_gold_action = _chest_button("gold", "Yellow")
	info.add_child(_gold_action)
	_gold_deficit = _copy("", 24)
	_gold_deficit.name = "GoldDeficit"
	_gold_deficit.add_theme_color_override("font_color", Color("8b342c"))
	info.add_child(_gold_deficit)
	var footer := UiKit.hbox(12)
	box.add_child(footer)
	_pity_copy = _copy("", 24)
	_pity_copy.name = "GoldPity"
	_pity_copy.add_theme_color_override("font_color", PURPLE)
	_pity_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_pity_copy)
	var rates := Button.new()
	rates.name = "ShopRates"
	rates.text = "Tỉ lệ thẻ  ›"
	rates.custom_minimum_size = Vector2(188, 88)
	rates.focus_mode = Control.FOCUS_NONE
	rates.add_theme_font_override("font", UiKit.game_font())
	rates.add_theme_font_size_override("font_size", 24)
	rates.add_theme_constant_override("outline_size", 0)
	for state in ["normal", "disabled", "focus"]:
		rates.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["hover", "pressed", "hover_pressed"]:
		var hover := _flat_style(Color("c4d9ce"), 8, 8)
		hover.set_border_width_all(0)
		rates.add_theme_stylebox_override(state, hover)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		rates.add_theme_color_override(state, TEXT)
	rates.pressed.connect(func(): SoundLib.play("click"); _show_rates())
	footer.add_child(rates)


func _supply_card(kind: String) -> PanelContainer:
	var chest: Dictionary = Economy.CHESTS[kind]
	var panel := _offer_panel(PAPER_LIGHT, 16, 14)
	panel.name = "SupplyChest_" + kind
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.set_meta("shop_chest_kind", kind)
	var box := UiKit.vbox(5)
	panel.add_child(box)
	var heading := _copy(chest["name"], 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	box.add_child(_chest_art(kind, 160))
	var benefits := UiKit.vbox(1)
	benefits.custom_minimum_size.y = 74
	benefits.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(benefits)
	var cards := _copy("%d thẻ lính" % chest["cards"], 28)
	cards.name = kind.capitalize() + "Reward"
	cards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	benefits.add_child(cards)
	if kind == "wood":
		var bonus := _copy("+ %d–%d vàng" % chest["bonus_gold"], 24)
		bonus.name = "WoodBonus"
		bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		benefits.add_child(bonus)
	var action := _chest_button(kind, "White")
	box.add_child(action)
	if kind == "wood":
		_wood_status = _copy("", 24)
		_wood_status.name = "WoodStatus"
		_wood_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(_wood_status)
	else:
		_silver_action = action
		_silver_deficit = _copy("", 24)
		_silver_deficit.name = "SilverDeficit"
		_silver_deficit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_silver_deficit.add_theme_color_override("font_color", Color("8b342c"))
		box.add_child(_silver_deficit)
	return panel


func _chest_button(kind: String, tone: String) -> Button:
	var chest: Dictionary = Economy.CHESTS[kind]
	var amount: int = chest["gems"] if chest["gems"] > 0 else chest["gold"]
	var action := Ui.button("MIỄN PHÍ" if kind == "wood" else "MỞ · %s" % UiKit.format_number(amount), tone, Vector2(0, 88), 28)
	action.name = kind.capitalize() + "Open"
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.add_theme_color_override("font_color", Color.WHITE)
	action.add_theme_color_override("font_hover_color", Color.WHITE)
	action.add_theme_color_override("font_pressed_color", Color.WHITE)
	action.add_theme_color_override("font_outline_color", Color("251e18"))
	action.add_theme_constant_override("outline_size", 5)
	if kind != "wood":
		action.icon = Ui.icon_tex("gem", 30) if chest["gems"] > 0 else UiKit.coin_texture()
		action.add_theme_constant_override("icon_max_width", 30)
		action.add_theme_constant_override("h_separation", 8)
	else:
		_wood_button = action
	action.pressed.connect(_open.bind(kind))
	return action


func _exchange_row() -> void:
	var panel := _offer_panel(Color("e8d5b2"), 20, 16)
	panel.name = "GemExchange"
	body.add_child(panel)
	var box := UiKit.vbox(8)
	panel.add_child(box)
	box.add_child(_copy("Đổi kim cương", 28))
	var row := UiKit.hbox(14)
	box.add_child(row)
	row.add_child(UiKit.drawn(UiKit.DrawnIcon.Kind.GEM, 48))
	var conversion := _copy("%d kim cương\n→ %s vàng" % [Economy.EXCHANGE_GEMS, UiKit.format_number(Economy.EXCHANGE_GOLD)], 24)
	conversion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(conversion)
	var action := Ui.button("ĐỔI", "White", Vector2(150, 88), 28)
	action.name = "GemExchangeAction"
	action.disabled = PlayerData.gems < Economy.EXCHANGE_GEMS
	action.pressed.connect(func(): PlayerData.exchange_gems())
	row.add_child(action)


func _offer_panel(fill: Color, horizontal_padding: int, vertical_padding: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxTexture.new()
	style.texture = GOLD_PANEL if fill == PAPER else SUPPLY_PANEL
	style.set_texture_margin_all(32)
	style.content_margin_left = horizontal_padding
	style.content_margin_right = horizontal_padding
	style.content_margin_top = vertical_padding
	style.content_margin_bottom = vertical_padding
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _flat_style(fill: Color, horizontal_padding: int, vertical_padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = BROWN
	style.set_border_width_all(5)
	style.set_corner_radius_all(30)
	style.content_margin_left = horizontal_padding
	style.content_margin_right = horizontal_padding
	style.content_margin_top = vertical_padding
	style.content_margin_bottom = vertical_padding
	style.anti_aliasing = true
	style.shadow_size = 0
	return style


func _copy(text: String, font_size: int) -> Label:
	var label := UiKit.ink(text, font_size)
	label.add_theme_color_override("font_color", TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func has_alert() -> bool:
	return PlayerData.free_chest_seconds_left() == 0


func _chest_art(kind: String, icon_size: float) -> Control:
	# The chest silhouette is wide; crop the square drawing's empty top/bottom area.
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(icon_size, icon_size * 0.74)
	stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stage.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture = UiKit.drawn(UiKit.DrawnIcon.Kind.CHEST, icon_size)
	picture.tint = CHEST_COLORS[kind]
	Ui.pin(stage, picture, Vector2(-icon_size / 2, -icon_size / 2), Control.PRESET_CENTER)
	return stage


func _show_rates() -> void:
	var box := UiKit.sheet_popup(home, 560, "Tỉ lệ quay cơ bản")
	box.add_child(_copy("Tỉ lệ mỗi thẻ trước khi áp dụng bảo đảm của rương.", 22))
	var total := 0.0
	for weight in Economy.RARITY_WEIGHTS:
		total += weight
	for i in Economy.RARITY_WEIGHTS.size():
		var row := UiKit.hbox(12)
		var name_label := UiKit.ink(Economy.RARITY_NAMES[i], 24)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(UiKit.ink("%s%%" % str(snappedf(100.0 * Economy.RARITY_WEIGHTS[i] / maxf(total, 0.001), 0.1)), 24))
		box.add_child(row)
	box.add_child(_copy("Rương Vàng bảo đảm ít nhất %d thẻ Hiếm trở lên." % Economy.CHESTS["gold"]["min_rare"], 22))


func _open(kind: String) -> void:
	var locked := []
	for id in PlayerData.TROOP_ORDER:
		if not PlayerData.is_unlocked(id):
			locked.append(id)
	var loot := PlayerData.open_chest(kind)
	if loot.is_empty():
		return
	var fresh := []
	for id in loot["cards"]:
		if locked.has(id):
			fresh.append(id)
	var opening = ChestOpening.new()
	opening.setup(Economy.CHESTS[kind]["name"], CHEST_COLORS[kind], loot, fresh, PlayerData.fast_chest, func(): home.select_tab(home.TROOPS_TAB))
	opening.attach(home)
