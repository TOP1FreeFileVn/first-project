extends Node2D

# A 6x4 grid of gear cells. The master drive (an orb with one pin) takes one cell and
# never stops. Like a Geneva drive, each time its pin sweeps past a neighbouring gear it
# catches a tooth and shoves the train one tooth forward, the orb slowing under the load;
# between shoves the gears rest. Like real cogs, a gear only turns when it meshes (4-way
# adjacency) with a turning neighbour, and it turns the opposite way to that neighbour.
# Drag to move or swap, drop on an identical gear (same troop, same tier) to merge,
# drop on the SELL zone (or right-click) to sell. The castle level decides how many
# cells are open; they open outward from the master so every open cell can be driven.
# Levels can mark special cells (tiles): rock (no gear fits), gold (+50% production),
# rust (turns and passes the drive on, but never spawns) and ice (a gear there slips: it
# meshes with no other gear, so it only turns when it touches the master itself).

const Gear = preload("res://game/battle/Gear.gd")
const DrawnIcon = preload("res://game/ui/DrawnIcon.gd")

const COLS := 6
const ROWS := 4
const CELL := 100.0
const MAX_TIER := 5
const NO_CELL := Vector2i(-1, -1)
const MASTER_CELL := Vector2i(2, 1)
const MASTER_CELLS := [MASTER_CELL]
const NEIGHBOURS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## Seconds per master revolution, whatever the load: the drive speeds up between shoves to
## make up for slowing down during them.
const REV_TIME := 3.0
## How much slower the master turns while its pin drives a gear (the "heavy shove").
const PUSH_SLOWDOWN := 2.5
## Spawn production per tooth a gear turns. One tooth per revolution per master
## neighbour, so a train touching the master once produces in real time on average;
## touching it on two sides makes it turn, and produce, twice as much.
const SECONDS_PER_TOOTH := REV_TIME
## Master neighbours and the pin angle that points straight at each (screen angles).
const PUSH_DIRS := [[Vector2i(1, 0), 0.0], [Vector2i(0, 1), PI / 2.0], [Vector2i(-1, 0), PI], [Vector2i(0, -1), -PI / 2.0]]
## Pin tip distance from the master's centre, chosen so that while the tip is inside a
## neighbour's tip circle the neighbour turns exactly one tooth: the tip enters and leaves
## where the line gear→tip is half a tooth off the line gear→master.
static var PIN_REACH := sqrt(CELL * CELL + Gear.OUTER * Gear.OUTER - 2.0 * CELL * Gear.OUTER * cos(PI / Gear.TEETH))
## Pin angle, either side of a neighbour's direction, at which the tip enters its teeth.
static var PIN_ENTRY := acos((PIN_REACH * PIN_REACH + CELL * CELL - Gear.OUTER * Gear.OUTER) / (2.0 * PIN_REACH * CELL))

var battle
var gears := {}
# Every train rests at this plus a whole number of teeth. It starts 0.3 tooth back so the
# pin tip rides in the middle of a tooth gap for the whole pass (tests/PinMeshTest.tscn).
var _rest_phase := -0.3 * TAU / Gear.TEETH
# Gear trains: groups of gears meshed with each other (not through the master). Only the
# train the pin is driving turns; the others wait. Each entry is an Array of gears.
var _chains: Array = []
# Train index -> how far through the current pin pass it is (0..1), for trains being driven.
var _driving := {}
## Accumulated master drive angle; the pin is drawn at pin_angle().
var drive := 0.0
## True while the pin is driving a gear (the master turns slower then).
var pushing := false
var open_cells := {}
## Special cells of this level: cell -> "rock" | "gold" | "rust" | "ice".
var tiles := {}

var _drag = null
var _drag_from := NO_CELL
var _drag_pointer := Vector2.ZERO
var _slot_face: StyleBoxFlat
var _locked_face: StyleBoxFlat


func _ready() -> void:
	_slot_face = _cell_face(Color("cbb893"), Color("a78b63"))
	_locked_face = _cell_face(Color("b69d79"), Color("a78b63"))
	var order := open_order()
	for i in mini(PlayerData.unlocked_cells(), order.size()):
		open_cells[order[i]] = true


