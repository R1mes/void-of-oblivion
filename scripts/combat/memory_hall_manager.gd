class_name MemoryHallManager
extends RefCounted

## Менеджер сезонного игрового режима «Зал воспоминаний» (Memory Hall).
## Отвечает за проверку времени сервера, расписание сезона, конфигурацию этажей,
## волны противников, модификаторы особенности и расчет звёзд.

# Окончание Сезона 1: 1 ноября 2026, 00:00 (GMT+3)
# В UTC это: 31 октября 2026, 21:00:00 = 1793480400
const SEASON_1_END_TIMESTAMP: int = 1793480400
const GMT3_OFFSET_SECONDS: int = 3 * 3600

const FLOORS: Dictionary = {
	1: {
		"id": 1,
		"title": "Бронзовый чертог",
		"level": 40,
		"waves": 1,
		"cycles": 14,
		"teams": 1,
	},
	2: {
		"id": 2,
		"title": "Серебряный чертог",
		"level": 55,
		"waves": 1,
		"cycles": 14,
		"teams": 1,
	},
	3: {
		"id": 3,
		"title": "Золотой чертог",
		"level": 70,
		"waves": 2,
		"cycles": 14,
		"teams": 1,
	},
	4: {
		"id": 4,
		"title": "Платиновый чертог",
		"level": 85,
		"waves": 2,
		"cycles": 28,
		"teams": 2,
	},
}

const ATTACK_TECHNIQUE_HEROES: Array[String] = [
	"pusenkov", "kaori", "shoji", "dasha", "vika", "rimes",
	"musienko", "joan", "joan_spirit", "isaac_admin", "shoji_swan",
	"lenskaya_antimatter", "lenskaya_sky_guardian", "rimes_ascension"
]

static func has_attack_technique(char_id: String) -> bool:
	return char_id in ATTACK_TECHNIQUE_HEROES

# Текущее время сервера (преобразуется в GMT+3)
static func get_server_time_unix() -> int:
	var offset: int = 0
	if Engine.has_singleton("NetworkManager"):
		var net = Engine.get_singleton("NetworkManager")
		if net != null and net.get("server_time_offset") != null:
			offset = int(net.get("server_time_offset"))
	return int(Time.get_unix_time_from_system()) + offset

static func is_season_active() -> bool:
	return get_server_time_unix() < SEASON_1_END_TIMESTAMP

static func get_season_end_datetime_gmt3() -> Dictionary:
	var gmt3_time: int = SEASON_1_END_TIMESTAMP + GMT3_OFFSET_SECONDS
	return Time.get_datetime_dict_from_unix_time(gmt3_time)

static func get_season_end_datetime_gmt3_str() -> String:
	var dt := get_season_end_datetime_gmt3()
	return "%02d.%02d.%d 00:00 (GMT+3)" % [dt.day, dt.month, dt.year]

static func get_current_server_time_gmt3_str() -> String:
	var gmt3_time: int = get_server_time_unix() + GMT3_OFFSET_SECONDS
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(gmt3_time)
	return "%02d.%02d.%d %02d:%02d:%02d (GMT+3)" % [dt.day, dt.month, dt.year, dt.hour, dt.minute, dt.second]

static func get_season_time_remaining_str() -> String:
	var now: int = get_server_time_unix()
	var diff: int = SEASON_1_END_TIMESTAMP - now
	if diff <= 0:
		return "Сезон завершён (режим заблокирован)"
	var days: int = diff / 86400
	var hours: int = (diff % 86400) / 3600
	var minutes: int = (diff % 3600) / 60
	if days > 0:
		return "%d дн. %d ч. %d мин." % [days, hours, minutes]
	elif hours > 0:
		return "%d ч. %d мин." % [hours, minutes]
	else:
		return "%d мин." % minutes

