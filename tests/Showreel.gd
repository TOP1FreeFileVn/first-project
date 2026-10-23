extends Node

# A scripted gameplay video: the lobby (level select swipes, heroes, a gold chest, a x10
# hero summon), then a real battle on level 13, ending on the victory dance and the
# result panel. The battle is played like a person would, so it reads on video: a finger
# pointer travels to each target, taps shop cards, and drags gears slowly from cell to
# cell (through the board's real drag/drop code). Shop turns run at normal speed; only
# the fights are fast-forwarded. Purchase choices come from the balance bot.
# Record: Godot --path . --write-movie C:/out.avi --fixed-fps 30 --resolution 720x1280 res://tests/Showreel.tscn

const Bot = preload("res://game/admin/Bot.gd")
const LEVEL := 13
const FIGHT_SPEED := 3.0
const END_HOLD := 8.0
## Seconds (video time) the finger takes to reach a target, a drag takes, and the pause
## after each action.
const TRAVEL := 0.35
const DRAG_TIME := 0.9
const PAUSE := 0.35

var _home
var _battle
var _t := 0.0
var _events: Array = []
var _stage := "lobby"
var _won_at := -1.0
var _coach_closed := false
# The on-screen finger and the action in progress.
var _pointer: Control
var _finger := Vector2(560, 1000)
var _pressed := 0.0
var _busy := 0.0
var _drag_gear = null
var _drag_from := Vector2i.ZERO
var _drag_to := Vector2i.ZERO
var _drag_t := -1.0
var _next_action := Callable()


func _ready() -> void:
	# Record at the game's full size, not the smaller editor window.
	get_window().size = Vector2i(720, 1280)
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.player_name = "Cường Quốc"
	PlayerData.gold = 25000
	PlayerData.gems = 3000
	PlayerData.castle_level = 6
	PlayerData.unlocked_levels = PlayerData.LEVELS.size()
	for i in 12:
		PlayerData.level_stars[i] = 3 if i % 3 != 1 else 2
	for id in PlayerData.TROOP_ORDER:
		PlayerData.troops[id]["unlocked"] = true
		PlayerData.troops[id]["level"] = 12
		PlayerData.troops[id]["stars"] = 2
	PlayerData.team = PlayerData.auto_team()
	PlayerData.forge_stones = 240
	PlayerData.frame = "royal"
	_home = load("res://game/menu/Home.tscn").instantiate()
	add_child(_home)
	_hide_admin(_home)
	_home.select_tab(2, false)
	var page = _home._pages[2]
	# Start on level 15 and swipe back to 13.
	_events = [
		[1.8, func(): page._go(-1)],
		[3.4, func(): page._go(-1)],
		[5.2, func(): _home.select_tab(4)],
		[7.8, func(): _home.select_tab(0)],
		[9.0, func(): _home._pages[0]._open("gold")],
		[10.6, func(): _chest_tap()],
		[15.5, func(): _opening().skip()],
		[17.5, func(): _close_opening()],
		[18.0, func(): _home.open_page(_home.SummonPage)],
		[19.6, func(): _home._overlay_page._summon(10)],
		[25.5, func(): _opening().skip()],
		[27.5, func(): _close_opening()],
		[28.0, _start_battle],
	]


func _process(delta: float) -> void:
	# Video time, whatever the game speed.
	_t += delta / Engine.time_scale
	while not _events.is_empty() and _t >= _events[0][0]:
		var event: Array = _events.pop_front()
		event[1].call()
	if _stage != "battle":
		return
	_play_like_a_person(delta / Engine.time_scale)
	# Let the new-cell card show for a moment, then close it and play.
	if not _coach_closed and _t > _battle_start + 3.0:
		_coach_closed = true
		for child in _battle.hud._root.get_children():
			if child.has_method("_advance"):
				child._advance()
	Engine.time_scale = FIGHT_SPEED if _battle.phase == "fight" and _drag_gear == null else 1.0
	if (_battle.phase == "won" or _battle.phase == "lost") and _won_at < 0.0:
		_won_at = _t
		Engine.time_scale = 1.0
	if _won_at >= 0.0:
		Engine.time_scale = 1.0
		if _t > _won_at + END_HOLD:
			print("SHOWREEL done: %s at %.1fs of video" % [_battle.phase, _t])
			get_tree().quit()


var _battle_start := 0.0


func _start_battle() -> void:
	_home.queue_free()
	PlayerData.select_level(LEVEL - 1)
	_battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(_battle)
	_battle_start = _t
	_stage = "battle"
	_busy = 3.5
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_pointer = Control.new()
	_pointer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.draw.connect(_draw_pointer)
	layer.add_child(_pointer)


