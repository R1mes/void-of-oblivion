extends Node

## Глобальное состояние, профиль игрока и система сохранения.

var team_members: Array[Dictionary] = []
var enemy_members: Array[Dictionary] = []
var battle_initiator_id: String = "vika"
var battle_mode: String = "custom"

# --- ПРОФИЛЬ И ВАЛЮТА ---
var coins: int = 300
var shine: int = 0
var relic_shards: int = 0
var unlocked_characters: Array[String] = ["vika"]

var unlocked_light_cones: Array[String] = [
	"database", "archive", "adversary", "arrows", "vitality", 
	"leak", "lullaby", "multiplication", "amber", "apocalypse", 
	"monument_of_silence", "impulse"
]

var current_level_progress: int = 1
var completed_levels: Array[String] = []
var menu_tutorial_completed: bool = false
var tutorial_skipped: bool = false

# Звезды за каждый уровень { "level_7": 3, "level_8": 2 }
var level_stars: Dictionary = {}
# Полученные награды за звезды ["stars_12"]
var claimed_star_rewards: Array[String] = []
# Активированные промокоды (очищаются при полном сбросе прогресса)
var redeemed_promo_codes: Array[String] = []

# --- ЗАЛ ВОСПОМИНАНИЙ (MEMORY HALL) ---
var memory_hall_unlocked_floor: int = 1
var memory_hall_stars: Dictionary = {} # {"floor_1": 3, "floor_2": 2, ...}
var memory_hall_claimed_rewards: Array[String] = [] # ["stars_3", "stars_6", "stars_9", "stars_12", "floor_4_clear"]
var memory_hall_team_1: Array = []
var memory_hall_team_2: Array = []
var memory_hall_initiator_1: String = ""
var memory_hall_initiator_2: String = ""

# --- ГАЧА И ГАРАНТЫ ---
var gacha_5star_pity: int = 0
var gacha_4star_pity: int = 0
var gacha_guaranteed_featured: bool = false
var gacha_weapon_5star_pity: int = 0
var gacha_weapon_guaranteed_featured: bool = false

var saved_builds: Dictionary = {}
var saved_teams: Dictionary = {}
var saved_teams_admin: Dictionary = {}
var last_used_team: Array[Dictionary] = []
var relic_inventory: Array[Dictionary] = []
var is_admin_battle: bool = false

# --- ТЕСТОВАЯ СРЕДА (SANDBOX) ---
var is_test_mode_battle: bool = false
var test_submode: String = "boss" # "boss", "trio", "fiction"
var test_boss_hp: float = 1500000.0
var test_trio_boss_hp: float = 1200000.0
var test_trio_elite_hp: float = 500000.0
var test_fiction_hp: float = 70000.0
var test_fiction_count: int = 30

const SAVE_PATH := "user://save_game.json"
const PRESETS_DIR := "user://team_presets/"
var is_test_environment: bool = false
var save_path: String = SAVE_PATH
var presets_dir: String = PRESETS_DIR

func _ready() -> void:
	if not is_test_environment:
		load_game()

func reset() -> void:
	team_members.clear()
	enemy_members.clear()
	battle_initiator_id = "vika"
	battle_mode = "custom"
	is_admin_battle = false
	is_test_mode_battle = false
	test_submode = "boss"
	test_boss_hp = 1500000.0
	test_trio_boss_hp = 1200000.0
	test_trio_elite_hp = 500000.0
	test_fiction_hp = 70000.0
	test_fiction_count = 30

