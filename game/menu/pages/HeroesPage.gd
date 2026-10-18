extends "res://game/menu/pages/MenuPage.gd"

# Heroes (Tướng): the hero being looked at stands on a stage at the top (animated, with an
# aura in its rarity colour), with its buff, level / star upgrades and the LEAD button.
# Below, every hero as a card: owned ones show level and stars, locked ones their shard
# progress (30 shards unlock). The summon event button sits under the title.

const Heroes = preload("res://game/core/Heroes.gd")
const SummonPage = preload("res://game/menu/pages/SummonPage.gd")
const STAGE_SIZE := Vector2(672, 250)
const CARD_SIZE := Vector2(212, 250)

var _view := ""


func build() -> void:
	if _view == "" or not Heroes.HEROES.has(_view):
		_view = PlayerData.leader() if PlayerData.leader() != "" else Heroes.ORDER[0]
	var top := UiKit.hbox(12)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(UiKit.ribbon("Tướng", 26, UiKit.Ribbon.YELLOW))
	body.add_child(top)
	_build_summon_banner()
	_build_stage()
	_build_details()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	for id in Heroes.ORDER:
		grid.add_child(_card(id))
	body.add_child(grid)


func has_alert() -> bool:
	return PlayerData.hero_alert()


# A strip that opens the summon event, with the featured hero and the free pull.
func _build_summon_banner() -> void:
	var featured := PlayerData.summon_featured()
	var banner := Button.new()
	banner.custom_minimum_size = Vector2(0, 92)
	banner.focus_mode = Control.FOCUS_NONE
	var color: Color = Economy.RARITY_COLORS[Heroes.HEROES[featured]["rarity"]]
	var style := UiKit.card_style(color, Color(0.16, 0.08, 0.24, 0.95))
	for state in ["normal", "hover", "pressed"]:
		banner.add_theme_stylebox_override(state, style)
	banner.pressed.connect(func(): home.open_page(SummonPage))
	var row := UiKit.hbox(12)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(row)
	row.add_child(UiKit.drawn(UiKit.DrawnIcon.Kind.PORTAL, 64))
	var text := UiKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(UiKit.label("TRIỆU HỒI TƯỚNG QUÂN", 22, UiKit.GOLD_TEXT))
	text.add_child(UiKit.label("Nổi bật: %s" % Heroes.HEROES[featured]["name"], 16, color))
	row.add_child(text)
	row.add_child(UiKit.hero_portrait(featured, 70))
	if PlayerData.summon_free_ready():
		var free := UiKit.label("MIỄN PHÍ", 15, Color("7fd66b"))
		free.position = Vector2(470, -8)
		free.add_theme_stylebox_override("normal", UiKit.card_style(Color("7fd66b"), Color(0.05, 0.15, 0.05, 0.95)))
		banner.add_child(free)
	body.add_child(banner)


func _build_stage() -> void:
	var hero: Dictionary = Heroes.HEROES[_view]
	var owned := PlayerData.owns_hero(_view)
	var color: Color = Economy.RARITY_COLORS[hero["rarity"]]
	var stage := Control.new()
	stage.custom_minimum_size = STAGE_SIZE
	stage.clip_contents = true
	var back := Panel.new()
	back.size = STAGE_SIZE
	back.add_theme_stylebox_override("panel", UiKit.card_style(color, Color(0.07, 0.09, 0.13, 0.95)))
	stage.add_child(back)
	# Aura, drawn behind the hero, pulsing.
	var aura := Control.new()
	aura.size = STAGE_SIZE
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura.draw.connect(func():
		var t := Time.get_ticks_msec() / 1000.0
		var center := Vector2(170, 170)
		for i in 5:
			aura.draw_circle(center, (110.0 - i * 18.0) * (1.0 + 0.04 * sin(t * 3.0)), Color(color, 0.08 + i * 0.03))
		aura.draw_set_transform(center + Vector2(0, 46), 0.0, Vector2(1.0, 0.3))
		aura.draw_circle(Vector2.ZERO, 90.0, Color(0, 0, 0, 0.35))
		aura.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		aura.queue_redraw())
	stage.add_child(aura)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.unit_frames(hero["unit"], "Blue")
	sprite.material = UiKit.hero_material(_view)
	sprite.offset = Vector2(0, -SpriteLib.foot_offset(hero["unit"]))
	sprite.position = Vector2(170, 215)
	sprite.scale = Vector2(1.2, 1.2)
	sprite.play("idle")
	if not owned:
		sprite.modulate = Color(0.15, 0.15, 0.2)
	stage.add_child(sprite)
	if hero["rarity"] >= 3:
		var crown := UiKit.drawn(UiKit.DrawnIcon.Kind.CROWN, 46)
		crown.position = Vector2(147, 22)
		crown.size = Vector2(46, 46)
		stage.add_child(crown)

	var info := UiKit.vbox(4)
	info.position = Vector2(330, 18)
	info.size = Vector2(320, STAGE_SIZE.y - 36)
	stage.add_child(info)
	var name_label := UiKit.label(hero["name"], 26)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = 320
	info.add_child(name_label)
	info.add_child(UiKit.label(Economy.RARITY_NAMES[hero["rarity"]], 18, color))
	if owned:
		var h := PlayerData.hero_state(_view)
		info.add_child(UiKit.label("★".repeat(h["stars"]) + "☆".repeat(Heroes.MAX_STARS - h["stars"]) + "   Cấp %d/%d" % [h["level"], PlayerData.hero_level_cap(_view)], 18, UiKit.GOLD_TEXT))
		info.add_child(_buff_label(Heroes.bonus_text(_view, h["level"], h["stars"])))
	else:
		info.add_child(UiKit.label("Chưa sở hữu", 18, UiKit.WARN))
		info.add_child(_buff_label(Heroes.bonus_text(_view, 1, 1)))
	var story := UiKit.label(hero["story"], 15, Color(1, 1, 1, 0.7))
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.custom_minimum_size.x = 320
	info.add_child(story)
	if PlayerData.leader() == _view:
		var badge := UiKit.label("DẪN ĐỘI", 16, Color("7fd66b"))
		badge.add_theme_stylebox_override("normal", UiKit.card_style(Color("7fd66b"), Color(0.05, 0.15, 0.05, 0.95)))
		badge.position = Vector2(16, 14)
		stage.add_child(badge)
	body.add_child(stage)


