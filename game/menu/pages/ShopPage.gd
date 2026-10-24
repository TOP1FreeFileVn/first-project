extends "res://game/menu/pages/MenuPage.gd"

# Approved speech-bubble offer for Gold, with x1/x10 purchases. Supply cards keep
# their teal/cream layout; all prices and per-chest rewards come from Economy.
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const RewardBubble = preload("res://game/ui/ShopRewardBubble.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const Ui = preload("res://game/ui/Ui.gd")
const SectionHeader = preload("res://game/ui/ShopSectionHeader.gd")
const ShopCatalog = preload("res://game/core/ShopCatalog.gd")
const GemPackCard = preload("res://game/ui/GemPackCard.gd")
const GoldOfferCard = preload("res://game/ui/GoldOfferCard.gd")
const CHEST_COLORS := {"wood": Color("a0673a"), "silver": Color("aeb8c2"), "gold": Color("e8b93c")}
const PAPER := Color("f2dcab")
const PAPER_LIGHT := Color("f8e8c5")
const BROWN := Color("583f21")
const TEXT := Color("3b2b1e")
const PURPLE := Color("69328c")
const GOLD_PANEL = preload("res://game/ui/skin/menu/shop_teal_gold.svg")
const SUPPLY_PANEL = preload("res://game/ui/skin/menu/shop_teal_supply.svg")
const SILVER_PANEL = preload("res://game/ui/skin/menu/shop_silver_supply.svg")

var _wood_button: Button
var _wood_status: Label

var _gold_action: Button
var _gold_action_ten: Button
var _silver_action: Button
var _gold_deficit: Label
var _silver_deficit: Label
var _opening_pending := false
var _gold_offer_cards: Array = []


func build() -> void:
	_gold_offer_cards.clear()
	var margin := body.get_parent() as MarginContainer
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 26)
	body.add_theme_constant_override("separation", 16)
	_section_header("premium", "Rương cao cấp", Color("e8b260"))
	_featured_chest()
	_section_header("supply", "Rương tiếp tế", Color("a9c8bd"))
	var supplies := UiKit.vbox(10)
	var grid := GridContainer.new()
	grid.name = "SupplyChestGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.add_child(_supply_card("wood"))
	grid.add_child(_supply_card("silver"))
	supplies.add_child(grid)
	body.add_child(supplies)
	_section_header("gems", "Nạp kim cương", Color("bba6d6"))
	_gem_packs()
	_section_header("gold", "Vàng", Color("edc370"))
	_gold_offers()
	tick()


func _section_header(id: String, text: String, accent: Color) -> void:
	var header := SectionHeader.new(text, accent)
	header.name = "ShopSection_" + id
	body.add_child(header)


func tick() -> void:
	if _wood_button == null or not is_instance_valid(_wood_button):
		return
	var remaining := PlayerData.free_chest_seconds_left()
	_wood_button.disabled = remaining > 0
	_wood_button.text = "MIỄN PHÍ" if remaining == 0 else "CHỜ NHẬN"
	_wood_status.visible = remaining > 0
	_wood_status.text = "Còn " + UiKit.format_time(remaining) if remaining > 0 else ""
	_gold_action.disabled = not PlayerData.can_open_chest("gold")
	_gold_action_ten.disabled = not PlayerData.can_open_chest("gold", 10)
	for action in [_gold_action, _gold_action_ten]:
		var copy := action.get_child(0) as Control
		copy.modulate.a = 0.65 if action.disabled else 1.0
	_silver_action.disabled = not PlayerData.can_open_chest("silver")
	var missing_gems := maxi(0, int(Economy.CHESTS["gold"]["gems"]) - PlayerData.gems)
	var missing_gold := maxi(0, int(Economy.CHESTS["silver"]["gold"]) - PlayerData.gold)
	_gold_deficit.text = "Thiếu %s kim cương" % UiKit.format_number(missing_gems) if missing_gems > 0 else ""
	_silver_deficit.text = "Thiếu %s vàng" % UiKit.format_number(missing_gold) if missing_gold > 0 else ""
	_gold_deficit.visible = missing_gems > 0
	_silver_deficit.visible = missing_gold > 0
	for card in _gold_offer_cards:
		var offer: Dictionary = ShopCatalog.gold_offer(card.offer_id)
		card.update_offer(offer)
		if card.offer_id == "daily_gold":
			var available := PlayerData.shop_gold_available()
			card.set_available(available, not available)
		else:
			card.set_available(PlayerData.gems >= int(offer["gems"]) and int(offer["gems"]) > 0 and int(offer["gold"]) > 0)


