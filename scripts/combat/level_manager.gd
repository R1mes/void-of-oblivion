class_name LevelManager
extends RefCounted

## Модуль управления Уровнями, Обучением и Сюжетными Встречами.

const AntimatterSlave = preload("res://scripts/enemies/antimatter_slave.gd")
const Insurgent = preload("res://scripts/enemies/insurgent.gd")
const KyleRebelLeader = preload("res://scripts/enemies/kyle_rebel_leader.gd")

static var current_level_id: String = ""
static var is_tutorial: bool = false
static var tut_step: int = 0

# UI-элементы обучения
const TutorialGuideOverlayScript = preload("res://scripts/ui/tutorial_guide_overlay.gd")
static var guide_overlay: Control = null
static var tut_overlay: Control = null
static var tut_panel: Control = null
static var tut_label: Control = null
static var tut_next_btn: Control = null
static var tut_pointer: Control = null

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

			"dungeon_detroit_airfield":
				var elite: CombatUnit = OrtofetaminHorror.create_unit()
				elite.display_name = "Ужас ортофетамина"
				elite.stats.max_hp = 135000.0 * hp_scale
				elite.stats.hp = elite.stats.max_hp
				elite.stats.atk = 2500.0 * atk_scale
				bm.enemies.append(elite)

				for i in 2:
					var inf: CombatUnit = Infected.create_unit()
					inf.display_name = "Заражённый %d" % (i + 1)
					inf.stats.max_hp = 42000.0 * hp_scale
					inf.stats.hp = inf.stats.max_hp
					inf.stats.atk = 1600.0 * atk_scale
					bm.enemies.append(inf)
				bm.log_message("🛫 Аэродром Детройта | Аномалия «Звёздный распад»: Крит. урон +30%, Бинарный урон игнорирует 20% защиты, урон по ослабленным целям +25%!")

			"planar_server":
				var boss: CombatUnit = ShojiVz.create_unit()
				boss.display_name = "Сёдзи ВЗ"
				boss.stats.max_hp = 240000.0 * hp_scale
				boss.stats.hp = boss.stats.max_hp
				boss.stats.atk = 2500.0 * atk_scale
				bm.enemies.append(boss)

				for i in 2:
					var cleaner: CombatUnit = CitadelCleaner.create_unit(i + 1, true)
					cleaner.display_name = "Чистильщик Цитадели %d" % (i + 1)
					cleaner.stats.max_hp = 38000.0 * hp_scale
					cleaner.stats.hp = cleaner.stats.max_hp
					cleaner.stats.atk = 1500.0 * atk_scale
					bm.enemies.append(cleaner)
				bm.log_message("🖥 Сервер | Аномалия «Глубины реальности»: Скорость отряда +15%, подрыв DoT восстанавливает 5 энергии и 1 Вектор!")

			"dungeon_rebellion_ruins":
				var elite: CombatUnit = Insurgent.create_unit()
				elite.display_name = "Восставший"
				elite.stats.max_hp = 225000.0 * hp_scale
				elite.stats.hp = elite.stats.max_hp
				elite.stats.atk = 1900.0 * atk_scale
				bm.enemies.append(elite)

				for i in 2:
					var slave: CombatUnit = AntimatterSlave.create_unit(i + 1)
					slave.display_name = "Раб Антиматерии %d" % (i + 1)
					slave.stats.max_hp = 30000.0 * hp_scale
					slave.stats.hp = slave.stats.max_hp
					slave.stats.atk = 1200.0 * atk_scale
					bm.enemies.append(slave)

				for ally in bm.allies:
					ally.stats.break_effect += 0.40
				bm.log_message("🏛 Руины восстания | Аномалия «Разлом сингулярности»: Эффект пробития отряда +40%! Атаки Духов Памяти истощают стойкость на 100% эффективнее, а пробитие уязвимости восстанавливает 10 энергии и продвигает действие на 15%!")

			"planar_rebellion_hq":
				var boss: CombatUnit = KyleRebelLeader.create_unit()
				boss.display_name = "Кайл • Лидер восстания"
				boss.stats.max_hp = 350000.0 * hp_scale
				boss.stats.hp = boss.stats.max_hp
				boss.stats.atk = 2400.0 * atk_scale
				bm.enemies.append(boss)

				var elite: CombatUnit = Insurgent.create_unit(1)
				elite.display_name = "Восставший"
				elite.stats.max_hp = 180000.0 * hp_scale
				elite.stats.hp = elite.stats.max_hp
				elite.stats.atk = 1800.0 * atk_scale
				bm.enemies.append(elite)

				for ally in bm.allies:
					ally.stats.crit_dmg += 0.30
				bm.log_message("🚩 Оплот восстания | Аномалия «Эхо революции»: Крит. урон отряда +30%! Пока на поле есть Дух Памяти, весь отряд игнорирует 20% защиты, а пробитие уязвимости наносит дополнительный урон в 100% базового пробития!")

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
			soldier.stats.max_hp = 3200.0
			soldier.stats.hp = 3200.0
			soldier.stats.atk = 600.0
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
			soldier.stats.atk = 1100.0
			bm.enemies.append(soldier)
		bm.log_message("⚔ Уровень 2: Обучение Уязвимостям и Щитам Данилла")

	elif level_id == "level_3":
		bm.skill_points = 2
		bm.skill_points_changed.emit(2)
		bm.enemies.clear()
		var elite: CombatUnit = VoidElite.create_unit()
		elite.stats.max_hp *= 0.70
		elite.stats.hp = elite.stats.max_hp
		elite.max_toughness = 90.0
		elite.toughness = 90.0
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
			elite.stats.max_hp *= 0.75
			elite.stats.hp = elite.stats.max_hp
			bm.enemies.append(elite)
		bm.log_message("⚔ Уровень 7: 3 Элитных Стража (75% ХП, Аномалия: Крит. Шанс +50% на 3 хода)")

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
		bm.log_message("⚔ Уровень 20: Силуэт в Маске и Солдаты Бездны")
	elif level_id == "level_21":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		var cleaner1: CombatUnit = CitadelCleaner.create_unit(0, true)
		cleaner1.stats.max_hp = 45000.0; cleaner1.stats.hp = cleaner1.stats.max_hp; cleaner1.stats.atk = 1800.0
		bm.enemies.append(cleaner1)
		var shoji_boss: CombatUnit = ShojiVz.create_unit()
		shoji_boss.stats.max_hp = 240000.0; shoji_boss.stats.hp = shoji_boss.stats.max_hp; shoji_boss.stats.atk = 2600.0
		bm.enemies.append(shoji_boss)
		var cleaner2: CombatUnit = CitadelCleaner.create_unit(2, true)
		cleaner2.stats.max_hp = 45000.0; cleaner2.stats.hp = cleaner2.stats.max_hp; cleaner2.stats.atk = 1800.0
		bm.enemies.append(cleaner2)
		bm.log_message("⚔ Уровень 21 (БОСС): Сёдзи ВЗ и Взломанные Чистильщики Цитадели")
	elif level_id == "level_22" or level_id == "boss_velzebul":
		is_tutorial = false
		bm.skill_points = 3
		bm.skill_points_changed.emit(3)
		bm.enemies.clear()
		var velz: CombatUnit = VelzebulBoss.create_unit()
		velz.stats.max_hp = 320000.0; velz.stats.hp = velz.stats.max_hp; velz.stats.atk = 2700.0
		bm.enemies.append(velz)
		var inf1: CombatUnit = Infected.create_unit()
		inf1.stats.max_hp = 50000.0; inf1.stats.hp = inf1.stats.max_hp; inf1.stats.atk = 1800.0
		bm.enemies.append(inf1)
		var inf2: CombatUnit = Infected.create_unit()
		inf2.stats.max_hp = 50000.0; inf2.stats.hp = inf2.stats.max_hp; inf2.stats.atk = 1800.0
		bm.enemies.append(inf2)
		bm.log_message("⚔ Уровень 22 (ВЕЛИКИЙ БОСС): Вельзевул — Повелительница Антиматерии")