func _buff_label(text: String) -> Label:
	var label := UiKit.label("✦ " + text, 18, Color("9ff0a0"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 320
	return label


func _build_details() -> void:
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var id := _view
	if not PlayerData.owns_hero(id):
		var shards: int = PlayerData.hero_state(id)["shards"]
		var unlock := UiKit.button("MỞ KHOÁ  %d/%d mảnh" % [shards, Heroes.UNLOCK_SHARDS], Vector2(360, 76), func(): PlayerData.hero_unlock(id))
		unlock.disabled = not PlayerData.hero_can_unlock(id)
		row.add_child(unlock)
		body.add_child(row)
		return
	var level_cost := PlayerData.hero_level_cost(id)
	var level_button := UiKit.button("", Vector2(210, 76), func(): PlayerData.hero_level_up(id))
	if level_cost < 0:
		level_button.text = "Cần lên sao"
		level_button.disabled = true
	else:
		level_button.text = "CẤP  %s" % UiKit.format_number(level_cost)
		level_button.icon = UiKit.coin_texture()
		level_button.add_theme_constant_override("icon_max_width", 28)
		level_button.disabled = PlayerData.gold < level_cost
	row.add_child(level_button)
	var star_cost := PlayerData.hero_star_cost(id)
	var shards: int = PlayerData.hero_state(id)["shards"]
	var star_button := UiKit.button("", Vector2(210, 76), func(): PlayerData.hero_star_up(id), true)
	star_button.text = "Sao tối đa" if star_cost < 0 else "SAO  %d/%d" % [shards, star_cost]
	star_button.disabled = star_cost < 0 or shards < star_cost
	row.add_child(star_button)
	var lead := UiKit.button("DẪN ĐỘI", Vector2(210, 76), func(): PlayerData.select_hero(id))
	lead.disabled = PlayerData.leader() == id
	row.add_child(lead)
	for b in [level_button, star_button, lead]:
		b.add_theme_font_size_override("font_size", 19)
	body.add_child(row)


func _card(id: String) -> Button:
	var hero: Dictionary = Heroes.HEROES[id]
	var owned := PlayerData.owns_hero(id)
	var color: Color = Economy.RARITY_COLORS[hero["rarity"]]
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	var style := UiKit.card_style(color if id == _view else color.darkened(0.35), Color(0.1, 0.12, 0.17, 0.95) if hero["rarity"] < 3 else Color(0.18, 0.13, 0.05, 0.95))
	style.set_border_width_all(5 if id == _view else 3)
	for state in ["normal", "hover", "pressed"]:
		card.add_theme_stylebox_override(state, style)
	card.pressed.connect(func():
		_view = id
		refresh())
	var column := UiKit.vbox(2)
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_top = 8
	column.offset_bottom = -8
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	var portrait := UiKit.hero_portrait(id, 110)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not owned:
		portrait.modulate = Color(0.3, 0.3, 0.35)
	column.add_child(portrait)
	var name_label := UiKit.label(hero["name"], 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = CARD_SIZE.x - 16
	column.add_child(name_label)
	var h := PlayerData.hero_state(id)
	if owned:
		var stars := UiKit.label("★".repeat(h["stars"]) + "  Cấp %d" % h["level"], 15, UiKit.GOLD_TEXT)
		stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(stars)
	var need: int = Heroes.UNLOCK_SHARDS if not owned else maxi(PlayerData.hero_star_cost(id), 1)
	var shard_row := UiKit.hbox(4)
	shard_row.alignment = BoxContainer.ALIGNMENT_CENTER
	shard_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shard_row.add_child(UiKit.shard_icon(id, 20))
	var bar := UiKit.bar(Color("7fd66b") if h["shards"] >= need else color, Vector2(120, 10))
	bar.max_value = need
	bar.value = h["shards"]
	shard_row.add_child(bar)
	shard_row.add_child(UiKit.label("%d/%d" % [h["shards"], need], 13))
	column.add_child(shard_row)
	if PlayerData.leader() == id:
		var badge := UiKit.label("DẪN ĐỘI", 13, Color("7fd66b"))
		badge.add_theme_stylebox_override("normal", UiKit.dark_style(6, Color("7fd66b")))
		badge.position = Vector2(8, 8)
		card.add_child(badge)
	if PlayerData.hero_can_improve(id):
		var dot := UiKit.drawn(UiKit.DrawnIcon.Kind.DOT, 22)
		dot.position = Vector2(CARD_SIZE.x - 30, 8)
		dot.size = Vector2(22, 22)
		card.add_child(dot)
	return card
