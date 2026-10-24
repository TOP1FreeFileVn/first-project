extends RefCounted

## The approved equipment face is shared by the hero bag, chest reveals and
## reward rows. Empty-slot symbols remain separate from these filled badges.
const PaperboardFrame = preload("res://game/ui/PaperboardFrame.gd")
const BADGE_GLYPH = preload("res://game/ui/equipment_badge_glyph.gdshader")
const CATEGORY_BADGES := {
	"weapon": preload("res://game/ui/art/equipment_badge_weapon.svg"),
	"helmet": preload("res://game/ui/art/equipment_badge_helmet.svg"),
	"armor": preload("res://game/ui/art/equipment_badge_armor.svg"),
	"boots": preload("res://game/ui/art/equipment_badge_boots.svg"),
}

static var _badge_textures: Dictionary = {}
static var _badge_materials: Dictionary = {}


## Decorate only real equipment categories; unrelated preview cards keep their
## existing face. The item art itself has already resolved via Ui.icon_tex().
static func apply(card: Control, type_icon: String, tone: String, size: float) -> void:
	var slot := type_icon.trim_prefix("slot_")
	if not type_icon.begins_with("slot_") or not CATEGORY_BADGES.has(slot):
		return
	var old_frame := card.get_child(0)
	card.remove_child(old_frame)
	old_frame.queue_free()
	var frame := PaperboardFrame.new()
	frame.kind = "card"
	frame.tone = tone
	card.add_child(frame)
	card.move_child(frame, 0)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var old_badge: TextureRect = card.get_node("SlotBadge")
	var badge_index := old_badge.get_index()
	card.remove_child(old_badge)
	old_badge.queue_free()
	var badge_size := size * 0.29
	var badge_position := Vector2(-2, -2)
	var badge_frame := PaperboardFrame.new()
	badge_frame.name = "EquipmentCategoryBadge"
	badge_frame.kind = "badge"
	badge_frame.tone = tone
	badge_frame.custom_minimum_size = Vector2.ONE * badge_size
	card.add_child(badge_frame)
	badge_frame.position = badge_position
	badge_frame.size = badge_frame.custom_minimum_size
	card.move_child(badge_frame, badge_index)

	var badge := TextureRect.new()
	badge.name = "SlotBadge"
	badge.texture = _category_texture(slot)
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2.ONE * (badge_size - 12)
	badge.material = _category_material(tone)
	card.add_child(badge)
	badge.position = badge_position + Vector2.ONE * 6
	badge.size = badge.custom_minimum_size
	card.move_child(badge, badge_index + 1)

	var level := card.get_node_or_null("EquipmentLevel") as Label
	if level != null:
		level.add_theme_color_override("font_color", Color.WHITE)
		level.add_theme_color_override("font_outline_color", Color("241c1c"))
		level.add_theme_constant_override("outline_size", 3)


## Center painted bounds, not the source SVG's transparent margins.
static func _category_texture(slot: String) -> Texture2D:
	if _badge_textures.has(slot):
		return _badge_textures[slot]
	var source: Texture2D = CATEGORY_BADGES[slot]
	var bounds := source.get_image().get_used_rect()
	if not bounds.has_area():
		return source
	var cropped := AtlasTexture.new()
	cropped.atlas = source
	cropped.region = bounds
	cropped.filter_clip = true
	_badge_textures[slot] = cropped
	return cropped


static func _category_material(tone: String) -> ShaderMaterial:
	if not _badge_materials.has(tone):
		var material := ShaderMaterial.new()
		material.shader = BADGE_GLYPH
		material.set_shader_parameter("accent_color", PaperboardFrame.BADGE_ACCENTS.get(tone, Color("a29480")))
		_badge_materials[tone] = material
	return _badge_materials[tone]
