extends Node2D

# A troop cog in one grid cell. Its spawn bar only fills while it actually turns: the
# board feeds it production for every tooth it rotates (see GearBoard.SECONDS_PER_TOOTH).
# Merging two identical gears raises the tier: new metal and stronger troops.

const CogDraw = preload("res://game/battle/CogDraw.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const Economy = preload("res://game/core/Economy.gd")

const METALS := [Color("ead5ac"), Color("80bfd7"), Color("b49cd6"), Color("eead6c"), Color("aec778")]
const IDLE_METAL := Color("aaa995")
# Short broad teeth sit on a 44px shoulder; the concave 36.5px notches leave painted
# clearance for neighbouring teeth and the master pin on the 100px grid.
# Multiples of four keep the same tooth/gap phase on all four sides of the master.
const OUTER := 54.0
const INNER := 36.5
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
## Hero skill gears (troop id "skill:<weapon>") charge for spawn_interval() seconds of
## production, then the hero casts the weapon's skill; they never spawn units.
func is_skill() -> bool:
	return troop.id.begins_with("skill:")


func produce(seconds: float, battle) -> void:
	total_produced += seconds
	if is_skill():
		if not powered:
			return
		_clock += seconds
		if _clock >= spawn_interval():
			# A charged skill waits (full) until there is a fight to cast it in.
			if battle.cast_hero_skill(self):
				_clock -= spawn_interval()
				_pop(1.25)
			else:
				_clock = spawn_interval()
		return
	_alive = _alive.filter(func(unit): return is_instance_valid(unit) and not unit.is_dead())
	if not powered or _alive.size() >= troop.max_alive:
		return
	_clock += seconds
	if _clock >= spawn_interval() and not battle.can_feed(troop):
		# The fish basket is full: hold the finished unit until a cat falls.
		_clock = spawn_interval()
		return
	if _clock >= spawn_interval():
		# Keep a little overflow so a long shove isn't wasted, but never bank a second unit.
		_clock = minf(_clock - spawn_interval(), spawn_interval() * 0.5)
		var unit = battle.spawn_player_unit(troop, tier, global_position + Vector2(0, -30))
		if unit != null:
			_alive.append(unit)
			_pop(0.85)


func _refresh_icon() -> void:
	if SpriteLib.is_cat(troop.unit_key):
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_icon = SpriteLib.unit_frames(troop.unit_key, SpriteLib.player_color(tier)).get_frame_texture("idle", 0)


func _pop(amount: float) -> void:
	scale = Vector2(amount, amount)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.18)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var metal: Color = METALS[tier - 1] if powered else IDLE_METAL
	CogDraw.draw_cog(self, Vector2.ZERO, OUTER, INNER, TEETH, angle, metal, Color("583f21"))

	if powered:
		var full: bool = not is_skill() and _alive.size() >= troop.max_alive
		var progress := 1.0 if full else clampf(_clock / spawn_interval(), 0.0, 1.0)
		draw_arc(Vector2.ZERO, 32.5, 0.0, TAU, 48, Color("583f21"), 2.0, true)
		if progress > 0.0:
			draw_arc(Vector2.ZERO, 32.5, -PI / 2.0, -PI / 2.0 + TAU * progress, 48, Color("dcebb5") if full else Color("fff2bf"), 3.0, true)

	# The troop icon stays upright while the cog turns underneath it.
	var icon_size := 62.0
	var tint: Color = troop.tint * (Color.WHITE if powered else Color(0.6, 0.6, 0.6, 0.85))
	draw_texture_rect(_icon, Rect2(Vector2(-icon_size, -icon_size - 6.0) / 2.0, Vector2(icon_size, icon_size)), false, tint)

	var badge := Vector2(32, -34)
	draw_circle(badge, 14.0, Color("583f21"))
	draw_circle(badge, 11.0, Color("fff3d4"))
	draw_string(_font, badge + Vector2(-13, 7), str(tier), HORIZONTAL_ALIGNMENT_CENTER, 26, 20, Color("583f21"))
