extends RefCounted

# Builds UI pieces from ordinary Godot Controls and Containers skinned by the game theme
# (game/ui/skin/game_theme.tres): the SVG skin draws them, containers lay them out.
# Call Ui.setup_root(screen) once so every child picks up the skin, then pick looks with
# theme_type_variation (the list is at the top of tools/ui/build_theme.gd).

const THEME = preload("res://game/ui/skin/game_theme.tres")
const SKIN := "res://game/ui/skin/"
const PATTERN_SHADER = preload("res://game/ui/pattern_scroll.gdshader")
const MENU_SKY_SHADER = preload("res://game/ui/menu_sky.gdshader")
const CartonNav = preload("res://game/ui/CartonNav.gd")
const MenuSection = preload("res://game/ui/MenuSection.gd")
const DARK_TEXT := Color("4b4444")


static func tex(name: String) -> Texture2D:
	# Accepted raster art is kept outside the generated SVG skin, so rebuilding
	# the legacy skin cannot silently restore superseded weapon/equipment art.
	var raster := "res://game/ui/art/" + name + ".png"
	if ResourceLoader.exists(raster):
		return load(raster)
	return load(SKIN + name + ".svg")


## Themed, full-rect screen root with smooth filtering for the SVG skin (the project
## default is nearest, for the pixel-art packs).
static func setup_root(control: Control) -> void:
	control.theme = THEME
	control.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	control.set_anchors_preset(Control.PRESET_FULL_RECT)


# --- Basics ----------------------------------------------------------------------------------

