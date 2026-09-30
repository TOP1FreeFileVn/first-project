extends Node2D

# Root of one level. Owns the unit lists and routes spawns, hits, merges and results
# between the gear board, the castle core, the wave director and the HUD.
# A level alternates SHOP (time stands still: buy gears from five offers drawn from the
# team, reroll, lock, arrange, merge, sell) and FIGHT (one wave; arranging, merging and
# selling still work, buying doesn't). Clearing a wave pays income plus interest.

signal shop_changed

const UnitScene := preload("res://game/battle/Unit.tscn")
const Projectile := preload("res://game/battle/Projectile.gd")
const ShopRoller := preload("res://game/battle/ShopRoller.gd")
const TroopData := preload("res://game/data/TroopData.gd")
const HOME_SCENE := "res://game/menu/Home.tscn"

const PLAYER := 0
const ENEMY := 1
# Portrait layout (720x1280): enemies march down from the top; the 6x4 gear grid with the
# master gear and castle in its middle sits below the wall.
const WALL_Y := 700.0
const RALLY_Y := 470.0
const FIELD_TOP := 110.0
const FIELD_LEFT := 24.0
const FIELD_RIGHT := 696.0
const UNIT_MAX_Y := 1190.0
const ENEMY_SPAWN_Y := -30.0
const SELL_RECT := Rect2(16, 1196, 152, 76)
const Economy := preload("res://game/core/Economy.gd")
const Heroes := preload("res://game/core/Heroes.gd")
const UiKit := preload("res://game/ui/UiKit.gd")
## Seconds of victory dance before the result panel.
const VICTORY_DANCE_TIME := 1.8
## Where the leading hero comes out: the middle of the wall.
const HERO_AT := Vector2(360, 690)
## Milliseconds between two "CHÍ MẠNG!" texts.
const CRIT_TEXT_GAP := 90

@onready var core = $Core
@onready var board = $Board
@onready var units_layer: Node2D = $Units
@onready var projectiles: Node2D = $Projectiles
@onready var effects: Node2D = $Effects
@onready var waves = $WaveDirector
@onready var hud = $HUD

var level: Resource
## "shop", "fight", "won" or "lost".
var phase := "shop"
var player_units: Array = []
var enemy_units: Array = []
## Offers on sale: [{"id", "tier", "price", "sold"}].
var shop: Array = []
var shop_locked := false
var free_rerolls := 0
var _merge_hint_shown := false
# The player's team; the shop only offers these.
var _pool: Array = []
# Gear tier multipliers, computed once per battle instead of evaluating the formula per spawn.
var _tier_mult: Array = []
# The leading hero's buffs, read once per battle.
var _hero_hp := 1.0
var _hero_damage := 1.0
var _hero_unit = null
var _last_crit_text := 0


func _ready() -> void:
	for tier in range(1, board.MAX_TIER + 1):
		_tier_mult.append(Economy.tier_multiplier(tier))
	level = PlayerData.level_data()
	_hero_hp = PlayerData.hero_hp_multiplier()
	_hero_damage = PlayerData.hero_damage_multiplier()
	for id in PlayerData.battle_team():
		_pool.append(PlayerData.TROOPS[id])
	core.setup(level)
	core.destroyed.connect(_on_core_destroyed)
	board.battle = self
	core.board = board
	waves.battle = self
	waves.setup(level)
	waves.spawn_requested.connect(_spawn_enemy)
	waves.wave_started.connect(_on_wave_started)
	waves.wave_cleared.connect(_on_wave_cleared)
	waves.all_cleared.connect(_on_all_waves_cleared)
	hud.bind(self)
	board.setup_tiles(level)
	board.place_new(_pool[0], 1)
	_spawn_hero()
	_open_shop()
	var leader := PlayerData.leader()
	if leader != "":
		var h: Dictionary = PlayerData.hero_state(leader)
		hud.show_message("Tướng %s: %s" % [Heroes.HEROES[leader]["name"], Heroes.bonus_text(leader, h["level"], h["stars"])])
	else:
		hud.show_message("Lượt nghỉ: mua gear, ghép gear giống nhau rồi bấm SẴN SÀNG.")


