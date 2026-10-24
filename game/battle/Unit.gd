extends Node2D

# One soldier on the battlefield. Player and enemy units share this script: `team` decides
# who they fight, and `rally` is where they walk when nothing is in reach (enemies rally
# on the castle wall and attack it once there). Troop abilities (TroopData.Ability) hook
# into targeting, hits, damage taken and a periodic timer.

const TroopData = preload("res://game/data/TroopData.gd")
const DrawnIcon = preload("res://game/ui/DrawnIcon.gd")
const UiKit = preload("res://game/ui/UiKit.gd")
const Economy = preload("res://game/core/Economy.gd")
const SoldierRig = preload("res://game/battle/SoldierRig.gd")
## Cats with a skeleton (tools/ui/make_cat_rigs.py) animate with it: game/assets/units/<id>/<id>.json.
const RIG_DIR := "res://game/assets/units/"
const Ability = TroopData.Ability
const Role = TroopData.Role

const PLAYER := 0
const ENEMY := 1
const BASE_SCALE := 0.5
const SEPARATION := 24.0
const RETARGET_INTERVAL := 0.25
const REACH_PADDING := 14.0
const AURA_INTERVAL := 0.5
const CLEAVE_RADIUS := 55.0
const CLEAVE_SHARE := 0.5
const WHIRL_RADIUS := 95.0
## Rally points: a unit stops within ARRIVE of its goal, or behind an ally who already
## stopped there (so a crowd forms rings instead of everyone pushing into the middle), and
## only walks again once shoved LEAVE away from its spot. Without this, neighbours nudging
## each other flipped units between run and idle every frame.
const ARRIVE := 10.0
const LEAVE := 36.0
## Once in reach, a fighter keeps swinging until the target is this much further away.
const ENGAGE_SLACK := 16.0
## How fast crowding is resolved (fraction of the overlap per second).
const SEPARATION_RATE := 3.5
const ENEMY_COOK_HEAL := 0.1

var battle
var troop: Resource
var team := PLAYER
var tier := 1
var elite := false
var max_hp := 1.0
var hp := 1.0
var damage := 1.0
var rally := Vector2.ZERO
## Cat soldiers are one baked texture; _animate_cat bobs and swings it.
var _cat := false
## The cat's skeleton, when it has one. The AnimatedSprite2D then stays as the state clock
## (animation name, flip, playing) and the rig draws in its place.
var _rig: Node2D
var _cat_clock := randf() * 10.0
var _dead := false
var _target = null
var _attack_target = null
var _attacking_wall := false
var _cooldown := 0.0
var _hit_timer := -1.0
var _retarget := 0.0
var _flash := 0.0
var _tint := Color.WHITE

# Ability state.
var _ability_clock := 0.0
var _aura_clock := 0.0
var _first_hit := true
var _shield_time := 0.0
var _armor_time := 0.0
var _armor := 0.0
var _command_time := 0.0
var _command_bonus := 0.0
var _burn_time := 0.0
var _burn_dps := 0.0
var _fire: AnimatedSprite2D
var _whirl := 0.0
var _settled := false
var _settle_spot := Vector2.ZERO
var _settle_goal := Vector2.ZERO
var _engaged := false
var _celebrating := false
var _dance_phase := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite


func setup(p_battle, p_troop: Resource, p_team: int, p_tier: int, hp_mult: float, damage_mult: float, p_elite := false) -> void:
	battle = p_battle
	troop = p_troop
	team = p_team
	tier = p_tier
	elite = p_elite
	max_hp = troop.max_hp * hp_mult
	hp = max_hp
	damage = troop.damage * damage_mult


