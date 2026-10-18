extends "res://game/menu/pages/MenuPage.gd"

# Troop roster: the battle team pinned on top (slots grow with the castle), then the
# collection with a rarity filter, which scrolls on its own. Tapping a card opens the
# detail popup with stats, the ability, level-up / star-up and join / leave team. Joining
# a full team enters "swap" mode: the team slots blink and the next slot tapped takes the
# new troop. Troops can also be dragged: drag a card and drop it on a slot, drag a slot
# onto another to swap them, or drag one out of the team panel to bench it.

const Ui = preload("res://game/ui/Ui.gd")
const CARD_SIZE := Vector2(326, 216)
const SLOT_HEIGHT := 184.0
const MAX_SLOTS := 5
## With a mouse a card picks up as soon as it moves. On a touch screen a vertical swipe
## scrolls the list, so a card picks up after being held this long, or when the finger
## moves sideways first. Team slots always pick up as soon as they move.
const HOLD_TIME := 0.25
const HOLD_SLOP := 14.0

var _detail_box: VBoxContainer
var _detail_id := ""
## Troop waiting for a team slot (swap mode), or "".
var _swap_id := ""
## -1 = all rarities.
var _filter := -1
var _slots: Array = []
var _blink := 0.0
var _top: VBoxContainer
var _team_panel: Control
var _scroll: ScrollContainer
# Drag and drop: the troop under the finger, the slot it came from (-1 = collection).
var _press_id := ""
var _press_slot := -1
var _press_at := Vector2.ZERO
var _press_time := 0.0
# Pointer position (page coordinates) and button state, tracked from input events so the
# drag never depends on the OS cursor.
var _pointer := Vector2.ZERO
var _pointer_down := false
var _ghost: Control
var _scroll_lock := 0
var _eat_press := false


func _init() -> void:
	super()
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# The team (and the filter) stay put; only the collection below scrolls.
	_scroll = get_child(0)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)
	_top = Ui.vbox(10)
	margin.add_child(_top)
	margin.resized.connect(func(): _scroll.offset_top = margin.size.y)


func build() -> void:
	for child in _top.get_children():
		_top.remove_child(child)
		child.queue_free()
	_top.add_child(Ui.center(Ui.title_plaque("Lính", "", 26)))
	_build_team()
	_build_filter()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 22)
	for id in PlayerData.TROOP_ORDER:
		if _filter < 0 or PlayerData.rarity_of(id) == _filter:
			grid.add_child(_card(id))
	body.add_child(grid)
	var hint := Ui.label("Cấp tăng chỉ số bằng vàng · Sao nâng trần cấp bằng thẻ lính", "LabelSmall", 18)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(hint)
	if _detail_box != null and is_instance_valid(_detail_box):
		_fill_detail()


func has_alert() -> bool:
	return PlayerData.any_troop_improvable()


func _process(delta: float) -> void:
	if not visible:
		_cancel_drag()
		return
	_watch_press(delta)
	if _ghost != null:
		# The list must not scroll under a dragged troop.
		_scroll.scroll_vertical = _scroll_lock
	if _swap_id == "" and _ghost == null:
		return
	_blink += delta
	var glow := 1.0 + 0.35 * (0.5 + 0.5 * sin(_blink * 8.0))
	var hovered := _slot_at(_pointer) if _ghost != null else -1
	for i in _slots.size():
		if is_instance_valid(_slots[i]):
			_slots[i].modulate = Color(1.5, 1.5, 1.1) if i == hovered else Color(glow, glow, glow * 0.8)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_pointer = event.position
		if _ghost != null:
			_move_ghost(_pointer)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer = event.position
		_pointer_down = event.pressed
		if not event.pressed and _ghost != null:
			_drop(_pointer)


# --- Drag and drop ----------------------------------------------------------------------

func _on_press(id: String, from_slot: int) -> void:
	_press_id = id
	_press_slot = from_slot
	_press_at = _pointer
	_press_time = 0.0


