extends Control

# The 16 soldier weapons from the "Solider" design sheet (4 groups x 4 rarities) on rarity
# cards, using the game skin.
# Run: Godot --path . res://tests/ui/WeaponsPreview.tscn [-- --shot=C:/some/folder/weapons.png]

const Ui = preload("res://game/ui/Ui.gd")

## Rarity → card tone.
const RARITY := [["Bình thường", "green"], ["Hiếm", "blue"], ["Sử thi", "purple"], ["Huyền thoại", "orange"]]
const CLASS_ICON := {"Bộ binh": "w_kiem", "Tầm xa": "w_cung", "Pháp sư": "w_gay_phep", "Kỵ binh": "w_giao"}
const GROUPS := [
	["Bộ binh", [["w_kiem", "Kiếm"], ["w_riu", "Rìu"], ["w_dao", "Đao"], ["w_katana", "Katana"]]],
	["Tầm xa", [["w_cung", "Cung"], ["w_no", "Nỏ"], ["w_sung", "Súng"], ["w_dai_bac", "Đại bác"]]],
	["Pháp sư", [["w_gay_phep", "Gậy phép"], ["w_thuoc", "Thuốc"], ["w_sach_phep", "Sách phép"], ["w_dua_phep", "Đũa phép"]]],
	["Kỵ binh", [["w_giao", "Giáo"], ["w_cu_kiem", "Cự kiếm"], ["w_chuy", "Chùy"], ["w_bua", "Búa"]]],
]


func _ready() -> void:
	Ui.setup_root(self)
	var bg := ColorRect.new()
	bg.color = Color("e9d6cc")
	add_child(bg)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var pad := Ui.margin(14, 18, 14, 14)
	add_child(pad)
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board := Ui.panel("Board")
	pad.add_child(board)
	var stack := Ui.vbox(10)
	board.add_child(stack)
	stack.add_child(Ui.center(Ui.title_plaque("Vũ khí quân lính", "", 26)))
	var legend := Ui.hbox(14)
	for r in RARITY:
		var chip := Ui.panel("CardUnit" + String(r[1]).capitalize(), Ui.label(r[0], "LabelTiny", 15))
		legend.add_child(chip)
	stack.add_child(legend)
	for g in GROUPS:
		stack.add_child(Ui.center(Ui.title_plaque(g[0], "", 22)))
		var row := Ui.hbox(12)
		for i in 4:
			var item: Array = g[1][i]
			row.add_child(Ui.caption(Ui.gear_card(item[0], CLASS_ICON[g[0]], RARITY[i][1], "1", 132), item[1], "LabelSmall", 17))
		stack.add_child(Ui.panel("Well", row))
	_shot_if_asked()


func _shot_if_asked() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			await get_tree().create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.get_slice("=", 1))
			get_tree().quit()
