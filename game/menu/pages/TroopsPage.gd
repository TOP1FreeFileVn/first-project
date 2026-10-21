extends "res://game/menu/pages/MenuPage.gd"

# Troop roster: the battle team pinned on top (slots grow with the castle), then the
# collection with a rarity filter, which scrolls on its own. Tapping a card opens the
# dedicated training screen with stats, skills, level-up / star-up and team actions. Joining
# a full team enters "swap" mode: the team slots blink and the next slot tapped takes the
# new troop. Troops can also be dragged: drag a card and drop it on a slot, drag a slot
# onto another to swap them, or drag one out of the team panel to bench it.

const Ui = preload("res://game/ui/Ui.gd")
const UpgradeHint = preload("res://game/ui/UpgradeHint.gd")
const TroopUpgradeScreen = preload("res://game/menu/popups/TroopUpgradeScreen.gd")
const CARD_SIZE := Vector2(150, 240)
const SLOT_HEIGHT := 138.0
const MAX_SLOTS := 5
const INK := Color("583f21")
const MUTED_INK := Color("6b563b")
## With a mouse a card picks up as soon as it moves. On a touch screen a vertical swipe
## scrolls the list, so a card picks up after being held this long, or when the finger
## moves sideways first. Team slots always pick up as soon as they move.
const HOLD_TIME := 0.25
const HOLD_SLOP := 14.0

var _detail_screen: Control
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
	# Upgrade prompts rise above the top card edge, including at maximum pulse.
	(_scroll.get_child(0) as MarginContainer).add_theme_constant_override("margin_top", 28)
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
	var heading := Ui.label("Lính", "LabelDark", 32)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	heading.add_theme_color_override("font_color", INK)
	_top.add_child(heading)
	_build_team()
	_build_filter()
	var grid := GridContainer.new()
	grid.name = "TroopGrid"
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 36)
	for id in PlayerData.TROOP_ORDER:
		if _filter < 0 or PlayerData.rarity_of(id) == _filter:
			grid.add_child(_card(id))
	body.add_child(grid)
	grid.resized.connect(_fit_roster_cards.bind(grid))


func has_alert() -> bool:
	return PlayerData.any_troop_improvable()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
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
	if not is_visible_in_tree():
		return
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


## A quiet rarity frame with a separate pressed face.
static func card_button(rarity: int, min_size: Vector2) -> Button:
	var b := Button.new()
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	var face := Ui.THEME.get_stylebox("panel", "TroopCard" + tone(rarity))
	for state in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(state, face)
	b.add_theme_stylebox_override("pressed", Ui.THEME.get_stylebox("panel", "TroopCard" + tone(rarity) + "Pressed"))
	return b


static func _small_text(text: String, font_size := 22, muted := false) -> Label:
	var caption := Ui.label(text, "LabelDark", font_size)
	caption.add_theme_color_override("font_color", MUTED_INK if muted else INK)
	caption.add_theme_constant_override("outline_size", 0)
	return caption


## The portrait and caption share the same full-card rarity colour.
static func _portrait_field(portrait: Control, rarity: int, height: float, top_inset := 0.0) -> Control:
	var field := Control.new()
	field.name = "TroopRarityField"
	field.set_meta("rarity", rarity)
	field.custom_minimum_size.y = height
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := Ui.image("troop_portrait_" + tone(rarity).to_lower(), Vector2.ZERO)
	background.name = "TroopRarityBackground"
	background.stretch_mode = TextureRect.STRETCH_SCALE
	field.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := Ui.center(portrait)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = top_inset
	return field


static func _pin_state_badge(card: Control, badge: Control, at: Vector2, preset := Control.PRESET_TOP_LEFT) -> void:
	Ui.pin(card, badge, at, preset)


static func _level_badge(level: int) -> Control:
	var badge := Control.new()
	badge.name = "TroopLevelBadge"
	badge.custom_minimum_size = Vector2(80, 30)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caption := _small_text("Cấp %d" % level, 20)
	caption.name = "TroopLevel"
	badge.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return badge


## Show earned stars only; the row remains centred as its count changes.
static func _earned_stars(count: int, icon_size := 28.0) -> HBoxContainer:
	var row := Ui.hbox(0)
	row.name = "TroopStars"
	row.custom_minimum_size.y = 29
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in clampi(count, 0, Economy.MAX_STARS):
		var star := Ui.icon("troop_star", icon_size)
		star.name = "TroopStar_%d" % (i + 1)
		row.add_child(star)
	return row


