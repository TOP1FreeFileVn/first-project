extends "res://game/menu/pages/MenuPage.gd"

# Troop roster. The team stands on an open meadow beside the cardboard castle:
# one spot per cat (Cats.gd), with a live idle rig and drag-to-field / drag-to-bench
# interactions (how many cats fight grows with the castle). Below, one column per cat with its four versions
# (one per world) stacked top to bottom; those cards stay still, the fighting one only gets
# a gold frame and a tick (pirate cards retain their rarity rim). Tapping a card opens the training screen, whose team button
# picks that version.

const Ui = preload("res://game/ui/Ui.gd")
const UpgradeHint = preload("res://game/ui/UpgradeHint.gd")
const TroopUpgradeScreen = preload("res://game/menu/popups/TroopUpgradeScreen.gd")
const SoldierRig = preload("res://game/battle/SoldierRig.gd")
const Cats = preload("res://game/data/Cats.gd")
const FormationMeadow = preload("res://game/ui/FormationMeadow.gd")
const MeadowSectionHeader = preload("res://game/ui/MeadowSectionHeader.gd")
const TroopDragButton = preload("res://game/ui/TroopDragButton.gd")
const PirateTroopCard = preload("res://game/ui/PirateTroopCard.gd")
const RIG_DIR := "res://game/assets/units/"
const CARD_SIZE := Vector2(0, 150)
const STAGE_HEIGHT := 140.0
## Rig pixels (256x240 art, feet at the origin) to stage pixels.
const RIG_SCALE := 0.5
const INK := Color("583f21")
const MUTED_INK := Color("6b563b")
const GOLD := Color("ffc93c")
## Card background per world, in Cats.WORLDS order.
const WORLD_TINTS := {"carton": Color("e0b680"), "den_long": Color("ef8f7a"), "co_tich": Color("93c983"), "hai_tac": Color("7fb6dc")}
const KLASS_ICONS := ["w_kiem", "w_cung", "w_gay_phep", "w_giao"]

var _detail_screen: Control
var _detail_id := ""
var _formation_backdrop: Control
var _formation_stage: Control
var _formation_column: VBoxContainer
var _roster_scroll: ScrollContainer
var _roster_drop_cue: Panel
var _drag_source: Control
var _drag_id := ""
var _drag_kind := ""

func _init() -> void:
	super()
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Upgrade prompts rise above the top card edge, including at maximum upward bob.
	(get_child(0).get_child(0) as MarginContainer).add_theme_constant_override("margin_top", 16)
	_roster_scroll = get_child(0) as ScrollContainer
	_roster_scroll.name = "TroopRosterScroll"
	_roster_scroll.set_drag_forwarding(Callable(), _can_bench_drop, _receive_bench_drop)
	_formation_backdrop = FormationMeadow.new()
	_formation_backdrop.name = "TeamMeadowBackdrop"
	add_child(_formation_backdrop)
	move_child(_formation_backdrop, 0)
	var fixed_header := Ui.margin(0, 0, 0, 0)
	fixed_header.name = "TroopsFixedHeader"
	add_child(fixed_header)
	fixed_header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_formation_column = Ui.vbox(0)
	fixed_header.add_child(_formation_column)
	resized.connect(_fit_formation_backdrop, CONNECT_DEFERRED)
	_roster_drop_cue = _drop_cue("RosterDropCue")
	add_child(_roster_drop_cue)
	_roster_drop_cue.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_roster_drop_cue.offset_left = 8
	_roster_drop_cue.offset_right = -8
	_roster_drop_cue.offset_bottom = -8
	visibility_changed.connect(_clear_drag_feedback)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_clear_drag_feedback.call_deferred()

func refresh() -> void:
	for child in _formation_column.get_children():
		_formation_column.remove_child(child)
		child.queue_free()
	super()

func build() -> void:
	body.add_theme_constant_override("separation", 12)
	_formation_column.add_child(_section_heading("ĐỘI HÌNH", "TroopsFormationSectionHeader"))
	_formation_column.add_child(_team_stage())
	_formation_column.add_child(_section_heading("LÍNH", "TroopsRosterSectionHeader"))
	body.add_child(_roster())
	_fit_formation_backdrop.call_deferred()

func has_alert() -> bool:
	return PlayerData.any_troop_improvable()

