extends Control

# Full-screen admin overlay opened from the lobby (debug / "admin" builds only). A top
# toolbar (undo, save, JSON, history, close), a row of tabs, and the selected tab below.
# Every balance edit goes through Balance and applies live; Save writes the override file.

const UiKit = preload("res://game/ui/UiKit.gd")
const Ui = preload("res://game/ui/Ui.gd")
const SimRunner = preload("res://game/admin/SimRunner.gd")
const TABS := [
	["Công thức", preload("res://game/admin/tabs/FormulaTab.gd")],
	["Lính", preload("res://game/admin/tabs/TroopTab.gd")],
	["Thành", preload("res://game/admin/tabs/CastleTab.gd")],
	["Cửa hàng", preload("res://game/admin/tabs/ShopTab.gd")],
	["Màn chơi", preload("res://game/admin/tabs/LevelTab.gd")],
	["Người chơi", preload("res://game/admin/tabs/PlayerTab.gd")],
	["Mô phỏng", preload("res://game/admin/tabs/SimTab.gd")],
	["Shop trận", preload("res://game/admin/tabs/BattleShopTab.gd")],
]
const TOP := 72.0
const TAB_BAR := 64.0

var home
var sim: Node

var _tab_buttons: Array = []
var _tabs: Array = []
var _current := -1
var _undo_button: Button
var _dirty_label: Label
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.make_theme()
	var back := Ui.pattern_bg(Ui.menu_pattern_color("admin"))
	back.name = "AdminPatternBackground"
	back.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	Ui.register_menu_surface(self, self, "admin")
	sim = SimRunner.new()
	add_child(sim)
	_build_toolbar()
	_build_tab_bar()
	_build_content()
	_build_toast()
	Balance.changed.connect(_on_balance_changed)
	PlayerData.changed.connect(_on_player_changed)
	select_tab(0)
	_refresh_toolbar()


func select_tab(index: int) -> void:
	_current = index
	for i in _tabs.size():
		_tabs[i].visible = i == index
		_tab_buttons[i].modulate = Color.WHITE if i == index else Color(0.6, 0.6, 0.6)
	_tabs[index].rebuild()


func tab(index: int):
	return _tabs[index]


func toast(text: String, color := UiKit.INFO) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


## Removes the panel together with the CanvasLayer the lobby put it on.
func dispose() -> void:
	if sim.running:
		sim.cancel()
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()


func close() -> void:
	if not Balance.dirty:
		dispose()
		return
	var box := UiKit.popup(self, 560, "Chưa lưu thay đổi")
	box.add_child(UiKit.ink("Bạn có %d mục đã chỉnh nhưng chưa lưu vào máy." % Balance.change_count(), 18))
	var row := UiKit.hbox(10)
	row.add_child(UiKit.button("LƯU & ĐÓNG", Vector2(170, 60), func():
		Balance.save("Lưu khi đóng admin")
		dispose()))
	row.add_child(UiKit.button("BỎ THAY ĐỔI", Vector2(170, 60), func():
		Balance.revert_to_saved()
		dispose(), true))
	box.add_child(row)


func _on_balance_changed() -> void:
	_refresh_toolbar()
	if _current >= 0 and not sim.running:
		_tabs[_current].rebuild()


func _on_player_changed() -> void:
	# The player tab shows the profile; other tabs don't depend on it.
	if _current == 5 and not sim.running:
		_tabs[_current].rebuild()


func _refresh_toolbar() -> void:
	_undo_button.disabled = not Balance.can_undo()
	_dirty_label.visible = Balance.dirty


func _build_toolbar() -> void:
	var bar := UiKit.hbox(8)
	bar.position = Vector2(12, 12)
	bar.size = Vector2(696, TOP - 16)
	add_child(bar)
	bar.add_child(UiKit.label("ADMIN", 26, UiKit.GOLD_TEXT))
	_dirty_label = UiKit.label("● chưa lưu", 15, UiKit.WARN)
	bar.add_child(_dirty_label)
	bar.add_child(UiKit.spacer())
	_undo_button = _tool("↶", func(): Balance.undo(), 56)
	bar.add_child(_undo_button)
	bar.add_child(_tool("LƯU", _open_save, 84))
	bar.add_child(_tool("JSON", _open_json, 84))
	bar.add_child(_tool("L.SỬ", _open_history, 84))
	var close_button := UiKit.button("", Vector2(52, 48), close, true)
	close_button.icon = Ui.icon_tex("close", 48)
	close_button.expand_icon = true
	bar.add_child(close_button)


func _tool(text: String, on_pressed: Callable, width: float) -> Button:
	var b := UiKit.button(text, Vector2(width, 48), on_pressed)
	b.add_theme_font_size_override("font_size", 16)
	return b


