extends SceneTree

# Builds game/ui/skin/game_theme.tres from the skin SVGs (run tools/ui/make_svgs.py and an
# import first). The theme is plain Godot: set it on a Control and pick looks with
# theme_type_variation, in code or in the editor's Inspector.
# Run: Godot --headless --path . --script res://tools/ui/build_theme.gd
#
# Variations
#   Button:        BtnYellow (default) BtnGreen BtnBlue BtnRed BtnPurple BtnOrange BtnWhite BtnTab
#                  (disabled = grey; pressed = the sunk art)
#   PanelContainer: Board Well BluePanel Sheet TitlePlaque SectionPlaque InfoStrip HudPill Counter
#                  HudBar AvatarFrame LvPlaque NavCell NavSelected NavSelectedFooter
#                  CardUnitOrange/Yellow/Blue/Purple/Red  CardItemCream/Blue/Orange/Red/Purple
#                  TroopCardGreen/Blue/Purple/Orange/Locked
#   ProgressBar:   BarHpRed BarHpBlue BarHpGreen BarHpYellow BarExp BarItem
#   Label:         LabelTitle LabelSmall LabelTiny LabelDark LabelAccent

const SKIN := "res://game/ui/skin/"
const FONTS := "res://game/ui/fonts/"
const TEXT_LINE := Color("2e1c1c")
const DARK_TEXT := Color("4b4444")


func _init() -> void:
	var theme := Theme.new()
	var font := FontVariation.new()
	font.base_font = load(FONTS + "PaytoneOne-Regular.ttf")
	font.fallbacks = [load(FONTS + "DejaVuSans.ttf")]
	theme.default_font = font
	theme.default_font_size = 22

	_labels(theme)
	_buttons(theme)
	_panels(theme)
	_bars(theme)

	var path := SKIN + "game_theme.tres"
	var err := ResourceSaver.save(theme, path)
	print("Saved " + path if err == OK else "Save failed: %d" % err)
	quit()


## A 9-slice style from a skin SVG. `margins` = [left, top, right, bottom] of the art,
## `content` = padding for the children.
func _box(file: String, margins: Array, content: Array) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(SKIN + file + ".svg")
	box.texture_margin_left = margins[0]
	box.texture_margin_top = margins[1]
	box.texture_margin_right = margins[2]
	box.texture_margin_bottom = margins[3]
	box.content_margin_left = content[0]
	box.content_margin_top = content[1]
	box.content_margin_right = content[2]
	box.content_margin_bottom = content[3]
	return box


func _labels(theme: Theme) -> void:
	theme.set_color("font_color", "Label", Color.WHITE)
	theme.set_color("font_outline_color", "Label", TEXT_LINE)
	theme.set_constant("outline_size", "Label", 7)
	for v in [["LabelTitle", 30, 9], ["LabelSmall", 18, 6], ["LabelTiny", 15, 5]]:
		theme.set_type_variation(v[0], "Label")
		theme.set_font_size("font_size", v[0], v[1])
		theme.set_constant("outline_size", v[0], v[2])
	theme.set_type_variation("LabelDark", "Label")
	# #5c3d38: 4.8:1 on the Well, 5.5:1 on the Board (#6b4a45 was 3.9:1 on the Well).
	theme.set_color("font_color", "LabelDark", Color("5c3d38"))
	theme.set_constant("outline_size", "LabelDark", 0)
	theme.set_type_variation("LabelAccent", "Label")
	theme.set_color("font_color", "LabelAccent", Color("7bf07d"))


func _buttons(theme: Theme) -> void:
	var tones := {"BtnYellow": "yellow", "BtnGreen": "green", "BtnBlue": "blue", "BtnRed": "red",
		"BtnPurple": "purple", "BtnOrange": "orange", "BtnWhite": "white", "BtnTab": "tab"}
	var margins := [40, 33, 40, 36]
	var normal_pad := [22, 10, 22, 22]
	var pressed_pad := [22, 16, 22, 16]
	var disabled := _box("btn_grey", margins, normal_pad)
	for type in ["Button"] + tones.keys():
		var tone: String = tones.get(type, "yellow")
		if type != "Button":
			theme.set_type_variation(type, "Button")
		var normal := _box("btn_" + tone, margins, normal_pad)
		theme.set_stylebox("normal", type, normal)
		theme.set_stylebox("hover", type, normal)
		theme.set_stylebox("pressed", type, _box("btn_%s_pressed" % tone, margins, pressed_pad))
		theme.set_stylebox("hover_pressed", type, _box("btn_%s_pressed" % tone, margins, pressed_pad))
		theme.set_stylebox("disabled", type, disabled)
		theme.set_stylebox("focus", type, StyleBoxEmpty.new())
		var ink := DARK_TEXT if tone == "white" else Color.WHITE
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			theme.set_color(key, type, ink)
		theme.set_color("font_disabled_color", type, Color(0.95, 0.95, 0.95))
		theme.set_color("font_outline_color", type, TEXT_LINE)
		theme.set_constant("outline_size", type, 0 if tone == "white" else 7)
		theme.set_constant("h_separation", type, 8)
		theme.set_font_size("font_size", type, 26)


