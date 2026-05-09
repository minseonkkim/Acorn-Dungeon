extends CanvasLayer

signal closed

const _C_DIM      := Color(0.0, 0.0, 0.0, 0.72)
const _C_PANEL    := Color(0.10, 0.12, 0.18)
const _C_TEXT     := Color(0.95, 0.90, 0.75)
const _C_LOCKED   := Color(0.42, 0.42, 0.42)
const _C_SELECTED := Color(0.12, 0.28, 0.12)
const _C_NORMAL   := Color(0.08, 0.10, 0.16)

# Week 6에서 실제 구현 예정인 캐릭터 정의
const _CHARACTERS: Array = [
	{"id": "doori", "name": "도리",  "icon": "o", "desc": "균형잡힌 모험가"},
	{"id": "tobi",  "name": "토비",  "icon": "o", "desc": "근접 돌격 전사"},
	{"id": "pongi", "name": "퐁이",  "icon": "o", "desc": "원거리 투척가"},
	{"id": "nuni",  "name": "누니",  "icon": "o", "desc": "관통 사수"},
	{"id": "bibi",  "name": "비비",  "icon": "o", "desc": "부채꼴 마법사"},
]

var _card_bgs: Dictionary = {}   # id → ColorRect
var _sel_btns: Dictionary = {}   # id → Button (unlocked only)

func _ready() -> void:
	layer = 8
	visible = false
	_build_ui()

func open() -> void:
	_refresh()
	visible = true

# ─── UI 빌드 ────────────────────────────────────────────────

func _build_ui() -> void:
	_add_cr(Vector2(0.0, 0.0), Vector2(360.0, 640.0), _C_DIM)
	_add_cr(Vector2(20.0, 50.0), Vector2(320.0, 540.0), _C_PANEL)

	var title := _make_lbl("캐릭터 선택", 20, _C_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(320.0, 38.0)
	title.position = Vector2(20.0, 60.0)
	add_child(title)

	var hint := _make_lbl("다른 캐릭터는 Week 6에 추가 예정", 11, Color(0.55, 0.55, 0.55))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(320.0, 20.0)
	hint.position = Vector2(20.0, 102.0)
	add_child(hint)

	var row_y := 128.0
	for c: Dictionary in _CHARACTERS:
		_build_card(c, row_y)
		row_y += 68.0

	var close_btn := _make_btn("닫기", Color(0.35, 0.22, 0.10))
	close_btn.size = Vector2(140.0, 42.0)
	close_btn.position = Vector2(110.0, 556.0)
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

func _build_card(c: Dictionary, y: float) -> void:
	var uid: String = str(c["id"])
	var unlocked: bool = SaveManager.unlocked_characters.has(uid)

	var bg := _add_cr(Vector2(34.0, y), Vector2(292.0, 58.0),
		_C_NORMAL if unlocked else Color(0.06, 0.06, 0.09))
	_card_bgs[uid] = bg

	# 캐릭터 아이콘 (도리는 실제 썸네일, 나머지는 플레이스홀더)
	_add_cr(Vector2(44.0, y + 9.0), Vector2(40.0, 40.0),
		Color(0.20, 0.25, 0.20) if unlocked else Color(0.10, 0.10, 0.10))
	if uid == "doori":
		# Sprite2D: 128x128 → 40x40 슬롯, scale = 40/128
		var thumb := Sprite2D.new()
		thumb.texture = load("res://assets/ui/char_thumb_doori.png")
		thumb.centered = true
		thumb.position = Vector2(64.0, y + 29.0)  # 슬롯 중심 (44+20, y+9+20)
		thumb.scale = Vector2(40.0 / 128.0, 40.0 / 128.0)
		add_child(thumb)
	else:
		var icon_lbl := _make_lbl("?", 20,
			Color(0.7, 0.9, 0.6) if unlocked else Color(0.3, 0.3, 0.3))
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.size = Vector2(40.0, 40.0)
		icon_lbl.position = Vector2(44.0, y + 9.0)
		add_child(icon_lbl)

	var name_lbl := _make_lbl(
		str(c["name"]) if unlocked else "???",
		15, _C_TEXT if unlocked else _C_LOCKED)
	name_lbl.size = Vector2(155.0, 24.0)
	name_lbl.position = Vector2(92.0, y + 8.0)
	add_child(name_lbl)

	var desc_lbl := _make_lbl(
		str(c["desc"]) if unlocked else "잠금 해제 필요",
		11, Color(0.68, 0.68, 0.68) if unlocked else Color(0.38, 0.38, 0.38))
	desc_lbl.size = Vector2(155.0, 20.0)
	desc_lbl.position = Vector2(92.0, y + 32.0)
	add_child(desc_lbl)

	if unlocked:
		var sel_btn := _make_btn("선택", Color(0.22, 0.40, 0.55))
		sel_btn.size = Vector2(56.0, 30.0)
		sel_btn.add_theme_font_size_override("font_size", 12)
		sel_btn.position = Vector2(258.0, y + 14.0)
		sel_btn.pressed.connect(_on_select.bind(uid))
		add_child(sel_btn)
		_sel_btns[uid] = sel_btn
	else:
		var lock_lbl := _make_lbl("🔒", 18, _C_LOCKED)
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.size = Vector2(50.0, 34.0)
		lock_lbl.position = Vector2(256.0, y + 12.0)
		add_child(lock_lbl)

# ─── 갱신 ───────────────────────────────────────────────────

func _refresh() -> void:
	var selected := SaveManager.selected_character
	for uid in _card_bgs:
		var bg: ColorRect = _card_bgs[uid]
		if SaveManager.unlocked_characters.has(uid):
			bg.color = _C_SELECTED if uid == selected else _C_NORMAL

# ─── 이벤트 ─────────────────────────────────────────────────

func _on_select(char_id: String) -> void:
	SaveManager.selected_character = char_id
	SaveManager.save_game()
	_refresh()

func _on_close() -> void:
	visible = false
	closed.emit()

# ─── 헬퍼 ───────────────────────────────────────────────────

func _add_cr(pos: Vector2, sz: Vector2, color: Color) -> ColorRect:
	var cr := ColorRect.new()
	cr.position = pos
	cr.size = sz
	cr.color = color
	add_child(cr)
	return cr

func _make_lbl(text_val: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text_val
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _make_btn(label_text: String, bg_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", _C_TEXT)
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left    = 5
	style.corner_radius_top_right   = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	btn.add_theme_stylebox_override("normal", style)
	var hover := StyleBoxFlat.new()
	hover.bg_color = bg_color.lightened(0.15)
	hover.corner_radius_top_left    = 5
	hover.corner_radius_top_right   = 5
	hover.corner_radius_bottom_left = 5
	hover.corner_radius_bottom_right = 5
	btn.add_theme_stylebox_override("hover", hover)
	return btn
