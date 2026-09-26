extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  ЗАПУСК ТЕСТОВ ОГРАНИЧЕНИЯ СВЕТОВЫХ КОНУСОВ И СБРОСА")
	print("========================================================\n")
	
	var passed := 0
	var failed := 0
	
	# ТЕСТ 1: 3★ конусы неограничены ("apocalypse" и "database" - 3★)
	var total_3star: int = TeamConfig.get_light_cone_total_count("database")
	var total_apoc: int = TeamConfig.get_light_cone_total_count("apocalypse")
	if total_3star == 999 and total_apoc == 999:
		print("  [PASS] test_1_3star_unlimited")
		passed += 1
	else:
		print("  [FAIL] test_1_3star_unlimited: database=%d, apocalypse=%d" % [total_3star, total_apoc])
		failed += 1

	# ТЕСТ 2: 4★ и 5★ конусы учитывают точное количество копий ("cant_kill_you" - 5★)
	TeamConfig.unlocked_light_cones = ["cant_kill_you", "cant_kill_you"] # 2 копии
	var total_5star: int = TeamConfig.get_light_cone_total_count("cant_kill_you")
	if total_5star == 2:
		print("  [PASS] test_2_copy_count")
		passed += 1
	else:
		print("  [FAIL] test_2_copy_count: expected 2, got %d" % total_5star)
		failed += 1

	# ТЕСТ 3: Проверка занятости (1 копия)
	TeamConfig.unlocked_light_cones = ["cant_kill_you"] # 1 копия
	TeamConfig.unlocked_characters = ["vika", "marina", "milena"]
	TeamConfig.saved_builds["vika"] = {"light_cone": "cant_kill_you"}
	TeamConfig.saved_builds["marina"] = {"light_cone": ""}
	
	var can_vika: bool = TeamConfig.can_equip_light_cone("vika", "cant_kill_you")
	var can_marina: bool = TeamConfig.can_equip_light_cone("marina", "cant_kill_you")
	if can_vika == true and can_marina == false:
		print("  [PASS] test_3_single_copy_occupancy")
		passed += 1
	else:
		print("  [FAIL] test_3_single_copy_occupancy: vika=%s (exp true), marina=%s (exp false)" % [can_vika, can_marina])
		failed += 1

	# ТЕСТ 4: Проверка занятости (2 копии)
	TeamConfig.unlocked_light_cones = ["cant_kill_you", "cant_kill_you"] # 2 копии
	can_marina = TeamConfig.can_equip_light_cone("marina", "cant_kill_you")
	if can_marina == true:
		print("  [PASS] test_4_two_copies_occupancy")
		passed += 1
	else:
		print("  [FAIL] test_4_two_copies_occupancy: marina should be able to equip 2nd copy")
		failed += 1

	# ТЕСТ 5: Перенос светового конуса с одного персонажа на другого
	TeamConfig.unlocked_light_cones = ["cant_kill_you"] # снова 1 копия
	TeamConfig.equip_light_cone_to_character("marina", "cant_kill_you", "vika")
	var vika_build := TeamConfig.get_saved_build("vika")
	var marina_build := TeamConfig.get_saved_build("marina")
	if vika_build.get("light_cone", "") == "" and marina_build.get("light_cone", "") == "cant_kill_you":
		print("  [PASS] test_5_transfer_light_cone")
		passed += 1
	else:
		print("  [FAIL] test_5_transfer_light_cone: vika=%s, marina=%s" % [vika_build.get("light_cone"), marina_build.get("light_cone")])
		failed += 1

	# ТЕСТ 6: Учёт active_team слотов
	var mock_team: Array = [
		{"id": "marina", "light_cone": "cant_kill_you"},
		{"id": "vika", "light_cone": ""}
	]
	var can_vika_in_team: bool = TeamConfig.can_equip_light_cone("vika", "cant_kill_you", mock_team)
	if can_vika_in_team == false:
		print("  [PASS] test_6_active_team_occupancy")
		passed += 1
	else:
		print("  [FAIL] test_6_active_team_occupancy: expected false because 1 copy is in mock_team")
		failed += 1

	# ТЕСТ 7: Сброс промокодов при полном сбросе прогресса
	TeamConfig.redeemed_promo_codes = ["FREECOINS", "SUPERSTAR"]
	TeamConfig.reset_all_progress()
	if TeamConfig.redeemed_promo_codes.is_empty():
		print("  [PASS] test_7_promo_reset_on_progress_reset")
		passed += 1
	else:
		print("  [FAIL] test_7_promo_reset_on_progress_reset: redeemed_promo_codes not empty")
		failed += 1

	print("\n--------------------------------------------------------")
	print("  РЕЗУЛЬТАТ: Пройдено: %d / %d  (Ошибок: %d)" % [passed, passed + failed, failed])
	print("========================================================\n")
	
	get_tree().quit(0 if failed == 0 else 1)
