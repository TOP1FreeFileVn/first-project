extends HBoxContainer

# Label + [−] number [+], clamped to a range. Emits `committed` when the value really
# changes (Enter, leaving the field, or the buttons) so callers can apply it once.

signal committed(value)

const UiKit = preload("res://game/ui/UiKit.gd")

var min_value := 0.0
var max_value := 1e9
var step := 1.0
var is_int := false

var _value := 0.0
var _edit: LineEdit
var _label: Label


## `changed_from_default` highlights the label so edited numbers stand out.
func setup(text: String, value: float, p_min: float, p_max: float, p_step: float, p_int := false, changed_from_default := false, label_width := 300.0) -> HBoxContainer:
	min_value = p_min
	max_value = p_max
	step = p_step
	is_int = p_int
	_value = value
	add_theme_constant_override("separation", 6)
	_label = UiKit.label(text, 16, UiKit.GOLD_TEXT if changed_from_default else Color.WHITE)
	_label.custom_minimum_size.x = label_width
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)
	add_child(UiKit.button("−", Vector2(44, 44), func(): _apply_value(_value - step)))
	_edit = LineEdit.new()
	_edit.custom_minimum_size = Vector2(120, 44)
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	_edit.select_all_on_focus = true
	_edit.text_submitted.connect(func(_t): _commit_text())
	_edit.focus_exited.connect(_commit_text)
	add_child(_edit)
	add_child(UiKit.button("+", Vector2(44, 44), func(): _apply_value(_value + step)))
	_show()
	return self


func _commit_text() -> void:
	var text := _edit.text.strip_edges().replace(",", ".")
	if text.is_valid_float():
		_apply_value(float(text))
	else:
		_show()


func _apply_value(v: float) -> void:
	v = clampf(v, min_value, max_value)
	if is_int:
		v = roundf(v)
	if is_equal_approx(v, _value):
		_show()
		return
	_value = v
	_show()
	committed.emit(int(v) if is_int else v)


func _show() -> void:
	_edit.text = str(int(_value)) if is_int else str(snappedf(_value, 0.0001))
