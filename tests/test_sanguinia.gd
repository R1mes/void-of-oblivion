extends Node

const SanguiniaAbilities = preload("res://scripts/characters/sanguinia.gd")

func _ready() -> void:
	print("\n========================================================")
	print("  ЗАПУСК ТЕСТОВ: САНГИНИЯ ЯЛ (sanguinia)")
	print("========================================================\n")
	
	var passed := 0
	var failed := 0

	var tests := [
		"test_1_sanguinia_stats_and_creation",
		"test_2_basic_attack",
		"test_3_skill_q_advance_and_atk_buff",
		"test_4_skill_e_special_guest_application",
		"test_5_special_guest_charge_reduction_and_fua",
		"test_6_ultimate_summons_creation",
		"test_7_prep_turn_execution",
		"test_8_settlement_turn_execution",
		"test_9_talent_waves_stacking_sync_with_lenskaya",
		"test_10_talent_47_stacks_threshold_and_reset",
		"test_11_eidolons_e1_e2_e4_e6",
		"test_12_technique",
		"test_13_battle_info_provider_descriptions",
		"test_14_dot_does_not_reduce_special_guest",
		"test_15_all_sanguinia_buffs_increase_damage",
		"test_16_special_guest_fua_vulnerability",
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

func _create_dummy_enemy(hp: float = 50000.0, toughness: float = 60.0) -> CombatUnit:
	var enemy := CombatUnit.new()
	enemy.id = "dummy_enemy"
	enemy.display_name = "Манекен"
	enemy.is_ally = false
	enemy.stats.hp = hp
	enemy.stats.max_hp = hp
	enemy.stats.atk = 500.0
	enemy.stats.def = 200.0
	enemy.stats.spd = 100.0
	enemy.max_toughness = toughness
	enemy.toughness = toughness
	enemy.weaknesses = [CombatConstants.Element.FIRE, CombatConstants.Element.ICE]
	return enemy

# 1. Проверка создания и базовых параметров
func test_1_sanguinia_stats_and_creation() -> bool:
	var unit := SanguiniaAbilities.create_unit(0)
	if unit.id != "sanguinia": return false
	if unit.display_name != "Сангиния Ял": return false
	if unit.element != CombatConstants.Element.FIRE: return false
	if unit.path != CombatConstants.Path.HARMONY: return false
	if unit.max_energy != 150.0: return false
	if unit.stats.hp != 3200.0: return false
	if unit.stats.atk != 1500.0: return false
	if unit.stats.spd != 104.0: return false
	
	# Фракция Обречённые
	if not FactionSystem.FACTIONS["doomed"].members.has("sanguinia"): return false
	
	# Реестр персонажей
	var reg := CharacterRegistry.get_character("sanguinia")
	if reg.is_empty(): return false
	if reg.name != "Сангиния Ял": return false
	if reg.rarity != 5: return false
	return true

# 2. Базовая атака: 100% СА Огонь, +1 SP, +20 ЭН, снятие стойкости
func test_2_basic_attack() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var enemy := _create_dummy_enemy()
	bm.allies = [sanguinia]
	bm.enemies = [enemy]
	bm.skill_points = 2
	sanguinia.energy = 0.0

	var hp_before := enemy.stats.hp
	var tgh_before := enemy.toughness
	SanguiniaAbilities.execute_basic_attack(sanguinia, enemy, bm)

	if enemy.stats.hp >= hp_before: return false
	if enemy.toughness >= tgh_before: return false
	if bm.skill_points != 3: return false
	if sanguinia.energy != 20.0: return false
	return true

# 3. Навык Q: продвижение на 100%, +40% СА на 3 хода, 30 ЭН
func test_3_skill_q_advance_and_atk_buff() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var ally := LenskayaAbilities.create_unit(0)
	bm.allies = [sanguinia, ally]
	sanguinia.energy = 0.0
	ally.action_value = 50.0

	var base_atk := bm.get_effective_atk_complete(ally)
	SanguiniaAbilities.execute_skill_q(sanguinia, ally, bm)

	if ally.action_value != 0.0: return false
	if not ally.has_meta("sanguinia_q_atk_turns"): return false
	if int(ally.get_meta("sanguinia_q_atk_turns", 0)) != 3: return false
	var buffed_atk := bm.get_effective_atk_complete(ally)
	if buffed_atk <= base_atk: return false
	if sanguinia.energy != 30.0: return false
	return true

# 4. Навык E: Особый гость (12 зарядов), 30 ЭН
func test_4_skill_e_special_guest_application() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var enemy1 := _create_dummy_enemy()
	var enemy2 := _create_dummy_enemy()
	bm.allies = [sanguinia]
	bm.enemies = [enemy1, enemy2]
	sanguinia.energy = 0.0

	SanguiniaAbilities.execute_skill_e(sanguinia, enemy1, bm)
	if not enemy1.has_meta("sanguinia_special_guest_charges"): return false
	if int(enemy1.get_meta("sanguinia_special_guest_charges", 0)) != 12: return false
	if not enemy1.statuses.debuffs.has("sanguinia_special_guest"): return false
	if sanguinia.energy != 30.0: return false

	# Переналожение на другого врага снимает с первого
	SanguiniaAbilities.execute_skill_e(sanguinia, enemy2, bm)
	if enemy1.has_meta("sanguinia_special_guest_charges"): return false
	if enemy1.statuses.debuffs.has("sanguinia_special_guest"): return false
	if int(enemy2.get_meta("sanguinia_special_guest_charges", 0)) != 12: return false
	if not enemy2.statuses.debuffs.has("sanguinia_special_guest"): return false
	return true

# 5. Снятие зарядов Особого гостя и бонус-атаки на 9/6/3/0, +1 SP на 0
func test_5_special_guest_charge_reduction_and_fua() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var ally := LenskayaAbilities.create_unit(0)
	var enemy := _create_dummy_enemy()
	bm.allies = [sanguinia, ally]
	bm.enemies = [enemy]
	bm.skill_points = 2
	
	SanguiniaAbilities.execute_skill_e(sanguinia, enemy, bm)
	
	# Имитируем 3 атаки союзника -> заряды 11, 10, 9 (на 9 триггерится FUA)
	SanguiniaAbilities.on_ally_attack_action_performed(ally, bm) # 11
	if int(enemy.get_meta("sanguinia_special_guest_charges")) != 11: return false
	
	SanguiniaAbilities.on_ally_attack_action_performed(ally, bm) # 10
	if int(enemy.get_meta("sanguinia_special_guest_charges")) != 10: return false

	var hp_before := enemy.stats.hp
	SanguiniaAbilities.on_ally_attack_action_performed(ally, bm) # 9 -> триггер FUA!
	if int(enemy.get_meta("sanguinia_special_guest_charges")) != 9: return false
	if enemy.stats.hp >= hp_before: return false # Урон от FUA получен!

	# Доводим до 0 зарядов
	for i in range(8): # 8..1
		SanguiniaAbilities.on_ally_attack_action_performed(ally, bm)
		
	if int(enemy.get_meta("sanguinia_special_guest_charges")) != 1: return false
	
	# Финальный удар -> 0 зарядов: FUA, снятие статуса, +1 SP
	var sp_before := bm.skill_points
	SanguiniaAbilities.on_ally_attack_action_performed(ally, bm)
	if enemy.has_meta("sanguinia_special_guest_charges"): return false
	if bm.skill_points != sp_before + 1: return false
	return true

# 6. Ультимейт: призыв «Готовьтесь...» (AV 19) и 3x «Заселение!» (AV 20)
func test_6_ultimate_summons_creation() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	bm.allies = [sanguinia]
	bm.sanguinia_summons.clear()

	SanguiniaAbilities.execute_ultimate(sanguinia, bm)
	if bm.sanguinia_summons.size() != 4: return false
	
	var prep_count := 0
	var pop_count := 0
	for s in bm.sanguinia_summons:
		if s.id == "sanguinia_prep":
			prep_count += 1
			if s.action_value != 19.0: return false
		elif s.id == "sanguinia_settlement":
			pop_count += 1
			if s.action_value != 20.0: return false

	if prep_count != 1: return false
	if pop_count != 3: return false
	
	# Сущности видны в get_all_units()
	var all_units := bm.get_all_units()
	if all_units.size() < 5: return false
	return true

# 7. Ход «Готовьтесь...»: 100% advance, +40 energy, +60% ATK, След 2 (игнор 20% DEF)
func test_7_prep_turn_execution() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var lenskaya := LenskayaAbilities.create_unit(0) # СА 2000 > СА 1500 Сангинии
	bm.allies = [sanguinia, lenskaya]
	
	SanguiniaAbilities.execute_ultimate(sanguinia, bm)
	var prep: CombatUnit = null
	for s in bm.sanguinia_summons:
		if s.id == "sanguinia_prep":
			prep = s
			break
	if prep == null: return false
	
	lenskaya.action_value = 80.0
	lenskaya.energy = 0.0
	
	SanguiniaAbilities.execute_prep_turn(prep, bm)
	
	if lenskaya.action_value != 0.0: return false
	if lenskaya.energy != 40.0: return false
	if not lenskaya.has_meta("sanguinia_prep_atk_turns"): return false
	if not lenskaya.has_meta("sanguinia_prep_ignore_def_attack"): return false
	return true

# 8. Ход «Заселение!»: урон по всем, бонус-атака, След 1 (+7 энергии Сангинии)
func test_8_settlement_turn_execution() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var e1 := _create_dummy_enemy()
	var e2 := _create_dummy_enemy()
	bm.allies = [sanguinia]
	bm.enemies = [e1, e2]
	
	SanguiniaAbilities.execute_ultimate(sanguinia, bm)
	sanguinia.energy = 10.0
	var pop: CombatUnit = null
	for s in bm.sanguinia_summons:
		if s.id == "sanguinia_settlement":
			pop = s
			break
	if pop == null: return false
	
	var hp1 := e1.stats.hp
	var hp2 := e2.stats.hp
	SanguiniaAbilities.execute_settlement_turn(pop, bm)
	
	if e1.stats.hp >= hp1: return false
	if e2.stats.hp >= hp2: return false
	# След 1: +7 энергии Сангинии
	if sanguinia.energy != 17.0: return false
	return true

# 9. Талант: стаки Журчания волн синхронны с Манипуляцией Ленской
func test_9_talent_waves_stacking_sync_with_lenskaya() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var lenskaya := LenskayaAbilities.create_unit(0)
	var enemy := _create_dummy_enemy()
	bm.allies = [sanguinia, lenskaya]
	bm.enemies = [enemy]
	
	# При бонус-атаке союзника обе получают по 2 стака
	SanguiniaAbilities.add_waves_stacks(2, bm)
	LenskayaAbilities.add_manipulation_stack(lenskaya, 2, bm)
	
	var s_waves := int(sanguinia.get_meta("sanguinia_waves", 0))
	var l_man := int(lenskaya.get_meta("lenskaya_manipulation", 0))
	if s_waves != 2 or l_man != 2: return false
	
	# Ульта сильнейшего союзника (Ленская) дает еще по 2 стака обеим
	SanguiniaAbilities.add_waves_stacks(2, bm)
	LenskayaAbilities.add_manipulation_stack(lenskaya, 2, bm)
	
	s_waves = int(sanguinia.get_meta("sanguinia_waves", 0))
	l_man = int(lenskaya.get_meta("lenskaya_manipulation", 0))
	if s_waves != 4 or l_man != 4: return false

	# Трата стаков: когда Ленская использует Навык E, стаки Манипуляции И Журчания волн синхронно сбрасываются до 0
	LenskayaAbilities.execute_skill_e(lenskaya, enemy, bm)
	s_waves = int(sanguinia.get_meta("sanguinia_waves", 0))
	l_man = int(lenskaya.get_meta("lenskaya_manipulation", 0))
	if s_waves != 0 or l_man != 0: return false

	return true

# 10. Талант при 47 стаках: продвижение сильнейшего на 100%, +100% урона, принудительный Навык E без траты ОН, сброс до 0, След 3 (+1 SP)
func test_10_talent_47_stacks_threshold_and_reset() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var lenskaya := LenskayaAbilities.create_unit(0)
	var enemy := _create_dummy_enemy()
	bm.allies = [sanguinia, lenskaya]
	bm.enemies = [enemy]
	bm.skill_points = 2
	lenskaya.action_value = 60.0
	
	# Случай 1: Набор 47 стаков вне хода Ленской
	# Моментальный advance_action (100%), принудительное применение Навыка E по врагу с наивысшим ХП без траты ОН
	SanguiniaAbilities.add_waves_stacks(47, bm)
	if lenskaya.action_value != 0.0: return false
	# После успешного применения Навыка E стаки обеих сбрасываются до 0
	if int(sanguinia.get_meta("sanguinia_waves", 0)) != 0: return false
	if int(lenskaya.get_meta("lenskaya_manipulation", 0)) != 0: return false
	if lenskaya.has_meta("sanguinia_talent_dmg_boost"): return false
	# ОН не должны были потратиться на Навык E, а След 3 дает +1 ОН при сбросе (2 + 1 = 3)
	if bm.skill_points != 3: return false

	# Случай 2: Набор 47 стаков, когда сильнейший союзник заморожен (skip_next_turn)
	# Принудительный Навык E откладывается, стаки НЕ сбрасываются!
	lenskaya.statuses.skip_next_turn = true
	lenskaya.action_value = 50.0
	SanguiniaAbilities.add_waves_stacks(47, bm)
	if int(sanguinia.get_meta("sanguinia_waves", 0)) != 47: return false
	if not sanguinia.has_meta("sanguinia_pending_forced_skill_unit"): return false
	# Стаки не сбросились, так как Ленская не смогла применить Навык E
	if int(lenskaya.get_meta("lenskaya_manipulation", 0)) != 47: return false
	# ОН не изменились
	if bm.skill_points != 3: return false

	# Теперь Ленская размораживается (получает возможность действовать)
	lenskaya.statuses.skip_next_turn = false
	bm.check_sanguinia_pending_forced_skill()
	# Теперь принудительный Навык E выполнен, стаки сброшены, +1 ОН получен (3 + 1 = 4)
	if int(sanguinia.get_meta("sanguinia_waves", 0)) != 0: return false
	if int(lenskaya.get_meta("lenskaya_manipulation", 0)) != 0: return false
	if sanguinia.has_meta("sanguinia_pending_forced_skill_unit"): return false
	if bm.skill_points != 4: return false

	return true

# 11. Эйдолоны E1, E2, E4, E6
func test_11_eidolons_e1_e2_e4_e6() -> bool:
	var bm := _setup_test_bm()
	var sanguinia_e6 := SanguiniaAbilities.create_unit(6)
	var lenskaya := LenskayaAbilities.create_unit(0)
	var enemy := _create_dummy_enemy()
	bm.allies = [sanguinia_e6, lenskaya]
	bm.enemies = [enemy]
	
	# E4: Сверхспособность повышает СА Сангинии на 40% на 3 хода
	SanguiniaAbilities.execute_ultimate(sanguinia_e6, bm)
	if not sanguinia_e6.has_meta("sanguinia_e4_atk_turns"): return false
	if int(sanguinia_e6.get_meta("sanguinia_e4_atk_turns", 0)) != 3: return false
	
	# E4: игнорирует себя при выборе союзника с наибольшей СА
	var highest := SanguiniaAbilities.get_highest_atk_ally(bm, true)
	if highest == sanguinia_e6: return false
	if highest != lenskaya: return false
	
	# E2: при сбросе 47 стаков дает +60% урона Сангинии на 2 хода
	sanguinia_e6.set_meta("sanguinia_waves_pending_reset_target", lenskaya)
	SanguiniaAbilities.check_reset_waves_stacks(lenskaya, bm)
	if not sanguinia_e6.has_meta("sanguinia_e2_dmg_turns"): return false
	if float(sanguinia_e6.get_meta("sanguinia_e2_dmg_buff", 0.0)) != 0.60: return false
	
	# E6: Множитель Заселение 80% (удвоен с 40%) и наносит чистый урон
	var pop := CombatUnit.new()
	pop.id = "sanguinia_settlement"
	pop.set_meta("sanguinia_owner", sanguinia_e6)
	var hp_before := enemy.stats.hp
	SanguiniaAbilities.execute_settlement_turn(pop, bm)
	if enemy.stats.hp >= hp_before: return false
	return true

# 12. Техника поддержки: 30% advance и +15 скорости на 3 хода
func test_12_technique() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var lenskaya := LenskayaAbilities.create_unit(0)
	bm.allies = [sanguinia, lenskaya]
	lenskaya.base_action_value = 100.0
	lenskaya.action_value = 100.0
	
	var base_spd := lenskaya.stats.get_effective_spd()
	SanguiniaAbilities.execute_technique(sanguinia, bm)
	
	var expected_av := 70.0 * (base_spd / (base_spd + 15.0))
	if not is_equal_approx(lenskaya.action_value, expected_av): return false
	if not lenskaya.has_meta("sanguinia_tech_spd_turns"): return false
	if lenskaya.stats.get_effective_spd() != base_spd + 15.0: return false
	return true

# 13. Описание в BattleInfoProvider, отображение статусов и расчет характеристик
func test_13_battle_info_provider_descriptions() -> bool:
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var text := BattleInfoProvider.get_skills_text(sanguinia)
	if text.is_empty(): return false
	if not "Сангиния Ял" in text: return false
	if not "Особый гость" in text: return false
	if not "Готовьтесь..." in text: return false
	if not "Заселение!" in text: return false
	if not "Журчание волн" in text: return false
	
	# Проверка отображения стаков Журчания волн в статусах Сангинии
	sanguinia.set_meta("sanguinia_waves", 15)
	var s_statuses := BattleInfoProvider.get_statuses_text(sanguinia, [sanguinia])
	if not "Журчание волн (15/47 стаков)" in s_statuses: return false
	
	# Проверка отображения Особого гостя в дебаффах врага
	var enemy := _create_dummy_enemy()
	enemy.set_meta("sanguinia_special_guest_charges", 8)
	var e_statuses := BattleInfoProvider.get_statuses_text(enemy, [sanguinia])
	if not "Особый гость (8/12 зар.)" in e_statuses: return false
	
	# Проверка отображения баффа Навыка Q и изменения эффективной СА союзника
	var ally := LenskayaAbilities.create_unit(0)
	var base_eff_atk := BattleInfoProvider.get_unit_effective_atk_static(ally, [sanguinia, ally])
	ally.set_meta("sanguinia_q_atk_turns", 3)
	ally.set_meta("sanguinia_q_atk_buff", 0.40)
	var buffed_eff_atk := BattleInfoProvider.get_unit_effective_atk_static(ally, [sanguinia, ally])
	var a_statuses := BattleInfoProvider.get_statuses_text(ally, [sanguinia, ally])
	if not "Поддержка Сангинии (Навык Q)" in a_statuses: return false
	if not is_equal_approx(buffed_eff_atk, base_eff_atk + ally.stats.atk * 0.40): return false
	
	return true

# 14. ДоТ урон не уменьшает заряды Особого гостя
func test_14_dot_does_not_reduce_special_guest() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var ally := LenskayaAbilities.create_unit(0)
	var enemy := _create_dummy_enemy()
	bm.allies = [sanguinia, ally]
	bm.enemies = [enemy]
	
	SanguiniaAbilities.execute_skill_e(sanguinia, enemy, bm)
	if int(enemy.get_meta("sanguinia_special_guest_charges", 0)) != 12: return false
	
	# 1. ДоТ урон от союзника
	bm.deal_damage(enemy, 500.0, ally, CombatConstants.Element.FIRE, false, "DoT")
	if int(enemy.get_meta("sanguinia_special_guest_charges", 0)) != 12: return false
	
	# 2. ДоТ урон при установленном флаге is_processing_dots
	bm.set_meta("is_processing_dots", true)
	bm.deal_damage(enemy, 500.0, ally, CombatConstants.Element.PHYSICAL, false, "")
	bm.remove_meta("is_processing_dots")
	if int(enemy.get_meta("sanguinia_special_guest_charges", 0)) != 12: return false

	# 3. Урон от пробития уязвимости (Break)
	bm.deal_damage(enemy, 500.0, ally, CombatConstants.Element.QUANTUM, false, "Break")
	if int(enemy.get_meta("sanguinia_special_guest_charges", 0)) != 12: return false
	
	# 4. Атака союзника (Basic) уменьшает заряды
	bm.start_attack_action()
	bm.deal_damage(enemy, 500.0, ally, CombatConstants.Element.QUANTUM, false, "Basic")
	bm.finish_attack_action()
	if int(enemy.get_meta("sanguinia_special_guest_charges", 0)) != 11: return false
	return true

# 15. Проверка работы всех баффов Сангинии и их влияние на урон (calc_dmg)
func test_15_all_sanguinia_buffs_increase_damage() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(2)
	var ally := LenskayaAbilities.create_unit(0)
	sanguinia.stats.crit_rate = 0.0
	ally.stats.crit_rate = 0.0
	var enemy := _create_dummy_enemy()
	bm.allies = [sanguinia, ally]
	bm.enemies = [enemy]
	
	# 1) Базовый урон обычной атаки ally
	var res_base := bm.calc_dmg(ally, enemy, 1.0, 0.0, false, 0.0, 0.0, false, false, "Basic")
	var dmg_base: float = float(res_base.get("damage", 0.0))
	
	# 2) Бафф Навыка Q (+40% СА)
	ally.set_meta("sanguinia_q_atk_turns", 3)
	ally.set_meta("sanguinia_q_atk_buff", 0.40)
	var res_q := bm.calc_dmg(ally, enemy, 1.0, 0.0, false, 0.0, 0.0, false, false, "Basic")
	var dmg_q: float = float(res_q.get("damage", 0.0))
	if dmg_q <= dmg_base: return false
	ally.remove_meta("sanguinia_q_atk_turns")
	ally.remove_meta("sanguinia_q_atk_buff")
	
	# 3) Бафф «Готовьтесь...» (+60% СА и игнор 20% DEF)
	ally.set_meta("sanguinia_prep_atk_turns", 1)
	ally.set_meta("sanguinia_prep_atk_buff", 0.60)
	ally.set_meta("sanguinia_prep_ignore_def_attack", true)
	var res_prep := bm.calc_dmg(ally, enemy, 1.0, 0.0, false, 0.0, 0.0, false, false, "Basic")
	var dmg_prep: float = float(res_prep.get("damage", 0.0))
	if dmg_prep <= dmg_base: return false
	ally.remove_meta("sanguinia_prep_atk_turns")
	ally.remove_meta("sanguinia_prep_atk_buff")
	ally.remove_meta("sanguinia_prep_ignore_def_attack")
	
	# 4) Журчание волн (+2% за стак для бонус-атак)
	var res_fua_0 := bm.calc_dmg(ally, enemy, 1.0, 0.0, false, 0.0, 0.0, false, true, "Бонус-атака")
	var dmg_fua_0: float = float(res_fua_0.get("damage", 0.0))
	sanguinia.set_meta("sanguinia_waves", 10)
	var res_fua_10 := bm.calc_dmg(ally, enemy, 1.0, 0.0, false, 0.0, 0.0, false, true, "Бонус-атака")
	var dmg_fua_10: float = float(res_fua_10.get("damage", 0.0))
	if dmg_fua_10 <= dmg_fua_0: return false
	sanguinia.set_meta("sanguinia_waves", 0)
	
	# 5) Бафф 47 стаков (+100% урона следующей атаки)
	ally.set_meta("sanguinia_talent_dmg_boost", 1.00)
	var res_boost := bm.calc_dmg(ally, enemy, 1.0, 0.0, false, 0.0, 0.0, false, false, "Basic")
	var dmg_boost: float = float(res_boost.get("damage", 0.0))
	if dmg_boost <= dmg_base: return false
	ally.remove_meta("sanguinia_talent_dmg_boost")
	
	# 6) Бафф E2 (+60% урона для Сангинии)
	var res_s_base := bm.calc_dmg(sanguinia, enemy, 1.0, 0.0, false, 0.0, 0.0, false, false, "Basic")
	var dmg_s_base: float = float(res_s_base.get("damage", 0.0))
	sanguinia.set_meta("sanguinia_e2_dmg_turns", 2)
	sanguinia.set_meta("sanguinia_e2_dmg_buff", 0.60)
	var res_s_e2 := bm.calc_dmg(sanguinia, enemy, 1.0, 0.0, false, 0.0, 0.0, false, false, "Basic")
	var dmg_s_e2: float = float(res_s_e2.get("damage", 0.0))
	if dmg_q <= dmg_base: return false
	if dmg_prep <= dmg_base: return false
	if dmg_fua_10 <= dmg_fua_0: return false
	if dmg_boost <= dmg_base: return false
	if dmg_s_e2 <= dmg_s_base: return false
	
	return true

# 16. Получаемый Особым гостем урон бонус-атак повышается на 70% (пока действует этот статус)
func test_16_special_guest_fua_vulnerability() -> bool:
	var bm := _setup_test_bm()
	var sanguinia := SanguiniaAbilities.create_unit(0)
	var ally := LenskayaAbilities.create_unit(0)
	var enemy_guest := _create_dummy_enemy()
	var enemy_other := _create_dummy_enemy()
	bm.allies = [sanguinia, ally]
	bm.enemies = [enemy_guest, enemy_other]
	
	# 1. Накладываем «Особый гость» на enemy_guest
	SanguiniaAbilities.execute_skill_e(sanguinia, enemy_guest, bm)
	if not enemy_guest.has_meta("sanguinia_special_guest_charges"): return false
	if not enemy_guest.statuses.debuffs.has("sanguinia_special_guest"): return false
	
	# 2. Обычная атака ("Basic") НЕ должна получать +70% бонуса
	var res_basic_guest := bm.calc_dmg(ally, enemy_guest, 1.0, 0.0, false, 0.0, 0.0, false, false, "Basic")
	var res_basic_other := bm.calc_dmg(ally, enemy_other, 1.0, 0.0, false, 0.0, 0.0, false, false, "Basic")
	var dmg_basic_guest: float = float(res_basic_guest.get("damage", 0.0))
	var dmg_basic_other: float = float(res_basic_other.get("damage", 0.0))
	if not is_equal_approx(dmg_basic_guest, dmg_basic_other):
		printerr("Базовая атака не должна получать бафф уязвимости бонус-атак!")
		return false
		
	# 3. Бонус-атака ("Бонус-атака") по enemy_guest должна наносить ровно на 70% больше урона, чем по enemy_other
	var res_fua_other := bm.calc_dmg(ally, enemy_other, 1.0, 0.0, false, 0.0, 0.0, false, false, "Бонус-атака")
	var res_fua_guest := bm.calc_dmg(ally, enemy_guest, 1.0, 0.0, false, 0.0, 0.0, false, false, "Бонус-атака")
	var dmg_fua_other: float = float(res_fua_other.get("damage", 0.0))
	var dmg_fua_guest: float = float(res_fua_guest.get("damage", 0.0))
	if not is_equal_approx(dmg_fua_guest, dmg_fua_other * 1.70):
		printerr("Бонус-атака по Особому гостю должна быть усилена ровно на 70%! Получено: ", dmg_fua_guest, " против базового: ", dmg_fua_other)
		return false

	# 4. Чистый урон бонус-атаки (deal_damage с "lenskaya_true_fua" или "sanguinia_true_fua")
	var hp_before := enemy_guest.stats.hp
	bm.deal_damage(enemy_guest, 1000.0, sanguinia, CombatConstants.Element.FIRE, false, "sanguinia_true_fua")
	var dealt_guest: float = hp_before - enemy_guest.stats.hp
	if not is_equal_approx(dealt_guest, 1700.0):
		printerr("Чистый урон бонус-атаки по Особому гостю должен быть усилен на 70%! Получено: ", dealt_guest)
		return false
		
	# 5. После снятия статуса «Особый гость» урон бонус-атак возвращается к норме
	sanguinia.set_meta("sanguinia_waves", 0)
	ally.set_meta("lenskaya_manipulation", 0)
	enemy_guest.remove_meta("sanguinia_special_guest_charges")
	enemy_guest.statuses.debuffs.erase("sanguinia_special_guest")
	var res_fua_cleared := bm.calc_dmg(ally, enemy_guest, 1.0, 0.0, false, 0.0, 0.0, false, false, "Бонус-атака")
	var dmg_fua_cleared: float = float(res_fua_cleared.get("damage", 0.0))
	if not is_equal_approx(dmg_fua_cleared, dmg_fua_other):
		printerr("После снятия статуса урон бонус-атак должен вернуться к стандартному значению! Получено: ", dmg_fua_cleared, " против базового: ", dmg_fua_other)
		return false

	return true

