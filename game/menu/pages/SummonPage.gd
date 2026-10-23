extends "res://game/menu/pages/MenuPage.gd"

# The equipment summon (bottom tab "Triệu hồi"): gems buy random items for the hero cat
# (weapons, helmets, armour, boots) plus some Forge Stones with every pull. A banner with
# the four item kinds, the pity counter toward a legendary, the rates, and x1 / x10 buttons.
# Results play in SummonOpening. Numbers live in HeroCat (SUMMON_*).

const HeroCat = preload("res://game/core/HeroCat.gd")
const Ui = preload("res://game/ui/Ui.gd")
const SummonOpening = preload("res://game/ui/SummonOpening.gd")
const BANNER_MIN_HEIGHT := 460.0
## The items shown standing on the banner, one per slot, best first.
const SHOWCASE := ["katana_nguyet", "mu_rong", "giap_rong", "giay_than"]

func build() -> void:
	fill_available_height()
	body.add_theme_constant_override("separation", 16)
	var color: Color = Economy.RARITY_COLORS[3]
	body.add_child(_banner(color))

	var box := UiKit.vbox(10)
	var pity := UiKit.ink("Còn %d lượt chắc chắn ra trang bị Huyền thoại" % PlayerData.summon_pity_left(), 22)
	pity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pity)
	var bar := UiKit.bar(color, Vector2(0, 16))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = HeroCat.SUMMON_PITY
	bar.value = PlayerData.summon_pity
	box.add_child(bar)
	var note := UiKit.ink("Gói x10 chắc chắn có ít nhất 1 Sử thi · Mỗi lượt kèm %d đá rèn · 3 món giống nhau ghép thành 1 món phẩm cao hơn" % HeroCat.SUMMON_STONES, 22)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	var rates := UiKit.button("XEM TỈ LỆ", Vector2(220, 64), _show_rates)
	rates.add_theme_font_size_override("font_size", 20)
	rates.add_theme_constant_override("outline_size", 3)
	rates.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(rates)
	body.add_child(Ui.menu_section("summon", "Bảo hiểm triệu hồi", box))

	var buttons := UiKit.hbox(18)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_child(_summon_button(1))
	buttons.add_child(_summon_button(10))
	body.add_child(buttons)

func tick() -> void:
	pass

func _banner(color: Color) -> Control:
	var banner := PanelContainer.new()
	banner.custom_minimum_size.y = BANNER_MIN_HEIGHT
	banner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	banner.clip_contents = true
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("211133")
	frame_style.border_color = color
	frame_style.set_border_width_all(5)
	frame_style.set_corner_radius_all(20)
	frame_style.set_content_margin_all(18)
	banner.add_theme_stylebox_override("panel", frame_style)
	var column := UiKit.vbox(8)
	banner.add_child(column)

	var title := UiKit.label("TRIỆU HỒI TRANG BỊ", 30, UiKit.GOLD_TEXT)
	title.add_theme_constant_override("outline_size", 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var sub := _secondary("Vũ khí · Mũ · Giáp · Giày cho mèo anh hùng", 22)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(sub)

	# The four best items stand on a turning summoning circle.
	var art := Control.new()
	art.custom_minimum_size.y = 220
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.clip_contents = true
	column.add_child(art)
	var row := UiKit.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in SHOWCASE:
		var d: Dictionary = HeroCat.ITEMS[id]
		row.add_child(Ui.gear_card(d["icon"], HeroCat.SLOT_ICONS[d["slot"]], HeroCat.tone(d["rarity"]), "", 112.0))
	art.add_child(row)
	var fit := func():
		row.size = Vector2(art.size.x, 0)
		row.position = Vector2(0, art.size.y * 0.62 - 56)
	art.resized.connect(fit)
	art.ready.connect(fit)
	art.draw.connect(func():
		var t := Time.get_ticks_msec() / 1000.0
		var center := art.size * Vector2(0.5, 0.5)
		var ray_length := maxf(art.size.x, art.size.y) * 1.5
		for i in 12:
			var angle := t * 0.25 + i * TAU / 12.0
			art.draw_colored_polygon(PackedVector2Array([center, center + Vector2.from_angle(angle - 0.09) * ray_length, center + Vector2.from_angle(angle + 0.09) * ray_length]), Color(color, 0.08))
		var radius := minf(art.size.x * 0.4, art.size.y * 0.52)
		art.draw_set_transform(art.size * Vector2(0.5, 0.86), 0.0, Vector2(1.0, 0.3))
		art.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color, 0.8), 6.0, true)
		art.draw_arc(Vector2.ZERO, radius * 0.82, t, t + TAU * 0.8, 48, Color(color.lightened(0.4), 0.7), 3.0, true)
		art.draw_circle(Vector2.ZERO, radius * 0.76, Color(color, 0.18))
		art.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		art.queue_redraw())

	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UiKit.card_style(color, Color(0.05, 0.04, 0.1, 0.85)))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag_box := UiKit.vbox(2)
	tag.add_child(tag_box)
	for caption in [
		_secondary("HUYỀN THOẠI · %s%%" % str(HeroCat.SUMMON_RARITY[3]).replace(".", ","), 20, color),
		UiKit.label("Vũ khí đổi chiêu của mèo và tăng sát thương 2 lớp lính hợp", 22),
	]:
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tag_box.add_child(caption)
	column.add_child(tag)
	return banner

func _secondary(text: String, font_size: int, color := UiKit.INFO) -> Label:
	var caption := UiKit.label(text, font_size, color)
	caption.add_theme_constant_override("outline_size", 2)
	return caption

func _summon_button(count: int) -> Button:
	var cost := PlayerData.summon_cost(count)
	var text := "TRIỆU HỒI x%d\n" % count + ("MIỄN PHÍ" if cost == 0 else "◆ %d" % cost)
	var b := UiKit.button(text, Vector2(300, 108), func(): _summon(count), count == 10)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 24)
	b.disabled = not PlayerData.can_summon(count)
	return b

func _summon(count: int) -> void:
	var results := PlayerData.summon(count)
	if results.is_empty():
		return
	var opening = SummonOpening.new()
	opening.setup(results, "", func(): _summon(count))
	opening.attach(home)

func _show_rates() -> void:
	var box := UiKit.dark_popup(home, 560, "Tỉ lệ triệu hồi")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 8)
	for r in HeroCat.SUMMON_RARITY.size():
		var name_label := UiKit.ink("Trang bị " + Economy.RARITY_NAMES[r], 22)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(name_label)
		grid.add_child(UiKit.ink(("%.1f%%" % HeroCat.SUMMON_RARITY[r]).replace(".", ","), 22))
	box.add_child(grid)
	var pity := UiKit.ink("Bảo hiểm: lượt thứ %d chắc chắn ra trang bị Huyền thoại. Món ra ngẫu nhiên trong 4 loại; loại nào chưa có phẩm đó thì ra phẩm thấp hơn gần nhất." % HeroCat.SUMMON_PITY, 22)
	pity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pity)
