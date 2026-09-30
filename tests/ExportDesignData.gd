extends Node

# Dumps the game's design numbers (levels, troops, castle, heroes, rewards) as JSON for
# the design report. Run: Godot --headless --path . res://tests/ExportDesignData.tscn -- --out=C:/file.json

const Heroes = preload("res://game/core/Heroes.gd")
const Economy = preload("res://game/core/Economy.gd")


func _ready() -> void:
	var out := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.get_slice("=", 1)
	PlayerData.persist = false
	var data := {"levels": [], "troops": [], "castle": Economy.CASTLE, "heroes": [], "chests": Economy.CHESTS,
		"rarity_weights": Economy.RARITY_WEIGHTS, "battle_shop": Economy.BATTLE_SHOP}
	for i in PlayerData.LEVELS.size():
		var level: Resource = PlayerData.level_data(i)
		var waves := []
		var total := 0
		var elites := 0
		var kinds := []
		for wave in level.waves:
			var count := 0
			var groups := []
			for g in wave["groups"]:
				count += int(g["count"])
				if g.get("elite", false):
					elites += int(g["count"])
				if not kinds.has(g["troop"]):
					kinds.append(g["troop"])
				groups.append({"troop": g["troop"], "count": g["count"], "elite": g.get("elite", false)})
			total += count
			waves.append({"count": count, "groups": groups})
		data["levels"].append({
			"index": i + 1, "name": level.display_name, "core_hp": level.core_hp, "start_meat": level.start_meat,
			"enemy_power": level.enemy_power, "waves": waves, "enemies": total, "elites": elites, "kinds": kinds,
			"gold_3star": Economy.win_gold(i, 3), "gift": Economy.FIRST_CLEAR_GIFT.get(i, ""),
			"income_wave1": Economy.round_income(1, 0),
		})
	for id in PlayerData.TROOP_ORDER:
		var t: Resource = PlayerData.TROOPS[id]
		data["troops"].append({"id": id, "name": t.display_name, "rarity": t.rarity, "role": t.role, "hp": t.max_hp,
			"damage": t.damage, "range": t.attack_range, "cooldown": t.attack_cooldown, "speed": t.move_speed, "crit": t.crit_chance, "crit_mult": t.crit_mult, "spawn": t.spawn_interval,
			"ability": t.ability_text, "description": t.description})
	for id in Heroes.ORDER:
		var h: Dictionary = Heroes.HEROES[id]
		data["heroes"].append({"id": id, "name": h["name"], "rarity": h["rarity"], "buff": Heroes.bonus_text(id, 1, 1), "troop": h["troop"]})
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	print("exported ", out)
	get_tree().quit()
