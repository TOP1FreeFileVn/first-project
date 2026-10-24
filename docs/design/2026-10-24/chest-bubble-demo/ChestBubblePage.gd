extends "res://game/menu/pages/ShopPage.gd"

## Review only: three chest-card compositions, using the current real offers.
## All reward and guarantee copy lives inside the speech bubble, as requested.
const BubbleShape = preload("res://docs/design/2026-10-24/chest-bubble-demo/SpeechBubble.gd")
const VARIANT_NAMES := ["A · Rương nói chuyện", "B · Phiếu tiếp tế", "C · Lời nhắn trong hộp"]

var variant := 0
var _bubble_status: Dictionary = {}
var _bubble_actions: Dictionary = {}


func set_variant(value: int) -> void:
	variant = clampi(value, 0, 2)
	if body != null and is_instance_valid(body):
		refresh()


func build() -> void:
	_bubble_status.clear()
	_bubble_actions.clear()
	var margin := body.get_parent() as MarginContainer
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 28)
	body.add_theme_constant_override("separation", 16)
	for kind in ["gold", "silver", "wood"]:
		_build_card(kind)
	_exchange_row()
	tick()


func tick() -> void:
	for kind in _bubble_actions:
		var action: Button = _bubble_actions[kind]
		if not is_instance_valid(action):
			continue
		var status: Label = _bubble_status[kind]
		action.disabled = not PlayerData.can_open_chest(kind)
		var chest: Dictionary = Economy.CHESTS[kind]
		if kind == "wood":
			var seconds := PlayerData.free_chest_seconds_left()
			action.text = "MIỄN PHÍ" if seconds == 0 else "CHỜ NHẬN"
			status.text = "Còn " + UiKit.format_time(seconds) if seconds > 0 else ""
		else:
			var is_gems: bool = chest["gems"] > 0
			var missing := maxi(0, int(chest["gems"] if is_gems else chest["gold"]) - (PlayerData.gems if is_gems else PlayerData.gold))
			status.text = "Thiếu %s %s" % [UiKit.format_number(missing), "kim cương" if is_gems else "vàng"] if missing > 0 else ""
		status.visible = not status.text.is_empty()


func _build_card(kind: String) -> void:
	var chest: Dictionary = Economy.CHESTS[kind]
	var panel := PanelContainer.new()
	panel.name = "BubbleCard_" + kind
	panel.set_meta("shop_chest_kind", kind)
	panel.set_meta("review_variant", variant)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _card_skin(kind))
	body.add_child(panel)
	var box := UiKit.vbox(10)
	panel.add_child(box)
	var heading := UiKit.hbox(10)
	box.add_child(heading)
	var title_label := _demo_label(chest["name"], 32, Color("fff8e6"), true)
	title_label.name = kind.capitalize() + "Title"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if variant == 0 else HORIZONTAL_ALIGNMENT_LEFT
	heading.add_child(title_label)
	if kind == "gold":
		heading.add_child(_rates_action())
	match variant:
		0: _reference_layout(box, kind)
		1: _supply_layout(box, kind)
		2: _note_layout(box, kind)


func _reference_layout(box: VBoxContainer, kind: String) -> void:
	var row := UiKit.hbox(22)
	box.add_child(row)
	var art := _chest_art(kind, 238)
	art.name = "ChestArt_" + kind
	row.add_child(art)
	var right := UiKit.vbox(9)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var bubble := _reward_bubble(kind, "left")
	right.add_child(bubble)
	right.add_child(_demo_action(kind))


func _supply_layout(box: VBoxContainer, kind: String) -> void:
	var row := UiKit.hbox(22)
	box.add_child(row)
	var bubble := _reward_bubble(kind, "right")
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bubble)
	var art := _chest_art(kind, 228)
	art.name = "ChestArt_" + kind
	row.add_child(art)
	box.add_child(_demo_action(kind))


func _note_layout(box: VBoxContainer, kind: String) -> void:
	var bubble := _reward_bubble(kind, "bottom", true)
	box.add_child(bubble)
	var row := UiKit.hbox(25)
	box.add_child(row)
	var art := _chest_art(kind, 208)
	art.name = "ChestArt_" + kind
	row.add_child(art)
	var action := _demo_action(kind)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(action)