# --- 2. ПОДПИСКА И УПРАВЛЕНИЕ ОБУЧЕНИЕМ В UI ---

static func init_tutorial_ui(battle_ui: Control) -> void:
	if not is_tutorial:
		return

	if current_level_id == "level_1":
		battle_ui.battle_manager.skill_points = 0
		battle_ui.battle_manager.skill_points_changed.emit(0)

	if guide_overlay and is_instance_valid(guide_overlay):
		guide_overlay.queue_free()
		guide_overlay = null

	guide_overlay = TutorialGuideOverlayScript.new()
	battle_ui.add_child(guide_overlay)
	
	# Для обратной совместимости со старыми ссылками
	tut_overlay = guide_overlay
	tut_panel = guide_overlay.dialog_panel
	tut_label = guide_overlay.text_label
	tut_next_btn = guide_overlay.btn_next
	tut_pointer = guide_overlay.pointer_label

	guide_overlay.set_skip_callback(func(): _show_skip_confirmation(battle_ui))

	if current_level_id == "level_1": _run_step_l1(1, battle_ui)
	elif current_level_id == "level_2": _run_step_l2(1, battle_ui)
	elif current_level_id == "level_3": _run_step_l3(1, battle_ui)
	elif current_level_id == "level_4": _run_step_l4(1, battle_ui)

# --- 3. ПОШАГОВЫЕ СЦЕНАРИИ ОБУЧЕНИЯ ---

