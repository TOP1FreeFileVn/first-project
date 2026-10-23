extends Node

const DemoHome = preload("res://docs/design/2026-10-24/shop-clarity-demo/ShopDemoHome.gd")
const Proposal = preload("res://docs/design/2026-10-24/shop-clarity-demo/ShopClarityPage.gd")
const OUT := "res://docs/design/2026-10-24/shop-clarity-demo/captures"
var _home: Control
var _stock: Control
var _proposal: Control
var _checks := 0
var _failures: Array = []
var _captures: Array = []


func _ready() -> void:
	PlayerData.persist = false
	_reset_account()
	AudioServer.set_bus_mute(0, true)
	_home = DemoHome.new()
	add_child(_home)
	_home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stock = _home._pages[_home.SHOP_TAB]
	_proposal = Proposal.new()
	_proposal.home = _home
	_proposal.visible = false
	_home._content.add_child(_proposal)
	_show_proposal(true)
	if "--capture" in OS.get_cmdline_user_args():
		get_tree().create_timer(70.0).timeout.connect(func(): get_tree().quit(2))
		await _capture_review()
	else:
		get_window().size = Vector2i(450, 800)
		var usable := DisplayServer.screen_get_usable_rect()
		get_window().position = usable.position + (usable.size - get_window().size) / 2
		_update_title()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F1: _show_proposal(false)
		KEY_F2: _show_proposal(true)
		KEY_G:
			_home.palette_mode = (_home.palette_mode + 1) % 3
			_proposal.set_palette(_home.palette_mode)
			_show_proposal(true)
		KEY_R:
			_reset_account()
			_home._pages[_home.SHOP_TAB].refresh()
			_home._update_header()
		KEY_P:
			PlayerData.gems = 0
			PlayerData.gold = 0
			_home._pages[_home.SHOP_TAB].refresh()
			_home._update_header()
	_update_title()


func _reset_account() -> void:
	PlayerData._reset()
	PlayerData.sound_on = false
	PlayerData.tutorial_done = true
	PlayerData.gold = 1800
	PlayerData.gems = 240
	PlayerData.gold_chest_pity = 3


func _show_proposal(value: bool) -> void:
	_home.close_page()
	_home.proposed = value
	_stock.visible = false
	_proposal.visible = false
	_home._pages[_home.SHOP_TAB] = _proposal if value else _stock
	_home._current = -1
	_home.select_tab(_home.SHOP_TAB, false)
	_home._update_header()
	_update_title()


func _update_title() -> void:
	var palette_names := ["Giấy phẳng", "Mật ong", "Xanh ngọc"]
	var label: String = palette_names[_home.palette_mode] if _home.proposed else "Bản hiện tại"
	get_window().title = "DEMO SHOP · " + label + " | G đổi màu · F1 cũ · F2 mới · R reset · P thiếu tiền"


func _capture_review() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for dimensions in [Vector2i(360, 640), Vector2i(450, 800)]:
		get_window().size = dimensions
		_reset_account()
		_show_proposal(false)
		await _snap("current", dimensions)
		for palette in 3:
			_home.palette_mode = palette
			_proposal.set_palette(palette)
			_show_proposal(true)
			await _snap(["flat", "honey", "teal"][palette], dimensions)
			_check_layout(dimensions)
	# Review the state which was invisible in the previous fully funded capture.
	_home.palette_mode = 1
	_proposal.set_palette(1)
	PlayerData.gems = 0
	PlayerData.gold = 0
	_show_proposal(true)
	await _settle()
	var gold_action: Button = _proposal.find_child("GoldOpen", true, false)
	var silver_action: Button = _proposal.find_child("SilverOpen", true, false)
	_check(gold_action != null and gold_action.disabled, "Gold disabled without gems")
	_check(silver_action != null and silver_action.disabled, "Silver disabled without gold")
	await _snap("insufficient", Vector2i(450, 800))
	_reset_account()
	_show_proposal(true)
	await _settle()
	var scroll := _proposal.get_child(0) as ScrollContainer
	scroll.scroll_vertical = 10000
	await _snap("scrolled", Vector2i(450, 800))
	scroll.scroll_vertical = 0
	await _settle()
	var rate: Button = _proposal.find_child("ShopRates", true, false)
	_check(rate != null, "Rates link exists before purchase")
	if rate != null:
		await _tap(rate)
		await _snap("rates", Vector2i(450, 800))
	_home.queue_free()
	await _settle()
	# A fresh Home ensures the popup test does not influence the real action test.
	_home = DemoHome.new()
	add_child(_home)
	_home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stock = _home._pages[_home.SHOP_TAB]
	_proposal = Proposal.new()
	_proposal.home = _home
	_home._content.add_child(_proposal)
	_show_proposal(true)
	await _settle()
	var before := PlayerData.gems
	gold_action = _proposal.find_child("GoldOpen", true, false)
	_check(gold_action != null and not gold_action.disabled, "Gold action available with funds")
	await _tap(gold_action)
	await get_tree().create_timer(1.4).timeout
	_check(PlayerData.gems == before - 120, "Demo open spends the unchanged 120 gem cost once")
	await _snap("opening", Vector2i(450, 800))
	_check(not PlayerData.persist, "Demo does not persist account changes")
	var report := {"checks": _checks, "failures": _failures, "captures": _captures,
		"profile": OS.get_user_data_dir(), "persist": PlayerData.persist,
		"scope": "Isolated shop proposal, existing Home chrome and original chest art; no production UI modifications"}
	var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("SHOP_DEMO_COMPLETE checks=", _checks, " failures=", _failures)
	_home.queue_free()
	await _settle()
	get_tree().quit.call_deferred(0 if _failures.is_empty() else 1)


func _check_layout(dimensions: Vector2i) -> void:
	var width: float = _home._content.size.x
	for title in ["GoldOpen", "WoodOpen", "SilverOpen", "ShopRates"]:
		var item := _proposal.find_child(title, true, false) as Control
		_check(item != null, title + " exists at " + str(dimensions))
		if item != null:
			var rect := item.get_global_rect()
			_check(rect.position.x >= 0 and rect.end.x <= width + 1,
				title + " fits horizontal viewport at " + str(dimensions))


func _snap(label: String, dimensions: Vector2i) -> void:
	await _settle()
	var shot := get_viewport().get_texture().get_image()
	if shot.get_size() != dimensions:
		shot.resize(dimensions.x, dimensions.y, Image.INTERPOLATE_LANCZOS)
	var filename := "%s-%dx%d.png" % [label, dimensions.x, dimensions.y]
	_check(shot.save_png(OUT + "/" + filename) == OK, filename + " captured")
	_captures.append(filename)


func _settle() -> void:
	for frame in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _tap(button: Button) -> void:
	var at := button.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.pressed = down
		get_viewport().push_input(event, true)
		await get_tree().process_frame


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(message)
		push_error(message)
