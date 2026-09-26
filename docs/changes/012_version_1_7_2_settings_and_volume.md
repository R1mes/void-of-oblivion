# Релиз версии 1.7.2 (Void of Oblivion 1.7.2)

## Что сделано
- **Меню «⚙️ Настройки»**:
  - Добавлена кнопка «⚙️ Настройки» на главном экране (под загрузкой сохранения) и на нижней панели Хаба (рядом с сохранением).
  - Красивое модальное окно на отдельном слое `CanvasLayer` (layer 115) с затемнённым оверлеем и тёмно-синей стилизованной панелью с золотистой рамкой.
- **Регулировка общей громкости звука и музыки**:
  - Ползунок громкости (`HSlider`) от `0` до `10` с шагом `1` и делениями.
  - Значение по умолчанию: `7 / 10` (70%).
  - Прямое управление шиной `Master` в `AudioServer` через функцию `TeamConfig.apply_audio_volume(vol)`.
  - При значении `0 / 10` шина полностью глушится (`AudioServer.set_bus_mute(bus_idx, true)`), при значениях `1..10` устанавливается соответствующий уровень в децибелах через `linear_to_db(vol / 10.0)`.
  - Изменение ползунка мгновенно меняет громкость и сохраняет конфигурацию.
- **Персистентность настроек**:
  - Поле `master_volume` интегрировано в `save_game()`, `load_game()` и `reset_all_progress()` в `TeamConfig`.
  - Настройки сохраняются как локально, так и в облаке Firestore.
- **Система обновлений и патч**:
  - Версия клиента повышена до `1.7.2` в `scripts/updater/patch_manager.gd`.
  - Сгенерирован инкрементальный пакет `patch_v1.7.2.pck` (39.6 МБ) и подписан приватным RSA-2048 ключом.
  - Обновлён `patches/version_manifest.json`.

## Изменённые файлы
- [`scripts/autoload/team_config.gd`](file:///Users/rimes/void-of-oblivion/scripts/autoload/team_config.gd): хранение, применение и сохранение громкости `master_volume`.
- [`scenes/main_menu/main_menu.gd`](file:///Users/rimes/void-of-oblivion/scenes/main_menu/main_menu.gd): кнопки настроек на титульном экране и в хабе, модальное окно с ползунком.
- [`scripts/updater/patch_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/updater/patch_manager.gd): поднятие версии до 1.7.2.
- [`tools/patch_builder/build_patch.sh`](file:///Users/rimes/void-of-oblivion/tools/patch_builder/build_patch.sh): исправление аргументов для сборки патча.
- [`patches/version_manifest.json`](file:///Users/rimes/void-of-oblivion/patches/version_manifest.json): подписанный манифест 1.7.2.

## Как проверить
- Автотесты:
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_character_splashes_runner.tscn`
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_batch_fixes_runner.tscn`
