extends Node

# Static design comparison only. Production Home and troop behavior stay untouched.
const Ui = preload("res://game/ui/Ui.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const Economy = preload("res://game/core/Economy.gd")
const HomeScene = preload("res://game/menu/Home.tscn")
const OUT := "res://docs/ui_review/2026-10-19/troops-proposals"
const INK := Color("583f21")
const MUTED := Color("79684f")
const BODY_FONT = preload("res://game/ui/fonts/DejaVuSans.ttf")
const RARITY := [Color("75ad56"), Color("4d9ec3"), Color("a17bc5"), Color("cc9557")]
var _home: Control
var _preview: Control
var _labels: Array[Label] = []


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
	PlayerData.troops["kiem"]["level"] = 7
	PlayerData.troops["kiem"]["cards"] = 7
	PlayerData.troops["riu"]["cards"] = 9
	PlayerData.team = ["gay_phep", "cung", "chuy"]
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.TROOPS_TAB, false)
	await _capture("current")
	_home._content.visible = false
	_preview = Control.new()
	_preview.theme = Ui.THEME
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_preview.position = Vector2(24, 124)
	_preview.size = Vector2(672, 988)
	_home.add_child(_preview)
	var column := Ui.vbox(12)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview.add_child(column)
	var title := _text("Lính", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.custom_minimum_size.y = 40
	column.add_child(title)
	column.add_child(_team())
	var collection := _text("Bộ sưu tập", 28)
	collection.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	collection.custom_minimum_size.y = 32
	column.add_child(collection)
	column.add_child(_filters())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	for id in PlayerData.TROOP_ORDER:
		grid.add_child(_card(id))
	scroll.add_child(grid)
	await _capture("grid")
	scroll.scroll_vertical = 100000
	await _capture("grid_scrolled")
	var checks := []
	var failures := 0
	for label in _labels:
		var width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		var fits := width <= label.size.x + 1.0
		checks.append({"text": label.text, "width": width, "available": label.size.x, "fits": fits})
		if not fits:
			failures += 1
	var file := FileAccess.open(OUT + "/grid-labels.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"static_mockup": true, "persist": PlayerData.persist, "labels": checks, "failures": failures}, "\t"))
	print("TROOPS_GRID_PROPOSAL: static previews captured; label failures=", failures)
	get_tree().quit(1 if failures else 0)


func _text(value: String, font_size: int, color := INK) -> Label:
	var text := Ui.label(value, "LabelDark", font_size)
	text.add_theme_color_override("font_color", color)
	text.add_theme_constant_override("outline_size", 0)
	if font_size <= 24:
		text.add_theme_font_override("font", BODY_FONT)
	_labels.append(text)
	return text


func _panel(fill: Color, border := INK, radius := 16, padding := 12) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _team() -> PanelContainer:
	var panel := _panel(Color("f6e7c9"))
	panel.custom_minimum_size.y = 222
	var column := Ui.vbox(4)
	panel.add_child(column)
	var header := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	header.add_child(_text("Đội hình 3/3", 28))
	header.add_child(Ui.spacer())
	header.add_child(Ui.icon("star", 26))
	header.add_child(_text(UiKit.format_number(PlayerData.team_power()), 26))
	column.add_child(header)
	var row := Ui.hbox(8)
	for index in 5:
		var slot := _panel(Color("fff5df") if index < 3 else Color("e6dac4"), Color("ba9b70"), 10, 2)
		slot.custom_minimum_size = Vector2(115, 138)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var slot_body := Ui.vbox(0, BoxContainer.ALIGNMENT_CENTER)
		slot.add_child(slot_body)
		if index < 3:
			var portrait := UiKit.troop_portrait(PlayerData.TROOPS[PlayerData.team[index]], 72)
			portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			slot_body.add_child(portrait)
			slot_body.add_child(_text(PlayerData.TROOPS[PlayerData.team[index]].display_name.trim_prefix("Mèo "), 20))
			slot_body.add_child(_text("Cấp 1", 22))
		else:
			slot_body.add_child(Ui.center(Ui.icon("lock", 40)))
			slot_body.add_child(_text("Thành %d" % (3 if index == 3 else 6), 20, MUTED))
		row.add_child(slot)
	column.add_child(row)
	column.add_child(_text("Chạm để xem · Giữ để đổi đội", 22, MUTED))
	return panel


func _filters() -> HBoxContainer:
	var row := Ui.hbox(6)
	for name in ["Tất cả", "Thường", "Hiếm", "Sử thi", "Huyền thoại"]:
		var selected: bool = name == "Tất cả"
		var pill := _panel(Color("efce79") if selected else Color("e9eef1"), INK if selected else Color("aabac8"), 16, 6)
		pill.custom_minimum_size.y = 72
		pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pill.add_child(_text(name, 24))
		row.add_child(pill)
	return row


func _card(id: String) -> PanelContainer:
	var troop: Resource = PlayerData.TROOPS[id]
	var unlocked: bool = PlayerData.is_unlocked(id)
	var color: Color = RARITY[troop.rarity]
	var card := _panel(Color("fff4de") if unlocked else Color("e9e2d8"), color, 14, 12)
	card.custom_minimum_size = Vector2(316, 268)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := Ui.vbox(4)
	card.add_child(column)
	var name_row := Ui.hbox(4)
	var name_label := _text(troop.display_name, 26)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)
	if unlocked and PlayerData.in_team(id):
		name_row.add_child(Ui.icon("badge_check", 24))
	column.add_child(name_row)
	column.add_child(_text("%s · %s" % [["Thường", "Hiếm", "Sử thi", "Huyền thoại"][troop.rarity], troop.KLASS_NAMES[troop.klass]], 22, MUTED))
	var middle := Ui.hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	var portrait := UiKit.troop_portrait(troop, 96)
	if not unlocked:
		portrait.modulate = Color(0.65, 0.65, 0.65)
	middle.add_child(portrait)
	var stats := Ui.vbox(1, BoxContainer.ALIGNMENT_CENTER)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(stats)
	if unlocked:
		stats.add_child(_text("Cấp %d/%d" % [PlayerData.troop(id)["level"], PlayerData.level_cap(id)], 24))
		var stars := Ui.hbox(2)
		for star in Economy.MAX_STARS:
			stars.add_child(Ui.icon("star" if star < PlayerData.troop(id)["stars"] else "star_off", 22))
		stats.add_child(stars)
	else:
		stats.add_child(_text("Chưa mở", 23, MUTED))
		stats.add_child(Ui.center(Ui.icon("lock", 30)))
	column.add_child(middle)
	if unlocked:
		var need: int = PlayerData.star_up_cost(id)
		column.add_child(_text("Thẻ lên sao  %d/%d" % [PlayerData.troop(id)["cards"], need], 22, MUTED))
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size.y = 14
		bar.max_value = maxi(need, 1)
		bar.value = PlayerData.troop(id)["cards"]
		var track := StyleBoxFlat.new()
		track.bg_color = Color("d8cdb9")
		track.set_corner_radius_all(7)
		var fill := track.duplicate() as StyleBoxFlat
		fill.bg_color = Color("5ca3b9")
		bar.add_theme_stylebox_override("background", track)
		bar.add_theme_stylebox_override("fill", fill)
		column.add_child(bar)
		if need > 0 and PlayerData.troop(id)["cards"] >= need:
			column.add_child(_text("★ Đủ thẻ lên sao", 22, Color("704391")))
		else:
			column.add_child(_text("↑ Lên cấp bằng vàng", 22, Color("426c32")))
	else:
		column.add_child(_text("Nhận 1 thẻ để mở", 22, MUTED))
	return card


func _capture(key: String) -> void:
	for window_size in [Vector2i(720, 1280), Vector2i(360, 640)]:
		get_window().size = window_size
		await get_tree().create_timer(0.2).timeout
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png(OUT + "/%s_%dx%d.png" % [key, window_size.x, window_size.y])