# --- Layout -----------------------------------------------------------------------------

## The approved honey-cream A strip, inset from both screen edges.
func _section_heading(text: String, node_name: String) -> Control:
	var header := MeadowSectionHeader.new()
	header.name = node_name
	header.heading = text
	header.gutter = FormationMeadow.SKY_COLOR if text == "ĐỘI HÌNH" else Color("c3d8a8")
	return header

## The team: a spot per cat with the fighting version's rig playing idle.
func _team_stage() -> Control:
	var meadow := Control.new()
	meadow.name = "TeamFormationMeadow"
	meadow.custom_minimum_size.y = 276
	meadow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formation_stage = meadow
	meadow.item_rect_changed.connect(_fit_formation_backdrop, CONNECT_DEFERRED)
	var row := Ui.hbox(8)
	row.name = "TeamFormation"
	for cat in Cats.ORDER:
		row.add_child(_team_spot(cat))
	meadow.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 34
	row.offset_top = 96
	row.offset_right = -34
	row.offset_bottom = -8
	return meadow

## The meadow, heading and team stay fixed. Only the roster below them scrolls.
func _fit_formation_backdrop() -> void:
	if not is_instance_valid(_formation_stage) or not is_inside_tree():
		return
	var page_inverse := get_global_transform().affine_inverse()
	var stage_start := page_inverse * _formation_stage.get_global_rect().position
	var stage_end := page_inverse * _formation_stage.get_global_rect().end
	_formation_backdrop.position = Vector2(0, stage_start.y)
	_formation_backdrop.size = Vector2(size.x, stage_end.y - stage_start.y)
	var fixed_end := page_inverse * _formation_column.get_global_rect().end
	_roster_scroll.offset_top = fixed_end.y
	_roster_drop_cue.offset_top = fixed_end.y + 4

func _team_spot(cat: String) -> Control:
	var column := Ui.vbox(2, BoxContainer.ALIGNMENT_CENTER)
	column.name = "TeamSlot_" + cat
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fighting := PlayerData.team_same_cat(Cats.VERSIONS[cat][0])
	var stage := TroopDragButton.new()
	stage.name = "TeamStage_" + cat
	stage.troop_id = fighting
	stage.source = "team"
	stage.cat = cat
	_wire_drag(stage)
	stage.drop_allowed = _can_team_drop.bind(cat)
	stage.drop_receiver = _receive_team_drop.bind(cat)
	stage.custom_minimum_size = Vector2(0, STAGE_HEIGHT)
	stage.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		stage.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	if fighting != "":
		stage.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		stage.pressed.connect(_open_detail.bind(fighting))
		stage.tooltip_text = "Chạm xem chi tiết · Kéo xuống danh sách để cho nghỉ"
		_add_rig(stage, fighting)
	else:
		var empty := _small_text("Kéo lính\nvào đây", 20, true)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stage.add_child(empty)
		empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cue := _drop_cue("TeamDropCue")
	stage.add_child(cue)
	stage.move_child(cue, 0)
	cue.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_child(stage)
	var caption: String = Cats.NAMES[cat]
	if fighting != "":
		caption += " · Lv %d" % PlayerData.troop(fighting)["level"]
	var name_label := _small_text(caption, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.tooltip_text = Cats.BLURBS[cat]
	column.add_child(name_label)
	return column

## The version's battle rig, feet on the spot's floor, playing idle at its own pace.
func _add_rig(stage: Control, id: String) -> void:
	var path := RIG_DIR + id + "/" + id + ".json"
	if not FileAccess.file_exists(path):
		var portrait := UiKit.troop_portrait(PlayerData.TROOPS[id], 110)
		stage.add_child(portrait)
		portrait.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		return
	var shadow := Panel.new()
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0.35, 0.24, 0.12, 0.18)
	shade.set_corner_radius_all(40)
	shadow.add_theme_stylebox_override("panel", shade)
	stage.add_child(shadow)
	var rig := SoldierRig.new()
	rig.name = "TeamRig"
	rig.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rig.load_skeleton(path)
	rig.play("idle")
	rig.speed = randf_range(0.85, 1.1)
	rig.scale = Vector2.ONE * RIG_SCALE
	stage.add_child(rig)
	var place := func():
		var floor_at := Vector2(stage.size.x * 0.5, stage.size.y - 10.0)
		rig.position = floor_at
		shadow.position = floor_at + Vector2(-34, -6)
		shadow.size = Vector2(68, 12)
	stage.resized.connect(place)
	place.call_deferred()