func _ready() -> void:
	var look: String = troop.unit_key
	sprite.sprite_frames = SpriteLib.unit_frames(look, _sprite_color())
	sprite.offset = Vector2(0, -SpriteLib.foot_offset(look))
	var s: float = BASE_SCALE * troop.sprite_scale * (1.0 + 0.07 * (tier - 1)) * (1.35 if elite else 1.0)
	_tint = troop.tint
	sprite.scale = Vector2(s, s)
	sprite.flip_h = randf() < 0.5
	sprite.modulate = _tint
	if SpriteLib.is_cat(look):
		_cat = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_setup_rig(look)
	sprite.play("idle")
	_retarget = randf() * RETARGET_INTERVAL
	_ability_clock = troop.ability_cooldown * randf_range(0.3, 0.7)


func _setup_rig(look: String) -> void:
	if not look.begins_with("art:"):
		return
	var id := look.substr(4)
	var path := RIG_DIR + id + "/" + id + ".json"
	if not FileAccess.file_exists(path):
		return
	_rig = SoldierRig.new()
	_rig.name = "Rig"
	_rig.load_skeleton(path)
	_rig.material = sprite.material
	_rig.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_rig.event.connect(_on_rig_event)
	add_child(_rig)
	move_child(_rig, sprite.get_index() + 1)
	sprite.self_modulate.a = 0.0
	_sync_rig()

# Rig skeleton units are the 256x240 art's pixels; the baked sprite showed that art at half size.
func _sync_rig() -> void:
	var s := sprite.scale.x * 0.5
	_rig.scale = Vector2(-s if sprite.flip_h else s, sprite.scale.y * 0.5)
	_rig.position = sprite.position + Vector2(0, 4.0)
	_rig.modulate = sprite.modulate
	_rig.rotation = sprite.rotation if _celebrating else 0.0
	var anim := String(sprite.animation)
	if anim == "guard" or not _rig.has_animation(anim):
		anim = "idle"
	_rig.play(anim)

func _on_rig_event(name: String) -> void:
	# The rig's "hit" lands the blow at the frame the weapon strikes.
	if name == "hit" and _hit_timer >= 0.0:
		_hit_timer = -1.0
		_resolve_hit()

func is_dead() -> bool:
	return _dead


func is_ranged_or_healer() -> bool:
	return troop.role == Role.RANGED or troop.role == Role.HEALER


## `ranged` marks arrows and bombs (miners shrug part of it off).
func take_damage(amount: float, ranged := false) -> void:
	if _dead or _shield_time > 0.0:
		return
	if _armor_time > 0.0:
		amount *= 1.0 - _armor
	if ranged and troop.ability == Ability.TUNNEL:
		amount *= 1.0 - troop.ability_value
	hp -= amount
	_flash = 0.12
	if hp <= 0.0:
		_dead = true
		battle.on_unit_died(self)
		queue_free()


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


func apply_armor(amount: float, duration: float) -> void:
	_armor = maxf(_armor if _armor_time > 0.0 else 0.0, amount)
	_armor_time = maxf(_armor_time, duration)


func apply_command(bonus: float, duration: float) -> void:
	_command_bonus = maxf(_command_bonus if _command_time > 0.0 else 0.0, bonus)
	_command_time = maxf(_command_time, duration)


func apply_burn(dps: float, duration: float) -> void:
	if _dead or dps <= 0.0:
		return
	_burn_dps = maxf(_burn_dps if _burn_time > 0.0 else 0.0, dps)
	_burn_time = maxf(_burn_time, duration)
	if _fire == null:
		_fire = AnimatedSprite2D.new()
		_fire.sprite_frames = SpriteLib.effect_frames("fire")
		_fire.position = Vector2(0, -22)
		_fire.scale = Vector2(0.7, 0.7)
		add_child(_fire)
		_fire.play("default")


## Damage of the next hit, with a commander troop's aura bonus.
func hit_damage() -> float:
	return damage * (1.0 + (_command_bonus if _command_time > 0.0 else 0.0))


