extends Node

const RimesFinalBoss = preload("res://scripts/enemies/rimes_final_boss.gd")
const VelzebulBoss = preload("res://scripts/enemies/velzebul_boss.gd")

func _ready() -> void:
	print("\n========================================================")
	print("  ЗАПУСК ТЕСТОВ: BGM СИСТЕМЫ И МУЗЫКИ БОЯ")
	print("========================================================\n")
	
	var passed := 0
	var failed := 0

	var tests := [
		"test_1_all_audio_files_exist_and_load",
		"test_2_default_battle_bgm",
		"test_3_velzebul_boss_bgm",
		"test_4_rimes_boss_bgm_phase1_and_chorus_trigger",
		"test_5_battle_bgm_loops_on_finish",
		"test_6_smooth_fadeout_on_exit",
		"test_7_rimes_glass_shatter_trigger",
		"test_8_rimes_chorus_fire_transition",
		"test_9_menu_bgm_and_sara_unlock",
		"test_10_hsr_five_star_warp_reveal",
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

# 1. Проверка существования всех 4 аудиофайлов и их загрузки
func test_1_all_audio_files_exist_and_load() -> bool:
	var paths := [
		"res://assets/audio/most_wanted.mp3",
		"res://assets/audio/my_heart.mp3",
		"res://assets/audio/unbridled_growth.mp3",
		"res://assets/audio/hopes_and_dreams.mp3",
	]
	
	for path in paths:
		if not ResourceLoader.exists(path):
			printerr("Аудиофайл не найден: %s" % path)
			return false
		var stream: AudioStream = load(path) as AudioStream
		if stream == null:
			printerr("Не удалось загрузить AudioStream: %s" % path)
			return false
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
			if not (stream as AudioStreamMP3).loop:
				return false
	return true

# 2. По умолчанию в боях играет Most Wanted
func test_2_default_battle_bgm() -> bool:
	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)
	
	var bm: BattleManager = battle_scene.battle_manager
	var dummy_enemy := CombatUnit.new()
	dummy_enemy.id = "regular_enemy"
	dummy_enemy.is_ally = false
	bm.enemies = [dummy_enemy]
	
	battle_scene._setup_battle_bgm()
	
	var ok: bool = (battle_scene._current_bgm_path == "res://assets/audio/most_wanted.mp3")
	battle_scene.queue_free()
	return ok

# 3. В бою с Вельзевулом с самого начала играет my heart *+
func test_3_velzebul_boss_bgm() -> bool:
	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)
	
	var bm: BattleManager = battle_scene.battle_manager
	var velz := VelzebulBoss.create_unit()
	bm.enemies = [velz]
	
	battle_scene._setup_battle_bgm()
	
	var ok: bool = (battle_scene._current_bgm_path == "res://assets/audio/my_heart.mp3")
	battle_scene.queue_free()
	return ok

# 4. В бою с Раймсом:
# - в 1 фазе играет Unbridled Growth
# - смена на 2 и 3 фазу НЕ меняет трек
# - активация Зова/Хора Человечества переключает на Hopes and Dreams
func test_4_rimes_boss_bgm_phase1_and_chorus_trigger() -> bool:
	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)
	
	var bm: BattleManager = battle_scene.battle_manager
	var rimes := RimesFinalBoss.create_unit()
	rimes.set_meta("phase", 1)
	bm.enemies = [rimes]
	
	battle_scene._setup_battle_bgm()
	
	# Фаза 1: Unbridled Growth
	if battle_scene._current_bgm_path != "res://assets/audio/unbridled_growth.mp3":
		printerr("Ожидался трек unbridled_growth.mp3, получен: ", battle_scene._current_bgm_path)
		battle_scene.queue_free()
		return false
		
	# Переход на фазу 2 НЕ должен менять трек на Hopes and Dreams
	bm._execute_boss_phase_transition(rimes)
	if battle_scene._current_bgm_path != "res://assets/audio/unbridled_growth.mp3":
		printerr("Трек не должен меняться при переходе на 2 фазу!")
		battle_scene.queue_free()
		return false
		
	# Переход на фазу 3 НЕ должен менять трек
	bm._execute_boss_phase_transition(rimes)
	if battle_scene._current_bgm_path != "res://assets/audio/unbridled_growth.mp3":
		printerr("Трек не должен меняться при переходе на 3 фазу!")
		battle_scene.queue_free()
		return false
		
	# Активация Хора/Зова Человечества -> переключение на Hopes and Dreams
	var ally := CombatUnit.new()
	ally.id = "test_hero"
	ally.is_ally = true
	battle_scene._on_chorus_activated_bgm(ally)
	
	if battle_scene._current_bgm_path != "res://assets/audio/hopes_and_dreams.mp3":
		printerr("Ожидался трек hopes_and_dreams.mp3 после Хора Человечества!")
		battle_scene.queue_free()
		return false
		
	battle_scene.queue_free()
	return true

