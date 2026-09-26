extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  ТЕСТИРОВАНИЕ РЕЖИМА «ТЕСТОВАЯ СРЕДА» (SANDBOX)")
	print("========================================================\n")

	test_ally_100_percent_crit_and_excess_conversion()
	test_mode_boss_setup_and_stats()
	test_mode_trio_setup_and_adjacency()
	test_mode_fiction_reinforcements()
	test_deterministic_rng_seed()
	test_test_environment_crit_display_and_statuses()

	print("\n--------------------------------------------------------")
	print("  РЕЗУЛЬТАТ: Все тесты Тестовой среды успешно пройдены!")
	print("========================================================\n")

	get_tree().quit(0)

func test_ally_100_percent_crit_and_excess_conversion() -> void:
	TeamConfig.reset()
	TeamConfig.is_test_mode_battle = true

	var ally := CombatUnit.new()
	ally.setup_from_template({
		"id": "test_hero",
		"name": "Тест Герой",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.HUNT,
		"is_ally": true,
		"stats": {
			"hp": 3000,
			"atk": 1000,
			"def": 500,
			"spd": 100,
			"crit_rate": 0.50,
			"crit_dmg": 0.50,
		}
	})

	var enemy := TestBoss.create_unit(1500000.0, 1200.0)

	# 1. Проверка гарантированного крита при 50% базового шанса
	var roll := DamageCalculator.roll_crit(ally)
	assert(roll == true, "В Тестовой среде roll_crit для союзника должен возвращать true")

	# 2. Проверка нанесения урона с базовым КШ
	var res1 := DamageCalculator.calc_damage(ally, enemy, 1.0)
	assert(res1.crit == true, "Атака союзника должна гарантированно быть критической")

	# 3. Проверка конвертации избыточного КШ:
	# Добавим союзнику +40% КШ (всего 50% + 40% = 90% -> в Тестовой среде база 100% -> 100% + 40% = 140%).
	# Избыток 40% (0.40) должен дать +60% КУ (0.40 * 1.5 = 0.60).
	ally.stats.crit_rate = 1.40 # 140% КШ
	var res2 := DamageCalculator.calc_damage(ally, enemy, 1.0)
	assert(res2.crit == true, "Атака союзника должна быть критической")
	# Базовый крит_мульт при КУ 50% = 1.50
	# С конвертацией +60% КУ -> крит_мульт = 1.0 + 0.50 + 0.60 = 2.10
	# Урон res2 должен быть больше res1 в 2.10 / 1.50 = 1.4 раза
	var ratio: float = res2.damage / res1.damage
	assert(absf(ratio - (2.10 / 1.50)) < 0.01, "Избыточный КШ должен конвертироваться в КУ в соотношении 1:1.5 (получено соотношение урона: %f)" % ratio)

	print("  [PASS] test_ally_100_percent_crit_and_excess_conversion")

func test_mode_boss_setup_and_stats() -> void:
	TeamConfig.reset()
	TeamConfig.battle_mode = "test_env"
	TeamConfig.is_test_mode_battle = true
	TeamConfig.test_submode = "boss"
	TeamConfig.test_boss_hp = 1500000.0

	var boss := TestBoss.create_unit(TeamConfig.test_boss_hp, 1200.0)
	assert(boss.id == "test_boss", "ID босса должен быть test_boss")
	assert(boss.display_name == "Тест Босс", "Имя босса должно быть Тест Босс")
	assert(boss.stats.max_hp == 1500000.0, "HP босса должно быть 1 500 000")
	assert(boss.stats.def == 1200.0, "Защита босса должна быть 1200")
	assert(boss.stats.effect_res == 0.0, "Сопротивление эффектам босса должно быть 0%")
	assert(boss.weaknesses.size() == 7, "Босс должен иметь все 7 уязвимостей")

	# Проверка одиночной атаки босса (1.5x ATK)
	var ally := CombatUnit.new()
	ally.setup_from_template({
		"id": "hero", "name": "Герой", "element": CombatConstants.Element.ICE,
		"path": CombatConstants.Path.PRESERVATION, "is_ally": true,
		"stats": {"hp": 5000, "atk": 1000, "def": 500, "spd": 100}
	})
	var res_single := DamageCalculator.calc_damage(boss, ally, 1.50)
	assert(res_single.damage > 0.0, "Одиночная атака босса должна наносить урон")

	print("  [PASS] test_mode_boss_setup_and_stats")

func test_mode_trio_setup_and_adjacency() -> void:
	TeamConfig.reset()
	TeamConfig.battle_mode = "test_env"
	TeamConfig.is_test_mode_battle = true
	TeamConfig.test_submode = "trio"
	TeamConfig.test_trio_boss_hp = 1200000.0
	TeamConfig.test_trio_elite_hp = 500000.0

	var elite1 := TestElite.create_unit(TeamConfig.test_trio_elite_hp, 800.0)
	var boss := TestBoss.create_unit(TeamConfig.test_trio_boss_hp, 1200.0)
	var elite2 := TestElite.create_unit(TeamConfig.test_trio_elite_hp, 800.0)

	assert(elite1.stats.def == 800.0, "Защита элиты должна быть 800")
	assert(elite1.stats.effect_res == 0.0, "Сопротивление эффектам элиты должно быть 0%")
	assert(elite1.stats.max_hp == 500000.0, "HP элиты должно быть 500 000")
	assert(boss.stats.max_hp == 1200000.0, "HP босса в режиме трио должно быть 1 200 000")

	# Проверка соседства в BattleManager
	var bm := BattleManager.new()
	bm.enemies = [elite1, boss, elite2]
	var adj := bm.get_adjacent_enemies(boss)
	assert(adj.size() == 2, "У босса должно быть ровно 2 соседа")
	assert(elite1 in adj and elite2 in adj, "Соседями босса должны быть elite1 и elite2")

	print("  [PASS] test_mode_trio_setup_and_adjacency")

