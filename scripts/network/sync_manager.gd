class_name SyncManager
extends Node

## Двусторонняя синхронизация профиля игрока между TeamConfig и Cloud Firestore.
## Автоматически загружает данные из облака при входе и отправляет изменения при сохранении.

signal sync_started()
signal sync_completed(success: bool)

var auth: FirebaseAuth
var firestore: FirestoreService
var is_syncing: bool = false
var has_initial_sync_completed: bool = false
var _pending_sync: bool = false

func _ready() -> void:
	auth = get_node_or_null("../FirebaseAuth")
	firestore = get_node_or_null("../FirestoreService")

	if auth:
		auth.auth_state_changed.connect(_on_auth_state_changed)
		if auth.is_authenticated():
			_on_auth_state_changed(true, auth.local_id)

func _on_auth_state_changed(is_logged_in: bool, uid: String) -> void:
	print("[SyncManager] _on_auth_state_changed: is_logged_in=", is_logged_in, " uid=", uid, " has_synced=", has_initial_sync_completed, " pending=", _pending_sync)
	if is_logged_in:
		if not has_initial_sync_completed:
			# Всегда сначала загружаем актуальные данные из облака!
			sync_from_cloud()
		elif _pending_sync:
			_pending_sync = false
			sync_to_cloud()

## Загрузка профиля из Firestore в TeamConfig
func sync_from_cloud() -> void:
	if not FirebaseConfig.is_configured() or auth == null or not auth.is_authenticated():
		return

	is_syncing = true
	sync_started.emit()

	var doc_path := "users/" + auth.local_id
	firestore.get_document(doc_path, func(found: bool, cloud_data: Dictionary, http_code: int = 0):
		if found and not cloud_data.is_empty():
			print("[SyncManager] Cloud document found. Syncing to game state...")
			# Накатываем облачные данные в TeamConfig
			TeamConfig.coins = int(cloud_data.get("coins", TeamConfig.coins))
			TeamConfig.shine = int(cloud_data.get("shine", TeamConfig.shine))
			TeamConfig.relic_shards = int(cloud_data.get("relic_shards", TeamConfig.relic_shards))
			TeamConfig.current_level_progress = int(cloud_data.get("current_level_progress", TeamConfig.current_level_progress))
			TeamConfig.gacha_5star_pity = int(cloud_data.get("gacha_5star_pity", TeamConfig.gacha_5star_pity))
			TeamConfig.gacha_4star_pity = int(cloud_data.get("gacha_4star_pity", TeamConfig.gacha_4star_pity))
			TeamConfig.gacha_guaranteed_featured = bool(cloud_data.get("gacha_guaranteed_featured", TeamConfig.gacha_guaranteed_featured))
			TeamConfig.gacha_weapon_5star_pity = int(cloud_data.get("gacha_weapon_5star_pity", TeamConfig.gacha_weapon_5star_pity))
			TeamConfig.gacha_weapon_guaranteed_featured = bool(cloud_data.get("gacha_weapon_guaranteed_featured", TeamConfig.gacha_weapon_guaranteed_featured))

			if cloud_data.has("nickname") and not str(cloud_data["nickname"]).is_empty():
				auth.nickname = str(cloud_data["nickname"])
				auth.save_session()

			# Персонажи и конусы
			var c_list = cloud_data.get("unlocked_characters", [])
			if c_list is Array and not c_list.is_empty():
				for c in c_list:
					if not str(c) in TeamConfig.unlocked_characters:
						TeamConfig.unlocked_characters.append(str(c))

			var lc_list = cloud_data.get("unlocked_light_cones", [])
			if lc_list is Array and not lc_list.is_empty():
				for lc in lc_list:
					if not str(lc) in TeamConfig.unlocked_light_cones:
						TeamConfig.unlocked_light_cones.append(str(lc))

			var lvls = cloud_data.get("completed_levels", [])
			if lvls is Array and not lvls.is_empty():
				for l in lvls:
					if not str(l) in TeamConfig.completed_levels:
						TeamConfig.completed_levels.append(str(l))

			var stars = cloud_data.get("level_stars", {})
			if stars is Dictionary and not stars.is_empty():
				for k in stars:
					TeamConfig.level_stars[str(k)] = int(stars[k])

			has_initial_sync_completed = true
			# Сохраняем полученные данные в локальный файл save_game.json, БЕЗ повторной отправки в облако!
			TeamConfig.save_game(false)
			print("[SyncManager] Successfully synced profile from cloud! coins=%d shine=%d characters=%d" % [TeamConfig.coins, TeamConfig.shine, TeamConfig.unlocked_characters.size()])
			is_syncing = false
			sync_completed.emit(true)
			if _pending_sync:
				_pending_sync = false
				sync_to_cloud()
		elif http_code == 404:
			# Если профиля в облаке ещё нет (новый игрок с кодом 404), инициализируем облачный профиль
			print("[SyncManager] No cloud profile found (404 Not Found). Uploading initial local profile...")
			has_initial_sync_completed = true
			sync_to_cloud()
		else:
			# Ошибка сети (http_code 0, 500 и т.д.) — НЕ перезаписываем облако локальным сейвом!
			print("[SyncManager] Cloud profile could not be loaded (HTTP %d). Preserving cloud data!" % http_code)
			is_syncing = false
			sync_completed.emit(false)
	)

## Выгрузка локальных данных TeamConfig в Firestore
func sync_to_cloud() -> void:
	if not FirebaseConfig.is_configured():
		return
	if not has_initial_sync_completed:
		print("[SyncManager] Skipping sync_to_cloud: initial sync from cloud has not completed yet. Queuing pending sync.")
		_pending_sync = true
		return
	if auth == null or not auth.is_authenticated():
		print("[SyncManager] Cannot sync_to_cloud yet: auth not ready. Queuing pending sync.")
		_pending_sync = true
		return

	print("[SyncManager] Starting sync_to_cloud for UID: ", auth.local_id, " coins=", TeamConfig.coins, " shine=", TeamConfig.shine)

	var doc_path := "users/" + auth.local_id
	var payload := {
		"coins": TeamConfig.coins,
		"shine": TeamConfig.shine,
		"relic_shards": TeamConfig.relic_shards,
		"current_level_progress": TeamConfig.current_level_progress,
		"unlocked_characters": TeamConfig.unlocked_characters,
		"unlocked_light_cones": TeamConfig.unlocked_light_cones,
		"completed_levels": TeamConfig.completed_levels,
		"level_stars": TeamConfig.level_stars,
		"gacha_5star_pity": TeamConfig.gacha_5star_pity,
		"gacha_4star_pity": TeamConfig.gacha_4star_pity,
		"gacha_guaranteed_featured": TeamConfig.gacha_guaranteed_featured,
		"gacha_weapon_5star_pity": TeamConfig.gacha_weapon_5star_pity,
		"gacha_weapon_guaranteed_featured": TeamConfig.gacha_weapon_guaranteed_featured,
		"nickname": auth.nickname,
		"updated_at": int(Time.get_unix_time_from_system())
	}

	firestore.set_document(doc_path, payload, func(success: bool):
		if success:
			print("[SyncManager] Cloud profile updated successfully! coins=%d shine=%d" % [TeamConfig.coins, TeamConfig.shine])
		is_syncing = false
		sync_completed.emit(success)
	)