func reset_all_progress() -> void:
	coins = 300
	shine = 0
	relic_shards = 0
	unlocked_characters = ["vika"]
	unlocked_light_cones = [
		"database", "archive", "adversary", "arrows", "vitality", 
		"leak", "lullaby", "multiplication", "amber", "apocalypse", 
		"monument_of_silence", "impulse"
	]
	current_level_progress = 1
	completed_levels.clear()
	menu_tutorial_completed = false
	tutorial_skipped = false
	level_stars.clear()
	claimed_star_rewards.clear()
	redeemed_promo_codes.clear()
	memory_hall_unlocked_floor = 1
	memory_hall_stars.clear()
	memory_hall_claimed_rewards.clear()
	memory_hall_team_1.clear()
	memory_hall_team_2.clear()
	memory_hall_initiator_1 = ""
	memory_hall_initiator_2 = ""
	gacha_5star_pity = 0
	gacha_4star_pity = 0
	gacha_guaranteed_featured = false
	gacha_weapon_5star_pity = 0
	gacha_weapon_guaranteed_featured = false
	saved_builds.clear()
	saved_teams.clear()
	relic_inventory.clear()
	
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		
	save_game()

# Подсчет всех полученных звезд на всех уровнях
func get_total_stars() -> int:
	var total := 0
	for lvl_id in level_stars:
		total += int(level_stars[lvl_id])
	return total

# --- МЕТОДЫ ЗАЛА ВОСПОМИНАНИЙ ---

func get_memory_hall_total_stars() -> int:
	var total := 0
	for f_key in memory_hall_stars:
		total += int(memory_hall_stars[f_key])
	return total

func get_memory_hall_floor_stars(floor_num: int) -> int:
	if memory_hall_stars.has("floor_%d" % floor_num):
		return int(memory_hall_stars["floor_%d" % floor_num])
	elif memory_hall_stars.has(str(floor_num)):
		return int(memory_hall_stars[str(floor_num)])
	return 0

func is_memory_hall_floor_completed(floor_num: int) -> bool:
	return memory_hall_stars.has("floor_%d" % floor_num) or memory_hall_stars.has(str(floor_num))

func is_memory_hall_completed() -> bool:
	return is_memory_hall_floor_completed(4)

func can_claim_memory_hall_reward(reward_id: String) -> bool:
	if reward_id in memory_hall_claimed_rewards:
		return false
	var total_stars := get_memory_hall_total_stars()
	match reward_id:
		"stars_3": return total_stars >= 3
		"stars_6": return total_stars >= 6
		"stars_9": return total_stars >= 9
		"stars_12": return total_stars >= 12
		"floor_4_clear": return is_memory_hall_floor_completed(4)
	return false

func claim_single_memory_hall_reward(reward_id: String) -> Dictionary:
	if not can_claim_memory_hall_reward(reward_id):
		return {}
	memory_hall_claimed_rewards.append(reward_id)
	var shine_amount := 5
	var r_name := ""
	match reward_id:
		"stars_3":
			r_name = "3★ в Зале воспоминаний"
			shine_amount = 5
		"stars_6":
			r_name = "6★ в Зале воспоминаний"
			shine_amount = 5
		"stars_9":
			r_name = "9★ в Зале воспоминаний"
			shine_amount = 5
		"stars_12":
			r_name = "12★ в Зале воспоминаний"
			shine_amount = 5
		"floor_4_clear":
			r_name = "Прохождение 4-го этажа (Платина)"
			shine_amount = 4
	shine += shine_amount
	save_game()
	return {
		"id": reward_id,
		"name": r_name,
		"shine": shine_amount
	}

# Проверка и начисление всех доступных наград (например, при вызове «Собрать всё»):
# Каждые 3 полученные звезды дают +5 Блеска Свечения (3, 6, 9, 12).
# Прохождение 4-го этажа дает дополнительно +4 Блеска Свечения.
func claim_memory_hall_rewards() -> Array[Dictionary]:
	var granted: Array[Dictionary] = []
	var total_stars := get_memory_hall_total_stars()
	
	var star_milestones := [3, 6, 9, 12]
	for ms in star_milestones:
		var reward_key := "stars_%d" % ms
		if can_claim_memory_hall_reward(reward_key):
			var res := claim_single_memory_hall_reward(reward_key)
			if not res.is_empty():
				granted.append(res)
			
	if can_claim_memory_hall_reward("floor_4_clear"):
		var res_f4 := claim_single_memory_hall_reward("floor_4_clear")
		if not res_f4.is_empty():
			granted.append(res_f4)
		
	return granted

