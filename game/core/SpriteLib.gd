extends Node

# Builds and caches SpriteFrames and textures at runtime: the drawn cat and monster units,
# the battle effects (game/assets/battle/fx, tools/ui/make_battle_fx.py) and the legacy Cozy UI.

const FX := "res://game/assets/battle/fx/"
const COZY := "res://DEMO_Cozy_UI_Pack_doboui/"

## Battle effects: one horizontal strip of square frames each (frame = strip height).
const EFFECTS := {
	"dust": {}, "dust2": {}, "explosion": {}, "blast": {},
	"fire": {"loop": true}, "heal": {},
}

var _textures := {}
var _frames := {}


## A still from game/assets/battle/fx (the arrows).
func fx_texture(name: String) -> Texture2D:
	var key := "fx_tex/" + name
	if not _textures.has(key):
		_textures[key] = load(FX + name + ".png")
	return _textures[key]


func unit_frames(unit_key: String, _color := "") -> SpriteFrames:
	return _cat_frames(unit_key)


## Card and button picture of a unit (all units are drawn art now).
func portrait(unit_key: String, _color := "") -> Texture2D:
	return cat_texture(unit_key)


## A Cozy UI Pack image shrunk to `scale` (its art is drawn large and smooth), cached.
## 9-slice margins stay small enough for phone-sized buttons this way.
func cozy(path: String, scale := 1.0) -> Texture2D:
	var key := "cozy/%s/%s" % [path, scale]
	if _textures.has(key):
		return _textures[key]
	var source: Texture2D = load(COZY + path)
	var result: Texture2D = source
	if scale != 1.0:
		var image := source.get_image()
		if image.is_compressed():
			image.decompress()
		image.resize(maxi(1, roundi(image.get_width() * scale)), maxi(1, roundi(image.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
		result = ImageTexture.create_from_image(image)
	_textures[key] = result
	return result


# A round black bomb with a fuse, drawn once (the pack has no bomb sprite).
func bomb_texture() -> Texture2D:
	if _textures.has("bomb"):
		return _textures["bomb"]
	var image := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 17.5).length()
			if d <= 11.0:
				var shade := 0.12 + 0.18 * clampf(1.0 - Vector2(x - 12, y - 14).length() / 10.0, 0.0, 1.0)
				image.set_pixel(x, y, Color(shade, shade, shade + 0.03) if d <= 10.0 else Color(0.02, 0.02, 0.03))
	for i in 5:
		image.set_pixel(18 + i / 2, 6 - i, Color("c9a26b"))
	image.set_pixel(21, 1, Color("ffd35c"))
	image.set_pixel(22, 1, Color("ff7a2a"))
	image.set_pixel(21, 0, Color("ff7a2a"))
	var result := ImageTexture.create_from_image(image)
	_textures["bomb"] = result
	return result


# Player troops change uniform as their gear tiers up.
func player_color(tier: int) -> String:
	if tier >= 5:
		return "Yellow"
	if tier >= 3:
		return "Purple"
	return "Blue"


func foot_offset(unit_key: String) -> float:
	if unit_key.begins_with("art:") or unit_key.begins_with("hero:"):
		return ART_SIZE.y / 2.0 - 4.0
	return CAT_CANVAS.y / 2.0 - 2.0


# --- Cat soldiers ----------------------------------------------------------------------------
# unit_key "cat:<coat>:<weapon>": the skin's cat (game/ui/skin/cat_<coat>.svg) holding its
# weapon icon (icon_w_<weapon>), baked into one smooth texture. It has no drawn animation
# frames; Unit.gd bobs and swings it instead. Draw it with linear filtering.

const SKIN := "res://game/ui/skin/"
const RASTER_ART := "res://game/ui/art/"
const HeroCat = preload("res://game/core/HeroCat.gd")
const HERO_WEAPON_ART := {
	"kiem_go": "hero_cat_melee", "cung_san": "hero_cat_ranged",
	"gay_sao": "hero_cat_magic", "riu_lua": "hero_cat_heavy",
	"katana_nguyet": "hero_cat_katana",
}
const CAT_CANVAS := Vector2i(128, 104)
const CAT_SIZE := Vector2i(107, 100)
## Where the weapon's 64 px icon goes: hilt at the cat's right paw, blade up and out.
const CAT_WEAPON_AT := Vector2i(62, 28)


## Drawn units (cats, generals, monsters) rather than the pixel-art pack.
static func is_cat(unit_key: String) -> bool:
	return unit_key.begins_with("cat:") or unit_key.begins_with("art:") or unit_key.begins_with("icon:") or unit_key.begins_with("hero:")


## Size the drawn unit SVGs (256x240) are baked at.
const ART_SIZE := Vector2i(128, 120)


func cat_texture(unit_key: String) -> Texture2D:
	var key := "tex/" + unit_key
	if _textures.has(key):
		return _textures[key]
	if unit_key.begins_with("icon:"):
		var face := ImageTexture.create_from_image(_skin_image("icon_" + unit_key.substr(5), Vector2i(112, 112)))
		_textures[key] = face
		return face
	if unit_key.begins_with("art:") or unit_key.begins_with("hero:"):
		# "hero:<family>" is the hero cat holding its weapon (game/ui/art/hero_cat_<family>.png).
		var file := "unit_" + unit_key.substr(4) if unit_key.begins_with("art:") else "hero_cat_" + unit_key.substr(5)
		var art := ImageTexture.create_from_image(_skin_image(file, ART_SIZE))
		_textures[key] = art
		return art
	var parts := unit_key.split(":")
	var canvas := Image.create_empty(CAT_CANVAS.x, CAT_CANVAS.y, false, Image.FORMAT_RGBA8)
	var cat := _skin_image("cat_" + parts[1], CAT_SIZE)
	canvas.blend_rect(cat, Rect2i(Vector2i.ZERO, cat.get_size()), Vector2i(0, CAT_CANVAS.y - CAT_SIZE.y))
	if parts.size() > 2:
		var weapon := _skin_image("icon_w_%s_64" % parts[2], Vector2i(64, 64))
		canvas.blend_rect(weapon, Rect2i(Vector2i.ZERO, weapon.get_size()), CAT_WEAPON_AT)
	var result := ImageTexture.create_from_image(canvas)
	_textures[key] = result
	return result


func _skin_image(file: String, size: Vector2i) -> Image:
	var raster := RASTER_ART + file + ".png"
	var source := raster if ResourceLoader.exists(raster) else SKIN + file + ".svg"
	var image: Image = load(source).get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	if image.get_size() != size:
		image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	return image


## Only the equipped weapon changes this original hero's front-facing look.
## The three other slots keep their existing stats and standalone item icons.
## Cache by artwork, so a level/stat upgrade never creates another costume.
func hero_cat_texture(state: Dictionary) -> Texture2D:
	var uid := HeroCat.equipped_uid(state, "weapon")
	var definition := HeroCat.def(state, uid)
	var weapon_id := str(HeroCat.item(state, uid).get("id", "")) if not definition.is_empty() else ""
	var art_name: String = HERO_WEAPON_ART.get(weapon_id, "hero_cat_bare")
	var key := "hero_cat/" + art_name
	if not _textures.has(key):
		_textures[key] = load(RASTER_ART + art_name + ".png")
	return _textures[key]


## Same texture in every frame: idle and run loop, attack plays once (its length sets
## when the hit lands, as for the pack's units).
func _cat_frames(unit_key: String) -> SpriteFrames:
	if _frames.has(unit_key):
		return _frames[unit_key]
	var tex := cat_texture(unit_key)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim in [["idle", 1, 4.0, true], ["run", 4, 10.0, true], ["attack", 6, 12.0, false]]:
		frames.add_animation(anim[0])
		frames.set_animation_speed(anim[0], anim[2])
		frames.set_animation_loop(anim[0], anim[3])
		for i in anim[1]:
			frames.add_frame(anim[0], tex)
	_frames[unit_key] = frames
	return frames


func effect_frames(effect: String) -> SpriteFrames:
	var key := "fx/" + effect
	if _frames.has(key):
		return _frames[key]
	var sheet: Texture2D = load(FX + effect + ".png")
	var frames := SpriteFrames.new()
	_add_strip(frames, "default", sheet, sheet.get_height(), 16.0, EFFECTS[effect].get("loop", false))
	_frames[key] = frames
	return frames


func _add_strip(frames: SpriteFrames, anim: String, sheet: Texture2D, frame_size: int, fps: float, loop: bool) -> void:
	if not frames.has_animation(anim):
		frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in floori(float(sheet.get_width()) / frame_size):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_size, 0, frame_size, frame_size)
		frames.add_frame(anim, atlas)
