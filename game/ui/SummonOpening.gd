extends Control

# Full-screen troop summon. A floating card gathers the paw portal's motes, compresses,
# then releases the hand. Rarity is hinted only at the end of the charge.
#   reveal   - cards flip one by one, with a local celebration for epic / legendary;
#   showcase - every new troop and every epic or legendary card steps out large (tap to continue);
#   done     - the results stay on screen with DONE and SUMMON AGAIN.
# The results are already granted, so SKIP or closing never loses anything.

signal closed

const Cats = preload("res://game/data/Cats.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const Ui = preload("res://game/ui/Ui.gd")
const Economy = preload("res://game/core/Economy.gd")
const TroopData = preload("res://game/data/TroopData.gd")
const SummonPortal = preload("res://game/ui/SummonPortal.gd")

const SCREEN := Vector2(720, 1280)
const CIRCLE_AT := Vector2(360, 600)
const CARD_SIZE := Vector2(122, 168)
const SOURCE_SIZE := Vector2(156, 212)

var _results: Array = []
var _menu_pattern := false
var _on_again: Callable
var _best := 0
var _stage := "charge"
var _time := 0.0
var _tween: Tween
var _motions: Array[Tween] = []
var _cards: Array = []
var _next := 0
var _showcase_queue: Array = []
## Troops this summon unlocked (their first card).
var _fresh := {}
var _special_until := 0.0

# Presentation only: no reward or currency changes happen in this layer.
var dim := 0.0
var charge := 0.0
var circle_alpha := 1.0
var light := Color("d7c2f4")
var source_squash := Vector2.ONE
var _portal: Node2D
var _source_card: Control

var _hint: Label
var _status: Label
var _skip: Button
var _extras: Array = []


func setup(results: Array, on_again := Callable()) -> void:
	_results = results
	_on_again = on_again
	for result in results:
		_best = maxi(_best, _rank(result))
		if result["new"]:
			_fresh[result["id"]] = true
		if (result["rarity"] >= 2 or result["new"]) and not _showcase_queue.has(result["id"]):
			_showcase_queue.append(result["id"])


func attach(host: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	host.add_child(layer)
	layer.add_child(self)
	_menu_pattern = Ui.register_menu_surface(host, layer, "summon")


func _ready() -> void:
	# It lives on its own CanvasLayer, which does not inherit the lobby's smooth filtering;
	# the SVG skin scaled up for the reveal would look jagged with the project's nearest.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.make_theme()
	_portal = SummonPortal.new()
	_portal.name = "SummonPortal"
	_portal.position = CIRCLE_AT
	add_child(_portal)
	_source_card = UiKit.card_back_face(SOURCE_SIZE, true)
	_source_card.name = "SummonSourceCard"
	_source_card.pivot_offset = SOURCE_SIZE / 2.0
	add_child(_source_card)
	_hint = UiKit.label("", 22, UiKit.INFO)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.position = Vector2(0, 1040)
	_hint.size = Vector2(SCREEN.x, 40)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	var title := UiKit.label("TRIỆU HỒI x%d" % _results.size(), 34, UiKit.GOLD_TEXT)
	title.add_theme_constant_override("outline_size", 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 70)
	title.size = Vector2(SCREEN.x, 50)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	_status = UiKit.label("GỌI ĐỒNG ĐỘI", 26, Color("e7d6f6"))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.position = Vector2(40, 236)
	_status.size = Vector2(SCREEN.x - 80, 42)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status)
	_skip = UiKit.button("BỎ QUA ≫", Vector2(170, 64), skip)
	_skip.position = Vector2(530, 140)
	add_child(_skip)
	_charge()


func _process(delta: float) -> void:
	_time += delta
	_portal.energy = charge
	_portal.opacity = circle_alpha
	_portal.accent = light
	if _stage == "charge":
		_source_card.position = CIRCLE_AT - SOURCE_SIZE / 2.0 + Vector2(0, -24.0 - charge * 65.0 + sin(_time * 2.8) * 7.0)
		_source_card.scale = Vector2.ONE * (0.8 + charge * 0.4) * source_squash
		_source_card.rotation = sin(_time * 2.0) * 0.065 * (1.0 - charge * 0.6)
	_motions = _motions.filter(func(motion: Tween): return motion.is_valid() and motion.is_running())
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_on_tap()


func _on_tap() -> void:
	if _time < _special_until:
		return
	match _stage:
		"charge", "burst":
			if _tween != null and _tween.is_valid():
				_tween.custom_step(60.0)
		"reveal":
			# Finish an ordinary flip, but leave a rare card's hold on screen.
			if _tween != null and _tween.is_valid():
				_tween.custom_step(0.34)
		"showcase":
			_next_showcase()


func skip() -> void:
	if _stage == "done":
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_stop_motion()
	_clear_extras()
	_portal.clear_bursts()
	_source_card.visible = false
	_showcase_queue.clear()
	charge = 0.0
	circle_alpha = 0.45
	if _cards.is_empty():
		_deal(false)
	for card in _cards:
		card.position = card.get_meta("home")
		card.scale = Vector2.ONE * card.get_meta("scale")
		card.rotation = 0.0
		_set_face(card, true)
	_done()


# --- Stages -------------------------------------------------------------------------------

func _charge() -> void:
	_stage = "charge"
	_hint.text = "Chạm để gọi nhanh"
	var target: Color = Economy.RARITY_COLORS[_best].lightened(0.22)
	var time: float = [1.0, 1.1, 1.25, 1.45][_best] + (0.1 if _results.size() > 1 else 0.0)
	_tween = create_tween()
	_tween.set_parallel()
	_tween.tween_property(self, "dim", 0.9, 0.25)
	_tween.tween_property(self, "charge", 1.0, time - 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# The colour gives the result away only near the end.
	_tween.tween_property(self, "light", target, 0.3).set_delay(time - 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# A short compression gives the release weight without shaking the interface.
	_tween.tween_property(self, "source_squash", Vector2(0.84, 1.12), 0.16).set_delay(time - 0.16)
	_tween.chain().tween_callback(_burst)
	SoundLib.play("charge", -2.0, 0.0)


func _burst() -> void:
	_stage = "burst"
	SoundLib.play("chest_open", 0.0, 0.0)
	charge = 0.0
	_source_card.visible = false
	_status.text = "ĐỒNG ĐỘI ĐANG ĐẾN!"
	_hint.text = ""
	_portal.pulse(Vector2(0, -65), light, 1.45 if _best >= 2 else 1.0)
	circle_alpha = 0.6
	_deal(true)
	_tween = create_tween()
	_tween.tween_interval(0.5 if _results.size() == 1 else 0.82)
	_tween.tween_callback(_reveal_next)


func _deal(animate: bool) -> void:
	var count := _results.size()
	var columns := 1 if count == 1 else 5
	var card_scale := 1.9 if count == 1 else 1.0
	var gap := 12.0
	var rows := ceili(count / float(columns))
	var width := columns * CARD_SIZE.x * card_scale + (columns - 1) * gap
	var height := rows * CARD_SIZE.y * card_scale + (rows - 1) * gap
	var origin := Vector2((SCREEN.x - width) / 2.0, 560.0 - height / 2.0)
	for i in count:
		var card := _make_card(_results[i])
		var home := origin + Vector2((i % columns) * (CARD_SIZE.x * card_scale + gap), (i / columns) * (CARD_SIZE.y * card_scale + gap))
		# Scale from the card's centre, so place it by its top-left adjusted for the pivot.
		home += CARD_SIZE * (card_scale - 1.0) / 2.0
		card.set_meta("home", home)
		card.set_meta("scale", card_scale)
		add_child(card)
		move_child(card, _hint.get_index())
		_cards.append(card)
		if animate:
			card.position = CIRCLE_AT - CARD_SIZE / 2.0 - Vector2(0, 65)
			card.scale = Vector2(0.15, 0.15)
			card.modulate.a = 0.0
			card.rotation = (float(i) - float(count - 1) / 2.0) * 0.12
			var fly := _motion().set_parallel()
			fly.tween_property(card, "position", home, 0.46).set_delay(i * 0.032).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			fly.tween_property(card, "scale", Vector2.ONE * card_scale, 0.46).set_delay(i * 0.032).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			fly.tween_property(card, "rotation", 0.0, 0.4).set_delay(i * 0.032)
			fly.tween_property(card, "modulate:a", 1.0, 0.12).set_delay(i * 0.032)
		else:
			card.position = home
			card.scale = Vector2.ONE * card_scale


func _reveal_next() -> void:
	if _stage == "burst":
		# A tap can finish the burst timer before the staggered flights finish.
		_stop_motion()
		for dealt in _cards:
			dealt.position = dealt.get_meta("home")
			dealt.scale = Vector2.ONE * dealt.get_meta("scale")
			dealt.rotation = 0.0
			dealt.modulate.a = 1.0
	_stage = "reveal"
	_hint.text = "Chạm để lật nhanh"
	if _next >= _cards.size():
		_after_reveal()
		return
	var card: Control = _cards[_next]
	var result: Dictionary = _results[_next]
	_next += 1
	_status.text = "DẤU ẤN ĐỒNG ĐỘI · %d / %d" % [_next, _results.size()]
	var rank := _rank(result)
	var card_scale: float = card.get_meta("scale")
	_tween = create_tween()
	if rank >= 2:
		# Tease: the face-down card trembles in its colour.
		card.get_node("Back").self_modulate = Economy.RARITY_COLORS[rank].lightened(0.2)
		_tween.tween_property(card, "scale", Vector2.ONE * card_scale * 1.08, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(card, "scale:x", 0.0, 0.08)
	_tween.tween_callback(func():
		SoundLib.play("flip")
		_set_face(card, true)
		_portal.pulse(card.position + CARD_SIZE / 2.0 - CIRCLE_AT, Economy.RARITY_COLORS[rank], 0.65 if rank < 2 else 1.0)
		if rank >= 2:
			_special(card, result, rank))
	_tween.tween_property(card, "scale", Vector2.ONE * card_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(0.9 if rank >= 2 else 0.04)
	_tween.tween_callback(_reveal_next)


func _special(_card: Control, result: Dictionary, rank: int) -> void:
	_special_until = _time + 0.45
	MusicLib.duck(1.6)
	SoundLib.play("legend" if rank >= 3 else "epic", 0.0, 0.0)
	var color: Color = Economy.RARITY_COLORS[rank]
	var text := "HUYỀN THOẠI!" if rank >= 3 else "SỬ THI!"
	if result.get("new", false):
		text = "MỚI! " + text
	var banner := UiKit.label(text, 40, color.lightened(0.15))
	banner.add_theme_constant_override("outline_size", 7)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position = Vector2(0, 302)
	banner.size = Vector2(SCREEN.x, 70)
	banner.pivot_offset = banner.size / 2.0
	banner.scale = Vector2(0.88, 0.88)
	banner.modulate.a = 0.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	_extras.append(banner)
	var slam := _motion().set_parallel()
	slam.tween_property(banner, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slam.tween_property(banner, "modulate:a", 1.0, 0.1)
	slam.chain().tween_interval(0.5)
	slam.chain().tween_property(banner, "modulate:a", 0.0, 0.25)
	light = color.lightened(0.22)


func _after_reveal() -> void:
	if _showcase_queue.is_empty():
		_done()
	else:
		_next_showcase()


# One troop at a time, large and running, with its name, class and ability.
func _next_showcase() -> void:
	_stop_motion()
	_clear_extras()
	if _showcase_queue.is_empty():
		_done()
		return
	_stage = "showcase"
	_status.text = "GẶP GỠ ĐỒNG ĐỘI"
	_special_until = _time + 0.5
	_hint.text = "Chạm để tiếp tục"
	var id: String = _showcase_queue.pop_front()
	SoundLib.play("hero", 0.0, 0.0)
	var troop: Resource = PlayerData.TROOPS[id]
	var color: Color = Economy.RARITY_COLORS[troop.rarity]
	light = color.lightened(0.3)
	for card in _cards:
		card.modulate.a = 0.15
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.03, 0.1, 0.65)
	shade.size = SCREEN
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	move_child(shade, _hint.get_index())
	_extras.append(shade)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.unit_frames(troop.unit_key, "Blue")
	sprite.offset = Vector2(0, -SpriteLib.foot_offset(troop.unit_key))
	sprite.position = Vector2(360, 700)
	sprite.scale = Vector2(1.8, 1.8)
	sprite.modulate.a = 0.0
	sprite.play("attack")
	sprite.animation_finished.connect(func(): sprite.play("idle"))
	add_child(sprite)
	_extras.append(sprite)
	var arrive := _motion().set_parallel()
	arrive.tween_property(sprite, "scale", Vector2(2.4, 2.4), 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	arrive.tween_property(sprite, "modulate:a", 1.0, 0.2)
	# This celebration sits above the showcase shade, behind the unchanged cat.
	var celebration := SummonPortal.new()
	celebration.position = CIRCLE_AT
	celebration.opacity = 0.7
	celebration.accent = light
	add_child(celebration)
	move_child(celebration, sprite.get_index())
	_extras.append(celebration)
	celebration.pulse(Vector2(0, -30), color.lightened(0.2), 1.6)
	var box := UiKit.vbox(4)
	box.position = Vector2(0, 760)
	box.size = Vector2(SCREEN.x, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_extras.append(box)
	var tag := UiKit.label("LÍNH MỚI!" if _fresh.has(id) else Economy.RARITY_NAMES[troop.rarity].to_upper() + "!", 44, UiKit.GOLD_TEXT)
	tag.add_theme_constant_override("outline_size", 10)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tag)
	var name_label := UiKit.label(troop.display_name, 32, color)
	name_label.add_theme_constant_override("outline_size", 8)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var klass := UiKit.label("✦ %s · %s · %s" % [TroopData.KLASS_NAMES[troop.klass], Economy.RARITY_NAMES[troop.rarity], Cats.WORLD_NAMES.get(Cats.world_of(id), "")], 22, Color("9ff0a0"))
	klass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(klass)
	if troop.ability_text != "":
		var skill := UiKit.label(troop.ability_text, 20)
		skill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skill.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		skill.custom_minimum_size.x = SCREEN.x - 80
		box.add_child(skill)

func _done() -> void:
	if _stage == "done":
		return
	_stage = "done"
	_stop_motion()
	_clear_extras()
	_source_card.visible = false
	_skip.visible = false
	_hint.text = ""
	_status.text = "ĐỒNG ĐỘI ĐÃ SẴN SÀNG"
	circle_alpha = 0.45
	for card in _cards:
		card.modulate.a = 1.0
	var buttons := UiKit.hbox(18)
	buttons.name = "SummonResultButtons"
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.position = Vector2(0, 1010)
	buttons.size = Vector2(SCREEN.x, 90)
	add_child(buttons)
	buttons.add_child(UiKit.button("XONG", Vector2(240, 84), _close))
	if _on_again.is_valid():
		var count := _results.size()
		var cost := PlayerData.summon_cost(count)
		var again := UiKit.button("LẠI x%d\n%s" % [count, "MIỄN PHÍ" if cost == 0 else "◆ %d" % cost], Vector2(260, 84), func():
			_close()
			_on_again.call(), true)
		again.disabled = not PlayerData.can_summon(count)
		buttons.add_child(again)


func _close() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_stop_motion()
	closed.emit()
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()


# --- Drawing ------------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2(-60, -60), SCREEN + Vector2(120, 120)), Color(0.03, 0.02, 0.08, dim * (0.5 if _menu_pattern else 1.0)))


# --- Pieces -------------------------------------------------------------------------------

func _rank(result: Dictionary) -> int:
	return int(result.get("rarity", 0))


func _make_card(result: Dictionary) -> Control:
	var rank := _rank(result)
	var color: Color = Economy.RARITY_COLORS[rank]
	var card := Control.new()
	card.size = CARD_SIZE
	card.pivot_offset = CARD_SIZE / 2.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	card.add_child(UiKit.card_back_face(CARD_SIZE, true))

	var front := PanelContainer.new()
	front.name = "Front"
	front.size = CARD_SIZE
	front.add_theme_stylebox_override("panel", UiKit.rarity_card(rank))
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := UiKit.vbox(0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	front.add_child(column)
	var troop: Resource = PlayerData.TROOPS[result["id"]]
	column.add_child(_center(UiKit.label(Economy.RARITY_NAMES[rank], 13)))
	column.add_child(_center(UiKit.troop_portrait(troop, 70)))
	var name_label := UiKit.label(troop.display_name, 12)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size.x = CARD_SIZE.x - 20
	column.add_child(name_label)
	column.add_child(_center(UiKit.tag("Mới!") if result["new"] else UiKit.label("+1 thẻ", 13)))
	card.add_child(front)
	_set_face(card, false)
	return card


func _center(control: Control) -> Control:
	control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return control


func _set_face(card: Control, up: bool) -> void:
	card.get_node("Back").visible = not up
	card.get_node("Front").visible = up


func _motion() -> Tween:
	var motion := create_tween()
	_motions.append(motion)
	return motion


func _stop_motion() -> void:
	for motion in _motions:
		if motion.is_valid():
			motion.kill()
	_motions.clear()


func _clear_extras() -> void:
	for node in _extras:
		if is_instance_valid(node):
			node.hide()
			node.queue_free()
	_extras.clear()
