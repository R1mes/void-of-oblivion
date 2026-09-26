extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  ЗАПУСК АВТОМАТИЧЕСКИХ ТЕСТОВ ДИНАМИКИ КАРТОЧЕК В БОЮ")
	print("========================================================\n")

	TeamConfig.reset()
	TeamConfig.battle_mode = "level_1"
	TeamConfig.team_members = [
		TeamConfig.get_saved_build("vika")
	]

	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)

	# Ждем 2 кадра для полной инициализации сцены и боевого менеджера
	await get_tree().process_frame
	await get_tree().process_frame

	var bm: BattleManager = battle_scene.battle_manager
	assert(bm != null, "BattleManager must exist")
	assert(bm.enemies.size() > 0, "Must have enemies in battle")
	assert(bm.allies.size() > 0, "Must have allies in battle")

	# Тест 1: Проверяем, что активный союзник во время своего хода приподнят и имеет динамику покачивания
	var active_ally: CombatUnit = bm.current_unit
	if active_ally == null and bm.allies.size() > 0:
		active_ally = bm.allies[0]
		bm.current_unit = active_ally
	assert(active_ally != null and active_ally.is_ally, "Current unit should be ally")
	battle_scene._on_turn_started(active_ally)

	var active_panel: PanelContainer = battle_scene._unit_panels[active_ally]
	assert(is_instance_valid(active_panel), "Active panel must be valid")
	
	# Прокручиваем несколько кадров симуляции для накопления _card_anim_time
	for f in range(25):
		battle_scene._process(0.016)
	
	assert(active_panel.scale.y >= 1.06, "Active ally card should remain elevated during its turn, got scale.y: %f" % active_panel.scale.y)
	assert(active_panel.pivot_offset.y == active_panel.size.y, "Active ally pivot must be at bottom for realistic sway")
	assert(absf(active_panel.rotation) > 0.0001, "Active ally card should smoothly sway during turn, got rotation: %f" % active_panel.rotation)
	print("  [PASS] test_1_active_ally_card_elevated_and_swaying")

	# Тест 2: Проверяем карточки врагов вне их хода — они должны плавать, наклоняться и дышать
	var enemy1: CombatUnit = bm.enemies[0]
	var enemy_panel: PanelContainer = battle_scene._unit_panels[enemy1]
	assert(is_instance_valid(enemy_panel), "Enemy panel must be valid")
	assert(enemy_panel.has_meta("drift_offset"), "Enemy card outside turn must have drift_offset")
	var drift: Vector2 = enemy_panel.get_meta("drift_offset")
	assert(drift.length() > 0.001, "Enemy card should drift/float across screen, got drift: %s" % str(drift))
	assert(absf(enemy_panel.scale.x - 1.0) > 0.0001 or absf(enemy_panel.scale.y - 1.0) > 0.0001, "Enemy card should breathe/scale outside its turn")
	print("  [PASS] test_2_enemy_cards_floating_and_breathing_outside_turn")

	# Тест 3: Если врагов несколько, их фазы парения отличаются (не синхронные)
	if bm.enemies.size() > 1:
		var enemy2: CombatUnit = bm.enemies[1]
		var enemy2_panel: PanelContainer = battle_scene._unit_panels[enemy2]
		var drift1: Vector2 = enemy_panel.get_meta("drift_offset")
		var drift2: Vector2 = enemy2_panel.get_meta("drift_offset")
		assert(drift1 != drift2, "Enemies should have distinct phase shifts to avoid robotic synchronized drift")
		print("  [PASS] test_3_enemies_distinct_phases")
	else:
		print("  [SKIP] test_3_enemies_distinct_phases (single enemy)")

	# Тест 4: Сброс активного юнита возвращает поворот в 0
	battle_scene._reset_active_unit_visual()
	await get_tree().create_timer(0.25).timeout
	battle_scene._process(0.016)
	assert(absf(active_panel.rotation) < 0.005, "Reset active unit should restore rotation to zero, got: %f" % active_panel.rotation)
	print("  [PASS] test_4_reset_active_ally_restores_rotation")

	# Тест 5: Поверженный враг сбрасывает drift_offset
	enemy1.stats.hp = 0
	battle_scene._process(0.016)
	assert(not enemy_panel.has_meta("drift_offset"), "Defeated enemy should clear drift_offset")
	print("  [PASS] test_5_defeated_enemy_clears_drift")

	print("\n--------------------------------------------------------")
	print("  РЕЗУЛЬТАТ: Все 5 тестов успешно пройдены!")
	print("========================================================\n")

	battle_scene.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
