extends Node

# Single source of every balance number and formula. Defaults ship in balance.json and
# the troop/level .tres files; the admin panel writes a sparse override file on top.
# Game code asks Balance (usually through Economy) instead of hard-coding numbers.

signal changed

const FormulaEngine = preload("res://game/core/FormulaEngine.gd")
const Content = preload("res://game/core/Content.gd")
const Economy = preload("res://game/core/Economy.gd")

const DEFAULTS_PATH := "res://game/data/balance.json"
const OVERRIDE_PATH := "user://balance_override.json"
const HISTORY_PATH := "user://balance_history.json"
const TROOP_PROPS := ["max_hp", "damage", "attack_range", "attack_cooldown", "move_speed", "crit_chance", "crit_mult", "aggro_range", "spawn_interval", "max_alive", "summon_weight", "rarity", "ability_value", "ability_duration", "ability_cooldown", "ability_radius"]
const LEVEL_PROPS := ["display_name", "core_hp", "enemy_power", "start_meat", "prep_time", "waves"]
const MAX_UNDO := 50
const MAX_HISTORY := 20

var defaults := {}
var overrides := {}
## Unsaved changes since the last save().
var dirty := false
## Formulas that failed at runtime and fell back to their default: fname -> message.
var runtime_errors := {}

var _compiled := {}
var _undo: Array = []
var _troop_defaults := {}
var _level_defaults := {}
# Strong references: without them Godot drops the cached resources and the next load()
# would return a fresh copy from disk, without the overrides applied.
var _troops := {}
var _levels := {}


func _ready() -> void:
	defaults = load(DEFAULTS_PATH).data.duplicate(true)
	for id in Content.ALL_TROOPS:
		var troop: Resource = load(Content.TROOP_PATH % id)
		_troops[id] = troop
		var snapshot := {}
		for prop in TROOP_PROPS:
			snapshot[prop] = troop.get(prop)
		_troop_defaults[id] = snapshot
	for i in Content.LEVELS.size():
		var level: Resource = load(Content.LEVELS[i])
		_levels[i] = level
		var snapshot := {}
		for prop in LEVEL_PROPS:
			snapshot[prop] = _copy(level.get(prop))
		_level_defaults[i] = snapshot
	if FileAccess.file_exists(OVERRIDE_PATH):
		var saved = JSON.parse_string(FileAccess.get_file_as_string(OVERRIDE_PATH))
		if saved is Dictionary:
			overrides = _drop_stale(saved)
	_rebuild()

## An admin override saved against an older balance.json can miss keys the game now
## reads (e.g. chests that used to hold cards and now hold "items"). Such a section falls
## back to the shipped one instead of crashing the screen that reads it.
func _drop_stale(saved: Dictionary) -> Dictionary:
	for key in ["chests", "castle", "workshop", "battle_shop"]:
		if not saved.has(key) or not defaults.has(key):
			continue
		if not _same_shape(saved[key], defaults[key]):
			push_warning("Balance: ignoring the saved '%s' override; it predates the current data layout." % key)
			saved.erase(key)
	return saved

static func _same_shape(a, b) -> bool:
	if b is Dictionary:
		if not a is Dictionary:
			return false
		for k in b:
			if not a.has(k) or not _same_shape(a[k], b[k]):
				return false
		return true
	if b is Array:
		return a is Array and (b.is_empty() or a.is_empty() or _same_shape(a[0], b[0]))
	return true


# --- Reading ---------------------------------------------------------------------------

func formula(fname: String, inputs: Dictionary) -> float:
	var def: Dictionary = defaults["formulas"][fname]
	var e = _compiled.get(fname)
	if e != null:
		var result := FormulaEngine.run(e, def["vars"], inputs)
		if result[1] == "":
			return result[0]
		runtime_errors[fname] = result[1]
	# Broken override: fall back to the shipped formula.
	var fallback := FormulaEngine.compile(def["expr"], def["vars"])
	return FormulaEngine.run(fallback[0], def["vars"], inputs)[0]


func formula_int(fname: String, inputs: Dictionary) -> int:
	return roundi(formula(fname, inputs))


func formula_names() -> Array:
	return defaults["formulas"].keys()


func formula_meta(fname: String) -> Dictionary:
	return defaults["formulas"][fname]


func formula_expr(fname: String) -> String:
	return overrides.get("formulas", {}).get(fname, defaults["formulas"][fname]["expr"])


func is_formula_changed(fname: String) -> bool:
	return overrides.get("formulas", {}).has(fname)


func value(key: String):
	return overrides.get("values", {}).get(key, defaults["values"][key]["value"])


func value_keys() -> Array:
	return defaults["values"].keys()


func value_meta(key: String) -> Dictionary:
	return defaults["values"][key]


## Whole sections: "star_card_cost", "rarity_weights", "castle", "workshop", "chests",
## "battle_shop".
func section(key: String):
	return overrides.get(key, defaults[key])


