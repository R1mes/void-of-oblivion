extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  ТЕСТ УРОВНЯ 3 (КАОРИ, ФИЗИЧЕСКОЕ ПРОБИТИЕ)")
	print("========================================================\n")

	TeamConfig.reset()
	TeamConfig.battle_mode = "level_3"
	TeamConfig.team_members = [
		TeamConfig.get_saved_build("kaori"),
		TeamConfig.get_saved_build("danill"),
		TeamConfig.get_saved_build("vika")
	]
	TeamConfig.battle_initiator_id = "kaori"

	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)

	# 1. Проверяем состав отряда и инициализацию врага со стойкостью 90
	assert(battle_scene.battle_manager.allies[0].id == "kaori", "Kaori should be first ally in level 3")
	assert(battle_scene.battle_manager.enemies.size() == 1, "Enemy team should have 1 Elite Guard")
	var elite = battle_scene.battle_manager.enemies[0]
	assert(elite.toughness == 90.0, "Elite Guard toughness should be 90.0 for tutorial level 3")
	assert(elite.max_toughness == 90.0, "Elite Guard max_toughness should be 90.0")
	print("  [PASS] test_level_3_enemy_and_toughness")

	# 2. Проверяем симуляцию шагов 1..3
	assert(LevelManager.tut_step == 1, "Should start at step 1")
	LevelManager.on_action_pressed("factions_toggle", battle_scene)
	assert(LevelManager.tut_step == 2, "Should advance to step 2")
	LevelManager.on_action_pressed("factions_toggle", battle_scene)
	assert(LevelManager.tut_step == 3, "Should advance to step 3")
	LevelManager._on_next_pressed(battle_scene)
	assert(LevelManager.tut_step == 4, "Should advance to step 4")
	print("  [PASS] test_level_3_steps_1_to_4")

	# 3. Проверяем шаг 4 (Каори базовая атака) -> переход к шагу 5
	LevelManager.on_action_pressed("basic", battle_scene)
	LevelManager.on_action_pressed("basic_target_selected", battle_scene)
	await get_tree().create_timer(0.7).timeout
	assert(LevelManager.tut_step == 5, "Should advance to step 5 after Kaori basic attack")
	print("  [PASS] test_level_3_step_5_advancement")

	# 4. Проверяем шаг 5 (Улучшенная базовая) -> переход к шагу 6 (пробитие)
	LevelManager.on_action_pressed("enhanced_basic", battle_scene)
	LevelManager.on_action_pressed("enhanced_basic_target_selected", battle_scene)
	await get_tree().create_timer(0.8).timeout
	assert(LevelManager.tut_step == 6, "Should advance to step 6 (Toughness broken)")
	print("  [PASS] test_level_3_step_6_toughness_broken")

	# 5. Проверяем переход к шагу 7 и финиш
	LevelManager._on_next_pressed(battle_scene)
	assert(LevelManager.tut_step == 7, "Should advance to step 7")
	LevelManager._on_next_pressed(battle_scene)
	assert(LevelManager.is_tutorial == false, "Tutorial should finish at step 7")
	print("  [PASS] test_level_3_finish")

	print("\n--------------------------------------------------------")
	print("  РЕЗУЛЬТАТ: Все тесты уровня 3 успешно пройдены!")
	print("========================================================\n")

	battle_scene.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
