extends CanvasLayer

signal closed

# 화면 좌표 기준 (360x640 뷰포트)
const _C_DIM     := Color(0.0, 0.0, 0.0, 0.72)
const _C_PANEL   := Color(0.10, 0.14, 0.08)
const _C_TEXT    := Color(0.95, 0.90, 0.75)
const _C_ACORN   := Color(1.0, 0.85, 0.2)
const _C_UPGRADE := Color(0.50, 0.35, 0.10)
const _C_MAXED   := Color(0.18, 0.42, 0.18)
const _C_LOCKED  := Color(0.25, 0.25, 0.25)
const _C_ROWBG   := Color(0.07, 0.10, 0.05)

var _acorn_label: Label
var _rows: Array = []  # Array of { id, name_label, btn, max_level }

func _ready() -> void:
	layer = 8
	visible = false
	_build_ui()

func open() -> void:
	_refresh()
	visible = true

# ─── UI 빌드 ────────────────────────────────────────────────

func _build_ui() -> void:
	_add_color_rect(Vector2(0.0, 0.0), Vector2(360.0, 640.0), _C_DIM)
	_add_color_rect(Vector2(20.0, 55.0), Vector2(320.0, 460.0), _C_PANEL)

	var title := _make_label("도토리 나무", 20, _C_ACORN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(320.0, 38.0)
	title.position = Vector2(20.0, 65.0)
	add_child(title)

	# 도토리 아이콘 (Sprite2D: 128x128 → 20x20, scale=0.156)
	var acorn_icon := Sprite2D.new()
	acorn_icon.texture = load("res://assets/ui/icon_acorn.png")
	acorn_icon.centered = true
	acorn_icon.position = Vector2(150.0, 118.0)  # 아이콘 중심
	acorn_icon.scale = Vector2(20.0 / 128.0, 20.0 / 128.0)
	add_child(acorn_icon)

	_acorn_label = _make_label("", 14, _C_ACORN)
	_acorn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_acorn_label.size = Vector2(70.0, 20.0)
	_acorn_label.position = Vector2(162.0, 108.0)
	add_child(_acorn_label)

	_add_color_rect(Vector2(40.0, 140.0), Vector2(280.0, 1.0), Color(0.4, 0.4, 0.4, 0.5))

	var row_y := 148.0
	for u: Dictionary in SaveManager.TREE_UPGRADES:
		_build_row(u, row_y)
		row_y += 76.0

	var close_btn := _make_styled_button("닫기", Color(0.35, 0.22, 0.10))
	close_btn.size = Vector2(140.0, 42.0)
	close_btn.position = Vector2(110.0, 462.0)
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

func _build_row(u: Dictionary, y: float) -> void:
	_add_color_rect(Vector2(34.0, y), Vector2(292.0, 66.0), _C_ROWBG)

	var name_lbl := _make_label("", 13, _C_TEXT)
	name_lbl.size = Vector2(188.0, 22.0)
	name_lbl.position = Vector2(42.0, y + 6.0)
	add_child(name_lbl)

	var desc_lbl := _make_label(str(u["desc"]), 11, Color(0.68, 0.68, 0.68))
	desc_lbl.size = Vector2(188.0, 18.0)
	desc_lbl.position = Vector2(42.0, y + 28.0)
	add_child(desc_lbl)

	var btn := _make_styled_button("", _C_UPGRADE)
	btn.size = Vector2(88.0, 34.0)
	btn.position = Vector2(230.0, y + 16.0)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(_on_upgrade.bind(str(u["id"])))
	add_child(btn)

	_rows.append({
		"id": str(u["id"]),
		"name_lbl": name_lbl,
		"btn": btn,
		"max_level": int(u["max_level"]),
	})

# ─── 갱신 ───────────────────────────────────────────────────

func _refresh() -> void:
	_acorn_label.text = "%d" % SaveManager.acorns

	for row in _rows:
		var uid: String = row["id"]
		var max_lv: int = row["max_level"]
		var lv := SaveManager.get_upgrade_level(uid)
		var name_lbl: Label = row["name_lbl"]
		var btn: Button = row["btn"]

		for u: Dictionary in SaveManager.TREE_UPGRADES:
			if str(u["id"]) == uid:
				name_lbl.text = "%s  %s" % [str(u["name"]), _stars(lv, max_lv)]
				break

		var style := StyleBoxFlat.new()
		style.corner_radius_top_left    = 4
		style.corner_radius_top_right   = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4

		if lv >= max_lv:
			btn.text = "완료"
			btn.disabled = true
			style.bg_color = _C_MAXED
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("disabled", style)
		else:
			var cost := SaveManager.get_upgrade_cost(uid)
			btn.text = "%d" % cost
			btn.disabled = not SaveManager.can_upgrade(uid)
			style.bg_color = _C_UPGRADE if SaveManager.can_upgrade(uid) else _C_LOCKED
			btn.add_theme_stylebox_override("normal", style)
			var dis_style := StyleBoxFlat.new()
			dis_style.corner_radius_top_left    = 4
			dis_style.corner_radius_top_right   = 4
			dis_style.corner_radius_bottom_left = 4
			dis_style.corner_radius_bottom_right = 4
			dis_style.bg_color = _C_LOCKED
			btn.add_theme_stylebox_override("disabled", dis_style)

func _stars(level: int, max_level: int) -> String:
	var s := ""
	for i in max_level:
		s += "★" if i < level else "☆"
	return s

# ─── 이벤트 ─────────────────────────────────────────────────

func _on_upgrade(upgrade_id: String) -> void:
	SaveManager.upgrade_tree(upgrade_id)
	_refresh()

func _on_close() -> void:
	visible = false
	closed.emit()

# ─── 헬퍼 ───────────────────────────────────────────────────

func _add_color_rect(pos: Vector2, sz: Vector2, color: Color) -> ColorRect:
	var cr := ColorRect.new()
	cr.position = pos
	cr.size = sz
	cr.color = color
	add_child(cr)
	return cr

func _make_label(text_val: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text_val
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _make_styled_button(label_text: String, bg_color: Color) -> Button:
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
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = bg_color.lightened(0.15)
	hover_style.corner_radius_top_left    = 5
	hover_style.corner_radius_top_right   = 5
	hover_style.corner_radius_bottom_left = 5
	hover_style.corner_radius_bottom_right = 5
	btn.add_theme_stylebox_override("hover", hover_style)
	return btn
