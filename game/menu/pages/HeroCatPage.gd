extends "res://game/menu/pages/MenuPage.gd"

signal inventory_layout_changed

# Approved paperboard equipment layout: four slots around the hero, inline combat
# power, compact stat/skill rows and a five-column inventory with local filters.
# Tapping a real item keeps the existing comparison, upgrade and equip flow.
# Item data is placeholder until the design sheet's Hero&Weapon tab is filled (HeroCat.gd).

const Ui = preload("res://game/ui/Ui.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const TroopData = preload("res://game/data/TroopData.gd")
const PaperboardFrame = preload("res://game/ui/PaperboardFrame.gd")
const HeroPreview = preload("res://game/ui/HeroPreview.gd")
const SIDE_CARD := 124.0
const SLOTS_PER_SIDE := 2
const BAG_CARD := 124.0
const BAG_COLUMNS := 5
const BAG_GAP := 12.0
const BAG_STEP := BAG_CARD + BAG_GAP
## The bag grid's top margin inside its scroll (Ui.margin below), and rows built beyond view.
const BAG_EDGE := 8.0
const BAG_ROW_MARGIN := 1
## Lower the inventory clipping edge slightly into the clear space above nav art.
const BOTTOM_MASK_OFFSET := 12.0
## Grow with the viewport so the hero and inventory header keep their positions.
const BAG_HEIGHT := 576.0 + BOTTOM_MASK_OFFSET
## Soldier class -> its tier-1 weapon icon (how the classes are shown everywhere).
const KLASS_ICONS := ["w_kiem", "w_cung", "w_gay_phep", "w_giao"]
## These are text accents on the light mint inset, not rarity-card fills.
const UP := Color("1c5326")
const DOWN := Color("8b2828")

var _column: VBoxContainer
var _detail: VBoxContainer
var _detail_uid := ""
var _filter := "all"
var _sort_by := "rarity"
var _sort_descending := true
var _sort_overlay: Control
var _bag_scroll_y := 0
var _reset_bag_scroll := false
var _inventory_scroll: ScrollContainer
## Virtual bag grid: the item uids in order and the cards built so far (index -> card).
var _bag_grid: Control
var _bag_uids: Array = []
var _bag_built := {}
var _hero_preview: HeroPreview


func _init() -> void:
	super()
	body.get_parent().get_parent().visible = false
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visibility_changed.connect(_close_sort_when_hidden)
	resized.connect(_fit_sections, CONNECT_DEFERRED)


func refresh() -> void:
	build()
	if _detail != null and is_instance_valid(_detail):
		_fill_detail()


func build() -> void:
	_close_sort_menu()
	if _column != null:
		if is_instance_valid(_inventory_scroll) and not _reset_bag_scroll:
			_bag_scroll_y = _inventory_scroll.scroll_vertical
		# Keep the idle phase when a stat/resource refresh rebuilds this page.
		if is_instance_valid(_hero_preview):
			_hero_preview.get_parent().remove_child(_hero_preview)
		remove_child(_column)
		_column.queue_free()
	_column = Ui.vbox(0)
	_column.name = "HeroPaperboardLayout"
	add_child(_column)
	_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_column.add_child(_doll())
	_column.add_child(_bag())
	_fit_sections.call_deferred()
	_reset_bag_scroll = false


func _fit_sections() -> void:
	if not is_instance_valid(_column) or _column.get_child_count() != 2:
		return
	var hero := _column.get_child(0) as Control
	var inventory := _column.get_child(1) as Control
	# Shorter viewports give up some scroll height; taller ones grow the hero.
	inventory.custom_minimum_size.y = minf(BAG_HEIGHT, maxf(0.0, size.y - hero.get_combined_minimum_size().y))


func has_alert() -> bool:
	return PlayerData.hero_alert()


func _can_upgrade(uid: String) -> bool:
	return PlayerData.hero_cat_can_upgrade(uid)


# --- Paper doll ---------------------------------------------------------------------------

func _doll() -> Control:
	var state: Dictionary = PlayerData.hero_cat
	var sheet := PaperboardFrame.new()
	sheet.name = "HeroPaperboardFolder"
	sheet.kind = "hero"
	sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := Ui.vbox(6)
	sheet.add_child(box)

	var row := Ui.hbox(14)
	row.name = "HeroEquipmentRow"
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left := _slot_column(HeroCat.SLOTS.slice(0, SLOTS_PER_SIDE))
	left.name = "HeroEquipmentLeft"
	row.add_child(left)
	var stage := Control.new()
	stage.name = "HeroPreviewStage"
	stage.custom_minimum_size = Vector2(0, 340)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := _paper_text("Mèo anh hùng", 20)
	stage.add_child(name_label)
	name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_label.offset_top = -8
	name_label.offset_bottom = 24
	if not is_instance_valid(_hero_preview):
		_hero_preview = HeroPreview.new()
		_hero_preview.name = "HeroPreview"
	_hero_preview.custom_minimum_size = Vector2(312, 244)
	_hero_preview.setup(state)
	Ui.pin(stage, _hero_preview, Vector2(-156, -142), Control.PRESET_CENTER)
	var stats := PlayerData.hero_cat_stats()
	var power := Ui.hbox(10)
	power.name = "HeroCombatPower"
	power.custom_minimum_size = Vector2(232, 56)
	var power_icon := Ui.icon("power", 36)
	power_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	power.add_child(power_icon)
	var power_value := _paper_text(UiKit.format_number(HeroCat.power(stats)), 32)
	power.add_child(power_value)
	var power_holder := Ui.center(power)
	power_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(power_holder)
	power_holder.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	power_holder.offset_top = -56
	row.add_child(stage)
	var right := _slot_column(HeroCat.SLOTS.slice(SLOTS_PER_SIDE))
	right.name = "HeroEquipmentRight"
	row.add_child(right)
	box.add_child(row)

	var totals := Ui.hbox(10)
	totals.name = "HeroStatCards"
	totals.custom_minimum_size.y = 58
	for key in ["hp", "atk", "def"]:
		var card := PanelContainer.new()
		card.name = "HeroStatCard_" + key
		card.custom_minimum_size = Vector2(200, 58)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var face := StyleBoxFlat.new()
		face.bg_color = Color("efddb6")
		face.border_color = Color("b99b70")
		face.set_border_width_all(2)
		face.set_corner_radius_all(12)
		face.content_margin_left = 12
		face.content_margin_right = 12
		face.content_margin_top = 4
		face.content_margin_bottom = 4
		face.anti_aliasing = true
		card.add_theme_stylebox_override("panel", face)
		var stat := Ui.hbox(7)
		stat.name = "EquipmentStat_" + key
		stat.add_child(Ui.icon(HeroCat.STAT_ICONS[key], 38))
		stat.add_child(_paper_text(UiKit.format_number(stats[key]), 22))
		card.add_child(Ui.center(stat))
		totals.add_child(card)
	box.add_child(totals)
	box.add_child(_weapon_strip(state))
	return sheet


func _slot_column(slots: Array) -> VBoxContainer:
	var column := Ui.vbox(16, BoxContainer.ALIGNMENT_CENTER)
	var state: Dictionary = PlayerData.hero_cat
	for slot in slots:
		var uid := HeroCat.equipped_uid(state, slot)
		if uid == "":
			var symbol := Ui.icon(HeroCat.SLOT_ICONS[slot], SIDE_CARD * 0.5)
			symbol.name = "EmptyEquipmentSymbol"
			var empty := PaperboardFrame.new()
			empty.kind = "card"
			empty.tone = "empty"
			empty.add_child(Ui.center(symbol))
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
	row.custom_minimum_size.y = 46
	if d.is_empty():
		row.add_child(_paper_text("Chưa cầm vũ khí", 20))
		return row
	row.add_child(Ui.icon("gear", 36))
	row.add_child(_paper_text(str(d["skill"]).get_slice(":", 0), 20))
	row.add_child(Ui.spacer())
	row.add_child(_paper_text("Hợp lính", 18))
	for klass in d["pairs"]:
		row.add_child(Ui.icon(KLASS_ICONS[klass], 36))
	return row


# --- Bag ------------------------------------------------------------------------------------

func _bag() -> Control:
	var spare := _visible_spare()
	var section := PaperboardFrame.new()
	section.kind = "bag"
	section.name = "HeroPaperboardInventory"
	section.fill_surface = false
	section.custom_minimum_size.y = BAG_HEIGHT
	section.size_flags_vertical = Control.SIZE_FILL
	section.item_rect_changed.connect(inventory_layout_changed.emit)
	var box := Ui.vbox(8)
	section.add_child(box)
	var header := PanelContainer.new()
	header.name = "HeroEquipmentSectionHeader"
	header.custom_minimum_size.y = 52
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color("4d352d")
	header_style.border_color = Color("35261f")
	header_style.border_width_top = 3
	header_style.border_width_bottom = 3
	# Draw to the screen edges without changing the inventory's content margins.
	header_style.expand_margin_left = 18
	header_style.expand_margin_right = 18
	header.add_theme_stylebox_override("panel", header_style)
	header.add_child(_paper_text("TRANG BỊ", 26, Color("fff1d1")))
	box.add_child(header)
	var heading := Ui.hbox(0)
	heading.custom_minimum_size.y = 28
	var count := HeroCat.spare_count(PlayerData.hero_cat)
	# Blueprints per slot: what each slot's items level with.
	var plans_row := Ui.hbox(4)
	plans_row.name = "HeroBlueprints"
	for slot in HeroCat.SLOTS:
		plans_row.add_child(UiKit.blueprint_icon(slot, 28))
		plans_row.add_child(_paper_text(UiKit.format_number(PlayerData.blueprints.get(slot, 0)), 19, Color("fff1d1")))
	heading.add_child(plans_row)
	heading.add_child(Ui.spacer())
	var capacity := _paper_text("%d món" % count, 20, Color("fff1d1"))
	capacity.name = "HeroInventoryCount"
	heading.add_child(capacity)
	box.add_child(heading)
	var tools := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	for filter in [["all", "Tất cả"], ["weapon", "Vũ khí"], ["gear", "Phòng thủ"]]:
		var choice := Button.new()
		choice.name = "EquipmentFilter_" + filter[0]
		choice.text = filter[1]
		choice.toggle_mode = true
		choice.button_pressed = _filter == filter[0]
		choice.custom_minimum_size.y = 46
		choice.add_theme_font_size_override("font_size", 18)
		choice.add_theme_constant_override("outline_size", 0)
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			var selected: bool = state in ["pressed", "hover_pressed"]
			var style := StyleBoxFlat.new()
			style.bg_color = Color("edd3a1") if selected else Color("5c412c")
			style.set_corner_radius_all(7)
			style.content_margin_left = 16
			style.content_margin_right = 16
			choice.add_theme_stylebox_override(state, style)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			choice.add_theme_color_override(state, Color("51391f") if "pressed" in state else Color("fff1d1"))
		choice.pressed.connect(_choose_filter.bind(filter[0]))
		tools.add_child(choice)
	tools.add_child(Ui.spacer())
	var sort := Ui.button("", "Yellow", Vector2(76, 48))
	sort.name = "EquipmentSort"
	sort.tooltip_text = "Sắp xếp theo %s · %s" % ["độ hiếm" if _sort_by == "rarity" else "level", "giảm dần" if _sort_descending else "tăng dần"]
	var sort_icon := Ui.center(Ui.image("icon_equipment_filter", Vector2(34, 34)))
	sort_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sort.add_child(sort_icon)
	sort_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sort.pressed.connect(_open_sort_menu.bind(sort))
	tools.add_child(sort)
	box.add_child(tools)
	var fusable := PlayerData.hero_cat_fusable()
	if not fusable.is_empty():
		var id: String = fusable[0]
		var target := HeroCat.fuse_target(id)
		var fuse := Ui.button("Ghép 3 %s → %s" % [HeroCat.ITEMS[id]["name"], HeroCat.ITEMS[target]["name"]], "Green", Vector2(0, 56), 20)
		fuse.name = "EquipmentFuse"
		fuse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fuse.pressed.connect(func():
			if PlayerData.hero_cat_fuse(id) != "":
				SoundLib.play("merge"))
		Ui.dot(fuse, Vector2(-14, -8))
		box.add_child(fuse)
	var scroll := ScrollContainer.new()
	scroll.name = "HeroInventoryScroll"
	scroll.custom_minimum_size.y = 124
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_inventory_scroll = scroll
	# A virtual grid: a big bag only builds the rows on screen (plus a small margin) and
	# reuses them while scrolling, so its cost no longer grows with the number of items.
	var grid := Control.new()
	grid.name = "HeroInventoryGrid"
	var rows := ceili(spare.size() / float(BAG_COLUMNS))
	grid.custom_minimum_size = Vector2(BAG_COLUMNS * BAG_STEP - BAG_GAP, maxf(0.0, rows * BAG_STEP - BAG_GAP))
	_bag_grid = grid
	_bag_uids = spare
	_bag_built = {}
	scroll.get_v_scroll_bar().value_changed.connect(func(_v): _fill_bag_rows())
	scroll.resized.connect(_fill_bag_rows)
	# Keep partial rows at the same left edge as a full five-item row.
	var contents: Control = grid
	if spare.is_empty():
		grid.free()
		var empty_text := "Chưa có trang bị loại này." if count > 0 else "Túi trống · Mở rương ở Cửa hàng để nhận trang bị"
		var empty := _paper_text(empty_text, 20, Color("fff1d1"))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.x = 600
		contents = empty
	# Keep badge clearance at the top/left; the right gutter is reserved for the
	# scrollbar so a longer inventory never widens the page or clips its frame.
	var bag_edge := Ui.margin(8, 8, 0, 8)
	bag_edge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	contents.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bag_edge.add_child(contents)
	scroll.add_child(bag_edge)
	box.add_child(scroll)
	scroll.set_deferred("scroll_vertical", _bag_scroll_y)
	_fill_bag_rows.call_deferred()
	return section


## Builds the bag cards of the rows in view and frees the ones scrolled far away.
func _fill_bag_rows() -> void:
	if not is_instance_valid(_bag_grid) or not is_instance_valid(_inventory_scroll):
		return
	var top := float(_inventory_scroll.scroll_vertical) - BAG_EDGE
	var height := maxf(_inventory_scroll.size.y, BAG_CARD)
	var first := maxi(0, floori(top / BAG_STEP) - BAG_ROW_MARGIN)
	var last := ceili((top + height) / BAG_STEP) + BAG_ROW_MARGIN
	var wanted := {}
	for row in range(first, last + 1):
		for col in BAG_COLUMNS:
			var index := row * BAG_COLUMNS + col
			if index >= _bag_uids.size():
				break
			wanted[index] = true
			if _bag_built.has(index):
				continue
			var card := _item_card(_bag_uids[index], BAG_CARD, false)
			card.position = Vector2(col * BAG_STEP, row * BAG_STEP)
			card.size = Vector2.ONE * BAG_CARD
			_bag_grid.add_child(card)
			_bag_built[index] = card
	for index in _bag_built.keys():
		if not wanted.has(index):
			_bag_built[index].queue_free()
			_bag_built.erase(index)


## Unworn items for the filter, in the chosen order. Each item gets one integer sort key
## (primary, secondary, uid) computed once, so the sort compares plain ints instead of
## looking items up on every comparison.
func _visible_spare() -> Array:
	var state: Dictionary = PlayerData.hero_cat
	var bag: Dictionary = state["bag"]
	var worn := {}
	for slot in state["equipped"]:
		worn[str(state["equipped"][slot])] = true
	var keyed := []
	for uid in bag:
		if worn.has(uid):
			continue
		var d: Dictionary = HeroCat.ITEMS.get(bag[uid]["id"], {})
		if d.is_empty():
			continue
		var slot: String = d["slot"]
		if not (_filter == "all" or (_filter == "weapon" and slot == "weapon") or (_filter == "gear" and slot != "weapon")):
			continue
		var rarity: int = d["rarity"]
		var level: int = bag[uid]["level"]
		var primary := rarity if _sort_by == "rarity" else level
		var secondary := level if _sort_by == "rarity" else rarity
		var rank := primary * 1000 + secondary
		if not _sort_descending:
			rank = -rank
		# Ties keep the oldest item first (uids are increasing numbers).
		keyed.append([rank, -int(uid) if str(uid).is_valid_int() else 0, uid])
	keyed.sort_custom(func(a, b): return a[0] > b[0] or (a[0] == b[0] and a[1] > b[1]))
	var out := []
	for entry in keyed:
		out.append(entry[2])
	return out


func _choose_filter(value: String) -> void:
	_filter = value
	_reset_bag_scroll = true
	_bag_scroll_y = 0
	SoundLib.play("click")
	build()


func _choose_sort(criterion: String, descending: bool) -> void:
	_sort_by = criterion
	_sort_descending = descending
	_reset_bag_scroll = true
	_bag_scroll_y = 0
	build()


func _open_sort_menu(anchor: Button) -> void:
	if is_instance_valid(_sort_overlay):
		_close_sort_menu()
		return
	_sort_overlay = Control.new()
	_sort_overlay.name = "EquipmentSortOverlay"
	add_child(_sort_overlay)
	_sort_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dismiss := Button.new()
	dismiss.name = "EquipmentSortDismiss"
	dismiss.flat = true
	dismiss.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus"]:
		dismiss.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_sort_overlay.add_child(dismiss)
	dismiss.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dismiss.pressed.connect(_close_sort_menu)
	var panel := PanelContainer.new()
	panel.name = "EquipmentSortMenu"
	panel.custom_minimum_size.x = 360
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f3e1be")
	style.border_color = Color("583f21")
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	_sort_overlay.add_child(panel)
	var options := Ui.vbox(10)
	panel.add_child(options)
	options.add_child(_paper_text("Sắp xếp", 24))
	var by := Ui.hbox(8)
	for choice in [["rarity", "Độ hiếm"], ["level", "Level"]]:
		var button := Ui.button(choice[1], "Yellow" if _sort_by == choice[0] else "White", Vector2(152, 58), 20)
		button.name = "EquipmentSortBy_" + choice[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_choose_sort.bind(choice[0], _sort_descending))
		by.add_child(button)
	options.add_child(by)
	var direction := Ui.hbox(8)
	for descending in [true, false]:
		var selected: bool = _sort_descending == descending
		var button := Ui.button("Giảm dần" if descending else "Tăng dần", "Yellow" if selected else "White", Vector2(152, 58), 20)
		button.name = "EquipmentSortDescending" if descending else "EquipmentSortAscending"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_choose_sort.bind(_sort_by, descending))
		direction.add_child(button)
	options.add_child(direction)
	panel.reset_size()
	_position_sort_menu.call_deferred(panel, anchor)
	panel.resized.connect(_position_sort_menu.bind(panel, anchor))


