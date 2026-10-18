extends Control

# "Anh hùng" screen, modelled on Capybara Go's equipment screen (the reference the user sent):
# a cream panel with the hero in the middle and 6 gear cards beside it (type badge, Lv, up
# arrow), a big power plaque and 3 stat pills under it, a row of feature shortcuts, then a
# dark bag with "sort / title / merge" header and a 5-column grid. Tapping an item opens the
# comparison sheet (`-- --detail`).
# Run: Godot --path . res://tests/ui/HeroPreview.tscn [-- --detail] [-- --shot=C:/x/hero.png]

const Ui = preload("res://game/ui/Ui.gd")

const TABS := [["tab_shop", "Cửa hàng"], ["tab_cat", "Anh hùng"], ["tab_battle", "Chiến"], ["tab_army", "Lính"], ["tab_summon", "Triệu hồi"]]
## [item icon, slot type icon, tone, level, can upgrade]
const LEFT := [["w_katana", "w_kiem", "orange", "14", true], ["eq_helmet", "eq_helmet", "purple", "16", true], ["eq_armor", "eq_armor", "purple", "11", true]]
const RIGHT := [["eq_amulet", "eq_amulet", "purple", "10", true], ["eq_ring", "eq_ring", "green", "10", true], ["eq_boots", "eq_boots", "purple", "10", false]]
const BAG := [
	["w_dai_bac", "w_kiem", "orange", "1"], ["w_sach_phep", "w_kiem", "purple", "1"], ["eq_helmet", "eq_helmet", "blue", "1"], ["w_chuy", "w_kiem", "green", "1"], ["eq_ring", "eq_ring", "green", "1"],
	["eq_armor", "eq_armor", "green", "1"], ["w_riu", "w_kiem", "green", "1"], ["eq_boots", "eq_boots", "green", "1"], ["eq_amulet", "eq_amulet", "green", "1"], ["w_no", "w_kiem", "green", "1"],
	["eq_gloves", "eq_gloves", "green", "1"], ["w_gay_phep", "w_kiem", "green", "1"], ["w_giao", "w_kiem", "green", "1"], ["eq_helmet", "eq_helmet", "green", "1"], ["eq_ring", "eq_ring", "green", "1"],
]


func _ready() -> void:
	Ui.setup_root(self)
	var bg := ColorRect.new()
	bg.color = Color("2c3046")  # dark bag colour fills everything behind the panels
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := Ui.vbox(0)
	add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_child(Ui.hud(12, "28/30", "02:41", "12.450", "860", 0.86))
	col.add_child(_doll())
	col.add_child(_bag())
	col.add_child(Ui.bottom_nav(TABS, 1))
	if "--detail" in OS.get_cmdline_user_args():
		_detail_sheet()
	_shot_if_asked()


## Cream panel: cards | hero | cards, power plaque, stat pills, feature shortcuts.
func _doll() -> Control:
	var sheet := Ui.panel("Sheet")
	var box := Ui.vbox(8)
	sheet.add_child(box)

	var row := Ui.hbox(0)
	row.add_child(_column(LEFT))
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(250, 410)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Ui.pin(stage, Ui.image("platform", Vector2(240, 96)), Vector2(-120, -100), Control.PRESET_CENTER_BOTTOM)
	Ui.pin(stage, Ui.image("cat_hero", Vector2(250, 234)), Vector2(-125, -282), Control.PRESET_CENTER_BOTTOM)
	row.add_child(stage)
	row.add_child(_column(RIGHT))
	box.add_child(row)

	var power := Ui.hbox(6)
	power.add_child(Ui.icon("star", 40))
	power.add_child(Ui.label("12.8K", "", 28))
	box.add_child(Ui.center(Ui.panel("TitlePlaque", power)))

	var stats := Ui.hbox(8)
	stats.add_child(Ui.stat_pill("heart", "11.7K", 170))
	stats.add_child(Ui.stat_pill("w_kiem", "3.144", 170))
	stats.add_child(Ui.stat_pill("eq_armor", "511", 150))
	stats.add_child(Ui.button("", "Tab", Vector2(64, 54), 0, "rail_quest"))
	box.add_child(stats)

	# Shortcuts: what this hero has besides gear (skill gears of the weapon, soldier pairing,
	# skins, collection, achievements).
	var shortcuts := Ui.hbox(0)
	shortcuts.add_child(Ui.shortcut("gear", "Kỹ năng", true))
	shortcuts.add_child(Ui.shortcut("tab_army", "Hợp lính"))
	shortcuts.add_child(Ui.shortcut("chest", "Sưu tập"))
	shortcuts.add_child(Ui.shortcut("rail_pass", "Thành tựu", true))
	shortcuts.add_child(Ui.shortcut("tab_cat", "Skin"))
	box.add_child(Ui.panel("Well", shortcuts))

	var m := Ui.margin(10, 4, 10, 8)
	m.add_child(sheet)
	return m