# Сценарий Уровня 1 (Основы, Очки навыков, Взрывной урон, Баффы и Ульта)
static func _run_step_l1(step: int, battle_ui: Control) -> void:
	tut_step = step
	if not guide_overlay or not is_instance_valid(guide_overlay):
		return
	guide_overlay.hide_pointer()
	_lock_all_buttons(battle_ui, true)

	match step:
		1:
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"ПРИВЕТ! Готов погрузиться в тактические битвы?\n\nЭта игра — пошаговая боевая система. Вверху отображается [b]очередность ходов[/b] твоих бойцов и противников. При наведении на иконку видно полное имя.",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 1/13 ✦",
				true,
				"Далее ➔",
				func(): _on_next_pressed(battle_ui),
				true
			)
			if battle_ui.action_bar:
				guide_overlay.point_at(battle_ui.action_bar)
		2:
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Сейчас твой ход! У персонажа есть 4 умения: Базовая атака, Навык Q, Навык E и Сверхспособность.\n\nСейчас у тебя [b]0 Очков Навыков (ОН)[/b]. Базовая атака не требует очков и [b]восстанавливает +1 ОН[/b]!\n\nНажми [b]«Базовую атаку»[/b]!",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 2/13 ✦",
				false
			)
			battle_ui.btn_basic.disabled = false
			guide_overlay.point_at(battle_ui.btn_basic)
		3:
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Базовая атака — Одиночное умение, поражающее одну цель.\n\nНажми [b]«🎯 Выбрать целью»[/b] у центрального Солдата Пустоты!\n\n💡 [color=gold][b]Горячие клавиши:[/b][/color] переключать цели можно на клавиши [b]A[/b] и [b]D[/b] (или стрелочками), подтверждать на [b]Пробел/Enter[/b], а выбирать способности — на [b]Q, W, E, R[/b]!",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 3/13 ✦",
				false
			)
			var center_enemy: CombatUnit = battle_ui.battle_manager.enemies[1] if battle_ui.battle_manager.enemies.size() > 1 else battle_ui.battle_manager.enemies[0]
			_unlock_target_only(battle_ui, center_enemy)
		4:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Ты нанёс противнику урон! Каждая успешная атака накапливает [b]Энергию[/b], необходимую для применения мощной Сверхспособности.",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 4/13 ✦",
				true,
				"Далее ➔",
				func(): _on_next_pressed(battle_ui)
			)
			var vika: CombatUnit = battle_ui.battle_manager.allies[0]
			var vika_p = battle_ui._unit_panels.get(vika)
			if vika_p:
				guide_overlay.point_at(vika_p)
		5:
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Теперь наступает ход противников. При получении ударов твой персонаж также накапливает энергию!",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 5/13 ✦",
				true,
				"Понятно (пуск) ➔",
				func(): _on_next_pressed(battle_ui)
			)
			if battle_ui.action_bar:
				guide_overlay.point_at(battle_ui.action_bar)
		6:
			guide_overlay.dialog_panel.show()
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Противники нанесли урон, и шкала энергии почти полная! Благодаря прошлой базовой атаке у тебя есть [b]1 Очко Навыков[/b].\n\nНажми [b]Навык Q[/b], чтобы атаковать сразу группу врагов!",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 6/13 ✦",
				false
			)
			battle_ui.btn_skill.disabled = false
			guide_overlay.point_at(battle_ui.btn_skill)
		7:
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Навык Q Вики — [b]Взрывная атака[/b]. Она бьёт сильно по центру и слабее по соседним целям.\n\nВыбери [b]центральную цель[/b], чтобы задеть всех троих!",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 7/13 ✦",
				false
			)
			var center_enemy: CombatUnit = battle_ui.battle_manager.enemies[1] if battle_ui.battle_manager.enemies.size() > 1 else battle_ui.battle_manager.enemies[0]
			_unlock_target_only(battle_ui, center_enemy)
		8:
			guide_overlay.dialog_panel.show()
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			var vika: CombatUnit = battle_ui.battle_manager.allies[0]
			battle_ui.battle_manager.current_unit = vika
			battle_ui.battle_manager._waiting_for_player = true
			vika.energy = vika.max_energy
			battle_ui._refresh_unit_panel(vika)
			battle_ui.battle_manager.skill_points = mini(battle_ui.battle_manager.skill_points + 2, CombatConstants.MAX_SKILL_POINTS)
			battle_ui.battle_manager.skill_points_changed.emit(battle_ui.battle_manager.skill_points)
			battle_ui._update_action_buttons(vika)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Превосходно! У тебя зарядилась Сверхспособность, но перед её ударом давай усилим Вику. Я добавил тебе Очки Навыков.\n\nНавык E Вики тратит её ХП, но даёт взамен огромный [b]бонус Силы Атаки[/b]!\n\nНажми [b]Навык E[/b]!",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 8/13 ✦",
				false
			)
			battle_ui.btn_skill_e.disabled = false
			guide_overlay.point_at(battle_ui.btn_skill_e)
		9:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			var vika: CombatUnit = battle_ui.battle_manager.allies[0]
			vika.energy = vika.max_energy
			battle_ui._refresh_unit_panel(vika)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Супер! Вика получила бафф силы атаки. Чтобы посмотреть текущие параметры, длительность эффектов и умения, нажми [b]«Инфо»[/b] на карточке Вики!",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 9/13 ✦",
				false
			)
			_unlock_card_button(battle_ui, "vika", "InfoButton")
		10:
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Это окно характеристик и статусов. Бафф Навыка E длится [b]3 хода[/b] Вики и уменьшается каждый её ход.\n\nЗакрой окно инфо, нажав на крестик (✕)!",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 10/13 ✦",
				false
			)
			if battle_ui._btn_inspect_header_close:
				battle_ui._btn_inspect_header_close.disabled = false
				guide_overlay.point_at(battle_ui._btn_inspect_header_close)
			elif battle_ui.btn_close_inspect:
				battle_ui.btn_close_inspect.disabled = false
				guide_overlay.point_at(battle_ui.btn_close_inspect)
		11:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			var vika: CombatUnit = battle_ui.battle_manager.allies[0]
			vika.energy = vika.max_energy
			battle_ui._refresh_unit_panel(vika)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Смотри! Сверхспособность готова к бою! Её можно применить [b]В ЛЮБОЙ МОМЕНТ[/b], даже во время хода противника, и она не тратит ходы баффов.\n\nЖми [b]Сверхспособность[/b] на карточке Вики!\n\n💡 [color=gold][b]Горячие клавиши:[/b][/color] Сверхспособности персонажей можно активировать на клавиши [b]1, 2, 3, 4[/b] (по номеру позиции в отряде)!",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 11/13 ✦",
				false
			)
			_unlock_card_button(battle_ui, "vika", "UltButtonOnCard")
		12:
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Сверхспособность Вики — мощнейшая Взрывная атака. Выбери [b]центральную цель[/b]!",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 12/13 ✦",
				false
			)
			var center_enemy: CombatUnit = battle_ui.battle_manager.enemies[1] if battle_ui.battle_manager.enemies.size() > 1 else battle_ui.battle_manager.enemies[0]
			_unlock_target_only(battle_ui, center_enemy)
		13:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			guide_overlay.hide_pointer()
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Потрясающе! Вика вошла в состояние [b]«Пробуждение»[/b]: теперь она восстанавливает здоровье в начале каждого своего хода!\n\nТвоя задача — добить оставшихся врагов. [b]В БОЙ![/b]",
				"✦ ОБУЧЕНИЕ 1 • ЭТАП 13/13 ✦",
				true,
				"В бой! ⚔",
				func(): _on_next_pressed(battle_ui)
			)

