extends RefCounted

## The settings sheet, shared by the lobby (gear in the top bar) and the battle (gear on
## the HUD, which pauses the fight while it is open). Rows are grouped: Âm thanh, Trận
## đánh, Chung; the lobby version adds the data section, the battle one its own actions.
## Every change saves at once (PlayerData.set_setting).

const UiKit = preload("res://game/ui/UiKit.gd")
const Ui = preload("res://game/ui/Ui.gd")

const INK := Color("583f21")
const MUTED := Color("6b563b")

## Opens the sheet over `host`. `in_battle` adds Tiếp tục / Chơi lại / Rời trận (through
## `battle`) and pauses the tree until the sheet closes.
static func open(host: Control, in_battle := false, battle = null) -> VBoxContainer:
	var box := UiKit.popup(host, 600, "Cài đặt")
	var overlay: Control = box.get_meta("overlay", null)
	if in_battle:
		# The sheet works while the fight is frozen.
		if overlay != null:
			overlay.process_mode = Node.PROCESS_MODE_ALWAYS
		host.get_tree().paused = true
		if overlay != null:
			overlay.tree_exited.connect(func():
				if is_instance_valid(host) and host.is_inside_tree():
					host.get_tree().paused = false)
	box.add_theme_constant_override("separation", 10)

	_heading(box, "Âm thanh")
	_toggle_slider(box, "Nhạc nền", "music_on", "music_volume", func(): MusicLib.refresh())
	_toggle_slider(box, "Hiệu ứng âm thanh", "sound_on", "sound_volume", func(): SoundLib.play("click"))
	_toggle(box, "Rung khi có sự kiện lớn", "vibration_on", func(): PlayerData.vibrate(40))

	_heading(box, "Trận đánh")
	_choice(box, "Tốc độ khi vào trận", "battle_speed", [[1, "x1"], [2, "x2"]], func():
		if in_battle:
			Engine.time_scale = float(PlayerData.battle_speed))
	_toggle(box, "Hiện chữ CHÍ MẠNG", "crit_text_on")
	_toggle(box, "Hỏi lại khi rời trận", "confirm_leave")

	_heading(box, "Chung")
	_toggle(box, "Mở rương nhanh (bỏ hoạt ảnh)", "fast_chest")

	if in_battle and battle != null:
		_battle_actions(box, battle)
	else:
		_data_section(box, host)
	var version := _text("Gear Defenders · bản thử nghiệm · tiến độ lưu tự động trên máy", 15, MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(version)
	return box


# --- Rows ---------------------------------------------------------------------------------

static func _heading(box: VBoxContainer, text: String) -> void:
	var label := _text(text, 22)
	label.name = "SettingsHeading_" + text
	box.add_child(label)


static func _row(box: VBoxContainer, title: String) -> HBoxContainer:
	var row := UiKit.hbox(10)
	row.custom_minimum_size.y = 52
	var label := _text(title, 19)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	box.add_child(row)
	return row


## An on/off switch (a CheckBox with the theme's big tick).
static func _switch(key: String, on_change := Callable()) -> CheckBox:
	var check := CheckBox.new()
	check.name = "Setting_" + key
	check.button_pressed = bool(PlayerData.get(key))
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(func(on):
		PlayerData.set_setting(key, on)
		SoundLib.play("click")
		if on_change.is_valid():
			on_change.call())
	return check


static func _toggle(box: VBoxContainer, title: String, key: String, on_change := Callable()) -> void:
	_row(box, title).add_child(_switch(key, on_change))


## A switch plus a volume slider; the slider greys out while the switch is off.
static func _toggle_slider(box: VBoxContainer, title: String, on_key: String, volume_key: String, on_change: Callable) -> void:
	var row := _row(box, title)
	var slider := HSlider.new()
	slider.name = "Setting_" + volume_key
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(PlayerData.get(volume_key))
	slider.custom_minimum_size = Vector2(190, 36)
	slider.focus_mode = Control.FOCUS_NONE
	slider.editable = bool(PlayerData.get(on_key))
	slider.modulate.a = 1.0 if slider.editable else 0.45
	var percent := _text("%d%%" % roundi(slider.value * 100.0), 17, MUTED)
	percent.custom_minimum_size.x = 52
	slider.value_changed.connect(func(v):
		percent.text = "%d%%" % roundi(v * 100.0)
		PlayerData.set_setting(volume_key, v)
		on_change.call())
	row.add_child(slider)
	row.add_child(percent)
	var check := _switch(on_key, func():
		slider.editable = bool(PlayerData.get(on_key))
		slider.modulate.a = 1.0 if slider.editable else 0.45
		on_change.call())
	row.add_child(check)


## A small segmented choice, e.g. x1 / x2.
static func _choice(box: VBoxContainer, title: String, key: String, options: Array, on_change := Callable()) -> void:
	var row := _row(box, title)
	var buttons: Array = []
	for option in options:
		var b := Button.new()
		b.name = "Setting_%s_%s" % [key, str(option[0])]
		b.text = option[1]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(72, 46)
		b.button_pressed = PlayerData.get(key) == option[0]
		b.add_theme_font_size_override("font_size", 20)
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			var style := StyleBoxFlat.new()
			var selected: bool = state in ["pressed", "hover_pressed"]
			style.bg_color = Color("ffd23f") if selected else Color("efe2c8")
			style.border_color = INK
			style.set_border_width_all(3)
			style.set_corner_radius_all(10)
			b.add_theme_stylebox_override(state, style)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(state, INK)
		b.add_theme_constant_override("outline_size", 0)
		buttons.append(b)
		row.add_child(b)
	for i in buttons.size():
		var value = options[i][0]
		buttons[i].pressed.connect(func():
			for j in buttons.size():
				buttons[j].set_pressed_no_signal(j == i)
			PlayerData.set_setting(key, value)
			SoundLib.play("click")
			if on_change.is_valid():
				on_change.call())


# --- Sections ------------------------------------------------------------------------------

static func _battle_actions(box: VBoxContainer, battle) -> void:
	_heading(box, "Trận này")
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var resume := Ui.button("Tiếp tục", "Yellow", Vector2(170, 64), 20)
	resume.name = "SettingsResume"
	resume.pressed.connect(func(): UiKit.close_popup(box))
	row.add_child(resume)
	var again := Ui.button("Chơi lại", "Blue", Vector2(160, 64), 20)
	again.name = "SettingsRestart"
	again.pressed.connect(func():
		battle.get_tree().paused = false
		battle.restart())
	row.add_child(again)
	var leave := Ui.button("Rời trận", "Red", Vector2(160, 64), 20)
	leave.name = "SettingsLeave"
	leave.pressed.connect(func():
		battle.get_tree().paused = false
		battle.go_home())
	row.add_child(leave)
	box.add_child(row)
	var note := _text("Rời hoặc chơi lại giữa trận sẽ không nhận thưởng.", 15, MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)


static func _data_section(box: VBoxContainer, host: Control) -> void:
	_heading(box, "Dữ liệu")
	var reset := UiKit.button("XOÁ DỮ LIỆU", Vector2(260, 60), func(): pass, true)
	reset.name = "SettingsReset"
	reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Two taps within a few seconds, so a stray tap can't wipe the save.
	reset.pressed.connect(func():
		if reset.get_meta("armed", false):
			PlayerData.reset_progress()
			UiKit.close_popup(box)
		else:
			reset.set_meta("armed", true)
			reset.text = "CHẠM LẦN NỮA ĐỂ XOÁ"
			host.get_tree().create_timer(3.0).timeout.connect(func():
				if is_instance_valid(reset):
					reset.set_meta("armed", false)
					reset.text = "XOÁ DỮ LIỆU"))
	box.add_child(reset)
	var note := _text("Xoá toàn bộ tiến độ, giữ lại cài đặt.", 15, MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)


static func _text(text: String, size: int, color := INK) -> Label:
	var label := UiKit.ink(text, size)
	label.add_theme_color_override("font_color", color)
	return label
