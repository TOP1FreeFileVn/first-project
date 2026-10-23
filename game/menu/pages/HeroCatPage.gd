extends "res://game/menu/pages/MenuPage.gd"

# Approved paperboard equipment layout: four slots around the cat, a light power
# plaque, compact stat/skill rows and a five-column inventory with local filters.
# Tapping a real item keeps the existing comparison, gold upgrade and equip flow.
# Item data is placeholder until the design sheet's Hero&Weapon tab is filled (HeroCat.gd).

const Ui = preload("res://game/ui/Ui.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const TroopData = preload("res://game/data/TroopData.gd")
const PaperboardFrame = preload("res://game/ui/PaperboardFrame.gd")
const BADGE_GLYPH = preload("res://game/ui/equipment_badge_glyph.gdshader")
const BOOTS_BADGE = preload("res://game/ui/art/equipment_badge_boots.svg")
const SIDE_CARD := 124.0
const SLOTS_PER_SIDE := 2
const BAG_CARD := 124.0
## Soldier class -> its tier-1 weapon icon (how the classes are shown everywhere).
const KLASS_ICONS := ["w_kiem", "w_cung", "w_gay_phep", "w_giao"]
## These are text accents on the light mint inset, not rarity-card fills.
const UP := Color("1c5326")
const DOWN := Color("8b2828")

var _column: VBoxContainer
var _detail: VBoxContainer
var _detail_uid := ""
var _filter := "all"
var _sort_descending := true
var _bag_scroll_y := 0
var _reset_bag_scroll := false
var _inventory_scroll: ScrollContainer
var _paper_grain: Texture2D
var _badge_material: ShaderMaterial
var _badge_textures: Dictionary = {}


func _init() -> void:
	super()
	body.get_parent().get_parent().visible = false
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_badge_material = ShaderMaterial.new()
	_badge_material.shader = BADGE_GLYPH


func refresh() -> void:
	build()
	if _detail != null and is_instance_valid(_detail):
		_fill_detail()


func build() -> void:
	if _column != null:
		if is_instance_valid(_inventory_scroll) and not _reset_bag_scroll:
			_bag_scroll_y = _inventory_scroll.scroll_vertical
		remove_child(_column)
		_column.queue_free()
	if _paper_grain == null:
		_paper_grain = Ui.tex("paper_grain")
	_column = Ui.vbox(12)
	_column.name = "HeroPaperboardLayout"
	add_child(_column)
	_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_column.add_child(_doll())
	_column.add_child(_bag())
	_reset_bag_scroll = false


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
	sheet.grain = _paper_grain
	var box := Ui.vbox(6)
	sheet.add_child(box)

	var row := Ui.hbox(14)
	row.name = "HeroEquipmentRow"
	var left := _slot_column(HeroCat.SLOTS.slice(0, SLOTS_PER_SIDE))
	left.name = "HeroEquipmentLeft"
	row.add_child(left)
	var stage := Control.new()
	stage.name = "HeroPreviewStage"
	stage.custom_minimum_size = Vector2(0, SIDE_CARD * SLOTS_PER_SIDE + 16)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var halo := PaperboardFrame.new()
	halo.kind = "halo"
	halo.custom_minimum_size = Vector2(232, 204)
	Ui.pin(stage, halo, Vector2(-116, 18), Control.PRESET_CENTER_TOP)
	var name_label := _paper_text("Mèo anh hùng", 20)
	stage.add_child(name_label)
	name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_label.offset_top = -8
	name_label.offset_bottom = 24
	var cat := Ui.image("cat_hero", Vector2(312, 224))
	cat.name = "HeroPreview"
	cat.texture = SpriteLib.hero_cat_texture(state)
	Ui.pin(stage, cat, Vector2(-156, -246), Control.PRESET_CENTER_BOTTOM)
	Ui.bob(cat, 3.0, 1.6)
	var stats := PlayerData.hero_cat_stats()
	var power := Ui.hbox(10)
	var seal := PaperboardFrame.new()
	seal.kind = "power_icon"
	seal.custom_minimum_size = Vector2(44, 44)
	seal.add_child(Ui.center(Ui.icon("power", 36)))
	power.add_child(seal)
	var power_value := _paper_text(UiKit.format_number(HeroCat.power(stats)), 32)
	power_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power.add_child(power_value)
	var plaque := PaperboardFrame.new()
	plaque.kind = "plaque"
	plaque.name = "HeroCombatPower"
	plaque.custom_minimum_size = Vector2(232, 56)
	plaque.add_child(power)
	# Center the entire paper label even when a longer power value widens it.
	var power_holder := Ui.center(plaque)
	power_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(power_holder)
	power_holder.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	power_holder.offset_top = -56
	row.add_child(stage)
	var right := _slot_column(HeroCat.SLOTS.slice(SLOTS_PER_SIDE))
	right.name = "HeroEquipmentRight"
	row.add_child(right)
	box.add_child(row)

	var totals := Ui.hbox(0)
	totals.custom_minimum_size.y = 54
	for key in ["hp", "atk", "def"]:
		if key != "hp":
			var divider := VSeparator.new()
			var line := StyleBoxLine.new()
			line.color = Color("a47a48")
			line.thickness = 2
			line.vertical = true
			divider.add_theme_stylebox_override("separator", line)
			totals.add_child(divider)
		var stat := Ui.hbox(7)
		stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat.add_child(Ui.icon(HeroCat.STAT_ICONS[key], 38))
		stat.add_child(_paper_text(UiKit.format_number(stats[key]), 22))
		totals.add_child(stat)
	var stat_panel := PanelContainer.new()
	var stat_style := StyleBoxFlat.new()
	stat_style.bg_color = Color.TRANSPARENT
	stat_style.border_color = Color("a47a48")
	stat_style.border_width_top = 2
	stat_style.border_width_bottom = 2
	stat_panel.add_theme_stylebox_override("panel", stat_style)
	stat_panel.add_child(totals)
	box.add_child(stat_panel)
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
	section.grain = _paper_grain
	section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := Ui.vbox(8)
	section.add_child(box)
	var heading := Ui.hbox(0)
	heading.custom_minimum_size.y = 58
	var tag := PanelContainer.new()
	var tag_style := StyleBoxFlat.new()
	tag_style.bg_color = Color("dfbb87")
	tag_style.border_color = Color("583f21")
	tag_style.set_border_width_all(3)
	tag_style.border_width_top = 0
	tag_style.corner_radius_bottom_left = 12
	tag_style.corner_radius_bottom_right = 12
	tag_style.content_margin_left = 22
	tag_style.content_margin_right = 22
	tag.add_theme_stylebox_override("panel", tag_style)
	tag.add_child(_paper_text("Túi trang bị", 24))
	heading.add_child(tag)
	heading.add_child(Ui.spacer())
	var count := HeroCat.spare(PlayerData.hero_cat).size()
	var stones := Ui.hbox(4)
	stones.name = "HeroForgeStones"
	stones.add_child(UiKit.forge_stone_icon(28))
	stones.add_child(_paper_text(UiKit.format_number(PlayerData.forge_stones), 20, Color("fff1d1")))
	heading.add_child(stones)
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
	var sort := Ui.button("Độ hiếm " + ("↓" if _sort_descending else "↑"), "Yellow", Vector2(154, 48), 18)
	sort.name = "EquipmentSort"
	sort.add_theme_constant_override("outline_size", 3)
	sort.pressed.connect(_toggle_sort)
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
	var grid := GridContainer.new()
	grid.name = "HeroInventoryGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for uid in spare:
		grid.add_child(_item_card(uid, BAG_CARD, false))
	# Keep partial rows at the same left edge as a full five-item row.
	var contents: Control = grid
	if spare.is_empty():
		grid.free()
		var empty_text := "Chưa có trang bị loại này." if count > 0 else "Túi trống · Nhận trang bị ở tab Triệu hồi"
		var empty := _paper_text(empty_text, 20, Color("fff1d1"))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.x = 600
		contents = empty
	# Keep clearance for the protruding badges at the scroll's top/left edge.
	var bag_edge := Ui.margin(8, 8, 8, 8)
	bag_edge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	contents.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bag_edge.add_child(contents)
	scroll.add_child(bag_edge)
	box.add_child(scroll)
	scroll.set_deferred("scroll_vertical", _bag_scroll_y)
	return section


func _visible_spare() -> Array:
	var state: Dictionary = PlayerData.hero_cat
	var visible := HeroCat.spare(state).filter(func(uid):
		var slot: String = HeroCat.def(state, uid)["slot"]
		return _filter == "all" or (_filter == "weapon" and slot == "weapon") or (_filter == "gear" and slot != "weapon"))
	if not _sort_descending:
		visible.reverse()
	return visible


func _choose_filter(value: String) -> void:
	_filter = value
	_reset_bag_scroll = true
	_bag_scroll_y = 0
	SoundLib.play("click")
	build()


func _toggle_sort() -> void:
	_sort_descending = not _sort_descending
	_reset_bag_scroll = true
	_bag_scroll_y = 0
	build()


func _paper_text(text: String, font_size: int, color := Color("583f21")) -> Label:
	var result := Ui.label(text, "LabelDark", font_size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_constant_override("outline_size", 0)
	return result


## Center painted bounds, not each source SVG's different transparent margins.
func _category_badge_texture(slot: String) -> Texture2D:
	if _badge_textures.has(slot):
		return _badge_textures[slot]
	var source: Texture2D = BOOTS_BADGE if slot == "boots" else Ui.tex("icon_" + HeroCat.SLOT_ICONS[slot])
	var bounds := source.get_image().get_used_rect()
	if not bounds.has_area():
		return source
	var cropped := AtlasTexture.new()
	cropped.atlas = source
	cropped.region = bounds
	cropped.filter_clip = true
	_badge_textures[slot] = cropped
	return cropped


func _gear_face(uid: String, size: float, can_upgrade := false) -> Control:
	var state: Dictionary = PlayerData.hero_cat
	var d := HeroCat.def(state, uid)
	var card := Ui.gear_card(d["icon"], HeroCat.SLOT_ICONS[d["slot"]], HeroCat.tone(d["rarity"]),
		str(HeroCat.item(state, uid)["level"]), size, can_upgrade)
	card.set_meta("equipment_uid", uid)
	var old_frame := card.get_child(0)
	card.remove_child(old_frame)
	old_frame.queue_free()
	var frame := PaperboardFrame.new()
	frame.kind = "card"
	frame.tone = HeroCat.tone(d["rarity"])
	card.add_child(frame)
	card.move_child(frame, 0)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var badge_size := size * 0.29
	var badge_position := Vector2(-2, -2)
	var badge_frame := PaperboardFrame.new()
	badge_frame.name = "EquipmentCategoryBadge"
	badge_frame.kind = "badge"
	badge_frame.tone = HeroCat.tone(d["rarity"])
	badge_frame.custom_minimum_size = Vector2.ONE * badge_size
	Ui.pin(card, badge_frame, badge_position)
	var old_badge: TextureRect = card.get_node("SlotBadge")
	var badge_index := old_badge.get_index()
	card.remove_child(old_badge)
	old_badge.queue_free()
	card.move_child(badge_frame, badge_index)
	# Build at the fitted size: shrinking the old glyph retains its cached minimum.
	var badge := TextureRect.new()
	badge.name = "SlotBadge"
	badge.texture = _category_badge_texture(d["slot"])
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2.ONE * (badge_size - 12)
	badge.material = _badge_material
	Ui.pin(card, badge, badge_position + Vector2.ONE * 6)
	card.move_child(badge, badge_index + 1)
	var level: Label = card.get_node("EquipmentLevel")
	level.add_theme_color_override("font_color", Color.WHITE)
	level.add_theme_color_override("font_outline_color", Color("241c1c"))
	level.add_theme_constant_override("outline_size", 3)
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
		upgrade = Ui.button("Cấp tối đa", "Yellow", Vector2(240, 96), 22)
		upgrade.disabled = true
	else:
		upgrade = Ui.cost_button("Nâng cấp", UiKit.format_number(cost), "coin", "Yellow", Vector2(240, 96))
		_stone_cost(upgrade, cost, HeroCat.upgrade_gold(state, uid))
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
		var salvage := Ui.button("Rã · +%d đá" % HeroCat.salvage_value(state, uid), "White", Vector2(240, 72), 22)
		salvage.pressed.connect(func():
			if PlayerData.hero_cat_salvage(uid) > 0:
				SoundLib.play("sell")
				UiKit.close_popup(_detail))
		more.add_child(salvage)
	if more.get_child_count() > 0:
		box.add_child(more)
	_style_detail_surface()


# Turns a gold cost_button into a Forge Stone one: the stone icon and count, then the gold.
func _stone_cost(button: Button, stones: int, gold: int) -> void:
	var row: HBoxContainer = button.get_child(0).get_child(1)
	var coin := row.get_child(0)
	row.remove_child(coin)
	coin.queue_free()
	row.add_child(UiKit.forge_stone_icon(26))
	row.move_child(row.get_child(row.get_child_count() - 1), 0)
	(row.get_child(1) as Label).text = UiKit.format_number(stones)
	if gold > 0:
		row.add_child(Ui.icon("coin", 22))
		row.add_child(Ui.label(UiKit.format_number(gold), "LabelSmall", 18))

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
