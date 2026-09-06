class_name FirebaseConfig
extends RefCounted

## Конфигурация бесплатного Firebase Spark и внешнего CDN патчей для 'Void of Oblivion'.
## Вся сетевая работа происходит через прямые REST API (не требует внешних плагинов или Node.js).

# Вставьте ваши ключи из Firebase Console (Project Settings -> General -> Web App):
# Никаких платных функций или биллинга не требуется (0 € Spark Plan).
const API_KEY: String = "AIzaSyBnRhdyEFX4-fmCnCGc3x2FYbmkiGMiLZ4"
const PROJECT_ID: String = "void-of-oblivion"

# REST Эндпоинты Firebase
const AUTH_SIGNUP_URL: String = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key="
const AUTH_SIGNIN_URL: String = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="
const AUTH_REFRESH_URL: String = "https://securetoken.googleapis.com/v1/token?key="
const FIRESTORE_BASE_URL: String = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents"

# Бесплатный CDN для проверки и скачивания PCK-патчей (GitHub Releases / Pages / Cloudflare Pages)
# Файл манифеста содержит инфу о последней версии, sha256, URL и RSA-2048 подпись
const DEFAULT_MANIFEST_URL: String = "https://raw.githubusercontent.com/R1mes/void-of-oblivion/main/patches/version_manifest.json"

static func get_firestore_url(path: String) -> String:
	var base := FIRESTORE_BASE_URL % PROJECT_ID
	if not path.begins_with("/"):
		path = "/" + path
	return base + path

static func is_configured() -> bool:
	return API_KEY != "YOUR_FIREBASE_WEB_API_KEY" and not API_KEY.is_empty()