func _process(delta: float) -> void:
	if _dead:
		return
	if _celebrating:
		_dance(delta)
		return
	_cooldown -= delta
	_retarget -= delta
	_tick_effects(delta)
	if _dead:
		return
	_tick_ability(delta)
	if _flash > 0.0:
		_flash -= delta
	sprite.modulate = _tint * (Color(1.0, 0.55, 0.55) if _flash > 0.0 else Color.WHITE)
	if _hit_timer >= 0.0:
		_hit_timer -= delta
		if _hit_timer < 0.0:
			_resolve_hit()
	if _retarget <= 0.0 or not _alive(_target):
		_retarget = RETARGET_INTERVAL
		_target = _find_target()

	# A raised shield plants the knight in place.
	if _shield_time > 0.0 and sprite.sprite_frames.has_animation("guard"):
		_play("guard")
		_separate(delta)
		queue_redraw()
		return

	var attacking := sprite.animation == "attack" and sprite.is_playing()
	var goal := _goal()
	_engaged = _in_range(goal)
	if _engaged:
		_settled = false
		_face(goal.x - position.x)
		if _cooldown <= 0.0 and _hit_timer < 0.0:
			_start_attack()
		elif not attacking:
			_play("idle")
	elif not attacking:
		var offset := goal - position
		var distance := offset.length()
		# A chased target is always walked to; a rally point uses the arrive/leave band.
		var chasing := _alive(_target)
		# A settled unit stays put until it is shoved off its spot or its rally moves.
		if _settled and (chasing or position.distance_to(_settle_spot) > LEAVE or goal.distance_to(_settle_goal) > LEAVE):
			_settled = false
		if _settled:
			_play("idle")
		elif distance > ARRIVE and (chasing or not _queued(goal, distance)):
			position += offset / distance * minf(troop.move_speed * delta, distance)
			_face(offset.x)
			_play("run")
		else:
			# Arrived, or an ally already stands between us and the rally point.
			if not chasing:
				_settled = true
				_settle_spot = position
				_settle_goal = goal
			_play("idle")
	_separate(delta)
	if _rig != null:
		_sync_rig()
	elif _cat:
		_animate_cat(delta)
	queue_redraw()


## The baked cat texture moves instead of changing frames: a hop while running, a lean
## back then a lunge forward through the attack, a slow breath while idle.
func _animate_cat(delta: float) -> void:
	_cat_clock += delta
	var facing := -1.0 if sprite.flip_h else 1.0
	match sprite.animation:
		"run":
			sprite.position.y = -absf(sin(_cat_clock * 13.0)) * 5.0
			sprite.rotation = sin(_cat_clock * 13.0) * 0.07
			sprite.scale.y = sprite.scale.x
		"attack":
			var count := sprite.sprite_frames.get_frame_count("attack")
			var t := (sprite.frame + sprite.frame_progress) / float(count)
			var swing := -0.3 + 0.75 * smoothstep(0.35, 0.6, t) - 0.45 * smoothstep(0.6, 1.0, t)
			sprite.rotation = swing * facing
			sprite.position.y = 0.0
		_:
			sprite.position.y = 0.0
			sprite.rotation = 0.0
			sprite.scale.y = sprite.scale.x * (1.0 + sin(_cat_clock * 3.0) * 0.025)


func _tick_effects(delta: float) -> void:
	_shield_time -= delta
	_armor_time -= delta
	_command_time -= delta
	_whirl -= delta
	if _burn_time > 0.0:
		_burn_time -= delta
		if _burn_time <= 0.0 and _fire != null:
			_fire.queue_free()
			_fire = null
		take_damage(_burn_dps * delta)


