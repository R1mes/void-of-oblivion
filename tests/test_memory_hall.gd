extends Node

const MemoryHallManager = preload("res://scripts/combat/memory_hall_manager.gd")
const MarinaSkyGuardianAbilities = preload("res://scripts/characters/marina_sky_guardian.gd")
const DashaAbilities = preload("res://scripts/characters/dasha.gd")
const VikaAbilities = preload("res://scripts/characters/vika.gd")

const VelzebulAbilities = preload("res://scripts/characters/velzebul.gd")

func _ready() -> void:
	print("\n========================================================")
	print("  ЗАПУСК ТЕСТОВ: ЗАЛ ВОСПОМИНАНИЙ (MEMORY HALL)")
	print("========================================================\n")

	var passed := 0
	var failed := 0

	var tests := [
		"test_1_season_timer_gmt3",
		"test_2_turbulence_buffs",
		"test_3_floor_enemy_setups_and_scaling",
		"test_4_floor_intel_provider",
		"test_5_star_calculation_floors_1_to_3",
		"test_6_star_calculation_floor_4",
		"test_7_rewards_and_milestones",
		"test_8_save_and_load_persistence",
		"test_9_two_team_duplicate_validation",
		"test_10_battle_manager_wave_advancement",
		"test_11_lenskaya_antimatter_physical_weakness_break",
		"test_12_individual_rewards_and_initiators",
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

# 1. Проверка таймера сезона и конвертации в GMT+3
func test_1_season_timer_gmt3() -> bool:
	if MemoryHallManager.SEASON_1_END_TIMESTAMP != 1793480400:
		print("    FAIL: End timestamp mismatch")
		return false

	var is_active := MemoryHallManager.is_season_active()
	if not is_active:
		print("    FAIL: Season 1 should be active in 2026")
		return false

	var remaining_str := MemoryHallManager.get_season_time_remaining_str()
	if remaining_str.is_empty() or "дн." not in remaining_str:
		print("    FAIL: get_season_time_remaining_str returned '%s'" % remaining_str)
		return false

	var end_gmt3_dict: Dictionary = MemoryHallManager.get_season_end_datetime_gmt3()
	if end_gmt3_dict.get("year", 0) != 2026 or end_gmt3_dict.get("month", 0) != 11 or end_gmt3_dict.get("day", 0) != 1 or end_gmt3_dict.get("hour", -1) != 0:
		print("    FAIL: GMT+3 datetime should be 2026-11-01 00:00:00, got: %s" % str(end_gmt3_dict))
		return false

	return true

# 2. Проверка Турбулентности зала: Небожители +30% урона, Рассвет Хаоса +20% скор.
func test_2_turbulence_buffs() -> bool:
	var bm := BattleManager.new()

	var marina := MarinaSkyGuardianAbilities.create_unit(0) # Небожители
	var dasha := DashaAbilities.create_unit(1) # Рассвет Хаоса
	var velz := VelzebulAbilities.create_unit(2) # Нейтральный персонаж

	bm.allies = [marina, dasha, velz]

	var marina_dmg_before: float = marina.stats.damage_bonus
	var dasha_spd_pct_before: float = float(dasha.stats.get_meta("spd_pct_bonus", 0.0))
	var velz_dmg_before: float = velz.stats.damage_bonus
	var velz_spd_pct_before: float = float(velz.stats.get_meta("spd_pct_bonus", 0.0))

	MemoryHallManager.apply_turbulence(bm)

	if not is_equal_approx(marina.stats.damage_bonus, marina_dmg_before + 0.30):
		print("    FAIL: Marina should receive +0.30 damage_bonus, got %f" % marina.stats.damage_bonus)
		return false

	var dasha_spd_pct_after: float = float(dasha.stats.get_meta("spd_pct_bonus", 0.0))
	if not is_equal_approx(dasha_spd_pct_after, dasha_spd_pct_before + 0.20):
		print("    FAIL: Dasha should receive +0.20 spd_pct_bonus, got %f" % dasha_spd_pct_after)
		return false

	if not is_equal_approx(velz.stats.damage_bonus, velz_dmg_before):
		print("    FAIL: Velzebul should not receive damage bonus")
		return false

	var velz_spd_pct_after: float = float(velz.stats.get_meta("spd_pct_bonus", 0.0))
	if not is_equal_approx(velz_spd_pct_after, velz_spd_pct_before):
		print("    FAIL: Velzebul should not receive spd bonus")
		return false

	return true

# 3. Настройка врагов по этажам и скейлинг ХП (1 легкий, 3 с 2 волнами и повышенным ХП)
func test_3_floor_enemy_setups_and_scaling() -> bool:
	var f1_w1 := MemoryHallManager.get_wave_enemies(1, 1)
	if f1_w1.size() != 4:
		print("    FAIL: Floor 1 Wave 1 should have 4 enemies")
		return false
	var f1_hp: float = f1_w1[0].stats.hp

	var f2_w1 := MemoryHallManager.get_wave_enemies(2, 1)
	var f2_hp: float = f2_w1[0].stats.hp
	if f2_hp <= f1_hp:
		print("    FAIL: Floor 2 HP (%f) should be higher than Floor 1 HP (%f)" % [f2_hp, f1_hp])
		return false

	# Этаж 3: 2 волны
	var f3_w1 := MemoryHallManager.get_wave_enemies(3, 1)
	var f3_w2 := MemoryHallManager.get_wave_enemies(3, 2)
	if f3_w1.is_empty() or f3_w2.is_empty():
		print("    FAIL: Floor 3 must have 2 waves")
		return false
	if f3_w1[0].stats.hp <= f2_hp:
		print("    FAIL: Floor 3 HP should be scaled higher than Floor 2")
		return false

	# Этаж 4: 2 половины по 2 волны
	var f4_h1_w1 := MemoryHallManager.get_wave_enemies(4, 1, 1)
	var f4_h1_w2 := MemoryHallManager.get_wave_enemies(4, 2, 1)
	var f4_h2_w1 := MemoryHallManager.get_wave_enemies(4, 1, 2)
	var f4_h2_w2 := MemoryHallManager.get_wave_enemies(4, 2, 2)
	if f4_h1_w1.is_empty() or f4_h1_w2.is_empty() or f4_h2_w1.is_empty() or f4_h2_w2.is_empty():
		print("    FAIL: Floor 4 must have 2 halves with 2 waves each")
		return false

	return true

# 4. Проверка провайдера разведки этажей
func test_4_floor_intel_provider() -> bool:
	var intel1 := MemoryHallManager.get_floor_intel(1)
	if intel1.get("is_two_teams", true) != false: return false
	if intel1.get("cycles", 0) != 14: return false
	if intel1.get("waves", []).size() != 1: return false

	var intel3 := MemoryHallManager.get_floor_intel(3)
	if intel3.get("waves", []).size() != 2:
		print("    FAIL: Floor 3 intel should report 2 waves")
		return false

	var intel4 := MemoryHallManager.get_floor_intel(4)
	if intel4.get("is_two_teams", false) != true: return false
	if intel4.get("cycles", 0) != 28: return false
	if intel4.get("half1_waves", []).size() != 2 or intel4.get("half2_waves", []).size() != 2:
		return false

	return true

# 5. Расчёт звёзд для этажей 1–3 (лимит 14 циклов)
func test_5_star_calculation_floors_1_to_3() -> bool:
	if MemoryHallManager.calculate_stars(1, 14) != 3: return false
	if MemoryHallManager.calculate_stars(1, 10) != 3: return false
	if MemoryHallManager.calculate_stars(2, 9) != 2: return false
	if MemoryHallManager.calculate_stars(2, 7) != 2: return false
	if MemoryHallManager.calculate_stars(3, 6) != 1: return false
	if MemoryHallManager.calculate_stars(3, 4) != 1: return false
	if MemoryHallManager.calculate_stars(3, 3) != 0: return false
	if MemoryHallManager.calculate_stars(3, 0) != 0: return false
	return true

# 6. Расчёт звёзд для 4 этажа (лимит 28 циклов)
func test_6_star_calculation_floor_4() -> bool:
	if MemoryHallManager.calculate_stars(4, 28) != 3: return false
	if MemoryHallManager.calculate_stars(4, 20) != 3: return false
	if MemoryHallManager.calculate_stars(4, 19) != 2: return false
	if MemoryHallManager.calculate_stars(4, 16) != 2: return false
	if MemoryHallManager.calculate_stars(4, 15) != 1: return false
	if MemoryHallManager.calculate_stars(4, 12) != 1: return false
	if MemoryHallManager.calculate_stars(4, 11) != 0: return false
	if MemoryHallManager.calculate_stars(4, 0) != 0: return false
	return true

# 7. Награды: +5 за каждые 3 звезды (до 20), +4 за 4-й этаж, всего 24
func test_7_rewards_and_milestones() -> bool:
	TeamConfig.reset_all_progress()
	TeamConfig.shine = 0

	# Пока нет звёзд
	if not TeamConfig.claim_memory_hall_rewards().is_empty(): return false

	# 3 звезды (1 этаж на 3★)
	TeamConfig.memory_hall_stars["1"] = 3
	var r1 := TeamConfig.claim_memory_hall_rewards()
	if r1.size() != 1 or TeamConfig.shine != 5:
		print("    FAIL: First 3 stars should award 5 shine, got %s (total shine %d)" % [str(r1), TeamConfig.shine])
		return false

	# Повторный запрос без новых звёзд не даёт награды
	if not TeamConfig.claim_memory_hall_rewards().is_empty(): return false

	# 6 звёзд (2 этаж на 3★)
	TeamConfig.memory_hall_stars["2"] = 3
	var r2 := TeamConfig.claim_memory_hall_rewards()
	if r2.size() != 1 or TeamConfig.shine != 10: return false

	# 9 звёзд (3 этаж на 3★)
	TeamConfig.memory_hall_stars["3"] = 3
	var r3 := TeamConfig.claim_memory_hall_rewards()
	if r3.size() != 1 or TeamConfig.shine != 15: return false

	# 12 звёзд (4 этаж на 3★) + закрытие 4 этажа
	TeamConfig.memory_hall_stars["4"] = 3
	var r4 := TeamConfig.claim_memory_hall_rewards()
	# Должно выдать +5 за 12★ и +4 за 4 этаж = 2 награды, суммарный shine = 24
	if r4.size() != 2 or TeamConfig.shine != 24:
		print("    FAIL: 12 stars + floor 4 clear should award 2 items (total 24), got %s (total %d)" % [str(r4), TeamConfig.shine])
		return false

	if not TeamConfig.is_memory_hall_completed():
		print("    FAIL: is_memory_hall_completed should be true when floor 4 is cleared")
		return false

	return true

# 8. Сохранение и загрузка данных Зала воспоминаний в TeamConfig
func test_8_save_and_load_persistence() -> bool:
	var orig_save_path: String = TeamConfig.save_path
	var test_save_path: String = "res://tests/temp_memory_hall_save.json"
	TeamConfig.save_path = test_save_path

	TeamConfig.reset_all_progress()
	TeamConfig.memory_hall_unlocked_floor = 3
	TeamConfig.memory_hall_stars["1"] = 3
	TeamConfig.memory_hall_stars["2"] = 2
	TeamConfig.memory_hall_claimed_rewards.append("stars_3")
	TeamConfig.memory_hall_team_1 = [{"id": "marina", "slot_idx": 0}]
	TeamConfig.memory_hall_team_2 = [{"id": "velzebul", "slot_idx": 0}]
	TeamConfig.memory_hall_initiator_1 = "marina"
	TeamConfig.memory_hall_initiator_2 = "velzebul"

	var save_ok := TeamConfig.save_game(false)
	if not save_ok:
		print("    FAIL: save_game returned false with path %s, error=%d" % [test_save_path, FileAccess.get_open_error()])
		TeamConfig.save_path = orig_save_path
		return false

	# Очищаем данные в памяти
	TeamConfig.memory_hall_unlocked_floor = 1
	TeamConfig.memory_hall_stars.clear()
	TeamConfig.memory_hall_claimed_rewards.clear()
	TeamConfig.memory_hall_team_1.clear()
	TeamConfig.memory_hall_team_2.clear()

	var load_ok := TeamConfig.load_game()
	if not load_ok:
		print("    FAIL: load_game returned false")
		TeamConfig.save_path = orig_save_path
		return false

	var passed := true
	if TeamConfig.memory_hall_unlocked_floor != 3:
		print("    FAIL: unlocked_floor is %d, expected 3" % TeamConfig.memory_hall_unlocked_floor)
		passed = false
	if TeamConfig.memory_hall_stars.get("1", 0) != 3:
		print("    FAIL: stars '1' is %s, expected 3" % str(TeamConfig.memory_hall_stars.get("1", null)))
		passed = false
	if TeamConfig.memory_hall_stars.get("2", 0) != 2:
		print("    FAIL: stars '2' is %s, expected 2" % str(TeamConfig.memory_hall_stars.get("2", null)))
		passed = false
	if not ("stars_3" in TeamConfig.memory_hall_claimed_rewards):
		print("    FAIL: stars_3 not in claimed_rewards: %s" % str(TeamConfig.memory_hall_claimed_rewards))
		passed = false
	if TeamConfig.memory_hall_team_1.size() != 1 or TeamConfig.memory_hall_team_1[0]["id"] != "marina":
		print("    FAIL: team_1 is %s" % str(TeamConfig.memory_hall_team_1))
		passed = false
	if TeamConfig.memory_hall_team_2.size() != 1 or TeamConfig.memory_hall_team_2[0]["id"] != "velzebul":
		print("    FAIL: team_2 is %s" % str(TeamConfig.memory_hall_team_2))
		passed = false
	if TeamConfig.memory_hall_initiator_1 != "marina":
		print("    FAIL: initiator_1 is %s" % TeamConfig.memory_hall_initiator_1)
		passed = false
	if TeamConfig.memory_hall_initiator_2 != "velzebul":
		print("    FAIL: initiator_2 is %s" % TeamConfig.memory_hall_initiator_2)
		passed = false

	# Очистка временного файла
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	TeamConfig.save_path = orig_save_path
	return passed

# 9. Проверка валидации дубликатов между двумя командами для 4-го этажа
func test_9_two_team_duplicate_validation() -> bool:
	var t1 := [{"id": "marina"}, {"id": "vika"}]
	var t2_invalid := [{"id": "marina"}, {"id": "velzebul"}]
	var t2_valid := [{"id": "pusenkov"}, {"id": "velzebul"}]

	var set1 := {}
	for m in t1: set1[m.id] = true

	var has_dup := false
	for m in t2_invalid:
		if set1.has(m.id):
			has_dup = true
			break
	if not has_dup:
		print("    FAIL: Duplicate detection failed for invalid team")
		return false

	var has_dup_valid := false
	for m in t2_valid:
		if set1.has(m.id):
			has_dup_valid = true
			break
	if has_dup_valid:
		print("    FAIL: False positive duplicate detected for valid team")
		return false

	return true

# 10. Продвижение волн и проверка боевого менеджера
func test_10_battle_manager_wave_advancement() -> bool:
	var bm := BattleManager.new()
	bm.battle_mode = "memory_hall_3"
	bm.memory_hall_floor = 3
	bm.memory_hall_wave = 1
	bm.memory_hall_total_waves = 2

	var wave_advanced_called := [false]
	bm.memory_hall_wave_advanced.connect(func(w_num: int, total_w: int):
		wave_advanced_called[0] = true
	)

	# Имитируем поражение врагов волны 1 (hp = 0)
	var dummy_enemy := CombatUnit.new()
	dummy_enemy.id = "dummy"
	dummy_enemy.stats.max_hp = 1000.0
	dummy_enemy.stats.hp = 0.0
	bm.enemies = [dummy_enemy]

	var dummy_ally := CombatUnit.new()
	dummy_ally.id = "ally"
	dummy_ally.stats.max_hp = 1000.0
	dummy_ally.stats.hp = 1000.0
	bm.allies = [dummy_ally]

	var res := bm._check_battle_end()

	if not wave_advanced_called[0]:
		print("    FAIL: memory_hall_wave_advanced signal should be emitted")
		return false

	if bm.memory_hall_wave != 2:
		print("    FAIL: Wave should be 2 after advancing, got %d" % bm.memory_hall_wave)
		return false

	if bm.enemies.is_empty():
		print("    FAIL: Wave 2 enemies should have spawned")
		return false

	return true

# 11. Ленская • Явление антиматерии вне формы снижает физическую стойкость и накладывает Кровотечение
func test_11_lenskaya_antimatter_physical_weakness_break() -> bool:
	var LenskayaAm = preload("res://scripts/characters/lenskaya_antimatter.gd")
	var bm := BattleManager.new()

	var lenskaya: CombatUnit = LenskayaAm.create_unit(0)
	var enemy := CombatUnit.new()
	enemy.setup_from_template({
		"id": "phys_target",
		"name": "Физическая цель",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"toughness": 60.0,
		"weaknesses": [CombatConstants.Element.PHYSICAL], # Только Физическая уязвимость (НЕ Квант!)
		"stats": {"hp": 10000.0, "atk": 100.0, "def": 100.0, "spd": 100.0}
	})
	enemy.max_toughness = 60.0
	enemy.toughness = 60.0

	bm.allies = [lenskaya]
	bm.enemies = [enemy]

	if enemy.toughness != 60.0:
		print("    FAIL: Target toughness should start at 60.0")
		return false

	# Базовая атака вне формы (наносит физ. урон)
	LenskayaAm.execute_basic_attack(lenskaya, enemy, bm)

	if enemy.toughness >= 60.0:
		print("    FAIL: Lenskaya AM outside form should reduce Physical toughness, but toughness remains %f" % enemy.toughness)
		return false

	# Вторая базовая атака пробивает стойкость
	LenskayaAm.execute_basic_attack(lenskaya, enemy, bm)

	if enemy.toughness > 0.0:
		print("    FAIL: Toughness should be 0.0 after 2 hits, got %f" % enemy.toughness)
		return false

	if not enemy.statuses.toughness_broken:
		print("    FAIL: Toughness should be broken")
		return false

	if enemy.statuses.break_status != "Кровотечение":
		print("    FAIL: Break status for physical break should be 'Кровотечение', got '%s'" % enemy.statuses.break_status)
		return false

	return true

# 12. Проверка индивидуального сбора наград и фильтрации атакующих техник
func test_12_individual_rewards_and_initiators() -> bool:
	# Атакующие техники
	if not MemoryHallManager.has_attack_technique("vika"):
		print("    FAIL: Vika should have attack technique")
		return false
	if not MemoryHallManager.has_attack_technique("lenskaya_antimatter"):
		print("    FAIL: Lenskaya AM should have attack technique")
		return false
	if MemoryHallManager.has_attack_technique("marina"):
		print("    FAIL: Base Marina has support technique, not attack technique")
		return false
	if MemoryHallManager.has_attack_technique("danill"):
		print("    FAIL: Danill has support technique, not attack technique")
		return false

	# Индивидуальный сбор наград
	TeamConfig.reset_all_progress()
	TeamConfig.shine = 0
	TeamConfig.memory_hall_stars["1"] = 3 # 3 звезды на 1 этаже

	if not TeamConfig.can_claim_memory_hall_reward("stars_3"):
		print("    FAIL: stars_3 should be claimable")
		return false
	if TeamConfig.can_claim_memory_hall_reward("stars_6"):
		print("    FAIL: stars_6 should NOT be claimable with only 3 stars")
		return false

	var res := TeamConfig.claim_single_memory_hall_reward("stars_3")
	if res.is_empty() or TeamConfig.shine != 5:
		print("    FAIL: Claiming stars_3 should grant 5 shine, got %s, shine=%d" % [str(res), TeamConfig.shine])
		return false

	# Повторный запрос недоступен
	if TeamConfig.can_claim_memory_hall_reward("stars_3"):
		print("    FAIL: stars_3 should no longer be claimable after claiming")
		return false

	return true

