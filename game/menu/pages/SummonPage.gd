extends "res://game/menu/pages/MenuPage.gd"

# The hero summon event (opened from the Events icon or the Heroes tab): a banner with
# the week's featured hero, a countdown, the pity counter, the rates, and the x1 / x10
# buttons. Results play in SummonOpening.

const Heroes = preload("res://game/core/Heroes.gd")
const SummonOpening = preload("res://game/ui/SummonOpening.gd")
const BANNER_SIZE := Vector2(672, 430)

var _countdown: Label


func build() -> void:
	var featured := PlayerData.summon_featured()
	var hero: Dictionary = Heroes.HEROES[featured]
	var color: Color = Economy.RARITY_COLORS[hero["rarity"]]
	body.add_child(_banner(featured, hero, color))

	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UiKit.card_style())
	var box := UiKit.vbox(6)
	info.add_child(box)
	var pity := UiKit.label("Còn %d lượt chắc chắn nhận %s" % [PlayerData.summon_pity_left(), hero["name"]], 18, UiKit.GOLD_TEXT)
	pity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pity)
	var bar := UiKit.bar(color, Vector2(560, 14))
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.max_value = Heroes.SUMMON_PITY
	bar.value = PlayerData.summon_pity
	box.add_child(bar)
	var note := UiKit.label("Gói x10 chắc chắn có ít nhất 1 tướng · Trùng tướng đổi thành %d mảnh" % Heroes.DUPLICATE_SHARDS, 15, UiKit.INFO)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	var rates := UiKit.button("XEM TỈ LỆ", Vector2(200, 52), _show_rates)
	rates.add_theme_font_size_override("font_size", 16)
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
	var banner := Control.new()
	banner.custom_minimum_size = BANNER_SIZE
	banner.clip_contents = true
	var back := Control.new()
	back.size = BANNER_SIZE
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Night-purple gradient, turning rays in the hero's colour, a summoning circle.
	back.draw.connect(func():
		var t := Time.get_ticks_msec() / 1000.0
		var w := BANNER_SIZE.x
		var h := BANNER_SIZE.y
		back.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("2a1244"), Color("2a1244"), Color("0d0a1c"), Color("0d0a1c")]))
		var center := Vector2(w * 0.5, h * 0.62)
		for i in 12:
			var angle := t * 0.25 + i * TAU / 12.0
			back.draw_colored_polygon(PackedVector2Array([center, center + Vector2.from_angle(angle - 0.09) * 700.0, center + Vector2.from_angle(angle + 0.09) * 700.0]), Color(color, 0.08))
		back.draw_set_transform(center + Vector2(0, 70), 0.0, Vector2(1.0, 0.32))
		back.draw_arc(Vector2.ZERO, 170.0, 0.0, TAU, 64, Color(color, 0.8), 6.0, true)
		back.draw_arc(Vector2.ZERO, 140.0, t, t + TAU * 0.8, 48, Color(color.lightened(0.4), 0.7), 3.0, true)
		back.draw_circle(Vector2.ZERO, 130.0, Color(color, 0.18))
		back.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		back.queue_redraw())
	banner.add_child(back)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.unit_frames(hero["unit"], "Blue")
	sprite.material = UiKit.hero_material(featured)
	sprite.offset = Vector2(0, -SpriteLib.foot_offset(hero["unit"]))
	sprite.position = Vector2(BANNER_SIZE.x * 0.5, BANNER_SIZE.y * 0.62 + 70)
	sprite.scale = Vector2(1.7, 1.7)
	sprite.play("idle")
	banner.add_child(sprite)
	var frame := Panel.new()
	frame.size = BANNER_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.draw_center = false
	frame_style.border_color = color
	frame_style.set_border_width_all(5)
	frame_style.set_corner_radius_all(20)
	frame.add_theme_stylebox_override("panel", frame_style)
	banner.add_child(frame)

	var head := UiKit.vbox(0)
	head.position = Vector2(0, 14)
	head.size = Vector2(BANNER_SIZE.x, 0)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(head)
	var title := UiKit.label("TRIỆU HỒI TƯỚNG QUÂN", 32, UiKit.GOLD_TEXT)
	title.add_theme_constant_override("outline_size", 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title)
	_countdown = UiKit.label("", 16, UiKit.INFO)
	_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_countdown)

	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UiKit.card_style(color, Color(0.05, 0.04, 0.1, 0.85)))
	tag.position = Vector2(20, BANNER_SIZE.y - 96)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag_box := UiKit.vbox(0)
	tag.add_child(tag_box)
	tag_box.add_child(UiKit.label("%s · TỈ LỆ TĂNG!" % Economy.RARITY_NAMES[hero["rarity"]].to_upper(), 15, color))
	tag_box.add_child(UiKit.label(hero["name"], 24))
	tag_box.add_child(UiKit.label("✦ " + Heroes.bonus_text(featured, 1, 1), 15, Color("9ff0a0")))
	banner.add_child(tag)
	if hero["rarity"] >= 3:
		var crown := UiKit.drawn(UiKit.DrawnIcon.Kind.CROWN, 56)
		crown.position = Vector2(BANNER_SIZE.x * 0.5 - 28, 120)
		crown.size = Vector2(56, 56)
		banner.add_child(crown)
	return banner


func _summon_button(count: int) -> Button:
	var cost := PlayerData.summon_cost(count)
	var text := "TRIỆU HỒI x%d\n" % count + ("MIỄN PHÍ" if cost == 0 else "◆ %d" % cost)
	var b := UiKit.button(text, Vector2(300, 100), func(): _summon(count), count == 10)
	b.add_theme_font_size_override("font_size", 22)
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
		var name_label := UiKit.label(names[row[0]], 18)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(name_label)
		grid.add_child(UiKit.label(("%.1f%%" % row[1]).replace(".", ","), 18, UiKit.GOLD_TEXT))
	box.add_child(grid)
	var pity := UiKit.label("Bảo hiểm: lượt thứ %d chắc chắn ra tướng nổi bật. Tính cả bảo hiểm, tỉ lệ nhận tướng nổi bật thực tế khoảng 2,9%%." % Heroes.SUMMON_PITY, 16, UiKit.INFO)
	pity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pity)
