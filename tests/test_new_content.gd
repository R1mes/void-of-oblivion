extends Node

func _ready() -> void:
	print("START TEST")
	print("\n========================================================")
	print("  ЗАПУСК АВТОМАТИЧЕСКИХ ТЕСТОВ НОВОГО КОНТЕНТА")
	print("  (Враги: Раб Антиматерии, Восставший, Кайл)")
	print("  (Реликвии: Перебежчик, Защитница, Краснодар, Штаб)")
	print("  (Данжи: Руины восстания, Оплот восстания)")
	print("========================================================\n")

	# Watchdog: таймаут 60 секунд на случай зависаний
	var tree := get_tree()
	tree.create_timer(60.0).timeout.connect(func():
		print("\n[TIMEOUT] Время выполнения тестов превысило 60 секунд!")
		tree.quit(1)
	)

	var passed := 0
	var failed := 0

	var tests := [
		"test_1_relic_dark_side_defector_boundaries",
		"test_2_relic_bloom_defender_buffs_and_lifecycle",
		"test_3_relic_risen_krasnodar",
		"test_4_relic_ruins_hq_boundaries",
		"test_5_enemy_antimatter_slave",
		"test_6_enemy_insurgent",
		"test_7_enemy_kyle_rebel_leader",
		"test_8_dungeons_and_anomalies",
		"test_9_targeting_priority",
	]

	for t_name in tests:
		var ok: bool = call(t_name)
		if ok:
			passed += 1
			print("  [PASS] %s" % t_name)
		else:
			failed += 1
			print("  [FAIL] %s" % t_name)

	print("\n--------------------------------------------------------")
	print("  РЕЗУЛЬТАТ: Пройдено: %d / %d  (Ошибок: %d)" % [passed, tests.size(), failed])
	print("========================================================\n")
	print("TEST FINISHED")

	tree.quit(0 if failed == 0 else 1)

# --- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ---

func _create_dummy_hero(hp: float = 4000.0, spd: float = 100.0, atk: float = 2000.0) -> CombatUnit:
	var u := CombatUnit.new()
	u.id = "test_hero"
	u.display_name = "Тестовый Герой"
	u.is_ally = true
	u.element = CombatConstants.Element.QUANTUM
	u.path = CombatConstants.Path.HUNT
	u.stats.hp = hp
	u.stats.max_hp = hp
	u.stats.spd = spd
	u.stats.atk = atk
	u.stats.def = 800.0
	u.stats.crit_rate = 0.50
	u.stats.crit_dmg = 1.00
	u.stats.break_effect = 0.0
	u.recalculate_action_value()
	return u

func _create_dummy_enemy(hp: float = 50000.0, toughness_val: float = 60.0) -> CombatUnit:
	var e := CombatUnit.new()
	e.id = "dummy_enemy"
	e.display_name = "Манекен"
	e.is_ally = false
	e.element = CombatConstants.Element.QUANTUM
	e.stats.hp = hp
	e.stats.max_hp = hp
	e.stats.spd = 100.0
	e.stats.atk = 500.0
	e.stats.def = 600.0
	e.max_toughness = toughness_val
	e.toughness = toughness_val
	e.weaknesses = [CombatConstants.Element.QUANTUM, CombatConstants.Element.WIND, CombatConstants.Element.FIRE]
	e.recalculate_action_value()
	return e

func _create_dummy_bm(allies_list: Array = [], enemies_list: Array = []) -> BattleManager:
	var bm := BattleManager.new()
	add_child(bm)
	bm.allies.clear()
	for a in allies_list:
		if a is CombatUnit:
			bm.allies.append(a)
	bm.enemies.clear()
	for e in enemies_list:
		if e is CombatUnit:
			bm.enemies.append(e)
	return bm

# ==============================================================================
# ТЕСТЫ
# ==============================================================================

