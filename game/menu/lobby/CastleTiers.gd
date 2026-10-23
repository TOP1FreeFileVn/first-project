extends Node2D

# The cardboard cat castle at the player's castle level, with waving flags.
# Art: game/assets/lobby/castle-tiers (from docs/design/2026-10-23/castle-tiers-canvas).
# Each tier spans two castle levels. The body has bare flag poles; each cloth is its own
# sprite on a subdivided mesh so flag_wave.gdshader can ripple it.
#
# Local frame: 440 x 380 art units, origin at the top-left; `scale_to` resizes it.

const DIR := "res://game/assets/lobby/castle-tiers/"
const TIERS := 5
const BODIES := [
	preload(DIR + "castle-tier-1-body.svg"), preload(DIR + "castle-tier-2-body.svg"),
	preload(DIR + "castle-tier-3-body.svg"), preload(DIR + "castle-tier-4-body.svg"),
	preload(DIR + "castle-tier-5-body.svg"),
]
const FLAG_BIG := preload(DIR + "flag-big.svg")
const FLAG_SMALL := preload(DIR + "flag-small.svg")
const WAVE := preload(DIR + "flag_wave.gdshader")
const ART_SIZE := Vector2(440, 380)
## Where the gate ramp meets the ground, in art units (for placing the castle).
const GATE_FOOT := Vector2(220, 354)

var _tier := 0
var _body: Sprite2D
var _flags: Array[MeshInstance2D] = []
var _anchors := {}
var _pad := 8.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var data = JSON.parse_string(FileAccess.get_file_as_string(DIR + "anchors.json"))
	if data is Dictionary:
		_anchors = data["tiers"]
		_pad = float(data["pad"])
	_body = Sprite2D.new()
	_body.centered = false
	add_child(_body)

## Castle tier (1-5) for a castle level (1-10): two levels per tier.
static func tier_for(level: int) -> int:
	return clampi((level + 1) / 2, 1, TIERS)

func set_level(level: int) -> void:
	var tier := tier_for(level)
	if tier == _tier:
		return
	_tier = tier
	_body.texture = BODIES[tier - 1]
	for flag in _flags:
		flag.queue_free()
	_flags.clear()
	var i := 0
	for a in _anchors.get(str(tier), []):
		var flag := make_flag(Vector2(a["x"], a["y"]), bool(a["big"]), i, _pad)
		add_child(flag)
		_flags.append(flag)
		i += 1

## A waving flag cloth whose hoist (pole-side top corner) hangs at `hoist`.
## Shared with the battle castle (Background.gd).
static func make_flag(hoist: Vector2, big: bool, index: int, pad: float) -> MeshInstance2D:
	var tex: Texture2D = FLAG_BIG if big else FLAG_SMALL
	var size := tex.get_size()
	var flag := MeshInstance2D.new()
	flag.texture = tex
	flag.mesh = _grid(size, 12, 3)
	flag.position = hoist - Vector2(pad, pad)
	var mat := ShaderMaterial.new()
	mat.shader = WAVE
	mat.set_shader_parameter("amplitude", 2.6 if big else 2.0)
	mat.set_shader_parameter("phase", index * 1.9)
	mat.set_shader_parameter("hoist_u", pad / size.x)
	flag.material = mat
	return flag

# A flat grid mesh covering `size`, so the vertex shader has points to bend.
static func _grid(size: Vector2, cols: int, rows: int) -> ArrayMesh:
	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for r in rows + 1:
		for c in cols + 1:
			var uv := Vector2(float(c) / cols, float(r) / rows)
			verts.append(uv * size)
			uvs.append(uv)
	for r in rows:
		for c in cols:
			var i := r * (cols + 1) + c
			idx.append_array([i, i + 1, i + cols + 1, i + 1, i + cols + 2, i + cols + 1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