# Сценарий Уровня 2 (Данилл, Стойкость, Уязвимости и Щиты)
static func _run_step_l2(step: int, battle_ui: Control) -> void:
	tut_step = step
	if not guide_overlay or not is_instance_valid(guide_overlay):
		return
	guide_overlay.hide_pointer()
	_lock_all_buttons(battle_ui, true)

	match step:
		1:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"У каждого персонажа свой [b]Путь[/b] (роль) и [b]Элемент[/b] атаки. У противников над шкалой ХП отображается белая полоса — [b]Стойкость[/b].\n\nПосмотри уязвимости врага в его [b]Инфо[/b]!",
				"✦ ОБУЧЕНИЕ 2 • ЭТАП 1/11 ✦",
				false,
				"Далее ➔",
				Callable(),
				true
			)
			_unlock_enemy_info_button(battle_ui)
		2:
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Внизу показаны [b]Уязвимости[/b] противника (Огонь, Лед, Электро). У Вики — Квантовый элемент, у Данилла — Огненный. Элементы, к которым нет уязвимости, не снижают стойкость и наносят меньше урона!\n\nЗакрой окно инфо.",
				"✦ ОБУЧЕНИЕ 2 • ЭТАП 2/11 ✦",
				false
			)
			if battle_ui._btn_inspect_header_close:
				battle_ui._btn_inspect_header_close.disabled = false
				guide_overlay.point_at(battle_ui._btn_inspect_header_close)
			elif battle_ui.btn_close_inspect:
				battle_ui.btn_close_inspect.disabled = false
				guide_overlay.point_at(battle_ui.btn_close_inspect)
		3:
			battle_ui.battle_manager.remove_meta("tutorial_paused")
			var vika_unit: CombatUnit = battle_ui.battle_manager.allies[0]
			battle_ui.battle_manager.current_unit = vika_unit
			battle_ui.battle_manager._waiting_for_player = true
			battle_ui._update_action_buttons(vika_unit)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Сходи Базовой атакой на первого Солдата Пустоты!\n\n💡 [color=gold][b]Управление:[/b][/color]\n• Выбрать Базовую атаку можно клавишей [b]W[/b] (или кликом мышью).\n• Подтвердить атаку по цели: клавиша [b]Пробел[/b] или [b]Enter[/b]!\n• Переключать цели: клавиши [b]A[/b] и [b]D[/b].",
				"✦ ОБУЧЕНИЕ 2 • ЭТАП 3/11 ✦",
				false
			)
			battle_ui.btn_basic.disabled = false
			guide_overlay.point_at(battle_ui.btn_basic)
		4:
			battle_ui.battle_manager.remove_meta("tutorial_paused")
			var danill_unit: CombatUnit = battle_ui.battle_manager.allies[1] if battle_ui.battle_manager.allies.size() > 1 else battle_ui.battle_manager.allies[0]
			battle_ui.battle_manager.current_unit = danill_unit
			battle_ui.battle_manager._waiting_for_player = true
			battle_ui._update_action_buttons(danill_unit)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Стойкость врага не изменилась, ведь у него нет Квантовой уязвимости!\n\nТеперь ход Данилла. Его элемент — [b]Огонь[/b]!\nВыбери атаку клавишей [b]W[/b] и подтверди удар по этому же врагу клавишей [b]Пробел[/b] или [b]Enter[/b]!",
				"✦ ОБУЧЕНИЕ 2 • ЭТАП 4/11 ✦",
				false
			)
			battle_ui.btn_basic.disabled = false
			guide_overlay.point_at(battle_ui.btn_basic)
		5:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			guide_overlay.hide_pointer()
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Смотри — Стойкость врага снизилась! Данилл пробил её огнём. Когда стойкость падает до 0, враг получает [b]урон Пробития[/b], а его ход откладывается!",
				"✦ ОБУЧЕНИЕ 2 • ЭТАП 5/11 ✦",
				true,
				"Далее ➔",
				func(): _on_next_pressed(battle_ui)
			)
		6:
			battle_ui.battle_manager.remove_meta("tutorial_paused")
			var vika_unit: CombatUnit = battle_ui.battle_manager.allies[0]
			battle_ui.battle_manager.current_unit = vika_unit
			battle_ui.battle_manager._waiting_for_player = true
			battle_ui._update_action_buttons(vika_unit)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Теперь нажми [b]Навык E Вики[/b], чтобы усилить её атаку перед следующим ударом!",
				"✦ ОБУЧЕНИЕ 2 • ЭТАП 6/11 ✦",
				false
			)
			battle_ui.btn_skill_e.disabled = false
			guide_overlay.point_at(battle_ui.btn_skill_e)
		7:
			battle_ui.battle_manager.remove_meta("tutorial_paused")
			var danill_unit: CombatUnit = battle_ui.battle_manager.allies[1] if battle_ui.battle_manager.allies.size() > 1 else battle_ui.battle_manager.allies[0]
			battle_ui.battle_manager.current_unit = danill_unit
			battle_ui.battle_manager._waiting_for_player = true
			battle_ui._update_action_buttons(danill_unit)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Вика потратила здоровье. Данилл следует [b]Пути Сохранения[/b] — он защищает союзников щитами.\n\nНажми [b]Навык Q Данилла[/b]!",
				"✦ ОБУЧЕНИЕ 2 • ЭТАП 7/11 ✦",
				false
			)
			battle_ui.btn_skill.disabled = false
			guide_overlay.point_at(battle_ui.btn_skill)
		8:
			battle_ui.battle_manager.remove_meta("tutorial_paused")
			var vika_unit: CombatUnit = battle_ui.battle_manager.allies[0]
			battle_ui.battle_manager.current_unit = vika_unit
			battle_ui.battle_manager._waiting_for_player = true
			battle_ui._update_action_buttons(vika_unit)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Вика под щитом! Сходи за Вику Базовой атакой ([b]W[/b] + [b]Пробел/Enter[/b]), чтобы восстановить Очки навыков для Данилла!",
				"✦ ОБУЧЕНИЕ 2 • ЭТАП 8/11 ✦",
				false
			)
			battle_ui.btn_basic.disabled = false
			guide_overlay.point_at(battle_ui.btn_basic)
		9:
			battle_ui.battle_manager.remove_meta("tutorial_paused")
			var danill_unit: CombatUnit = battle_ui.battle_manager.allies[1] if battle_ui.battle_manager.allies.size() > 1 else battle_ui.battle_manager.allies[0]
			battle_ui.battle_manager.current_unit = danill_unit
			battle_ui.battle_manager._waiting_for_player = true
			battle_ui._update_action_buttons(danill_unit)
			battle_ui.battle_manager.skill_points = mini(battle_ui.battle_manager.skill_points + 2, CombatConstants.MAX_SKILL_POINTS)
			battle_ui.battle_manager.skill_points_changed.emit(battle_ui.battle_manager.skill_points)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Навык E Данилла накладывает [b]Провокацию[/b] на всех врагов на 3 хода. Враги будут бить только Данилла, сохраняя жизнь союзникам!\n\nНажми [b]Навык E Данилла[/b]!",
				"✦ ОБУЧЕНИЕ 2 • ЭТАП 9/11 ✦",
				false
			)
			battle_ui.btn_skill_e.disabled = false
			guide_overlay.point_at(battle_ui.btn_skill_e)
		10:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			for ally in battle_ui.battle_manager.allies:
				if ally.id == "danill":
					ally.energy = ally.max_energy
					battle_ui._refresh_unit_panel(ally)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Сверхспособность Данилла накладывает мощный щит на [b]ВСЕХ союзников разом[/b]!\n\nНажми [b]Сверхспособность Данилла[/b] на его карточке!\n\n💡 [color=gold][b]Горячие клавиши:[/b][/color] Нажми [b]2[/b] для мгновенной активации!",
				"✦ ОБУЧЕНИЕ 2 • ЭТАП 10/11 ✦",
				false
			)
			_unlock_card_button(battle_ui, "danill", "UltButtonOnCard")
		11:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			guide_overlay.hide_pointer()
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Супер! Вся команда защищена, а враги заблокированы провокацией. Победи противников, чтобы принять Данилла в команду!",
				"✦ ОБУЧЕНИЕ 2 • ЭТАП 11/11 ✦",
				true,
				"В бой! ⚔",
				func(): _on_next_pressed(battle_ui)
			)

