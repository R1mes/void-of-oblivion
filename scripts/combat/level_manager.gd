class_name LevelManager
extends RefCounted

## Модуль управления Уровнями, Обучением и Сюжетными Встречами.

static var current_level_id: String = ""
static var is_tutorial: bool = false
static var tut_step: int = 0

# UI-элементы обучения
static var tut_overlay: ColorRect
static var tut_panel: PanelContainer
static var tut_label: RichTextLabel
static var tut_next_btn: Button
static var tut_pointer: Label

# --- 1. ИНИЦИАЛИЗАЦИЯ И НАСТРОЙКА УРОВНЕЙ ---

static func setup_level_battle(level_id: String, bm: BattleManager) -> void:
	current_level_id = level_id
	is_tutorial = true
	tut_step = 1
	TeamConfig.enemy_members.clear()
	
	if level_id.begins_with("dungeon_") or level_id.begins_with("planar_"):
		is_tutorial = false
		tut_step = 0
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		
		var player_lvl: int = TeamConfig.current_level_progress
		var is_planar: bool = level_id.begins_with("planar_")
		
		# Градация сложности по уровням игрока:
		# - до 15 уровня: легче базовой сложности (45% ХП и АТК)
		# - с 15 до 24 уровня: сложнее, чем до 15 (75% ХП и АТК)
		# - с 25 уровня: стандартная сложность (100% ХП и АТК)
		var hp_scale := 1.0
		var atk_scale := 1.0
		if player_lvl < 15:
			hp_scale = 0.45
			atk_scale = 0.45
		elif player_lvl < 25:
			hp_scale = 0.75
			atk_scale = 0.75
		else:
			hp_scale = 1.0
			atk_scale = 1.0
			
		# Планарные пещеры сложнее пещерных (там боссы + множитель прочности)
		if is_planar:
			hp_scale *= 1.25
			atk_scale *= 1.15
		
		match level_id:
			# --- ПЕЩЕРНЫЕ ПОДЗЕМЕЛЬЯ (ТОЛЬКО ОБЫЧНЫЕ И ЭЛИТНЫЕ ВРАГИ, БЕЗ БОССОВ) ---
			"dungeon_academy":
				var elite: CombatUnit = VoidElite.create_unit()
				elite.display_name = "Элитный Страж"
				elite.stats.max_hp = 85000.0 * hp_scale
				elite.stats.hp = elite.stats.max_hp
				elite.stats.atk = 2200.0 * atk_scale
				bm.enemies.append(elite)
				
				for i in 2:
					var soldier: CombatUnit = VoidSoldier.create_unit()
					soldier.display_name = "Солдат Пустоты %d" % (i + 1)
					soldier.stats.max_hp = 35000.0 * hp_scale
					soldier.stats.hp = soldier.stats.max_hp
					soldier.stats.atk = 1600.0 * atk_scale
					bm.enemies.append(soldier)
				bm.log_message("🏛 Академия | Аномалия «Симбиоз Нуля и Хаоса»: Ледяной и Квантовый урон +30%, урон по замороженным и пробитым целям +40%!")

			"dungeon_hq":
				var arm: CombatUnit = VoidArmored.create_unit()
				arm.display_name = "Бронированный Рыцарь"
				arm.stats.max_hp = 90000.0 * hp_scale
				arm.stats.hp = arm.stats.max_hp
				arm.stats.atk = 2100.0 * atk_scale
				bm.enemies.append(arm)
				
				for i in 2:
					var soldier: CombatUnit = VoidSoldier.create_unit()
					soldier.display_name = "Солдат Пустоты %d" % (i + 1)
					soldier.stats.max_hp = 35000.0 * hp_scale
					soldier.stats.hp = soldier.stats.max_hp
					soldier.stats.atk = 1600.0 * atk_scale
					bm.enemies.append(soldier)
				bm.log_message("🏢 Штаб | Аномалия «Лавовый отпор»: Огненный и Физ. урон +30%, пробитие уязвимости накладывает Горение (100% СА)!")

			"dungeon_kitchens":
				var elite: CombatUnit = VoidElite.create_unit()
				elite.display_name = "Элитный Страж"
				elite.stats.max_hp = 85000.0 * hp_scale
				elite.stats.hp = elite.stats.max_hp
				elite.stats.atk = 2100.0 * atk_scale
				bm.enemies.append(elite)
				
				for i in 2:
					var inf: CombatUnit = Infected.create_unit()
					inf.display_name = "Заражённый %d" % (i + 1)
					inf.stats.max_hp = 40000.0 * hp_scale
					inf.stats.hp = inf.stats.max_hp
					inf.stats.atk = 1600.0 * atk_scale
					bm.enemies.append(inf)
				bm.log_message("🍳 Район «TheКухни» | Аномалия «Световой резонанс»: Электро и Мнимый урон +30%, Навыки лечат 12% макс. ХП и дают +20% СА на 1 ход!")

			"dungeon_dam":
				var elite: CombatUnit = VoidElite.create_unit()
				elite.display_name = "Элитный Страж"
				elite.stats.max_hp = 85000.0 * hp_scale
				elite.stats.hp = elite.stats.max_hp
				elite.stats.atk = 2200.0 * atk_scale
				bm.enemies.append(elite)

				var infected: CombatUnit = Infected.create_unit()
				infected.display_name = "Заражённый"
				infected.stats.max_hp = 45000.0 * hp_scale
				infected.stats.hp = infected.stats.max_hp
				infected.stats.atk = 1700.0 * atk_scale
				bm.enemies.append(infected)
				bm.log_message("🌊 Дмитриевская дамба | Аномалия «Стремительный поток»: Ветер +30% урона, Ульты продвигают ход на 30%, лечение дает +20% урона на 2 хода!")

			"dungeon_dawn_chaos":
				var arm: CombatUnit = VoidArmored.create_unit()
				arm.display_name = "Бронированный Рыцарь"
				arm.stats.max_hp = 90000.0 * hp_scale
				arm.stats.hp = arm.stats.max_hp
				arm.stats.atk = 2100.0 * atk_scale
				bm.enemies.append(arm)
				
				for i in 2:
					var inf: CombatUnit = Infected.create_unit()
					inf.display_name = "Заражённый %d" % (i + 1)
					inf.stats.max_hp = 40000.0 * hp_scale
					inf.stats.hp = inf.stats.max_hp
					inf.stats.atk = 1600.0 * atk_scale
					bm.enemies.append(inf)
				bm.log_message("⚔ Штаб «Рассвета хаоса» | Аномалия «Эгида и Тлен»: Персонажи под щитами получают +30% СА, каждый DoT на враге снижает защиту на 5% (до 30%)!")

			"dungeon_as_house":
				var elite: CombatUnit = VoidElite.create_unit()
				elite.display_name = "Элитный Страж"
				elite.stats.max_hp = 85000.0 * hp_scale
				elite.stats.hp = elite.stats.max_hp
				elite.stats.atk = 2200.0 * atk_scale
				bm.enemies.append(elite)
				
				for i in 2:
					var soldier: CombatUnit = VoidSoldier.create_unit()
					soldier.display_name = "Солдат Пустоты %d" % (i + 1)
					soldier.stats.max_hp = 35000.0 * hp_scale
					soldier.stats.hp = soldier.stats.max_hp
					soldier.stats.atk = 1600.0 * atk_scale
					bm.enemies.append(soldier)
				for ally in bm.allies:
					ally.stats.crit_dmg += 0.25
				bm.log_message("🏠 Дом А.С. | Аномалия «Театр Силуэтов»: Урон бонус-атак +50%, Крит. урон отряда +25%!")

			"dungeon_slums_apt":
				var arm: CombatUnit = VoidArmored.create_unit()
				arm.display_name = "Бронированный Рыцарь"
				arm.stats.max_hp = 90000.0 * hp_scale
				arm.stats.hp = arm.stats.max_hp
				arm.stats.atk = 2100.0 * atk_scale
				bm.enemies.append(arm)
				
				for i in 2:
					var inf: CombatUnit = Infected.create_unit()
					inf.display_name = "Заражённый %d" % (i + 1)
					inf.stats.max_hp = 42000.0 * hp_scale
					inf.stats.hp = inf.stats.max_hp
					inf.stats.atk = 1650.0 * atk_scale
					bm.enemies.append(inf)
				bm.log_message("🏚 Квартира посреди Трущоб | Аномалия «Принятие Греха»: Смена ХП союзника (потеря или лечение) дает +15% КШ и +30% урона на 2 хода (до 2 стаков)!")

			# --- ПЛАНАРНЫЕ ПОДЗЕМЕЛЬЯ (С БОССАМИ — ПОВЫШЕННАЯ СЛОЖНОСТЬ) ---
			"planar_empyreans":
				var boss: CombatUnit = VoidBoss.create_unit()
				boss.display_name = "Повелитель Пустоты"
				boss.stats.max_hp = 120000.0 * hp_scale
				boss.stats.hp = boss.stats.max_hp
				boss.stats.atk = 2300.0 * atk_scale
				bm.enemies.append(boss)
				
				var elite: CombatUnit = VoidElite.create_unit()
				elite.display_name = "Элитный Страж"
				elite.stats.max_hp = 70000.0 * hp_scale
				elite.stats.hp = elite.stats.max_hp
				elite.stats.atk = 2000.0 * atk_scale
				bm.enemies.append(elite)
				for ally in bm.allies:
					ally.stats.spd += 20.0
				bm.log_message("🌌 Эмпирейцы | Аномалия «Скоростной резонанс»: Скорость команды +20 ед., при Скорости >= 120 урон +35%!")

			"planar_slums":
				var boss: CombatUnit = OrthoMutant.create_unit()
				boss.display_name = "Орто Мутант"
				boss.stats.max_hp = 115000.0 * hp_scale
				boss.stats.hp = boss.stats.max_hp
				boss.stats.atk = 2300.0 * atk_scale
				bm.enemies.append(boss)

				var arm: CombatUnit = VoidArmored.create_unit()
				arm.display_name = "Бронированный Рыцарь"
				arm.stats.max_hp = 80000.0 * hp_scale
				arm.stats.hp = arm.stats.max_hp
				arm.stats.atk = 2000.0 * atk_scale
				bm.enemies.append(arm)
				bm.log_message("🌆 Трущобы | Аномалия «Сердце Апокалипсиса»: Урон Сверхспособностей и Бонус-атак +40%!")

			"planar_detroit":
				var boss1: CombatUnit = MaskedSilhouette.create_unit()
				boss1.display_name = "Силуэт в маске"
				boss1.stats.max_hp = 105000.0 * hp_scale
				boss1.stats.hp = boss1.stats.max_hp
				boss1.stats.atk = 2200.0 * atk_scale
				bm.enemies.append(boss1)
				
				var boss2: CombatUnit = ServerVirus.create_unit()
				boss2.display_name = "Серверный Вирус"
				boss2.stats.max_hp = 100000.0 * hp_scale
				boss2.stats.hp = boss2.stats.max_hp
				boss2.stats.atk = 2100.0 * atk_scale
				bm.enemies.append(boss2)
				for ally in bm.allies:
					ally.stats.break_effect += 0.50
				bm.log_message("🏙 Детройт | Аномалия «Другая сторона»: Эффект пробития +50%, поверженный враг продвигает отряд на 25% и восстанавливает 20 энергии!")

			_:
				var elite_def: CombatUnit = VoidElite.create_unit()
				elite_def.stats.max_hp = 85000.0 * hp_scale
				elite_def.stats.hp = elite_def.stats.max_hp
				elite_def.stats.atk = 2200.0 * atk_scale
				elite_def.display_name = "Элитный Страж"
				bm.enemies.append(elite_def)
				for i in 2:
					var soldier_def: CombatUnit = VoidSoldier.create_unit()
					soldier_def.stats.max_hp = 35000.0 * hp_scale
					soldier_def.stats.hp = soldier_def.stats.max_hp
					soldier_def.stats.atk = 1600.0 * atk_scale
					soldier_def.display_name = "Страж Коррозии %d" % (i + 1)
					bm.enemies.append(soldier_def)
				bm.log_message("⚔ Добыча реликвий: победите Хранителя и Стражей для получения наград!")
		return
		
	if level_id == "level_1":
		bm.skill_points = 0
		bm.skill_points_changed.emit(0)
		bm.enemies.clear()
		for i in 3:
			var soldier: CombatUnit = VoidSoldier.create_unit()
			soldier.stats.max_hp = 1755.0
			soldier.stats.hp = 1755.0
			soldier.stats.atk = 3300.0
			bm.enemies.append(soldier)
		bm.log_message("⚔ Уровень 1: Обучение бою с 3 Солдатами Пустоты")

	elif level_id == "level_2":
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		for i in 2:
			var soldier: CombatUnit = VoidSoldier.create_unit()
			soldier.stats.max_hp = 3500.0
			soldier.stats.hp = 3500.0
			soldier.stats.atk = 2200.0
			bm.enemies.append(soldier)
		bm.log_message("⚔ Уровень 2: Обучение Уязвимостям и Щитам Данилла")

	elif level_id == "level_3":
		bm.skill_points = 2
		bm.skill_points_changed.emit(2)
		bm.enemies.clear()
		var elite: CombatUnit = VoidElite.create_unit()
		elite.stats.max_hp *= 0.70
		elite.stats.hp = elite.stats.max_hp
		bm.enemies.append(elite)
		bm.log_message("⚔ Уровень 3: Фракции и Пробитие Каори против Элитного Стража (70% ХП)")

	elif level_id == "level_4":
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		
		# Солдат слева (70% ХП)
		var s1: CombatUnit = VoidSoldier.create_unit()
		s1.stats.max_hp *= 0.70; s1.stats.hp = s1.stats.max_hp
		bm.enemies.append(s1)
		
		# Элитный Страж в центре (70% ХП)
		var elite: CombatUnit = VoidElite.create_unit()
		elite.stats.max_hp *= 0.70; elite.stats.hp = elite.stats.max_hp
		bm.enemies.append(elite)
		
		# Солдат справа (70% ХП)
		var s2: CombatUnit = VoidSoldier.create_unit()
		s2.stats.max_hp *= 0.70; s2.stats.hp = s2.stats.max_hp
		bm.enemies.append(s2)
		
		bm.log_message("⚔ Уровень 4: Боевой экзамен за 10 Циклов")
	elif level_id == "level_5":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		
		# Солдат Пустоты (100% ХП)
		var s1 := VoidSoldier.create_unit()
		bm.enemies.append(s1)
		
		# Элитный Страж в центре (100% ХП = 19800)
		var elite := VoidElite.create_unit()
		bm.enemies.append(elite)
		
		# Солдат Пустоты (100% ХП)
		var s2 := VoidSoldier.create_unit()
		bm.enemies.append(s2)
		
		bm.log_message("⚔ Уровень 5: Экзамен против Элитного Стража и Солдатов (100% ХП)")
	elif level_id == "level_6":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		for i in 5:
			var soldier: CombatUnit = VoidSoldier.create_unit()
			bm.enemies.append(soldier)
		bm.log_message("⚔ Уровень 6: 5 Солдатов Пустоты (Аномалия: Эрудиция +20% урона)")
	elif level_id == "level_7":
		is_tutorial = false
		bm.skill_points = 3
		bm.enemies.clear()
		for i in 3:
			var elite: CombatUnit = VoidElite.create_unit()
			bm.enemies.append(elite)
		bm.log_message("⚔ Уровень 7: 3 Элитных Стража (Аномалия: Крит. Шанс +50% на 3 хода)")

	elif level_id == "level_8":
		is_tutorial = false
		bm.skill_points = 3
		bm.enemies.clear()
		var boss: CombatUnit = VoidBoss.create_unit()
		boss.stats.max_hp *= 0.60; boss.stats.hp = boss.stats.max_hp
		bm.enemies.append(boss)
		bm.log_message("⚔ Уровень 8: Повелитель Бездны 60% ХП (Аномалия: Охота игнорирует 40% ЗАЩ)")

	elif level_id == "level_9":
		is_tutorial = false
		bm.skill_points = 3
		bm.enemies.clear()
		for i in 2:
			var elite: CombatUnit = VoidElite.create_unit()
			bm.enemies.append(elite)
		for i in 3:
			var soldier: CombatUnit = VoidSoldier.create_unit()
			bm.enemies.append(soldier)
		bm.log_message("⚔ Уровень 9: 2 Стража и 3 Солдатов (Аномалия: Ульт наносит +30% Чистого урона)")
	elif level_id == "level_10":
		is_tutorial = false
		bm.skill_points = 3
		bm.enemies.clear()
		
		var s1: CombatUnit = VoidSoldier.create_unit()
		s1.stats.max_hp *= 2.0; s1.stats.hp = s1.stats.max_hp
		s1.stats.atk *= 2.50
		bm.enemies.append(s1)
		
		# Повелитель Пустоты (Босс) в центре (130% ХП, 200% АТК)
		var boss: CombatUnit = VoidBoss.create_unit()
		boss.stats.max_hp *= 1.30; boss.stats.hp = boss.stats.max_hp
		boss.stats.atk *= 2.00
		bm.enemies.append(boss)
		
		# Солдат бездны справа (200% ХП, 250% АТК)
		var s2: CombatUnit = VoidSoldier.create_unit()
		s2.stats.max_hp *= 2.0; s2.stats.hp = s2.stats.max_hp
		s2.stats.atk *= 2.50
		bm.enemies.append(s2)
		
		bm.log_message("⚔ Уровень 10 (Босс): Повелитель Бездны и Солдаты")
	elif level_id == "level_11":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		for i in 5:
			var inf: CombatUnit = Infected.create_unit()
			inf.stats.max_hp = 49500.0
			inf.stats.hp = 49500.0
			inf.stats.atk = 1650.0
			bm.enemies.append(inf)
		bm.log_message("⚔ Уровень 11: Очаг Заражения (5 Заражённых)")
	elif level_id == "level_12":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		var inf1: CombatUnit = Infected.create_unit()
		inf1.stats.max_hp = 64350.0; inf1.stats.hp = inf1.stats.max_hp; inf1.stats.atk = 1700.0
		bm.enemies.append(inf1)
		var mutant: CombatUnit = OrthoMutant.create_unit()
		mutant.stats.max_hp = 127600.0; mutant.stats.hp = mutant.stats.max_hp; mutant.stats.atk = 2500.0
		bm.enemies.append(mutant)
		var inf2: CombatUnit = Infected.create_unit()
		inf2.stats.max_hp = 64350.0; inf2.stats.hp = inf2.stats.max_hp; inf2.stats.atk = 1700.0
		bm.enemies.append(inf2)
		bm.log_message("⚔ Уровень 12: Биохимическая Мутация (Орто Мутант и Заражённые)")
	elif level_id == "level_13":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		var arm1: CombatUnit = VoidArmored.create_unit()
		arm1.stats.max_hp = 84825.0; arm1.stats.hp = arm1.stats.max_hp; arm1.stats.def = 1250.0; arm1.stats.atk = 1600.0
		bm.enemies.append(arm1)
		var elite: CombatUnit = VoidElite.create_unit()
		elite.stats.max_hp = 98010.0; elite.stats.hp = elite.stats.max_hp; elite.stats.def = 900.0; elite.stats.atk = 2200.0
		bm.enemies.append(elite)
		var arm2: CombatUnit = VoidArmored.create_unit()
		arm2.stats.max_hp = 84825.0; arm2.stats.hp = arm2.stats.max_hp; arm2.stats.def = 1250.0; arm2.stats.atk = 1600.0
		bm.enemies.append(arm2)
		bm.log_message("⚔ Уровень 13: Бронированный Авангард (2 Бронированных Стража и Элитный Страж)")
	elif level_id == "level_14":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		var inf1: CombatUnit = Infected.create_unit()
		inf1.stats.max_hp = 59400.0; inf1.stats.hp = inf1.stats.max_hp; inf1.stats.atk = 1650.0
		bm.enemies.append(inf1)
		var mutant: CombatUnit = OrthoMutant.create_unit()
		mutant.stats.max_hp = 139200.0; mutant.stats.hp = mutant.stats.max_hp; mutant.stats.atk = 2600.0
		bm.enemies.append(mutant)
		var elite: CombatUnit = VoidElite.create_unit()
		elite.stats.max_hp = 80190.0; elite.stats.hp = elite.stats.max_hp; elite.stats.atk = 2200.0
		bm.enemies.append(elite)
		var inf2: CombatUnit = Infected.create_unit()
		inf2.stats.max_hp = 59400.0; inf2.stats.hp = inf2.stats.max_hp; inf2.stats.atk = 1650.0
		bm.enemies.append(inf2)
		bm.log_message("⚔ Уровень 14: Симбиоз Мутации и Пустоты")
	elif level_id == "level_15":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		var inf1: CombatUnit = Infected.create_unit()
		inf1.stats.max_hp = 64350.0; inf1.stats.hp = inf1.stats.max_hp; inf1.stats.atk = 1800.0
		bm.enemies.append(inf1)
		var virus: CombatUnit = ServerVirus.create_unit()
		virus.stats.max_hp = 243000.0; virus.stats.hp = virus.stats.max_hp; virus.stats.atk = 2800.0
		virus.set_meta("server_virus_firewall", 4)
		bm.enemies.append(virus)
		var inf2: CombatUnit = Infected.create_unit()
		inf2.stats.max_hp = 64350.0; inf2.stats.hp = inf2.stats.max_hp; inf2.stats.atk = 1800.0
		bm.enemies.append(inf2)
		bm.log_message("⚔ Уровень 15 (Мини-босс): Серверный Сбой (Серверный Вирус и Заражённые)")
	elif level_id == "level_16":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		var v1: CombatUnit = ServerVirus.create_unit()
		v1.stats.max_hp = 141750.0; v1.stats.hp = v1.stats.max_hp; v1.stats.atk = 2400.0
		v1.set_meta("server_virus_firewall", 2)
		bm.enemies.append(v1)
		var s1: CombatUnit = VoidSoldier.create_unit()
		s1.stats.max_hp = 52650.0; s1.stats.hp = s1.stats.max_hp; s1.stats.atk = 2800.0
		bm.enemies.append(s1)
		var v2: CombatUnit = ServerVirus.create_unit()
		v2.stats.max_hp = 141750.0; v2.stats.hp = v2.stats.max_hp; v2.stats.atk = 2400.0
		v2.set_meta("server_virus_firewall", 2)
		bm.enemies.append(v2)
		var s2: CombatUnit = VoidSoldier.create_unit()
		s2.stats.max_hp = 52650.0; s2.stats.hp = s2.stats.max_hp; s2.stats.atk = 2800.0
		bm.enemies.append(s2)
		bm.log_message("⚔ Уровень 16: Прорыв Сети (2 Вируса и 2 Солдата Бездны)")
	elif level_id == "level_17":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		var m1: CombatUnit = OrthoMutant.create_unit()
		m1.stats.max_hp = 150800.0; m1.stats.hp = m1.stats.max_hp; m1.stats.atk = 2700.0
		bm.enemies.append(m1)
		var arm: CombatUnit = VoidArmored.create_unit()
		arm.stats.max_hp = 104400.0; arm.stats.hp = arm.stats.max_hp; arm.stats.def = 1300.0; arm.stats.atk = 1800.0
		bm.enemies.append(arm)
		var m2: CombatUnit = OrthoMutant.create_unit()
		m2.stats.max_hp = 150800.0; m2.stats.hp = m2.stats.max_hp; m2.stats.atk = 2700.0
		bm.enemies.append(m2)
		bm.log_message("⚔ Уровень 17: Двойной Биохазард (2 Орто Мутанта и Бронированный Страж)")
	elif level_id == "level_18":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		var e1: CombatUnit = VoidElite.create_unit()
		e1.stats.max_hp = 111375.0; e1.stats.hp = e1.stats.max_hp; e1.stats.atk = 2600.0
		bm.enemies.append(e1)
		var boss: CombatUnit = VoidBoss.create_unit()
		boss.stats.max_hp = 210600.0; boss.stats.hp = boss.stats.max_hp; boss.stats.atk = 3200.0
		bm.enemies.append(boss)
		var e2: CombatUnit = VoidElite.create_unit()
		e2.stats.max_hp = 111375.0; e2.stats.hp = e2.stats.max_hp; e2.stats.atk = 2600.0
		bm.enemies.append(e2)
		bm.log_message("⚔ Уровень 18: Гвардия Забвения (Повелитель Бездны и 2 Элитных Стража)")
	elif level_id == "level_19":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		var virus: CombatUnit = ServerVirus.create_unit()
		virus.stats.max_hp = 162000.0; virus.stats.hp = virus.stats.max_hp; virus.stats.atk = 2700.0
		virus.set_meta("server_virus_firewall", 3)
		bm.enemies.append(virus)
		var mutant: CombatUnit = OrthoMutant.create_unit()
		mutant.stats.max_hp = 162400.0; mutant.stats.hp = mutant.stats.max_hp; mutant.stats.atk = 2800.0
		bm.enemies.append(mutant)
		var elite: CombatUnit = VoidElite.create_unit()
		elite.stats.max_hp = 133650.0; elite.stats.hp = elite.stats.max_hp; elite.stats.atk = 2800.0
		bm.enemies.append(elite)
		bm.log_message("⚔ Уровень 19: Преддверие Бездны (Трио Элит: Вирус, Мутант и Страж)")
	elif level_id == "level_20":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		var s1: CombatUnit = VoidSoldier.create_unit()
		s1.stats.max_hp = 70200.0; s1.stats.hp = s1.stats.max_hp; s1.stats.atk = 2800.0
		bm.enemies.append(s1)
		var silhouette: CombatUnit = MaskedSilhouette.create_unit()
		silhouette.stats.max_hp = 120000.0; silhouette.stats.hp = silhouette.stats.max_hp; silhouette.stats.atk = 2800.0
		silhouette.set_meta("mask_layers", 14)
		bm.enemies.append(silhouette)
		var s2: CombatUnit = VoidSoldier.create_unit()
		s2.stats.max_hp = 70200.0; s2.stats.hp = s2.stats.max_hp; s2.stats.atk = 2800.0
		bm.enemies.append(s2)
		bm.log_message("⚔ Уровень 20 (ФИНАЛЬНЫЙ БОСС): Силуэт в Маске и Солдаты Бездны")
