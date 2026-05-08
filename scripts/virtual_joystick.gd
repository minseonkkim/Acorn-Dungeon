extends Control
class_name VirtualJoystick

@export var max_radius: float = 50.0
@export var dead_zone: float = 0.15

@onready var background: Control = $Background
@onready var knob: Control = $Background/Knob

var _touch_index: int = -1
var _direction: Vector2 = Vector2.ZERO
var _origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	await get_tree().process_frame
	_origin = background.global_position + background.size * 0.5
	_reset_knob()

func get_direction() -> Vector2:
	return _direction

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			_update_touch(d.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _touch_index == -1 and _is_inside(mb.position):
				_touch_index = 0
				_update_touch(mb.position)
			elif not mb.pressed and _touch_index == 0:
				_end_touch()
	elif event is InputEventMouseMotion and _touch_index == 0:
		_update_touch((event as InputEventMouseMotion).position)

func _handle_touch(t: InputEventScreenTouch) -> void:
	if t.pressed:
		if _touch_index == -1 and _is_inside(t.position):
			_touch_index = t.index
			_update_touch(t.position)
	elif t.index == _touch_index:
		_end_touch()

func _is_inside(pos: Vector2) -> bool:
	var center := background.global_position + background.size * 0.5
	return pos.distance_to(center) <= max_radius * 1.4

func _update_touch(pos: Vector2) -> void:
	var offset: Vector2 = pos - _origin
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
	knob.global_position = _origin + offset - knob.size * 0.5
	var ratio: float = offset.length() / max_radius
	if ratio < dead_zone:
		_direction = Vector2.ZERO
	else:
		_direction = offset.normalized() * minf(1.0, ratio)

func _end_touch() -> void:
	_touch_index = -1
	_direction = Vector2.ZERO
	_reset_knob()

func _reset_knob() -> void:
	knob.global_position = _origin - knob.size * 0.5
