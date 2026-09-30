extends RefCounted

# Shared UI building blocks: theme, buttons, labels, ribbons, panels, currency rows and a
# modal popup. Used by the battle HUD and every menu page so the whole game looks the same.
# Two skins: "cozy" (Cozy UI Pack: wooden buttons, card popups, teal panels) and
# "swords" (the Tiny Swords UI art). PlayerData.ui_skin picks one; the art is chosen here.

const DrawnIcon = preload("res://game/ui/DrawnIcon.gd")
const Heroes = preload("res://game/core/Heroes.gd")
const Economy = preload("res://game/core/Economy.gd")
const Meta = preload("res://game/core/Meta.gd")
const RECOLOR = preload("res://game/ui/recolor.gdshader")

const INFO := Color("fff2c2")
const WARN := Color("ff9c8a")
const INK := Color("3b2b1e")
const GOLD_TEXT := Color("ffd35c")
const DARK := Color(0.07, 0.12, 0.16, 0.9)
const UI := "UI Elements/UI Elements/"
const MEAT := "Terrain/Resources/Meat/Meat Resource/Meat Resource.png"
const COIN := UI + "Icons/Icon_03.png"

enum Ribbon { BLUE = 0, RED = 2, YELLOW = 4, PURPLE = 6, GREY = 8 }

const COZY_BUTTON := "Buttons/Square/SquareButton2_wood.png"
const COZY_BUTTON_RED := "Buttons/Square/SquareButton2_red.png"
const COZY_BUTTON_SQUARE := "Buttons/Square/SquareButton1_wood.png"
const COZY_POPUP := "Cards/CardRegular/CardRegular1_wood.png"
const COZY_PANEL := "Containers/Containers/ContainerAdvanced4.png"
const COZY_PLANK := "Containers/Containers/WoodenContainer1.png"
const COZY_CLOSE := "Icons/Icons Default/64px/IconsDefault25_64px.png"
const COZY_PLUS := "Icons/Icons Default/64px/IconsDefault19_64px.png"
const COZY_HEART := "Icons/Icons Default/64px/IconsDefault38_64px.png"
const COZY_CHECKED := "Checkboxes/Checkbox2_checked.png"
const COZY_UNCHECKED := "Checkboxes/Checkbox2_unchecked.png"


const FONTS := "res://game/ui/fonts/"
const FRAME_BROWN := Color("5b3a1e")
static var _game_font: Font
static var _hero_materials := {}


static func is_cozy() -> bool:
	return PlayerData.ui_skin == "cozy"


## A 9-slice style from a Cozy image scaled by `scale`. `margins` are the texture's
## corner sizes after scaling [left, top, right, bottom]; `content` the padding inside.
static func cozy_style(path: String, scale: float, margins: Array, content: Array) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = SpriteLib.cozy(path, scale)
	style.texture_margin_left = margins[0]
	style.texture_margin_top = margins[1]
	style.texture_margin_right = margins[2]
	style.texture_margin_bottom = margins[3]
	style.content_margin_left = content[0]
	style.content_margin_top = content[1]
	style.content_margin_right = content[2]
	style.content_margin_bottom = content[3]
	return style


## Cozy button art: long wooden (or red) plank, or the square one for narrow buttons.
static func cozy_button_style(red: bool, narrow: bool, short: bool) -> StyleBoxTexture:
	if narrow and not red:
		return cozy_style(COZY_BUTTON_SQUARE, 0.3, [14, 12, 14, 16], [6, 4, 6, 10])
	var scale := 0.22 if short else 0.3
	var m := 30.0 * scale / 0.3
	return cozy_style(COZY_BUTTON_RED if red else COZY_BUTTON, scale, [m * 0.5, m * 0.4, m * 0.5, m * 0.55], [12, 4, 12, 10 if not short else 8])


## Teal container for grouped content on the lobby pages and the battle shop.
static func panel_style() -> StyleBox:
	if is_cozy():
		return cozy_style(COZY_PANEL, 0.4, [22, 20, 22, 26], [20, 18, 20, 22])
	return dark_style()


