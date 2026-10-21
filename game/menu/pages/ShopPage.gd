extends "res://game/menu/pages/MenuPage.gd"

# Chests (free wood, silver for gold, gold for gems with a pity counter) and the
# gem-to-gold exchange. Opening a chest plays the full-screen ChestOpening.

const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const Ui = preload("res://game/ui/Ui.gd")
const CHEST_COLORS := {"wood": Color("a0673a"), "silver": Color("aeb8c2"), "gold": Color("e8b93c")}

var _wood_button: Button
var _wood_status: Label


func build() -> void:
	var page_margin := body.get_parent() as MarginContainer
	page_margin.add_theme_constant_override("margin_top", 8)
	page_margin.add_theme_constant_override("margin_bottom", 16)
	body.add_theme_constant_override("separation", 24)
	_featured_chest()
	var supplies := UiKit.vbox(12)
	var heading := UiKit.hbox()
	heading.add_child(Ui.menu_tag("Rương tiếp tế"))
	supplies.add_child(heading)
	var grid := GridContainer.new()
	grid.name = "SupplyChestGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	for kind in ["wood", "silver"]:
		grid.add_child(_supply_card(kind))
	supplies.add_child(grid)
	body.add_child(supplies)
	_exchange_row()
	tick()


func tick() -> void:
	if _wood_button == null or not is_instance_valid(_wood_button):
		return
	var left := PlayerData.free_chest_seconds_left()
	_wood_button.disabled = left > 0
	_wood_status.text = "Miễn phí!" if left == 0 else "Mở lại sau " + UiKit.format_time(left)


func has_alert() -> bool:
	return PlayerData.free_chest_seconds_left() == 0


func _featured_chest() -> void:
	var chest: Dictionary = Economy.CHESTS["gold"]
	var box := UiKit.vbox(12)
	var frame := Ui.menu_section("shop", chest["name"], box)
	frame.name = "FeaturedChest"
	(frame.get_child(0) as PanelContainer).add_theme_stylebox_override("panel", _offer_style("featured"))
	body.add_child(frame)
	var row := UiKit.hbox(18)
	box.add_child(row)
	row.add_child(_chest_art("gold", 188))
	var info := UiKit.vbox(8)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(_copy("%d thẻ lính" % chest["cards"], 30))
	info.add_child(_copy("Chắc chắn ≥ %d thẻ Hiếm" % chest["min_rare"], 22))
	var action := _chest_button("gold")
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(action)
	row.add_child(info)
	var footer := UiKit.hbox(12)
	var pity := _copy("Còn %d lần mở chắc chắn có thẻ Sử thi" % PlayerData.gold_chest_pity_left(), 20)
	pity.add_theme_color_override("font_color", Color("69328c"))
	pity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(pity)
	var rates := UiKit.button("TỈ LỆ THẺ", Vector2(142, 60), _show_rates)
	rates.name = "ShopRates"
	rates.add_theme_font_size_override("font_size", 20)
	rates.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	footer.add_child(rates)
	box.add_child(footer)


func _supply_card(kind: String) -> PanelContainer:
	var chest: Dictionary = Economy.CHESTS[kind]
	var card := Ui.menu_panel("shop")
	card.name = "SupplyChest_" + kind
	card.set_meta("shop_chest_kind", kind)
	card.add_theme_stylebox_override("panel", _offer_style(kind, 20))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := UiKit.vbox(8)
	card.add_child(box)
	var title_label := _copy(chest["name"], 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	box.add_child(_chest_art(kind, 200))
	var contents := _copy("%d thẻ lính" % chest["cards"], 24)
	contents.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(contents)
	var status := _copy("+ %d–%d vàng" % chest["bonus_gold"] if chest["bonus_gold"][1] > 0 else "Mở bằng vàng", 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.custom_minimum_size.y = 32
	box.add_child(status)
	if kind == "wood":
		_wood_status = _copy("", 20)
		_wood_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_wood_status.custom_minimum_size.y = 32
		box.add_child(_wood_status)
	else:
		box.add_child(UiKit.gap(0, 32))
	var action := _chest_button(kind)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(action)
	return card


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


func _chest_button(kind: String) -> Button:
	var chest: Dictionary = Economy.CHESTS[kind]
	var b := UiKit.button("MỞ", Vector2(200, 78), _open.bind(kind))
	b.add_theme_font_size_override("font_size", 24)
	if kind == "wood":
		_wood_button = b
	else:
		var currency := "gems" if chest["gems"] > 0 else "gold"
		var amount: int = chest["gems"] if chest["gems"] > 0 else chest["gold"]
		b.text = "MỞ · " + UiKit.format_number(amount)
		b.icon = UiKit.coin_texture() if currency == "gold" else Ui.icon_tex("gem", 28)
		b.add_theme_constant_override("icon_max_width", 28)
		b.disabled = not PlayerData.can_open_chest(kind)
	return b


func _exchange_row() -> void:
	var box := UiKit.vbox(0)
	body.add_child(Ui.menu_section("shop", "Đổi kim cương", box))
	var row := UiKit.hbox(16)
	box.add_child(row)
	row.add_child(UiKit.drawn(UiKit.DrawnIcon.Kind.GEM, 64))
	var info := UiKit.vbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var conversion := UiKit.ink("%d kim cương → %s vàng" % [Economy.EXCHANGE_GEMS, UiKit.format_number(Economy.EXCHANGE_GOLD)], 22)
	conversion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(conversion)
	row.add_child(info)
	var b := UiKit.button("ĐỔI", Vector2(144, 78), func(): PlayerData.exchange_gems())
	b.add_theme_font_size_override("font_size", 24)
	b.disabled = PlayerData.gems < Economy.EXCHANGE_GEMS
	row.add_child(b)


func _offer_style(kind: String, padding := 28) -> StyleBoxTexture:
	var style := Ui.menu_panel_style("shop")
	style.texture = load("res://game/ui/skin/menu/shop_" + kind + ".svg")
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style


func _copy(text: String, font_size: int) -> Label:
	var label := UiKit.ink(text, font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _show_rates() -> void:
	var box := UiKit.sheet_popup(home, 560, "Tỉ lệ thẻ trong rương")
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
	box.add_child(_copy("Rương Vàng chắc chắn có ít nhất %d thẻ Hiếm." % Economy.CHESTS["gold"]["min_rare"], 22))


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