# The leading hero fights as a big unit: its base troop's behaviour, the hero's stats and
# look. It comes out from the wall at the start and again each wave if it fell.
func _spawn_hero() -> void:
	var id := PlayerData.leader()
	if id == "" or (_hero_unit != null and is_instance_valid(_hero_unit) and not _hero_unit.is_dead()):
		return
	var hero: Dictionary = Heroes.HEROES[id]
	var h: Dictionary = PlayerData.hero_state(id)
	var troop: Resource = PlayerData.TROOPS[hero["troop"]]
	var unit = UnitScene.instantiate()
	unit.hero_id = id
	unit.setup(self, troop, PLAYER, 1, Heroes.hp_mult(h["level"], h["stars"]) * _hero_hp, Heroes.damage_mult(h["level"], h["stars"]) * _hero_damage)
	unit.position = HERO_AT
	unit.rally = Vector2(FIELD_LEFT + (FIELD_RIGHT - FIELD_LEFT) / 2.0, RALLY_Y + (150.0 if troop.role != TroopData.Role.MELEE else 40.0))
	units_layer.add_child(unit)
	player_units.append(unit)
	_hero_unit = unit
	spawn_effect("blast", HERO_AT + Vector2(0, -30), 0.9)
	SoundLib.play("hero", -2.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		start_wave()
		get_viewport().set_input_as_handled()


func accepts_input() -> bool:
	return phase == "shop" or phase == "fight"


func is_sell_zone(point: Vector2) -> bool:
	return SELL_RECT.has_point(point)


func units_of(team: int) -> Array:
	return player_units if team == PLAYER else enemy_units


## 1-based number of the wave being fought, or of the one the shop is preparing for.
func wave_number() -> int:
	return mini(waves.wave_index + (2 if phase == "shop" else 1), waves.total())


# --- Shop -------------------------------------------------------------------------------

func start_wave() -> void:
	if phase != "shop":
		return
	phase = "fight"
	waves.start_next()
	shop_changed.emit()


func can_buy(slot: int) -> bool:
	if phase != "shop" or slot < 0 or slot >= shop.size():
		return false
	var offer: Dictionary = shop[slot]
	return not offer["sold"] and core.can_afford(offer["price"]) and not board.is_full()


## Buys the offer in `slot` onto the board. Returns the new gear or null.
func buy(slot: int):
	if phase != "shop" or slot < 0 or slot >= shop.size() or shop[slot]["sold"]:
		return null
	var offer: Dictionary = shop[slot]
	if board.is_full():
		hud.show_message("Bàn đã đầy, hãy ghép hoặc bán bớt gear!", hud.WARN)
		return null
	if not core.can_afford(offer["price"]):
		hud.show_message("Chưa đủ thịt (cần %d)." % offer["price"], hud.WARN)
		return null
	core.spend(offer["price"])
	SoundLib.play("buy")
	offer["sold"] = true
	var gear = board.place_new(PlayerData.TROOPS[offer["id"]], offer["tier"])
	spawn_effect("dust", gear.global_position + Vector2(0, 10), 1.6)
	if not _merge_hint_shown and _has_merge_pair():
		_merge_hint_shown = true
		hud.show_message("Có 2 gear giống nhau! Kéo gear này thả lên gear kia để ghép.")
	shop_changed.emit()
	return gear


## True when the board already has a gear this offer would merge with.
func offer_merges(slot: int) -> bool:
	var offer: Dictionary = shop[slot]
	for gear in board.gears.values():
		if gear.troop.id == offer["id"] and gear.tier == offer["tier"] and gear.tier < board.MAX_TIER:
			return true
	return false


func reroll_cost() -> int:
	return 0 if free_rerolls > 0 else int(Economy.BATTLE_SHOP.get("reroll_cost", 1))


func reroll() -> bool:
	if phase != "shop" or not core.can_afford(reroll_cost()):
		return false
	if free_rerolls > 0:
		free_rerolls -= 1
	else:
		core.spend(reroll_cost())
	shop_locked = false
	_roll_shop()
	SoundLib.play("reroll")
	shop_changed.emit()
	return true


func toggle_lock() -> void:
	shop_locked = not shop_locked
	shop_changed.emit()


## What clearing the coming wave would pay right now: [income, interest].
func income_preview() -> Array:
	return [Economy.round_income(wave_number(), PlayerData.round_income_bonus()), Economy.interest(core.meat)]


func _open_shop() -> void:
	phase = "shop"
	# A locked shop keeps its offers for one break, then unlocks.
	if shop_locked and not shop.is_empty():
		shop_locked = false
	else:
		_roll_shop()
	free_rerolls = int(Economy.BATTLE_SHOP.get("free_rerolls", 1))
	shop_changed.emit()


func _roll_shop() -> void:
	shop = ShopRoller.roll(_pool, wave_number())


func sell_gear(gear) -> void:
	SoundLib.play("sell")
	var refund := Economy.sell_refund(gear.troop.rarity, gear.tier)
	core.add_meat(refund)
	board.remove_gear(gear)
	hud.show_message("Đã bán gear, hoàn %d thịt." % refund)
	shop_changed.emit()


func on_gear_merged(gear) -> void:
	SoundLib.play("merge")
	spawn_effect("dust", gear.global_position + Vector2(0, 10), 2.2)
	hud.show_message("%s lên bậc %d!" % [gear.troop.display_name, gear.tier])
	shop_changed.emit()


func spawn_player_unit(troop: Resource, tier: int, at: Vector2):
	if player_units.size() >= Economy.MAX_PLAYER_UNITS:
		return null
	var mult: float = _tier_mult[tier - 1] * PlayerData.troop_multiplier(troop.id)
	var unit = UnitScene.instantiate()
	unit.setup(self, troop, PLAYER, tier, mult * _hero_hp, mult * _hero_damage)
	unit.position = at
	var hold_back := 0.0
	match troop.role:
		TroopData.Role.RANGED:
			hold_back = 120.0
		TroopData.Role.HEALER:
			hold_back = 170.0
		TroopData.Role.SUPPORT:
			hold_back = 200.0
	unit.rally = Vector2(randf_range(FIELD_LEFT + 30, FIELD_RIGHT - 30), RALLY_Y + hold_back + randf_range(-40, 40))
	units_layer.add_child(unit)
	player_units.append(unit)
	if troop.rarity >= 3:
		spawn_effect("blast", at + Vector2(0, -20), 0.7)
		hud.show_message("%s xuất trận!" % troop.display_name)
	return unit


func on_unit_died(unit) -> void:
	SoundLib.play("death" if unit.team == PLAYER else "pop", -1.0, 0.12)
	if unit.team == PLAYER:
		player_units.erase(unit)
		if unit == _hero_unit:
			spawn_effect("explosion", unit.position + Vector2(0, -30), 0.8)
			hud.show_message("%s đã ngã! Sẽ trở lại ở đợt sau." % Heroes.HEROES[unit.hero_id]["name"], hud.WARN)
			return
		spawn_effect("dust", unit.position + Vector2(0, -8), 1.1)
		return
	enemy_units.erase(unit)
	core.add_meat(Economy.ELITE_KILL_MEAT if unit.elite else Economy.KILL_MEAT)
	if unit.elite:
		spawn_effect("explosion", unit.position + Vector2(0, -30), 0.8)
		hud.show_message("Hạ gục tinh nhuệ! +%d thịt" % Economy.ELITE_KILL_MEAT)
	else:
		spawn_effect("dust", unit.position + Vector2(0, -8), 1.1)


func damage_core(amount: float) -> void:
	if phase == "fight":
		SoundLib.play("wall", -3.0, 0.1)
		# Troops hit the wall for a fraction of their damage, so a few leakers hurt
		# without ending the level on the spot.
		core.take_damage(Economy.siege_damage(amount))


## Fires the shooter's projectile: an arrow (burning for fire archers) or a lobbed bomb.
func spawn_arrow(shooter, target, amount: float, crit := false) -> void:
	SoundLib.play("arrow", -2.0, 0.15)
	var arrow = Projectile.new()
	var troop: Resource = shooter.troop
	arrow.battle = self
	arrow.team = shooter.team
	arrow.target = target
	arrow.damage = amount
	arrow.crit = crit
	arrow.hits_core = target == null
	arrow.position = shooter.position + Vector2(0, -26)
	arrow.point = target.position if target != null else Vector2(shooter.position.x, WALL_Y + 8)
	match troop.ability:
		TroopData.Ability.BOMB:
			arrow.texture = SpriteLib.bomb_texture()
			arrow.splash_radius = troop.ability_radius
		TroopData.Ability.BURN:
			arrow.burn_dps = troop.ability_value * amount / maxf(troop.damage, 0.01)
			arrow.burn_time = troop.ability_duration
			arrow.modulate = Color(1.0, 0.6, 0.3)
	if arrow.texture == null:
		var color := "Blue" if shooter.team == PLAYER else "Red"
		arrow.texture = SpriteLib.texture("Units/%s Units/Archer/Arrow.png" % color)
	projectiles.add_child(arrow)


## A cook's meat flies from the cook to the master gear, then counts.
func cook_meat(cook, amount: float) -> void:
	var meat := Sprite2D.new()
	meat.texture = SpriteLib.texture("Terrain/Resources/Meat/Meat Resource/Meat Resource.png")
	meat.position = cook.position + Vector2(0, -30)
	meat.scale = Vector2(0.6, 0.6)
	effects.add_child(meat)
	var tween := meat.create_tween()
	tween.tween_property(meat, "position", core.position, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(meat, "scale", Vector2(0.35, 0.35), 0.6)
	tween.tween_callback(func():
		if accepts_input():
			core.add_meat(amount)
		meat.queue_free())


func spawn_effect(effect: String, at: Vector2, effect_scale := 1.0) -> void:
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = SpriteLib.effect_frames(effect)
	fx.position = at
	fx.scale = Vector2(effect_scale, effect_scale)
	fx.animation_finished.connect(fx.queue_free)
	effects.add_child(fx)
	fx.play("default")


## A short "CHÍ MẠNG!" that floats up where a critical hit landed. Throttled so a big
## fight doesn't fill the screen with text.
func show_crit(at: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_crit_text < CRIT_TEXT_GAP:
		return
	_last_crit_text = now
	var text := UiKit.label("CHÍ MẠNG!", 20, Color(1.0, 0.82, 0.25))
	text.add_theme_color_override("font_outline_color", Color(0.35, 0.08, 0.02))
	text.add_theme_constant_override("outline_size", 6)
	if UiKit.game_font() != null:
		text.add_theme_font_override("font", UiKit.game_font())
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.size = Vector2(160, 30)
	text.pivot_offset = text.size / 2.0
	text.position = at - Vector2(80, 62)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.z_index = 30
	text.scale = Vector2(0.6, 0.6)
	effects.add_child(text)
	var tween := text.create_tween()
	tween.tween_property(text, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(text, "position:y", text.position.y - 30.0, 0.7)
	tween.tween_property(text, "modulate:a", 0.0, 0.25)
	tween.tween_callback(text.queue_free)


func restart() -> void:
	get_tree().reload_current_scene()


func next_level() -> void:
	PlayerData.select_level(PlayerData.current_level + 1)
	get_tree().reload_current_scene()


func go_home() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(HOME_SCENE)


func _has_merge_pair() -> bool:
	var gears: Array = board.gears.values()
	for i in gears.size():
		for j in range(i + 1, gears.size()):
			if board.can_merge(gears[i], gears[j]):
				return true
	return false


func _spawn_enemy(troop_id: String, elite: bool) -> void:
	var troop: Resource = PlayerData.TROOPS[troop_id]
	var mult: float = Economy.enemy_multiplier(level.enemy_power, waves.wave_index)
	var unit = UnitScene.instantiate()
	unit.setup(self, troop, ENEMY, 1, mult * (Economy.ELITE_HP_MULT if elite else 1.0), mult * (Economy.ELITE_DAMAGE_MULT if elite else 1.0), elite)
	var x := randf_range(FIELD_LEFT + 20, FIELD_RIGHT - 20)
	unit.position = Vector2(x, ENEMY_SPAWN_Y - randf_range(0, 40))
	var hang_back: bool = troop.role == TroopData.Role.HEALER or troop.role == TroopData.Role.SUPPORT
	unit.rally = Vector2(x, WALL_Y - (170.0 if hang_back else 0.0))
	units_layer.add_child(unit)
	enemy_units.append(unit)
	if elite:
		hud.show_message("Tinh nhuệ %s xuất hiện!" % troop.display_name, hud.WARN)


func _on_wave_started(index: int, total: int) -> void:
	SoundLib.play("wave", 0.0, 0.0)
	hud.show_message("Đợt %d/%d đang tới!" % [index + 1, total], hud.WARN)
	if PlayerData.leader() != "" and (_hero_unit == null or not is_instance_valid(_hero_unit) or _hero_unit.is_dead()):
		_spawn_hero()
		hud.show_message("%s trở lại chiến trường!" % Heroes.HEROES[PlayerData.leader()]["name"])


func _on_wave_cleared(index: int) -> void:
	if phase != "fight":
		return
	# Interest counts what was saved before the income lands.
	var interest := Economy.interest(core.meat)
	var income := Economy.round_income(index + 1, PlayerData.round_income_bonus())
	core.add_meat(income + interest)
	SoundLib.play("coin")
	_open_shop()
	hud.on_wave_cleared(index, income, interest)


func _on_all_waves_cleared() -> void:
	if phase != "fight":
		return
	phase = "won"
	var ratio: float = core.hp / core.max_hp
	var stars := Economy.battle_stars(ratio)
	var reward: Dictionary = PlayerData.grant_battle_rewards(true, stars, level.waves.size())
	# The troops dance first; the result panel follows.
	SoundLib.play("victory", 0.0, 0.0)
	_celebrate()
	var delay := get_tree().create_timer(VICTORY_DANCE_TIME)
	delay.timeout.connect(func(): hud.show_end(true, stars, "Thành còn %d%% máu" % roundi(ratio * 100.0), reward))


## Every soldier left standing jumps for joy, with confetti over the field.
func _celebrate() -> void:
	for unit in player_units:
		if is_instance_valid(unit) and not unit.is_dead():
			unit.celebrate()
	var colors := [Color("ffd35c"), Color("e0586a"), Color("5aa9e6"), Color("7fd66b"), Color("c28bff")]
	for i in colors.size():
		var confetti := CPUParticles2D.new()
		confetti.position = Vector2(360, 60)
		confetti.amount = 30
		confetti.lifetime = 2.6
		confetti.one_shot = true
		confetti.explosiveness = 0.85
		confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		confetti.emission_rect_extents = Vector2(340, 20)
		confetti.direction = Vector2(0, 1)
		confetti.spread = 30.0
		confetti.initial_velocity_min = 80.0
		confetti.initial_velocity_max = 220.0
		confetti.gravity = Vector2(0, 160)
		confetti.angular_velocity_min = -360.0
		confetti.angular_velocity_max = 360.0
		confetti.scale_amount_min = 4.0
		confetti.scale_amount_max = 7.0
		confetti.color = colors[i]
		effects.add_child(confetti)
		confetti.emitting = true
		confetti.finished.connect(confetti.queue_free)


func _on_core_destroyed() -> void:
	phase = "lost"
	SoundLib.play("defeat", 0.0, 0.0)
	SoundLib.play("explosion")
	waves.stop()
	units_layer.process_mode = Node.PROCESS_MODE_DISABLED
	projectiles.process_mode = Node.PROCESS_MODE_DISABLED
	spawn_effect("explosion", core.position, 1.2)
	var waves_cleared: int = maxi(0, waves.wave_index)
	var reward: Dictionary = PlayerData.grant_battle_rewards(false, 0, waves_cleared)
	hud.show_end(false, 0, "Cầm cự tới đợt %d/%d. Nâng cấp lính và thành rồi thử lại!" % [waves.wave_index + 1, level.waves.size()], reward)