# --- 2. ПОДПИСКА И УПРАВЛЕНИЕ ОБУЧЕНИЕМ В UI ---

static func init_tutorial_ui(battle_ui: Control) -> void:
	if not is_tutorial:
		return

	if current_level_id == "level_1":
		battle_ui.battle_manager.skill_points = 0
		battle_ui.battle_manager.skill_points_changed.emit(0)

	tut_overlay = ColorRect.new()
	tut_overlay.color = Color(0, 0, 0, 0.2)
	tut_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tut_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_ui.add_child(tut_overlay)

	tut_panel = PanelContainer.new()
	tut_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	tut_panel.custom_minimum_size = Vector2(380, 280)
	tut_panel.offset_left = -410
	tut_panel.offset_right = -30
	tut_panel.offset_top = -140
	tut_panel.offset_bottom = 140
	
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.08, 0.10, 0.16, 0.95)
	panel_sb.border_color = Color(0.9, 0.75, 0.3, 1.0)
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(12)
	panel_sb.set_content_margin_all(14)
	tut_panel.add_theme_stylebox_override("panel", panel_sb)
	
	tut_overlay.add_child(tut_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	tut_panel.add_child(vbox)

	tut_label = RichTextLabel.new()
	tut_label.custom_minimum_size = Vector2(0, 180)
	tut_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tut_label.bbcode_enabled = true
	tut_label.add_theme_font_size_override("normal_font_size", 16)
	vbox.add_child(tut_label)

	tut_next_btn = Button.new()
	tut_next_btn.text = "Далее ➔"
	tut_next_btn.custom_minimum_size = Vector2(180, 44)
	tut_next_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.15, 0.55, 0.95, 1.0)
	btn_sb.set_corner_radius_all(8)
	tut_next_btn.add_theme_stylebox_override("normal", btn_sb)
	tut_next_btn.add_theme_font_size_override("font_size", 16)
	tut_next_btn.pressed.connect(func(): _on_next_pressed(battle_ui))
	vbox.add_child(tut_next_btn)

	tut_pointer = Label.new()
	tut_pointer.text = "⬇"
	tut_pointer.add_theme_font_size_override("font_size", 56)
	tut_pointer.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	tut_pointer.add_theme_color_override("font_outline_color", Color.BLACK)
	tut_pointer.add_theme_constant_override("outline_size", 10)
	tut_pointer.visible = false
	battle_ui.add_child(tut_pointer)

	if current_level_id == "level_1": _run_step_l1(1, battle_ui)
	elif current_level_id == "level_2": _run_step_l2(1, battle_ui)
	elif current_level_id == "level_3": _run_step_l3(1, battle_ui)
	elif current_level_id == "level_4": _run_step_l4(1, battle_ui)

