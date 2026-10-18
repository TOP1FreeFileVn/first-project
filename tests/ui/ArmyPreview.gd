extends Control

# "Lính" screen, on the same equipment pattern as the hero screen: pick a class (4 tabs with
# the counter ring), see the class's banner soldier with its 4 class-gear slots hugging it and
# the class totals, then the class's tiers as upgrade rows (Figma UI-057: name, level, stats,
# price on the same spot). Class gear boosts every tier of that class; hero gear is separate.
# Run: Godot --path . res://tests/ui/ArmyPreview.tscn [-- --shot=C:/some/folder/army.png]

const Ui = preload("res://game/ui/Ui.gd")

const TABS := [["tab_shop", "Cửa hàng"], ["tab_cat", "Anh hùng"], ["tab_battle", "Chiến"], ["tab_army", "Lính"], ["tab_summon", "Triệu hồi"]]
const CLASSES := [["w_kiem", "Bộ binh"], ["w_cung", "Tầm xa"], ["w_gay_phep", "Pháp sư"], ["w_giao", "Kỵ binh"]]
const SELECTED_CLASS := 0
## Class gear: [icon, tone ("" = empty), level]
const LEFT := [["eq_helmet", "blue", "4"], ["eq_armor", "purple", "6"]]
const RIGHT := [["eq_gloves", "green", "2"], ["eq_amulet", "", ""]]
## Tiers of Bộ binh (numbers from the "Solider (sửa)" sheet tab): [icon, tone, name, level, atk, hp, price, locked]
const TIERS := [
	["w_kiem", "green", "Kiếm", "8", "20", "60", "320", false], ["w_riu", "blue", "Rìu", "5", "43", "90", "540", false],
	["w_dao", "purple", "Đao", "3", "56", "140", "880", false], ["w_katana", "orange", "Katana", "1", "70", "285", "", true],
]


func _ready() -> void:
	Ui.setup_root(self)
	var bg := ColorRect.new()
	bg.color = Color("6f8fd8")
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := Ui.vbox(0)
	add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_child(Ui.hud(12, "28/30", "02:41", "12.450", "860", 0.86))
	var top := Ui.vbox(10)
	top.add_child(_class_tabs())
	top.add_child(_class_banner())
	var m := Ui.margin(12, 4, 12, 6)
	m.add_child(top)
	col.add_child(m)
	col.add_child(_tiers())
	col.add_child(Ui.bottom_nav(TABS, 3))
	_shot_if_asked()


func _class_tabs() -> Control:
	var row := Ui.hbox(8)
	for i in CLASSES.size():
		row.add_child(Ui.button(CLASSES[i][1], "Yellow" if i == SELECTED_CLASS else "Tab", Vector2(162, 64), 19, CLASSES[i][0]))
	return row


## Banner soldier (the class's top weapon) on a stand, 4 class-gear slots beside it, the class
## totals and the counter ring line under it.
func _class_banner() -> Control:
	var box := Ui.vbox(8)
	var row := Ui.hbox(10)
	row.add_child(_column(LEFT))
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(250, 250)
	Ui.pin(stage, Ui.image("platform", Vector2(230, 92)), Vector2(-115, -96), Control.PRESET_CENTER_BOTTOM)
	Ui.pin(stage, Ui.icon("w_katana", 170), Vector2(-85, -226), Control.PRESET_CENTER_BOTTOM)
	row.add_child(stage)
	row.add_child(_column(RIGHT))
	box.add_child(row)
	var totals := Ui.hbox(10)
	totals.add_child(Ui.stat_pill("w_kiem", "+5% Công", 160))
	totals.add_child(Ui.stat_pill("heart", "+8% Máu", 160))
	totals.add_child(Ui.stat_pill("eq_armor", "+12% Giáp", 170))
	box.add_child(totals)
	var counter := Ui.hbox(8)
	counter.add_child(Ui.label("Khắc", "LabelSmall", 18))
	counter.add_child(Ui.icon("w_gay_phep", 32))
	counter.add_child(Ui.label("Pháp sư ×2", "LabelAccent", 18))
	counter.add_child(Ui.label("  ·  Bị khắc bởi", "LabelSmall", 18))
	counter.add_child(Ui.icon("w_cung", 32))
	counter.add_child(Ui.label("Tầm xa", "LabelSmall", 18))
	box.add_child(Ui.panel("InfoStrip", Ui.center(counter)))
	return box


func _column(items: Array) -> VBoxContainer:
	var c := Ui.vbox(14, BoxContainer.ALIGNMENT_CENTER)
	for it in items:
		c.add_child(Ui.gear_card(it[0], it[0], it[1] if it[1] != "" else "grey", it[2] if it[2] != "" else "-", 116))
	return c


## The class's tiers as rows: rarity slot, name + level, stats, upgrade price always on the right.
func _tiers() -> Control:
	var board := Ui.panel("Board")
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := Ui.vbox(10)
	board.add_child(box)
	for t in TIERS:
		var row := Ui.hbox(12, BoxContainer.ALIGNMENT_BEGIN)
		row.add_child(Ui.gear_card(t[0], "w_kiem", t[1], t[3], 96))
		var info := Ui.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var n := Ui.label(t[2], "LabelDark", 22)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(n)
		var stats := Ui.hbox(14, BoxContainer.ALIGNMENT_BEGIN)
		for s in [["w_kiem", t[4]], ["heart", t[5]]]:
			var c := Ui.hbox(4)
			c.add_child(Ui.icon(s[0], 28))
			c.add_child(Ui.label(s[1], "LabelDark", 19))
			stats.add_child(c)
		info.add_child(stats)
		row.add_child(info)
		var b := Ui.button(t[6], "Green", Vector2(170, 70), 22, "coin")
		if t[7]:
			b = Ui.lock(Ui.button("Mở khoá", "Green", Vector2(170, 70), 20))
		row.add_child(b)
		box.add_child(Ui.panel("Well", row))
	var m := Ui.margin(6, 0, 6, 0)
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	m.add_child(board)
	return m


func _shot_if_asked() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			await get_tree().create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.get_slice("=", 1))
			get_tree().quit()
