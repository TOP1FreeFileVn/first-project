extends Node2D

## The castle upgrade as a little building site: a crowd of cats run up to the castle and
## hammer at it all over, in a cloud of dust, with knocks and wobbles; then a burst, and
## the castle stands at its new level (on_swap is called at that moment) while the cats
## cheer and fade away. Drawn in the castle art's space, gate foot at its origin.

const SoldierRig := preload("res://game/battle/SoldierRig.gd")
const RIG := "res://game/assets/units/lobby_%s/lobby_%s.json"
const HAMMER := preload("res://game/ui/skin/icon_w_bua_64.svg")
const COATS := ["tabby", "cream", "calico"]
const CAT_SCALE := 0.3
## Phase lengths (s): run in, hammer, burst, cheer and leave.
const ARRIVE := 0.7
const WORK := 2.6
const BURST := 0.35
const LEAVE := 1.1

## Where each cat works, around the castle (relative to its gate foot), and its facing.
const SPOTS := [
	[Vector2(-150, -10), 1.0], [Vector2(-95, 8), 1.0], [Vector2(-40, 14), 1.0],
	[Vector2(40, 14), -1.0], [Vector2(95, 8), -1.0], [Vector2(150, -10), -1.0],
	[Vector2(-120, -120), 1.0], [Vector2(120, -120), -1.0],
]

var castle: Node2D
var on_swap: Callable
var on_done: Callable
var _cats: Array = []
var _time := 0.0
var _swapped := false
var _shake := 0.0
var _castle_home := Vector2.ZERO
var _dust: Array = []
## Dust and chips draw on their own layer above the cats (a parent draws under its children).
var _dust_layer: Node2D

func start(p_castle: Node2D, swap: Callable, done: Callable) -> void:
	castle = p_castle
	on_swap = swap
	on_done = done
	_castle_home = castle.position
	z_index = 5
	for i in SPOTS.size():
		var spot: Vector2 = SPOTS[i][0]
		var facing: float = SPOTS[i][1]
		var cat := Node2D.new()
		add_child(cat)
		var rig := SoldierRig.new()
		rig.load_skeleton(RIG % [COATS[i % COATS.size()], COATS[i % COATS.size()]])
		rig.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		rig.scale = Vector2(CAT_SCALE * facing, CAT_SCALE)
		rig.speed = randf_range(0.9, 1.15)
		rig.play("walk")
		rig.event.connect(_on_bang.bind(cat))
		cat.add_child(rig)
		var hammer := Sprite2D.new()
		hammer.texture = HAMMER
		hammer.scale = Vector2.ONE * 0.55
		hammer.visible = false
		rig.add_child(hammer)
		# Cats run in from both sides of the courtyard.
		var from := spot + Vector2(-260.0 * facing, 60.0 + randf_range(-20, 20))
		cat.position = from
		_cats.append({"node": cat, "rig": rig, "hammer": hammer, "from": from, "to": spot, "delay": i * 0.06})
	SoundLib.play("reroll", -2.0)
	_dust_layer = Node2D.new()
	_dust_layer.name = "BuildDust"
	add_child(_dust_layer)
	_dust_layer.draw.connect(_draw_dust)

func _process(delta: float) -> void:
	_time += delta
	var t := _time
	for c in _cats:
		var cat: Node2D = c.node
		var rig = c.rig
		var hammer: Sprite2D = c.hammer
		var delay: float = c.delay
		var start: Vector2 = c.from
		var spot: Vector2 = c.to
		var arrive_t := clampf((t - delay) / ARRIVE, 0.0, 1.0)
		if t < ARRIVE + delay:
			cat.position = start.lerp(spot, ease(arrive_t, -2.0)) - Vector2(0, absf(sin(arrive_t * PI * 3.0)) * 10.0)
		elif t < ARRIVE + WORK:
			cat.position = spot
			if rig.animation != "hammer":
				rig.play("hammer", true)
				hammer.visible = true
		elif t < ARRIVE + WORK + BURST + LEAVE:
			# Done: a happy hop where it stands, fading away.
			hammer.visible = false
			rig.play("happy")
			var leave_t := clampf((t - ARRIVE - WORK) / (BURST + LEAVE), 0.0, 1.0)
			cat.position = spot - Vector2(0, absf(sin(t * 12.0 + delay * 9.0)) * 12.0 * (1.0 - leave_t))
			cat.modulate.a = 1.0 - smoothstep(0.35, 1.0, leave_t)
		# The hammer rides in the right paw.
		if hammer.visible:
			var paw: Transform2D = rig.bone_transform("paw_r")
			# Rig pixels: the 64 px icon held at the paw, head up and out, as big as the cat's head.
			hammer.transform = paw * Transform2D(deg_to_rad(-35.0), Vector2(10, -46)).scaled_local(Vector2.ONE * 1.6)
	# The castle shakes with the work, then stands up tall when it swaps.
	_shake = maxf(0.0, _shake - delta * 6.0)
	if castle != null:
		castle.position = _castle_home + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 3.0
	if not _swapped and t >= ARRIVE + WORK:
		_swapped = true
		_burst()
	_animate_dust(delta)
	# A haze keeps rising off the busy castle between blows.
	if t > ARRIVE and t < ARRIVE + WORK and randf() < delta * 10.0:
		_puff(Vector2(randf_range(-160, 160), randf_range(-230, -150)), 1.1)
	_dust_layer.queue_redraw()
	if t >= ARRIVE + WORK + BURST + LEAVE:
		if castle != null:
			castle.position = _castle_home
			castle.scale = Vector2.ONE
		if on_done.is_valid():
			on_done.call()
		queue_free()

