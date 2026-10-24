extends Node

# The troop page's drag rules on the real page, in RAM (no save): a version dropped on its
# cat's spot joins (swapping that cat's other version), on another cat's spot is refused,
# and a fighter dropped on the roster benches (never the last one).
# Run: Godot --headless --path . res://tests/DragTest.tscn

const Cats = preload("res://game/data/Cats.gd")

var _fails := 0

func _check(ok: bool, what: String) -> void:
	print(("DRAG_OK " if ok else "DRAG_FAIL ") + what)
	if not ok:
		_fails += 1

func _ready() -> void:
	PlayerData.persist = false
	PlayerData._reset()
	PlayerData.castle_level = 3
	for id in PlayerData.TROOP_ORDER:
		PlayerData.troops[id]["unlocked"] = true
	PlayerData.team = ["kiem", "no", "sach_phep"]
	var home = load("res://game/menu/Home.tscn").instantiate()
	add_child(home)
	await get_tree().process_frame
	home.select_tab(home.TROOPS_TAB, false)
	await get_tree().process_frame
	var page = home._pages[home.TROOPS_TAB]
	var drag := func(id: String, source: String) -> Dictionary:
		return {"kind": "troop", "troop_id": id, "source": source, "cat": Cats.cat_of(id), "owner_id": page.get_instance_id()}

	# Mướp Súng onto Mướp's spot swaps out Mướp Kiếm.
	_check(page._can_team_drop(Vector2.ZERO, drag.call("sung", "roster"), "muop"), "a Mướp version may drop on Mướp's spot")
	_check(not page._can_team_drop(Vector2.ZERO, drag.call("sung", "roster"), "tro"), "a Mướp version may not drop on Tro's spot")
	page._apply_team_drop("sung", false)
	var team: Array = PlayerData.battle_team()
	_check(team.has("sung") and not team.has("kiem") and team.size() == 3, "dropping swaps the cat's version in (%s)" % [team])
	# Bơ joins the free fourth slot only if the castle has one.
	_check(PlayerData.team_slots() == 4 or not page._can_team_drop(Vector2.ZERO, drag.call("bua", "roster"), "bo"), "a new cat needs a free slot")
	# Bench a fighter; never the last one.
	_check(page._can_bench_drop(Vector2.ZERO, drag.call("no", "team")), "a fighter can be benched")
	page._apply_team_drop("no", true)
	_check(not PlayerData.in_team("no"), "benched fighter left the team")
	PlayerData.team = ["sung"]
	_check(not page._can_bench_drop(Vector2.ZERO, drag.call("sung", "team")), "the last fighter cannot be benched")
	_check(not page._can_team_drop(Vector2.ZERO, {"kind": "troop", "troop_id": "sung", "owner_id": 0}, "muop"), "foreign drag data is refused")
	print("DragTest: fails=%d" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
