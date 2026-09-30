extends "res://game/menu/pages/MenuPage.gd"

# Level select, midcore style: a big "MÀN N" title, a card with the level's own scene that
# you swipe (or arrow) left and right between levels (its enemies stand in the scene),
# page dots, the rewards and the PLAY button for the level on the card. Behind it all the same
# scene, blown up and darkened, fills the page and cross-fades when the level changes.
# Locked levels can be looked at but not played.

const LevelArt = preload("res://game/menu/widgets/LevelArt.gd")
const CARD_SIZE := Vector2(560, 460)
const STAGE_WIDTH := 672.0
const SWIPE_DISTANCE := 70.0
const SLIDE_TIME := 0.22

var _selected := -1
var _stage: Control
var _card: Control
var _number: Label
var _name: Label
var _dots: HBoxContainer
var _info: VBoxContainer
var _play: Button
var _drag_from := -1.0
var _sliding := false
var _backdrop: Control
var _backdrop_art: Control
var _backdrop_level := -1


func _init() -> void:
	super()
	_backdrop = Control.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.clip_contents = true
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	move_child(_backdrop, 0)
	# Darkens the scene, most at the top and bottom where the text and buttons are.
	var shade := Control.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.draw.connect(func():
		var h := shade.size.y
		var w := shade.size.x
		var top := Color(0.02, 0.03, 0.05, 0.75)
		var middle := Color(0.02, 0.03, 0.05, 0.35)
		var bottom := Color(0.02, 0.03, 0.05, 0.85)
		shade.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.4), Vector2(0, h * 0.4)]), PackedColorArray([top, top, middle, middle]))
		shade.draw_polygon(PackedVector2Array([Vector2(0, h * 0.4), Vector2(w, h * 0.4), Vector2(w, h), Vector2(0, h)]), PackedColorArray([middle, middle, bottom, bottom])))
	shade.resized.connect(shade.queue_redraw)
	_backdrop.add_child(shade)


func build() -> void:
	if _selected < 0:
		_selected = PlayerData.unlocked_levels - 1

	var header := UiKit.vbox(0)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	_number = UiKit.label("", 44, UiKit.GOLD_TEXT)
	_number.add_theme_constant_override("outline_size", 10)
	_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(_number)
	_name = UiKit.label("", 22)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(_name)
	body.add_child(header)

	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(STAGE_WIDTH, CARD_SIZE.y)
	_stage.clip_contents = true
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_on_stage_input)
	body.add_child(_stage)
	_card = _make_card(_selected)
	_stage.add_child(_card)
	var prev := UiKit.button("◀", Vector2(56, 90), func(): _go(-1))
	prev.position = Vector2(0, CARD_SIZE.y / 2.0 - 45)
	_stage.add_child(prev)
	var next := UiKit.button("▶", Vector2(56, 90), func(): _go(1))
	next.position = Vector2(STAGE_WIDTH - 56, CARD_SIZE.y / 2.0 - 45)
	_stage.add_child(next)

	_dots = UiKit.hbox(8)
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(_dots)
	_info = UiKit.vbox(8)
	body.add_child(_info)
	_play = UiKit.button("CHƠI", Vector2(420, 106), func(): home.start_battle(_selected))
	_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_play.add_theme_font_size_override("font_size", 40)
	body.add_child(_play)
	_fill_level()


func has_alert() -> bool:
	# A level unlocked but never cleared.
	return PlayerData.stars_for(PlayerData.unlocked_levels - 1) == 0


# --- Carousel -----------------------------------------------------------------------------

func _go(step: int) -> void:
	var target := _selected + step
	if _sliding or target < 0 or target >= PlayerData.LEVELS.size():
		_snap_back()
		return
	_sliding = true
	var old := _card
	_selected = target
	_card = _make_card(target)
	_card.position.x = _card_x() + step * STAGE_WIDTH
	_stage.add_child(_card)
	_stage.move_child(_card, 0)
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(old, "position:x", _card_x() - step * STAGE_WIDTH, SLIDE_TIME)
	tween.tween_property(_card, "position:x", _card_x(), SLIDE_TIME)
	tween.chain().tween_callback(func():
		old.queue_free()
		_sliding = false)
	_fill_level()


