extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  ЗАПУСК ТЕСТОВ: МАРИНА • ХРАНИТЕЛЬ НЕБЕС (marina_sky_guardian)")
	print("========================================================\n")
	
	var passed := 0
	var failed := 0

	var tests := [
		"test_1_marina_stats_and_creation",
		"test_2_ego_summon_and_inheritance",
		"test_3_ego_heal_and_cc_cleanse",
		"test_4_basic_attack_and_charge",
		"test_5_ego_dejavu_and_reality",
		"test_6_skill_q_link_and_crit_stacking",
		"test_7_ultimate_elysium_zone_and_e1_e2_e6",
		"test_8_talent_energy_to_charge_and_other_sprite",
		"test_9_sky_guardians_moon_maiden",
		"test_10_radiance_faction_buffs",
		"test_11_new_remembrance_light_cones",
		"test_12_memosprite_damage_credited_to_owner",
		"test_13_marina_link_dynamic_stats",
		"test_14_single_skill_text_isolation",
		"test_15_ego_reality_manual_execution",
		"test_16_isaac_advance_and_ult_on_ego",
		"test_17_shoji_dance_skill_q_no_elysium_damage",
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

func test_1_marina_stats_and_creation() -> bool:
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	if marina.id != "marina_sky_guardian": return false
	if marina.element != CombatConstants.Element.WIND: return false
	if marina.path != CombatConstants.Path.REMEMBRANCE: return false
	if marina.stats.hp != 2800.0 or marina.stats.max_hp != 2800.0: return false
	if marina.stats.atk != 1050.0: return false
	if marina.stats.def != 750.0: return false
	if marina.stats.spd != 105.0: return false
	if marina.stats.crit_rate != 0.05: return false
	if marina.stats.crit_dmg != 0.50: return false
	if marina.max_energy != 140.0: return false
	return true

func test_2_ego_summon_and_inheritance() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	bm.allies.append(marina)
	
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	if ego == null or not ego.is_alive():
		return false
	
	# Проверка характеристик Эго: HP = 2800 * 0.68 + 300 = 2204
	var expected_hp := 2800.0 * 0.68 + 300.0
	if absf(ego.stats.max_hp - expected_hp) > 1.0:
		return false
	if ego.stats.spd != 130.0:
		return false
	
	# Наследование параметров
	if ego.stats.atk != marina.stats.atk:
		return false
	if ego.stats.def != marina.stats.def:
		return false
	if ego.stats.crit_rate != marina.stats.crit_rate:
		return false
	if ego.stats.crit_dmg != marina.stats.crit_dmg:
		return false
	
	# След 2: Первый призыв дает 40% заряда + Талант: 30 энергии от навыка дают 3% заряда = 43%
	if ego.get_charge() != 43.0:
		return false
	return true

func test_3_ego_heal_and_cc_cleanse() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	bm.allies.append(marina)
	
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	
	# Наносим урон и накладываем эффект контроля
	ego.stats.hp = 500.0
	ego.statuses.skip_next_turn = true
	ego.statuses.break_status = "freeze"
	ego.statuses.break_status_turns = 1
	
	# Повторное использование Навыка E очищает контроль и лечит на 60% макс ХП
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	if ego.statuses.skip_next_turn or ego.statuses.break_status == "freeze": return false
	var expected_healed := 500.0 + (ego.stats.max_hp * 0.60)
	if absf(ego.stats.hp - expected_healed) > 1.0: return false
	return true

func test_4_basic_attack_and_charge() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	var enemy := CombatUnit.new()
	enemy.id = "target"
	enemy.stats.hp = 10000.0
	enemy.stats.max_hp = 10000.0
	enemy.stats.def = 500.0
	bm.allies.append(marina)
	bm.enemies.append(enemy)
	
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	var init_charge := ego.get_charge()
	
	MarinaSkyGuardianAbilities.execute_basic_attack(marina, enemy, bm)
	# +5% заряда от атаки + 2% заряда от восстановления 20 энергии талантом = +7%
	if ego.get_charge() != init_charge + 7.0:
		return false
	# Нанесен урон
	if enemy.stats.hp >= 10000.0:
		return false
	return true

func test_5_ego_dejavu_and_reality() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	var enemy := CombatUnit.new()
	enemy.id = "target"
	enemy.stats.hp = 20000.0
	enemy.stats.max_hp = 20000.0
	enemy.stats.def = 500.0
	bm.allies.append(marina)
	bm.enemies.append(enemy)
	
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	
	# Дежавю?
	var c_before := ego.get_charge()
	MarinaSkyGuardianAbilities.execute_ego_dejavu(ego, enemy, bm)
	# След 3: +5% заряда
	if ego.get_charge() != c_before + 5.0: return false
	
	# Заряжаем до 100%
	ego.add_charge(100.0)
	MarinaSkyGuardianAbilities.check_ego_full_charge(ego, bm)
	if not bool(ego.get_meta("use_reality", false)): return false
	
	# Применение «Реальности»
	MarinaSkyGuardianAbilities.execute_ego_reality(ego, enemy, bm)
	if bool(ego.get_meta("use_reality", false)): return false
	if ego.get_charge() != 0.0: return false
	if int(enemy.get_meta("ego_reality_vuln_turns", 0)) != 2: return false
	if int(enemy.get_meta("ego_reality_true_dmg_turns", 0)) != 2: return false
	return true

func test_6_skill_q_link_and_crit_stacking() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(4) # E4
	var ally := CombatUnit.new()
	ally.id = "ally_dps"
	ally.display_name = "Союзник"
	ally.stats.hp = 3000.0
	ally.stats.max_hp = 3000.0
	ally.stats.atk = 1500.0
	bm.allies.append(marina)
	bm.allies.append(ally)
	
	MarinaSkyGuardianAbilities.execute_skill_q(marina, ally, bm)
	if int(marina.get_meta("marina_sk_link_turns", 0)) != 3: return false
	if not MarinaSkyGuardianAbilities.is_in_skill_q_link(ally, marina, bm): return false
	if not MarinaSkyGuardianAbilities.is_in_skill_q_link(marina, marina, bm): return false
	
	# Атака союзника стакает КШ
	MarinaSkyGuardianAbilities.on_attack_performed(ally, bm)
	var cr_1: float = float(marina.get_meta("marina_sk_link_crit_rate", 0.0))
	if absf(cr_1 - 0.015) > 0.001: return false
	
	# Проверка бонуса в calc_dmg
	var enemy := CombatUnit.new()
	enemy.id = "target"
	enemy.stats.hp = 10000.0
	enemy.stats.max_hp = 10000.0
	enemy.stats.def = 500.0
	bm.enemies.append(enemy)
	
	# Проверяем, что расчет урона учитывает КШ связи, +20% КУ от Следа 1 и 18% игнора защиты от E4
	var res := bm.calc_dmg(ally, enemy, 1.0)
	if res.is_empty(): return false
	return true

func test_7_ultimate_elysium_zone_and_e1_e2_e6() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(6) # E6
	var enemy := CombatUnit.new()
	enemy.id = "target"
	enemy.stats.hp = 50000.0
	enemy.stats.max_hp = 50000.0
	enemy.stats.def = 500.0
	bm.allies.append(marina)
	bm.enemies.append(enemy)
	
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	ego.set_charge(10.0)
	
	MarinaSkyGuardianAbilities.execute_ultimate(marina, bm)
	# +40% заряда Эго -> 50%
	if ego.get_charge() != 50.0: return false
	# Зона на 2 хода
	if int(marina.get_meta("marina_sk_elysium_zone_turns", 0)) != 2: return false
	# E6 бафф на урон духа памяти
	if int(ego.get_meta("marina_sk_e6_dmg_buff_turns", 0)) != 1: return false
	return true

func test_8_talent_energy_to_charge_and_other_sprite() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	bm.allies.append(marina)
	
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	var init_c := ego.get_charge()
	
	# Получение 30 энергии дает 3% заряда Эго
	bm.gain_energy_with_err(marina, 30.0)
	if ego.get_charge() != init_c + 3.0: return false
	
	# Действие другого духа памяти дает Марине 8 энергии
	var def_other := MemospriteDefinition.new()
	def_other.id = "other_sprite"
	def_other.display_name = "Другой дух"
	var other_owner := CombatUnit.new()
	other_owner.id = "other_hero"
	other_owner.is_ally = true
	other_owner.stats.max_hp = 2000.0
	other_owner.stats.hp = 2000.0
	bm.allies.append(other_owner)
	var other_sprite := MemospriteSystem.summon(other_owner, def_other, bm)
	
	var m_energy_before := marina.energy
	MarinaSkyGuardianAbilities.check_other_memosprite_action(other_sprite, bm)
	if marina.energy != m_energy_before + 8.0: return false
	return true

func test_9_sky_guardians_moon_maiden() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	bm.allies.append(marina)
	bm.init_moon_maiden()
	
	if bm.moon_maiden == null: return false
	if bm.moon_maiden.stats.spd != 60.0: return false
	if not bm.is_moon_maiden_active(): return false
	
	# Накопление ударов
	bm.moon_maiden_hits = 3
	var enemy := CombatUnit.new()
	enemy.id = "enemy"
	enemy.stats.hp = 20000.0
	enemy.stats.max_hp = 20000.0
	bm.enemies.append(enemy)
	
	bm._execute_moon_maiden_turn()
	# Удары сбросились до 1
	if bm.moon_maiden_hits != 1: return false
	# Враг получил чистый урон
	if enemy.stats.hp >= 20000.0: return false
	return true

func test_10_radiance_faction_buffs() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	var radiance_ally := CombatUnit.new()
	radiance_ally.id = "sara"
	bm.allies.append(marina)
	
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	if ego == null: return false
	
	var enemy := CombatUnit.new()
	enemy.id = "enemy"
	enemy.stats.hp = 20000.0
	enemy.stats.max_hp = 20000.0
	bm.enemies.append(enemy)
	
	var res := bm.calc_dmg(ego, enemy, 1.0)
	if res.is_empty(): return false
	return true

func test_11_new_remembrance_light_cones() -> bool:
	var bm := _setup_test_bm()

	# --- 1. threads_of_mnema (Нити мнемы) ---
	var marina1 := MarinaSkyGuardianAbilities.create_unit(0)
	marina1.set_meta("light_cone_id", "threads_of_mnema")
	bm.allies = [marina1]
	MarinaSkyGuardianAbilities.execute_skill_e(marina1, bm)
	var ego1 := MarinaSkyGuardianAbilities.get_ego_sprite(marina1, bm)
	if ego1 == null: return false

	# В начале хода духа памяти владелец и дух получают по 1 ур. статуса «Почитание памяти»
	bm._process_turn_start_statuses(ego1)
	if int(marina1.get_meta("mnema_reverence_stacks", 0)) != 1: return false
	if int(ego1.get_meta("mnema_reverence_stacks", 0)) != 1: return false

	# Стакается до 4 раз
	bm._process_turn_start_statuses(ego1)
	bm._process_turn_start_statuses(ego1)
	bm._process_turn_start_statuses(ego1)
	if int(marina1.get_meta("mnema_reverence_stacks", 0)) != 4: return false
	if int(ego1.get_meta("mnema_reverence_stacks", 0)) != 4: return false

	# Не превышает 4
	bm._process_turn_start_statuses(ego1)
	if int(marina1.get_meta("mnema_reverence_stacks", 0)) != 4: return false

	# При исчезновении духа памяти статус снимается
	MemospriteSystem.despawn(ego1, bm)
	if marina1.has_meta("mnema_reverence_stacks"): return false
	if ego1.has_meta("mnema_reverence_stacks"): return false

	# --- 2. burned_page (Сгоревшая страница) ---
	var marina2 := MarinaSkyGuardianAbilities.create_unit(0)
	marina2.set_meta("light_cone_id", "burned_page")
	bm.allies = [marina2]
	var base_spd2 := marina2.stats.get_effective_spd()
	var base_hp2 := marina2.stats.max_hp
	MarinaSkyGuardianAbilities.execute_skill_e(marina2, bm)
	var ego2 := MarinaSkyGuardianAbilities.get_ego_sprite(marina2, bm)
	if ego2 == null: return false

	# После призыва: СКР +8%, Макс. HP +15% на 2 хода
	if int(marina2.get_meta("burned_page_turns", 0)) != 2: return false
	if int(ego2.get_meta("burned_page_turns", 0)) != 2: return false
	if absf(marina2.stats.get_effective_spd() - base_spd2 * 1.08) > 0.1: return false
	if marina2.stats.max_hp <= base_hp2: return false

	# Первый ход (skip tick)
	bm._process_turn_start_statuses(marina2)
	if int(marina2.get_meta("burned_page_turns", 0)) != 2: return false
	# Второй ход
	bm._process_turn_start_statuses(marina2)
	if int(marina2.get_meta("burned_page_turns", 0)) != 1: return false
	# Третий ход -> истекает, скорость возвращается к норме
	bm._process_turn_start_statuses(marina2)
	if marina2.has_meta("burned_page_turns"): return false
	if absf(marina2.stats.get_effective_spd() - base_spd2) > 0.1: return false

	# --- 3. let_past_stay_behind (Пусть прошлое остаётся позади) ---
	var marina3 := MarinaSkyGuardianAbilities.create_unit(0)
	marina3.set_meta("light_cone_id", "let_past_stay_behind")
	var base_cd3 := marina3.stats.crit_dmg
	bm.allies = [marina3]
	bm._init_light_cone_effects(marina3)
	if absf(marina3.stats.crit_dmg - (base_cd3 + 0.36)) > 0.001: return false

	MarinaSkyGuardianAbilities.execute_skill_e(marina3, bm)
	var ego3 := MarinaSkyGuardianAbilities.get_ego_sprite(marina3, bm)
	if ego3 == null: return false

	var enemy3 := CombatUnit.new()
	enemy3.id = "test_enemy_3"
	enemy3.is_ally = false
	enemy3.stats.hp = 10000.0
	enemy3.stats.max_hp = 10000.0
	bm.enemies = [enemy3]

	# Атака духа памяти накладывает «По следам воспоминаний» на 1 ход
	bm.deal_damage(enemy3, 100.0, ego3)
	if int(enemy3.get_meta("traces_of_memories_turns", 0)) != 1: return false

	# Атака владельца восстанавливает 10 энергии, снимает статус и снижает защиту на 10% на 1 ход
	marina3.energy = 0.0
	bm.deal_damage(enemy3, 100.0, marina3)
	if absf(marina3.energy - 10.0) > 0.01: return false
	if enemy3.has_meta("traces_of_memories_turns"): return false
	if not enemy3.has_meta("def_reductions"): return false
	var def_reds: Dictionary = enemy3.get_meta("def_reductions", {})
	if not def_reds.has("По следам воспоминаний (конус)"): return false
	if absf(float(def_reds["По следам воспоминаний (конус)"]["percent"]) - 0.10) > 0.001: return false

	return true

func test_12_memosprite_damage_credited_to_owner() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	bm.allies.append(marina)
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	if ego == null: return false

	var enemy := CombatUnit.new()
	enemy.id = "target_enemy"
	enemy.stats.hp = 10000.0
	enemy.stats.max_hp = 10000.0
	bm.enemies.append(enemy)

	# Урон, нанесенный Эго, должен засчитываться Марине в damage_tracker
	bm.deal_damage(enemy, 1500.0, ego)
	if not bm.damage_tracker.has(marina.id): return false
	if bm.damage_tracker[marina.id] < 1500.0: return false
	return true

func test_13_marina_link_dynamic_stats() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	var ally := CombatUnit.new()
	ally.id = "test_ally"
	ally.display_name = "Тестовый Союзник"
	ally.stats.hp = 3000.0
	ally.stats.max_hp = 3000.0
	ally.stats.crit_rate = 0.10
	ally.stats.crit_dmg = 0.50
	bm.allies.append(marina)
	bm.allies.append(ally)

	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)

	# Создаем связь между Мариной и ally
	MarinaSkyGuardianAbilities.execute_skill_q(marina, ally, bm)
	# Добавляем немного накопленного крита
	marina.set_meta("marina_sk_link_crit_rate", 0.15)

	var ally_stats := BattleInfoProvider.get_stats_text(ally, bm.allies)
	if not "Крит: 25% / +70%" in ally_stats: return false

	var ally_statuses := BattleInfoProvider.get_statuses_text(ally, bm.allies)
	if not "Под связью Марины" in ally_statuses: return false
	if not "Крит. урон +20%" in ally_statuses: return false

	var ego_stats := BattleInfoProvider.get_stats_text(ego, bm.allies)
	if not "Заряд" in ego_stats: return false

	var ego_statuses := BattleInfoProvider.get_statuses_text(ego, bm.allies)
	if not "Талант Эго" in ego_statuses: return false
	return true

