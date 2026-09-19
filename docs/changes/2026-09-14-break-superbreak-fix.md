# Задача: Корректировка формул урона Пробития (Break DMG) и Суперпробития (Super Break DMG)

Приведение боевых формул Пробития и Суперпробития к эталонным спецификациям референса с фиксированным базовым множителем уровня `1640.0`.

## Что сделано
1. **Обновлены базовые константы и коэффициенты стихий в `DamageCalculator`**:
   - Задан `const LEVEL_MULTIPLIER := 1640.0`.
   - Внедрены точные коэффициенты элементов для базового урона пробития:
     - Физический / Огненный: $2.0 \times 1640 = 3280.0$
     - Ветряной: $1.5 \times 1640 = 2460.0$
     - Молния / Лёд: $1.0 \times 1640 = 1640.0$
     - Квантовый / Мнимый: $0.5 \times 1640 = 820.0$
   - Добавлен масштабирующий множитель стойкости цели $(0.5 + \text{max\_toughness} / 120.0)$.

2. **Реализована полная формула урона Пробития (`calc_break_damage`)**:
   - Добавлен расчёт множителя защиты цели (`get_def_multiplier`) по эталонной формуле:
     $$\text{DEF Mult} = \frac{\text{Уровень атакующего} + 20}{(\text{Уровень врага} + 20) \times (1 - \text{DEF Shred} - \text{DEF Ignore}) + \text{Уровень атакующего} + 20}$$
   - Интегрированы множители сопротивлений (`RES Mult`), получаемого урона цели (`Vuln Mult`), снижения урона (`DMG Red Mult`) и множитель неистощённой стойкости цели ($0.9$).

3. **Исправлена формула Суперпробития (`calc_super_break_damage`)**:
   - Делитель урона стойкости приведён к эталону $/ 10.0$ (вместо устаревшего $/ 30.0$).
   - Устранено ошибочное умножение на максимальную стойкость цели $(target\_max\_tgh + 2.0)$ — суперпробитие теперь строго масштабируется от истощения стойкости конкретной атаки.
   - Подключены эталонные множители защиты, сопротивления, уязвимости цели и бонусов урона суперпробития.

## Старые и новые формулы

### 1. Урон Пробития (Break DMG)
* **Старая формула**:
  $$\text{Break DMG} = 600.14 \times (\text{target\_max\_toughness} + 2.0) \times (1 + \text{Break Effect}) \times (\text{Radiance 1.30 if applicable})$$
  *(Защита цели, RES цели, уязвимости, снижение урона и множитель 0.9 не учитывались).*
* **Новая формула**:
  $$\text{Break DMG} = \text{Base Break} \times \text{Ability Mult} \times (1 + \text{Break Effect}) \times (1 + \text{Break Boost}) \times \text{DEF Mult} \times \text{RES Mult} \times \text{Vuln Mult} \times \text{DMG Red Mult} \times 0.9$$
  где $\text{Base Break} = 1640.0 \times \text{Elem Mult} \times (0.5 + \frac{\text{target\_max\_toughness}}{120.0})$.

### 2. Урон Суперпробития (Super Break DMG)
* **Старая формула**:
  $$\text{Super Break} = [600.14 \times (\text{target\_max\_tgh} + 2.0)] \times \frac{\text{base\_tgh\_reduction}}{30.0} \times (1 + \text{BE}) \times (1 + \text{Extra SB}) \times (1 - \frac{\text{DEF}}{\text{DEF} + 300}) \times \text{RES} \times \text{Vuln}$$
* **Новая формула**:
  $$\text{Super Break} = \frac{\text{Effective Toughness Reduction}}{10.0} \times 1640.0 \times \text{Ability Mult} \times (1 + \text{BE}) \times (1 + \text{Break Boost}) \times (1 + \text{Extra SB Boost}) \times \text{DEF Mult} \times \text{RES Mult} \times \text{Vuln Mult} \times \text{DMG Red Mult}$$

## Затронутые игровые сценарии и персонажи
* **Ленская • Хранитель небес**:
  - Конверсия урона атак по пробитой цели в суперпробитие (60% по таланту) теперь точно соответствует эталону.
  - След 3 (+30% суперпробития усиленной базовой атаки) корректно перемножается в итоговой формуле.
  - Дебафф «Враг Свечения» (+30% / +45% урона пробития и суперпробития) применяется через единый реестр уязвимости (`Vuln Mult`).
* **Даша**:
  - Суперпробитие Навыка Q (30 единиц истощения стойкости по центральной и соседним целям) теперь рассчитывается по эталонному шагу стойкости $/ 10.0$.
* **Сёдзи**:
  - Дебафф уязвимости танца (`shoji_swan_dance_vuln_pct`) и срез огненного сопротивления цели корректно усиливают урон пробития и суперпробития.
* **Валраморс**:
  - Уязвимость от Сверхспособности (`valramors_ult_vuln`) и игнорирование защиты от техники (`valramors_tech_ignore`) усиливают как пробитие, так и суперпробитие союзников.
* **Раймс, Катарина, Жоан, Эго Марины**:
  - Входящие статусы уязвимости и срез сопротивлений/защиты теперь корректно и прозрачно усиливают эффекты пробития команды.

## Изменённые файлы
- [`scripts/combat/damage_calculator.gd`](file:///Users/rimes/void-of-oblivion/scripts/combat/damage_calculator.gd): реализация `LEVEL_MULTIPLIER`, коэффициентов стихий, хелперов `get_def_multiplier`, `get_vuln_multiplier`, `get_dmg_reduction_multiplier`, обновление `calc_raw_break_damage`, `calc_break_damage` и `calc_super_break_damage`.
- [`tests/test_break_system.gd`](file:///Users/rimes/void-of-oblivion/tests/test_break_system.gd): новый сьют автотестов формул пробития и суперпробития (6 тестов).
- [`tests/test_break_runner.tscn`](file:///Users/rimes/void-of-oblivion/tests/test_break_runner.tscn): сцена запуска тестов пробития.

## Как проверить
1. Запуск нового тестового сьюта:
   `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_break_runner.tscn`
   *Ожидаемый результат*: `6 / 6 [PASS]`.
2. Запуск тестов Духов Памяти (регрессия):
   `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_runner.tscn`
   *Ожидаемый результат*: `15 / 15 [PASS]`.
3. Запуск тестов Марины:
   `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_marina_runner.tscn`
   *Ожидаемый результат*: `17 / 17 [PASS]`.

## Что осталось / TODO
- Все поставленные задачи по формулам пробития и суперпробития выполнены полностью.
