extends Control

# The lobby: resource bar on top (the avatar opens the profile), the selected page in the
# middle and the five-tab nav bar at the bottom (Battle, in the middle, is the biggest and
# the default tab). On the Battle tab, icons down the sides open the 7-day gift, the daily
# quests, the events hub and the hero summon. Event pages (Patrol, Summon) open on top of
# the tabs with a back button.

const UiKit = preload("res://game/ui/UiKit.gd")
const DrawnIcon = preload("res://game/ui/DrawnIcon.gd")
const AdminGate = preload("res://game/admin/AdminGate.gd")
const AdminPanel = preload("res://game/admin/AdminPanel.gd")
const MetaPopups = preload("res://game/menu/popups/MetaPopups.gd")
const SummonPage = preload("res://game/menu/pages/SummonPage.gd")
const PAGES := [
	preload("res://game/menu/pages/ShopPage.gd"),
	preload("res://game/menu/pages/TroopsPage.gd"),
	preload("res://game/menu/pages/BattlePage.gd"),
	preload("res://game/menu/pages/CastlePage.gd"),
	preload("res://game/menu/pages/HeroesPage.gd"),
]
const TAB_NAMES := ["Cửa hàng", "Lính", "CHIẾN ĐẤU", "Thành", "Tướng"]
const SHOP_TAB := 0
const BATTLE_TAB := 2
const TOP_HEIGHT := 84.0
const NAV_HEIGHT := 140.0
const SCREEN := Vector2(720, 1280)
const TAB_WIDTHS := [136.0, 136.0, 176.0, 136.0, 136.0]
const CENTER_RAISE := 24.0

# Remembered across scene changes so returning from a battle lands on the same tab.
static var last_tab := BATTLE_TAB

var _content: Control
var _pages: Array = []
var _tabs: Array = []
var _dots: Array = []
var _current := -1
var _gold_label: Label
var _gem_label: Label
var _cheat_label: Label
var _avatar_button: Button
## Icons beside the level select, and their alert dots by name.
var _side: Control
var _side_dots := {}
## An event page opened over the tabs, or null.
var _overlay: Control
var _overlay_page: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.make_theme()
	_content = Control.new()
	_content.position = Vector2(0, TOP_HEIGHT)
	_content.size = Vector2(SCREEN.x, SCREEN.y - TOP_HEIGHT - NAV_HEIGHT)
	_content.clip_contents = true
	add_child(_content)
	for script in PAGES:
		var page = script.new()
		page.home = self
		page.visible = false
		_content.add_child(page)
		page.build()
		_pages.append(page)
	_build_side_icons()
	_build_top_bar()
	_build_nav_bar()
	PlayerData.changed.connect(_on_data_changed)
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)
	select_tab(last_tab, false)
	_update_header()


func select_tab(index: int, animate := true) -> void:
	close_page()
	if index == _current:
		return
	var from := _current
	_current = index
	last_tab = index
	for i in _pages.size():
		_pages[i].visible = i == index
	var page: Control = _pages[index]
	page.refresh()
	if animate and from >= 0:
		page.position.x = 60.0 if index > from else -60.0
		page.modulate.a = 0.0
		var tween := create_tween().set_parallel()
		tween.tween_property(page, "position:x", 0.0, 0.15)
		tween.tween_property(page, "modulate:a", 1.0, 0.15)
	_update_tabs()


func start_battle(level_index: int) -> void:
	PlayerData.select_level(level_index)
	get_tree().change_scene_to_file("res://game/battle/Battle.tscn")


func _on_data_changed() -> void:
	_pages[_current].refresh()
	if _overlay_page != null:
		_overlay_page.refresh()
	_update_header()


func _on_tick() -> void:
	_pages[_current].tick()
	if _overlay_page != null:
		_overlay_page.tick()
	_update_tabs()


