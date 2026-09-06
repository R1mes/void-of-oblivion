class_name PromoService
extends Node

## Сервис активации промокодов с защитой от повторного использования через Firebase.

signal promo_redeemed(code: String, rewards: Dictionary)
signal promo_failed(code: String, reason: String)

var firestore: FirestoreService
var auth: FirebaseAuth

func _ready() -> void:
	if auth == null:
		auth = get_node_or_null("../FirebaseAuth")
	if firestore == null:
		firestore = get_node_or_null("../FirestoreService")

## Активировать промокод
func redeem_promo_code(code: String) -> void:
	var clean_code := code.strip_edges().to_upper()
	if clean_code.is_empty():
		promo_failed.emit(code, "Введите промокод!")
		return

	# Если работаем в оффлайн-режиме без Firebase
	if not FirebaseConfig.is_configured() or auth == null or not auth.is_authenticated():
		_redeem_offline(clean_code)
		return

	var user_id := auth.local_id
	var check_path := "users/%s/redeemed_codes/%s" % [user_id, clean_code]

	# 1. Проверяем, не активировал ли уже этот игрок данный код
	firestore.get_document(check_path, func(already_redeemed: bool, _data: Dictionary):
		if already_redeemed:
			promo_failed.emit(clean_code, "Вы уже активировали этот промокод!")
			return

		# 2. Получаем данные промокода из глобального справочника
		firestore.get_document("promo_codes/" + clean_code, func(found: bool, promo_data: Dictionary):
			if not found or promo_data.is_empty():
				promo_failed.emit(clean_code, "Промокод не найден или не существует!")
				return

			var is_active: bool = bool(promo_data.get("active", true))
			if not is_active:
				promo_failed.emit(clean_code, "Срок действия этого промокода истёк!")
				return

			# 3. Фиксируем активацию в профиле игрока
			var record := {
				"code": clean_code,
				"redeemed_at": int(Time.get_unix_time_from_system())
			}
			firestore.set_document(check_path, record, func(success: bool):
				if not success:
					promo_failed.emit(clean_code, "Не удалось активировать код (ошибка безопасности).")
					return

				# 4. Начисляем награды игроку
				_apply_rewards(clean_code, promo_data)
			)
		)
	)

func _redeem_offline(clean_code: String) -> void:
	# Локальный реестр промокодов для тестирования и оффлайн-игры
	var local_codes := {
		"VOID2026": {"shine": 300, "coins": 5000, "relic_shards": 50},
		"WELCOME": {"shine": 160, "coins": 2000},
		"GODOT4": {"shine": 500, "coins": 10000}
	}

	if not local_codes.has(clean_code):
		promo_failed.emit(clean_code, "Неверный промокод!")
		return

	var redeemed: Array = TeamConfig.claimed_star_rewards # используем существующий массив или отдельный
	var key := "promo_" + clean_code
	if key in redeemed:
		promo_failed.emit(clean_code, "Промокод уже был активирован на этом устройстве!")
		return

	redeemed.append(key)
	_apply_rewards(clean_code, local_codes[clean_code])

func _apply_rewards(code: String, rewards: Dictionary) -> void:
	var coins_add: int = int(rewards.get("coins", 0))
	var shine_add: int = int(rewards.get("shine", 0))
	var shards_add: int = int(rewards.get("relic_shards", 0))

	TeamConfig.coins += coins_add
	TeamConfig.shine += shine_add
	TeamConfig.relic_shards += shards_add
	TeamConfig.save_game()

	# Если синхронизация активна, отправляем обновленный баланс в облако
	var sync_mgr = get_node_or_null("../SyncManager")
	if sync_mgr and sync_mgr.has_method("sync_to_cloud"):
		sync_mgr.sync_to_cloud()

	promo_redeemed.emit(code, rewards)