# --- 3. ПОШАГОВЫЕ СЦЕНАРИИ ОБУЧЕНИЯ ---

# Сценарий Уровня 1
static func _run_step_l1(step: int, battle_ui: Control) -> void:
	tut_step = step
	tut_next_btn.visible = false
	tut_pointer.visible = false
	_lock_all_buttons(battle_ui, true)

	match step:
		1:
			_set_text("ПРИВЕТ! Готов погрузиться в мир Рунтэрры?\n\nЭта игра — пошаговая боевая система. Ты и враги ходите по очереди. Вот тут можно посмотреть, в каком порядке кто ходит. При наведении покажется полное имя.")
			_show_pointer(battle_ui.action_bar.global_position + Vector2(200, -55))
			tut_next_btn.text = "Далее ➔"
			tut_next_btn.visible = true
		2:
			_set_text("Сейчас твой ход! Стандартно у персонажей есть 4 умения: Базовая атака, Навык Q, Навык E и Сверхспособность.\n\nСейчас у тебя нет Очков навыков, но не волнуйся — использование Базовой атаки восстанавливает 1 Очко навыков. Нажми на [b]«Базовую атаку»[/b]!")
			battle_ui.btn_basic.disabled = false
			_show_pointer(battle_ui.btn_basic.global_position + Vector2(60, -60))
		3:
			_set_text("Базовая атака, зачастую — Одиночное умение, и бьёт лишь по одной цели. Выбери, какого противника ты хочешь поразить!")
		4:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("Ты нанёс противнику урон. Нанесение урона восстанавливает тебе Энергию, которая нужна для использования Сверхспособности.")
			_show_pointer(battle_ui.energy_bar.global_position + Vector2(100, -55))
			tut_next_btn.text = "Далее ➔"
			tut_next_btn.visible = true
		5:
			_set_text("Теперь ходят противники.")
			_show_pointer(battle_ui.action_bar.global_position + Vector2(200, -55))
			tut_next_btn.text = "Понятно (пуск) ➔"
			tut_next_btn.visible = true
		6:
			_set_text("Противники сходили друг за другом, поэтому ты получил урон 3 раза. Каждый из ударов восстановил тебе энергию.\n\nТеперь нажми [b]Навык Q[/b], для того, чтобы нанести урон сразу трём противникам!")
			battle_ui.btn_skill.disabled = false
			_show_pointer(battle_ui.btn_skill.global_position + Vector2(60, -60))
		7:
			_set_text("Навык Q Вики — Взрывная атака. Это такой тип атак, которые бьют сильно по центральной цели, и слабее по тем, что её окружают. Выбери центральную цель, чтобы нанести удар!")
		8:
			battle_ui.battle_manager.skill_points = mini(battle_ui.battle_manager.skill_points + 2, CombatConstants.MAX_SKILL_POINTS)
			battle_ui.battle_manager.skill_points_changed.emit(battle_ui.battle_manager.skill_points)
			_set_text("Отлично! У тебя доступна Сверхспособность, но перед её применением давай сначала используем [b]Навык E[/b] для того, чтобы получить бафф. У тебя не хватает Очков навыков, но я тебе дам парочку.\n\nНавык Е Вики тратит её ХП, но даёт взамен много Силы атаки. Нажми [b]Навык E[/b]!")
			battle_ui.btn_skill_e.disabled = false
			_show_pointer(battle_ui.btn_skill_e.global_position + Vector2(60, -60))
		9:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("Супер! Ты получил бафф силы атаки. Чтобы посмотреть свои характеристики, эффекты и описания умений, нажми на [b]«Инфо»[/b] на карточке персонажа!")
			_unlock_card_button(battle_ui, "vika", "InfoButton")
		10:
			_set_text("Это инфо. Здесь можно отслеживать длительность статусов на своих персонажах и на врагах.\n\nСмотри — твой бафф Навыка Е длится всего 3 хода. Каждый ход Вики его длительность будет уменьшаться на 1. Всё. Выходи отсюда.")
		11:
			_set_text("Смотри! У тебя доступна [b]Сверхспособность[/b]. Сверхспособность можно применить В ЛЮБОЕ ВРЕМЯ. Она не считается полноценным ходом, поэтому её можно применять, не боясь, что снимутся баффы. Жми! Жми!")
			_unlock_card_button(battle_ui, "vika", "UltButtonOnCard")
		12:
			_set_text("Сверхспособность Вики — тоже Взрывная атака. Выбери центральную цель!")
		13:
			_set_text("Супер! Вика вошла в состояние «Пробуждение». В этом состоянии она наносит чуть меньше урона, но восстанавливает ХП в начале каждого своего хода!\n\nТвоя задача — добить врагов. [b]УНИЧТОЖЬ ИХ![/b]")
			tut_next_btn.text = "В бой! ⚔"
			tut_next_btn.visible = true