# Сценарий Уровня 3 (Каори, Путь Охоты, Фракции и Пробитие)
static func _run_step_l3(step: int, battle_ui: Control) -> void:
	tut_step = step
	if not guide_overlay or not is_instance_valid(guide_overlay):
		return
	guide_overlay.hide_pointer()
	_lock_all_buttons(battle_ui, true)

	match step:
		1:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Это Каори! Она следует [b]Пути Охоты[/b] — её умения бьют сосредоточенным уроном по одиночным целям.\n\nНажми на кнопку [b]«Синергии»[/b] вверху экрана!",
				"✦ ОБУЧЕНИЕ 3 • ЭТАП 1/7 ✦",
				false,
				"Далее ➔",
				Callable(),
				true
			)
			_unlock_top_button(battle_ui, "btn_factions")
		2:
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Персонажи из одной [b]Фракции[/b] усиливают друг друга. Каори и Данилл — из «Рассвета хаоса» (+15% СА и ХП). Вика — из «Академии» (+1 ОН на старте боя).\n\nЗакрой окно Синергий.",
				"✦ ОБУЧЕНИЕ 3 • ЭТАП 2/7 ✦",
				false
			)
			if battle_ui.factions_panel:
				var f_close = battle_ui.factions_panel.find_child("Button", true, false)
				if f_close:
					f_close.disabled = false
					guide_overlay.point_at(f_close)
				else:
					_unlock_top_button(battle_ui, "btn_factions")
			else:
				_unlock_top_button(battle_ui, "btn_factions")
		3:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			guide_overlay.hide_pointer()
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Основной урон Каори раскрывается при [b]Пробитии уязвимости[/b]. Её способности наносят огромный Дополнительный урон по пробитой стойкости врага!\n\nДавай подготовим пробитие!",
				"✦ ОБУЧЕНИЕ 3 • ЭТАП 3/7 ✦",
				true,
				"Далее ➔",
				func(): _on_next_pressed(battle_ui)
			)
		4:
			battle_ui.battle_manager.remove_meta("tutorial_paused")
			var kaori_unit: CombatUnit = null
			for a in battle_ui.battle_manager.allies:
				if a.id == "kaori":
					kaori_unit = a
					break
			if kaori_unit == null and not battle_ui.battle_manager.allies.is_empty():
				kaori_unit = battle_ui.battle_manager.allies[0]
			battle_ui.battle_manager.current_unit = kaori_unit
			battle_ui.battle_manager._waiting_for_player = true
			kaori_unit.action_value = 0.0
			battle_ui._update_action_buttons(kaori_unit)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Сходи Базовой атакой Каори на Элитного Стража!\n\n💡 [color=gold][b]Управление:[/b][/color]\n• Выбрать атаку: клавиша [b]W[/b] (или клик мышью).\n• Подтвердить удар: клавиша [b]Пробел[/b] или [b]Enter[/b]!",
				"✦ ОБУЧЕНИЕ 3 • ЭТАП 4/7 ✦",
				false
			)
			battle_ui.btn_basic.disabled = false
			guide_overlay.point_at(battle_ui.btn_basic)
		5:
			battle_ui.battle_manager.remove_meta("tutorial_paused")
			var kaori_unit: CombatUnit = null
			for a in battle_ui.battle_manager.allies:
				if a.id == "kaori":
					kaori_unit = a
					break
			if kaori_unit == null and not battle_ui.battle_manager.allies.is_empty():
				kaori_unit = battle_ui.battle_manager.allies[0]
			battle_ui.battle_manager.current_unit = kaori_unit
			battle_ui.battle_manager._waiting_for_player = true
			kaori_unit.action_value = 0.0
			for ally in battle_ui.battle_manager.allies:
				if ally.id == "kaori":
					ally.set_meta("weakness_concentration", true)
					battle_ui._refresh_unit_panel(ally)
			battle_ui._update_action_buttons(kaori_unit)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Базовая атака Каори превратилась в [b]Улучшенную Базовую атаку[/b]! Это Талант Каори: нанесение урона усиливает её следующую атаку.\n\nАтакуй Элитного Стража клавишей [b]W[/b] (или кликом) и подтверди на [b]Пробел/Enter[/b]!",
				"✦ ОБУЧЕНИЕ 3 • ЭТАП 5/7 ✦",
				false
			)
			battle_ui.btn_basic.disabled = false
			battle_ui.btn_enhanced_basic.disabled = false
			var btn_target = battle_ui.btn_enhanced_basic if battle_ui.btn_enhanced_basic.visible else battle_ui.btn_basic
			guide_overlay.point_at(btn_target)
		6:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			guide_overlay.hide_pointer()
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Стойкость врага [b]ПРОБИТА[/b]! Пока действует пробитие, получаемый им урон увеличен. Враг восстановит стойкость в свой следующий ход, поэтому атакуй на максимуме!",
				"✦ ОБУЧЕНИЕ 3 • ЭТАП 6/7 ✦",
				true,
				"Далее ➔",
				func(): _on_next_pressed(battle_ui)
			)
		7:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			guide_overlay.hide_pointer()
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Добей Элитного Стража, чтобы принять Каори в отряд!",
				"✦ ОБУЧЕНИЕ 3 • ЭТАП 7/7 ✦",
				true,
				"В бой! ⚔",
				func(): _on_next_pressed(battle_ui)
			)