func _column(items: Array) -> VBoxContainer:
	var c := Ui.vbox(12, BoxContainer.ALIGNMENT_CENTER)
	for it in items:
		c.add_child(Ui.gear_card(it[0], it[1], it[2], it[3], 128, it[4]))
	return c


## Dark bag: header (sort / title / merge) and a scrolling 5-column grid.
func _bag() -> Control:
	var box := Ui.vbox(10)
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var head := Ui.hbox(10)
	head.add_child(Ui.button("Theo phẩm", "Blue", Vector2(170, 60), 19))
	var title := Ui.label("Trang bị của tôi", "", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var merge := Ui.button("Ghép", "Green", Vector2(150, 60), 20)
	Ui.dot(merge)
	head.add_child(merge)
	var band := Ui.panel("Well", head)
	box.add_child(band)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for it in BAG:
		grid.add_child(Ui.gear_card(it[0], it[1], it[2], it[3], 124))
	scroll.add_child(Ui.center(grid))
	box.add_child(scroll)
	var m := Ui.margin(12, 2, 12, 0)
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	m.add_child(box)
	return m


## Comparison sheet (tap an item): equipped vs new, coloured diffs, actions.
func _detail_sheet() -> void:
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.55)
	add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sheet := Ui.panel("Sheet")
	add_child(sheet)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.offset_top = -560
	sheet.offset_left = 16
	sheet.offset_right = -16
	sheet.offset_bottom = -20
	var box := Ui.vbox(12)
	sheet.add_child(box)
	var head := Ui.hbox(18)
	for side in [["Đang mặc", "w_katana", "orange", "14", "Katana"], ["Mới", "w_dai_bac", "orange", "1", "Đại bác"]]:
		var c := Ui.vbox(4)
		c.add_child(Ui.label(side[0], "LabelDark", 18))
		c.add_child(Ui.center(Ui.gear_card(side[1], "w_kiem", side[2], side[3], 124)))
		c.add_child(Ui.label(side[4], "LabelDark", 20))
		head.add_child(c)
		if side[0] == "Đang mặc":
			head.add_child(_arrow(44))
	box.add_child(head)
	for r in [["Công", "3.144", "3.372", "+228", true], ["Tầm đánh", "2,1", "9", "+6,9", true], ["Tốc đánh", "1,25", "0,33", "−0,92", false]]:
		var row := Ui.hbox(10)
		var stat := Ui.label(r[0], "LabelDark", 20)
		stat.custom_minimum_size.x = 150
		row.add_child(stat)
		row.add_child(Ui.label("%s → %s" % [r[1], r[2]], "LabelDark", 20))
		var diff := Ui.label(r[3], "LabelSmall", 20)
		diff.add_theme_color_override("font_color", Color("3fbf4a") if r[4] else Color("e04b4b"))
		row.add_child(diff)
		box.add_child(Ui.panel("Well", row))
	var fit := Ui.hbox(8)
	fit.add_child(Ui.label("Đổi lính hợp:", "LabelDark", 18))
	fit.add_child(Ui.icon("w_kiem", 32))
	fit.add_child(_arrow(26))
	fit.add_child(Ui.icon("w_cung", 32))
	box.add_child(fit)
	var actions := Ui.hbox(14)
	actions.add_child(Ui.button("Nâng cấp", "Blue", Vector2(200, 76), 22))
	actions.add_child(Ui.button("Trang bị", "Yellow", Vector2(260, 76), 24))
	box.add_child(actions)


## "→": the back chevron mirrored.
func _arrow(size: float) -> TextureRect:
	var a := Ui.icon("back", size)
	a.flip_h = true
	return a


func _shot_if_asked() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			await get_tree().create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.get_slice("=", 1))
			get_tree().quit()