static func _cell_face(fill: Color, border: Color) -> StyleBoxFlat:
	var face := StyleBoxFlat.new()
	face.bg_color = fill
	face.border_color = border
	face.set_border_width_all(2)
	face.set_corner_radius_all(16)
	return face


## The order cells open in as the castle levels up: nearest to the master first, ties
## going to the upper rows (closer to the fight). Also used by the Castle page preview.
static func open_order() -> Array:
	var cells := []
	for y in ROWS:
		for x in COLS:
			var cell := Vector2i(x, y)
			if not cell in MASTER_CELLS:
				cells.append(cell)
	cells.sort_custom(func(a, b):
		var da: int = absi(a.x - MASTER_CELL.x) + absi(a.y - MASTER_CELL.y)
		var db: int = absi(b.x - MASTER_CELL.x) + absi(b.y - MASTER_CELL.y)
		return da < db if da != db else (a.y < b.y if a.y != b.y else a.x < b.x))
	return cells


func is_open(cell: Vector2i) -> bool:
	return open_cells.has(cell)


## What each tile does: name, one-line rule, production multiplier.
const TILE_INFO := {
	"rock": {"name": "Ô đá", "text": "Không đặt gear được: nối xích đi vòng qua ô khác.", "production": 1.0},
	"gold": {"name": "Ô vàng", "text": "Gear đặt trên ô này sinh lính nhanh hơn 50%.", "production": 1.5},
	"rust": {"name": "Ô rỉ sét", "text": "Gear vẫn quay và truyền động tiếp, nhưng không sinh lính. Dùng làm cầu nối.", "production": 0.0},
	"ice": {"name": "Ô băng", "text": "Gear trơn trượt, không ăn khớp gear nào: chỉ quay khi chạm thẳng trục cam.", "production": 1.0},
}


## Reads the level's special cells.
func setup_tiles(level: Resource) -> void:
	tiles.clear()
	var spec: Dictionary = level.get("tiles") if level.get("tiles") != null else {}
	for kind in spec:
		for cell in spec[kind]:
			tiles[Vector2i(cell)] = kind
	queue_redraw()


func tile(cell: Vector2i) -> String:
	return tiles.get(cell, "")


## Open and not a rock.
func is_placeable(cell: Vector2i) -> bool:
	return is_open(cell) and tile(cell) != "rock"


## Two neighbouring gears mesh unless either sits on ice.
func _meshes(a: Vector2i, b: Vector2i) -> bool:
	return tile(a) != "ice" and tile(b) != "ice"


func tile_production(cell: Vector2i) -> float:
	return TILE_INFO[tile(cell)]["production"] if tiles.has(cell) else 1.0


## Tile kinds present on open cells (for the level's intro).
func tile_kinds() -> Array:
	var kinds := []
	for cell in tiles:
		if is_open(cell) and not kinds.has(tiles[cell]):
			kinds.append(tiles[cell])
	return kinds


# All gears of one train share a phase: cells of opposite parity turn opposite ways. The
# 0.9-tooth offset puts each tooth tip in the facing gap of the neighbour (tooth centre
# sits at 0.3 of a pitch, gap centre at 0.8); an even tooth count keeps this true for
# vertical neighbours too.
func gear_angle(cell: Vector2i, at_phase: float) -> float:
	if (cell.x + cell.y) % 2 == 1:
		return -at_phase + 0.9 * TAU / Gear.TEETH
	return at_phase


func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * CELL


func cell_at(local: Vector2) -> Vector2i:
	var cell := Vector2i(floori(local.x / CELL), floori(local.y / CELL))
	if not is_placeable(cell):
		return NO_CELL
	return cell


func is_dragging() -> bool:
	return _drag != null


func dragged_gear():
	return _drag


func drag_can_sell() -> bool:
	return _drag != null and not _drag.is_skill()


func drag_over_sell_zone() -> bool:
	return drag_can_sell() and battle != null and battle.is_sell_zone(_drag_pointer)


func cancel_drag() -> void:
	if _drag != null:
		_drop(NO_CELL)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		cancel_drag()


func is_full() -> bool:
	var room := 0
	for cell in open_cells:
		if is_placeable(cell):
			room += 1
	return gears.size() >= room