## Opens an event page (a MenuPage script) over the tabs, with a back button.
func open_page(script) -> void:
	close_page()
	var holder := ColorRect.new()
	holder.color = Color(0.05, 0.07, 0.1, 0.98)
	holder.position = _content.position
	holder.size = _content.size
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(holder)
	move_child(holder, _side.get_index() + 1)
	# A strip with the back button above the page.
	var page = script.new()
	page.home = self
	holder.add_child(page)
	page.offset_top = 64
	page.build()
	var back := UiKit.button("◀  QUAY LẠI", Vector2(190, 52), close_page)
	back.add_theme_font_size_override("font_size", 17)
	back.position = Vector2(14, 8)
	holder.add_child(back)
	_overlay = holder
	_overlay_page = page
	holder.position.x = 60.0
	holder.modulate.a = 0.0
	var tween := holder.create_tween().set_parallel()
	tween.tween_property(holder, "position:x", 0.0, 0.15)
	tween.tween_property(holder, "modulate:a", 1.0, 0.15)
	_update_tabs()


func close_page() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
		_overlay_page = null
		if _side != null:
			_update_tabs()


func _update_header() -> void:
	_gold_label.text = UiKit.format_number(PlayerData.gold)
	_gem_label.text = UiKit.format_number(PlayerData.gems)
	_cheat_label.visible = PlayerData.cheated
	for child in _avatar_button.get_children():
		child.queue_free()
	var picture := UiKit.avatar(62)
	picture.position = Vector2(1, 1)
	_avatar_button.add_child(picture)
	_update_tabs()


func _update_tabs() -> void:
	for i in _tabs.size():
		var selected := i == _current
		var tab: Button = _tabs[i]
		tab.add_theme_stylebox_override("normal", _tab_style(selected, i == BATTLE_TAB))
		tab.add_theme_stylebox_override("hover", _tab_style(selected, i == BATTLE_TAB))
		tab.add_theme_stylebox_override("pressed", _tab_style(true, i == BATTLE_TAB))
		tab.get_meta("icon").scale = Vector2.ONE * (1.1 if selected else 1.0)
		_dots[i].visible = _pages[i].has_alert() and not selected
	_side.visible = _current == BATTLE_TAB and _overlay == null
	_side_dots["login"].visible = PlayerData.login_can_claim()
	_side_dots["quests"].visible = PlayerData.quest_alert()
	_side_dots["events"].visible = PlayerData.patrol_alert()
	_side_dots["summon"].visible = PlayerData.summon_free_ready()


func _draw() -> void:
	var grass := SpriteLib.texture("Terrain/Tileset/Tilemap_color1.png")
	for x in range(0, int(SCREEN.x), 64):
		for y in range(0, int(SCREEN.y), 64):
			draw_texture_rect_region(grass, Rect2(x, y, 64, 64), Rect2(64, 64, 64, 64))
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.04, 0.08, 0.07, 0.55))


func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2.ZERO
	bar.size = Vector2(SCREEN.x, TOP_HEIGHT)
	var style := UiKit.dark_style(0)
	style.set_border_width_all(0)
	style.border_width_bottom = 3
	style.content_margin_left = 16
	style.content_margin_right = 16
	bar.add_theme_stylebox_override("panel", style)
	add_child(bar)
	var row := UiKit.hbox(10)
	bar.add_child(row)

	_avatar_button = Button.new()
	_avatar_button.custom_minimum_size = Vector2(64, 64)
	_avatar_button.focus_mode = Control.FOCUS_NONE
	_avatar_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state in ["normal", "hover", "pressed"]:
		_avatar_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_avatar_button.pressed.connect(func(): MetaPopups.open_profile(self))
	row.add_child(_avatar_button)
	row.add_child(UiKit.gap(6))
	row.add_child(UiKit.icon(SpriteLib.texture(UiKit.COIN), 38))
	_gold_label = UiKit.label("", 24)
	_gold_label.custom_minimum_size.x = 96
	row.add_child(_gold_label)
	row.add_child(_plus_button())
	row.add_child(UiKit.gap(12))
	row.add_child(UiKit.drawn(DrawnIcon.Kind.GEM, 36))
	_gem_label = UiKit.label("", 24)
	_gem_label.custom_minimum_size.x = 64
	row.add_child(_gem_label)
	row.add_child(_plus_button())
	row.add_child(UiKit.spacer())
	_cheat_label = UiKit.label("CHEAT", 16, UiKit.WARN)
	row.add_child(_cheat_label)
	# One tap opens the admin panel; the button only exists in debug / "admin" builds.
	if AdminGate.available():
		var admin := UiKit.button("ADMIN", Vector2(96, 52), open_admin, true)
		admin.add_theme_font_size_override("font_size", 16)
		row.add_child(admin)
	var settings := UiKit.button("", Vector2(56, 52), _open_settings)
	settings.icon = SpriteLib.texture(UiKit.UI + "Icons/Icon_10.png")
	settings.expand_icon = true
	row.add_child(settings)


