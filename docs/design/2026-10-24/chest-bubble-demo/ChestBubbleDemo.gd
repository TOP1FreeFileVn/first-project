extends Node

## Review-only layouts. Account and purchases stay in an isolated, nonpersistent profile.
const HomeScene = preload("res://game/menu/Home.tscn")
const Proposal = preload("res://docs/design/2026-10-24/chest-bubble-demo/ChestBubblePage.gd")
const OUT := "res://docs/design/2026-10-24/chest-bubble-demo/captures"
const LABELS := ["A · Sát mẫu", "B · Ô thoại giấy", "C · Ô thoại nổi"]
var _home: Control
var _page: Control
var _variant := 0
var _checks := 0
var _failures: Array = []
var _captures: Array = []


func _ready() -> void:
	PlayerData.persist = false
	_reset_account()
	AudioServer.set_bus_mute(0, true)
	_home = HomeScene.instantiate()
	add_child(_home)
	var old: Control = _home._pages[_home.SHOP_TAB]
	old.hide()
	_page = Proposal.new()
	_page.home = _home
	_home._content.add_child(_page)
	_home._pages[_home.SHOP_TAB] = _page
	old.queue_free()
	_home._current = -1
	_home.select_tab(_home.SHOP_TAB, false)
	_select_variant(0)
	if "--capture" in OS.get_cmdline_user_args():
		get_tree().create_timer(70.0).timeout.connect(func(): get_tree().quit(2))
		await _capture_all()
	else:
		get_window().size = Vector2i(450, 800)
		var usable := DisplayServer.screen_get_usable_rect()
		get_window().position = usable.position + (usable.size - get_window().size) / 2


func _reset_account() -> void:
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.tutorial_done = true
	PlayerData.gold = 1800
	PlayerData.gems = 240
	PlayerData.gold_chest_pity = 3


func _select_variant(value: int) -> void:
	_variant = wrapi(value, 0, 3)
	_home.close_page()
	if _home._current != _home.SHOP_TAB:
		_home.select_tab(_home.SHOP_TAB, false)
	_page.set_variant(_variant)
	(_page.get_child(0) as ScrollContainer).scroll_vertical = 0
	get_window().title = "DEMO RƯƠNG · %s | 1 / 2 / 3 đổi mẫu · R reset" % LABELS[_variant]


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: _select_variant(0)
		KEY_2: _select_variant(1)
		KEY_3: _select_variant(2)
		KEY_RIGHT, KEY_G: _select_variant(_variant + 1)
		KEY_LEFT: _select_variant(_variant - 1)
		KEY_R:
			_reset_account()
			_home._update_header()
			_select_variant(_variant)


func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for dimensions in [Vector2i(360, 640), Vector2i(450, 800)]:
		get_window().size = dimensions
		for value in 3:
			_select_variant(value)
			await _settle()
			_check_layout(dimensions)
			var prefix: String = ["a-reference", "b-paper", "c-floating"][value]
			await _snap(prefix, dimensions, true)
			if dimensions.x == 450:
				var scroll := _page.get_child(0) as ScrollContainer
				scroll.scroll_vertical = 10000
				await _snap(prefix + "-scrolled", dimensions)
				scroll.scroll_vertical = 0
				await _settle()
	# Inspect the same layout with currency gating and live cooldown copy.
	_select_variant(1)
	PlayerData.gold = 0
	PlayerData.gems = 0
	PlayerData.free_chest_at = PlayerData.now() + 120
	PlayerData.changed.emit()
	await _settle()
	for node_name in ["GoldOpen", "SilverOpen", "WoodOpen"]:
		var action := _page.find_child(node_name, true, false) as Button
		_check(action != null and action.disabled, node_name + " observes actual account availability")
	await _snap("b-unavailable", Vector2i(450, 800))
	_check(not PlayerData.persist, "Demo account does not persist")
	var report := {"checks": _checks, "failures": _failures, "captures": _captures,
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist}
	var report_file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report, "\t"))
	print("CHEST_BUBBLE_DEMO_COMPLETE checks=", _checks, " failures=", _failures)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _check_layout(dimensions: Vector2i) -> void:
	for kind in ["gold", "silver", "wood"]:
		var card := _page.find_child("BubbleCard_" + kind, true, false) as Control
		var bubble := _page.find_child("Bubble_" + kind, true, false) as Control
		_check(card != null and bubble != null, "Card and speech bubble exist: " + kind)
		if card == null or bubble == null:
			continue
		var rect := card.get_global_rect()
		_check(rect.position.x >= 0 and rect.end.x <= _home.size.x + 1,
			"Card contained at %s: %s/%s" % [dimensions, _variant, kind])
		var bubble_rect := bubble.get_global_rect()
		_check(rect.grow(1).encloses(bubble_rect), "Speech bubble contained: %s/%s" % [_variant, kind])
	_check(_home._nav_holder.is_visible_in_tree(), "Original bottom navigation visible")


func _snap(prefix: String, dimensions: Vector2i, crop := false) -> void:
	await _settle()
	var shot := get_viewport().get_texture().get_image()
	var stem := "%s-%dx%d" % [prefix, dimensions.x, dimensions.y]
	_check(shot.get_size() == dimensions, "Native capture dimensions: " + stem)
	_check(shot.save_png(OUT + "/" + stem + ".png") == OK, "Saved " + stem)
	_captures.append(stem + ".png")
	if crop:
		var card := _page.find_child("BubbleCard_gold", true, false) as Control
		if card != null:
			var logical := card.get_global_rect()
			var scale_factor: float = dimensions.x / _home.size.x
			var pixels := Rect2i((logical.position * scale_factor).floor(), (logical.size * scale_factor).ceil())
			var clipped := pixels.intersection(Rect2i(Vector2i.ZERO, dimensions))
			_check(clipped == pixels, "Gold card fully visible: " + stem)
			shot.get_region(clipped).save_png(OUT + "/" + stem + "-card.png")


func _settle() -> void:
	for frame in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(message)
		push_error(message)
