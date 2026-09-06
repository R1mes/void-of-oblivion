class_name FirebaseAuth
extends Node

## Модуль аутентификации Firebase Auth (REST API) для Godot 4.6.
## Поддерживает гостевой/анонимный вход (Anonymous) и Email/Password.

signal auth_state_changed(is_logged_in: bool, uid: String)
signal auth_error(message: String)

var id_token: String = ""
var refresh_token: String = ""
var local_id: String = "" # UID пользователя в Firebase
var email: String = ""
var is_anonymous: bool = false
var expires_in: int = 3600
var token_timestamp: int = 0

const TOKEN_CACHE_PATH := "user://auth_tokens.json"

func _ready() -> void:
	load_cached_session()

func is_authenticated() -> bool:
	return not id_token.is_empty() and not local_id.is_empty()

func get_auth_header() -> PackedStringArray:
	if id_token.is_empty():
		return PackedStringArray(["Content-Type: application/json"])
	return PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + id_token
	])

## Анонимный гостевой вход (идеально для мгновенного старта игры)
func sign_in_anonymously() -> void:
	if not FirebaseConfig.is_configured():
		# Демо-режим, если ключи ещё не вставлены
		local_id = "offline_user_" + OS.get_unique_id()
		id_token = "mock_token"
		is_anonymous = true
		auth_state_changed.emit(true, local_id)
		return

	var url := FirebaseConfig.AUTH_SIGNUP_URL + FirebaseConfig.API_KEY
	var body := JSON.stringify({"returnSecureToken": true})
	_send_auth_request(url, body)

## Вход по Email и паролю
func sign_in_with_email(user_email: String, password: String) -> void:
	if not FirebaseConfig.is_configured():
		auth_error.emit("Firebase не сконфигурирован (укажите API_KEY в FirebaseConfig)")
		return

	var url := FirebaseConfig.AUTH_SIGNIN_URL + FirebaseConfig.API_KEY
	var body := JSON.stringify({
		"email": user_email,
		"password": password,
		"returnSecureToken": true
	})
	_send_auth_request(url, body)

## Регистрация по Email и паролю
func sign_up_with_email(user_email: String, password: String) -> void:
	if not FirebaseConfig.is_configured():
		auth_error.emit("Firebase не сконфигурирован")
		return

	var url := FirebaseConfig.AUTH_SIGNUP_URL + FirebaseConfig.API_KEY
	var body := JSON.stringify({
		"email": user_email,
		"password": password,
		"returnSecureToken": true
	})
	_send_auth_request(url, body)

## Выход из аккаунта
func sign_out() -> void:
	id_token = ""
	refresh_token = ""
	local_id = ""
	email = ""
	is_anonymous = false
	if FileAccess.file_exists(TOKEN_CACHE_PATH):
		DirAccess.remove_absolute(TOKEN_CACHE_PATH)
	auth_state_changed.emit(false, "")

func _send_auth_request(url: String, json_body: String) -> void:
	print("[FirebaseAuth] Sending auth request to: ", url.split("?")[0])
	var http := HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		var json_str := body.get_string_from_utf8()
		print("[FirebaseAuth] Auth response: result=", result, " http_code=", response_code, " body=", json_str)
		var parsed = JSON.parse_string(json_str)
		
		if response_code >= 200 and response_code < 300 and parsed is Dictionary:
			id_token = str(parsed.get("idToken", ""))
			refresh_token = str(parsed.get("refreshToken", ""))
			local_id = str(parsed.get("localId", ""))
			email = str(parsed.get("email", ""))
			is_anonymous = email.is_empty()
			expires_in = int(parsed.get("expiresIn", 3600))
			token_timestamp = int(Time.get_unix_time_from_system())
			
			save_session()
			auth_state_changed.emit(true, local_id)
		else:
			var err_msg := "Ошибка авторизации"
			if parsed is Dictionary and parsed.has("error"):
				var err_dict = parsed["error"]
				if err_dict is Dictionary:
					err_msg = str(err_dict.get("message", err_msg))
			print("[FirebaseAuth] Auth error message: ", err_msg)
			auth_error.emit(err_msg)
	)

	var headers := PackedStringArray(["Content-Type: application/json"])
	http.request(url, headers, HTTPClient.METHOD_POST, json_body)

