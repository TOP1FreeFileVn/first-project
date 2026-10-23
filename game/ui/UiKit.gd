extends RefCounted

# Shared UI building blocks: theme, buttons, labels, ribbons, panels, currency rows and a
# modal popup. Used by the battle HUD and every menu page so the whole game looks the same.
# The game skin (game/ui/Ui.gd: SVG skin + Theme) is on for every page; the older "cozy"
# (Cozy UI Pack) and "swords" (Tiny Swords UI) branches stay below is_game() checks until
# every page is rebuilt on Ui.gd directly.

const DrawnIcon = preload("res://game/ui/DrawnIcon.gd")
const HeroCat = preload("res://game/core/HeroCat.gd")
const Economy = preload("res://game/core/Economy.gd")
const Meta = preload("res://game/core/Meta.gd")
const Ui = preload("res://game/ui/Ui.gd")

const INFO := Color("fff2c2")
const WARN := Color("ff9c8a")
const INK := Color("3b2b1e")
const GOLD_TEXT := Color("ffd35c")
## Card fill on the lobby pages: the slate of the nav cells.
const DARK := Color(0.235, 0.3, 0.45, 0.96)
## The skin's one outline colour.
const LINE := Color("583f21")
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


static func is_game() -> bool:
	return true


static func is_cozy() -> bool:
	return not is_game() and PlayerData.ui_skin == "cozy"


## A theme box from the game skin (a copy, so callers may change it).
static func skin_box(variation: String) -> StyleBox:
	return Ui.THEME.get_stylebox("panel", variation).duplicate()


## Small button face for sizes the 9-slice art is too big for: flat tone, skin outline.
static func flat_button_style(fill: Color, radius := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = LINE
	style.set_border_width_all(3)
	style.border_width_bottom = 6
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(6)
	return style


## Card face by rarity, as in the battle shop and the Lính page: Thường green, Hiếm blue,
## Sử thi purple, Huyền thoại orange.
static func rarity_card(rarity: int) -> StyleBox:
	var box := skin_box("CardUnit" + ["Green", "Blue", "Purple", "Orange"][clampi(rarity, 0, 3)])
	box.content_margin_top = 8
	box.content_margin_bottom = 12
	return box


## Face-down card: yellow card (chests) or purple (summons).
static func card_back(summon := false) -> StyleBox:
	return skin_box("CardUnitPurple" if summon else "CardUnitYellow")


## Face-down card: the back art, a thin light frame inset from the edge and one round
## medallion dead centre with the emblem (a paw for chests, the crystal ball for summons).
## Children are anchored, not stacked, so nothing drifts with font metrics.
static func card_back_face(card_size: Vector2, summon := false) -> Panel:
	var back := Panel.new()
	back.name = "Back"
	back.size = card_size
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_theme_stylebox_override("panel", card_back(summon))
	var frame := Panel.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.draw_center = false
	frame_style.border_color = Color(1, 1, 1, 0.45)
	frame_style.set_border_width_all(3)
	frame_style.set_corner_radius_all(8)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 12
	frame.offset_top = 12
	frame.offset_right = -12
	frame.offset_bottom = -16
	var size := minf(card_size.x, card_size.y) * 0.62
	var medal := Panel.new()
	var medal_style := StyleBoxFlat.new()
	medal_style.bg_color = Color("8f5fd0") if summon else Color("e0a93a")
	medal_style.border_color = LINE
	medal_style.set_border_width_all(4)
	medal_style.set_corner_radius_all(int(size))
	medal.add_theme_stylebox_override("panel", medal_style)
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(medal)
	medal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	medal.offset_left = -size / 2.0
	medal.offset_right = size / 2.0
	medal.offset_top = -size / 2.0 - 2.0
	medal.offset_bottom = size / 2.0 - 2.0
	var emblem := Ui.icon("tab_summon" if summon else "paw", size * 0.66)
	emblem.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	medal.add_child(emblem)
	emblem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset := size * 0.12
	emblem.offset_left = inset
	emblem.offset_top = inset
	emblem.offset_right = -inset
	emblem.offset_bottom = -inset
	return back


## Solid pill tag ("Mới", "Trong đội", "Ghép được").
static func tag(text: String, fill := Color("ff5a4a")) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = LINE
	style.set_border_width_all(3)
	style.set_corner_radius_all(13)
	style.content_margin_left = 9
	style.content_margin_right = 9
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style)
	var l := label(text, 14)
	l.add_theme_constant_override("outline_size", 5)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func fish_texture() -> Texture2D:
	return Ui.icon_tex("fish", 64)


