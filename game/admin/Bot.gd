extends RefCounted

# A simple player for balance testing, one action per call: merge any matching pair
# through the real drag/drop code, move stranded gears back onto the drive train, and
# in the between-wave shop buy what merges first, then the rarest affordable gear,
# keeping a savings floor for interest from wave 3 on; reroll with spare meat; then
# press READY. Used by tests/AutoPlay and the admin Simulation tab.

## Meat kept back for interest once the economy has started (wave 3+).
const SAVINGS := 5
## Rerolls only with at least this much to spend on top of the savings.
const REROLL_SPARE := 4
const MAX_REROLLS := 2

static var _rerolls := {}


static func step(battle) -> void:
	if not battle.accepts_input():
		return
	if _merge_one(battle.board) or _reconnect_one(battle.board):
		return
	if battle.phase != "shop":
		return
	var reserve := SAVINGS if battle.wave_number() >= 3 else 0
	var slot := _best_offer(battle, reserve)
	if slot >= 0:
		battle.buy(slot)
		return
	var key: String = "%d/%d" % [battle.get_instance_id(), battle.wave_number()]
	var done: int = _rerolls.get(key, 0)
	if done < MAX_REROLLS and not battle.board.is_full() and battle.core.meat - battle.reroll_cost() >= reserve + REROLL_SPARE:
		_rerolls[key] = done + 1
		battle.reroll()
		return
	_rerolls.erase(key)
	battle.start_wave()


# Merging offers first, then the rarest (then highest tier) the budget allows.
static func _best_offer(battle, reserve: int) -> int:
	if battle.board.is_full():
		return -1
	var best := -1
	var best_score := -1.0
	for slot in battle.shop.size():
		var offer: Dictionary = battle.shop[slot]
		if offer["sold"]:
			continue
		var merges: bool = battle.offer_merges(slot)
		# Merges are worth dipping into savings for.
		var budget: float = battle.core.meat - (0 if merges else reserve)
		if offer["price"] > budget:
			continue
		var score: float = PlayerData.TROOPS[offer["id"]].rarity + offer["tier"] * 2.0 + (10.0 if merges else 0.0)
		if score > best_score:
			best = slot
			best_score = score
	return best


static func _merge_one(board) -> bool:
	var gears: Array = board.gears.values()
	for a in gears:
		for b in gears:
			if board.can_merge(a, b):
				_move(board, a, b.cell)
				return true
	return false


static func _reconnect_one(board) -> bool:
	for a in board.gears.values():
		if a.powered:
			continue
		for y in board.ROWS:
			for x in board.COLS:
				var cell := Vector2i(x, y)
				if board.is_open(cell) and not board.gears.has(cell) and board._would_turn(cell):
					_move(board, a, cell)
					return true
	return false


static func _move(board, gear, cell: Vector2i) -> void:
	board._drag = gear
	board._drag_from = gear.cell
	board._drop(cell)
