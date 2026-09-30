extends Control

# Full-screen hero summon:
#   charge   - a summoning circle spins up; its light starts white and turns to the colour
#              of the best result (longer and stronger for epic / legendary);
#   burst    - flash and shockwave, the cards fly out face down into place;
#   reveal   - they flip one by one; epic and legendary heroes stop for a banner and shake;
#   showcase - every new hero steps out large with its buff (tap to continue);
#   done     - the results stay on screen with DONE and SUMMON AGAIN.
# The results are already granted, so SKIP or closing never loses anything.

signal closed

const UiKit = preload("res://game/ui/UiKit.gd")
const Economy = preload("res://game/core/Economy.gd")
const Heroes = preload("res://game/core/Heroes.gd")
const DrawnIcon = preload("res://game/ui/DrawnIcon.gd")

const SCREEN := Vector2(720, 1280)
const CIRCLE_AT := Vector2(360, 600)
const CARD_SIZE := Vector2(122, 168)

var _results: Array = []
var _featured := ""
var _on_again: Callable
var _best := 0
var _stage := "charge"
var _time := 0.0
var _tween: Tween
var _cards: Array = []
var _next := 0
var _showcase_queue: Array = []
var _special_until := 0.0

# Drawn state.
var dim := 0.0
var spin := 0.0
var charge := 0.0
var circle_alpha := 1.0
var light := Color.WHITE
var flash := 0.0
var ring := 0.0
var ray_alpha := 0.0

var _front: Control
var _hint: Label
var _skip: Button
var _extras: Array = []


func setup(results: Array, featured: String, on_again := Callable()) -> void:
	_results = results
	_featured = featured
	_on_again = on_again
	for result in results:
		_best = maxi(_best, _rank(result))
		if result["type"] == "hero" and result["new"]:
			_showcase_queue.append(result["id"])