func _on_bang(event_name: String, cat: Node2D) -> void:
	if event_name != "bang" or _time > ARRIVE + WORK:
		return
	SoundLib.play("hit", -9.0, 0.25)
	_shake = minf(1.0, _shake + 0.35)
	# Each blow: a burst of dust where the hammer lands, and a few cardboard chips.
	var at := cat.position + Vector2(randf_range(-6, 6) + 22.0 * signf(-cat.position.x), -44)
	for i in 3:
		_puff(at + Vector2(randf_range(-12, 12), randf_range(-8, 8)), 1.0)
	for i in 2:
		_chip(at)

func _burst() -> void:
	SoundLib.play("chest_open", 0.0, 0.0)
	SoundLib.play("reward", -2.0, 0.0)
	for i in 18:
		var angle := TAU * i / 18.0
		_puff(Vector2(cos(angle) * 150.0, -120 + sin(angle) * 110.0), 1.3)
	if on_swap.is_valid():
		on_swap.call()
	if castle != null:
		castle.scale = Vector2(1.08, 0.9)
		var tween := castle.create_tween()
		tween.tween_property(castle, "scale", Vector2(0.96, 1.06), 0.12)
		tween.tween_property(castle, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## A soft round dust puff in the lobby's cardboard colours.
func _puff(at: Vector2, size: float) -> void:
	_dust.append({"at": at, "v": Vector2(randf_range(-50, 50), randf_range(-90, -35)), "age": 0.0,
		"life": randf_range(0.55, 0.85), "r": randf_range(13, 20) * size})

## A white disc fading to clear at its edge, drawn once and tinted per puff.
static var _puff_tex: Texture2D

static func _soft_puff() -> Texture2D:
	if _puff_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(0.96, 0.9, 0.8, 1.0))
		g.set_color(1, Color(0.96, 0.9, 0.8, 0.0))
		g.add_point(0.5, Color(0.96, 0.9, 0.8, 0.8))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_puff_tex = t
	return _puff_tex

## A cardboard chip flung off by a blow: falls with gravity, spinning.
func _chip(at: Vector2) -> void:
	_dust.append({"at": at, "v": Vector2(randf_range(-150, 150), randf_range(-220, -120)), "age": 0.0,
		"life": randf_range(0.45, 0.7), "r": randf_range(5, 8), "chip": true, "spin": randf_range(-12, 12)})

func _animate_dust(delta: float) -> void:
	for d in _dust:
		d["age"] = float(d["age"]) + delta
		d["at"] = Vector2(d["at"]) + Vector2(d["v"]) * delta
		if d.get("chip", false):
			d["v"] = Vector2(d["v"]) + Vector2(0, 700) * delta
		else:
			d["v"] = Vector2(d["v"]) * exp(-delta * 2.0)
	_dust = _dust.filter(func(d): return float(d["age"]) < float(d["life"]))

func _draw_dust() -> void:
	for d in _dust:
		var u: float = float(d["age"]) / float(d["life"])
		var at: Vector2 = d["at"]
		if d.get("chip", false):
			var r: float = d["r"]
			var angle: float = float(d["spin"]) * float(d["age"])
			var pts := PackedVector2Array()
			for k in 4:
				pts.append(at + Vector2(r * (1.0 if k % 2 == 0 else 0.55), 0).rotated(angle + k * PI / 2.0))
			_dust_layer.draw_colored_polygon(pts, Color(0.86, 0.68, 0.45, 1.0 - u * u))
			continue
		# A soft cloud, no outline: a radial-gradient sprite that swells and fades.
		var r: float = float(d["r"]) * (1.3 + 1.4 * sqrt(u))
		var a := 0.95 * (1.0 - smoothstep(0.35, 1.0, u))
		_dust_layer.draw_texture_rect(_soft_puff(), Rect2(at - Vector2.ONE * r, Vector2.ONE * r * 2.0), false, Color(1, 1, 1, a))
