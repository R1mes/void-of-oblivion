extends Node

## Главный синглтон сетевой подсистемы игры 'Void of Oblivion'.
## Объединяет FirebaseAuth, FirestoreService, SyncManager, PromoService и BannerService.

const FirebaseAuthScript = preload("res://scripts/network/firebase_auth.gd")
const FirestoreServiceScript = preload("res://scripts/network/firestore_service.gd")
const SyncManagerScript = preload("res://scripts/network/sync_manager.gd")
const PromoServiceScript = preload("res://scripts/network/promo_service.gd")
const BannerServiceScript = preload("res://scripts/network/banner_service.gd")

var auth: FirebaseAuth
var firestore: FirestoreService
var sync: SyncManager
var promo: PromoService
var banners: BannerService

func _enter_tree() -> void:
	# Инициализация дочерних узлов
	auth = FirebaseAuthScript.new()
	auth.name = "FirebaseAuth"
	add_child(auth)

	firestore = FirestoreServiceScript.new()
	firestore.name = "FirestoreService"
	firestore.auth = auth
	add_child(firestore)

	sync = SyncManagerScript.new()
	sync.name = "SyncManager"
	sync.auth = auth
	sync.firestore = firestore
	add_child(sync)

	promo = PromoServiceScript.new()
	promo.name = "PromoService"
	promo.auth = auth
	promo.firestore = firestore
	add_child(promo)

	banners = BannerServiceScript.new()
	banners.name = "BannerService"
	banners.firestore = firestore
	add_child(banners)

func _ready() -> void:
	# Пытаемся автоматически восстановить сессию или войти анонимно
	if not auth.is_authenticated():
		auth.sign_in_anonymously()