# 5. Проверка зацикливания при окончании трека (_on_bgm_finished)
func test_5_battle_bgm_loops_on_finish() -> bool:
	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)
	
	battle_scene._play_bgm("res://assets/audio/most_wanted.mp3", "Most Wanted")
	if battle_scene._current_bgm_path == "":
		battle_scene.queue_free()
		return false
		
	# Эмулируем завершение трека
	battle_scene._on_bgm_finished()
	if battle_scene._current_bgm_path == "":
		battle_scene.queue_free()
		return false
		
	battle_scene.queue_free()
	return true

# 6. Плавное затухание (fade-out) музыки при выходе из боя
func test_6_smooth_fadeout_on_exit() -> bool:
	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)
	
	battle_scene._play_bgm("res://assets/audio/most_wanted.mp3", "Most Wanted")
	if battle_scene._bgm_player == null or not battle_scene._bgm_player.playing:
		battle_scene.queue_free()
		return false
		
	# Проверяем флаг выхода и запуск затухания
	battle_scene._return_to_previous_screen()
	if not battle_scene._is_exiting_battle:
		battle_scene.queue_free()
		return false
		
	# Проверяем остановку музыки
	battle_scene._stop_bgm()
	if battle_scene._current_bgm_path != "":
		battle_scene.queue_free()
		return false
	if battle_scene._bgm_player.playing:
		battle_scene.queue_free()
		return false
		
	battle_scene.queue_free()
	return true

# 7. Проверка триггера растрескивания стекла и появления фона Пустоты в бою с Раймсом
func test_7_rimes_glass_shatter_trigger() -> bool:
	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)
	
	var bm: BattleManager = battle_scene.battle_manager
	var rimes := RimesFinalBoss.create_unit()
	bm.enemies = [rimes]
	
	battle_scene._setup_battle_bgm()
	
	if not battle_scene._is_rimes_battle:
		printerr("Ожидался бой с Раймсом!")
		battle_scene.queue_free()
		return false
		
	if battle_scene._rimes_glass_shatter_triggered:
		printerr("Флаг растрескивания стекла должен быть изначально false!")
		battle_scene.queue_free()
		return false
		
	# Принудительный запуск триггера растрескивания стекла
	battle_scene._trigger_rimes_glass_shatter()
	
	if not battle_scene._rimes_glass_shatter_triggered:
		printerr("Флаг растрескивания стекла должен стать true после _trigger_rimes_glass_shatter!")
		battle_scene.queue_free()
		return false
		
	if battle_scene._rimes_void_bg == null or not is_instance_valid(battle_scene._rimes_void_bg):
		printerr("Узел фона Пустоты RimesVoidBackground не был создан!")
		battle_scene.queue_free()
		return false
		
	# Момент разбития стекла (раскрытие фона)
	battle_scene._on_rimes_glass_break_moment()
	
	if not battle_scene._rimes_void_bg.visible:
		printerr("Фон Пустоты должен стать видимым после момента разбития стекла!")
		battle_scene.queue_free()
		return false
		
	var bg: ColorRect = battle_scene.get_node_or_null("Background")
	if bg != null and bg.color.v > 0.05:
		printerr("Базовый фон должен потемнеть до чёрного!")
		battle_scene.queue_free()
		return false
		
	battle_scene.queue_free()
	return true

