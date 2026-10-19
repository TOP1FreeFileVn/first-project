extends "res://game/menu/pages/MenuPage.gd"

# Level select in the game skin, on the approved lobby layout (tests/ui/HomePreview):
# [flex] level plaque + stars → stage island with the hero cat and the level's enemies →
# ◀ page dots ▶ → rewards → [flex] one big "Trận chiến" button. Swipe the island (or tap the
# arrows) to look at other levels; locked ones can be looked at but not played.

const Ui = preload("res://game/ui/Ui.gd")
const SWIPE_DISTANCE := 70.0
## Where the level's enemies stand on the island, as fractions of it.
const ENEMY_SPOTS := [Vector2(0.76, 0.40), Vector2(0.86, 0.53), Vector2(0.68, 0.58)]

var _selected := -1
var _column: VBoxContainer
var _stage: Control
var _drag_from := -1.0
var _sliding := false


func _init() -> void:
	super()
	# This page lays itself out to fill the screen instead of scrolling `body`.
	body.get_parent().get_parent().visible = false
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func refresh() -> void:
	build()


func build() -> void:
	if _selected < 0:
		_selected = PlayerData.unlocked_levels - 1
	if _column != null:
		_column.queue_free()
	_column = Ui.vbox(6)
	add_child(_column)
	_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_column.offset_bottom = -20
	_fill()


func has_alert() -> bool:
	# A level unlocked but never cleared.
	return PlayerData.stars_for(PlayerData.unlocked_levels - 1) == 0


func _fill() -> void:
	var index := _selected
	var level: Resource = PlayerData.level_data(index)
	var locked := not PlayerData.can_select(index)
	var stars := PlayerData.stars_for(index)
	var parts: PackedStringArray = level.display_name.split(" · ")
	var level_name: String = parts[parts.size() - 1] if parts.size() > 1 else level.display_name

	_column.add_child(_flex(0.15))
	# Plaque + stars on top of the stage.
	var title := Ui.center(Ui.title_plaque("Màn %d · %s" % [index + 1, level_name], "", 26))
	title.name = "LobbyTitle"
	_column.add_child(title)
	var star_row := Ui.hbox(4)
	for i in 3:
		star_row.add_child(Ui.icon("star" if i < stars else "star_off", 40 if i == 1 else 34))
	_column.add_child(star_row)

	# Stage: island at its aspect ratio between the side rails; hero cat in the middle,
	# the level's enemies on the far side.
	var side := Ui.margin(96, 0, 96, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var fit := AspectRatioContainer.new()
	fit.ratio = 560.0 / 400.0
	side.add_child(fit)
	_stage = Control.new()
	_stage.name = "LobbyStage"
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_on_stage_input)
	fit.add_child(_stage)
	var island := Ui.image("menu_castle_island", Vector2.ZERO)
	island.name = "LobbyIsland"
	_stage.add_child(island)
	island.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cat := Ui.image("cat_hero", Vector2.ZERO)
	_stage.add_child(cat)
	_place(cat, Vector2(0.12, 0.14), Vector2(0.40, 0.59))
	var ids := _enemy_ids(level)
	for i in mini(ids.size(), ENEMY_SPOTS.size()):
		var foe := UiKit.troop_portrait(PlayerData.TROOPS[ids[i]], 64, "Red")
		foe.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		foe.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foe.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		foe.flip_h = true
		foe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stage.add_child(foe)
		var spot: Vector2 = ENEMY_SPOTS[i]
		_place(foe, spot - Vector2(0.08, 0.16), spot + Vector2(0.08, 0.0))
	if locked:
		_stage.modulate = Color(0.45, 0.48, 0.58)
		var padlock := Ui.icon("lock", 110)
		_stage.add_child(padlock)
		_place(padlock, Vector2(0.38, 0.2), Vector2(0.62, 0.55))
	elif stars == 0:
		# First-clear bonus as a callout over the island.
		var note := "Lần đầu: x2 vàng"
		var gift: String = Economy.FIRST_CLEAR_GIFT.get(index, "")
		if gift != "":
			note += " + " + PlayerData.TROOPS[gift].display_name
		var tip := Ui.callout(note)
		tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stage.add_child(tip)
		tip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		tip.grow_horizontal = Control.GROW_DIRECTION_BOTH
		tip.offset_top = -10
		Ui.bob(tip, 5.0, 1.2)
	_column.add_child(side)

	# ◀ page dots ▶
	var pager := Ui.hbox(14)
	pager.name = "LobbyPager"
	var prev := _page_arrow(false)
	prev.name = "LobbyPrev"
	prev.pressed.connect(func(): _go(-1))
	prev.disabled = index == 0
	pager.add_child(prev)
	var dots := Ui.hbox(8)
	for i in PlayerData.LEVELS.size():
		var dot := Panel.new()
		var size_px := 18.0 if i == index else 12.0
		dot.custom_minimum_size = Vector2(size_px, size_px)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(9)
		style.border_color = Color("583f21")
		style.set_border_width_all(2)
		style.bg_color = Color("ffd23f") if i == index else (Color.WHITE if PlayerData.can_select(i) else Color("3d5a8a"))
		dot.add_theme_stylebox_override("panel", style)
		dots.add_child(dot)
	pager.add_child(dots)
	var next := _page_arrow(true)
	next.name = "LobbyNext"
	next.pressed.connect(func(): _go(1))
	next.disabled = index == PlayerData.LEVELS.size() - 1
	pager.add_child(next)
	_column.add_child(pager)

	# Keep the selected stage's reward and its action together, as one compact group.
	var action_block := Ui.vbox(16)
	action_block.name = "BattleActionBlock"
	_column.add_child(action_block)
	# Rewards for this level, or how to unlock it.
	if locked:
		var why := Ui.label("Qua màn %d để mở khoá" % index, "LabelSmall", 22)
		why.add_theme_color_override("font_color", UiKit.WARN)
		var reason := Ui.center(Ui.panel("InfoStrip", why))
		reason.name = "LobbyRewards"
		action_block.add_child(reason)
	else:
		var first_clear := stars == 0
		var reward := Ui.hbox(14)
		reward.name = "LobbyRewards"
		reward.add_child(Ui.label("Thưởng", "LabelSmall", 20))
		var gold := roundi(Economy.win_gold(index, 3) * (Economy.FIRST_CLEAR_GOLD_MULT if first_clear else 1.0))
		reward.add_child(Ui.counter("coin", UiKit.format_number(gold)))
		if stars < 3:
			reward.add_child(Ui.counter("gem", str(Economy.FIRST_THREE_STAR_GEMS)))
		reward.add_child(Ui.counter("chest", "Rương"))
		action_block.add_child(reward)

	var play := Ui.button("", "Yellow", Vector2(360, 104))
	play.name = "LobbyBattleButton"
	# A centred, content-sized row avoids the native button's far-left icon gap.
	var content := Ui.center(Ui.hbox(12))
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Centre the row on the raised face, above the button's lower lip.
	content.offset_top = -6
	content.offset_bottom = -16
	var row: HBoxContainer = content.get_child(0)
	row.name = "LobbyBattleContent"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(Ui.icon("lock" if locked else "tab_battle", 46))
	row.add_child(Ui.label("Chưa mở" if locked else "Trận chiến", "", 36))
	play.button_down.connect(func(): content.offset_top = 0; content.offset_bottom = -10)
	play.button_up.connect(func(): content.offset_top = -6; content.offset_bottom = -16)
	play.disabled = locked
	play.pressed.connect(func(): home.start_battle(_selected))
	action_block.add_child(Ui.center(play))
	var bottom_gap := Control.new()
	bottom_gap.custom_minimum_size.y = 16
	_column.add_child(bottom_gap)
	if not locked:
		play.ready.connect(func(): Ui.pulse(play, 0.04, 1.4))


