extends Control

# The lobby in the game skin (game/ui/Ui.gd): HUD on top (hero avatar opens the profile,
# coin and gem pills that open the shop, settings), the selected page in the middle and the
# five-tab nav at the bottom (Cửa hàng · Anh hùng · Chiến · Lính · Triệu hồi; Chiến, in the
# middle, is the default). On the Chiến tab, side rails open the 7-day gift, the daily quests,
# the events hub. The courtyard castle's speech bubble opens its details.

const UiKit = preload("res://game/ui/UiKit.gd")
const Ui = preload("res://game/ui/Ui.gd")
const CartonNav = preload("res://game/ui/CartonNav.gd")
const LobbyShortcut = preload("res://game/ui/LobbyShortcut.gd")
const CastleBubble = preload("res://game/ui/CastleBubble.gd")
const AdminGate = preload("res://game/admin/AdminGate.gd")
const AdminPanel = preload("res://game/admin/AdminPanel.gd")
const MetaPopups = preload("res://game/menu/popups/MetaPopups.gd")
const SummonPage = preload("res://game/menu/pages/SummonPage.gd")
const CastlePage = preload("res://game/menu/pages/CastlePage.gd")
const CardboardLobby = preload("res://game/menu/lobby/CardboardLobby.gd")
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
const NAV_HEIGHT := 204.0
const SHOP_SKY := Color("4e78a3")
const SHOP_AWNING_SIZE := Vector2(720, 104)
const SCREEN := Vector2(720, 1280)

# Remembered across scene changes so returning from a battle lands on the same tab.
static var last_tab := BATTLE_TAB

var _content: Control
var _pages: Array = []
var _current := -1
var _pattern_backdrop: ColorRect
var _shop_awning: Control
var _menu_surfaces: Array = []
var _lobby_world: Control
var _header: Control
var _gold_label: Label
var _gem_label: Label
var _cheat_label: Label
var _nav_holder: Control
var _nav_bar: CartonNav
## Side rails on the Chiến tab; keep their animation states through badge refreshes.
var _side: Control
var _side_shortcuts := {}
var _shortcut_pending := false
var _shortcut_epoch := 0
var _castle_controls: Control
var _castle_bubble: Button
var _castle_upgrade_hint: Control
## An event page opened over the tabs, or null.
var _overlay: Control
var _overlay_page: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Older pages still use the UiKit theme; the new chrome sets Ui.THEME on its own roots.
	theme = UiKit.make_theme()
	# The skin is smooth SVG art; pixel portraits set nearest on themselves.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_pattern_backdrop = Ui.pattern_bg(SHOP_SKY)
	_pattern_backdrop.name = "MenuPatternBackground"
	_pattern_backdrop.visible = false
	add_child(_pattern_backdrop)
	_pattern_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var awning := Ui.image("shop_awning", SHOP_AWNING_SIZE)
	_shop_awning = awning
	awning.name = "ShopAwning"
	awning.stretch_mode = TextureRect.STRETCH_SCALE
	awning.size = SHOP_AWNING_SIZE
	_pattern_backdrop.add_child(awning)
	_lobby_world = CardboardLobby.new()
	add_child(_lobby_world)
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
	_build_castle_controls()
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
	# A delayed shortcut must not open over a tab selected during its feedback.
	_shortcut_epoch += 1
	_shortcut_pending = false
	close_page()
	if index == _current:
		return
	var from := _current
	_current = index
	last_tab = index
	# The shop canopy sits above the shared HUD row.
	_header.position.y = SHOP_AWNING_SIZE.y if index == SHOP_TAB else 0.0
	_content.position.y = TOP_HEIGHT + _header.position.y
	_content.size.y = SCREEN.y - _content.position.y - NAV_HEIGHT
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
	_update_tabs(animate)


func start_battle(level_index: int) -> void:
	PlayerData.select_level(level_index)
	get_tree().change_scene_to_file("res://game/battle/Battle.tscn")


func _on_data_changed() -> void:
	_lobby_world.sync_castle_level()
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
	# The full-screen pattern remains behind the shared chrome, without a seam
	# or a second independently moving tile field inside this content viewport.
	var holder := Control.new()
	holder.name = "MenuPageOverlay"
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
	register_menu_surface(holder, script.resource_path.get_file().get_basename().trim_suffix("Page").to_snake_case())
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


## Independent surface lifetimes avoid an old popup exit restoring stale color
## when Events opens another page or several sheets are stacked.
func register_menu_surface(surface: Node, context := "") -> void:
	for entry in _menu_surfaces:
		if entry.node == surface:
			return
	var chosen := active_menu_context() if context.is_empty() else context
	if chosen == "battle":
		chosen = "hero"
	_menu_surfaces.append({"node": surface, "context": chosen})
	surface.tree_exited.connect(_menu_surface_closed.bind(surface.get_instance_id()), CONNECT_ONE_SHOT)
	_update_tabs()


func _menu_surface_closed(surface_id: int) -> void:
	for i in range(_menu_surfaces.size() - 1, -1, -1):
		var node = _menu_surfaces[i].node
		if not is_instance_valid(node) or node.get_instance_id() == surface_id:
			_menu_surfaces.remove_at(i)
	if is_inside_tree() and not is_queued_for_deletion():
		_update_tabs()


