extends "res://game/menu/pages/MenuPage.gd"

# The hero summon event (opened from the Events icon or the Heroes tab): a banner with
# the week's featured hero, a countdown, the pity counter, the rates, and the x1 / x10
# buttons. Results play in SummonOpening.

const Heroes = preload("res://game/core/Heroes.gd")
const SummonOpening = preload("res://game/ui/SummonOpening.gd")
const BANNER_MIN_HEIGHT := 460.0

var _countdown: Label


func build() -> void:
	fill_available_height()
	body.add_theme_constant_override("separation", 16)
	var featured := PlayerData.summon_featured()
	var hero: Dictionary = Heroes.HEROES[featured]
	var color: Color = Economy.RARITY_COLORS[hero["rarity"]]
	body.add_child(_banner(featured, hero, color))

	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UiKit.card_style())
	var box := UiKit.vbox(10)
	info.add_child(box)
	var pity := _secondary("Còn %d lượt chắc chắn nhận %s" % [PlayerData.summon_pity_left(), hero["name"]], 22, UiKit.GOLD_TEXT)
	pity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pity)
	var bar := UiKit.bar(color, Vector2(0, 16))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = Heroes.SUMMON_PITY
	bar.value = PlayerData.summon_pity
	box.add_child(bar)
	var note := _secondary("Gói x10 chắc chắn có ít nhất 1 tướng · Trùng tướng đổi thành %d mảnh" % Heroes.DUPLICATE_SHARDS, 22)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	var rates := UiKit.button("XEM TỈ LỆ", Vector2(220, 64), _show_rates)
	rates.add_theme_font_size_override("font_size", 20)
	rates.add_theme_constant_override("outline_size", 3)
	rates.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(rates)
	body.add_child(info)

	var buttons := UiKit.hbox(18)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_child(_summon_button(1))
	buttons.add_child(_summon_button(10))
	body.add_child(buttons)
	tick()


func tick() -> void:
	if _countdown == null or not is_instance_valid(_countdown):
		return
	var left := PlayerData.summon_seconds_left()
	_countdown.text = "Kết thúc sau %d ngày %s" % [left / 86400, UiKit.format_time(left % 86400)]


func _banner(featured: String, hero: Dictionary, color: Color) -> Control:
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

	var head := UiKit.vbox(2)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(head)
	var title := UiKit.label("TRIỆU HỒI TƯỚNG QUÂN", 30, UiKit.GOLD_TEXT)
	title.add_theme_constant_override("outline_size", 5)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title)
	_countdown = _secondary("", 22)
	_countdown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_countdown)

	# The scene receives spare height; the information and pull buttons stay together
	# in the lower action area. A short viewport scrolls the same column.
	var art := Control.new()
	art.custom_minimum_size.y = 220
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.clip_contents = true
	column.add_child(art)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.unit_frames(hero["unit"], "Blue")
	sprite.material = UiKit.hero_material(featured)
	sprite.offset = Vector2(0, -SpriteLib.foot_offset(hero["unit"]))
	sprite.play("idle")
	art.add_child(sprite)
	var crown: Control
	if hero["rarity"] >= 3:
		crown = UiKit.drawn(UiKit.DrawnIcon.Kind.CROWN, 56)
		crown.size = Vector2(56, 56)
		art.add_child(crown)
	var natural_size := sprite.sprite_frames.get_frame_texture("idle", 0).get_size()
	var fit_sprite := func():
		var scale_factor := minf(art.size.x * 0.5 / natural_size.x, art.size.y * 0.76 / natural_size.y)
		sprite.scale = Vector2.ONE * scale_factor
		sprite.position = Vector2(art.size.x * 0.5, art.size.y * 0.82)
		if crown != null:
			crown.position = Vector2(sprite.position.x - 28, maxf(0, sprite.position.y - natural_size.y * scale_factor - 12))
	art.resized.connect(fit_sprite)
	art.ready.connect(fit_sprite)
	# Turning rays and the circle follow the available scene bounds.
	art.draw.connect(func():
		var t := Time.get_ticks_msec() / 1000.0
		var center := art.size * Vector2(0.5, 0.5)
		var ray_length := maxf(art.size.x, art.size.y) * 1.5
		for i in 12:
			var angle := t * 0.25 + i * TAU / 12.0
			art.draw_colored_polygon(PackedVector2Array([center, center + Vector2.from_angle(angle - 0.09) * ray_length, center + Vector2.from_angle(angle + 0.09) * ray_length]), Color(color, 0.08))
		var radius := minf(art.size.x * 0.28, art.size.y * 0.52)
		art.draw_set_transform(art.size * Vector2(0.5, 0.82), 0.0, Vector2(1.0, 0.32))
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
		_secondary("%s · TỈ LỆ TĂNG!" % Economy.RARITY_NAMES[hero["rarity"]].to_upper(), 20, color),
		UiKit.label(hero["name"], 28),
		_secondary("✦ " + Heroes.bonus_text(featured, 1, 1), 20, Color("9ff0a0")),
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
	opening.setup(results, PlayerData.summon_featured(), func(): _summon(count))
	opening.attach(home)


func _show_rates() -> void:
	var box := UiKit.dark_popup(home, 560, "Tỉ lệ triệu hồi")
	var names := {
		"featured": "Tướng nổi bật (%s)" % Heroes.HEROES[PlayerData.summon_featured()]["name"],
		"legendary": "Tướng Huyền thoại khác", "epic": "Tướng Sử thi", "rare": "Tướng Hiếm",
		"featured_shards": "%d mảnh tướng nổi bật" % Heroes.FEATURED_SHARDS,
		"shards": "%d mảnh tướng ngẫu nhiên" % Heroes.RANDOM_SHARDS,
		"gold": "%d vàng" % Heroes.SUMMON_GOLD,
	}
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 8)
	for row in Heroes.SUMMON_TABLE:
		var name_label := UiKit.ink(names[row[0]], 22)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		grid.add_child(name_label)
		grid.add_child(UiKit.ink(("%.1f%%" % row[1]).replace(".", ","), 22))
	box.add_child(grid)
	var pity := UiKit.ink("Bảo hiểm: lượt thứ %d chắc chắn ra tướng nổi bật. Tính cả bảo hiểm, tỉ lệ nhận tướng nổi bật thực tế khoảng 2,9%%." % Heroes.SUMMON_PITY, 22)
	pity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pity)
