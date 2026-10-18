extends Node

# Run in the review client's isolated APPDATA/LOCALAPPDATA profile, headless.
# Exercises the production spawn caller and movement bound, including wall attacks.
const TroopData = preload("res://game/data/TroopData.gd")
var _battle
var _checks := 0
var _failed := 0


func _ready() -> void:
	print("DEPLOYMENT_TEST_USER_DIR ", OS.get_user_data_dir())
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.tutorial_done = true
	_battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(_battle)
	_battle.board.set_process(false)
	_battle.fish_cap = 1000
	var hero = _battle.player_units[0]
	_check(hero.position.y < _battle.WALL_Y and hero.rally.y < _battle.WALL_Y,
		"hero deploys and rallies above the wall")
	var sources := [Vector2(110, 780), Vector2(-200, 1280), Vector2(900, 1500), Vector2(360, 520)]
	for role in [TroopData.Role.MELEE, TroopData.Role.RANGED, TroopData.Role.HEALER, TroopData.Role.SUPPORT]:
		for source in sources:
			var troop: Resource = PlayerData.TROOPS["kiem"].duplicate()
			troop.role = role
			var unit = _battle.spawn_player_unit(troop, 1, source)
			if unit == null:
				_check(false, "role %d spawned from %s" % [role, source])
				continue
			_check(_on_field(unit.position) and _on_field(unit.rally),
				"role %d spawn and rally stay above wall from %s" % [role, source])
			if source == Vector2(360, 520):
				_check(unit.position.is_equal_approx(source), "valid field source is preserved for role %d" % role)
			elif source.x == 110:
				_check(is_equal_approx(unit.position.x, source.x), "gear column is preserved for role %d" % role)
	# The actual gear caller passes a point in the board, not a field position.
	var gear = _battle.board.gears.values().filter(func(g): return not g.is_skill())[0]
	gear.powered = true
	var before: int = _battle.player_units.size()
	gear.produce(gear.spawn_interval() + 0.01, _battle)
	_check(_battle.player_units.size() == before + 1 and _on_field(_battle.player_units.back().position),
		"gear production deploys a real soldier on the battlefield")
	# Simulate a crowd shove below the wall through the real unit boundary code.
	var displaced = _battle.player_units.back()
	displaced.position.y = 900
	displaced._separate(1.0 / 60.0)
	_check(displaced.position.y <= _battle.WALL_Y, "movement bound prevents drift onto the gear board")
	for unit in _battle.player_units:
		unit.queue_free()
	_battle.player_units.clear()
	await get_tree().process_frame
	# Lowest-range enemy attacker: the new lower field edge must still allow wall damage.
	_battle.phase = "fight"
	_battle._spawn_enemy("assassin", false)
	var attacker = _battle.enemy_units.back()
	attacker.position = Vector2(360, _battle.WALL_Y + 40)
	attacker._separate(1.0 / 60.0)
	var hp_before: float = _battle.core.hp
	await get_tree().create_timer(1.2).timeout
	_check(attacker.position.y <= _battle.WALL_Y, "enemy attacker stays above the gear board")
	_check(_battle.core.hp < hp_before, "enemy can damage the castle from the new movement boundary")
	print("DeploymentTest: %d checks, %d failed" % [_checks, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _on_field(point: Vector2) -> bool:
	return point.x >= _battle.FIELD_LEFT and point.x <= _battle.FIELD_RIGHT \
		and point.y >= _battle.FIELD_TOP and point.y < _battle.WALL_Y


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
	print(("PASS: " if ok else "FAIL: ") + what)