func _tick_ability(delta: float) -> void:
	match troop.ability:
		Ability.FORGE, Ability.SHIELD, Ability.COOK, Ability.COMMAND:
			_ability_clock -= delta
	match troop.ability:
		Ability.FORGE:
			if _ability_clock <= 0.0:
				_ability_clock = troop.ability_cooldown
				for ally in _allies_near(troop.ability_radius):
					ally.apply_armor(troop.ability_value, troop.ability_duration)
				_whirl = 0.4
		Ability.SHIELD:
			if _ability_clock <= 0.0 and _alive(_target):
				_ability_clock = troop.ability_cooldown
				_shield_time = troop.ability_duration
		Ability.COOK:
			# No cooking during the shop break (it has no time limit).
			if _ability_clock <= 0.0 and battle.phase == "fight":
				_ability_clock = troop.ability_cooldown
				if team == PLAYER:
					battle.cook_meat(self, troop.ability_value)
				else:
					for ally in _allies_near(troop.ability_radius):
						ally.heal(ally.max_hp * ENEMY_COOK_HEAL * troop.ability_value)
					battle.spawn_effect("heal", position + Vector2(0, -16), 0.5)
		Ability.COMMAND:
			_aura_clock -= delta
			if _aura_clock <= 0.0:
				_aura_clock = AURA_INTERVAL
				for ally in _allies_near(troop.ability_radius):
					if ally != self:
						ally.apply_command(troop.ability_value, AURA_INTERVAL + 0.2)
			if _ability_clock <= 0.0 and not _foes_near(position, WHIRL_RADIUS).is_empty():
				_ability_clock = troop.ability_cooldown
				_whirl = 0.45
				for foe in _foes_near(position, WHIRL_RADIUS):
					foe.take_damage(hit_damage() * troop.ability_duration)
				battle.spawn_effect("dust2", position + Vector2(0, -6), 2.4)


func _draw() -> void:
	# Ability auras sit under the feet.
	if troop.ability == Ability.COMMAND:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 34.0, Color(1.0, 0.78, 0.25, 0.18 + 0.12 * pulse))
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.35, 0.8), 2.5, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _whirl > 0.0:
		var radius: float = (WHIRL_RADIUS if troop.ability == Ability.COMMAND else troop.ability_radius) * (1.0 - _whirl)
		var ring := Color(1.0, 0.85, 0.35) if troop.ability == Ability.COMMAND else Color(0.6, 0.85, 1.0)
		ring.a = clampf(_whirl * 2.0, 0.0, 1.0)
		draw_arc(Vector2(0, -10), maxf(radius, 4.0), 0.0, TAU, 40, ring, 3.0, true)
	if _shield_time > 0.0:
		draw_arc(Vector2(0, -22), 30.0, 0.0, TAU, 28, Color(1.0, 0.9, 0.4, 0.9), 3.0, true)
	elif _armor_time > 0.0:
		draw_arc(Vector2(0, -22), 24.0, 0.0, TAU, 24, Color(0.6, 0.85, 1.0, 0.55), 2.0, true)
	if troop.rarity >= 3:
		var head := -sprite.scale.y * 86.0 - 2.0
		DrawnIcon.draw_crown(self, Vector2(0, head - 10.0), 20.0)
	if _command_time > 0.0:
		draw_circle(Vector2(0, -sprite.scale.y * 86.0 - 16.0), 3.5, Color(1.0, 0.8, 0.3))

	if hp >= max_hp and not elite and troop.rarity < 3:
		return
	var width := 46.0 if elite or troop.rarity >= 3 else 30.0
	var top := -sprite.scale.y * 86.0 - 8.0
	draw_rect(Rect2(-width / 2.0 - 1.0, top - 1.0, width + 2.0, 6.0), Color(0.08, 0.1, 0.13, 0.9))
	var fill := Color("7fd66b") if team == PLAYER else Color("f0605a")
	draw_rect(Rect2(-width / 2.0, top, width * clampf(hp / max_hp, 0.0, 1.0), 4.0), fill)


func _sprite_color() -> String:
	if team == ENEMY:
		return "Black" if elite else "Red"
	return SpriteLib.player_color(tier)


func _is_healer() -> bool:
	return troop.role == Role.HEALER


func _attacks_wall() -> bool:
	return team == ENEMY and troop.role != Role.HEALER and troop.role != Role.SUPPORT


func _alive(unit) -> bool:
	return unit != null and is_instance_valid(unit) and not unit.is_dead()