## A locked troop is a true black silhouette; the question mark stays light above it.
static func _troop_art(troop: Resource, t: Dictionary, portrait_size: float) -> Control:
	var portrait := UiKit.troop_portrait(troop, portrait_size, SpriteLib.player_color(1 + 2 * (t["stars"] - 1)))
	portrait.name = "TroopPortrait"
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if t["unlocked"]:
		return portrait
	portrait.modulate = Color.BLACK
	var mystery := Control.new()
	mystery.name = "TroopLockedPortrait"
	mystery.custom_minimum_size = Vector2.ONE * portrait_size
	mystery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mystery.add_child(portrait)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var question := _small_text("?", roundi(portrait_size * 0.42))
	question.name = "TroopLockedQuestion"
	question.add_theme_color_override("font_color", Color("fff0d3"))
	mystery.add_child(question)
	question.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return mystery


func _fit_roster_cards(grid: GridContainer) -> void:
	var gaps := grid.get_theme_constant("h_separation") * (grid.columns - 1)
	var width := floorf((grid.size.x - gaps) / grid.columns)
	for child in grid.get_children():
		(child as Control).custom_minimum_size = Vector2(maxf(width, CARD_SIZE.x), CARD_SIZE.y)


func _build_team() -> void:
	var box := Ui.vbox(6)
	var head := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	head.add_child(Ui.spacer())
	head.add_child(Ui.icon("star", 30))
	head.add_child(_small_text(UiKit.format_number(PlayerData.team_power()), 24))
	box.add_child(head)
	if _swap_id != "":
		var swap := Ui.hbox(8)
		var text := _small_text("Chọn ô cho %s" % PlayerData.TROOPS[_swap_id].display_name.trim_prefix("Mèo "), 22)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		swap.add_child(text)
		var cancel := Ui.button("Huỷ", "Red", Vector2(110, 56), 18)
		cancel.pressed.connect(func():
			_swap_id = ""
			refresh())
		swap.add_child(cancel)
		box.add_child(swap)

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
	if _swap_id == "":
		box.add_child(_small_text("Chạm xem chi tiết · Giữ và kéo để đổi đội", 20))
	_team_panel = Ui.menu_section("troops", "Đội hình %d/%d" % [team.size(), PlayerData.team_slots()], box)
	_top.add_child(_team_panel)


func _fit_team_slots(row: HBoxContainer) -> void:
	var gaps := row.get_theme_constant("separation") * (MAX_SLOTS - 1)
	var width := floorf((row.size.x - gaps) / float(MAX_SLOTS))
	if width <= 0.0:
		return
	for child in row.get_children():
		var slot := child as Control
		slot.custom_minimum_size = Vector2(width, SLOT_HEIGHT)


## Fit long names such as Bình Thuốc on one line in the compact five-slot team.
static func _fit_team_name(caption: Label) -> void:
	if caption.size.x <= 0.0:
		return
	var font := caption.get_theme_font("font")
	var font_size := 20
	while font_size > 18 and font.get_string_size(caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > caption.size.x:
		font_size -= 1
	if caption.get_theme_font_size("font_size") != font_size:
		caption.add_theme_font_size_override("font_size", font_size)


func _team_slot(index: int, id: String) -> Button:
	var slot: Button
	if id == "":
		slot = Button.new()
		slot.custom_minimum_size = Vector2(0, SLOT_HEIGHT)
		slot.focus_mode = Control.FOCUS_NONE
		var face := Ui.menu_panel_style("troops", "Well")
		for state in ["normal", "hover", "pressed"]:
			slot.add_theme_stylebox_override(state, face)
	else:
		slot = card_button(PlayerData.rarity_of(id), Vector2(0, SLOT_HEIGHT))
	slot.name = "TeamSlot_%d" % index
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.pressed.connect(_on_slot_pressed.bind(index, id))
	if id != "":
		slot.button_down.connect(_on_press.bind(id, index))
	var column := Ui.vbox(0, BoxContainer.ALIGNMENT_CENTER)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 6
	column.offset_right = -6
	column.offset_top = 6
	column.offset_bottom = -10
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(column)
	if id == "":
		column.add_child(Ui.center(Ui.icon("plus", 44)))
		column.add_child(_small_text("Trống", 22))
		return slot
	var t: Dictionary = PlayerData.troop(id)
	var portrait := UiKit.troop_portrait(PlayerData.TROOPS[id], 64, SpriteLib.player_color(1 + 2 * (t["stars"] - 1)))
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_portrait_field(portrait, PlayerData.rarity_of(id), 64))
	var name_label := _small_text(PlayerData.TROOPS[id].display_name.trim_prefix("Mèo "), 20)
	name_label.name = "TeamTroopName"
	name_label.custom_minimum_size.y = 28
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.resized.connect(_fit_team_name.bind(name_label))
	column.add_child(name_label)
	var level := _small_text("Cấp %d" % t["level"], 20)
	column.add_child(level)
	return slot


