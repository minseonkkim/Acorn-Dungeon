extends Area2D
class_name SpikeZone

@export var damage_per_tick: int = 8
@export var tick_interval: float = 0.5
@export var lifetime: float = 4.0

var _tick_cd: float = 0.3
var _life: float = 0.0

func _process(delta: float) -> void:
	_life += delta
	if _life >= lifetime:
		queue_free()
		return
	_tick_cd -= delta
	if _tick_cd <= 0.0:
		_tick_cd = tick_interval
		for body in get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(damage_per_tick, Combat.DamageType.TRUE)