func add_gear(troop: Resource, tier: int, cell: Vector2i):
	var gear = Gear.new()
	gear.troop = troop
	gear.tier = tier
	add_child(gear)
	_place(gear, cell)
	_update_power()
	return gear


# Bought gears land in the free cell nearest the master that turns right away, or the
# nearest free cell if none would turn.
func place_new(troop: Resource, tier := 1):
	var fallback := NO_CELL
	for cell in open_order():
		if not is_placeable(cell) or gears.has(cell):
			continue
		# A new gear goes where it turns and spawns; a rust cell only if nothing better.
		if _would_turn(cell) and tile(cell) != "rust":
			return add_gear(troop, tier, cell)
		if fallback == NO_CELL:
			fallback = cell
	if fallback == NO_CELL:
		return null
	return add_gear(troop, tier, fallback)


func remove_gear(gear) -> void:
	gears.erase(gear.cell)
	gear.queue_free()
	_update_power()


func can_merge(a, b) -> bool:
	return a != b and a.troop == b.troop and a.tier == b.tier and a.tier < MAX_TIER


# Spawning happens in _process, driven by rotation (see _count_production).
func tick(_delta: float) -> void:
	pass


func pin_angle() -> float:
	return -drive


# Turns the master. While the pin tip is inside an occupied neighbour's tip circle, the
# gear train's angle comes from where the tip is (the tooth gap follows it, as in a real
# pin drive), so the pin never cuts into a tooth; each pass ends one tooth further on.
func _advance_drive(delta: float) -> void:
	var before := pin_angle()
	var step := delta * _drive_speed() / (PUSH_SLOWDOWN if pushing else 1.0)
	drive += step
	var after := pin_angle()
	pushing = false
	_driving.clear()
	for dir in PUSH_DIRS:
		var root = gears.get(MASTER_CELL + dir[0])
		if root == null:
			continue
		var chain: int = root.chain
		# The pin turns with falling angle: it enters at +PIN_ENTRY and leaves at -PIN_ENTRY.
		var was := wrapf(before - dir[1], -PI, PI)
		if was > -PIN_ENTRY and was - step <= -PIN_ENTRY:
			for gear in _chains[chain]:
				gear.turns += 1
		var now := wrapf(after - dir[1], -PI, PI)
		if absf(now) < PIN_ENTRY:
			pushing = true
			_driving[chain] = _pin_progress(now)


# Free-running speed that keeps one revolution at REV_TIME with this many neighbours.
func _drive_speed() -> float:
	var loaded := 0
	for dir in PUSH_DIRS:
		if gears.has(MASTER_CELL + dir[0]):
			loaded += 1
	return (TAU + (PUSH_SLOWDOWN - 1.0) * loaded * 2.0 * PIN_ENTRY) / REV_TIME


# 0 when the tip enters, 1 when it leaves: the turn of the line gear→tip, as a share of
# one tooth.
static func _pin_progress(offset: float) -> float:
	var edge := atan2(PIN_REACH * sin(PIN_ENTRY), CELL - PIN_REACH * cos(PIN_ENTRY))
	var turn := atan2(PIN_REACH * sin(offset), CELL - PIN_REACH * cos(offset))
	return (edge - turn) / (2.0 * edge)


func _process(delta: float) -> void:
	if _drag != null and (battle == null or not battle.accepts_input()):
		cancel_drag()
	_advance_drive(delta)
	var fighting: bool = battle != null and battle.phase == "fight"
	for gear in gears.values():
		# Stranded gears keep their last position.
		var through: float = _driving.get(gear.chain, 0.0) if gear.powered else 0.0
		var position_in_teeth: float = gear.turns + through
		if gear != _drag:
			gear.angle = gear_angle(gear.cell, _rest_phase + position_in_teeth * TAU / Gear.TEETH)
		# Only turning counts towards spawning, and only while a wave is on.
		var turned: float = position_in_teeth - gear.counted
		gear.counted = position_in_teeth
		var production := tile_production(gear.cell)
		if fighting and turned > 0.0 and production > 0.0:
			gear.produce(turned * SECONDS_PER_TOOTH * production, battle)
	queue_redraw()


