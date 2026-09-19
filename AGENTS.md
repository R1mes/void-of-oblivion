# AGENTS.md — Правила и контекст для Antigravity

## 1. Описание проекта
Пошаговая тактическая RPG в стиле Honkai: Star Rail на движке Godot 4. Включает глубокую боевую систему со стойкостью (Toughness), пробитиями, суперпробитием, Духами Памяти (Memosprites), системой фракций, реликвий, световых конусов и онлайн-профилем на Firebase.

## 2. Стек и версии
* **Движок**: Godot Engine 4.6.x (`gl_compatibility` рендерер, Jolt Physics 3D)
* **Язык**: GDScript (статическая типизация)
* **Бэкенд / Сеть**: Firebase REST API (Firestore, Firebase Authentication)
* **Платформы**: Windows Desktop, macOS, Android

## 3. Ключевая структура папок
* `scenes/` — UI сцены и игровые экраны (`battle/`, `main_menu/`, `team_setup/`).
* `scripts/combat/` — Ядро боевой системы (`battle_manager.gd`, `damage_calculator.gd`, `toughness_system.gd`, `combat_unit.gd`, подпапка `memosprite/`).
* `scripts/characters/` — Логика персонажей и их способностей.
* `scripts/enemies/` — Логика врагов и боссов.
* `scripts/data/` — Базы данных и реестры (`character_registry.gd`, `light_cone_registry.gd`, `relic_system.gd`).
* `scripts/network/` — Сетевые сервисы и интеграция с Firebase.
* `scripts/ui/` — Текстовые провайдеры и тултипы боя (`battle_info_provider.gd`).
* `tests/` — Автоматические тесты боевых механик (главный раннер, раннеры персонажей).
* `security/` — Криптографические ключи для подписи патчей (приватные ключи защищены `.gitignore`).
* `patches/` — Файлы инкрементальных обновлений игры (`.pck`, `.sig`).

## 4. Команды проекта
* **install**: Не настроено (не требуется, зависимости встроенные).
* **dev (запуск игры)**:
  `/Applications/Godot.app/Contents/MacOS/Godot --path .` (или через Godot Editor).
* **test (автотесты)**:
  * Все тесты Духов Памяти:
    `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_runner.tscn`
  * Тесты Марины • Хранитель небес:
    `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_marina_runner.tscn`
  * Тесты Ленской • Хранитель небес:
    `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_lenskaya_runner.tscn`
* **lint**: Не настроено (проверка синтаксиса выполняется движком Godot при компиляции/запуске тестов).
* **build**:
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release "Windows Desktop" build/VoidOfOblivion.exe`

## 5. Правила стиля и конвенции
* **Типизация**: Строгая статическая типизация в GDScript (`var target: CombatUnit = null`, `func get_name() -> String:`).
* **Именование**:
  * Классы: `PascalCase` (`class_name CombatUnit`).
  * Функции и переменные: `snake_case` (`calculate_damage()`, `current_turn`).
  * Приватные методы: префикс `_` (`_apply_buffs()`).
  * Константы: `UPPER_SNAKE_CASE`.
* **Боевая система**: Все расчёты урона, пробития и статусов должны производиться строго через `DamageCalculator`, `ToughnessSystem` и методы `BattleManager`. Не дублировать формулы в логику отдельных персонажей.
* **Метаданные**: Динамические статусы и эффекты хранить через `set_meta() / get_meta() / remove_meta()` с явной очисткой по завершении.

## 6. Что НЕЛЬЗЯ трогать
* ⛔ Папку `security/` и файлы закрытых ключей (`*.key`).
* ⛔ Конфигурации Firebase: `.firebaserc`, `firebase.json`, `firestore.rules`, `firestore.indexes.json`.
* ⛔ Настройки экспорта `export_presets.cfg` без прямого указания.
* ⛔ Папки пользовательских данных `user/`, `user_data/`.
* ⛔ Системные каталоги `.godot/`, `.git/`.

## 7. Как проверять изменения
1. **Запуск тестов headless**: Запустить соответствующий сьют через `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/<suite>.tscn`.
2. **Проверка компиляции**: Если тест завершился с кодом 0 и выводом `[PASS]`, код валиден и не содержит синтаксических ошибок.
3. **Логирование**: Обращать внимание на ошибки `SCRIPT ERROR` и предупреждения утечек памяти в выводе.

## 8. Правила экономии токенов для агента
* ⚡ **Не читать весь проект без запроса**: изучать только конкретные файлы, затрагиваемые задачей. Использовать `grep_search` и точечный просмотр строк через `view_file` с `StartLine/EndLine`.
* ⚡ **Сначала план — потом код**: перед сложными правками сформулировать краткий план и зафиксировать его.
* ⚡ **Отвечать кратко, без длинных объяснений**: формулировать суть правок без «воды» и повторения очевидного.
* ⚡ **Не использовать браузер / скриншоты**, если задача относится к логике, формулам, расчётам или бэкенду.
