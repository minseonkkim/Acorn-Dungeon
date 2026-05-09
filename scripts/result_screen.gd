extends CanvasLayer
class_name ResultScreen

signal retry_requested
signal town_requested

@onready var _title: Label = $Panel/Title
@onready var _kills_label: Label  = $Panel/KillsRow/Value
@onready var _time_label: Label   = $Panel/TimeRow/Value
@onready var _rooms_label: Label  = $Panel/RoomsRow/Value
@onready var _acorn_label: Label  = $Panel/AcornRow/Value
@onready var _retry: Button = $Panel/RetryButton
@onready var _town: Button  = $Panel/TownButton

func _ready() -> void:
	visible = false
	_retry.pressed.connect(_on_retry_pressed)
	_town.pressed.connect(_on_town_pressed)
	# AcornRow 맨 앞에 도토리 아이콘 (TextureRect: HBoxContainer 안이라 size 적용됨)
	var acorn_icon := TextureRect.new()
	acorn_icon.texture = load("res://assets/ui/icon_acorn.png")
	acorn_icon.custom_minimum_size = Vector2(18.0, 18.0)
	acorn_icon.stretch_mode = TextureRect.STRETCH_SCALE
	acorn_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	$Panel/AcornRow.add_child(acorn_icon)
	$Panel/AcornRow.move_child(acorn_icon, 0)

func show_result(victory: bool, kills: int, run_time: float, floors_cleared: int, acorns_earned: int) -> void:
	if victory:
		_title.text = "던전 클리어!"
		_title.modulate = Color(1.0, 0.85, 0.2)
	else:
		_title.text = "사망"
		_title.modulate = Color(1.0, 0.45, 0.45)
	_kills_label.text = str(kills)
	_time_label.text = _format_time(run_time)
	_rooms_label.text = str(floors_cleared)
	_acorn_label.text = "+%d" % acorns_earned
	visible = true

func _format_time(t: float) -> String:
	var m: int = int(t) / 60
	var s: int = int(t) % 60
	return "%02d:%02d" % [m, s]

func _on_retry_pressed() -> void:
	retry_requested.emit()

func _on_town_pressed() -> void:
	town_requested.emit()
