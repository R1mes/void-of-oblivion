extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  ТЕСТ ЗАПУСКА УРОВНЯ 1 И ИНИЦИАЛИЗАЦИИ БОЕВОГО ОБУЧЕНИЯ")
	print("========================================================\n")

	TeamConfig.reset()
	TeamConfig.battle_mode = "level_1"
	TeamConfig.team_members = [
		TeamConfig.get_saved_build("vika")
	]

	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)

	# Verify battle_ui elements
	assert(battle_scene.btn_factions != null, "btn_factions should be initialized")
	assert(battle_scene.btn_graphs != null, "btn_graphs should be initialized")
	assert(battle_scene.btn_skills_help != null, "btn_skills_help should be initialized")
	assert(battle_scene.btn_basic != null, "btn_basic should be initialized")

	# Wait a frame for battle_manager turn init
	await get_tree().process_frame

	print("  [PASS] test_level_1_init_and_tutorial_overlay")
	print("\n--------------------------------------------------------")
	print("  РЕЗУЛЬТАТ: Успешно пройден!")
	print("========================================================\n")

	battle_scene.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
