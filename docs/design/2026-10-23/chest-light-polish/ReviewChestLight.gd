extends Node

## Review-only entry point. Production Home and ChestOpening, no loot-grant call.
const HomeScene = preload("res://game/menu/Home.tscn")
const HomeScript = preload("res://game/menu/Home.gd")
const ChestOpening = preload("res://game/ui/ChestOpening.gd")
const ChestArt = preload("res://game/ui/ChestArt.gd")
const Economy = preload("res://game/core/Economy.gd")
const OUT := "res://docs/design/2026-10-23/chest-light-polish"
const SIZES := [Vector2i(360, 640), Vector2i(450, 800)]
const FIXTURES := [{"label": "common", "id": "kiem", "rarity": 0},
	{"label": "rare", "id": "cu_kiem", "rarity": 1},
	{"label": "epic", "id": "dao", "rarity": 2}]

var _home: Control
var _opening: Control
var _size := Vector2i.ZERO
var _original: Dictionary
var _original_persist := true
var _original_tab := 0
var _save_before := ""
var _fixture_state: Dictionary
var _checks: Array = []
var _captures: Array = []
var _frames: Array = []
var _failures := 0
var _closed_signals := 0


func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "/frames"))
	_original = PlayerData.to_dict().duplicate(true)
	_original_persist = PlayerData.persist
	_original_tab = HomeScript.last_tab
	PlayerData.persist = false
	_save_before = _save_hash()
	var opening_script: Script = ChestOpening
	if not opening_script.can_instantiate():
		_check(false, "production_chest_script_compiles")
		_restore()
		_finish()
		return
	get_tree().create_timer(110.0).timeout.connect(func():
		push_error("CHEST_LIGHT_REVIEW_TIMEOUT")
		_restore()
		get_tree().quit(1))
	for dimensions in SIZES:
		_size = dimensions
		await _mount()
		for fixture in FIXTURES:
			await _production_cycle(fixture)
		for stage in ["wait", "charge", "reveal", "fast"]:
			await _skip_and_close(stage)
		await _unmount()
	_check(not PlayerData.persist and _save_before == _save_hash(), "no_persistent_save_change")
	await _release_audio()
	_restore()
	_check(PlayerData.to_dict() == _original, "original_profile_restored")
	_check(PlayerData.persist == _original_persist, "original_persist_restored")
	_check(HomeScript.last_tab == _original_tab, "original_home_tab_restored")
	_finish()


func _mount() -> void:
	PlayerData._reset()
	PlayerData.persist = false
	PlayerData.tutorial_done = true
	PlayerData.sound_on = false
	PlayerData.music_on = false
	get_window().size = _size
	_home = HomeScene.instantiate()
	add_child(_home)
	_home.select_tab(_home.SHOP_TAB, false)
	await _settle()
	_fixture_state = PlayerData.to_dict().duplicate(true)
	_check(_home.is_visible_in_tree(), "production_home_visible")


func _unmount() -> void:
	_home.queue_free()
	await _settle()
	_home = null


func _new_opening(id: String, fast := false) -> void:
	_opening = ChestOpening.new()
	# Presentation already receives granted loot in the real flow. This harness only
	# passes safe data directly to presentation; it never calls grant/open_chest.
	_opening.setup(Economy.CHESTS.gold.name, ChestArt.TINTS.gold,
		{"gold": 0, "cards": {id: 2}}, [], fast)
	_opening.closed.connect(func(): _closed_signals += 1)
	_opening.attach(_home)


func _production_cycle(fixture: Dictionary) -> void:
	var label: String = fixture.label
	_check(PlayerData.rarity_of(fixture.id) == fixture.rarity, label + "_fixture_rarity")
	_new_opening(fixture.id)
	_check(await _until(func(): return _opening._stage == "wait"), label + "_reaches_wait")
	_check(_opening.lid_offset == Vector2.ZERO and _opening.lid_alpha == 1.0,
		label + "_wait_lid_closed")
	await _capture(label + "-wait")
	var make_sequence := _size == SIZES[0] and label == "common"
	if make_sequence:
		await _sequence(0.6)
	_opening._on_tap()
	_check(_opening._stage == "open", label + "_tap_starts_charge")
	var got_mouth := false
	var got_card := false
	var got_charge := false
	var started := Time.get_ticks_msec()
	var next_frame := started
	while Time.get_ticks_msec() - started < 6000:
		await get_tree().process_frame
		if _opening.charge > 0.1:
			got_charge = true
		if not got_mouth and _opening.mouth > 0.5 and _opening._stage == "open":
			got_mouth = true
			await _capture(label + "-open-mouth")
		if not got_card and _opening._stage == "card" and _opening._card != null and _opening.sweep >= 0.0:
			got_card = true
			await _capture(label + "-card")
		if make_sequence and Time.get_ticks_msec() >= next_frame:
			await _frame()
			next_frame = Time.get_ticks_msec() + 83
		if got_card:
			break
	_check(got_charge, label + "_actual_charge_animated")
	_check(got_mouth, label + "_actual_open_mouth_captured")
	_check(got_card, label + "_actual_face_up_card_captured")
	_check(_opening.lid_alpha == 0.0 and _opening.mouth > 0.0,
		label + "_card_keeps_open_chest")
	if make_sequence:
		await _sequence(0.35)
	_opening.skip()
	await _settle()
	await _close_summary(label + "_cycle")
	_check(PlayerData.to_dict() == _fixture_state, label + "_presentation_does_not_grant_loot")