# Turns a press into a drag (see HOLD_TIME). A vertical swipe on a touch screen is left to
# the list's scrolling.
func _watch_press(delta: float) -> void:
	if _press_id == "" or _ghost != null:
		return
	if not _pointer_down:
		_press_id = ""
		return
	var move := _pointer - _press_at
	if move.length() > HOLD_SLOP:
		var sideways := absf(move.x) > absf(move.y)
		if _press_slot >= 0 or sideways or not DisplayServer.is_touchscreen_available():
			_start_drag()
		else:
			_press_id = ""
	else:
		_press_time += delta
		if _press_time >= HOLD_TIME:
			_start_drag()


func _start_drag() -> void:
	var t: Dictionary = PlayerData.troop(_press_id)
	_ghost = UiKit.troop_portrait(PlayerData.TROOPS[_press_id], 120, SpriteLib.player_color(1 + 2 * (t["stars"] - 1)))
	_ghost.top_level = true
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.size = Vector2(120, 120)
	_ghost.pivot_offset = Vector2(60, 60)
	_ghost.z_index = 10
	add_child(_ghost)
	_move_ghost(_pointer)
	_ghost.scale = Vector2(0.7, 0.7)
	_ghost.create_tween().tween_property(_ghost, "scale", Vector2(1.1, 1.1), 0.12)
	_scroll_lock = _scroll.scroll_vertical
	_blink = 0.0


func _move_ghost(at: Vector2) -> void:
	if _ghost != null:
		_ghost.global_position = at - Vector2(60, 70)


## Drops the dragged troop: on a slot it takes that slot (swapping if it was already in
## the team); a team troop dropped outside the team panel leaves the team.
func _drop(at: Vector2) -> void:
	var id := _press_id
	var from_slot := _press_slot
	_cancel_drag()
	# The button under the finger still sees this release as a tap; ignore it.
	_eat_press = true
	set_deferred("_eat_press", false)
	var target := _slot_at(at)
	if target >= 0:
		if target != from_slot:
			PlayerData.set_team_slot(target, id)
	elif from_slot >= 0 and not _team_panel.get_global_rect().has_point(at):
		if not PlayerData.remove_from_team(id):
			_toast("Đội phải còn ít nhất 1 lính.")
	refresh()


func _cancel_drag() -> void:
	_press_id = ""
	_press_slot = -1
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
		for slot in _slots:
			if is_instance_valid(slot):
				slot.modulate = Color.WHITE


func _slot_at(at: Vector2) -> int:
	for i in _slots.size():
		if is_instance_valid(_slots[i]) and _slots[i].get_global_rect().grow(8).has_point(at):
			return i
	return -1


# --- Team -------------------------------------------------------------------------------

## Card tone per rarity, the same as the battle shop: Thường green, Hiếm blue, Sử thi
## purple, Huyền thoại orange.
static func tone(rarity: int) -> String:
	return ["Green", "Blue", "Purple", "Orange"][clampi(rarity, 0, 3)]


## A button drawn as a rarity card (CardUnit<tone>) in every state.
static func card_button(rarity: int, min_size: Vector2) -> Button:
	var b := Button.new()
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	var face := Ui.THEME.get_stylebox("panel", "CardUnit" + tone(rarity))
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, face)
	return b


