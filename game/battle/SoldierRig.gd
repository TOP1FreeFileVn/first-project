extends Node2D

# Plays the small Spine rigs made by tools/ui/make_soldier_spine.py and friends (cats and
# monsters drawn as separate parts). Only what those rigs use: a bone tree without setup
# rotations, region attachments, linear translate / rotate / scale keys, and slots that an
# animation shows (a slot with no setup attachment is hidden unless the animation keys it,
# e.g. the lobby cats' shut eyes). It is not a general Spine runtime.
#
# Skeleton units are pixels with Y up and the origin on the ground; this node draws with Y
# down, so its own origin is the cat's feet.

@export_file("*.json") var skeleton_file := ""
@export var animation := "run"
@export var speed := 1.0

## Fired once per loop when the animation passes an event key (e.g. "hit" when the blade lands).
signal event(name: String)

var _bones: Array = []        # [{name, parent index, x, y}] in file order (parents first)
var _slots: Array = []        # [{name, bone index, texture, rect: Rect2 in bone space (Y down), shown}]
var _anims := {}
var _time := 0.0
var _world: Array[Transform2D] = []

func _ready() -> void:
	if skeleton_file != "":
		load_skeleton(skeleton_file)

func load_skeleton(path: String) -> void:
	if not _cache.has(path):
		_cache[path] = [JSON.parse_string(FileAccess.get_file_as_string(path)), _read_atlas(path.get_basename() + ".atlas")]
	var data: Dictionary = _cache[path][0]
	var regions: Dictionary = _cache[path][1]
	var index := {}
	_bones.clear()
	for b in data["bones"]:
		index[b["name"]] = _bones.size()
		_bones.append({"name": b["name"], "parent": index.get(b.get("parent", ""), -1),
			"x": float(b.get("x", 0.0)), "y": float(b.get("y", 0.0))})
	var atts: Dictionary = data["skins"][0]["attachments"]
	_slots.clear()
	for s in data["slots"]:
		var att_name: String = s.get("attachment", s["name"])
		var a: Dictionary = atts[s["name"]][att_name]
		var tex: AtlasTexture = regions[att_name]
		var size := Vector2(float(a["width"]) * float(a.get("scaleX", 1.0)), float(a["height"]) * float(a.get("scaleY", 1.0)))
		var centre := Vector2(float(a["x"]), -float(a["y"]))
		_slots.append({"name": s["name"], "bone": index[s["bone"]], "texture": tex,
			"rect": Rect2(centre - size / 2.0, size), "shown": s.has("attachment")})
	_anims = data.get("animations", {})
	_world.resize(_bones.size())
	_time = 0.0
	queue_redraw()

## Switches animation. `restart` replays it from the start even if it is already playing.
func play(anim: String, restart := false) -> void:
	if anim != animation or restart:
		animation = anim
		_time = 0.0

func has_animation(anim: String) -> bool:
	return _anims.has(anim)

## A bone's transform in this node's space as last drawn (identity before the first draw),
## for props pinned to a paw, e.g. the lobby's building hammers.
func bone_transform(bone_name: String) -> Transform2D:
	for i in _bones.size():
		if _bones[i]["name"] == bone_name and i < _world.size():
			return _world[i]
	return Transform2D.IDENTITY

## Seconds into the current animation where its first `name` event sits, or -1.
func event_time(name: String) -> float:
	for e in _anims.get(animation, {}).get("events", []):
		if e.get("name", "") == name:
			return float(e.get("time", 0.0))
	return -1.0

## Length of an animation in seconds.
func length(anim: String) -> float:
	return _duration(_anims.get(anim, {}))

## Skeletons are cached per file: every soldier of a kind shares one parsed copy.
static var _cache := {}

static func _read_atlas(path: String) -> Dictionary:
	var page: Texture2D = null
	var out := {}
	var current := ""
	for line in FileAccess.get_file_as_string(path).split("\n"):
		line = line.strip_edges()
		if line == "":
			continue
		if page == null:
			page = load(path.get_base_dir().path_join(line))
		elif line.begins_with("bounds:"):
			var v := line.substr(7).split(",")
			var region := AtlasTexture.new()
			region.atlas = page
			region.region = Rect2(int(v[0]), int(v[1]), int(v[2]), int(v[3]))
			out[current] = region
		elif not line.contains(":"):
			current = line
	return out

func _process(delta: float) -> void:
	var anim: Dictionary = _anims.get(animation, {})
	var dur := _duration(anim)
	var before := _time
	_time += delta * speed
	if dur > 0.0:
		for e in anim.get("events", []):
			var at := float(e.get("time", 0.0))
			# Crossing `at` in this frame, counting loops.
			if floor((before - at) / dur) != floor((_time - at) / dur):
				event.emit(String(e["name"]))
	queue_redraw()

func _duration(anim: Dictionary) -> float:
	if anim.has("_duration"):
		return anim["_duration"]
	var d := 0.0
	for timeline in anim.get("bones", {}).values():
		for channel in timeline.values():
			for k in channel:
				d = maxf(d, float(k.get("time", 0.0)))
	return d

static func _sample(track: Array, t: float, defaults: Dictionary) -> Dictionary:
	if track.is_empty():
		return defaults
	var prev: Dictionary = track[0]
	if t <= float(prev.get("time", 0.0)):
		return prev
	for i in range(1, track.size()):
		var next: Dictionary = track[i]
		var t0 := float(prev.get("time", 0.0))
		var t1 := float(next.get("time", 0.0))
		if t <= t1:
			var u := (t - t0) / maxf(t1 - t0, 0.0001)
			var out := {}
			for key in defaults:
				out[key] = lerpf(float(prev.get(key, defaults[key])), float(next.get(key, defaults[key])), u)
			return out
		prev = next
	return prev

func _draw() -> void:
	if _bones.is_empty():
		return
	var anim: Dictionary = _anims.get(animation, {})
	var timelines: Dictionary = anim.get("bones", {})
	var dur := _duration(anim)
	var t := fposmod(_time, dur) if dur > 0.0 else 0.0
	for i in _bones.size():
		var b: Dictionary = _bones[i]
		var tl: Dictionary = timelines.get(b["name"], {})
		var tr := _sample(tl.get("translate", []), t, {"x": 0.0, "y": 0.0})
		var rot := _sample(tl.get("rotate", []), t, {"value": 0.0})
		var sc := _sample(tl.get("scale", []), t, {"x": 1.0, "y": 1.0})
		# Spine is Y up and counter-clockwise; flip both into Godot's Y-down space.
		var local := Transform2D(-deg_to_rad(float(rot.get("value", 0.0))),
			Vector2(float(sc.get("x", 1.0)), float(sc.get("y", 1.0))), 0.0,
			Vector2(b["x"] + float(tr.get("x", 0.0)), -(b["y"] + float(tr.get("y", 0.0)))))
		_world[i] = local if b["parent"] < 0 else _world[b["parent"]] * local
	var slot_keys: Dictionary = anim.get("slots", {})
	for s in _slots:
		var shown: bool = s["shown"]
		if slot_keys.has(s["name"]):
			var att: Array = slot_keys[s["name"]].get("attachment", [])
			if not att.is_empty():
				shown = att[0].get("name") != null
		if not shown:
			continue
		draw_set_transform_matrix(_world[s["bone"]])
		draw_texture_rect(s["texture"], s["rect"], false)
	draw_set_transform_matrix(Transform2D.IDENTITY)