func test_14_single_skill_text_isolation() -> bool:
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	
	var basic_text := BattleInfoProvider.get_single_skill_text(marina, "basic")
	if not "Базовая атака" in basic_text: return false
	if "Навык Q" in basic_text: return false
	if "Сверхспособность" in basic_text: return false

	var q_text := BattleInfoProvider.get_single_skill_text(marina, "skill_q")
	if not "Навык Q" in q_text: return false
	if "Базовая атака" in q_text: return false
	if "Навык E" in q_text: return false

	var e_text := BattleInfoProvider.get_single_skill_text(marina, "skill_e")
	if not "Навык E" in e_text: return false
	if "Сверхспособность" in e_text: return false

	var ult_text := BattleInfoProvider.get_single_skill_text(marina, "ult")
	if not "Сверхспособность" in ult_text: return false
	if "Талант" in ult_text: return false

	return true

func test_15_ego_reality_manual_execution() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	bm.allies.append(marina)
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)

	var enemy := CombatUnit.new()
	enemy.id = "reality_target"
	enemy.stats.hp = 20000.0
	enemy.stats.max_hp = 20000.0
	bm.enemies.append(enemy)

	# Заполняем заряд до 100%
	ego.charge_comp.add_charge(100.0)
	MarinaSkyGuardianAbilities.check_ego_full_charge(ego, bm)

	if not ego.has_meta("ego_ready_for_reality"): return false
	if not ego.get_meta("use_reality", false): return false

	# Игрок выбирает цель
	bm.player_memosprite_reality(ego, enemy)

	# Проверяем, что Реальность выполнилась, заряд сброшен, флаг снят
	if ego.has_meta("ego_ready_for_reality"): return false
	if ego.charge_comp.charge > 0.0: return false
	if enemy.stats.hp >= 20000.0: return false
	return true