func get_saved_build(char_id: String) -> Dictionary:
	if saved_builds.has(char_id):
		var custom_build: Dictionary = saved_builds[char_id]
		return custom_build.duplicate(true)
		
	return {
		"id": char_id, 
		"eidolon": 0,
		"light_cone": "",
		"relics": {
			"cavern_set_1": "", 
			"cavern_set_2": "",
			"body": "crit_rate",
			"feet": "speed",
			"planar_set": "",   
			"sphere": "ice_dmg",
			"rope": "break_effect",
			"slots": {}
		}
	}

func set_saved_build(char_id: String, build_data: Dictionary) -> void:
	saved_builds[char_id] = build_data.duplicate(true)

# --- МЕТОДЫ УЧЁТА И ЭКИПИРОВКИ СВЕТОВЫХ КОНУСОВ ---

## Получить общее количество имеющихся копий светового конуса
func get_light_cone_total_count(lc_id: String) -> int:
	if lc_id.is_empty():
		return 0
	var cone_data := LightConeRegistry.get_cone(lc_id)
	if cone_data.is_empty():
		return 0
	if int(cone_data.get("rarity", 3)) == 3:
		return 999 # 3★ конусы не ограничены
	var count := 0
	for id_str in unlocked_light_cones:
		if id_str == lc_id:
			count += 1
	return count

## Получить список ID персонажей, у которых экипирован данный конус
func get_light_cone_equipped_characters(lc_id: String, active_team: Array = []) -> Array[String]:
	var result: Array[String] = []
	if lc_id.is_empty():
		return result
	var cone_data := LightConeRegistry.get_cone(lc_id)
	if int(cone_data.get("rarity", 3)) == 3:
		return result # 3★ конусы не отслеживают занятость
	
	var in_active_team: Dictionary = {}
	for slot in active_team:
		if slot != null and slot is Dictionary:
			var c_id: String = slot.get("id", "")
			if not c_id.is_empty():
				in_active_team[c_id] = true
				if slot.get("light_cone", "") == lc_id:
					result.append(c_id)

	for c_id in unlocked_characters:
		if in_active_team.has(c_id):
			continue
		var build := get_saved_build(c_id)
		if build.get("light_cone", "") == lc_id:
			result.append(c_id)
	return result

## Проверить, доступен ли конус для персонажа char_id
func can_equip_light_cone(char_id: String, lc_id: String, active_team: Array = []) -> bool:
	if lc_id.is_empty():
		return true
	var cone_data := LightConeRegistry.get_cone(lc_id)
	if cone_data.is_empty():
		return false
	if int(cone_data.get("rarity", 3)) == 3:
		return true
	var total := get_light_cone_total_count(lc_id)
	if total <= 0:
		return false
	var equipped := get_light_cone_equipped_characters(lc_id, active_team)
	if char_id in equipped:
		return true
	return equipped.size() < total

## Снять световой конус с указанного персонажа
func unequip_light_cone_from_character(char_id: String, active_team: Array = []) -> void:
	for slot in active_team:
		if slot != null and slot is Dictionary and slot.get("id", "") == char_id:
			slot["light_cone"] = ""
	if saved_builds.has(char_id):
		saved_builds[char_id]["light_cone"] = ""
		save_game()

## Экипировать световой конус на персонажа (при необходимости сняв с другого персонажа)
func equip_light_cone_to_character(to_char: String, lc_id: String, from_char: String = "", active_team: Array = []) -> void:
	if not from_char.is_empty() and from_char != to_char:
		unequip_light_cone_from_character(from_char, active_team)
	for slot in active_team:
		if slot != null and slot is Dictionary and slot.get("id", "") == to_char:
			slot["light_cone"] = lc_id
	var build := get_saved_build(to_char)
	build["light_cone"] = lc_id
	set_saved_build(to_char, build)
	save_game()

# --- МЕТОДЫ УПРАВЛЕНИЯ РЕЛИКВИЯМИ ---