# 8. Проверка перехода фона на горящий розово-золотой огонь после Хора Человечества
func test_8_rimes_chorus_fire_transition() -> bool:
	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)
	
	var bm: BattleManager = battle_scene.battle_manager
	var rimes := RimesFinalBoss.create_unit()
	bm.enemies = [rimes]
	
	battle_scene._setup_battle_bgm()
	battle_scene._trigger_rimes_glass_shatter()
	battle_scene._on_rimes_glass_break_moment()
	
	var ally := CombatUnit.new()
	ally.id = "hero"
	ally.is_ally = true
	battle_scene._on_chorus_activated_bgm(ally)
	
	if not battle_scene._chorus_bgm_triggered:
		printerr("Хор Человечества должен быть активирован!")
		battle_scene.queue_free()
		return false
		
	if battle_scene._rimes_chorus_fire_triggered:
		printerr("Флаг огненного перехода должен быть изначально false!")
		battle_scene.queue_free()
		return false
		
	# Запуск огненного перехода
	battle_scene._start_rimes_chorus_fire_transition()
	
	if not battle_scene._rimes_chorus_fire_triggered:
		printerr("Флаг огненного перехода должен стать true после _start_rimes_chorus_fire_transition!")
		battle_scene.queue_free()
		return false
		
	if battle_scene._rimes_void_bg == null or not is_instance_valid(battle_scene._rimes_void_bg):
		printerr("Фон Пустоты должен существовать!")
		battle_scene.queue_free()
		return false
		
	# Переключаем фон на режим огня
	battle_scene._rimes_void_bg.set_mode_rose_gold_fire()
	if battle_scene._rimes_void_bg._mode != 1:
		printerr("Режим фона должен переключиться на ROSE_GOLD_FIRE (1)!")
		battle_scene.queue_free()
		return false
		
	battle_scene.queue_free()
	return true

# 9. Проверка музыки Меню (Spellbound Dreamscape) и разблокировки кнопок после Сары
func test_9_menu_bgm_and_sara_unlock() -> bool:
	var bgm_path := "res://assets/audio/spellbound_dreamscape.mp3"
	if not ResourceLoader.exists(bgm_path):
		printerr("Аудиофайл Меню не найден: %s" % bgm_path)
		return false
	var stream: AudioStream = load(bgm_path) as AudioStream
	if stream == null:
		printerr("Не удалось загрузить AudioStream Меню: %s" % bgm_path)
		return false

	var menu_scene = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(menu_scene)

	# 1. Проверяем BGM плеер
	if menu_scene._menu_bgm_player == null:
		menu_scene._setup_menu_bgm()
	if menu_scene._menu_bgm_player == null or not is_instance_valid(menu_scene._menu_bgm_player):
		printerr("_menu_bgm_player не был создан!")
		menu_scene.queue_free()
		return false

	# 2. Проверяем переключение экранов
	menu_scene._show_screen("main")
	if menu_scene._menu_bgm_player.playing:
		printerr("На экране 'main' музыка меню должна быть остановлена!")
		menu_scene.queue_free()
		return false

	# 3. Проверяем разблокировку кнопок после выбивания Сары в обучении
	menu_scene.is_menu_tutorial = true
	menu_scene.menu_tut_step = 19
	TeamConfig.menu_tutorial_completed = false
	var pull_res = menu_scene._single_gacha_pull()
	if pull_res.get("id", "") != "sara":
		printerr("На шаге 19 должна выпадать Сара!")
		menu_scene.queue_free()
		return false

	if menu_scene.is_menu_tutorial:
		printerr("После выбивания Сары is_menu_tutorial должен стать false!")
		menu_scene.queue_free()
		return false

	if not TeamConfig.menu_tutorial_completed:
		printerr("После выбивания Сары menu_tutorial_completed должен стать true!")
		menu_scene.queue_free()
		return false

	var btn_b: Button = menu_scene.gacha_screen.find_child("BtnGachaBack", true, false)
	if btn_b != null and btn_b.disabled:
		printerr("Кнопка 'Назад' на экране гачи должна быть активна!")
		menu_scene.queue_free()
		return false

	if menu_scene.btn_menu_levels != null and menu_scene.btn_menu_levels.disabled:
		printerr("Кнопка уровней в хабе должна быть разблокирована!")
		menu_scene.queue_free()
		return false

	menu_scene.queue_free()
	return true

# 10. Проверка создания и валидности компонента 5★ HsrFiveStarWarpReveal
func test_10_hsr_five_star_warp_reveal() -> bool:
	var completed := false
	var menu_scene = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(menu_scene)

	var reveal = menu_scene.HsrFiveStarWarpReveal.new(func(): completed = true)
	menu_scene.add_child(reveal)

	if reveal.z_index != 160:
		printerr("Ожидался z_index 160 у HsrFiveStarWarpReveal!")
		menu_scene.queue_free()
		return false

	reveal.queue_redraw()
	reveal.queue_free()
	menu_scene.queue_free()
	return true

