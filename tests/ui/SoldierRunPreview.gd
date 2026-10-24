extends Node2D

# Test scene: the rigged sword cat runs along the lobby's dirt path, there and back.
# Open tests/ui/SoldierRunPreview.tscn and press F6, or record it:
#   Godot --path . res://tests/ui/SoldierRunPreview.tscn --write-movie out.avi --fixed-fps 30 --quit-after 240

const SoldierRig := preload("res://game/battle/SoldierRig.gd")
const TERRAIN := preload("res://game/assets/lobby/cardboard/terrain-clean.png")
const SKELETON := "res://game/assets/units/kiem/kiem.json"
## Centreline of the dirt road in the 720x1280 lobby art (traced from terrain-clean.png),
## from the castle gate down past the scratching post.
const PATH := [Vector2(348, 650), Vector2(395, 690), Vector2(413, 725), Vector2(403, 760), Vector2(361, 800),
	Vector2(320, 840), Vector2(300, 880), Vector2(305, 920), Vector2(340, 960), Vector2(389, 1000), Vector2(424, 1040)]
const RUN_SPEED := 120.0
const CAT_SCALE := 0.4

var _cat: Node2D
var _shadow: Polygon2D
var _distance := 0.0
var _length := 0.0

func _ready() -> void:
	var view := get_viewport_rect().size
	var fit := minf(view.x / 720.0, view.y / 1280.0)
	scale = Vector2.ONE * fit
	position = (view - Vector2(720, 1280) * fit) * 0.5
	var ground := Sprite2D.new()
	ground.texture = TERRAIN
	ground.centered = false
	add_child(ground)
	for i in PATH.size() - 1:
		_length += PATH[i].distance_to(PATH[i + 1])
	_shadow = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * 34, sin(a) * 7))
	_shadow.polygon = pts
	_shadow.color = Color(0.34, 0.43, 0.22, 0.25)
	add_child(_shadow)
	_cat = SoldierRig.new()
	_cat.skeleton_file = SKELETON
	_cat.scale = Vector2.ONE * CAT_SCALE
	add_child(_cat)

func _process(delta: float) -> void:
	_distance += RUN_SPEED * delta
	# Ping-pong along the path; flip the cat to face where it runs.
	var d := fposmod(_distance, _length * 2.0)
	var forward := d < _length
	var at := _point(d if forward else _length * 2.0 - d)
	_cat.position = at
	_shadow.position = at + Vector2(0, -2)
	_cat.scale.x = absf(_cat.scale.x) * (1.0 if forward else -1.0)

func _point(d: float) -> Vector2:
	for i in PATH.size() - 1:
		var seg: float = PATH[i].distance_to(PATH[i + 1])
		if d <= seg:
			return PATH[i].lerp(PATH[i + 1], d / seg)
		d -= seg
	return PATH[-1]
