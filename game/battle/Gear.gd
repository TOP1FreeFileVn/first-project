extends Node2D

# A troop cog in one grid cell. Its spawn bar only fills while it actually turns: the
# board feeds it production for every tooth it rotates (see GearBoard.SECONDS_PER_TOOTH).
# Merging two identical gears raises the tier: new metal and stronger troops.

const CogDraw = preload("res://game/battle/CogDraw.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const Economy = preload("res://game/core/Economy.gd")

const METALS := [Color("c07a45"), Color("b9c3cc"), Color("e8b93c"), Color("a67be0"), Color("e0586a")]
const IDLE_METAL := Color("6d7277")
# Outer + inner radius = one cell (100px), so the tips of one gear reach the roots of its
# neighbour and the teeth interlock. The tooth count must stay even for neighbours to mesh.
const OUTER := 60.0
const INNER := 40.0
const TEETH := 8
## The master's hub: smaller than the gap to the gear tips, so only its pin arm touches
## the gears.
const ORB_RADIUS := 30.0

var troop: Resource
var tier := 1
var cell := Vector2i.ZERO
var powered := false
# Set by the board each frame so meshed neighbours stay in step.
var angle := 0.0
# Board bookkeeping: which gear train this belongs to, how many teeth it has turned, and
# its position (in teeth) when production was last counted.
var chain := -1
var turns := 0
var counted := 0.0
## Production seconds received so far (tests compare gears with it).
var total_produced := 0.0

var _clock := 0.0
var _interval := -1.0
var _alive: Array = []
var _icon: Texture2D
var _font: Font


func _ready() -> void:
	_font = UiKit.game_font()
	_refresh_icon()
	_pop(1.3)


# Cached: the gear asks every frame and the answer only changes with the tier.
func spawn_interval() -> float:
	if _interval < 0.0:
		_interval = Economy.spawn_interval(troop.spawn_interval, tier, PlayerData.spawn_speed_multiplier() - 1.0)
	return _interval


func tier_up() -> void:
	tier += 1
	_interval = -1.0
	_refresh_icon()
	_pop(1.35)


## Adds `seconds` of production (the board converts rotation into seconds).
func produce(seconds: float, battle) -> void:
	total_produced += seconds
	_alive = _alive.filter(func(unit): return is_instance_valid(unit) and not unit.is_dead())
	if not powered or _alive.size() >= troop.max_alive:
		return
	_clock += seconds
	if _clock >= spawn_interval():
		# Keep a little overflow so a long shove isn't wasted, but never bank a second unit.
		_clock = minf(_clock - spawn_interval(), spawn_interval() * 0.5)
		var unit = battle.spawn_player_unit(troop, tier, global_position + Vector2(0, -30))
		if unit != null:
			_alive.append(unit)
			_pop(0.85)


func _refresh_icon() -> void:
	_icon = SpriteLib.unit_frames(troop.unit_key, SpriteLib.player_color(tier)).get_frame_texture("idle", 0)


func _pop(amount: float) -> void:
	scale = Vector2(amount, amount)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.18)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var metal: Color = METALS[tier - 1] if powered else IDLE_METAL
	draw_circle(Vector2(0, 5), INNER, Color(0, 0, 0, 0.25))
	CogDraw.draw_cog(self, Vector2.ZERO, OUTER, INNER, TEETH, angle, metal, metal.darkened(0.6))

	if powered:
		var full: bool = _alive.size() >= troop.max_alive
		var progress := 1.0 if full else clampf(_clock / spawn_interval(), 0.0, 1.0)
		draw_arc(Vector2.ZERO, 26.0, -PI / 2.0, -PI / 2.0 + TAU * progress, 32, Color(1, 1, 1, 0.35 if full else 0.85), 3.0, true)

	# The troop icon stays upright while the cog turns underneath it.
	var icon_size := 112.0 * _icon.get_width() / 192.0
	if troop.rarity >= 3:
		draw_circle(Vector2(0, -3), 30.0, Color(1.0, 0.78, 0.25, 0.35 if powered else 0.15))
	var tint: Color = troop.tint * (Color.WHITE if powered else Color(0.6, 0.6, 0.6, 0.85))
	draw_texture_rect(_icon, Rect2(Vector2(-icon_size, -icon_size - 6.0) / 2.0, Vector2(icon_size, icon_size)), false, tint)

	var badge := Vector2(32, -32)
	draw_circle(badge, 11.0, Color("3b2b1e"))
	draw_circle(badge, 9.0, Color("ffd35c"))
	draw_string(_font, badge + Vector2(-11, 5.5), str(tier), HORIZONTAL_ALIGNMENT_CENTER, 22, 15, Color("3b2b1e"))
