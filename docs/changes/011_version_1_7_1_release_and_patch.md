# Релиз версии 1.7.1 (Void of Oblivion 1.7.1)

## Что сделано
- **Интеграция сплеш-артов персонажей**:
  - Карточки в Инвентаре, меню "Текущий отряд" и слоты настройки отряда получили фоновые сплеш-арты высокого разрешения с затемняющим градиентом для читаемости текста.
  - Настройка отряда перед уровнем переведена на горизонтальный плавно прокручиваемый ряд (карусель) с увеличенными карточками.
- **Новый режим «Зал воспоминаний» (Memory Hall)**:
  - 5 уникальных этажей возрастающей сложности со специальными механиками усилений и наградами.
  - Сохранение прогресса, отображение звёзд и условий победы.
- **Кинематографичная анимация Сверхспособности**:
  - При нажатии на кнопку ультимейта или горячие клавиши 1-4 от кнопки исходит ударная волна в цвет стихии (1.0с).
  - Сверхспособность сразу ставится в очередь: сначала на затемнённом фоне проигрывается 3-фазная кат-сцена карточки персонажа со сплеш-артом, и лишь затем поле боя открывается для выбора цели.
  - 3 фазы кат-сцены: быстрое появление силуэта с раскрытием цвета (0.64с), спокойный дрейф цветной карточки (0.60с), ускоренное погружение и растворение (0.38с).
- **Интерфейс инвентаря и модальные окна**:
  - Меню эйдолонов сделано полностью непрозрачным с изоляцией по Z-index (200), устранено просвечивание карточек персонажей.
  - Добавлено модальное окно подробного описания световых конусов с информацией о владельце и характеристиках.
- **Динамика карт в бою**:
  - Плавное покачивание активного союзника на своём ходу и мягкий дрейф неактивных противников ("дыхание").
- **Патч и система автообновления**:
  - Версия клиента обновлена до `1.7.1`.
  - Сгенерирован и подписан криптографический пакет `patch_v1.7.1.pck` и `version_manifest.json` ключом RSA-2048.
  - Клиенты на версии 1.7 и ранее при запуске автоматически получают предложение обновиться до 1.7.1.

## Изменённые файлы
- [`scripts/updater/patch_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/updater/patch_manager.gd): версия клиента обновлена до `1.7.1`.
- [`patches/version_manifest.json`](file:///Users/rimes/void-of-oblivion/patches/version_manifest.json): подписанный манифест релиза 1.7.1.
- [`scenes/battle/battle.gd`](file:///Users/rimes/void-of-oblivion/scenes/battle/battle.gd): кат-сцена ультимейта, ударная волна кнопки, динамика карт, сплеш-арты.
- [`scenes/main_menu/main_menu.gd`](file:///Users/rimes/void-of-oblivion/scenes/main_menu/main_menu.gd): сплеш-арты инвентаря, отряда, модальные окна эйдолонов и конусов.
- [`scenes/team_setup/team_setup.gd`](file:///Users/rimes/void-of-oblivion/scenes/team_setup/team_setup.gd): горизонтальная карусель персонажей.
- [`scripts/combat/battle_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/combat/battle_manager.gd): порядок вызова кат-сцены до прицеливания в очереди ультимейтов.
- [`scripts/combat/memory_hall_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/combat/memory_hall_manager.gd): менеджер Зала воспоминаний.
- [`tests/test_character_splashes.gd`](file:///Users/rimes/void-of-oblivion/tests/test_character_splashes.gd): 14 автоматических тестов сплешей, модалок и безопасности боя.

## Как проверить
- Автотесты:
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_character_splashes_runner.tscn`
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_card_dynamics_runner.tscn`
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_batch_fixes_runner.tscn`
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_memory_hall_runner.tscn`
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_marina_runner.tscn`
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_lenskaya_runner.tscn`