func _on_stage_input(event: InputEvent) -> void:
	if _sliding:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_from = event.position.x
		elif _drag_from >= 0.0:
			var moved: float = event.position.x - _drag_from
			_drag_from = -1.0
			if moved <= -SWIPE_DISTANCE:
				_go(1)
			elif moved >= SWIPE_DISTANCE:
				_go(-1)
			else:
				_snap_back()
	elif event is InputEventMouseMotion and _drag_from >= 0.0:
		# The card follows the finger, with resistance past the first and last level.
		var moved: float = event.position.x - _drag_from
		var at_end := (moved > 0.0 and _selected == 0) or (moved < 0.0 and _selected == PlayerData.LEVELS.size() - 1)
		_card.position.x = _card_x() + moved * (0.3 if at_end else 1.0)


func _snap_back() -> void:
	if _card != null:
		create_tween().tween_property(_card, "position:x", _card_x(), 0.15)


func _card_x() -> float:
	return (STAGE_WIDTH - CARD_SIZE.x) / 2.0


func _make_card(index: int) -> Control:
	var locked := not PlayerData.can_select(index)
	# Plain Control (not a container) so the strip and lock keep their own positions.
	var card := Control.new()
	card.position = Vector2(_card_x(), 0)
	card.size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := StyleBoxFlat.new()
	frame.draw_center = false
	frame.set_border_width_all(6)
	frame.border_color = Color("5b3a1e") if not locked else Color(0.2, 0.2, 0.22)
	frame.set_corner_radius_all(18)
	# The art is clipped to the card; the frame is drawn over it to round the corners.
	var art = LevelArt.new()
	art.level_index = index
	art.locked = locked
	art.enemy_ids = _enemy_ids(PlayerData.level_data(index))
	art.size = CARD_SIZE
	card.add_child(art)
	var border := Panel.new()
	border.size = CARD_SIZE
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.add_theme_stylebox_override("panel", frame)
	card.add_child(border)

	# Bottom strip: stars, or how to unlock.
	var strip := PanelContainer.new()
	var strip_style := StyleBoxFlat.new()
	strip_style.bg_color = Color(0.05, 0.06, 0.08, 0.7)
	strip_style.corner_radius_bottom_left = 14
	strip_style.corner_radius_bottom_right = 14
	strip_style.set_content_margin_all(6)
	strip.add_theme_stylebox_override("panel", strip_style)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.position = Vector2(6, CARD_SIZE.y - 66)
	strip.size = Vector2(CARD_SIZE.x - 12, 60)
	var text: Label
	if locked:
		text = UiKit.label("Qua màn %d để mở khoá" % index, 24, UiKit.WARN)
		var lock := UiKit.drawn(UiKit.DrawnIcon.Kind.LOCK, 110)
		lock.position = CARD_SIZE / 2.0 - Vector2(55, 80)
		lock.size = Vector2(110, 110)
		card.add_child(lock)
	else:
		var stars := PlayerData.stars_for(index)
		text = UiKit.label("★".repeat(stars) + "☆".repeat(3 - stars), 40, UiKit.GOLD_TEXT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strip.add_child(text)
	card.add_child(strip)
	# First-clear bonus as a tag in the card's corner.
	if not locked and PlayerData.stars_for(index) == 0:
		var note := "LẦN ĐẦU: x2 vàng"
		var gift: String = Economy.FIRST_CLEAR_GIFT.get(index, "")
		if gift != "":
			note += " + %s" % PlayerData.TROOPS[gift].display_name
		var tag := PanelContainer.new()
		var tag_style := StyleBoxFlat.new()
		tag_style.bg_color = Color(0.12, 0.08, 0.02, 0.85)
		tag_style.border_color = UiKit.GOLD_TEXT
		tag_style.set_border_width_all(2)
		tag_style.set_corner_radius_all(12)
		tag_style.content_margin_left = 12
		tag_style.content_margin_right = 12
		tag_style.content_margin_top = 3
		tag_style.content_margin_bottom = 3
		tag.add_theme_stylebox_override("panel", tag_style)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.position = Vector2(16, 16)
		tag.add_child(UiKit.label("★ " + note, 17, UiKit.GOLD_TEXT))
		card.add_child(tag)
	return card


# --- Details for the level on the card ------------------------------------------------------

func _fill_level() -> void:
	var index := _selected
	var level: Resource = PlayerData.level_data(index)
	var locked := not PlayerData.can_select(index)
	_show_backdrop(index, locked)
	var parts: PackedStringArray = level.display_name.split(" · ")
	_number.text = "MÀN %d" % (index + 1)
	_name.text = parts[parts.size() - 1] if parts.size() > 1 else level.display_name

	for child in _dots.get_children():
		child.queue_free()
	for i in PlayerData.LEVELS.size():
		var dot := Panel.new()
		var size_px := 16.0 if i == index else 11.0
		dot.custom_minimum_size = Vector2(size_px, size_px)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.bg_color = UiKit.GOLD_TEXT if i == index else (Color(1, 1, 1, 0.8) if PlayerData.can_select(i) else Color(0.1, 0.1, 0.12, 0.8))
		dot.add_theme_stylebox_override("panel", style)
		_dots.add_child(dot)

	for child in _info.get_children():
		_info.remove_child(child)
		child.queue_free()
	# Just the rewards, as a row of pills under the card.
	var stars := PlayerData.stars_for(index)
	var first_clear := stars == 0
	var reward := UiKit.hbox(12)
	reward.alignment = BoxContainer.ALIGNMENT_CENTER
	reward.add_child(UiKit.label("THƯỞNG", 20, UiKit.GOLD_TEXT))
	reward.add_child(_reward_pill(UiKit.price("gold", roundi(Economy.win_gold(index, 3) * (Economy.FIRST_CLEAR_GOLD_MULT if first_clear else 1.0)), 22)))
	if stars < 3:
		reward.add_child(_reward_pill(UiKit.price("gems", Economy.FIRST_THREE_STAR_GEMS, 22)))
	var chest := UiKit.hbox(4)
	chest.add_child(UiKit.drawn(UiKit.DrawnIcon.Kind.CHEST, 38))
	chest.add_child(UiKit.label("Rương", 20))
	reward.add_child(_reward_pill(chest))
	_info.add_child(reward)

	_play.disabled = locked
	_play.text = "CHƠI" if not locked else "CHƯA MỞ"


func _enemy_ids(level: Resource) -> Array:
	var ids := []
	for wave in level.waves:
		for group in wave["groups"]:
			if not ids.has(group["troop"]):
				ids.append(group["troop"])
	return ids


# --- Reward pills ----------------------------------------------------------------------

func _reward_pill(content: Control) -> Control:
	var pill := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.06, 0.75)
	style.set_corner_radius_all(18)
	style.content_margin_left = 10
	style.content_margin_right = 12
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", style)
	pill.add_child(content)
	return pill


# --- Page background ------------------------------------------------------------------------

## The level's scene, scaled to cover the page, cross-faded in over the previous one.
func _show_backdrop(index: int, locked: bool) -> void:
	if index == _backdrop_level and _backdrop_art != null:
		return
	_backdrop_level = index
	var art = LevelArt.new()
	art.level_index = index
	art.locked = locked
	art.size = CARD_SIZE
	var page_size: Vector2 = size if size.x > 0.0 else Vector2(720, 1020)
	var cover := maxf(page_size.x / CARD_SIZE.x, page_size.y / CARD_SIZE.y) * 1.05
	art.scale = Vector2(cover, cover)
	art.position = (page_size - CARD_SIZE * cover) / 2.0
	# LevelArt sets its own modulate (tint), so the fade goes on a holder.
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.modulate.a = 0.0
	holder.add_child(art)
	_backdrop.add_child(holder)
	_backdrop.move_child(holder, _backdrop.get_child_count() - 2)
	var old := _backdrop_art
	_backdrop_art = holder
	var tween := holder.create_tween()
	tween.tween_property(holder, "modulate:a", 1.0, 0.3)
	if old != null:
		tween.tween_callback(old.queue_free)
