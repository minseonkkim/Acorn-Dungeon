extends CanvasLayer
class_name HUD

@onready var _hp_fill: ColorRect = $TopLeft/HPBar/Fill
@onready var _hp_label: Label = $TopLeft/HPBar/Label
@onready var _kills_label: Label = $TopLeft/KillsLabel
@onready var _floor_label: Label = $TopRight/FloorLabel
@onready var _boss_bar: Control = $BossBar
@onready var _boss_fill: ColorRect = $BossBar/BG/Fill
@onready var _boss_hp_label: Label = $BossBar/BG/HPLabel

var _hp_bar_width: float = 120.0
var _boss_bar_width: float = 320.0

func _ready() -> void:
	_hp_bar_width = ($TopLeft/HPBar as Control).size.x
	_boss_bar_width = ($BossBar/BG as Control).size.x
	_boss_bar.visible = false

func set_hp(current: int, max_hp: int) -> void:
	if _hp_fill == null:
		return
	var ratio: float = clamp(float(current) / maxf(float(max_hp), 1.0), 0.0, 1.0)
	_hp_fill.size = Vector2(_hp_bar_width * ratio, _hp_fill.size.y)
	_hp_label.text = "%d / %d" % [current, max_hp]

func set_kills(kills: int) -> void:
	_kills_label.text = "처치 %d" % kills

func set_floor(floor_num: int, total: int) -> void:
	_floor_label.text = "층 %d / %d" % [floor_num, total]

func show_boss_bar(show: bool) -> void:
	_boss_bar.visible = show

func set_boss_hp(current: int, max_hp: int) -> void:
	if _boss_fill == null:
		return
	var ratio: float = clamp(float(current) / maxf(float(max_hp), 1.0), 0.0, 1.0)
	if _boss_bar_width <= 0.0:
		_boss_bar_width = ($BossBar/BG as Control).size.x
	_boss_fill.size = Vector2(_boss_bar_width * ratio, _boss_fill.size.y)
	_boss_hp_label.text = "HP %d / %d" % [current, max_hp]
