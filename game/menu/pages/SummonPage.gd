extends "res://game/menu/pages/MenuPage.gd"

# The troop summon (bottom tab "Triệu hồi"): gems recruit random troop cards, each one of
# the four cats as it lives in some world (Cats.gd). A first card unlocks that version; more
# cards raise its stars on the Lính tab. The banner features one world a day (its four
# versions are FEATURED_SHARE of the pulls of their rarity), then the pity counter toward
# a legendary, the rates, and x1 / x10 buttons. Results play
# in SummonOpening. Numbers live in HeroCat (SUMMON_*). Equipment comes from shop chests.

const HeroCat = preload("res://game/core/HeroCat.gd")
const Ui = preload("res://game/ui/Ui.gd")
const SummonOpening = preload("res://game/ui/SummonOpening.gd")
const Cats = preload("res://game/data/Cats.gd")
const CartonSummonBox = preload("res://game/ui/CartonSummonBox.gd")
const BANNER_MIN_HEIGHT := 460.0

func build() -> void:
	fill_available_height()
	body.add_theme_constant_override("separation", 16)
	var color: Color = Economy.RARITY_COLORS[3]
	body.add_child(_banner(color))

	var box := UiKit.vbox(10)
	var pity := UiKit.ink("Còn %d lượt chắc chắn ra lính Huyền thoại" % PlayerData.summon_pity_left(), 22)
	pity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pity)
	var bar := UiKit.bar(color, Vector2(0, 16))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = HeroCat.SUMMON_PITY
	bar.value = PlayerData.summon_pity
	box.add_child(bar)
	var note := UiKit.ink("Gói x10 chắc chắn có ít nhất 1 thẻ Sử thi · Thẻ đầu tiên mở khoá lính, thẻ trùng dùng để lên sao", 22)
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

	var world := PlayerData.featured_world()
	var title := UiKit.label(Cats.WORLD_NAMES[world].to_upper(), 30, UiKit.GOLD_TEXT)
	title.name = "SummonWorldTitle"
	title.add_theme_constant_override("outline_size", 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var names := []
	for id in Cats.world_versions(world):
		names.append(Cats.NAMES[Cats.cat_of(id)])
	var sub := _secondary("Bản thể của %s ở thế giới này · Đổi thế giới mỗi ngày" % ", ".join(names), 22)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(sub)

	# The daily cast sits behind the same carton used by the summon reveal.
	var art := Control.new()
	art.custom_minimum_size.y = 220
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.clip_contents = true
	column.add_child(art)
	var row := UiKit.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in Cats.world_versions(world):
		row.add_child(UiKit.troop_portrait(PlayerData.TROOPS[id], 120))
	art.add_child(row)
	var carton := CartonSummonBox.new()
	carton.name = "SummonBannerCarton"
	art.add_child(carton)
	carton.set_process(false)
	var fit := func():
		var row_scale := minf(1.0, art.size.x / 522.0)
		row.scale = Vector2.ONE * row_scale
		row.size = Vector2(art.size.x / maxf(row_scale, 0.01), 120)
		row.position = Vector2(0, maxf(4.0, art.size.y * 0.06))
		var carton_scale := minf(0.52, minf(art.size.x / 535.0, art.size.y / 420.0))
		carton.scale = Vector2.ONE * carton_scale
		carton.position = Vector2(art.size.x * 0.5, art.size.y - 4.0)
	art.resized.connect(fit)
	art.ready.connect(fit)

	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UiKit.card_style(color, Color(0.05, 0.04, 0.1, 0.85)))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag_box := UiKit.vbox(2)
	tag.add_child(tag_box)
	for caption in [
		_secondary("HUYỀN THOẠI · %s%%" % str(HeroCat.SUMMON_RARITY[3]).replace(".", ","), 20, color),
		UiKit.label("Lên đến 5★ · mỗi sao mở thêm 10 cấp", 22),
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
	opening.setup(results, func(): _summon(count))
	opening.attach(home)

func _show_rates() -> void:
	var box := UiKit.dark_popup(home, 560, "Tỉ lệ triệu hồi")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 8)
	for r in HeroCat.SUMMON_RARITY.size():
		var name_label := UiKit.ink("Lính " + Economy.RARITY_NAMES[r], 22)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(name_label)
		grid.add_child(UiKit.ink(("%.1f%%" % HeroCat.SUMMON_RARITY[r]).replace(".", ","), 22))
	box.add_child(grid)
	var pity := UiKit.ink(("Thế giới nổi bật: %d%% số thẻ mỗi phẩm chắc chắn là bản thể của thế giới hôm nay. "
		+ "Bảo hiểm: lượt thứ %d chắc chắn ra lính Huyền thoại. Lính đã tối đa sao thì thẻ trùng đổi thành vàng.") % [roundi(PlayerData.FEATURED_SHARE * 100), HeroCat.SUMMON_PITY], 22)
	pity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pity)