# Сценарий Уровня 2 (Данилл)
static func _run_step_l2(step: int, battle_ui: Control) -> void:
	tut_step = step
	tut_next_btn.visible = false
	tut_pointer.visible = false
	_lock_all_buttons(battle_ui, true)

	match step:
		1:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("У каждого персонажа есть свой Путь, по которому он следует, и Элемент, которым он атакует.\n\nОт Пути зависит его роль в отряде, а от Элемента — уязвимости, которые он пробивает.\n\nЭто — полоска Стойкости врага. Посмотреть Уязвимости врага можно в его [b]Инфо[/b]!")
			_unlock_enemy_info_button(battle_ui)
		2:
			_set_text("Прокрути характеристики вниз, чтобы увидеть Уязвимости противника. Элементы, к которым у врага НЕТ уязвимости, наносят ему меньше урона. Собирай отряд под элементы врагов!\n\nВыходи отсюда.")
		3:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
			tut_overlay.show()
			_set_text("Нажми [b]Базовую атаку Вики[/b] на этого Солдата Пустоты!")
			battle_ui.btn_basic.disabled = false
			_show_pointer(battle_ui.btn_basic.global_position + Vector2(60, -60))
		4:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("Видишь — ничего не произошло. Это потому что у Вики Квантовый элемент, а враг не имеет Квантовой Уязвимости.\n\nТеперь сходи [b]Базовой атакой Данилла[/b] на этого Солдата Пустоты!")
			tut_next_btn.text = "Далее ➔"
			tut_next_btn.visible = true
		5:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("Смотри — Стойкость врага снизилась! Это потому что у него есть огненная Уязвимость. А Элемент Данилла — как раз огненный! Когда стойкость станет равна 0, враг получит урон Пробития, а его ход будет отложен!")
			tut_next_btn.text = "Понятно (пуск) ➔"
			tut_next_btn.visible = true
		6:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("Теперь нажми [b]Навык Е Вики[/b] и усиль её!")
			battle_ui.btn_skill_e.disabled = false
			_show_pointer(battle_ui.btn_skill_e.global_position + Vector2(60, -60))
		7:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("Навык Е Вики расходует её здоровье. Это делает её уязвимой для врагов. Хорошо, что у тебя в отряде есть Данилл.\n\nДанилл следует Пути Сохранения — его умения заточены на то, чтобы защищать союзников, накладывая на них щиты. Своей Техникой Данилл уже наложил щит на союзников в начале боя, однако Вике нужен новый.\n\nНажми [b]Навык Q Данилла[/b] на Вику, чтобы наложить на неё мощный Щит!")
			tut_next_btn.text = "Далее ➔"
			tut_next_btn.visible = true
		8:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("Отлично! Смотри — Щит Данилла защищает союзников от урона противника. Но у Данилла осталась ещё одна способность — Навык Е.\n\nСходи за Вику [b]Базовой атакой[/b], чтобы сохранить Очки навыков для Навыка Е Данилла!")
			battle_ui.btn_basic.disabled = false
			_show_pointer(battle_ui.btn_basic.global_position + Vector2(60, -60))
		9:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			battle_ui.battle_manager.skill_points = mini(battle_ui.battle_manager.skill_points + 2, CombatConstants.MAX_SKILL_POINTS)
			battle_ui.battle_manager.skill_points_changed.emit(battle_ui.battle_manager.skill_points)
			_set_text("Навык Е Данилла [b]Провоцирует[/b] всех врагов. Это заставляет их выбирать Данилла в качестве цели для своих умений, что позволяет остальным персонажам отдохнуть от бесконечных атак врагов. Теперь они будут атаковать только Данилла на протяжении 3х ходов. Однако, у врагов могут быть атаки по нескольким целям, поэтому Навык Е Данилла защищает не полностью. Для этого есть Сверхспособность.\n\nНажми [b]Навык E Данилла[/b]!")
			battle_ui.btn_skill_e.disabled = false
			_show_pointer(battle_ui.btn_skill_e.global_position + Vector2(60, -60))
		10:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			for ally in battle_ui.battle_manager.allies:
				if ally.id == "danill":
					ally.energy = ally.max_energy
					battle_ui._refresh_unit_panel(ally)
			_set_text("Теперь, ты можешь активировать [b]Сверхспособность Данилла[/b], чтобы защитить ВСЕХ союзников за раз. Жми!")
			_unlock_card_button(battle_ui, "danill", "UltButtonOnCard")
		11:
			_set_text("Супер! Все союзники в безопасности. Продолжай сражаться и победи противника, чтобы бесплатно получить Данилла в команду!")
			tut_next_btn.text = "В бой! ⚔"
			tut_next_btn.visible = true

