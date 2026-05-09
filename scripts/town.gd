extends Node2D

const _AcornTreeUIScript    := preload("res://scripts/acorn_tree_ui.gd")
const _CharSelectUIScript   := preload("res://scripts/character_select_ui.gd")

const _C_BG      := Color(0.10, 0.15, 0.08)
const _C_TEXT    := Color(0.95, 0.90, 0.75)
const _C_ACORN   := Color(1.0, 0.85, 0.2)
const _C_BTN     := Color(0.28, 0.42, 0.18)
const _C_BTN_HVR := Color(0.38, 0.54, 0.24)
const _C_BTN_PRS := Color(0.20, 0.32, 0.12)

var _acorn_label: Label
var _stats_label: Label
var _tree_ui: CanvasLayer
var _char_ui: CanvasLayer

func _ready() -> void:
	_build_background()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	_build_header(canvas)
	_build_stats(canvas)
	_build_buttons(canvas)
	_build_overlays()
	_refresh()

# ─── UI 빌드 ────────────────────────────────────────────────

func _build_background() -> void:
	# Sprite2D로 뷰포트(360x640) 정확히 채움 — 원본 577x1023
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/backgrounds/town_bg.png")
	bg.centered = true
	bg.position = Vector2(180.0, 320.0)
	bg.scale = Vector2(360.0 / 577.0, 640.0 / 1023.0)
	add_child(bg)
	# 장식용 수평선
	var line1 := ColorRect.new()
	line1.color = Color(0.25, 0.38, 0.15, 0.6)
	line1.size = Vector2(360.0, 1.0)
	line1.position = Vector2(0.0, 290.0)
	add_child(line1)

func _build_header(canvas: CanvasLayer) -> void:
	var title := _make_lbl("도토리 던전", 30, _C_ACORN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(360.0, 55.0)
	title.position = Vector2(0.0, 58.0)
	canvas.add_child(title)

	var tree := _make_lbl("[나무]", 52, Color(0.4, 0.75, 0.3))
	tree.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tree.size = Vector2(360.0, 80.0)
	tree.position = Vector2(0.0, 118.0)
	canvas.add_child(tree)

func _build_stats(canvas: CanvasLayer) -> void:
	# 도토리 아이콘 + 수치 (HBox로 중앙 정렬)
	# 도토리 아이콘 (Sprite2D: 128x128 → 26x26, scale=0.203)
	var acorn_icon := Sprite2D.new()
	acorn_icon.texture = load("res://assets/ui/icon_acorn.png")
	acorn_icon.centered = true
	acorn_icon.position = Vector2(167.0, 223.0)  # 아이콘 중심
	acorn_icon.scale = Vector2(26.0 / 128.0, 26.0 / 128.0)
	canvas.add_child(acorn_icon)

	_acorn_label = _make_lbl("", 17, _C_ACORN)
	_acorn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_acorn_label.size = Vector2(80.0, 26.0)
	_acorn_label.position = Vector2(180.0, 210.0)
	canvas.add_child(_acorn_label)

	_stats_label = _make_lbl("", 13, Color(0.70, 0.70, 0.70))
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.size = Vector2(360.0, 24.0)
	_stats_label.position = Vector2(0.0, 248.0)
	canvas.add_child(_stats_label)

func _build_buttons(canvas: CanvasLayer) -> void:
	var entries := [
		["던전 입장", _on_enter_dungeon],
		["도토리 나무", _on_open_tree],
		["캐릭터 선택", _on_open_char],
	]
	var y := 306.0
	for e in entries:
		var btn := _make_btn(str(e[0]))
		btn.position = Vector2(80.0, y)
		btn.pressed.connect(e[1])
		canvas.add_child(btn)
		y += 72.0

func _build_overlays() -> void:
	_tree_ui = _AcornTreeUIScript.new()
	add_child(_tree_ui)
	_tree_ui.closed.connect(_refresh)

	_char_ui = _CharSelectUIScript.new()
	add_child(_char_ui)
	_char_ui.closed.connect(_refresh)

# ─── 갱신 ───────────────────────────────────────────────────

func _refresh() -> void:
	_acorn_label.text = "%d" % SaveManager.acorns
	var best := SaveManager.best_floor
	if best > 0:
		_stats_label.text = "최고 기록 %d층   총 런 %d회" % [best, SaveManager.total_runs]
	else:
		_stats_label.text = "아직 기록이 없습니다"

# ─── 이벤트 ─────────────────────────────────────────────────

func _on_enter_dungeon() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_open_tree() -> void:
	_tree_ui.open()

func _on_open_char() -> void:
	_char_ui.open()

# ─── 헬퍼 ───────────────────────────────────────────────────

func _make_lbl(text_val: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text_val
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _make_btn(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.size = Vector2(200.0, 52.0)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", _C_TEXT)
	for pair in [["normal", _C_BTN], ["hover", _C_BTN_HVR], ["pressed", _C_BTN_PRS]]:
		var s := StyleBoxFlat.new()
		s.bg_color = pair[1] as Color
		s.corner_radius_top_left    = 7
		s.corner_radius_top_right   = 7
		s.corner_radius_bottom_left = 7
		s.corner_radius_bottom_right = 7
		btn.add_theme_stylebox_override(str(pair[0]), s)
	return btn