# Сценарий Уровня 4 (Боевой Экзамен)
static func _run_step_l4(step: int, battle_ui: Control) -> void:
	tut_step = step
	if not guide_overlay or not is_instance_valid(guide_overlay):
		return
	guide_overlay.hide_pointer()
	_lock_all_buttons(battle_ui, true)

	match step:
		1:
			battle_ui.battle_manager.set_meta("tutorial_paused", true)
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"Финальный боевой экзамен! Победи этого Элитного стража и Солдатов Пустоты не более чем за [b]10 Циклов[/b]!\n\nСчетчик текущего цикла находится здесь.",
				"✦ ОБУЧЕНИЕ 4 • ЭТАП 1/2 ✦",
				true,
				"Далее ➔",
				func(): _on_next_pressed(battle_ui),
				true
			)
			if battle_ui.turn_label:
				guide_overlay.point_at(battle_ui.turn_label)
		2:
			guide_overlay.set_dialog(
				"🧭 Наставник",
				"В правом верхнем углу доступны [b]«Графики урона»[/b] для подробной аналитики боя.\n\nПокажи всё, чему научился! Удачи!",
				"✦ ОБУЧЕНИЕ 4 • ЭТАП 2/2 ✦",
				true,
				"В бой! ⚔",
				func(): _on_next_pressed(battle_ui)
			)
			_unlock_top_button(battle_ui, "btn_graphs")

static func _on_next_pressed(battle_ui: Control) -> void:
	if current_level_id == "level_1":
		match tut_step:
			1: _run_step_l1(2, battle_ui)
			4: _run_step_l1(5, battle_ui)
			5:
				if guide_overlay:
					guide_overlay.hide_pointer()
					guide_overlay.dialog_panel.hide()
				battle_ui.battle_manager.remove_meta("tutorial_paused")
			13:
				_finish_tutorial(battle_ui)

	elif current_level_id == "level_2":
		match tut_step:
			5:
				battle_ui.battle_manager.remove_meta("tutorial_paused")
				_run_step_l2(6, battle_ui)
			11:
				_finish_tutorial(battle_ui)

	elif current_level_id == "level_3":
		match tut_step:
			3:
				battle_ui.battle_manager.remove_meta("tutorial_paused")
				_run_step_l3(4, battle_ui)
			6:
				_run_step_l3(7, battle_ui)
			7:
				_finish_tutorial(battle_ui)

	elif current_level_id == "level_4":
		match tut_step:
			1:
				_run_step_l4(2, battle_ui)
			2:
				_finish_tutorial(battle_ui)

