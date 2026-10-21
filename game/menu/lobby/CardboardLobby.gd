extends Control

# Approved courtyard art with the SVG prop/actor depth contract from the pilot.
# Home owns this once; refreshing a page must never restart its actors.
const ART := "res://game/assets/lobby/cardboard/"
const CANVAS := Vector2(720, 1280)
const PROP_ORIGIN := Vector2(128, 224)
const CAT_ORIGIN := Vector2(128, 238)
const CAT_SCALE := 0.37
const LAYERS := ["tail", "foot_L_image", "foot_R_image", "body", "paw_L_image", "paw_R_image", "head"]

var _world: Node2D
var _depth: Node2D
var _props: Dictionary = {}
var _actors: Dictionary = {}
var _clock := 0.0
var _active := false
var _castle_level := 1


func _ready() -> void:
	name = "CardboardLobby"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world = Node2D.new()
	add_child(_world)
	_part(_world, "terrain-clean.png", Vector2.ZERO)
	_depth = Node2D.new()
	_depth.name = "FootDepthWorld"
	_depth.y_sort_enabled = true
	_world.add_child(_depth)
	var castle := Node2D.new()
	castle.name = "CardboardCastle"
	castle.position = Vector2(365, 646)
	_depth.add_child(castle)
	_part(castle, "castle-layer.png", castle.position)
	_make_prop("tunnel", Vector2(165, 790), 0.82)
	_make_prop("bed", Vector2(530, 866), 0.86)
	var yarn := Node2D.new()
	yarn.name = "YarnForeground"
	yarn.position = Vector2(214, 854)
	_depth.add_child(yarn)
	_part(yarn, "yarn-foreground.png", yarn.position)
	var pillow := Node2D.new()
	pillow.name = "PillowForeground"
	pillow.position = Vector2(630, 903)
	_depth.add_child(pillow)
	_part(pillow, "pillow-foreground.png", pillow.position)
	_make_cat("cream", "cat_cream")
	_make_cat("tabby", "cat_tabby")
	_make_cat("calico", "cat_calico")
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


func _make_cat(key: String, source: String) -> void:
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
	var pose := Node2D.new()
	pose.name = "FrontVisual"
	pose.scale = Vector2.ONE * CAT_SCALE
	actor.add_child(pose)
	var feet: Array[Node2D] = []
	for layer: String in LAYERS:
		var path := "cats/" + source + "/" + layer + ".svg"
		if layer.begins_with("foot_"):
			var pivot := Node2D.new()
			var at := Vector2(82, 203) if layer == "foot_L_image" else Vector2(174, 203)
			pivot.position = at - CAT_ORIGIN
			pose.add_child(pivot)
			_part(pivot, path, at)
			feet.append(pivot)
		else:
			_part(pose, path, CAT_ORIGIN)
	_actors[key] = {"root": actor, "pose": pose, "feet": feet, "state": "rest", "position": Vector2.ZERO}


func set_active(active: bool) -> void:
	_active = active
	visible = active
	set_process(active)


func sync_castle_level() -> void:
	# Only the approved castle illustration is shipped. Upgrade stats stay in PlayerData;
	# do not invent unreviewed tier artwork or reconstruct the world on an upgrade.
	_castle_level = PlayerData.castle_level


func _process(delta: float) -> void:
	_clock += delta
	_pose()


func _pose() -> void:
	_resident("cream", "tunnel", fposmod(_clock, 28.0), -1.0)
	_resident("calico", "bed", fposmod(_clock + 2.0, 28.0), -1.0)
	var t := fposmod(_clock, 24.0)
	var p := Vector2(375, 786)
	var walking := true
	if t < 4.0:
		walking = false
	elif t < 9.0:
		p = _travel(p, Vector2(342, 881), (t - 4.0) / 5.0)
	elif t < 13.0:
		p = _travel(Vector2(342, 881), Vector2(399, 875), (t - 9.0) / 4.0)
	elif t < 18.0:
		p = _travel(Vector2(399, 875), Vector2(375, 786), (t - 13.0) / 5.0)
	else:
		walking = false
	_place_cat("tabby", p, "", walking, "walk" if walking else "rest")


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


func _travel(from: Vector2, to: Vector2, weight: float) -> Vector2:
	return from.lerp(to, clampf(weight, 0.0, 1.0))


func _place_cat(key: String, position_px: Vector2, kind: String, walking: bool, state: String) -> void:
	var data: Dictionary = _actors[key]
	var actor: Node2D = data.root
	var parent: Node2D = _depth if kind.is_empty() else _props[kind].slot
	if actor.get_parent() != parent:
		actor.reparent(parent, true)
	actor.global_position = _world.to_global(position_px)
	# Preserve scale at the handoff. Never shrink, fade or flip an entering cat.
	actor.global_scale = _world.global_scale
	data.position = position_px
	data.state = state
	var phase := _clock * TAU * 1.6
	var amount := 1.0 if walking else 0.0
	for i in data.feet.size():
		var pivot: Node2D = data.feet[i]
		var sign_x := 1.0 if i == 0 else -1.0
		var at := Vector2(82, 203) if i == 0 else Vector2(174, 203)
		pivot.rotation = sin(phase) * 0.11 * sign_x * amount
		pivot.position = at - CAT_ORIGIN + Vector2(0, -maxf(0.0, sin(phase) * sign_x) * 3 * amount)
	data.pose.position.y = -absf(sin(phase)) * 1.3 * CAT_SCALE * amount


func get_review_state() -> Dictionary:
	var tabby: Dictionary = _actors.tabby
	var actor_ids: Array = []
	var actors: Array = []
	var reservations: Dictionary = {}
	for key in _actors:
		var data: Dictionary = _actors[key]
		actor_ids.append(data.root.get_instance_id())
		actors.append({"name": key, "position": [data.position.x, data.position.y], "state": data.state, "facing": "front", "parent": str(data.root.get_parent().name)})
	for key in _props:
		reservations[key] = {"reserved_by": _props[key].reservation, "occupant": _props[key].occupant}
	return {"world_id": get_instance_id(), "actor_id": tabby.root.get_instance_id(),
		"actor_ids": actor_ids, "clock": _clock, "position": tabby.position,
		"active": _active, "processing": is_processing(), "front_only": true,
		"world_scale": _world.scale, "castle_level": _castle_level,
		"actors": actors, "reservations": reservations}
