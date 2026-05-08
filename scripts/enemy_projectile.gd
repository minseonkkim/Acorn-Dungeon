extends Area2D
class_name EnemyProjectile

@export var speed: float = 150.0
@export var lifetime: float = 2.0
@export var damage: int = 8

var direction: Vector2 = Vector2.RIGHT
var _life: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func set_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	direction = dir.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	_life += delta
	if _life >= lifetime:
		queue_free()
		return
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, Combat.DamageType.PHYSICAL)
		queue_free()