## Solid green "Trong đội" pill, as on the battle shop's "Ghép được".
static func pill(text: String, color := Color("5fd03e")) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("583f21")
	style.set_border_width_all(3)
	style.set_corner_radius_all(13)
	style.content_margin_left = 9
	style.content_margin_right = 9
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style)
	var label := Ui.label(text, "LabelSmall", 18)
	label.add_theme_constant_override("outline_size", 3)
	p.add_child(label)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _build_team() -> void:
	_team_panel = Ui.panel("Board")
	_top.add_child(_team_panel)
	var box := Ui.vbox(8)
	_team_panel.add_child(box)
	var head := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	head.add_child(Ui.label("Đội hình", "", 24))
	head.add_child(Ui.label("%d/%d" % [PlayerData.battle_team().size(), PlayerData.team_slots()], "LabelAccent", 22))
	head.add_child(Ui.spacer())
	head.add_child(Ui.icon("star", 30))
	head.add_child(Ui.label(UiKit.format_number(PlayerData.team_power()), "", 22))
	box.add_child(head)
	if _swap_id != "":
		var swap := Ui.hbox(8)
		var text := Ui.label("Chạm một ô để đưa %s vào đội" % PlayerData.TROOPS[_swap_id].display_name, "LabelDark", 18)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		swap.add_child(text)
		var cancel := Ui.button("Huỷ", "Red", Vector2(110, 56), 18)
		cancel.pressed.connect(func():
			_swap_id = ""
			refresh())
		swap.add_child(cancel)
		box.add_child(swap)
	else:
		var hint := Ui.label("Giữ lính rồi kéo vào ô để thay · kéo ra ngoài để bỏ khỏi đội", "LabelDark", 18)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(hint)

	var row := Ui.hbox(8)
	var team := PlayerData.battle_team()
	_slots.clear()
	for i in MAX_SLOTS:
		if i < PlayerData.team_slots():
			var slot := _team_slot(i, team[i] if i < team.size() else "")
			_slots.append(slot)
			row.add_child(slot)
		else:
			row.add_child(_locked_slot(i))
	# Divide the width left by the Board's real padding. Fixed 122px slots made the
	# whole header 746px wide, moving the title and clipping the Board's right edge.
	row.resized.connect(_fit_team_slots.bind(row))
	box.add_child(row)


func _fit_team_slots(row: HBoxContainer) -> void:
	var gaps := row.get_theme_constant("separation") * (MAX_SLOTS - 1)
	var width := floorf((row.size.x - gaps) / float(MAX_SLOTS))
	if width <= 0.0:
		return
	for child in row.get_children():
		var slot := child as Control
		slot.custom_minimum_size = Vector2(width, SLOT_HEIGHT)


func _team_slot(index: int, id: String) -> Button:
	var slot: Button
	if id == "":
		slot = Button.new()
		slot.custom_minimum_size = Vector2(0, SLOT_HEIGHT)
		slot.focus_mode = Control.FOCUS_NONE
		var face := Ui.THEME.get_stylebox("panel", "Well")
		for state in ["normal", "hover", "pressed"]:
			slot.add_theme_stylebox_override(state, face)
	else:
		slot = card_button(PlayerData.rarity_of(id), Vector2(0, SLOT_HEIGHT))
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.pressed.connect(_on_slot_pressed.bind(index, id))
	if id != "":
		slot.button_down.connect(_on_press.bind(id, index))
	var column := Ui.vbox(4, BoxContainer.ALIGNMENT_CENTER)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 6
	column.offset_right = -6
	column.offset_top = 6
	column.offset_bottom = -10
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(column)
	if id == "":
		column.add_child(Ui.center(Ui.icon("plus", 44)))
		column.add_child(Ui.label("Trống", "LabelDark", 18))
		return slot
	var t: Dictionary = PlayerData.troop(id)
	var portrait := UiKit.troop_portrait(PlayerData.TROOPS[id], 72, SpriteLib.player_color(1 + 2 * (t["stars"] - 1)))
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(portrait)
	var name_label := Ui.label(PlayerData.TROOPS[id].display_name, "LabelSmall", 18)
	# Paytone needs 58px for two 18px lines at this slot width.
	name_label.custom_minimum_size.y = 58
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_constant_override("outline_size", 3)
	column.add_child(name_label)
	# White (outlined): the accent green vanished on green and orange cards (1.25:1).
	var level := Ui.label("Cấp %d" % t["level"], "LabelSmall", 18)
	level.add_theme_constant_override("outline_size", 3)
	column.add_child(level)
	return slot


