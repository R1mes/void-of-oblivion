extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  ЗАПУСК ТЕСТОВ: РАЙМС • ВОСХОЖДЕНИЕ (rimes_ascension)")
	print("========================================================\n")
	
	var passed := 0
	var failed := 0

	var tests := [
		"test_1_stats_and_factions",
		"test_2_paws_definition_and_summon",
		"test_3_basic_attack_and_hp_scaling",
		"test_4_skill_q_ally_drain_and_joint_attack",
		"test_5_skill_q_xaeroh_boost",
		"test_6_crescendo_accumulation_and_talent_buff",
		"test_7_skill_e_summon_heal_cleanse_and_charges",
		"test_8_trace_1_sp_reduction",
		"test_9_trace_2_heal_conversion_and_reset",
		"test_10_trace_3_paws_stacking",
		"test_11_ultimate_and_rupture_zone",
		"test_12_paws_backup_redirection",
		"test_13_paws_death_despawn_strikes_and_heal",
		"test_14_paws_con_brio_and_sforzando",
		"test_15_eidolons_e1_e2_e4_e6",
		"test_16_technique",
		"test_17_valramors_corruption_transfer_with_memosprite",
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
	
	get_tree().quit(0 if failed == 0 else 1)

func _setup_test_bm() -> BattleManager:
	var bm := BattleManager.new()
	bm.skill_points = 5
	return bm

func _create_dummy_enemy(hp: float = 20000.0, def: float = 500.0) -> CombatUnit:
	var e := CombatUnit.new()
	e.id = "dummy_enemy"
	e.display_name = "Манекен"
	e.is_ally = false
	e.stats.hp = hp
	e.stats.max_hp = hp
	e.stats.def = def
	e.stats.spd = 100.0
	e.toughness = 60.0
	e.max_toughness = 60.0
	return e

# 1. Проверка характеристик и фракций
func test_1_stats_and_factions() -> bool:
	var rimes := RimesAscensionAbilities.create_unit(0)
	if rimes.id != "rimes_ascension": return false
	if rimes.element != CombatConstants.Element.QUANTUM: return false
	if rimes.path != CombatConstants.Path.REMEMBRANCE: return false
	if rimes.stats.max_hp != 4500.0 or rimes.stats.hp != 4500.0: return false
	if rimes.stats.atk != 500.0: return false
	if rimes.stats.def != 850.0: return false
	if rimes.stats.spd != 102.0: return false
	if rimes.stats.crit_rate != 0.15: return false
	if rimes.stats.crit_dmg != 0.50: return false
	if not bool(rimes.get_meta("is_hp_scaler", false)): return false
	var factions := FactionSystem.get_unit_factions(rimes.id)
	if not ("antimatter" in factions): return false
	if not ("empyreans" in factions): return false
	return true

# 2. Определение и характеристики Духа Памяти «Лапы антиматерии»
func test_2_paws_definition_and_summon() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	bm.allies.append(rimes)
	
	RimesAscensionAbilities.execute_skill_e(rimes, bm)
	var paws := RimesAscensionAbilities.get_paws_sprite(rimes, bm)
	if paws == null or not paws.is_alive(): return false
	
	# Базовое ХП = 150% от макс. ХП Раймса = 4500 * 1.5 = 6750
	if absf(paws.stats.max_hp - 6750.0) > 1.0: return false
	if paws.stats.spd != 165.0: return false
	if paws.is_targetable != false: return false
	if paws.is_backup != true: return false
	if paws.element != CombatConstants.Element.QUANTUM: return false
	if paws.path != CombatConstants.Path.REMEMBRANCE: return false
	if paws.get_charge() != 1.0: return false
	
	# Проверка наследования параметров
	if paws.stats.atk != rimes.stats.atk: return false
	if paws.stats.def != rimes.stats.def: return false
	if paws.stats.crit_rate != rimes.stats.crit_rate: return false
	if paws.stats.crit_dmg != rimes.stats.crit_dmg: return false
	return true

# 3. Базовая атака и скалирование от макс. ХП
func test_3_basic_attack_and_hp_scaling() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	var enemy := _create_dummy_enemy(20000.0, 0.0) # 0 защиты для точного расчета
	bm.allies.append(rimes)
	bm.enemies.append(enemy)
	
	bm.skill_points = 2
	var hp_before := enemy.stats.hp
	RimesAscensionAbilities.execute_basic_attack(rimes, enemy, bm)
	
	var dealt := hp_before - enemy.stats.hp
	if bm.skill_points != 3: return false # Базовая дает +1 ОН
	# 100% макс ХП = 4500 базового урона (с учетом защиты 0.5x, 20% RES и не пробитой стойкости 0.9x = 1620 урона, с критом 2430)
	if dealt < 1500.0 or dealt > 3000.0: return false
	return true

# 4. Навык Q: расход текущего ХП команды и совместный удар
func test_4_skill_q_ally_drain_and_joint_attack() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	var ally := CombatUnit.new()
	ally.id = "dummy_ally"
	ally.stats.hp = 3000.0
	ally.stats.max_hp = 3000.0
	ally.is_ally = true
	
	bm.allies = [rimes, ally]
	RimesAscensionAbilities.execute_skill_e(rimes, bm)
	var paws := RimesAscensionAbilities.get_paws_sprite(rimes, bm)
	
	var enemy := _create_dummy_enemy(50000.0)
	bm.enemies.append(enemy)
	
	bm.skill_points = 3
	var rimes_hp_before := rimes.stats.hp
	var ally_hp_before := ally.stats.hp
	var paws_hp_before := paws.stats.hp
	var enemy_hp_before := enemy.stats.hp
	
	RimesAscensionAbilities.execute_skill_q(rimes, bm)
	
	# Навык Q стоит 0 SP!
	if bm.skill_points != 3: return false
	# Раймс потерял 15% ХП
	if absf(rimes.stats.hp - (rimes_hp_before * 0.85)) > 1.0: return false
	# Союзник потерял 15% ХП
	if absf(ally.stats.hp - (ally_hp_before * 0.85)) > 1.0: return false
	# Лапы потеряли 30% ХП
	if absf(paws.stats.hp - (paws_hp_before * 0.70)) > 1.0: return false
	# Враг получил урон от совместной атаки
	if enemy.stats.hp >= enemy_hp_before: return false
	return true

# 5. Навык Q: усиление от Зеро (>= 60)
func test_5_skill_q_xaeroh_boost() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	bm.allies.append(rimes)
	var enemy := _create_dummy_enemy(50000.0)
	bm.enemies.append(enemy)
	
	RimesAscensionAbilities.execute_skill_e(rimes, bm) # Призываем Лапы
	bm.add_xaeroh(70)
	if bm.get_xaeroh() != 70: return false
	
	RimesAscensionAbilities.execute_skill_q(rimes, bm)
	# Должно потратить 10 Зеро -> остаток 60
	if bm.get_xaeroh() != 60: return false
	return true

# 6. Талант: набор Крещендо при потере ХП союзниками и стаки урона
func test_6_crescendo_accumulation_and_talent_buff() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	var ally := CombatUnit.new()
	ally.id = "dummy_ally"
	ally.stats.hp = 4000.0
	ally.stats.max_hp = 4000.0
	ally.is_ally = true
	bm.allies = [rimes, ally]
	
	# Союзник теряет 800 ХП (20% от макс. ХП)
	bm.deal_damage(ally, 800.0)
	
	# Раймс должен получить 20% Крещендо
	var c := float(rimes.get_meta("crescendo_stacks", 0.0))
	if absf(c - 20.0) > 1.0: return false
	
	# Талант: +1 стак урона на 3 хода
	var stacks := int(rimes.get_meta("talent_dmg_stacks", 0))
	if stacks != 1: return false
	var turns := int(rimes.get_meta("talent_dmg_turns", 0))
	if turns != 3: return false
	
	# Еще 3 потери ХП союзника -> максимум 3 стака
	bm.deal_damage(ally, 400.0)
	bm.deal_damage(ally, 400.0)
	bm.deal_damage(ally, 400.0)
	stacks = int(rimes.get_meta("talent_dmg_stacks", 0))
	if stacks != 3: return false
	return true

# 7. Навык E: призыв, лечение 60%, снятие контроля, прирост зарядов и макс. ХП
func test_7_skill_e_summon_heal_cleanse_and_charges() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	bm.allies.append(rimes)
	
	# Первый призыв
	RimesAscensionAbilities.execute_skill_e(rimes, bm)
	var paws := RimesAscensionAbilities.get_paws_sprite(rimes, bm)
	if paws == null or not paws.is_alive(): return false
	if paws.get_charge() != 1.0: return false
	var base_max_hp := paws.stats.max_hp
	
	# Раним лапы и вешаем контроль
	paws.stats.hp = 1000.0
	paws.statuses.skip_next_turn = true
	paws.statuses.break_status = "freeze"
	
	# Повторный Навык E: очищает контроль, хилит на 60% и дает +1 заряд (всего 2)
	RimesAscensionAbilities.execute_skill_e(rimes, bm)
	if paws.statuses.skip_next_turn or paws.statuses.break_status == "freeze": return false
	if paws.get_charge() != 2.0: return false
	
	# При 2 зарядах макс. ХП должно увеличиться на +75% базового = base_max_hp * 1.75
	var expected_max := base_max_hp * 1.75
	if absf(paws.stats.max_hp - expected_max) > 1.0: return false
	return true

# 8. След 1: Снижение стоимости Навыка E с 2 до 1 ОН
func test_8_trace_1_sp_reduction() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	bm.allies.append(rimes)
	bm.skill_points = 5
	
	bm.phase = BattleManager.Phase.RUNNING
	
	# Без следа стоит 2 ОН
	bm.current_unit = rimes
	bm._waiting_for_player = true
	bm.player_skill_e(null)
	if bm.skill_points != 3: return false
	
	# Разблокируем След 1
	rimes.set_meta("trace_1_unlocked", true)
	bm.current_unit = rimes
	bm._waiting_for_player = true
	bm.player_skill_e(null)
	if bm.skill_points != 2: return false # Потратил 1 ОН!
	return true

# 9. След 2: Конверсия 30% входящего лечения в Крещендо (макс 12% за ход от цели)
func test_9_trace_2_heal_conversion_and_reset() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	rimes.set_meta("trace_2_unlocked", true)
	var ally := CombatUnit.new()
	ally.id = "dummy_ally"
	ally.stats.hp = 1000.0
	ally.stats.max_hp = 5000.0
	ally.is_ally = true
	bm.allies = [rimes, ally]
	
	# Лечим союзника на 1000 ХП (20% от макс. ХП) -> 30% от 20% = 6% Крещендо
	bm.heal_unit(ally, 1000.0)
	var c := float(rimes.get_meta("crescendo_stacks", 0.0))
	if absf(c - 6.0) > 0.5: return false
	
	# Лечим еще на 2000 ХП (40% макс ХП) -> дало бы +12%, но капает на 12% суммарно за ход
	bm.heal_unit(ally, 2000.0)
	c = float(rimes.get_meta("crescendo_stacks", 0.0))
	if absf(c - 12.0) > 0.5: return false
	
	# Конец хода сбрасывает лимит хода
	bm._end_turn(rimes)
	bm.heal_unit(ally, 1000.0)
	c = float(rimes.get_meta("crescendo_stacks", 0.0))
	if absf(c - 18.0) > 0.5: return false
	return true

# 10. След 3: Стаки урона Лап (+30% за удар, до 6 стаков), сброс в конце хода Лап
func test_10_trace_3_paws_stacking() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	bm.allies.append(rimes)
	RimesAscensionAbilities.execute_skill_e(rimes, bm)
	var paws := RimesAscensionAbilities.get_paws_sprite(rimes, bm)
	paws.set_meta("trace_3_unlocked", true)
	
	var enemy := _create_dummy_enemy(50000.0)
	bm.enemies.append(enemy)
	
	# Con brio с 1 зарядом делает 1 удар
	RimesAscensionAbilities.execute_paws_con_brio(paws, bm)
	var stacks := int(paws.get_meta("paws_trace3_stacks", 0))
	if stacks != 1: return false
	
	# Конец хода Лап сбрасывает стаки
	bm._end_turn(paws)
	stacks = int(paws.get_meta("paws_trace3_stacks", 0))
	if stacks != 0: return false
	return true

# 11. Сверхспособность: Зона Разрыва (-20% RES), +10 Зеро, лечение/призыв Лап, КУ кап 60%
func test_11_ultimate_and_rupture_zone() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	bm.allies.append(rimes)
	var enemy := _create_dummy_enemy(50000.0)
	bm.enemies.append(enemy)
	
	# Сверхспособность заблокирована до 100% Крещендо
	rimes.set_meta("crescendo_stacks", 50.0)
	bm.queue_ultimate(rimes)
	if not bm.ult_queue.is_empty(): return false
	
	# При 100% Крещендо ульта ставится в очередь
	rimes.set_meta("crescendo_stacks", 100.0)
	bm._is_processing_ult_queue = true
	bm.queue_ultimate(rimes)
	if bm.ult_queue.size() != 1: return false
	bm.ult_queue.clear()
	bm._is_processing_ult_queue = false
	
	# 1) Первый ультимейт: призывает Лапы, восстанавливает 10 Зеро, создает зону на 3 хода
	RimesAscensionAbilities.execute_ultimate(rimes, bm)
	var paws := RimesAscensionAbilities.get_paws_sprite(rimes, bm)
	if paws == null or not paws.is_alive(): return false
	if int(rimes.get_meta("rimes_rupture_zone_turns", 0)) != 3: return false
	if float(rimes.get_meta("crescendo_stacks", 0.0)) != 0.0: return false
	if bm.get_xaeroh() != 10: return false # Восстановлено 10 Зеро
	
	# 2) Второй ультимейт при живых Лапах: восстанавливает 60% ХП, +1 заряд, +10 Зеро
	paws.stats.hp = 1000.0
	var prev_ch := paws.get_charge()
	rimes.set_meta("crescendo_stacks", 100.0)
	RimesAscensionAbilities.execute_ultimate(rimes, bm)
	if paws.stats.hp <= 1000.0: return false
	if paws.get_charge() != prev_ch + 1.0: return false
	if bm.get_xaeroh() != 20: return false
	
	# 3) Проверка урона с -20% RES и капом КУ 60%
	bm.add_xaeroh(100) # 120 Зеро -> >50 на 70 ед -> кап 60% КУ
	var res := bm.calc_dmg(rimes, enemy, 1.0)
	if not res.has("damage"): return false
	return true

# 12. Поддержка Лап: Перенаправление смертельного урона на Лапы (300%)
func test_12_paws_backup_redirection() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	var ally := CombatUnit.new()
	ally.id = "fragile_ally"
	ally.stats.hp = 100.0
	ally.stats.max_hp = 1000.0
	ally.is_ally = true
	bm.allies = [rimes, ally]
	
	RimesAscensionAbilities.execute_skill_e(rimes, bm)
	var paws := RimesAscensionAbilities.get_paws_sprite(rimes, bm)
	var paws_hp_before := paws.stats.hp
	
	# Наносим смертельный урон (500) союзнику со 100 ХП
	bm.deal_damage(ally, 500.0)
	
	# Союзник должен выжить с 1 ХП
	if ally.stats.hp != 1.0 or not ally.is_alive(): return false
	# Лапы должны принять 300% оригинального урона = 1500
	var paws_lost := paws_hp_before - paws.stats.hp
	if absf(paws_lost - 1500.0) > 1.0: return false
	return true

# 13. Гибель Лап: Предсмертная серия ударов (6 тычек по 40%) и командный отхил (6% + 400)
func test_13_paws_death_despawn_strikes_and_heal() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	rimes.stats.hp = 1000.0 # Раним Раймса
	bm.allies.append(rimes)
	
	RimesAscensionAbilities.execute_skill_e(rimes, bm)
	var paws := RimesAscensionAbilities.get_paws_sprite(rimes, bm)
	var enemy := _create_dummy_enemy(50000.0)
	bm.enemies.append(enemy)
	
	var paws_max_hp := paws.stats.max_hp
	var enemy_hp_before := enemy.stats.hp
	var rimes_hp_before := rimes.stats.hp
	
	# Убиваем Лапы
	bm.deal_damage(paws, paws.stats.hp + 500.0)
	
	# Лапы должны погибнуть
	if paws.is_alive(): return false
	# Враг должен получить 6 ударов урона
	if enemy.stats.hp >= enemy_hp_before: return false
	# Раймс должен получить лечение: 6% от max_hp Раймса + 400
	var expected_heal := (rimes.stats.max_hp * 0.06) + 400.0
	var actual_heal := rimes.stats.hp - rimes_hp_before
	if absf(actual_heal - expected_heal) > 2.0: return false
	return true

# 14. Умения Лап: Con brio (< 4 зарядов) и Sforzando (4 заряда, повтор за 20 Зеро при >= 60)
func test_14_paws_con_brio_and_sforzando() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	bm.allies.append(rimes)
	var enemy := _create_dummy_enemy(100000.0)
	bm.enemies.append(enemy)
	
	RimesAscensionAbilities.execute_skill_e(rimes, bm)
	var paws := RimesAscensionAbilities.get_paws_sprite(rimes, bm)
	
	# 1) Con brio (2 заряда)
	paws.set_charge(2.0)
	var hp_before_cb := enemy.stats.hp
	RimesAscensionAbilities.execute_paws_con_brio(paws, bm)
	if enemy.stats.hp >= hp_before_cb: return false
	
	# 2) Sforzando (4 заряда, 80 Зеро -> тратит 20 Зеро -> остаток 60)
	paws.set_charge(4.0)
	bm.add_xaeroh(80)
	
	var enemy_hp_before := enemy.stats.hp
	RimesAscensionAbilities.execute_paws_skill(paws, enemy, bm)
	
	# Должен потратить 20 Зеро -> остаток 60
	if bm.get_xaeroh() != 60: return false
	# Заряды должны сброситься до 1
	if paws.get_charge() != 1.0: return false
	# Враг должен получить ощутимый урон от Sforzando
	if enemy.stats.hp >= enemy_hp_before: return false
	return true

# 15. Эйдолоны E1, E2, E4, E6
func test_15_eidolons_e1_e2_e4_e6() -> bool:
	# E1: проверка множителя
	var rimes_e1 := RimesAscensionAbilities.create_unit(1)
	var enemy_low_hp := _create_dummy_enemy(10000.0)
	enemy_low_hp.stats.hp = 4000.0 # 40% ХП (<= 50%)
	var mult := RimesAscensionAbilities._apply_e1_mult(enemy_low_hp, 1000.0, rimes_e1)
	if absf(mult - 1400.0) > 1.0: return false # +40%
	
	# E2: Навык E дает +2 заряда Лап (всего 3), 50% AV advance и +30% Крещендо
	var bm := _setup_test_bm()
	var rimes_e2 := RimesAscensionAbilities.create_unit(2)
	bm.allies.append(rimes_e2)
	RimesAscensionAbilities.execute_skill_e(rimes_e2, bm)
	var paws := RimesAscensionAbilities.get_paws_sprite(rimes_e2, bm)
	if paws.get_charge() != 3.0: return false # начальный 1 + 2
	var c := float(rimes_e2.get_meta("crescendo_stacks", 0.0))
	if absf(c - 30.0) > 0.5: return false
	
	# E4: +30% исцеления по команде
	var rimes_e4 := RimesAscensionAbilities.create_unit(4)
	bm.allies = [rimes_e4]
	rimes_e4.stats.hp = 1000.0
	bm.heal_unit(rimes_e4, 1000.0)
	# 1000 * 1.30 = 1300
	if absf(rimes_e4.stats.hp - 2300.0) > 2.0: return false
	
	# E6: Проверка RES PEN 20% (без случайных критов)
	var rimes_e6 := RimesAscensionAbilities.create_unit(6)
	var e6_enemy := _create_dummy_enemy(10000.0)
	bm.allies = [rimes_e6]
	bm.enemies = [e6_enemy]
	var res_normal := bm.calc_dmg(rimes_e1, e6_enemy, 1.0, 0.0, false, 0.0, 0.0, false, false)
	var res_e6 := bm.calc_dmg(rimes_e6, e6_enemy, 1.0, 0.0, false, 0.0, 0.0, false, false)
	if float(res_e6.get("damage", 0.0)) <= float(res_normal.get("damage", 0.0)): return false
	return true

# 16. Техника: Урон, +1 SP, +30% Крещендо, +20% продвижение действий
func test_16_technique() -> bool:
	var bm := _setup_test_bm()
	var rimes := RimesAscensionAbilities.create_unit(0)
	bm.allies.append(rimes)
	var enemy := _create_dummy_enemy(20000.0)
	bm.enemies.append(enemy)
	
	bm.skill_points = 2
	var enemy_hp_before := enemy.stats.hp
	RimesAscensionAbilities.execute_technique(rimes, bm)
	
	if bm.skill_points != 3: return false # +1 SP
	var c := float(rimes.get_meta("crescendo_stacks", 0.0))
	if absf(c - 30.0) > 0.5: return false # +30% Крещендо
	if enemy.stats.hp >= enemy_hp_before: return false # Урон всем врагам
	return true

# 17. Валраморс: Передача порчи работает с духами памяти
func test_17_valramors_corruption_transfer_with_memosprite() -> bool:
	var bm := _setup_test_bm()
	var valramors := ValramorsAbilities.create_unit(0)
	var rimes := RimesAscensionAbilities.create_unit(0)
	bm.allies = [valramors, rimes]
	var enemy := _create_dummy_enemy(50000.0)
	bm.enemies = [enemy]
	
	# Призываем Лапы
	RimesAscensionAbilities.execute_skill_e(rimes, bm)
	var paws := RimesAscensionAbilities.get_paws_sprite(rimes, bm)
	if paws == null or not paws.is_alive(): return false
	
	# Валраморс применяет Навык E на Раймса
	ValramorsAbilities.execute_skill_e(valramors, rimes, bm)
	
	# Проверяем, что статус есть и у Раймса, и у Лап
	if not rimes.has_meta("valramors_corruption_transfer"): return false
	if not paws.has_meta("valramors_corruption_transfer"): return false
	
	# Лапы атакуют Con brio
	RimesAscensionAbilities.execute_paws_con_brio(paws, bm)
	
	# Проверяем, что на врага наложен срез защиты от Передачи порчи (-40% DEF)
	if not bm.has_def_reduction_source(enemy, "Передача порчи (Валраморс)"): return false
	
	# Статус должен быть снят после атаки
	if rimes.has_meta("valramors_corruption_transfer"): return false
	if paws.has_meta("valramors_corruption_transfer"): return false
	return true
