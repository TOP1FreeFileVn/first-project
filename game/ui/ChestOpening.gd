extends Control

# Full-screen chest opening, gacha style:
#   drop    - the chest falls in, squashes on landing and kicks up dust;
#   wait    - it bobs and rattles, light leaking from the seam in the colour of the best
#             card inside, with a badge counting the cards;
#   open    - on tap it winds up (shaking harder and longer the better the loot, the light
#             turning from white to that colour), then bursts: flash, shockwave, the lid
#             flies off and light pours out;
#   card    - cards shoot out one by one (rarest last). Their halo hints at the rarity
#             before the flip; epic and legendary cards shake first. After the flip a
#             shine sweeps the card, with an extra beat for epic/legendary and new troops;
#   summary - everything received.
# The loot is granted before this plays, so SKIP or closing early never loses anything.
# Tapping hurries the current step; the special beats still show briefly.
#
# Use: var o = ChestOpening.new(); o.setup(...); o.attach(host)

signal closed

const UiKit = preload("res://game/ui/UiKit.gd")
const Ui = preload("res://game/ui/Ui.gd")
const Economy = preload("res://game/core/Economy.gd")
const ChestArt = preload("res://game/ui/ChestArt.gd")
const ChestBurst = preload("res://game/ui/ChestBurst.gd")

const SCREEN := Vector2(720, 1280)
const CHEST_AT := Vector2(360, 760)
const CARD_AT := Vector2(360, 470)
const CARD_SIZE := Vector2(170, 230)
const CARD_SCALE := 1.25
const TRAY_Y := 1110.0
const CHEST_SIZE := 250.0
const RAYS := 12
const SPECIAL_MIN := 0.4
const TOP_BAR_GOLD := Vector2(150, 42)

var _chest_name := ""
var _chest_color := Color("a0673a")
var _style: Dictionary
var _chest_size := CHEST_SIZE
var _loot := {}
var _new_ids: Array = []
var _fast := false
var _menu_pattern := false
var _on_view_troops: Callable

var _stage := "drop"
var _order: Array = []
var _next := 0
var _tween: Tween
var _best := 0
var _time := 0.0
var _special_until := 0.0

# Drawn state, animated by tweens.
var chest_pos := Vector2(360, -260)
var chest_squash := Vector2.ONE
var chest_alpha := 1.0
var charge := 0.0
var lid_offset := Vector2.ZERO
var lid_rotation := 0.0
var lid_alpha := 1.0
var glow := 0.0
var glow_color := Color.WHITE
var mouth := 0.0
var ray_alpha := 0.0
var ray_center := CHEST_AT
var ray_color := Color.WHITE
var dim := 0.0
var flash := 0.0
var ring := 0.0
var ring_center := CHEST_AT
var ring_color := Color.WHITE
var halo := 0.0
var halo_color := Color.WHITE
var sweep := -1.0
var twinkle := 0.0

var _hint: Label
var _skip: Button
var _title: Control
var _chest: Node2D
var _front: Control
var _card: Control
var _extras: Array = []
var _tray: Array = []
var _sparks: CPUParticles2D


## `new_ids` are troops this chest unlocked. `on_view_troops` (optional) adds a button that
## jumps to the troop tab from the summary.
func setup(chest_name: String, chest_color: Color, loot: Dictionary, new_ids: Array, fast := false, on_view_troops := Callable()) -> void:
	_chest_name = chest_name
	_chest_color = chest_color
	_style = ChestArt.style_for(chest_color)
	_chest_size = CHEST_SIZE * (1.2 if _style.get("kind", "wood") == "gold" else 1.0)
	_loot = loot
	_new_ids = new_ids
	_fast = fast
	_on_view_troops = on_view_troops
	var cards: Dictionary = loot.get("cards", {})
	_order = cards.keys()
	# Weakest first, so the best card is the last thing revealed.
	_order.sort_custom(func(a, b): return _rank(a) < _rank(b))
	for id in _order:
		_best = maxi(_best, PlayerData.rarity_of(id))


