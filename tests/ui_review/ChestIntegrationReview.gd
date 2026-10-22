extends Node

# Production-only integration proof. Fixtures never touch the player's save.
const OUT := "res://docs/ui_review/2026-10-22/chest-integration"
const Economy = preload("res://game/core/Economy.gd")
const ChestArt = preload("res://game/ui/ChestArt.gd")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const DrawnIcon = preload("res://game/ui/DrawnIcon.gd")
const Ui = preload("res://game/ui/Ui.gd")
const HomeScene = preload("res://game/menu/Home.tscn")
const KINDS := ["wood", "silver", "gold"]
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
const ICON_SIZES := [26, 48, 64, 96, 128, 256]
var _checks := 0
var _failures: Array = []
var _captures: Array = []
var _bounds: Array = []
var _shop_layouts: Array = []
var _icon_routes: Array = []
var _route_textures: Dictionary = {}
var _home: Control
var _opening: Control


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.tutorial_done = true
	PlayerData.gold = 100000
	PlayerData.gems = 5000
	AudioServer.set_bus_mute(0, true)
	get_tree().create_timer(90.0).timeout.connect(func():
		push_error("Chest integration review timed out")
		get_tree().quit(1))
	for kind in KINDS:
		_check(ChestArt.style_for(ChestArt.TINTS[kind]) == ChestArt.STYLES[kind], kind + " tint maps to its production tier")
		for icon_size in ICON_SIZES:
			await _native_icon(kind, icon_size)
	_check_icon_routes()
	_check_gold_construction()
	await _board("accepted-chest-icon-routes.png", Vector2i(1200, 300), _routes_board)
	await _board("tier-and-small-symbols.png", Vector2i(1200, 810), _tiers)
	await _board("separate-lid-states.png", Vector2i(1200, 600), _states)
	get_window().size = SIZES[0]
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.SHOP_TAB, false)
	var opening_kinds: Array = ["gold"] if "--gold-only" in OS.get_cmdline_user_args() else KINDS
	for dimensions in SIZES:
		get_window().size = dimensions
		await _settle()
		await _shop(dimensions)
		await _lobby_counter(dimensions)
		for kind in opening_kinds:
			await _production_opening(kind, dimensions)
	_check(not PlayerData.persist, "Review never persists player changes")
	var report := {
		"mode": "gold-followup" if opening_kinds.size() == 1 else "all-tiers",
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"sizes": [[360, 640], [450, 800]], "icon_bounds": _bounds,
		"shop_layouts": _shop_layouts, "icon_routes": _icon_routes, "captures": _captures,
		"checks": _checks, "failures": _failures,
		"contract": "Actual DrawnIcon, Shop and ChestOpening; all three tier palettes; independent lid flight; fixed body and latch."
	}
	var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("CHEST_INTEGRATION_COMPLETE checks=", _checks, " captures=", _captures.size(), " failures=", _failures)
	get_tree().quit(1 if not _failures.is_empty() else 0)


func _native_icon(kind: String, icon_size: int) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(icon_size * 2, icon_size * 2)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var icon := DrawnIcon.new()
	icon.kind = DrawnIcon.Kind.CHEST
	icon.tint = ChestArt.TINTS[kind]
	icon.size = Vector2(icon_size, icon_size)
	icon.position = Vector2(icon_size, icon_size) / 2.0
	viewport.add_child(icon)
	await RenderingServer.frame_post_draw
	var shot := viewport.get_texture().get_image()
	var painted := shot.get_used_rect()
	var control := Rect2i(Vector2i(icon.position), Vector2i(icon.size))
	var title := "%s %d px" % [kind, icon_size]
	_check(painted.size.x > icon_size * 0.8, title + " fills expected width")
	_check(control.encloses(painted), title + " contour fits inside icon control")
	_bounds.append({"kind": kind, "size": icon_size,
		"painted": [painted.position.x, painted.position.y, painted.size.x, painted.size.y],
		"control": [control.position.x, control.position.y, control.size.x, control.size.y]})
	var file := "icon-%s-%d.png" % [kind, icon_size]
	_check(shot.get_region(control).save_png(OUT + "/" + file) == OK, file + " saved")
	_captures.append({"file": file, "size": [icon_size, icon_size]})
	viewport.queue_free()
	await get_tree().process_frame


