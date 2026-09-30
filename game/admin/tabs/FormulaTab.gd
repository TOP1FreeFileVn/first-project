extends "res://game/admin/tabs/AdminTab.gd"

# Formula list + editor, and every loose constant. The editor validates as you type,
# evaluates any input you try, and compares old vs new on a chart and a table before
# anything is applied.

const LineChart = preload("res://game/admin/widgets/LineChart.gd")
const SERIES_COLORS := [Color("7fd66b"), Color("5aa9e6"), Color("ffd35c"), Color("ff8a7a")]
const MAX_TABLE_ROWS := 16

var _editing := ""
var _expr: LineEdit
var _status: Label
var _apply: Button
var _chart
var _table: GridContainer
var _summary: Label
var _quick_inputs := {}
var _quick_result: Label


func build() -> void:
	if _editing == "":
		_build_list()
	else:
		_build_editor(_editing)


# --- List ---------------------------------------------------------------------------------

func _build_list() -> void:
	note("Bấm vào một công thức để sửa, thử giá trị và so sánh cũ/mới. Màu vàng = đã khác mặc định.")
	var list := section("Công thức (%d)" % Balance.formula_names().size())
	for fname in Balance.formula_names():
		var meta: Dictionary = Balance.formula_meta(fname)
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.custom_minimum_size = Vector2(0, 84)
		var style := UiKit.dark_style(8, Color("c9a14a") if Balance.is_formula_changed(fname) else Color("2d4a52"))
		row.add_theme_stylebox_override("normal", style)
		row.add_theme_stylebox_override("hover", style)
		row.add_theme_stylebox_override("pressed", style)
		row.pressed.connect(_open.bind(fname))
		var column := UiKit.vbox(2)
		column.set_anchors_preset(Control.PRESET_FULL_RECT)
		column.offset_left = 12
		column.offset_right = -12
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(column)
		var heading: String = meta["label"]
		if Balance.runtime_errors.has(fname):
			heading += "   ⚠ LỖI"
		column.add_child(UiKit.label(heading, 18, UiKit.WARN if Balance.runtime_errors.has(fname) else (UiKit.GOLD_TEXT if Balance.is_formula_changed(fname) else Color.WHITE)))
		var expr_label := UiKit.label(Balance.formula_expr(fname), 15, UiKit.INFO)
		expr_label.clip_text = true
		column.add_child(expr_label)
		list.add_child(row)

	var values := section("Hằng số")
	note("Số lẻ không nằm trong công thức. Sửa xong bấm Enter hoặc chạm ra ngoài.", values)
	for key in Balance.value_keys():
		var meta: Dictionary = Balance.value_meta(key)
		var current = Balance.value(key)
		var is_int: bool = float(meta["step"]) >= 1.0 and is_equal_approx(float(meta["value"]), roundf(float(meta["value"])))
		number(values, meta["label"], float(current), meta["min"], meta["max"], meta["step"], is_int,
			current != meta["value"], func(v): Balance.set_value(key, v))


func _open(fname: String) -> void:
	_editing = fname
	rebuild()


# --- Editor -------------------------------------------------------------------------------

