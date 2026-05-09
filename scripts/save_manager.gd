extends Node

const SAVE_PATH := "user://save.json"
const _SIGN_KEY := "acorn_dungeon_v1"

var acorns: int = 0
var tree_upgrades: Dictionary = {}
var selected_character: String = "doori"
var unlocked_characters: Array[String] = ["doori"]
var best_floor: int = 0
var total_runs: int = 0

# 업그레이드 정의 (id, 이름, 설명, 최대레벨, 레벨별 비용, 효과 종류, 효과 값)
const TREE_UPGRADES: Array = [
	{
		"id": "hp_up", "name": "두꺼운 나무껍질",
		"desc": "시작 최대 체력 +10", "max_level": 3,
		"costs": [5, 10, 20], "effect": "max_hp_flat", "value": 10
	},
	{
		"id": "atk_up", "name": "날카로운 도토리",
		"desc": "시작 공격력 +2", "max_level": 3,
		"costs": [5, 10, 20], "effect": "attack_flat", "value": 2
	},
	{
		"id": "speed_up", "name": "바람 발바닥",
		"desc": "이동속도 +10", "max_level": 2,
		"costs": [8, 20], "effect": "move_speed_flat", "value": 10
	},
	{
		"id": "start_heal", "name": "치유의 씨앗",
		"desc": "던전 시작 시 체력 10% 회복", "max_level": 1,
		"costs": [15], "effect": "start_heal_pct", "value": 0.1
	},
]

func _ready() -> void:
	load_save()

# ─── 업그레이드 ──────────────────────────────────────────────

func get_upgrade_level(upgrade_id: String) -> int:
	return int(tree_upgrades.get(upgrade_id, 0))

func get_upgrade_cost(upgrade_id: String) -> int:
	var level := get_upgrade_level(upgrade_id)
	for u: Dictionary in TREE_UPGRADES:
		if str(u["id"]) == upgrade_id:
			if level >= int(u["max_level"]):
				return -1
			return int(u["costs"][level])
	return -1

func can_upgrade(upgrade_id: String) -> bool:
	var cost := get_upgrade_cost(upgrade_id)
	return cost > 0 and acorns >= cost

func upgrade_tree(upgrade_id: String) -> bool:
	if not can_upgrade(upgrade_id):
		return false
	acorns -= get_upgrade_cost(upgrade_id)
	tree_upgrades[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	save_game()
	return true

func apply_to_player(player: Player) -> void:
	for u: Dictionary in TREE_UPGRADES:
		var level := get_upgrade_level(str(u["id"]))
		if level == 0:
			continue
		match str(u["effect"]):
			"max_hp_flat":
				player.max_hp += int(u["value"]) * level
			"attack_flat":
				player.attack_damage += int(u["value"]) * level
				player.base_attack_damage = player.attack_damage
			"move_speed_flat":
				player.move_speed += float(u["value"]) * level
			# start_heal_pct는 main.gd에서 _ready 이후 heal()로 처리

func get_start_heal_pct() -> float:
	return 0.1 if get_upgrade_level("start_heal") > 0 else 0.0

# ─── 런 기록 ─────────────────────────────────────────────────

func add_acorns(amount: int) -> void:
	acorns += amount
	save_game()

func finish_run(floors_cleared: int) -> void:
	total_runs += 1
	best_floor = maxi(best_floor, floors_cleared)
	save_game()

# ─── 저장 / 로드 ─────────────────────────────────────────────

func save_game() -> void:
	var uc_arr: Array = []
	for c in unlocked_characters:
		uc_arr.append(c)
	var data: Dictionary = {
		"acorns": acorns,
		"tree_upgrades": tree_upgrades,
		"selected_character": selected_character,
		"unlocked_characters": uc_arr,
		"best_floor": best_floor,
		"total_runs": total_runs,
	}
	data["checksum"] = _make_checksum(data)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: 파일 저장 실패 — " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data))
	file.close()

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("SaveManager: 세이브 파일 파싱 실패")
		return
	var stored: String = parsed.get("checksum", "")
	var copy: Dictionary = (parsed as Dictionary).duplicate()
	copy.erase("checksum")
	if _make_checksum(copy) != stored:
		push_warning("SaveManager: 변조 감지 — 데이터 초기화")
		return
	acorns = int(parsed.get("acorns", 0))
	var raw_upgrades = parsed.get("tree_upgrades", {})
	if raw_upgrades is Dictionary:
		tree_upgrades = {}
		for key in raw_upgrades:
			tree_upgrades[str(key)] = int(raw_upgrades[key])
	selected_character = str(parsed.get("selected_character", "doori"))
	var uc = parsed.get("unlocked_characters", ["doori"])
	if uc is Array:
		unlocked_characters.clear()
		for c in uc:
			unlocked_characters.append(str(c))
	best_floor = int(parsed.get("best_floor", 0))
	total_runs = int(parsed.get("total_runs", 0))

func _make_checksum(data: Dictionary) -> String:
	# JSON.stringify는 기본적으로 sort_keys=true → 키 순서가 항상 일정
	var text := JSON.stringify(data) + _SIGN_KEY
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish().hex_encode()
