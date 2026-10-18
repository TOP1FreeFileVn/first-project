extends Control

# Gear inventory preview, laid out like the real Gear Defenders "Deployed Cards / Inventory"
# screen, built only from themed Controls and Containers (game/ui/Ui.gd + the SVG skin).
# Also shows a locked button state.
# Run: Godot --path . res://tests/ui/GearsPreview.tscn [-- --shot=C:/some/folder/gears.png]

const Ui = preload("res://game/ui/Ui.gd")

const TABS := [["tab_shop", "Cửa hàng"], ["tab_cat", "Anh hùng"], ["tab_battle", "Chiến"], ["tab_army", "Lính"], ["tab_summon", "Triệu hồi"]]
## [tone, icon, level, have, need]
const DEPLOYED := [["cream", "heart", "5", 4, 6], ["cream", "gear", "6", 6, 7], ["cream", "bolt", "3", 3, 4], ["cream", "star", "6", 1, 7]]
const OWNED := [
	["blue", "coins", "4", 3, 5], ["orange", "paw", "2", 1, 3], ["blue", "gem", "3", 3, 4], ["blue", "heart", "3", 1, 4],
	["blue", "gear", "3", 3, 4], ["red", "bolt", "2", 1, 3], ["orange", "star", "1", 1, 2], ["purple", "chest", "1", 1, 2],
]


func _ready() -> void:
	Ui.setup_root(self)
	var bg := ColorRect.new()
	bg.color = Color("b8524a")
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := Ui.vbox(0)
	add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_child(Ui.hud(4, "21/30", "00:12", "1.340", "9.604", 0.38))
	var pad := Ui.margin(12, 12, 12, 8)
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(_board())
	col.add_child(pad)
	col.add_child(Ui.bottom_nav(TABS, 3))
	_shot_if_asked()


func _board() -> Control:
	var board := Ui.panel("Board")
	var stack := Ui.vbox(14)
	board.add_child(stack)

	stack.add_child(Ui.center(Ui.title_plaque("Đang trang bị")))
	var deployed := Ui.hbox(14)
	for d in DEPLOYED:
		deployed.add_child(Ui.item_card(d[0], d[1], d[2], d[3], d[4]))
	stack.add_child(Ui.panel("Well", deployed))

	var head := Ui.hbox(0)
	head.add_child(Ui.spacer())
	head.add_child(Ui.title_plaque("Kho đồ"))
	var right := Ui.hbox(0, BoxContainer.ALIGNMENT_END)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(Ui.counter("gear", "8/12"))
	head.add_child(right)
	stack.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 18)
	for o in OWNED:
		grid.add_child(Ui.item_card(o[0], o[1], o[2], o[3], o[4]))
	var top := Ui.hbox(0)
	top.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(grid)
	var well := Ui.panel("Well", top)
	well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(well)

	var buttons := Ui.hbox(14)
	buttons.add_child(Ui.cost_button("Quay 1", "5/5", "ad", "White"))
	buttons.add_child(Ui.cost_button("Quay 1", "20", "gem", "Blue"))
	buttons.add_child(Ui.lock(Ui.cost_button("Quay 10", "180", "gem", "Purple")))
	stack.add_child(buttons)
	return board


func _shot_if_asked() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			await get_tree().create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.get_slice("=", 1))
			get_tree().quit()
