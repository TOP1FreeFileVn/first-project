extends Node

# Production roster, isolated in-memory profile. Captures native 720/360px screens.
const HOME = preload("res://game/menu/Home.tscn")
const UiKit = preload("res://game/ui/UiKit.gd")
const OUT := "res://docs/ui_review/2026-10-19/troops-flat-cards"
@export var native_width := 720

var _home: Control
var _page: Control
var _failures: Array[String] = []
var _checks := 0
var _captures: Array = []
var _cards: Array = []
var _routes: Array = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	PlayerData.gold = 100000
	for id in PlayerData.TROOP_ORDER:
		PlayerData.troops[id]["unlocked"] = false
	# One owned cat at each star count, with all four locked rarities in the collection.
	for entry in [["kiem", 1], ["riu", 2], ["gay_phep", 3]]:
		PlayerData.troops[entry[0]]["unlocked"] = true
		PlayerData.troops[entry[0]]["stars"] = entry[1]
	PlayerData.troops["kiem"]["cards"] = PlayerData.star_up_cost("kiem")
	PlayerData.team = ["kiem", "riu", "gay_phep"]
	get_window().size = Vector2i(native_width, native_width * 16 / 9)
	_home = HOME.instantiate()
	add_child(_home)
	_home.select_tab(3, false)
	_page = _home._pages[3]
	await _settle()
	_verify_collection()
	await _capture("top")
	await _scroll_end()
	await _capture("bottom")
	_page._scroll.scroll_vertical = 0
	await _settle()
	await _detail_route("kiem", "owned_detail")
	await _detail_route("dao", "locked_detail")
	_write_json("manifest_%d.json" % native_width, {
		"native_width": native_width, "persist": PlayerData.persist,
		"profile": OS.get_user_data_dir(), "checks": _checks,
		"failures": _failures, "failure_count": _failures.size(),
		"captures": _captures, "cards": _cards, "routes": _routes})
	print("TROOPS_FLAT_COMPLETE width=", native_width, " checks=", _checks, " failures=", _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)