## A borderless button showing only `texture` (Cozy close / plus icons).
static func icon_button(texture: Texture2D, button_size: float, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(button_size, button_size)
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.icon = texture
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.pressed.connect(func(): SoundLib.play("click"))
	b.pressed.connect(on_pressed)
	return b


## The "+" next to the currencies.
static func plus_button(on_pressed: Callable) -> Button:
	if is_cozy():
		return icon_button(SpriteLib.cozy(COZY_PLUS), 42, on_pressed)
	return button("+", Vector2(40, 40), on_pressed)


## A red close button (popup headers).
static func close_button(on_pressed: Callable) -> Button:
	if is_cozy():
		return icon_button(SpriteLib.cozy(COZY_CLOSE), 44, on_pressed)
	var close := button("", Vector2(48, 48), on_pressed, true)
	close.icon = SpriteLib.texture(UI + "Icons/Icon_09.png")
	close.expand_icon = true
	return close


## The game font: Paytone One, a heavy rounded casual face that has every Vietnamese
## letter. (Lilita One was tried first, but it has no Vietnamese, so words mixed two fonts.)
## Symbols like ★ ◀ ▶ ✦ come from DejaVu Sans: the web build has no system fonts to fall
## back on, so they would show as empty boxes there.
static func game_font() -> Font:
	if _game_font == null:
		# load() goes through the imported resource, which is what an exported build ships
		# (the raw .ttf is not packed, so load_dynamic_font() fails outside the editor).
		var font: FontFile = load(FONTS + "PaytoneOne-Regular.ttf")
		font.fallbacks = [load(FONTS + "DejaVuSans.ttf")]
		_game_font = font
	return _game_font


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = game_font()
	theme.default_font_size = 18
	var normal := button_style("SmallBlueSquareButton_Regular.png")
	var hover := normal.duplicate() as StyleBoxTexture
	hover.modulate_color = Color(1.15, 1.15, 1.15)
	var disabled := normal.duplicate() as StyleBoxTexture
	disabled.modulate_color = Color(0.55, 0.55, 0.55)
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", button_style("SmallBlueSquareButton_Pressed.png"))
	theme.set_stylebox("disabled", "Button", disabled)
	if is_cozy():
		theme.set_icon("checked", "CheckBox", SpriteLib.cozy(COZY_CHECKED, 0.3))
		theme.set_icon("unchecked", "CheckBox", SpriteLib.cozy(COZY_UNCHECKED, 0.3))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	# CheckBox inherits Button styles; it should only show its tick box.
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "CheckBox", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(key, "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color(0.8, 0.8, 0.8))
	theme.set_color("font_outline_color", "Button", Color("1b2a33"))
	theme.set_constant("outline_size", "Button", 6)
	theme.set_color("font_color", "Label", Color.WHITE)
	theme.set_color("font_outline_color", "Label", Color("1b2a33"))
	theme.set_constant("outline_size", "Label", 5)
	return theme


## Tiny Swords button art by file name; in the Cozy skin the same names map to the
## wooden ("Blue") or red plank, darker when "Pressed".
static func button_style(file: String) -> StyleBoxTexture:
	if is_cozy():
		var cozy := cozy_button_style(file.contains("Red"), false, false)
		if file.contains("Pressed"):
			cozy.modulate_color = Color(0.85, 0.85, 0.85)
		return cozy
	var style := StyleBoxTexture.new()
	style.texture = SpriteLib.texture(UI + "Buttons/" + file)
	style.set_texture_margin_all(20)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 10
	return style


## Popup / result panel. Cozy: a card whose wooden header band holds the title row.
static func paper_style() -> StyleBoxTexture:
	if is_cozy():
		return cozy_style(COZY_POPUP, 0.6, [26, 56, 26, 30], [26, 6, 26, 30])
	var style := StyleBoxTexture.new()
	style.texture = SpriteLib.stitched(UI + "Papers/RegularPaper.png", [0, 128, 256])
	style.set_texture_margin_all(32)
	style.set_content_margin_all(30)
	return style


static func ribbon_style(color := Ribbon.BLUE) -> StyleBoxTexture:
	if is_cozy():
		return cozy_style(COZY_PLANK, 0.1, [14, 8, 14, 10], [26, 2, 26, 8])
	var style := StyleBoxTexture.new()
	style.texture = SpriteLib.stitched(UI + "Ribbons/SmallRibbons.png", [color * 64])
	style.texture_margin_left = 30
	style.texture_margin_right = 30
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 2
	style.content_margin_bottom = 6
	return style


static func dark_style(radius := 10, border := Color("5d9d8d")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = DARK
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color = border
	style.set_content_margin_all(12)
	return style


## `red` picks the red button art; buttons narrower than 80px or shorter than 64px use
## the 64px tiny art, because the 128px art barely shows at that size.
static func button(text: String, min_size: Vector2, on_pressed: Callable, red := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): SoundLib.play("click"))
	b.pressed.connect(on_pressed)
	# The 128px art has thick transparent padding, so short or narrow buttons use the 64px art.
	var small := min_size.x < 80.0 or min_size.y < 64.0
	if is_cozy():
		var normal_cozy := cozy_button_style(red, min_size.x > 0.0 and min_size.x < 80.0, min_size.y < 56.0)
		var states := {"normal": 1.0, "hover": 1.1, "pressed": 0.85, "disabled": 0.55}
		for state in states:
			var style := normal_cozy.duplicate() as StyleBoxTexture
			style.modulate_color = Color(states[state], states[state], states[state])
			b.add_theme_stylebox_override(state, style)
		return b
	if red or small:
		var color := "Red" if red else "Blue"
		var file := ("TinySquare%sButton.png" if small else "Small%sSquareButton_Regular.png") % color
		var normal := button_style(file)
		if small:
			normal.set_texture_margin_all(14)
			normal.set_content_margin_all(8)
		var hover := normal.duplicate() as StyleBoxTexture
		hover.modulate_color = Color(1.15, 1.15, 1.15)
		var pressed := normal.duplicate() as StyleBoxTexture
		pressed.modulate_color = Color(0.8, 0.8, 0.8)
		var disabled := normal.duplicate() as StyleBoxTexture
		disabled.modulate_color = Color(0.5, 0.5, 0.5)
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", pressed)
		b.add_theme_stylebox_override("disabled", disabled)
	return b


static func label(text: String, font_size: int, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		l.add_theme_color_override("font_color", color)
	return l


## Dark text without outline, for use on paper panels.
static func ink(text: String, font_size: int) -> Label:
	var l := label(text, font_size, INK)
	l.add_theme_constant_override("outline_size", 0)
	return l


static func icon(texture: Texture2D, icon_size: float) -> TextureRect:
	var i := TextureRect.new()
	i.texture = texture
	i.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	i.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	i.custom_minimum_size = Vector2(icon_size, icon_size)
	i.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i


static func drawn(kind: int, icon_size: float) -> Control:
	var i := DrawnIcon.new()
	i.kind = kind
	i.custom_minimum_size = Vector2(icon_size, icon_size)
	i.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i


static func bar(color: Color, min_size: Vector2) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = min_size
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.03, 0.05, 0.07, 0.9)
	back.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	b.add_theme_stylebox_override("background", back)
	b.add_theme_stylebox_override("fill", fill)
	return b


static func gap(width: float, height := 0.0) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(width, height)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g


static func spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


static func ribbon(text: String, font_size := 20, color := Ribbon.BLUE) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", ribbon_style(color))
	panel.add_child(label(text, font_size))
	return panel


static func hbox(separation := 8) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func vbox(separation := 8) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


## Icon + amount, e.g. coin 250. `currency` is "gold", "gems" or "meat".
static func price(currency: String, amount: int, font_size := 18, on_paper := false) -> HBoxContainer:
	var row := hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_size := font_size * 1.4
	match currency:
		"gems":
			row.add_child(drawn(DrawnIcon.Kind.GEM, icon_size))
		"meat":
			row.add_child(icon(SpriteLib.texture(MEAT), icon_size))
		_:
			row.add_child(icon(SpriteLib.texture(COIN), icon_size))
	row.add_child(ink(format_number(amount), font_size) if on_paper else label(format_number(amount), font_size))
	return row


static func format_number(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	while text.length() > 3:
		out = "." + text.substr(text.length() - 3) + out
		text = text.substr(0, text.length() - 3)
	return ("-" if value < 0 else "") + text + out


static func format_time(seconds: int) -> String:
	return "%02d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]


static func troop_portrait(troop: Resource, portrait_size: float, color := "Blue") -> TextureRect:
	var portrait := icon(SpriteLib.portrait(troop.unit_key, color), portrait_size)
	# self_modulate, so callers can still dim a locked troop with modulate.
	portrait.self_modulate = troop.tint
	if troop.rarity >= 3:
		var crown := drawn(DrawnIcon.Kind.CROWN, portrait_size * 0.3)
		crown.position = Vector2(portrait_size * 0.36, -portrait_size * 0.02)
		crown.size = crown.custom_minimum_size
		portrait.add_child(crown)
	return portrait


## Dims the screen and shows a paper panel with a close button. Returns the VBox to fill;
## the whole popup is freed on close (the VBox's owner chain leads back to the overlay).
static func popup(host: Control, width: float, title: String) -> VBoxContainer:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(overlay)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	panel.add_theme_stylebox_override("panel", paper_style())
	overlay.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var box := vbox(12)
	panel.add_child(box)
	var header := hbox()
	var heading := ink(title, 26)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	header.add_child(close_button(overlay.queue_free))
	box.add_child(header)

	panel.scale = Vector2(0.85, 0.85)
	panel.pivot_offset = Vector2(width / 2.0, 0)
	overlay.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.12)
	box.set_meta("overlay", overlay)
	return box


static func close_popup(box: Control) -> void:
	var overlay = box.get_meta("overlay", null)
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()


# --- Heroes, avatars, dark popups ---------------------------------------------------------

## The recolour that turns a stock unit into this hero (shared per hero).
static func hero_material(id: String) -> ShaderMaterial:
	if not _hero_materials.has(id):
		var hero: Dictionary = Heroes.HEROES[id]
		var material := ShaderMaterial.new()
		material.shader = RECOLOR
		material.set_shader_parameter("hue_shift", hero["hue"])
		material.set_shader_parameter("saturation", hero["sat"])
		material.set_shader_parameter("brightness", hero["val"])
		_hero_materials[id] = material
	return _hero_materials[id]


static func hero_portrait(id: String, portrait_size: float) -> TextureRect:
	var hero: Dictionary = Heroes.HEROES[id]
	var portrait := icon(SpriteLib.portrait(hero["unit"], "Blue"), portrait_size)
	portrait.material = hero_material(id)
	if hero["rarity"] >= 3:
		var crown := drawn(DrawnIcon.Kind.CROWN, portrait_size * 0.3)
		crown.position = Vector2(portrait_size * 0.36, -portrait_size * 0.02)
		crown.size = crown.custom_minimum_size
		portrait.add_child(crown)
	return portrait


static func shard_icon(id: String, icon_size: float) -> Control:
	var shard := drawn(DrawnIcon.Kind.SHARD, icon_size)
	shard.tint = Economy.RARITY_COLORS[Heroes.HEROES[id]["rarity"]]
	return shard



## The player's avatar in its frame. `value`/`frame_id` default to the profile's.
static func avatar(avatar_size: float, value := "", frame_id := "") -> Control:
	if value == "":
		value = PlayerData.avatar
	if frame_id == "":
		frame_id = PlayerData.frame
	var holder := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.14, 0.18)
	style.border_color = Meta.FRAMES.get(frame_id, Meta.FRAMES["wood"])["color"]
	style.set_border_width_all(maxi(3, roundi(avatar_size * 0.07)))
	style.set_corner_radius_all(roundi(avatar_size * 0.22))
	style.set_content_margin_all(maxf(2.0, avatar_size * 0.06))
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 2
	holder.add_theme_stylebox_override("panel", style)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size = Vector2(avatar_size, avatar_size)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var inner := avatar_size * 0.8
	var picture: Control
	if value.begins_with("hero:") and Heroes.HEROES.has(value.substr(5)):
		picture = hero_portrait(value.substr(5), inner)
	else:
		picture = icon(SpriteLib.texture(Meta.avatar_path(clampi(int(value), 1, Meta.AVATAR_COUNT))), inner)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.add_child(picture)
	return holder


## Dark modal sheet (same look as the level select): a brown-framed panel, a gold title
## and a close button. Returns the VBox to fill; close with close_popup(box).
static func dark_popup(host: Control, width: float, title: String) -> VBoxContainer:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(overlay)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.11, 0.97)
	style.border_color = FRAME_BROWN
	style.set_border_width_all(5)
	style.set_corner_radius_all(22)
	style.set_content_margin_all(20)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(width, 0)
	overlay.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := vbox(12)
	panel.add_child(box)
	var header := hbox()
	var heading := label(title, 30, GOLD_TEXT)
	heading.add_theme_constant_override("outline_size", 8)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	header.add_child(close_button(overlay.queue_free))
	box.add_child(header)
	panel.scale = Vector2(0.85, 0.85)
	panel.pivot_offset = Vector2(width / 2.0, 0)
	overlay.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.12)
	box.set_meta("overlay", overlay)
	return box


