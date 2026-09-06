class_name PatchVerifier
extends RefCounted

## Модуль криптографической проверки целостности и подлинности PCK-патчей.
## Реализует строгий Zero-Trust: SHA-256 хэширование и верификацию цифровой подписи RSA-2048 через Godot Crypto.

const PUBLIC_KEY_PATH := "res://security/patch_public_key.pub"

enum VerificationResult {
	SUCCESS = 0,
	FILE_NOT_FOUND = 1,
	PUBLIC_KEY_MISSING = 2,
	HASH_MISMATCH = 3,
	INVALID_SIGNATURE = 4,
	CRYPTO_ERROR = 5
}

## Вычисление SHA-256 хэша файла побайтово через чанки
static func calculate_file_sha256(filepath: String) -> Dictionary:
	# Возвращает {"hash_bytes": PackedByteArray, "hex": String}
	if not FileAccess.file_exists(filepath):
		return {}

	var file := FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		return {}

	var ctx := HashingContext.new()
	var err := ctx.start(HashingContext.HASH_SHA256)
	if err != OK:
		file.close()
		return {}

	var chunk_size := 65536 # 64 KB
	while file.get_position() < file.get_length():
		var chunk := file.get_buffer(chunk_size)
		ctx.update(chunk)

	var hash_bytes := ctx.finish()
	file.close()

	return {
		"bytes": hash_bytes,
		"hex": hash_bytes.hex_encode()
	}

## Полная проверка: сверка SHA-256 и проверка цифровой подписи RSA-2048
static func verify_patch_file(filepath: String, expected_sha256: String, signature_bytes: PackedByteArray) -> VerificationResult:
	if not FileAccess.file_exists(filepath):
		printerr("[PatchVerifier] Error: Patch file not found at: ", filepath)
		return VerificationResult.FILE_NOT_FOUND

	if not FileAccess.file_exists(PUBLIC_KEY_PATH):
		printerr("[PatchVerifier] Error: Embedded public key missing at: ", PUBLIC_KEY_PATH)
		return VerificationResult.PUBLIC_KEY_MISSING

	# 1. Проверяем хэш
	var hash_res := calculate_file_sha256(filepath)
	if hash_res.is_empty():
		return VerificationResult.CRYPTO_ERROR

	var calculated_hex: String = str(hash_res["hex"]).to_lower()
	var target_hex: String = expected_sha256.strip_edges().to_lower()

	if calculated_hex != target_hex:
		printerr("[PatchVerifier] Security ALERT: SHA-256 mismatch!")
		printerr("Expected:   ", target_hex)
		printerr("Calculated: ", calculated_hex)
		return VerificationResult.HASH_MISMATCH

	# 2. Загружаем публичный ключ разработчика
	var pub_key := CryptoKey.new()
	var key_err := pub_key.load(PUBLIC_KEY_PATH, true)
	if key_err != OK:
		printerr("[PatchVerifier] Error loading public key: ", key_err)
		return VerificationResult.PUBLIC_KEY_MISSING

	# 3. Верифицируем RSA-2048 цифровую подпись
	var crypto := Crypto.new()
	var hash_bytes: PackedByteArray = hash_res["bytes"]
	var is_valid := crypto.verify(HashingContext.HASH_SHA256, hash_bytes, signature_bytes, pub_key)

	if not is_valid:
		printerr("[PatchVerifier] Security ALERT: Digital signature verification FAILED! Patch is corrupted or untrusted.")
		return VerificationResult.INVALID_SIGNATURE

	print("[PatchVerifier] Verification SUCCESS: SHA-256 and RSA signature are 100% valid.")
	return VerificationResult.SUCCESS
