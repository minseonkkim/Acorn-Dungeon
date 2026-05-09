extends Node2D

const PORTAL_SCENE: PackedScene = preload("res://scenes/portal.tscn")
const ACORN_KING_SCENE: PackedScene = preload("res://scenes/acorn_king.tscn")
const ACORN_BUG_SCENE: PackedScene = preload("res://scenes/acorn_bug.tscn")
const GRASS_GOBLIN_SCENE: PackedScene = preload("res://scenes/grass_goblin.tscn")
const ANGRY_SQUIRREL_SCENE: PackedScene = preload("res://scenes/angry_squirrel.tscn")

enum RoomType { COMBAT, REST, BOSS }

const TOTAL_FLOORS: int = 5

# 층별 방 타입 시퀀스 (1층~5층)
const FLOOR_SEQUENCE: Array[int] = [
	RoomType.COMBAT,  # 1층: 도토리벌레
	RoomType.COMBAT,  # 2층: 도토리벌레 + 도깨비풀
	RoomType.REST,    # 3층: 휴식
	RoomType.COMBAT,  # 4층: 전부 혼합
	RoomType.BOSS,    # 5층: 다람쥐 왕
]

@onready var player: Player = $Player
@onready var background: Polygon2D = $Background
@onready var joystick: Node = $UI/VirtualJoystick
@onready var skill_button: Node = $UI/SkillButton
@onready var hud: HUD = $HUD
@onready var result_screen: ResultScreen = $ResultScreen
@onready var spawner: SpawnManager = $SpawnManager

var _run_time: float = 0.0
var _floors_cleared: int = 0
var _current_floor: int = 1
var _portal: Portal = null
var _running: bool = false
var _rune_manager: RuneManager = null
var _boss: Node = null
var _total_kills: int = 0
var _acorns_earned: int = 0  # 이번 런에서 획득한 도토리

func _ready() -> void:
	_rune_manager = RuneManager.new()
	add_child(_rune_manager)
	_rune_manager.load_from_json("res://data/runes.json")

	player.joystick = joystick
	player.rune_manager = _rune_manager
	player.hp_changed.connect(_on_player_hp_changed)
	player.died.connect(_on_player_died)
	player.skill_cooldown_changed.connect(_on_skill_cd_changed)

	if skill_button.has_signal("pressed_skill"):
		skill_button.pressed_skill.connect(player.use_skill)

	spawner.enemy_killed.connect(_on_enemy_killed)
	spawner.room_cleared.connect(_on_room_cleared)
	result_screen.retry_requested.connect(_on_retry)
	result_screen.town_requested.connect(_on_go_to_town)

	# 도토리 나무 영구 업그레이드 적용
	SaveManager.apply_to_player(player)

	hud.set_hp(player.current_hp, player.max_hp)
	hud.set_kills(0)
	hud.set_floor(_current_floor, TOTAL_FLOORS)

	_start_floor()

	# 치유의 씨앗 업그레이드: 시작 시 체력 10% 회복
	var heal_pct := SaveManager.get_start_heal_pct()
	if heal_pct > 0.0:
		player.heal(int(player.max_hp * heal_pct))

func _process(delta: float) -> void:
	if _running:
		_run_time += delta
	background.position = player.global_position

# ─── 층 진행 ───────────────────────────────────────────────────

func _start_floor() -> void:
	_running = true
	_clear_portal()
	hud.set_floor(_current_floor, TOTAL_FLOORS)

	match FLOOR_SEQUENCE[_current_floor - 1]:
		RoomType.COMBAT: _start_combat_floor()
		RoomType.REST:   _start_rest_floor()
		RoomType.BOSS:   _start_boss_floor()

func _start_combat_floor() -> void:
	var scenes: Array = _get_enemy_scenes()
	var quota: int = _get_quota()
	spawner.configure_enemies(scenes, quota)
	spawner.start_room(player)

func _get_enemy_scenes() -> Array:
	match _current_floor:
		1: return [ACORN_BUG_SCENE]
		2: return [ACORN_BUG_SCENE, GRASS_GOBLIN_SCENE]
		4: return [ACORN_BUG_SCENE, GRASS_GOBLIN_SCENE, ANGRY_SQUIRREL_SCENE]
		_: return [ACORN_BUG_SCENE]