# Особенность Сезона 1: «Командная работа»
# Наносимый Эмпирейцами урон увеличивается на 30%, Скорость всех участников Рассвета Хаоса увеличивается на 20%.
static func apply_turbulence(bm: BattleManager) -> void:
	if bm == null:
		return
	bm.log_message("🌌 Особенность Зала воспоминаний «Командная работа» активирована:")
	bm.log_message("  ↳ Эмпирейцы: наносимый урон +30%!")
	bm.log_message("  ↳ Рассвет Хаоса: скорость всех участников +20%!")

	for ally in bm.allies:
		if ally == null:
			continue
		var is_emp: bool = FactionSystem.FACTIONS.has("empyreans") and (ally.id in FactionSystem.FACTIONS["empyreans"].members or ally.id.begins_with("marina") or ally.id.begins_with("dotseva"))
		var is_chaos: bool = FactionSystem.FACTIONS.has("chaos") and (ally.id in FactionSystem.FACTIONS["chaos"].members or ally.id.begins_with("lenskaya") or ally.id.begins_with("rimes"))

		if is_emp:
			ally.stats.damage_bonus += 0.30
			ally.set_meta("memory_hall_emp_buff", true)

		if is_chaos:
			var old_bonus: float = float(ally.stats.get_meta("spd_pct_bonus", 0.0))
			ally.stats.set_meta("spd_pct_bonus", old_bonus + 0.20)
			ally.set_meta("memory_hall_chaos_buff", true)
			ally.recalculate_action_value()

	bm.action_order_changed.emit()

# Расчёт звёзд за прохождение этажей
static func calculate_stars(floor_num: int, remaining_cycles: int) -> int:
	if floor_num in [1, 2, 3]:
		# Этажи 1-3: даётся 14 циклов
		if remaining_cycles >= 10:
			return 3
		elif remaining_cycles >= 7:
			return 2
		elif remaining_cycles >= 4:
			return 1
		else:
			return 0 # Меньше 4 циклов: 0 звезд, но этаж засчитан
	elif floor_num == 4:
		# Этаж 4: даётся 28 циклов
		if remaining_cycles >= 20:
			return 3
		elif remaining_cycles >= 16:
			return 2
		elif remaining_cycles >= 12:
			return 1
		else:
			return 0
	return 0