# Сценарий Уровня 3 (Каори и Синергии)
static func _run_step_l3(step: int, battle_ui: Control) -> void:
	tut_step = step
	tut_next_btn.visible = false
	tut_pointer.visible = false
	_lock_all_buttons(battle_ui, true)

	match step:
		1:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("Это Каори. Она следует Пути Охоты, и поэтому её умения бьют сосредоточенным уроном только по одной цели. Персонажи Пути Охоты полезны против Боссов и Одиночных противников.\n\nТеперь нажми на [b]«Синергии»[/b]!")
			_unlock_top_button(battle_ui, "btn_factions")
		2:
			_set_text("Каждый персонаж имеет свои «Фракции». Когда в отряде есть несколько персонажей из одной Фракции, они получают бонусы. Так, например, Каори и Данилл оба состоят во Фракции «Рассвет хаоса». Из-за того, что они в одной команде, их Сила атаки и Макс. ХП увеличились на 15%.\n\nТакже, Вика состоит во Фракции «Академия» (1 участник дает +1 ОН на старте боя).\n\nЗакрой меню Фракций.")
			_unlock_top_button(battle_ui, "btn_factions")
		3:
			_set_text("Теперь о Каори. В отличие от других персонажей, её основной урон завязан на механике Пробития уязвимости. Её способности наносят Дополнительный урон, когда пробивают стойкость врага. Поэтому старайся наносить решающий удар по Стойкости именно Каори!\n\nНажми Базовую атаку на противника, и ходи Базовыми атаками других союзников, чтобы припасти Очки Навыков!")
			tut_next_btn.text = "Далее ➔"
			tut_next_btn.visible = true
		4:
			battle_ui.btn_basic.disabled = false
			_show_pointer(battle_ui.btn_basic.global_position + Vector2(60, -60))
		5:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			
			for ally in battle_ui.battle_manager.allies:
				if ally.id == "kaori":
					ally.set_meta("weakness_concentration", true)
					battle_ui._refresh_unit_panel(ally)
					
			_set_text("Смотри — Базовая атака Каори улучшилась до Улучшенной Базовой атаки! Это Талант Каори: Нанесение урона улучшает её следующую Базовую атаку. Используй Улучшенную Базовую атаку на противнике!")
			battle_ui.btn_basic.disabled = false
			_show_pointer(battle_ui.btn_basic.global_position + Vector2(60, -60))
		6:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("Молодец! Теперь твоя задача — пробить уязвимость этого противника для реализации урона Каори.")
			tut_next_btn.text = "В бой! ⚔"
			tut_next_btn.visible = true
		7:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("Уязвимость врага была пробита! Получаемый им урон увеличен до восстановления Стойкости. Враг восстановит стойкость в свой следующий ход, поэтому поторопись! Убей врага, чтобы получить Каори!")
			tut_next_btn.text = "Уничтожить! ⚔"
			tut_next_btn.visible = true