## `size`: the largest size it is shown at (bigger reveals need the 128 art).
static func coin_texture(size := 64) -> Texture2D:
	return Ui.icon_tex("coin", size)


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


## Menus opt into a contextual face; the battle shop keeps its existing skin.
static func panel_style(context := "") -> StyleBox:
	if is_game():
		if not context.is_empty():
			return Ui.menu_panel_style(context)
		return skin_box("Board")
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
	if is_game():
		return icon_button(Ui.icon_tex("badge_plus", 48), 40, on_pressed)
	if is_cozy():
		return icon_button(SpriteLib.cozy(COZY_PLUS), 42, on_pressed)
	return button("+", Vector2(40, 40), on_pressed)


## A red close button (popup headers).
static func close_button(on_pressed: Callable) -> Button:
	if is_game():
		var x := Button.new()
		# 68 px: a thumb-sized target (the art fills it).
		x.custom_minimum_size = Vector2(68, 68)
		x.focus_mode = Control.FOCUS_NONE
		x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for state in ["normal", "hover", "pressed"]:
			x.add_theme_stylebox_override(state, flat_button_style(Color("ff6b5a") if state != "pressed" else Color("e2503f"), 34))
		x.icon = Ui.icon_tex("close", 36)
		x.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		x.add_theme_constant_override("icon_max_width", 34)
		x.pressed.connect(func(): SoundLib.play("click"))
		x.pressed.connect(on_pressed)
		return x
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
	if is_game():
		var skin: Theme = Ui.THEME.duplicate()
		skin.default_font_size = 18
		# The old pages size text for 18-20 px buttons.
		for type in ["Button", "BtnYellow", "BtnGreen", "BtnBlue", "BtnRed", "BtnPurple", "BtnOrange", "BtnWhite", "BtnTab"]:
			skin.set_font_size("font_size", type, 20)
		for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			skin.set_stylebox(state, "CheckBox", StyleBoxEmpty.new())
		# Big tick boxes: the whole row is the touch target, the box reads at a glance.
		skin.set_icon("checked", "CheckBox", Ui.icon_tex("badge_check", 40))
		skin.set_icon("unchecked", "CheckBox", Ui.icon_tex("box_empty", 40))
		skin.set_constant("h_separation", "CheckBox", 12)
		skin.set_constant("outline_size", "Label", 5)
		return skin
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
	if is_game():
		return skin_box("Sheet")
	if is_cozy():
		return cozy_style(COZY_POPUP, 0.6, [26, 56, 26, 30], [26, 6, 26, 30])
	var style := StyleBoxTexture.new()
	style.texture = SpriteLib.stitched(UI + "Papers/RegularPaper.png", [0, 128, 256])
	style.set_texture_margin_all(32)
	style.set_content_margin_all(30)
	return style