func _allies_near(radius: float) -> Array:
	var result := []
	for ally in battle.units_of(team):
		if not ally.is_dead() and position.distance_to(ally.position) <= radius:
			result.append(ally)
	return result


func _foes_near(center: Vector2, radius: float) -> Array:
	var result := []
	for foe in battle.units_of(ENEMY if team == PLAYER else PLAYER):
		if not foe.is_dead() and center.distance_to(foe.position) <= radius:
			result.append(foe)
	return result


func _find_target():
	if troop.role == Role.SUPPORT:
		return null
	if _is_healer():
		var patient = null
		var lowest := 0.95
		for ally in battle.units_of(team):
			if ally.is_dead():
				continue
			var ratio: float = ally.hp / ally.max_hp
			if ratio < lowest and position.distance_to(ally.position) <= troop.aggro_range:
				patient = ally
				lowest = ratio
		return patient
	var foes: Array = battle.units_of(ENEMY if team == PLAYER else PLAYER)
	# Assassins go for the back line wherever it stands.
	if troop.ability == Ability.ASSASSIN:
		var prey = null
		var prey_distance := INF
		for foe in foes:
			if foe.is_dead() or not foe.is_ranged_or_healer() or foe.position.y <= battle.FIELD_TOP:
				continue
			var d := position.distance_to(foe.position)
			if d < prey_distance:
				prey = foe
				prey_distance = d
		if prey != null:
			return prey
	var nearest = null
	var nearest_anywhere = null
	var best := troop.aggro_range as float
	var best_anywhere := INF
	for foe in foes:
		if foe.is_dead():
			continue
		var distance := position.distance_to(foe.position)
		if distance < best:
			nearest = foe
			best = distance
		if distance < best_anywhere and foe.position.y > battle.FIELD_TOP:
			nearest_anywhere = foe
			best_anywhere = distance
	# With nothing close, player troops push the line toward whatever is left on the field,
	# so enemy archers or healers can't stall behind their own range.
	if nearest == null and team == PLAYER:
		return nearest_anywhere
	return nearest


func _goal() -> Vector2:
	if _alive(_target):
		return _target.position
	return rally


func _in_range(goal: Vector2) -> bool:
	if troop.role == Role.SUPPORT:
		return false
	if _alive(_target):
		return position.distance_to(goal) <= troop.attack_range + REACH_PADDING + (ENGAGE_SLACK if _engaged else 0.0)
	if _attacks_wall():
		return battle.WALL_Y - position.y <= troop.attack_range * 0.8 + 6.0
	return false


func _start_attack() -> void:
	_cooldown = troop.attack_cooldown
	_attack_target = _target if _alive(_target) else null
	_attacking_wall = _attack_target == null
	sprite.stop()
	sprite.play("attack")
	var frames := sprite.sprite_frames
	_hit_timer = frames.get_frame_count("attack") / frames.get_animation_speed("attack") * 0.55
	if _rig != null:
		# Restart the swing; the rig's "hit" event resolves the blow, the timer is a fallback.
		_rig.play("attack", true)
		var at: float = _rig.event_time("hit")
		if at >= 0.0:
			_hit_timer = at + 0.1
		# The swing outlasts the old frame strip; keep the sprite clock on "attack" for it.
		frames.set_animation_speed("attack", frames.get_frame_count("attack") / maxf(_rig.length("attack"), 0.1))