func add_relic(relic: Dictionary) -> void:
	relic_inventory.append(relic)

func remove_relic(uid: String) -> bool:
	for i in range(relic_inventory.size()):
		if relic_inventory[i].get("uid", "") == uid:
			var eq_to: String = String(relic_inventory[i].get("equipped_to", ""))
			if not eq_to.is_empty():
				unequip_relic(eq_to, String(relic_inventory[i].get("slot", "")))
			relic_inventory.remove_at(i)
			return true
	return false

func get_relic(uid: String) -> Dictionary:
	for r in relic_inventory:
		if r.get("uid", "") == uid:
			return r
	return {}

func equip_relic(char_id: String, slot: String, uid: String) -> void:
	var target_relic := get_relic(uid)
	if target_relic.is_empty():
		return
		
	var prev_char: String = String(target_relic.get("equipped_to", ""))
	if not prev_char.is_empty() and prev_char != char_id:
		unequip_relic(prev_char, slot)
		
	unequip_relic(char_id, slot)
	target_relic["equipped_to"] = char_id
	
	var build := get_saved_build(char_id)
	if not build.has("relics") or not (build["relics"] is Dictionary):
		build["relics"] = {}
	if not build["relics"].has("slots") or not (build["relics"]["slots"] is Dictionary):
		build["relics"]["slots"] = {}
		
	build["relics"]["slots"][slot] = uid
	set_saved_build(char_id, build)

func unequip_relic(char_id: String, slot: String) -> void:
	var build := get_saved_build(char_id)
	if build.has("relics") and build["relics"] is Dictionary and build["relics"].has("slots") and (build["relics"]["slots"] is Dictionary):
		var old_uid: String = String(build["relics"]["slots"].get(slot, ""))
		if not old_uid.is_empty():
			var old_r := get_relic(old_uid)
			if not old_r.is_empty() and old_r.get("equipped_to", "") == char_id:
				old_r["equipped_to"] = ""
			build["relics"]["slots"].erase(slot)
			set_saved_build(char_id, build)
			
	for r in relic_inventory:
		if r.get("equipped_to", "") == char_id and r.get("slot", "") == slot:
			r["equipped_to"] = ""

func get_equipped_relics(char_id: String) -> Dictionary:
	var res: Dictionary = {}
	for r in relic_inventory:
		if r.get("equipped_to", "") == char_id:
			var slot: String = String(r.get("slot", ""))
			res[slot] = r
	return res

func is_character_unlocked(char_id: String) -> bool:
	return char_id in unlocked_characters

# --- ПРЕСЕТЫ ОТРЯДОВ (СОХРАНЕНИЕ И ЗАГРУЗКА) ---

func save_team_preset(preset_name: String, members: Array, initiator_id: String = "", is_admin: bool = false) -> void:
	var clean_members: Array = []
	for member in members:
		if member != null and member is Dictionary:
			clean_members.append(member.duplicate(true))
		else:
			clean_members.append(null)
	
	var preset_data: Dictionary = {
		"name": preset_name,
		"members": clean_members,
		"initiator": initiator_id,
		"is_admin": is_admin
	}
	if is_admin:
		saved_teams_admin[preset_name] = preset_data
	else:
		saved_teams[preset_name] = preset_data
	
	# Сохраняем в отдельный файл пресета для защиты от стирания
	if not is_test_environment:
		var target_dir := presets_dir + ("admin/" if is_admin else "game/")
		var global_dir := ProjectSettings.globalize_path(target_dir)
		if not DirAccess.dir_exists_absolute(global_dir):
			DirAccess.make_dir_recursive_absolute(global_dir)
		var file_name := preset_name.validate_filename()
		if file_name.is_empty():
			file_name = "preset_%d" % int(Time.get_unix_time_from_system())
		var preset_file := FileAccess.open(target_dir + file_name + ".json", FileAccess.WRITE)
		if preset_file != null:
			preset_file.store_string(JSON.stringify(preset_data, "\t"))
			preset_file.close()

		save_game()