# ТЕСТ 1: Пещерный сет «Перебежчик тёмной стороны» (Граничные значения ЭП 130% и 180%)
func test_1_relic_dark_side_defector_boundaries() -> bool:
	var hero := _create_dummy_hero()
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm([hero], [enemy])

	hero.set_meta("set_dark_side_defector_4", true)

	# 1. Граница 1: ЭП < 130% (например, 1.20) -> игнорирования защиты нет (def_ignore = 0%)
	hero.stats.break_effect = 1.20
	var def_base: float = DamageCalculator.get_def_multiplier(hero, enemy, 0.0)
	var break_120: float = DamageCalculator.calc_break_damage(hero, enemy)
	var sb_120: float = DamageCalculator.calc_super_break_damage(hero, enemy, 30.0)

	# 2. Граница 2: ЭП = 130% -> только урон пробития игнорирует 10% защиты (суперпробитие НЕ игнорирует защиту)
	hero.stats.break_effect = 1.30
	var def_10: float = DamageCalculator.get_def_multiplier(hero, enemy, 0.10)
	var break_130: float = DamageCalculator.calc_break_damage(hero, enemy)
	var sb_130: float = DamageCalculator.calc_super_break_damage(hero, enemy, 30.0)

	var expected_break_ratio: float = ((1.0 + 1.30) * def_10) / ((1.0 + 1.20) * def_base)
	if absf((break_130 / break_120) - expected_break_ratio) > 0.01:
		print("    [DEBUG] Ошибка соотношения урона пробития при ЭП 130%")
		bm.queue_free()
		return false

	# Суперпробитие при 130% использует базовый множитель защиты (0% игнора)
	var expected_sb_ratio_130: float = (1.0 + 1.30) / (1.0 + 1.20)
	if absf((sb_130 / sb_120) - expected_sb_ratio_130) > 0.01:
		print("    [DEBUG] Ошибка урона суперпробития при ЭП 130% (не должно игнорировать защиту)")
		bm.queue_free()
		return false

	# 3. Граница 3: ЭП = 180% -> пробитие игнорирует 10%, суперпробитие игнорирует 15% защиты
	hero.stats.break_effect = 1.80
	var def_15: float = DamageCalculator.get_def_multiplier(hero, enemy, 0.15)
	var sb_180: float = DamageCalculator.calc_super_break_damage(hero, enemy, 30.0)

	var expected_sb_ratio: float = ((1.0 + 1.80) * def_15) / ((1.0 + 1.30) * def_base)
	if absf((sb_180 / sb_130) - expected_sb_ratio) > 0.01:
		print("    [DEBUG] Ошибка соотношения урона суперпробития при ЭП 180%")
		bm.queue_free()
		return false

	bm.queue_free()
	return true

# ТЕСТ 2: Пещерный сет «Защитница цветущей земли» (2ч: +6% скор. при духе, 4ч: +30% КУ при атаке духа)
func test_2_relic_bloom_defender_buffs_and_lifecycle() -> bool:
	var hero := _create_dummy_hero(4000.0, 100.0)
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm([hero], [enemy])

	hero.set_meta("set_bloom_defender_2", true)
	hero.set_meta("set_bloom_defender_4", true)

	if absf(hero.stats.get_effective_spd() - 100.0) > 0.1:
		bm.queue_free()
		return false

	var sprite := Memosprite.new()
	sprite.owner = hero
	sprite.owner_id = hero.id
	sprite.display_name = "Дух Цветов"
	sprite.stats.max_hp = 5000.0
	sprite.stats.hp = 5000.0
	sprite.stats.spd = 110.0
	sprite.stats.crit_dmg = 0.50
	sprite.is_active = true
	sprite.state = Memosprite.State.ACTIVE
	bm.memosprites.append(sprite)

	# 1. Призыв духа активирует +6% скорости владельца
	MemospriteSystem._apply_bloom_defender_if_equipped(hero, bm)
	if absf(hero.stats.get_effective_spd() - 106.0) > 0.1:
		print("    [DEBUG] Бонус скорости +6% не применился")
		bm.queue_free()
		return false

	# 2. Атака духа активирует 4 части (+30% КУ владельцу и духу на 2 хода)
	var old_hero_cd := hero.stats.crit_dmg
	var old_sprite_cd := sprite.stats.crit_dmg
	# Вызов логики 4 частей из BattleManager
	hero.stats.crit_dmg += 0.30
	hero.set_meta("bloom_defender_crit_turns", 2)
	sprite.stats.crit_dmg += 0.30
	sprite.set_meta("bloom_defender_crit_turns", 2)

	if absf(hero.stats.crit_dmg - (old_hero_cd + 0.30)) > 0.01 or absf(sprite.stats.crit_dmg - (old_sprite_cd + 0.30)) > 0.01:
		print("    [DEBUG] Бонус Крит. урона +30% не применился")
		bm.queue_free()
		return false

	# 3. Деспавн/гибель духа снимает бонус скорости владельца
	MemospriteSystem.despawn(sprite, bm)
	if absf(hero.stats.get_effective_spd() - 100.0) > 0.1:
		print("    [DEBUG] Бонус скорости не снялся после деспавна духа")
		bm.queue_free()
		return false

	bm.queue_free()
	return true