func active_menu_context() -> String:
	for i in range(_menu_surfaces.size() - 1, -1, -1):
		var node = _menu_surfaces[i].node
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			return _menu_surfaces[i].context
	match _current:
		SHOP_TAB: return "shop"
		HERO_TAB: return "hero"
		TROOPS_TAB: return "troops"
		SUMMON_TAB: return "summon"
	return "battle"


func _update_backdrop() -> void:
	var context := active_menu_context()
	var full_screen := false
	for entry in _menu_surfaces:
		var node = entry.node
		if is_instance_valid(node) and not node.is_queued_for_deletion() and node is CanvasLayer:
			full_screen = true
			break
	_pattern_backdrop.visible = context != "battle"
	if _pattern_backdrop.visible:
		var paint := Ui.menu_pattern_color(context)
		_pattern_backdrop.color = paint
		_pattern_backdrop.material.set_shader_parameter("sky", paint)
	_shop_awning.visible = _current == SHOP_TAB and not full_screen
	_content.visible = _overlay == null and not full_screen
	_header.visible = not full_screen
	_nav_holder.visible = not full_screen
	if _overlay != null:
		_overlay.visible = not full_screen
	_side.visible = context == "battle"
	_castle_controls.visible = context == "battle"
	_lobby_world.set_active(context == "battle")


func _update_header() -> void:
	_gold_label.text = UiKit.format_number(PlayerData.gold)
	_gem_label.text = UiKit.format_number(PlayerData.gems)
	for amount in [_gold_label, _gem_label]:
		var fit_value: Callable = amount.get_meta("fit_value")
		fit_value.call()
	_cheat_label.visible = PlayerData.cheated
	_update_tabs()


func _update_tabs(animate := true) -> void:
	if _nav_holder == null:
		return
	var badges := []
	for i in _pages.size():
		if i != _current and _pages[i].has_alert():
			badges.append(i)
	if _nav_bar == null:
		_build_nav(badges)
	else:
		_nav_bar.set_selected(_current, animate)
		_nav_bar.set_badges(badges)
	_update_backdrop()
	_side_shortcuts["login"].set_alert(PlayerData.login_can_claim())
	_side_shortcuts["quests"].set_alert(PlayerData.quest_alert())
	_side_shortcuts["events"].set_alert(PlayerData.patrol_alert())
	_update_castle_controls()


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
	_header = bar
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


## Keep the five carton states alive through tab changes and badge refreshes.
func _build_nav(badges: Array) -> void:
	_nav_bar = Ui.bottom_nav(TABS, _current, badges)
	_nav_bar.name = "CartonNavigation"
	_nav_holder.add_child(_nav_bar)
	_nav_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_nav_bar.tab_pressed.connect(select_tab)


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
	])
	Ui.pin(_side, right, Vector2(-16 - Ui.RAIL_ITEM_SIZE.x, 140), Control.PRESET_TOP_RIGHT)


func _rail_entry(key: String, icon_name: String, text: String, on_press: Callable) -> Control:
	var kind: int = ["login", "quests", "events", "castle"].find(key)
	var shortcut := LobbyShortcut.new()
	shortcut.configure(kind, text, Ui.icon_tex(icon_name, 96), false)
	shortcut.name = key.to_pascal_case() + "Shortcut"
	_side_shortcuts[key] = shortcut
	shortcut.activated.connect(func(_kind: int): _activate_shortcut(shortcut, on_press))
	return shortcut


func _activate_shortcut(shortcut: Button, on_press: Callable) -> void:
	if _shortcut_pending or _current != BATTLE_TAB or not _side.is_visible_in_tree() or active_menu_context() != "battle":
		return
	_shortcut_pending = true
	_shortcut_epoch += 1
	var request := _shortcut_epoch
	SoundLib.play("click")
	# Let the release response read before the destination covers the shortcut.
	await get_tree().create_timer(0.20).timeout
	if not is_inside_tree() or request != _shortcut_epoch:
		return
	_shortcut_pending = false
	if _current != BATTLE_TAB or active_menu_context() != "battle" or not is_instance_valid(shortcut) or not shortcut.is_visible_in_tree():
		return
	on_press.call()


func _build_castle_controls() -> void:
	_castle_controls = _skinned(Control.new())
	_castle_controls.name = "LobbyCastleControls"
	_castle_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_castle_controls)
	_castle_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_castle_bubble = CastleBubble.new()
	_castle_bubble.name = "LobbyCastleBubble"
	# Keep the bubble above the near ear, clear of the flag and stage title.
	Ui.pin(_castle_controls, _castle_bubble, Vector2(270, 244))
	_castle_bubble.pressed.connect(_open_castle_details)
	_castle_upgrade_hint = _castle_bubble.find_child("CastleUpgradeHint", false, false)
	_update_castle_controls()


func _update_castle_controls() -> void:
	var cost := PlayerData.castle_upgrade_cost()
	_castle_bubble.configure(PlayerData.castle_level, cost >= 0 and PlayerData.gold >= cost)


func _open_castle_details() -> void:
	if _current != BATTLE_TAB or active_menu_context() != "battle":
		return
	SoundLib.play("click")
	open_page(CastlePage)


## A short tap on the illustration opens stats and the workshop; swipes stay in BattlePage.
func open_castle_details_at(global_at: Vector2) -> bool:
	if _current != BATTLE_TAB or active_menu_context() != "battle" or not Rect2(160, 345, 435, 300).has_point(global_at):
		return false
	_open_castle_details()
	return true


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