func save_session() -> void:
	var data := {
		"id_token": id_token,
		"refresh_token": refresh_token,
		"local_id": local_id,
		"email": email,
		"is_anonymous": is_anonymous,
		"timestamp": token_timestamp,
		"expires_in": expires_in
	}
	var f := FileAccess.open(TOKEN_CACHE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))
		f.close()

func is_token_expired() -> bool:
	if id_token.is_empty():
		return true
	var now := int(Time.get_unix_time_from_system())
	# Считаем токен устаревшим, если до конца осталось меньше 5 минут (300 сек)
	return (now - token_timestamp) >= (expires_in - 300)

## Обновление id_token через refresh_token (Firebase SecureToken API)
func refresh_auth_token(callback: Callable = Callable()) -> void:
	if not FirebaseConfig.is_configured():
		if callback.is_valid():
			callback.call(false)
		return

	if refresh_token.is_empty():
		print("[FirebaseAuth] Cannot refresh token: refresh_token is empty. Re-authenticating anonymously...")
		sign_in_anonymously()
		if callback.is_valid():
			callback.call(false)
		return

	var url := FirebaseConfig.AUTH_REFRESH_URL + FirebaseConfig.API_KEY
	print("[FirebaseAuth] Refreshing auth token via SecureToken API...")
	var http := HTTPRequest.new()
	add_child(http)

	var form_body := "grant_type=refresh_token&refresh_token=" + refresh_token.uri_encode()
	var headers := PackedStringArray(["Content-Type: application/x-www-form-urlencoded"])

	http.request_completed.connect(func(result: int, response_code: int, res_headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		var json_str := body.get_string_from_utf8()
		var parsed = JSON.parse_string(json_str)

		if response_code == 200 and parsed is Dictionary:
			id_token = str(parsed.get("id_token", ""))
			refresh_token = str(parsed.get("refresh_token", refresh_token))
			local_id = str(parsed.get("user_id", local_id))
			expires_in = int(parsed.get("expires_in", 3600))
			token_timestamp = int(Time.get_unix_time_from_system())
			save_session()
			print("[FirebaseAuth] Auth token refreshed successfully! UID: ", local_id)
			if callback.is_valid():
				callback.call(true)
			auth_state_changed.emit(true, local_id)
		else:
			print("[FirebaseAuth] Token refresh failed (code %d): %s" % [response_code, json_str])
			if response_code == 400:
				# Токен отозван или недействителен — пересоздаем анонимную сессию
				sign_out()
				sign_in_anonymously()
			if callback.is_valid():
				callback.call(false)
	)

	http.request(url, headers, HTTPClient.METHOD_POST, form_body)

func load_cached_session() -> bool:
	if not FileAccess.file_exists(TOKEN_CACHE_PATH):
		return false
	var f := FileAccess.open(TOKEN_CACHE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		id_token = str(parsed.get("id_token", ""))
		refresh_token = str(parsed.get("refresh_token", ""))
		local_id = str(parsed.get("local_id", ""))
		email = str(parsed.get("email", ""))
		is_anonymous = bool(parsed.get("is_anonymous", false))
		token_timestamp = int(parsed.get("timestamp", 0))
		expires_in = int(parsed.get("expires_in", 3600))

		if not local_id.is_empty():
			if is_token_expired():
				print("[FirebaseAuth] Cached token is expired (age > %d s). Refreshing before use..." % (expires_in - 300))
				refresh_auth_token()
			else:
				auth_state_changed.emit(true, local_id)
			return true
	return false