## Both directions use the same fixed icon and face-centred layout.
func _page_arrow(flip: bool) -> Button:
	var button := Ui.button("", "Blue", Vector2(70, 62))
	var arrow := Ui.icon("back", 34)
	arrow.name = "LobbyPageArrow"
	arrow.flip_h = flip
	var content := Ui.center(arrow)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_bottom = -8
	return button


## Anchors a child of the stage to a box given in fractions of the island.
func _place(child: Control, top_left: Vector2, bottom_right: Vector2) -> void:
	child.anchor_left = top_left.x
	child.anchor_top = top_left.y
	child.anchor_right = bottom_right.x
	child.anchor_bottom = bottom_right.y
	child.offset_left = 0
	child.offset_top = 0
	child.offset_right = 0
	child.offset_bottom = 0


func _flex(ratio: float) -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.size_flags_stretch_ratio = ratio
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


# --- Switching levels ---------------------------------------------------------------------

func _go(step: int) -> void:
	var target := _selected + step
	if _sliding or target < 0 or target >= PlayerData.LEVELS.size():
		_snap_back()
		return
	_sliding = true
	_selected = target
	build()
	# The new level slides in from the side it came from.
	_column.position.x = 80.0 * step
	_column.modulate.a = 0.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_column, "position:x", 0.0, 0.2)
	tween.tween_property(_column, "modulate:a", 1.0, 0.2)
	tween.chain().tween_callback(func(): _sliding = false)


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
		# The island follows the finger, with resistance past the first and last level.
		var moved: float = event.position.x - _drag_from
		var at_end := (moved > 0.0 and _selected == 0) or (moved < 0.0 and _selected == PlayerData.LEVELS.size() - 1)
		_stage.position.x = moved * (0.3 if at_end else 1.0)


func _snap_back() -> void:
	if _stage != null:
		create_tween().tween_property(_stage, "position:x", 0.0, 0.15)


func _enemy_ids(level: Resource) -> Array:
	var ids := []
	for wave in level.waves:
		for group in wave["groups"]:
			if not ids.has(group["troop"]):
				ids.append(group["troop"])
	return ids