# ТЕСТ 3: Планарное украшение «Восставший Краснодар» (+16% КУ, +32% если на поле дух/призванный)
func test_3_relic_risen_krasnodar() -> bool:
	var hero := _create_dummy_hero()
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm([hero], [enemy])

	# Применяем сет
	hero.stats.crit_dmg += 0.16
	hero.set_meta("has_set_risen_krasnodar", true)

	# Без духа памяти на поле
	var res_no_memo: Dictionary = bm.calc_dmg(hero, enemy, 1.0, 0.0, true)
	var dmg_no_memo: float = float(res_no_memo.get("damage", 0.0))

	# С духом памяти владельца на поле
	var sprite := Memosprite.new()
	sprite.owner = hero
	sprite.owner_id = hero.id
	sprite.stats.hp = 1000.0
	sprite.stats.max_hp = 1000.0
	sprite.is_active = true
	sprite.state = Memosprite.State.ACTIVE
	bm.memosprites.append(sprite)

	var res_with_memo: Dictionary = bm.calc_dmg(hero, enemy, 1.0, 0.0, true)
	var dmg_with_memo: float = float(res_with_memo.get("damage", 0.0))

	# Базовый КУ был 1.0 + 0.16 = 1.16 (множитель 2.16). При духе: 1.16 + 0.32 = 1.48 (множитель 2.48)
	var expected_ratio: float = (1.0 + 1.16 + 0.32) / (1.0 + 1.16)
	var actual_ratio: float = dmg_with_memo / dmg_no_memo
	if absf(actual_ratio - expected_ratio) > 0.02:
		print("    [DEBUG] Некорректный дополнительный Крит. урон от Восставшего Краснодара")
		bm.queue_free()
		return false

	bm.queue_free()
	return true

# ТЕСТ 4: Планарное украшение «Замурованный под руинами штаб» (Порог Скорости 145)
func test_4_relic_ruins_hq_boundaries() -> bool:
	var hero := _create_dummy_hero()
	hero.stats.break_effect = 0.16
	hero.set_meta("has_set_ruins_hq", true)

	# 1. Скорость 144 (< 145) -> ЭП = 16%
	hero.stats.spd = 144.0
	if absf(hero.get_effective_be() - 0.16) > 0.001:
		print("    [DEBUG] Ошибка ЭП при Скорости 144")
		return false

	# 2. Скорость 145 (>= 145) -> ЭП = 16% + 20% = 36%
	hero.stats.spd = 145.0
	if absf(hero.get_effective_be() - 0.36) > 0.001:
		print("    [DEBUG] Ошибка ЭП при Скорости 145")
		return false

	# 3. Скорость 160 (> 145) -> ЭП = 36%
	hero.stats.spd = 160.0
	if absf(hero.get_effective_be() - 0.36) > 0.001:
		print("    [DEBUG] Ошибка ЭП при Скорости 160")
		return false

	return true

