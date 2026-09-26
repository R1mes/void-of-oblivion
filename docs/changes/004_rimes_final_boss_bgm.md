# Фоновая музыка в бою (BGM) и плавное затухание

## Что сделано
1. **Плавное затухание музыки при выходе из боя**:
   - При нажатии кнопки «Сдаться» или кнопки «Назад» на экране победы/поражения музыка плавно затухает (`volume_db` уменьшается с `-3.0` до `-60.0` за 0.75 секунды с помощью `create_tween()`), после чего происходит переход на предыдущий экран.
   - Повторные нажатия кнопки возврата блокируются на время затухания.
   - Переход сцены вызывается через `.call_deferred(...)`.
2. **Битва с Вельзевулом (`velzebul_boss`)**:
   - С самого начала битвы зацикленно играет композиция `my heart *+ — jdmfessh, nudness` (`assets/audio/my_heart.mp3`).
3. **Битва с Раймсом (`rimes_final_boss`)**:
   - В 1 фазе и до первого использования Зова / Хора Человечества играет композиция `Unbridled Growth — HOYO-MiX` (`assets/audio/unbridled_growth.mp3`).
   - Переход на 2 или 3 фазу НЕ прерывает трек.
   - Сразу после первой активации «Зова Человечества» / «Хора Человечества» (`chorus_activated`) музыка переключается на `Hopes And Dreams — Toby Fox (Mash-up)` (`assets/audio/hopes_and_dreams.mp3`) и зацикленно играет до окончания боя.
4. **Бои по умолчанию**:
   - Во всех остальных боях, где не задан специальный трек, по умолчанию играет тема `Most Wanted — Honkai: Star Rail` (`assets/audio/most_wanted.mp3`).
5. **Зацикливание аудио**:
   - Все аудиофайлы настроены с `loop = true` в конфигурации импорта Godot (`.mp3.import`), принудительно выставляют `loop = true` на `AudioStreamMP3` при загрузке, а также подписаны на сигнал `finished` плеера.

## Изменённые файлы
- [`assets/audio/most_wanted.mp3`](file:///Users/rimes/void-of-oblivion/assets/audio/most_wanted.mp3): дефолтная музыка для боев.
- [`assets/audio/my_heart.mp3`](file:///Users/rimes/void-of-oblivion/assets/audio/my_heart.mp3): тема битвы с Вельзевулом.
- [`assets/audio/unbridled_growth.mp3`](file:///Users/rimes/void-of-oblivion/assets/audio/unbridled_growth.mp3): тема битвы с Раймсом (Фаза 1 и до Хора Человечества).
- [`assets/audio/hopes_and_dreams.mp3`](file:///Users/rimes/void-of-oblivion/assets/audio/hopes_and_dreams.mp3): тема битвы с Раймсом после активации Хора Человечества.
- [`scenes/battle/battle.gd`](file:///Users/rimes/void-of-oblivion/scenes/battle/battle.gd): система выбора трека, переключения по событию Хора Человечества и плавного затухания громкости при выходе.
- [`scripts/combat/battle_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/combat/battle_manager.gd): сигнал `boss_phase_changed` и эмит события `chorus_activated`.
- [`scripts/updater/patch_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/updater/patch_manager.gd): защита исходников в режиме редактора от монтирования старых PCK.
- [`tests/test_rimes_boss_bgm.gd`](file:///Users/rimes/void-of-oblivion/tests/test_rimes_boss_bgm.gd): тест загрузки всех 4 аудиофайлов, тем боссов, триггера Хора Человечества, зацикливания и фейдаута.
- [`tests/test_rimes_boss_bgm_runner.tscn`](file:///Users/rimes/void-of-oblivion/tests/test_rimes_boss_bgm_runner.tscn): тестовый раннер.

## Как проверить
- Запуск теста BGM:
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_rimes_boss_bgm_runner.tscn`
- Ожидаемый результат: `Пройдено: 6 / 6 (Ошибок: 0)`
