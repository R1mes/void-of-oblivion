class_name FirestoreService
extends Node

## Сервис работы с Cloud Firestore через официальный REST API.
## Выполняет чтение и запись документов без сторонних библиотек.

signal document_received(path: String, data: Dictionary)
signal document_saved(path: String, success: bool)
signal error_occurred(operation: String, error_message: String)

var auth: FirebaseAuth

func _ready() -> void:
	# Ищем узел авторизации в родительской иерархии или создаем
	if auth == null:
		auth = get_node_or_null("../FirebaseAuth")

## Преобразование словаря GDScript в типизированный формат Firestore REST Document
static func dict_to_firestore_fields(data: Dictionary) -> Dictionary:
	var fields: Dictionary = {}
	for k in data:
		fields[k] = _variant_to_firestore_value(data[k])
	return fields

## Преобразование типизированного формата Firestore Document в обычный GDScript Dictionary
static func firestore_fields_to_dict(fields: Dictionary) -> Dictionary:
	var res: Dictionary = {}
	for k in fields:
		var val_obj = fields[k]
		if val_obj is Dictionary:
			res[k] = _firestore_value_to_variant(val_obj)
	return res

static func _variant_to_firestore_value(val) -> Dictionary:
	if val == null:
		return {"nullValue": null}
	elif val is bool:
		return {"booleanValue": val}
	elif val is int:
		return {"integerValue": str(val)}
	elif val is float:
		return {"doubleValue": val}
	elif val is String:
		return {"stringValue": val}
	elif val is Array:
		var arr_vals: Array = []
		for item in val:
			arr_vals.append(_variant_to_firestore_value(item))
		return {"arrayValue": {"values": arr_vals}}
	elif val is Dictionary:
		return {"mapValue": {"fields": dict_to_firestore_fields(val)}}
	return {"stringValue": str(val)}

static func _firestore_value_to_variant(val_dict: Dictionary):
	if val_dict.has("stringValue"):
		return str(val_dict["stringValue"])
	elif val_dict.has("integerValue"):
		return int(val_dict["integerValue"])
	elif val_dict.has("doubleValue"):
		return float(val_dict["doubleValue"])
	elif val_dict.has("booleanValue"):
		return bool(val_dict["booleanValue"])
	elif val_dict.has("arrayValue"):
		var raw_arr = val_dict["arrayValue"].get("values", [])
		var res_arr: Array = []
		if raw_arr is Array:
			for item in raw_arr:
				res_arr.append(_firestore_value_to_variant(item))
		return res_arr
	elif val_dict.has("mapValue"):
		var raw_fields = val_dict["mapValue"].get("fields", {})
		if raw_fields is Dictionary:
			return firestore_fields_to_dict(raw_fields)
		return {}
	elif val_dict.has("nullValue"):
		return null
	return null