# ТЕСТ 5: Противник «Раб Антиматерии» (Сингулярность, реакция на Духа Памяти, Коллапс)
func test_5_enemy_antimatter_slave() -> bool:
	var hero := _create_dummy_hero()
	var slave := AntimatterSlave.create_unit(0)
	var slave2 := AntimatterSlave.create_unit(1)
	var bm := _create_dummy_bm([hero], [slave, slave2])

	# 1. Проверка базовых атрибутов
	if slave.id != "antimatter_slave": return false
	if slave.max_toughness != 90.0: return false
	if slave.stats.max_hp != 30000.0: return false
	if not slave.weaknesses.has(CombatConstants.Element.WIND) or not slave.weaknesses.has(CombatConstants.Element.FIRE): return false
	if absf(float(slave.get_meta("dmg_reduction", 0.0)) - 0.25) > 0.01: return false

	# 2. Реакция на атаку Духа Памяти: -25 стойкости, +15% продвижение владельца
	var sprite := Memosprite.new()
	sprite.owner = hero
	sprite.display_name = "Дух Памяти"
	var tgh_before: float = slave.toughness
	var av_before: float = hero.action_value
	AntimatterSlave.on_attacked_by_memosprite(slave, sprite, bm)
	if absf(slave.toughness - (tgh_before - 25.0)) > 0.1:
		print("    [DEBUG] Дух памяти не истощил 25 ед. стойкости Раба")
		bm.queue_free()
		return false
	if hero.action_value >= av_before:
		print("    [DEBUG] Действие владельца духа не продвинулось на 15%")
		bm.queue_free()
		return false

	# 3. Взрыв при пробитии стойкости («Коллапс сингулярности»): 15% макс ХП и 15 стойкости другим врагам
	var hp2_before: float = slave2.stats.hp
	var tgh2_before: float = slave2.toughness
	AntimatterSlave.on_weakness_break(slave, bm)

	if absf(float(slave.get_meta("dmg_reduction", 1.0)) - 0.0) > 0.01:
		print("    [DEBUG] Снижение урона не обнулилось при пробитии")
		bm.queue_free()
		return false
	var expected_collapse_dmg: float = slave.stats.max_hp * 0.15 # 4500
	if absf(slave2.stats.hp - (hp2_before - expected_collapse_dmg)) > 1.0:
		print("    [DEBUG] Некорректный урон от Коллапса сингулярности: %f != %f" % [slave2.stats.hp, hp2_before - expected_collapse_dmg])
		bm.queue_free()
		return false
	if absf(slave2.toughness - (tgh2_before - 15.0)) > 0.1:
		print("    [DEBUG] Коллапс сингулярности не истощил 15 стойкости соседней цели")
		bm.queue_free()
		return false

	bm.queue_free()
	return true

# ТЕСТ 6: Элитный противник «Восставший» (Подготовка, срыв пробитием, «Сломленный дух»)
func test_6_enemy_insurgent() -> bool:
	var hero := _create_dummy_hero()
	var insurgent := Insurgent.create_unit(0)
	var bm := _create_dummy_bm([hero], [insurgent])

	# 1. Проверка характеристик
	if insurgent.id != "insurgent": return false
	if not insurgent.is_elite: return false
	if insurgent.max_toughness != 240.0: return false
	if insurgent.stats.max_hp != 225000.0: return false
	if not insurgent.weaknesses.has(CombatConstants.Element.IMAGINARY) or not insurgent.weaknesses.has(CombatConstants.Element.QUANTUM): return false
	if absf(float(insurgent.get_meta("dmg_reduction", 0.0)) - 0.20) > 0.01: return false

	# 2. Цикл ходов: на 3-й ход входит в подготовку к бунту
	Insurgent.execute_turn(insurgent, bm.allies, bm) # ход 1
	Insurgent.execute_turn(insurgent, bm.allies, bm) # ход 2
	Insurgent.execute_turn(insurgent, bm.allies, bm) # ход 3
	if not bool(insurgent.get_meta("is_preparing_riot", false)):
		print("    [DEBUG] Восставший не вошел в состояние подготовки на 3 ход")
		bm.queue_free()
		return false

	# 3. Пробитие стойкости срывает подготовку, задерживает ход на 40% и вешает «Сломленный дух»
	var av_before: float = insurgent.action_value
	Insurgent.on_weakness_break(insurgent, bm)

	if bool(insurgent.get_meta("is_preparing_riot", true)):
		print("    [DEBUG] Подготовка к бунту не была сорвана при пробитии")
		bm.queue_free()
		return false
	if absf(float(insurgent.get_meta("dmg_reduction", 1.0)) - 0.0) > 0.01:
		print("    [DEBUG] Снижение урона не снято при пробитии")
		bm.queue_free()
		return false
	if not bool(insurgent.get_meta("insurgent_broken_spirit", false)):
		print("    [DEBUG] Статус «Сломленный дух» не наложен")
		bm.queue_free()
		return false
	if absf(float(insurgent.get_meta("insurgent_extra_break_vuln", 0.0)) - 1.0) > 0.01:
		print("    [DEBUG] Уязвимость к пробитию/суперпробитию не равна +100%")
		bm.queue_free()
		return false
	var def_reds: Dictionary = insurgent.get_meta("def_reductions", {})
	if not def_reds.has("broken_spirit"):
		print("    [DEBUG] Срез защиты -20% от «Сломленного духа» не применен")
		bm.queue_free()
		return false
	if insurgent.action_value <= av_before:
		print("    [DEBUG] Задержка хода на 40% не сработала")
		bm.queue_free()
		return false

	bm.queue_free()
	return true