func _plus_button() -> Button:
	return UiKit.plus_button(func(): select_tab(SHOP_TAB))


func _build_nav_bar() -> void:
	var back := ColorRect.new()
	back.color = Color(0.05, 0.09, 0.12, 0.96)
	back.position = Vector2(0, SCREEN.y - NAV_HEIGHT)
	back.size = Vector2(SCREEN.x, NAV_HEIGHT)
	add_child(back)
	var icons := [
		SpriteLib.texture(UiKit.COIN),
		SpriteLib.portrait("Warrior"),
		SpriteLib.texture(UiKit.UI + "Icons/Icon_05.png"),
		SpriteLib.texture("Buildings/Blue Buildings/Castle.png"),
		SpriteLib.portrait("Warrior", "Yellow"),
	]
	var x := 0.0
	for i in TAB_NAMES.size():
		var big: bool = i == BATTLE_TAB
		var width: float = TAB_WIDTHS[i]
		var height := NAV_HEIGHT + (CENTER_RAISE if big else 0.0)
		var tab := Button.new()
		tab.focus_mode = Control.FOCUS_NONE
		tab.position = Vector2(x + 4, SCREEN.y - height + 4)
		tab.size = Vector2(width - 8, height - 8)
		tab.pressed.connect(func(): SoundLib.play("click"))
		tab.pressed.connect(select_tab.bind(i))
		add_child(tab)

		var column := UiKit.vbox(0)
		column.set_anchors_preset(Control.PRESET_FULL_RECT)
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tab.add_child(column)
		var icon := UiKit.icon(icons[i], 76.0 if big else 58.0)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.pivot_offset = icon.custom_minimum_size / 2.0
		column.add_child(icon)
		var name_label := UiKit.label(TAB_NAMES[i], 20 if big else 16)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(name_label)
		tab.set_meta("icon", icon)

		var dot := UiKit.drawn(DrawnIcon.Kind.DOT, 22)
		dot.position = Vector2(width - 34, 6)
		dot.size = Vector2(22, 22)
		tab.add_child(dot)
		_tabs.append(tab)
		_dots.append(dot)
		x += width


# Four icons in the side gutters of the Battle tab, beside the level card.
func _build_side_icons() -> void:
	_side = Control.new()
	_side.position = _content.position
	_side.size = _content.size
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_side)
	var entries := [
		["login", DrawnIcon.Kind.GIFT, "Quà 7 ngày", Vector2(4, 116), func(): MetaPopups.open_login(self)],
		["quests", DrawnIcon.Kind.SCROLL, "Nhiệm vụ", Vector2(4, 206), func(): MetaPopups.open_quests(self)],
		["events", DrawnIcon.Kind.FLAG, "Sự kiện", Vector2(SCREEN.x - 80, 116), func(): MetaPopups.open_events(self)],
		["summon", DrawnIcon.Kind.PORTAL, "Triệu hồi", Vector2(SCREEN.x - 80, 206), func(): open_page(SummonPage)],
	]
	for entry in entries:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.position = entry[3]
		button.size = Vector2(76, 88)
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.pressed.connect(func(): SoundLib.play("click"))
		button.pressed.connect(entry[4])
		var disc := Panel.new()
		var disc_style := StyleBoxFlat.new()
		disc_style.bg_color = Color(0.05, 0.07, 0.1, 0.75)
		disc_style.border_color = UiKit.FRAME_BROWN
		disc_style.set_border_width_all(3)
		disc_style.set_corner_radius_all(32)
		disc.add_theme_stylebox_override("panel", disc_style)
		disc.position = Vector2(6, 0)
		disc.size = Vector2(64, 64)
		disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(disc)
		var icon := UiKit.drawn(entry[1], 50)
		icon.position = Vector2(13, 7)
		icon.size = Vector2(50, 50)
		button.add_child(icon)
		var text := UiKit.label(entry[2], 14)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.position = Vector2(-10, 62)
		text.size = Vector2(96, 24)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(text)
		var dot := UiKit.drawn(DrawnIcon.Kind.DOT, 20)
		dot.position = Vector2(54, 0)
		dot.size = Vector2(20, 20)
		button.add_child(dot)
		_side_dots[entry[0]] = dot
		_side.add_child(button)
		# A gentle bob so the icons read as tappable.
		icon.pivot_offset = Vector2(25, 25)
		var bob := icon.create_tween().set_loops()
		bob.tween_interval(randf_range(0.5, 2.5))
		bob.tween_property(icon, "scale", Vector2(1.12, 1.12), 0.15)
		bob.tween_property(icon, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)


