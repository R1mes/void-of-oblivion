class_name BannerService
extends Node

## Сервис управления баннерами: загрузка актуальных баннеров с сервера
## с автоматическим fallback на встроенные локальные баннеры.

signal banners_updated(banners_list: Array[Dictionary])

var firestore: FirestoreService
var current_banners: Array[Dictionary] = []

# Локальные баннеры по умолчанию (из main_menu.gd)
const DEFAULT_BANNERS: Array[Dictionary] = [
	{"id": "katarina", "name": "Катарина", "title": "⚔ Катарина (5★)", "type": "character"},
	{"id": "dotseva_crimson_tears", "name": "Доцева • Багровые слёзы", "title": "🩸 Доцева • Багровые слёзы (5★)", "type": "character"},
	{"id": "dotseva", "name": "Юлия Доцева", "title": "🌟 Юлия Доцева (5★)", "type": "character"},
	{"id": "shoji", "name": "Сёдзи", "title": "🔥 Сёдзи (5★)", "type": "character"},
	{"id": "lenskaya", "name": "Ленская", "title": "❄ Ленская (5★)", "type": "character"},
	{"id": "rimes", "name": "Раймс", "title": "🌌 Раймс (5★)", "type": "character"},
	{"id": "musienko", "name": "Мусиенко", "title": "🌋 Мусиенко (5★)", "type": "character"},
	{"id": "valramors", "name": "Валраморс", "title": "🔮 Валраморс (5★)", "type": "character"},
	{"id": "joan_spirit", "name": "Жоан • Форма духа", "title": " Жоан • Форма духа (5★)", "type": "character"},
	{"id": "isaac_admin", "name": "Айзек • Права администратора", "title": "🔮 Айзек • Права администратора (5★)", "type": "character"},
	{"id": "sara_admin", "name": "Сара • Права администратора", "title": "🔮 Сара • Права администратора (5★)", "type": "character"},
	{"id": "shoji_swan", "name": "Сёдзи • Лебединое озеро", "title": "🦢 Сёдзи • Лебединое озеро (5★)", "type": "character"},
	{"id": "crimson_tears", "type": "weapon", "title": "⚔ Басня о Багровых слезах (5★ Конус)"},
	{"id": "perfect_metamorphosis", "type": "weapon", "title": "⚔ Идеальный Метаморфоз (5★ Конус)"},
	{"id": "save_the_world_plan", "type": "weapon", "title": "⚔ План по спасению мира (5★ Конус)"},
	{"id": "edge_of_existence", "type": "weapon", "title": "⚔ Рубеж Бытия (5★ Конус)"},
	{"id": "inevitable_fall", "type": "weapon", "title": "⚔ Падение мира неизбежно (5★ Конус)"},
	{"id": "corrupted_save", "type": "weapon", "title": "⚔ Повреждённое сохранение (5★ Конус)"},
	{"id": "server_crash_moment", "type": "weapon", "title": "⚔ Момент, когда падают сервера (5★ Конус)"},
	{"id": "history_soaked_in_blood", "type": "weapon", "title": "🩸 История, вымоченная в крови (5★ Конус)"},
	{"id": "why_did_you_remember_me", "type": "weapon", "title": "⚔ Почему ты вспомнила меня? (5★ Конус)"}
]

func _ready() -> void:
	firestore = get_node_or_null("../FirestoreService")
	current_banners = DEFAULT_BANNERS.duplicate(true)

func fetch_active_banners() -> void:
	if not FirebaseConfig.is_configured() or firestore == null:
		banners_updated.emit(current_banners)
		return

	# Запрашиваем активные баннеры из Firestore коллекции 'banners'
	firestore.get_collection("banners", func(success: bool, banners_from_cloud: Array[Dictionary]):
		if success and not banners_from_cloud.is_empty():
			var now := int(Time.get_unix_time_from_system())
			var filtered: Array[Dictionary] = []
			for b in banners_from_cloud:
				var start_t = int(b.get("start_timestamp", 0))
				var end_t = int(b.get("end_timestamp", 0))
				# Проверяем временное окно доступности баннера
				if (start_t == 0 or now >= start_t) and (end_t == 0 or now <= end_t):
					filtered.append(b)

			if not filtered.is_empty():
				current_banners = filtered
				print("[BannerService] Loaded %d active banners from Firestore!" % current_banners.size())

		banners_updated.emit(current_banners)
	)
