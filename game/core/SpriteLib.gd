extends Node

# Builds and caches SpriteFrames and textures from the Tiny Swords pack at runtime, so
# scenes don't need hand-made atlas resources for every unit and colour.

const ART := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/"
const COZY := "res://DEMO_Cozy_UI_Pack_doboui/"

# folder: unit folder in the pack (defaults to the key); frame: size of one square frame;
# foot: pixels from frame centre down to the feet; guard: optional block animation.
const UNIT_ANIMS := {
	"Warrior": {"frame": 192, "foot": 34, "idle": "Warrior_Idle", "run": "Warrior_Run", "attack": "Warrior_Attack1"},
	"Guard": {"folder": "Warrior", "frame": 192, "foot": 34, "idle": "Warrior_Idle", "run": "Warrior_Run", "attack": "Warrior_Attack1", "guard": "Warrior_Guard"},
	"General": {"folder": "Warrior", "frame": 192, "foot": 34, "idle": "Warrior_Idle", "run": "Warrior_Run", "attack": "Warrior_Attack2"},
	"Archer": {"frame": 192, "foot": 34, "idle": "Archer_Idle", "run": "Archer_Run", "attack": "Archer_Shoot"},
	"Lancer": {"frame": 320, "foot": 32, "idle": "Lancer_Idle", "run": "Lancer_Run", "attack": "Lancer_Right_Attack"},
	"Monk": {"frame": 192, "foot": 34, "idle": "Idle", "run": "Run", "attack": "Heal"},
	"Pawn": {"frame": 192, "foot": 34, "idle": "Pawn_Idle Axe", "run": "Pawn_Run Axe", "attack": "Pawn_Interact Axe"},
	"PawnPickaxe": {"folder": "Pawn", "frame": 192, "foot": 34, "idle": "Pawn_Idle Pickaxe", "run": "Pawn_Run Pickaxe", "attack": "Pawn_Interact Pickaxe"},
	"PawnHammer": {"folder": "Pawn", "frame": 192, "foot": 34, "idle": "Pawn_Idle Hammer", "run": "Pawn_Run Hammer", "attack": "Pawn_Interact Hammer"},
	"PawnKnife": {"folder": "Pawn", "frame": 192, "foot": 34, "idle": "Pawn_Idle Knife", "run": "Pawn_Run Knife", "attack": "Pawn_Interact Knife"},
	# Meat and gold carriers have no attack strip; their idle stands in for it.
	"PawnMeat": {"folder": "Pawn", "frame": 192, "foot": 34, "idle": "Pawn_Idle Meat", "run": "Pawn_Run Meat", "attack": "Pawn_Idle Meat"},
	"PawnBomb": {"folder": "Pawn", "frame": 192, "foot": 34, "idle": "Pawn_Idle Gold", "run": "Pawn_Run Gold", "attack": "Pawn_Idle Gold"},
}
const ANIM_FPS := {"idle": 8.0, "run": 10.0, "attack": 12.0}

const EFFECTS := {
	"dust": {"path": "Particle FX/Dust_01.png", "frame": 64},
	"explosion": {"path": "Particle FX/Explosion_01.png", "frame": 192},
	"blast": {"path": "Particle FX/Explosion_02.png", "frame": 192},
	"fire": {"path": "Particle FX/Fire_01.png", "frame": 64, "loop": true},
	"dust2": {"path": "Particle FX/Dust_02.png", "frame": 64},
	"heal": {"path": "Units/Blue Units/Monk/Heal_Effect.png", "frame": 192},
}

var _textures := {}
var _frames := {}
var _stitched := {}


func texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(ART + path)
	return _textures[path]


func unit_frames(unit_key: String, color: String) -> SpriteFrames:
	if is_cat(unit_key):
		return _cat_frames(unit_key)
	var key := unit_key + "/" + color
	if _frames.has(key):
		return _frames[key]
	var spec: Dictionary = UNIT_ANIMS[unit_key]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var folder: String = spec.get("folder", unit_key)
	for anim in ["idle", "run", "attack", "guard"]:
		if not spec.has(anim):
			continue
		var sheet := texture("Units/%s Units/%s/%s.png" % [color, folder, spec[anim]])
		_add_strip(frames, anim, sheet, spec["frame"], ANIM_FPS.get(anim, 12.0), anim == "idle" or anim == "run")
	_frames[key] = frames
	return frames


