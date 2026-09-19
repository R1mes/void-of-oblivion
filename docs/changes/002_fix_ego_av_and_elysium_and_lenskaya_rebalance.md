# Задача: Исправление багов шкалы действия Эго, зоны Элизиума и ребаланс Ленской • Хранитель небес

## Что сделано
1. **Исправлен Баг 1 (Сброс AV Эго при баффе Айзека)**:
   - В `scripts/combat/combat_unit.gd` добавлено отслеживание флага `_av_initialized`. Метод `recalculate_action_value()` теперь инициализирует AV только при первичном создании или если AV отрицательно, предотвращая сброс готового хода (`action_value == 0.0`) назад на `base_action_value`.
   - В `scripts/characters/isaac.gd` в `execute_ultimate` удалён избыточный вызов `target.recalculate_action_value()`, так как `add_speed_modifier()` корректно пересчитывает AV через `on_speed_changed()`.

2. **Исправлен Баг 2 (Ложный прок Элизиума от ненаносящего урон Навыка Q Сёдзи в танце)**:
   - В `scripts/combat/battle_manager.gd`:
     - В `start_attack_action()` при глубине действия 1 очищается массив `action_hit_enemies.clear()`.
     - В `player_skill` и `player_skill_e` добавлен сброс `action_hit_enemies.clear()`.
     - В `_end_turn()` добавлен сброс `action_hit_enemies.clear()`.
     - В `_process_elysium_zone_proc()` добавлена проверка общего урона текущего действия `float(get_meta("current_action_total_dmg", 0.0)) <= 0.0` для исключения срабатывания Элизиума от действий без урона.

3. **Ребаланс Ленской • Хранитель небес и Суперпробития**:
   - Базовые характеристики в `scripts/characters/lenskaya_sky_guardian.gd` повышены до стандарта 4* Hunt (как у Каори):
     - HP: 2400
     - ATK: 1900
     - DEF: 700
     - Break Effect (ЭП): 60% (0.60)
   - В `scripts/combat/battle_manager.gd`:
     - Талант Суперпробития Ленской адаптирован для Усиленной базовой атаки: каждый из 6 ударов теперь активирует собственное Суперпробитие (с множителем стойкости 5.0 на каждый удар вместо единичного срабатывания).
     - Вторичный чистый урон (включая фракционный урон Хранителей небес и Элизиум) исключён из триггера Суперпробития.

4. **Автоматические тесты**:
   - В `tests/test_marina_sky_guardian.gd` добавлены тесты `test_16_isaac_advance_and_ult_on_ego` и `test_17_shoji_dance_skill_q_no_elysium_damage`.
   - В `tests/test_lenskaya_sky_guardian.gd` обновлены проверки характеристик и расширен `test_7_talent_super_break_conversion` для валидации 6 ударов Суперпробития Усиленной базовой атаки.

## Изменённые файлы
- [`scripts/combat/combat_unit.gd`](file:///Users/rimes/void-of-oblivion/scripts/combat/combat_unit.gd): флаг `_av_initialized` и безопасный `recalculate_action_value()`.
- [`scripts/characters/isaac.gd`](file:///Users/rimes/void-of-oblivion/scripts/characters/isaac.gd): удаление сброса AV в ульте Айзека.
- [`scripts/combat/battle_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/combat/battle_manager.gd): очистка `action_hit_enemies`, защита Элизиума, мульти-хит Суперпробитие.
- [`scripts/characters/lenskaya_sky_guardian.gd`](file:///Users/rimes/void-of-oblivion/scripts/characters/lenskaya_sky_guardian.gd): увеличение характеристик (HP 2400, ATK 1900, DEF 700, BE 60%).
- [`tests/test_marina_sky_guardian.gd`](file:///Users/rimes/void-of-oblivion/tests/test_marina_sky_guardian.gd): тесты 16 и 17.
- [`tests/test_lenskaya_sky_guardian.gd`](file:///Users/rimes/void-of-oblivion/tests/test_lenskaya_sky_guardian.gd): актуализация статов и тест 6 ударов Суперпробития.

## Как проверить
1. Тесты Марины:
   `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_marina_runner.tscn` (17/17 PASS)
2. Тесты Ленской:
   `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_lenskaya_runner.tscn` (15/15 PASS)
3. Тесты Духов Памяти:
   `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_runner.tscn` (15/15 PASS)
