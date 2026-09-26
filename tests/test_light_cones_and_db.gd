class_name TestLightConesAndDb
extends Node

var tests_passed: int = 0
var tests_failed: int = 0

func _ready() -> void:
	print("==================================================")
	print("--- Running Test Suite: New Light Cones & Database ---")
	print("==================================================")
	
	run_test("test_01_farewell_before_awakening", Callable(self, "test_01_farewell_before_awakening"))
	run_test("test_02_last_summer", Callable(self, "test_02_last_summer"))
	run_test("test_03_alone_again", Callable(self, "test_03_alone_again"))
	run_test("test_04_character_database_and_recommendations", Callable(self, "test_04_character_database_and_recommendations"))

	print("==================================================")
	if tests_failed == 0:
		print(" [PASS] ALL TESTS PASSED (%d/%d)" % [tests_passed, tests_passed + tests_failed])
		get_tree().quit(0)
	else:
		print(" [FAIL] SOME TESTS FAILED (%d failed, %d passed)" % [tests_failed, tests_passed])
		get_tree().quit(1)

func run_test(test_name: String, test_callable: Callable) -> void:
	print("\n>>> Running %s..." % test_name)
	var success: bool = test_callable.call()
	if success:
		print(" [OK] %s PASSED." % test_name)
		tests_passed += 1
	else:
		print(" [ERR] %s FAILED." % test_name)
		tests_failed += 1

func _create_test_battle_manager() -> BattleManager:
	var bm := BattleManager.new()
	bm.allies = []
	bm.enemies = []
	bm.memosprites = []
	return bm

