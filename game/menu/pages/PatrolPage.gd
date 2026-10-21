extends "res://game/menu/pages/MenuPage.gd"

# Idle gold: a patrol earns gold per real-time hour (more for each level cleared), up to
# 8 hours of storage. Quick patrol pays 2 hours at once, free twice a day.

const STAGE_SIZE := Vector2(620, 170)
const PATROL_UNITS := ["art:giao", "art:kiem", "art:cung", "art:gay_phep"]

var _stored_label: Label
var _stored_bar: ProgressBar
var _full_label: Label
var _claim: Button


func build() -> void:
	body.add_theme_constant_override("separation", 28)
	body.add_child(_stage())

	var info := section("Kho vàng", 14)
	_stored_label = UiKit.ink("", 52)
	_stored_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(_stored_label)
	var rate := UiKit.hbox(8)
	rate.alignment = BoxContainer.ALIGNMENT_CENTER
	rate.add_child(UiKit.price("gold", roundi(PlayerData.patrol_rate()), 22, true))
	rate.add_child(UiKit.ink("vàng / giờ", 22))
	info.add_child(rate)
	_stored_bar = UiKit.bar(Color("ffd35c"), Vector2(0, 24))
	_stored_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(_stored_bar)
	var timing := UiKit.hbox(12)
	_full_label = UiKit.ink("", 21)
	_full_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_full_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	timing.add_child(_full_label)
	timing.add_child(UiKit.ink("Tối đa %d giờ" % int(Economy.PATROL_MAX_HOURS), 21))
	info.add_child(timing)
	info.add_child(UiKit.gap(0, 8))

	_claim = UiKit.button("THU HOẠCH", Vector2(360, 84), func(): PlayerData.claim_patrol())
	_claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_claim.add_theme_font_size_override("font_size", 28)
	info.add_child(_claim)

	var free_left := PlayerData.quick_patrol_free_left()
	var quick_row := UiKit.hbox(16)
	var quick_info := UiKit.vbox(4)
	quick_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quick_info.add_child(UiKit.ink("Tuần tra nhanh", 24))
	quick_info.add_child(UiKit.ink("Nhận ngay %d giờ tích lũy" % int(Economy.PATROL_QUICK_HOURS), 20))
	quick_row.add_child(quick_info)
	var quick_text := "Miễn phí %d/%d" % [free_left, Economy.PATROL_QUICK_FREE] if free_left > 0 else "◆ %d" % Economy.PATROL_QUICK_GEMS
	var quick := UiKit.button(quick_text, Vector2(228, 76), func(): PlayerData.quick_patrol(), true)
	quick.add_theme_font_size_override("font_size", 20)
	quick.disabled = not PlayerData.can_quick_patrol()
	quick_row.add_child(quick)
	body.add_child(quick_row)
	tick()


func tick() -> void:
	if _stored_label == null or not is_instance_valid(_stored_label):
		return
	var stored := PlayerData.patrol_stored()
	var capacity := PlayerData.patrol_capacity()
	_stored_label.text = "%s / %s" % [UiKit.format_number(stored), UiKit.format_number(capacity)]
	_stored_bar.max_value = capacity
	_stored_bar.value = stored
	var seconds_to_full := ceili((capacity - stored) / PlayerData.patrol_rate() * 3600.0)
	_full_label.text = "Kho đã đầy, hãy thu hoạch!" if stored >= capacity else "Đầy sau " + UiKit.format_time(seconds_to_full)
	_claim.disabled = stored <= 0


func has_alert() -> bool:
	return PlayerData.patrol_alert()


# A strip of grass with a few blue troops running back and forth.
func _stage() -> Control:
	var card := PanelContainer.new()
	var style := UiKit.Ui.menu_panel_style("patrol")
	style.texture = load("res://game/ui/skin/menu/patrol_scene.svg")
	style.set_content_margin_all(18)
	card.add_theme_stylebox_override("panel", style)
	var column := UiKit.vbox(4)
	card.add_child(column)
	column.add_child(UiKit.ink("Tuần tra", 34))
	var stage := Control.new()
	stage.custom_minimum_size = STAGE_SIZE
	stage.clip_contents = true
	column.add_child(stage)
	for i in PATROL_UNITS.size():
		var unit := AnimatedSprite2D.new()
		var key: String = PATROL_UNITS[i]
		unit.sprite_frames = SpriteLib.unit_frames(key, "Blue")
		unit.offset = Vector2(0, -SpriteLib.foot_offset(key))
		unit.scale = Vector2(0.85, 0.85)
		var y := 116.0 + (i % 2) * 30.0
		var left := 72.0 + i * 20.0
		var right := STAGE_SIZE.x - 72.0 - (3 - i) * 20.0
		unit.position = Vector2(lerpf(left, right, i / 3.0), y)
		unit.play("run")
		stage.add_child(unit)
		var duration := 3.5 + i * 0.6
		var tween := unit.create_tween().set_loops()
		tween.tween_callback(func(): unit.flip_h = false)
		tween.tween_property(unit, "position:x", right, duration * (right - unit.position.x) / (right - left) + 0.01)
		tween.tween_callback(func(): unit.flip_h = true)
		tween.tween_property(unit, "position:x", left, duration)
		tween.tween_callback(func(): unit.flip_h = false)
		tween.tween_property(unit, "position:x", right, duration)
	return card