static func image(name: String, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Icons come in several drawn sizes so the outline stays ~3.5 px on screen (see
## tools/ui/make_svgs.py, ICON_SIZES). Pick the smallest one at least `size` big.
const ICON_SIZES := [32, 48, 64, 96]


static func icon_tex(name: String, size: float) -> Texture2D:
	for s in ICON_SIZES:
		if size <= s:
			return tex("icon_%s_%d" % [name, s])
	return tex("icon_" + name)


static func icon(name: String, size: float) -> TextureRect:
	var r := image("icon_" + name, Vector2(size, size))
	r.texture = icon_tex(name, size)
	return r


static func label(text: String, variation := "", font_size := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font_size > 0:
		l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func hbox(separation := 8, align := BoxContainer.ALIGNMENT_CENTER) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", separation)
	b.alignment = align
	return b


static func vbox(separation := 8, align := BoxContainer.ALIGNMENT_BEGIN) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", separation)
	b.alignment = align
	return b


static func margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", left)
	m.add_theme_constant_override("margin_top", top)
	m.add_theme_constant_override("margin_right", right)
	m.add_theme_constant_override("margin_bottom", bottom)
	return m


static func center(child: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.add_child(child)
	return c


## Shop backdrop: the sky colour with gears and cat paws drifting on a diagonal
## (bg_tile.svg through pattern_scroll.gdshader). Put it first, full rect.
static func pattern_bg(sky := Color("6fa3e0")) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = sky
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = PATTERN_SHADER
	mat.set_shader_parameter("tile", tex("bg_tile"))
	mat.set_shader_parameter("sky", sky)
	bg.material = mat
	return bg


## One family of quiet scrolling menu backdrops. Light roster colors preserve
## the brown headings; darker blue/violet support the shop and summon artwork.
const MENU_PATTERN_COLORS := {
	"shop": Color("4e78a3"),
	"hero": Color("96b5ae"),
	"troops": Color("b1c6a3"),
	"summon": Color("81749f"),
	"castle": Color("93aaa0"),
	"patrol": Color("a4bb91"),
	"events": Color("b89299"),
	"login": Color("bca789"),
	"quests": Color("99b3c1"),
	"profile": Color("92abae"),
	"settings": Color("8ea4b4"),
	"admin": Color("526a7b"),
}


static func menu_pattern_color(context: String) -> Color:
	return MENU_PATTERN_COLORS.get(context, MENU_PATTERN_COLORS["hero"])


static func menu_context_for_title(title: String) -> String:
	match title:
		"Sự kiện": return "events"
		"Quà 7 ngày": return "login"
		"Nhiệm vụ hằng ngày": return "quests"
		"Hồ sơ": return "profile"
		"Cài đặt": return "settings"
	return ""


## Popup/opening helpers can find Home without depending on its script. Combat
## scenes have no such ancestor, so their existing backgrounds stay untouched.
static func register_menu_surface(host: Node, surface: Node, context := "") -> bool:
	var owner_node := host
	while owner_node != null:
		if owner_node.has_method("register_menu_surface"):
			owner_node.register_menu_surface(surface, context)
			return true
		owner_node = owner_node.get_parent()
	return false


## The shared animated sky uses screen coordinates so page overlays join the header
## and navigation backdrop without compressing or restarting the scene.
static func menu_bg() -> ColorRect:
	var bg := ColorRect.new()
	bg.name = "MenuBackground"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = MENU_SKY_SHADER
	mat.set_shader_parameter("sky_scene", tex("bg_sky_base"))
	mat.set_shader_parameter("clouds_far", tex("bg_sky_clouds_far"))
	mat.set_shader_parameter("clouds_near", tex("bg_sky_clouds_near"))
	mat.set_shader_parameter("clouds_front", tex("bg_sky_clouds_front"))
	mat.set_shader_parameter("distant_islands", tex("bg_sky_distant_islands"))
	bg.material = mat
	return bg


static func spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


static func panel(variation: String, child: Control = null) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	if child != null:
		p.add_child(child)
	return p


## Menu-only frames: one brown contour and shallow lip, separate from combat/rarity art.
const MENU_PANEL_CONTEXTS := ["shop", "hero", "troops", "castle", "patrol", "events", "summon", "login", "quests", "profile", "settings"]


static func menu_panel_style(context: String, variation := "Board") -> StyleBoxTexture:
	var chosen := context if MENU_PANEL_CONTEXTS.has(context) else "hero"
	var kind := variation if variation in ["Board", "Well"] else "Board"
	var box := THEME.get_stylebox("panel", kind).duplicate() as StyleBoxTexture
	box.texture = load(SKIN + "menu/" + chosen + "_" + kind.to_snake_case() + ".svg")
	if kind == "Board":
		box.texture_margin_left = 48
		box.texture_margin_right = 48
		box.texture_margin_top = 48
		box.texture_margin_bottom = 56
		box.content_margin_left = 28
		box.content_margin_right = 28
		box.content_margin_top = 30
		box.content_margin_bottom = 30
	else:
		box.set_texture_margin_all(24)
		box.set_content_margin_all(14)
	return box


static func menu_panel(context: String, variation := "Board", child: Control = null) -> PanelContainer:
	var p := panel(variation, child)
	p.add_theme_stylebox_override("panel", menu_panel_style(context, variation))
	p.set_meta("menu_panel_context", context)
	p.set_meta("menu_panel_kind", variation)
	return p


## A section title attached to its top edge; content stays in normal container flow.
static func menu_section(context: String, title: String, child: Control) -> Control:
	var p := menu_panel(context, "Board", child)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = child.size_flags_vertical
	var tag := menu_tag(title)
	var section := MenuSection.new()
	section.configure(p, tag)
	section.set_meta("menu_section_context", context)
	section.set_meta("menu_section_title", title)
	return section


static func menu_tag(title: String) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := StyleBoxFlat.new()
	face.bg_color = Color("e9c578")
	face.border_color = Color("583f21")
	face.set_border_width_all(4)
	face.set_corner_radius_all(22)
	face.content_margin_left = 22
	face.content_margin_right = 22
	face.content_margin_top = 8
	face.content_margin_bottom = 8
	face.anti_aliasing = true
	tag.add_theme_stylebox_override("panel", face)
	var caption := label(title, "LabelDark", 26)
	caption.add_theme_color_override("font_color", Color("4b3927"))
	caption.add_theme_constant_override("outline_size", 0)
	tag.add_child(caption)
	return tag


## Puts `child` at a fixed spot over `host` (badges on cards and icons).
static func pin(host: Control, child: Control, at: Vector2, preset := Control.PRESET_TOP_LEFT) -> Control:
	host.add_child(child)
	child.set_anchors_preset(preset)
	# `at` is measured from the preset's anchor point (e.g. bottom-right corner), so set offsets,
	# not `position` (which is always from the parent's top-left).
	var size := child.custom_minimum_size
	child.offset_left = at.x
	child.offset_top = at.y
	child.offset_right = at.x + size.x
	child.offset_bottom = at.y + size.y
	return child


# --- Buttons ---------------------------------------------------------------------------------

## Button faces by tone: [light, dull] from BUTTON_TONES in make_svgs.py.
const TONE_COLORS := {
	"Yellow": ["faea76", "ebc76d"], "Orange": ["ffbe8b", "efa569"], "Blue": ["6bc6ef", "51b4de"],
	"Green": ["78ec80", "59d961"], "Red": ["f56161", "eb4e4d"], "Purple": ["f68ff1", "e66fe6"],
	"White": ["f7f5f4", "e2dedc"], "Tab": ["73a4de", "6294d6"], "Grey": ["cccccc", "b2b2b2"],
}
## The 9-slice button art needs this much height (corner 33 + lip 36); shorter buttons
## get the chip face instead, or their corners, lip and paw squash.
const CHIP_BELOW := 68.0


## Short button face: the art's face colour, the shared brown outline and a thick brown base
## standing in for the lip (thinner when pressed). No paw mark at this size.
static func chip_box(tone: String, pressed := false) -> StyleBoxFlat:
	var colors: Array = TONE_COLORS.get(tone, TONE_COLORS["Yellow"])
	var box := StyleBoxFlat.new()
	box.bg_color = Color(colors[0]).lerp(Color(colors[1]), 0.35)
	box.border_color = Color("583f21")
	box.set_border_width_all(3)
	box.border_width_bottom = 3 if pressed else 7
	box.set_corner_radius_all(22)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 4 if not pressed else 8
	box.content_margin_bottom = 4
	box.anti_aliasing = true
	return box


## `tone`: Yellow Green Blue Red Purple Orange White Tab.
static func button(text: String, tone := "Yellow", min_size := Vector2(0, 72), font_size := 0, icon_name := "") -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = "Btn" + tone
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	if min_size.y > 0.0 and min_size.y < CHIP_BELOW:
		b.add_theme_stylebox_override("normal", chip_box(tone))
		b.add_theme_stylebox_override("hover", chip_box(tone))
		b.add_theme_stylebox_override("pressed", chip_box(tone, true))
		b.add_theme_stylebox_override("hover_pressed", chip_box(tone, true))
		b.add_theme_stylebox_override("disabled", chip_box("Grey"))
	if font_size > 0:
		b.add_theme_font_size_override("font_size", font_size)
	if icon_name != "":
		var icon_px := int((font_size if font_size > 0 else 26) * 1.35)
		b.icon = icon_tex(icon_name, icon_px)
		b.add_theme_constant_override("icon_max_width", icon_px)
	b.pressed.connect(func(): SoundLib.play("click"))
	return b


## Action on top, cost (icon + amount) under it, e.g. "Quay 1 / 💎 20".
static func cost_button(title: String, cost: String, cost_icon: String, tone := "Blue", min_size := Vector2(200, 96)) -> Button:
	var b := button("", tone, min_size)
	var box := vbox(0, BoxContainer.ALIGNMENT_CENTER)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_bottom = -12
	var top := label(title, "", 26)
	var row := hbox(6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon(cost_icon, 26))
	var amount := label(cost, "LabelSmall", 20)
	row.add_child(amount)
	if tone == "White":
		for l in [top, amount]:
			l.add_theme_color_override("font_color", DARK_TEXT)
			l.add_theme_constant_override("outline_size", 0)
	box.add_child(top)
	box.add_child(row)
	# The art sinks 6 px when pressed; move the text with it.
	b.button_down.connect(func(): box.offset_top = 6; box.offset_bottom = -6)
	b.button_up.connect(func(): box.offset_top = 0; box.offset_bottom = -12)
	return b


## Locked: grey art, padlock on the corner, no taps.
static func lock(b: Button) -> Button:
	b.disabled = true
	pin(b, icon("lock", 34), Vector2(-26, -8), Control.PRESET_TOP_RIGHT)
	return b


## Red "!" on a control's top-right corner.
static func dot(host: Control, at := Vector2(-18, -8)) -> Control:
	return pin(host, icon("badge_dot", 30), at, Control.PRESET_TOP_RIGHT)


# --- Plaques, strips, counters -----------------------------------------------------------------

## bg_qbnzsx: title with an optional green accent ("Mèo Thủ Thành" + "Lv12").
static func title_plaque(text: String, accent := "", font_size := 24) -> PanelContainer:
	var row := hbox(6)
	row.add_child(label(text, "", font_size))
	if accent != "":
		row.add_child(label(accent, "LabelAccent", font_size))
	var p := panel("TitlePlaque", row)
	p.custom_minimum_size.y = 51
	return p


## bg_fenye_01: section title on a blue panel.
static func section_plaque(text: String) -> PanelContainer:
	var p := panel("SectionPlaque", label(text, "", 22))
	p.custom_minimum_size = Vector2(240, 48)
	return p


## Stat line: icon, label + green accent on the left, value, and an optional upgrade cost
## button inside the strip's right end (like Gear Defenders' "Castle HP … 740 [230]").
static func info_strip(text: String, accent: String, value: String, cost := "", cost_icon := "coin", icon_name := "") -> PanelContainer:
	var row := hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	if icon_name != "":
		row.add_child(icon(icon_name, 34))
	row.add_child(label(text, "LabelSmall", 20))
	row.add_child(label(accent, "LabelAccent", 20))
	row.add_child(spacer())
	row.add_child(label(value, "", 24))
	if cost != "":
		row.add_child(button(cost, "Yellow", Vector2(124, 54), 22, cost_icon))
	var p := panel("InfoStrip", row)
	p.custom_minimum_size.y = 58 if cost != "" else 44
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


static func counter(icon_name: String, text: String) -> PanelContainer:
	var row := hbox(6)
	row.add_child(icon(icon_name, 26))
	row.add_child(label(text, "LabelSmall"))
	var p := panel("Counter", row)
	p.custom_minimum_size.y = 38
	return p


# --- Badges -------------------------------------------------------------------------------------

static func level_shield(text: String, tone := "blue") -> TextureRect:
	var s := icon("badge_shield_" + tone, 42)
	var l := label(text, "LabelTiny", 17)
	s.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.offset_bottom = -6
	return s


static func level_flower(text: String) -> TextureRect:
	var f := icon("badge_flower", 34)
	var l := label(text, "LabelDark", 17)
	f.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return f


# --- Cards --------------------------------------------------------------------------------------

## bg_kapai: unit card. `tone`: green orange yellow blue purple red; empty `level` hides the shield.
static func unit_card(tone: String, icon_name: String, name: String, level: String, picked := false) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(124, 146)
	var body := vbox(2, BoxContainer.ALIGNMENT_CENTER)
	body.add_child(center(icon(icon_name, 62)))
	body.add_child(label(name, "LabelSmall", 17))
	var card := panel("CardUnit" + tone.capitalize(), body)
	root.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if level != "":
		pin(root, level_shield(level, "orange" if tone == "orange" else "blue"), Vector2(-7, -7))
	if picked:
		pin(root, icon("badge_check", 30), Vector2(-26, -30), Control.PRESET_BOTTOM_RIGHT)
	return root


## Inventory gear card: art, have/need bar, level flower. `tone`: cream blue orange red purple.
static func item_card(tone: String, icon_name: String, level: String, have: int, need: int) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(140, 158)
	var body := vbox(6, BoxContainer.ALIGNMENT_END)
	body.add_child(center(icon(icon_name, 70)))
	var bar := ProgressBar.new()
	bar.theme_type_variation = "BarItem"
	bar.show_percentage = false
	bar.max_value = need
	bar.value = have
	bar.custom_minimum_size = Vector2(0, 20)
	var count := label("%d/%d" % [have, need], "LabelTiny", 15)
	bar.add_child(count)
	count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(bar)
	var card := panel("CardItem" + tone.capitalize(), body)
	root.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pin(root, level_flower(level), Vector2(-6, -6))
	return root


## tianjia_sb_ptlan: a unit on its stand with the level shield below. `art` is a cat sprite
## (cat_*) or an icon name.
static func platform(art: String, level: String) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(170, 124)
	pin(root, image("platform", Vector2(170, 72)), Vector2(0, 38))
	if art.begins_with("cat_"):
		pin(root, image(art, Vector2(96, 90)), Vector2(37, -28))
	else:
		pin(root, icon(art, 66), Vector2(52, 4))
	pin(root, level_shield(level), Vector2(64, 88))
	return root


# --- HUD and nav ---------------------------------------------------------------------------------

## One HUD resource: a fixed-height pill with the icon overlapping its left end, the value
## centred between its icon and optional green "+", with a timer tag below when needed.
## The value is a sibling of the panel so its minimum width cannot stretch the pill.
static func _currency(icon_name: String, text: String, plus: bool, timer := "") -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(0, 52)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pill := panel("HudPill")
	pill.name = "CurrencyPill"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pill)
	pill.anchor_right = 1.0
	pill.offset_left = 20
	pill.offset_top = 8
	pill.offset_bottom = 44
	var value := label(text, "LabelSmall", 18)
	value.name = "CurrencyValue"
	value.add_theme_constant_override("outline_size", 3)
	value.clip_text = true
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	root.add_child(value)
	value.anchor_right = 1.0
	value.offset_left = 44
	value.offset_right = -36 if plus else -8
	value.offset_top = 8
	value.offset_bottom = 44
	# Refit after a resize and after Home changes the amount. Both keep the icon/plus slots.
	var fit_value := func():
		var available := value.size.x - 8.0
		if available <= 0.0:
			return
		var font := value.get_theme_font("font")
		var font_size := 18
		while font_size > 12 and font.get_string_size(value.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available:
			font_size -= 1
		if value.get_theme_font_size("font_size") != font_size:
			value.add_theme_font_size_override("font_size", font_size)
	value.set_meta("fit_value", fit_value)
	value.resized.connect(fit_value)
	if plus:
		var add := icon("badge_plus", 28)
		add.name = "CurrencyPlus"
		pin(root, add, Vector2(-30, 12), Control.PRESET_TOP_RIGHT)
	var resource_icon := icon(icon_name, 48)
	resource_icon.name = "CurrencyIcon"
	pin(root, resource_icon, Vector2(-2, 2))
	if timer != "":
		var t := label(timer, "LabelTiny", 13)
		root.add_child(t)
		t.anchor_right = 1.0
		t.offset_left = 20
		t.offset_top = 38
		t.offset_bottom = 54
	return root


## Compact top HUD: avatar + Lv on the left; three equal resource pills over the EXP bar.
static func hud(level: int, energy: String, timer: String, gold: String, gems: String, exp_ratio: float) -> PanelContainer:
	var row := hbox(14, BoxContainer.ALIGNMENT_BEGIN)
	var avatar := Control.new()
	avatar.custom_minimum_size = Vector2(88, 98)
	var frame := panel("AvatarFrame", center(image("cat_head_hero", Vector2(62, 50))))
	pin(avatar, frame, Vector2.ZERO).size = Vector2(80, 84)
	pin(avatar, icon("gear", 26), Vector2(-8, -8))
	var lv := panel("LvPlaque", label("Lv.%d" % level, "LabelTiny", 15))
	pin(avatar, lv, Vector2(28, 70)).size = Vector2(60, 26)
	row.add_child(avatar)

	var right := vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var money := hbox(12)
	money.add_child(_currency("bolt", energy, false, timer))
	money.add_child(_currency("coin", gold, true))
	money.add_child(_currency("gem", gems, true))
	right.add_child(money)
	var bar := ProgressBar.new()
	bar.theme_type_variation = "BarExp"
	bar.show_percentage = false
	bar.value = exp_ratio * 100.0
	bar.custom_minimum_size = Vector2(0, 14)
	right.add_child(bar)
	row.add_child(right)

	var p := panel("HudBar", row)
	p.custom_minimum_size.y = 128
	return p


## Persistent carton states keep opening/closing motion alive through selection
## and alert changes. The legacy bleed argument stays accepted by preview scenes.
static func bottom_nav(tabs: Array, selected: int, badges := [], _bleed := 0.0) -> CartonNav:
	var bar := CartonNav.new()
	bar.configure(tabs, selected, badges)
	return bar


# --- Lobby pieces ----------------------------------------------------------------------------------

const RAIL_ITEM_SIZE := Vector2(108, 128)
const RAIL_BADGE_AT := Vector2(-20, -6)
const SHORTCUT_BADGE_AT := Vector2(-10, -12)
const SHORTCUT_TONES := {
	"rail_checkin": "peach", "rail_quest": "sage",
	"rail_event": "lavender", "rail_castle": "sand",
}

## One shortcut: equal icon/label space and a full-size target when wrapped by Home.
static func rail_item(icon_name: String, text: String, timer := "", badge := false) -> Control:
	var root := Control.new()
	root.custom_minimum_size = RAIL_ITEM_SIZE + Vector2(0, 20 if timer != "" else 0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backing := image("shortcut_" + SHORTCUT_TONES.get(icon_name, "sand"), Vector2.ZERO)
	root.add_child(backing)
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ic := icon(icon_name, 72)
	ic.name = "ShortcutIcon"
	pin(root, ic, Vector2(18, 9))
	var caption := label(text, "LabelDark", 16)
	caption.name = "ShortcutCaption"
	caption.custom_minimum_size = Vector2(96, 28)
	caption.add_theme_color_override("font_color", Color("583f21"))
	caption.add_theme_constant_override("outline_size", 0)
	pin(root, caption, Vector2(6, 88))
	if timer != "":
		var t := label(timer, "LabelTiny", 14)
		t.custom_minimum_size = Vector2(108, 20)
		t.add_theme_color_override("font_color", Color("583f21"))
		t.add_theme_constant_override("outline_size", 0)
		pin(root, t, Vector2(0, 116))
	if badge:
		dot(ic, SHORTCUT_BADGE_AT)
	return root


## A light column of independent shortcuts, leaving the central stage visible.
static func rail(items: Array) -> PanelContainer:
	var col := vbox(16)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for it in items:
		col.add_child(it)
	var root := panel("", col)
	root.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return root


## Yellow hint tag ("Triệu hồi miễn phí!") pointing down at a tab.
static func callout(text: String) -> PanelContainer:
	return panel("Callout", label(text, "LabelSmall", 18))


## Breathing scale on the main call to action (loops forever).
static func pulse(control: Control, amount := 0.05, period := 1.2) -> void:
	control.pivot_offset = control.custom_minimum_size * 0.5
	var tw := control.create_tween().set_loops()
	tw.tween_property(control, "scale", Vector2.ONE * (1.0 + amount), period * 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(control, "scale", Vector2.ONE, period * 0.5).set_trans(Tween.TRANS_SINE)


## Small up-down hop (callouts, chests that can be opened).
static func bob(control: Control, height := 6.0, period := 1.0) -> void:
	# Start from the laid-out position: right after creation a pinned control's position is
	# still measured against a parent of size 0.
	if not control.is_inside_tree():
		await control.ready
	await control.get_tree().process_frame
	if not is_instance_valid(control):
		return
	var y := control.position.y
	var tw := control.create_tween().set_loops()
	tw.tween_property(control, "position:y", y - height, period * 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(control, "position:y", y, period * 0.5).set_trans(Tween.TRANS_SINE)


# --- Equipment ------------------------------------------------------------------------------

## One equipment slot: rarity card, item icon, level flower; empty slots show a faded icon
## and a "+". `tone`: green blue purple orange (Bình thường → Huyền thoại) or "" for empty.
static func equip_slot(icon_name: String, tone: String, level := "", size := 96.0) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(size, size)
	var card := panel("CardUnit" + (tone.capitalize() if tone != "" else "Yellow"))
	root.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ic := icon(icon_name, size * 0.62)
	card.add_child(center(ic))
	if tone == "":
		card.modulate = Color(1, 1, 1, 0.55)
		pin(root, icon("badge_plus", size * 0.3), Vector2(-size * 0.3, -size * 0.3), Control.PRESET_BOTTOM_RIGHT)
	elif level != "":
		pin(root, level_flower(level), Vector2(-8, -8))
	return root


## Label under a slot (name or effect), small and centred.
static func caption(child: Control, text: String, variation := "LabelTiny", font_size := 15) -> VBoxContainer:
	var box := vbox(2)
	box.add_child(center(child))
	box.add_child(label(text, variation, font_size))
	return box


## Equipment slot for the paper doll and the bag: rarity card, item icon, "Lv" plaque at the
## bottom, no caption. Empty slots show the slot type as a grey silhouette.
static func gear_slot(icon_name: String, tone: String, level := "", size := 108.0, selected := false) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(size, size)
	var card := panel("CardUnit" + (tone.capitalize() if tone != "" else "Yellow"))
	root.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ic := icon(icon_name, size * 0.66)
	var holder := Control.new()
	card.add_child(holder)
	pin(holder, ic, Vector2(-size * 0.33, -size * 0.38), Control.PRESET_CENTER)
	if tone == "":
		card.modulate = Color(0.75, 0.72, 0.7, 0.75)
		ic.modulate = Color(0.25, 0.2, 0.2, 0.5)
	elif level != "":
		var lv := panel("LvPlaque", label("Lv." + level, "LabelTiny", 14))
		pin(root, lv, Vector2(-30, -16), Control.PRESET_CENTER_BOTTOM)
		lv.offset_right = lv.offset_left + 60
		lv.offset_bottom = lv.offset_top + 24
	if selected:
		pin(root, icon("badge_check", 30), Vector2(-24, -10), Control.PRESET_TOP_RIGHT)
	return root


## Small translucent pill with an icon and a value (stat totals under the hero).
static func stat_pill(icon_name: String, text: String, min_width := 150.0) -> PanelContainer:
	var row := hbox(6)
	row.add_child(icon(icon_name, 32))
	row.add_child(label(text, "", 21))
	var p := panel("HudPill", row)
	p.custom_minimum_size = Vector2(min_width, 40)
	return p


## Equipment card in the Capybara-Go style: rarity card, slot-type badge top-left, "Lv.x" top
## right, big item art, green up arrow bottom-right when it can be upgraded now.
static func gear_card(icon_name: String, type_icon: String, tone: String, level: String, size := 116.0, can_upgrade := false) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(size, size)
	var card := panel("CardUnit" + (tone if tone != "grey" else "yellow").capitalize())
	root.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Lay art out against the full card, independently of the face's theme margins.
	# Source icons already contain safe alpha padding; this square also leaves the
	# top row free for the slot and level, including in the smaller bag cards.
	var art := icon(icon_name, size * 0.78)
	art.name = "EquipmentArt"
	pin(root, art, Vector2(size * 0.11, size * 0.22))
	var badge := icon(type_icon, size * 0.26)
	badge.name = "SlotBadge"
	pin(root, badge, Vector2(5, 5))
	var lv := label("Lv." + level, "LabelTiny", int(size * 0.15))
	lv.name = "EquipmentLevel"
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pin(root, lv, Vector2(-size * 0.62, 4), Control.PRESET_TOP_RIGHT)
	lv.offset_right = -8
	lv.offset_bottom = lv.offset_top + size * 0.24
	if can_upgrade:
		var up := icon("badge_up", size * 0.3)
		up.name = "EquipmentUpgrade"
		pin(root, up, Vector2(-size * 0.3, -size * 0.32), Control.PRESET_BOTTOM_RIGHT)
	return root


## Feature shortcut: icon with a label under it and an optional red dot.
static func shortcut(icon_name: String, text: String, badge := false) -> Control:
	var box := vbox(0, BoxContainer.ALIGNMENT_CENTER)
	var ic := icon(icon_name, 62)
	box.add_child(center(ic))
	box.add_child(label(text, "LabelTiny", 15))
	if badge:
		dot(ic, Vector2(-12, -4))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return box