func attach(host: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	host.add_child(layer)
	layer.add_child(self)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.make_theme()
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
	_skip = UiKit.button("BỎ QUA ≫", Vector2(170, 64), skip)
	_skip.position = Vector2(530, 140)
	add_child(_skip)
	_front = Control.new()
	_front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.draw.connect(_draw_front)
	add_child(_front)
	_charge()


func _process(delta: float) -> void:
	_time += delta
	spin += delta * (0.6 + charge * 6.0)
	if _front.get_index() != get_child_count() - 1:
		move_child(_front, -1)
	queue_redraw()
	_front.queue_redraw()


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
			# Flip everything left, still stopping for the specials.
			if _tween != null and _tween.is_valid():
				_tween.custom_step(60.0)
		"showcase":
			_next_showcase()


func skip() -> void:
	if _stage == "done":
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_clear_extras()
	_showcase_queue.clear()
	charge = 0.0
	circle_alpha = 0.35
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
	var target: Color = Economy.RARITY_COLORS[_best].lightened(0.3)
	var time: float = [0.8, 0.9, 1.15, 1.45][_best] + (0.2 if _results.size() > 1 else 0.0)
	_tween = create_tween()
	_tween.set_parallel()
	_tween.tween_property(self, "dim", 0.9, 0.25)
	_tween.tween_property(self, "charge", 1.0, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# The colour gives the result away only near the end.
	_tween.tween_property(self, "light", target, time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(_burst)
	SoundLib.play("charge", -2.0, 0.0)


func _burst() -> void:
	_stage = "burst"
	SoundLib.play("chest_open", 0.0, 0.0)
	charge = 0.0
	flash = 0.9 if _best >= 2 else 0.6
	create_tween().tween_property(self, "flash", 0.0, 0.4)
	ring = 0.001
	create_tween().tween_property(self, "ring", 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_shake(12.0 if _best >= 2 else 6.0, 0.3)
	_fx("blast", CIRCLE_AT, 1.8, light)
	ray_alpha = 1.0
	circle_alpha = 0.35
	_deal(true)
	_tween = create_tween()
	_tween.tween_interval(0.55)
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
			card.position = CIRCLE_AT - CARD_SIZE / 2.0
			card.scale = Vector2(0.2, 0.2)
			card.rotation = randf_range(-1.0, 1.0)
			var fly := card.create_tween().set_parallel()
			fly.tween_property(card, "position", home, 0.35).set_delay(i * 0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			fly.tween_property(card, "scale", Vector2.ONE * card_scale, 0.35).set_delay(i * 0.04)
			fly.tween_property(card, "rotation", 0.0, 0.35).set_delay(i * 0.04)
		else:
			card.position = home
			card.scale = Vector2.ONE * card_scale


func _reveal_next() -> void:
	_stage = "reveal"
	_hint.text = "Chạm để lật nhanh"
	if _next >= _cards.size():
		_after_reveal()
		return
	var card: Control = _cards[_next]
	var result: Dictionary = _results[_next]
	_next += 1
	var rank := _rank(result)
	var card_scale: float = card.get_meta("scale")
	_tween = create_tween()
	if rank >= 2:
		# Tease: the face-down card trembles in its colour.
		card.get_node("Back").self_modulate = Economy.RARITY_COLORS[rank].lightened(0.2)
		for i in 4:
			_tween.tween_property(card, "rotation", 0.1 * (1 if i % 2 == 0 else -1), 0.05)
		_tween.tween_property(card, "rotation", 0.0, 0.04)
	_tween.tween_property(card, "scale:x", 0.0, 0.08)
	_tween.tween_callback(func():
		SoundLib.play("flip")
		_set_face(card, true)
		if rank >= 2:
			_special(card, result, rank))
	_tween.tween_property(card, "scale:x", card_scale, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(0.9 if rank >= 2 else 0.04)
	_tween.tween_callback(_reveal_next)


func _special(card: Control, result: Dictionary, rank: int) -> void:
	_special_until = _time + 0.45
	SoundLib.play("legend" if rank >= 3 else "epic", 0.0, 0.0)
	var color: Color = Economy.RARITY_COLORS[rank]
	var text := "HUYỀN THOẠI!" if rank >= 3 else "SỬ THI!"
	if result.get("new", false):
		text = "MỚI! " + text
	var banner := UiKit.label(text, 52, color)
	banner.add_theme_constant_override("outline_size", 12)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position = Vector2(0, 200)
	banner.size = Vector2(SCREEN.x, 70)
	banner.pivot_offset = banner.size / 2.0
	banner.scale = Vector2(2.2, 2.2)
	banner.modulate.a = 0.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	_extras.append(banner)
	var slam := banner.create_tween().set_parallel()
	slam.tween_property(banner, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slam.tween_property(banner, "modulate:a", 1.0, 0.1)
	slam.chain().tween_interval(0.5)
	slam.chain().tween_property(banner, "modulate:a", 0.0, 0.25)
	var center: Vector2 = card.position + card.pivot_offset
	_fx("blast", center, 1.4, color.lightened(0.3))
	_shake(10.0 if rank >= 3 else 6.0, 0.3)
	flash = 0.5 if rank >= 3 else 0.3
	create_tween().tween_property(self, "flash", 0.0, 0.3)
	light = color.lightened(0.3)
	ring = 0.001
	create_tween().tween_property(self, "ring", 1.0, 0.5)


func _after_reveal() -> void:
	if _showcase_queue.is_empty():
		_done()
	else:
		_next_showcase()


# One new hero at a time, large, with its name and buff.
func _next_showcase() -> void:
	_clear_extras()
	if _showcase_queue.is_empty():
		_done()
		return
	_stage = "showcase"
	_special_until = _time + 0.5
	_hint.text = "Chạm để tiếp tục"
	var id: String = _showcase_queue.pop_front()
	SoundLib.play("hero", 0.0, 0.0)
	var hero: Dictionary = Heroes.HEROES[id]
	var color: Color = Economy.RARITY_COLORS[hero["rarity"]]
	light = color.lightened(0.3)
	for card in _cards:
		card.modulate.a = 0.15
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.5)
	shade.size = SCREEN
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	move_child(shade, _hint.get_index())
	_extras.append(shade)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.unit_frames(hero["unit"], "Blue")
	sprite.material = UiKit.hero_material(id)
	sprite.offset = Vector2(0, -SpriteLib.foot_offset(hero["unit"]))
	sprite.position = Vector2(360, 700)
	sprite.scale = Vector2(0.2, 0.2)
	sprite.play("attack")
	sprite.animation_finished.connect(func(): sprite.play("idle"))
	add_child(sprite)
	_extras.append(sprite)
	sprite.create_tween().tween_property(sprite, "scale", Vector2(2.4, 2.4), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx("blast", Vector2(360, 620), 2.2, color.lightened(0.3))
	flash = 0.7
	create_tween().tween_property(self, "flash", 0.0, 0.4)
	var box := UiKit.vbox(4)
	box.position = Vector2(0, 760)
	box.size = Vector2(SCREEN.x, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_extras.append(box)
	var tag := UiKit.label("TƯỚNG MỚI!", 44, UiKit.GOLD_TEXT)
	tag.add_theme_constant_override("outline_size", 10)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tag)
	var name_label := UiKit.label(hero["name"], 32, color)
	name_label.add_theme_constant_override("outline_size", 8)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var buff := UiKit.label("✦ " + Heroes.bonus_text(id, 1, 1), 22, Color("9ff0a0"))
	buff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(buff)


func _done() -> void:
	_stage = "done"
	_clear_extras()
	_skip.visible = false
	_hint.text = ""
	ray_alpha = 0.4
	for card in _cards:
		card.modulate.a = 1.0
	var buttons := UiKit.hbox(18)
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
	closed.emit()
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()


# --- Drawing ------------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2(-60, -60), SCREEN + Vector2(120, 120)), Color(0.03, 0.02, 0.08, dim))
	if ray_alpha > 0.0:
		for i in 14:
			var angle := _time * 0.3 + i * TAU / 14.0
			draw_colored_polygon(PackedVector2Array([CIRCLE_AT, CIRCLE_AT + Vector2.from_angle(angle - 0.08) * 1000.0,
				CIRCLE_AT + Vector2.from_angle(angle + 0.08) * 1000.0]), Color(light, 0.08 * ray_alpha))
	# The summoning circle, flattened like a floor seal.
	var glow := 0.3 + charge * 0.7
	draw_set_transform(CIRCLE_AT + Vector2(0, 150), 0.0, Vector2(1.0, 0.36))
	for i in 4:
		draw_circle(Vector2.ZERO, 250.0 - i * 40.0, Color(light, (0.05 + 0.05 * i) * glow * circle_alpha))
	draw_arc(Vector2.ZERO, 250.0, 0.0, TAU, 72, Color(light, 0.9 * circle_alpha), 6.0, true)
	draw_arc(Vector2.ZERO, 205.0, spin, spin + TAU * 0.75, 60, Color(light.lightened(0.3), 0.8 * circle_alpha), 4.0, true)
	draw_arc(Vector2.ZERO, 160.0, -spin * 1.4, -spin * 1.4 + TAU * 0.6, 48, Color(light, 0.7 * circle_alpha), 3.0, true)
	for i in 12:
		var at := Vector2.from_angle(spin + i * TAU / 12.0) * 228.0
		draw_rect(Rect2(at - Vector2(6, 6), Vector2(12, 12)), Color(light.lightened(0.5), 0.9 * circle_alpha))
	var star := PackedVector2Array()
	for i in 12:
		star.append(Vector2.from_angle(-spin + i * TAU / 12.0) * (140.0 if i % 2 == 0 else 60.0))
	star.append(star[0])
	draw_polyline(star, Color(light, 0.6 * circle_alpha), 3.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# A pillar of light while charging.
	if charge > 0.0:
		var width := 60.0 + charge * 160.0
		draw_colored_polygon(PackedVector2Array([CIRCLE_AT + Vector2(-width, 150), CIRCLE_AT + Vector2(width, 150),
			CIRCLE_AT + Vector2(width * 0.6, -700), CIRCLE_AT + Vector2(-width * 0.6, -700)]), Color(light, 0.25 * charge))
		for i in 6:
			var t := fmod(_time * 1.5 + i * 0.37, 1.0)
			var at := CIRCLE_AT + Vector2(sin(i * 2.1) * width * 0.8, 150 - t * 600.0)
			draw_circle(at, 4.0 + 4.0 * charge, Color(light.lightened(0.5), (1.0 - t) * charge))


func _draw_front() -> void:
	if ring > 0.0 and ring < 1.0:
		var r := lerpf(40.0, 700.0, ring)
		_front.draw_arc(CIRCLE_AT, r, 0.0, TAU, 72, Color(light.lightened(0.4), 0.8 * (1.0 - ring)), 26.0 * (1.0 - ring) + 2.0, true)
	if flash > 0.0:
		_front.draw_rect(Rect2(Vector2(-60, -60), SCREEN + Vector2(120, 120)), Color(1, 1, 0.97, flash))


# --- Pieces -------------------------------------------------------------------------------

func _rank(result: Dictionary) -> int:
	match result["type"]:
		"hero":
			return Heroes.HEROES[result["id"]]["rarity"]
		"shards":
			return 1 if result["id"] == _featured else 0
	return 0


func _make_card(result: Dictionary) -> Control:
	var rank := _rank(result)
	var color: Color = Economy.RARITY_COLORS[rank]
	var card := Control.new()
	card.size = CARD_SIZE
	card.pivot_offset = CARD_SIZE / 2.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var back := Panel.new()
	back.name = "Back"
	back.size = CARD_SIZE
	var back_style := UiKit.card_style(Color("c9a14a"), Color("2a1650"))
	back_style.set_border_width_all(4)
	back.add_theme_stylebox_override("panel", back_style)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portal := UiKit.drawn(DrawnIcon.Kind.PORTAL, 70)
	portal.position = CARD_SIZE / 2.0 - Vector2(35, 35)
	portal.size = Vector2(70, 70)
	back.add_child(portal)
	card.add_child(back)

	var front := PanelContainer.new()
	front.name = "Front"
	front.size = CARD_SIZE
	var style := UiKit.card_style(color, Color(0.1, 0.12, 0.17, 0.97) if rank < 3 else Color(0.22, 0.15, 0.05, 0.97))
	style.set_border_width_all(4 if rank < 2 else 5)
	style.set_content_margin_all(4)
	front.add_theme_stylebox_override("panel", style)
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := UiKit.vbox(0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	front.add_child(column)
	match result["type"]:
		"hero":
			var hero: Dictionary = Heroes.HEROES[result["id"]]
			column.add_child(_center(UiKit.label(Economy.RARITY_NAMES[rank], 13, color)))
			column.add_child(_center(UiKit.hero_portrait(result["id"], 86)))
			var name_label := UiKit.label(hero["name"], 13)
			name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.custom_minimum_size.x = CARD_SIZE.x - 10
			column.add_child(name_label)
			column.add_child(_center(UiKit.label("MỚI!" if result["new"] else "+%d mảnh" % Heroes.DUPLICATE_SHARDS, 14, UiKit.WARN if result["new"] else UiKit.GOLD_TEXT)))
		"shards":
			column.add_child(_center(UiKit.label("Mảnh tướng", 13, color)))
			var icons := Control.new()
			icons.custom_minimum_size = Vector2(90, 86)
			var portrait := UiKit.hero_portrait(result["id"], 76)
			portrait.position = Vector2(0, 4)
			icons.add_child(portrait)
			var shard := UiKit.shard_icon(result["id"], 40)
			shard.position = Vector2(56, 44)
			shard.size = Vector2(40, 40)
			icons.add_child(shard)
			column.add_child(_center(icons))
			column.add_child(_center(UiKit.label("x%d" % result["count"], 22, UiKit.GOLD_TEXT)))
		_:
			column.add_child(_center(UiKit.label("Vàng", 13, color)))
			column.add_child(_center(UiKit.icon(SpriteLib.texture(UiKit.COIN), 70)))
			column.add_child(_center(UiKit.label(UiKit.format_number(result["amount"]), 22, UiKit.GOLD_TEXT)))
	card.add_child(front)
	_set_face(card, false)
	return card


func _center(control: Control) -> Control:
	control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return control


func _set_face(card: Control, up: bool) -> void:
	card.get_node("Back").visible = not up
	card.get_node("Front").visible = up


func _fx(effect: String, at: Vector2, effect_scale: float, color := Color.WHITE) -> void:
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = SpriteLib.effect_frames(effect)
	fx.position = at
	fx.scale = Vector2(effect_scale, effect_scale)
	fx.modulate = color
	fx.animation_finished.connect(fx.queue_free)
	add_child(fx)
	fx.play("default")


func _shake(strength: float, duration: float) -> void:
	var tween := create_tween()
	var steps := int(duration / 0.04)
	for i in steps:
		var fall := 1.0 - float(i) / steps
		tween.tween_property(self, "position", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * fall, 0.04)
	tween.tween_property(self, "position", Vector2.ZERO, 0.04)


func _clear_extras() -> void:
	for node in _extras:
		if is_instance_valid(node):
			node.queue_free()
	_extras.clear()