# Сценарий Уровня 4 (Боевой Экзамен)
static func _run_step_l4(step: int, battle_ui: Control) -> void:
	tut_step = step
	tut_next_btn.visible = false
	tut_pointer.visible = false
	_lock_all_buttons(battle_ui, true)

	match step:
		1:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", true)
			tut_overlay.show()
			_set_text("На этом всё. Теперь давай проверим твои силы.\n\nПобеди этого Элитного стража и Солдатов Пустоты за [b]10 Циклов[/b] (посмотреть текущий цикл можно здесь)!")
			_show_pointer(battle_ui.turn_label.global_position + Vector2(100, 20))
			tut_next_btn.text = "Далее ➔"
			tut_next_btn.visible = true
		2:
			_set_text("Более точно посмотреть динамику урона отряда можно в [b]Графиках урона[/b].\n\nНа этом всё! Удачи!")
			_unlock_top_button(battle_ui, "btn_graphs")
			tut_next_btn.text = "В бой! ⚔"
			tut_next_btn.visible = true

static func _on_next_pressed(battle_ui: Control) -> void:
	if current_level_id == "level_1":
		match tut_step:
			1: _run_step_l1(2, battle_ui)
			4: _run_step_l1(5, battle_ui)
			5:
				tut_overlay.hide()
				battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
			13:
				is_tutorial = false
				battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
				tut_overlay.queue_free()
				tut_pointer.queue_free()
				_lock_all_buttons(battle_ui, false)

	elif current_level_id == "level_2":
		match tut_step:
			5:
				tut_overlay.hide()
				battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
			11:
				is_tutorial = false
				battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
				tut_overlay.queue_free()
				tut_pointer.queue_free()
				_lock_all_buttons(battle_ui, false)

	elif current_level_id == "level_3":
		match tut_step:
			3:
				tut_overlay.hide()
				battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
				_run_step_l3(4, battle_ui)
			6:
				tut_overlay.hide()
				battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
				_lock_all_buttons(battle_ui, false)
			7:
				is_tutorial = false
				battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
				tut_overlay.queue_free()
				tut_pointer.queue_free()
				_lock_all_buttons(battle_ui, false)

	elif current_level_id == "level_4":
		match tut_step:
			1:
				_run_step_l4(2, battle_ui)
			2:
				is_tutorial = false
				battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
				tut_overlay.queue_free()
				tut_pointer.queue_free()
				_lock_all_buttons(battle_ui, false)