func delete_team_preset(preset_name: String, is_admin: bool = false) -> void:
	var target_dict := saved_teams_admin if is_admin else saved_teams
	if target_dict.has(preset_name):
		target_dict.erase(preset_name)
		if not is_test_environment:
			var file_name := preset_name.validate_filename()
			var target_dir := presets_dir + ("admin/" if is_admin else "game/")
			var p_path := target_dir + file_name + ".json"
			var global_path := ProjectSettings.globalize_path(p_path)
			if FileAccess.file_exists(p_path):
				DirAccess.remove_absolute(global_path)
			save_game()

func get_saved_teams(is_admin: bool = false) -> Dictionary:
	return saved_teams_admin if is_admin else saved_teams

func get_team_preset(preset_name: String, is_admin: bool = false) -> Dictionary:
	var target_dict := saved_teams_admin if is_admin else saved_teams
	if target_dict.has(preset_name):
		return target_dict[preset_name].duplicate(true)
	return {}

# --- СОХРАНЕНИЕ И ЗАГРУЗКА ---

func save_game(trigger_cloud: bool = true) -> bool:
	var data := {
		"coins": coins,
		"shine": shine,
		"relic_shards": relic_shards,
		"unlocked_characters": unlocked_characters,
		"unlocked_light_cones": unlocked_light_cones,
		"current_level_progress": current_level_progress,
		"completed_levels": completed_levels,
		"menu_tutorial_completed": menu_tutorial_completed,
		"tutorial_skipped": tutorial_skipped,
		"level_stars": level_stars,
		"claimed_star_rewards": claimed_star_rewards,
		"redeemed_promo_codes": redeemed_promo_codes,
		"memory_hall_unlocked_floor": memory_hall_unlocked_floor,
		"memory_hall_stars": memory_hall_stars,
		"memory_hall_claimed_rewards": memory_hall_claimed_rewards,
		"memory_hall_team_1": memory_hall_team_1,
		"memory_hall_team_2": memory_hall_team_2,
		"memory_hall_initiator_1": memory_hall_initiator_1,
		"memory_hall_initiator_2": memory_hall_initiator_2,
		"gacha_5star_pity": gacha_5star_pity,
		"gacha_4star_pity": gacha_4star_pity,
		"gacha_guaranteed_featured": gacha_guaranteed_featured,
		"gacha_weapon_5star_pity": gacha_weapon_5star_pity,
		"gacha_weapon_guaranteed_featured": gacha_weapon_guaranteed_featured,
		"saved_builds": saved_builds,
		"saved_teams": saved_teams,
		"saved_teams_admin": saved_teams_admin,
		"last_used_team": last_used_team if not team_members.is_empty() else last_used_team,
		"relic_inventory": relic_inventory
	}
	if not team_members.is_empty():
		data["last_used_team"] = team_members.duplicate(true)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		if trigger_cloud:
			_trigger_cloud_sync()
		return true
	return false

func _trigger_cloud_sync() -> void:
	if get_tree() != null and get_tree().root != null:
		var net = get_tree().root.get_node_or_null("NetworkManager")
		if net != null and net.get("sync") != null:
			var sync_mgr = net.get("sync")
			if sync_mgr.has_method("sync_to_cloud"):
				sync_mgr.sync_to_cloud()

