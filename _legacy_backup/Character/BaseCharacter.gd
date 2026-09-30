extends CharacterBody2D

const SPEED = 200.0

enum State {
	IDLE,
	MOVE,
	ATTACK,
}

var current_state: State = State.IDLE
var attack_timer: float = 0.0
var move_target: Vector2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("units")
	animated_sprite.play("idle")

func command_move(destination: Vector2):
	move_target = destination	
	set_state(State.MOVE)

func command_attack():
	set_state(State.ATTACK)

func set_selected(selected: bool):
	animated_sprite.modulate = Color(1.0, 0.8, 0.45) if selected else Color.WHITE

func _physics_process(delta):
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.MOVE:
			_handle_move_state()
		State.ATTACK:
			_handle_attack_state(delta)

	move_and_slide()

func _handle_move_state():
	var offset = move_target - global_position
	if offset.length() <= 4.0:
		velocity = Vector2.ZERO
		set_state(State.IDLE)
	else:
		velocity = offset.normalized() * SPEED
		animated_sprite.flip_h = offset.x < 0.0

func _handle_attack_state(delta):
	velocity = Vector2.ZERO
	attack_timer -= delta
	if attack_timer <= 0.0:
		set_state(State.IDLE)

func set_state(new_state: State):
	if current_state == new_state:
		return

	current_state = new_state

	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.MOVE:
			animated_sprite.play("walk")
		State.ATTACK:
			animated_sprite.play("attack")
			attack_timer = 0.35