# Power flows from the master gear through chains of adjacent gears.
func _update_power() -> void:
	for gear in gears.values():
		gear.powered = false
	var queue := []
	for cell in MASTER_CELLS:
		for offset in NEIGHBOURS:
			var gear = gears.get(cell + offset)
			if gear != null and not gear.powered:
				gear.powered = true
				queue.append(gear)
	while not queue.is_empty():
		var current = queue.pop_front()
		for offset in NEIGHBOURS:
			var next = gears.get(current.cell + offset)
			if next != null and not next.powered and _meshes(current.cell, next.cell):
				next.powered = true
				queue.append(next)
	_build_chains()
	queue_redraw()


# Groups powered gears into trains (4-way adjacency, not through the master). Gears newly
# joined to a train snap to its position, the furthest-turned member's, so it stays meshed.
func _build_chains() -> void:
	_chains.clear()
	for gear in gears.values():
		gear.chain = -1
	for start in gears.values():
		if not start.powered or start.chain >= 0:
			continue
		var members := [start]
		start.chain = _chains.size()
		var i := 0
		while i < members.size():
			for offset in NEIGHBOURS:
				var next = gears.get(members[i].cell + offset)
				if next != null and next.powered and next.chain < 0 and _meshes(members[i].cell, next.cell):
					next.chain = start.chain
					members.append(next)
			i += 1
		var turns := 0
		for gear in members:
			turns = maxi(turns, gear.turns)
		for gear in members:
			gear.counted += turns - gear.turns
			gear.turns = turns
		_chains.append(members)


func _would_turn(cell: Vector2i) -> bool:
	for offset in NEIGHBOURS:
		var near: Vector2i = cell + offset
		if near in MASTER_CELLS:
			return true
		var gear = gears.get(near)
		if gear != null and gear.powered and _meshes(cell, near):
			return true
	return false


# _input rather than _unhandled_input so a release over a HUD control still ends the drag.
func _input(event: InputEvent) -> void:
	if battle == null or not battle.accepts_input():
		if _drag != null:
			cancel_drag()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouse:
		_drag_pointer = get_canvas_transform().affine_inverse() * event.position
	if event is InputEventMouseButton:
		var cell := cell_at(to_local(_drag_pointer))
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _drag == null and gears.has(cell):
				_drag = gears[cell]
				_drag_from = cell
				_drag.z_index = 20
				get_viewport().set_input_as_handled()
			elif not event.pressed and _drag != null:
				if drag_over_sell_zone():
					var gear = _drag
					_drag = null
					battle.sell_gear(gear)
				else:
					_drop(cell)
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and _drag == null and gears.has(cell):
			battle.sell_gear(gears[cell])
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _drag != null:
		_drag.position = to_local(_drag_pointer)
		get_viewport().set_input_as_handled()


func _drop(cell: Vector2i) -> void:
	var gear = _drag
	_drag = null
	gear.z_index = 0
	var other = gears.get(cell)
	if cell == NO_CELL or cell == _drag_from:
		gear.position = cell_center(_drag_from)
	elif other == null:
		gears.erase(_drag_from)
		_place(gear, cell)
		SoundLib.play("place")
	elif can_merge(gear, other):
		gears.erase(_drag_from)
		gear.queue_free()
		other.tier_up()
		battle.on_gear_merged(other)
	else:
		_place(other, _drag_from)
		_place(gear, cell)
		SoundLib.play("place")
	_update_power()


func _place(gear, cell: Vector2i) -> void:
	gears[cell] = gear
	gear.cell = cell
	gear.position = cell_center(cell)


