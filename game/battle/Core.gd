extends Node2D

# The cat-operated master drive in its grid cell. It never stops and drives every gear chained to
# it; the castle's HP is the level's life, and it stores the meat the
# between-wave shop spends. Meat comes from wave income, interest on savings and kills.

signal destroyed

const CatDrive = preload("res://game/battle/CatDrive.gd")

const Economy = preload("res://game/core/Economy.gd")
## Radius of the pin's rounded tip; fits the gear's tooth gap where the tip travels.
const PIN_TIP := 2.5

var board
var max_hp := 100.0
var hp := 100.0
var meat := 0.0
var max_meat := 10.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var angle: float = board.pin_angle() if board else -PI / 2.0
	CatDrive.draw_drive(self, angle, board.PIN_REACH if board else 51.0, PIN_TIP)


# Castle level and workshop upgrades from PlayerData shape every level.
func setup(level: Resource) -> void:
	max_hp = level.core_hp * PlayerData.core_hp_multiplier()
	hp = max_hp
	max_meat = PlayerData.max_meat()
	meat = minf(max_meat, level.start_meat + PlayerData.start_meat_bonus())


func can_afford(cost: int) -> bool:
	return meat >= cost


func spend(cost: int) -> void:
	meat -= cost


func add_meat(amount: float) -> void:
	meat = minf(max_meat, meat + amount)


func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	modulate = Color(1.0, 0.6, 0.6)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
	if hp <= 0.0:
		destroyed.emit()
