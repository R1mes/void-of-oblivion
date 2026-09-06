extends Node

## Менеджер обновления и динамической загрузки PCK-патчей.
## 1. Проверяет наличие обновлений по манифесту (GitHub Releases / CDN).
## 2. Скачивает patch PCK во временный буфер.
## 3. Проводит криптографическую валидацию (SHA-256 + RSA-2048 подпись).
## 4. Монтирует одобренный пакет через ProjectSettings.load_resource_pack().

signal update_check_finished(has_update: bool, update_info: Dictionary)
signal download_progress(downloaded_bytes: int, total_bytes: int, percent: float)
signal update_installed(version: String)
signal update_failed(error_message: String)

const CURRENT_VERSION: String = "1.3.0"
var patches_dir: String = "user://patches/"
var temp_patch_path: String = "user://patch_temp.pck"
var installed_manifest_path: String = "user://installed_patches.json"

var is_downloading: bool = false
var latest_patch_info: Dictionary = {}

func _ready() -> void:
	# Проверяем доступность user:// для создания каталогов
	var test_dir := DirAccess.open("user://")
	if test_dir == null or test_dir.make_dir("patches") != OK and not test_dir.dir_exists("patches"):
		patches_dir = "res://user_data/patches/"
		temp_patch_path = "res://user_data/patch_temp.pck"
		installed_manifest_path = "res://user_data/installed_patches.json"

	_ensure_patches_directory()
	load_existing_patches()

func _ensure_patches_directory() -> void:
	if not DirAccess.dir_exists_absolute(patches_dir):
		DirAccess.make_dir_recursive_absolute(patches_dir)

## Монтирование ранее скачанных и проверенных патчей при запуске игры
func load_existing_patches() -> void:
	if not FileAccess.file_exists(installed_manifest_path):
		return

	var f := FileAccess.open(installed_manifest_path, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(text)
	if parsed is Dictionary and parsed.has("installed_pck"):
		var pck_file: String = str(parsed["installed_pck"])
		var full_path := patches_dir + pck_file
		if FileAccess.file_exists(full_path):
			# В Godot 4.6 load_resource_pack(path, replace_files)
			var success := ProjectSettings.load_resource_pack(full_path, true)
			print("[PatchManager] Mounted existing patch PCK: %s (Success: %s)" % [full_path, success])

## Проверка наличия новой версии по URL манифеста
func check_for_updates(manifest_url: String = FirebaseConfig.DEFAULT_MANIFEST_URL) -> void:
	var http := HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		if response_code != 200:
			update_check_finished.emit(false, {})
			return

		var json_str := body.get_string_from_utf8()
		var parsed = JSON.parse_string(json_str)
		if parsed is Dictionary and parsed.has("patch"):
			var patch_dict: Dictionary = parsed["patch"]
			var remote_version: String = str(parsed.get("latest_version", ""))
			
			if remote_version != "" and remote_version != CURRENT_VERSION:
				latest_patch_info = parsed
				update_check_finished.emit(true, parsed)
				return

		update_check_finished.emit(false, {})
	)

	http.request(manifest_url)

## Скачивание и криптографическая верификация патча
func download_and_install_patch(patch_info: Dictionary) -> void:
	if is_downloading:
		return

	var patch_data: Dictionary = patch_info.get("patch", {})
	var download_url: String = str(patch_data.get("download_url", ""))
	var expected_sha256: String = str(patch_data.get("sha256", ""))
	var sig_b64: String = str(patch_data.get("signature_base64", ""))
	var target_version: String = str(patch_info.get("latest_version", "1.4.0"))
	var filename: String = str(patch_data.get("filename", "patch_v" + target_version + ".pck"))

	if download_url.is_empty() or expected_sha256.is_empty() or sig_b64.is_empty():
		update_failed.emit("Неполные данные манифеста обновления (отсутствует SHA256 или подпись).")
		return

	var signature_bytes := Marshalls.base64_to_raw(sig_b64)
	is_downloading = true

	var http := HTTPRequest.new()
	http.download_file = temp_patch_path
	add_child(http)

	# Отслеживание прогресса скачивания в _process
	var timer := get_tree().create_timer(0.1)

	http.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		is_downloading = false

		if response_code != 200 or not FileAccess.file_exists(temp_patch_path):
			if FileAccess.file_exists(temp_patch_path):
				DirAccess.remove_absolute(temp_patch_path)
			update_failed.emit("Ошибка загрузки файла патча с сервера (Код HTTP: %d)" % response_code)
			return

		print("[PatchManager] Download completed. Verifying cryptographic signature...")

		# КРИПТОГРАФИЧЕСКАЯ ПРОВЕРКА ПОДПИСИ И ХЭША
		var verify_code := PatchVerifier.verify_patch_file(temp_patch_path, expected_sha256, signature_bytes)
		if verify_code != PatchVerifier.VerificationResult.SUCCESS:
			# НЕМЕДЛЕННО УДАЛЯЕМ НЕПОДПИСАННЫЙ / СКОМПРОМЕТИРОВАННЫЙ ФАЙЛ
			DirAccess.remove_absolute(temp_patch_path)
			var err_desc := "Ошибка проверки безопасности патча (код: %d). Файл отклонён движком!" % verify_code
			printerr("[PatchManager] " + err_desc)
			update_failed.emit(err_desc)
			return

		# Если подпись верна -> перемещаем в постоянное хранилище патчей
		var final_pck_path := patches_dir + filename
		if FileAccess.file_exists(final_pck_path):
			DirAccess.remove_absolute(final_pck_path)

		var move_err := DirAccess.rename_absolute(temp_patch_path, final_pck_path)
		if move_err != OK:
			# Fallback через копирование
			DirAccess.copy_absolute(temp_patch_path, final_pck_path)
			DirAccess.remove_absolute(temp_patch_path)

		# Сохраняем информацию об установленном патче
		var installed_record := {
			"installed_version": target_version,
			"installed_pck": filename,
			"sha256": expected_sha256,
			"installed_at": int(Time.get_unix_time_from_system())
		}
		var f := FileAccess.open(installed_manifest_path, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(installed_record, "\t"))
			f.close()

		# ДИНАМИЧЕСКОЕ МОНТИРОВАНИЕ В СИСТЕМУ RES:// БЕЗ ПЕРЕЗАПУСКА EXE
		var mount_ok := ProjectSettings.load_resource_pack(final_pck_path, true)
		print("[PatchManager] Patch %s mounted successfully: %s" % [final_pck_path, mount_ok])

		update_installed.emit(target_version)
	)

	http.request(download_url)
