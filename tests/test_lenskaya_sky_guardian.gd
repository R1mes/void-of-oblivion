extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  ЗАПУСК ТЕСТОВ: ЛЕНСКАЯ • ХРАНИТЕЛЬ НЕБЕС (lenskaya_sky_guardian)")
	print("========================================================\n")
	
	var passed := 0
	var failed := 0

	var tests := [
		"test_1_lenskaya_stats_and_creation",
		"test_2_basic_attack",
		"test_3_enhanced_basic_and_e4",
		"test_4_skill_q_radiance_enemy_and_enhancement",
		"test_5_skill_e_and_e1_e6",
		"test_6_ultimate_and_trace2",
		"test_7_talent_super_break_conversion",
		"test_8_traces",
		"test_9_technique",
		"test_10_memosprite_card_and_element_inheritance",
		"test_11_marina_q_cannot_target_memosprite",
		"test_12_jeff_q_adjacent_healing_memosprite",
		"test_13_star_guide_selection_radiance",
		"test_14_skill_q_enhanced_basic_turn_persistence",
		"test_15_battle_info_provider_milena_traces_and_skill_text",
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
	enemy.weaknesses = [CombatConstants.Element.IMAGINARY, CombatConstants.Element.WIND]
	return enemy

func test_1_lenskaya_stats_and_creation() -> bool:
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	if lenskaya.id != "lenskaya_sky_guardian": return false
	if lenskaya.element != CombatConstants.Element.IMAGINARY: return false
	if lenskaya.path != CombatConstants.Path.HUNT: return false
	if lenskaya.stats.hp != 2400.0 or lenskaya.stats.max_hp != 2400.0: return false
	if lenskaya.stats.atk != 1700.0: return false
	if lenskaya.stats.def != 700.0: return false
	if lenskaya.stats.spd != 108.0: return false
	if lenskaya.stats.crit_rate != 0.05: return false
	if lenskaya.stats.crit_dmg != 0.50: return false
	if lenskaya.stats.break_effect != 0.60: return false
	if lenskaya.max_energy != 110.0: return false

	# Проверка фракций
	var factions := FactionSystem.get_unit_factions("lenskaya_sky_guardian")
	if not "sky_guardians" in factions or not "radiance" in factions:
		return false
	return true

func test_2_basic_attack() -> bool:
	var bm := _setup_test_bm()
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	lenskaya.energy = 0.0
	var enemy := _create_dummy_enemy(50000.0, 60.0)
	bm.allies.append(lenskaya)
	bm.enemies.append(enemy)

	bm.skill_points = 2
	LenskayaSkyGuardianAbilities.execute_basic_attack(lenskaya, enemy, bm)

	# +1 SP (2 -> 3)
	if bm.skill_points != 3: return false
	# +20 Energy
	if lenskaya.energy != 20.0: return false
	# 10 Toughness reduction (60 -> 50)
	if absf(enemy.toughness - 50.0) > 0.01: return false
	# Damage dealt
	if enemy.stats.hp >= 50000.0: return false
	return true

func test_3_enhanced_basic_and_e4() -> bool:
	var bm := _setup_test_bm()
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	lenskaya.energy = 0.0
	var enemy := _create_dummy_enemy(50000.0, 60.0)
	bm.allies.append(lenskaya)
	bm.enemies.append(enemy)

	# 6 hits of 30% ATK, 5 toughness each (30 total)
	LenskayaSkyGuardianAbilities.execute_enhanced_basic(lenskaya, enemy, bm)

	# Energy: +20
	if lenskaya.energy != 20.0: return false
	# Toughness: 60 - 30 = 30
	if absf(enemy.toughness - 30.0) > 0.01: return false

	# E4: +5 additional energy (+25 total)
	var lenskaya_e4 := LenskayaSkyGuardianAbilities.create_unit(4)
	lenskaya_e4.energy = 0.0
	LenskayaSkyGuardianAbilities.execute_enhanced_basic(lenskaya_e4, enemy, bm)
	if lenskaya_e4.energy != 25.0: return false
	return true

func test_4_skill_q_radiance_enemy_and_enhancement() -> bool:
	var bm := _setup_test_bm()
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	lenskaya.energy = 0.0
	var enemy := _create_dummy_enemy(50000.0, 60.0)
	bm.allies.append(lenskaya)
	bm.enemies.append(enemy)

	LenskayaSkyGuardianAbilities.execute_skill_q(lenskaya, enemy, bm)

	# Energy: +30
	if lenskaya.energy != 30.0: return false
	# Status "Враг Свечения" on enemy for 3 turns
	if int(enemy.get_meta("lenskaya_radiance_enemy_turns", 0)) != 3: return false
	# Enhanced basic on self for 3 turns
	if int(lenskaya.get_meta("lenskaya_enhanced_basic_turns", 0)) != 3: return false

	# Test 1.5x toughness reduction efficiency on Radiance Enemy
	var initial_tgh := enemy.toughness
	ToughnessSystem.apply_weakness_hit(lenskaya, enemy, bm, 10.0 / 30.0)
	# Normal 10 tgh * 1.5 = 15 tgh reduction
	var expected_tgh := initial_tgh - 15.0
	if absf(enemy.toughness - expected_tgh) > 0.01: return false

	# Test E0 Super Break multiplier bonus (+30%)
	var dmg_e0 := DamageCalculator.calc_super_break_damage(lenskaya, enemy, 10.0)
	
	# Test E2 Super Break multiplier bonus (+45%)
	var lenskaya_e2 := LenskayaSkyGuardianAbilities.create_unit(2)
	var enemy_e2 := _create_dummy_enemy(50000.0, 60.0)
	LenskayaSkyGuardianAbilities.execute_skill_q(lenskaya_e2, enemy_e2, bm)
	var dmg_e2 := DamageCalculator.calc_super_break_damage(lenskaya_e2, enemy_e2, 10.0)
	# dmg_e2 should be higher than dmg_e0 (1.45 / 1.30 ratio)
	if dmg_e2 <= dmg_e0: return false
	if absf((dmg_e2 / dmg_e0) - (1.45 / 1.30)) > 0.05: return false
	return true

func test_5_skill_e_and_e1_e6() -> bool:
	var bm := _setup_test_bm()
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	lenskaya.energy = 0.0
	var enemy := _create_dummy_enemy(50000.0, 60.0)
	bm.allies.append(lenskaya)
	bm.enemies.append(enemy)

	# E0 Skill E: 300% ATK, 30 toughness, +30 Energy
	LenskayaSkyGuardianAbilities.execute_skill_e(lenskaya, enemy, bm)
	if lenskaya.energy != 30.0: return false
	if absf(enemy.toughness - 30.0) > 0.01: return false

	# E1: first use per battle costs 1 SP, subsequent costs 2 SP
	var lenskaya_e1 := LenskayaSkyGuardianAbilities.create_unit(1)
	bm.current_unit = lenskaya_e1
	bm.skill_points = 3
	# Check SP cost evaluation for player_skill_e
	var e1_free := lenskaya_e1.eidolon >= 1 and not lenskaya_e1.has_meta("lenskaya_e1_used")
	var first_cost := 1 if e1_free else 2
	if first_cost != 1: return false
	# Execute first time
	LenskayaSkyGuardianAbilities.execute_skill_e(lenskaya_e1, enemy, bm)
	var e1_free_after := lenskaya_e1.eidolon >= 1 and not lenskaya_e1.has_meta("lenskaya_e1_used")
	var second_cost := 1 if e1_free_after else 2
	if second_cost != 2: return false

	# E6: Implants Imaginary Weakness for 2 turns
	var enemy_no_imaginary := _create_dummy_enemy(50000.0, 60.0)
	enemy_no_imaginary.weaknesses = [CombatConstants.Element.PHYSICAL]
	var lenskaya_e6 := LenskayaSkyGuardianAbilities.create_unit(6)
	LenskayaSkyGuardianAbilities.execute_skill_e(lenskaya_e6, enemy_no_imaginary, bm)
	if not CombatConstants.Element.IMAGINARY in enemy_no_imaginary.weaknesses: return false
	if int(enemy_no_imaginary.get_meta("lenskaya_e6_weakness_turns", 0)) != 2: return false
	return true

func test_6_ultimate_and_trace2() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	bm.allies.append(marina)   # Slot 0
	bm.allies.append(lenskaya) # Slot 1

	lenskaya.action_value = 50.0
	LenskayaSkyGuardianAbilities.execute_ultimate(lenskaya, bm)

	# Self gains +40% BE for 3 turns
	if int(lenskaya.get_meta("lenskaya_ult_be_turns", 0)) != 3: return false
	if float(lenskaya.get_effective_be()) < 0.40: return false
	# 100% action advance -> action_value = 0.0
	if lenskaya.action_value != 0.0: return false

	# Trace 2: slot 0 ally (marina) receives +40% BE for 2 turns
	if int(marina.get_meta("lenskaya_trace2_be_turns", 0)) != 2: return false
	if float(marina.get_effective_be()) < 0.40: return false
	return true

func test_7_talent_super_break_conversion() -> bool:
	var bm := _setup_test_bm()
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	var enemy := _create_dummy_enemy(50000.0, 60.0)
	enemy.toughness = 0.0 # Broken toughness!
	bm.allies.append(lenskaya)
	bm.enemies.append(enemy)

	bm.start_attack_action()
	var hp_before := enemy.stats.hp
	# Deal regular damage
	bm.deal_damage(enemy, 1000.0, lenskaya, lenskaya.element)
	var total_dmg := hp_before - enemy.stats.hp
	bm.finish_attack_action()

	# Total damage must include the 60% Super Break damage conversion
	if total_dmg <= 1000.0: return false

	# Тестируем Усиленную базовую атаку: 4 удара по пробитой цели должны активировать 4 удара суперпробития
	var enemy2 := _create_dummy_enemy(200000.0, 60.0)
	enemy2.toughness = 0.0
	bm.enemies.append(enemy2)
	var sb_proc_count := [0]
	var count_callable := func(msg: String) -> void:
		if "конвертирована в" in msg and "урона суперпробития" in msg:
			sb_proc_count[0] += 1
	bm.log_added.connect(count_callable)

	bm.start_attack_action()
	LenskayaSkyGuardianAbilities.execute_enhanced_basic(lenskaya, enemy2, bm)
	bm.finish_attack_action()
	bm.log_added.disconnect(count_callable)

	if sb_proc_count[0] != 4:
		return false

	return true

func test_8_traces() -> bool:
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	var enemy := _create_dummy_enemy(50000.0, 60.0)
	
	# Trace 1: CR +10% of BE (max 30%), CD +50% of BE (max 150%)
	lenskaya.stats.break_effect = 1.0 # 100% BE
	# Base CR 5% + 10% = 15%, Base CD 50% + 50% = 100%
	var res := DamageCalculator.calc_damage(lenskaya, enemy, 1.0)
	# Test with 400% BE (should cap CR to +30% and CD to +150%)
	lenskaya.stats.break_effect = 4.0
	# Trace 3: Enhanced Basic Super Break damage +30%
	var normal_sb := DamageCalculator.calc_super_break_damage(lenskaya, enemy, 10.0)
	lenskaya.set_meta("is_enhanced_basic", true)
	var enh_sb := DamageCalculator.calc_super_break_damage(lenskaya, enemy, 10.0)
	lenskaya.remove_meta("is_enhanced_basic")
	if enh_sb <= normal_sb: return false
	if absf((enh_sb / normal_sb) - 1.30) > 0.01: return false
	return true

func test_9_technique() -> bool:
	var bm := _setup_test_bm()
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	# Enemy without Imaginary weakness
	var enemy1 := _create_dummy_enemy(50000.0, 60.0)
	enemy1.weaknesses = [CombatConstants.Element.FIRE]
	var enemy2 := _create_dummy_enemy(50000.0, 60.0)
	enemy2.weaknesses = [CombatConstants.Element.ICE]
	bm.allies.append(lenskaya)
	bm.enemies.append(enemy1)
	bm.enemies.append(enemy2)

	LenskayaSkyGuardianAbilities.execute_technique(lenskaya, bm)

	# Both enemies must take damage and lose 40 toughness regardless of weakness
	if absf(enemy1.toughness - 20.0) > 0.01: return false
	if absf(enemy2.toughness - 20.0) > 0.01: return false
	return true

func test_10_memosprite_card_and_element_inheritance() -> bool:
	# Verify Memosprite element inheritance directly from owner
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	bm.allies.append(marina)
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	if ego == null: return false
	# Element must strictly match mentor (WIND, NOT ICE!)
	if ego.element != marina.element: return false
	if ego.element != CombatConstants.Element.WIND: return false
	return true

func test_11_marina_q_cannot_target_memosprite() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	bm.allies.append(marina)
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	if ego == null: return false

	# Attempt to target Ego with Marina's Skill Q
	MarinaSkyGuardianAbilities.execute_skill_q(marina, ego, bm)
	# Ego must NOT have the link
	if ego.has_meta("marina_link_active"): return false
	return true

func test_12_jeff_q_adjacent_healing_memosprite() -> bool:
	var bm := _setup_test_bm()
	var jeff := CombatUnit.new()
	jeff.id = "jeff"
	jeff.display_name = "Джефф"
	jeff.is_ally = true
	jeff.stats.hp = 3000.0
	jeff.stats.max_hp = 3000.0

	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)

	bm.allies.append(jeff)     # Slot 0
	bm.allies.append(marina)   # Slot 1
	bm.allies.append(lenskaya) # Slot 2

	# Summon Ego for Marina
	MarinaSkyGuardianAbilities.execute_skill_e(marina, bm)
	var ego := MarinaSkyGuardianAbilities.get_ego_sprite(marina, bm)
	if ego == null: return false

	# Order in battlefield: [jeff, marina, ego, lenskaya]
	var order := bm.get_battlefield_allies_order()
	if order.size() != 4: return false
	if order[0] != jeff or order[1] != marina or order[2] != ego or order[3] != lenskaya:
		return false

	# Check adjacent to Marina: should be Jeff and Ego
	var adj_marina := bm.get_adjacent_allies(marina)
	if adj_marina.size() != 2: return false
	if adj_marina[0] != jeff or adj_marina[1] != ego: return false

	# Check adjacent to Ego: should be Marina and Lenskaya
	var adj_ego := bm.get_adjacent_allies(ego)
	if adj_ego.size() != 2: return false
	if adj_ego[0] != marina or adj_ego[1] != lenskaya: return false

	# Check adjacent to Lenskaya: should be Ego (NOT Marina!)
	var adj_lenskaya := bm.get_adjacent_allies(lenskaya)
	if adj_lenskaya.size() != 1 or adj_lenskaya[0] != ego: return false

	return true