## Получить документ из Firestore (например, "users/USER_ID" или "config/banners")
func get_document(doc_path: String, callback: Callable, _retry_count: int = 0) -> void:
	if not FirebaseConfig.is_configured():
		_dispatch_callback(callback, false, {}, 0)
		return

	var url := FirebaseConfig.get_firestore_url(doc_path)
	print("[FirestoreService] get_document: ", doc_path, " url: ", url)
	var http := HTTPRequest.new()
	add_child(http)

	var headers: PackedStringArray = auth.get_auth_header() if auth else PackedStringArray(["Content-Type: application/json"])
	
	http.request_completed.connect(func(result: int, response_code: int, response_headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		var json_str := body.get_string_from_utf8().strip_edges()
		print("[FirestoreService] get_document response: path=", doc_path, " result=", result, " http_code=", response_code, " body=", json_str)

		if response_code == 401 and _retry_count < 1 and auth != null and not auth.refresh_token.is_empty():
			print("[FirestoreService] 401 Unauthorized for ", doc_path, ". Attempting token refresh...")
			auth.refresh_auth_token(func(refreshed: bool):
				if refreshed:
					get_document(doc_path, callback, _retry_count + 1)
				else:
					_dispatch_callback(callback, false, {}, 401)
			)
			return

		if json_str.is_empty():
			_dispatch_callback(callback, false, {}, response_code)
			return

		var parsed = JSON.parse_string(json_str)

		if response_code >= 200 and response_code < 300 and parsed is Dictionary:
			var fields: Dictionary = parsed.get("fields", {})
			var dict_data := firestore_fields_to_dict(fields)
			document_received.emit(doc_path, dict_data)
			_dispatch_callback(callback, true, dict_data, response_code)
		else:
			_dispatch_callback(callback, false, {}, response_code)
	)

	http.request(url, headers, HTTPClient.METHOD_GET)

func _dispatch_callback(callback: Callable, success: bool, data: Dictionary, code: int) -> void:
	if not callback.is_valid():
		return
	if callback.get_argument_count() >= 3:
		callback.call(success, data, code)
	else:
		callback.call(success, data)

## Сохранить или обновить документ в Firestore (PATCH/UPSERT)
func set_document(doc_path: String, data: Dictionary, callback: Callable = Callable(), _retry_count: int = 0) -> void:
	if not FirebaseConfig.is_configured():
		if callback.is_valid():
			callback.call(false)
		return

	var url := FirebaseConfig.get_firestore_url(doc_path)
	print("[FirestoreService] set_document: ", doc_path, " url: ", url)
	var payload := {
		"fields": dict_to_firestore_fields(data)
	}
	var json_body := JSON.stringify(payload)

	var http := HTTPRequest.new()
	add_child(http)

	var headers: PackedStringArray = auth.get_auth_header() if auth else PackedStringArray(["Content-Type: application/json"])

	http.request_completed.connect(func(result: int, response_code: int, response_headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		var success := (response_code >= 200 and response_code < 300)
		var resp_str := body.get_string_from_utf8()
		print("[FirestoreService] set_document response: path=", doc_path, " result=", result, " http_code=", response_code, " success=", success, " body=", resp_str)

		if response_code == 401 and _retry_count < 1 and auth != null and not auth.refresh_token.is_empty():
			print("[FirestoreService] 401 Unauthorized for set_document ", doc_path, ". Attempting token refresh...")
			auth.refresh_auth_token(func(refreshed: bool):
				if refreshed:
					set_document(doc_path, data, callback, _retry_count + 1)
				else:
					document_saved.emit(doc_path, false)
					if callback.is_valid():
						callback.call(false)
			)
			return

		document_saved.emit(doc_path, success)
		if callback.is_valid():
			callback.call(success)
	)

	http.request(url, headers, HTTPClient.METHOD_PATCH, json_body)

## Получить коллекцию документов (например, список баннеров "banners")
func get_collection(collection_path: String, callback: Callable) -> void:
	if not FirebaseConfig.is_configured():
		callback.call(false, [])
		return

	var url := FirebaseConfig.get_firestore_url(collection_path)
	var http := HTTPRequest.new()
	add_child(http)

	var headers: PackedStringArray = auth.get_auth_header() if auth else PackedStringArray(["Content-Type: application/json"])

	http.request_completed.connect(func(result: int, response_code: int, response_headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		var json_str := body.get_string_from_utf8().strip_edges()
		if json_str.is_empty():
			var empty_results: Array[Dictionary] = []
			callback.call(false, empty_results)
			return
		var parsed = JSON.parse_string(json_str)

		if response_code >= 200 and response_code < 300 and parsed is Dictionary:
			var docs = parsed.get("documents", [])
			var results: Array[Dictionary] = []
			if docs is Array:
				for doc in docs:
					if doc is Dictionary and doc.has("fields"):
						var dict_item := firestore_fields_to_dict(doc["fields"])
						var doc_name: String = str(doc.get("name", ""))
						dict_item["_doc_id"] = doc_name.get_file()
						results.append(dict_item)
			callback.call(true, results)
		else:
			var empty_results: Array[Dictionary] = []
			callback.call(false, empty_results)
	)

	http.request(url, headers, HTTPClient.METHOD_GET)