func _build_tab_bar() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, TOP)
	scroll.size = Vector2(720, TAB_BAR)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var row := UiKit.hbox(6)
	scroll.add_child(row)
	row.add_child(UiKit.gap(6))
	for i in TABS.size():
		var b := UiKit.button(TABS[i][0], Vector2(0, 50), select_tab.bind(i))
		b.add_theme_font_size_override("font_size", 16)
		row.add_child(b)
		_tab_buttons.append(b)


func _build_content() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, TOP + TAB_BAR)
	scroll.size = Vector2(720, 1280 - TOP - TAB_BAR)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	margin.add_theme_constant_override("margin_bottom", 80)
	scroll.add_child(margin)
	var stack := UiKit.vbox(0)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(stack)
	for entry in TABS:
		var t = entry[1].new()
		t.panel = self
		t.visible = false
		stack.add_child(t)
		_tabs.append(t)


func _build_toast() -> void:
	_toast = UiKit.label("", 18)
	_toast.position = Vector2(20, 1180)
	_toast.size = Vector2(680, 60)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_theme_stylebox_override("normal", UiKit.dark_style(10))
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)


# --- Toolbar popups -----------------------------------------------------------------------

func _open_save() -> void:
	var box := UiKit.popup(self, 600, "Lưu cân bằng")
	box.add_child(UiKit.ink("Ghi chú cho lần lưu này (để xem lại trong lịch sử):", 16))
	var note := LineEdit.new()
	note.placeholder_text = "vd: tăng giá cấp 8–10"
	note.custom_minimum_size = Vector2(0, 48)
	box.add_child(note)
	box.add_child(UiKit.ink("Đang có %d mục khác mặc định." % Balance.change_count(), 16))
	var save := UiKit.button("LƯU", Vector2(200, 60), func():
		Balance.save(note.text.strip_edges())
		UiKit.close_popup(box)
		toast("Đã lưu vào máy."))
	save.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(save)


func _open_json() -> void:
	var box := UiKit.popup(self, 660, "Xuất / nhập JSON")
	box.add_child(UiKit.ink("Toàn bộ thay đổi so với mặc định. Copy để gửi người khác, hoặc dán JSON vào ô rồi Nhập.", 15))
	var text := TextEdit.new()
	text.custom_minimum_size = Vector2(0, 420)
	text.text = Balance.export_json()
	box.add_child(text)
	var row1 := UiKit.hbox(8)
	row1.add_child(_tool("COPY", func():
		DisplayServer.clipboard_set(Balance.export_json())
		toast("Đã copy JSON."), 130))
	row1.add_child(_tool("DÁN", func(): text.text = DisplayServer.clipboard_get(), 130))
	row1.add_child(_tool("NHẬP Ô TRÊN", func():
		var problem := Balance.import_json(text.text)
		if problem == "":
			UiKit.close_popup(box)
			toast("Đã nhập. Nhớ bấm LƯU nếu muốn giữ.")
		else:
			toast(problem, UiKit.WARN), 190))
	box.add_child(row1)
	var row2 := UiKit.hbox(8)
	row2.add_child(UiKit.button("VỀ MẶC ĐỊNH TẤT CẢ", Vector2(300, 56), func():
		Balance.reset_all()
		UiKit.close_popup(box)
		toast("Đã về mặc định (chưa lưu)."), true))
	if Balance.can_write_to_build():
		row2.add_child(UiKit.button("GHI VÀO BẢN BUILD", Vector2(300, 56), func():
			var problem := Balance.write_to_build()
			UiKit.close_popup(box)
			toast("Đã ghi balance.json và .tres. Build lại để phát hành." if problem == "" else problem)))
	box.add_child(row2)


func _open_history() -> void:
	var box := UiKit.popup(self, 640, "Lịch sử lưu")
	var history := Balance.load_history()
	if history.is_empty():
		box.add_child(UiKit.ink("Chưa có lần lưu nào.", 18))
		return
	for entry in history:
		var row := UiKit.hbox(8)
		var info := UiKit.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UiKit.ink(entry["time"].replace("T", " "), 16))
		var summary: String = entry["note"] if entry["note"] != "" else "(không ghi chú)"
		info.add_child(UiKit.ink("%s · %d khoá thay đổi" % [summary, entry["overrides"].size()], 14))
		row.add_child(info)
		row.add_child(UiKit.button("KHÔI PHỤC", Vector2(150, 50), func():
			Balance.restore_history(entry)
			UiKit.close_popup(box)
			toast("Đã khôi phục bản %s (chưa lưu)." % entry["time"].replace("T", " "))))
		box.add_child(row)