# Создание врагов для заданной волны и этажа
static func get_wave_enemies(floor_num: int, wave_num: int, half_num: int = 1) -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	match floor_num:
		1:
			# Этаж 1 (Бронза) - Универсальные враги, доступные для новичков
			var elite: CombatUnit = VoidElite.create_unit()
			_apply_stats(elite, 22000.0, 750.0, 300.0, 95.0, 90.0, 0)
			result.append(elite)

			var arm: CombatUnit = VoidArmored.create_unit()
			_apply_stats(arm, 18000.0, 650.0, 350.0, 92.0, 60.0, 1)
			result.append(arm)

			for i in 2:
				var sol: CombatUnit = VoidSoldier.create_unit()
				_apply_stats(sol, 8000.0, 500.0, 250.0, 90.0, 30.0, 2 + i)
				result.append(sol)

		2:
			# Этаж 2 (Серебро) - Универсальные враги + очищение/дебаффы
			var elite: CombatUnit = VoidElite.create_unit()
			_apply_stats(elite, 75000.0, 1400.0, 550.0, 100.0, 150.0, 0)
			result.append(elite)

			var cleaner: CombatUnit = CitadelCleaner.create_unit(1)
			_apply_stats(cleaner, 40000.0, 1200.0, 500.0, 102.0, 90.0, 1)
			result.append(cleaner)

			var ins: CombatUnit = Insurgent.create_unit(2)
			_apply_stats(ins, 35000.0, 1100.0, 480.0, 98.0, 80.0, 2)
			result.append(ins)

			var slave: CombatUnit = AntimatterSlave.create_unit(3)
			_apply_stats(slave, 28000.0, 1000.0, 450.0, 96.0, 70.0, 3)
			result.append(slave)

		3:
			# Этаж 3 (Золото) - 2 волны, требует хорошей прокачки!
			if wave_num == 1:
				var elite: CombatUnit = VoidElite.create_unit()
				_apply_stats(elite, 120000.0, 1900.0, 750.0, 102.0, 180.0, 0)
				result.append(elite)

				var cleaner: CombatUnit = CitadelCleaner.create_unit(1)
				_apply_stats(cleaner, 55000.0, 1400.0, 650.0, 104.0, 90.0, 1)
				result.append(cleaner)

				for i in 2:
					var arm: CombatUnit = VoidArmored.create_unit()
					_apply_stats(arm, 65000.0, 1500.0, 800.0, 95.0, 100.0, 2 + i)
					result.append(arm)
			else:
				# Волна 2: Серверный вирус + Твои воспоминания + Ужас ортофетамина
				var virus: CombatUnit = ServerVirus.create_unit()
				_apply_stats(virus, 220000.0, 2300.0, 950.0, 106.0, 270.0, 0)
				result.append(virus)

				var mem: CombatUnit = YourMemories.create_unit()
				_apply_stats(mem, 180000.0, 2100.0, 900.0, 105.0, 240.0, 1)
				result.append(mem)

				var horror: CombatUnit = OrtofetaminHorror.create_unit()
				_apply_stats(horror, 160000.0, 2000.0, 850.0, 104.0, 210.0, 2)
				result.append(horror)

		4:
			# Этаж 4 (Платина) - 2 отряда, по 2 волны в каждой половине!
			if half_num == 1:
				# Половина 1 (Отряд 1)
				if wave_num == 1:
					var elite: CombatUnit = VoidElite.create_unit()
					_apply_stats(elite, 150000.0, 2200.0, 850.0, 104.0, 200.0, 0)
					result.append(elite)

					for i in 2:
						var cleaner: CombatUnit = CitadelCleaner.create_unit(1 + i)
						_apply_stats(cleaner, 80000.0, 1700.0, 750.0, 105.0, 120.0, 1 + i)
						result.append(cleaner)

					var slave: CombatUnit = AntimatterSlave.create_unit(3)
					_apply_stats(slave, 70000.0, 1600.0, 700.0, 100.0, 100.0, 3)
					result.append(slave)
				else:
					# Волна 2: Силуэт в маске + Серверный вирус + Чистильщик Цитадели
					var mask: CombatUnit = MaskedSilhouette.create_unit()
					_apply_stats(mask, 300000.0, 2500.0, 1100.0, 110.0, 360.0, 0)
					result.append(mask)

					var virus: CombatUnit = ServerVirus.create_unit()
					_apply_stats(virus, 240000.0, 2400.0, 1000.0, 108.0, 300.0, 1)
					result.append(virus)

					var cleaner: CombatUnit = CitadelCleaner.create_unit(2)
					_apply_stats(cleaner, 90000.0, 1800.0, 800.0, 105.0, 120.0, 2)
					result.append(cleaner)
			else:
				# Половина 2 (Отряд 2)
				if wave_num == 1:
					var horror: CombatUnit = OrtofetaminHorror.create_unit()
					_apply_stats(horror, 160000.0, 2100.0, 850.0, 104.0, 210.0, 0)
					result.append(horror)

					for i in 2:
						var mutant: CombatUnit = OrthoMutant.create_unit()
						_apply_stats(mutant, 80000.0, 1600.0, 750.0, 100.0, 110.0, 1 + i)
						result.append(mutant)

					var inf: CombatUnit = Infected.create_unit()
					_apply_stats(inf, 70000.0, 1500.0, 700.0, 98.0, 90.0, 3)
					result.append(inf)
				else:
					# Волна 2: Кайл • Лидер восстания + Твои воспоминания + 2x Раб антиматерии
					var kyle: CombatUnit = KyleRebelLeader.create_unit(0)
					_apply_stats(kyle, 380000.0, 2600.0, 1150.0, 105.0, 380.0, 0)
					result.append(kyle)

					var mem: CombatUnit = YourMemories.create_unit()
					_apply_stats(mem, 220000.0, 2300.0, 1000.0, 106.0, 270.0, 1)
					result.append(mem)

					for i in 2:
						var slave: CombatUnit = AntimatterSlave.create_unit(2 + i)
						_apply_stats(slave, 90000.0, 1700.0, 800.0, 102.0, 120.0, 2 + i)
						result.append(slave)

	return result

static func _apply_stats(unit: CombatUnit, hp: float, atk: float, def_val: float, spd_val: float, toughness_val: float, slot: int) -> void:
	unit.slot_index = slot
	unit.stats.max_hp = hp
	unit.stats.hp = hp
	unit.stats.atk = atk
	unit.stats.def = def_val
	unit.stats.spd = spd_val
	unit.toughness = toughness_val
	unit.max_toughness = toughness_val

	unit.set_meta("base_hp_original", hp)
	unit.set_meta("base_atk_original", atk)
	unit.set_meta("base_def_original", def_val)
	unit.set_meta("base_spd_original", spd_val)
	unit.recalculate_action_value()