## One column per cat, its four versions from top to bottom (world order).
func _roster() -> Control:
	var row := Ui.hbox(8)
	row.name = "TroopGrid"
	for cat in Cats.ORDER:
		var column := Ui.vbox(10)
		column.name = "CatColumn_" + cat
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := _small_text(Cats.NAMES[cat], 24)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.tooltip_text = Cats.BLURBS[cat]
		column.add_child(title)
		var fighting := PlayerData.team_same_cat(Cats.VERSIONS[cat][0])
		for id in Cats.VERSIONS[cat]:
			column.add_child(_card(id, id == fighting))
		row.add_child(column)
	return row

func _card(id: String, fighting: bool) -> Button:
	var troop: Resource = PlayerData.TROOPS[id]
	var t: Dictionary = PlayerData.troop(id)
	var unlocked: bool = t["unlocked"]
	var world := Cats.world_of(id)
	var pirate := world == "hai_tac"
	var card := TroopDragButton.new()
	card.name = "TroopCard_" + id
	card.troop_id = id
	card.source = "roster"
	card.cat = Cats.cat_of(id)
	_wire_drag(card)
	card.drop_allowed = _can_bench_drop
	card.drop_receiver = _receive_bench_drop
	card.set_meta("troop_id", id)
	card.custom_minimum_size = CARD_SIZE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.tooltip_text = troop.display_name + (" · Giữ rồi kéo lên đội hình" if unlocked else " · Chưa mở khóa")
	var face := _card_style(WORLD_TINTS[world], troop.rarity, fighting, unlocked)
	for state in ["normal", "hover", "disabled", "focus"]:
		card.add_theme_stylebox_override(state, StyleBoxEmpty.new() if pirate else face)
	var pressed := face.duplicate() as StyleBoxFlat
	pressed.bg_color = face.bg_color.darkened(0.12)
	card.add_theme_stylebox_override("pressed", StyleBoxEmpty.new() if pirate else pressed)
	if pirate:
		card.add_theme_stylebox_override("hover_pressed", StyleBoxEmpty.new())
	card.pressed.connect(_open_detail.bind(id))
	if pirate:
		card.add_child(_pirate_layer(id, troop.rarity, unlocked, fighting, false))

	var column := Ui.vbox(0, BoxContainer.ALIGNMENT_END)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_top = 22
	column.offset_bottom = -4
	var art := _troop_art(troop, t, 60 if pirate else 76)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(art)
	if unlocked:
		column.add_child(_earned_stars(t["stars"], 18))
	var world_label := _card_text(Cats.WORLD_SHORT[world], 17)
	world_label.name = "TroopWorld"
	world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_label.clip_text = true
	column.add_child(world_label)
	if pirate:
		# Reuse the real portrait, stars and caption; only the pirate world gets
		# the ship composition. The near hull sits in front of the feet, below UI.
		var stars := column.get_node_or_null("TroopStars") as Control
		art.reparent(card)
		if stars != null:
			stars.reparent(card)
		world_label.reparent(card)
		card.remove_child(column)
		column.queue_free()
		card.add_child(_pirate_layer(id, troop.rarity, unlocked, fighting, true))
		card.move_child(art, 1)
		if stars != null:
			card.move_child(stars, card.get_child_count() - 1)
		card.move_child(world_label, card.get_child_count() - 1)
		var place := _place_pirate_contents.bind(card, art, stars, world_label)
		card.resized.connect(place)
		place.call_deferred()
	# Top strip: level on the left, class on the right.
	if unlocked:
		Ui.pin(card, _level_badge(t["level"]), Vector2(8, 2))
	var klass := Ui.icon(KLASS_ICONS[clampi(troop.klass, 0, 3)], 26)
	klass.name = "TroopClass"
	klass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	klass.modulate.a = 1.0 if unlocked else 0.5
	Ui.pin(card, klass, Vector2(-32, 4), Control.PRESET_TOP_RIGHT)
	if fighting:
		var check := Ui.icon("badge_check", 26)
		check.name = "TroopInTeam"
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Ui.pin(card, check, Vector2(-16, -16), Control.PRESET_BOTTOM_RIGHT)
	# Only a star-up (enough cards) earns the big arrow; a level-up a small dot.
	if unlocked:
		var star_cost := PlayerData.star_up_cost(id)
		var level_cost := PlayerData.level_up_cost(id)
		if star_cost >= 0 and t["cards"] >= star_cost:
			var hint := UpgradeHint.new()
			hint.name = "TroopStarReady"
			hint.scale = Vector2(0.8, 0.7)
			Ui.pin(card, hint, Vector2(-30, -22), Control.PRESET_TOP_RIGHT)
		elif level_cost >= 0 and PlayerData.gold >= level_cost:
			var dot := Panel.new()
			dot.name = "TroopLevelReady"
			dot.custom_minimum_size = Vector2(14, 14)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var dot_style := StyleBoxFlat.new()
			dot_style.bg_color = Color("4cc35a")
			dot_style.set_corner_radius_all(7)
			dot_style.border_color = Color.WHITE
			dot_style.set_border_width_all(2)
			dot.add_theme_stylebox_override("panel", dot_style)
			Ui.pin(card, dot, Vector2(-8, -8), Control.PRESET_TOP_RIGHT)
	return card