func _skip_and_close(stage: String) -> void:
	_new_opening("dao", stage == "fast")
	if stage != "fast":
		_check(await _until(func(): return _opening._stage == "wait"), stage + "_skip_fixture_wait")
		if stage == "charge":
			_opening._on_tap()
			_check(await _until(func(): return _opening.charge > 0.1), "skip_during_charge_before_burst")
		elif stage == "reveal":
			_opening._on_tap()
			_check(await _until(func(): return _opening._stage == "card"), "skip_during_card_reveal")
		_check(await _tap(_opening._skip), stage + "_native_skip_button_receives_tap")
	await _settle()
	_check(_opening._stage == "summary", stage + "_skip_reaches_summary")
	_check(not _opening._skip.visible and _opening._card == null, stage + "_summary_hides_active_reveal")
	_check(_opening.charge == 0.0 and _opening.chest_alpha == 0.0, stage + "_summary_clears_charge_and_chest")
	if stage == "fast":
		await _capture("fast-summary")
	await _close_summary(stage)
	_check(PlayerData.to_dict() == _fixture_state, stage + "_skip_does_not_grant_loot")


func _close_summary(label: String) -> void:
	var old_layer := _opening.get_parent()
	var before := _closed_signals
	var done := _opening.find_child("ChestDoneButton", true, false) as Button
	_check(await _tap(done), label + "_native_done_button_receives_tap")
	await _settle()
	_check(not is_instance_valid(_opening) and not is_instance_valid(old_layer), label + "_opening_layer_freed")
	_check(_closed_signals == before + 1, label + "_closed_emitted_once")
	_check(_home.is_visible_in_tree() and _home._current == _home.SHOP_TAB, label + "_returns_to_home_shop")
	_opening = null


func _sequence(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await _frame()
		await get_tree().create_timer(0.083).timeout


func _frame() -> void:
	await RenderingServer.frame_post_draw
	var filename := "frames/frame_%03d.png" % _frames.size()
	var image := get_viewport().get_texture().get_image()
	_check(image.get_size() == _size and image.save_png(OUT.path_join(filename)) == OK,
		"sequence_frame_%03d" % _frames.size())
	_frames.append({"file": filename, "stage": _opening._stage, "charge": _opening.charge,
		"mouth": _opening.mouth, "flash": _opening.flash, "time_ms": Time.get_ticks_msec()})


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var filename := "%s_%dx%d.png" % [label, _size.x, _size.y]
	_check(image.get_size() == _size and image.save_png(OUT.path_join(filename)) == OK, "capture_" + label)
	_captures.append({"file": filename, "window": [_size.x, _size.y],
		"stage": _opening._stage, "charge": _opening.charge, "mouth": _opening.mouth,
		"flash": _opening.flash, "ray_alpha": _opening.ray_alpha})


func _tap(button: Button) -> bool:
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	var received := [false]
	button.pressed.connect(func(): received[0] = true, CONNECT_ONE_SHOT)
	var native := get_tree().root.get_final_transform() * button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = native
	motion.global_position = native
	Input.parse_input_event(motion)
	await get_tree().process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = native
		event.global_position = native
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
	return received[0]


func _until(condition: Callable, timeout := 6.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return condition.call()


func _settle() -> void:
	for frame in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _save_hash() -> String:
	return FileAccess.get_sha256(PlayerData.SAVE_PATH) if FileAccess.file_exists(PlayerData.SAVE_PATH) else "absent"


func _release_audio() -> void:
	# Home intentionally starts a muted looping music stream even when its toggle
	# is off. Drain the Dummy audio driver's playback before this short process
	# exits, so it does not report a live WAV/playback resource as an exit leak.
	for library in [MusicLib, SoundLib]:
		for player: AudioStreamPlayer in library.find_children("*", "AudioStreamPlayer", true, false):
			player.stop()
			player.stream = null
	await get_tree().create_timer(0.08).timeout
	await _settle()


func _restore() -> void:
	PlayerData.from_dict(_original)
	HomeScript.last_tab = _original_tab
	PlayerData.persist = _original_persist


func _check(passed: bool, label: String) -> void:
	_checks.append({"name": label, "passed": passed, "window": [_size.x, _size.y]})
	if not passed:
		_failures += 1
		push_error("CHEST_LIGHT_REVIEW_FAIL " + label + " " + str(_size))


func _finish() -> void:
	var report := {"scope": "Production Home + ChestOpening, safe presentation-only fixtures; native Skip/Done interactions, charge/reveal/fast routes, state restoration.",
		"profile": OS.get_user_data_dir(), "save_before": _save_before, "save_after": _save_hash(),
		"original_persist_restored": PlayerData.persist == _original_persist,
		"checks": _checks, "captures": _captures, "frames": _frames, "failures": _failures}
	var file := FileAccess.open(OUT.path_join("review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("CHEST_LIGHT_REVIEW_COMPLETE checks=", _checks.size(), " captures=", _captures.size(), " sequence_frames=", _frames.size(), " failures=", _failures)
	get_tree().quit(1 if _failures > 0 else 0)
