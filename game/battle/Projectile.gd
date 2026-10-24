extends Sprite2D

# An arrow homing on a unit, a bomb lobbed at a spot (splash_radius > 0), or either one
# flying at the castle wall when `hits_core` is set.

const SPEED := 560.0
const BOMB_SPEED := 300.0
const BOMB_ARC := 70.0

var battle
var team := 0
var target = null
var point := Vector2.ZERO
var damage := 0.0
var hits_core := false
var burn_dps := 0.0
var burn_time := 0.0
var splash_radius := 0.0
## A critical hit: shows "CHÍ MẠNG!" where it lands.
var crit := false

var _ground := Vector2.ZERO
var _start := Vector2.ZERO
var _travel := 0.0


func _ready() -> void:
	scale = Vector2(0.55, 0.55)
	_ground = position
	_start = position
	if splash_radius > 0.0:
		scale = Vector2(0.8, 0.8)


func _process(delta: float) -> void:
	if splash_radius > 0.0:
		_fly_bomb(delta)
		return
	if _target_alive():
		point = target.position + Vector2(0, -18)
	var to := point - position
	var step := SPEED * delta
	rotation = to.angle()
	if to.length() <= step:
		if hits_core:
			battle.damage_core(damage)
		elif _target_alive():
			target.take_damage(damage, true)
			if crit:
				battle.show_crit(target.position)
			if burn_dps > 0.0 and _target_alive():
				target.apply_burn(burn_dps, burn_time)
		queue_free()
		return
	position += to / to.length() * step


# Bombs don't home: they arc to where the target stood and blow up there.
func _fly_bomb(delta: float) -> void:
	var total := maxf(_start.distance_to(point), 1.0)
	_travel = minf(_travel + BOMB_SPEED * delta, total)
	var t := _travel / total
	_ground = _start.lerp(point, t)
	position = _ground + Vector2(0, -sin(t * PI) * BOMB_ARC)
	rotation += 8.0 * delta
	if t < 1.0:
		return
	battle.spawn_effect("explosion", point + Vector2(0, -20), 0.6)
	SoundLib.play("explosion", -4.0, 0.1)
	if crit:
		battle.show_crit(point)
	if hits_core:
		battle.damage_core(damage)
	else:
		# A copy: a foe killed here leaves units_of() at once, which would skip the next one.
		for foe in battle.units_of(1 - team).duplicate():
			if is_instance_valid(foe) and not foe.is_dead() and foe.position.distance_to(point) <= splash_radius:
				foe.take_damage(damage, true)
	queue_free()


func _target_alive() -> bool:
	return target != null and is_instance_valid(target) and not target.is_dead()
