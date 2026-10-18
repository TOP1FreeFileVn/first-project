extends "res://game/menu/pages/MenuPage.gd"

# Idle gold: a patrol earns gold per real-time hour (more for each level cleared), up to
# 8 hours of storage. Quick patrol pays 2 hours at once, free twice a day.

const STAGE_SIZE := Vector2(620, 200)
const PATROL_UNITS := ["art:giao", "art:kiem", "art:cung", "art:gay_phep"]

var _stored_label: Label
var _stored_bar: ProgressBar
var _full_label: Label
var _claim: Button


func build() -> void:
	title("Tuần tra")
	body.add_child(_stage())

	var info := panel(8)
	var rate := UiKit.hbox(8)
	rate.alignment = BoxContainer.ALIGNMENT_CENTER
	rate.add_child(UiKit.price("gold", roundi(PlayerData.patrol_rate()), 26))
	rate.add_child(UiKit.label("mỗi giờ", 22))
	info.add_child(rate)
	var hint := UiKit.label("Qua thêm màn để tuần tra kiếm nhiều vàng hơn. Kho chứa tối đa %d giờ." % int(Economy.PATROL_MAX_HOURS), 16, UiKit.INFO)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(hint)

	_stored_label = UiKit.label("", 22)
	_stored_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(_stored_label)
	_stored_bar = UiKit.bar(Color("ffd35c"), Vector2(520, 20))
	_stored_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	info.add_child(_stored_bar)
	_full_label = UiKit.label("", 15, UiKit.INFO)
	_full_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(_full_label)

	_claim = UiKit.button("THU HOẠCH", Vector2(360, 84), func(): PlayerData.claim_patrol())
	_claim.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_claim.add_theme_font_size_override("font_size", 28)
	body.add_child(_claim)

	var free_left := PlayerData.quick_patrol_free_left()
	var quick_text := "TUẦN TRA NHANH (%d giờ)\n" % int(Economy.PATROL_QUICK_HOURS)
	quick_text += "Miễn phí %d/%d hôm nay" % [free_left, Economy.PATROL_QUICK_FREE] if free_left > 0 else "◆ %d kim cương" % Economy.PATROL_QUICK_GEMS
	var quick := UiKit.button(quick_text, Vector2(420, 90), func(): PlayerData.quick_patrol(), true)
	quick.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quick.disabled = not PlayerData.can_quick_patrol()
	body.add_child(quick)
	tick()


func tick() -> void:
	if _stored_label == null or not is_instance_valid(_stored_label):
		return
	var stored := PlayerData.patrol_stored()
	var capacity := PlayerData.patrol_capacity()
	_stored_label.text = "Kho: %s / %s vàng" % [UiKit.format_number(stored), UiKit.format_number(capacity)]
	_stored_bar.max_value = capacity
	_stored_bar.value = stored
	var seconds_to_full := ceili((capacity - stored) / PlayerData.patrol_rate() * 3600.0)
	_full_label.text = "Kho đã đầy, hãy thu hoạch!" if stored >= capacity else "Đầy sau " + UiKit.format_time(seconds_to_full)
	_claim.disabled = stored <= 0


func has_alert() -> bool:
	return PlayerData.patrol_alert()


# A strip of grass with a few blue troops running back and forth.
func _stage() -> Control:
	var stage := Panel.new()
	stage.custom_minimum_size = STAGE_SIZE
	stage.clip_contents = true
	var style := UiKit.dark_style(12)
	style.bg_color = Color("5e8a3a")
	stage.add_theme_stylebox_override("panel", style)
	for i in PATROL_UNITS.size():
		var unit := AnimatedSprite2D.new()
		var key: String = PATROL_UNITS[i]
		unit.sprite_frames = SpriteLib.unit_frames(key, "Blue")
		unit.offset = Vector2(0, -SpriteLib.foot_offset(key))
		unit.scale = Vector2(0.55, 0.55)
		var y := 70.0 + (i % 2) * 70.0
		var left := 60.0 + i * 20.0
		var right := STAGE_SIZE.x - 60.0 - (3 - i) * 20.0
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
	return stage
