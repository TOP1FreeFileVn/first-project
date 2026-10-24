extends Control

## The original equipment hero, played as separate parts by the existing Spine
## runtime. Only the held weapon changes the model; the other slots add stats.
const HeroCat = preload("res://game/core/HeroCat.gd")
const SoldierRig = preload("res://game/battle/SoldierRig.gd")
const FAMILIES := {
	"kiem_go": "melee", "cung_san": "ranged", "gay_sao": "magic",
	"riu_lua": "heavy", "katana_nguyet": "katana",
}
## Includes the complete 1.2-second idle sweep, not just the setup pose.
const MODEL_RECT := Rect2(-128, -248, 272, 256)

var family := "bare"
var rig: SoldierRig
var _loaded_family := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(_fit_rig)
	visibility_changed.connect(_sync_visibility)


func _ready() -> void:
	rig = SoldierRig.new()
	rig.name = "HeroRig"
	add_child(rig)
	_load_family()


func setup(state: Dictionary) -> void:
	var uid := HeroCat.equipped_uid(state, "weapon")
	var weapon_id := str(HeroCat.item(state, uid).get("id", ""))
	family = FAMILIES.get(weapon_id, "bare")
	if is_node_ready():
		_load_family()


func _load_family() -> void:
	if family != _loaded_family:
		var path := "res://game/assets/hero/%s/%s.json" % [family, family]
		rig.skeleton_file = path
		rig.load_skeleton(path)
		rig.play("idle", true)
		_loaded_family = family
	_fit_rig()
	_sync_visibility()


func _fit_rig() -> void:
	if not is_instance_valid(rig) or size.x <= 0 or size.y <= 0:
		return
	var available := (size - Vector2.ONE * 8).max(Vector2.ONE)
	var fitted_scale := minf(available.x / MODEL_RECT.size.x, available.y / MODEL_RECT.size.y)
	rig.scale = Vector2.ONE * fitted_scale
	rig.position = size * 0.5 - MODEL_RECT.get_center() * fitted_scale


func _sync_visibility() -> void:
	if is_instance_valid(rig):
		rig.set_process(is_visible_in_tree())
