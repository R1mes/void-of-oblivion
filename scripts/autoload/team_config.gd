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
