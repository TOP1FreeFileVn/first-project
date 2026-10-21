extends "res://game/menu/pages/MenuPage.gd"

# Stage selection is UI over the persistent cardboard courtyard owned by Home.
# Changing a selected stage never rebuilds the backdrop or restarts its cats.
const Ui = preload("res://game/ui/Ui.gd")
const SWIPE_DISTANCE := 70.0

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
		remove_child(_column)
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

	var top_gap := Control.new()
	top_gap.custom_minimum_size.y = 32
	_column.add_child(top_gap)
	var header_margin := Ui.margin(40, 0, 40, 0)
	var pager := Ui.hbox(12)
	pager.name = "LobbyPager"
	header_margin.add_child(pager)
	var prev := _page_arrow(false)
	prev.name = "LobbyPrev"
	prev.pressed.connect(func(): _go(-1))
	prev.disabled = index == 0
	pager.add_child(prev)
	var title := Ui.label("Màn %d · %s" % [index + 1, level_name], "", 28)
	title.name = "LobbyTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color("583f21"))
	title.add_theme_constant_override("outline_size", 3)
	pager.add_child(title)
	var next := _page_arrow(true)
	next.name = "LobbyNext"
	next.pressed.connect(func(): _go(1))
	next.disabled = index == PlayerData.LEVELS.size() - 1
	pager.add_child(next)
	_column.add_child(header_margin)
	var star_row := Ui.hbox(2)
	star_row.custom_minimum_size.y = 30
	for i in stars:
		star_row.add_child(Ui.icon("star", 28))
	_column.add_child(star_row)

	# This transparent region keeps swipe navigation over the courtyard.
	# The world itself lives outside this page's rebuildable UI column.
	_stage = Control.new()
	_stage.name = "LobbyStage"
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_on_stage_input)
	_column.add_child(_stage)

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
		# Keep the gesture local to this transparent region; courtyard actors stay in place.
		var moved: float = event.position.x - _drag_from
		var at_end := (moved > 0.0 and _selected == 0) or (moved < 0.0 and _selected == PlayerData.LEVELS.size() - 1)
		_stage.position.x = moved * (0.3 if at_end else 1.0)


func _snap_back() -> void:
	if _stage != null:
		create_tween().tween_property(_stage, "position:x", 0.0, 0.15)
