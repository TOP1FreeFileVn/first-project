extends Node

# The four cats x four worlds table and the one-version-per-cat team. Never touches the save.
# Run: Godot --headless --path . res://tests/CatsTest.tscn

const Cats = preload("res://game/data/Cats.gd")

var _fails := 0

func _check(ok: bool, what: String) -> void:
	print(("CATS_OK " if ok else "CATS_FAIL ") + what)
	if not ok:
		_fails += 1

func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()

	# Table: every troop once; each cat and each world has all classes and rarities.
	var seen := []
	for cat in Cats.ORDER:
		seen.append_array(Cats.VERSIONS[cat])
	seen.sort()
	var order: Array = PlayerData.TROOP_ORDER.duplicate()
	order.sort()
	_check(seen == order, "the 16 troops are the 16 versions")
	for cat in Cats.ORDER:
		_check(_covers(Cats.VERSIONS[cat]), "%s has every class and rarity" % cat)
	for world in Cats.WORLDS:
		_check(_covers(Cats.world_versions(world)), "%s has every class and rarity" % world)
	_check(Cats.cat_of("katana") == "tro" and Cats.world_of("katana") == "den_long", "katana is Tro in Phố Đèn Lồng")

	# Team: one version per cat, swapping in place.
	PlayerData.castle_level = PlayerData.castle_max_level()
	_check(PlayerData.team_slots() == 4, "team caps at four (one per cat)")
	for id in PlayerData.TROOP_ORDER:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "sung", "no"]
	_check(PlayerData.battle_team() == ["kiem", "no"], "two Mướp versions in a saved team keep the first")
	PlayerData.team = ["kiem", "no", "giao"]
	_check(PlayerData.add_to_team("dua_phep") and PlayerData.battle_team() == ["dua_phep", "no", "giao"], "joining with another Mướp swaps it in place")
	PlayerData.set_team_slot(2, "kiem")
	var team := PlayerData.battle_team()
	_check(team.count("kiem") == 1 and not team.has("dua_phep") and team[2] == "kiem", "set_team_slot moves the cat into the asked slot (%s)" % [team])
	_check(PlayerData.add_to_team("bua") and PlayerData.battle_team().size() == 4, "a fourth cat fills the last slot")
	var cats := []
	for id in PlayerData.auto_team():
		cats.append(Cats.cat_of(id))
	_check(cats.size() == 4 and not cats.has(""), "auto team takes one version of each cat")
	for cat in Cats.ORDER:
		_check(cats.count(cat) == 1, "auto team has %s once" % cat)

	# Featured world: about half of each rarity lands on its version.
	PlayerData._reset()
	var featured: Array = Cats.world_versions(PlayerData.featured_world())
	var hits := 0
	for i in 2000:
		if featured.has(PlayerData._summon_card(0)["id"]):
			hits += 1
	var share := hits / 2000.0
	# 50% forced + 1/4 of the other half: about 62.5%.
	_check(share > 0.55 and share < 0.70, "featured version share %.2f" % share)

	print("CatsTest: fails=%d" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)

func _covers(ids: Array) -> bool:
	var klasses := []
	var rarities := []
	for id in ids:
		klasses.append(int(PlayerData.TROOPS[id].klass))
		rarities.append(int(PlayerData.TROOPS[id].rarity))
	klasses.sort()
	rarities.sort()
	return klasses == [0, 1, 2, 3] and rarities == [0, 1, 2, 3]