## A rounded dark card used inside dark popups and the new pages.
static func card_style(border := FRAME_BROWN, background := Color(0.1, 0.13, 0.17, 0.95)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(10)
	return style


## Icons and text for a Meta reward / PlayerData.grant() result, in one row.
static func reward_row(reward: Dictionary, font_size := 18) -> HBoxContainer:
	var row := hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if int(reward.get("gold", 0)) > 0:
		row.add_child(price("gold", reward["gold"], font_size))
	if int(reward.get("gems", 0)) > 0:
		row.add_child(price("gems", reward["gems"], font_size))
	var cards = reward.get("cards", null)
	if cards is int and cards > 0:
		var chest := hbox(4)
		chest.add_child(drawn(DrawnIcon.Kind.CHEST, font_size * 1.6))
		chest.add_child(label("%d thẻ" % cards, font_size))
		row.add_child(chest)
	elif cards is Dictionary:
		for id in cards:
			var item := hbox(2)
			item.add_child(troop_portrait(PlayerData.TROOPS[id], font_size * 2.0))
			item.add_child(label("x%d" % cards[id], font_size))
			row.add_child(item)
	var shards = reward.get("shards", null)
	if shards is Array:
		var id: String = PlayerData.summon_featured() if shards[0] == "featured" else shards[0]
		var item := hbox(2)
		item.add_child(shard_icon(id, font_size * 1.5))
		item.add_child(label("%d" % shards[1], font_size))
		row.add_child(item)
	elif shards is Dictionary:
		for id in shards:
			var item := hbox(2)
			item.add_child(shard_icon(id, font_size * 1.5))
			item.add_child(label("%d" % shards[id], font_size))
			row.add_child(item)
	var heroes: Array = []
	if reward.get("hero", "") != "":
		heroes.append(reward["hero"])
	heroes.append_array(reward.get("heroes", []))
	for id in heroes:
		row.add_child(hero_portrait(id, font_size * 2.4))
	return row


## A short gold toast in the middle of `host`.
static func toast(host: Control, text: String) -> void:
	var note := label(text, 22, GOLD_TEXT)
	var style := card_style(GOLD_TEXT)
	style.content_margin_left = 20
	style.content_margin_right = 20
	note.add_theme_stylebox_override("normal", style)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.position = Vector2(60, 560)
	note.size = Vector2(600, 64)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.z_index = 50
	host.add_child(note)
	SoundLib.play("reward")
	var tween := note.create_tween()
	tween.tween_property(note, "position:y", 520.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.4)
	tween.tween_property(note, "modulate:a", 0.0, 0.3)
	tween.tween_callback(note.queue_free)