# Head-and-shoulders crop of a unit's first idle frame, for cards and buttons.
func portrait(unit_key: String, color := "Blue") -> Texture2D:
	if is_cat(unit_key):
		return cat_texture(unit_key)
	var key := "portrait/%s/%s" % [unit_key, color]
	if _textures.has(key):
		return _textures[key]
	var spec: Dictionary = UNIT_ANIMS[unit_key]
	var frame: int = spec["frame"]
	# Characters sit a little above the frame centre; crop a square around them.
	var center := Vector2(frame / 2.0, frame / 2.0 - 4.0)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture("Units/%s Units/%s/%s.png" % [color, spec.get("folder", unit_key), spec["idle"]])
	atlas.region = Rect2(center - Vector2(56, 56), Vector2(112, 112))
	_textures[key] = atlas
	return atlas


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
	if unit_key.begins_with("art:"):
		return ART_SIZE.y / 2.0 - 4.0
	if is_cat(unit_key):
		return CAT_CANVAS.y / 2.0 - 2.0
	return UNIT_ANIMS[unit_key]["foot"]


# --- Cat soldiers ----------------------------------------------------------------------------
# unit_key "cat:<coat>:<weapon>": the skin's cat (game/ui/skin/cat_<coat>.svg) holding its
# weapon icon (icon_w_<weapon>), baked into one smooth texture. It has no drawn animation
# frames; Unit.gd bobs and swings it instead. Draw it with linear filtering.

const SKIN := "res://game/ui/skin/"
const CAT_CANVAS := Vector2i(128, 104)
const CAT_SIZE := Vector2i(107, 100)
## Where the weapon's 64 px icon goes: hilt at the cat's right paw, blade up and out.
const CAT_WEAPON_AT := Vector2i(62, 28)


## Drawn units (cats, generals, monsters) rather than the pixel-art pack.
static func is_cat(unit_key: String) -> bool:
	return unit_key.begins_with("cat:") or unit_key.begins_with("art:") or unit_key.begins_with("icon:")


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
	if unit_key.begins_with("art:"):
		var art := ImageTexture.create_from_image(_skin_image("unit_" + unit_key.substr(4), ART_SIZE))
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
	var image: Image = load(SKIN + file + ".svg").get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	if image.get_size() != size:
		image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	return image


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


## A looping animation from a horizontal strip of square frames (trees, sheep, bushes...).
## A looping one-row strip. Frames are square unless `frame_width` says otherwise
## (the trees are 192 wide and 256 tall).
func strip_frames(path: String, fps := 8.0, frame_width := 0) -> SpriteFrames:
	var key := "strip/" + path
	if _frames.has(key):
		return _frames[key]
	var sheet := texture(path)
	var frames := SpriteFrames.new()
	var width: int = frame_width if frame_width > 0 else sheet.get_height()
	frames.set_animation_speed("default", fps)
	frames.set_animation_loop("default", true)
	for i in sheet.get_width() / width:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * width, 0, width, sheet.get_height())
		frames.add_frame("default", atlas)
	_frames[key] = frames
	return frames


func effect_frames(effect: String) -> SpriteFrames:
	var key := "fx/" + effect
	if _frames.has(key):
		return _frames[key]
	var spec: Dictionary = EFFECTS[effect]
	var frames := SpriteFrames.new()
	_add_strip(frames, "default", texture(spec["path"]), spec["frame"], 16.0, spec.get("loop", false))
	_frames[key] = frames
	return frames


# The pack ships 9-slice UI art as 64px pieces spaced 128px apart; pack them tight so
# the result can back a StyleBoxTexture.
func stitched(path: String, rows: Array, cols := [0, 128, 256], piece := 64, scale := 0.5) -> Texture2D:
	var key := "%s|%s|%s" % [path, rows, scale]
	if _stitched.has(key):
		return _stitched[key]
	var source := texture(path).get_image()
	if source.is_compressed():
		source.decompress()
	var image := Image.create_empty(cols.size() * piece, rows.size() * piece, false, source.get_format())
	for r in rows.size():
		for c in cols.size():
			image.blit_rect(source, Rect2i(cols[c], rows[r], piece, piece), Vector2i(c * piece, r * piece))
	if scale != 1.0:
		image.resize(roundi(image.get_width() * scale), roundi(image.get_height() * scale), Image.INTERPOLATE_NEAREST)
	var result := ImageTexture.create_from_image(image)
	_stitched[key] = result
	return result


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