static func _finish_tutorial(battle_ui: Control) -> void:
	is_tutorial = false
	tut_step = 0
	battle_ui.battle_manager.remove_meta("tutorial_paused")
	if guide_overlay and is_instance_valid(guide_overlay):
		guide_overlay.queue_free()
		guide_overlay = null
	_lock_all_buttons(battle_ui, false)
	for unit in battle_ui._unit_panels:
		var panel: PanelContainer = battle_ui._unit_panels[unit]
		var vbox: VBoxContainer = panel.get_child(0)
		var target_btn: Button = vbox.get_node_or_null("TargetButton")
		if target_btn:
			target_btn.disabled = false
	if battle_ui.battle_manager.current_unit:
		battle_ui._update_action_buttons(battle_ui.battle_manager.current_unit)

# --- 4. РЕАКЦИИ НА ДЕЙСТВИЯ ИГРОКА ---

static func on_turn_started(unit: CombatUnit, battle_ui: Control) -> void:
	if not is_tutorial: return
	
	if current_level_id == "level_1":
		if unit.is_ally:
			if tut_step == 5: _run_step_l1(6, battle_ui)
			elif tut_step == 7: _run_step_l1(8, battle_ui)
			elif tut_step == 12: _run_step_l1(13, battle_ui)

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
		if action_type == "basic" and tut_step == 2:
			_run_step_l1(3, battle_ui)
		elif action_type == "basic_target_selected" and tut_step == 3:
			_run_step_l1(4, battle_ui)
		elif action_type == "skill_q" and tut_step == 6:
			_run_step_l1(7, battle_ui)
		elif action_type == "skill_q_target_selected" and tut_step == 7:
			_run_step_l1(8, battle_ui)
		elif action_type == "skill_e" and tut_step == 8:
			_run_step_l1(9, battle_ui)
		elif action_type == "inspect_open" and tut_step == 9:
			_run_step_l1(10, battle_ui)
		elif action_type == "inspect_close" and tut_step == 10:
			_run_step_l1(11, battle_ui)
		elif action_type == "ult_card" and tut_step == 11:
			_run_step_l1(12, battle_ui)
		elif action_type == "ult_target_selected" and tut_step == 12:
			_run_step_l1(13, battle_ui)

	elif current_level_id == "level_2":
		if action_type == "inspect_open" and tut_step == 1:
			_run_step_l2(2, battle_ui)
		elif action_type == "inspect_close" and tut_step == 2:
			_run_step_l2(3, battle_ui)
		elif action_type == "basic" and tut_step == 3:
			var target_enemy: CombatUnit = battle_ui.battle_manager.enemies[0]
			_unlock_target_only(battle_ui, target_enemy)
		elif action_type == "basic_target_selected" and tut_step == 3:
			pass
		elif action_type == "basic" and tut_step == 4:
			var target_enemy: CombatUnit = battle_ui.battle_manager.enemies[0]
			_unlock_target_only(battle_ui, target_enemy)
		elif action_type == "basic_target_selected" and tut_step == 4:
			_run_step_l2(5, battle_ui)
		elif action_type == "skill_e" and tut_step == 6:
			pass
		elif action_type == "skill_q" and tut_step == 7:
			var vika_unit: CombatUnit = battle_ui.battle_manager.allies[0]
			_unlock_target_only(battle_ui, vika_unit)
		elif action_type == "skill_q_target_selected" and tut_step == 7:
			pass
		elif action_type == "basic" and tut_step == 8:
			var target_enemy: CombatUnit = battle_ui.battle_manager.enemies[0]
			_unlock_target_only(battle_ui, target_enemy)
		elif action_type == "basic_target_selected" and tut_step == 8:
			pass
		elif action_type == "skill_e" and tut_step == 9:
			_run_step_l2(10, battle_ui)
		elif action_type == "ult_card" and tut_step == 10:
			_run_step_l2(11, battle_ui)

	elif current_level_id == "level_3":
		if action_type == "factions_toggle" and tut_step == 1:
			_run_step_l3(2, battle_ui)
		elif action_type == "factions_toggle" and tut_step == 2:
			_run_step_l3(3, battle_ui)
		elif action_type == "basic" and tut_step == 4:
			var elite = battle_ui.battle_manager.enemies[0]
			_unlock_target_only(battle_ui, elite)
		elif action_type == "basic_target_selected" and tut_step == 4:
			battle_ui.get_tree().create_timer(0.6).timeout.connect(func():
				if is_tutorial and current_level_id == "level_3" and tut_step == 4:
					_run_step_l3(5, battle_ui)
			)
		elif (action_type == "basic" or action_type == "enhanced_basic") and tut_step == 5:
			var elite = battle_ui.battle_manager.enemies[0]
			_unlock_target_only(battle_ui, elite)
		elif (action_type == "basic_target_selected" or action_type == "enhanced_basic_target_selected") and tut_step == 5:
			battle_ui.get_tree().create_timer(0.7).timeout.connect(func():
				if is_tutorial and current_level_id == "level_3" and tut_step == 5:
					_run_step_l3(6, battle_ui)
			)

# Реакция на пробитие стойкости (принимает любой Узел без ошибок типизации)
static func on_toughness_broken(caller_node = null) -> void:
	if is_tutorial and current_level_id == "level_3" and (tut_step == 5 or tut_step == 6):
		var battle_ui: Control = null
		if caller_node is Control:
			battle_ui = caller_node
		elif caller_node is Node and caller_node.get_parent() is Control:
			battle_ui = caller_node.get_parent() as Control
			
		if battle_ui:
			_run_step_l3(6, battle_ui)

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
			
# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ГЛОБАЛЬНОЙ БЛОКИРОВКИ И НАВИГАЦИИ ---

static func _set_text(txt: String) -> void:
	if guide_overlay:
		guide_overlay.text_label.text = txt
	elif tut_label:
		tut_label.text = txt

static func _show_pointer(pos: Vector2) -> void:
	if tut_pointer and is_instance_valid(tut_pointer):
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

		if vbox.has_node("TargetButton"):
			var target_btn: Button = vbox.get_node("TargetButton")
			if not locked:
				target_btn.disabled = false

	if "btn_skills_help" in battle_ui and battle_ui.btn_skills_help:
		battle_ui.btn_skills_help.disabled = locked
	if "btn_factions" in battle_ui and battle_ui.btn_factions:
		battle_ui.btn_factions.disabled = locked
	if "btn_graphs" in battle_ui and battle_ui.btn_graphs:
		battle_ui.btn_graphs.disabled = locked

	var give_up = battle_ui.find_child("BtnGiveUp", true, false)
	if give_up is Button:
		give_up.disabled = locked

static func _unlock_target_only(battle_ui: Control, target_unit: CombatUnit) -> void:
	var target_btn: Button = null
	var is_targeting_ally: bool = (target_unit != null and target_unit.is_ally)
	for u in battle_ui._unit_panels:
		var panel: PanelContainer = battle_ui._unit_panels[u]
		var vbox: VBoxContainer = panel.get_child(0)
		var btn: Button = vbox.get_node_or_null("TargetButton")
		if btn:
			var can_target: bool = (u.is_ally == is_targeting_ally and u.is_alive())
			btn.visible = can_target
			btn.disabled = false
			if u == target_unit:
				target_btn = btn
	if target_unit:
		battle_ui._selected_target_unit = target_unit
		battle_ui._update_targeting_visuals()
	if target_btn and guide_overlay:
		guide_overlay.point_at(target_btn)
	elif target_btn:
		_show_pointer(target_btn.global_position + Vector2(20, -50))

static func _unlock_card_button(battle_ui: Control, unit_id: String, btn_name: String) -> void:
	for unit in battle_ui._unit_panels:
		if unit.id == unit_id:
			var panel: PanelContainer = battle_ui._unit_panels[unit]
			var vbox: VBoxContainer = panel.get_child(0)
			var btn: Button = vbox.get_node(btn_name)
			btn.disabled = false
			if guide_overlay:
				guide_overlay.point_at(btn)
			else:
				_show_pointer(btn.global_position + Vector2(50, -50))

static func _unlock_enemy_info_button(battle_ui: Control) -> void:
	for unit in battle_ui._unit_panels:
		if not unit.is_ally and unit.is_alive():
			var panel: PanelContainer = battle_ui._unit_panels[unit]
			var vbox: VBoxContainer = panel.get_child(0)
			var btn: Button = vbox.get_node("InfoButton")
			btn.disabled = false
			if guide_overlay:
				guide_overlay.point_at(btn)
			else:
				_show_pointer(btn.global_position + Vector2(-30, -70))
			return

static func _unlock_top_button(battle_ui: Control, btn_var_name: String) -> void:
	if battle_ui.get(btn_var_name):
		var btn: Button = battle_ui.get(btn_var_name)
		btn.disabled = false
		if guide_overlay:
			guide_overlay.point_at(btn)
		else:
			_show_pointer(btn.global_position + Vector2(40, 40))

# --- ДИАЛОГ И ЛОГИКА ПРОПУСКА ОБУЧЕНИЯ В БОЮ ---

static func _show_skip_confirmation(battle_ui: Control) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	battle_ui.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 240)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	sb.border_color = Color(1.0, 0.85, 0.3, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "⚠ ПРОПУСК БОЕВОГО ОБУЧЕНИЯ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	var msg := Label.new()
	msg.text = "Вы уверены, что хотите пропустить боевое обучение? Вы сразу завершите 1–4 уровни, получите персонажей Данилла и Каори, 900 монет и перейдёте к обучению по меню!"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 14)
	vbox.add_child(msg)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)

	var confirm_btn := Button.new()
	confirm_btn.text = "Да, пропустить"
	confirm_btn.custom_minimum_size = Vector2(170, 46)
	confirm_btn.add_theme_font_size_override("font_size", 15)
	confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	confirm_btn.pressed.connect(func():
		overlay.queue_free()
		_execute_skip_combat_tutorial(battle_ui)
	)
	btn_hbox.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Отмена"
	cancel_btn.custom_minimum_size = Vector2(130, 46)
	cancel_btn.add_theme_font_size_override("font_size", 15)
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	btn_hbox.add_child(cancel_btn)

static func _execute_skip_combat_tutorial(battle_ui: Control) -> void:
	is_tutorial = false
	tut_step = 0
	TeamConfig.tutorial_skipped = true
	
	for lvl in ["level_1", "level_2", "level_3", "level_4"]:
		if not lvl in TeamConfig.completed_levels:
			TeamConfig.completed_levels.append(lvl)
	
	if not "danill" in TeamConfig.unlocked_characters:
		TeamConfig.unlocked_characters.append("danill")
	if not "kaori" in TeamConfig.unlocked_characters:
		TeamConfig.unlocked_characters.append("kaori")
		
	TeamConfig.coins += 900
	if TeamConfig.current_level_progress < 5:
		TeamConfig.current_level_progress = 5
	TeamConfig.save_game()
	
	if guide_overlay and is_instance_valid(guide_overlay):
		guide_overlay.queue_free()
		guide_overlay = null
		
	battle_ui.get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
