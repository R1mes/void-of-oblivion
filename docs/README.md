# Документация проекта Void of Oblivion (Версия 1.7)

## Архитектура
Проект построен по модульному принципу на Godot Engine 4.6 (GDScript со статической типизацией):

* **Боевое ядро (`scripts/combat/`)**:
  * `battle_manager.gd` — центральный менеджер боя (очередь ходов на базе Action Value, цикл действий, обработка эффектов начала/конца хода, начисление очков действий и энергии, внеочередные ультимейты).
  * `damage_calculator.gd` — единый калькулятор прямого урона, урона пробития (Break DMG), суперпробития (Super Break DMG), критических ударов, сопротивлений (RES / RES PEN), срезов защиты (DEF Reductions / DEF Ignore).
  * `toughness_system.gd` — система истощения стойкости, пробития уязвимостей и наложения элементальных статусов пробития.
  * `combat_unit.gd` / `combat_stats.gd` — базовые сущности участников боя и их эффективных характеристик.
  * `memosprite/` — подсистема Духов Памяти (призыв, привязка к наставнику, независимая шкала действий ИД, перенаправление урона, автобой/ручное управление).
  * `memory_hall_manager.gd` — эндгейм-режим «Зал воспоминаний» (Memory Hall) с сезонным таймером (GMT+3), Турбулентностью, 4 этажами сложности, механикой двух отрядов на 4 этаже и наградами в виде Блеска Свечения.
  * `faction_system.gd` — синергии фракций («Обречённые», «Рассвет Хаоса», «Эмпирейцы», «Академия», «Консоль», «Антиматерия», «Хранители небес»).
  * `level_manager.gd` — модуль уровней кампании (1–22), контекстного обучения (уровни 1–4, горячие клавиши) и наград.

* **Персонажи и Способности (`scripts/characters/`)**:
  * 34 игровых персонажа (включая альтернативные формы Консоли, Хранителей небес, Антиматерии, Сангинию Ял и Раймса • Восхождение). Каждый герой имеет модульный файл способностей со статическими фабриками и изолированной логикой талантов, навыков и эйдолонов.

* **Враги и Боссы (`scripts/enemies/`)**:
  * Фабрики и скрипты ИИ для рядовых противников (Солдаты Пустоты, Заражённые, Рабы антиматерии, Повстанцы), элитных монстров (Элитный страж, Бронированный рыцарь, Орто Мутант, Ортофетаминовый ужас, Чистильщик цитадели, Кайл — лидер повстанцев) и многофазных боссов (Повелитель Пустоты, Силуэт в маске, Серверный вирус, Сёдзи ВЗ, Босс Вельзевул, Финальный Босс Раймс).

* **Реестры и Данные (`scripts/data/`)**:
  * `character_registry.gd` — реестр 34 персонажей, пути, стихии, редкости, сплеш-арты и рекомендации по сборкам.
  * `light_cone_registry.gd` — реестр 50 световых конусов с подробными эффектами и масштабированием.
  * `relic_system.gd` — система реликвий (18 пещерных и 10 планарных комплектов, генерация характеристик, роллы сабстатов, 9 пещерных и 5 планарных данжей).

* **Сетевой слой и Облако (`scripts/network/`)**:
  * `firebase_auth.gd` — аутентификация и регистрация аккаунтов через Firebase Auth REST API.
  * `firestore_service.gd` — работа с коллекциями Cloud Firestore.
  * `sync_manager.gd` — двусторонняя синхронизация профиля с защитой от оффлайна и буферизацией сохранений.
  * `promo_service.gd` — активация онлайн и оффлайн промокодов (включая предустановленный `RIMES1000`).
  * `banner_service.gd` — логика ивентовых баннеров и расчет гарантов гачи.

* **Пользовательский интерфейс и визуал (`scenes/`, `scripts/ui/`)**:
  * `scenes/battle/` (`battle.gd`, `battle.tscn`) — боевой интерфейс, 3-фазная кинематографичная кат-сцена ультимейта, парение и покачивание карточек (Card Dynamics), затемнение неактивных целей (dimming 0.60), сплеш-арты, оверлеи заморозки, FCT.
  * `scenes/main_menu/` (`main_menu.gd`, `main_menu.tscn`) — хаб, карусель отряда, карта уровней с плавной прокруткой, модалка Зала воспоминаний, магазин, гача, инвентарь с Z-index изоляцией эйдолонов/конусов, атлас базы данных.
  * `scenes/team_setup/` (`team_setup.gd`, `team_setup.tscn`) — админ-панель и песочница для тестирования персонажей, врагов и отрядов.
  * `scripts/ui/battle_info_provider.gd` — генератор форматированных BBCode-описаний способностей, статусов, баффов и дебаффов.

* **Автоапдейтер (`scripts/updater/`)**:
  * `patch_manager.gd` — Zero-Trust загрузчик и верификатор криптографически подписанных инкрементальных обновлений (`.pck`, `version_manifest.json`).

---

## Как запускать локально
1. **Через Godot Editor**:
   * Открыть проект в Godot Engine 4.6 (`project.godot`).
   * Нажать `F5` (запуск проекта) или `F6` (запуск текущей сцены).
2. **Через терминал (CLI)**:
   ```bash
   /Applications/Godot.app/Contents/MacOS/Godot --path .
   ```

---

## Автоматическое тестирование (Test Suites)
Для полной проверки стабильности и верификации боевых механик без графического окна используются headless-автотесты Godot:

* **Главный раннер боевой системы и Духов Памяти (Memosprites)**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_runner.tscn
  ```
* **Зал воспоминаний (Memory Hall)**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_memory_hall_runner.tscn
  ```
* **Сангиния Ял (механики, FUA, «Особый гость»)**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_sanguinia_runner.tscn
  ```
* **Раймс • Восхождение и Дух Памяти «Лапы антиматерии»**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_rimes_ascension_runner.tscn
  ```
* **Марина • Хранитель небес и Дух Памяти «Эго»**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_marina_runner.tscn
  ```
* **Ленская • Хранитель небес (Враг Свечения, Суперпробитие)**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_lenskaya_runner.tscn
  ```
* **Стойкость, Пробитие и Суперпробитие**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_break_runner.tscn
  ```
* **Интеграция сплеш-артов, модальные окна и кат-сцены ультимейта**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_character_splashes_runner.tscn
  ```
* **Динамика карт (парение, покачивание, дыхание)**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_card_dynamics_runner.tscn
  ```
* **Пакетные фиксы (промокоды, Арсений, затенение карт)**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_batch_fixes_runner.tscn
  ```
* **Новый контент (враги восстания/антиматерии, новые сеты реликвий)**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_new_content_runner.tscn
  ```
* **Световые конусы и база данных**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_light_cones_and_db_runner.tscn
  ```
* **Обучение и кампания (Уровни 1 и 3)**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_level1_runner.tscn
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_level3_runner.tscn
  ```

**Критерии успешности**:
* Код завершения процесса `0`.
* Отсутствие `SCRIPT ERROR` в консоли.
* Все тесты в сьюте отмечены как `[PASS]`.