# --- 4. РЕАКЦИИ НА ДЕЙСТВИЯ ИГРОКА ---

static func on_turn_started(unit: CombatUnit, battle_ui: Control) -> void:
	if not is_tutorial: return
	
	if current_level_id == "level_1":
		if unit.is_ally:
			if tut_step == 5: tut_overlay.show(); _run_step_l1(6, battle_ui)
			elif tut_step == 7: tut_overlay.show(); _run_step_l1(8, battle_ui)
			elif tut_step == 12: tut_overlay.show(); _run_step_l1(13, battle_ui)

	elif current_level_id == "level_2":
		if unit.is_ally:
			if tut_step == 3 and unit.id == "danill": _run_step_l2(4, battle_ui)
			elif tut_step == 5 and unit.id == "vika": _run_step_l2(6, battle_ui)
			elif tut_step == 6 and unit.id == "danill": _run_step_l2(7, battle_ui)
			elif tut_step == 7 and unit.id == "vika": _run_step_l2(8, battle_ui)
			elif tut_step == 8 and unit.id == "danill": _run_step_l2(9, battle_ui)

	elif current_level_id == "level_3":
		if unit.is_ally:
			if tut_step == 4 and unit.id == "kaori":
				_run_step_l3(5, battle_ui)

static func on_action_pressed(action_type: String, battle_ui: Control) -> void:
	if not is_tutorial: return
	
	if current_level_id == "level_1":
		if action_type == "basic" and tut_step == 2: _run_step_l1(3, battle_ui)
		elif action_type == "basic_target_selected" and tut_step == 3: _run_step_l1(4, battle_ui)
		elif action_type == "skill_q" and tut_step == 6: _run_step_l1(7, battle_ui)
		elif action_type == "skill_e" and tut_step == 8: _run_step_l1(9, battle_ui)
		elif action_type == "inspect_open" and tut_step == 9: _run_step_l1(10, battle_ui)
		elif action_type == "inspect_close" and tut_step == 10: _run_step_l1(11, battle_ui)
		elif action_type == "ult_card" and tut_step == 11: _run_step_l1(12, battle_ui)

	elif current_level_id == "level_2":
		if action_type == "inspect_open" and tut_step == 1: _run_step_l2(2, battle_ui)
		elif action_type == "inspect_close" and tut_step == 2: _run_step_l2(3, battle_ui)
		elif action_type == "basic" and tut_step == 3:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
			tut_overlay.hide()
		elif action_type == "basic" and tut_step == 4:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
			tut_overlay.hide()
			_run_step_l2(5, battle_ui)
		elif action_type == "skill_e" and tut_step == 6:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
			tut_overlay.hide()
		elif action_type == "skill_q" and tut_step == 7:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
			tut_overlay.hide()
		elif action_type == "basic" and tut_step == 8:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
			tut_overlay.hide()
		elif action_type == "skill_e" and tut_step == 9: _run_step_l2(10, battle_ui)
		elif action_type == "ult_card" and tut_step == 10: _run_step_l2(11, battle_ui)

	elif current_level_id == "level_3":
		if action_type == "factions_toggle" and tut_step == 1: _run_step_l3(2, battle_ui)
		elif action_type == "factions_toggle" and tut_step == 2: _run_step_l3(3, battle_ui)
		elif action_type == "basic" and tut_step == 5:
			battle_ui.battle_manager.set_meta("is_selecting_ult_target", false)
			tut_overlay.hide()
			_run_step_l3(6, battle_ui)

# Реакция на пробитие стойкости (принимает любой Узел без ошибок типизации)
static func on_toughness_broken(caller_node = null) -> void:
	if is_tutorial and current_level_id == "level_3" and tut_step == 6:
		var battle_ui: Control = null
		if caller_node is Control:
			battle_ui = caller_node
		elif caller_node is Node and caller_node.get_parent() is Control:
			battle_ui = caller_node.get_parent() as Control
			
		if battle_ui:
			_run_step_l3(7, battle_ui)

# --- 5. ВЫДАЧА НАГРАД ПРИ ПОБЕДЕ ---