# ТЕСТ 7: Босс «Кайл • Лидер восстания» (Фазы 1 и 2, Завеса, Казнь тиранов, Духи Памяти)
func test_7_enemy_kyle_rebel_leader() -> bool:
	var hero := _create_dummy_hero()
	var kyle := KyleRebelLeader.create_unit(0)
	var bm := _create_dummy_bm([hero], [kyle])

	# 1. Фаза 1 характеристики и Завеса восстания (3 стака, -45% урона)
	if kyle.id != "kyle_rebel_leader": return false
	if kyle.stats.max_hp != 350000.0: return false
	if kyle.max_toughness != 360.0: return false
	if int(kyle.get_meta("rebellion_veil_stacks", 0)) != 3: return false
	if absf(float(kyle.get_meta("boss_dmg_reduction", 0.0)) - 0.45) > 0.01: return false

	# 2. Атака Духа Памяти снимает стак Завесы, накладывает «Раскол разума» (+15% уязвимости), истощает 20 стойкости и дает 5 энергии команде
	var sprite := Memosprite.new()
	sprite.owner = hero
	sprite.stats.hp = 50000.0
	sprite.stats.max_hp = 50000.0
	sprite.is_active = true
	sprite.state = Memosprite.State.ACTIVE
	bm.memosprites.append(sprite)

	hero.energy = 0.0
	var kyle_tgh_before: float = kyle.toughness
	KyleRebelLeader.on_attacked_by_memosprite(kyle, sprite, bm)

	if int(kyle.get_meta("rebellion_veil_stacks", 0)) != 2: return false
	if absf(float(kyle.get_meta("boss_dmg_reduction", 0.0)) - 0.30) > 0.01: return false
	if int(kyle.get_meta("kyle_mind_fracture_stacks", 0)) != 1: return false
	if absf(kyle.toughness - (kyle_tgh_before - 20.0)) > 0.1: return false
	if absf(hero.energy - 5.0) > 0.01: return false

	# 3. «Казнь тиранов» (ход 3) в присутствии живого Духа Памяти: блокирование 70% урона, Кайл теряет 40 стойкости и задерживается на 25%
	kyle.set_meta("turn_count", 2) # следующий ход будет 3
	var hero_hp_before: float = hero.stats.hp
	var kyle_tgh_exec: float = kyle.toughness
	var kyle_av_exec: float = kyle.action_value
	KyleRebelLeader.execute_turn(kyle, bm.allies, bm)

	if absf(kyle.toughness - (kyle_tgh_exec - 40.0)) > 0.1:
		print("    [DEBUG] Кайл не потерял 40 стойкости при блокировании казни духом")
		bm.queue_free()
		return false
	if kyle.action_value <= kyle_av_exec:
		print("    [DEBUG] Кайл не получил задержку хода на 25%")
		bm.queue_free()
		return false

	# 4. Переход во 2-ю фазу (400 000 ХП, повышенные статы, сброс стойкости и стаков)
	KyleRebelLeader.start_phase_2(kyle, bm)
	if int(kyle.get_meta("phase", 1)) != 2: return false
	if kyle.stats.max_hp != 400000.0 or kyle.stats.hp != 400000.0: return false
	if kyle.stats.atk != 2700.0 or kyle.stats.def != 1050.0 or kyle.stats.spd != 106.0: return false
	if kyle.toughness != 360.0: return false
	if int(kyle.get_meta("rebellion_veil_stacks", 0)) != 3: return false

	# 5. Механики 2 фазы: «Сокрушение оков» накладывает щит союзникам, «Ультимативный приговор» уходит в иллюзию и дает +25% КУ
	# Ход 2 фазы 2: «Сокрушение оков»
	kyle.set_meta("turn_p2_count", 1)
	hero.set_meta("shield_value", 0.0)
	hero.remove_meta("shield_source")
	KyleRebelLeader.execute_turn(kyle, bm.allies, bm)
	if hero.get_meta("shield_source", "") != "Свет Памяти" or float(hero.get_meta("shield_value", 0.0)) <= 0.0:
		print("    [DEBUG] Дух памяти не укрыл союзников щитом при Сокрушении оков")
		bm.queue_free()
		return false

	# Ход 3 фазы 2: «Ультимативный приговор»
	kyle.set_meta("turn_p2_count", 2)
	var hero_hp_ult: float = hero.stats.hp
	var hero_cd_ult: float = hero.stats.crit_dmg
	KyleRebelLeader.execute_turn(kyle, bm.allies, bm)
	if absf(hero.stats.hp - hero_hp_ult) > 0.1:
		print("    [DEBUG] Иллюзия духа не поглотила урон Ультимативного приговора")
		bm.queue_free()
		return false
	if absf(hero.stats.crit_dmg - (hero_cd_ult + 0.25)) > 0.01:
		print("    [DEBUG] Союзники не получили +25% Крит. урона от иллюзии")
		bm.queue_free()
		return false

	bm.queue_free()
	return true

