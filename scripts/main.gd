extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_count: int = 4
@export var spawn_radius: float = 180.0
@export var respawn_interval: float = 4.0

@onready var player: Player = $Player
@onready var joystick: VirtualJoystick = $UI/VirtualJoystick
@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	if enemy_scene == null:
		enemy_scene = load("res://scenes/acorn_bug.tscn")
	player.joystick = joystick
	spawn_timer.wait_time = respawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	_spawn_initial_enemies()

func _spawn_initial_enemies() -> void:
	for i in spawn_count:
		var angle: float = (TAU / spawn_count) * i
		_spawn_enemy_at_angle(angle)

func _on_spawn_timer_timeout() -> void:
	if not is_instance_valid(player):
		return
	if get_tree().get_nodes_in_group("enemies").size() >= 8:
		return
	_spawn_enemy_at_angle(randf() * TAU)

func _spawn_enemy_at_angle(angle: float) -> void:
	if not is_instance_valid(player):
		return
	var pos: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * spawn_radius
	var enemy := enemy_scene.instantiate()
	enemy.global_position = pos
	add_child(enemy)