func _draw() -> void:
	var hover := cell_at(to_local(_drag_pointer)) if _drag != null else NO_CELL
	for y in ROWS:
		for x in COLS:
			var cell := Vector2i(x, y)
			if cell in MASTER_CELLS:
				continue
			var center := cell_center(cell)
			if not is_open(cell):
				draw_style_box(_locked_face, Rect2(center - Vector2(46, 46), Vector2(92, 92)))
				DrawnIcon.draw_lock(self, center, 26.0)
				continue
			draw_style_box(_slot_face, Rect2(center - Vector2(46, 46), Vector2(92, 92)))
			if tiles.has(cell):
				draw_tile(self, tiles[cell], center)
			if gears.has(cell) or tile(cell) == "rock":
				continue
			# Empty cells that would mesh with the drive train glow, to guide placement.
			var hot := _would_turn(cell)
			var mark := Color("806346") if hot else Color("a78b63")
			draw_arc(center, 34.0, 0.0, TAU, 40, mark, 2.0, true)
			draw_line(center - Vector2(8, 0), center + Vector2(8, 0), mark, 3.0, true)
			draw_line(center - Vector2(0, 8), center + Vector2(0, 8), mark, 3.0, true)
	if _drag == null:
		return
	for cell in gears:
		var other = gears[cell]
		if can_merge(_drag, other):
			draw_arc(cell_center(cell), 50.0, 0.0, TAU, 40, Color(1.0, 0.85, 0.3, 0.95 if cell == hover else 0.5), 4.0, true)
	if hover != NO_CELL and not (gears.has(hover) and can_merge(_drag, gears[hover])):
		draw_arc(cell_center(hover), 50.0, 0.0, TAU, 40, Color(1, 1, 1, 0.6), 3.0, true)


# Each special cell has its own look, plus a corner badge that stays visible under a gear.
static func draw_tile(ci: CanvasItem, kind: String, center: Vector2) -> void:
	var rect := Rect2(center - Vector2(46, 46), Vector2(92, 92))
	var corner := center + Vector2(-34, -34)
	match kind:
		"rock":
			ci.draw_rect(rect, Color(0.18, 0.17, 0.16, 0.75))
			var rock: Texture2D = SpriteLib.texture("Terrain/Decorations/Rocks/Rock3.png")
			ci.draw_texture_rect(rock, Rect2(center - Vector2(40, 44), Vector2(80, 80)), false)
		"gold":
			ci.draw_rect(rect, Color(1.0, 0.78, 0.2, 0.28))
			ci.draw_rect(rect.grow(-3), Color(1.0, 0.85, 0.3, 0.9), false, 3.0)
			var t := Time.get_ticks_msec() / 1000.0
			for i in 3:
				var at := center + Vector2(cos(t * 1.3 + i * 2.1) * 30.0, sin(t * 1.7 + i * 2.1) * 30.0)
				_sparkle(ci, at, 4.0 + 2.0 * sin(t * 5.0 + i), Color(1.0, 0.95, 0.6, 0.9))
			ci.draw_circle(corner, 10.0, Color("24170e"))
			ci.draw_circle(corner, 8.0, Color("ffcc4d"))
		"rust":
			ci.draw_rect(rect, Color(0.55, 0.3, 0.14, 0.45))
			for i in 4:
				var y := rect.position.y + 14.0 + i * 22.0
				ci.draw_line(Vector2(rect.position.x + 6, y), Vector2(rect.end.x - 6, y + 8), Color(0.35, 0.18, 0.08, 0.6), 2.0)
			ci.draw_rect(rect.grow(-3), Color(0.7, 0.38, 0.16, 0.9), false, 3.0)
			ci.draw_circle(corner, 10.0, Color("24170e"))
			ci.draw_circle(corner, 8.0, Color("b5652b"))
			ci.draw_line(corner + Vector2(-4, -4), corner + Vector2(4, 4), Color("24170e"), 2.0)
		"ice":
			ci.draw_rect(rect, Color(0.7, 0.9, 1.0, 0.4))
			for i in 3:
				var x := rect.position.x + 18.0 + i * 26.0
				ci.draw_line(Vector2(x, rect.end.y - 8), Vector2(x + 22, rect.position.y + 8), Color(1, 1, 1, 0.45), 3.0)
			ci.draw_rect(rect.grow(-3), Color(0.75, 0.93, 1.0, 0.95), false, 3.0)
			ci.draw_circle(corner, 10.0, Color("24170e"))
			ci.draw_circle(corner, 8.0, Color("bfe9ff"))
			for a in 3:
				var dir := Vector2.from_angle(a * PI / 3.0) * 6.0
				ci.draw_line(corner - dir, corner + dir, Color("2b7fb8"), 1.5)


static func _sparkle(ci: CanvasItem, at: Vector2, size: float, color: Color) -> void:
	var thin := size * 0.3
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -size), at + Vector2(thin, -thin), at + Vector2(size, 0), at + Vector2(thin, thin),
		at + Vector2(0, size), at + Vector2(-thin, thin), at + Vector2(-size, 0), at + Vector2(-thin, -thin)]), color)