func test_mode_fiction_reinforcements() -> void:
	TeamConfig.reset()
	TeamConfig.battle_mode = "test_env"
	TeamConfig.is_test_mode_battle = true
	TeamConfig.test_submode = "fiction"
	TeamConfig.test_fiction_count = 30
	TeamConfig.test_fiction_hp = 70000.0

	var bm := BattleManager.new()
	bm.battle_mode = "test_env"
	bm.fiction_max_pool = TeamConfig.test_fiction_count - 5 # 25 в резерве
	bm.fiction_defeated_count = 0

	for i in 5:
		var s := TestSoldier.create_unit(TeamConfig.test_fiction_hp, 400.0)
		s.slot_index = i
		bm.enemies.append(s)

	assert(bm.enemies.size() == 5, "На поле боя должно быть 5 врагов")
	assert(bm.enemies[0].stats.def == 400.0, "Защита солдата должна быть 400")
	assert(bm.enemies[0].stats.effect_res == 0.0, "Сопротивление эффектам солдата должно быть 0%")
	assert(bm.enemies[0].stats.max_hp == 70000.0, "HP солдата должно быть 70 000")

	# Симулируем гибель врага
	var dead := bm.enemies[0]
	bm._handle_enemy_death_reinforcement(dead)

	assert(bm.fiction_defeated_count == 1, "Счетчик поверженных врагов должен быть 1")
	assert(bm.fiction_max_pool == 24, "В резерве должно остаться 24 врага")
	assert(bm.enemies[0] != dead, "На место погибшего врага должен встать новый")
	assert(bm.enemies[0].stats.max_hp == 70000.0, "Новый враг должен иметь 70 000 HP")
	assert(bm.enemies[0].stats.def == 400.0, "Новый враг должен иметь 400 DEF")

	print("  [PASS] test_mode_fiction_reinforcements")

func test_deterministic_rng_seed() -> void:
	const TEST_ENV_SEED: int = 133742

	var allies_pool: Array[CombatUnit] = []
	for i in 4:
		var u := CombatUnit.new()
		u.id = "hero_%d" % i
		u.display_name = "Герой %d" % i
		allies_pool.append(u)

	# Запуск 1
	seed(TEST_ENV_SEED)
	var targets_run_1: Array[String] = []
	for i in 20:
		var picked: CombatUnit = TestBoss.pick_target(allies_pool)
		targets_run_1.append(picked.id)

	# Запуск 2 (сброс сида в исходное значение)
	seed(TEST_ENV_SEED)
	var targets_run_2: Array[String] = []
	for i in 20:
		var picked: CombatUnit = TestBoss.pick_target(allies_pool)
		targets_run_2.append(picked.id)

	assert(targets_run_1 == targets_run_2, "Выбор целей при одинаковом сиде должен быть на 100% идентичным")

	# Проверка отскоков (bounce)
	seed(TEST_ENV_SEED)
	var bounces_run_1: Array[int] = []
	for i in 20:
		bounces_run_1.append(randi() % 4)

	seed(TEST_ENV_SEED)
	var bounces_run_2: Array[int] = []
	for i in 20:
		bounces_run_2.append(randi() % 4)

	assert(bounces_run_1 == bounces_run_2, "Отскоки при одинаковом сиде должны быть на 100% идентичными")

	print("  [PASS] test_deterministic_rng_seed")

func test_test_environment_crit_display_and_statuses() -> void:
	TeamConfig.reset()
	TeamConfig.is_test_mode_battle = true

	var ally := CombatUnit.new()
	ally.setup_from_template({
		"id": "hero",
		"name": "Герой",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.HUNT,
		"is_ally": true,
		"stats": {
			"hp": 3000, "atk": 1000, "def": 500, "spd": 100,
			"crit_rate": 1.40, # 140% КШ
			"crit_dmg": 0.50, # 50% КУ
		}
	})

	var stats_text := BattleInfoProvider.get_stats_text(ally, [ally])
	assert("Крит: 100% / +110%" in stats_text, "В Тестовой среде КШ должен отображаться строго как 100%, а избыток 40% переходить в +60% КУ")

	var statuses_text := BattleInfoProvider.get_statuses_text(ally, [ally])
	assert("• 🧪 Тестовая среда: КШ зафиксирован на 100% (+40.0% КШ конвертировано в +60.0% КУ)." in statuses_text, "Статус конвертации должен присутствовать в Info панели")

	# Случай без избыточного КШ
	ally.stats.crit_rate = 0.50
	var stats_text_normal := BattleInfoProvider.get_stats_text(ally, [ally])
	assert("Крит: 100% / +50%" in stats_text_normal, "При базовом КШ 50% отображаемый КШ должен быть строго 100%, КУ = +50%")

	var statuses_text_normal := BattleInfoProvider.get_statuses_text(ally, [ally])
	assert("• 🧪 Тестовая среда: Крит. шанс зафиксирован на 100%." in statuses_text_normal, "Статус фиксации 100% КШ должен присутствовать")

	print("  [PASS] test_test_environment_crit_display_and_statuses")