func _panel(theme: Theme, type: String, file: String, margins: Array, content: Array) -> void:
	theme.set_type_variation(type, "PanelContainer")
	theme.set_stylebox("panel", type, _box(file, margins, content))


func _panels(theme: Theme) -> void:
	theme.set_stylebox("panel", "PanelContainer", StyleBoxEmpty.new())
	_panel(theme, "Board", "board", [34, 34, 34, 42], [28, 24, 28, 32])
	_panel(theme, "Well", "well", [18, 18, 18, 18], [16, 16, 16, 16])
	_panel(theme, "BluePanel", "blue_panel", [0, 10, 0, 0], [0, 10, 0, 0])
	_panel(theme, "Sheet", "sheet", [22, 22, 22, 28], [20, 18, 20, 24])
	_panel(theme, "TitlePlaque", "title_plaque", [24, 20, 24, 20], [30, 4, 30, 8])
	_panel(theme, "SectionPlaque", "section_plaque", [34, 20, 34, 20], [38, 2, 38, 6])
	_panel(theme, "InfoStrip", "info_strip", [22, 20, 22, 20], [20, 4, 20, 4])
	_panel(theme, "HudPill", "hud_pill", [18, 18, 18, 18], [0, 0, 0, 0])
	_panel(theme, "Counter", "counter", [19, 18, 19, 18], [14, 0, 16, 0])
	# No band behind the HUD: resources sit straight on each screen's own background.
	theme.set_type_variation("HudBar", "PanelContainer")
	var hud_box := StyleBoxEmpty.new()
	hud_box.content_margin_left = 16
	hud_box.content_margin_top = 14
	hud_box.content_margin_right = 20
	hud_box.content_margin_bottom = 12
	theme.set_stylebox("panel", "HudBar", hud_box)
	_panel(theme, "AvatarFrame", "avatar_frame", [16, 16, 16, 20], [8, 8, 8, 12])
	_panel(theme, "LvPlaque", "lv_plaque", [10, 10, 10, 10], [8, 0, 8, 2])
	_panel(theme, "NavCell", "nav_cell", [24, 24, 24, 24], [4, 4, 4, 6])
	_panel(theme, "NavSelected", "nav_selected", [26, 30, 26, 30], [0, 6, 0, 0])
	_panel(theme, "NavSelectedFooter", "nav_selected_footer", [4, 2, 4, 0], [4, 2, 4, 0])
	for tone in ["green", "blue", "purple", "orange", "locked"]:
		_panel(theme, "TroopCard" + tone.capitalize(), "troop_card_" + tone, [14, 14, 14, 14], [8, 8, 8, 8])
		if tone != "locked":
			_panel(theme, "TroopCard" + tone.capitalize() + "Pressed", "troop_card_" + tone + "_pressed", [14, 14, 14, 14], [8, 8, 8, 8])
	for tone in ["green", "blue", "purple", "orange", "grey"]:
		_panel(theme, "GearBg" + tone.capitalize(), "gear_bg_" + tone, [26, 26, 26, 30], [0, 0, 0, 0])
	_panel(theme, "Callout", "callout", [20, 14, 20, 22], [14, 4, 14, 16])
	_panel(theme, "Rail", "rail_bg", [30, 30, 30, 30], [6, 12, 6, 12])
	for tone in ["green", "orange", "yellow", "blue", "purple", "red"]:
		_panel(theme, "CardUnit" + tone.capitalize(), "card_unit_" + tone, [20, 20, 20, 24], [8, 10, 8, 12])
	for tone in ["cream", "blue", "orange", "red", "purple"]:
		_panel(theme, "CardItem" + tone.capitalize(), "card_item_" + tone, [20, 20, 20, 24], [10, 10, 10, 14])


func _bar(theme: Theme, type: String, track: String, fill: String, track_m: Array, fill_m: Array, inset: int) -> void:
	theme.set_type_variation(type, "ProgressBar")
	theme.set_stylebox("background", type, _box(track, track_m, [0, 0, 0, 0]))
	var f := _box(fill, fill_m, [0, 0, 0, 0])
	f.expand_margin_left = -inset
	f.expand_margin_top = -inset
	f.expand_margin_right = -inset
	f.expand_margin_bottom = -inset
	theme.set_stylebox("fill", type, f)
	theme.set_color("font_color", type, Color.WHITE)
	theme.set_color("font_outline_color", type, TEXT_LINE)
	theme.set_constant("outline_size", type, 5)
	theme.set_font_size("font_size", type, 17)


func _bars(theme: Theme) -> void:
	for tone in ["red", "blue", "green", "yellow"]:
		_bar(theme, "BarHp" + tone.capitalize(), "bar_track_hp", "bar_fill_" + tone, [14, 13, 14, 13], [11, 10, 11, 10], 3)
	_bar(theme, "BarExp", "bar_track_exp", "bar_fill_exp", [7, 6, 7, 6], [5, 4, 5, 4], 2)
	_bar(theme, "BarItem", "bar_track_item", "bar_fill_item", [6, 8, 6, 8], [4, 6, 4, 6], 2)