static func ribbon_style(color := Ribbon.BLUE) -> StyleBoxTexture:
	if is_game():
		return skin_box("TitlePlaque")
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
	style.set_corner_radius_all(maxi(radius, 14))
	style.set_border_width_all(3)
	# The old teal default border becomes the skin's brown line.
	style.border_color = LINE if border == Color("5d9d8d") else border
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
	if is_game():
		# Yellow = main action, red = back out / danger; tiny ones get a flat face.
		if min_size.x < 90.0 or min_size.y < 58.0:
			var fill := Color("ff6b5a") if red else Color("ffd23f")
			b.add_theme_stylebox_override("normal", flat_button_style(fill))
			b.add_theme_stylebox_override("hover", flat_button_style(fill))
			var down := flat_button_style(fill.darkened(0.12))
			down.border_width_bottom = 3
			b.add_theme_stylebox_override("pressed", down)
			b.add_theme_stylebox_override("disabled", flat_button_style(Color("b9b4b0")))
		else:
			b.theme_type_variation = "BtnRed" if red else "BtnYellow"
		return b
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
	var skin_icon: String = {DrawnIcon.Kind.GEM: "gem", DrawnIcon.Kind.LOCK: "lock", DrawnIcon.Kind.DOT: "badge_dot",
		DrawnIcon.Kind.GIFT: "rail_limited", DrawnIcon.Kind.SCROLL: "rail_quest",
		DrawnIcon.Kind.FLAG: "rail_event", DrawnIcon.Kind.PORTAL: "tab_summon"}.get(kind, "")
	if is_game() and skin_icon != "":
		var r := Ui.icon(skin_icon, icon_size)
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		return r
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
	back.bg_color = Color("3a2a1c")
	back.set_corner_radius_all(int(min_size.y))
	back.border_color = LINE
	back.set_border_width_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(int(min_size.y))
	fill.border_color = LINE
	fill.set_border_width_all(2)
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
	var caption := label(text, font_size)
	# Centred, so a plaque wider than its text (a fixed minimum width) keeps it in the middle.
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(caption)
	return panel


static func hbox(separation := 8) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func vbox(separation := 8) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


## Icon + amount, e.g. coin 250. `currency` is "gold", "gems" or "meat" (in-battle xu).
static func price(currency: String, amount: int, font_size := 18, on_paper := false) -> HBoxContainer:
	var row := hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_size := font_size * 1.4
	match currency:
		"gems":
			row.add_child(drawn(DrawnIcon.Kind.GEM, icon_size))
		"meat":
			row.add_child(icon(coin_texture() if is_game() else SpriteLib.texture(MEAT), icon_size))
		_:
			row.add_child(icon(coin_texture() if is_game() else SpriteLib.texture(COIN), icon_size))
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
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if SpriteLib.is_cat(troop.unit_key) else CanvasItem.TEXTURE_FILTER_NEAREST
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
	if is_game():
		return sheet_popup(host, width, title)
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


## How far the window sits below the plaque's top.
const PLAQUE_DROP := 26.0


## The skin's popup (layout.md "Popups"): dark scrim, cream window, the title plaque sitting
## on its top edge and a red round close on its top-right corner. The returned VBox starts
## with a small spacer (index 0), standing in for the old header row callers skip.
static func sheet_popup(host: Control, width: float, title: String) -> VBoxContainer:
	var overlay := ColorRect.new()
	overlay.color = Color(0.05, 0.06, 0.12, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = make_theme()
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	host.add_child(overlay)
	var context := Ui.menu_context_for_title(title)
	var ancestor: Node = host
	while context == "" and ancestor != null:
		if ancestor.has_method("active_menu_context"):
			context = ancestor.active_menu_context()
		ancestor = ancestor.get_parent()
	if context == "battle" or context == "":
		context = "hero"
	if Ui.register_menu_surface(host, overlay, context):
		return _menu_popup(overlay, width, title, context)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	# A plain Control frame, so the plaque and the close button are laid over the window
	# after it: drawn on top and, just as important, first to receive taps.
	var frame := Control.new()
	center.add_child(frame)
	var panel := Ui.panel("Sheet")
	frame.add_child(panel)
	panel.position = Vector2(0, PLAQUE_DROP)
	panel.custom_minimum_size.x = width
	var box := Ui.vbox(12)
	panel.add_child(box)
	box.add_child(gap(0, 22))
	var fit := func():
		var h := panel.get_combined_minimum_size().y
		panel.size = Vector2(width, h)
		frame.custom_minimum_size = Vector2(width, h + PLAQUE_DROP)
		frame.pivot_offset = frame.custom_minimum_size / 2.0
	panel.minimum_size_changed.connect(fit)
	fit.call()
	var plaque := Ui.center(Ui.title_plaque(title, "", 26))
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(plaque)
	plaque.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	plaque.offset_bottom = 56
	var close := close_button(overlay.queue_free)
	frame.add_child(close)
	close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -50
	close.offset_right = 18
	close.offset_top = 0
	close.offset_bottom = 68
	# A tap on the dark scrim outside the window closes it too.
	overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			overlay.queue_free())
	frame.scale = Vector2(0.85, 0.85)
	overlay.create_tween().tween_property(frame, "scale", Vector2.ONE, 0.12)
	box.set_meta("overlay", overlay)
	return box