## Puts the opening on its own layer above everything in `host` and starts it.
func attach(host: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	host.add_child(layer)
	layer.add_child(self)
	_menu_pattern = Ui.register_menu_surface(host, layer, "shop")


func _ready() -> void:
	# It lives on its own CanvasLayer, which does not inherit the lobby's smooth filtering;
	# the SVG skin scaled up for the reveal would look jagged with the project's nearest.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.make_theme()
	ray_color = Economy.RARITY_COLORS[_best]
	glow_color = _best_light()
	_chest = Node2D.new()
	_chest.draw.connect(_draw_chest)
	add_child(_chest)
	_hint = UiKit.label("", 22, UiKit.INFO)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.position = Vector2(0, 1000)
	_hint.size = Vector2(SCREEN.x, 40)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	_title = UiKit.ribbon(_chest_name, 26, UiKit.Ribbon.YELLOW)
	_title.name = "ChestTitle"
	_title.position = Vector2(200, 70)
	_title.custom_minimum_size.x = 320
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_skip = UiKit.button("BỎ QUA ≫", Vector2(170, 64), skip)
	_skip.position = Vector2(530, 150)
	add_child(_skip)
	# Flash, shockwave, card shine and badges draw over everything else.
	_front = Control.new()
	_front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.draw.connect(_draw_front)
	add_child(_front)
	if _fast:
		dim = 0.92
		_show_summary()
		return
	_drop()


func _process(delta: float) -> void:
	_time += delta
	_place_chest()
	if _front.get_index() != get_child_count() - 1:
		move_child(_front, -1)
	queue_redraw()
	_chest.queue_redraw()
	_front.queue_redraw()


# Position, squash and shake of the chest node.
func _place_chest() -> void:
	var offset := Vector2.ZERO
	var tilt := 0.0
	var squash := chest_squash
	if _stage == "wait":
		# Breathing bob, and a little rattle every couple of seconds.
		offset.y = sin(_time * 3.0) * 6.0
		squash *= Vector2(1.0 + 0.025 * sin(_time * 6.0), 1.0 - 0.025 * sin(_time * 6.0))
		var phase := fmod(_time, 1.8)
		if phase < 0.35:
			tilt = sin(phase * 45.0) * 0.06 * (1.0 - phase / 0.35)
	if charge > 0.0:
		tilt += sin(_time * 55.0) * 0.07 * charge
		offset += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 5.0 * charge
	_chest.position = chest_pos + offset
	_chest.rotation = tilt
	_chest.scale = squash
	_chest.visible = chest_alpha > 0.0


func _gui_input(event: InputEvent) -> void:
	# Touches also arrive as emulated mouse clicks, so only the mouse event counts.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_on_tap()


func _on_tap() -> void:
	match _stage:
		"wait":
			_open()
		"drop", "open", "card":
			if _time < _special_until:
				return
			if _tween != null and _tween.is_valid():
				_tween.custom_step(60.0)


## Jumps straight to the summary.
func skip() -> void:
	if _stage == "summary":
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_show_summary()


# --- Stages -------------------------------------------------------------------------------

func _drop() -> void:
	_stage = "drop"
	_tween = create_tween()
	_tween.tween_property(self, "dim", 0.92, 0.25)
	_tween.tween_property(self, "chest_pos", CHEST_AT, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func():
		SoundLib.play("thud", 0.0, 0.0)
		_fx("dust", CHEST_AT + Vector2(-_chest_size * 0.44, _chest_size * 0.44), 2.4)
		_fx("dust", CHEST_AT + Vector2(_chest_size * 0.44, _chest_size * 0.44), 2.4)
		_shake(9.0, 0.25))
	# Squash on landing, stretch back up, settle.
	_tween.tween_property(self, "chest_squash", Vector2(1.3, 0.7), 0.07)
	_tween.tween_property(self, "chest_squash", Vector2(0.88, 1.14), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "chest_squash", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_wait)


func _wait() -> void:
	_stage = "wait"
	_hint.text = "Chạm để mở"
	_tween = create_tween().set_loops()
	_tween.tween_property(self, "glow", 1.0, 0.5)
	_tween.tween_property(self, "glow", 0.35, 0.5)
	if _best >= Economy.Rarity.EPIC:
		_sparks = _particles(null, ray_color, 18, 1.0)
		_sparks.position = CHEST_AT + Vector2(0, -20)
		_sparks.one_shot = false
		_sparks.explosiveness = 0.0
		_sparks.initial_velocity_min = 90
		_sparks.initial_velocity_max = 180
		_sparks.gravity = Vector2(0, 120)
		_sparks.emitting = true


func _open() -> void:
	_stage = "open"
	_hint.text = ""
	if _sparks != null:
		_sparks.emitting = false
	_tween.kill()
	# The better the loot, the longer and harder the wind-up. For epic and up the light
	# starts white and only turns to the rarity colour as the chest is about to burst.
	var windup: float = [0.35, 0.45, 0.65, 0.85][_best]
	var reveal := _best_light()
	if _best >= Economy.Rarity.EPIC:
		glow_color = Color.WHITE
	_tween = create_tween()
	_tween.set_parallel()
	_tween.tween_property(self, "charge", 1.0, windup).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "chest_squash", Vector2(1.14, 0.84), windup)
	_tween.tween_property(self, "glow", 1.8, windup)
	_tween.tween_property(self, "glow_color", reveal, windup).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	SoundLib.play("charge", -4.0, 0.0)
	_tween.chain().tween_callback(_burst)
	_tween.tween_property(self, "chest_squash", Vector2(0.86, 1.18), 0.08)
	_tween.tween_property(self, "lid_offset", Vector2(110, -420), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "lid_rotation", 1.8, 0.6)
	_tween.tween_property(self, "lid_alpha", 0.0, 0.5).set_delay(0.25)
	_tween.tween_property(self, "ray_alpha", 1.0, 0.35)
	_tween.tween_property(self, "mouth", 1.0, 0.2)
	_tween.chain().tween_property(self, "chest_squash", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_callback(_next_card)


func _burst() -> void:
	SoundLib.play("chest_open", 0.0, 0.0)
	charge = 0.0
	glow = 1.0
	ray_center = CHEST_AT + Vector2(0, -40)
	_flash(0.9 if _best >= Economy.Rarity.EPIC else 0.6)
	_ring(CHEST_AT, ray_color)
	_fx("blast", CHEST_AT + Vector2(0, -50), 1.5, ray_color.lightened(0.3))
	_shake(14.0 if _best >= Economy.Rarity.EPIC else 7.0, 0.35)
	var stars := _particles(null, _best_light(), 36, 1.0)
	stars.position = CHEST_AT
	stars.spread = 70.0
	stars.initial_velocity_min = 350.0
	stars.initial_velocity_max = 700.0
	stars.gravity = Vector2(0, 900)
	if _loot.get("gold", 0) > 0:
		_coins()


func _next_card() -> void:
	_clear_extras()
	if _next >= _order.size():
		_show_summary()
		return
	_stage = "card"
	_hint.text = "Chạm để lật nhanh"
	var id: String = _order[_next]
	_next += 1
	var rarity := PlayerData.rarity_of(id)
	var special := rarity >= Economy.Rarity.EPIC or _new_ids.has(id)
	_card = _make_card(id, _loot["cards"][id], true)
	_card.position = CHEST_AT - CARD_SIZE / 2.0
	_card.scale = Vector2(0.2, 0.2)
	_card.rotation = -0.6
	_set_face(_card, false)
	add_child(_card)
	move_child(_card, _hint.get_index())
	# The halo behind the card back already hints at the rarity.
	ray_color = Economy.RARITY_COLORS[rarity]
	halo_color = ray_color
	halo = 0.0
	sweep = -1.0
	_fx("dust", CHEST_AT + Vector2(0, -20), 1.4, Color(_best_light(), 0.8))

	_tween = create_tween()
	_tween.set_parallel()
	_tween.tween_property(_card, "position", CARD_AT - CARD_SIZE / 2.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_card, "scale", Vector2(CARD_SCALE, CARD_SCALE), 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_card, "rotation", 0.0, 0.34)
	_tween.tween_property(self, "ray_center", CARD_AT, 0.3)
	_tween.tween_property(self, "halo", 0.6 if rarity < Economy.Rarity.EPIC else 0.8, 0.3)
	if rarity >= Economy.Rarity.EPIC:
		# Tease: the face-down card trembles while its halo swells.
		var shakes := 6 if rarity >= Economy.Rarity.LEGENDARY else 4
		for i in shakes:
			_tween.chain().tween_property(_card, "rotation", 0.09 * (1 if i % 2 == 0 else -1), 0.06)
		_tween.chain().tween_property(_card, "rotation", 0.0, 0.05)
		_tween.parallel().tween_property(self, "halo", 1.4, 0.05)
	_tween.chain().tween_property(_card, "scale:x", 0.0, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(func():
		SoundLib.play("flip")
		_set_face(_card, true)
		if rarity >= Economy.Rarity.RARE:
			_flash(0.5 if rarity >= Economy.Rarity.EPIC else 0.25))
	_tween.chain().tween_property(_card, "scale:x", CARD_SCALE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_callback(_hold.bind(id, rarity, special))


# Second half of a card, in its own tween so a tap that hurries the flip still lands on
# the special beat instead of skipping past it.
func _hold(id: String, rarity: int, special: bool) -> void:
	if special:
		_special(id, rarity)
	var shine := create_tween()
	sweep = 0.0
	shine.tween_property(self, "sweep", 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shine.tween_callback(func(): sweep = -1.0)
	_tween = create_tween()
	_tween.tween_interval(1.2 if special else 0.55)
	_tween.tween_callback(_to_tray)
	_tween.tween_interval(0.05)
	_tween.tween_callback(_next_card)


# Epic / legendary / new troop: banner, shake, burst; guaranteed to stay SPECIAL_MIN seconds.
func _special(id: String, rarity: int) -> void:
	_special_until = _time + SPECIAL_MIN
	SoundLib.play("legend" if rarity >= Economy.Rarity.LEGENDARY else ("epic" if rarity >= Economy.Rarity.EPIC else "rare"), 0.0, 0.0)
	var text := ""
	if rarity >= Economy.Rarity.LEGENDARY:
		text = "HUYỀN THOẠI!"
	elif rarity >= Economy.Rarity.EPIC:
		text = "SỬ THI!"
	if _new_ids.has(id):
		text = ("MỚI! " + text).strip_edges()
	var banner := UiKit.label(text, 50, Economy.RARITY_COLORS[rarity] if rarity >= Economy.Rarity.EPIC else UiKit.WARN)
	banner.add_theme_constant_override("outline_size", 12)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position = Vector2(0, 250)
	banner.size = Vector2(SCREEN.x, 64)
	banner.pivot_offset = banner.size / 2.0
	banner.scale = Vector2(2.2, 2.2)
	banner.modulate.a = 0.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	_extras.append(banner)
	# Slams down onto the card, then keeps a gentle pulse.
	var slam := banner.create_tween()
	slam.set_parallel()
	slam.tween_property(banner, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slam.tween_property(banner, "modulate:a", 1.0, 0.12)
	slam.chain().tween_property(banner, "scale", Vector2(1.06, 1.06), 0.35).set_trans(Tween.TRANS_SINE)
	slam.chain().tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)
	if rarity >= Economy.Rarity.EPIC:
		var legendary := rarity >= Economy.Rarity.LEGENDARY
		_shake(12.0 if legendary else 7.0, 0.35)
		_ring(CARD_AT, Economy.RARITY_COLORS[rarity])
		_fx("blast", CARD_AT, 2.0, Economy.RARITY_COLORS[rarity].lightened(0.3), true)
		var burst := _particles(null, Economy.RARITY_COLORS[rarity], 50, 1.2)
		burst.position = CARD_AT
		move_child(burst, _card.get_index())
		_extras.append(burst)
		twinkle = 1.0
		var fade := create_tween()
		fade.tween_interval(1.0)
		fade.tween_property(self, "twinkle", 0.0, 0.3)
		if legendary:
			# Golden rain over the whole screen.
			var rain := _particles(null, Color("ffd76a"), 70, 1.6)
			rain.position = Vector2(SCREEN.x / 2.0, -20)
			rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			rain.emission_rect_extents = Vector2(SCREEN.x / 2.0, 10)
			rain.explosiveness = 0.6
			rain.direction = Vector2(0, 1)
			rain.spread = 15.0
			rain.initial_velocity_min = 150.0
			rain.initial_velocity_max = 320.0
			rain.gravity = Vector2(0, 250)
			rain.scale_amount_min = 3.0
			rain.scale_amount_max = 7.0
			_extras.append(rain)
	if _new_ids.has(id):
		# The new recruit runs in and stands next to its card.
		var troop: Resource = PlayerData.TROOPS[id]
		var runner := AnimatedSprite2D.new()
		runner.sprite_frames = SpriteLib.unit_frames(troop.unit_key, "Blue")
		runner.offset = Vector2(0, -SpriteLib.foot_offset(troop.unit_key))
		runner.modulate = troop.tint
		runner.scale = Vector2(0.9, 0.9) * troop.sprite_scale
		runner.position = Vector2(-80, CARD_AT.y + 230)
		runner.play("run")
		add_child(runner)
		_extras.append(runner)
		var run := runner.create_tween()
		run.tween_property(runner, "position:x", CARD_AT.x - 190, 0.5)
		run.tween_callback(func(): runner.play("idle"))


func _to_tray() -> void:
	var card := _card
	_card = null
	halo = 0.0
	sweep = -1.0
	_tray.append(card)
	var step := minf(96.0, 620.0 / maxf(_order.size(), 1))
	var x: float = SCREEN.x / 2.0 - step * (_order.size() - 1) / 2.0 + step * (_tray.size() - 1)
	var tween := card.create_tween().set_parallel()
	tween.tween_property(card, "scale", Vector2(0.45, 0.45), 0.22)
	tween.tween_property(card, "position", Vector2(x, TRAY_Y) - CARD_SIZE / 2.0, 0.22)


func _show_summary() -> void:
	_stage = "summary"
	_clear_extras()
	if _sparks != null:
		_sparks.queue_free()
		_sparks = null
	for card in _tray:
		card.queue_free()
	_tray.clear()
	if _card != null:
		_card.queue_free()
		_card = null
	_skip.visible = false
	_hint.text = ""
	chest_alpha = 0.0
	charge = 0.0
	halo = 0.0
	sweep = -1.0
	twinkle = 0.0
	ray_color = Economy.RARITY_COLORS[_best]
	var fade := create_tween()
	fade.tween_property(self, "ray_alpha", 0.45, 0.3)
	fade.parallel().tween_property(self, "dim", 0.92, 0.3)

	# Centre the whole result, including its title and actions. A short reward list
	# should read as one celebration rather than a tiny row stranded at the top.
	var host := CenterContainer.new()
	host.name = "ChestSummaryHost"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.offset_left = 30
	host.offset_right = -30
	host.offset_top = 70
	host.offset_bottom = -70
	var box := UiKit.vbox(20)
	box.name = "ChestSummary"
	box.custom_minimum_size.x = SCREEN.x - 60
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(box)
	_title.reparent(box)
	var heading := UiKit.label("Nhận được", 36, UiKit.GOLD_TEXT)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(heading)
	# Only the rewards scroll when the list is long; actions stay visible below it.
	var scroll := ScrollContainer.new()
	scroll.name = "ChestSummaryScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	box.add_child(scroll)
	var rewards := UiKit.vbox(18)
	rewards.name = "ChestSummaryRewards"
	rewards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(rewards)
	var grid := GridContainer.new()
	grid.name = "ChestRewardGrid"
	grid.columns = clampi(_order.size(), 1, 4)
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Leave room for the "Mới" tags above the card silhouettes.
	if not _order.is_empty():
		rewards.add_child(UiKit.gap(0, 14))
		rewards.add_child(grid)
	else:
		grid.free()
		grid = null
	var ordered := _order.duplicate()
	ordered.reverse()
	var small := 1.12 if _order.size() <= 3 else 0.86
	var delay := 0.0
	for id in ordered:
		var holder := Control.new()
		holder.name = "Reward_" + id
		holder.custom_minimum_size = CARD_SIZE * small
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(holder)
		var card := _make_card(id, _loot["cards"][id], true)
		card.scale = Vector2(small, small) * 0.2
		card.pivot_offset = Vector2.ZERO
		holder.add_child(card)
		card.create_tween().tween_property(card, "scale", Vector2(small, small), 0.22).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.05
	if _loot.get("gold", 0) > 0:
		var gold := UiKit.price("gold", _loot["gold"], 28)
		gold.name = "ChestSummaryGold"
		rewards.add_child(gold)
	if not _new_ids.is_empty():
		var names := []
		for id in _new_ids:
			names.append(PlayerData.TROOPS[id].display_name)
		var fresh := UiKit.label("Lính mới: " + ", ".join(names), 20, UiKit.WARN)
		fresh.name = "ChestSummaryFresh"
		fresh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fresh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fresh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rewards.add_child(fresh)
	var buttons := UiKit.hbox(14)
	buttons.name = "ChestSummaryButtons"
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _on_view_troops.is_valid():
		var view := UiKit.button("XEM LÍNH", Vector2(250, 88), func():
			_close()
			_on_view_troops.call(), true)
		view.name = "ChestViewTroopsButton"
		buttons.add_child(view)
	var done := UiKit.button("XONG", Vector2(250, 88), _close)
	done.name = "ChestDoneButton"
	buttons.add_child(done)
	box.add_child(buttons)
	var fit := func():
		var fixed_height := _title.get_combined_minimum_size().y + heading.get_combined_minimum_size().y + buttons.get_combined_minimum_size().y + 60.0
		var available := maxf(0.0, host.size.y - fixed_height)
		var height := minf(rewards.get_combined_minimum_size().y, available)
		if not is_equal_approx(scroll.custom_minimum_size.y, height):
			scroll.custom_minimum_size.y = height
	host.resized.connect(fit)
	rewards.minimum_size_changed.connect(fit)
	fit.call_deferred()
	# Keep the celebration centred on the visible cards, also after container sorting.
	var sync_light := func():
		var focus: Control = grid if is_instance_valid(grid) else rewards
		var visible_rewards := focus.get_global_rect().intersection(scroll.get_global_rect())
		ray_center = visible_rewards.get_center() - global_position
	box.item_rect_changed.connect(sync_light)
	scroll.item_rect_changed.connect(sync_light)
	rewards.item_rect_changed.connect(sync_light)
	if is_instance_valid(grid):
		grid.item_rect_changed.connect(sync_light)


func _close() -> void:
	closed.emit()
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()


# --- Drawing ------------------------------------------------------------------------------

# Background: the dim, two layers of turning rays and a soft glow, plus the card's halo.
func _draw() -> void:
	draw_rect(Rect2(Vector2(-60, -60), SCREEN + Vector2(120, 120)), Color(0.02, 0.03, 0.05, dim * (0.5 if _menu_pattern else 1.0)))
	if ray_alpha > 0.0:
		for i in RAYS:
			var angle := _time * 0.35 + i * TAU / RAYS
			_ray(ray_center, angle, 0.13, Color(ray_color, 0.11 * ray_alpha))
		for i in RAYS:
			var angle := -_time * 0.6 + (i + 0.5) * TAU / RAYS
			_ray(ray_center, angle, 0.04, Color(ray_color.lightened(0.4), 0.12 * ray_alpha))
		_soft_glow(ray_center, 220.0, ray_color, 0.2 * ray_alpha)
	if halo > 0.0 and _card != null:
		var pulse := 1.0 + 0.06 * sin(_time * 9.0)
		_soft_glow(_card_center(), 190.0 * halo * pulse, halo_color, 0.5 * minf(halo, 1.0))


func _ray(from: Vector2, angle: float, half_width: float, color: Color) -> void:
	var a := from + Vector2.from_angle(angle - half_width) * 1000.0
	var b := from + Vector2.from_angle(angle + half_width) * 1000.0
	draw_colored_polygon(PackedVector2Array([from, a, b]), color)


func _soft_glow(at: Vector2, radius: float, color: Color, alpha: float) -> void:
	for i in 5:
		var f := 1.0 - i * 0.18
		draw_circle(at, radius * f, Color(color.lightened(i * 0.12), alpha * 0.35))


func _draw_chest() -> void:
	var w := _chest_size
	var light := glow_color
	var closed := lid_alpha > 0.5 and lid_offset == Vector2.ZERO
	# Once the lid is off, a beam pours out behind the cards.
	if mouth > 0.0:
		var beam := PackedVector2Array([Vector2(-w * 0.44, 0), Vector2(w * 0.44, 0), Vector2(w * 1.0, -620), Vector2(-w * 1.0, -620)])
		_chest.draw_colored_polygon(beam, Color(light, 0.2 * mouth * chest_alpha))
		var core := PackedVector2Array([Vector2(-w * 0.25, 0), Vector2(w * 0.25, 0), Vector2(w * 0.45, -620), Vector2(-w * 0.45, -620)])
		_chest.draw_colored_polygon(core, Color(light.lightened(0.5), 0.14 * mouth * chest_alpha))
	# The closed rays rise behind the prop, keeping the latch and its contour intact.
	if glow > 0.0 and closed:
		var bright := minf(glow, 1.0)
		for i in 7:
			var x := (i - 3) * w * 0.16
			var reach := w * 0.34 + 60.0 * glow * (1.0 - absf(i - 3) * 0.2)
			var tip := Vector2(x * 1.7, -reach)
			_chest.draw_colored_polygon(PackedVector2Array([Vector2(x - 8, 0), Vector2(x + 8, 0), tip]), Color(light, 0.26 * bright * chest_alpha))
	ChestArt.draw(_chest, Vector2.ZERO, w, _style, chest_alpha, lid_offset, lid_rotation, lid_alpha,
		Color(light, mouth) if mouth > 0.0 else Color(0, 0, 0, 0))
	if glow > 0.0 and closed:
		# Light escapes along the seam on either side of the foreground cat latch.
		var latch_width := 44.0 if _style.get("kind", "wood") == "gold" else 32.0
		var latch_clearance := w * latch_width / ChestArt.AUTHOR_WIDTH
		var leak := Color(light.lightened(0.3), 0.95 * minf(glow, 1.0) * chest_alpha)
		for side in [-1.0, 1.0]:
			var x := -w * 0.5 if side < 0.0 else latch_clearance
			_chest.draw_rect(Rect2(Vector2(x, -3.0), Vector2(w * 0.5 - latch_clearance, 6.0)), leak)


# Over everything: shockwave ring, card shine, sparkles, the cards-left badge and the flash.
func _draw_front() -> void:
	if ring > 0.0 and ring < 1.0:
		var r := lerpf(40.0, 620.0, ring)
		var fade := 1.0 - ring
		_front.draw_arc(ring_center, r, 0.0, TAU, 64, Color(ring_color.lightened(0.5), 0.8 * fade), 26.0 * fade + 2.0, true)
		_front.draw_arc(ring_center, r * 0.8, 0.0, TAU, 64, Color(Color.WHITE, 0.4 * fade), 8.0 * fade + 1.0, true)
	if _card != null and sweep >= 0.0 and _card.get_node("Front").visible:
		_draw_sweep()
	if twinkle > 0.0 and _card != null:
		var center := _card_center()
		for i in 8:
			var angle := _time * 1.4 + i * TAU / 8.0
			var at := center + Vector2(cos(angle) * 150.0, sin(angle) * 185.0)
			var radius := 9.0 + 5.0 * sin(_time * 8.0 + i * 1.7)
			_star(at, radius, Color(halo_color.lightened(0.6), twinkle))
	elif _stage == "wait" and _best >= Economy.Rarity.EPIC:
		for i in 5:
			var t := fmod(_time * 0.8 + i * 0.37, 1.0)
			var at := CHEST_AT + Vector2(cos(i * 2.4) * 150.0, -60.0 + sin(i * 1.3) * 60.0)
			_star(at, 10.0 * sin(t * PI), Color(_best_light(), sin(t * PI)))
	var left := _order.size() - _next
	if chest_alpha > 0.0 and left > 0 and _stage in ["wait", "open", "card"]:
		var at := _chest.position + Vector2(_chest_size * 0.44, -_chest_size * 0.3)
		_front.draw_circle(at, 30.0, Color("24170e"))
		_front.draw_circle(at, 26.0, Color("e0405a"))
		var font := UiKit.game_font()
		var text := str(left)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		_front.draw_string_outline(font, at + Vector2(-width / 2.0, 11), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, Color("24170e"))
		_front.draw_string(font, at + Vector2(-width / 2.0, 11), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
	if flash > 0.0:
		_front.draw_rect(Rect2(Vector2(-60, -60), SCREEN + Vector2(120, 120)), Color(1, 1, 0.95, flash))


# A diagonal band of light crossing the face-up card, clipped to the card.
func _draw_sweep() -> void:
	var center := _card_center()
	var half := CARD_SIZE * absf(_card.scale.y) / 2.0
	var rect := PackedVector2Array([center - half, center + Vector2(half.x, -half.y), center + half, center + Vector2(-half.x, half.y)])
	var x := lerpf(-half.x - 120.0, half.x + 120.0, sweep)
	var band := PackedVector2Array([
		center + Vector2(x - 30, -half.y), center + Vector2(x + 30, -half.y),
		center + Vector2(x - 50, half.y), center + Vector2(x - 110, half.y)])
	for piece in Geometry2D.intersect_polygons(band, rect):
		_front.draw_colored_polygon(piece, Color(1, 1, 1, 0.35))


func _star(at: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.5:
		return
	var thin := radius * 0.28
	_front.draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, -radius), at + Vector2(thin, -thin), at + Vector2(radius, 0), at + Vector2(thin, thin),
		at + Vector2(0, radius), at + Vector2(-thin, thin), at + Vector2(-radius, 0), at + Vector2(-thin, -thin)]), color)


func _card_center() -> Vector2:
	return _card.position + _card.pivot_offset


func _best_light() -> Color:
	return Economy.RARITY_COLORS[_best].lightened(0.45)


# --- Pieces -------------------------------------------------------------------------------

## A card with a back (question mark) and a front (portrait, name, count, star progress).
func _make_card(id: String, count: int, face_up: bool) -> Control:
	var troop: Resource = PlayerData.TROOPS[id]
	var rarity: int = troop.rarity
	var card := Control.new()
	card.size = CARD_SIZE
	card.pivot_offset = CARD_SIZE / 2.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	card.add_child(UiKit.card_back_face(CARD_SIZE))

	var front := PanelContainer.new()
	front.name = "Front"
	front.add_theme_stylebox_override("panel", UiKit.rarity_card(rarity))
	front.size = CARD_SIZE
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := UiKit.vbox(2)
	front.add_child(column)
	var rarity_label := UiKit.label(Economy.RARITY_NAMES[rarity], 15)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(rarity_label)
	var portrait := UiKit.troop_portrait(troop, 100)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(portrait)
	var name_label := UiKit.label(troop.display_name, 19)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	var count_label := UiKit.label("x%d" % count, 24)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(count_label)
	var t: Dictionary = PlayerData.troop(id)
	var need := PlayerData.star_up_cost(id)
	var bar := UiKit.bar(Color("7fd66b") if need > 0 and t["cards"] >= need else Color("5aa9e6"), Vector2(140, 10))
	bar.max_value = maxi(need, 1)
	bar.value = t["cards"] if need > 0 else bar.max_value
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(bar)
	card.add_child(front)
	if _new_ids.has(id):
		var badge := UiKit.tag("Mới")
		badge.position = Vector2(CARD_SIZE.x - 58, -12)
		card.add_child(badge)
	_set_face(card, face_up)
	return card


func _set_face(card: Control, up: bool) -> void:
	card.get_node("Back").visible = not up
	card.get_node("Front").visible = up
	for child in card.get_children():
		if child is Label:
			child.visible = up


## `behind` puts the effect under the current card so it frames it instead of covering it.
func _fx(effect: String, at: Vector2, effect_scale: float, color := Color.WHITE, behind := false) -> void:
	var fx := ChestBurst.new()
	fx.setup(effect, color)
	fx.position = at
	fx.scale = Vector2(effect_scale, effect_scale)
	add_child(fx)
	if behind and _card != null:
		move_child(fx, _card.get_index())


func _flash(strength: float) -> void:
	flash = strength
	create_tween().tween_property(self, "flash", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _ring(at: Vector2, color: Color) -> void:
	ring_center = at
	ring_color = color
	ring = 0.001
	create_tween().tween_property(self, "ring", 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _particles(texture: Texture2D, color: Color, amount: int, lifetime: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = texture
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 220.0
	p.initial_velocity_max = 480.0
	p.gravity = Vector2(0, 500)
	p.scale_amount_min = 4.0 if texture == null else 0.35
	p.scale_amount_max = 8.0 if texture == null else 0.55
	p.color = color
	var fade := Gradient.new()
	fade.set_color(0, color)
	fade.set_color(1, Color(color, 0.0))
	p.color_ramp = fade
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


# Coins burst out of the chest, then a handful fly to the gold counter.
func _coins() -> void:
	SoundLib.play("coin")
	var burst := _particles(UiKit.coin_texture(128), Color.WHITE, 26, 1.1)
	burst.position = CHEST_AT + Vector2(0, -50)
	burst.spread = 60.0
	burst.initial_velocity_min = 450.0
	burst.initial_velocity_max = 750.0
	burst.gravity = Vector2(0, 1300)
	burst.color_ramp = null
	for i in 6:
		var coin := UiKit.icon(UiKit.coin_texture(128), 34)
		coin.position = CHEST_AT + Vector2(randf_range(-50, 50), -60)
		add_child(coin)
		var fly := coin.create_tween()
		fly.tween_interval(0.25 + i * 0.06)
		fly.tween_property(coin, "position", TOP_BAR_GOLD, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fly.tween_callback(coin.queue_free)


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


func _rank(id: String) -> int:
	return PlayerData.rarity_of(id) * 10 + (5 if _new_ids.has(id) else 0)