func _verify_collection() -> void:
	var grid := _page.find_child("TroopGrid", true, false) as GridContainer
	_check(grid != null, "Production collection grid exists")
	if grid == null:
		return
	_check(grid.columns == 4, "Collection retains four columns")
	_check(grid.get_child_count() == PlayerData.TROOP_ORDER.size(), "All troops remain in collection")
	var locked_rarities: Array[int] = []
	var width := -1.0
	var scroll_rect: Rect2 = _page._scroll.get_global_rect()
	for child in grid.get_children():
		var card := child as Button
		_check(card != null, "Collection child remains a button")
		if card == null:
			continue
		var id := str(card.name).trim_prefix("TroopCard_")
		_check(PlayerData.TROOPS.has(id), "Card maps to a known troop: " + id)
		if not PlayerData.TROOPS.has(id):
			continue
		var unlocked: bool = PlayerData.is_unlocked(id)
		var rect := card.get_global_rect()
		if width < 0.0:
			width = rect.size.x
		_check(absf(rect.size.x - width) <= 1.0, "Equal card width: " + id)
		_check(rect.position.x >= scroll_rect.position.x - 1.0 and rect.end.x <= scroll_rect.end.x + 1.0,
			"Card fits viewport horizontally: " + id)
		var record := {"id": id, "unlocked": unlocked, "rect": _rect(card)}
		var name_label := card.find_child("TroopName", true, false) as Label
		_check(name_label != null, "Troop name remains visible: " + id)
		if name_label != null:
			_check(name_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Name centered: " + id)
			_check(_label_fits(name_label), "Complete name fits: " + id)
			_check(rect.grow(1.0).encloses(name_label.get_global_rect()), "Name stays inside card: " + id)
			_check(name_label.get_theme_constant("outline_size") == 0, "Name has no white outline: " + id)
			_check(_card_label_color(name_label), "Name remains dark: " + id)
			record["name_rect"] = _rect(name_label)
		var portrait := card.find_child("TroopPortrait", true, false) as Control
		_check(portrait != null, "Portrait exists: " + id)
		if portrait != null:
			_check(rect.grow(1.0).encloses(portrait.get_global_rect()), "Portrait stays inside card: " + id)
			record["portrait_rect"] = _rect(portrait)
		var stars := card.find_child("TroopStars", true, false) as Control
		if unlocked:
			_check(stars != null, "Owned card has stars: " + id)
			if stars != null:
				var expected: int = PlayerData.troop(id)["stars"]
				_check(stars.get_child_count() == expected, "Only earned stars shown: " + id)
				_check(absf(stars.get_global_rect().get_center().x - rect.get_center().x) <= 1.0, "Stars centered: " + id)
				_check(rect.grow(1.0).encloses(stars.get_global_rect()), "Stars stay inside card: " + id)
				record["stars"] = stars.get_child_count()
				record["stars_rect"] = _rect(stars)
				for star in stars.get_children():
					_check(star is TextureRect, "Star is drawn icon: " + id)
					if star is TextureRect and star.texture != null:
						_check(not star.texture.resource_path.contains("star_off"), "No empty star placeholders: " + id)
			_check(card.find_child("TroopLockedQuestion", true, false) == null, "Owned portrait has no question: " + id)
		else:
			var rarity: int = PlayerData.rarity_of(id)
			if not locked_rarities.has(rarity):
				locked_rarities.append(rarity)
			_check(stars == null or stars.get_child_count() == 0, "Locked card has no stars: " + id)
			_check(portrait != null and _is_black(portrait), "Locked portrait is fully black: " + id)
			var question := card.find_child("TroopLockedQuestion", true, false) as Label
			_check(question != null and question.text == "?", "Locked portrait has question mark: " + id)
			if question != null and portrait != null:
				_check(question.is_visible_in_tree(), "Question mark visible: " + id)
				_check(question.get_global_rect().get_center().distance_to(portrait.get_global_rect().get_center()) <= 2.0,
					"Question mark centered over silhouette: " + id)
				record["question_rect"] = _rect(question)
			_check(card.find_child("TroopLevel", true, false) == null, "Locked card has no level chip: " + id)
		_check_no_old_locked_ui(card, id)
		_cards.append(record)
	_check(locked_rarities.size() == 4, "Fixture exercises locked portraits of every rarity")


func _is_black(portrait: Control) -> bool:
	# Zero RGB preserves the sprite's alpha, removing internal colors and outlines.
	var tint := portrait.modulate * portrait.self_modulate
	return tint.r <= 0.001 and tint.g <= 0.001 and tint.b <= 0.001 and tint.a > 0.99


func _check_no_old_locked_ui(node: Node, id: String) -> void:
	if node is Label:
		_check(not node.text.to_lower().contains("chưa mở"), "No locked caption: " + id)
	if node is TextureRect and node.texture != null:
		var texture_path: String = node.texture.resource_path
		_check(not texture_path.contains("icon_lock") and not texture_path.get_file().begins_with("lock"),
			"No padlock badge: " + id)
	for child in node.get_children():
		_check_no_old_locked_ui(child, id)


func _card_label_color(label: Label) -> bool:
	var tint := label.get_theme_color("font_color")
	return tint.get_luminance() < 0.3


func _label_fits(label: Label) -> bool:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	if label.get_visible_line_count() < label.get_line_count():
		return false
	if font.get_height(font_size) * label.get_line_count() > label.size.y + 2.0:
		return false
	for word in label.text.split(" "):
		if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x + 1.0:
			return false
	return true


func _scroll_end() -> void:
	var at: Vector2 = _page._scroll.get_global_rect().get_center()
	for i in range(16):
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_WHEEL_DOWN
			event.pressed = pressed
			event.position = at
			event.global_position = at
			get_viewport().push_input(event, true)
		await get_tree().process_frame
	var bar: VScrollBar = _page._scroll.get_v_scroll_bar()
	_check(bar.max_value - bar.page > 0, "Collection is scrollable")
	_check(_page._scroll.scroll_vertical >= bar.max_value - bar.page - 1, "Wheel reaches collection bottom")


func _detail_route(id: String, capture_name: String) -> void:
	var card := _page.find_child("TroopCard_" + id, true, false) as Button
	var received := await _tap(card)
	await _settle()
	var opened: bool = received and is_instance_valid(_page._detail_box) and _page._detail_id == id
	_check(opened, "Tapping card still opens detail: " + id)
	_routes.append({"id": id, "passed": opened})
	if not opened:
		return
	await get_tree().create_timer(0.15).timeout
	await _capture(capture_name)
	if PlayerData.is_unlocked(id):
		await _star_upgrade_route(id)
	var box: Control = _page._detail_box
	var overlay: Control = box.get_meta("overlay")
	UiKit.close_popup(box)
	await get_tree().create_timer(0.2).timeout
	await _settle()
	_check(not is_instance_valid(overlay), "Detail closes: " + id)


func _star_upgrade_route(id: String) -> void:
	var old_stars: int = PlayerData.troop(id)["stars"]
	var old_cards: int = PlayerData.troop(id)["cards"]
	var star_cost: int = PlayerData.star_up_cost(id)
	var button := _button_prefix(_page._detail_box, "LÊN SAO")
	var received := await _tap(button)
	await _settle()
	var upgraded: bool = received and PlayerData.troop(id)["stars"] == old_stars + 1
	_check(upgraded, "Star-up button increases earned stars: " + id)
	_check(PlayerData.troop(id)["cards"] == old_cards - star_cost, "Star-up spends exact cards: " + id)
	var card := _page.find_child("TroopCard_" + id, true, false) as Control
	var row: Control = card.find_child("TroopStars", true, false) if card != null else null
	var roster_refreshed: bool = row != null and row.get_child_count() == old_stars + 1
	_check(roster_refreshed, "Roster earned-star row updates immediately: " + id)
	var detail_row := _page._detail_box.find_child("TroopStars", true, false) as Control
	var detail_refreshed: bool = detail_row != null and detail_row.get_child_count() == old_stars + 1
	_check(detail_refreshed, "Detail earned-star row updates immediately: " + id)
	_routes.append({"id": id, "route": "star_upgrade", "passed": upgraded and roster_refreshed and detail_refreshed})


func _button_prefix(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):
		return node
	for child in node.get_children():
		var found := _button_prefix(child, prefix)
		if found != null:
			return found
	return null


func _tap(button: Button) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var at := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	return received[0]


func _capture(label: String) -> void:
	await _settle()
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var filename := "%s_%d.png" % [label, native_width]
	_check(shot.get_size() == Vector2i(native_width, native_width * 16 / 9), "Native screenshot size: " + filename)
	_check(shot.save_png(OUT + "/" + filename) == OK, "Screenshot saved: " + filename)
	_captures.append(filename)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _rect(control: Control) -> Array:
	var rect := control.get_global_rect()
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _check(passed: bool, message: String) -> void:
	_checks += 1
	if passed:
		return
	_failures.append(message)
	push_error(message)


func _write_json(filename: String, value: Dictionary) -> void:
	var file := FileAccess.open(OUT + "/" + filename, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t"))
	file.close()