func _locked_slot(index: int) -> Control:
	var slot := Ui.panel("TroopCardLocked")
	slot.name = "TeamSlot_%d" % index
	slot.custom_minimum_size = Vector2(0, SLOT_HEIGHT)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := Ui.vbox(2, BoxContainer.ALIGNMENT_CENTER)
	slot.add_child(column)
	column.add_child(Ui.center(Ui.icon("lock", 44)))
	var need := _castle_for_slot(index)
	column.add_child(_small_text("Thành %d" % need if need > 0 else "—", 20, true))
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
		var b := Button.new()
		b.name = "TroopFilter_%d" % rarity
		b.text = names[i]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 76)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_constant_override("outline_size", 0)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(state, INK)
		var tone_name := "btn_yellow" if rarity == _filter else "btn_tab"
		var face := Ui.THEME.get_stylebox("normal", "BtnYellow" if rarity == _filter else "BtnTab").duplicate() as StyleBoxTexture
		face.content_margin_left = 8
		face.content_margin_right = 8
		face.content_margin_top = 4
		face.content_margin_bottom = 8
		b.add_theme_stylebox_override("normal", face)
		b.add_theme_stylebox_override("hover", face)
		var pressed := face.duplicate() as StyleBoxTexture
		pressed.texture = Ui.tex(tone_name + "_pressed")
		b.add_theme_stylebox_override("pressed", pressed)
		b.pressed.connect(func(): SoundLib.play("click"))
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
	var star_ready := false
	var level_ready := false
	if unlocked:
		var star_cost := PlayerData.star_up_cost(id)
		var level_cost := PlayerData.level_up_cost(id)
		star_ready = star_cost >= 0 and t["cards"] >= star_cost
		level_ready = level_cost >= 0 and PlayerData.gold >= level_cost
	var has_upgrade := star_ready or level_ready
	var card := card_button(rarity, CARD_SIZE)
	card.name = "TroopCard_" + id
	card.set_meta("troop_id", id)
	card.pressed.connect(_on_card_pressed.bind(id))
	if unlocked:
		card.button_down.connect(_on_press.bind(id, -1))
	var column := Ui.vbox(4)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 8
	column.offset_right = -8
	column.offset_top = 8
	column.offset_bottom = -10
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	var portrait := _troop_art(troop, t, 120)
	# Corner badges get their own headroom; the larger cat fills the rest of the colour field.
	column.add_child(_portrait_field(portrait, rarity, 154, 26))
	var details := Ui.vbox(0)
	details.name = "TroopCardDetails"
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(details)
	var name_label := _small_text(troop.display_name.trim_prefix("Mèo "), 24)
	name_label.name = "TroopName"
	name_label.add_theme_color_override("font_color", INK)
	name_label.custom_minimum_size.y = 34
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(name_label)
	if unlocked:
		Ui.pin(card, _level_badge(t["level"]), Vector2(-88, 8), Control.PRESET_TOP_RIGHT)
		details.add_child(_earned_stars(t["stars"]))
	if unlocked and PlayerData.in_team(id):
		var badge := Ui.icon("badge_check", 24)
		badge.name = "TroopInTeam"
		# The upgrade arrow leads; team membership follows without moving the level.
		_pin_state_badge(card, badge, Vector2(42 if has_upgrade else 8, 8))
	if unlocked:
		var ready: Control
		if star_ready:
			ready = UpgradeHint.new()
			ready.name = "TroopStarReady"
		elif level_ready:
			ready = UpgradeHint.new()
			ready.name = "TroopLevelReady"
		if ready != null:
			# Last child draws above the team marker without escaping the card's layer.
			# Raising z_index here would also draw the arrow above later modal popups.
			_pin_state_badge(card, ready, Vector2(4, -18))
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
	_cancel_drag()
	_close_detail()
	_detail_id = id
	var screen := TroopUpgradeScreen.new()
	_detail_screen = screen
	screen.team_requested.connect(_join_team)
	screen.tree_exited.connect(func():
		if _detail_screen == screen:
			_detail_screen = null)
	screen.attach(home, id)


func _close_detail() -> void:
	if is_instance_valid(_detail_screen):
		_detail_screen.close()
	_detail_screen = null


func _join_team(id: String) -> void:
	if PlayerData.add_to_team(id):
		_close_detail()
		return
	# Team full: pick the slot to replace.
	_swap_id = id
	_blink = 0.0
	_close_detail()
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