func _locked_slot(index: int) -> Control:
	var slot := Ui.panel("Well")
	slot.custom_minimum_size = Vector2(0, SLOT_HEIGHT)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.modulate = Color(0.85, 0.85, 0.85)
	var column := Ui.vbox(2, BoxContainer.ALIGNMENT_CENTER)
	slot.add_child(column)
	column.add_child(Ui.center(Ui.icon("lock", 44)))
	var need := _castle_for_slot(index)
	column.add_child(Ui.label("Thành %d" % need if need > 0 else "—", "LabelDark", 18))
	return slot


## Castle level that opens slot `index` (0-based), or -1 if no level does.
func _castle_for_slot(index: int) -> int:
	for level in range(1, PlayerData.castle_max_level() + 1):
		if Economy.team_slots(level) > index:
			return level
	return -1


func _on_slot_pressed(index: int, id: String) -> void:
	if _eat_press:
		return
	if _swap_id != "":
		PlayerData.set_team_slot(index, _swap_id)
		_swap_id = ""
		refresh()
	elif id != "":
		_open_detail(id)
	else:
		_toast("Chọn một lính bên dưới rồi bấm VÀO ĐỘI.")


func _toast(text: String) -> void:
	var note := Ui.panel("InfoStrip", Ui.label(text, "LabelSmall", 18))
	note.position = Vector2(60, 860)
	note.size = Vector2(600, 56)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(note)
	var tween := note.create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(note, "modulate:a", 0.0, 0.3)
	tween.tween_callback(note.queue_free)


func _build_filter() -> void:
	var row := Ui.hbox(6)
	var names := ["Tất cả"] + Array(Economy.RARITY_NAMES)
	for i in names.size():
		var rarity := i - 1
		var b := Ui.button(names[i], "Yellow" if rarity == _filter else "Tab", Vector2(150 if i == 4 else 124, 58), 18)
		b.pressed.connect(func():
			_filter = rarity
			refresh())
		row.add_child(b)
	_top.add_child(row)


# --- Collection -------------------------------------------------------------------------

func _card(id: String) -> Button:
	var troop: Resource = PlayerData.TROOPS[id]
	var t: Dictionary = PlayerData.troop(id)
	var unlocked: bool = t["unlocked"]
	var rarity: int = troop.rarity
	var card := card_button(rarity, CARD_SIZE)
	card.pressed.connect(_on_card_pressed.bind(id))
	if unlocked:
		card.button_down.connect(_on_press.bind(id, -1))
	else:
		card.self_modulate = Color(0.62, 0.62, 0.66)

	var row := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.offset_bottom = -6
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var portrait := UiKit.troop_portrait(troop, 104, SpriteLib.player_color(1 + 2 * (t["stars"] - 1)))
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not unlocked:
		portrait.modulate = Color(0.15, 0.15, 0.2, 0.85)
	row.add_child(portrait)

	var info := Ui.vbox(3, BoxContainer.ALIGNMENT_CENTER)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	var name_label := Ui.label(troop.display_name, "", 22)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.custom_minimum_size.y = 32
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(name_label)
	var kind_text := ("%s\n%s" if rarity == 3 else "%s · %s") % [Economy.RARITY_NAMES[rarity], troop.KLASS_NAMES[troop.klass]]
	var kind := Ui.label(kind_text, "LabelSmall", 18)
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	kind.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kind.add_theme_constant_override("outline_size", 3)
	info.add_child(kind)
	if not unlocked:
		var locked := Ui.label("Chưa mở khoá", "LabelSmall", 18)
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		locked.add_theme_color_override("font_color", Color("ffb0a0"))
		info.add_child(locked)
		var need_card := Ui.label("Cần 1 thẻ (rương)", "LabelSmall", 18)
		need_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		need_card.add_theme_constant_override("outline_size", 3)
		info.add_child(need_card)
		Ui.pin(card, Ui.icon("lock", 40), Vector2(-46, 8), Control.PRESET_TOP_RIGHT)
	else:
		var stars := Ui.hbox(1, BoxContainer.ALIGNMENT_BEGIN)
		for i in Economy.MAX_STARS:
			stars.add_child(Ui.icon("star" if i < t["stars"] else "star_off", 24))
		info.add_child(stars)
		var level := Ui.label("Cấp %d/%d" % [t["level"], PlayerData.level_cap(id)], "LabelSmall", 20)
		level.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(level)
		var need := PlayerData.star_up_cost(id)
		var bar := ProgressBar.new()
		bar.theme_type_variation = "BarItem"
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(150, 28)
		bar.max_value = maxi(need, 1)
		bar.value = t["cards"] if need > 0 else bar.max_value
		var count := Ui.label("%d/%s" % [t["cards"], str(need) if need > 0 else "—"], "LabelSmall", 18)
		count.add_theme_constant_override("outline_size", 3)
		bar.add_child(count)
		count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		info.add_child(bar)

	if unlocked and PlayerData.in_team(id):
		var badge := pill("Trong đội")
		card.add_child(badge)
		badge.position = Vector2(10, -12)
	if PlayerData.can_improve(id):
		Ui.dot(card, Vector2(-26, -8))
	return card


