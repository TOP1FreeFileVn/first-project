extends Control

# The lobby in the game skin (game/ui/Ui.gd): HUD on top (hero avatar opens the profile,
# coin and gem pills that open the shop, settings), the selected page in the middle and the
# five-tab nav at the bottom (Cửa hàng · Anh hùng · Chiến · Lính · Triệu hồi; Chiến, in the
# middle, is the default). On the Chiến tab, side rails open the 7-day gift, the daily quests,
# the events hub and the castle. Event pages open on top of the tabs with a back button.

const UiKit = preload("res://game/ui/UiKit.gd")
const Ui = preload("res://game/ui/Ui.gd")
const AdminGate = preload("res://game/admin/AdminGate.gd")
const AdminPanel = preload("res://game/admin/AdminPanel.gd")
const MetaPopups = preload("res://game/menu/popups/MetaPopups.gd")
const SummonPage = preload("res://game/menu/pages/SummonPage.gd")
const CastlePage = preload("res://game/menu/pages/CastlePage.gd")
const PAGES := [
	preload("res://game/menu/pages/ShopPage.gd"),
	preload("res://game/menu/pages/HeroCatPage.gd"),
	preload("res://game/menu/pages/BattlePage.gd"),
	preload("res://game/menu/pages/TroopsPage.gd"),
	SummonPage,
]
const TABS := [["tab_shop", "Cửa hàng"], ["tab_cat", "Anh hùng"], ["tab_battle", "Chiến"], ["tab_army", "Lính"], ["tab_summon", "Triệu hồi"]]
const SHOP_TAB := 0
const HERO_TAB := 1
const BATTLE_TAB := 2
const TROOPS_TAB := 3
const SUMMON_TAB := 4
const TOP_HEIGHT := 112.0
const NAV_HEIGHT := 160.0
const SCREEN := Vector2(720, 1280)
const SKY := Color("6fa3e0")
## The nav bar runs this far past the bottom edge (see Ui.bottom_nav).
const NAV_BLEED := 18.0

# Remembered across scene changes so returning from a battle lands on the same tab.
static var last_tab := BATTLE_TAB

var _content: Control
var _pages: Array = []
var _current := -1
var _gold_label: Label
var _gem_label: Label
var _cheat_label: Label
var _nav_holder: Control
var _nav_key := ""
## Side rails on the Chiến tab, and their alert dots by name.
var _side: Control
var _side_dots := {}
## An event page opened over the tabs, or null.
var _overlay: Control
var _overlay_page: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Older pages still use the UiKit theme; the new chrome sets Ui.THEME on its own roots.
	theme = UiKit.make_theme()
	# The skin is smooth SVG art; pixel portraits set nearest on themselves.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var backdrop := Ui.pattern_bg(SKY)
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	_build_side_rails()
	_build_top_bar()
	_nav_holder = _skinned(Control.new())
	_nav_holder.position = Vector2(0, SCREEN.y - NAV_HEIGHT)
	_nav_holder.size = Vector2(SCREEN.x, NAV_HEIGHT)
	_nav_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_nav_holder)
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
	var holder := Ui.pattern_bg(SKY)
	holder.position = _content.position
	holder.size = _content.size
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(holder)
	move_child(holder, _side.get_index() + 1)
	var page = script.new()
	page.home = self
	holder.add_child(page)
	page.offset_top = 72
	page.build()
	var back := _skinned(Ui.button("Quay lại", "Red", Vector2(190, 60), 20, "back"))
	back.position = Vector2(14, 6)
	back.pressed.connect(close_page)
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
	for amount in [_gold_label, _gem_label]:
		var fit_value: Callable = amount.get_meta("fit_value")
		fit_value.call()
	_cheat_label.visible = PlayerData.cheated
	_update_tabs()


func _update_tabs() -> void:
	if _nav_holder == null:
		return
	var badges := []
	for i in _pages.size():
		if i != _current and _pages[i].has_alert():
			badges.append(i)
	var key := "%d %s" % [_current, str(badges)]
	if key != _nav_key:
		_nav_key = key
		_build_nav(badges)
	_side.visible = _current == BATTLE_TAB and _overlay == null
	_side_dots["login"].visible = PlayerData.login_can_claim()
	_side_dots["quests"].visible = PlayerData.quest_alert()
	_side_dots["events"].visible = PlayerData.patrol_alert()
	_side_dots["castle"].visible = false


## Gives a chrome root the SVG skin and smooth filtering.
func _skinned(control: Control) -> Control:
	control.theme = Ui.THEME
	control.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return control


## Makes a drawn piece tappable: a flat button laid over it.
func _tap(content: Control, on_press: Callable) -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.add_child(content)
	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.pressed.connect(func(): SoundLib.play("click"))
	hit.pressed.connect(on_press)
	wrap.add_child(hit)
	return wrap