func _featured_chest() -> void:
	var chest: Dictionary = Economy.CHESTS["gold"]
	var panel := PanelContainer.new()
	var skin := _flat_style(Color("e9b260"), 20, 12)
	skin.set_corner_radius_all(24)
	panel.add_theme_stylebox_override("panel", skin)
	panel.name = "FeaturedChest"
	panel.set_meta("shop_chest_kind", "gold")
	body.add_child(panel)
	var box := UiKit.vbox(10)
	panel.add_child(box)
	var header := UiKit.hbox(10)
	box.add_child(header)
	var heading := _gold_copy(chest["name"], 32, Color("fff8e6"), true)
	heading.name = "GoldTitle"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(heading)
	header.add_child(_gold_rates())
	var row := UiKit.hbox(22)
	box.add_child(row)
	row.add_child(_chest_art("gold", 238))
	var info := UiKit.vbox(9)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	var bubble := RewardBubble.new()
	bubble.name = "GoldRewardBubble"
	info.add_child(bubble)
	var rewards := UiKit.vbox(3)
	bubble.add_child(rewards)
	var quantity := _gold_copy("%d trang bị / rương" % chest["items"], 29)
	quantity.name = "GoldReward"
	rewards.add_child(quantity)
	var materials := "%d–%d bản vẽ" % [chest["blueprints"][0], chest["blueprints"][1]]
	var materials_copy := _gold_copy(materials, 23)
	materials_copy.name = "GoldMaterials"
	rewards.add_child(materials_copy)
	var guarantee := _gold_copy("≥ %d món %s trở lên" % [chest.get("min_count", 1), Economy.RARITY_NAMES[chest["min_rare"]]], 24, Color("f0c7ff"))
	guarantee.name = "GoldGuarantee"
	rewards.add_child(guarantee)
	_gold_deficit = _gold_copy("", 22, Color("ffdf9e"))
	_gold_deficit.name = "GoldDeficit"
	rewards.add_child(_gold_deficit)
	var actions := UiKit.hbox(10)
	info.add_child(actions)
	_gold_action = _gold_cost_button(1)
	_gold_action_ten = _gold_cost_button(10)
	actions.add_child(_gold_action)
	actions.add_child(_gold_action_ten)


func _gold_cost_button(count: int) -> Button:
	var price := int(Economy.CHESTS["gold"]["gems"]) * count
	var action := Ui.cost_button("MỞ ×%d" % count, UiKit.format_number(price), "gem",
		"Yellow" if count == 1 else "Green", Vector2(0, 100))
	action.name = "GoldOpen" if count == 1 else "GoldOpenTen"
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.tooltip_text = "Mở %d rương Vàng · %s kim cương" % [count, UiKit.format_number(price)]
	for label in action.find_children("*", "Label", true, false):
		label.add_theme_font_override("font", UiKit.game_font())
		label.add_theme_font_size_override("font_size", 25)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color("251e18"))
		label.add_theme_constant_override("outline_size", 4)
	action.pressed.connect(_open.bind("gold", count))
	return action


func _gold_copy(text: String, font_size: int, ink := Color("fff6dd"), outlined := false) -> Label:
	var label := _copy(text, font_size)
	label.add_theme_color_override("font_color", ink)
	label.add_theme_color_override("font_outline_color", Color("392b20"))
	label.add_theme_constant_override("outline_size", 4 if outlined else 0)
	return label


func _gold_rates() -> Button:
	var rates := Button.new()
	rates.name = "ShopRates"
	rates.text = "Tỉ lệ  ›"
	rates.custom_minimum_size = Vector2(106, 64)
	rates.focus_mode = Control.FOCUS_NONE
	rates.add_theme_font_override("font", UiKit.game_font())
	rates.add_theme_font_size_override("font_size", 23)
	rates.add_theme_color_override("font_outline_color", Color("352719"))
	rates.add_theme_constant_override("outline_size", 3)
	for state in ["normal", "disabled", "focus"]:
		rates.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["hover", "pressed", "hover_pressed"]:
		var hover := _flat_style(Color("c4d9ce"), 8, 8)
		hover.set_border_width_all(0)
		rates.add_theme_stylebox_override(state, hover)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		rates.add_theme_color_override(state, Color("fff5dd"))
	rates.pressed.connect(func(): SoundLib.play("click"); _show_rates())
	return rates


