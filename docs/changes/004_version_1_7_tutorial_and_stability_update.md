# Релиз версии 1.7 (Void of Oblivion 1.7)

## Что сделано
- **Переработка и стабилизация обучения (Уровни 1–4)**:
  - Убраны дублирующиеся кнопки пропуска диалогов (кнопка пропуска теперь доступна только в начале уровня).
  - Интегрировано подробное контекстное обучение горячим клавишам: выбор способностей (`W` — базовая атака, `Q` — первая способность, `E` — навык, `R` — вторая способность), переключение целей (`A` / `D`), подтверждение хода (`Space` / `Enter`), активация сверхспособностей (`1`, `2`, `3`, `4` по слотам отряда).
  - Добавлены визуальные акценты и понятные пошаговые подсказки действий без блокирующих зависаний.
- **Исправление боевой механики 3-го уровня**:
  - Устранено искусственное принудительное пробитие квантовой стойкости без соответствия типу уязвимости.
  - Первым персонажем отряда назначена Каори (`battle_initiator_id = "kaori"`), которая легитимно снижает и пробивает физическую стойкость Элитного стража (30 + 60 = 90 ед.).
  - Автоматическое использование техник персонажей теперь отключено во время туториалов (`not LevelManager.is_tutorial`), чтобы игрок управлял ходом боя самостоятельно.
- **Интерфейс боя и карт персонажей**:
  - Убраны конфликтующие визуальные бейджи (`TurnBadge`, `ActiveTurnBorder`), восстановлена плавная и стабильная система подъёма активной карты персонажа без визуальных багов и дублирования.
  - Исправлено наложение статусов и обновление характеристик при нажатии навыка (`E`) и сверхспособностей.
- **Гача и меню**:
  - Исправлено перекрытие карточки выпадения персонажа (Сара) рамкой кнопки призыва: элементы обучения скрываются во время анимации, слой карточки призыва поднят на `z_index = 150`.
  - Исправлена блокировка кнопок после фразы «Я жду тебя на 5 уровне»: все кнопки хаба (Уровни, Персонажи, Реликвии, База данных, Инвентарь, Магазин, Молитва) и кнопка «Назад» корректно разблокируются, возвращая игрока в хаб.
- **Патч и версионирование**:
  - Версия клиента обновлена до `1.7`.
  - Сгенерирован и подписан криптографический пакет обновления `patch_v1.7.pck` и `version_manifest.json`.

## Изменённые файлы
- [`scripts/updater/patch_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/updater/patch_manager.gd): версия клиента обновлена до `1.7`.
- [`scenes/battle/battle.gd`](file:///Users/rimes/void-of-oblivion/scenes/battle/battle.gd): удалены проблемные плашки и границы хода, стабилизирована логика подсветки/подъёма карт, подсказки горячих клавиш.
- [`scripts/combat/battle_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/combat/battle_manager.gd): отключены автотехники в режиме обучения.
- [`scripts/combat/level_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/combat/level_manager.gd): Каори выставлена инициатором боя и первой в отряде на 3 уровне.
- [`scenes/main_menu/main_menu.gd`](file:///Users/rimes/void-of-oblivion/scenes/main_menu/main_menu.gd): исправление слоя гачи и корректная разблокировка всех разделов меню после туториала.
- [`patches/version_manifest.json`](file:///Users/rimes/void-of-oblivion/patches/version_manifest.json): манифест релиза 1.7 с цифровой подписью.

## Как проверить
- Автотесты:
  - `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_level1_runner.tscn`
  - `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_level3_runner.tscn`
  - `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_runner.tscn`
  - `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_marina_runner.tscn`
  - `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_lenskaya_runner.tscn`
- Ожидаемый результат: Все тесты завершаются с кодом 0 и статусом `[PASS]`.
- Проверка сборщика патчей: `bash tools/patch_builder/build_patch.sh "1.7" ...`