# One centered HUD row; the optional cheat marker never changes its layout.
func _build_top_bar() -> void:
	var bar := _skinned(Ui.margin(14, 12, 14, 16))
	bar.name = "Header"
	bar.position = Vector2.ZERO
	bar.size = Vector2(SCREEN.x, TOP_HEIGHT)
	add_child(bar)
	var row := Ui.hbox(12, BoxContainer.ALIGNMENT_BEGIN)
	row.name = "HeaderRow"
	bar.add_child(row)

	var frame := Ui.panel("AvatarFrame", Ui.center(Ui.image("cat_head_hero", Vector2(62, 50))))
	frame.name = "AvatarFrame"
	frame.custom_minimum_size = Vector2(80, 84)
	var avatar := _tap(frame, func(): MetaPopups.open_profile(self))
	avatar.name = "ProfileButton"
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(avatar)

	var gold := Ui._currency("coin", "", true)
	gold.name = "CurrencyGold"
	_gold_label = gold.get_node("CurrencyValue")
	var gems := Ui._currency("gem", "", true)
	gems.name = "CurrencyGems"
	_gem_label = gems.get_node("CurrencyValue")
	for pill in [gold, gems]:
		var hit := _tap(pill, func(): select_tab(SHOP_TAB))
		hit.name = "GoldButton" if pill == gold else "GemsButton"
		hit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(hit)

	var has_admin := AdminGate.available()
	var tool_width := 174.0 if has_admin else 68.0
	var tools := Control.new()
	tools.name = "HeaderTools"
	tools.custom_minimum_size = Vector2(tool_width, 84)
	var tool_row := Ui.hbox(6)
	tool_row.name = "HeaderActions"
	# One tap opens the admin panel; the button only exists in debug / "admin" builds.
	if has_admin:
		var admin := Ui.button("ADMIN", "Red", Vector2(100, 60), 16)
		admin.name = "AdminButton"
		admin.pressed.connect(open_admin)
		tool_row.add_child(admin)
	var settings := Ui.button("", "Tab", Vector2(68, 60), 0, "gear")
	settings.name = "SettingsButton"
	settings.pressed.connect(_open_settings)
	tool_row.add_child(settings)
	tools.add_child(tool_row)
	tool_row.anchor_top = 0.5
	tool_row.anchor_bottom = 0.5
	tool_row.offset_top = -30
	tool_row.offset_bottom = 30
	tool_row.offset_right = tool_width
	_cheat_label = Ui.label("CHEAT", "LabelTiny", 14)
	_cheat_label.name = "CheatLabel"
	_cheat_label.add_theme_color_override("font_color", UiKit.WARN)
	_cheat_label.add_theme_constant_override("outline_size", 2)
	Ui.pin(tools, _cheat_label, Vector2(0, 74)).size = Vector2(100 if has_admin else 68, 20)
	row.add_child(tools)


## Rebuilt only when the selected tab or the alert dots change.
func _build_nav(badges: Array) -> void:
	for child in _nav_holder.get_children():
		child.queue_free()
	var bar := Ui.bottom_nav(TABS, _current, badges, NAV_BLEED)
	_nav_holder.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.offset_left = 6
	bar.offset_right = -6
	bar.offset_bottom = NAV_BLEED
	for i in bar.get_child_count():
		var cell: Control = bar.get_child(i)
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.pressed.connect(func(): SoundLib.play("click"))
		hit.pressed.connect(select_tab.bind(i))
		cell.add_child(hit)


# Equal shortcut columns outside the stage, with a clear gap between each target.
func _build_side_rails() -> void:
	_side = _skinned(Control.new())
	_side.position = _content.position
	_side.size = _content.size
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_side)
	var left := Ui.rail([
		_rail_entry("login", "rail_checkin", "Quà 7 ngày", func(): MetaPopups.open_login(self)),
		_rail_entry("quests", "rail_quest", "Nhiệm vụ", func(): MetaPopups.open_quests(self)),
	])
	Ui.pin(_side, left, Vector2(16, 140))
	var right := Ui.rail([
		_rail_entry("events", "rail_event", "Sự kiện", func(): MetaPopups.open_events(self)),
		_rail_entry("castle", "rail_castle", "Thành", func(): open_page(CastlePage)),
	])
	Ui.pin(_side, right, Vector2(-16 - Ui.RAIL_ITEM_SIZE.x, 140), Control.PRESET_TOP_RIGHT)


func _rail_entry(key: String, icon_name: String, text: String, on_press: Callable) -> Control:
	var item := Ui.rail_item(icon_name, text)
	var ic: Control = item.find_child("ShortcutIcon", true, false)
	_side_dots[key] = Ui.dot(ic, Ui.SHORTCUT_BADGE_AT)
	var shortcut := _tap(item, on_press)
	shortcut.name = key.to_pascal_case() + "Shortcut"
	shortcut.custom_minimum_size = Ui.RAIL_ITEM_SIZE
	return shortcut


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
