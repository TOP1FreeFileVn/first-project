extends Control

# Full-screen carton summon, showing results already granted by PlayerData.
# The carton acts out each arrival; new and rare troops retain their introduction.
# This layer never rolls, grants, saves or charges. Skip and close only change UI.
signal closed

const Cats = preload("res://game/data/Cats.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const Ui = preload("res://game/ui/Ui.gd")
const Economy = preload("res://game/core/Economy.gd")
const TroopData = preload("res://game/data/TroopData.gd")
const CartonStage = preload("res://game/ui/CartonSummonStage.gd")
const SCREEN := Vector2(720, 1280)
const CARD_SIZE := CartonStage.CARD

var _results: Array = []
var _menu_pattern := false
var _on_again: Callable
var _stage := "carton"
var _time := 0.0
var _closing := false
var _cards: Array = []
var _showcase_queue: Array = []
var _fresh := {}
var _special_until := 0.0
var _motions: Array[Tween] = []
var _extras: Array = []
var _cartons: Control
var _hint: Label
var _status: Label
var _skip: Button
var dim := 0.9


func setup(results: Array, on_again := Callable()) -> void:
	_results = results.duplicate(true)
	_on_again = on_again
	for result in _results:
		if result.get("new", false):
			_fresh[result["id"]] = true
		if (int(result["rarity"]) >= 2 or result.get("new", false)) and not _showcase_queue.has(result["id"]):
			_showcase_queue.append(result["id"])


func attach(host: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	host.add_child(layer)
	# Register before _ready so the first opening frame hides the menu chrome.
	_menu_pattern = Ui.register_menu_surface(host, layer, "summon")
	layer.add_child(self)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.make_theme()
	_cartons = CartonStage.new()
	_cartons.name = "CartonSummonStage"
	_cartons.setup(_results)
	_cartons.finished.connect(_on_cartons_finished)
	add_child(_cartons)
	_cards = _cartons._cards
	_hint = UiKit.label("", 22, UiKit.INFO)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.position = Vector2(0, 1150)
	_hint.size = Vector2(SCREEN.x, 40)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	_status = UiKit.label("GẶP GỠ ĐỒNG ĐỘI", 26, Color("e7d6f6"))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.position = Vector2(40, 236)
	_status.size = Vector2(SCREEN.x - 80, 42)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.visible = false
	add_child(_status)
	_skip = UiKit.button("MỞ TẤT CẢ", Vector2(164, 54), skip)
	_skip.name = "SummonSkipButton"
	_skip.position = Vector2(526, 152)
	_skip.add_theme_font_size_override("font_size", 18)
	add_child(_skip)


func _process(delta: float) -> void:
	_time += delta
	_motions = _motions.filter(func(motion: Tween): return motion.is_valid() and motion.is_running())


func _draw() -> void:
	# A quiet violet veil subdues the shared menu pattern while its surface keeps
	# the same lifetime and context. This leaves the rarity light easy to read.
	draw_rect(Rect2(Vector2(-60, -60), SCREEN + Vector2(120, 120)), Color(0.24, 0.19, 0.31, dim * (0.9 if _menu_pattern else 1.0)))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_on_tap()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _on_tap() -> void:
	if _closing or _time < _special_until:
		return
	if _stage == "showcase":
		_next_showcase()
	# The carton keeps its soft anticipation on background taps. The explicit
	# Open all button remains available throughout, including a legendary hold.


func skip() -> void:
	if _closing or _stage == "done":
		return
	_showcase_queue.clear()
	_cartons.complete()
	_done()


func _on_cartons_finished() -> void:
	if _closing or _stage != "carton":
		return
	_next_showcase()


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
	_cartons.visible = false
	_status.visible = true
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
	if _closing or _stage == "done":
		return
	_stage = "done"
	_stop_motion()
	_clear_extras()
	_cartons.complete()
	_cartons.visible = true
	_cartons.modulate = Color.WHITE
	_skip.visible = false
	_status.visible = false
	_hint.text = ""
	var buttons := UiKit.hbox(18)
	buttons.name = "SummonResultButtons"
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.position = Vector2(0, 1010)
	buttons.size = Vector2(SCREEN.x, 90)
	add_child(buttons)
	var done := UiKit.button("XONG", Vector2(240, 84), _close)
	done.name = "SummonDoneButton"
	buttons.add_child(done)
	if _on_again.is_valid():
		var count := _results.size()
		var cost := PlayerData.summon_cost(count)
		var again := UiKit.button("LẠI x%d\n%s" % [count, "MIỄN PHÍ" if cost == 0 else "◆ %d" % cost], Vector2(260, 84), _again, true)
		again.name = "SummonAgainButton"
		again.disabled = not PlayerData.can_summon(count)
		buttons.add_child(again)


func _again() -> void:
	# A queued second press can arrive before queue_free. Claim this opening
	# synchronously so the caller can pay/grant exactly one new pull.
	if _closing or _stage != "done" or not _on_again.is_valid() or not PlayerData.can_summon(_results.size()):
		return
	var callback := _on_again
	_close()
	callback.call()


func _close() -> void:
	if _closing:
		return
	_closing = true
	set_process(false)
	_cartons.set_process(false)
	_stop_motion()
	for button: Button in find_children("*", "Button", true, false):
		button.disabled = true
	closed.emit()
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()


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
