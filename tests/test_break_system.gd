extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  ЗАПУСК ТЕСТОВ: ПРОБИТИЕ И СУПЕРПРОБИТИЕ (BREAK & SUPER BREAK)")
	print("========================================================\n")
	
	var passed := 0
	var failed := 0

	var tests := [
		"test_1_base_break_damage_elements_and_toughness",
		"test_2_break_damage_full_formula_multipliers",
		"test_3_super_break_damage_base_and_scaling",
		"test_4_super_break_weakness_efficiency_and_ability_mult",
		"test_5_super_break_lenskaya_trace3_boost",
		"test_6_toughness_system_break_integration",
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

func _create_test_unit(elem: int, be: float = 0.0) -> CombatUnit:
	var u := CombatUnit.new()
	u.id = "test_attacker"
	u.display_name = "Тестовый атакующий"
	u.is_ally = true
	u.element = elem
	u.stats.hp = 3000.0
	u.stats.max_hp = 3000.0
	u.stats.atk = 2000.0
	u.stats.def = 800.0
	u.stats.spd = 120.0
	u.stats.break_effect = be
	return u

func _create_dummy_enemy(toughness: float = 60.0) -> CombatUnit:
	var enemy := CombatUnit.new()
	enemy.id = "dummy_enemy"
	enemy.display_name = "Манекен"
	enemy.is_ally = false
	enemy.stats.hp = 50000.0
	enemy.stats.max_hp = 50000.0
	enemy.stats.atk = 500.0
	enemy.stats.def = 200.0
	enemy.stats.spd = 100.0
	enemy.max_toughness = toughness
	enemy.toughness = toughness
	enemy.weaknesses = [
		CombatConstants.Element.PHYSICAL,
		CombatConstants.Element.FIRE,
		CombatConstants.Element.WIND,
		CombatConstants.Element.LIGHTNING,
		CombatConstants.Element.ICE,
		CombatConstants.Element.QUANTUM,
		CombatConstants.Element.IMAGINARY,
	]
	return enemy

func test_1_base_break_damage_elements_and_toughness() -> bool:
	var dummy := _create_dummy_enemy(60.0) # toughness mult = 0.5 + 60/120 = 1.0

	var phys := _create_test_unit(CombatConstants.Element.PHYSICAL)
	var fire := _create_test_unit(CombatConstants.Element.FIRE)
	var wind := _create_test_unit(CombatConstants.Element.WIND)
	var lightning := _create_test_unit(CombatConstants.Element.LIGHTNING)
	var ice := _create_test_unit(CombatConstants.Element.ICE)
	var quantum := _create_test_unit(CombatConstants.Element.QUANTUM)
	var imag := _create_test_unit(CombatConstants.Element.IMAGINARY)

	# 1640 * mult * 1.0
	if absf(DamageCalculator.calc_raw_break_damage(phys, dummy) - 3280.0) > 0.01: return false
	if absf(DamageCalculator.calc_raw_break_damage(fire, dummy) - 3280.0) > 0.01: return false
	if absf(DamageCalculator.calc_raw_break_damage(wind, dummy) - 2460.0) > 0.01: return false
	if absf(DamageCalculator.calc_raw_break_damage(lightning, dummy) - 1640.0) > 0.01: return false
	if absf(DamageCalculator.calc_raw_break_damage(ice, dummy) - 1640.0) > 0.01: return false
	if absf(DamageCalculator.calc_raw_break_damage(quantum, dummy) - 820.0) > 0.01: return false
	if absf(DamageCalculator.calc_raw_break_damage(imag, dummy) - 820.0) > 0.01: return false

	# Toughness scaling: max_toughness = 120 -> mult = 0.5 + 1.0 = 1.5
	var big_dummy := _create_dummy_enemy(120.0)
	if absf(DamageCalculator.calc_raw_break_damage(phys, big_dummy) - 4920.0) > 0.01: return false

	return true

func test_2_break_damage_full_formula_multipliers() -> bool:
	var dummy := _create_dummy_enemy(60.0)
	var phys := _create_test_unit(CombatConstants.Element.PHYSICAL, 0.0)

	# Базовый урон = 3280.
	# DEF mult = 100 / (100 + 100) = 0.5
	# RES mult = 1.0
	# Vuln = 1.0, DmgRed = 1.0, broken_mult = 0.9
	# Итого: 3280 * 0.5 * 0.9 = 1476.0
	var dmg_base := DamageCalculator.calc_break_damage(phys, dummy)
	if absf(dmg_base - 1476.0) > 0.01: return false

	# С эффектом пробития 100% (1.0): урон должен удвоиться (2952.0)
	phys.stats.break_effect = 1.0
	var dmg_be := DamageCalculator.calc_break_damage(phys, dummy)
	if absf(dmg_be - 2952.0) > 0.01: return false

	# Со срезом защиты 20%: DEF mult = 100 / (100 * 0.8 + 100) = 100 / 180 = 5/9
	# Итого: 3280 * 2.0 * (5/9) * 0.9 = 3280.0
	dummy.set_meta("def_reductions", {"test_shred": {"percent": 0.20, "turns": 2}})
	var dmg_shred := DamageCalculator.calc_break_damage(phys, dummy)
	if absf(dmg_shred - 3280.0) > 0.05: return false

	# С уязвимостью +30% (например, Враг Свечения)
	dummy.set_meta("lenskaya_radiance_enemy_turns", 3)
	var dmg_vuln := DamageCalculator.calc_break_damage(phys, dummy)
	if absf(dmg_vuln - (3280.0 * 1.30)) > 0.05: return false

	return true

func test_3_super_break_damage_base_and_scaling() -> bool:
	var dummy := _create_dummy_enemy(60.0)
	var unit := _create_test_unit(CombatConstants.Element.IMAGINARY, 0.0)

	# 10 истощения стойкости, BE = 0%:
	# (10 / 10) * 1640 * 1.0 * (1 + 0) * (1 + 0) * (1 + 0) * 0.5 * 1.0 * 1.0 * 1.0 = 820.0
	var sb_10 := DamageCalculator.calc_super_break_damage(unit, dummy, 10.0)
	if absf(sb_10 - 820.0) > 0.01: return false

	# 30 истощения стойкости, BE = 150% (1.50):
	# (30 / 10) * 1640 * 1.0 * 2.5 * 0.5 = 6150.0
	unit.stats.break_effect = 1.50
	var sb_30 := DamageCalculator.calc_super_break_damage(unit, dummy, 30.0)
	if absf(sb_30 - 6150.0) > 0.01: return false

	# Независимость от максимальной стойкости цели: цель со стойкостью 200 должна получать ТОТ ЖЕ урон
	var boss_dummy := _create_dummy_enemy(200.0)
	var sb_boss := DamageCalculator.calc_super_break_damage(unit, boss_dummy, 30.0)
	if absf(sb_boss - sb_30) > 0.01: return false

	return true

func test_4_super_break_weakness_efficiency_and_ability_mult() -> bool:
	var dummy := _create_dummy_enemy(60.0)
	var unit := _create_test_unit(CombatConstants.Element.IMAGINARY, 1.0) # BE = 100%

	# База при 10 истощения стойкости: (10 / 10) * 1640 * 2.0 * 0.5 = 1640.0
	var sb_base := DamageCalculator.calc_super_break_damage(unit, dummy, 10.0)
	if absf(sb_base - 1640.0) > 0.01: return false

	# Эффективность пробития +50%: истощение стойкости масштабируется в 1.5 раза
	unit.stats.weakness_efficiency = 0.50
	var sb_eff := DamageCalculator.calc_super_break_damage(unit, dummy, 10.0)
	if absf(sb_eff - (1640.0 * 1.50)) > 0.01: return false
	unit.stats.weakness_efficiency = 0.0

	# Множитель способности (например, конверсия 60% таланта Ленской)
	var sb_ability := DamageCalculator.calc_super_break_damage(unit, dummy, 10.0, 0.60)
	if absf(sb_ability - (1640.0 * 0.60)) > 0.01: return false

	return true

func test_5_super_break_lenskaya_trace3_boost() -> bool:
	var dummy := _create_dummy_enemy(60.0)
	var lenskaya := LenskayaSkyGuardianAbilities.create_unit(0)

	var normal_sb := DamageCalculator.calc_super_break_damage(lenskaya, dummy, 10.0)
	lenskaya.set_meta("is_enhanced_basic", true)
	var enh_sb := DamageCalculator.calc_super_break_damage(lenskaya, dummy, 10.0)
	lenskaya.remove_meta("is_enhanced_basic")

	if enh_sb <= normal_sb: return false
	# Должно быть ровно +30% (множитель 1.30)
	if absf((enh_sb / normal_sb) - 1.30) > 0.01: return false

	return true

func test_6_toughness_system_break_integration() -> bool:
	var bm := BattleManager.new()
	var attacker := _create_test_unit(CombatConstants.Element.PHYSICAL, 0.50) # BE = 50%
	var target := _create_dummy_enemy(30.0)
	bm.allies.append(attacker)
	bm.enemies.append(target)

	var initial_hp := target.stats.hp
	# Снимаем 30 стойкости -> пробитие уязвимости
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)

	if target.toughness > 0.0: return false
	if not target.statuses.toughness_broken: return false

	# Урон пробития нанесен врагу:
	var dealt := initial_hp - target.stats.hp
	# Базовый урон при 30 стойкости: 1640 * 2.0 * (0.5 + 30/120) = 3280 * 0.75 = 2460.0
	# С BE 50%: 2460 * 1.5 = 3690.0
	# DEF mult = 0.5, broken = 0.9: 3690 * 0.5 * 0.9 = 1660.5
	if absf(dealt - 1660.5) > 1.0: return false

	return true