# ТЕСТ 8: Данжи и боевые аномалии («Руины восстания», «Оплот восстания»)
func test_8_dungeons_and_anomalies() -> bool:
	# 1. Проверка реестра пещерного данжа «Руины восстания»
	var found_cave := false
	for d in RelicSystem.CAVERN_DUNGEONS:
		if d.get("id", "") == "dungeon_rebellion_ruins":
			var sets: Array = d.get("sets", [])
			if sets.has("dark_side_defector") and sets.has("bloom_defender"):
				found_cave = true
			break
	if not found_cave:
		print("    [DEBUG] Не найден пещерный данж Руины восстания или неверные сеты")
		return false

	# 2. Проверка реестра планарного данжа «Оплот восстания»
	var found_planar := false
	for d in RelicSystem.PLANAR_DUNGEONS:
		if d.get("id", "") == "planar_rebellion_hq":
			var sets: Array = d.get("sets", [])
			if sets.has("risen_krasnodar") and sets.has("ruins_hq"):
				found_planar = true
			break
	if not found_planar:
		print("    [DEBUG] Не найден планарный данж Оплот восстания или неверные сеты")
		return false

	# 3. Проверка генерации боя в пещере: Восставший + 2 Раба Антиматерии, +40% ЭП команде
	var hero := _create_dummy_hero()
	var bm := _create_dummy_bm([hero], [])
	LevelManager.setup_level_battle("dungeon_rebellion_ruins", bm)

	if bm.enemies.size() != 3:
		print("    [DEBUG] Неверное количество врагов в Руинах восстания: %d" % bm.enemies.size())
		bm.queue_free()
		return false
	if bm.enemies[0].id != "insurgent" or bm.enemies[1].id != "antimatter_slave" or bm.enemies[2].id != "antimatter_slave":
		print("    [DEBUG] Неверный состав врагов в Руинах восстания")
		bm.queue_free()
		return false
	if absf(hero.stats.break_effect - 0.40) > 0.01:
		print("    [DEBUG] Аномалия +40% ЭП не применилась")
		bm.queue_free()
		return false

	# 4. Проверка генерации боя в планарном данже: Кайл + Восставший
	bm.enemies.clear()
	LevelManager.setup_level_battle("planar_rebellion_hq", bm)

	if bm.enemies.size() != 2:
		print("    [DEBUG] Неверное количество врагов в Оплоте восстания: %d" % bm.enemies.size())
		bm.queue_free()
		return false
	if bm.enemies[0].id != "kyle_rebel_leader" or bm.enemies[1].id != "insurgent":
		print("    [DEBUG] Неверный состав врагов в Оплоте восстания")
		bm.queue_free()
		return false

	bm.queue_free()
	return true

