extends Node

# Production Home, with the normal 720x1280 canvas scaled by Godot to each window.
# Run through nav-icons-plan.json so APPDATA/LOCALAPPDATA use an isolated profile.
# Small captures are rendered at 360x640; they are not resized copies of the large ones.
const OUT := "res://docs/ui_review/2026-10-19/nav-icons"
const Ui = preload("res://game/ui/Ui.gd")
const HomeScene = preload("res://game/menu/Home.tscn")
const WINDOW_SIZES := [Vector2i(720, 1280), Vector2i(360, 640)]
const ICON_SIZES := [32, 48, 64, 96, 128]

var _home: Control
var _failures := 0
var _captures: Array = []


func _ready() -> void:
	print("NAV_ICONS_USER_DIR ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 2400
	PlayerData.gems = 260
	PlayerData.castle_level = 3
	PlayerData.unlocked_levels = 3
	PlayerData.current_level = 2
	PlayerData.level_stars = {0: 3, 1: 2}
	PlayerData.troops["kiem"]["level"] = 6
	PlayerData.troops["kiem"]["cards"] = 12
	for id in ["giao", "katana", "riu"]:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "cung", "giao", "katana"]
	get_window().size = WINDOW_SIZES[0]
	_home = HomeScene.instantiate()
	add_child(_home)
	for size in WINDOW_SIZES:
		get_window().size = size
		await get_tree().process_frame
		await get_tree().process_frame
		for entry in [[2, "battle"], [3, "troops"]]:
			_home.select_tab(entry[0], false)
			await _capture(entry[1], size)
	_save_icon_sheet()
	var manifest := {
		"profile": OS.get_user_data_dir(),
		"persist": PlayerData.persist,
		"captures": _captures,
		"sheet": {"file": "icon_sizes_32_48_64_96_128.png", "columns": ICON_SIZES,
			"rows": ["tab_battle", "tab_army"], "native_pixels": true},
		"failures": _failures,
	}
	var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	if file == null:
		_failures += 1
		push_error("Could not write nav icon capture manifest")
	else:
		file.store_string(JSON.stringify(manifest, "\t"))
		file.close()
	print("NAV_ICONS_COMPLETE ", _captures.size(), " screens; failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _capture(tab_name: String, requested: Vector2i) -> void:
	await get_tree().create_timer(0.3).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var key := "%s_%dx%d" % [tab_name, requested.x, requested.y]
	if shot.get_size() != requested:
		_failures += 1
		push_error("Native capture size mismatch: %s expected %s, got %s" % [key, requested, shot.get_size()])
	_save(shot, key + ".png")
	# An unscaled crop makes the selected and unselected icons easy to compare.
	var nav_height := int(round(160.0 * shot.get_width() / 720.0))
	var crop := Rect2i(0, shot.get_height() - nav_height, shot.get_width(), nav_height)
	_save(shot.get_region(crop), key + "_nav.png")
	_captures.append({"tab": tab_name, "file": key + ".png", "nav": key + "_nav.png",
		"requested": [requested.x, requested.y], "actual": [shot.get_width(), shot.get_height()],
		"window": [get_window().size.x, get_window().size.y]})
	print("NAV_ICONS_CAPTURE ", key, " native=", shot.get_size())


func _save_icon_sheet() -> void:
	# Asset variants at native raster size, on a quiet neutral background.
	# Columns: 32 / 48 / 64 / 96 / 128. Rows: swords / shield.
	var cell := 144
	var sheet := Image.create(cell * ICON_SIZES.size(), cell * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("e9dfcd"))
	var names := ["tab_battle", "tab_army"]
	for row in names.size():
		for col in ICON_SIZES.size():
			var size: int = ICON_SIZES[col]
			var texture := Ui.icon_tex(names[row], size)
			if texture == null:
				_failures += 1
				push_error("Missing icon variant: %s/%d" % [names[row], size])
				continue
			var icon := texture.get_image()
			if icon.is_compressed():
				icon.decompress()
			icon.convert(Image.FORMAT_RGBA8)
			if icon.get_size() != Vector2i(size, size):
				_failures += 1
				push_error("Icon variant is not native %dpx: %s" % [size, names[row]])
			var at := Vector2i(col * cell + (cell - icon.get_width()) / 2, row * cell + (cell - icon.get_height()) / 2)
			sheet.blend_rect(icon, Rect2i(Vector2i.ZERO, icon.get_size()), at)
	_save(sheet, "icon_sizes_32_48_64_96_128.png")


func _save(image: Image, name: String) -> void:
	var result := image.save_png(OUT + "/" + name)
	if result != OK:
		_failures += 1
		push_error("Could not save %s: %d" % [name, result])