func troop_default(id: String, prop: String):
	return _troop_defaults[id][prop]


func level_default(index: int, prop: String):
	return _level_defaults[index][prop]


# --- Validation ------------------------------------------------------------------------

## "" if `expr` is safe and gives valid numbers across the preview range, else the reason.
func validate_formula(fname: String, expr: String) -> String:
	var def: Dictionary = defaults["formulas"][fname]
	var compiled := FormulaEngine.compile(expr, def["vars"])
	if compiled[0] == null:
		return compiled[1]
	for inputs in preview_inputs(fname):
		var result := FormulaEngine.run(compiled[0], def["vars"], inputs)
		if result[1] != "":
			return "%s (với %s)" % [result[1], _describe(inputs)]
		if def.has("min") and result[0] < def["min"]:
			return "Ra %s < tối thiểu %s (với %s)" % [_num(result[0]), _num(def["min"]), _describe(inputs)]
		if def.has("max") and result[0] > def["max"]:
			return "Ra %s > tối đa %s (với %s)" % [_num(result[0]), _num(def["max"]), _describe(inputs)]
	return ""


## Every input combination on the formula's preview grid.
func preview_inputs(fname: String) -> Array:
	var def: Dictionary = defaults["formulas"][fname]
	var preview: Dictionary = def["preview"]
	var base := {}
	for v in def["vars"]:
		base[v] = preview.get("samples", {}).get(v, 1.0)
	var series_values: Array = preview.get("series_values", [null])
	var out := []
	for s in series_values:
		var x: float = preview["from"]
		while x <= preview["to"] + 0.0001:
			var inputs := base.duplicate()
			inputs[preview["x"]] = x
			if s != null:
				inputs[preview["series"]] = s
			out.append(inputs)
			x += preview["step"]
	return out


## Evaluate an arbitrary expression (for previews of unsaved edits).
func evaluate(fname: String, expr: String, inputs: Dictionary) -> Array:
	var def: Dictionary = defaults["formulas"][fname]
	var compiled := FormulaEngine.compile(expr, def["vars"])
	if compiled[0] == null:
		return [0.0, compiled[1]]
	return FormulaEngine.run(compiled[0], def["vars"], inputs)


# --- Editing ---------------------------------------------------------------------------

func set_formula(fname: String, expr: String) -> String:
	var problem := validate_formula(fname, expr)
	if problem != "":
		return problem
	_edit(func():
		var formulas: Dictionary = overrides.get_or_add("formulas", {})
		if expr == defaults["formulas"][fname]["expr"]:
			formulas.erase(fname)
		else:
			formulas[fname] = expr)
	return ""


func reset_formula(fname: String) -> void:
	_edit(func(): overrides.get("formulas", {}).erase(fname))


func set_value(key: String, v) -> void:
	_edit(func():
		var values: Dictionary = overrides.get_or_add("values", {})
		if v == defaults["values"][key]["value"]:
			values.erase(key)
		else:
			values[key] = v)


func set_section(key: String, data) -> void:
	_edit(func():
		if data == defaults[key]:
			overrides.erase(key)
		else:
			overrides[key] = _copy(data))


func set_troop_stat(id: String, prop: String, v) -> void:
	_edit(func():
		var troops: Dictionary = overrides.get_or_add("troops", {})
		var entry: Dictionary = troops.get_or_add(id, {})
		if v == _troop_defaults[id][prop]:
			entry.erase(prop)
		else:
			entry[prop] = v
		if entry.is_empty():
			troops.erase(id))


func set_level_prop(index: int, prop: String, v) -> void:
	_edit(func():
		var levels: Dictionary = overrides.get_or_add("levels", {})
		var entry: Dictionary = levels.get_or_add(str(index), {})
		if v == _level_defaults[index][prop]:
			entry.erase(prop)
		else:
			entry[prop] = _copy(v)
		if entry.is_empty():
			levels.erase(str(index)))


func reset_all() -> void:
	_edit(func(): overrides = {})


func can_undo() -> bool:
	return not _undo.is_empty()


func undo() -> void:
	if _undo.is_empty():
		return
	overrides = _undo.pop_back()
	dirty = true
	_rebuild()


## Drops unsaved edits: back to what is in the override file.
func revert_to_saved() -> void:
	overrides = {}
	if FileAccess.file_exists(OVERRIDE_PATH):
		var saved = JSON.parse_string(FileAccess.get_file_as_string(OVERRIDE_PATH))
		if saved is Dictionary:
			overrides = _drop_stale(saved)
	_undo.clear()
	dirty = false
	_rebuild()


func change_count() -> int:
	var count := 0
	for key in overrides:
		count += overrides[key].size() if overrides[key] is Dictionary else 1
	return count


# --- Save, history, import/export ------------------------------------------------------

