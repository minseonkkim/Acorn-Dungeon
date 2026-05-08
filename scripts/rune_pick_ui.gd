extends CanvasLayer
class_name RunePickUI

signal rune_chosen(rune_id: String)

const RARITY_COLORS: Dictionary = {
	"common":    Color(0.85, 0.85, 0.85),
	"rare":      Color(0.3,  0.6,  1.0),
	"epic":      Color(0.8,  0.3,  1.0),
	"legendary": Color(1.0,  0.75, 0.1),
}

const CATEGORY_LABELS: Dictionary = {
	"offense": "공격",
	"defense": "방어",
	"utility": "유틸",
	"synergy": "시너지",
}

var _rune_ids: Array[String] = []
var _rune_manager: RuneManager = null

func setup(rune_manager: RuneManager, rune_ids: Array[String]) -> void:
	_rune_manager = rune_manager
	_rune_ids = rune_ids

func _ready() -> void:
	layer = 10
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Dim overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	root.add_child(overlay)

	# Outer CenterContainer fills the screen and centers its single child
	var screen_center := CenterContainer.new()
	screen_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(screen_center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	screen_center.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "— 룬 카드 선택 —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(title)

	# Cards row
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	for rune_id: String in _rune_ids:
		_build_card(hbox, rune_id)

func _build_card(parent: HBoxContainer, rune_id: String) -> void:
	if _rune_manager == null:
		return
	var def: Dictionary = _rune_manager.get_definition(rune_id)
	if def.is_empty():
		return

	var rarity: String   = def.get("rarity",   "common")
	var category: String = def.get("category", "")
	var rarity_color: Color = RARITY_COLORS.get(rarity, Color.WHITE)

	# Card panel
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(100, 170)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.13, 0.96)
	style.border_color = rarity_color
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left   = 8.0
	style.content_margin_right  = 8.0
	style.content_margin_top    = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Rarity badge
	var badge := Label.new()
	badge.text = rarity.to_upper()
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 8)
	badge.add_theme_color_override("font_color", rarity_color)
	vbox.add_child(badge)

	# Name
	var name_label := Label.new()
	name_label.text = def.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)

	# Category
	var cat_label := Label.new()
	cat_label.text = "[%s]" % CATEGORY_LABELS.get(category, category)
	cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_label.add_theme_font_size_override("font_size", 9)
	cat_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	vbox.add_child(cat_label)

	# Separator space
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(sep)

	# Description
	var desc := Label.new()
	desc.text = def.get("description", "")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 9)
	desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	vbox.add_child(desc)

	# Stack counter
	var current_stack: int = _rune_manager.get_active().get(rune_id, 0)
	var stack_limit: int   = int(def.get("stack_limit", 3))
	var stack_label := Label.new()
	stack_label.text = "중첩 %d / %d" % [current_stack, stack_limit]
	stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack_label.add_theme_font_size_override("font_size", 8)
	stack_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.9))
	vbox.add_child(stack_label)

	# Spacer to push button down
	var push := Control.new()
	push.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(push)

	# Pick button
	var btn := Button.new()
	btn.text = "선택"
	btn.add_theme_font_size_override("font_size", 11)
	vbox.add_child(btn)
	btn.pressed.connect(_on_card_picked.bind(rune_id, panel))

func _on_card_picked(rune_id: String, picked_panel: Control) -> void:
	# Disable all pick buttons immediately
	for card in picked_panel.get_parent().get_children():
		for btn in card.find_children("*", "Button", true, false):
			(btn as Button).disabled = true

	# Flash the chosen card, then emit
	var tween := create_tween()
	tween.tween_property(picked_panel, "modulate", Color(1.6, 1.6, 0.4), 0.12)
	tween.tween_property(picked_panel, "modulate", Color.WHITE,           0.10)
	await tween.finished

	rune_chosen.emit(rune_id)
	queue_free()
