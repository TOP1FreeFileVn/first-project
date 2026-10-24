extends Control

# Approved courtyard art with the SVG prop/actor depth contract from the pilot.
# Home owns this once; refreshing a page must never restart its actors.
const ART := "res://game/assets/lobby/cardboard/"
const CANVAS := Vector2(720, 1280)
const PROP_ORIGIN := Vector2(128, 224)
const CAT_ORIGIN := Vector2(128, 238)
const CAT_SCALE := 0.37
const CastleTiers := preload("res://game/menu/lobby/CastleTiers.gd")
## The tier art (440 units wide) at 1:1 matches the old castle footprint (435 px, top at y 290).
const CASTLE_SCALE := 1.0
const SoldierRig := preload("res://game/battle/SoldierRig.gd")
## Lobby cats are skeletons (tools/ui/make_lobby_cat_rigs.py): idle, walk, scratch, bat, knead, nap.
const RIG := "res://game/assets/units/lobby_%s/lobby_%s.json"
const HeroCat := preload("res://game/core/HeroCat.gd")
## The hero cat's rig per weapon family (tools/ui/animate_hero_rig.py adds its lobby clips).
const HERO_RIG := "res://game/assets/hero/%s/%s.json"
## The hero art is drawn larger than the lobby cats; this keeps it a head taller than them.
const HERO_RIG_SCALE := 0.42
## Skeleton units are the 256x240 art's pixels, the same frame CAT_SCALE was set for.
const RIG_SCALE := CAT_SCALE
## Where a cat stands to play with each courtyard toy (720x1280 art px) and how it plays.
const TOYS := {
	"post": {"spot": Vector2(556, 792), "anim": "scratch"},    # in front of the scratching post
	"fish": {"spot": Vector2(640, 790), "anim": "bat"},        # under the fish hanging from the post
	"yarn": {"spot": Vector2(250, 862), "anim": "bat"},        # yarn ball, from its right
	"pillow": {"spot": Vector2(632, 918), "anim": "knead"},    # in front of the teal pillow; hops up onto it
}

var _world: Node2D
var _depth: Node2D
var _props: Dictionary = {}
var _actors: Dictionary = {}
var _clock := 0.0
var _active := false
var _castle_level := 1
var _castle: Node2D
# Toys that move when a cat plays with them.
var _yarn: Node2D            # the ball (rolls); its shadow stays on the ground
var _yarn_ball: Sprite2D
var _yarn_home := Vector2.ZERO
var _yarn_roll := 0.0        # px the ball is pushed away from home; springs back
var _yarn_spin := 0.0
var _fish: Sprite2D          # hangs from the post bracket; swings
var _fish_angle := 0.0
var _fish_speed := 0.0
## A tapped cat: key -> seconds of reaction left. It hops, meows and looks up.
var _petted := {}
## Weapon family of the hero rig now loaded.
var _hero_family := ""


func _ready() -> void:
	name = "CardboardLobby"
	# Taps come from the battle page's stage (Home.pet_cat_at), which covers this world.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world = Node2D.new()
	add_child(_world)
	_part(_world, "terrain-props-clean.png", Vector2.ZERO)
	_depth = Node2D.new()
	_depth.name = "FootDepthWorld"
	_depth.y_sort_enabled = true
	_world.add_child(_depth)
	var castle := Node2D.new()
	castle.name = "CardboardCastle"
	castle.position = Vector2(365, 646)
	_depth.add_child(castle)
	# The castle's look follows its level; its gate foot sits on the old door's ground point.
	_castle = CastleTiers.new()
	_castle.name = "CastleTiers"
	_castle.scale = Vector2.ONE * CASTLE_SCALE
	_castle.position = -CastleTiers.GATE_FOOT * CASTLE_SCALE
	castle.add_child(_castle)
	_make_prop("tunnel", Vector2(165, 790), 0.82)
	_make_prop("bed", Vector2(530, 866), 0.86)
	_static_prop("ScratchingPost", "props/scratching-post.svg", Vector2(590, 780), Vector2(80, 176))
	_make_fish(Vector2(590, 780), Vector2(80, 176))
	_make_yarn(Vector2(214, 854), Vector2(40, 74))
	_make_pillow(Vector2(630, 903), Vector2(75, 80))
	_make_cat("cream", "cream")
	_make_cat("tabby", "tabby")
	_make_cat("calico", "calico")
	_make_hero()
	resized.connect(_fit)
	_fit()
	sync_castle_level()
	_pose()
	set_active(false)