static func on_battle_ended(victory: bool, bm: BattleManager = null) -> void:
	if victory and (current_level_id.begins_with("dungeon_") or current_level_id.begins_with("planar_")):
		var drops: Array[Dictionary] = []
		if TeamConfig.has_meta("tutorial_dungeon_academy"):
			TeamConfig.remove_meta("tutorial_dungeon_academy")
			drops = RelicSystem.generate_tutorial_drops()
			TeamConfig.add_relic_shards(30)
		else:
			drops = RelicSystem.generate_dungeon_drops(current_level_id, TeamConfig.current_level_progress)
		for r in drops:
			TeamConfig.add_relic(r)
		TeamConfig.save_game()
		TeamConfig.set_meta("pending_relic_drops", drops)
		if bm != null:
			bm.log_message("🎉 Победа в Подземелье! Получено %d реликвий." % drops.size())
		return

	if victory and current_level_id.begins_with("level_"):
		# Узнаем точное число циклов из текущего боя
		var cycles := 1
		if bm != null:
			cycles = bm.get_current_cycles()
		
		# Внутри on_battle_ended() в level_manager.gd:
		match current_level_id:
			"level_1":
				if not "level_1" in TeamConfig.completed_levels:
					TeamConfig.completed_levels.append("level_1")
					TeamConfig.coins += 150
				if TeamConfig.current_level_progress < 2: TeamConfig.current_level_progress = 2
			"level_2":
				if not "level_2" in TeamConfig.completed_levels:
					TeamConfig.completed_levels.append("level_2")
					TeamConfig.coins += 200
					if not "danill" in TeamConfig.unlocked_characters: TeamConfig.unlocked_characters.append("danill")
				if TeamConfig.current_level_progress < 3: TeamConfig.current_level_progress = 3
			"level_3":
				if not "level_3" in TeamConfig.completed_levels:
					TeamConfig.completed_levels.append("level_3")
					TeamConfig.coins += 250
					if not "kaori" in TeamConfig.unlocked_characters: TeamConfig.unlocked_characters.append("kaori")
				if TeamConfig.current_level_progress < 4: TeamConfig.current_level_progress = 4
			"level_4":
				if not "level_4" in TeamConfig.completed_levels:
					TeamConfig.completed_levels.append("level_4")
					TeamConfig.coins += 300
				if TeamConfig.current_level_progress < 5: TeamConfig.current_level_progress = 5
			"level_5":
				if not "level_5" in TeamConfig.completed_levels:
					TeamConfig.completed_levels.append("level_5")
					TeamConfig.shine += 10
					TeamConfig.set_meta("show_level_5_reward", true)
				if TeamConfig.current_level_progress < 6: TeamConfig.current_level_progress = 6
			"level_6":
				if not "level_6" in TeamConfig.completed_levels:
					TeamConfig.completed_levels.append("level_6")
					TeamConfig.coins += 300
				if TeamConfig.current_level_progress < 7: TeamConfig.current_level_progress = 7
			"level_7":
				_process_star_rewards("level_7", cycles, 8, 10, 15, 2, 8)
			"level_8":
				_process_star_rewards("level_8", cycles, 5, 8, 12, 3, 9)
			"level_9":
				_process_star_rewards("level_9", cycles, 6, 8, 12, 0, 10)
			"level_10":
				_process_star_rewards("level_10", cycles, 8, 10, 12, 10, 11) # Единая функция!
			"level_11":
				_process_star_rewards("level_11", cycles, 5, 8, 12, 1, 12)
			"level_12":
				_process_star_rewards("level_12", cycles, 6, 9, 13, 1, 13)
			"level_13":
				_process_star_rewards("level_13", cycles, 6, 9, 14, 2, 14)
			"level_14":
				_process_star_rewards("level_14", cycles, 7, 10, 15, 2, 15)
			"level_15":
				_process_star_rewards("level_15", cycles, 8, 11, 15, 6, 16)
			"level_16":
				_process_star_rewards("level_16", cycles, 7, 10, 14, 2, 17)
			"level_17":
				_process_star_rewards("level_17", cycles, 7, 10, 14, 2, 18)
			"level_18":
				_process_star_rewards("level_18", cycles, 8, 11, 15, 3, 19)
			"level_19":
				_process_star_rewards("level_19", cycles, 8, 11, 15, 3, 20)
			"level_20":
				_process_star_rewards("level_20", cycles, 10, 14, 18, 8, 21)
		TeamConfig.save_game()

# Расчет звёзд с зачислением разницы наград при перепрохождении на лучший результат
static func _process_star_rewards(level_id: String, cycles: int, c3: int, c2: int, c1: int, shine_bonus: int, next_prog: int) -> void:
	var new_stars := 0
	if cycles <= c3: new_stars = 3
	elif cycles <= c2: new_stars = 2
	elif cycles <= c1: new_stars = 1
	
	if new_stars > 0:
		var old_stars: int = int(TeamConfig.level_stars.get(level_id, 0))
		
		# Если получен новый рекорд по звездам
		if new_stars > old_stars:
			var added_stars := new_stars - old_stars
			TeamConfig.coins += added_stars * 50 # Доначисляем по 50 монет за каждую новую звезду!
			
			# Если 3 звезды выбиты впервые -> выдаем ивентовый бонус Блеска Свечения!
			if new_stars == 3 and old_stars < 3 and shine_bonus > 0:
				TeamConfig.shine += shine_bonus
				
			TeamConfig.level_stars[level_id] = new_stars
			
			if not level_id in TeamConfig.completed_levels:
				TeamConfig.completed_levels.append(level_id)
				
		if TeamConfig.current_level_progress < next_prog:
			TeamConfig.current_level_progress = next_prog
			
# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ГЛОБАЛЬНОЙ БЛОКИРОВКИ ---

static func _set_text(txt: String) -> void:
	tut_label.text = txt

static func _show_pointer(pos: Vector2) -> void:
	tut_pointer.global_position = pos
	tut_pointer.visible = true

static func _lock_all_buttons(battle_ui: Control, locked: bool) -> void:
	battle_ui.btn_basic.disabled = locked
	battle_ui.btn_enhanced_basic.disabled = locked
	battle_ui.btn_skill.disabled = locked
	battle_ui.btn_skill_e.disabled = locked
	battle_ui.btn_ult.disabled = locked

	for unit in battle_ui._unit_panels:
		var panel: PanelContainer = battle_ui._unit_panels[unit]
		var vbox: VBoxContainer = panel.get_child(0)
		
		if vbox.has_node("InfoButton"):
			var info_btn: Button = vbox.get_node("InfoButton")
			info_btn.disabled = locked
			
		if vbox.has_node("UltButtonOnCard"):
			var ult_btn: Button = vbox.get_node("UltButtonOnCard")
			ult_btn.disabled = locked

	if battle_ui.btn_skills_help:
		battle_ui.btn_skills_help.disabled = locked

static func _unlock_card_button(battle_ui: Control, unit_id: String, btn_name: String) -> void:
	for unit in battle_ui._unit_panels:
		if unit.id == unit_id:
			var panel: PanelContainer = battle_ui._unit_panels[unit]
			var vbox: VBoxContainer = panel.get_child(0)
			var btn: Button = vbox.get_node(btn_name)
			btn.disabled = false
			_show_pointer(btn.global_position + Vector2(50, -50))

static func _unlock_enemy_info_button(battle_ui: Control) -> void:
	for unit in battle_ui._unit_panels:
		if not unit.is_ally and unit.is_alive():
			var panel: PanelContainer = battle_ui._unit_panels[unit]
			var vbox: VBoxContainer = panel.get_child(0)
			var btn: Button = vbox.get_node("InfoButton")
			btn.disabled = false
			_show_pointer(btn.global_position + Vector2(-30, -70))
			return

static func _unlock_top_button(battle_ui: Control, btn_var_name: String) -> void:
	if battle_ui.get(btn_var_name):
		var btn: Button = battle_ui.get(btn_var_name)
		btn.disabled = false
		_show_pointer(btn.global_position + Vector2(40, 40))