# --- Playing like a person ------------------------------------------------------------

func _play_like_a_person(dt: float) -> void:
	_pressed = maxf(0.0, _pressed - dt)
	_pointer.queue_redraw()
	if _drag_t >= 0.0:
		_drag_t += dt / DRAG_TIME
		var board = _battle.board
		var k := smoothstep(0.0, 1.0, minf(_drag_t, 1.0))
		_drag_gear.position = board.cell_center(_drag_from).lerp(board.cell_center(_drag_to), k)
		_finger = _screen(_drag_gear.position)
		_pressed = 1.0
		if _drag_t >= 1.0:
			_drag_t = -1.0
			board._drop(_drag_to)
			_drag_gear = null
			_busy = PAUSE
		return
	if _busy > 0.0:
		_busy -= dt
		if _busy <= 0.0 and _next_action.is_valid():
			var action := _next_action
			_next_action = Callable()
			action.call()
		return
	if not _battle.accepts_input() or not _coach_closed:
		return
	var board = _battle.board
	# Merges and reconnecting stranded gears, like the balance bot, but dragged slowly.
	for a in board.gears.values():
		for b in board.gears.values():
			if board.can_merge(a, b):
				_travel_then(_screen(board.cell_center(a.cell)), _begin_drag.bind(a, b.cell))
				return
	for a in board.gears.values():
		if a.powered:
			continue
		for y in board.ROWS:
			for x in board.COLS:
				var cell := Vector2i(x, y)
				if board.is_placeable(cell) and not board.gears.has(cell) and board._would_turn(cell) and board.tile(cell) != "rust":
					_travel_then(_screen(board.cell_center(a.cell)), _begin_drag.bind(a, cell))
					return
	if _battle.phase != "shop":
		return
	var reserve := Bot.SAVINGS if _battle.wave_number() >= 3 else 0
	var slot := Bot._best_offer(_battle, reserve)
	if slot >= 0 and slot < _battle.hud._cards.size():
		_travel_then(_battle.hud._cards[slot].get_global_rect().get_center(), func():
			_pressed = 1.0
			_battle.buy(slot)
			_busy = PAUSE)
		return
	var ready: Button = _battle.hud._ready_button
	_travel_then(ready.get_global_rect().get_center(), func():
		_pressed = 1.0
		_battle.start_wave()
		_busy = PAUSE)


# Moves the finger to a point, then runs the action.
func _travel_then(target: Vector2, action: Callable) -> void:
	var tween := create_tween()
	tween.tween_property(self, "_finger", target, TRAVEL * Engine.time_scale).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_busy = TRAVEL + 0.12
	_next_action = action


func _begin_drag(gear, to: Vector2i) -> void:
	if not is_instance_valid(gear) or not _battle.board.gears.values().has(gear):
		return
	var board = _battle.board
	board._drag = gear
	board._drag_from = gear.cell
	gear.z_index = 20
	_drag_gear = gear
	_drag_from = gear.cell
	_drag_to = to
	_drag_t = 0.0
	SoundLib.play("click")


func _screen(local: Vector2) -> Vector2:
	return _battle.board.get_global_transform_with_canvas() * local


# A round fingertip with a soft shadow; it shrinks and rings while pressing.
func _draw_pointer() -> void:
	var r := 20.0 - 4.0 * _pressed
	_pointer.draw_circle(_finger + Vector2(4, 6), r, Color(0, 0, 0, 0.25))
	_pointer.draw_circle(_finger, r + 3.0, Color(0.15, 0.1, 0.05, 0.9))
	_pointer.draw_circle(_finger, r, Color(1, 1, 1, 0.92))
	if _pressed > 0.0:
		_pointer.draw_arc(_finger, 34.0 - 10.0 * _pressed, 0.0, TAU, 32, Color(1.0, 0.85, 0.3, _pressed), 4.0, true)


func _opening():
	for layer in _home.get_children():
		if layer is CanvasLayer and layer.get_child_count() > 0 and layer.get_child(0).has_method("skip"):
			return layer.get_child(0)
	return null


func _chest_tap() -> void:
	var opening = _opening()
	if opening != null:
		opening._on_tap()


func _close_opening() -> void:
	var opening = _opening()
	if opening != null:
		opening.get_parent().queue_free()


# The debug-only ADMIN button has no place in a gameplay video.
func _hide_admin(node: Node) -> void:
	for child in node.get_children():
		if child is Button and child.text == "ADMIN":
			child.visible = false
		_hide_admin(child)
