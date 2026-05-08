extends CharacterBody2D
class_name Player

@export var move_speed: float = 110.0
@export var max_hp: int = 80
@export var attack_damage: int = 10
@export var attack_speed: float = 1.2
@export var attack_range: float = 120.0

var current_hp: int
var joystick: Node = null

@onready var attack_timer: Timer = $AttackTimer

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")

signal hp_changed(new_hp: int, max_hp: int)
signal died

func _ready() -> void:
	current_hp = max_hp
	add_to_group("player")
	attack_timer.wait_time = 1.0 / attack_speed
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if joystick != null and joystick.has_method("get_direction"):
		dir = joystick.get_direction()
	if dir == Vector2.ZERO:
		dir.x = Input.get_axis("ui_left", "ui_right")
		dir.y = Input.get_axis("ui_up", "ui_down")
		if dir.length() > 1.0:
			dir = dir.normalized()
	velocity = dir * move_speed
	move_and_slide()

func _on_attack_timer_timeout() -> void:
	var target := _find_nearest_enemy()
	if target == null:
		return
	if global_position.distance_to(target.global_position) > attack_range:
		return
	_spawn_projectile(target)

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := INF
	for e in enemies:
		if not (e is Node2D) or not is_instance_valid(e):
			continue
		var d: float = global_position.distance_squared_to((e as Node2D).global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

func _spawn_projectile(target: Node2D) -> void:
	var p := PROJECTILE_SCENE.instantiate()
	p.global_position = global_position
	var dir: Vector2 = (target.global_position - global_position).normalized()
	p.set_direction(dir)
	p.damage = attack_damage
	get_tree().current_scene.add_child(p)

func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, max_hp)
	if current_hp == 0:
		died.emit()
		queue_free()
