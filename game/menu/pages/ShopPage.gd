extends "res://game/menu/pages/MenuPage.gd"

# Chests (free wood, silver for gold, gold for gems with a pity counter) and the
# gem-to-gold exchange. Opening a chest plays the full-screen ChestOpening.

const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const CHEST_COLORS := {"wood": Color("a0673a"), "silver": Color("aeb8c2"), "gold": Color("e8b93c")}

var _wood_button: Button
var _wood_status: Label
var _offers: VBoxContainer


func build() -> void:
	fill_available_height()
	body.add_theme_constant_override("separation", 16)
	title("Cửa hàng", UiKit.Ribbon.YELLOW)
	var total := 0.0
	for w in Economy.RARITY_WEIGHTS:
		total += w
	var parts := []
	for i in Economy.RARITY_WEIGHTS.size():
		parts.append("%s %s%%" % [Economy.RARITY_NAMES[i], str(snappedf(100.0 * Economy.RARITY_WEIGHTS[i] / maxf(total, 0.001), 0.1))])
	var rates := UiKit.ink("Tỉ lệ thẻ: " + " · ".join(parts), 22)
	rates.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rates.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(rates)
	_offers = UiKit.vbox(16)
	_offers.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_offers)
	for kind in Economy.CHEST_ORDER:
		_chest_row(kind)
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


func _chest_row(kind: String) -> void:
	var chest: Dictionary = Economy.CHESTS[kind]
	var box := _offer_panel(184)
	var row := UiKit.hbox(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	var icon = UiKit.drawn(UiKit.DrawnIcon.Kind.CHEST, 104)
	icon.tint = CHEST_COLORS[kind]
	row.add_child(icon)
	var info := UiKit.vbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(UiKit.label(chest["name"], 26))
	var contents := "%d thẻ lính" % chest["cards"]
	if chest["bonus_gold"][1] > 0:
		contents += " + %d–%d vàng" % chest["bonus_gold"]
	if chest["min_rare"] > 0:
		contents += "\nChắc chắn ≥ %d thẻ Hiếm" % chest["min_rare"]
	var contents_label := UiKit.ink(contents, 22)
	contents_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(contents_label)
	if kind == "gold":
		var pity := UiKit.ink("Còn %d lần nữa chắc chắn có thẻ Sử thi" % PlayerData.gold_chest_pity_left(), 20)
		pity.add_theme_color_override("font_color", Color("69328c"))
		pity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(pity)
	row.add_child(info)

	var b := UiKit.button("MỞ", Vector2(144, 78), _open.bind(kind))
	b.add_theme_font_size_override("font_size", 24)
	if kind == "wood":
		_wood_button = b
		_wood_status = UiKit.ink("", 20)
		_wood_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(_wood_status)
	else:
		var currency := "gems" if chest["gems"] > 0 else "gold"
		var amount: int = chest["gems"] if chest["gems"] > 0 else chest["gold"]
		b.text = UiKit.format_number(amount)
		if currency == "gold":
			b.icon = UiKit.coin_texture()
			b.add_theme_constant_override("icon_max_width", 28)
		else:
			b.text = "◆ " + b.text
		b.disabled = not PlayerData.can_open_chest(kind)
	row.add_child(b)


func _exchange_row() -> void:
	var box := _offer_panel(148)
	var row := UiKit.hbox(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	row.add_child(UiKit.drawn(UiKit.DrawnIcon.Kind.GEM, 64))
	var info := UiKit.vbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(UiKit.label("Đổi kim cương", 26))
	var conversion := UiKit.ink("%d kim cương → %s vàng" % [Economy.EXCHANGE_GEMS, UiKit.format_number(Economy.EXCHANGE_GOLD)], 22)
	conversion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(conversion)
	row.add_child(info)
	var b := UiKit.button("ĐỔI", Vector2(144, 78), func(): PlayerData.exchange_gems())
	b.add_theme_font_size_override("font_size", 24)
	b.disabled = PlayerData.gems < Economy.EXCHANGE_GEMS
	row.add_child(b)


func _offer_panel(min_height: float) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel_style())
	p.custom_minimum_size.y = min_height
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_offers.add_child(p)
	var box := UiKit.vbox(0)
	p.add_child(box)
	return box


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
