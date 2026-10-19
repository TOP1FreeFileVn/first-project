extends Node

# Static design proposal B. This fixture only covers Home's content band.
# The production HUD/navigation are preserved; no gameplay save or production file changes.
const HomeScene = preload("res://game/menu/Home.tscn")
const Ui = preload("res://game/ui/Ui.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const Economy = preload("res://game/core/Economy.gd")
const BODY_FONT = preload("res://game/ui/fonts/DejaVuSans.ttf")
const OUT := "res://docs/ui_review/2026-10-19/troops-proposals/rows"
const INK := Color("583f21")
const PAPER := Color("f3e6d0")
const CARD := Color("fff4df")
const RARITY := [Color("84ba65"), Color("6aa9d1"), Color("ab88c9"), Color("cea06d")]

var _home: Control
var _scroll: ScrollContainer


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 100000577
	PlayerData.gems = 9998159
	PlayerData.castle_level = 1
	for id in ["gay_phep", "cung", "chuy", "kiem", "riu"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["gay_phep", "cung", "chuy"]
	PlayerData.troops["kiem"]["level"] = 7
	PlayerData.troops["kiem"]["cards"] = 7
	PlayerData.troops["riu"]["cards"] = 9
	get_window().size = Vector2i(720, 1280)
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(3, false)
	_build()
	for native in [Vector2i(720, 1280), Vector2i(360, 640)]:
		get_window().size = native
		_scroll.scroll_vertical = 0
		await _shot("rows_%dx%d" % [native.x, native.y])
	_scroll.scroll_vertical = 9999
	await _shot("rows_360x640_scrolled")
	var manifest := {"proposal": "B — static one-column rows", "production_edits": false,
		"persist": PlayerData.persist, "profile": OS.get_user_data_dir(),
		"row_design_height": 184, "native_name_font_360": 14, "native_body_font_360": 12,
		"content_band_design": [0, 112, 720, 1008], "team": PlayerData.battle_team(),
		"troops": ["kiem", "riu", "dao", "katana"], "native_capture": true}
	var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	print("TROOPS_ROWS_PROPOSAL_COMPLETE static mockup; production HUD and nav preserved")
	get_tree().quit()


func _build() -> void:
	var root := Control.new()
	root.name = "StaticTroopsRowsProposal"
	root.theme = Ui.THEME
	root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	root.position = Vector2(0, 112)
	root.size = Vector2(720, 1008)
	root.clip_contents = true
	_home.add_child(root)
	var bg := ColorRect.new()
	bg.color = PAPER
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var margin := Ui.margin(24, 10, 24, 18)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(margin)
	var page := Ui.vbox(12)
	margin.add_child(page)
	var title := Ui.hbox(10, BoxContainer.ALIGNMENT_BEGIN)
	title.add_child(_text("Lính", 32))
	title.add_child(Ui.spacer())
	title.add_child(_text("Phác thảo B", 22, Color("826d51")))
	page.add_child(title)
	page.add_child(_team_panel())
	var hint := _text("Giữ lính để kéo đổi vị trí trong đội", 24, Color("826d51"))
	page.add_child(hint)
	var heading := Ui.hbox(10, BoxContainer.ALIGNMENT_BEGIN)
	heading.add_child(_text("Bộ sưu tập", 28))
	heading.add_child(Ui.spacer())
	heading.add_child(_text("Chạm lính để xem chi tiết", 24, Color("826d51")))
	page.add_child(heading)
	var filters := Ui.hbox(8)
	for caption in ["Tất cả", "Thường", "Hiếm", "Sử thi", "Huyền thoại"]:
		var chip := _surface(Color("ead59d") if caption == "Tất cả" else Color("eee4cf"), 12, 2, 10)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.custom_minimum_size.y = 54
		chip.add_child(_text(caption, 24))
		filters.add_child(chip)
	page.add_child(filters)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	page.add_child(_scroll)
	var rows := Ui.vbox(12)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(rows)
	for id in ["kiem", "riu", "dao", "katana"]:
		rows.add_child(_troop_row(id))


func _team_panel() -> PanelContainer:
	var panel := _surface(CARD, 18, 3, 14)
	var box := Ui.vbox(10)
	panel.add_child(box)
	var head := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	head.add_child(_text("Đội hình", 28))
	head.add_child(_text("3/3", 28, Color("438739")))
	head.add_child(Ui.spacer())
	head.add_child(Ui.icon("star", 28))
	head.add_child(_text(str(PlayerData.team_power()), 28))
	box.add_child(head)
	var slots := Ui.hbox(10)
	box.add_child(slots)
	for id in ["gay_phep", "cung", "chuy", "", ""]:
		var locked: bool = id == ""
		var index := slots.get_child_count()
		var rarity := int(PlayerData.TROOPS[id].rarity) if not locked else 0
		var slot := _surface(Color("e6ddc9") if locked else RARITY[rarity].lightened(0.63), 12, 2, 6)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.custom_minimum_size = Vector2(0, 126)
		var column := Ui.vbox(0, BoxContainer.ALIGNMENT_CENTER)
		slot.add_child(column)
		if locked:
			column.add_child(Ui.center(Ui.icon("lock", 40)))
			column.add_child(_text("Thành %d" % (3 if index == 3 else 6), 24))
		else:
			var art := UiKit.troop_portrait(PlayerData.TROOPS[id], 80)
			art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			column.add_child(art)
			column.add_child(_text("Cấp 1", 24))
		slots.add_child(slot)
	return panel


func _troop_row(id: String) -> PanelContainer:
	var troop: Resource = PlayerData.TROOPS[id]
	var data: Dictionary = PlayerData.troop(id)
	var locked: bool = not data["unlocked"]
	var panel := _surface(Color("e9e0cf") if locked else CARD, 16, 2, 14)
	panel.custom_minimum_size.y = 184
	var row := Ui.hbox(16, BoxContainer.ALIGNMENT_BEGIN)
	panel.add_child(row)
	var portrait_box := _surface(RARITY[troop.rarity].lightened(0.5), 14, 2, 6)
	portrait_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var art := UiKit.troop_portrait(troop, 102)
	if locked:
		art.modulate = Color(0.65, 0.65, 0.65)
	portrait_box.add_child(art)
	row.add_child(portrait_box)
	var info := Ui.vbox(4, BoxContainer.ALIGNMENT_CENTER)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(_text(troop.display_name, 28))
	info.add_child(_text("%s · %s" % [Economy.RARITY_NAMES[troop.rarity], troop.KLASS_NAMES[troop.klass]], 24, Color("745c3f")))
	if locked:
		info.add_child(_text("Chưa mở khóa", 24, Color("826d51")))
		info.add_child(_text("Mở rương để nhận 1 thẻ", 24, Color("826d51")))
	else:
		var level_row := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
		level_row.add_child(_text("Cấp %d/10" % data["level"], 24))
		for i in range(3):
			level_row.add_child(Ui.icon("star" if i < data["stars"] else "star_off", 24))
		info.add_child(level_row)
		var progress := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(174, 18)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.max_value = 10
		bar.value = data["cards"]
		var track := StyleBoxFlat.new()
		track.bg_color = Color("d8d1bd")
		track.set_corner_radius_all(7)
		var fill := track.duplicate()
		fill.bg_color = Color("6badd2")
		bar.add_theme_stylebox_override("background", track)
		bar.add_theme_stylebox_override("fill", fill)
		progress.add_child(bar)
		progress.add_child(_text("%d/10 thẻ" % data["cards"], 24))
		info.add_child(progress)
	var end := Ui.vbox(4, BoxContainer.ALIGNMENT_CENTER)
	end.custom_minimum_size.x = 80
	row.add_child(end)
	if locked:
		end.add_child(Ui.center(Ui.icon("lock", 36)))
	else:
		var status := _text("Có thể\nnâng cấp", 24, Color("346b2c"))
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		end.add_child(status)
	return panel


func _surface(color: Color, radius: int, border: int, padding: int) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = INK
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _text(value: String, font_size: int, color := INK) -> Label:
	var label := Ui.label(value, "LabelDark", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if color == Color("826d51"):
		color = Color("745c3f")
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 0)
	if font_size <= 24:
		label.add_theme_font_override("font", BODY_FONT)
	return label


func _shot(file_name: String) -> void:
	await get_tree().create_timer(0.25).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	shot.save_png(OUT + "/" + file_name + ".png")
	print("TROOPS_ROWS_PROPOSAL_CAPTURE ", file_name, " native=", shot.get_size())