func test_13_star_guide_selection_radiance() -> bool:
	var bm := _setup_test_bm()
	var marina := MarinaSkyGuardianAbilities.create_unit(0)
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	bm.allies = [marina, lenskaya]

	# По умолчанию выбирается первый живой союзник фракции Свечение (Марина)
	if bm.get_chosen_star_guide() != "marina_sky_guardian": return false

	# Устанавливаем Ленскую Звёздным проводником
	bm.set_chosen_star_guide("lenskaya_sky_guardian")
	if bm.get_chosen_star_guide() != "lenskaya_sky_guardian": return false

	# Проверяем триггер таланта Ленской с бонусом Свечения
	var enemy := _create_dummy_enemy(50000.0, 60.0)
	enemy.statuses.toughness_broken = true
	bm.enemies = [enemy]

	bm.deal_damage(enemy, 1000.0, lenskaya, -1, false, "Basic")
	if not bm.has_meta("lenskaya_talent_triggered_this_action"): return false

	# Переключаем на Марину в качестве проводника
	bm.set_chosen_star_guide("marina_sky_guardian")
	if bm.get_chosen_star_guide() != "marina_sky_guardian": return false

	return true

func test_14_skill_q_enhanced_basic_turn_persistence() -> bool:
	var bm := _setup_test_bm()
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	var enemy := _create_dummy_enemy(50000.0, 60.0)
	bm.allies = [lenskaya]
	bm.enemies = [enemy]

	# Использование Навыка Q активирует усиленную базовую атаку на 3 хода
	LenskayaSkyGuardianAbilities.execute_skill_q(lenskaya, enemy, bm)
	if int(lenskaya.get_meta("lenskaya_enhanced_basic_turns", 0)) != 3: return false
	if not bool(lenskaya.get_meta("lenskaya_enhanced_basic_skip_tick", false)): return false

	# Ход 1: тики в начале хода (skip_tick предотвращает сгорание первого хода)
	bm._process_turn_start_statuses(lenskaya)
	if int(lenskaya.get_meta("lenskaya_enhanced_basic_turns", 0)) != 3: return false
	if bool(lenskaya.get_meta("lenskaya_enhanced_basic_skip_tick", false)): return false

	# Ход 2: остается 2 хода
	bm._process_turn_start_statuses(lenskaya)
	if int(lenskaya.get_meta("lenskaya_enhanced_basic_turns", 0)) != 2: return false

	# Ход 3: остается 1 ход
	bm._process_turn_start_statuses(lenskaya)
	if int(lenskaya.get_meta("lenskaya_enhanced_basic_turns", 0)) != 1: return false

	# Ход 4: статус истекает
	bm._process_turn_start_statuses(lenskaya)
	if lenskaya.has_meta("lenskaya_enhanced_basic_turns"): return false

	return true

func test_15_battle_info_provider_milena_traces_and_skill_text() -> bool:
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)
	var enemy := _create_dummy_enemy(50000.0, 60.0)

	# 1. Текст усиленной базовой атаки
	var eb_text := BattleInfoProvider.get_single_skill_text(lenskaya, "enhanced_basic")
	if not eb_text.begins_with("🏹 [b]Усиленная базовая"): return false
	if not "4 удара" in eb_text: return false

	# 2. Бафф таланта Милены
	lenskaya.set_meta("milena_be_buff", 0.40)
	var buffs := BattleInfoProvider.get_statuses_text(lenskaya, [lenskaya])
	if not "Талант Милены: Эффект пробития повышен на +40%" in buffs: return false

	# 3. Дебафф «По следам воспоминаний» на противнике
	enemy.set_meta("traces_of_memories_turns", 1)
	var debuffs := BattleInfoProvider.get_statuses_text(enemy, [lenskaya])
	if not "По следам воспоминаний (1 х.)" in debuffs: return false

	return true