# Данные разведки для окна просмотра противников в лобби
static func get_floor_intel(floor_num: int) -> Dictionary:
	var info := {
		"floor": floor_num,
		"title": "",
		"cycles_limit": 14,
		"halves": []
	}

	match floor_num:
		1:
			info.title = "Этаж 1: Бронза"
			info.cycles_limit = 14
			info.halves = [
				{
					"name": "Основная битва",
					"waves": [
						{
							"wave": 1,
							"enemies": [
								{"name": "Элитный Страж", "hp": "22 000", "element": CombatConstants.Element.ICE, "weaknesses": [CombatConstants.Element.ICE, CombatConstants.Element.PHYSICAL, CombatConstants.Element.IMAGINARY, CombatConstants.Element.WIND], "is_elite": true},
								{"name": "Бронированный Рыцарь", "hp": "18 000", "element": CombatConstants.Element.PHYSICAL, "weaknesses": [CombatConstants.Element.PHYSICAL, CombatConstants.Element.ICE, CombatConstants.Element.FIRE], "is_elite": false},
								{"name": "Солдат Пустоты (x2)", "hp": "8 000", "element": CombatConstants.Element.QUANTUM, "weaknesses": [CombatConstants.Element.ICE, CombatConstants.Element.FIRE, CombatConstants.Element.LIGHTNING], "is_elite": false},
							]
						}
					]
				}
			]
		2:
			info.title = "Этаж 2: Серебро"
			info.cycles_limit = 14
			info.halves = [
				{
					"name": "Основная битва",
					"waves": [
						{
							"wave": 1,
							"enemies": [
								{"name": "Элитный Страж", "hp": "75 000", "element": CombatConstants.Element.ICE, "weaknesses": [CombatConstants.Element.ICE, CombatConstants.Element.PHYSICAL, CombatConstants.Element.IMAGINARY, CombatConstants.Element.WIND], "is_elite": true},
								{"name": "Чистильщик Цитадели", "hp": "40 000", "element": CombatConstants.Element.FIRE, "weaknesses": [CombatConstants.Element.WIND, CombatConstants.Element.FIRE], "is_elite": false},
								{"name": "Повстанец", "hp": "35 000", "element": CombatConstants.Element.PHYSICAL, "weaknesses": [CombatConstants.Element.PHYSICAL, CombatConstants.Element.FIRE, CombatConstants.Element.LIGHTNING], "is_elite": false},
								{"name": "Раб Антиматерии", "hp": "28 000", "element": CombatConstants.Element.QUANTUM, "weaknesses": [CombatConstants.Element.QUANTUM, CombatConstants.Element.ICE, CombatConstants.Element.PHYSICAL], "is_elite": false},
							]
						}
					]
				}
			]
		3:
			info.title = "Этаж 3: Золото"
			info.cycles_limit = 14
			info.halves = [
				{
					"name": "Основная битва",
					"waves": [
						{
							"wave": 1,
							"enemies": [
								{"name": "Элитный Страж", "hp": "120 000", "element": CombatConstants.Element.ICE, "weaknesses": [CombatConstants.Element.ICE, CombatConstants.Element.PHYSICAL, CombatConstants.Element.IMAGINARY, CombatConstants.Element.WIND], "is_elite": true},
								{"name": "Чистильщик Цитадели", "hp": "55 000", "element": CombatConstants.Element.FIRE, "weaknesses": [CombatConstants.Element.WIND, CombatConstants.Element.FIRE], "is_elite": false},
								{"name": "Бронированный Рыцарь (x2)", "hp": "65 000", "element": CombatConstants.Element.PHYSICAL, "weaknesses": [CombatConstants.Element.PHYSICAL, CombatConstants.Element.ICE, CombatConstants.Element.FIRE], "is_elite": false},
							]
						},
						{
							"wave": 2,
							"enemies": [
								{"name": "Серверный Вирус", "hp": "220 000", "element": CombatConstants.Element.LIGHTNING, "weaknesses": [CombatConstants.Element.PHYSICAL, CombatConstants.Element.LIGHTNING, CombatConstants.Element.WIND], "is_elite": true, "note": "Блокирует навыки файрволом"},
								{"name": "Твои Воспоминания", "hp": "180 000", "element": CombatConstants.Element.IMAGINARY, "weaknesses": [CombatConstants.Element.QUANTUM, CombatConstants.Element.ICE, CombatConstants.Element.LIGHTNING], "is_elite": true, "note": "Призма памяти и замедление"},
								{"name": "Ужас Ортофетамина", "hp": "160 000", "element": CombatConstants.Element.PHYSICAL, "weaknesses": [CombatConstants.Element.PHYSICAL, CombatConstants.Element.LIGHTNING, CombatConstants.Element.ICE], "is_elite": true, "note": "Призыв мутантов и ярость"},
							]
						}
					]
				}
			]
		4:
			info.title = "Этаж 4: Платина"
			info.cycles_limit = 28
			info.halves = [
				{
					"name": "Половина 1 (Отряд 1)",
					"waves": [
						{
							"wave": 1,
							"enemies": [
								{"name": "Элитный Страж", "hp": "150 000", "element": CombatConstants.Element.ICE, "weaknesses": [CombatConstants.Element.ICE, CombatConstants.Element.PHYSICAL, CombatConstants.Element.IMAGINARY, CombatConstants.Element.WIND], "is_elite": true},
								{"name": "Чистильщик Цитадели (x2)", "hp": "80 000", "element": CombatConstants.Element.FIRE, "weaknesses": [CombatConstants.Element.WIND, CombatConstants.Element.FIRE], "is_elite": false},
								{"name": "Раб Антиматерии", "hp": "70 000", "element": CombatConstants.Element.QUANTUM, "weaknesses": [CombatConstants.Element.QUANTUM, CombatConstants.Element.ICE, CombatConstants.Element.PHYSICAL], "is_elite": false},
							]
						},
						{
							"wave": 2,
							"enemies": [
								{"name": "Силуэт в Маске", "hp": "300 000 (Фаза 1+2)", "element": CombatConstants.Element.QUANTUM, "weaknesses": [CombatConstants.Element.LIGHTNING, CombatConstants.Element.QUANTUM, CombatConstants.Element.IMAGINARY], "is_elite": true, "note": "Фазовый переход и клоны"},
								{"name": "Серверный Вирус", "hp": "240 000", "element": CombatConstants.Element.LIGHTNING, "weaknesses": [CombatConstants.Element.PHYSICAL, CombatConstants.Element.LIGHTNING, CombatConstants.Element.WIND], "is_elite": true},
								{"name": "Чистильщик Цитадели", "hp": "90 000", "element": CombatConstants.Element.FIRE, "weaknesses": [CombatConstants.Element.WIND, CombatConstants.Element.FIRE], "is_elite": false},
							]
						}
					]
				},
				{
					"name": "Половина 2 (Отряд 2)",
					"waves": [
						{
							"wave": 1,
							"enemies": [
								{"name": "Ужас Ортофетамина", "hp": "160 000", "element": CombatConstants.Element.PHYSICAL, "weaknesses": [CombatConstants.Element.PHYSICAL, CombatConstants.Element.LIGHTNING, CombatConstants.Element.ICE], "is_elite": true},
								{"name": "Орто-мутант (x2)", "hp": "80 000", "element": CombatConstants.Element.PHYSICAL, "weaknesses": [CombatConstants.Element.PHYSICAL, CombatConstants.Element.FIRE], "is_elite": false},
								{"name": "Заражённый", "hp": "70 000", "element": CombatConstants.Element.WIND, "weaknesses": [CombatConstants.Element.WIND, CombatConstants.Element.ICE], "is_elite": false},
							]
						},
						{
							"wave": 2,
							"enemies": [
								{"name": "Кайл • Лидер Восстания", "hp": "380 000 (Фаза 1+2)", "element": CombatConstants.Element.QUANTUM, "weaknesses": [CombatConstants.Element.WIND, CombatConstants.Element.QUANTUM, CombatConstants.Element.PHYSICAL], "is_elite": true, "note": "Вуаль стойкости (-45% урона) и призывы"},
								{"name": "Твои Воспоминания", "hp": "220 000", "element": CombatConstants.Element.IMAGINARY, "weaknesses": [CombatConstants.Element.QUANTUM, CombatConstants.Element.ICE, CombatConstants.Element.LIGHTNING], "is_elite": true},
								{"name": "Раб Антиматерии (x2)", "hp": "90 000", "element": CombatConstants.Element.QUANTUM, "weaknesses": [CombatConstants.Element.QUANTUM, CombatConstants.Element.ICE, CombatConstants.Element.PHYSICAL], "is_elite": false},
							]
						}
					]
				}
			]

	info["is_two_teams"] = (floor_num == 4)
	info["cycles"] = info.cycles_limit
	if floor_num < 4 and not info.halves.is_empty():
		info["waves"] = info.halves[0].get("waves", [])
	elif floor_num == 4 and info.halves.size() >= 2:
		info["half1_waves"] = info.halves[0].get("waves", [])
		info["half2_waves"] = info.halves[1].get("waves", [])

	return info