## Menu-only B shell; long lists scroll inside the fixed tag/close boundary.
## Combat keeps sheet_popup's original art and typography below the menu branch.
static func _menu_popup(overlay: Control, width: float, title: String, context: String) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := vbox(14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	# Existing popup rebuilders preserve child zero as their header placeholder.
	box.add_child(gap(0, 0))
	var frame := Ui.menu_section(context, title, scroll)
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(frame)
	var close := close_button(overlay.queue_free)
	frame.add_child(close)
	close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -62
	close.offset_right = 6
	close.offset_top = 0
	close.offset_bottom = 68
	var fit := func():
		var view := overlay.get_viewport_rect().size
		var shell_width := minf(width, view.x - 48)
		var height_limit := maxf(120, view.y - 220)
		scroll.custom_minimum_size = Vector2(shell_width - 56, minf(box.get_combined_minimum_size().y, height_limit))
		frame.pivot_offset = frame.get_combined_minimum_size() / 2.0
	box.minimum_size_changed.connect(fit)
	overlay.resized.connect(fit)
	fit.call()
	overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			overlay.queue_free())
	box.set_meta("overlay", overlay)
	return box


static func close_popup(box: Control) -> void:
	var overlay = box.get_meta("overlay", null)
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()


# --- Forge Stones, avatars, dark popups --------------------------------------------------

## Forge Stone (đá rèn), the hero-cat equipment upgrade resource: a grey-blue cut stone.
const FORGE_STONE_TINT := Color("8fa3b8")

static func forge_stone_icon(icon_size: float) -> Control:
	var stone := drawn(DrawnIcon.Kind.SHARD, icon_size)
	stone.tint = FORGE_STONE_TINT
	return stone

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
	holder.add_theme_stylebox_override("panel", style)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size = Vector2(avatar_size, avatar_size)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var inner := avatar_size * 0.8
	var picture: Control
	picture = icon(SpriteLib.texture(Meta.avatar_path(clampi(int(value), 1, Meta.AVATAR_COUNT))), inner)
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.add_child(picture)
	return holder


## Dark modal sheet (same look as the level select): a brown-framed panel, a gold title
## and a close button. Returns the VBox to fill; close with close_popup(box).
static func dark_popup(host: Control, width: float, title: String) -> VBoxContainer:
	if is_game():
		return sheet_popup(host, width, title)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(overlay)
	var panel := PanelContainer.new()
	if is_game():
		panel.add_theme_stylebox_override("panel", skin_box("Board"))
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.08, 0.11, 0.97)
		style.border_color = FRAME_BROWN
		style.set_border_width_all(5)
		style.set_corner_radius_all(22)
		style.set_content_margin_all(20)
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
	# Near-black fills from the old look become the skin's slate (tinted ones stay).
	style.bg_color = DARK if is_game() and background.get_luminance() < 0.2 else background
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
	if int(reward.get("stones", 0)) > 0:
		var stones := hbox(2)
		stones.add_child(forge_stone_icon(font_size * 1.5))
		stones.add_child(label("%d" % reward["stones"], font_size))
		row.add_child(stones)
	# {"item": rarity} (a promised random item) or {"items": [ids]} (what was granted).
	var items: Array = reward.get("items", [])
	if reward.has("item"):
		var tag_label := label("Trang bị " + Economy.RARITY_NAMES[int(reward["item"])], font_size)
		tag_label.add_theme_color_override("font_color", Economy.RARITY_COLORS[int(reward["item"])])
		row.add_child(tag_label)
	for id in items:
		var d: Dictionary = HeroCat.ITEMS[id]
		var face := Ui.gear_card(d["icon"], HeroCat.SLOT_ICONS[d["slot"]], HeroCat.tone(d["rarity"]), "", font_size * 2.4)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(face)
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