func _create_test_ally(p_id: String = "test_ally", p_name: String = "Тестовый Союзник", p_hp: float = 3000.0, p_atk: float = 1000.0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.id = p_id
	unit.display_name = p_name
	unit.is_ally = true
	unit.element = CombatConstants.Element.PHYSICAL
	unit.path = CombatConstants.Path.HUNT
	unit.stats.max_hp = p_hp
	unit.stats.hp = p_hp
	unit.stats.atk = p_atk
	unit.stats.def = 800.0
	unit.stats.spd = 120.0
	unit.stats.crit_rate = 0.50
	unit.stats.crit_dmg = 1.00
	unit.stats.break_effect = 0.0
	unit.max_energy = 100.0
	unit.energy = 50.0
	unit.set_meta("base_hp_original", p_hp)
	unit.set_meta("base_def_original", 800.0)
	unit.set_meta("base_spd_original", 120.0)
	unit.recalculate_action_value()
	return unit

func _create_test_enemy(p_id: String = "test_enemy", p_name: String = "Тестовый Враг", p_hp: float = 50000.0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.id = p_id
	unit.display_name = p_name
	unit.is_ally = false
	unit.element = CombatConstants.Element.FIRE
	unit.path = CombatConstants.Path.DESTRUCTION
	unit.stats.max_hp = p_hp
	unit.stats.hp = p_hp
	unit.stats.atk = 800.0
	unit.stats.def = 600.0
	unit.stats.spd = 100.0
	unit.max_toughness = 90.0
	unit.toughness = 90.0
	unit.set_meta("base_hp_original", p_hp)
	unit.set_meta("base_def_original", 600.0)
	unit.set_meta("base_spd_original", 100.0)
	return unit

# ------------------------------------------------------------------------------
# TEST 1: «Прощание перед пробуждением» (farewell_before_awakening)
# ------------------------------------------------------------------------------
func test_01_farewell_before_awakening() -> bool:
	var cone := LightConeRegistry.get_cone("farewell_before_awakening")
	if cone.is_empty():
		print("FAIL: farewell_before_awakening not found in LightConeRegistry")
		return false
	if cone.path != CombatConstants.Path.HUNT or cone.rarity != 4:
		print("FAIL: Incorrect path or rarity for farewell_before_awakening: %s, %d" % [cone.path, cone.rarity])
		return false

	var bm := _create_test_battle_manager()
	var ally := _create_test_ally("hunt_unit", "Охотник")
	var enemy := _create_test_enemy("target_mob", "Моб")
	bm.allies.append(ally)
	bm.enemies.append(enemy)

	ally.set_meta("light_cone_id", "farewell_before_awakening")
	bm._init_light_cone_effects(ally)

	# 1. Проверяем +50% эффекта пробития
	if not is_equal_approx(ally.stats.break_effect, 0.50):
		print("FAIL: Break effect should be 0.50, got: %f" % ally.stats.break_effect)
		return false

	# 2. Атака восстанавливает 8 энергии (1 раз за ход)
	var start_energy: float = ally.energy
	bm.current_unit = ally
	bm.deal_damage(enemy, 500.0, ally, ally.element, false, "Basic")
	
	if not is_equal_approx(ally.energy, start_energy + 8.0):
		print("FAIL: Energy after first attack should be %f, got %f" % [start_energy + 8.0, ally.energy])
		return false

	# 3. Вторая атака на том же ходу НЕ должна восстанавливать энергию
	bm.deal_damage(enemy, 500.0, ally, ally.element, false, "Skill")
	if not is_equal_approx(ally.energy, start_energy + 8.0):
		print("FAIL: Second attack on same turn should NOT grant energy, got: %f" % ally.energy)
		return false

	# 4. Начало нового хода сбрасывает ограничение
	bm._process_turn_start_statuses(ally)
	bm.deal_damage(enemy, 500.0, ally, ally.element, false, "Basic")
	if not is_equal_approx(ally.energy, start_energy + 16.0):
		print("FAIL: Attack on next turn should grant 8 energy again, got: %f" % ally.energy)
		return false

	return true

# ------------------------------------------------------------------------------
# TEST 2: «Последнее лето» (last_summer)
# ------------------------------------------------------------------------------
func test_02_last_summer() -> bool:
	var cone := LightConeRegistry.get_cone("last_summer")
	if cone.is_empty():
		print("FAIL: last_summer not found in LightConeRegistry")
		return false
	if cone.path != CombatConstants.Path.HARMONY or cone.rarity != 5:
		print("FAIL: Incorrect path or rarity for last_summer")
		return false

	var bm := _create_test_battle_manager()
	var wearer := _create_test_ally("harmony_unit", "Носитель Лета")
	var ally2 := _create_test_ally("fua_ally", "Союзник FUA")
	var enemy := _create_test_enemy("target_mob", "Моб")
	bm.allies.append(wearer)
	bm.allies.append(ally2)
	bm.enemies.append(enemy)

	wearer.set_meta("light_cone_id", "last_summer")
	bm._init_light_cone_effects(wearer)

	# 1. Проверяем бафф урона FUA владельца (+30%)
	var calc_no_cone: Dictionary = bm.calc_dmg(ally2, enemy, 1.0, 0.0, false, 0.0, 0.0, false, false, "Бонус-атака")
	var calc_with_cone: Dictionary = bm.calc_dmg(wearer, enemy, 1.0, 0.0, false, 0.0, 0.0, false, false, "Бонус-атака")
	if float(calc_with_cone.get("damage", 0.0)) <= float(calc_no_cone.get("damage", 0.0)):
		print("FAIL: Wearer FUA damage should be higher than normal FUA damage")
		return false

	# 2. Нанесение урона FUA владельцем накладывает «Закрой глаза» на 1 ход
	bm.deal_damage(enemy, 500.0, wearer, wearer.element, false, "Бонус-атака")
	if not enemy.has_meta("close_eyes_turns") or int(enemy.get_meta("close_eyes_turns", 0)) != 1:
		print("FAIL: Enemy should have close_eyes_turns == 1, got: %s" % [enemy.get_meta("close_eyes_turns") if enemy.has_meta("close_eyes_turns") else "none"])
		return false

	# 3. Под статусом «Закрой глаза» враг получает +30% урона FUA
	var dmg_before_fua_vuln: float = float(calc_no_cone.get("damage", 0.0))
	var dmg_with_close_eyes: Dictionary = bm.calc_dmg(ally2, enemy, 1.0, 0.0, false, 0.0, 0.0, false, false, "Бонус-атака")
	if float(dmg_with_close_eyes.get("damage", 0.0)) <= dmg_before_fua_vuln:
		print("FAIL: FUA damage on enemy with close_eyes should be increased (+30% vuln)")
		return false

	# 4. Союзники бьют FUA по цели с «Закрой глаза» -> накапливаются стаки постоянной FUA vuln (+3% за удар, до 48%)
	bm.deal_damage(enemy, 500.0, ally2, ally2.element, false, "Бонус-атака")
	var perm1: float = float(enemy.get_meta("close_eyes_perm_fua_vuln", 0.0))
	if not is_equal_approx(perm1, 0.03):
		print("FAIL: Permanent FUA vuln should be 0.03 after 1 ally FUA hit, got: %f" % perm1)
		return false

	# Симулируем 20 ударов для проверки ограничения 48% (0.48)
	for i in range(20):
		bm.deal_damage(enemy, 500.0, ally2, ally2.element, false, "Бонус-атака")
	var perm_max: float = float(enemy.get_meta("close_eyes_perm_fua_vuln", 0.0))
	if not is_equal_approx(perm_max, 0.48):
		print("FAIL: Permanent FUA vuln should cap at 0.48, got: %f" % perm_max)
		return false

	# 5. Окончание статуса «Закрой глаза» НЕ сбрасывает постоянную vuln
	enemy.remove_meta("close_eyes_turns")
	var perm_after_expire: float = float(enemy.get_meta("close_eyes_perm_fua_vuln", 0.0))
	if not is_equal_approx(perm_after_expire, 0.48):
		print("FAIL: Permanent FUA vuln should remain after close_eyes expires, got: %f" % perm_after_expire)
		return false

	return true

# ------------------------------------------------------------------------------
# TEST 3: «И вновь я один» (alone_again)
# ------------------------------------------------------------------------------
func test_03_alone_again() -> bool:
	var cone := LightConeRegistry.get_cone("alone_again")
	if cone.is_empty():
		print("FAIL: alone_again not found in LightConeRegistry")
		return false
	if cone.path != CombatConstants.Path.REMEMBRANCE or cone.rarity != 5:
		print("FAIL: Incorrect path or rarity for alone_again")
		return false

	var bm := _create_test_battle_manager()
	var wearer := _create_test_ally("remembrance_unit", "Носитель Памяти", 3000.0)
	var enemy := _create_test_enemy("target_mob", "Моб")
	bm.allies.append(wearer)
	bm.enemies.append(enemy)

	# 1. Максимальное HP +30%
	wearer.set_meta("light_cone_id", "alone_again")
	bm._init_light_cone_effects(wearer)
	if not is_equal_approx(wearer.stats.max_hp, 3900.0):
		print("FAIL: Max HP with alone_again should be 3900, got: %f" % wearer.stats.max_hp)
		return false

	# 2. Потеря HP во время СВОЕГО хода активирует «Искупление» (2 хода)
	bm.current_unit = wearer
	wearer.stats.hp -= 300.0
	bm.trigger_accepted_sin_hp_loss(wearer, 300.0)
	if not wearer.has_meta("redemption_turns") or int(wearer.get_meta("redemption_turns", 0)) != 2:
		print("FAIL: Wearer should have redemption_turns == 2 after HP loss on own turn")
		return false

	# 3. Под «Искуплением» атакующий игнорирует 30% защиты противников
	var def_mult_normal := DamageCalculator.get_def_multiplier(null, enemy, 0.0)
	var def_mult_redemption := DamageCalculator.get_def_multiplier(wearer, enemy, 0.0)
	if def_mult_redemption <= def_mult_normal:
		print("FAIL: DEF multiplier under redemption should be higher (due to 30% DEF ignore), normal: %f, redemption: %f" % [def_mult_normal, def_mult_redemption])
		return false

	# 4. Использование Сверхспособности продвигает действие на 12%
	var prev_av: float = wearer.action_value
	bm._execute_ultimate(wearer, enemy)
	# advance_action(12.0) уменьшает action_value на 12% от базового интервала
	if wearer.action_value >= prev_av:
		print("FAIL: Action value should decrease (advance) after ultimate with alone_again. prev: %f, now: %f" % [prev_av, wearer.action_value])
		return false

	return true

# ------------------------------------------------------------------------------
# TEST 4: Рекомендации и манекены в базе данных персонажей
# ------------------------------------------------------------------------------
func test_04_character_database_and_recommendations() -> bool:
	var chars_to_test := [
		"sanguinia",
		"lenskaya_sky_guardian",
		"marina_sky_guardian",
		"rimes_ascension"
	]

	var main_menu_script = load("res://scenes/main_menu/main_menu.gd")
	var dummy_main_menu = Control.new()
	dummy_main_menu.set_script(main_menu_script)

	for cid in chars_to_test:
		# 1. Проверяем наличие персонажа в CharacterRegistry
		var char_data := CharacterRegistry.get_character(cid)
		if char_data.is_empty():
			print("FAIL: Character %s not found in CharacterRegistry" % cid)
			dummy_main_menu.free()
			return false

		# 2. Проверяем наличие рекомендаций всех типов через CharacterRegistry
		for rtype in ["allies", "cones", "relics", "tip"]:
			var rec := CharacterRegistry.get_recommendation(cid, rtype)
			if rec.is_empty() or rec == "—":
				print("FAIL: Missing recommendation '%s' for character '%s' in CharacterRegistry" % [rtype, cid])
				dummy_main_menu.free()
				return false

		# 3. Проверяем создание dummy unit для базы данных
		var dummy_unit: CombatUnit = dummy_main_menu._create_dummy_unit_for_db(cid)
		if dummy_unit == null:
			print("FAIL: _create_dummy_unit_for_db returned null for '%s'" % cid)
			dummy_main_menu.free()
			return false

		# 4. Проверяем генерацию текста навыков через BattleInfoProvider
		var skills_text := BattleInfoProvider.get_skills_text(dummy_unit)
		if skills_text.is_empty():
			print("FAIL: BattleInfoProvider returned empty skills text for '%s'" % cid)
			dummy_main_menu.free()
			return false

	dummy_main_menu.free()
	return true
