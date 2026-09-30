extends Control

# In-battle guidance, drawn over the HUD without blocking the game:
#  - the first-battle tutorial (level 1, until finished or skipped): buy a gear, see that
#    only gears touching the drive turn and spawn, merge two gears, press READY, then the
#    wave's income and interest;
#  - a "new cell!" card the first time a level has a kind of special board cell, with the
#    rule, while those cells pulse on the board.
# A pulsing ring and a bouncing arrow point at what the current step is about.

const UiKit = preload("res://game/ui/UiKit.gd")
const GearBoard = preload("res://game/battle/GearBoard.gd")
## The card sits in the gap between the shop and the gear grid.
const CARD_Y := 596.0
## Room on the card's left for tile samples.
const SAMPLE_PAD := 120.0

var battle
var hud

var _step := ""
var _target := Rect2()
var _target_fn: Callable
var _panel: PanelContainer
var _text: Label
var _next: Button
var _skip: Button
var _gears_before := 0
var _time := 0.0
var _tile_cells: Array = []
var _auto_hide := -1.0
# Draws the tile samples above the card (the card would hide anything drawn by this node).
var _samples: Control


func setup(p_hud, p_battle) -> void:
	hud = p_hud
	battle = p_battle


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	var style := UiKit.card_style(UiKit.GOLD_TEXT, Color(0.06, 0.08, 0.11, 0.96))
	style.set_border_width_all(4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size = Vector2(560, 0)
	_panel.visible = false
	add_child(_panel)
	var box := UiKit.vbox(8)
	_panel.add_child(box)
	_text = UiKit.label("", 21)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 520
	box.add_child(_text)
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_END
	_skip = UiKit.button("Bỏ hướng dẫn", Vector2(180, 50), _finish)
	_skip.add_theme_font_size_override("font_size", 15)
	row.add_child(_skip)
	_next = UiKit.button("TIẾP ▶", Vector2(150, 50), func(): _advance())
	_next.add_theme_font_size_override("font_size", 17)
	row.add_child(_next)
	box.add_child(row)
	_samples = Control.new()
	_samples.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_samples.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_samples.draw.connect(_draw_samples)
	add_child(_samples)
	# Wait a frame so the shop and the first gear exist.
	_start.call_deferred()


func _start() -> void:
	var kinds: Array = battle.board.tile_kinds()
	var fresh := kinds.filter(func(k): return not PlayerData.seen_tiles.has(k))
	if not fresh.is_empty():
		_show_tiles(fresh)
	elif PlayerData.current_level == 0 and not PlayerData.tutorial_done:
		_go("buy")


func _process(delta: float) -> void:
	_time += delta
	if _target_fn.is_valid():
		_target = _target_fn.call()
	match _step:
		"buy":
			if battle.board.gears.size() > _gears_before:
				_go("turn")
		"merge":
			for gear in battle.board.gears.values():
				if gear.tier >= 2:
					_go("ready")
					break
			if _step == "merge" and battle.phase == "fight":
				_go("fight")
		"ready":
			if battle.phase == "fight":
				_go("fight")
		"fight":
			if battle.phase == "shop":
				_go("income")
	if _auto_hide > 0.0:
		_auto_hide -= delta
		if _auto_hide <= 0.0:
			_panel.visible = false
			_target = Rect2()
			_target_fn = Callable()
	queue_redraw()


func _advance() -> void:
	match _step:
		"turn":
			_go("merge")
		"merge":
			_go("ready")
		"income":
			_finish()
		"tiles":
			PlayerData.mark_tiles_seen(battle.board.tile_kinds())
			_tile_cells.clear()
			_step = ""
			_panel.visible = false
			if PlayerData.current_level == 0 and not PlayerData.tutorial_done:
				_go("buy")


func _finish() -> void:
	if _step == "tiles":
		PlayerData.mark_tiles_seen(battle.board.tile_kinds())
	elif not PlayerData.tutorial_done and PlayerData.current_level == 0:
		PlayerData.finish_tutorial()
	_step = ""
	_tile_cells.clear()
	_panel.visible = false
	_target = Rect2()
	_target_fn = Callable()


func _go(step: String) -> void:
	_step = step
	_auto_hide = -1.0
	_next.visible = true
	_skip.visible = true
	match step:
		"buy":
			_gears_before = battle.board.gears.size()
			_say("① Chạm một lính trong SHOP để mua gear. Mỗi món tốn thịt, giá ghi dưới thẻ.", CARD_Y, func(): return _card_rect())
			_next.visible = false
		"turn":
			_say("② Gear nằm cạnh QUẢ CẦU CAM (hoặc cạnh một gear đang quay) sẽ quay theo. Chỉ gear ĐANG QUAY mới sinh lính!", CARD_Y, func(): return _newest_gear_rect())
		"merge":
			_say("③ Hai gear cùng lính, cùng bậc: KÉO gear này THẢ lên gear kia để ghép lên bậc 2, mạnh gấp đôi. Chưa có cặp thì mua thêm.", CARD_Y, func(): return _board_rect())
		"ready":
			_say("④ Xếp xong rồi! Bấm SẴN SÀNG để địch tới. Lính tự đánh, giữ thành đừng để hết máu.", CARD_Y, func(): return hud._ready_button.get_global_rect())
			_next.visible = false
		"fight":
			_say("Trong trận vẫn kéo, ghép và bán gear được (kéo vào ô BÁN). Chỉ mua được ở lượt nghỉ.", 120.0, Callable())
			_next.visible = false
			_auto_hide = 6.0
		"income":
			_say("⑤ Hết đợt: nhận thịt thu nhập, cộng LÃI (mỗi 5 thịt để dành +1, tối đa +3). Mua thêm, ghép gear rồi tiếp tục!", CARD_Y, func(): return _card_rect())
			_next.text = "ĐÃ HIỂU"


func _show_tiles(kinds: Array) -> void:
	_step = "tiles"
	_tile_cells.clear()
	for cell in battle.board.tiles:
		if kinds.has(battle.board.tiles[cell]) and battle.board.is_open(cell):
			_tile_cells.append(cell)
	var lines := []
	for kind in kinds:
		var info: Dictionary = GearBoard.TILE_INFO[kind]
		lines.append("■ %s: %s" % [info["name"], info["text"]])
	_say("Ô MỚI TRÊN LƯỚI!\n" + "\n".join(lines), CARD_Y, Callable(), SAMPLE_PAD)
	# Taller than the tutorial cards: sit it right above the grid once its size is known.
	_sit_above_board.call_deferred()
	_next.text = "ĐÃ HIỂU"
	_skip.visible = false


func _say(text: String, y: float, target: Callable, left_pad := 18.0) -> void:
	_text.text = text
	_text.custom_minimum_size.x = 520 - (left_pad - 18.0)
	(_panel.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_left = left_pad
	_panel.reset_size()
	_panel.visible = true
	_panel.position = Vector2(80, y)
	_target_fn = target
	_target = target.call() if target.is_valid() else Rect2()
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.2)


func _card_rect() -> Rect2:
	if hud._cards.is_empty() or not is_instance_valid(hud._cards[0]) or not hud._shop_panel.visible:
		return Rect2()
	return hud._cards[0].get_global_rect()


func _gear_screen(cell: Vector2i) -> Vector2:
	return battle.board.get_global_transform_with_canvas() * battle.board.cell_center(cell)


func _newest_gear_rect() -> Rect2:
	var gear = null
	for g in battle.board.gears.values():
		if g.powered:
			gear = g
	if gear == null:
		return Rect2()
	return Rect2(_gear_screen(gear.cell) - Vector2(55, 55), Vector2(110, 110))


func _board_rect() -> Rect2:
	var board = battle.board
	var top_left: Vector2 = board.get_global_transform_with_canvas() * Vector2.ZERO
	return Rect2(top_left, Vector2(board.COLS, board.ROWS) * board.CELL)


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 6.0)
	if _target.size != Vector2.ZERO:
		var r := _target.grow(6.0 + pulse * 6.0)
		draw_rect(r, Color(1.0, 0.85, 0.3, 0.9), false, 4.0)
		# A bouncing arrow above (or below, near the top of the screen) the target.
		var above := r.position.y > 200.0
		var tip := Vector2(r.get_center().x, r.position.y - 8.0 - pulse * 10.0) if above else Vector2(r.get_center().x, r.end.y + 8.0 + pulse * 10.0)
		var dir := -1.0 if above else 1.0
		var arrow := PackedVector2Array([tip, tip + Vector2(-20, 30 * dir), tip + Vector2(-8, 30 * dir), tip + Vector2(-8, 56 * dir),
			tip + Vector2(8, 56 * dir), tip + Vector2(8, 30 * dir), tip + Vector2(20, 30 * dir)])
		var outline := arrow.duplicate()
		outline.append(arrow[0])
		draw_polyline(outline, Color("24170e"), 5.0, true)
		draw_colored_polygon(arrow, Color("ffd35c"))
	for cell in _tile_cells:
		var center: Vector2 = _gear_screen(cell)
		draw_rect(Rect2(center - Vector2(50, 50), Vector2(100, 100)), Color(1.0, 0.9, 0.4, 0.5 + 0.5 * pulse), false, 4.0)
	_samples.queue_redraw()


func _sit_above_board() -> void:
	_panel.position.y = _board_rect().position.y - 8.0 - _panel.size.y


# A sample of each new tile on the card's left.
func _draw_samples() -> void:
	if _step != "tiles" or not _panel.visible:
		return
	var kinds: Array = battle.board.tile_kinds().filter(func(k): return not PlayerData.seen_tiles.has(k))
	for i in kinds.size():
		GearBoard.draw_tile(_samples, kinds[i], _panel.position + Vector2(64, 64 + i * 104.0))
