extends Node

# Read-only production UI audit. Transparent text keeps container geometry intact
# for a second capture of the exact backgrounds underneath each label.
const OUT := "res://docs/ui_review/2026-10-19/contrast"
const HomeScene = preload("res://game/menu/Home.tscn")
const CastlePage = preload("res://game/menu/pages/CastlePage.gd")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const FONT_KEYS := ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color", "font_outline_color"]
var _home: Control
var _captures: Array = []
var _failures := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	_home = HomeScene.instantiate()
	add_child(_home)
	for window_size in [Vector2i(720, 1280), Vector2i(360, 640)]:
		get_window().size = window_size
		await get_tree().process_frame
		_home.select_tab(_home.BATTLE_TAB, false)
		await _capture("lobby", window_size)
		_home.open_page(CastlePage)
		await get_tree().create_timer(0.3).timeout
		await _capture("castle", window_size, _home._overlay_page)
		var castle_scroll: ScrollContainer = _home._overlay_page.get_child(0)
		castle_scroll.scroll_vertical = 100000
		await _capture("castle_workshop", window_size, _home._overlay_page)
		_home.close_page()
		_home.select_tab(_home.SHOP_TAB, false)
		var opening := ChestOpening.new()
		opening.setup("Rương Gỗ", Color("a0673a"), {"cards": {"kiem": 2, "giao": 1}, "gold": 83}, [], true, func(): pass)
		opening.attach(_home)
		await get_tree().create_timer(0.45).timeout
		await _capture("chest_two", window_size, opening)
		opening.get_parent().queue_free()
		await get_tree().process_frame
	var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"persist": PlayerData.persist, "profile": OS.get_user_data_dir(), "captures": _captures, "failures": _failures}, "\t"))
	print("CONTRAST_COMPLETE ", _captures.size(), " captures; failures=", _failures)
	get_tree().quit(1 if _failures else 0)


func _capture(key: String, requested: Vector2i, scope: Node = null) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var mode := _home.process_mode
	_home.process_mode = Node.PROCESS_MODE_DISABLED
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var file_key := "%s_%dx%d" % [key, requested.x, requested.y]
	if shot.get_size() != requested:
		_failures += 1
	shot.save_png(OUT + "/" + file_key + ".png")
	var records := []
	var changed := []
	_collect(scope if scope != null else _home, records, changed, Vector2(requested) / Vector2(720, 1280))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + "/" + file_key + "_background.png")
	for entry in changed:
		var control: Control = entry.control
		if control is Label:
			control.self_modulate = entry.modulate
		else:
			for color_key in FONT_KEYS:
				if entry.colors[color_key].overridden:
					control.add_theme_color_override(color_key, entry.colors[color_key].color)
				else:
					control.remove_theme_color_override(color_key)
	_home.process_mode = mode
	_captures.append({"file": file_key + ".png", "background": file_key + "_background.png", "actual": [shot.get_width(), shot.get_height()], "labels": records})
	print("CONTRAST_CAPTURE ", file_key, " text controls=", records.size())


func _collect(node: Node, records: Array, changed: Array, render_scale: Vector2) -> void:
	if node is Control and node.is_visible_in_tree() and (node is Label or node is Button):
		var control: Control = node
		var rect := _visible_rect(control)
		if rect.has_area() and control.text != "":
			var color_key := "font_disabled_color" if control is Button and control.disabled else "font_color"
			var effective_scale := control.get_global_transform().get_scale() * render_scale
			var foreground := control.get_theme_color(color_key)
			var outline := control.get_theme_color("font_outline_color")
			var scale_y := absf(effective_scale.y)
			records.append({"path": str(_home.get_path_to(control)), "type": control.get_class(), "text": control.text,
				"render_rect": [rect.position.x * render_scale.x, rect.position.y * render_scale.y, rect.size.x * render_scale.x, rect.size.y * render_scale.y],
				"font_size": control.get_theme_font_size("font_size"), "render_font_size": control.get_theme_font_size("font_size") * scale_y,
				"fill": foreground.to_html(), "outline": outline.to_html(), "render_outline_size": control.get_theme_constant("outline_size") * scale_y,
				"disabled": control is Button and control.disabled})
			if control is Label:
				changed.append({"control": control, "modulate": control.self_modulate})
				control.self_modulate = Color(1, 1, 1, 0)
			else:
				var original := {}
				for key in FONT_KEYS:
					original[key] = {"overridden": control.has_theme_color_override(key), "color": control.get_theme_color(key)}
					control.add_theme_color_override(key, Color.TRANSPARENT)
				changed.append({"control": control, "colors": original})
	for child in node.get_children():
		_collect(child, records, changed, render_scale)


func _visible_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect().intersection(Rect2(0, 0, 720, 1280))
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents:
			rect = rect.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return rect