func _get_quota() -> int:
	match _current_floor:
		1: return 10
		2: return 12
		4: return 15
		_: return 12

func _start_rest_floor() -> void:
	spawner.stop()
	var heal: int = int(player.max_hp * 0.3)
	player.heal(heal)
	_show_rest_message_async()

func _show_rest_message_async() -> void:
	var label := Label.new()
	label.text = "✦ 휴식의 방 ✦\n체력 %d 회복!" % int(player.max_hp * 0.3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(0.65, 1.0, 0.65)
	label.size = Vector2(240.0, 60.0)
	label.position = Vector2(60.0, player.global_position.y - 80.0)
	add_child(label)

	await get_tree().create_timer(1.6).timeout

	if not is_instance_valid(label):
		return
	label.queue_free()
	if not _running:
		return
	_show_rune_pick()

func _start_boss_floor() -> void:
	spawner.stop()
	hud.show_boss_bar(true)
	_boss = ACORN_KING_SCENE.instantiate()
	_boss.global_position = player.global_position + Vector2(0.0, -150.0)
	add_child(_boss)
	_boss.died.connect(_on_boss_died)
	_boss.hp_changed.connect(_on_boss_hp_changed)

# ─── 룬 & 포탈 ─────────────────────────────────────────────────

func _on_room_cleared() -> void:
	_floors_cleared += 1
	_show_rune_pick()

func _show_rune_pick() -> void:
	var picks := _rune_manager.draw_three(_current_floor)
	if picks.is_empty():
		_spawn_portal()
		return
	var ui := RunePickUI.new()
	ui.setup(_rune_manager, picks)
	add_child(ui)
	ui.rune_chosen.connect(_on_rune_chosen)

func _on_rune_chosen(rune_id: String) -> void:
	_rune_manager.apply_rune(rune_id, player)
	player.play_rune_pickup_effect()
	_spawn_portal()

func _spawn_portal() -> void:
	_portal = PORTAL_SCENE.instantiate()
	_portal.global_position = player.global_position + Vector2(0.0, -120.0)
	_portal.entered.connect(_on_portal_entered)
	add_child(_portal)

func _on_portal_entered() -> void:
	_current_floor += 1
	if _current_floor > TOTAL_FLOORS:
		_end_run(true)
	else:
		_start_floor()

# ─── 보스 ───────────────────────────────────────────────────────

func _on_boss_hp_changed(current: int, max_hp: int) -> void:
	hud.set_boss_hp(current, max_hp)

func _on_boss_died(_boss_node: Node) -> void:
	_total_kills += 1
	_acorns_earned += 10  # 보스 처치 보너스
	_floors_cleared += 1
	hud.show_boss_bar(false)
	_deactivate_all_enemies()
	await get_tree().create_timer(1.0).timeout
	if _running:
		_end_run(true)

func _deactivate_all_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.visible and e.has_method("deactivate"):
			e.deactivate()

# ─── 플레이어 이벤트 ─────────────────────────────────────────────

func _on_enemy_killed(total: int) -> void:
	_total_kills = total
	_acorns_earned += 1  # 적 처치당 도토리 1개
	hud.set_kills(_total_kills)

func _on_player_hp_changed(current: int, max_hp: int) -> void:
	hud.set_hp(current, max_hp)

func _on_player_died() -> void:
	_end_run(false)

func _on_skill_cd_changed(remaining: float, total: float) -> void:
	if skill_button.has_method("set_cooldown"):
		skill_button.set_cooldown(remaining, total)

# ─── 유틸 ───────────────────────────────────────────────────────

func _end_run(victory: bool) -> void:
	_running = false
	spawner.stop()
	# 런 결과를 SaveManager에 기록
	SaveManager.add_acorns(_acorns_earned)
	SaveManager.finish_run(_floors_cleared)
	result_screen.show_result(victory, _total_kills, _run_time, _floors_cleared, _acorns_earned)

func _clear_portal() -> void:
	if _portal != null and is_instance_valid(_portal):
		_portal.queue_free()
		_portal = null

func _on_retry() -> void:
	_rune_manager.reset()
	get_tree().reload_current_scene()

func _on_go_to_town() -> void:
	get_tree().change_scene_to_file("res://scenes/town.tscn")