func _resolve_hit() -> void:
	var amount := hit_damage()
	if troop.ability == Ability.ASSASSIN and _first_hit and _alive(_attack_target):
		amount *= troop.ability_value
		_first_hit = false
	# Only our troops land critical hits: enemies are tuned by their level's power alone.
	# Class counter ring: x2 against the class this one beats.
	if _alive(_attack_target):
		amount *= Economy.counter_mult(troop.klass, _attack_target.troop.klass)
	var crit: bool = team == PLAYER and troop.role != Role.HEALER and troop.crit_chance > 0.0 and randf() < troop.crit_chance
	if crit:
		amount *= troop.crit_mult
	match troop.role:
		Role.HEALER:
			if _alive(_attack_target):
				SoundLib.play("heal", -3.0)
				_attack_target.heal(damage)
				battle.spawn_effect("heal", _attack_target.position + Vector2(0, -16), 0.45)
		Role.RANGED:
			if _alive(_attack_target) or _attacking_wall:
				battle.spawn_arrow(self, _attack_target if _alive(_attack_target) else null, amount, crit)
		_:
			if _alive(_attack_target):
				if position.distance_to(_attack_target.position) <= troop.attack_range * 1.6 + REACH_PADDING + ENGAGE_SLACK:
					SoundLib.play("hit", -1.0, 0.15)
					var center: Vector2 = _attack_target.position
					_attack_target.take_damage(amount)
					if crit:
						battle.show_crit(center)
					if troop.ability == Ability.COMMAND:
						for foe in _foes_near(center, CLEAVE_RADIUS):
							if foe != _attack_target:
								foe.take_damage(amount * CLEAVE_SHARE)
			elif _attacking_wall:
				battle.damage_core(amount)
				if crit:
					battle.show_crit(Vector2(position.x, battle.WALL_Y))


# True when a settled ally stands just ahead, nearer to the goal.
func _queued(goal: Vector2, distance: float) -> bool:
	for other in battle.units_of(team):
		if other != self and other._settled and position.distance_to(other.position) < SEPARATION * 1.4 \
				and other.position.distance_to(goal) < distance:
			return true
	return false


## Victory: stop fighting and jump for joy until the scene changes.
func celebrate() -> void:
	_celebrating = true
	_target = null
	_hit_timer = -1.0
	_dance_phase = randf() * 0.6
	sprite.play("idle")


# Hops on the spot with a squash on landing, turning around every other hop. Legendary
# troops also swing their weapon at the top of a hop.
func _dance(delta: float) -> void:
	var before := _dance_phase
	_dance_phase += delta
	var period := 0.62
	var t := fmod(_dance_phase, period) / period
	var hop := sin(t * PI)
	sprite.position.y = -hop * 22.0
	# Squash at the bottom of the hop, stretch in the air.
	var squash := 1.0 - 0.18 * (1.0 - hop) * (1.0 - hop) + 0.06 * hop
	var s := _base_scale()
	sprite.scale = Vector2(s * (2.0 - squash), s * squash)
	if _rig != null:
		_sync_rig()
	if int(before / period) != int(_dance_phase / period):
		sprite.flip_h = not sprite.flip_h
		SoundLib.play("jump", -6.0, 0.2)
		if troop.rarity >= 3:
			sprite.play("attack")
		elif sprite.animation != "idle":
			sprite.play("idle")
	queue_redraw()


func _base_scale() -> float:
	var s: float = BASE_SCALE * troop.sprite_scale * (1.0 + 0.07 * (tier - 1)) * (1.35 if elite else 1.0)
	return s


func _face(direction_x: float) -> void:
	# A few pixels of wobble must not turn the unit around.
	if absf(direction_x) > 6.0:
		sprite.flip_h = direction_x < 0.0


func _play(anim: String) -> void:
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _separate(delta: float) -> void:
	var push := Vector2.ZERO
	for other in battle.units_of(team):
		if other == self:
			continue
		var away: Vector2 = position - other.position
		var distance := away.length()
		if distance < SEPARATION:
			# Two units on the same spot split along a fixed direction of their own.
			var direction: Vector2 = away / distance if distance > 0.01 else Vector2.from_angle(get_instance_id() % 628 / 100.0)
			push += direction * (SEPARATION - distance)
	# Small overlaps are left alone; bigger ones ease apart instead of snapping.
	if push.length() > 2.0:
		position += push.limit_length(SEPARATION) * minf(1.0, SEPARATION_RATE * delta)
	position.x = clampf(position.x, battle.FIELD_LEFT, battle.FIELD_RIGHT)
	position.y = minf(position.y, battle.UNIT_MAX_Y)
