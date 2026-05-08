extends CharacterBody2D
class_name AcornBug

@export var move_speed: float = 50.0
@export var max_hp: int = 20
@export var contact_damage: int = 5
@export var contact_cooldown: float = 0.6

var current_hp: int
var _attack_cd: float = 0.0

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	_attack_cd = max(_attack_cd - delta, 0.0)
	var player := _get_player()
	if player == null:
		velocity = Vector2.ZERO
	else:
		var to_player: Vector2 = player.global_position - global_position
		if to_player.length() > 1.0:
			velocity = to_player.normalized() * move_speed
		else:
			velocity = Vector2.ZERO
	move_and_slide()
	_check_contact_damage()

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node2D

func _check_contact_damage() -> void:
	if _attack_cd > 0.0:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider != null and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(contact_damage)
			_attack_cd = contact_cooldown
			return

func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		queue_free()