func _on_card_pressed(id: String) -> void:
	if _eat_press:
		return
	# In swap mode a tap on another unlocked card picks that troop instead.
	if _swap_id != "" and PlayerData.is_unlocked(id) and not PlayerData.in_team(id):
		_swap_id = id
		refresh()
		return
	_open_detail(id)


func _open_detail(id: String) -> void:
	_detail_id = id
	_detail_box = UiKit.popup(home, 600, PlayerData.TROOPS[id].display_name)
	_fill_detail()


# Everything under the popup header is rebuilt after each upgrade.
func _fill_detail() -> void:
	var box := _detail_box
	while box.get_child_count() > 1:
		var child := box.get_child(1)
		box.remove_child(child)
		child.queue_free()
	var id := _detail_id
	var troop: Resource = PlayerData.TROOPS[id]
	var t: Dictionary = PlayerData.troop(id)

	var top := UiKit.hbox(16)
	top.add_child(UiKit.troop_portrait(troop, 150, SpriteLib.player_color(1 + 2 * (t["stars"] - 1))))
	var info := UiKit.vbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rarity_label := UiKit.label(Economy.RARITY_NAMES[troop.rarity], 18, Economy.RARITY_COLORS[troop.rarity])
	rarity_label.add_theme_color_override("font_outline_color", UiKit.INK)
	info.add_child(rarity_label)
	info.add_child(UiKit.ink("Sao: " + "★".repeat(t["stars"]) + "☆".repeat(Economy.MAX_STARS - t["stars"]), 20))
	info.add_child(UiKit.ink("Cấp %d / %d" % [t["level"], PlayerData.level_cap(id)], 20))
	info.add_child(UiKit.ink("Thẻ: %d" % t["cards"], 18))
	var desc := UiKit.ink(troop.description, 16)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 340
	info.add_child(desc)
	top.add_child(info)
	box.add_child(top)
	if troop.ability_text != "":
		var ability := UiKit.ink("✦ " + troop.ability_text, 16)
		ability.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ability.add_theme_color_override("font_color", Color("6b3fa0") if troop.rarity < 3 else Color("9a5a00"))
		box.add_child(ability)

	if not t["unlocked"]:
		box.add_child(UiKit.ink("Chưa mở khoá. Mở rương ở Cửa hàng để nhận thẻ %s." % troop.display_name, 18))
		return

	# Stats now and after the next level.
	var mult: float = PlayerData.troop_multiplier(id)
	var next_mult: float = Economy.troop_multiplier(t["level"] + 1, t["stars"])
	var can_level := PlayerData.level_up_cost(id) >= 0
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 24)
	var entries := [["Máu", troop.max_hp]]
	if troop.role != 3:
		entries.append(["Hồi máu" if troop.role == 2 else "Sát thương", troop.damage])
	for entry in entries:
		stats.add_child(UiKit.ink(entry[0], 18))
		var text := "%.1f" % (entry[1] * mult)
		if can_level:
			text += "  →  %.1f" % (entry[1] * next_mult)
		stats.add_child(UiKit.ink(text, 18))
	if troop.role != 3:
		stats.add_child(UiKit.ink("Tầm đánh", 18))
		stats.add_child(UiKit.ink("%d" % troop.attack_range, 18))
		stats.add_child(UiKit.ink("Hồi chiêu", 18))
		stats.add_child(UiKit.ink("%.1f giây" % troop.attack_cooldown, 18))
	stats.add_child(UiKit.ink("Tốc chạy", 18))
	stats.add_child(UiKit.ink("%d (%s)" % [troop.move_speed, speed_word(troop.move_speed)], 18))
	if troop.crit_factor() > 1.0:
		stats.add_child(UiKit.ink("Chí mạng", 18))
		stats.add_child(UiKit.ink("%d%% · x%s sát thương" % [roundi(troop.crit_chance * 100.0), String.num(troop.crit_mult, 2)], 18))
	stats.add_child(UiKit.ink("Sinh lính", 18))
	stats.add_child(UiKit.ink("mỗi %.1f giây (tối đa %d)" % [troop.spawn_interval, troop.max_alive], 18))
	box.add_child(stats)

	var actions := UiKit.hbox(14)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	var level_cost := PlayerData.level_up_cost(id)
	var level_button := UiKit.button("", Vector2(250, 76), func(): PlayerData.level_up(id))
	if level_cost < 0:
		level_button.text = "Cần lên sao" if t["stars"] < Economy.MAX_STARS else "Cấp tối đa"
		level_button.disabled = true
	else:
		level_button.text = "NÂNG CẤP  %s" % UiKit.format_number(level_cost)
		level_button.icon = UiKit.coin_texture()
		level_button.add_theme_constant_override("icon_max_width", 30)
		level_button.disabled = PlayerData.gold < level_cost
	actions.add_child(level_button)
	var star_cost := PlayerData.star_up_cost(id)
	var star_button := UiKit.button("", Vector2(250, 76), func(): PlayerData.star_up(id), true)
	if star_cost < 0:
		star_button.text = "Sao tối đa"
		star_button.disabled = true
	else:
		star_button.text = "LÊN SAO  %d/%d thẻ" % [t["cards"], star_cost]
		star_button.disabled = t["cards"] < star_cost
	actions.add_child(star_button)
	box.add_child(actions)

	var team_button: Button
	if PlayerData.in_team(id):
		team_button = UiKit.button("RA KHỎI ĐỘI", Vector2(300, 66), func():
			if not PlayerData.remove_from_team(id):
				_toast("Đội phải còn ít nhất 1 lính."), true)
		team_button.disabled = PlayerData.battle_team().size() <= 1
	else:
		team_button = UiKit.button("VÀO ĐỘI", Vector2(300, 66), func(): _join_team(id))
	team_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(team_button)


func _join_team(id: String) -> void:
	if PlayerData.add_to_team(id):
		UiKit.close_popup(_detail_box)
		return
	# Team full: pick the slot to replace.
	_swap_id = id
	_blink = 0.0
	UiKit.close_popup(_detail_box)
	refresh()


## How fast a troop runs, in words: slow, normal, fast, very fast.
static func speed_word(speed: float) -> String:
	if speed < 52.0:
		return "chậm"
	if speed < 70.0:
		return "vừa"
	if speed < 100.0:
		return "nhanh"
	return "rất nhanh"