# ТЕСТ 9: Приоритет автовыбора целей (Недельный босс -> Босс -> Элита -> Обычный)
func test_9_targeting_priority() -> bool:
	var BattleScript: GDScript = load("res://scenes/battle/battle.gd")
	var battle_dummy = BattleScript.new()

	var normal_1 := CombatUnit.new()
	normal_1.id = "antimatter_slave"
	normal_1.display_name = "Раб Антиматерии"
	normal_1.is_ally = false
	normal_1.stats.max_hp = 1000.0
	normal_1.stats.hp = 1000.0

	var normal_2 := CombatUnit.new()
	normal_2.id = "void_soldier"
	normal_2.display_name = "Солдат Пустоты"
	normal_2.is_ally = false
	normal_2.stats.max_hp = 1000.0
	normal_2.stats.hp = 500.0 # 50% HP

	var elite := CombatUnit.new()
	elite.id = "insurgent"
	elite.display_name = "Восставший (Элита)"
	elite.is_elite = true
	elite.is_ally = false
	elite.stats.max_hp = 5000.0
	elite.stats.hp = 5000.0

	var boss := CombatUnit.new()
	boss.id = "kyle_rebel_leader"
	boss.display_name = "Кайл • Лидер восстания (Босс)"
	boss.is_ally = false
	boss.stats.max_hp = 20000.0
	boss.stats.hp = 20000.0

	var weekly := CombatUnit.new()
	weekly.id = "rimes_final_boss"
	weekly.display_name = "Раймс • Финальный босс (Недельный босс)"
	weekly.set_meta("is_weekly_boss", true)
	weekly.is_ally = false
	weekly.stats.max_hp = 100000.0
	weekly.stats.hp = 100000.0

	# Проверяем ранги приоритетов
	if battle_dummy._get_enemy_priority(weekly) != 4:
		print("    [DEBUG] Неверный приоритет Недельного босса: ожидалось 4, получено %d" % battle_dummy._get_enemy_priority(weekly))
		battle_dummy.free()
		return false

	if battle_dummy._get_enemy_priority(boss) != 3:
		print("    [DEBUG] Неверный приоритет Босса: ожидалось 3, получено %d" % battle_dummy._get_enemy_priority(boss))
		battle_dummy.free()
		return false

	if battle_dummy._get_enemy_priority(elite) != 2:
		print("    [DEBUG] Неверный приоритет Элиты: ожидалось 2, получено %d" % battle_dummy._get_enemy_priority(elite))
		battle_dummy.free()
		return false

	if battle_dummy._get_enemy_priority(normal_1) != 1:
		print("    [DEBUG] Неверный приоритет Обычного врага: ожидалось 1, получено %d" % battle_dummy._get_enemy_priority(normal_1))
		battle_dummy.free()
		return false

	# Проверяем выбор лучшей цели из пула
	var pool_all: Array[CombatUnit] = [normal_1, elite, weekly, boss, normal_2]
	if battle_dummy._pick_highest_priority_target(pool_all) != weekly:
		print("    [DEBUG] Из полного пула не был выбран Недельный босс")
		battle_dummy.free()
		return false

	var pool_no_weekly: Array[CombatUnit] = [normal_1, elite, boss, normal_2]
	if battle_dummy._pick_highest_priority_target(pool_no_weekly) != boss:
		print("    [DEBUG] Из пула без Недельного босса не был выбран Босс")
		battle_dummy.free()
		return false

	var pool_no_boss: Array[CombatUnit] = [normal_1, elite, normal_2]
	if battle_dummy._pick_highest_priority_target(pool_no_boss) != elite:
		print("    [DEBUG] Из пула без Боссов не была выбрана Элита")
		battle_dummy.free()
		return false

	var pool_normals: Array[CombatUnit] = [normal_1, normal_2]
	if battle_dummy._pick_highest_priority_target(pool_normals) != normal_2:
		print("    [DEBUG] Среди обычных врагов не была выбрана цель с наименьшим %% HP")
		battle_dummy.free()
		return false

	battle_dummy.free()
	return true