func _reward_bubble(kind: String, tail: String, horizontal := false) -> PanelContainer:
	var chest: Dictionary = Economy.CHESTS[kind]
	var bubble := BubbleShape.new()
	bubble.name = "Bubble_" + kind
	bubble.tail_side = tail
	bubble.tail_ratio = 0.22 if horizontal else 0.53
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bubble.fill = Color("67402e") if variant == 0 else (Color("d1e1d7") if variant == 1 else Color("f3e5c8"))
	var ink := Color("fff6dd") if variant == 0 else Color("3b3326")
	var box := UiKit.vbox(3)
	bubble.add_child(box)
	if horizontal:
		var row := UiKit.hbox(14)
		box.add_child(row)
		var quantity := _demo_label("%d trang bị" % chest["items"], 29, ink)
		quantity.name = kind.capitalize() + "Reward"
		quantity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(quantity)
		var stone := _demo_label("%d–%d đá rèn" % [chest["stones"][0], chest["stones"][1]], 26, ink)
		stone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stone.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(stone)
	else:
		var quantity := _demo_label("%d trang bị" % chest["items"], 29, ink)
		quantity.name = kind.capitalize() + "Reward"
		box.add_child(quantity)
		box.add_child(_demo_label("%d–%d đá rèn" % [chest["stones"][0], chest["stones"][1]], 24, ink))
	if int(chest.get("min_rare", 0)) > 0:
		var guarantee := _demo_label("≥ %d món %s" % [chest.get("min_count", 1), Economy.RARITY_NAMES[int(chest["min_rare"])]], 24, Color("f0c7ff") if variant == 0 and kind == "gold" else ink)
		guarantee.name = kind.capitalize() + "Guarantee"
		box.add_child(guarantee)
	elif kind == "wood":
		var bonus: Array = chest["bonus_gold"]
		box.add_child(_demo_label("+ %d–%d vàng" % [bonus[0], bonus[1]], 24, ink))
	var status := _demo_label("", 22, Color("ffdf9e") if variant == 0 else Color("8b342c"))
	status.name = "WoodStatus" if kind == "wood" else kind.capitalize() + "Deficit"
	status.visible = false
	box.add_child(status)
	_bubble_status[kind] = status
	return bubble


func _demo_action(kind: String) -> Button:
	var action := _chest_button(kind, "Yellow" if kind == "gold" else "White")
	action.custom_minimum_size.y = 80
	_bubble_actions[kind] = action
	return action


func _rates_action() -> Button:
	var action := Button.new()
	action.name = "ShopRates"
	action.text = "Tỉ lệ  ›"
	action.custom_minimum_size = Vector2(106, 40)
	action.add_theme_font_override("font", UiKit.game_font())
	action.add_theme_font_size_override("font_size", 23)
	action.add_theme_color_override("font_outline_color", Color("352719"))
	action.add_theme_constant_override("outline_size", 3)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		action.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		action.add_theme_color_override(state, Color("fff5dd"))
	action.pressed.connect(func(): SoundLib.play("click"); _show_rates())
	return action


func _demo_label(value: String, font_size: int, ink: Color, outlined := false) -> Label:
	var label := UiKit.ink(value, font_size)
	label.add_theme_color_override("font_color", ink)
	label.add_theme_color_override("font_outline_color", Color("392b20"))
	label.add_theme_constant_override("outline_size", 4 if outlined else 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _card_skin(kind: String) -> StyleBoxFlat:
	var palettes := [
		{"gold": "e9b260", "silver": "c3d3cd", "wood": "d9b78b"},
		{"gold": "e2e5ca", "silver": "efe9da", "wood": "ecdfc8"},
		{"gold": "3f6569", "silver": "5c7778", "wood": "6b786b"},
	]
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color(palettes[variant][kind])
	skin.border_color = BROWN
	skin.set_border_width_all(5)
	skin.set_corner_radius_all(24)
	skin.content_margin_left = 20
	skin.content_margin_right = 20
	skin.content_margin_top = 12
	skin.content_margin_bottom = 14
	skin.anti_aliasing = true
	skin.shadow_size = 0
	return skin
