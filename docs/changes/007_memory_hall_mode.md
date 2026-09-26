# Задача
Разработка обновляемого игрового режима «Зал воспоминаний» (Memory Hall)

## Что сделано
- **Сезонный таймер (GMT+3)**: Сезон 1 активен до 01.11.2026 00:00 (GMT+3) (`1793480400`). Автоматический расчет оставшегося времени и блокировка режима по окончании сезона.
- **Турбулентность сезона**: Бафф Небожителей (+30% урона) и Рассвета Хаоса (+20% скорости), поддержаны базовые персонажи и их формы.
- **4 этажа с масштабированием сложности**:
  - 1 этаж (Бронза): Начальный уровень, 1 волна, 14 циклов.
  - 2 этаж (Серебро): Усиленные враги, 1 волна, 14 циклов.
  - 3 этаж (Золото): 2 волны противников с элитным лидером на второй волне, 14 циклов.
  - 4 этаж (Платина): 2 половины по 2 волны (всего 4 волны), 2 независимых отряда без повторяющихся героев, 28 суммарных циклов.
- **Превью противников**: Кнопка «🔍 Противники» в лобби с показом состава волн, элементов, уязвимостей и HP.
- **Система наград**: Начисление до 24 «Блеска Свечения» (5 за каждые 3 звезды до 12★ + 4 за закрытие 4 этажа).
- **Интерфейс меню**: 8-я карточка с анимированной фиолетовой рамкой (переливается при наличии незакрытых этажей).
- **Автотесты**: 10 модульных тестов сьют `tests/test_memory_hall_runner.tscn`.

## Изменённые файлы
- [`scripts/combat/memory_hall_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/combat/memory_hall_manager.gd): синглтон/менеджер режима, формулы, волны, интел.
- [`scripts/autoload/team_config.gd`](file:///Users/rimes/void-of-oblivion/scripts/autoload/team_config.gd): сохранение/загрузка прогресса, наград, пресетов отрядов 1 и 2.
- [`scripts/combat/battle_manager.gd`](file:///Users/rimes/void-of-oblivion/scripts/combat/battle_manager.gd): управление волнами, половинами 4-го этажа, турбулентностью.
- [`scenes/battle/battle.gd`](file:///Users/rimes/void-of-oblivion/scenes/battle/battle.gd): UI битвы, волны, оставшиеся циклы, переходы, победный расчет звезд.
- [`scenes/main_menu/main_menu.gd`](file:///Users/rimes/void-of-oblivion/scenes/main_menu/main_menu.gd): карточка с пульсирующей рамкой, лобби, модалка разведки, сетап двух отрядов.
- [`tests/test_memory_hall.gd`](file:///Users/rimes/void-of-oblivion/tests/test_memory_hall.gd): автотесты режима.
- [`tests/test_memory_hall_runner.tscn`](file:///Users/rimes/void-of-oblivion/tests/test_memory_hall_runner.tscn): тестовая сцена запуска.

## Как проверить
- Запуск тестов Зала воспоминаний:
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_memory_hall_runner.tscn`
- Ожидаемый результат: `РЕЗУЛЬТАТ: Пройдено: 10 / 10 (Ошибок: 0)`.
- Запуск регрессионных тестов:
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_marina_runner.tscn`
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_lenskaya_runner.tscn`
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_runner.tscn`

## Что осталось / TODO
- По завершении первого сезона реализовать ротацию турбулентности для сезона 2.