func _shop(dimensions: Vector2i) -> void:
	var page: Control = _home._pages[_home.SHOP_TAB]
	var icons := _chest_icons(page)
	_check(icons.size() == 3, "Shop has exactly three chest controls")
	var records: Array = []
	var gold_width := 0.0
	var basic_width := 0.0
	for icon: Control in icons:
		var kind := _kind(icon.tint)
		var expected := 248.0 if kind == "gold" else 200.0
		_check(icon.size == Vector2(expected, expected), kind + " Shop uses its current production control size")
		var stage := icon.get_parent() as Control
		_check(stage.size == Vector2(expected, expected * 0.74), kind + " stage crops only empty square margins")
		var sample: Dictionary = _bounds.filter(func(entry): return entry.kind == kind and entry.size == 256)[0]
		var used: Array = sample.painted
		var source: Array = sample.control
		var local_paint := Rect2(Vector2(used[0] - source[0], used[1] - source[1]) / 256.0 * expected,
			Vector2(used[2], used[3]) / 256.0 * expected)
		var stage_paint := Rect2(icon.position + local_paint.position, local_paint.size)
		_check(Rect2(Vector2.ZERO, stage.size).grow(1.0).encloses(stage_paint), kind + " painted contour fits Shop stage")
		if kind == "gold":
			gold_width = stage_paint.size.x
		else:
			basic_width = maxf(basic_width, stage_paint.size.x)
		records.append({"kind": kind, "control": [icon.size.x, icon.size.y],
			"stage": [stage.size.x, stage.size.y], "painted_in_stage": [stage_paint.position.x, stage_paint.position.y, stage_paint.size.x, stage_paint.size.y]})
	_shop_layouts.append({"size": [dimensions.x, dimensions.y], "tiers": records})
	_check(gold_width > basic_width * 1.2, "Gold painted width is more than 20% larger than basic Shop chests")
	await _capture("shop-" + _suffix(dimensions) + ".png", dimensions)


func _check_icon_routes() -> void:
	for icon_size in [32, 48, 64, 96, 128]:
		var texture := Ui.icon_tex("chest", icon_size)
		_route_textures[icon_size] = texture
		var expected := "res://game/ui/art/icon_chest_%d.svg" % icon_size if icon_size <= 96 else "res://game/ui/art/icon_chest.svg"
		_check(texture != null and texture.resource_path == expected,
			"Ui.icon_tex chest %d resolves to accepted SVG" % icon_size)
		_icon_routes.append({"size": icon_size, "path": texture.resource_path if texture != null else ""})
	_check(Ui.icon_tex("eq_armor", 32).resource_path == "res://game/ui/art/icon_eq_armor_32.png", "Existing armor PNG keeps override priority")
	_check(Ui.tex("weapon_kiem").resource_path == "res://game/ui/art/weapon_kiem.png", "Existing sword PNG keeps override priority")


func _check_gold_construction() -> void:
	var data: Dictionary = ChestArt.Paths.DATA
	_check(ChestArt.STYLES.gold.get("kind", "") == "gold", "Gold style selects its own geometry family")
	_check(not ChestArt.STYLES.gold.get("gem", true), "Final gold construction omits the rejected lid gem")
	for layer in ["body", "lid", "latch"]:
		_check(data["gold_full_closed"][layer].size() > data["basic_full_closed"][layer].size(),
			"Gold " + layer + " has its own additional reinforcement geometry")


func _lobby_counter(dimensions: Vector2i) -> void:
	_home.select_tab(_home.BATTLE_TAB, false)
	await _settle()
	var rewards: Node = _home._pages[_home.BATTLE_TAB].find_child("LobbyRewards", true, false)
	_check(rewards != null, "Battle lobby has native reward counters")
	var accepted_chests := 0
	if rewards != null:
		for node in rewards.find_children("*", "TextureRect", true, false):
			if node.texture != null and node.texture.resource_path == "res://game/ui/art/icon_chest_32.svg":
				accepted_chests += 1
	_check(accepted_chests == 1, "Battle lobby counter uses one accepted chest icon")
	await _capture("lobby-chest-counter-" + _suffix(dimensions) + ".png", dimensions)
	_home.select_tab(_home.SHOP_TAB, false)
	await _settle()


func _production_opening(kind: String, dimensions: Vector2i) -> void:
	var suffix := kind + "-" + _suffix(dimensions)
	_opening = ChestOpening.new()
	_opening.setup(Economy.CHESTS[kind]["name"], ChestArt.TINTS[kind], {"gold": 83, "cards": {"kiem": 2}}, [], false)
	_opening.attach(_home)
	_check(_opening._chest_size == (300.0 if kind == "gold" else 250.0), suffix + " uses its tier's native opening width")
	await get_tree().create_timer(1.35).timeout
	_check(_opening._stage == "wait", suffix + " reaches wait after real drop")
	_check(_opening.lid_offset == Vector2.ZERO and _opening.lid_alpha == 1.0, suffix + " starts with closed lid")
	await _capture("actual-wait-" + suffix + ".png", dimensions)
	_opening._on_tap()
	await get_tree().create_timer(0.62).timeout
	_check(_opening._stage == "open" and _opening.lid_offset.y < 0 and _opening.mouth > 0,
		suffix + " moves separate lid and lights mouth")
	_check(_opening.lid_rotation > 0.0 and _opening.lid_alpha > 0.0, suffix + " captures a rotating visible lid")
	await _capture("actual-open-" + suffix + ".png", dimensions)
	while _opening._stage == "open":
		await get_tree().process_frame
	_check(_opening._stage == "card", suffix + " reaches real card reveal")
	await get_tree().create_timer(0.65).timeout
	await _capture("actual-card-" + suffix + ".png", dimensions)
	_check(_opening.lid_alpha == 0.0 and _opening.mouth > 0 and _opening.chest_alpha > 0,
		suffix + " card reveal leaves body and mouth after lid fades")
	_opening.get_parent().queue_free()
	await _settle()


