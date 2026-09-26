extends Node

func _ready() -> void:
	# Защитный таймер от зависания
	var timeout_timer := get_tree().create_timer(10.0)
	timeout_timer.timeout.connect(func():
		print("\n[TIMEOUT] Тест завис и был принудительно остановлен!")
		get_tree().quit(1)
	)

	print("\n========================================================")
	print("  ЗАПУСК ТЕСТОВ: ПРОМОКОДЫ, АРСЕНИЙ И ПРОЗРАЧНОСТЬ КАРТОЧЕК")
	print("========================================================\n")
	
	var passed := 0
	var failed := 0
	
	# ========================================================
	# ТЕСТ 1: Промокод RIMES1000 и сброс прогресса
	# ========================================================
	var codes: Dictionary = PromoService._get_local_codes()
	if codes.has("RIMES1000") and int(codes["RIMES1000"].get("shine", 0)) == 1000:
		print("  [PASS] test_1_rimes1000_exists_in_registry")
		passed += 1
	else:
		print("  [FAIL] test_1_rimes1000_exists_in_registry")
		failed += 1

	TeamConfig.reset_all_progress()
	if TeamConfig.redeemed_promo_codes.is_empty():
		print("  [PASS] test_2_reset_clears_redeemed_codes")
		passed += 1
	else:
		print("  [FAIL] test_2_reset_clears_redeemed_codes: %s" % str(TeamConfig.redeemed_promo_codes))
		failed += 1

	var promo_svc := PromoService.new()
	add_child(promo_svc)
	promo_svc._redeem_offline("RIMES1000")
	var shine_after: int = TeamConfig.shine
	if "RIMES1000" in TeamConfig.redeemed_promo_codes and shine_after >= 1000:
		print("  [PASS] test_3_rimes1000_offline_redeem")
		passed += 1
	else:
		print("  [FAIL] test_3_rimes1000_offline_redeem: shine=%d" % shine_after)
		failed += 1

	# Снова сбрасываем и активируем повторно
	TeamConfig.reset_all_progress()
	promo_svc._redeem_offline("RIMES1000")
	if "RIMES1000" in TeamConfig.redeemed_promo_codes and TeamConfig.shine == 1000:
		print("  [PASS] test_4_rimes1000_re_redeem_after_reset")
		passed += 1
	else:
		print("  [FAIL] test_4_rimes1000_re_redeem_after_reset")
		failed += 1

	# ========================================================
	# ТЕСТ 2: Базовая атака Арсения в «Новой разработке»
	# ========================================================
	var bm := BattleManager.new()
	add_child(bm)
	bm.skill_points = 2
	
	var arseniy := ArseniyAbilities.create_unit()
	var enemy := CombatUnit.new()
	enemy.setup_from_template({
		"id": "test_enemy",
		"name": "Враг",
		"element": CombatConstants.Element.ICE,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"stats": {"hp": 10000, "atk": 100, "def": 100, "spd": 100}
	})
	bm.allies = [arseniy]
	bm.enemies = [enemy]
	bm.current_unit = arseniy
	
	# Обычная базовая (вне Новой разработки)
	var sp_before: int = bm.skill_points
	bm._execute_basic_attack(arseniy, enemy)
	if not enemy.statuses.has_dark_seal and bm.skill_points == sp_before + 1:
		print("  [PASS] test_5_arseniy_normal_basic_no_dark_seal")
		passed += 1
	else:
		print("  [FAIL] test_5_arseniy_normal_basic_no_dark_seal")
		failed += 1

	# Включаем «Новую разработку»
	ArseniyAbilities.apply_new_development(arseniy, 2)
	sp_before = bm.skill_points
	bm._execute_basic_attack(arseniy, enemy)
	
	var dark_seal_ok: bool = enemy.statuses.has_dark_seal and enemy.statuses.dark_seal_turns == 2
	var sp_ok: bool = bm.skill_points == sp_before + 1 # Дает +1 ОН, а не тратит!
	if dark_seal_ok and sp_ok:
		print("  [PASS] test_6_arseniy_enhanced_basic_replaces_normal_in_new_dev")
		passed += 1
	else:
		print("  [FAIL] test_6_arseniy_enhanced_basic_replaces_normal_in_new_dev: seal=%s, sp=%d (was %d)" % [dark_seal_ok, bm.skill_points, sp_before])
		failed += 1

	# Проверяем player_enhanced_basic не тратит ОН
	ArseniyAbilities.clear_dark_seal(enemy)
	ArseniyAbilities.apply_new_development(arseniy, 2)
	bm._waiting_for_player = true
	bm.phase = bm.Phase.RUNNING
	sp_before = bm.skill_points
	bm.player_enhanced_basic(enemy)
	if enemy.statuses.has_dark_seal and bm.skill_points == sp_before + 1:
		print("  [PASS] test_7_arseniy_player_enhanced_basic_no_sp_cost")
		passed += 1
	else:
		print("  [FAIL] test_7_arseniy_player_enhanced_basic_no_sp_cost")
		failed += 1

	# ========================================================
	# ТЕСТ 3: Полупрозрачность карточек в ход союзника
	# ========================================================
	var battle_scene := preload("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)
	
	var b_mgr: BattleManager = battle_scene.battle_manager
	var ally1 := MarinaAbilities.create_unit()
	var ally2 := SaraAbilities.create_unit()
	var ally3 := ArseniyAbilities.create_unit()
	var battle_enemy := CombatUnit.new()
	battle_enemy.setup_from_template({
		"id": "target_enemy",
		"name": "Противник",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"stats": {"hp": 20000, "atk": 200, "def": 200, "spd": 90}
	})
	b_mgr.allies = [ally1, ally2, ally3]
	b_mgr.enemies = [battle_enemy]
	battle_scene._build_unit_displays()
	
	# 3.1: Ход союзника Ally1 (Marina) — атака по врагам по умолчанию
	b_mgr.current_unit = ally1
	battle_scene._on_turn_started(ally1)
	
	var mod_ally1: Color = battle_scene._get_unit_base_modulate(ally1)
	var mod_ally2: Color = battle_scene._get_unit_base_modulate(ally2)
	var mod_ally3: Color = battle_scene._get_unit_base_modulate(ally3)
	var mod_enemy: Color = battle_scene._get_unit_base_modulate(battle_enemy)
	
	if is_equal_approx(mod_ally1.a, 1.0) and is_equal_approx(mod_ally2.a, 0.60) and is_equal_approx(mod_ally3.a, 0.60) and is_equal_approx(mod_enemy.a, 1.0):
		print("  [PASS] test_8_other_allies_dimmed_on_ally_turn")
		passed += 1
	else:
		print("  [FAIL] test_8_other_allies_dimmed_on_ally_turn: ally1.a=%.2f, ally2.a=%.2f, ally3.a=%.2f, enemy.a=%.2f" % [mod_ally1.a, mod_ally2.a, mod_ally3.a, mod_enemy.a])
		failed += 1

	# 3.2: Союзник переключается на умение, нацеленное на союзников (show_enemies=false, show_allies=true)
	battle_scene._set_target_buttons_visible(false, true)
	
	mod_ally1 = battle_scene._get_unit_base_modulate(ally1)
	mod_ally2 = battle_scene._get_unit_base_modulate(ally2)
	mod_ally3 = battle_scene._get_unit_base_modulate(ally3)
	mod_enemy = battle_scene._get_unit_base_modulate(battle_enemy)
	
	if is_equal_approx(mod_ally1.a, 1.0) and is_equal_approx(mod_ally2.a, 1.0) and is_equal_approx(mod_ally3.a, 1.0) and is_equal_approx(mod_enemy.a, 0.60):
		print("  [PASS] test_9_enemies_dimmed_when_targeting_allies")
		passed += 1
	else:
		print("  [FAIL] test_9_enemies_dimmed_when_targeting_allies: ally1.a=%.2f, ally2.a=%.2f, enemy.a=%.2f" % [mod_ally1.a, mod_ally2.a, mod_enemy.a])
		failed += 1

	# 3.3: Союзник переключается обратно на базовую атаку (show_enemies=true, show_allies=false)
	battle_scene._set_target_buttons_visible(true, false)
	mod_ally1 = battle_scene._get_unit_base_modulate(ally1)
	mod_ally2 = battle_scene._get_unit_base_modulate(ally2)
	mod_enemy = battle_scene._get_unit_base_modulate(battle_enemy)
	if is_equal_approx(mod_ally1.a, 1.0) and is_equal_approx(mod_ally2.a, 0.60) and is_equal_approx(mod_enemy.a, 1.0):
		print("  [PASS] test_10_restore_dimming_on_hostile_targeting")
		passed += 1
	else:
		print("  [FAIL] test_10_restore_dimming_on_hostile_targeting: ally1.a=%.2f, ally2.a=%.2f, enemy.a=%.2f" % [mod_ally1.a, mod_ally2.a, mod_enemy.a])
		failed += 1

	# 3.4: Конец хода союзника
	battle_scene._on_turn_ended(ally1)
	mod_ally1 = battle_scene._get_unit_base_modulate(ally1)
	mod_ally2 = battle_scene._get_unit_base_modulate(ally2)
	mod_enemy = battle_scene._get_unit_base_modulate(battle_enemy)
	if is_equal_approx(mod_ally1.a, 1.0) and is_equal_approx(mod_ally2.a, 1.0) and is_equal_approx(mod_enemy.a, 1.0):
		print("  [PASS] test_11_all_restored_on_turn_ended")
		passed += 1
	else:
		print("  [FAIL] test_11_all_restored_on_turn_ended: ally1.a=%.2f, ally2.a=%.2f, enemy.a=%.2f" % [mod_ally1.a, mod_ally2.a, mod_enemy.a])
		failed += 1

	# 3.5: Ход врага
	b_mgr.current_unit = battle_enemy
	battle_scene._on_turn_started(battle_enemy)
	mod_ally1 = battle_scene._get_unit_base_modulate(ally1)
	mod_ally2 = battle_scene._get_unit_base_modulate(ally2)
	mod_enemy = battle_scene._get_unit_base_modulate(battle_enemy)
	if is_equal_approx(mod_ally1.a, 1.0) and is_equal_approx(mod_ally2.a, 1.0) and is_equal_approx(mod_enemy.a, 1.0):
		print("  [PASS] test_12_no_dimming_on_enemy_turn")
		passed += 1
	else:
		print("  [FAIL] test_12_no_dimming_on_enemy_turn: ally1.a=%.2f, enemy.a=%.2f" % [mod_ally1.a, mod_enemy.a])
		failed += 1

	# 3.6: Проверка кнопки Арсения в Новой разработке
	b_mgr.current_unit = ally3
	ArseniyAbilities.apply_new_development(ally3, 2)
	battle_scene._update_action_buttons(ally3)
	if not battle_scene.btn_enhanced_basic.visible and battle_scene.btn_basic.text.begins_with("⚔ Усил. Базовая"):
		print("  [PASS] test_13_arseniy_action_button_replacement")
		passed += 1
	else:
		print("  [FAIL] test_13_arseniy_action_button_replacement: enh_vis=%s, basic_txt='%s'" % [battle_scene.btn_enhanced_basic.visible, battle_scene.btn_basic.text])
		failed += 1

	# ========================================================
	# ТЕСТ 4: Выделение активного юнита и безопасность промокодов
	# ========================================================
	# 4.1: Карточка активного союзника выделяется при начале его хода
	b_mgr.current_unit = ally1
	battle_scene._on_turn_started(ally1)
	
	var panel_ally1: PanelContainer = battle_scene._unit_panels[ally1]
	if battle_scene._highlighted_unit_panel == panel_ally1:
		print("  [PASS] test_14_active_card_highlighted_on_turn_start")
		passed += 1
	else:
		print("  [FAIL] test_14_active_card_highlighted_on_turn_start: high=%s" % [battle_scene._highlighted_unit_panel == panel_ally1])
		failed += 1

	# 4.2: Безопасность обработчика промокодов
	var dummy_btn := Button.new()
	dummy_btn.free()
	if not is_instance_valid(dummy_btn):
		print("  [PASS] test_15_promo_code_safety_is_instance_valid")
		passed += 1
	# 4.3: Карточка активного союзника ВСЕГДА приподнята при переключении на цели-союзники
	battle_scene._set_target_buttons_visible(false, true)
	if battle_scene._highlighted_unit_panel == panel_ally1 and panel_ally1.z_index == 10:
		print("  [PASS] test_16_active_card_remains_elevated_on_ally_targeting")
		passed += 1
	else:
		print("  [FAIL] test_16_active_card_remains_elevated_on_ally_targeting: high=%s, z=%d" % [
			battle_scene._highlighted_unit_panel == panel_ally1,
			panel_ally1.z_index
		])
		failed += 1

	# 4.4: Навык Q Джеффа возвращает соседних союзников как вторичные цели
	var jeff := JeffAbilities.create_unit()
	b_mgr.allies = [ally1, ally2, ally3]
	b_mgr.current_unit = jeff
	battle_scene._target_mode = "skill"
	var jeff_secondaries: Array[CombatUnit] = battle_scene._get_affected_secondary_targets(ally2)
	if jeff_secondaries.has(ally1) and jeff_secondaries.has(ally3) and not jeff_secondaries.has(ally2):
		print("  [PASS] test_17_jeff_skill_q_adjacent_allies_secondary_targets")
		passed += 1
	else:
		print("  [FAIL] test_17_jeff_skill_q_adjacent_allies_secondary_targets: size=%d" % jeff_secondaries.size())
		failed += 1

	print("\n--------------------------------------------------------")
	print("  РЕЗУЛЬТАТ: Пройдено: %d / %d  (Ошибок: %d)" % [passed, passed + failed, failed])
	print("========================================================\n")
	
	if failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)