func _build_editor(fname: String) -> void:
	var meta: Dictionary = Balance.formula_meta(fname)
	add_child(small_button("◀ Danh sách", func():
		_editing = ""
		rebuild(), false, 170))
	var head := section(meta["label"])
	note("Dùng ở: " + meta["used_in"], head)
	note("Biến: " + ", ".join(_describe_vars(fname)), head)
	note("Mặc định: " + meta["expr"], head, Color(1, 1, 1, 0.6))
	if Balance.runtime_errors.has(fname):
		note("⚠ Đang lỗi khi chạy, game tạm dùng công thức mặc định: " + Balance.runtime_errors[fname], head, UiKit.WARN)

	_expr = LineEdit.new()
	_expr.custom_minimum_size = Vector2(0, 56)
	_expr.add_theme_font_size_override("font_size", 20)
	_expr.text = Balance.formula_expr(fname)
	_expr.text_changed.connect(func(_t): _refresh())
	head.add_child(_expr)

	var inserts := HFlowContainer.new()
	inserts.add_theme_constant_override("h_separation", 6)
	inserts.add_theme_constant_override("v_separation", 6)
	for v in meta["vars"]:
		inserts.add_child(_insert_button(v, v))
	for f in ["pow", "floor", "round", "min", "max", "clamp", "int"]:
		inserts.add_child(_insert_button(f + "(", f))
	for op in ["+", "-", "*", "/", "(", ")", ">=", "and"]:
		inserts.add_child(_insert_button(" %s " % op if op.length() > 1 or op in ["+", "-", "*", "/"] else op, op))
	head.add_child(inserts)
	_status = UiKit.label("", 16)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(_status)

	var quick := section("Thử nhanh")
	var inputs_row := HFlowContainer.new()
	inputs_row.add_theme_constant_override("h_separation", 12)
	_quick_inputs.clear()
	var sample := _sample_inputs(fname)
	for v in meta["vars"]:
		var pair := UiKit.hbox(4)
		pair.add_child(UiKit.label(v + " =", 17))
		var edit := LineEdit.new()
		edit.custom_minimum_size = Vector2(100, 44)
		edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
		edit.text = str(sample[v])
		edit.text_changed.connect(func(_t): _refresh_quick())
		pair.add_child(edit)
		inputs_row.add_child(pair)
		_quick_inputs[v] = edit
	quick.add_child(inputs_row)
	_quick_result = UiKit.label("", 22, UiKit.GOLD_TEXT)
	quick.add_child(_quick_result)

	var preview := section("So sánh trên dải (nét liền = mới, nét đứt = đang dùng)")
	_chart = LineChart.new()
	preview.add_child(_chart)
	_summary = UiKit.label("", 16, UiKit.INFO)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview.add_child(_summary)
	_table = GridContainer.new()
	_table.add_theme_constant_override("h_separation", 18)
	preview.add_child(_table)

	var actions := UiKit.hbox(8)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_child(small_button("MẶC ĐỊNH", func():
		_expr.text = meta["expr"]
		_refresh(), true, 150))
	actions.add_child(small_button("HUỶ SỬA", func():
		_expr.text = Balance.formula_expr(fname)
		_refresh(), false, 150))
	_apply = small_button("ÁP DỤNG", _apply_edit, false, 200)
	actions.add_child(_apply)
	add_child(actions)
	_refresh()


func _insert_button(text: String, label_text: String) -> Button:
	var b := UiKit.button(label_text, Vector2(0, 42), func():
		_expr.insert_text_at_caret(text)
		_expr.grab_focus()
		_refresh())
	b.add_theme_font_size_override("font_size", 15)
	return b


func _apply_edit() -> void:
	var problem := Balance.set_formula(_editing, _expr.text.strip_edges())
	if problem != "":
		toast(problem, UiKit.WARN)
	else:
		toast("Đã áp dụng. Game dùng công thức mới ngay (bấm LƯU để giữ).")


func _refresh() -> void:
	var fname := _editing
	var text := _expr.text.strip_edges()
	var current := Balance.formula_expr(fname)
	var problem := Balance.validate_formula(fname, text)
	if problem == "":
		_status.text = "✔ Hợp lệ" + ("" if text != current else " (đang dùng)")
		_status.add_theme_color_override("font_color", Color("7fd66b"))
	else:
		_status.text = "✘ " + problem
		_status.add_theme_color_override("font_color", UiKit.WARN)
	_apply.disabled = problem != "" or text == current
	_refresh_quick()
	_refresh_preview(problem == "")


func _refresh_quick() -> void:
	var fname := _editing
	var inputs := {}
	for v in _quick_inputs:
		var raw: String = _quick_inputs[v].text.strip_edges().replace(",", ".")
		if not raw.is_valid_float():
			_quick_result.text = "Nhập số cho %s" % v
			return
		inputs[v] = float(raw)
	var old := Balance.evaluate(fname, Balance.formula_expr(fname), inputs)
	var fresh := Balance.evaluate(fname, _expr.text.strip_edges(), inputs)
	if fresh[1] != "":
		_quick_result.text = "→ lỗi: %s   (đang dùng: %s)" % [fresh[1], _fmt(old[0])]
	else:
		_quick_result.text = "→ %s   (đang dùng: %s)" % [_fmt(fresh[0]), _fmt(old[0])]