func _pirate_layer(id: String, rarity: int, unlocked: bool, fighting: bool, front: bool) -> Control:
	var layer := PirateTroopCard.new()
	layer.name = "PirateShipFront" if front else "PirateTroopCard"
	layer.troop_id = id
	layer.rarity = rarity
	layer.unlocked = unlocked
	layer.fighting = fighting
	layer.front_only = front
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return layer


func _place_pirate_contents(card: Control, art: Control, stars: Control, caption: Label) -> void:
	# Ship fits the entire 160x150 frame. A slightly leftward cat leaves the
	# aft sail's skull and stern cabin visible beside it.
	var center := card.size.x * 0.5
	art.set_anchors_preset(Control.PRESET_TOP_LEFT)
	art.size = Vector2(60, 60)
	art.position = Vector2(center - 40, 41)
	if stars != null:
		for star in stars.get_children():
			(star as Control).custom_minimum_size = Vector2(16, 16)
		stars.set_anchors_preset(Control.PRESET_TOP_LEFT)
		stars.position = Vector2(0, 114)
		stars.size = Vector2(card.size.x, 16)
	caption.add_theme_font_size_override("font_size", 16)
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.set_anchors_preset(Control.PRESET_TOP_LEFT)
	caption.position = Vector2(0, 126)
	caption.size = Vector2(card.size.x, 23)

