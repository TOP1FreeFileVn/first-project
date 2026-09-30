extends Node

# Screenshots of the admin panel on a throwaway profile (nothing is saved).
# Run (windowed): Godot --path . res://tests/AdminShots.tscn -- --shot-dir=C:/some/folder

var _home
var _panel
var _dir := ""
var _step := 0
var _wait := 1.0
var _steps: Array = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			_dir = arg.get_slice("=", 1)
	PlayerData.persist = false
	PlayerData._reset()
	_home = load("res://game/menu/Home.tscn").instantiate()
	add_child(_home)
	_steps = [
		func(): _shot("lobby"),
		func(): _panel = _home.open_admin(),
		func(): _shot("formulas"),
		func(): _panel.tab(0)._open("level_cost"),
		func():
			var tab = _panel.tab(0)
			tab._expr.text = "round(40 * pow(1.4, level - 1))"
			tab._refresh(),
		func(): _shot("formula_edit"),
		func():
			var tab = _panel.tab(0)
			tab._expr.text = "level * 2 level"
			tab._refresh(),
		func(): _shot("formula_invalid"),
		func(): _panel.tab(0)._open("troop_multiplier"),
		func(): _shot("formula_series"),
		func(): _panel.select_tab(1),
		func(): _shot("troops"),
		func():
			_panel.tab(1)._selected = "general"
			_panel.tab(1).rebuild(),
		func(): _shot("troops_general"),
		func(): _panel.select_tab(2),
		func(): _shot("castle"),
		func(): _panel.select_tab(3),
		func(): _panel.tab(3)._simulate(),
		func(): _shot("shop"),
		func(): _panel.select_tab(4),
		func(): _shot("level"),
		func(): _panel.select_tab(5),
		func(): _shot("player"),
		func():
			_panel.select_tab(6)
			var sim = _panel.tab(6)
			sim.runs = 2
			sim.speed = 8
			sim._run(),
		"wait_sim",
		func(): _shot("sim"),
		func():
			_panel.select_tab(7)
			_panel.tab(7)._sim_wave = 6
			_panel.tab(7)._simulate(),
		func(): _shot("battle_shop"),
	]


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	if _step >= _steps.size():
		print("AdminShots done, dirty=%s overrides=%s" % [Balance.dirty, Balance.overrides])
		get_tree().quit()
		return
	var step = _steps[_step]
	if step is String:
		if _panel.sim.running:
			return
		_step += 1
		return
	_step += 1
	_wait = 0.5
	step.call()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/admin_%s.png" % [_dir, name])