func _board(file: String, dimensions: Vector2i, painter: Callable) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var canvas := Node2D.new()
	viewport.add_child(canvas)
	canvas.draw.connect(func(): painter.call(canvas))
	canvas.queue_redraw()
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	_check(picture.get_size() == dimensions, file + " native dimensions")
	_check(picture.save_png(OUT + "/" + file) == OK, file + " saved")
	_captures.append({"file": file, "size": [dimensions.x, dimensions.y]})
	viewport.queue_free()
	await get_tree().process_frame


func _text(ci: CanvasItem, value: String, at: Vector2, font_size := 20, color := Color("583f21")) -> void:
	ci.draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _tiers(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1200, 810), Color("e5e8da"))
	_text(ci, "PRODUCTION CHEST / three tier paints / native Godot vectors", Vector2(24, 38), 24)
	for index in 3:
		var x := 200.0 + index * 400.0
		var kind: String = KINDS[index]
		_text(ci, kind.to_upper(), Vector2(x - 40, 83), 22)
		ChestArt.draw(ci, Vector2(x, 250), 250.0, ChestArt.STYLES[kind])
		for entry in [[128.0, 440.0], [96.0, 555.0], [64.0, 645.0], [48.0, 710.0], [26.0, 760.0]]:
			var width: float = entry[0]
			var y: float = entry[1]
			_text(ci, "%d px" % width, Vector2(x - 140, y + 7), 17)
			DrawnIcon.draw_chest(ci, Vector2(x + 20, y), width * 0.9, ChestArt.TINTS[kind])


func _states(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1200, 600), Color("31495b"))
	var paper := Color("f4e7c4")
	_text(ci, "Separate lid motion / stationary base and cat latch", Vector2(24, 38), 24, paper)
	for index in 3:
		var at := Vector2(200 + 400 * index, 360)
		var offset := Vector2(35, -130) if index == 1 else Vector2.ZERO
		var rotation := 0.38 if index == 1 else 0.0
		var lid_alpha := 0.0 if index == 2 else 1.0
		var mouth := Color("ffe5a0") if index > 0 else Color.TRANSPARENT
		ChestArt.draw(ci, at, 250, ChestArt.STYLES.gold, 1.0, offset, rotation, lid_alpha, mouth)
		_text(ci, ["WAIT / closed", "OPEN / separate flying lid", "CARD / body remains"][index], Vector2(at.x - 120, 540), 21, paper)


func _routes_board(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1200, 300), Color("e5e8da"))
	_text(ci, "LIVE Ui.icon_tex ROUTE / accepted chest SVG / native request size", Vector2(24, 38), 24)
	var requested_sizes := [32, 48, 64, 96, 128]
	for index in requested_sizes.size():
		var width: int = requested_sizes[index]
		var at := Vector2(120.0 + index * 240.0, 162)
		ci.draw_texture_rect(_route_textures[width], Rect2(at - Vector2.ONE * width / 2.0, Vector2.ONE * width), false)
		_text(ci, "%d px" % width, at + Vector2(-28, 105), 20)


func _kind(tint: Color) -> String:
	for kind in KINDS:
		if tint == ChestArt.TINTS[kind]:
			return kind
	return "unknown"


func _chest_icons(node: Node) -> Array:
	var result: Array = []
	if node.get_script() == DrawnIcon and node.kind == DrawnIcon.Kind.CHEST:
		result.append(node)
	for child in node.get_children():
		result.append_array(_chest_icons(child))
	return result


func _capture(file: String, dimensions: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	_check(shot.get_size() == dimensions, file + " native dimensions")
	_check(shot.save_png(OUT + "/" + file) == OK, file + " saved")
	_captures.append({"file": file, "size": [dimensions.x, dimensions.y]})


func _settle() -> void:
	for frame in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _suffix(dimensions: Vector2i) -> String:
	return "%dx%d" % [dimensions.x, dimensions.y]


func _check(ok: bool, description: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(description)
		push_error(description)