## World tint fill; a rarity-coloured rim, a thick gold one on the fighting version.
static func _card_style(tint: Color, rarity: int, fighting: bool, unlocked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = tint if unlocked else tint.lerp(Color("d9cfc0"), 0.6)
	style.set_corner_radius_all(16)
	style.border_color = GOLD if fighting else Economy.RARITY_COLORS[rarity].darkened(0.1)
	style.set_border_width_all(6 if fighting else 4)
	if fighting:
		style.shadow_color = Color(1.0, 0.78, 0.2, 0.55)
		style.shadow_size = 10
	return style

func _squash(card: Control, target: float) -> void:
	card.pivot_offset = card.size * 0.5
	card.create_tween().tween_property(card, "scale", Vector2.ONE * target, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- Drag to field / bench --------------------------------------------------------------

func _wire_drag(button: TroopDragButton) -> void:
	button.drag_data_provider = _troop_drag_data.bind(button)
	button.drag_preview_provider = _troop_drag_preview
	button.drag_started.connect(_show_drag_feedback.bind(button))

func _troop_drag_data(_at: Vector2, button: TroopDragButton) -> Variant:
	if not is_visible_in_tree() or is_instance_valid(_detail_screen):
		return null
	var id := button.troop_id
	if not PlayerData.TROOPS.has(id) or not PlayerData.is_unlocked(id):
		return null
	if button.source == "team" and not PlayerData.in_team(id):
		return null
	return {"kind": "troop", "troop_id": id, "source": button.source,
		"cat": Cats.cat_of(id), "owner_id": get_instance_id()}

func _drop_payload(data: Variant) -> Dictionary:
	if not data is Dictionary or data.get("kind") != "troop" or data.get("owner_id") != get_instance_id():
		return {}
	var id := str(data.get("troop_id", ""))
	if not PlayerData.TROOPS.has(id) or not PlayerData.is_unlocked(id):
		return {}
	if not is_visible_in_tree() or is_instance_valid(_detail_screen):
		return {}
	return data

func _can_team_drop(_at: Vector2, data: Variant, cat: String) -> bool:
	var payload := _drop_payload(data)
	if payload.is_empty() or Cats.cat_of(payload.troop_id) != cat:
		return false
	return PlayerData.team_same_cat(payload.troop_id) != "" or PlayerData.battle_team().size() < PlayerData.team_slots()

func _receive_team_drop(at: Vector2, data: Variant, cat: String) -> void:
	if _can_team_drop(at, data, cat):
		_apply_team_drop.call_deferred(str(data.troop_id), false)

func _can_bench_drop(_at: Vector2, data: Variant) -> bool:
	var payload := _drop_payload(data)
	return not payload.is_empty() and payload.get("source") == "team" and PlayerData.in_team(payload.troop_id) and PlayerData.battle_team().size() > 1

func _receive_bench_drop(at: Vector2, data: Variant) -> void:
	if _can_bench_drop(at, data):
		_apply_team_drop.call_deferred(str(data.troop_id), true)

func _apply_team_drop(id: String, bench: bool) -> void:
	# Finish Godot's native drop before PlayerData.changed rebuilds the source.
	_clear_drag_feedback()
	var changed := PlayerData.remove_from_team(id) if bench else PlayerData.add_to_team(id)
	if changed:
		SoundLib.play("click")
		if not is_instance_valid(home):
			refresh()

func _troop_drag_preview(data: Variant) -> Control:
	var id := str(data.troop_id)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := PanelContainer.new()
	face.custom_minimum_size = Vector2(124, 148)
	face.position = Vector2(-62, -116)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = WORLD_TINTS[Cats.world_of(id)]
	style.border_color = INK
	style.set_border_width_all(4)
	style.set_corner_radius_all(12)
	face.add_theme_stylebox_override("panel", style)
	root.add_child(face)
	var column := Ui.vbox(2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_troop_art(PlayerData.TROOPS[id], PlayerData.troop(id), 100))
	column.add_child(_small_text(Cats.NAMES[Cats.cat_of(id)], 20))
	face.add_child(column)
	return root

func _drop_cue(node_name: String) -> Panel:
	var cue := Panel.new()
	cue.name = node_name
	cue.visible = false
	cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.93, 0.58, 0.18)
	style.border_color = Color("6ca147")
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	cue.add_theme_stylebox_override("panel", style)
	return cue

func _show_drag_feedback(data: Variant, source: Control) -> void:
	_drag_source = source
	_drag_source.modulate.a = 0.45
	_drag_id = str(data.troop_id)
	_drag_kind = str(data.source)
	for cat in Cats.ORDER:
		var stage := find_child("TeamStage_" + cat, true, false) as Control
		var cue := stage.get_node("TeamDropCue") as Panel
		cue.visible = _drag_kind == "roster" and _can_team_drop(Vector2.ZERO, data, cat)
	_roster_drop_cue.visible = _can_bench_drop(Vector2.ZERO, data)
	var header := find_child("TroopsRosterSectionHeader", true, false) as MeadowSectionHeader
	if _roster_drop_cue.visible:
		header.heading = "THẢ ĐỂ CHO NGHỈ"

func _clear_drag_feedback() -> void:
	if is_instance_valid(_drag_source):
		_drag_source.modulate.a = 1.0
	_drag_source = null
	_drag_id = ""
	_drag_kind = ""
	if is_instance_valid(_roster_drop_cue):
		_roster_drop_cue.visible = false
	for cue in find_children("TeamDropCue", "Panel", true, false):
		cue.visible = false
	var header := find_child("TroopsRosterSectionHeader", true, false) as MeadowSectionHeader
	if header != null:
		header.heading = "LÍNH"

# --- Team -------------------------------------------------------------------------------

## The strongest unlocked version of a cat, or "".
func _best_owned(cat: String) -> String:
	var best := ""
	for id in Cats.VERSIONS[cat]:
		if PlayerData.is_unlocked(id) and (best == "" or PlayerData.troop_power(id) > PlayerData.troop_power(best)):
			best = id
	return best

func _field(id: String) -> void:
	if id == "":
		return
	if PlayerData.add_to_team(id):
		SoundLib.play("click")
		refresh()
	else:
		_toast("Đủ %d mèo ra trận · Nâng thành để mang thêm" % PlayerData.team_slots())

func _bench(id: String) -> void:
	if PlayerData.remove_from_team(id):
		SoundLib.play("click")
		refresh()
	else:
		_toast("Phải còn ít nhất 1 mèo ra trận.")

## Picks a version from the training screen: it replaces its cat's version in the team.
func _join_team(id: String) -> void:
	if PlayerData.add_to_team(id):
		_close_detail()
		refresh()
		return
	_close_detail()
	_toast("Đủ %d mèo ra trận · Cho một mèo nghỉ trước" % PlayerData.team_slots())

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

func _open_detail(id: String) -> void:
	_close_detail()
	_detail_id = id
	var screen := TroopUpgradeScreen.new()
	_detail_screen = screen
	screen.team_requested.connect(_join_team)
	screen.tree_exited.connect(func():
		if _detail_screen == screen:
			_detail_screen = null
			refresh())
	screen.attach(home, id)

func _close_detail() -> void:
	if is_instance_valid(_detail_screen):
		_detail_screen.close()
	_detail_screen = null

# --- Shared card pieces (also used by the training screen and reviews) -------------------

## Card tone per rarity, the same as the battle shop: Thường green, Hiếm blue, Sử thi
## purple, Huyền thoại orange.
static func tone(rarity: int) -> String:
	return ["Green", "Blue", "Purple", "Orange"][clampi(rarity, 0, 3)]

static func _small_text(text: String, font_size := 22, muted := false) -> Label:
	var caption := Ui.label(text, "LabelDark", font_size)
	caption.add_theme_color_override("font_color", MUTED_INK if muted else INK)
	caption.add_theme_constant_override("outline_size", 0)
	return caption

## Compact card captions keep the game font legible over every colour.
static func _card_text(text: String, font_size := 22) -> Label:
	var caption := Ui.label(text, "", font_size)
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_color_override("font_outline_color", Color.BLACK)
	# Keep the black contour visible when the 720 px layout shrinks to a phone.
	caption.add_theme_constant_override("outline_size", 6)
	return caption

static func _level_badge(level: int) -> Control:
	var badge := Control.new()
	badge.name = "TroopLevelBadge"
	badge.custom_minimum_size = Vector2(64, 26)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caption := _card_text("Lv %d" % level, 20)
	caption.name = "TroopLevel"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	badge.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return badge

## Show earned stars only; the row remains centred as its count changes.
static func _earned_stars(count: int, icon_size := 24.0) -> HBoxContainer:
	var row := Ui.hbox(0)
	row.name = "TroopStars"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in clampi(count, 0, Economy.MAX_STARS):
		var star := Ui.icon("troop_star", icon_size)
		star.name = "TroopStar_%d" % (i + 1)
		row.add_child(star)
	return row

## A locked troop is a soft silhouette with a light question mark.
static func _troop_art(troop: Resource, t: Dictionary, portrait_size: float) -> Control:
	var portrait := UiKit.troop_portrait(troop, portrait_size, SpriteLib.player_color(1 + 2 * (t["stars"] - 1)))
	portrait.name = "TroopPortrait"
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if t["unlocked"]:
		return portrait
	portrait.modulate = Color(0.25, 0.2, 0.16, 0.45)
	var mystery := Control.new()
	mystery.name = "TroopLockedPortrait"
	mystery.custom_minimum_size = Vector2.ONE * portrait_size
	mystery.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mystery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mystery.add_child(portrait)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var question := _small_text("?", roundi(portrait_size * 0.42))
	question.name = "TroopLockedQuestion"
	question.add_theme_color_override("font_color", Color("fff0d3"))
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mystery.add_child(question)
	question.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return mystery

## How fast a troop runs, in words: slow, normal, fast, very fast.
static func speed_word(speed: float) -> String:
	if speed < 52.0:
		return "chậm"
	if speed < 70.0:
		return "vừa"
	if speed < 100.0:
		return "nhanh"
	return "rất nhanh"
