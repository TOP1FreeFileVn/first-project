extends Node

# Headless balance check: a bot summons whenever it can, merges every matching pair
# through the real drag/drop code, and prints how the level goes.
# Run: Godot --headless --fixed-fps 60 --path . res://tests/AutoPlay.tscn -- --level=1
# Starts from a fresh profile (the real save is never read or written). Simulate meta
# progress with --castle=N (castle level), --troops=N (every troop at level N) and
# --stars=N (every troop at N stars); --all-troops unlocks every troop (and picks the
# strongest team); --team=general,bomber,... unlocks and fields exactly those troops.

const Bot = preload("res://game/admin/Bot.gd")

var battle
var _clock := 0.0
var _report := 0.0
# Optional screenshots: --shots=2,40,90 --shot-dir=C:/some/folder
var _shots: Array = []
var _shot_dir := ""


func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.unlocked_levels = PlayerData.LEVELS.size()
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		if arg.begins_with("--level="):
			PlayerData.select_level(int(value) - 1)
		elif arg.begins_with("--castle="):
			PlayerData.castle_level = int(value)
		elif arg.begins_with("--troops="):
			for id in PlayerData.TROOP_ORDER:
				PlayerData.troops[id]["level"] = int(value)
		elif arg.begins_with("--stars="):
			for id in PlayerData.TROOP_ORDER:
				PlayerData.troops[id]["stars"] = int(value)
		elif arg == "--all-troops":
			for id in PlayerData.TROOP_ORDER:
				PlayerData.troops[id]["unlocked"] = true
			PlayerData.team = PlayerData.auto_team()
		elif arg.begins_with("--team="):
			PlayerData.team = []
			for id in value.split(","):
				PlayerData.troops[id]["unlocked"] = true
				PlayerData.team.append(id)
		elif arg.begins_with("--shots="):
			for shot in value.split(","):
				_shots.append(float(shot))
		elif arg.begins_with("--shot-dir="):
			_shot_dir = arg.trim_prefix("--shot-dir=")
	battle = load("res://game/battle/Battle.tscn").instantiate()
	add_child(battle)


func _process(delta: float) -> void:
	_clock += delta
	_report += delta
	if not _shots.is_empty() and _clock >= _shots[0]:
		var image := get_viewport().get_texture().get_image()
		image.save_png("%s/shot_%06.2f.png" % [_shot_dir, _shots.pop_front()])
		if _shots.is_empty():
			get_tree().quit()
	Bot.step(battle)
	if _report >= 5.0:
		_report = 0.0
		print("t=%5.1f wave=%d/%d core=%5.1f meat=%4.1f gears=%s player=%d enemy=%d" % [
			_clock, battle.waves.wave_index + 1, battle.level.waves.size(), battle.core.hp,
			battle.core.meat, _gear_summary(), battle.player_units.size(), battle.enemy_units.size()])
	if battle.phase == "won" or battle.phase == "lost" or _clock > 600.0:
		if _shot_dir != "":
			await get_tree().create_timer(1.0).timeout
			get_viewport().get_texture().get_image().save_png("%s/shot_end.png" % _shot_dir)
			_shot_dir = ""
		print("RESULT level=%d phase=%s core=%.1f/%.1f time=%.1f" % [
			PlayerData.current_level + 1, battle.phase, battle.core.hp, battle.core.max_hp, _clock])
		get_tree().quit()


func _gear_summary() -> String:
	var parts := []
	for gear in battle.board.gears.values():
		parts.append("%s%d" % [gear.troop.id.substr(0, 2), gear.tier])
	parts.sort()
	return ",".join(parts)