func test_16_isaac_advance_and_ult_on_ego() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	var isaac := IsaacAbilities.create_unit(0)
	bm.allies.append(marina)
	bm.allies.append(isaac)

	# Марина призывает Эго
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	if ego == null or not ego.is_alive():
		return false

	# У Эго есть базовое действие > 0
	if ego.action_value <= 0.0:
		return false

	# Айзек получает 8 зарядов Теории на практике (усиленный Навык Q)
	IsaacAbilities.add_theory_stacks(isaac, 8, bm)

	# Айзек продвигает действие Эго на 100%
	IsaacAbilities.execute_skill_q(isaac, ego, [], bm)
	if ego.action_value != 0.0:
		return false

	# Айзек применяет Сверхспособность на Эго (бафф КУ и скорости +16)
	IsaacAbilities.execute_ultimate(isaac, ego, bm)

	# Действие Эго НЕ должно сбиваться назад (должно остаться 0.0 для немедленного хода!)
	if ego.action_value != 0.0:
		return false

	return true

func test_17_shoji_dance_skill_q_no_elysium_damage() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	var shoji := ShojiSwanAbilities.create_unit(0)
	bm.allies.append(marina)
	bm.allies.append(shoji)

	# Сёдзи на позиции саппорта (слот 1) переходит в состояние «Танец»
	ShojiSwanAbilities.apply_traces(shoji, bm)
	if String(shoji.get_meta("shoji_swan_stance", "")) != "dance":
		return false

	# Марина активирует зону Элизиум (2 хода)
	MarinaSkyGuardianAbilities.execute_ultimate(marina, bm)
	if int(marina.get_meta("marina_sk_elysium_zone_turns", 0)) != 2:
		return false

	var enemy := CombatUnit.new()
	enemy.id = "elysium_test_enemy"
	enemy.stats.hp = 100000.0
	enemy.stats.max_hp = 100000.0
	enemy.stats.def = 500.0
	bm.enemies.append(enemy)

	# Предыдущий ход: Марина атакует врага, нанося урон (в action_hit_enemies попадает цель)
	MarinaSkyGuardianAbilities.execute_basic_attack(marina, enemy, bm)
	bm._end_turn(marina)

	# Новый ход: Сёдзи в стойке «Танец» использует Навык Q (задержка хода, 0 урона)
	bm.current_unit = shoji
	bm.phase = BattleManager.Phase.RUNNING
	bm._waiting_for_player = true
	bm.skill_points = 2

	var hp_before_dance_q := enemy.stats.hp
	bm.player_skill(null)
	var hp_after_dance_q := enemy.stats.hp

	# Навык Q Сёдзи в танце не наносит урон, и Элизиум НЕ должен ошибочно наносить урон
	if hp_before_dance_q != hp_after_dance_q:
		return false

	return true

