extends Node2D

# Test scene: the rigged sword cat runs down the lobby road to a goblin and slashes it.
# Each "hit" event of the attack animation flashes the goblin and knocks it back; after
# three hits it poofs and the cat goes back to idle.
#   Godot --path . res://tests/ui/SoldierFightPreview.tscn --write-movie out.avi --fixed-fps 30 --quit-after 270

const SoldierRig := preload("res://game/battle/SoldierRig.gd")
const TERRAIN := preload("res://game/assets/lobby/cardboard/terrain-clean.png")
const GOBLIN := preload("res://game/ui/skin/unit_warrior.svg")
const SKELETON := "res://game/assets/units/soldier_kiem/soldier_kiem.json"
const START := Vector2(413, 725)
const FOE_AT := Vector2(305, 925)
const REACH := 92.0
const RUN_SPEED := 110.0
const CAT_SCALE := 0.4
const HITS := 3

var _cat: Node2D
var _foe: Sprite2D
var _state := "run"
var _hits := 0

func _ready() -> void:
	var view := get_viewport_rect().size
	var fit := minf(view.x / 720.0, view.y / 1280.0)
	scale = Vector2.ONE * fit
	position = (view - Vector2(720, 1280) * fit) * 0.5
	var ground := Sprite2D.new()
	ground.texture = TERRAIN
	ground.centered = false
	add_child(ground)
	_foe = Sprite2D.new()
	_foe.texture = GOBLIN
	_foe.scale = Vector2.ONE * CAT_SCALE
	_foe.offset = Vector2(0, -116)      # feet of the 256x240 sprite on its position
	_foe.flip_h = true                  # face the cat coming from above-right
	_foe.position = FOE_AT
	add_child(_foe)
	_cat = SoldierRig.new()
	_cat.skeleton_file = SKELETON
	_cat.scale = Vector2(-CAT_SCALE, CAT_SCALE)   # running left-down, toward the goblin
	_cat.position = START
	_cat.event.connect(_on_event)
	add_child(_cat)

func _process(delta: float) -> void:
	if _state == "run":
		var to := FOE_AT + Vector2(REACH, -6) - _cat.position
		if to.length() < 3.0:
			_state = "attack"
			_cat.play("attack")
		else:
			_cat.position += to.normalized() * minf(RUN_SPEED * delta, to.length())

func _on_event(name: String) -> void:
	if name != "hit" or _state != "attack":
		return
	_hits += 1
	var t := create_tween()
	t.tween_property(_foe, "modulate", Color(1, 0.45, 0.45), 0.04)
	t.parallel().tween_property(_foe, "position:x", FOE_AT.x - 10, 0.06)
	t.tween_property(_foe, "modulate", Color.WHITE, 0.12)
	t.parallel().tween_property(_foe, "position:x", FOE_AT.x, 0.12)
	if _hits >= HITS:
		_state = "idle"
		_cat.play("idle")
		var poof := create_tween()
		poof.tween_interval(0.18)
		poof.tween_property(_foe, "scale", Vector2.ONE * CAT_SCALE * 1.25, 0.1)
		poof.parallel().tween_property(_foe, "modulate:a", 0.0, 0.2)