func _tab_style(selected: bool, big: bool) -> StyleBox:
	if selected:
		var style := UiKit.button_style("SmallBlueSquareButton_Regular.png")
		style.set_content_margin_all(0)
		return style
	var flat := UiKit.dark_style(12, Color("2d4a52") if not big else Color("c9a14a"))
	flat.bg_color = Color(0.1, 0.16, 0.2, 0.95)
	return flat


# The panel lives on its own CanvasLayer so it always draws above the lobby.
func open_admin():
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var panel = AdminPanel.new()
	panel.home = self
	layer.add_child(panel)
	return panel


func _open_settings() -> void:
	var box := UiKit.popup(self, 520, "Cài đặt")
	box.add_child(UiKit.ink("Gear Defenders · bản thử nghiệm", 18))
	box.add_child(UiKit.ink("Tiến độ được lưu tự động trên máy.", 16))
	var fast := CheckBox.new()
	fast.text = "Mở rương nhanh (bỏ hoạt ảnh)"
	fast.button_pressed = PlayerData.fast_chest
	fast.focus_mode = Control.FOCUS_NONE
	fast.add_theme_color_override("font_color", UiKit.INK)
	fast.add_theme_color_override("font_pressed_color", UiKit.INK)
	fast.add_theme_color_override("font_hover_color", UiKit.INK)
	fast.add_theme_constant_override("outline_size", 0)
	fast.add_theme_font_size_override("font_size", 18)
	fast.toggled.connect(func(on): PlayerData.set_fast_chest(on))
	box.add_child(fast)
	var sound := CheckBox.new()
	sound.text = "Âm thanh"
	sound.button_pressed = PlayerData.sound_on
	sound.focus_mode = Control.FOCUS_NONE
	for key in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
		sound.add_theme_color_override(key, UiKit.INK)
	sound.add_theme_constant_override("outline_size", 0)
	sound.add_theme_font_size_override("font_size", 18)
	sound.toggled.connect(func(on):
		PlayerData.set_sound(on)
		SoundLib.play("click"))
	box.add_child(sound)
	var skin := CheckBox.new()
	skin.text = "Giao diện Cozy (tắt = giao diện Tiny Swords)"
	skin.button_pressed = UiKit.is_cozy()
	skin.focus_mode = Control.FOCUS_NONE
	for key in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
		skin.add_theme_color_override(key, UiKit.INK)
	skin.add_theme_constant_override("outline_size", 0)
	skin.add_theme_font_size_override("font_size", 18)
	# The skin is read while pages build, so switching reloads the lobby.
	skin.toggled.connect(func(on):
		PlayerData.set_ui_skin("cozy" if on else "swords")
		get_tree().reload_current_scene())
	box.add_child(skin)
	var reset := UiKit.button("XOÁ DỮ LIỆU", Vector2(260, 60), func(): pass, true)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Two taps within a few seconds, so a stray tap can't wipe the save.
	reset.pressed.connect(func():
		if reset.get_meta("armed", false):
			PlayerData.reset_progress()
			UiKit.close_popup(box)
		else:
			reset.set_meta("armed", true)
			reset.text = "CHẠM LẦN NỮA ĐỂ XOÁ"
			get_tree().create_timer(3.0).timeout.connect(func():
				if is_instance_valid(reset):
					reset.set_meta("armed", false)
					reset.text = "XOÁ DỮ LIỆU"))
	box.add_child(reset)
