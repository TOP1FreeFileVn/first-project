extends Control

# Presentation of already-granted troop results. The accepted carton/paw acting
# stays clock-driven so skip, native captures and the live reveal share one pose.
signal finished

const Box = preload("res://game/ui/CartonSummonBox.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const Economy = preload("res://game/core/Economy.gd")
const Cats = preload("res://game/data/Cats.gd")
const SCREEN := Vector2(720, 1280)
const FOCUS := Vector2(360, 806)
const ARRIVAL := 1.32
const CARD := Vector2(110, 156)
const LIGHTS := [Color("fff0c7"), Color("80d6ff"), Color("d9a0ff"), Color("ffd36f")]

var _raw_results: Array = []
var _count := 0
var _clock := 0.0
var _duration := 0.0
var _finished := false
var _boxes: Array = []
var _cards: Array = []
var _results: Array[Dictionary] = []
var _starts: Array[float] = []
var _lengths: Array[Array] = []
var _focus: Node2D
var _front: Control
var _title: Label
var _caption: Label
var _rarity: Label
var _name: Label
var _counter: Label
var _active := -1
var _glow := 0.0
var _opening := 0.0
var _collect := 0.0
var _color := Color("fff0c7")


func setup(results: Array) -> void:
	_raw_results = results.duplicate(true)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var stage := Node2D.new()
	stage.name = "StageLight"
	stage.draw.connect(_draw_stage)
	add_child(stage)
	_focus = Box.new()
	_focus.name = "FocusedCarton"
	add_child(_focus)
	_front = Control.new()
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.draw.connect(_draw_smoke)
	add_child(_front)
	_title = _label("", 34, Color("fff0c7"), Vector2(30, 60), Vector2(660, 52))
	var eyebrow := _label("MỘT CUỘC GẶP GỠ BẤT NGỜ", 18, Color("c5b5d6"), Vector2(30, 122), Vector2(660, 32))
	eyebrow.add_theme_constant_override("outline_size", 0)
	_caption = _label("", 25, Color("f6e6c8"), Vector2(35, 206), Vector2(650, 60))
	_caption.add_theme_constant_override("outline_size", 3)
	_rarity = _label("", 25, Color.WHITE, Vector2(30, 297), Vector2(660, 38))
	_name = _label("", 32, Color("fff0c7"), Vector2(30, 826), Vector2(660, 44))
	_counter = _label("", 18, Color("cbbcd9"), Vector2(30, 267), Vector2(660, 28))
	_counter.add_theme_constant_override("outline_size", 0)
	_build()


func _label(text: String, font_size: int, color: Color, at: Vector2, area: Vector2) -> Label:
	var label := UiKit.label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = at
	label.size = area
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _build() -> void:
	_count = _raw_results.size()
	for node in _boxes + _cards:
		node.queue_free()
	_boxes.clear()
	_cards.clear()
	_results.clear()
	_starts.clear()
	_lengths.clear()
	var next := ARRIVAL
	for i in _count:
		var id: String = _raw_results[i]["id"]
		var troop: Resource = PlayerData.TROOPS[id]
		var frames := SpriteLib.unit_frames(troop.unit_key, "Blue")
		var result := {"id": id, "rank": int(troop.rarity), "troop": troop,
			"texture": frames.get_frame_texture("idle", 0), "new": bool(_raw_results[i].get("new", false))}
		_results.append(result)
		_starts.append(next)
		var rank: int = result["rank"]
		# Focus, paw, light build + still hold, flap opening, cat rise, greeting, collect.
		# The light finishes its build well before this phase ends, leaving a real
		# anticipation beat. A slower cat rise is separate from that empty-box hold.
		var lengths: Array = [0.40, 1.02, [0.34, 0.44, 0.92, 1.48][rank], [0.40, 0.44, 0.58, 0.78][rank], [0.45, 0.48, 0.56, 0.72][rank], [0.50, 0.56, 0.70, 0.90][rank], 0.40] if _count == 1 else [
			[0.12, 0.13, 0.17, 0.22][rank], [0.34, 0.38, 0.55, 0.75][rank],
			[0.20, 0.30, 0.80, 1.40][rank], [0.23, 0.26, 0.48, 0.72][rank],
			[0.22, 0.26, 0.42, 0.62][rank], [0.12, 0.18, 0.36, 0.80][rank],
			[0.17, 0.18, 0.20, 0.26][rank]]
		_lengths.append(lengths)
		for length: float in lengths:
			next += length
		var box := Box.new()
		box.name = "WaitingBox%d" % i
		add_child(box)
		move_child(box, _focus.get_index())
		_boxes.append(box)
		var card := _make_card(result)
		add_child(card)
		move_child(card, _front.get_index())
		_cards.append(card)
	_duration = next + 0.5
	_title.text = "TRIỆU HỒI x%d" % _count
	_clock = 0.0
	seek(0.0)


func _process(delta: float) -> void:
	if _finished:
		return
	var before := _clock
	seek(minf(_clock + delta, _duration))
	_sound_between(before, _clock)
	if _clock >= _duration:
		complete()
		finished.emit()


# Finalising the visuals never grants rewards or invokes the completion callback.
# The owner can use this for skip without passing through any pending showcases.
func complete() -> void:
	_finished = true
	set_process(false)
	seek(_duration)


func _sound_between(before: float, after: float) -> void:
	if after <= before:
		return
	if before < 0.53 and after >= 0.53:
		SoundLib.play("thud", -9.0, 0.02, 1.15)
	for i in _count:
		var lengths: Array = _lengths[i]
		var reach: float = _starts[i] + float(lengths[0])
		var light_at := reach + float(lengths[1])
		var open_at := light_at + float(lengths[2])
		if before < reach and after >= reach:
			SoundLib.play("pet", -13.0, 0.02, 1.15)
		if before < light_at and after >= light_at:
			if int(_results[i]["rank"]) >= 2:
				MusicLib.duck(1.6)
			SoundLib.play(["rare", "rare", "epic", "legend"][_results[i]["rank"]], -9.0, 0.0, 1.05)
		if before < open_at and after >= open_at:
			SoundLib.play("chest_open", -12.0, 0.01, 1.35)


func seek(seconds: float) -> void:
	_clock = clampf(seconds, 0.0, _duration)
	_active = -1
	for i in _count:
		var end := _starts[i] + _sum(_lengths[i])
		if _clock >= _starts[i] and _clock < end:
			_active = i
		var completed := _clock >= end
		var box: Node2D = _boxes[i]
		var card: Control = _cards[i]
		var delay := float(i % 5) * 0.045 + (0.28 if i >= 5 else 0.0)
		var p := clampf((_clock - delay) / 0.8, 0.0, 1.0)
		var home := _slot(i)
		box.position = home + Vector2(0, -115.0 * pow(1.0 - _s(0.15, 0.65, p), 2.0))
		box.scale = Vector2.ONE * (1.30 if _count == 1 else 0.40)
		var impact := sin(_s(0.60, 0.87, p) * PI)
		box.scale *= Vector2(1.0 + impact * 0.08, 1.0 - impact * 0.10)
		box.rotation = sin(_clock * 4.0 + i * 1.8) * 0.018 * (0.4 if _active >= 0 else 1.0)
		box.modulate = Color.WHITE
		box.modulate.a = _s(0.23, 0.4, p) * (0.4 if _active >= 0 and _active != i else 1.0)
		box.visible = not completed and _active != i
		box.wiggle = 0.0 if _clock < 0.8 else sin(_clock * 3.5 + i * 2.0) * 0.2
		box.queue_redraw()
		card.visible = completed
		card.position = home - CARD * Vector2(0.5, 0.92)
		card.scale = Vector2.ONE
		card.modulate.a = 1.0 if _active < 0 else 0.65
	_glow = 0.0
	_opening = 0.0
	_collect = 0.0
	_focus.visible = _active >= 0
	_name.visible = false
	_rarity.visible = false
	_caption.text = "Mười kiện hàng vừa tới…" if _count == 10 else "Một kiện hàng vừa tới…"
	_counter.text = ""
	if _active >= 0:
		_pose_active()
	elif _clock >= _duration - 0.5:
		_caption.text = "Đồng đội đã sẵn sàng!"
		_counter.text = "Đã mở đủ %d hộp" % _count
		if _count == 1:
			var card: Control = _cards[0]
			card.position = Vector2(250, 440)
			card.scale = Vector2(2, 2)
		else:
			var settle := _s(_duration - 0.5, _duration - 0.08, _clock)
			for i in _count:
				var card: Control = _cards[i]
				card.position = card.position.lerp(Vector2(37 + (i % 5) * 134, 475 + (i / 5) * 180), settle)
				card.scale = Vector2.ONE * lerpf(1.0, 1.12, settle)
	get_node("StageLight").queue_redraw()
	_front.queue_redraw()


func _pose_active() -> void:
	var i := _active
	var result: Dictionary = _results[i]
	var lengths: Array = _lengths[i]
	var t := _clock - _starts[i]
	var focus_end: float = lengths[0]
	var paw_end := focus_end + float(lengths[1])
	var light_end := paw_end + float(lengths[2])
	var open_end := light_end + float(lengths[3])
	var rise_end := open_end + float(lengths[4])
	var hold_end := rise_end + float(lengths[5])
	var end := hold_end + float(lengths[6])
	var enter := _s(0.0, focus_end, t)
	var paw_u := clampf((t - focus_end) / float(lengths[1]), 0.0, 1.0)
	var paw := _paw_reach(paw_u)
	var light_full := paw_end + _light_build_duration(int(result["rank"]))
	_glow = _s(paw_end, light_full, t)
	# A quiet breath gives the held light life without switching its colour.
	if t >= light_full:
		_glow *= 0.96 + 0.04 * cos((t - light_full) * 3.6)
	var lid_move_end := open_end - (0.24 if int(result["rank"]) == 3 else 0.07)
	_opening = _soft(light_end, lid_move_end, t)
	_collect = _s(hold_end, end, t)
	_color = LIGHTS[result["rank"]]
	var target_scale := 1.3 if _count == 1 else 1.33
	_focus.position = _slot(i).lerp(FOCUS, enter)
	_focus.scale = Vector2.ONE * lerpf(1.3 if _count == 1 else 0.40, target_scale, enter)
	_focus.position = _focus.position.lerp(_slot(i), _collect)
	_focus.scale *= 1.0 - _collect * 0.62
	var press := _soft(0.72, 1.0, paw_u) * (1.0 - _s(light_end, lid_move_end, t))
	_focus.rotation = -0.006 * sin(paw_u * PI) * (1.0 - _opening)
	_focus.scale *= Vector2(1.0 + press * 0.008, 1.0 - press * 0.012)
	_focus.modulate = Color(1, 1, 1, 1.0 - _s(0.7, 1.0, _collect))
	_focus.paw = paw * (1.0 - _s(open_end, rise_end, t))
	_focus.paw_curl = _soft(0.48, 0.94, paw_u) * (1.0 - _s(0.38, 0.68, _opening))
	_focus.paw_press = press * 0.65
	_focus.paw_sway = sin(paw_u * PI * 1.3) * 1.6 * (1.0 - _opening)
	_focus.lid = paw * paw * 0.11 + _opening * 0.89
	_focus.glow = _glow
	_focus.rarity = result["rank"]
	_focus.cat_rise = _soft(open_end, rise_end, t)
	_focus.cat_texture = result["texture"]
	_focus.fur = {"muop": Color("eaba74"), "tro": Color("a8adb4"), "tam": Color("edc78c"), "bo": Color("f0dbad")}.get(Cats.cat_of(result["id"]), Color("eaba74"))
	_focus.wiggle = sin(t * 5.0) * sin(paw_u * PI) * 0.10
	_focus.queue_redraw()
	_caption.text = "Có tiếng động trong hộp…" if paw < 0.5 else "Ai đang muốn ra ngoài nhỉ?"
	if _glow > 0.05:
		_caption.text = "Một đồng đội đang tới!"
	if int(result["rank"]) == 3 and t >= light_full and t < light_end:
		_caption.text = "Ánh vàng đang lan ra…"
	if _focus.cat_rise > 0.20:
		_caption.text = "Chào mừng đồng đội!"
	_rarity.visible = _glow > 0.05
	_rarity.text = Economy.RARITY_NAMES[result["rank"]].to_upper()
	_rarity.add_theme_color_override("font_color", _color)
	_rarity.modulate.a = _s(0.1, 0.5, _glow) * (1.0 - _collect)
	_name.visible = _focus.cat_rise > 0.4
	_name.text = result["troop"].display_name
	_name.modulate.a = _s(0.4, 1.0, _focus.cat_rise) * (1.0 - _collect)
	_counter.text = "HỘP %02d / %02d" % [i + 1, _count] if _count > 1 else ""
	if _collect > 0.1:
		var card: Control = _cards[i]
		card.visible = true
		card.modulate.a = _s(0.1, 0.8, _collect)


func _slot(i: int) -> Vector2:
	if _count == 1:
		return FOCUS
	var first := Vector2(92 + (i % 5) * 134, 578 + (i / 5) * 164)
	var final := Vector2(92 + (i % 5) * 134, 1006 + (i / 5) * 154)
	return first.lerp(final, _s(ARRIVAL - 0.05, ARRIVAL + 0.30, _clock))


func _make_card(result: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.size = CARD
	card.custom_minimum_size = CARD
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UiKit.rarity_card(result["rank"]))
	var column := UiKit.vbox(1)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(column)
	var image := UiKit.troop_portrait(result["troop"], 62)
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(image)
	var name_label := UiKit.label(result["troop"].display_name, 11)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = 90
	column.add_child(name_label)
	var rarity := UiKit.label(Economy.RARITY_NAMES[result["rank"]], 12)
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(rarity)
	var reward := "MỚI!" if result["new"] else "+1 thẻ"
	if not result["new"] and int(PlayerData.troops[result["id"]]["stars"]) >= Economy.MAX_STARS:
		reward = "+%d vàng" % Economy.SPARE_CARD_GOLD
	var earned := UiKit.label(reward, 11, UiKit.GOLD_TEXT if result["new"] else UiKit.INFO)
	earned.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(earned)
	return card


func _draw_stage() -> void:
	var ci: Node2D = get_node("StageLight")
	# Small contact shadows ground each arriving parcel.
	for i in _count:
		if _boxes[i].visible:
			var at := _slot(i)
			ci.draw_set_transform(at + Vector2(0, 5), 0, Vector2(1, 0.19))
			ci.draw_circle(Vector2.ZERO, 140 * (1.3 if _count == 1 else 0.4), Color(0.10, 0.06, 0.15, 0.24 * _boxes[i].modulate.a))
	ci.draw_set_transform(Vector2.ZERO)
	if _active < 0:
		return
	# Local light spills out of the opening. Its outer vertices fade to transparent.
	var base := _focus.position + Vector2(0, -176) * _focus.scale.y
	var strength := _glow * (1.0 - _collect)
	if strength > 0.001:
		for i in 5:
			var width := 100.0 + i * 32.0
			var skew := sin(_clock * 1.8 + i) * 10
			var poly := PackedVector2Array([base + Vector2(-76, 0), base + Vector2(76, 0),
				base + Vector2(width + skew, -330), base + Vector2(-width + skew, -330)])
			ci.draw_polygon(poly, PackedColorArray([Color(_color, strength * 0.08), Color(_color, strength * 0.08), Color(_color, 0), Color(_color, 0)]))
		for i in 14:
			var p := fposmod(_clock * 0.5 + i * 0.618, 1.0)
			var at := base + Vector2(sin(i * 2.3) * (75 + p * 95), -p * 310)
			_star(ci, at, 3 + (i % 3) * 2, Color(_color, sin(p * PI) * strength * 0.8))


func _draw_smoke() -> void:
	for i in _count:
		var delay := float(i % 5) * 0.045 + (0.28 if i >= 5 else 0.0)
		var p := (_clock - delay) / 0.85
		if p > 0.0 and p < 1.0:
			_smoke(_slot(i) - Vector2(0, 90 if _count == 10 else 150), p, 65 if _count == 10 else 172, i)
	if _clock < ARRIVAL:
		var t := _s(0.0, 0.3, _clock)
		if _clock < 0.28:
			var at := Vector2(360, lerpf(300, 675, t))
			_star(_front, at, 15 * sin(t * PI), Color("fff0c7"))


func _smoke(at: Vector2, p: float, radius: float, seed_value: int) -> void:
	var grow := _s(0.0, 0.24, p)
	var fade := 1.0 - _s(0.35, 1.0, p)
	# A connected scalloped silhouette reads as a puff of paper dust. Separate
	# translucent circles would leave a necklace of overlapping soap bubbles.
	for side in [-1, 1]:
		var center := at + Vector2(side * radius * p * 0.63, -p * radius * 0.30)
		var silhouette := PackedVector2Array()
		var r := radius * grow * (1.0 - p * 0.3)
		for j in 60:
			var angle := j * TAU / 60.0
			var lobe := 0.78 + 0.085 * cos(angle * 7 + seed_value * 0.7) + 0.045 * sin(angle * 5 + side)
			silhouette.append(center + Vector2(cos(angle), sin(angle) * 0.78) * r * lobe)
		if r > 1.0 and fade > 0.01:
			_front.draw_colored_polygon(silhouette, Color(Color("ded3e6" if side < 0 else "e9e0ec"), fade))
	for j in 5:
		var direction := Vector2.from_angle(j * TAU / 5.0 + seed_value)
		_star(_front, at + direction * radius * (0.8 + p), 5.0 * (1.0 - p), Color(Color("fff0c7"), fade))


func _star(ci: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	if radius < 0.8 or color.a < 0.01: return
	var poly := PackedVector2Array()
	for i in 8:
		poly.append(at + Vector2.from_angle(i * TAU / 8.0 - PI / 2) * radius * (1.0 if i % 2 == 0 else 0.3))
	ci.draw_colored_polygon(poly, color)


func _s(start: float, end: float, value: float) -> float:
	var t := clampf((value - start) / maxf(0.001, end - start), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _soft(start: float, end: float, value: float) -> float:
	var t := clampf((value - start) / maxf(0.001, end - start), 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


func _paw_reach(u: float) -> float:
	# Toe peek -> a tiny retreat to find the edge -> palm settles -> weight.
	# C2 easing makes the changes of direction feel like a limb, not a slider.
	if u < 0.30: return lerpf(0.0, 0.52, _soft(0.0, 0.30, u))
	if u < 0.46: return lerpf(0.52, 0.46, _soft(0.30, 0.46, u))
	if u < 0.84: return lerpf(0.46, 0.92, _soft(0.46, 0.84, u))
	return lerpf(0.92, 1.0, _soft(0.84, 1.0, u))


func _light_build_duration(rank: int) -> float:
	return [0.16, 0.22, 0.36, 0.48][rank]


func _sum(values: Array) -> float:
	var total := 0.0
	for value: float in values: total += value
	return total


