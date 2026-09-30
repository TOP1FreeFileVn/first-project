extends VBoxContainer

# Base for admin tabs: build() fills the tab, rebuild() redoes it after data changes.

const UiKit = preload("res://game/ui/UiKit.gd")
const Economy = preload("res://game/core/Economy.gd")
const NumberField = preload("res://game/admin/widgets/NumberField.gd")

var panel


func _init() -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func build() -> void:
	pass


func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	build()


## A dark panel with a heading; returns the box to fill.
func section(title_text: String, parent: Control = self) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.dark_style(10))
	parent.add_child(p)
	var box := UiKit.vbox(8)
	p.add_child(box)
	if title_text != "":
		box.add_child(UiKit.label(title_text, 20, UiKit.GOLD_TEXT))
	return box


func note(text: String, parent: Control = self, color := UiKit.INFO) -> Label:
	var l := UiKit.label(text, 15, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


func number(parent: Control, text: String, value: float, min_value: float, max_value: float, step: float, is_int: bool, changed: bool, on_commit: Callable) -> void:
	var field = NumberField.new()
	field.setup(text, value, min_value, max_value, step, is_int, changed)
	field.committed.connect(on_commit)
	parent.add_child(field)


## A bare number box for dense tables; calls on_commit(value) when edited.
func cell(value: float, on_commit: Callable, width := 110.0, is_int := false) -> LineEdit:
	var edit := LineEdit.new()
	edit.custom_minimum_size = Vector2(width, 40)
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	edit.select_all_on_focus = true
	edit.text = str(int(value)) if is_int else str(snappedf(value, 0.0001))
	var commit := func():
		var text := edit.text.strip_edges().replace(",", ".")
		if not text.is_valid_float():
			edit.text = str(int(value)) if is_int else str(snappedf(value, 0.0001))
			return
		var v := float(text)
		if is_int:
			v = roundf(v)
		if not is_equal_approx(v, value):
			on_commit.call(int(v) if is_int else v)
	edit.text_submitted.connect(func(_t): commit.call())
	edit.focus_exited.connect(commit)
	return edit


func small_button(text: String, on_pressed: Callable, red := false, width := 120.0) -> Button:
	var b := UiKit.button(text, Vector2(width, 48), on_pressed, red)
	b.add_theme_font_size_override("font_size", 16)
	return b


func toast(text: String, color := UiKit.INFO) -> void:
	panel.toast(text, color)
