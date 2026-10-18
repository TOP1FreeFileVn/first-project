extends Control

# Cat screen preview, laid out like the real Gear Defenders troops screen, built only from
# themed Controls and Containers (game/ui/Ui.gd + the SVG skin).
# Run: Godot --path . res://tests/ui/LobbyPreview.tscn [-- --shot=C:/some/folder/lobby.png]

const Ui = preload("res://game/ui/Ui.gd")

const TABS := [["tab_shop", "Cửa hàng"], ["tab_cat", "Anh hùng"], ["tab_battle", "Chiến"], ["tab_army", "Lính"], ["tab_summon", "Triệu hồi"]]
const STANDS := [["cat_tabby", "4"], ["cat_hero", "5"], ["cat_grey", "5"], ["cat_calico", "5"]]
## [tone, icon, name, level, picked]
const TROOPS := [
	["orange", "star", "Ninja", "1", false], ["orange", "bolt", "Giáo", "2", false], ["yellow", "gear", "Kỵ binh", "1", false],
	["yellow", "heart", "Nỏ", "2", false], ["yellow", "gem", "Pháp sư", "1", false],
	["yellow", "coin", "Rìu", "5", false], ["blue", "bolt", "Thương", "5", true], ["blue", "star", "Cung", "5", true],
	["blue", "heart", "Kiếm", "4", true], ["blue", "gear", "Khiên", "5", true],
]


func _ready() -> void:
	Ui.setup_root(self)
	# Field green behind the HUD, continuing the wall scene's top (no HUD band any more).
	var field := ColorRect.new()
	field.color = Color("93cf68")
	add_child(field)
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := Ui.vbox(0)
	add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_child(Ui.hud(3, "29/30", "03:27", "2.630", "10.304", 0.62))
	col.add_child(_scene())
	col.add_child(_troops())
	col.add_child(Ui.bottom_nav(TABS, 1, [0]))
	_shot_if_asked()


## The castle wall with the cat's plaque, upgrade pill, HP strip and units on their stands.
func _scene() -> Control:
	var scene := Control.new()
	scene.custom_minimum_size.y = 566
	var wall := Ui.image("wall_scene", Vector2.ZERO)
	wall.stretch_mode = TextureRect.STRETCH_SCALE
	scene.add_child(wall)
	wall.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Ui.pin(scene, Ui.image("bush", Vector2(110, 76)), Vector2(-30, -70), Control.PRESET_BOTTOM_LEFT)
	Ui.pin(scene, Ui.image("bush", Vector2(110, 76)), Vector2(-80, -70), Control.PRESET_BOTTOM_RIGHT)

	var pad := Ui.margin(24, 126, 24, 58)
	scene.add_child(pad)
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := Ui.vbox(8)
	pad.add_child(stack)
	stack.add_child(Ui.center(Ui.title_plaque("Mèo Thủ Thành", "Lv12")))
	stack.add_child(Ui.center(Ui.button("Nâng cấp", "Green", Vector2(156, 60), 22)))
	stack.add_child(Ui.info_strip("Máu thành", "Lv(10/10)", "740", "230", "coin", "heart"))
	stack.add_child(Ui.spacer())  # room for the cats' heads above the stands
	var stands := Ui.hbox(0)
	for s in STANDS:
		stands.add_child(Ui.platform(s[0], s[1]))
	stack.add_child(stands)
	return scene


## Blue lower half: section plaque on its top edge, a 5-column card grid.
func _troops() -> Control:
	var area := Control.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var blue := Ui.panel("BluePanel")
	area.add_child(blue)
	blue.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pad := Ui.margin(20, 40, 20, 10)
	blue.add_child(pad)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 14)
	for t in TROOPS:
		grid.add_child(Ui.unit_card(t[0], t[1], t[2], t[3], t[4]))
	var top := Ui.vbox(0)
	top.add_child(Ui.center(grid))
	pad.add_child(top)
	var plaque := Ui.section_plaque("Quân hỗ trợ")
	Ui.pin(area, plaque, Vector2(-120, -22), Control.PRESET_CENTER_TOP)
	return area


func _shot_if_asked() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			await get_tree().create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.get_slice("=", 1))
			get_tree().quit()