func _refresh_preview(new_valid: bool) -> void:
	var fname := _editing
	var meta: Dictionary = Balance.formula_meta(fname)
	var preview: Dictionary = meta["preview"]
	var x_var: String = preview["x"]
	var series_var: String = preview.get("series", "")
	var series_values: Array = preview.get("series_values", [null])
	var old_expr := Balance.formula_expr(fname)
	var new_expr := _expr.text.strip_edges()

	# rows[x] = [[old, new] per series]
	var chart := []
	var rows := {}
	var sums := [0.0, 0.0]
	for si in series_values.size():
		var old_points := []
		var new_points := []
		for inputs in Balance.preview_inputs(fname):
			if series_var != "" and not is_equal_approx(float(inputs[series_var]), float(series_values[si])):
				continue
			var x: float = inputs[x_var]
			var old: float = Balance.evaluate(fname, old_expr, inputs)[0]
			var fresh: float = Balance.evaluate(fname, new_expr, inputs)[0] if new_valid else NAN
			old_points.append(Vector2(x, old))
			if new_valid:
				new_points.append(Vector2(x, fresh))
			if not rows.has(x):
				rows[x] = []
			rows[x].append([old, fresh])
			if si == 0:
				sums[0] += old
				sums[1] += fresh if new_valid else 0.0
		var color: Color = SERIES_COLORS[si % SERIES_COLORS.size()]
		var tag := "" if series_var == "" else "%s=%s" % [series_var, series_values[si]]
		chart.append({"points": old_points, "color": color.darkened(0.35), "dashed": true, "label": tag})
		if new_valid:
			chart.append({"points": new_points, "color": color, "dashed": false, "label": tag})
	_chart.set_series(chart, x_var)

	if new_valid:
		var delta := "" if is_zero_approx(sums[0]) else " (%+.1f%%)" % ((sums[1] - sums[0]) / absf(sums[0]) * 100.0)
		_summary.text = "Tổng trên dải%s: đang dùng %s → mới %s%s" % [
			"" if series_var == "" else " (%s=%s)" % [series_var, series_values[0]], _fmt(sums[0]), _fmt(sums[1]), delta]
	else:
		_summary.text = "Sửa công thức cho hợp lệ để xem giá trị mới."

	for child in _table.get_children():
		_table.remove_child(child)
		child.queue_free()
	_table.columns = 1 + series_values.size()
	_table.add_child(UiKit.label(x_var, 15, UiKit.GOLD_TEXT))
	for s in series_values:
		_table.add_child(UiKit.label("giá trị" if s == null else "%s=%s" % [series_var, s], 15, UiKit.GOLD_TEXT))
	var xs := rows.keys()
	xs.sort()
	var stride := maxi(1, ceili(xs.size() / float(MAX_TABLE_ROWS)))
	for i in range(0, xs.size(), stride):
		var x = xs[i]
		_table.add_child(UiKit.label(_fmt(x), 15))
		for pair in rows[x]:
			var text := _fmt(pair[0])
			if new_valid and not is_equal_approx(pair[0], pair[1]):
				text += " → " + _fmt(pair[1])
			_table.add_child(UiKit.label(text, 15, Color.WHITE if not new_valid or is_equal_approx(pair[0], pair[1]) else UiKit.GOLD_TEXT))


func _sample_inputs(fname: String) -> Dictionary:
	var meta: Dictionary = Balance.formula_meta(fname)
	var preview: Dictionary = meta["preview"]
	var out := {}
	for v in meta["vars"]:
		out[v] = preview.get("samples", {}).get(v, 1)
	out[preview["x"]] = preview["from"]
	if preview.has("series"):
		out[preview["series"]] = preview["series_values"][0]
	return out


func _describe_vars(fname: String) -> Array:
	var meta: Dictionary = Balance.formula_meta(fname)
	var preview: Dictionary = meta["preview"]
	var parts := []
	for v in meta["vars"]:
		if v == preview["x"]:
			parts.append("%s (%s–%s)" % [v, preview["from"], preview["to"]])
		elif v == preview.get("series", ""):
			parts.append("%s (%s)" % [v, ", ".join(preview["series_values"].map(func(s): return str(s)))])
		else:
			parts.append("%s (mẫu %s)" % [v, preview.get("samples", {}).get(v, 1)])
	return parts


static func _fmt(v) -> String:
	var f := float(v)
	if is_nan(f):
		return "—"
	if absf(f - roundf(f)) < 0.0001:
		return str(int(roundf(f)))
	return str(snappedf(f, 0.001))