func _position_sort_menu(panel: PanelContainer, anchor: Button) -> void:
	if not is_instance_valid(panel) or not is_instance_valid(anchor):
		return
	var button_rect := anchor.get_global_rect()
	var inverse := get_global_transform().affine_inverse()
	var below: Vector2 = inverse * button_rect.end
	var above: Vector2 = inverse * button_rect.position
	var y := below.y + 8
	if y + panel.size.y > size.y - 12:
		y = above.y - panel.size.y - 8
	panel.position = Vector2(clampf(below.x - panel.size.x, 12, maxf(12, size.x - panel.size.x - 12)),
		clampf(y, 12, maxf(12, size.y - panel.size.y - 12)))


func _close_sort_menu() -> void:
	if is_instance_valid(_sort_overlay):
		remove_child(_sort_overlay)
		_sort_overlay.queue_free()
	_sort_overlay = null


func _close_sort_when_hidden() -> void:
	if not is_visible_in_tree():
		_close_sort_menu()


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(_sort_overlay) and event.is_action_pressed("ui_cancel"):
		_close_sort_menu()
		get_viewport().set_input_as_handled()


func _paper_text(text: String, font_size: int, color := Color("583f21")) -> Label:
	var result := Ui.label(text, "LabelDark", font_size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_constant_override("outline_size", 0)
	return result


func _gear_face(uid: String, size: float, can_upgrade := false) -> Control:
	var state: Dictionary = PlayerData.hero_cat
	var d := HeroCat.def(state, uid)
	var card := Ui.gear_card(d["icon"], HeroCat.SLOT_ICONS[d["slot"]], HeroCat.tone(d["rarity"]),
		str(HeroCat.item(state, uid)["level"]), size, can_upgrade)
	card.set_meta("equipment_uid", uid)
	var up: Control = card.get_node_or_null("EquipmentUpgrade")
	if up != null:
		up.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		up.offset_left = -size * 0.25
		up.offset_top = size * 0.28
		up.offset_right = size * 0.05
		up.offset_bottom = size * 0.58
		# Draw above this card's art without escaping in front of modal sheets.
		up.z_index = 0
		card.move_child(up, card.get_child_count() - 1)
		Ui.bob(up, 4, 1.1)
	return card


## A gear card that opens the item sheet when tapped.
func _item_card(uid: String, size: float, can_upgrade: bool) -> Control:
	var card := _gear_face(uid, size, can_upgrade)
	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.pressed.connect(func(): SoundLib.play("click"))
	hit.pressed.connect(_open_detail.bind(uid))
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The protruding corner label is part of the same item tap target.
	hit.offset_left = -8
	hit.offset_top = -8
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
	var kind := "%s · %s · Lv.%d/%d" % [Economy.RARITY_NAMES[d["rarity"]], HeroCat.SLOT_NAMES[d["slot"]], it["level"], HeroCat.level_cap(state, uid)]
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
		# At the rarity cap: fusing to the next rarity is what raises it.
		var at_top: bool = d["rarity"] >= HeroCat.LEVEL_CAP.size() - 1
		upgrade = Ui.button("Cấp tối đa" if at_top else "Ghép để mở cấp", "Yellow", Vector2(240, 96), 22)
		upgrade.disabled = true
	else:
		upgrade = Ui.cost_button("Nâng cấp", UiKit.format_number(cost), "coin", "Yellow", Vector2(240, 96))
		_blueprint_cost(upgrade, d["slot"], cost)
		upgrade.disabled = not PlayerData.hero_cat_can_upgrade(uid)
	upgrade.pressed.connect(func():
		if PlayerData.hero_cat_upgrade(uid):
			SoundLib.play("reward"))
	actions.add_child(upgrade)
	if not wearing:
		var wear := Ui.button("Trang bị", "Green", Vector2(240, 96), 26)
		wear.pressed.connect(func():
			UiKit.close_popup(_detail)
			PlayerData.hero_cat_equip(uid))
		actions.add_child(wear)
	box.add_child(actions)
	var more := Ui.hbox(14)
	var copies := HeroCat.copies(state, it["id"]).size()
	var target := HeroCat.fuse_target(it["id"])
	if target != "":
		var fuse := Ui.button("Ghép (%d/%d)" % [mini(copies, HeroCat.FUSE_COUNT), HeroCat.FUSE_COUNT], "Green", Vector2(240, 72), 22)
		fuse.disabled = copies < HeroCat.FUSE_COUNT
		fuse.tooltip_text = "3 món %s → 1 %s" % [d["name"], HeroCat.ITEMS[target]["name"]]
		fuse.pressed.connect(func():
			var new_uid := PlayerData.hero_cat_fuse(it["id"])
			if new_uid != "":
				SoundLib.play("merge")
				_detail_uid = new_uid
				_fill_detail())
		more.add_child(fuse)
	if not wearing:
		var salvage := Ui.button("Rã · +%d bản vẽ" % HeroCat.salvage_value(state, uid), "White", Vector2(240, 72), 22)
		salvage.pressed.connect(func():
			if PlayerData.hero_cat_salvage(uid) > 0:
				SoundLib.play("sell")
				UiKit.close_popup(_detail))
		more.add_child(salvage)
	if more.get_child_count() > 0:
		box.add_child(more)
	_style_detail_surface()


# Turns a gold cost_button into a Blueprint one: the slot's blueprint icon and have/need.
func _blueprint_cost(button: Button, slot: String, plans: int) -> void:
	var row: HBoxContainer = button.get_child(0).get_child(1)
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	row.add_child(UiKit.blueprint_icon(slot, 26))
	var have: int = PlayerData.blueprints.get(slot, 0)
	var label := Ui.label("%s/%s" % [UiKit.format_number(have), UiKit.format_number(plans)], "LabelSmall", 20)
	if have < plans:
		label.add_theme_color_override("font_color", Color("ff8f80"))
	row.add_child(label)

func _style_detail_surface() -> void:
	var overlay := _detail.get_meta("overlay", null) as Control
	if overlay == null:
		return
	for panel: PanelContainer in overlay.find_children("*", "PanelContainer", true, false):
		if not panel.has_meta("menu_panel_context"):
			continue
		var face := StyleBoxFlat.new()
		face.bg_color = Color("f9edcf") if panel.is_ancestor_of(_detail) else Color("edd9ae")
		face.border_color = Color("583f21")
		face.set_border_width_all(4)
		face.set_corner_radius_all(22)
		face.anti_aliasing = true
		face.content_margin_left = 28
		face.content_margin_right = 28
		face.content_margin_top = 30
		face.content_margin_bottom = 30
		panel.add_theme_stylebox_override("panel", face)


func _captioned(uid: String, caption: String) -> Control:
	var state: Dictionary = PlayerData.hero_cat
	var d := HeroCat.def(state, uid)
	var column := Ui.vbox(4)
	column.add_child(Ui.label(caption, "LabelDark", 17))
	column.add_child(Ui.center(_gear_face(uid, 120)))
	column.add_child(Ui.label(d["name"], "LabelDark", 19))
	return column
