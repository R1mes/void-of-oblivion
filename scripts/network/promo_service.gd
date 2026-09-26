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
			# Если аккаунт анонимный и локально код не числится как активированный (произошел сброс прогресса)
			if auth != null and auth.is_anonymous and not (clean_code in TeamConfig.redeemed_promo_codes):
				print("[PromoService] Anonymous session has pre-reset code redeemed in cloud. Rotating session...")
				var on_auth_ref: Array = []
				var on_auth := func(is_logged_in: bool, _new_uid: String):
					if is_logged_in:
						if auth.auth_state_changed.is_connected(on_auth_ref[0]):
							auth.auth_state_changed.disconnect(on_auth_ref[0])
						redeem_promo_code(clean_code)
				on_auth_ref.append(on_auth)
				auth.auth_state_changed.connect(on_auth)
				auth.sign_out()
				auth.sign_in_anonymously()
				return

			promo_failed.emit(clean_code, "Вы уже активировали этот промокод!")
			return

		# 2. Получаем данные промокода из глобального справочника
		firestore.get_document("promo_codes/" + clean_code, func(found: bool, promo_data: Dictionary):
			if not found or promo_data.is_empty():
				var local_codes := _get_local_codes()
				if local_codes.has(clean_code):
					promo_data = local_codes[clean_code]
				else:
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

static func _get_local_codes() -> Dictionary:
	return {
		"VOID2026": {"shine": 300, "coins": 5000, "relic_shards": 50},
		"WELCOME": {"shine": 160, "coins": 2000},
		"GODOT4": {"shine": 500, "coins": 10000},
		"RIMES1000": {"shine": 1000, "coins": 10000, "relic_shards": 100}
	}

func _redeem_offline(clean_code: String) -> void:
	# Локальный реестр промокодов для тестирования и оффлайн-игры
	var local_codes := _get_local_codes()

	if not local_codes.has(clean_code):
		promo_failed.emit(clean_code, "Неверный промокод!")
		return

	if clean_code in TeamConfig.redeemed_promo_codes:
		promo_failed.emit(clean_code, "Промокод уже был активирован на этом устройстве!")
		return

	TeamConfig.redeemed_promo_codes.append(clean_code)
	TeamConfig.save_game()
	_apply_rewards(clean_code, local_codes[clean_code])

## Полный сброс всех использованных промокодов (локально и в облаке)
func reset_all_redeemed_codes(callback: Callable = Callable()) -> void:
	TeamConfig.redeemed_promo_codes.clear()
	TeamConfig.save_game(false)

	if not FirebaseConfig.is_configured() or auth == null or not auth.is_authenticated() or firestore == null:
		if callback.is_valid():
			callback.call(true)
		return

	if auth.is_anonymous:
		auth.sign_out()
		auth.sign_in_anonymously()
		if callback.is_valid():
			callback.call(true)
		return

	var collection_path := "users/%s/redeemed_codes" % auth.local_id
	firestore.get_collection(collection_path, func(success: bool, docs: Array):
		if not success or docs.is_empty():
			if callback.is_valid():
				callback.call(true)
			return

		var remaining := docs.size()
		for d in docs:
			var doc_id: String = String(d.get("_doc_id", ""))
			if not doc_id.is_empty():
				var doc_p := "users/%s/redeemed_codes/%s" % [auth.local_id, doc_id]
				firestore.delete_document(doc_p, func(_del_ok: bool):
					remaining -= 1
					if remaining <= 0 and callback.is_valid():
						callback.call(true)
				)
			else:
				remaining -= 1
				if remaining <= 0 and callback.is_valid():
					callback.call(true)
	)

func _apply_rewards(code: String, rewards: Dictionary) -> void:
	if not (code in TeamConfig.redeemed_promo_codes):
		TeamConfig.redeemed_promo_codes.append(code)
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
