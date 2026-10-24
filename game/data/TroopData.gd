extends Resource

# Stats for one troop type. Player gears and enemy waves both use these; tier, elite and
# level multipliers are applied on top when a unit spawns.

## SUPPORT troops never attack; their ability is all they do.
enum Role { MELEE, RANGED, HEALER, SUPPORT }
## What the four ability_* numbers mean depends on the ability (see Unit.gd):
## TUNNEL   value = share of ranged damage ignored
## FORGE    every cooldown: allies within radius take `value` less damage for `duration`
## ASSASSIN hunts enemy ranged/healers anywhere; first hit deals x`value`
## SHIELD   every cooldown: immune to damage for `duration`
## BURN     hits set the target on fire: `value` damage per second for `duration`
## COOK     every cooldown: +`value` meat (enemy cooks heal allies in radius `value`*10%)
## BOMB     shots explode, hitting every foe within `radius`
## COMMAND  allies within `radius` deal +`value` damage; every cooldown a whirlwind hits
##          all foes around it for `duration` x damage; normal swings also cleave
enum Ability { NONE, TUNNEL, FORGE, ASSASSIN, SHIELD, BURN, COOK, BOMB, COMMAND }
## Class ring (design sheet, Core battle): Tầm xa > Bộ binh > Pháp sư > Kỵ binh > Tầm xa,
## the counter deals x2 damage (Economy.counter_mult).
enum Klass { INFANTRY, RANGED, MAGE, CAVALRY }
const KLASS_NAMES := ["Bộ binh", "Tầm xa", "Pháp sư", "Kỵ binh"]

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
## Economy.Rarity: 0 common, 1 rare, 2 epic, 3 legendary. Decides chest drop rates.
@export_range(0, 3) var rarity := 0
## Drawn unit art: "art:<id>" (game/ui/art or skin unit_<id>), see SpriteLib.cat_texture.
@export var unit_key := "art:kiem"
## Gear art from "Buildings/Blue Buildings/" (without .png).
@export var building := "Barracks"
@export var role: Role = Role.MELEE
@export var klass: Klass = Klass.INFANTRY
## Multiplies the unit's colours so look-alike troops (same sprite) stay distinct.
@export var tint := Color.WHITE
@export var sprite_scale := 1.0

@export var max_hp := 40.0
## Damage per hit, or HP restored per cast for healers.
@export var damage := 6.0
@export var attack_range := 40.0
@export var attack_cooldown := 1.0
@export var move_speed := 60.0
## Chance (0-1) that an attack is a critical hit, and how much a critical hit multiplies
## the damage. Heals, burns and abilities never crit, and only player units crit.
@export_range(0.0, 1.0) var crit_chance := 0.05
@export var crit_mult := 1.5
@export var aggro_range := 220.0

## Seconds between units spawned by a tier-1 gear.
@export var spawn_interval := 4.0
## Units one gear can keep alive at once.
@export var max_alive := 3
## Relative chance to come out of a summon.
@export var summon_weight := 1.0

@export var ability: Ability = Ability.NONE
@export_multiline var ability_text := ""
@export var ability_value := 0.0
@export var ability_duration := 0.0
@export var ability_cooldown := 0.0
@export var ability_radius := 0.0


## Average damage multiplier from critical hits (1.0 for troops that never crit).
func crit_factor() -> float:
	if role == Role.HEALER or role == Role.SUPPORT:
		return 1.0
	return 1.0 + crit_chance * (crit_mult - 1.0)