func save(note := "") -> void:
	_write_json(OVERRIDE_PATH, overrides)
	var history := load_history()
	history.push_front({"time": Time.get_datetime_string_from_system(false, true), "note": note, "overrides": overrides.duplicate(true)})
	_write_json(HISTORY_PATH, history.slice(0, MAX_HISTORY))
	dirty = false
	changed.emit()


func load_history() -> Array:
	if not FileAccess.file_exists(HISTORY_PATH):
		return []
	var data = JSON.parse_string(FileAccess.get_file_as_string(HISTORY_PATH))
	return data if data is Array else []


func restore_history(entry: Dictionary) -> void:
	_edit(func(): overrides = entry["overrides"].duplicate(true))


func export_json() -> String:
	return JSON.stringify({"gear_defenders_balance": 1, "overrides": overrides}, "\t")


## Returns "" on success. Every formula inside is validated before anything changes.
func import_json(text: String) -> String:
	var data = JSON.parse_string(text)
	if not data is Dictionary or not data.has("overrides") or not data["overrides"] is Dictionary:
		return "Không đọc được: cần JSON xuất từ bảng admin."
	var incoming: Dictionary = data["overrides"]
	for fname in incoming.get("formulas", {}):
		if not defaults["formulas"].has(fname):
			return "Công thức không tồn tại: %s" % fname
		var problem := validate_formula(fname, incoming["formulas"][fname])
		if problem != "":
			return "%s: %s" % [fname, problem]
	for key in incoming.get("values", {}):
		if not defaults["values"].has(key):
			return "Hằng số không tồn tại: %s" % key
	_edit(func(): overrides = incoming.duplicate(true))
	return ""


func can_write_to_build() -> bool:
	return OS.has_feature("editor")


## Bakes the current numbers into balance.json and the .tres files (editor runs only),
## then clears the overrides since they are now the defaults.
func write_to_build() -> String:
	if not can_write_to_build():
		return "Chỉ ghi được khi chạy từ Godot editor trên máy tính."
	var baked: Dictionary = defaults.duplicate(true)
	for fname in overrides.get("formulas", {}):
		baked["formulas"][fname]["expr"] = overrides["formulas"][fname]
	for key in overrides.get("values", {}):
		baked["values"][key]["value"] = overrides["values"][key]
	for key in ["star_card_cost", "rarity_weights", "castle", "workshop", "chests", "battle_shop"]:
		if overrides.has(key):
			baked[key] = overrides[key]
	_write_json(ProjectSettings.globalize_path(DEFAULTS_PATH), baked)
	for id in _troop_defaults:
		ResourceSaver.save(load(Content.TROOP_PATH % id))
	for i in _level_defaults:
		ResourceSaver.save(load(Content.LEVELS[i]))
	defaults = baked
	for id in _troop_defaults:
		for prop in TROOP_PROPS:
			_troop_defaults[id][prop] = load(Content.TROOP_PATH % id).get(prop)
	for i in _level_defaults:
		for prop in LEVEL_PROPS:
			_level_defaults[i][prop] = _copy(load(Content.LEVELS[i]).get(prop))
	overrides = {}
	save("Ghi vào bản build")
	_rebuild()
	return ""


# --- Internals -------------------------------------------------------------------------

func _edit(change: Callable) -> void:
	_undo.append(overrides.duplicate(true))
	if _undo.size() > MAX_UNDO:
		_undo.pop_front()
	change.call()
	dirty = true
	_rebuild()


# Recompile formulas and push troop/level overrides into the shared resources.
func _rebuild() -> void:
	_compiled.clear()
	runtime_errors.clear()
	for fname in defaults["formulas"]:
		var compiled := FormulaEngine.compile(formula_expr(fname), defaults["formulas"][fname]["vars"])
		if compiled[0] == null:
			runtime_errors[fname] = compiled[1]
			compiled = FormulaEngine.compile(defaults["formulas"][fname]["expr"], defaults["formulas"][fname]["vars"])
		_compiled[fname] = compiled[0]
	var troop_overrides: Dictionary = overrides.get("troops", {})
	for id in _troop_defaults:
		var troop: Resource = _troops[id]
		for prop in TROOP_PROPS:
			troop.set(prop, troop_overrides.get(id, {}).get(prop, _troop_defaults[id][prop]))
	var level_overrides: Dictionary = overrides.get("levels", {})
	for i in _level_defaults:
		var level: Resource = _levels[i]
		for prop in LEVEL_PROPS:
			level.set(prop, _copy(level_overrides.get(str(i), {}).get(prop, _level_defaults[i][prop])))
	Economy.refresh(self)
	changed.emit()


func _write_json(path: String, data) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write %s: %s" % [path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data, "\t"))


static func _copy(v):
	return v.duplicate(true) if v is Array or v is Dictionary else v


static func _num(v) -> String:
	return str(snappedf(float(v), 0.001))


func _describe(inputs: Dictionary) -> String:
	var parts := []
	for k in inputs:
		parts.append("%s=%s" % [k, _num(inputs[k])])
	return ", ".join(parts)