func _supply_card(kind: String) -> PanelContainer:
	var chest: Dictionary = Economy.CHESTS[kind]
	var panel := _offer_panel(PAPER_LIGHT, 16, 14)
	if kind == "silver":
		var frame := panel.get_theme_stylebox("panel").duplicate() as StyleBoxTexture
		frame.texture = SILVER_PANEL
		panel.add_theme_stylebox_override("panel", frame)
	panel.name = "SupplyChest_" + kind
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.set_meta("shop_chest_kind", kind)
	var box := UiKit.vbox(5)
	panel.add_child(box)
	var heading := _copy(chest["name"], 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if kind == "silver":
		heading.add_theme_color_override("font_color", Color("344c59"))
	box.add_child(heading)
	box.add_child(_chest_art(kind, 160))
	var benefits := UiKit.vbox(1)
	benefits.custom_minimum_size.y = 74
	benefits.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(benefits)
	var cards := _copy("%d trang bị · %d–%d bản vẽ" % [chest["items"], chest["blueprints"][0], chest["blueprints"][1]], 26)
	if kind == "silver":
		cards.text = "%d trang bị\n%d–%d bản vẽ" % [chest["items"], chest["blueprints"][0], chest["blueprints"][1]]
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


func _gem_packs() -> void:
	var note := _gold_copy("Giá đề xuất · Thanh toán chưa mở", 22, Color("eee2ff"), true)
	note.name = "GemPackCatalogStatus"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(note)
	var grid := GridContainer.new()
	grid.name = "GemPackGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	body.add_child(grid)
	for pack in ShopCatalog.gem_packs():
		var card := GemPackCard.new(pack)
		card.selected.connect(_show_gem_pack)
		grid.add_child(card)


func _show_gem_pack(pack_id: String) -> void:
	# The catalogue is reviewable before a billing provider is configured. Never
	# credit currency for a local button tap: real grants require verified payment.
	if home.find_child("GemPackDetails", true, false) != null:
		return
	var selected: Dictionary = ShopCatalog.gem_pack(pack_id)
	if selected.is_empty():
		return
	var box := UiKit.sheet_popup(home, 560, "Gói kim cương")
	box.name = "GemPackDetailsContent"
	var overlay := box.get_meta("overlay") as Control
	overlay.name = "GemPackDetails"
	overlay.set_meta("shop_pack_id", pack_id)
	var illustration := load(str(selected["illustration"])) as Texture2D
	var artwork := UiKit.icon(illustration, 180)
	artwork.name = "GemPackDetailsIllustration"
	box.add_child(Ui.center(artwork))
	var amount := _copy("%s kim cương" % UiKit.format_number(int(selected["gems"])), 32)
	amount.name = "GemPackAmount"
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(amount)
	var price := _copy("Giá đề xuất: " + ShopCatalog.format_vnd(int(selected["price_vnd"])), 27)
	price.name = "GemPackPrice"
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(price)
	var status := _copy("Thanh toán chưa mở.\nGói và giá đang ở bản duyệt.", 24)
	status.name = "GemPackStatus"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(status)
	var close := Ui.button("ĐÃ HIỂU", "Yellow", Vector2(0, 80), 27)
	close.name = "GemPackClose"
	close.pressed.connect(func(): UiKit.close_popup(box))
	box.add_child(close)


func _gold_offers() -> void:
	var grid := GridContainer.new()
	grid.name = "GoldExchangeGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	body.add_child(grid)
	for offer in ShopCatalog.gold_offers():
		var card := GoldOfferCard.new(offer)
		card.selected.connect(_select_gold_offer)
		grid.add_child(card)
		_gold_offer_cards.append(card)


func _select_gold_offer(offer_id: String) -> void:
	var offer: Dictionary = ShopCatalog.gold_offer(offer_id)
	if offer.is_empty():
		return
	var amount := 0
	if offer_id == "daily_gold":
		amount = PlayerData.claim_shop_gold()
	elif PlayerData.exchange_gems(int(offer["multiplier"])):
		amount = int(offer["gold"])
	if amount > 0:
		SoundLib.play("reward")
		UiKit.toast(home, "+%s vàng" % UiKit.format_number(amount))


func focus_gem_packs() -> void:
	# A header currency shortcut can open the shop and jump straight to the aisle.
	await get_tree().process_frame
	var scroll := body.get_parent().get_parent() as ScrollContainer
	var header := body.get_node_or_null("ShopSection_gems") as Control
	if scroll != null and header != null:
		scroll.scroll_vertical += roundi(header.get_global_rect().position.y - scroll.get_global_rect().position.y) - 10


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
	return PlayerData.free_chest_seconds_left() == 0 or PlayerData.shop_gold_available()


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
	box.add_child(_copy("Tỉ lệ phẩm mỗi trang bị trong rương, trước khi áp dụng bảo đảm.", 22))
	var total := 0.0
	for weight in HeroCat.SUMMON_RARITY:
		total += weight
	for i in HeroCat.SUMMON_RARITY.size():
		var row := UiKit.hbox(12)
		var name_label := UiKit.ink(Economy.RARITY_NAMES[i], 24)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(UiKit.ink("%s%%" % str(snappedf(100.0 * HeroCat.SUMMON_RARITY[i] / maxf(total, 0.001), 0.1)), 24))
		box.add_child(row)
	box.add_child(_copy("Rương Bạc bảo đảm ít nhất 1 món Hiếm; Rương Vàng ít nhất %d món Sử thi." % Economy.CHESTS["gold"].get("min_count", 1), 22))


func _open(kind: String, count := 1) -> void:
	if _opening_pending:
		return
	_opening_pending = true
	var loot := PlayerData.open_chest(kind, count)
	if loot.is_empty():
		_opening_pending = false
		return
	var opening = ChestOpening.new()
	var title: String = Economy.CHESTS[kind]["name"]
	if count > 1:
		title += " ×%d" % count
	opening.setup(title, CHEST_COLORS[kind], loot, [], PlayerData.fast_chest, func(): home.select_tab(home.HERO_TAB))
	opening.tree_exited.connect(func(): _opening_pending = false, CONNECT_ONE_SHOT)
	opening.attach(home)