func _fit() -> void:
	if _world == null:
		return
	var fit := minf(size.x / CANVAS.x, size.y / CANVAS.y)
	_world.scale = Vector2.ONE * fit
	_world.position = (size - CANVAS * fit) * 0.5


func _part(parent: Node2D, path: String, origin: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(ART + path)
	sprite.centered = false
	sprite.position = -origin
	parent.add_child(sprite)
	return sprite


func _make_prop(kind: String, ground: Vector2, art_scale: float) -> void:
	var root := Node2D.new()
	root.name = kind.to_pascal_case() + "DepthRoot"
	root.position = ground
	root.scale = Vector2.ONE * art_scale
	# The prop is one sortable unit; its own internal order is fixed.
	root.y_sort_enabled = false
	_depth.add_child(root)
	for layer in ["shadow", "rear", "interior"]:
		_part(root, kind + "/" + layer + ".svg", PROP_ORIGIN)
	var slot := Node2D.new()
	slot.name = "OccupantSlot"
	slot.scale = Vector2.ONE / art_scale
	root.add_child(slot)
	_part(root, kind + "/front.svg", PROP_ORIGIN)
	_props[kind] = {"root": root, "slot": slot, "ground": ground, "occupant": "", "reservation": "cream" if kind == "tunnel" else "calico"}


func _static_prop(node_name: String, path: String, ground: Vector2, origin: Vector2) -> void:
	var root := Node2D.new()
	root.name = node_name
	root.position = ground
	_depth.add_child(root)
	_part(root, path, origin)


# The pillow, plus a slot drawn after it so a cat lying on it sits on top of the cushion.
func _make_pillow(ground: Vector2, origin: Vector2) -> void:
	var root := Node2D.new()
	root.name = "PillowForeground"
	root.position = ground
	_depth.add_child(root)
	_part(root, "props/pillow.svg", origin)
	var slot := Node2D.new()
	slot.name = "OccupantSlot"
	root.add_child(slot)
	_props["pillow"] = {"root": root, "slot": slot, "ground": ground, "occupant": "", "reservation": "tabby"}


# The fish toy hangs from the post's bracket at (137, 42) of the post art; it swings there.
func _make_fish(post_ground: Vector2, post_origin: Vector2) -> void:
	var hook := Vector2(137, 42)
	var root := Node2D.new()
	root.name = "FishToy"
	# Sorted with the post (same ground point, drawn after it).
	root.position = post_ground + Vector2(0, 1)
	_depth.add_child(root)
	_fish = Sprite2D.new()
	_fish.texture = load(ART + "props/fish-toy.svg")
	_fish.centered = false
	_fish.offset = -hook
	_fish.position = hook - post_origin
	root.add_child(_fish)

# The yarn ball rolls on its own node; its shadow stays painted on the ground.
func _make_yarn(ground: Vector2, origin: Vector2) -> void:
	_part(_world, "props/yarn-shadow.svg", origin - ground)
	_yarn = Node2D.new()
	_yarn.name = "YarnForeground"
	_yarn.position = ground
	_depth.add_child(_yarn)
	_yarn_home = ground
	# Spin around the ball's centre (40, 38) of the 80x80 art.
	_yarn_ball = Sprite2D.new()
	_yarn_ball.texture = load(ART + "props/yarn.svg")
	_yarn_ball.position = Vector2(40, 38) - origin
	_yarn.add_child(_yarn_ball)

## A cat swiped a toy: give it a push. `strength` 1 = a normal swipe.
func _swipe(toy: String, from_x: float, strength := 1.0) -> void:
	match toy:
		"yarn":
			# Rolls away from the paw, then drifts back (it never leaves its spot for long).
			var away := signf(_yarn_home.x - from_x)
			_yarn_roll = clampf(_yarn_roll + away * 14.0 * strength, -26.0, 26.0)
		"fish":
			_fish_speed += signf(_fish.global_position.x - from_x) * 3.2 * strength

func _animate_toys(delta: float) -> void:
	# Yarn: spring back to home with damping; spin by the distance rolled.
	var before := _yarn_roll
	_yarn_roll = lerpf(_yarn_roll, 0.0, 1.0 - exp(-delta * 1.6))
	_yarn.position = _yarn_home + Vector2(_yarn_roll, 0)
	_yarn_spin += (_yarn_roll - before) / 31.0
	_yarn_ball.rotation = _yarn_spin
	# Fish: a damped pendulum.
	_fish_speed += -_fish_angle * 22.0 * delta
	_fish_speed *= exp(-delta * 1.8)
	_fish_angle = clampf(_fish_angle + _fish_speed * delta, -0.9, 0.9)
	_fish.rotation = _fish_angle

func _make_cat(key: String, coat: String) -> void:
	var actor := Node2D.new()
	actor.name = key.to_pascal_case() + "FloorRoot"
	_depth.add_child(actor)
	var shadow := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 32:
		var angle := TAU * float(i) / 32.0
		points.append(Vector2(cos(angle) * 31, sin(angle) * 6 - 1))
	shadow.polygon = points
	shadow.color = Color(0.34, 0.43, 0.22, 0.22)
	actor.add_child(shadow)
	var rig := SoldierRig.new()
	rig.name = "FrontVisual"
	rig.load_skeleton(RIG % [coat, coat])
	rig.play("idle")
	rig.scale = Vector2.ONE * RIG_SCALE
	rig.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rig.event.connect(func(event_name: String): _on_cat_event(key, event_name))
	actor.add_child(rig)
	_actors[key] = {"root": actor, "pose": rig, "state": "rest", "position": Vector2.ZERO, "facing": 1.0}

## The hero cat, with the rig of its equipped weapon (sync_hero swaps it when that changes).
func _make_hero() -> void:
	_make_cat("hero", "tabby")
	_hero_family = ""
	sync_hero()


func sync_hero() -> void:
	var family := HeroCat.family(PlayerData.hero_cat)
	if family == _hero_family or not _actors.has("hero"):
		return
	_hero_family = family
	var rig: Node2D = _actors["hero"].pose
	rig.load_skeleton(HERO_RIG % [family, family])
	rig.scale = Vector2.ONE * HERO_RIG_SCALE
	rig.play("idle", true)


func set_active(active: bool) -> void:
	_active = active
	visible = active
	set_process(active)


func sync_castle_level() -> void:
	_castle_level = PlayerData.castle_level
	_castle.set_level(_castle_level)
	sync_hero()


func _process(delta: float) -> void:
	_clock += delta
	_pose()
	_animate_toys(delta)
	_animate_petted(delta)

# A playing cat's "swipe" event pushes the toy it is playing with.
func _on_cat_event(key: String, event_name: String) -> void:
	if event_name != "swipe":
		return
	var data: Dictionary = _actors[key]
	var toy := _nearest_toy(data.position)
	if toy in ["yarn", "fish"] and data.position.distance_to(TOYS[toy].spot) < 30.0:
		_swipe(toy, data.position.x + 20.0 * data.facing)

## Tap a cat: it hops, meows and blinks at you. Returns true when a cat was hit.
func pet_at(screen_point: Vector2) -> bool:
	var p := _world.get_global_transform().affine_inverse() * screen_point
	var best := ""
	for key in _actors:
		var d: Vector2 = p - (_actors[key].position + Vector2(0, -40))
		# The cat covers roughly 90 x 90 art px around its middle.
		if absf(d.x) < 48.0 and absf(d.y) < 50.0 and (best == "" or d.length() < (p - _actors[best].position).length()):
			best = key
	if best == "" or _petted.has(best):
		return best != ""
	_petted[best] = PET_TIME
	# The hero answers a tap with a battle cry instead of a meow.
	SoundLib.play("hero" if best == "hero" else "pet", -4.0 if best == "hero" else 0.0, 0.08)
	return true

const PET_TIME := 0.9

func _animate_petted(delta: float) -> void:
	for key in _petted.keys():
		var left: float = _petted[key] - delta
		var rig: Node2D = _actors[key].pose
		if left <= 0.0:
			_petted.erase(key)
			rig.position = Vector2.ZERO
			if key == "hero":
				rig.play("idle", true)
			continue
		_petted[key] = left
		if key == "hero":
			# Its own cheer clip already hops; only face the player while it plays.
			rig.scale = Vector2(HERO_RIG_SCALE * _actors[key].facing, HERO_RIG_SCALE)
			rig.play("cheer")
			continue
		# One happy hop with a squash on landing.
		var t := 1.0 - left / PET_TIME
		var hop := sin(clampf(t / 0.55, 0.0, 1.0) * PI)
		rig.position = Vector2(0, -hop * 14.0)
		var squash := 1.0 + 0.12 * sin(clampf((t - 0.55) / 0.45, 0.0, 1.0) * PI)
		rig.scale = Vector2(RIG_SCALE * _actors[key].facing * squash, RIG_SCALE / squash)
		rig.play("happy")


func _pose() -> void:
	_resident("cream", "tunnel", fposmod(_clock, 28.0), -1.0)
	_resident("calico", "bed", fposmod(_clock + 2.0, 28.0), -1.0)
	_tabby_rounds(fposmod(_clock, TABBY_LOOP))
	_hero_rounds(fposmod(_clock, HERO_LOOP))

## The tabby's round of the courtyard: from the gate to each toy, playing a while at each.
## [toy or "" for the gate, seconds spent playing there]; walking time comes from distance.
const TABBY_ROUTE := [["", 3.0], ["yarn", 5.0], ["post", 6.0], ["fish", 5.0], ["pillow", 12.0]]
## Where a cat lies on the pillow's top (art px), how high and long its hop is.
const PILLOW_TOP := Vector2(630, 870)
const HOP_TIME := 0.45
const HOP_HEIGHT := 34.0
const GATE := Vector2(375, 786)
const WALK_SPEED := 46.0
const TABBY_LOOP := 60.0

func _tabby_rounds(t: float) -> void:
	_props["pillow"].occupant = ""
	var at: Vector2 = GATE
	for i in TABBY_ROUTE.size() + 1:
		var stop: Array = TABBY_ROUTE[i % TABBY_ROUTE.size()]
		var toy: String = stop[0]
		var to: Vector2 = GATE if toy == "" else TOYS[toy].spot
		var walk := at.distance_to(to) / WALK_SPEED
		if t < walk:
			_place_cat("tabby", _travel(at, to, t / maxf(walk, 0.01)), "", true, "walk", to.x - at.x)
			return
		t -= walk
		if i == TABBY_ROUTE.size():
			break
		var play: float = stop[1]
		if t < play and toy == "pillow":
			_pillow_nap("tabby", to, t, play)
			return
		if t < play:
			var anim: String = "idle" if toy == "" else TOYS[toy].anim
			_place_cat("tabby", to, "", false, anim, (TOYS["post"].spot.x - to.x) if toy == "fish" else 0.0)
			return
		t -= play
		at = to
	_place_cat("tabby", GATE, "", false, "idle")

## On the pillow: hop up, knead the cushion a moment, curl up and nap, hop back down.
func _pillow_nap(key: String, front: Vector2, t: float, play: float) -> void:
	var pillow: Dictionary = _props["pillow"]
	if t < HOP_TIME or t > play - HOP_TIME:
		var u := t / HOP_TIME if t < HOP_TIME else (play - t) / HOP_TIME
		var p := front.lerp(PILLOW_TOP, u) - Vector2(0, sin(PI * u) * HOP_HEIGHT)
		# Drawn over the cushion as soon as its feet leave the ground in front of it
		# (y-sorting alone would put the rising cat behind the pillow).
		var on_top := u > 0.15
		pillow.occupant = key if on_top else ""
		_place_cat(key, p, "pillow" if on_top else "", false, "hop")
		return
	pillow.occupant = key
	_place_cat(key, PILLOW_TOP, "pillow", false, "knead" if t < HOP_TIME + 1.8 else "rest_inside")


## The hero cat's round: it guards the castle rather than play. It marches between posts in
## front of the gate and, at each, strikes a pose, trains, or keeps watch.
## [spot (720x1280 art px), action, seconds there]; walking time comes from distance.
const HERO_ROUTE := [
	[Vector2(300, 760), "pose", 4.0],
	[Vector2(440, 748), "train", 3.6],
	[Vector2(470, 770), "look", 3.4],
	[Vector2(330, 778), "train", 3.6],
	[Vector2(372, 754), "idle", 3.0],
]
const HERO_WALK_SPEED := 40.0
const HERO_LOOP := 40.0

func _hero_rounds(t: float) -> void:
	var at: Vector2 = HERO_ROUTE[-1][0]
	for stop in HERO_ROUTE:
		var to: Vector2 = stop[0]
		var walk := at.distance_to(to) / HERO_WALK_SPEED
		if t < walk:
			_place_cat("hero", _travel(at, to, t / maxf(walk, 0.01)), "", true, "walk", to.x - at.x)
			return
		t -= walk
		var stay: float = stop[2]
		if t < stay:
			# Face the courtyard's middle while posing / training; look turns on its own.
			_place_cat("hero", to, "", false, stop[1], 360.0 - to.x)
			return
		t -= stay
		at = to
	_place_cat("hero", at, "", false, "idle")


func _resident(key: String, kind: String, time: float, wander_side: float) -> void:
	var prop: Dictionary = _props[kind]
	var ground: Vector2 = prop.ground
	# The calico's tail extends farther on image-right. Keep its whole silhouette
	# clear of the front rim at the layer handoff, without changing the art/scale.
	if kind == "bed":
		ground.x -= 2.0
	var inside := ground + Vector2(0, -12)
	var threshold := ground + Vector2(0, 10)
	var approach := ground + Vector2(0, 49)
	var outside := approach + Vector2(58 * wander_side, 12)
	var p := inside
	var in_slot := true
	var walking := true
	var state := "rest_inside"
	if time < 6.0:
		walking = false
	elif time < 8.0:
		p = _travel(inside, threshold, (time - 6.0) / 2.0)
		state = "exit"
	elif time < 10.0:
		p = _travel(threshold, approach, (time - 8.0) / 2.0)
		in_slot = false
		state = "exit"
	elif time < 13.0:
		p = _travel(approach, outside, (time - 10.0) / 3.0)
		in_slot = false
		state = "walk"
	elif time < 17.0:
		p = outside
		walking = false
		in_slot = false
		state = "rest_outside"
		# Outside its box, the cat plays with the toy nearest to where it stopped.
		var toy := _nearest_toy(outside)
		if toy != "" and outside.distance_to(TOYS[toy].spot) < 90.0:
			state = TOYS[toy].anim
	elif time < 20.0:
		p = _travel(outside, approach, (time - 17.0) / 3.0)
		in_slot = false
		state = "approach"
	elif time < 23.0:
		p = _travel(approach, threshold, (time - 20.0) / 3.0)
		in_slot = false
		state = "approach"
	elif time < 25.0:
		p = _travel(threshold, inside, (time - 23.0) / 2.0)
		state = "enter"
	else:
		walking = false
	prop.occupant = key if in_slot else ""
	_place_cat(key, p, kind if in_slot else "", walking, state)


func _nearest_toy(p: Vector2) -> String:
	var best := ""
	for toy in TOYS:
		if best == "" or p.distance_to(TOYS[toy].spot) < p.distance_to(TOYS[best].spot):
			best = toy
	return best

func _travel(from: Vector2, to: Vector2, weight: float) -> Vector2:
	return from.lerp(to, clampf(weight, 0.0, 1.0))


## `face_dx` turns the cat toward a direction (its sign); 0 keeps the last facing.
func _place_cat(key: String, position_px: Vector2, kind: String, walking: bool, state: String, face_dx := 0.0) -> void:
	var data: Dictionary = _actors[key]
	var actor: Node2D = data.root
	var parent: Node2D = _depth if kind.is_empty() else _props[kind].slot
	if actor.get_parent() != parent:
		actor.reparent(parent, true)
	actor.global_position = _world.to_global(position_px)
	# Preserve scale at the handoff. Never shrink or fade an entering cat.
	actor.global_scale = _world.global_scale
	data.position = position_px
	data.state = state
	if absf(face_dx) > 1.0:
		data.facing = signf(face_dx)
	var rig: Node2D = data.pose
	if _petted.has(key):
		return
	if key == "hero":
		rig.scale = Vector2(HERO_RIG_SCALE * data.facing, HERO_RIG_SCALE)
		rig.play("walk" if walking else state)
		return
	rig.scale = Vector2(RIG_SCALE * data.facing, RIG_SCALE)
	rig.play(_anim_for(state, walking))

# Rig animation for a lobby state.
func _anim_for(state: String, walking: bool) -> String:
	if walking:
		return "walk"
	match state:
		"scratch", "bat", "knead":
			return state
		"rest_inside":
			return "nap"
	return "idle"

func get_review_state() -> Dictionary:
	var tabby: Dictionary = _actors.tabby
	var actor_ids: Array = []
	var actors: Array = []
	var reservations: Dictionary = {}
	for key in _actors:
		var data: Dictionary = _actors[key]
		actor_ids.append(data.root.get_instance_id())
		actors.append({"name": key, "position": [data.position.x, data.position.y], "state": data.state, "facing": "front",
			"animation": data.pose.animation, "parent": str(data.root.get_parent().name)})
	for key in _props:
		reservations[key] = {"reserved_by": _props[key].reservation, "occupant": _props[key].occupant}
	return {"world_id": get_instance_id(), "actor_id": tabby.root.get_instance_id(),
		"actor_ids": actor_ids, "clock": _clock, "position": tabby.position,
		"active": _active, "processing": is_processing(), "front_only": true,
		"world_scale": _world.scale, "castle_level": _castle_level,
		"actors": actors, "reservations": reservations}