func load_game() -> bool:
	var loaded_anything := false
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file != null:
			var json_text := file.get_as_text()
			file.close()
			
			var parsed = JSON.parse_string(json_text)
			if parsed is Dictionary:
				coins = int(parsed.get("coins", 300))
				shine = int(parsed.get("shine", 0))
				relic_shards = int(parsed.get("relic_shards", 0))
				unlocked_characters = Array(parsed.get("unlocked_characters", ["vika"]), TYPE_STRING, "", null)
				
				var loaded_cones = Array(parsed.get("unlocked_light_cones", []), TYPE_STRING, "", null)
				for c_id in ["database", "archive", "adversary", "arrows", "vitality", "leak", "lullaby", "multiplication", "amber", "apocalypse", "monument_of_silence", "impulse"]:
					if not c_id in loaded_cones:
						loaded_cones.append(c_id)
				unlocked_light_cones = loaded_cones
				
				current_level_progress = int(parsed.get("current_level_progress", 1))
				completed_levels = Array(parsed.get("completed_levels", []), TYPE_STRING, "", null)
				menu_tutorial_completed = bool(parsed.get("menu_tutorial_completed", false))
				tutorial_skipped = bool(parsed.get("tutorial_skipped", false))
				level_stars = parsed.get("level_stars", {})
				claimed_star_rewards = Array(parsed.get("claimed_star_rewards", []), TYPE_STRING, "", null)
				redeemed_promo_codes = Array(parsed.get("redeemed_promo_codes", []), TYPE_STRING, "", null)
				memory_hall_unlocked_floor = int(parsed.get("memory_hall_unlocked_floor", 1))
				memory_hall_stars = parsed.get("memory_hall_stars", {})
				memory_hall_claimed_rewards = Array(parsed.get("memory_hall_claimed_rewards", []), TYPE_STRING, "", null)
				memory_hall_team_1 = Array(parsed.get("memory_hall_team_1", []), TYPE_DICTIONARY, "", null)
				memory_hall_team_2 = Array(parsed.get("memory_hall_team_2", []), TYPE_DICTIONARY, "", null)
				memory_hall_initiator_1 = String(parsed.get("memory_hall_initiator_1", ""))
				memory_hall_initiator_2 = String(parsed.get("memory_hall_initiator_2", ""))
				gacha_5star_pity = int(parsed.get("gacha_5star_pity", 0))
				gacha_4star_pity = int(parsed.get("gacha_4star_pity", 0))
				gacha_guaranteed_featured = bool(parsed.get("gacha_guaranteed_featured", false))
				gacha_weapon_5star_pity = int(parsed.get("gacha_weapon_5star_pity", 0))
				gacha_weapon_guaranteed_featured = bool(parsed.get("gacha_weapon_guaranteed_featured", false))
				saved_builds = parsed.get("saved_builds", {})
				saved_teams = parsed.get("saved_teams", {})
				saved_teams_admin = parsed.get("saved_teams_admin", {})
				var raw_lut = parsed.get("last_used_team", [])
				last_used_team.clear()
				if raw_lut is Array:
					for m in raw_lut:
						if m is Dictionary:
							last_used_team.append(m)
				if not last_used_team.is_empty():
					team_members = last_used_team.duplicate(true)
				var raw_relics = parsed.get("relic_inventory", [])
				relic_inventory.clear()
				for r in raw_relics:
					if r is Dictionary:
						relic_inventory.append(r)
				loaded_anything = true

	# Дополнительно подгружаем отдельные файлы пресетов из presets_dir
	_load_presets_from_folder(presets_dir + "game/", saved_teams)
	_load_presets_from_folder(presets_dir + "admin/", saved_teams_admin)
	_load_presets_from_folder(presets_dir, saved_teams)

	return loaded_anything

func _load_presets_from_folder(folder_path: String, target_dict: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(folder_path):
		return
	var dir := DirAccess.open(folder_path)
	if dir != null:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var p_file := FileAccess.open(folder_path + file_name, FileAccess.READ)
				if p_file != null:
					var p_text := p_file.get_as_text()
					p_file.close()
					var p_json = JSON.parse_string(p_text)
					if p_json is Dictionary and p_json.has("name"):
						var t_name: String = str(p_json["name"])
						if not target_dict.has(t_name):
							target_dict[t_name] = p_json
			file_name = dir.get_next()
		dir.list_dir_end()

func has_save_file() -> bool:
	return FileAccess.file_exists(save_path)

func add_relic_shards(amount: int) -> void:
	relic_shards += maxi(0, amount)

func consume_relic_shards(amount: int) -> bool:
	if amount <= 0:
		return true
	if relic_shards >= amount:
		relic_shards -= amount
		return true
	return false
