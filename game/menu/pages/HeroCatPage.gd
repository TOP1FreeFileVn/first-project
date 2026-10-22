extends "res://game/menu/pages/MenuPage.gd"

# "Anh hùng": the one hero cat and its equipment, on the approved layout (tests/ui/HeroPreview,
# modelled on Capybara Go): a sheet with two gear cards either side of the cat on its
# stand, the power plaque and three stat pills, the weapon strip (paired soldier classes and
# skill), then the bag of spare items as a 5-column grid. Tapping any card opens the item
# sheet: compared with what is worn in that slot, with Nâng cấp (gold) and Trang bị.
# Item data is placeholder until the design sheet's Hero&Weapon tab is filled (HeroCat.gd).

const Ui = preload("res://game/ui/Ui.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const TroopData = preload("res://game/data/TroopData.gd")
const SIDE_CARD := 124.0
const SLOTS_PER_SIDE := 2
const BAG_CARD := 118.0
## Soldier class -> its tier-1 weapon icon (how the classes are shown everywhere).
const KLASS_ICONS := ["w_kiem", "w_cung", "w_gay_phep", "w_giao"]
## These are text accents on the light mint inset, not rarity-card fills.
const UP := Color("1c5326")
const DOWN := Color("8b2828")

var _column: VBoxContainer
var _detail: VBoxContainer
var _detail_uid := ""


func _init() -> void:
	super()
	body.get_parent().get_parent().visible = false
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func refresh() -> void:
	build()
	if _detail != null and is_instance_valid(_detail):
		_fill_detail()


func build() -> void:
	if _column != null:
		_column.queue_free()
	_column = Ui.vbox(8)
	add_child(_column)
	_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_column.offset_left = 10
	_column.offset_right = -10
	_column.offset_top = 4
	_column.offset_bottom = -26
	_column.add_child(_doll())
	_column.add_child(_bag())


func has_alert() -> bool:
	var state: Dictionary = PlayerData.hero_cat
	for slot in HeroCat.SLOTS:
		var uid := HeroCat.equipped_uid(state, slot)
		if uid != "" and _can_upgrade(uid):
			return true
	return false


func _can_upgrade(uid: String) -> bool:
	var cost := HeroCat.upgrade_cost(PlayerData.hero_cat, uid)
	return cost >= 0 and PlayerData.gold >= cost


# --- Paper doll ---------------------------------------------------------------------------

func _doll() -> Control:
	var state: Dictionary = PlayerData.hero_cat
	var sheet := Ui.menu_panel("hero", "Board")
	var box := Ui.vbox(8)
	sheet.add_child(box)

	var row := Ui.hbox(0)
	row.name = "HeroEquipmentRow"
	var left := _slot_column(HeroCat.SLOTS.slice(0, SLOTS_PER_SIDE))
	left.name = "HeroEquipmentLeft"
	row.add_child(left)
	var stage := Control.new()
	stage.name = "HeroPreviewStage"
	stage.custom_minimum_size = Vector2(0, SIDE_CARD * SLOTS_PER_SIDE + 24)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Ui.pin(stage, Ui.image("platform", Vector2(230, 92)), Vector2(-115, -98), Control.PRESET_CENTER_BOTTOM)
	var cat := Ui.image("cat_hero", Vector2(240, 225))
	cat.name = "HeroPreview"
	cat.texture = SpriteLib.hero_cat_texture(state)
	Ui.pin(stage, cat, Vector2(-120, -270), Control.PRESET_CENTER_BOTTOM)
	Ui.bob(cat, 4.0, 1.6)
	row.add_child(stage)
	var right := _slot_column(HeroCat.SLOTS.slice(SLOTS_PER_SIDE))
	right.name = "HeroEquipmentRight"
	row.add_child(right)
	box.add_child(row)

	var stats := PlayerData.hero_cat_stats()
	var power := Ui.hbox(6)
	power.add_child(Ui.icon("star", 38))
	power.add_child(Ui.label(UiKit.format_number(HeroCat.power(stats)), "", 28))
	box.add_child(Ui.center(Ui.panel("TitlePlaque", power)))
	var pills := Ui.hbox(8)
	for key in ["hp", "atk", "def"]:
		pills.add_child(Ui.stat_pill(HeroCat.STAT_ICONS[key], UiKit.format_number(stats[key]), 190))
	box.add_child(pills)
	box.add_child(_weapon_strip(state))
	return sheet


func _slot_column(slots: Array) -> VBoxContainer:
	var column := Ui.vbox(12, BoxContainer.ALIGNMENT_CENTER)
	var state: Dictionary = PlayerData.hero_cat
	for slot in slots:
		var uid := HeroCat.equipped_uid(state, slot)
		if uid == "":
			var symbol := Ui.icon(HeroCat.SLOT_ICONS[slot], SIDE_CARD * 0.5)
			symbol.name = "EmptyEquipmentSymbol"
			var empty := Ui.menu_panel("hero", "Well", Ui.center(symbol))
			empty.name = "EmptyEquipmentSlot_" + slot
			empty.custom_minimum_size = Vector2(SIDE_CARD, SIDE_CARD)
			empty.tooltip_text = "Chưa trang bị: " + HeroCat.SLOT_NAMES[slot]
			column.add_child(empty)
		else:
			column.add_child(_item_card(uid, SIDE_CARD, _can_upgrade(uid)))
	return column


## What the weapon brings: its two soldier classes and its skill.
func _weapon_strip(state: Dictionary) -> Control:
	var uid := HeroCat.equipped_uid(state, "weapon")
	var d := HeroCat.def(state, uid)
	var row := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	if d.is_empty():
		row.add_child(Ui.label("Chưa cầm vũ khí", "LabelDark", 18))
		return Ui.menu_panel("hero", "Well", row)
	row.add_child(Ui.label("Hợp lính", "LabelDark", 17))
	for klass in d["pairs"]:
		row.add_child(Ui.icon(KLASS_ICONS[klass], 34))
	row.add_child(Ui.label("·", "LabelDark", 18))
	var skill := Ui.label(str(d["skill"]).get_slice(":", 0), "LabelDark", 17)
	row.add_child(Ui.icon("gear", 30))
	row.add_child(skill)
	return Ui.menu_panel("hero", "Well", row)


# --- Bag ------------------------------------------------------------------------------------

func _bag() -> Control:
	var state: Dictionary = PlayerData.hero_cat
	var spare := HeroCat.spare(state)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for uid in spare:
		grid.add_child(_item_card(uid, BAG_CARD, false))
	# A ScrollContainer gives its child only its minimum width; the CenterContainer must fill
	# the row or the grid sits at the left edge.
	var holder := Ui.center(grid if not spare.is_empty() else Ui.label("Túi trống: trang bị rơi từ rương và sự kiện.", "LabelSmall", 18))
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(holder)
	var section := Ui.menu_section("hero", "Túi trang bị · %d món" % spare.size(), scroll)
	section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return section


## A gear card that opens the item sheet when tapped.
func _item_card(uid: String, size: float, can_upgrade: bool) -> Control:
	var state: Dictionary = PlayerData.hero_cat
	var d := HeroCat.def(state, uid)
	var card := Ui.gear_card(d["icon"], HeroCat.SLOT_ICONS[d["slot"]], HeroCat.tone(d["rarity"]),
		str(HeroCat.item(state, uid)["level"]), size, can_upgrade)
	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.pressed.connect(func(): SoundLib.play("click"))
	hit.pressed.connect(_open_detail.bind(uid))
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return card


# --- Item sheet -------------------------------------------------------------------------------

func _open_detail(uid: String) -> void:
	_detail_uid = uid
	var d := HeroCat.def(PlayerData.hero_cat, uid)
	_detail = UiKit.sheet_popup(home, 640, d["name"])
	_fill_detail()


func _fill_detail() -> void:
	var box := _detail
	while box.get_child_count() > 1:
		var child := box.get_child(1)
		box.remove_child(child)
		child.queue_free()
	var state: Dictionary = PlayerData.hero_cat
	var uid := _detail_uid
	var d := HeroCat.def(state, uid)
	var it := HeroCat.item(state, uid)
	var worn := HeroCat.equipped_uid(state, d["slot"])
	var wearing := worn == uid
	var cost := HeroCat.upgrade_cost(state, uid)

	# Head: what is worn → this item (or just this item when it is the one worn).
	var head := Ui.hbox(16)
	if not wearing and worn != "":
		head.add_child(_captioned(worn, "Đang mặc"))
		var arrow := Ui.icon("back", 44)
		arrow.flip_h = true
		head.add_child(arrow)
	head.add_child(_captioned(uid, "Đang mặc" if wearing else "Món này"))
	box.add_child(head)
	var kind := "%s · %s · Lv.%d/%d" % [Economy.RARITY_NAMES[d["rarity"]], HeroCat.SLOT_NAMES[d["slot"]], it["level"], HeroCat.MAX_LEVEL]
	box.add_child(Ui.label(kind, "LabelDark", 18))
	if d["slot"] == "weapon":
		var weapon_info := Ui.vbox(8)
		var pairs := Ui.hbox(6)
		pairs.add_child(Ui.label("%s · Hợp lính" % d["range"], "LabelDark", 17))
		for klass in d["pairs"]:
			pairs.add_child(Ui.icon(KLASS_ICONS[klass], 32))
			pairs.add_child(Ui.label(TroopData.KLASS_NAMES[klass], "LabelDark", 17))
		weapon_info.add_child(pairs)
		var skill := Ui.label(d["skill"], "LabelDark", 17)
		skill.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		skill.custom_minimum_size.x = 560
		weapon_info.add_child(skill)
		box.add_child(Ui.menu_section("hero", "Kỹ năng vũ khí", weapon_info))

	# Stat rows: against the worn item, or now → next level for the worn one.
	var mine := HeroCat.item_stats(state, uid)
	var other := {} if wearing else HeroCat.item_stats(state, worn)
	var next := HeroCat.item_stats(state, uid, it["level"] + 1) if wearing and cost >= 0 else {}
	var keys := []
	for key in ["hp", "atk", "def"]:
		if mine.has(key) or other.has(key):
			keys.append(key)
	var stats := Ui.vbox(8)
	for key in keys:
		var row := Ui.hbox(10, BoxContainer.ALIGNMENT_BEGIN)
		row.add_child(Ui.icon(HeroCat.STAT_ICONS[key], 30))
		var stat := Ui.label(HeroCat.STAT_NAMES[key], "LabelDark", 20)
		stat.custom_minimum_size.x = 90
		stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(stat)
		var from: int = other.get(key, 0) if not wearing else mine.get(key, 0)
		var to: int = mine.get(key, 0) if not wearing else next.get(key, from)
		var text := Ui.label("%s → %s" % [UiKit.format_number(from), UiKit.format_number(to)], "LabelDark", 20)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(text)
		if to != from:
			var diff := Ui.label(("+%s" if to > from else "−%s") % UiKit.format_number(absi(to - from)), "LabelDark", 20)
			diff.add_theme_color_override("font_color", UP if to > from else DOWN)
			row.add_child(diff)
		stats.add_child(row)
	if not keys.is_empty():
		box.add_child(Ui.menu_section("hero", "Chỉ số", stats))

	var actions := Ui.hbox(14)
	var upgrade: Button
	if cost < 0:
		upgrade = Ui.button("Cấp tối đa", "Blue", Vector2(240, 96), 22)
		upgrade.disabled = true
	else:
		upgrade = Ui.cost_button("Nâng cấp", UiKit.format_number(cost), "coin", "Blue", Vector2(240, 96))
		upgrade.disabled = PlayerData.gold < cost
	upgrade.pressed.connect(func():
		if PlayerData.hero_cat_upgrade(uid):
			SoundLib.play("reward"))
	actions.add_child(upgrade)
	if not wearing:
		var wear := Ui.button("Trang bị", "Yellow", Vector2(240, 96), 26)
		wear.pressed.connect(func():
			UiKit.close_popup(_detail)
			PlayerData.hero_cat_equip(uid))
		actions.add_child(wear)
	box.add_child(actions)


func _captioned(uid: String, caption: String) -> Control:
	var state: Dictionary = PlayerData.hero_cat
	var d := HeroCat.def(state, uid)
	var column := Ui.vbox(4)
	column.add_child(Ui.label(caption, "LabelDark", 17))
	column.add_child(Ui.center(Ui.gear_card(d["icon"], HeroCat.SLOT_ICONS[d["slot"]], HeroCat.tone(d["rarity"]), str(HeroCat.item(state, uid)["level"]), 120)))
	column.add_child(Ui.label(d["name"], "LabelDark", 19))
	return column
