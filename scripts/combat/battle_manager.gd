class_name BattleManager
extends Node

const ServerVirus = preload("res://scripts/enemies/server_virus.gd")
const OrthoMutant = preload("res://scripts/enemies/ortho_mutant.gd")
const Infected = preload("res://scripts/enemies/infected.gd")

signal battle_started
signal turn_started(unit: CombatUnit)
signal turn_ended(unit: CombatUnit)
signal skill_points_changed(points: int)
signal battle_ended(victory: bool)
signal log_added(message: String)
signal action_order_changed
signal unit_updated(unit: CombatUnit)
signal arya_changed(active: bool, remaining: float)
signal combat_text_spawned(unit: CombatUnit, text: String, color: Color, tag: String, is_crit: bool)
signal ult_targeting_requested(unit: CombatUnit)
signal enemies_reshuffled
signal screen_impact_requested(color: Color, intensity: float)

enum Phase { SETUP, RUNNING, VICTORY, DEFEAT }

var phase: Phase = Phase.SETUP
var allies: Array[CombatUnit] = []
var enemies: Array[CombatUnit] = []
var skill_points: int = 3
var current_unit: CombatUnit = null
var _last_attacker: CombatUnit = null
var _waiting_for_player: bool = false
var battle_mode: String = "custom"
var fiction_max_pool: int = 10 # 10 резервных солдат в "Чистом вымысле"
var fiction_defeated_count: int = 0 # Общий счетчик убитых солдат
# Массив уникальных противников, задетых за текущее действие (для таланта Жоана)
var action_hit_enemies: Array[CombatUnit] = []
var current_attack_action_id: int = 0
var current_fua_sequence_id: int = 0

func advance_fua_sequence() -> int:
	current_fua_sequence_id += 1
	return current_fua_sequence_id

# Буфер для таланта Сары (Векторы, которые копятся, пока талант активен)
var sara_buffered_vectors: int = 0
var sara_talent_active: bool = false # true, если мы "зафиксировались" на 100
var sara_talent_cooldown: int = 0

var arya_active: bool = false
var arya_remaining: float = 0.0
var sara_e4_used: bool = false
var dark_seal_holder: CombatUnit = null

# Трекер урона для графиков
var damage_tracker: Dictionary = {}

# Переменные для шкалы циклов
var accumulated_av: float = 0.0

# Очередь моментальных ультимейтов (Ultimate Queue)
var ult_queue: Array[CombatUnit] = []
var _is_processing_ult_queue: bool = false



func get_all_units() -> Array:
	var all: Array = []
	
	# Если на арене активна Дуэль 1 на 1 Раймса, на шкале ходов остаются ТОЛЬКО Раймс и его противник!
	if has_meta("rimes_duel_active") and get_meta("rimes_duel_active"):
		var rimes_ref := get_rimes_unit()
		if rimes_ref and rimes_ref.is_alive():
			all.append(rimes_ref)
		for enemy in enemies:
			if enemy.is_alive():
				all.append(enemy)
		return all
		
	all.append_array(allies)
	all.append_array(enemies)
	return all

func get_living_enemies() -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	for e in enemies:
		if e.is_alive():
			result.append(e)
	return result

func get_living_allies() -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	for a in allies:
		if a.is_alive():
			result.append(a)
	return result

func log_message(msg: String) -> void:
	log_added.emit(msg)

func record_damage(attacker: CombatUnit, amount: float) -> void:
	if attacker and attacker.is_ally:
		if not damage_tracker.has(attacker.id):
			damage_tracker[attacker.id] = 0.0
		damage_tracker[attacker.id] += amount

# Получение текущего игрового цикла по стандартам HSR
func get_current_cycles() -> int:
	if accumulated_av <= 150.0:
		return 0
	return 1 + int((accumulated_av - 150.0) / 100.0)

func _get_last_attacker_or_default() -> CombatUnit:
	if _last_attacker and _last_attacker.is_alive():
		return _last_attacker
	if not allies.is_empty():
		return allies[0]
	return enemies[0]

func get_marina_unit() -> CombatUnit:
	for a in allies:
		if a.id == MarinaAbilities.ID:
			return a
	return null

func get_sara_unit() -> CombatUnit:
	for a in allies:
		if a.id == SaraAbilities.ID:
			return a
	return null

func get_arseniy_unit() -> CombatUnit:
	for a in allies:
		if a.id == ArseniyAbilities.ID:
			return a
	return null
	
func get_shoji_unit() -> CombatUnit:
	for a in allies:
		if a.id == ShojiAbilities.ID:
			return a
	return null

func get_dasha_unit() -> CombatUnit:
	for a in allies:
		if a.id == "dasha":
			return a
	return null

func get_danila_unit() -> CombatUnit:
	for a in allies:
		if a.id == "danila" or a.id == "danill":
			return a
	return null
	
func get_dotseva_unit() -> CombatUnit:
	for a in allies:
		if a.id == "dotseva":
			return a
	return null
	
func get_milena_unit() -> CombatUnit:
	for a in allies:
		if a.id == "milena":
			return a
	return null

func start_battle(team_data: Array, initiator_id: String) -> void:
	phase = Phase.SETUP
	
	battle_mode = TeamConfig.battle_mode
	
	if battle_mode == "fiction":
		fiction_max_pool = 10
		fiction_defeated_count = 0
		log_message("⚔ Запуск режима «Чистый вымысел»: Победите 15 Солдат Пустоты!")
	elif battle_mode == "boss":
		log_message("⚔ Запуск режима «Босс-файт»: Битва с Повелителем Пустоты!")
	# Внутри start_battle() в battle_manager.gd (после создания противников):
	if battle_mode == "level_10":
		for enemy in enemies:
			enemy.add_speed_modifier(0.30, 0.0)
			enemy.recalculate_action_value()
		log_message("⚡ Аномалия 10 Уровня: Скорость всех противников увеличена на +30%!")
	allies.clear()
	enemies.clear()
	damage_tracker.clear()
	accumulated_av = 0.0
	skill_points = 3
	arya_active = false
	arya_remaining = 0.0
	sara_e4_used = false
	dark_seal_holder = null
	ult_queue.clear()
	_is_processing_ult_queue = false

	for member in team_data:
		var unit: CombatUnit = null
		match member.get("id", ""):
			MarinaAbilities.ID:
				unit = MarinaAbilities.create_unit(member.get("eidolon", 0))
			SaraAbilities.ID:
				unit = SaraAbilities.create_unit(member.get("eidolon", 0))
			ArseniyAbilities.ID:
				unit = ArseniyAbilities.create_unit(member.get("eidolon", 0))
			PusenkovAbilities.ID:
				unit = PusenkovAbilities.create_unit(member.get("eidolon", 0))
			KaoriAbilities.ID:
				unit = KaoriAbilities.create_unit(member.get("eidolon", 0))
			ShojiAbilities.ID:
				unit = ShojiAbilities.create_unit(member.get("eidolon", 0))
			"dasha":
				unit = DashaAbilities.create_unit(member.get("eidolon", 0))
			"danill":
				unit = DanillAbilities.create_unit(member.get("eidolon", 0))
			"vika":
				unit = VikaAbilities.create_unit(member.get("eidolon", 0))
			"dotseva":
				unit = DotsevaAbilities.create_unit(member.get("eidolon", 0))
			"milena":
				unit = MilenaAbilities.create_unit(member.get("eidolon", 0))
			"naama": # <--- ДОБАВИТЬ ЭТО
				unit = NaamaAbilities.create_unit(member.get("eidolon", 0))
			"lenskaya":
				unit = LenskayaAbilities.create_unit(member.get("eidolon", 0))
			"rimes":
				unit = RimesAbilities.create_unit(member.get("eidolon", 0))
			"isaac":
				unit = IsaacAbilities.create_unit(member.get("eidolon", 0))
			"keloist":
				unit = KeloistAbilities.create_unit(member.get("eidolon", 0))
			"musienko": 
				unit = MusienkoAbilities.create_unit(member.get("eidolon", 0))
			"joan":
				unit = JoanAbilities.create_unit(member.get("eidolon", 0))
			"jeff":
				unit = JeffAbilities.create_unit(member.get("eidolon", 0))
			"valramors":
				unit = ValramorsAbilities.create_unit(member.get("eidolon", 0))
			"joan_spirit":
				unit = JoanSpiritAbilities.create_unit(member.get("eidolon", 0))
			"isaac_admin":
				unit = IsaacAdminAbilities.create_unit(member.get("eidolon", 0))
			"sara_admin":
				unit = SaraAdminAbilities.create_unit(member.get("eidolon", 0))
			"arseniy_admin":
				unit = ArseniyAdminAbilities.create_unit(member.get("eidolon", 0))
			"dasha_admin":
				unit = DashaAdminAbilities.create_unit(member.get("eidolon", 0))
			"shoji_swan":
				unit = ShojiSwanAbilities.create_unit(member.get("eidolon", 0))
			"katarina":
				unit = KatarinaAbilities.create_unit(member.get("eidolon", 0))
			"dotseva_crimson_tears":
				unit = DotsevaCrimsonTearsAbilities.create_unit(member.get("eidolon", 0))
				
		if unit:
			unit.slot_index = allies.size()
			unit.set_meta("light_cone_id", member.get("light_cone", ""))
			
			# --- ПРИМЕНЕНИЕ ЭФФЕКТОВ РЕЛИКВИЙ НА СТАРТЕ БОЯ ---
			var relics_data: Dictionary = member.get("relics", {})
			_apply_relic_effects(unit, relics_data)
			
			allies.append(unit)
			
		
			
	for ally in allies:
		if ally.id == MarinaAbilities.ID:
			MarinaAbilities.apply_traces(ally, allies)
		elif ally.id == SaraAbilities.ID:
			SaraAbilities.apply_traces(ally)
		elif ally.id == ArseniyAbilities.ID:
			ArseniyAbilities.apply_traces(ally)
		elif ally.id == PusenkovAbilities.ID:
			PusenkovAbilities.apply_traces(ally)
		elif ally.id == KaoriAbilities.ID:
			KaoriAbilities.apply_traces(ally)
		elif ally.id == ShojiAbilities.ID:
			ShojiAbilities.apply_traces(ally)
		elif ally.id == "dasha":
			DashaAbilities.apply_traces(ally)
		elif ally.id == "danill":
			DanillAbilities.apply_traces(ally)
		elif ally.id == "vika":
			VikaAbilities.apply_traces(ally)
		elif ally.id == "dotseva":
			DotsevaAbilities.apply_traces(ally)
		elif ally.id == "milena":
			MilenaAbilities.apply_traces(ally, allies)
		elif ally.id == "naama":
			NaamaAbilities.apply_traces(ally)
		elif ally.id == "lenskaya": 
			LenskayaAbilities.apply_traces(ally)
		elif ally.id == "rimes": 
			RimesAbilities.apply_traces(ally)
		elif ally.id == "isaac": 
			IsaacAbilities.apply_traces(ally)
		elif ally.id == "keloist": 
			KeloistAbilities.apply_traces(ally)
		elif ally.id == "musienko": 
			MusienkoAbilities.apply_traces(ally)
		elif ally.id == "joan":
			JoanAbilities.apply_traces(ally)
		elif ally.id == "jeff":
			JeffAbilities.apply_traces(ally)
		elif ally.id == "valramors":
			ValramorsAbilities.apply_traces(ally)
		elif ally.id == "joan_spirit":
			JoanSpiritAbilities.apply_traces(ally, self)
		elif ally.id == "isaac_admin":
			IsaacAdminAbilities.apply_traces(ally, self)
		elif ally.id == "sara_admin":
			SaraAdminAbilities.apply_traces(ally, self)
		elif ally.id == "arseniy_admin":
			ArseniyAdminAbilities.apply_traces(ally, self)
		elif ally.id == "dasha_admin":
			DashaAdminAbilities.apply_traces(ally, self)
		elif ally.id == "shoji_swan":
			ShojiSwanAbilities.apply_traces(ally, self)
		elif ally.id == "katarina":
			KatarinaAbilities.apply_traces(ally, self)
		elif ally.id == "dotseva_crimson_tears":
			DotsevaCrimsonTearsAbilities.apply_traces(ally, self)
			
		_init_light_cone_effects(ally)

	# --- СПАВН ПРОТИВНИКОВ (Пропускается для Уровней и Данжей, так как их спавнит LevelManager) ---
	if battle_mode.begins_with("level_") or battle_mode.begins_with("dungeon_") or battle_mode.begins_with("planar_"):
		LevelManager.setup_level_battle(battle_mode, self)
	elif not TeamConfig.enemy_members.is_empty():
			for enemy_data in TeamConfig.enemy_members:
				var e_id = enemy_data.get("id", "")
				var enemy_unit: CombatUnit = null
				match e_id:
					VoidSoldier.ID:
						enemy_unit = VoidSoldier.create_unit()
					VoidElite.ID:
						enemy_unit = VoidElite.create_unit()
					"void_boss":
						enemy_unit = VoidBoss.create_unit()
					"void_armored":
						enemy_unit = VoidArmored.create_unit()
					"void_dummy":
						enemy_unit = VoidDummy.create_unit()
					"masked_silhouette":
						enemy_unit = MaskedSilhouette.create_unit()
					"server_virus":
						enemy_unit = ServerVirus.create_unit()
					"ortho_mutant":
						enemy_unit = OrthoMutant.create_unit()
					"infected":
						enemy_unit = Infected.create_unit()
					"ortho_spore":
						enemy_unit = OrthoMutant.create_spore()
				if enemy_unit:
					enemies.append(enemy_unit)
				else:
					enemies.append(VoidSoldier.create_unit())
					enemies.append(VoidSoldier.create_unit())
					enemies.append(VoidElite.create_unit())
	
	for enemy_unit in enemies:
		enemy_unit.set_meta("base_hp_original", enemy_unit.stats.max_hp)
		enemy_unit.set_meta("base_atk_original", enemy_unit.stats.atk)
		enemy_unit.set_meta("base_def_original", enemy_unit.stats.def)
		enemy_unit.set_meta("base_spd_original", enemy_unit.stats.spd)
		
	for unit in get_all_units():
		unit.recalculate_action_value()

	var initiator: CombatUnit = null
	for a in allies:
		if a.id == initiator_id:
			initiator = a
			break
	if initiator == null and not allies.is_empty():
		initiator = allies[0]
		
	# Внутри start_battle() -> перед вызовом _apply_all_techniques():
	# --- СИСТЕМА ФРАКЦИЙ: РАСЧЕТ И АКТИВАЦИЯ СИНЕРГИЙ ---
	var faction_counts := { "doomed": 0, "chaos": 0, "empyreans": 0, "academy": 0, "console": 0 }
	for ally in allies:
		for f_id in FactionSystem.FACTIONS:
			if ally.id in FactionSystem.FACTIONS[f_id].members:
				faction_counts[f_id] += 1
				
	set_meta("active_factions", faction_counts) # Сохраняем для UI-панели

	# 1. ОБРЕЧЁННЫЕ [2 / 3 / 4]
	var doomed_count: int = faction_counts["doomed"]
	var doomed_crit := 0.0
	if doomed_count == 2:
		doomed_crit = 0.15
	elif doomed_count >= 3:
		doomed_crit = 0.30
		
	if doomed_crit > 0.0:
		for ally in allies:
			ally.stats.crit_rate += doomed_crit
			ally.set_meta("faction_crit_bonus", doomed_crit)
			
	if doomed_count >= 4:
		for ally in allies:
			# ИСПРАВЛЕНО: Обращаемся к массиву участников обреченных в реестре фракций
			if ally.id in FactionSystem.FACTIONS["doomed"].members:
				ally.energy = ally.max_energy
				log_message("Обречённые [4]: Сверхспособность %s полностью заряжена!" % ally.display_name)

	# 2. РАССВЕТ ХАОСА [2 / 4]
	var chaos_count: int = faction_counts["chaos"]
	if chaos_count >= 2:
		for ally in allies:
			if ally.id in FactionSystem.FACTIONS["chaos"].members:
				# Записываем проценты баффов в метаданные
				ally.set_meta("faction_chaos_atk_pct", 0.15)
				ally.set_meta("faction_chaos_hp_pct", 0.15)
				ally.set_meta("faction_chaos_atk_hp", true)
				
				# ИСПРАВЛЕНО: Рассчитываем итоговое ХП аддитивно от оригинальной базы
				recalculate_unit_max_hp(ally)
				
	if chaos_count >= 4:
		for ally in allies:
			if ally.id in FactionSystem.FACTIONS["chaos"].members:
				ally.advance_action(50.0) 
				log_message("Рассвет Хаоса [4]: действие %s продвинуто на 50%%." % ally.display_name)

	# 3. ЭМПИРЕЙЦЫ [2 / 4]
	var empyreans_count: int = faction_counts["empyreans"]
	if empyreans_count >= 2:
		for ally in allies:
			if ally.id in FactionSystem.FACTIONS["empyreans"].members:
				# Записываем +30% СА в метаданные для аддитивного буста эффективной атаки
				ally.set_meta("faction_empyrean_atk_pct", 0.30)
				ally.set_meta("faction_empyrean_atk", true)
				
	if empyreans_count >= 4:
		for ally in allies:
			if ally.id in FactionSystem.FACTIONS["empyreans"].members:
				ally.set_meta("faction_empyrean_crit_turns", 4)
				ally.set_meta("faction_original_crit_rate", ally.stats.crit_rate)
				ally.stats.crit_rate = 1.0 # Гарантированный Крит

	# 4. АКАДЕМИЯ [1 / 2 / 3]
	var academy_count: int = faction_counts["academy"]
	if academy_count >= 1:
		skill_points = mini(skill_points + 1, CombatConstants.MAX_SKILL_POINTS)
		skill_points_changed.emit(skill_points)
		log_message("Академия [1]: получено +1 ОН на старте боя.")
		
	if academy_count >= 2:
		for ally in allies:
			ally.add_speed_modifier(0.08, 0.0) # Скорость +8%
			ally.set_meta("faction_academy_spd", true)
	
	# 5. КОНСОЛЬ [2 / 4]
	var console_count: int = faction_counts["console"]
	if console_count >= 2:
		for ally in allies:
			if ally.id in FactionSystem.FACTIONS["console"].members:
				ally.add_speed_modifier(0.10, 0.0) # Скорость +10%
				ally.set_meta("faction_console_spd", true)
				log_message("Консоль [2]: Скорость %s повышена на +10%%." % ally.display_name)
				
	if console_count >= 4:
		for ally in allies:
			if ally.id in FactionSystem.FACTIONS["console"].members:
				ally.set_meta("faction_console_full_access", true)
				log_message("Консоль [4]: Полный доступ активирован для %s!" % ally.display_name)
		# Консоль [4]: Отряд начинает бой с +15 Векторами
		set_console_vectors(get_console_vectors() + 15)
		
	_apply_all_techniques(initiator_id)

	# Сёздзи Е4: В начале боя восстанавливает 3 ОН
	var shoji_u := get_shoji_unit()
	if shoji_u and shoji_u.eidolon >= 4:
		skill_points = mini(skill_points + 3, CombatConstants.MAX_SKILL_POINTS)
		skill_points_changed.emit(skill_points)
		log_message("Эйдолон 4 Сёдзи: в начале боя получено 3 ОН!")
		
	var keloist_unit := get_keloist_unit()
	if keloist_unit and keloist_unit.is_alive() and keloist_unit.eidolon >= 4:
		gain_energy_with_err(keloist_unit, 30.0)
		log_message("🎯 Эйдолон 4 Келойста: получено +30 энергии на старте боя!")
	
	for ally in allies:
		if ally.is_alive() and ally.has_meta("set_biology_doctor_4"):
			gain_skill_point()
			log_message("🧪 Сет Доктора наук (4ч) %s: Восстановлено +1 ОН на старте боя!" % ally.display_name)
			
	var rimes_unit := get_rimes_unit()
	if rimes_unit and rimes_unit.is_alive() and rimes_unit.eidolon >= 1:
		RimesAbilities.increment_talent_stacks(rimes_unit, self)
		RimesAbilities.increment_talent_stacks(rimes_unit, self)
		log_message("🎯 Эйдолон 1 Раймса: получено +2 стака таланта на старте боя!")
	
	var musienko_unit := get_musienko_unit()
	if musienko_unit and musienko_unit.is_alive():
		var musienko_chaos_allies: int = 0
		for ally in allies:
			if ally.id != "musienko" and ally.id in FactionSystem.FACTIONS["chaos"].members:
				musienko_chaos_allies += 1
		if musienko_chaos_allies > 0:
			var hp_boost: float = 0.10 * float(musienko_chaos_allies)
			musienko_unit.set_meta("musienko_trace3_hp_pct", hp_boost)
			
			# ИСПРАВЛЕНО: Рассчитываем ХП аддитивно через единую функцию
			recalculate_unit_max_hp(musienko_unit)
			log_message("След 3 Мусиенко: макс. ХП увеличено на +%d%% за участников Рассвета Хаоса." % int(hp_boost * 100.0))
	
	# --- СВЕТОВОЙ КОНУС: ПЛАН ПО СПАСЕНИЮ МИРА (РЕФОРМА) ---
	for ally in allies:
		if ally.is_alive() and ally.get_meta("light_cone_id", "") == "save_the_world_plan":
			gain_energy_with_err(ally, 40.0)
			log_message("🛡 Конус спасения: %s восстановил +40 энергии на старте боя!" % ally.display_name)
			
	# ИСПРАВЛЕНО: Рассчитываем баффы Келойста на старте боя (например, от его Техники)
	KeloistAbilities.recalculate_allies_atk_buffs(self)
	
	phase = Phase.RUNNING
	battle_started.emit()
	var milena_unit := get_milena_unit()
	if milena_unit and milena_unit.is_alive():
		for ally in allies:
			ally.set_meta("milena_be_buff", 0.40)
	if battle_mode == "level_7":
		for ally in allies:
			ally.stats.crit_rate += 0.50
			log_message("⚡ Аномалия 7 Уровня: Крит. шанс %s повышен на +50%% на 3 хода!" % ally.display_name)
	elif battle_mode == "level_16":
		for ally in allies:
			ally.add_speed_modifier(0.0, 20.0)
			log_message("⚡ Аномалия 16 Уровня: Скорость %s повышена на +20 ед.!" % ally.display_name)
	elif battle_mode == "level_19":
		var paths: Array = []
		for ally in allies:
			if ally.is_alive() and not ally.path in paths:
				paths.append(ally.path)
		var unique_paths := paths.size()
		var bonus_dmg := 0.06 * float(unique_paths)
		var bonus_cr := 0.04 * float(unique_paths)
		for ally in allies:
			ally.set_meta("level19_dmg_buff", bonus_dmg)
			ally.stats.crit_rate += bonus_cr
		log_message("⚡ Аномалия 19 Уровня: Найдено %d уникальных Путей! Урон отряда +%d%%, Крит. шанс +%d%%!" % [unique_paths, int(bonus_dmg * 100.0), int(bonus_cr * 100.0)])
		
	_advance_to_next_turn()
	
func _init_light_cone_effects(unit: CombatUnit) -> void:
	var lc: String = unit.get_meta("light_cone_id", "")
	match lc:
		"amber":
			unit.stats.def *= 1.20
		"what_is_reality":
			unit.stats.effect_hit_rate += 0.40
		"adversary":
			unit.stats.crit_rate += 0.24
			unit.set_meta("adversary_buff_turns", 3)
			log_message("Световой конус Нападение: Крит. шанс %s повышен на 24%% на 3 хода!" % unit.display_name)
		# ИСПРАВЛЕНО: вечные баффы СА записываются в независимые мета-проценты
		"cant_kill_you":
			unit.stats.crit_dmg += 0.45
			log_message("Световой конус «Я не могу тебя убить»: Крит. урон %s повышен на +45%%." % unit.display_name)
		"moment_of_happiness":
			unit.set_meta("lc_atk_pct_bonus", 0.40) # вечный бафф СА
			log_message("Световой конус «Мгновение счастья»: Сила атаки %s повышена на +40%%." % unit.display_name)
		"touch_waking_world":
			unit.set_meta("lc_atk_pct_bonus", 0.25) # вечный бафф СА
			log_message("Световой конус «Коснись...»: Сила атаки %s повышена на +25%%." % unit.display_name)
		"crimson_tears":
			unit.set_meta("lc_atk_pct_bonus", 0.45) # вечный бафф СА
			log_message("Световой конус «Басня...»: Сила атаки %s повышена на +45%%." % unit.display_name)
		"perfect_metamorphosis":
			unit.stats.damage_bonus += 0.30
			log_message("Световой конус «Идеальный Метаморфоз»: Наносимый %s урон повышен на +30%%." % unit.display_name)
		# --- НОВЫЕ КОНУСЫ ВЕРСИИ 1.1 ---
		"monument_of_silence":
			for ally in allies:
				ally.statuses.atk_buff_percent += 0.25
				ally.statuses.atk_buff_turns = 2
				ally.statuses.atk_buff_source = "Памятник тишине"
			log_message("Конус «Памятник тишине»: СА всех союзников повышена на +25%% на 2 хода.")
			
		"impulse":
			var owner_def: float = unit.stats.def
			var relic_def_pct: float = float(unit.get_meta("relic_def_pct", 0.0))
			var effective_def: float = owner_def * (1.0 + relic_def_pct)
			var shield_amt: float = effective_def * 0.20
			
			for ally in allies:
				apply_shield(ally, shield_amt, 2, "Напор (конус)")
			log_message("Конус «Напор»: на всех союзников наложен щит прочностью %d на 2 хода." % int(shield_amt))
			
		"warm_embraces":
			unit.stats.crit_rate += 0.20
			log_message("Конус «В тёплых объятиях»: Крит. шанс %s повышен на +20%%." % unit.display_name)
			
		"echoes_of_the_past":
			# Эффект угасания урона ульты и восстановления ХП рассчитывается во время боя
			log_message("Конус «Отголоски прошлого»: Экипирован на %s." % unit.display_name)
			
		"forget_past_self":
			unit.stats.crit_dmg += 0.25
			log_message("Конус «Забудь прошлое Я»: Крит. урон %s повышен на +25%%." % unit.display_name)
			
		"save_the_world_plan":
			log_message("Световой конус «План по спасению мира»: Экипирован на %s." % unit.display_name)
			
		"edge_of_existence":
			unit.stats.crit_dmg += 0.40
			log_message("Конус «Рубеж Бытия»: Крит. урон %s повышен на +40%%." % unit.display_name)
		"apocalypse":
			log_message("Конус «Апокалипсис»: Экипирован на %s." % unit.display_name)
			
		"leak":
			unit.stats.effect_hit_rate += 0.40
			unit.set_meta("lc_leak_turns", 3)
			unit.set_meta("lc_leak_skip_tick", true)
			log_message("Конус «Утечка»: ШПЭ %s увеличен на +40%% на 3 хода." % unit.display_name)
			
		"new_life_start":
			# Записываем прибавку +24% к защите в мета-проценты реликвий
			var cur_def_pct: float = float(unit.get_meta("relic_def_pct", 0.0))
			unit.set_meta("relic_def_pct", cur_def_pct + 0.24)
			# Мутация unit.stats.def УДАЛЕНА. Все расчеты теперь идут динамически через get_effective_def_complete
			
			# Пересчитываем защиту юнита с учетом нового процента
			var base_def: float = float(unit.get_meta("base_def_original", unit.stats.def))
			unit.stats.def = base_def * (1.0 + cur_def_pct + 0.24)
			unit.set_meta("base_def", unit.stats.def)
			
			# Бафф Сопротивления ко всем типам урона на +12% для всех союзников
			for ally in allies:
				ally.set_meta("lc_all_res_bonus", 0.12)
			log_message("Конус «Начало новой жизни»: Защита %s повышена на +24%%, все союзники получили +12%% Сопротивления урону." % unit.display_name)
			
		"moon_dance":
			unit.stats.crit_rate += 0.16
			log_message("Конус «Танец при луне»: Крит. шанс %s повышен на +16%%." % unit.display_name)
			
		"inevitable_fall":
			# Аддитивный бафф ХП (+30%) от чистой базы
			var current_hp_pct: float = float(unit.get_meta("relic_hp_pct", 0.0))
			unit.set_meta("relic_hp_pct", current_hp_pct + 0.30)
			recalculate_unit_max_hp(unit)
			log_message("Конус «Падение мира неизбежно»: Макс. ХП %s повышено на +30%%." % unit.display_name)
		"mirror_illusion":
			unit.set_meta("lc_atk_pct_bonus", float(unit.get_meta("lc_atk_pct_bonus", 0.0)) + 0.20)
			unit.set_meta("mirror_illusion_triggers", 3)
			log_message("Конус «Зеркальная иллюзия»: СА %s повышена на +20%%." % unit.display_name)
			
		"scorching_gaze":
			unit.stats.crit_dmg += 0.25
			log_message("Конус «Палящий взор»: Крит. урон %s повышен на +25%%." % unit.display_name)
			
		"concert_dead":
			unit.set_meta("relic_err_bonus", float(unit.get_meta("relic_err_bonus", 0.0)) + 0.12)
			log_message("Конус «Концерт для мертвецов»: ВЭ %s повышена на +12%%." % unit.display_name)
			
		"sun_eclipses_moon":
			unit.stats.crit_rate += 0.22
			log_message("Конус «Солнце, затмевающее луну»: Крит. шанс %s повышен на +22%%." % unit.display_name)
			
		"feel_my_presence":
			unit.stats.crit_dmg += 0.40
			log_message("Конус «Ощути моё присутствие»: Крит. урон %s повышен на +40%%." % unit.display_name)
			
		"quarantine":
			log_message("Конус «Поместить в карантин»: Экипирован на %s." % unit.display_name)
			
		"corrupted_save":
			unit.add_speed_modifier(0.18, 0.0)
			add_console_vectors(10)
			unit.set_meta("immersion_turns", 3)
			unit.set_meta("immersion_skip_tick", true)
			log_message("Конус «Повреждённое сохранение»: Скорость %s повышена на +18%%, получено 10 Векторов, статус «Погружение» на 3 хода!" % unit.display_name)
			
		"server_crash_moment":
			log_message("Конус «Момент, когда падают сервера»: Экипирован на %s (Бинарный урон +40%%)." % unit.display_name)
			
		"first_minutes_of_war":
			log_message("Конус «Первые минуты войны»: Экипирован на %s (получаемый урон снижен на 20%%)." % unit.display_name)

		"history_soaked_in_blood":
			unit.stats.atk *= 1.40
			unit.set_meta("blood_soaked_recorded_dmg", 0.0)
			unit.set_meta("blood_soaked_dmg_red_stacks", 0)
			log_message("Конус «История, вымоченная в крови»: СА %s повышена на +40%%." % unit.display_name)

		"why_did_you_remember_me":
			unit.stats.atk *= 1.40
			unit.set_meta("remember_me_recorded_outgoing", 0.0)
			unit.set_meta("remember_me_in_position", false)
			log_message("Конус «Почему ты вспомнила меня?»: СА %s повышена на +40%%." % unit.display_name)
			
# Новый метод активации техник Атаки и Поддержки в battle_manager.gd:
func _apply_all_techniques(selected_attacker_id: String) -> void:
	var has_marina := false
	
	
	# 1. Активируем ВСЕ техники Поддержки (срабатывают всегда, если герой в пати)
	for ally in allies:
		if ally.is_alive():
			match ally.id:
				ArseniyAbilities.ID:
					ArseniyAbilities.apply_technique(ally)
					log_message("Техника поддержки Арсения: «Новая разработка» +20%% СА на 2 хода.")
				"danill":
					var def_val: float = get_effective_def_complete(ally)
					var shield_amount: float = def_val * 0.24 + 150.0
					for target_ally in allies:
						apply_shield(target_ally, shield_amount, 2, "Техника Данилла")
					log_message("Техника поддержки Данилла: На всех наложен щит %d на 2 хода." % int(shield_amount))
				SaraAbilities.ID:
					SaraAbilities.apply_technique_to_team(allies, self)
				"dotseva":
					# ИСПРАВЛЕНО: Теперь это техника ПОДДЕРЖКИ. 
					# Дает бонусы Доцевой автоматически при входе в бой. Без нанесения урона!
					add_calibration_stacks(ally, 20)
					ally.statuses.self_atk_buff_percent += 0.10
					ally.statuses.self_atk_buff_turns = 3
					ally.statuses.self_atk_buff_source = "Техника Доцевой"
					log_message("Техника поддержки Доцевой: получено 20 зарядов Калибровки и +10%% СА на 3 хода.")
				MarinaAbilities.ID:
					has_marina = true 
				# Внутри _apply_all_techniques() -> match ally.id:
				"milena":
					# Техника Поддержки: автоматически активирует Навык E без затрат SP
					ally.set_meta("milena_overtone_turns", 3)
					ally.set_meta("milena_overtone_skip_tick", true)
					update_milena_overtone_spd_buff(ally, true)
					log_message("Техника поддержки Милены: на старте боя активирован «Обертон» на 3 хода.")
				"naama": # <--- ДОБАВИТЬ ЭТО
					for enemy in enemies:
						NaamaAbilities.add_intox_stacks(enemy, 3, self)
					log_message("Техника поддержки Наамы: все противники получили 3 стака Опьянения.")
				"lenskaya": # <--- ДОБАВИТЬ ЭТО
					for target_ally in allies:
						target_ally.set_meta("lenskaya_tech_fua_buff_turns", 2)
						target_ally.set_meta("lenskaya_tech_fua_buff_skip_tick", true)
					log_message("Техника поддержки Ленской: урон бонус-атак союзников повышен на 40% на 2 хода.")
				"isaac": # <--- ДОБАВИТЬ ЭТО
					var energy_restore := ally.max_energy * 0.50
					gain_energy_with_err(ally, energy_restore)
					log_message("Техника поддержки Айзека: восполнено 50%% энергии на старте боя (+%d ед.)." % int(energy_restore))
				"keloist": # <--- ДОБАВИТЬ ЭТО
					var best_ally: CombatUnit = null
					for target_ally in allies:
						if target_ally.is_alive() and target_ally != ally:
							if best_ally == null or target_ally.stats.atk > best_ally.stats.atk:
								best_ally = target_ally
					if best_ally:
						best_ally.set_meta("keloist_orthoshield_turns", 3)
						best_ally.set_meta("keloist_orthoshield_skip_tick", true)
						log_message("Техника поддержки Келойста: На союзника %s с наивысшей СА наложен Ортощит на 3 хода." % best_ally.display_name)
				"jeff": # ДОБАВЛЕНО: Техника поддержки Джеффа
					ally.set_meta("jeff_make_noise_active", true)
					
					# Находим противника с наивысшим макс. ХП
					var strongest: CombatUnit = null
					for enemy in enemies:
						if enemy.is_alive():
							if strongest == null or enemy.stats.max_hp > strongest.stats.max_hp:
								strongest = enemy
								
					if strongest:
						JeffAbilities.apply_bass_listen(ally, strongest, self, 2)
					
					log_message("Техника поддержки Джеффа: активирован статус «Пошумите!», на %s наложена метка «Бассы! Слушай!» на 2 хода." % strongest.display_name)
				"valramors":
					for target_ally in allies:
						if target_ally.is_alive():
							target_ally.set_meta("valramors_tech_ignore_turns", 2)
							target_ally.set_meta("valramors_tech_ignore_skip_tick", true)
					log_message("Техника поддержки Валраморса: Все союзники игнорируют 15%% защиты противников на 2 хода.")
				"sara_admin":
					SaraAdminAbilities.add_vectors(20, self)
					for target_ally in allies:
						if target_ally.is_alive():
							target_ally.set_meta("sara_tech_binary_turns", 3)
							target_ally.set_meta("sara_tech_binary_skip_tick", true)
					log_message("Техника поддержки Сары: Получено +20 Векторов, Бинарный урон отряда повышен на +30%% на 3 хода.")
				"arseniy_admin":
					var sara_adm := get_sara_admin_unit()
					if sara_adm and sara_adm.is_alive():
						SaraAdminAbilities.add_vectors(10, self) # Через Сару (с учётом буфера)
					else:
						var isaac_adm := get_isaac_admin_unit()
						if isaac_adm and isaac_adm.is_alive():
							IsaacAdminAbilities.add_vectors(isaac_adm, 10, self)
						else:
							set_console_vectors(get_console_vectors() + 10)
					log_message("Техника поддержки Арсения: Получено +10 Векторов на старте боя.")
				"dasha_admin":
					var dasha_u := get_dasha_admin_unit()
					if dasha_u and dasha_u.is_alive():
						DashaAdminAbilities.add_digital_footprint(dasha_u, 10, self)
					for target_ally in allies:
						if target_ally.is_alive():
							target_ally.set_meta("dasha_tech_reduce_turns", 2)
							target_ally.set_meta("dasha_tech_reduce_skip_tick", true)
					log_message("Техника поддержки Даши: Получено +10 Цифровых следов, входящий урон отряда снижен на 40%% на 2 хода.")
				"katarina":
					KatarinaAbilities.apply_technique(ally, self)
				"dotseva_crimson_tears":
					DotsevaCrimsonTearsAbilities.apply_technique(ally, self)
					
					
	# 2. Активируем ЕДИНСТВЕННУЮ выбранную Атакующую технику
	var attacker_unit: CombatUnit = null
	for ally in allies:
		if ally.id == selected_attacker_id:
			attacker_unit = ally
			break
			
	var is_attacker_shoji := selected_attacker_id == ShojiAbilities.ID
	var is_attacker_dasha := selected_attacker_id == "dasha"
	var is_attacker_kaori := selected_attacker_id == KaoriAbilities.ID
	var is_attacker_kirill := selected_attacker_id == PusenkovAbilities.ID
	var is_attacker_vika := selected_attacker_id == "vika"
	var is_attacker_rimes := selected_attacker_id == "rimes"
	var is_attacker_musienko := selected_attacker_id == "musienko" 
	var is_attacker_joan := selected_attacker_id == "joan" 
	var is_attacker_joan_spirit := selected_attacker_id == "joan_spirit"
	var is_attacker_isaac_admin := selected_attacker_id == "isaac_admin"
	
	var has_attacker_tech := is_attacker_shoji or is_attacker_dasha or is_attacker_kaori or is_attacker_kirill or is_attacker_vika or is_attacker_rimes or is_attacker_joan or is_attacker_musienko or is_attacker_joan_spirit or is_attacker_isaac_admin
	
	if has_attacker_tech and attacker_unit:
		match selected_attacker_id:
			ShojiAbilities.ID:
				for enemy in enemies:
					if enemy.is_alive():
						enemy.set_meta("shoji_burn_stacks", 1)
						enemy.set_meta("shoji_burn_turns", 3)
				log_message("Атакующая техника Сёдзи: Все противники получили 1 уровень Горения Сёдзи на 3 хода.")
			"dasha":
				execute_dasha_bonus_attack(attacker_unit)
			KaoriAbilities.ID:
				var max_hp_enemy: CombatUnit = null
				for enemy in enemies:
					if enemy.is_alive():
						if max_hp_enemy == null or enemy.stats.max_hp > max_hp_enemy.stats.max_hp:
							max_hp_enemy = enemy
				if max_hp_enemy:
					var tgh_reduction := max_hp_enemy.max_toughness * 0.30
					max_hp_enemy.toughness = maxf(max_hp_enemy.toughness - tgh_reduction, 0.0)
					max_hp_enemy.set_meta("phys_res_reduced_turns", 2)
					log_message("Атакующая техника Каори: %s получил %d урона стойкости и −20%% физ. сопр. на 2 хода." % [max_hp_enemy.display_name, int(tgh_reduction)])
			PusenkovAbilities.ID:
				for enemy in enemies:
					if enemy.is_alive():
						var res := calc_dmg(attacker_unit, enemy, 1.50)
						deal_damage(enemy, res.damage, attacker_unit)
				attacker_unit.gain_energy(attacker_unit.max_energy * 0.30)
				log_message("Атакующая техника Кирилла: нанес 150%% ветра всем врагам и восстановил 30%% энергии.")
			"vika":
				for enemy in enemies:
					if enemy.is_alive():
						var res := calc_dmg(attacker_unit, enemy, 1.30)
						deal_damage(enemy, res.damage, attacker_unit)
				log_message("Атакующая техника Вики: нанесла 130%% СА квантового урона всем врагам.")
			"rimes":
				var max_hp_enemy: CombatUnit = null
				for enemy in enemies:
					if enemy.is_alive():
						if max_hp_enemy == null or enemy.stats.max_hp > max_hp_enemy.stats.max_hp:
							max_hp_enemy = enemy
				if max_hp_enemy:
					var res := calc_dmg(attacker_unit, max_hp_enemy, 3.00)
					deal_damage(max_hp_enemy, res.damage, attacker_unit, attacker_unit.element, res.crit)
				
				# Немедленно дает 1 стак Таланта
				RimesAbilities.increment_talent_stacks(attacker_unit, self)
			"musienko": # ДОБАВЛЕНО: Атакующая техника Мусиенко
				# Мгновенно вводим Мусиенко в состояние «Аннигиляция бытия»
				attacker_unit.set_meta("musienko_annihilation_active", true)
				attacker_unit.set_meta("musienko_annihilation_spd_bonus", 80.0)
				attacker_unit.add_speed_modifier(0.0, 80.0)
				attacker_unit.recalculate_action_value()
				
				if attacker_unit.get_meta("light_cone_id", "") == "inevitable_fall":
					attacker_unit.set_meta("inevitable_fall_wrath_turns", 3)
					attacker_unit.set_meta("inevitable_fall_wrath_skip_tick", true)
					log_message("🌋 Конус «Падение мира»: Навык E активирован Техникой! На Мусиенко наложен статус «Проявление Гнева» на 3 хода.")
				
				# Наносим урон 160% от макс. ХП всем противникам
				for enemy in enemies:
					if enemy.is_alive():
						var res := calc_dmg(attacker_unit, enemy, 1.60)
						deal_damage(enemy, res.damage, attacker_unit, attacker_unit.element, res.crit)
				log_message("⚡ Атакующая техника Мусиенко: нанес всем 160%% ХП огненного урона и вошел в состояние «Аннигиляция бытия»!")
			"joan":
				for enemy in enemies:
					if enemy.is_alive():
						var res := calc_dmg(attacker_unit, enemy, 0.50)
						deal_damage(enemy, res.damage, attacker_unit)
						
						# Накладываем уязвимость +20% на 1 ход
						enemy.set_meta("joan_tech_vuln_turns", 1)
				log_message("Атакующая техника Жоана: нанес всем 50%% СА урона и наложил уязвимость +20%% на 1 ход.")
			"joan_spirit":
				var wish_gain: int = 2
				
				# Проверка наличия 4 Эмпирейцев в отряде
				var f_map: Dictionary = get_meta("active_factions", {})
				var empyreans_count: int = int(f_map.get("empyreans", 0))
				if empyreans_count >= 4:
					wish_gain += 4
					log_message("🏛 Синергия Эмпирейцев [4]: Техника даёт +4 дополнительных заряда «Последнего желания»!")
					
				JoanSpiritAbilities.add_last_wish(attacker_unit, wish_gain, self)
				
				for enemy in enemies:
					if enemy.is_alive():
						var res := calc_dmg(attacker_unit, enemy, 2.10)
						deal_damage(enemy, res.damage, attacker_unit, CombatConstants.Element.IMAGINARY, res.crit)
						
				log_message("⚔ Атакующая техника Жоана: получено +%d «Последнего желания», нанесено 210%% урона всем врагам!" % wish_gain)
			"isaac_admin":
				IsaacAdminAbilities.add_vectors(attacker_unit, 15, self)
				attacker_unit.set_meta("is_binary_attack", true)
				for enemy in enemies:
					if enemy.is_alive():
						var res := calc_dmg(attacker_unit, enemy, 1.60, 0.0, false, 0.0, 0.0, false, true, "Binary")
						deal_damage(enemy, res.damage, attacker_unit, CombatConstants.Element.PHYSICAL, res.crit, "Binary")
				attacker_unit.remove_meta("is_binary_attack")
				log_message("⚔ Атакующая техника Айзека: нанесено 160%% Бинарного урона всем врагам, получено +15 Векторов!")
			"shoji_swan":
				ShojiSwanAbilities.apply_technique(enemies, attacker_unit, self)
			
			

	# 3. Активируем технику Марины
	if has_marina:
		var marina_unit := get_marina_unit()
		if marina_unit:
			MarinaAbilities.apply_technique(enemies, marina_unit)
			var target_to_advance: CombatUnit = null
			if has_attacker_tech and attacker_unit:
				target_to_advance = attacker_unit
			elif not allies.is_empty():
				target_to_advance = allies[0]
			if target_to_advance:
				target_to_advance.advance_action(100.0)
				log_message("Техника Марины: враги задержаны, %s продвинут на 100%%." % target_to_advance.display_name)
										
func _advance_to_next_turn() -> void:
	while (has_meta("is_selecting_ult_target") and get_meta("is_selecting_ult_target")) or _is_processing_ult_queue or not ult_queue.is_empty() or has_meta("tutorial_paused"):
		await get_tree().create_timer(0.1).timeout

	# Единая проверка превышения лимита циклов для Уровней
	var cur_c := get_current_cycles()
	if (battle_mode == "level_6" and cur_c >= 5) \
	or (battle_mode == "level_7" and cur_c >= 16) \
	or (battle_mode == "level_8" and cur_c >= 13) \
	or (battle_mode == "level_9" and cur_c >= 13) \
	or (battle_mode == "level_10" and cur_c >= 13) \
	or (battle_mode == "level_11" and cur_c >= 13) \
	or (battle_mode == "level_12" and cur_c >= 14) \
	or (battle_mode == "level_13" and cur_c >= 15) \
	or (battle_mode == "level_14" and cur_c >= 16) \
	or (battle_mode == "level_15" and cur_c >= 16) \
	or (battle_mode == "level_16" and cur_c >= 15) \
	or (battle_mode == "level_17" and cur_c >= 15) \
	or (battle_mode == "level_18" and cur_c >= 16) \
	or (battle_mode == "level_19" and cur_c >= 16) \
	or (battle_mode == "level_20" and cur_c >= 19):
		phase = Phase.DEFEAT
		log_message("⏳ Время истекло! Превышен лимит циклов. Поражение!")
		battle_ended.emit(false)
		return
		
	if _check_battle_end():
		return

	var result := ActionValueSystem.get_next_actor(get_all_units())
	current_unit = result.unit
	if current_unit == null:
		return

	var tick_val: float = float(result.get("tick", 0.0))
	
	if tick_val > 0.0 and sara_talent_active:
		release_sara_buffer()
		
	accumulated_av += tick_val

	# ИСПРАВЛЕНО: sara_u объявляется строго здесь (без дублирования!)
	if tick_val > 0.0:
		var sara_u: CombatUnit = get_sara_admin_unit()
		if sara_u and bool(sara_u.get_meta("sara_talent_pending_release", false)):
			sara_u.set_meta("sara_talent_pending_release", false)
			var excess_v: int = int(sara_u.get_meta("sara_recorded_excess_vectors", 0))
			sara_u.set_meta("sara_recorded_excess_vectors", 0)
			if excess_v > 0:
				log_message("🔓 ТАЛАНТ САРЫ: Наступил следующий индекс действия! Записанные +%d Векторов выгружены в пул Консоли." % excess_v)
				SaraAdminAbilities.add_vectors(excess_v, self)

	if arya_active and tick_val > 0.0:
		arya_remaining -= tick_val
		arya_changed.emit(true, arya_remaining)
		if arya_remaining <= 0.0:
			_end_arya()

	action_order_changed.emit()

	if current_unit.statuses.skip_next_turn:
		current_unit.statuses.skip_next_turn = false
		log_message("%s пропускает ход (Заморозка)" % current_unit.display_name)
		_end_turn(current_unit)
		return

	_process_turn_start_statuses(current_unit)
	_update_marina_e4()

	if current_unit.id == KaoriAbilities.ID and current_unit.is_alive():
		if current_unit.eidolon >= 4 and _is_only_one_elite_enemy():
			var target := get_living_enemies()[0]
			if not CombatConstants.Element.PHYSICAL in target.weaknesses:
				target.weaknesses.append(CombatConstants.Element.PHYSICAL)
				target.set_meta("e4_phys_weakness_turns", 3)
				log_message("Эйдолон 4 Каори: наложена Физическая уязвимость на %s на 3 хода!" % target.display_name)

	turn_started.emit(current_unit)

	if current_unit.is_ally:
		_waiting_for_player = true
	else:
		_waiting_for_player = false
		var enemy_actor := current_unit
		await get_tree().create_timer(0.6).timeout
		while (has_meta("is_selecting_ult_target") and get_meta("is_selecting_ult_target")) or _is_processing_ult_queue or not ult_queue.is_empty():
			await get_tree().create_timer(0.1).timeout
		_execute_enemy_turn(enemy_actor)
		
func _is_only_one_elite_enemy() -> bool:
	var living := get_living_enemies()
	return living.size() == 1 and living[0].is_elite

func _process_turn_start_statuses(unit: CombatUnit) -> void:
	advance_fua_sequence()
	set_meta("joan_wish_granted_this_turn", false)
	if unit.is_ally:
		# Е1 Айзека Админа: Восстанавливает 3 Вектора на старте хода ЛЮБОГО союзника, кроме самого Айзека
		var isaac_adm := get_isaac_admin_unit()
		if isaac_adm and isaac_adm.is_alive() and isaac_adm.eidolon >= 1 and unit != isaac_adm:
			IsaacAdminAbilities.add_vectors(isaac_adm, 3, self)
		# 1. Зеркальная иллюзия: обновление зарядов до 3 в свой ход
		if unit.get_meta("light_cone_id", "") == "mirror_illusion":
			unit.set_meta("mirror_illusion_triggers", 3)
			
		# 2. Солнце, что затмевает луну: потеря 1% ХП в начале своего хода
		if unit.get_meta("light_cone_id", "") == "sun_eclipses_moon":
			var hp_loss: float = unit.stats.max_hp * 0.01
			unit.stats.hp = maxf(unit.stats.hp - hp_loss, 1.0)
			log_message("☀ Конус «Солнце, затмевающее луну»: «Пылающее солнце» отняло 1%% ХП (остаток: %d)." % int(unit.stats.hp))
			unit_updated.emit(unit)
			trigger_accepted_sin_hp_loss(unit)
		# Конус Падения мира неизбежно: теряет 1% макс. ХП в начале своего хода (не ниже 1 ХП)
		if unit.has_meta("inevitable_fall_wrath_turns") and int(unit.get_meta("inevitable_fall_wrath_turns", 0)) > 0:
			var hp_loss: float = unit.stats.max_hp * 0.01
			unit.stats.hp = maxf(unit.stats.hp - hp_loss, 1.0)
			log_message("🩸 Конус «Падение мира»: «Проявление Гнева» отняло 1%% ХП (остаток: %d)." % int(unit.stats.hp))
			unit_updated.emit(unit)
			
			# ИСПРАВЛЕНО: Снятие ХП конусом зачисляет Мусиенко стак Кровавого Возмездия по Таланту!
			if unit.id == "musienko":
				MusienkoAbilities.increment_retribution_stacks(unit, self)
		SaraAbilities.on_ally_turn_start(unit, self)
		if unit.id == "dotseva" and unit.is_alive():
			add_calibration_stacks(unit, 2)
			log_message("След 2 Доцевой: Начало хода. Получено +2 стака Калибровки.")
		if unit.id == "dotseva_crimson_tears" and unit.is_alive():
			DotsevaCrimsonTearsAbilities.on_turn_start(unit, self)
		var doceva_tears_ref := get_dotseva_crimson_tears_unit()
		if doceva_tears_ref and doceva_tears_ref.is_alive() and unit != doceva_tears_ref:
			DotsevaCrimsonTearsAbilities.on_ally_turn_started(doceva_tears_ref, unit, self)
		if unit.id == "katarina" and unit.is_alive() and unit.has_meta("katarina_just_a_memory_turns") and int(unit.get_meta("katarina_just_a_memory_turns", 0)) > 0:
			if unit.get_meta("katarina_just_a_memory_skip_tick", false):
				unit.set_meta("katarina_just_a_memory_skip_tick", false)
			else:
				var mem_turns := int(unit.get_meta("katarina_just_a_memory_turns", 0)) - 1
				unit.set_meta("katarina_just_a_memory_turns", mem_turns)
				if mem_turns == 0:
					gain_energy_with_err(unit, 50.0)
					log_message("🕊 Состояние «Лишь воспоминание» завершено! %s восстановила +50 единиц энергии!" % unit.display_name)
		if unit.has_meta("katarina_q_ally_atk_buff_turns") and int(unit.get_meta("katarina_q_ally_atk_buff_turns", 0)) > 0:
			if unit.get_meta("katarina_q_ally_atk_buff_skip_tick", false):
				unit.set_meta("katarina_q_ally_atk_buff_skip_tick", false)
			else:
				var atk_turns := int(unit.get_meta("katarina_q_ally_atk_buff_turns", 0)) - 1
				unit.set_meta("katarina_q_ally_atk_buff_turns", atk_turns)
		if battle_mode == "level_10" and unit.is_ally:
			if unit.path == CombatConstants.Path.ABUNDANCE or unit.path == CombatConstants.Path.PRESERVATION:
				var base_val := maxf(unit.stats.max_hp, unit.stats.def)
				var heal_amt := base_val * 0.08 + 150.0

				for ally in allies:
					if ally.is_alive():
						heal_unit(ally, heal_amt)
				log_message("💖 Аномалия %s: Весь отряд исцелен на %d ХП!" % [unit.display_name, int(heal_amt)])
		if unit.id == "isaac" and unit.is_alive() and unit.statuses.patch_turns > 0:
			var has_sara := false
			for ally in allies:
				if ally.id == SaraAbilities.ID and ally.is_alive():
					has_sara = true
					break
			if has_sara:
				gain_energy_with_err(unit, 5.0)
				log_message("След 2 Айзека: Наличие Сары и Заплатки восстановило +5 энергии.")
		if unit.id == "joan" and unit.is_alive():
			JoanAbilities.add_coffee_liqueur_stacks(unit, 1, self)
			log_message("☕ Ход Жоана: получен 1 стак «Кофейного ликёра» (пассивный Таланта).")
		if unit.id == "jeff" and unit.is_alive():
			unit.set_meta("jeff_make_noise_active", true)
			log_message("🎶 Ход Джеффа: статус «Пошумите!» активирован (пассивный Таланта).")
		if unit.has_meta("ballast_turns") and int(unit.get_meta("ballast_turns", 0)) > 0:
			var ballast_dmg: float = 2500.0 * 0.05 # 5% от базовой СА босса (125 ед.)
			log_message("⚓ Балласт: Ход %s. Отряд получает по %d урона под тяжестью балласта!" % [unit.display_name, int(ballast_dmg)])
			for ally in allies:
				if ally.is_alive():
					deal_damage(ally, ballast_dmg, null, -1, false, "ballast_damage")
		if unit.has_meta("trojan_turns") and int(unit.get_meta("trojan_turns", 0)) > 0:
			var t_atk: float = float(unit.get_meta("trojan_source_atk", 2600.0))
			var t_dmg: float = t_atk * 0.30
			log_message("👾 Троян: %s получает %d урона от вредоносного скрипта!" % [unit.display_name, int(t_dmg)])
			deal_damage(unit, t_dmg, null, CombatConstants.Element.LIGHTNING, false, "DoT")
	else:		
		if not unit.is_ally:
			NaamaAbilities.process_enemy_turn_start(unit, self)
		if unit.has_meta("level18_vuln_turns") and int(unit.get_meta("level18_vuln_turns", 0)) > 0:
			var l18_t := int(unit.get_meta("level18_vuln_turns", 0)) - 1
			unit.set_meta("level18_vuln_turns", l18_t)
			if l18_t <= 0:
				unit.statuses.damage_taken_bonus = maxf(0.0, unit.statuses.damage_taken_bonus - 0.15)
				log_message("⚡ Аномалия 18 уровня: действие ослабления на %s закончилось." % unit.display_name)
		if unit.statuses.toughness_broken:
			unit.statuses.toughness_broken = false
			unit.statuses.damage_taken_bonus = 0.0
			unit.statuses.toughness_break_source = ""
			unit.toughness = unit.max_toughness
			log_message("%s восстановил стойкость" % unit.display_name)
		
		# Отработка тиков Шока «Бассы! Слушай!» Джеффа в ход врага
		if unit.has_meta("jeff_bass_listen_turns") and int(unit.get_meta("jeff_bass_listen_turns", 0)) > 0:
			var jeff := get_jeff_unit()
			if jeff and jeff.is_alive():
				var dot_mult: float = 0.80 # Базовый коэффициент Шока 80% СА
				
				# Е2: Урон DoT повышается на 50% при 2 союзниках Небытия
				if jeff.eidolon >= 2 and check_nihility_allies_e2():
					dot_mult *= 1.50
					
				var res := calc_dmg(jeff, unit, dot_mult, 0.0, false, 0.0, 0.0, false, false, "DoT")
				deal_damage(unit, res.damage, jeff, CombatConstants.Element.LIGHTNING, false, "DoT")
				
				# Восстановление Джеффу 5 энергии за каждый тик Шока
				gain_energy_with_err(jeff, 5.0)
				log_message("🎶 Бассы! Слушай! (Шок): Джефф восстановил +5 энергии за тик на %s." % unit.display_name)
				
		if unit.has_meta("def_reductions"):
				var reductions: Dictionary = unit.get_meta("def_reductions")
				if reductions.has("Жертва долгого симбиоза (4ч)"):
					reductions.erase("Жертва долгого симбиоза (4ч)")
					recalculate_target_def(unit)
		if unit.id == "masked_silhouette" and unit.has_meta("mask_layers"):
			var layers := int(unit.get_meta("mask_layers", 0))
			if layers > 0:
				unit.remove_meta("mask_layers")
				unit.set_meta("silhouette_mask_def_buff_permanent", 0.40) # ИСПРАВЛЕНО
				log_message("🎭 Тайна сияющей маски: время на сброс вышло! Прибавка защиты +40% зафиксирована НАВСЕГДА.")
			else:
				unit.remove_meta("mask_layers")
		if unit.has_meta("phys_res_reduced_turns"):
			var turns: int = int(unit.get_meta("phys_res_reduced_turns", 0))
			if turns > 0:
				unit.set_meta("phys_res_reduced_turns", turns - 1)
				if turns - 1 == 0:
					log_message("Физ. уязвимость от техники Каори на %s рассеялась." % unit.display_name)
		
		if unit.has_meta("arseniy_binary_vuln_turns") and int(unit.get_meta("arseniy_binary_vuln_turns", 0)) > 0:
			if unit.get_meta("arseniy_binary_vuln_skip_tick", false):
				unit.set_meta("arseniy_binary_vuln_skip_tick", false)
			else:
				var t := int(unit.get_meta("arseniy_binary_vuln_turns", 0)) - 1
				unit.set_meta("arseniy_binary_vuln_turns", t)

		if unit.has_meta("admin_vuln_turns") and int(unit.get_meta("admin_vuln_turns", 0)) > 0:
			unit.set_meta("admin_vuln_turns", int(unit.get_meta("admin_vuln_turns", 0)) - 1)

		if unit.has_meta("arseniy_atk_weaken_turns") and int(unit.get_meta("arseniy_atk_weaken_turns", 0)) > 0:
			if unit.get_meta("arseniy_atk_weaken_skip_tick", false):
				unit.set_meta("arseniy_atk_weaken_skip_tick", false)
			else:
				var t := int(unit.get_meta("arseniy_atk_weaken_turns", 0)) - 1
				unit.set_meta("arseniy_atk_weaken_turns", t)
				
		if unit.has_meta("arseniy_trace3_vuln_turns") and int(unit.get_meta("arseniy_trace3_vuln_turns", 0)) > 0:
			if unit.get_meta("arseniy_trace3_vuln_skip_tick", false):
				unit.set_meta("arseniy_trace3_vuln_skip_tick", false)
			else:
				var t := int(unit.get_meta("arseniy_trace3_vuln_turns", 0)) - 1
				unit.set_meta("arseniy_trace3_vuln_turns", t)
				
		if unit.has_meta("quantum_res_reduced_turns") and int(unit.get_meta("quantum_res_reduced_turns", 0)) > 0:
			if unit.get_meta("quantum_res_reduced_skip_tick", false):
				unit.set_meta("quantum_res_reduced_skip_tick", false)
			else:
				var t := int(unit.get_meta("quantum_res_reduced_turns", 0)) - 1
				unit.set_meta("quantum_res_reduced_turns", t)

		if unit.has_meta("shoji_swan_dance_vuln_turns") and int(unit.get_meta("shoji_swan_dance_vuln_turns", 0)) > 0:
			if unit.get_meta("shoji_swan_dance_vuln_skip_tick", false):
				unit.set_meta("shoji_swan_dance_vuln_skip_tick", false)
			else:
				var t := int(unit.get_meta("shoji_swan_dance_vuln_turns", 0)) - 1
				unit.set_meta("shoji_swan_dance_vuln_turns", t)

		if unit.has_meta("shoji_swan_tech_vuln_turns") and int(unit.get_meta("shoji_swan_tech_vuln_turns", 0)) > 0:
			if unit.get_meta("shoji_swan_tech_vuln_skip_tick", false):
				unit.set_meta("shoji_swan_tech_vuln_skip_tick", false)
			else:
				var t := int(unit.get_meta("shoji_swan_tech_vuln_turns", 0)) - 1
				unit.set_meta("shoji_swan_tech_vuln_turns", t)
				
		if unit.has_meta("katarina_vuln_turns") and int(unit.get_meta("katarina_vuln_turns", 0)) > 0:
			if unit.get_meta("katarina_vuln_skip_tick", false):
				unit.set_meta("katarina_vuln_skip_tick", false)
			else:
				var t := int(unit.get_meta("katarina_vuln_turns", 0)) - 1
				unit.set_meta("katarina_vuln_turns", t)
				if t == 0:
					unit.remove_meta("katarina_phys_res_reduction")
					unit.remove_meta("katarina_all_res_reduction")
					if unit.get_meta("katarina_added_phys_weakness", false):
						unit.weaknesses.erase(CombatConstants.Element.PHYSICAL)
						unit.remove_meta("katarina_added_phys_weakness")
						log_message("Физическая уязвимость от Катарины на %s рассеялась." % unit.display_name)
						unit_updated.emit(unit)

		if unit.has_meta("katarina_e1_spd_debuff_turns") and int(unit.get_meta("katarina_e1_spd_debuff_turns", 0)) > 0:
			if unit.get_meta("katarina_e1_spd_skip_tick", false):
				unit.set_meta("katarina_e1_spd_skip_tick", false)
			else:
				var t := int(unit.get_meta("katarina_e1_spd_debuff_turns", 0)) - 1
				unit.set_meta("katarina_e1_spd_debuff_turns", t)
				if t == 0:
					unit.remove_speed_modifier(-0.30, 0.0)

		if unit.has_meta("katarina_q_ally_mark_turns") and int(unit.get_meta("katarina_q_ally_mark_turns", 0)) > 0:
			if unit.get_meta("katarina_q_ally_mark_skip_tick", false):
				unit.set_meta("katarina_q_ally_mark_skip_tick", false)
			else:
				var t := int(unit.get_meta("katarina_q_ally_mark_turns", 0)) - 1
				unit.set_meta("katarina_q_ally_mark_turns", t)

		if unit.has_meta("doceva_tears_q_vuln_turns") and int(unit.get_meta("doceva_tears_q_vuln_turns", 0)) > 0:
			if unit.get_meta("doceva_tears_q_vuln_skip_tick", false):
				unit.set_meta("doceva_tears_q_vuln_skip_tick", false)
			else:
				var t := int(unit.get_meta("doceva_tears_q_vuln_turns", 0)) - 1
				unit.set_meta("doceva_tears_q_vuln_turns", t)

		if unit.has_meta("doceva_tears_outgoing_dmg_red_turns") and int(unit.get_meta("doceva_tears_outgoing_dmg_red_turns", 0)) > 0:
			if unit.get_meta("doceva_tears_outgoing_dmg_red_skip_tick", false):
				unit.set_meta("doceva_tears_outgoing_dmg_red_skip_tick", false)
			else:
				var t := int(unit.get_meta("doceva_tears_outgoing_dmg_red_turns", 0)) - 1
				unit.set_meta("doceva_tears_outgoing_dmg_red_turns", t)

		if unit.has_meta("doceva_tears_e2_vuln_turns") and int(unit.get_meta("doceva_tears_e2_vuln_turns", 0)) > 0:
			if unit.get_meta("doceva_tears_e2_vuln_skip_tick", false):
				unit.set_meta("doceva_tears_e2_vuln_skip_tick", false)
			else:
				var t := int(unit.get_meta("doceva_tears_e2_vuln_turns", 0)) - 1
				unit.set_meta("doceva_tears_e2_vuln_turns", t)
				
		if unit.has_meta("e4_phys_weakness_turns"):
			var e4_turns: int = int(unit.get_meta("e4_phys_weakness_turns", 0))
			if e4_turns > 0:
				unit.set_meta("e4_phys_weakness_turns", e4_turns - 1)
				if e4_turns - 1 == 0:
					unit.weaknesses.erase(CombatConstants.Element.PHYSICAL)
					log_message("Слабость от Е4 Каори на %s рассеялась." % unit.display_name)

		if unit.has_meta("shoji_burn_turns") and int(unit.get_meta("shoji_burn_turns", 0)) > 0:
			var shoji := get_shoji_unit()
			if shoji and shoji.is_alive():
				var talent_mult := 1.20 
				if shoji.eidolon >= 5:
					talent_mult *= 1.20 
					
				var dot_res: Dictionary = calc_dmg(shoji, unit, talent_mult, 0.0, false, 0.0, 0.0, false, false)
				var dot_dmg: float = float(dot_res.get("damage", 0.0))
				
				if shoji.eidolon >= 2:
					dot_dmg *= 1.30
					
				deal_damage(unit, dot_dmg, shoji, CombatConstants.Element.FIRE, false, "DoT")
				log_message("DoT Горения Сёдзи на %s: %d урона." % [unit.display_name, int(dot_dmg)])
				
				var turns: int = int(unit.get_meta("shoji_burn_turns", 0)) - 1
				unit.set_meta("shoji_burn_turns", turns)
				if turns <= 0:
					unit.set_meta("shoji_burn_stacks", 0)
					log_message("Горение Сёдзи на %s угасло." % unit.display_name)
					
		if unit.has_meta("shoji_fire_res_reduced_turns"):
			var fr_turns: int = int(unit.get_meta("shoji_fire_res_reduced_turns", 0))
			if fr_turns > 0:
				unit.set_meta("shoji_fire_res_reduced_turns", fr_turns - 1)
				if fr_turns - 1 == 0:
					log_message("Огненная уязвимость Сёдзи на %s рассеялась." % unit.display_name)
					
		# ИСПРАВЛЕНО: Периодический урон Сияния (Идеальный Метаморфоз) наносится в ход врага
		if unit.has_meta("radiance_status_turns") and int(unit.get_meta("radiance_status_turns", 0)) > 0:
			var radiance_host: CombatUnit = unit.get_meta("radiance_owner")
			if radiance_host and radiance_host.is_alive():
				var dot_res := calc_dmg(radiance_host, unit, 0.70, 0.0, false, 0.0, 0.0, false, false)
				var dot_dmg: float = float(dot_res.get("damage", 0.0))
				deal_damage(unit, dot_dmg, radiance_host, CombatConstants.Element.FIRE, false, "DoT")
				log_message("DoT Сияния на %s: %d урона." % [unit.display_name, int(dot_dmg)])
				
			var r_turns := int(unit.get_meta("radiance_status_turns", 0)) - 1
			unit.set_meta("radiance_status_turns", r_turns)
		
		if unit.has_meta("hq_burn_turns") and int(unit.get_meta("hq_burn_turns", 0)) > 0:
			var hq_turns: int = int(unit.get_meta("hq_burn_turns", 0)) - 1
			unit.set_meta("hq_burn_turns", hq_turns)
			var hq_dmg: float = float(unit.get_meta("hq_burn_dmg", 1000.0))
			var hq_atk: CombatUnit = unit.get_meta("hq_burn_attacker", null)
			deal_damage(unit, hq_dmg, hq_atk, CombatConstants.Element.FIRE, false, "DoT")
			log_message("🔥 DoT Горения «Лавовый отпор» на %s: %d урона." % [unit.display_name, int(hq_dmg)])
			if hq_turns <= 0:
				unit.remove_meta("hq_burn_turns")
				unit.remove_meta("hq_burn_dmg")
				unit.remove_meta("hq_burn_attacker")
		
	if unit.id == "vika" and unit.is_alive():
		if int(unit.get_meta("vika_awakening_turns", 0)) > 0:
			var heal_amt := unit.stats.max_hp * 0.30
			heal_unit(unit, heal_amt)
			log_message("Пробуждение Вики: восстановлено 30%% макс. ХП (+%d)." % int(heal_amt))

	set_meta("current_damage_tag", "DoT")
	ToughnessSystem.process_turn_start_dots(unit, self)
	set_meta("current_damage_tag", "")
	MarinaAbilities.tick_suppression_turn(unit)
	ToughnessSystem.tick_imaginary_debuff(unit)
	
func _update_marina_e4() -> void:
	for ally in allies:
		if ally.id == MarinaAbilities.ID:
			MarinaAbilities.apply_e4_speed_bonus(ally, enemies)

# === НАЙДИТЕ И ОБНОВИТЕ ЭТИ МЕТОДЫ В BATTLE_MANAGER.GD ===

func _execute_enemy_turn(enemy: CombatUnit) -> void:
	if enemy.has_meta("is_joan_spirit_clone"):
		var available_targets := get_valid_targets_for_enemy(enemy)
		if available_targets.is_empty():
			available_targets = get_living_allies()
		if not available_targets.is_empty():
			var target_ally: CombatUnit = available_targets.pick_random()
			log_message("👻 %s атакует %s на 5%% СА!" % [enemy.display_name, target_ally.display_name])
			var res := calc_dmg(enemy, target_ally, 0.05)
			deal_damage(target_ally, res.damage, enemy, enemy.element, res.crit)
		_end_turn(enemy)
		return
	var turn_count: int = enemy.get_meta("turn_count", 0) + 1
	enemy.set_meta("turn_count", turn_count)

	match enemy.id:
		VoidElite.ID:
			match VoidElite.pick_skill(turn_count):
				"aoe":
					VoidElite.execute_aoe_skill(enemy, allies, self)
				"heal":
					VoidElite.execute_self_heal(enemy, self)
				_:
					_execute_enemy_basic(enemy)
		VoidSoldier.ID:
			if VoidSoldier.should_use_splash(turn_count):
				VoidSoldier.execute_splash_attack(enemy, allies, self)
			else:
				_execute_enemy_basic(enemy)
		"void_boss":
			var available_targets: Array[CombatUnit] = get_valid_targets_for_enemy(enemy) # <--- ИСПРАВЛЕНО
			if available_targets.is_empty():
				for a in allies:
					if a.is_alive(): available_targets.append(a)
						
			var danill := get_danila_unit()
			var selected_target: CombatUnit = null
			if danill and danill.is_alive() and int(danill.get_meta("danill_taunt_turns", 0)) > 0 and danill in available_targets:
				selected_target = danill
			else:
				selected_target = VoidBoss.pick_target(available_targets)
				
			if selected_target:
				match VoidBoss.pick_skill(turn_count):
					"freeze":
						VoidBoss.execute_freeze_attack(enemy, selected_target, self)
					"aoe":
						VoidBoss.execute_aoe_attack(enemy, allies, self)
					_:
						var result: Dictionary = VoidBoss.execute_basic_attack(enemy, selected_target)
						var dmg_val: float = float(result.get("damage", 0.0))
						deal_damage(selected_target, dmg_val, enemy, -1, result.get("crit", false))
						log_message("%s атакует %s: %d урона." % [enemy.display_name, selected_target.display_name, int(dmg_val)])
		"void_armored":
			var available_targets: Array[CombatUnit] = get_valid_targets_for_enemy(enemy) # <--- ИСПРАВЛЕНО
			if available_targets.is_empty():
				for a in allies:
					if a.is_alive(): available_targets.append(a)
						
			var danill := get_danila_unit()
			var selected_target: CombatUnit = null
			if danill and danill.is_alive() and int(danill.get_meta("danill_taunt_turns", 0)) > 0 and danill in available_targets:
				selected_target = danill
			else:
				selected_target = VoidArmored.pick_target(available_targets)
				
			if selected_target:
				if turn_count > 0 and turn_count % VoidArmored.ARMOR_INTERVAL == 0:
					VoidArmored.execute_armor_skill(enemy, self)
				else:
					var result: Dictionary = VoidArmored.execute_basic_attack(enemy, selected_target)
					var dmg_val: float = float(result.get("damage", 0.0))
					deal_damage(selected_target, dmg_val, enemy, -1, result.get("crit", false))
					log_message("%s атакует %s: %d урона." % [enemy.display_name, selected_target.display_name, int(dmg_val)])
		"masked_silhouette": # ДОБАВЛЕНО: Обработка хода Силуэта в маске
			MaskedSilhouette.execute_turn(enemy, allies, self)
		"server_virus":
			ServerVirus.execute_turn(enemy, allies, self)
		"ortho_mutant":
			OrthoMutant.execute_turn(enemy, allies, self)
		"infected":
			Infected.execute_turn(enemy, allies, self)
		"ortho_spore":
			OrthoMutant.execute_spore_turn(enemy, allies, self)
		_:
			_execute_enemy_basic(enemy)

	_end_turn(enemy)
	
func _execute_enemy_basic(enemy: CombatUnit) -> void:
	var available_targets: Array[CombatUnit] = get_valid_targets_for_enemy(enemy) # <--- ИСПРАВЛЕНО
	if available_targets.is_empty():
		for a in allies:
			if a.is_alive(): available_targets.append(a)
				
	if available_targets.is_empty():
		return

	var danill := get_danila_unit()
	var target: CombatUnit = null
	if danill and danill.is_alive() and int(danill.get_meta("danill_taunt_turns", 0)) > 0 and danill in available_targets:
		target = danill
	else:
		target = VoidSoldier.pick_target(available_targets)
		
	if target == null:
		return

	var result := VoidSoldier.execute_basic_attack(enemy, target)
	deal_damage(target, result.damage, enemy, -1, result.crit)
	log_message(
		"%s атакует %s: %d урона%s" % [
			enemy.display_name,
			target.display_name,
			int(result.damage),
			" (КРИТ!)" if result.crit else "",
		],
	)
	
func _get_element_color(elem: int) -> Color:
	match elem:
		CombatConstants.Element.FIRE:
			return Color(1.0, 0.28, 0.2)     
		CombatConstants.Element.ICE:
			return Color(0.3, 0.8, 1.0)      
		CombatConstants.Element.LIGHTNING:
			return Color(0.75, 0.45, 1.0)    
		CombatConstants.Element.WIND:
			return Color(0.2, 0.85, 0.45)    
		CombatConstants.Element.PHYSICAL:
			return Color(0.673, 0.673, 0.673, 1.0)      
		CombatConstants.Element.QUANTUM:
			return Color(0.55, 0.2, 0.85)
		CombatConstants.Element.IMAGINARY:
			return Color(0.971, 0.802, 0.243, 1.0) 
		_:
			var elem_str = str(elem).to_lower()
			if "fire" in elem_str: return Color(1.0, 0.28, 0.2)
			if "ice" in elem_str: return Color(0.3, 0.8, 1.0)
			if "lightning" in elem_str: return Color(0.75, 0.45, 1.0)
			if "wind" in elem_str: return Color(0.2, 0.85, 0.45)
			if "quantum" in elem_str: return Color(0.55, 0.2, 0.85)
			if "physical" in elem_str: return Color(0.673, 0.673, 0.673, 1.0) 
			if "imaginary" in elem_str: return Color(0.971, 0.802, 0.243, 1.0) 
			return Color(0.9, 0.9, 0.9)
				
# Новый хелпер: наносит урон стойкости и дополнительно задерживает на 75% при пробитии под Подавлением
# Исправленная версия с поддержкой передачи self (BattleManager) на 3-й позиции
# Исправленная версия: 3-й аргумент стал необязательным (по умолчанию null)
# Обновленный хелпер apply_weakness_hit_and_delay:
# === ЗАМЕНИТЬ ЭТОТ МЕТОД В BATTLE_MANAGER.GD ===
func apply_weakness_hit_and_delay(attacker: CombatUnit, target: CombatUnit, battle_manager: BattleManager = null, multiplier: float = 1.0) -> void:
	var bm = battle_manager
	if bm == null:
		bm = self 
		
	var was_broken: bool = target.statuses.toughness_broken # Явно типизирован bool
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, multiplier)
	LevelManager.on_toughness_broken(self)
	
	if not was_broken and target.statuses.toughness_broken:
		if battle_mode == "dungeon_hq" and attacker.is_ally:
			target.set_meta("hq_burn_turns", 2)
			target.set_meta("hq_burn_dmg", attacker.stats.atk * 1.0)
			target.set_meta("hq_burn_attacker", attacker)
			log_message("🔥 Аномалия «Лавовый отпор»: Пробитие стойкости наложило Горение на %s (100%% СА = %d урона на 2 хода)!" % [target.display_name, int(attacker.stats.atk * 1.0)])
			
		# --- ГЛОБАЛЬНЫЙ СРЕЗ ЗАЩИТЫ ЖЕРТВЫ СИМБИОЗА (4 части) ПРИ ПРОБОЕ ---
		if attacker.has_meta("set_symbiosis_4"):
			apply_def_reduction(target, "Жертва долгого симбиоза (4ч)", 0.15, 99) # 99 ходов (до восстановления уязвимости)
			log_message("❄ Сет Симбиоза (4ч) %s: Защита %s снижена на 15%% при пробитии!" % [attacker.display_name, target.display_name])
		
		if attacker.id == "joan" and attacker.eidolon >= 4:
			target.delay_action(30.0)
			log_message("⚡ Эйдолон 4 Жоана: Ход %s отложен на доп. 30%% при пробитии уязвимости!" % target.display_name)
			
		var milena := get_milena_unit()
		if milena and milena.is_alive():
			# 1. Обертон: задержка цели на 50% при пробитии
			if int(milena.get_meta("milena_overtone_turns", 0)) > 0:
				target.delay_action(50.0)
				log_message("💥 Обертон Милены: действие %s задержано на доп. 50%% при пробитии уязвимости." % target.display_name)
				
			# 2. След 2: накладывает 2 уровня Заключения при любом пробитии
			target.delay_action(60.0)
			target.statuses.imaginary_spd_debuff_turns = 2
			target.statuses.imaginary_source = "Милена (След 2)"
			target.stats.add_spd_debuff(0.20)
			log_message("💥 След 2 Милены: %s получил 2 уровня Заключения независимо от уязвимостей." % target.display_name)

		if target.statuses.suppression_stacks > 0:
			target.delay_action(75.0)
			log_message("💥 Талант Марины: уязвимость %s пробита под Подавлением! Ход задержан на доп. 75%%." % target.display_name)
			
# Вспомогательный метод: применение среза защиты (рассчитывается от БАЗОВОЙ защиты врага)
func apply_def_reduction(target: CombatUnit, source_name: String, percent: float, turns: int) -> void:
	if target == null:
		return

	# --- ВЗАИМНОЕ ИСКЛЮЧЕНИЕ СРЕЗОВ ЗАЩИТЫ ВАЛРАМОРСА ---
	if source_name == "Передача порчи (Валраморс)":
		if has_def_reduction_source(target, "Навык Валраморса") or has_def_reduction_source(target, "Навык Валраморса (Е6)"):
			log_message("🛡 Иммунитет: На %s уже действует срез защиты от Навыка Q. Порча отклонена!" % target.display_name)
			return
	elif source_name == "Навык Валраморса" or source_name == "Навык Валраморса (Е6)":
		if has_def_reduction_source(target, "Передача порчи (Валраморс)"):
			log_message("🛡 Иммунитет: На %s уже действует срез от Передачи порчи. Срез Навыка Q отклонен!" % target.display_name)
			return
	var base_def := float(target.get_meta("base_def", target.stats.def))
	if not target.has_meta("base_def"):
		target.set_meta("base_def", target.stats.def)
		base_def = target.stats.def
		
	var reductions: Dictionary = {}
	if target.has_meta("def_reductions"):
		reductions = target.get_meta("def_reductions")

	
	# Записываем срез (если источник уже есть, он просто обновит проценты и длительность)
	reductions[source_name] = {
		"percent": percent,
		"turns": turns
	}
	target.set_meta("def_reductions", reductions)
	
	if battle_mode == "level_18" and target != null and not target.is_ally:
		if not target.has_meta("level18_vuln_turns") or int(target.get_meta("level18_vuln_turns", 0)) <= 0:
			target.set_meta("level18_vuln_turns", 2)
			target.statuses.damage_taken_bonus += 0.15
			log_message("⚡ Аномалия 18 Уровня: Наложение ослабления повысило получаемый урон %s на +15%% на 2 хода!" % target.display_name)
	
	notify_debuff_applied(target)
	recalculate_target_def(target)

func notify_debuff_applied(target: CombatUnit = null, source_unit: CombatUnit = null) -> void:
	var dt := get_dotseva_crimson_tears_unit()
	if dt and dt.is_alive():
		DotsevaCrimsonTearsAbilities.add_close_your_eyes_stack(dt, self)

func get_unit_debuff_count(unit: CombatUnit) -> int:
	if unit == null:
		return 0
	var count: int = 0
	if unit.has_meta("def_reductions"):
		var reds: Dictionary = unit.get_meta("def_reductions")
		count += reds.size()
	if unit.statuses.break_status != "":
		count += 1
	if unit.statuses.suppression_stacks > 0:
		count += 1
	if unit.statuses.imaginary_spd_debuff_turns > 0:
		count += 1
	if unit.statuses.atk_buff_percent < 0.0:
		count += 1
	if unit.statuses.damage_taken_bonus > 0.0:
		count += 1
	count += unit.statuses.debuffs.size()
	if int(unit.get_meta("doceva_tears_q_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("doceva_tears_outgoing_dmg_red_turns", 0)) > 0: count += 1
	if int(unit.get_meta("doceva_tears_e2_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("katarina_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("katarina_e1_spd_debuff_turns", 0)) > 0: count += 1
	if int(unit.get_meta("katarina_q_ally_mark_turns", 0)) > 0: count += 1
	if bool(unit.get_meta("katarina_broken_spirit", false)): count += 1
	if unit.has_meta("katarina_e6_binary_vuln"): count += 1
	if int(unit.get_meta("shoji_swan_dance_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("shoji_swan_tech_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("shoji_fire_res_reduced_turns", 0)) > 0: count += 1
	if int(unit.get_meta("phys_res_reduced_turns", 0)) > 0: count += 1
	if int(unit.get_meta("quantum_res_reduced_turns", 0)) > 0: count += 1
	if int(unit.get_meta("naama_kiss_turns", 0)) > 0: count += 1
	if int(unit.get_meta("naama_dot_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("naama_intox_stacks", 0)) > 0: count += 1
	if int(unit.get_meta("valramors_talent_turns", 0)) > 0: count += 1
	if int(unit.get_meta("valramors_ult_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("joan_dont_miss_turns", 0)) > 0: count += 1
	if int(unit.get_meta("joan_tech_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("sara_e2_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("binary_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("arseniy_binary_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("arseniy_trace3_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("isaac_crit_dmg_taken_turns", 0)) > 0: count += 1
	if int(unit.get_meta("isaac_dmg_reduce_turns", 0)) > 0: count += 1
	return count

# Метод перерасчета текущей защиты врага на основе всех активных дебаффов
# Метод перерасчета текущей защиты врага на основе всех активных дебаффов
func recalculate_target_def(target: CombatUnit) -> void:
	var base_def := float(target.get_meta("base_def", target.stats.def))
	if not target.has_meta("base_def"):
		target.set_meta("base_def", target.stats.def)
		base_def = target.stats.def
		
	var total_reduction_pct := 0.0
	
	# Чтение стандартных срезов из словаря дебаффов
	if target.has_meta("def_reductions"):
		var reductions: Dictionary = target.get_meta("def_reductions")
		for src in reductions:
			var data: Dictionary = reductions[src]
			if int(data.get("turns", 0)) > 0:
				total_reduction_pct += float(data.get("percent", 0.0))
				
	# --- СЛЕД 2 НААМЫ: Срез защиты при наличии статуса Поцелуй бездны ---
	if target.has_meta("naama_kiss_turns") and int(target.get_meta("naama_kiss_turns", 0)) > 0:
		total_reduction_pct += 0.15
		
	if target.has_meta("naama_intox_stacks") and int(target.get_meta("naama_intox_stacks", 0)) >= 20:
		total_reduction_pct += 0.20
		
	total_reduction_pct = minf(total_reduction_pct, 1.0) # Срез защиты не может превышать 100%
	target.stats.def = maxf(base_def * (1.0 - total_reduction_pct), 0.0)
	unit_updated.emit(target)
									
func deal_damage(target: CombatUnit, amount: float, attacker: CombatUnit = null, element_override: int = -1, is_crit: bool = false, tag_override: String = "") -> float:
	if amount <= 0.0:
		return 0.0
		
	var was_alive := target.is_alive()
	var was_hp_ratio: float = (target.stats.hp / target.stats.max_hp) if target.stats.max_hp > 0.0 else 1.0
	var original_amount: float = amount

	if attacker:
		_last_attacker = attacker
	
	var is_true_damage: bool = (tag_override == "lenskaya_true_fua" or tag_override == "musienko_true_damage" or tag_override == "rimes_execution" or tag_override == "True Damage")
	
	var is_binary: bool = (tag_override == "Binary" or tag_override == "binary" or tag_override == "BinaryGroup" or (attacker != null and attacker.has_meta("is_binary_attack")))
	var isaac_admin_ref: CombatUnit = get_isaac_admin_unit()
	var shoji_swan_ref: CombatUnit = get_shoji_swan_unit()
	if ((isaac_admin_ref and isaac_admin_ref.is_alive() and isaac_admin_ref.eidolon >= 6) or (shoji_swan_ref and shoji_swan_ref.is_alive() and shoji_swan_ref.eidolon >= 6)) and attacker != null and attacker.is_ally:
		is_binary = true

	# Проверка иммунитета от дуэли Вечной Изоляции Раймса
	if target and (target.has_meta("rimes_isolation_target") or target.has_meta("rimes_isolation_source")):
		if not is_rimes_duel_active():
			var is_immune := true
			if target.id == "rimes":
				if attacker == target.get_meta("rimes_isolation_target"):
					is_immune = false
			else:
				if attacker == target.get_meta("rimes_isolation_source"):
					is_immune = false
			if is_immune:
				return 0.0

	if attacker and attacker.is_ally and attacker.id != "rimes" and (attacker.has_meta("rimes_isolation_target") or attacker.has_meta("rimes_isolation_source")):
		if not is_rimes_duel_active():
			if target != attacker:
				return 0.0

	if attacker and not attacker.is_ally and (attacker.has_meta("rimes_isolation_target") or attacker.has_meta("rimes_isolation_source")):
		if not is_rimes_duel_active():
			if target.id != "rimes" and target != attacker:
				return 0.0

	# Иммунитет Катарины в состоянии «Лишь воспоминание»
	if target and target.id == "katarina" and int(target.get_meta("katarina_just_a_memory_turns", 0)) > 0:
		combat_text_spawned.emit(target, "Иммунитет", Color(0.9, 0.9, 1.0), "Лишь воспоминание", false)
		return 0.0

	# Блокировка урона Катарины по целям со статусом «Сломленный дух»
	if attacker and attacker.id == "katarina" and target and bool(target.get_meta("katarina_broken_spirit", false)):
		if attacker.has_meta("katarina_blood_murmur") and bool(attacker.get_meta("katarina_blood_murmur", false)):
			var recorded: float = float(target.get_meta("katarina_recorded_broken_spirit_dmg", 0.0)) + amount
			target.set_meta("katarina_recorded_broken_spirit_dmg", recorded)
			log_message("⛓ Сломленный дух: %s неуязвим к урону Катарины! Записано %d ед. урона." % [target.display_name, int(amount)])
		_handle_why_did_you_remember_me(attacker, target, original_amount, 0.0, tag_override)
		combat_text_spawned.emit(target, "Блок (Дух)", Color(0.7, 0.7, 0.7), "Сломленный дух", false)
		return 0.0

	# Ограничение урона Катарины пороговыми значениями (80%, 50%, 5%) и наложение «Сломленного духа»
	if attacker and attacker.id == "katarina" and target and not target.is_ally and target.stats.max_hp > 0.0:
		var has_bs := bool(target.get_meta("katarina_broken_spirit", false))
		if not has_bs:
			var cur_ratio := target.stats.hp / target.stats.max_hp
			var projected_ratio := (target.stats.hp - amount) / target.stats.max_hp
			var hit_threshold := false
			var target_hp := target.stats.hp

			if cur_ratio > 0.80 and projected_ratio <= 0.80:
				target_hp = target.stats.max_hp * 0.80
				amount = maxf(0.0, target.stats.hp - target_hp)
				hit_threshold = true
			elif cur_ratio > 0.50 and projected_ratio <= 0.50:
				target_hp = target.stats.max_hp * 0.50
				amount = maxf(0.0, target.stats.hp - target_hp)
				hit_threshold = true
			elif cur_ratio > 0.05 and projected_ratio <= 0.05:
				target_hp = target.stats.max_hp * 0.05
				amount = maxf(0.0, target.stats.hp - target_hp)
				hit_threshold = true

			if hit_threshold:
				target.set_meta("katarina_broken_spirit", true)
				if attacker.has_meta("katarina_blood_murmur") and bool(attacker.get_meta("katarina_blood_murmur", false)):
					var excess_dmg: float = maxf(0.0, original_amount - amount)
					if excess_dmg > 0.0:
						var recorded: float = float(target.get_meta("katarina_recorded_broken_spirit_dmg", 0.0)) + excess_dmg
						target.set_meta("katarina_recorded_broken_spirit_dmg", recorded)
						log_message("⛓ Сломленный дух (Порог): Избыточный урон %d записан для %s (Всего: %d)." % [int(excess_dmg), target.display_name, int(recorded)])
				log_message("⛓ Талант Катарины: Урон ограничен порогом! Наложен статус «Сломленный дух» на %s (Катарина перестаёт наносить урон)." % target.display_name)
				unit_updated.emit(target)

	# Перенаправление урона Зоны Доцевой • Багровые слёзы
	if target and target.is_ally and tag_override != "doceva_tears_redirect":
		var doceva_tears_unit: CombatUnit = get_dotseva_crimson_tears_unit()
		if doceva_tears_unit and doceva_tears_unit.is_alive() and bool(doceva_tears_unit.get_meta("doceva_tears_zone_active", false)):
			var guarded_ally: CombatUnit = doceva_tears_unit.get_meta("doceva_tears_guarded_ally", null)
			if target == guarded_ally:
				gain_energy_with_err(target, 10.0)
				gain_energy_with_err(doceva_tears_unit, 5.0)
				combat_text_spawned.emit(target, "100% В Доцеву", Color(1.0, 0.4, 0.4), "Перенаправление", false)
				deal_damage(doceva_tears_unit, amount, attacker, element_override, is_crit, "doceva_tears_redirect")
				return 0.0
			elif target != doceva_tears_unit:
				var redirected: float = amount * 0.80
				amount = amount * 0.20
				gain_energy_with_err(doceva_tears_unit, 5.0)
				deal_damage(doceva_tears_unit, redirected, attacker, element_override, is_crit, "doceva_tears_redirect")

	# След 2 Доцевой: Получаемый урон уменьшается на 30%
	if target and target.id == "dotseva_crimson_tears":
		amount *= 0.70

	# Конус «Первые минуты войны»: Получаемый урон снижается на 20%
	if target and target.get_meta("light_cone_id", "") == "first_minutes_of_war":
		amount *= 0.80

	# Конус «История, вымоченная в крови»: За каждую полученную атаку получаемый урон снижается на 3% (макс 10 стаков = 30%)
	if target and target.get_meta("light_cone_id", "") == "history_soaked_in_blood":
		var b_stacks: int = int(target.get_meta("blood_soaked_dmg_red_stacks", 0))
		if b_stacks > 0:
			amount *= (1.0 - minf(float(b_stacks) * 0.03, 0.30))
		
	var dealt: float = 0.0
	
	# --- ТРИГГЕРЫ СИЛУЭТА В МАСКЕ (БОСС) ---
	# 1. Сбивание слоев «Тайны сияющей маски» при получении любого урона в Фазе 2
	if target.id == "masked_silhouette" and target.has_meta("mask_layers") and int(target.get_meta("mask_layers", 0)) > 0:
		var allies_alive := get_living_allies()
		var is_isolated := false
		
		if target.has_meta("rimes_isolation_source") or allies_alive.size() <= 1:
			is_isolated = true
			
		if is_isolated:
			target.remove_meta("mask_layers")
			target.set_meta("silhouette_mask_def_buff", 0.0)
			apply_def_reduction(target, "Разоблачение Силуэта", 0.20, 99)
			log_message("🎭 Тайна сияющей маски: Силуэт остался один на один! Защитные слои маски мгновенно рассыпались. Защита −20%% до конца боя.")
			unit_updated.emit(target)
		else:
			var layers := int(target.get_meta("mask_layers", 0)) - 1
			target.set_meta("mask_layers", layers)
			log_message("🎭 Силуэт в маске получил урон! Слои маски снижены: %d/14." % layers)
			
			if allies_alive.size() > 0:
				var first_ally := allies_alive[0]
				var retal_dmg := first_ally.stats.max_hp * 0.03
				deal_damage(first_ally, retal_dmg, target, CombatConstants.Element.QUANTUM, false, "mask_retaliation")
				
			if layers == 0:
				target.remove_meta("mask_layers")
				target.set_meta("silhouette_mask_def_buff", 0.0)
				apply_def_reduction(target, "Разоблачение Силуэта", 0.20, 99)
				log_message("🎭 Тайна сияющей маски: Все слои уничтожены! Защита Силуэта снижена на -20%% до конца боя!")
				unit_updated.emit(target)
				
	if is_true_damage:
		dealt = target.apply_damage(amount)
	else:
		if target.has_meta("dotseva_e6_shared_target") and tag_override != "copied_e6":
			var adjacent := get_adjacent_enemies(target)
			for adj in adjacent:
				if adj.is_alive():
					deal_damage(adj, amount, attacker, -1, false, "copied_e6")

		var shield_absorbed := 0.0
		if target.is_ally:
			var shield_val: float = float(target.get_meta("shield_value", 0.0))
			if shield_val > 0.0:
				var had_dasha_shield := (String(target.get_meta("shield_source", "")) == "Щит Даши • Админ")
				if amount >= shield_val:
					shield_absorbed = shield_val
					amount -= shield_val
					target.set_meta("shield_value", 0.0)
					target.set_meta("shield_turns", 0)
					log_message("Щит на %s был полностью разрушен!" % target.display_name)
					if target.id == "danill" and target.get_meta("e_shield_active", false):
						_on_danill_e_shield_broken(target)
				else:
					shield_absorbed = amount
					shield_val -= amount
					amount = 0.0
					target.set_meta("shield_value", shield_val)

				if had_dasha_shield:
					var dasha_u := get_dasha_admin_unit()
					if dasha_u and dasha_u.is_alive():
						add_console_vectors(1)
						DashaAdminAbilities.add_digital_footprint(dasha_u, 2, self)
						log_message("🛡 След 2 Даши: Удар по защищенному союзнику восполнил +1 Вектор и +2 Цифровых следа!")

				if shield_absorbed > 0.0:
					combat_text_spawned.emit(target, "-%d" % int(shield_absorbed), Color(0.75, 0.85, 1.0), "Щит", false)

		var would_kill := target.stats.hp - amount <= 0.0
		
		if would_kill and target.id == "musienko" and target.has_meta("musienko_annihilation_active") and target.eidolon >= 2:
			if attacker and not attacker.is_ally:
				amount = maxf(0.0, target.stats.hp - 1.0)
				would_kill = false
				log_message("🛡 Эйдолон 2 Мусиенко: Бессмертие заблокировало гибель!")
		
		if would_kill and target.id == "joan_spirit":
			if target.get_meta("joan_spirit_form", false):
				target.set_meta("joan_spirit_form", false)
				target.set_meta("joan_last_wish", 0)
				target.energy = 0.0
				target.stats.hp = target.stats.max_hp * 0.10
				amount = 0.0
				would_kill = false
				log_message("🌟 Талант Жоана: «Форма духа» развеяна! Здоровье спасено на 10%%, Жоан возвращается к жизни.")
				unit_updated.emit(target)
				return 0.0
				
		if would_kill and target.is_ally:
			var is_chaos_ally := target.id in ["arseniy", "dasha", "shoji", "danill", "kaori", "musienko", "lenskaya", "valramors"]
			if is_chaos_ally:
				var milena := get_milena_unit()
				if milena and milena.is_alive() and not target.has_meta("second_chance_used"):
					target.stats.hp = 1.0
					target.set_meta("second_chance_active", true)
					target.set_meta("second_chance_turns", 2)
					target.set_meta("second_chance_used", true)
					log_message("⏳ Талант Милены: «Второй шанс» предотвратил гибель %s!" % target.display_name)
					unit_updated.emit(target)
					_check_battle_end()
					return 0.0

			if arya_active:
				amount = maxf(0.0, target.stats.hp - 1.0)
			elif SaraAbilities.try_e4_revive(target, self):
				unit_updated.emit(target)
				return 0.0
				
		if target.id == "vika" and not target.get_meta("vika_talent_used", false):
			var projected_hp := target.stats.hp - amount
			var projected_hp_ratio := projected_hp / target.stats.max_hp
			
			if projected_hp <= 0.0:
				target.stats.hp = target.stats.max_hp 
				target.set_meta("vika_talent_used", true)
				target.set_meta("vika_awakening_turns", 0) 
				if target.eidolon >= 1:
					gain_energy_with_err(target, 40.0)
				unit_updated.emit(target)
				_check_battle_end()
				return 0.0 
			elif projected_hp_ratio < 0.20:
				dealt = target.apply_damage(amount)
				target.heal(target.stats.max_hp) 
				target.set_meta("vika_talent_used", true)
				target.advance_action(100.0) 
				if target.eidolon >= 1:
					gain_energy_with_err(target, 40.0)
				unit_updated.emit(target)
				action_order_changed.emit()
				_check_battle_end()
				return dealt
				
		if has_meta("admin_god_mode") and bool(get_meta("admin_god_mode", false)) and target.is_ally:
			amount = 0.0

		dealt = target.apply_damage(amount)

	# --- ОБЩИЕ ПОСТ-ТРИГГЕРЫ УРОНА (РАБОТАЮТ ДЛЯ ВСЕХ ВИДОВ УРОНА) ---
	if dealt > 0.0:
		trigger_accepted_sin_hp_loss(target)
	
	# Талант Арсения Админа: Союзник атакует цель под срезом защиты Арсения -> +5 Векторов
	if dealt > 0.0 and target.is_alive() and not target.is_ally and attacker and attacker.is_ally:
		var has_ars_def_shred := false
		if target.has_meta("def_reductions"):
			for src in target.get_meta("def_reductions"):
				if "арсений" in src.to_lower() or "arseniy" in src.to_lower():
					has_ars_def_shred = true
					break
					
		if has_ars_def_shred:
			if not has_meta("arseniy_talent_credited_this_action"):
				set_meta("arseniy_talent_credited_this_action", true)
				var ars := get_arseniy_admin_unit()
				if ars and ars.is_alive():
					log_message("⚡ Талант Арсения Админа: Атака по ослабленной цели восстановила 5 Векторов!")
					add_console_vectors(5)
											
	if was_alive and not target.is_alive() and not target.is_ally:
		var ars := get_arseniy_admin_unit()
		if ars and ars.is_alive() and ars.eidolon >= 1:
			gain_energy_with_err(ars, 5.0)
			
	# Талант Жоана: +1 Последнее желание, когда союзник наносит урон себе сам
	if dealt > 0.0 and target.is_ally and attacker == target:
		if not has_meta("joan_wish_granted_self_harm_turn"):
			set_meta("joan_wish_granted_self_harm_turn", true)
			var js: CombatUnit = get_joan_spirit_unit()
			if js and js.is_alive():
				JoanSpiritAbilities.add_last_wish(js, 1, self)
		
	if dealt > 0.0 and target.is_ally and attacker and not attacker.is_ally:
		if target.has_meta("set_silhouette_4"):
			var s_stacks: int = int(target.get_meta("relic_silhouette_stacks", 0))
			if s_stacks < 5:
				var new_s_stacks: int = s_stacks + 1
				target.set_meta("relic_silhouette_stacks", new_s_stacks)
				target.set_meta("relic_silhouette_atk_pct", float(new_s_stacks) * 0.05)
				
	if attacker and attacker.get_meta("light_cone_id", "") == "perfect_metamorphosis" and tag_override != "copied_e6" and tag_override != "cant_kill_bonus_hit" and tag_override != "debtor_proc" and tag_override != "dotseva_fua" and tag_override != "dotseva_fua_normal" and tag_override != "DoT":
		var current_stacks := int(attacker.get_meta("meta_spd_stacks", 0))
		if current_stacks < 3:
			attacker.set_meta("meta_spd_stacks", current_stacks + 1)
			attacker.add_speed_modifier(0.0, 6.0)

	if attacker and attacker.get_meta("light_cone_id", "") == "perfect_metamorphosis" and not target.is_ally:
		if not target.has_meta("radiance_status_turns") or int(target.get_meta("radiance_status_turns", 0)) <= 0:
			target.set_meta("radiance_status_turns", 1)
			target.set_meta("radiance_owner", attacker)
			log_message("🦋 Конус «Идеальный метаморфоз»: на %s наложен статус «Сияние» (Горение) на 1 ход." % target.display_name)
			
	if attacker and attacker.get_meta("light_cone_id", "") == "cant_kill_you" and is_crit and tag_override != "cant_kill_bonus_hit" and tag_override != "copied_e6" and tag_override != "debtor_proc" and tag_override != "dotseva_fua" and tag_override != "dotseva_fua_normal" and tag_override != "DoT":
		var extra_dmg := attacker.stats.get_effective_atk(attacker.statuses) * 0.20
		deal_damage(target, extra_dmg, attacker, attacker.element, false, "cant_kill_bonus_hit")
		
	var is_any_fua: bool = (tag_override == "Бонус-атака" or tag_override == "FollowUp" or tag_override == "dotseva_fua" or tag_override == "copied_e6" or tag_override == "debtor_proc" or tag_override == "lenskaya_fua" or tag_override == "lenskaya_true_fua")
	if attacker and attacker.is_ally and is_any_fua:
		# Конус «Зеркальная иллюзия»: +5 энергии за Бонус-атаку (до 3 раз за ход)
		if attacker.get_meta("light_cone_id", "") == "mirror_illusion":
			if not has_meta("mirror_illusion_credited_this_fua"):
				set_meta("mirror_illusion_credited_this_fua", true)
				var trig: int = int(attacker.get_meta("mirror_illusion_triggers", 0))
				if trig > 0:
					attacker.set_meta("mirror_illusion_triggers", trig - 1)
					gain_energy_with_err(attacker, 5.0)
					log_message("🪞 Конус «Зеркальная иллюзия»: Бонус-атака восстановила 5 ед. энергии %s (осталось зарядов: %d/3)." % [attacker.display_name, trig - 1])
					
		if attacker.has_meta("set_galilean_4"):
			if not has_meta("galilean_fua_started_this_action"):
				set_meta("galilean_fua_started_this_action", true)
				attacker.set_meta("relic_galilean_stacks", 0)
				attacker.set_meta("relic_galilean_atk_pct", 0.0)
				
			var cur_g_stacks: int = int(attacker.get_meta("relic_galilean_stacks", 0))
			if cur_g_stacks < 8:
				var new_g_stacks: int = cur_g_stacks + 1
				attacker.set_meta("relic_galilean_stacks", new_g_stacks)
				attacker.set_meta("relic_galilean_atk_pct", float(new_g_stacks) * 0.04)
				attacker.set_meta("relic_galilean_turns", 3)
				attacker.set_meta("relic_galilean_skip_tick", true)
				
		for ally in allies:
			if ally.is_alive() and ally.has_meta("has_set_irkutsk") and ally != attacker:
				if not ally.has_meta("irkutsk_fua_credited_this_action"):
					ally.set_meta("irkutsk_fua_credited_this_action", true)
					
					var i_stacks: int = int(ally.get_meta("relic_irkutsk_feat_stacks", 0))
					if i_stacks < 5:
						var new_i_stacks: int = i_stacks + 1
						ally.set_meta("relic_irkutsk_feat_stacks", new_i_stacks)
						log_message("Сет Иркутска: %s получил стак Подвига от %s (%d/5)." % [ally.display_name, attacker.display_name, new_i_stacks])

	# Е6 Сары: При нанесении Бинарного урона союзником Сара бьет на 30% СА и продвигает пати на 3%
	if is_binary and attacker and attacker.is_ally and attacker.id != "sara_admin" and not has_meta("sara_e6_processing"):
		var sara_e6 := get_sara_admin_unit()
		if sara_e6 and sara_e6.is_alive() and sara_e6.eidolon >= 6 and target.is_alive():
			set_meta("sara_e6_processing", true)
			var res_e6 := calc_dmg(sara_e6, target, 0.30, 0.0, false, 0.0, 0.0, false, true, "Binary")
			deal_damage(target, res_e6.damage, sara_e6, CombatConstants.Element.LIGHTNING, res_e6.crit, "Binary")
			
			for ally in allies:
				if ally.is_alive():
					ally.advance_action(3.0)
			action_order_changed.emit()
			remove_meta("sara_e6_processing")

	# Файрвол Серверного Вируса: каждый удар Бинарного урона снимает 1 слой
	if is_binary and target.is_alive() and target.id == "server_virus" and target.has_meta("server_virus_firewall"):
		var fw: int = int(target.get_meta("server_virus_firewall", 0))
		if fw > 0:
			fw -= 1
			target.set_meta("server_virus_firewall", fw)
			log_message("🛡 Файрвол Серверного Вируса ослаблен! Осталось слоёв: %d" % fw)
			if fw == 0:
				add_console_vectors(10)
				target.set_meta("server_virus_breached_turns", 2)
				log_message("💥 Файрвол Серверного Вируса полностью взломан! Получено +10 Векторов, цель получает +20% уязвимости на 2 хода!")
				unit_updated.emit(target)
			
	var has_debtor := target.has_meta("dotseva_debtor_status")
	var dotseva_unit := get_dotseva_unit()
	
	if dotseva_unit and dotseva_unit.is_alive() and dotseva_unit.eidolon >= 6:
		has_debtor = true
		
	if was_alive and not target.is_alive() and has_debtor:
		if dotseva_unit and dotseva_unit.is_alive():
			add_calibration_stacks(dotseva_unit, 2)
			var cal_stacks := int(dotseva_unit.get_meta("dotseva_calibration_stacks", 0))
			var debtor_dmg := dotseva_unit.stats.atk * 0.30 + (cal_stacks * 80.0)
			
			var adjacent := get_adjacent_enemies(target)
			for adj in adjacent:
				if adj.is_alive():
					deal_damage(adj, debtor_dmg, dotseva_unit, dotseva_unit.element, false, "debtor_proc")
			
	if was_alive and not target.is_alive() and tag_override == "dotseva_fua":
		var dotseva := get_dotseva_unit()
		if dotseva and dotseva.is_alive():
			add_calibration_stacks(dotseva, 2)

	if attacker != null and attacker.is_ally and not target.is_ally and amount > 0.0:
		if not target in action_hit_enemies:
			action_hit_enemies.append(target)
	
	# Е4 Арсения: доп. 40% СА Бинарным уроном по врагу с ослаблениями (с защитой от рекурсии)
	if attacker and attacker.id == "arseniy_admin" and attacker.eidolon >= 4 and not target.is_ally and not has_meta("arseniy_e4_processing"):
		if not target.statuses.debuffs.is_empty() or target.has_meta("def_reductions") or has_any_dot(target):
			set_meta("arseniy_e4_processing", true)
			var extra_e4 := calc_dmg(attacker, target, 0.40, 0.0, false, 0.0, 0.0, false, true, "Binary")
			deal_damage(target, extra_e4.damage, attacker, CombatConstants.Element.QUANTUM, extra_e4.crit, "Binary")
			remove_meta("arseniy_e4_processing")
			
	# Аномалия Уровня 13: Навыки союзников снижают защиту целей на -10% на 2 хода
	if battle_mode == "level_13" and attacker != null and attacker.is_ally and (tag_override == "Skill" or tag_override == "skill"):
		apply_def_reduction(target, "Сверлящий разряд (ур. 13)", 0.10, 2)
	
	var is_non_ult_tag: bool = (tag_override == "Skill" or tag_override == "skill" or tag_override == "Basic" or tag_override == "basic" or tag_override == "Binary" or tag_override == "Follow-up" or tag_override == "DoT" or tag_override == "True Damage" or tag_override == "blood_soaked_ult_bonus")
	var is_ult_hit: bool = (tag_override == "Ultimate" or tag_override == "ultimate" or (attacker != null and attacker.has_meta("is_casting_ultimate") and not is_non_ult_tag))
	if battle_mode == "level_9" and is_ult_hit and tag_override != "True Damage" and not has_meta("level9_true_processing"):
		if attacker != null and attacker.is_ally and target != null and target.is_alive():
			set_meta("level9_true_processing", true)
			var raw_true_dmg := amount * 0.30
			deal_damage(target, raw_true_dmg, attacker, -1, false, "True Damage")
			remove_meta("level9_true_processing")
	
	# --- ТРИГГЕР ДЖЕФФА: Хилл отряда при тиках DoT на цели под Бассами ---
	if tag_override == "DoT" and target.is_alive() and target.has_meta("jeff_bass_listen_turns") and int(target.get_meta("jeff_bass_listen_turns", 0)) > 0:
		var jeff := get_jeff_unit()
		if jeff and jeff.is_alive():
			var heal_pct: float = 0.03
			var heal_val := jeff.stats.max_hp * heal_pct
			for ally in allies:
				if ally.is_alive():
					heal_unit(ally, heal_val)
			log_message("🎶 Бассы! Слушай!: Сработал DoT-эффект на %s. Отряд исцелен на %d ХП (3%% макс. ХП Джеффа)!" % [target.display_name, int(heal_val)])
			
	
	if target.id == "musienko" and dealt > 0.0:
		MusienkoAbilities.increment_retribution_stacks(target, self)
	
	if original_amount > 0.0 and target.is_ally:
		# 1. Атака врага по союзнику (даже если урон ушел в щит)
		if attacker and not attacker.is_ally:
			gain_energy_with_err(target, 10.0)
			# Срабатывает только в ход врага, при АоЕ по 4 союзникам выдаст ровно 1 стак на первом союзнике
			if current_unit and not current_unit.is_ally:
				notify_joan_spirit_last_wish("enemy_attack")
				
		# 2. Урон союзника самому себе или отряду (в свой ход)
		elif attacker and attacker.is_ally:
			if current_unit and current_unit.is_ally:
				notify_joan_spirit_last_wish("ally_self_harm")
	
	if dealt > 0.0:
		if was_alive and not target.is_alive() and not target.is_ally:
			var keloist := get_keloist_unit()
			if keloist and keloist.is_alive():
				gain_energy_with_err(keloist, 5.0)
			if target.has_meta("keloist_orthoshield_turns") and int(target.get_meta("keloist_orthoshield_turns", 0)) > 0:
				if keloist and keloist.is_alive() and keloist.eidolon >= 2:
					gain_skill_point()
					gain_skill_point()

		if attacker and attacker.is_ally and attacker.id != "keloist" and not target.is_ally and tag_override != "DoT":
			var keloist := get_keloist_unit()
			if keloist and keloist.is_alive():
				KeloistAbilities.increment_command_stacks(keloist, 1, self)
				
		if attacker and attacker.is_ally and tag_override != "DoT" and tag_override != "keloist_joint_attack" and target.is_alive():
			if attacker.has_meta("keloist_orthoshield_turns") and int(attacker.get_meta("keloist_orthoshield_turns", 0)) > 0:
				var hit_list: Array = []
				if attacker.has_meta("keloist_joint_attack_hit_list"):
					hit_list = attacker.get_meta("keloist_joint_attack_hit_list")
				if not target in hit_list:
					hit_list.append(target)
					attacker.set_meta("keloist_joint_attack_hit_list", hit_list)
					KeloistAbilities.trigger_joint_attack(target, self)
	
	var is_ult: bool = (tag_override == "Ultimate" or tag_override == "ultimate" or (attacker != null and attacker.has_meta("is_casting_ultimate") and not is_non_ult_tag))
	
	if attacker and attacker.is_ally and (is_any_fua or is_ult):
		var js: CombatUnit = get_joan_spirit_unit()
		if js and js.is_alive():
			JoanSpiritAbilities.add_gold_remnants(js, self)


	# --- СЛЕД 2 ЖОАНА: Восстановление 1 «Последнего желания» за каждые 4 атаки по единственному врагу ---
	if attacker and attacker.is_ally and not target.is_ally and (dealt > 0.0 or original_amount > 0.0) and tag_override != "DoT" and tag_override != "True Damage":
		_check_joan_spirit_trace2_solo_hit(target, attacker, tag_override, was_alive)
			
	if dealt > 0.0:
		if attacker and attacker.is_ally:
			var lc_id: String = attacker.get_meta("light_cone_id", "")
			match lc_id:
				"warm_embraces":
					if is_ult:
						var enemy_count: int = get_living_enemies().size()
						if enemy_count <= 3:
							apply_def_reduction(target, "В тёплых объятиях", 0.15, 1)
				"echoes_of_the_past":
					if is_ult:
						if not has_meta("echoes_ult_triggered_this_action"):
							set_meta("echoes_ult_triggered_this_action", true)
							var heal_amt: float = attacker.stats.max_hp * 0.15
							heal_unit(attacker, heal_amt)
							attacker.add_speed_modifier(0.40, 0.0)
							attacker.set_meta("echoes_spd_buff_turns", 2)
							attacker.set_meta("echoes_spd_buff_skip_tick", true)
				"save_the_world_plan":
					if is_any_fua:
						var last_seq: int = int(attacker.get_meta("save_world_plan_last_fua_seq", -1))
						if last_seq != current_fua_sequence_id:
							attacker.set_meta("save_world_plan_last_fua_seq", current_fua_sequence_id)
							var cur_stacks: int = int(attacker.get_meta("save_world_plan_stacks", 0))
							var new_stacks: int = int(mini(cur_stacks + 1, 10))
							attacker.set_meta("save_world_plan_stacks", new_stacks)
							attacker.set_meta("save_world_plan_turns", 2)
							attacker.set_meta("save_world_plan_skip_tick", true)
							log_message("Конус спасения: %s получил стак Проработки плана (%d/10)." % [attacker.display_name, new_stacks])
				"edge_of_existence":
					if not has_meta("edge_existence_stack_credited"):
						set_meta("edge_existence_stack_credited", true)
						var cur_stacks: int = int(attacker.get_meta("edge_existence_stacks", 0))
						var new_stacks: int = int(mini(cur_stacks + 1, 6))
						attacker.set_meta("edge_existence_stacks", new_stacks)
						var diff: int = new_stacks - cur_stacks
						if diff > 0:
							attacker.stats.crit_rate += 0.03 * float(diff)
				"history_soaked_in_blood":
					if is_ult and tag_override != "blood_soaked_ult_bonus":
						var rec_dmg: float = float(attacker.get_meta("blood_soaked_recorded_dmg", 0.0))
						if rec_dmg > 0.0:
							var hit_targets: Array = attacker.get_meta("blood_soaked_hit_targets", [])
							if not hit_targets.has(target):
								hit_targets.append(target)
								attacker.set_meta("blood_soaked_hit_targets", hit_targets)
								attacker.set_meta("blood_soaked_ult_triggered", true)
								var living_enemies := get_living_enemies()
								var enemy_count: int = living_enemies.size()
								if not target in living_enemies and was_alive:
									enemy_count += 1
								var mult: float = 2.0 if enemy_count <= 1 else 1.3
								var extra_dmg: float = rec_dmg * mult
								log_message("🩸 Конус «История, вымоченная в крови»: Сверхспособность дополнительно наносит %d%% от накопленного урона (%d) по %s!" % [int(mult * 100.0), int(extra_dmg), target.display_name])
								var dmg_info := calc_dmg(attacker, target, 0.0, 0.0, false, 0.0, 0.0, true, false, "blood_soaked_ult_bonus", extra_dmg)
								deal_damage(target, dmg_info.damage, attacker, CombatConstants.Element.WIND, false, "blood_soaked_ult_bonus")
	
	if target.is_alive() and target.has_meta("rimes_isolation_source"):
		var rimes_ref: CombatUnit = target.get_meta("rimes_isolation_source")
		if rimes_ref.is_alive() and target.stats.hp / target.stats.max_hp < 0.15:
			RimesAbilities.execute_target(target, rimes_ref, self)
	
	if was_alive and not target.is_alive() and not target.is_ally:
		if attacker and attacker.has_meta("set_silhouette_4") and tag_override == "rimes_execution":
			if attacker.has_meta("relic_silhouette_spd_turns") and int(attacker.get_meta("relic_silhouette_spd_turns", 0)) > 0:
				attacker.remove_speed_modifier(0.0, 20.0)
			attacker.add_speed_modifier(0.0, 20.0)
			attacker.set_meta("relic_silhouette_spd_turns", 2)
			attacker.set_meta("relic_silhouette_spd_skip_tick", true)
			
	if dealt > 0.0:
		if attacker and attacker.is_ally and is_any_fua:
			var last_credited: String = String(get_meta("lenskaya_fua_attacker_credited", ""))
			if last_credited != attacker.id:
				set_meta("lenskaya_fua_attacker_credited", attacker.id)
				if has_meta("lenskaya_fua_triggered_this_action"):
					remove_meta("lenskaya_fua_triggered_this_action")
				LenskayaAbilities.on_ally_fua(attacker, target, self)
			
		if attacker and attacker.is_ally and attacker.id != "lenskaya" and target.is_alive() and target.has_meta("lenskaya_bounty_turns") and int(target.get_meta("lenskaya_bounty_turns", 0)) > 0:
			if not has_meta("lenskaya_fua_triggered_this_action"):
				set_meta("lenskaya_fua_triggered_this_action", true)
				LenskayaAbilities.trigger_bounty_fua(target, is_any_fua, self)
	
	if attacker and attacker.has_meta("hope_beam_ult_buff"):
		attacker.remove_meta("hope_beam_ult_buff")
	
	if was_alive and not target.is_alive() and not target.is_ally:
		_handle_enemy_death_reinforcement(target)
		if battle_mode == "planar_detroit":
			for ally in allies:
				if ally.is_alive():
					ally.advance_action(25.0)
					ally.gain_energy(20.0)
			action_order_changed.emit()
			log_message("🏙 Аномалия «Другая сторона»: Враг повержен! Действие отряда продвинуто на 25%% и получено 20 ед. энергии.")
		
	if was_alive and not target.is_alive() and not target.is_ally:
		if target.has_meta("rimes_isolation_source"):
			var rimes_ref: CombatUnit = target.get_meta("rimes_isolation_source")
			RimesAbilities.remove_eternal_isolation(rimes_ref, target, self, true)
		
	# === НАЙДИТЕ СЕКЦИЮ СМЕРТИ В deal_damage() И ВСТАВЬТЕ ЭТО ===
	if was_alive and not target.is_alive() and not target.is_ally:
		# Воскрешение Силуэта в маске и переход во вторую фазу
		if target.id == "masked_silhouette" and int(target.get_meta("phase", 1)) == 1:
			target.set_meta("phase", 2)
			if target.has_meta("katarina_broken_spirit"):
				target.remove_meta("katarina_broken_spirit")
				if target.has_meta("katarina_recorded_broken_spirit_dmg"):
					target.remove_meta("katarina_recorded_broken_spirit_dmg")
				log_message("⛓ Смена фазы: Статус «Сломленный дух» Катарины сброшен с %s!" % target.display_name)
			target.stats.max_hp = 180000.0
			target.stats.hp = 180000.0
			target.set_meta("base_hp_original", 180000.0)
			target.set_meta("first_action_p2", true)
			target.statuses.toughness_broken = false
			target.toughness = target.max_toughness
			
			# ИСПРАВЛЕНО: Безусловный моментальный каст Маски и задержка на 150%
			MaskedSilhouette.execute_turn(target, allies, self)
			
			log_message("🎭 Поражение первой маски! Силуэт восстанавливает силы, мгновенно накладывает «Тайну сияющей маски» и откладывает свой ход на 150%!")
			unit_updated.emit(target)
			_check_battle_end()
			return 0.0
			
	if was_alive and not target.is_alive() and not target.is_ally:
		ArseniyAbilities.on_enemy_killed(attacker, target, self)

		if battle_mode == "level_14":
			for ally in allies:
				if ally.is_alive():
					gain_energy_with_err(ally, 10.0)
					heal_unit(ally, ally.stats.max_hp * 0.05)
			log_message("⚡ Аномалия уровня 14: Гибель врага восстановила отряду +10 энергии и 5% ХП!")

		if battle_mode == "level_20" and target.id == "void_soldier" and attacker != null and attacker.is_ally:
			gain_energy_with_err(attacker, 30.0)
			log_message("⚡ Аномалия уровня 20: Добивание Солдата Бездны восстановило +30 энергии %s!" % attacker.display_name)

		if target.id == "infected":
			add_console_vectors(4)
			log_message("⚡ Победа над %s: получено +4 Вектора Консоли!" % target.display_name)
			if was_hp_ratio < 0.30:
				log_message("💥 %s взрывается при гибели!" % target.display_name)
				var explode_dmg: float = target.stats.max_hp * 0.15
				var adjacents := get_adjacent_enemies(target)
				for adj in adjacents:
					if adj.is_alive():
						deal_damage(adj, explode_dmg, null, CombatConstants.Element.PHYSICAL, false, "Взрыв заразы")
		
		if target.id == "ortho_spore":
			var spore_toughness: float = 40.0 if battle_mode == "level_17" else 30.0
			for e in enemies:
				if e.is_alive() and e.id == "ortho_mutant":
					e.toughness = maxf(e.toughness - spore_toughness, 0.0)
					log_message("💥 Уничтожение Орто-споры травмирует Орто Мутанта (-%d стойкости)!" % int(spore_toughness))
					if e.toughness <= 0.0 and not e.statuses.toughness_broken:
						var break_attacker: CombatUnit = attacker if attacker != null else (allies[0] if not allies.is_empty() else null)
						if break_attacker:
							ToughnessSystem._trigger_break(break_attacker, e, self)
					unit_updated.emit(e)
			if battle_mode == "level_17":
				var sp_grants: int = int(get_meta("level17_sp_grants_cycle", 0))
				if sp_grants < 2:
					set_meta("level17_sp_grants_cycle", sp_grants + 1)
					gain_skill_point()
					log_message("⚡ Аномалия уровня 17: Уничтожение споры восстановило 1 ОН (%d/2 за цикл)!" % (sp_grants + 1))

		if attacker and attacker.get_meta("light_cone_id", "") == "forget_past_self" and not target.has_meta("forget_past_self_energy_credited"):
			target.set_meta("forget_past_self_energy_credited", true)
			gain_energy_with_err(attacker, 3.0)
		
		if attacker and attacker.id == "rimes" and not target.has_meta("rimes_stacks_credited"):
			target.set_meta("rimes_stacks_credited", true)
			RimesAbilities.increment_talent_stacks(attacker, self)
			if attacker.eidolon >= 2 and not attacker.has_meta("rimes_e2_triggered_this_action"):
				attacker.set_meta("rimes_e2_triggered_this_action", true)
				attacker.advance_action(100.0)
				action_order_changed.emit()
			
		_handle_enemy_death_reinforcement(target)
	
	if was_alive and not target.is_alive() and target.id == "milena":
		for ally in allies:
			if ally.has_meta("milena_be_buff"):
				ally.remove_meta("milena_be_buff")
		
	if dealt > 0.0:
		var final_element = element_override
		if final_element == -1 and attacker != null:
			final_element = attacker.element
		elif final_element == -1:
			final_element = CombatConstants.Element.PHYSICAL
			
		if final_element == CombatConstants.Element.PHYSICAL and tag_override == "DoT":
			var break_name: String = target.statuses.break_status
			if break_name != "":
				if "Горение" in break_name:
					final_element = CombatConstants.Element.FIRE
				elif "Выветривание" in break_name:
					final_element = CombatConstants.Element.WIND
				elif "Шок" in break_name:
					final_element = CombatConstants.Element.LIGHTNING
				elif "Связывание" in break_name:
					final_element = CombatConstants.Element.QUANTUM
			if target.statuses.suppression_stacks > 0:
				final_element = CombatConstants.Element.ICE

		var color := _get_element_color(final_element)
		var final_tag := tag_override
		
		if final_tag == "Skill" or final_tag == "Basic" or final_tag == "Ultimate" or final_tag == "skill" or final_tag == "basic" or final_tag == "ultimate":
			final_tag = ""
		elif final_tag == "lenskaya_true_fua" or final_tag == "musienko_true_damage" or final_tag == "True Damage":
			final_tag = "True Damage"
			color = Color(0.8, 0.95, 1.0) # Неоново-бело-голубой цвет Чистого урона!
		elif final_tag == "rimes_execution":
			final_tag = "Казнь"
			color = Color(0.8, 0.95, 1.0)
		elif final_tag == "Binary" or final_tag == "binary":
			final_tag = "Бинарный"
			
		if final_tag == "" and has_meta("current_damage_tag"):
			final_tag = get_meta("current_damage_tag", "")
		if final_tag == "" and is_crit:
			final_tag = "Крит. удар"
			

		check_arseniy_talent(target, attacker)

		combat_text_spawned.emit(target, str(int(dealt)), color, final_tag, is_crit)

	if attacker and attacker.is_ally and amount > 0.0:
		record_damage(attacker, amount)

	if target.id == "dasha" and target.get_meta("circle_dance", false):
		if target.stats.hp < target.stats.max_hp * 0.20:
			target.set_meta("circle_dance", false)

	if target.is_ally and target.stats.hp / target.stats.max_hp <= 0.30:
		var danill := get_danila_unit()
		if danill and danill.is_alive() and danill.eidolon >= 6:
			if int(danill.get_meta("e6_cooldown", 0)) == 0:
				var e6_val: float = danill.stats.def * 0.20 + 100.0
				apply_shield(target, e6_val, 1, "Е6 Данилла")
				danill.set_meta("e6_cooldown", 3)
				
	# Э4 Даши: Если ХП союзника упало ниже 20% — бесплатный Навык E (1 раз за бой)
	if dealt > 0.0 and target.is_ally and target.get_hp_ratio() < 0.20:
		var dasha_u := get_dasha_admin_unit()
		if dasha_u and dasha_u.is_alive() and dasha_u.eidolon >= 4 and not dasha_u.has_meta("dasha_e4_used"):
			dasha_u.set_meta("dasha_e4_used", true)
			log_message("🛡 Э4 Даши: Здоровье союзника упало ниже 20%! Экстренная активация Навыка E!")
			DashaAdminAbilities.execute_skill_e(dasha_u, self)

	if target.id == "danill" and dealt > 0.0:
		var stacks: int = int(target.get_meta("danill_talent_stacks", 0))
		if stacks < 3:
			target.set_meta("danill_talent_stacks", stacks + 1)

	if target.is_ally and dealt > 0.0:
		SaraAbilities.on_ally_damaged(target, dealt, self)

	if was_alive and not target.is_alive() and not target.is_ally:
		ArseniyAbilities.on_enemy_killed(attacker, target, self)
		var dotseva := get_dotseva_unit()
		if dotseva and dotseva.is_alive():
			add_calibration_stacks(dotseva, 3)
		
		var has_any_burn: bool = (target.statuses.break_status == "Горение" or (target.has_meta("shoji_burn_turns") and int(target.get_meta("shoji_burn_turns", 0)) > 0))
		if has_any_burn:
			var shoji := get_shoji_unit()
			if shoji and shoji.is_alive():
				gain_energy_with_err(shoji, 5.0)
		
		if attacker and attacker.is_ally and attacker.get_meta("light_cone_id", "") == "arrows":
			var spd_bonus: float = attacker.stats.spd * 0.18
			attacker.stats.spd += spd_bonus
			attacker.set_meta("arrows_spd_bonus", spd_bonus)
			attacker.set_meta("arrows_buff_turns", 2)
			
		if attacker and attacker.get_meta("light_cone_id", "") == "crimson_tears":
			if attacker.has_meta("crimson_tears_spd_turns") and int(attacker.get_meta("crimson_tears_spd_turns", 0)) > 0:
				var current_crimson_atk_boost: float = float(attacker.get_meta("crimson_tears_atk_pct", 0.0))
				if current_crimson_atk_boost < 0.40:
					var new_boost: float = current_crimson_atk_boost + 0.05
					attacker.set_meta("crimson_tears_atk_pct", new_boost)
					attacker.set_meta("lc_atk_pct_bonus", 0.45 + new_boost)
					unit_updated.emit(attacker)

	if was_alive and not target.is_alive() and target.is_ally:
		var danill := get_danila_unit()
		if danill and danill.is_alive():
			for ally in allies:
				if ally.is_alive():
					ally.set_meta("danill_trace3_def_buff", true)
			
	if was_alive and not target.is_alive() and target.is_ally:
		if target.id == "joan":
			JoanAbilities.trigger_death_trace(target, self)
		var rimes_ref := get_rimes_unit()
		if rimes_ref and rimes_ref.is_alive():
			var other_allies_alive := false
			for ally in allies:
				if ally.is_alive() and ally != rimes_ref:
					other_allies_alive = true
					break
			if not other_allies_alive and rimes_ref.has_meta("rimes_isolation_target"):
				var isolated_enemy: CombatUnit = rimes_ref.get_meta("rimes_isolation_target")
				RimesAbilities.remove_eternal_isolation(rimes_ref, isolated_enemy, self, false)

	if attacker and attacker.id == KaoriAbilities.ID and dealt > 0.0:
		if not attacker.get_meta("weakness_concentration", false):
			attacker.set_meta("weakness_concentration", true)
	
	if dealt > 0.0 and attacker and attacker.id == "musienko" and attacker.has_meta("musienko_annihilation_active") and not target.is_ally:
		var current_rec: float = float(target.get_meta("musienko_recorded_damage", 0.0))
		target.set_meta("musienko_recorded_damage", current_rec + dealt)
	
	if was_alive and not target.is_alive() and not target.is_ally:
		var musienko := get_musienko_unit()
		if musienko and musienko.is_alive():
			var heal_val := musienko.stats.max_hp * 0.20
			heal_unit(musienko, heal_val)
	
	# Проверка урона по Катарине (След 3)
	if target and target.id == "katarina" and dealt > 0.0:
		KatarinaAbilities.on_katarina_took_damage(target, self)

	# Срабатывание метки Навыка Q Катарины при атаках союзников
	if target and target.has_meta("katarina_q_ally_mark_turns") and int(target.get_meta("katarina_q_ally_mark_turns", 0)) > 0:
		if attacker != null and attacker.is_ally:
			attacker.set_meta("katarina_q_ally_atk_buff_turns", 2)
			attacker.set_meta("katarina_q_ally_atk_buff_skip_tick", true)
			log_message("⚔ Метка Навыка Q Катарины: %s получает +15%% СА на 2 хода!" % attacker.display_name)

	# Экстренное лечение Доцевой • Багровые слёзы (E1)
	var doceva_tears_u := get_dotseva_crimson_tears_unit()
	if doceva_tears_u:
		DotsevaCrimsonTearsAbilities.check_e1_emergency_heal(doceva_tears_u, self)

	# Проверка порогов ХП противника для Таланта Катарины («Сломленный дух»)
	if target and not target.is_ally:
		var new_hp_ratio: float = (target.stats.hp / target.stats.max_hp) if target.stats.max_hp > 0.0 else 0.0
		KatarinaAbilities.check_talent_thresholds(target, was_hp_ratio, new_hp_ratio, self, attacker)

	# Конус «История, вымоченная в крови»: запись полученного урона и стаки снижения урона
	_handle_history_soaked_in_blood_receive(target, dealt)

	# Конус «Почему ты вспомнила меня?»: запись исходящего урона и статус «Занять позицию»
	_handle_why_did_you_remember_me(attacker, target, original_amount, dealt, tag_override)

	unit_updated.emit(target)
	_check_battle_end()
	return dealt

func _handle_history_soaked_in_blood_receive(target_unit: CombatUnit, dealt_amt: float) -> void:
	if target_unit == null or dealt_amt <= 0.0:
		return
	if target_unit.get_meta("light_cone_id", "") != "history_soaked_in_blood":
		return

	var cur_rec: float = float(target_unit.get_meta("blood_soaked_recorded_dmg", 0.0)) + dealt_amt
	target_unit.set_meta("blood_soaked_recorded_dmg", cur_rec)
	var cur_stk: int = int(target_unit.get_meta("blood_soaked_dmg_red_stacks", 0))
	if cur_stk < 10:
		var new_stk: int = cur_stk + 1
		target_unit.set_meta("blood_soaked_dmg_red_stacks", new_stk)
		log_message("🩸 Конус «История, вымоченная в крови»: %s получил урон (%d). Всего записано: %d. Стаки снижения урона: %d/10 (-%d%%)." % [target_unit.display_name, int(dealt_amt), int(cur_rec), new_stk, new_stk * 3])

func start_attack_recording(attacker: CombatUnit) -> void:
	if attacker == null or attacker.get_meta("light_cone_id", "") != "why_did_you_remember_me":
		return
	var depth: int = int(attacker.get_meta("attack_rec_depth", 0))
	attacker.set_meta("attack_rec_depth", depth + 1)
	if depth == 0:
		attacker.set_meta("attack_rec_outgoing", 0.0)
		attacker.set_meta("attack_rec_dealt", 0.0)
		attacker.set_meta("attack_rec_targets", [])

func finish_attack_recording(attacker: CombatUnit) -> void:
	if attacker == null or attacker.get_meta("light_cone_id", "") != "why_did_you_remember_me":
		return
	var depth: int = int(attacker.get_meta("attack_rec_depth", 0))
	if depth <= 0:
		return
	depth -= 1
	attacker.set_meta("attack_rec_depth", depth)
	if depth > 0:
		return
	attacker.remove_meta("attack_rec_depth")

	var out_amt: float = float(attacker.get_meta("attack_rec_outgoing", 0.0))
	var dealt_amt: float = float(attacker.get_meta("attack_rec_dealt", 0.0))
	var hit_targets: Array = attacker.get_meta("attack_rec_targets", [])
	attacker.remove_meta("attack_rec_outgoing")
	attacker.remove_meta("attack_rec_dealt")
	attacker.remove_meta("attack_rec_targets")

	var is_in_murmur: bool = bool(attacker.get_meta("katarina_blood_murmur", false))
	var released := false

	# 1. Если был активен статус «Занять позицию» и в этой атаке нанесён урон (> 0)
	# ВАЖНО: Во время Сверхспособности Катарины (Журчание крови) статус не высвобождается посередине ударов серии
	if not is_in_murmur and dealt_amt > 0.0 and bool(attacker.get_meta("remember_me_in_position", false)):
		var recorded: float = float(attacker.get_meta("remember_me_recorded_outgoing", 0.0))
		var bonus_total: float = recorded * 0.20
		attacker.set_meta("remember_me_in_position", false)
		attacker.set_meta("remember_me_recorded_outgoing", 0.0)
		released = true
		unit_updated.emit(attacker)

		if bonus_total > 0.0 and not hit_targets.is_empty():
			var living_targets: Array[CombatUnit] = []
			for t in hit_targets:
				if t is CombatUnit and t.is_alive():
					living_targets.append(t)

			if living_targets.is_empty():
				for e in get_living_enemies():
					if e.is_alive():
						living_targets.append(e)

			if not living_targets.is_empty():
				var dmg_per_target: float = bonus_total / float(living_targets.size())
				log_message("🗡 Конус «Почему ты вспомнила меня?»: Статус «Занять позицию» высвобождает +20%% накопленного урона (%d всего, по %d на цель)!" % [int(bonus_total), int(dmg_per_target)])
				for lt in living_targets:
					deal_damage(lt, dmg_per_target, attacker, attacker.element, false, "why_did_you_remember_me_proc")
			else:
				log_message("🗡 Конус «Почему ты вспомнила меня?»: Статус «Занять позицию» сброшен, но поражённые цели уже повержены.")

	# 2. Если в конце атаки исходящий урон > нанесённого урона, записывается разница между исходящим и фактическим уроном
	# ВАЖНО: Если статус был только что высвобожден (released == true), то на этой же атаке повторная запись НЕ производится!
	if not released and out_amt > dealt_amt:
		var diff: float = out_amt - dealt_amt
		var cur_rec: float = float(attacker.get_meta("remember_me_recorded_outgoing", 0.0)) + diff
		attacker.set_meta("remember_me_recorded_outgoing", cur_rec)
		attacker.set_meta("remember_me_in_position", true)
		unit_updated.emit(attacker)
		log_message("🗡 Конус «Почему ты вспомнила меня?»: Исходящий урон (%d) > нанесённого (%d)! В статус «Занять позицию» добавлена разница %d (Всего записано: %d)." % [int(out_amt), int(dealt_amt), int(diff), int(cur_rec)])

func _handle_why_did_you_remember_me(atk_unit: CombatUnit, tgt_unit: CombatUnit, orig_amt: float, dealt_amt: float, tag: String) -> void:
	if atk_unit == null or tgt_unit == null or tgt_unit.is_ally or tag == "why_did_you_remember_me_proc":
		return
	if atk_unit.get_meta("light_cone_id", "") != "why_did_you_remember_me":
		return

	var auto_single_hit: bool = (int(atk_unit.get_meta("attack_rec_depth", 0)) == 0)
	if auto_single_hit:
		start_attack_recording(atk_unit)

	# Если враг погиб от удара (не заблокирован Сломленным духом и не упёрся в порог ХП),
	# то фактический урон считается полным (оверкилл не является заблокированным уроном)
	var effective_dealt := dealt_amt
	if not tgt_unit.is_alive() and not bool(tgt_unit.get_meta("katarina_broken_spirit", false)):
		effective_dealt = maxf(dealt_amt, orig_amt)

	var cur_out: float = float(atk_unit.get_meta("attack_rec_outgoing", 0.0)) + orig_amt
	var cur_dealt: float = float(atk_unit.get_meta("attack_rec_dealt", 0.0)) + effective_dealt
	atk_unit.set_meta("attack_rec_outgoing", cur_out)
	atk_unit.set_meta("attack_rec_dealt", cur_dealt)

	if dealt_amt > 0.0:
		var tgts: Array = atk_unit.get_meta("attack_rec_targets", [])
		if not tgts.has(tgt_unit):
			tgts.append(tgt_unit)
			atk_unit.set_meta("attack_rec_targets", tgts)

	if auto_single_hit:
		finish_attack_recording(atk_unit)
				
func heal_unit(target: CombatUnit, amount: float) -> float:
	# Партнёр по сцене: получаемое исцеление +15%
	if target.has_meta("stage_partner_turns") and int(target.get_meta("stage_partner_turns", 0)) > 0:
		amount *= 1.15
		
	if current_unit and current_unit.is_ally:
		if current_unit.get_meta("light_cone_id", "") == "multiplication":
			amount *= 1.25
			
		if current_unit.has_meta("medical_smell_healing_turns"):
			var smell_turns: int = int(current_unit.get_meta("medical_smell_healing_turns", 0))
			if smell_turns > 0:
				amount *= 1.24
		
		if current_unit.has_meta("relic_heal_bonus"):
			amount *= (1.0 + float(current_unit.get_meta("relic_heal_bonus", 0.0)))
			
		# След 3 Джеффа: +20% исходящего лечения на 1 ход за FUA
		if current_unit.has_meta("jeff_trace3_heal_buff") and int(current_unit.get_meta("jeff_trace3_heal_turns", 0)) > 0:
			amount *= (1.0 + float(current_unit.get_meta("jeff_trace3_heal_buff", 0.0)))
			
		# Е2 Джеффа: +30% исходящего исцеления при 2 напарниках Небытия в пати
		if current_unit.id == "jeff" and current_unit.eidolon >= 2 and check_nihility_allies_e2():
			amount *= 1.30
	
	if target.id == "musienko" and target.has_meta("musienko_annihilation_active") and target.eidolon >= 2:
		var max_allowed: float = target.stats.max_hp * 0.60
		if target.stats.hp >= max_allowed:
			return 0.0
		amount = minf(amount, max_allowed - target.stats.hp)
		
	if target.id == "vika":
		var missing_hp_ratio := 1.0 - target.get_hp_ratio()
		var missing_10pct_blocks := floorf(missing_hp_ratio * 10.0)
		var heal_multiplier := 1.0 + (missing_10pct_blocks * 0.05)
		amount *= heal_multiplier
		
	var healed: float = target.heal(amount)
	
	if healed > 0.0:
		combat_text_spawned.emit(target, "+%d" % int(healed), Color(0.2, 0.85, 0.3), "", false)
		if battle_mode == "dungeon_slums_apt" and target.is_ally:
			trigger_dungeon_slums_hp_change(target)
		if battle_mode == "dungeon_dam" and target.is_ally:
			target.set_meta("dungeon_dam_heal_buff_turns", 2)
			target.set_meta("dungeon_dam_heal_skip_tick", true)
			log_message("🌊 Аномалия «Стремительный поток»: Исцеление увеличило урон %s на +20%% на 2 хода!" % target.display_name)
		
	unit_updated.emit(target)
	return healed
	
func gain_skill_point() -> void:
	if skill_points < CombatConstants.MAX_SKILL_POINTS:
		skill_points += 1
		skill_points_changed.emit(skill_points)

func start_arya(duration: float) -> void:
	arya_active = true
	arya_remaining = duration
	arya_changed.emit(true, arya_remaining)

func _end_arya() -> void:
	arya_active = false
	arya_remaining = 0.0
	arya_changed.emit(false, 0.0)
	var sara := get_sara_unit()
	if sara:
		SaraAbilities.end_arya(sara, self)

func gain_energy_with_err(unit: CombatUnit, amount: float) -> void:
	if unit.id == "joan_spirit":
		return
	var err := 1.0
	if unit.get_meta("light_cone_id", "") == "medical_smell":
		err += 0.16
		
	if unit.get_meta("light_cone_id", "") == "corrupted_save" and int(unit.get_meta("immersion_turns", 0)) > 0:
		err += 0.12

	if unit.get_meta("light_cone_id", "") == "server_crash_moment" and int(unit.get_meta("refactoring_turns", 0)) > 0:
		err += 0.15

	if unit.has_meta("relic_err_bonus"):
		err += float(unit.get_meta("relic_err_bonus", 0.0))
		
	# ИСПРАВЛЕНО: Конус «Коснись...» дает пати +2% ВЭ за каждый стак «Общего долга» владельца на поле
	var total_debt_err_bonus := 0.0
	for ally in allies:
		if ally.is_alive() and ally.get_meta("light_cone_id", "") == "touch_waking_world":
			var stacks := int(ally.get_meta("mutual_debt_stacks", 0))
			total_debt_err_bonus += float(stacks) * 0.02
			
	unit.gain_energy(amount * (err + total_debt_err_bonus))
	
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ МЕТОД _end_turn() В BATTLE_MANAGER.GD ===
func _end_turn(unit: CombatUnit) -> void:
	set_meta("joan_wish_granted_this_turn", false)
	if has_meta("arseniy_talent_credited_this_action"):
		remove_meta("arseniy_talent_credited_this_action")
	ArseniyAbilities.tick_turn_end(unit, self)
	unit.reset_action_value() 
	
	# Проверяем, ходит ли Раймс в активной Дуэли 1 на 1
	var is_rimes_duel: bool = (unit.id == "rimes" and has_meta("rimes_duel_active") and bool(get_meta("rimes_duel_active")))
	
	# Если Раймс в Дуэли — мы пропускаем только списание длительности его баффов, щитов и меток
	if is_rimes_duel:
		log_message("🛡 Вечная Изоляция (Дуэль): Длительность баффов %s заморожена!" % unit.display_name)
		# Очищаем временные транзакции Ленской
		if has_meta("lenskaya_fua_triggered_this_action"):
			remove_meta("lenskaya_fua_triggered_this_action")
		if has_meta("lenskaya_fua_attacker_credited"):
			remove_meta("lenskaya_fua_attacker_credited")
	else:
		# Очистка разового флага FUA Зеркальной иллюзии
		if has_meta("mirror_illusion_credited_this_fua"):
			remove_meta("mirror_illusion_credited_this_fua")
			
		# Списание бонуса Палящего взора после использования Навыка Е
		if String(get_meta("current_attack_type", "")) == "skill_e" and unit.has_meta("scorching_gaze_next_e_buff"):
			unit.remove_meta("scorching_gaze_next_e_buff")

		# Списание аномалий подземелий
		if unit.has_meta("dungeon_slums_turns") and int(unit.get_meta("dungeon_slums_turns", 0)) > 0:
			if unit.get_meta("dungeon_slums_skip_tick", false):
				unit.set_meta("dungeon_slums_skip_tick", false)
			else:
				var ds_t := int(unit.get_meta("dungeon_slums_turns", 0)) - 1
				unit.set_meta("dungeon_slums_turns", ds_t)
				if ds_t == 0:
					var stks := int(unit.get_meta("dungeon_slums_stacks", 0))
					unit.stats.crit_rate -= float(stks) * 0.15
					unit.remove_meta("dungeon_slums_stacks")
					unit.remove_meta("dungeon_slums_turns")
					log_message("🏚 Аномалия «Принятие Греха» на %s завершилась." % unit.display_name)

		if unit.has_meta("dungeon_kitchens_atk_turns") and int(unit.get_meta("dungeon_kitchens_atk_turns", 0)) > 0:
			if unit.get_meta("dungeon_kitchens_atk_skip_tick", false):
				unit.set_meta("dungeon_kitchens_atk_skip_tick", false)
			else:
				var dk_t := int(unit.get_meta("dungeon_kitchens_atk_turns", 0)) - 1
				unit.set_meta("dungeon_kitchens_atk_turns", dk_t)
				if dk_t == 0:
					unit.remove_meta("dungeon_kitchens_atk_turns")

		if unit.has_meta("dungeon_dam_heal_buff_turns") and int(unit.get_meta("dungeon_dam_heal_buff_turns", 0)) > 0:
			if unit.get_meta("dungeon_dam_heal_skip_tick", false):
				unit.set_meta("dungeon_dam_heal_skip_tick", false)
			else:
				var dd_t := int(unit.get_meta("dungeon_dam_heal_buff_turns", 0)) - 1
				unit.set_meta("dungeon_dam_heal_buff_turns", dd_t)
				if dd_t == 0:
					unit.remove_meta("dungeon_dam_heal_buff_turns")

		# Списание «Партнёра по сцене»
		if unit.has_meta("stage_partner_turns") and int(unit.get_meta("stage_partner_turns", 0)) > 0:
			if unit.get_meta("stage_partner_skip_tick", false):
				unit.set_meta("stage_partner_skip_tick", false)
			else:
				var sp_turns := int(unit.get_meta("stage_partner_turns", 0)) - 1
				unit.set_meta("stage_partner_turns", sp_turns)
				if sp_turns == 0:
					log_message("Статус «Партнёр по сцене» на %s завершился." % unit.display_name)
					
		# Списание «Пылающего солнца»
		if unit.has_meta("blazing_sun_turns") and int(unit.get_meta("blazing_sun_turns", 0)) > 0:
			if unit.get_meta("blazing_sun_skip_tick", false):
				unit.set_meta("blazing_sun_skip_tick", false)
			else:
				var bs_turns := int(unit.get_meta("blazing_sun_turns", 0)) - 1
				unit.set_meta("blazing_sun_turns", bs_turns)
				if bs_turns == 0:
					log_message("Статус «Пылающее солнце» на %s угас." % unit.display_name)

		# Списание «Погружения» (Конус «Повреждённое сохранение»)
		if unit.has_meta("immersion_turns") and int(unit.get_meta("immersion_turns", 0)) > 0:
			if unit.get_meta("immersion_skip_tick", false):
				unit.set_meta("immersion_skip_tick", false)
			else:
				var im_turns := int(unit.get_meta("immersion_turns", 0)) - 1
				unit.set_meta("immersion_turns", im_turns)
				if im_turns == 0:
					log_message("Статус «Погружение» на %s завершился." % unit.display_name)

		# Списание «Рефакторинга» (Конус «Момент, когда падают сервера»)
		if unit.has_meta("refactoring_turns") and int(unit.get_meta("refactoring_turns", 0)) > 0:
			if unit.get_meta("refactoring_skip_tick", false):
				unit.set_meta("refactoring_skip_tick", false)
			else:
				var rf_turns := int(unit.get_meta("refactoring_turns", 0)) - 1
				unit.set_meta("refactoring_turns", rf_turns)
				if rf_turns == 0:
					log_message("Статус «Рефакторинг» на %s завершился." % unit.display_name)
					
		# Обычное уменьшение длительности дебаффов и баффов для всех остальных случаев
		if unit.has_meta("def_reductions"):
			var reductions: Dictionary = unit.get_meta("def_reductions")
			var to_remove := []
			for src in reductions:
				# ИСПРАВЛЕНО: Срез защиты от сета Симбиоза (4 части) НЕ сгорает на концах ходов!
				# Он висит вечно и сбрасывается только в момент физического восстановления уязвимости (toughness restored)
				if src == "Жертва долгого симбиоза (4ч)":
					continue
					
				var data: Dictionary = reductions[src]
				var turns: int = int(data.get("turns", 0)) - 1
				data["turns"] = turns
				if turns <= 0:
					to_remove.append(src)
					log_message("Срез защиты от %s на %s завершился." % [src, unit.display_name])
			for src in to_remove:
				reductions.erase(src)
			recalculate_target_def(unit)
		
		# Списание статуса «Троян»
		if unit.has_meta("trojan_turns") and int(unit.get_meta("trojan_turns", 0)) > 0:
			var tr_turns := int(unit.get_meta("trojan_turns", 0)) - 1
			unit.set_meta("trojan_turns", tr_turns)
			if tr_turns == 0:
				log_message("Статус «Троян» на %s завершился." % unit.display_name)

		# Списание «Задержки пакетов»
		if unit.has_meta("packet_delay_turns") and int(unit.get_meta("packet_delay_turns", 0)) > 0:
			var pd_turns := int(unit.get_meta("packet_delay_turns", 0)) - 1
			unit.set_meta("packet_delay_turns", pd_turns)
			if pd_turns == 0:
				unit.remove_speed_modifier(-0.15, 0.0)
				unit.recalculate_action_value()
				action_order_changed.emit()
				log_message("Статус «Задержка пакетов» на %s завершился." % unit.display_name)

		# Списание «Взлома файрвола»
		if unit.has_meta("server_virus_breached_turns") and int(unit.get_meta("server_virus_breached_turns", 0)) > 0:
			var sv_turns := int(unit.get_meta("server_virus_breached_turns", 0)) - 1
			unit.set_meta("server_virus_breached_turns", sv_turns)
			if sv_turns == 0:
				log_message("Статус «Взлом файрвола» на %s завершился." % unit.display_name)
		
		if unit.id == "dasha_admin":
			if unit.has_meta("dasha_tech_reduce_turns") and int(unit.get_meta("dasha_tech_reduce_turns", 0)) > 0:
				if unit.get_meta("dasha_tech_reduce_skip_tick", false):
					unit.set_meta("dasha_tech_reduce_skip_tick", false)
				else:
					var t := int(unit.get_meta("dasha_tech_reduce_turns", 0)) - 1
					unit.set_meta("dasha_tech_reduce_turns", t)
					
		if unit.has_meta("dasha_ult_binary_turns") and int(unit.get_meta("dasha_ult_binary_turns", 0)) > 0:
			if unit.get_meta("dasha_ult_binary_skip_tick", false):
				unit.set_meta("dasha_ult_binary_skip_tick", false)
			else:
				var t := int(unit.get_meta("dasha_ult_binary_turns", 0)) - 1
				unit.set_meta("dasha_ult_binary_turns", t)
				
		if unit.has_meta("dasha_e6_binary_turns") and int(unit.get_meta("dasha_e6_binary_turns", 0)) > 0:
			if unit.get_meta("dasha_e6_binary_skip_tick", false):
				unit.set_meta("dasha_e6_binary_skip_tick", false)
			else:
				var t := int(unit.get_meta("dasha_e6_binary_turns", 0)) - 1
				unit.set_meta("dasha_e6_binary_turns", t)
				
		if has_meta("arseniy_e4_processing"):
			remove_meta("arseniy_e4_processing")
			
		# Зона Сары «Среда разработки» уменьшает длительность В НАЧАЛЕ своего хода
		if unit.id == "sara_admin":
			if unit.has_meta("sara_dev_env_turns") and int(unit.get_meta("sara_dev_env_turns", 0)) > 0:
				if unit.get_meta("sara_dev_env_skip_tick", false):
					unit.set_meta("sara_dev_env_skip_tick", false)
				else:
					var env_t := int(unit.get_meta("sara_dev_env_turns", 0)) - 1
					unit.set_meta("sara_dev_env_turns", env_t)
					if env_t == 0:
						log_message("Зона «Среда разработки» Сары завершилась.")
						
			# Кулдаун таланта
			var cd := int(unit.get_meta("sara_talent_cooldown", 0))
			if cd > 0:
				unit.set_meta("sara_talent_cooldown", cd - 1)
				
		# Списание RES PEN
		if unit.has_meta("sara_ult_res_pen_turns") and int(unit.get_meta("sara_ult_res_pen_turns", 0)) > 0:
			if unit.get_meta("sara_ult_res_pen_skip_tick", false):
				unit.set_meta("sara_ult_res_pen_skip_tick", false)
			else:
				var pen_t := int(unit.get_meta("sara_ult_res_pen_turns", 0)) - 1
				unit.set_meta("sara_ult_res_pen_turns", pen_t)
				
		# Списание скорости Е1
		if unit.has_meta("sara_e1_spd_turns") and int(unit.get_meta("sara_e1_spd_turns", 0)) > 0:
			if unit.get_meta("sara_e1_spd_skip_tick", false):
				unit.set_meta("sara_e1_spd_skip_tick", false)
			else:
				var spd_t := int(unit.get_meta("sara_e1_spd_turns", 0)) - 1
				unit.set_meta("sara_e1_spd_turns", spd_t)
				if spd_t == 0 and unit.has_meta("sara_e1_spd_active"):
					unit.remove_meta("sara_e1_spd_active")
					unit.remove_speed_modifier(0.30, 0.0)
					unit.recalculate_action_value()
					action_order_changed.emit()
					
		# Списание техники
		if unit.has_meta("sara_tech_binary_turns") and int(unit.get_meta("sara_tech_binary_turns", 0)) > 0:
			if unit.get_meta("sara_tech_binary_skip_tick", false):
				unit.set_meta("sara_tech_binary_skip_tick", false)
			else:
				var tech_t := int(unit.get_meta("sara_tech_binary_turns", 0)) - 1
				unit.set_meta("sara_tech_binary_turns", tech_t)
				
		if unit.has_meta("lenskaya_trace3_turns") and int(unit.get_meta("lenskaya_trace3_turns", 0)) > 0:
			var t3_turns: int = int(unit.get_meta("lenskaya_trace3_turns", 0)) - 1
			unit.set_meta("lenskaya_trace3_turns", t3_turns)
			if t3_turns == 0:
				unit.remove_meta("lenskaya_trace3_stacks")
				unit.remove_meta("lenskaya_trace3_atk_percent")
				log_message("Усиление атаки от Следа 3 Ленской на %s испарилось." % unit.display_name)
		
		if unit.id == "isaac_admin":
			if unit.has_meta("isaac_hacked_turns") and int(unit.get_meta("isaac_hacked_turns", 0)) > 0:
				if unit.get_meta("isaac_hacked_skip_tick", false):
					unit.set_meta("isaac_hacked_skip_tick", false)
				else:
					var h_t := int(unit.get_meta("isaac_hacked_turns", 0)) - 1
					unit.set_meta("isaac_hacked_turns", h_t)
					if h_t == 0:
						log_message("Состояние «Взлом» Айзека завершилось.")
						
			if unit.has_meta("isaac_admin_trace2_atk_turns") and int(unit.get_meta("isaac_admin_trace2_atk_turns", 0)) > 0:
				if unit.get_meta("isaac_admin_trace2_skip_tick", false):
					unit.set_meta("isaac_admin_trace2_skip_tick", false)
				else:
					var a_t := int(unit.get_meta("isaac_admin_trace2_atk_turns", 0)) - 1
					unit.set_meta("isaac_admin_trace2_atk_turns", a_t)

		if unit.id == "shoji_swan":
			var q_cd: int = int(unit.get_meta("shoji_swan_q_cooldown_turns", 0))
			if q_cd > 0:
				unit.set_meta("shoji_swan_q_cooldown_turns", q_cd - 1)
				if q_cd - 1 == 0:
					log_message("🦢 Навык Q Сёдзи перезаряжен и готов к использованию!")

			if unit.has_meta("shoji_swan_trace2_spd_turns") and int(unit.get_meta("shoji_swan_trace2_spd_turns", 0)) > 0:
				if unit.get_meta("shoji_swan_trace2_spd_skip_tick", false):
					unit.set_meta("shoji_swan_trace2_spd_skip_tick", false)
				else:
					var spd_t := int(unit.get_meta("shoji_swan_trace2_spd_turns", 0)) - 1
					unit.set_meta("shoji_swan_trace2_spd_turns", spd_t)
					if spd_t == 0 and unit.has_meta("shoji_swan_trace2_spd_active"):
						unit.remove_meta("shoji_swan_trace2_spd_active")
						unit.remove_speed_modifier(0.20, 0.0)
						log_message("Бонус скорости +20%% от Следа 2 Сёдзи на %s рассеялся." % unit.display_name)

		if unit.has_meta("shoji_swan_atk_turns") and int(unit.get_meta("shoji_swan_atk_turns", 0)) > 0:
			if unit.get_meta("shoji_swan_atk_skip_tick", false):
				unit.set_meta("shoji_swan_atk_skip_tick", false)
			else:
				var a_t := int(unit.get_meta("shoji_swan_atk_turns", 0)) - 1
				unit.set_meta("shoji_swan_atk_turns", a_t)
				if a_t == 0:
					log_message("Бафф +50%% СА от таланта Сёдзи на %s рассеялся." % unit.display_name)
					
		if unit.has_meta("binary_vuln_turns") and int(unit.get_meta("binary_vuln_turns", 0)) > 0:
			if unit.get_meta("binary_vuln_skip_tick", false):
				unit.set_meta("binary_vuln_skip_tick", false)
			else:
				var v_t := int(unit.get_meta("binary_vuln_turns", 0)) - 1
				unit.set_meta("binary_vuln_turns", v_t)
				
		if unit.has_meta("jeff_trace3_heal_turns") and int(unit.get_meta("jeff_trace3_heal_turns", 0)) > 0:
			if unit.get_meta("jeff_trace3_heal_skip_tick", false):
				unit.set_meta("jeff_trace3_heal_skip_tick", false)
			else:
				var j_heal_t := int(unit.get_meta("jeff_trace3_heal_turns", 0)) - 1
				unit.set_meta("jeff_trace3_heal_turns", j_heal_t)
				if j_heal_t == 0:
					log_message("Исходящее исцеление Джеффа приведено к норме.")
		if unit.has_meta("valramors_ult_vuln_turns") and int(unit.get_meta("valramors_ult_vuln_turns", 0)) > 0:
			if unit.get_meta("valramors_ult_vuln_skip_tick", false):
				unit.set_meta("valramors_ult_vuln_skip_tick", false)
			else:
				var v_turns := int(unit.get_meta("valramors_ult_vuln_turns", 0)) - 1
				unit.set_meta("valramors_ult_vuln_turns", v_turns)
				if v_turns == 0:
					log_message("Уязвимость от Сверхспособности Валраморса на %s рассеялась." % unit.display_name)
				
		if unit.has_meta("valramors_talent_turns") and int(unit.get_meta("valramors_talent_turns", 0)) > 0:
			if unit.get_meta("valramors_talent_skip_tick", false):
				unit.set_meta("valramors_talent_skip_tick", false)
			else:
				var t_turns := int(unit.get_meta("valramors_talent_turns", 0)) - 1
				unit.set_meta("valramors_talent_turns", t_turns)
				if t_turns == 0:
					# Возвращаем скорость цели в норму
					if unit.has_meta("valramors_spd_applied"):
						unit.remove_meta("valramors_spd_applied")
						unit.remove_speed_modifier(-0.08, 0.0)
						unit.recalculate_action_value()
						action_order_changed.emit()
						
					# Снимаем наложенную уязвимость первого союзника
					var elem := int(unit.get_meta("valramors_talent_weakness", -1))
					if elem != -1:
						unit.weaknesses.erase(elem)
					log_message("Ослабление Таланта Валраморса на %s завершилось. Характеристики возвращены в норму." % unit.display_name)
					
		if unit.has_meta("valramors_tech_ignore_turns") and int(unit.get_meta("valramors_tech_ignore_turns", 0)) > 0:
			if unit.get_meta("valramors_tech_ignore_skip_tick", false):
				unit.set_meta("valramors_tech_ignore_skip_tick", false)
			else:
				var t_turns := int(unit.get_meta("valramors_tech_ignore_turns", 0)) - 1
				unit.set_meta("valramors_tech_ignore_turns", t_turns)
				if t_turns == 0:
					log_message("Игнорирование защиты от техники Валраморса на %s завершилось." % unit.display_name)
					
				
		if unit.has_meta("ballast_turns") and int(unit.get_meta("ballast_turns", 0)) > 0:
			if unit.get_meta("ballast_skip_tick", false):
				unit.set_meta("ballast_skip_tick", false)
			else:
				var b_turns := int(unit.get_meta("ballast_turns", 0)) - 1
				unit.set_meta("ballast_turns", b_turns)
				if b_turns == 0:
					log_message("Статус «Балласт» на %s рассеялся." % unit.display_name)
		if unit.id == PusenkovAbilities.ID:
			if unit.has_meta("spd_buff_turns"):
				var spd_turns: int = int(unit.get_meta("spd_buff_turns", 0))
				if spd_turns > 0:
					unit.set_meta("spd_buff_turns", spd_turns - 1)
					if spd_turns - 1 == 0:
						unit.stats.spd -= 20.0
						log_message("Ускорение Кирилла завершилось.")
						
		elif unit.id == KaoriAbilities.ID:
			if unit.has_meta("untargetable"):
				var untarg_turns: int = int(unit.get_meta("untargetable_turns", 0))
				if untarg_turns > 0:
					unit.set_meta("untargetable_turns", untarg_turns - 1)
					if untarg_turns - 1 == 0:
						unit.set_meta("untargetable", false)
						log_message("Каори вышла из тумана (Недосягаемость снята).")
						
			if unit.has_meta("ult_recast_window"):
				var recast_w: int = int(unit.get_meta("ult_recast_window", 0))
				if recast_w > 0:
					unit.set_meta("ult_recast_window", recast_w - 1)
					if recast_w - 1 == 0:
						log_message("Окно повторного применения Сверхспособности Каори закрылось.")

		elif unit.id == "dasha":
			if unit.get_meta("overload_skip_tick", false):
				unit.set_meta("overload_skip_tick", false) 
			elif unit.has_meta("overload_turns"):
				var overload_t: int = int(unit.get_meta("overload_turns", 0))
				if overload_t > 0:
					unit.set_meta("overload_turns", overload_t - 1)
					if overload_t - 1 == 0:
						log_message("Состояние «Перегрузка» Даши завершилось.")
						
		elif unit.id == "danill":
			var cd: int = int(unit.get_meta("e6_cooldown", 0))
			if cd > 0:
				unit.set_meta("e6_cooldown", cd - 1)
				
			if unit.get_meta("danill_taunt_skip_tick", false):
				unit.set_meta("danill_taunt_skip_tick", false)
			else:
				var taunt_t: int = int(unit.get_meta("danill_taunt_turns", 0))
				if taunt_t > 0:
					unit.set_meta("danill_taunt_turns", taunt_t - 1)
					if taunt_t - 1 == 0:
						log_message("Провокация Данилла завершилась.")
						
		elif unit.id == "vika":
			if unit.has_meta("vika_awakening_turns") and int(unit.get_meta("vika_awakening_turns", 0)) > 0:
				if unit.get_meta("vika_awk_skip_tick", false):
					unit.set_meta("vika_awk_skip_tick", false)
				else:
					var awk_t := int(unit.get_meta("vika_awakening_turns", 0)) - 1
					unit.set_meta("vika_awakening_turns", awk_t)
					if awk_t == 0:
						log_message("Состояние «Пробуждение» Вики завершилось.")
						
			if unit.has_meta("vika_e2_turns") and int(unit.get_meta("vika_e2_turns", 0)) > 0:
				if unit.get_meta("vika_e2_skip_tick", false):
					unit.set_meta("vika_e2_skip_tick", false)
				else:
					var e2_t := int(unit.get_meta("vika_e2_turns", 0)) - 1
					unit.set_meta("vika_e2_turns", e2_t)
					if e2_t == 0:
						unit.stats.crit_rate -= 0.30
						log_message("Эйдолон 2 Вики: Бафф крит. шанса завершился.")
						
			if unit.has_meta("vika_e_atk_turns") and int(unit.get_meta("vika_e_atk_turns", 0)) > 0:
				var e_turns := int(unit.get_meta("vika_e_atk_turns", 0)) - 1
				unit.set_meta("vika_e_atk_turns", e_turns)
				if e_turns == 0:
					unit.set_meta("vika_e_atk_buff", 0.0)
					log_message("Навык E Вики: Бафф силы атаки завершился.")
		elif unit.id == "dotseva":
			# 1. Списание ходов «Легкого тумана» Сверхспособности
			if unit.has_meta("dotseva_fog_turns") and int(unit.get_meta("dotseva_fog_turns", 0)) > 0:
				if unit.get_meta("dotseva_fog_skip_tick", false):
					unit.set_meta("dotseva_fog_skip_tick", false)
				else:
					var fog_t := int(unit.get_meta("dotseva_fog_turns", 0)) - 1
					unit.set_meta("dotseva_fog_turns", fog_t)
					if fog_t == 0:
						log_message("Состояние «Лёгкий туман» Доцевой рассеялось.")
		elif unit.id == "milena":
			# 1. Списание Обертона
			if unit.has_meta("milena_overtone_turns") and int(unit.get_meta("milena_overtone_turns", 0)) > 0:
				if unit.get_meta("milena_overtone_skip_tick", false):
					unit.set_meta("milena_overtone_skip_tick", false)
				else:
					var ov_t := int(unit.get_meta("milena_overtone_turns", 0)) - 1
					unit.set_meta("milena_overtone_turns", ov_t)
					if ov_t == 0:
						update_milena_overtone_spd_buff(unit, false)
						log_message("Действие статуса «Обертон» Милены завершилось. Скорость союзников нормализована.")
		
		if unit.id == "rimes":
			if unit.has_meta("rimes_e2_triggered_this_action"):
				unit.remove_meta("rimes_e2_triggered_this_action")
						
		if unit.has_meta("archive_buff_turns") and int(unit.get_meta("archive_buff_turns", 0)) > 0:
				var arch_t := int(unit.get_meta("archive_buff_turns", 0)) - 1
				unit.set_meta("archive_buff_turns", arch_t)
				if arch_t == 0:
					unit.statuses.self_atk_buff_percent -= 0.30
					log_message("Световой конус Архив: Бафф СА завершился.")
				
		if unit.has_meta("crimson_tears_spd_turns") and int(unit.get_meta("crimson_tears_spd_turns", 0)) > 0:
			if unit.get_meta("crimson_tears_spd_skip_tick", false):
				unit.set_meta("crimson_tears_spd_skip_tick", false)
			else:
				var spd_t := int(unit.get_meta("crimson_tears_spd_turns", 0)) - 1
				unit.set_meta("crimson_tears_spd_turns", spd_t)
				if spd_t == 0:
					unit.remove_speed_modifier(0.40, 0.0)
					log_message("Конус «Басня...»: Скорость возвращена к норме.")
		
		if unit.has_meta("jeff_bass_listen_turns") and int(unit.get_meta("jeff_bass_listen_turns", 0)) > 0:
			if unit.get_meta("jeff_bass_listen_skip_tick", false):
				unit.set_meta("jeff_bass_listen_skip_tick", false)
			else:
				var j_turns: int = int(unit.get_meta("jeff_bass_listen_turns", 0)) - 1
				unit.set_meta("jeff_bass_listen_turns", j_turns)
				if j_turns == 0:
					log_message("Дебафф «Бассы! Слушай!» на %s завершился." % unit.display_name)
					
		if unit.has_meta("second_chance_active") and int(unit.get_meta("second_chance_active", 0)) > 0:
			var sc_t := int(unit.get_meta("second_chance_active", 0)) - 1
			unit.set_meta("second_chance_active", sc_t)
			if sc_t == 0:
				log_message("Срок действия статуса «Второй шанс» для %s истек." % unit.display_name)
				
		if unit.has_meta("arseniy_q_turns"):
			var q_turns: int = int(unit.get_meta("arseniy_q_turns", 0))
			if q_turns > 0:
				unit.set_meta("arseniy_q_turns", q_turns - 1)
				if q_turns - 1 == 0:
					unit.set_meta("arseniy_q_atk_percent", 0.0)
					unit.set_meta("arseniy_q_atk_flat", 0.0)
					log_message("Усиление Q Арсения на %s завершилось." % unit.display_name)

		# Ход завершается — уменьшаем длительность любого щита
		if unit.has_meta("shield_turns") and int(unit.get_meta("shield_turns", 0)) > 0:
			if unit.get_meta("shield_skip_tick", false):
				unit.set_meta("shield_skip_tick", false) 
			else:
				var sh_turns: int = int(unit.get_meta("shield_turns", 0)) - 1
				unit.set_meta("shield_turns", sh_turns)
				
				if sh_turns <= 0:
					unit.set_meta("shield_value", 0.0)
					log_message("Действие щита на %s завершилось." % unit.display_name)
					
					if unit.id == "danill" and unit.get_meta("e_shield_active", false):
						_on_danill_e_shield_broken(unit)

		if unit.is_ally:
			if unit.has_meta("archive_buff_turns"):
				var archive_t: int = int(unit.get_meta("archive_buff_turns", 0))
				if archive_t > 0:
					unit.set_meta("archive_buff_turns", archive_t - 1)
					if archive_t - 1 == 0:
						unit.statuses.self_atk_buff_percent -= 0.30
						log_message("Световой конус Архив: Бафф СА завершился.")
						
			if unit.has_meta("adversary_buff_turns"):
				var adv_t: int = int(unit.get_meta("adversary_buff_turns", 0))
				if adv_t > 0:
					unit.set_meta("adversary_buff_turns", adv_t - 1)
					if adv_t - 1 == 0:
						unit.stats.crit_rate -= 0.24
						log_message("Световой конус Нападение: Крит. шанс возвращен к исходному.")
						
			if unit.has_meta("arrows_buff_turns"):
				var arr_t: int = int(unit.get_meta("arrows_buff_turns", 0))
				if arr_t > 0:
					unit.set_meta("arrows_buff_turns", arr_t - 1)
					if arr_t - 1 == 0:
						var bonus_spd: float = float(unit.get_meta("arrows_spd_bonus", 0.0))
						unit.stats.spd -= bonus_spd
						log_message("Световой конус Стрелы: Бафф скорости завершился.")
						
			if unit.has_meta("medical_smell_healing_turns"):
				var smell_turns: int = int(unit.get_meta("medical_smell_healing_turns", 0))
				if smell_turns > 0:
					unit.set_meta("medical_smell_healing_turns", smell_turns - 1)
					
			# Внутри _end_turn() -> в блоке союзников:
			# ИСПРАВЛЕНО: Списание ходов для каждого источника среза защиты независимо
			if unit.has_meta("def_reductions"):
				var reductions: Dictionary = unit.get_meta("def_reductions")
				var to_remove := []
				for src in reductions:
					var data: Dictionary = reductions[src]
					var turns: int = int(data.get("turns", 0)) - 1
					data["turns"] = turns
					if turns <= 0:
						to_remove.append(src)
						log_message("Срез защиты от %s на %s завершился." % [src, unit.display_name])
				for src in to_remove:
					reductions.erase(src)
				recalculate_target_def(unit)
		
		if has_meta("lenskaya_fua_triggered_this_action"):
			remove_meta("lenskaya_fua_triggered_this_action")
			
		if has_meta("lenskaya_fua_attacker_credited"): 
			remove_meta("lenskaya_fua_attacker_credited")
		# В конец метода _end_turn перед проверкой ult_queue:
		if unit.has_meta("naama_dot_vuln_turns") and int(unit.get_meta("naama_dot_vuln_turns", 0)) > 0:
			var v_turns := int(unit.get_meta("naama_dot_vuln_turns", 0)) - 1
			unit.set_meta("naama_dot_vuln_turns", v_turns)
			if v_turns == 0:
				log_message("Слабость к DoT от Наамы на %s рассеялась." % unit.display_name)
				
		if unit.has_meta("naama_kiss_turns") and int(unit.get_meta("naama_kiss_turns", 0)) > 0:
			var k_turns := int(unit.get_meta("naama_kiss_turns", 0)) - 1
			unit.set_meta("naama_kiss_turns", k_turns)
			if k_turns == 0:
				log_message("«Поцелуй бездны» на %s исчез." % unit.display_name)
				
				# Эйдолон Е6 Наамы:
				var naama_ref := get_naama_unit()
				if naama_ref and naama_ref.is_alive() and naama_ref.eidolon >= 6:
					log_message("Эйдолон 6 Наамы: «Поцелуй бездны» исчез! Детонация всех DoT!")
					explode_dots(unit, naama_ref, 1.0)
					gain_skill_point()
				recalculate_target_def(unit)
		
		if unit.id == "musienko":
		# Списание баффа КУ от Е4 (+60% КУ на 3 хода)
			if unit.has_meta("musienko_e4_cd_turns") and int(unit.get_meta("musienko_e4_cd_turns", 0)) > 0:
				if unit.get_meta("musienko_e4_cd_skip_tick", false):
					unit.set_meta("musienko_e4_cd_skip_tick", false)
				else:
					var e4_turns := int(unit.get_meta("musienko_e4_cd_turns", 0)) - 1
					unit.set_meta("musienko_e4_cd_turns", e4_turns)
					if e4_turns == 0:
						log_message("Эйдолон 4 Мусиенко: Бафф Крит. урона +60%% завершился.")
		
		
	# Очистка разовых блокировщиков FUA-наборов версии 1.1
	if has_meta("galilean_fua_started_this_action"):
		remove_meta("galilean_fua_started_this_action")
	if unit.has_meta("irkutsk_fua_credited_this_action"):
		unit.remove_meta("irkutsk_fua_credited_this_action")

	# Списание скорости Силуэта (+20 скорости на 2 хода)
	if unit.has_meta("relic_silhouette_spd_turns") and int(unit.get_meta("relic_silhouette_spd_turns", 0)) > 0:
		if unit.get_meta("relic_silhouette_spd_skip_tick", false):
			unit.set_meta("relic_silhouette_spd_skip_tick", false)
		else:
			var s_turns: int = int(unit.get_meta("relic_silhouette_spd_turns", 0)) - 1
			unit.set_meta("relic_silhouette_spd_turns", s_turns)
			if s_turns == 0:
				unit.remove_speed_modifier(0.0, 20.0)
				unit.recalculate_action_value()
				log_message("Сет Силуэта: Ускорение +20 ед. завершилось.")
				action_order_changed.emit()
				
	if unit.has_meta("sara_e2_vuln_turns") and int(unit.get_meta("sara_e2_vuln_turns", 0)) > 0:
			if unit.get_meta("sara_e2_vuln_skip_tick", false):
				unit.set_meta("sara_e2_vuln_skip_tick", false)
			else:
				var e2_t := int(unit.get_meta("sara_e2_vuln_turns", 0)) - 1
				unit.set_meta("sara_e2_vuln_turns", e2_t)

	# Списание КШ Принявшего грех глава (+5% за стак на 1 ход)
	if unit.has_meta("relic_sin_turns") and int(unit.get_meta("relic_sin_turns", 0)) > 0:
		if unit.get_meta("relic_sin_skip_tick", false):
			unit.set_meta("relic_sin_skip_tick", false)
		else:
			var s_turns: int = int(unit.get_meta("relic_sin_turns", 0)) - 1
			unit.set_meta("relic_sin_turns", s_turns)
			if s_turns == 0:
				var s_stacks: int = int(unit.get_meta("relic_sin_stacks", 0))
				unit.stats.crit_rate -= 0.05 * float(s_stacks)
				unit.remove_meta("relic_sin_stacks")
				log_message("Сет Принявшего грех: Бафф крит. шанса завершился.")

	# Списание скорости Исследователя будущего (+12% скорости на 1 ход)
	if unit.has_meta("relic_bereft_spd_turns") and int(unit.get_meta("relic_bereft_spd_turns", 0)) > 0:
		if unit.get_meta("relic_bereft_spd_skip_tick", false):
			unit.set_meta("relic_bereft_spd_skip_tick", false)
		else:
			var r_turns: int = int(unit.get_meta("relic_bereft_spd_turns", 0)) - 1
			unit.set_meta("relic_bereft_spd_turns", r_turns)
			if r_turns == 0:
				unit.remove_speed_modifier(0.12, 0.0)
				unit.recalculate_action_value()
				log_message("Сет Исследователя отнятого будущего: бафф скорости завершился.")
				action_order_changed.emit()

	# Списание баффа СА Галилеянина (3 хода)
	if unit.has_meta("relic_galilean_turns") and int(unit.get_meta("relic_galilean_turns", 0)) > 0:
		if unit.get_meta("relic_galilean_skip_tick", false):
			unit.set_meta("relic_galilean_skip_tick", false)
		else:
			var g_turns: int = int(unit.get_meta("relic_galilean_turns", 0)) - 1
			unit.set_meta("relic_galilean_turns", g_turns)
			if g_turns == 0:
				unit.remove_meta("relic_galilean_stacks")
				unit.remove_meta("relic_galilean_atk_pct")
				log_message("Сет Галилеянина: Бафф силы атаки завершился.")
				
		# В конец метода _end_turn перед проверкой ult_queue:
	if unit.has_meta("keloist_orthoshield_turns") and int(unit.get_meta("keloist_orthoshield_turns", 0)) > 0:
		if unit.get_meta("keloist_orthoshield_skip_tick", false):
			unit.set_meta("keloist_orthoshield_skip_tick", false)
		else:
			var o_turns: int = int(unit.get_meta("keloist_orthoshield_turns", 0)) - 1
			unit.set_meta("keloist_orthoshield_turns", o_turns)
			if o_turns == 0:
				log_message("Ортощит Келойста на %s завершился." % unit.display_name)
				
	# Очищаем список пораженных целей совместной атаки Келойста за этот ход
	if unit.has_meta("keloist_joint_attack_hit_list"):
		unit.remove_meta("keloist_joint_attack_hit_list")
		
	if unit.has_meta("lenskaya_stinger_turns") and int(unit.get_meta("lenskaya_stinger_turns", 0)) > 0:
		if unit.get_meta("lenskaya_stinger_skip_tick", false):
			unit.set_meta("lenskaya_stinger_skip_tick", false)
		else:
			var s_turns: int = int(unit.get_meta("lenskaya_stinger_turns", 0)) - 1
			unit.set_meta("lenskaya_stinger_turns", s_turns)
			if s_turns == 0:
				log_message("Состояние «Жало» Ленской завершилось.")
				
	if unit.has_meta("lenskaya_bounty_turns") and int(unit.get_meta("lenskaya_bounty_turns", 0)) > 0:
		var b_turns: int = int(unit.get_meta("lenskaya_bounty_turns", 0)) - 1
		unit.set_meta("lenskaya_bounty_turns", b_turns)
		if b_turns == 0:
			log_message("Статус «Награда за голову» на %s завершился." % unit.display_name)
			
	if unit.has_meta("lenskaya_tech_fua_buff_turns") and int(unit.get_meta("lenskaya_tech_fua_buff_turns", 0)) > 0:
		if unit.get_meta("lenskaya_tech_fua_buff_skip_tick", false):
			unit.set_meta("lenskaya_tech_fua_buff_skip_tick", false)
		else:
			var t_turns: int = int(unit.get_meta("lenskaya_tech_fua_buff_turns", 0)) - 1
			unit.set_meta("lenskaya_tech_fua_buff_turns", t_turns)
			if t_turns == 0:
				log_message("Бафф Техники Ленской на бонус-атаки %s рассеялся." % unit.display_name)
				
	if unit.has_meta("lenskaya_slow_turns") and int(unit.get_meta("lenskaya_slow_turns", 0)) > 0:
		var sl_turns: int = int(unit.get_meta("lenskaya_slow_turns", 0)) - 1
		unit.set_meta("lenskaya_slow_turns", sl_turns)
		if sl_turns == 0:
			var slow_val: float = float(unit.get_meta("lenskaya_slow_value", 20.0))
			unit.add_speed_modifier(0.0, slow_val) # Возвращаем скорость в норму
			log_message("Замедление Ленской на %s рассеялось." % unit.display_name)
			
	# Внутри _end_turn() в самом конце перед проверкой ult_queue:
	# 1. Эмпирейцы [4]: списание гарантированного крита
	if unit.has_meta("faction_empyrean_crit_turns") and int(unit.get_meta("faction_empyrean_crit_turns", 0)) > 0:
		var turns := int(unit.get_meta("faction_empyrean_crit_turns", 0)) - 1
		unit.set_meta("faction_empyrean_crit_turns", turns)
		if turns == 0:
			var orig_cr: float = float(unit.get_meta("faction_original_crit_rate", 0.05))
			unit.stats.crit_rate = orig_cr
			log_message("Эмпирейцы [4]: бафф гарантированного Крита на %s завершился." % unit.display_name)
			
	# 2. Академия [3]: списание баффа наносимого урона
	if unit.has_meta("academy_dmg_bonus_turns") and int(unit.get_meta("academy_dmg_bonus_turns", 0)) > 0:
		if unit.get_meta("academy_dmg_bonus_skip_tick", false):
			unit.set_meta("academy_dmg_bonus_skip_tick", false)
		else:
			var turns := int(unit.get_meta("academy_dmg_bonus_turns", 0)) - 1
			unit.set_meta("academy_dmg_bonus_turns", turns)
			if turns == 0:
				log_message("Академия [3]: бафф урона на %s завершился." % unit.display_name)
					
		# Очистка разовых блокировщиков стаков конусов версии 1.1
	if has_meta("echoes_ult_triggered_this_action"):
		remove_meta("echoes_ult_triggered_this_action")
	if has_meta("save_world_plan_credited_this_action"):
		remove_meta("save_world_plan_credited_this_action")
	if has_meta("edge_existence_stack_credited"):
		remove_meta("edge_existence_stack_credited")

	# Списание скорости Отголосков прошлого (+40% на 2 хода)
	if unit.has_meta("echoes_spd_buff_turns") and int(unit.get_meta("echoes_spd_buff_turns", 0)) > 0:
		if unit.get_meta("echoes_spd_buff_skip_tick", false):
			unit.set_meta("echoes_spd_buff_skip_tick", false)
		else:
			var e_turns: int = int(unit.get_meta("echoes_spd_buff_turns", 0)) - 1
			unit.set_meta("echoes_spd_buff_turns", e_turns)
			if e_turns == 0:
				unit.remove_speed_modifier(0.40, 0.0)
				log_message("Ускорение конуса «Отголоски прошлого» на %s завершилось." % unit.display_name)
	
	if unit.has_meta("isaac_dmg_buff_turns") and int(unit.get_meta("isaac_dmg_buff_turns", 0)) > 0:
		if unit.get_meta("isaac_dmg_buff_skip_tick", false):
			unit.set_meta("isaac_dmg_buff_skip_tick", false)
		else:
			var d_turns: int = int(unit.get_meta("isaac_dmg_buff_turns", 0)) - 1
			unit.set_meta("isaac_dmg_buff_turns", d_turns)
			if d_turns == 0:
				log_message("Улучшенный Навык Q Айзека: бафф урона на %s завершился." % unit.display_name)
				
	if unit.has_meta("isaac_ult_buff_turns") and int(unit.get_meta("isaac_ult_buff_turns", 0)) > 0:
		if unit.get_meta("isaac_ult_buff_skip_tick", false):
			unit.set_meta("isaac_ult_buff_skip_tick", false)
		else:
			var u_turns: int = int(unit.get_meta("isaac_ult_buff_turns", 0)) - 1
			unit.set_meta("isaac_ult_buff_turns", u_turns)
			if u_turns == 0:
				var spd_bonus: float = float(unit.get_meta("isaac_ult_spd_bonus", 20.0))
				unit.remove_speed_modifier(0.0, spd_bonus)
				unit.recalculate_action_value()
				log_message("Сверхспособность Айзека: баффы крит. урона и скорости на %s завершились." % unit.display_name)
				action_order_changed.emit()
				
	if unit.has_meta("isaac_crit_dmg_taken_turns") and int(unit.get_meta("isaac_crit_dmg_taken_turns", 0)) > 0:
		var c_turns: int = int(unit.get_meta("isaac_crit_dmg_taken_turns", 0)) - 1
		unit.set_meta("isaac_crit_dmg_taken_turns", c_turns)
		if c_turns == 0:
			log_message("Дебафф крит. урона Айзека на %s рассеялся." % unit.display_name)
			
	if unit.has_meta("isaac_dmg_reduce_turns") and int(unit.get_meta("isaac_dmg_reduce_turns", 0)) > 0:
		var r_turns: int = int(unit.get_meta("isaac_dmg_reduce_turns", 0)) - 1
		unit.set_meta("isaac_dmg_reduce_turns", r_turns)
		if r_turns == 0:
			log_message("Снижение урона от Навыка E Айзека на %s рассеялось." % unit.display_name)
	
	if unit.has_meta("joan_dont_miss_turns") and int(unit.get_meta("joan_dont_miss_turns", 0)) > 0:
		if unit.get_meta("joan_dont_miss_skip_tick", false):
			unit.set_meta("joan_dont_miss_skip_tick", false)
		else:
			var turns: int = int(unit.get_meta("joan_dont_miss_turns", 0)) - 1
			unit.set_meta("joan_dont_miss_turns", turns)
			if turns == 0:
				log_message("Дебафф «Не промахнись» на %s завершился." % unit.display_name)

	if unit.has_meta("joan_tech_vuln_turns") and int(unit.get_meta("joan_tech_vuln_turns", 0)) > 0:
		var tech_turns: int = int(unit.get_meta("joan_tech_vuln_turns", 0)) - 1
		unit.set_meta("joan_tech_vuln_turns", tech_turns)
		if tech_turns == 0:
			log_message("Уязвимость от техники Жоана на %s рассеялась." % unit.display_name)
				
	# ИСПРАВЛЕНО: Списание ходов Утечки (+40% ШПЭ на 3 хода)
	if unit.has_meta("lc_leak_turns") and int(unit.get_meta("lc_leak_turns", 0)) > 0:
		if unit.get_meta("lc_leak_skip_tick", false):
			unit.set_meta("lc_leak_skip_tick", false)
		else:
			var l_turns: int = int(unit.get_meta("lc_leak_turns", 0)) - 1
			unit.set_meta("lc_leak_turns", l_turns)
			if l_turns == 0:
				unit.stats.effect_hit_rate -= 0.40
				log_message("Световой конус Утечка: Бафф ШПЭ на %s завершился." % unit.display_name)
					
	# Списание стаков Плана по спасению мира (исчезают через 2 хода)
	if unit.has_meta("save_world_plan_turns") and int(unit.get_meta("save_world_plan_turns", 0)) > 0:
		if unit.get_meta("save_world_plan_skip_tick", false):
			unit.set_meta("save_world_plan_skip_tick", false)
		else:
			var p_turns: int = int(unit.get_meta("save_world_plan_turns", 0)) - 1
			unit.set_meta("save_world_plan_turns", p_turns)
			if p_turns == 0:
				unit.remove_meta("save_world_plan_stacks")
				log_message("Стаки Проработки плана конуса спасения на %s рассеялись." % unit.display_name)
	
	if unit.has_meta("action_advance_pending"):
		var advance_percent: float = float(unit.get_meta("action_advance_pending", 0.0))
		if advance_percent > 0.0:
			unit.advance_action(advance_percent)
			unit.set_meta("action_advance_pending", 0.0) 
			log_message("Продвижение действия %s на %.0f%% успешно применено к шкале." % [unit.display_name, advance_percent])
	
	if has_meta("arseniy_talent_credited_this_action"):
			remove_meta("arseniy_talent_credited_this_action")
			
	check_joan_talent_trigger()
	
	evaluate_feel_my_presence(unit)
		
	# === СТРОГО ВНЕ ВЕТКИ ELSE (В САМОМ КОНЦЕ МЕТОДА _end_turn) ===
	if not ult_queue.is_empty():
		await _process_ult_queue()
		
	turn_ended.emit(unit)
	action_order_changed.emit()
	await get_tree().create_timer(0.3).timeout
	_advance_to_next_turn()	

func force_end_turn() -> void:
	if current_unit != null:
		_end_turn(current_unit)

func _check_battle_end() -> bool:
	if battle_mode == "level_6" and get_living_enemies().is_empty():
		if get_living_allies().size() < allies.size():
			phase = Phase.DEFEAT
			log_message("💀 Поражение! Не выполнено условие: погиб союзник!")
			battle_ended.emit(false)
			return true
	if battle_mode == "level_10" and get_living_enemies().is_empty():
		if get_living_allies().size() < allies.size():
			phase = Phase.DEFEAT
			log_message("💀 Поражение! Не выполнено условие: погиб один из союзников!")
			battle_ended.emit(false)
			return true
	if battle_mode == "fiction":
		# В Вымысле победа засчитывается, когда резерв исчерпан И на поле никого не осталось
		if fiction_max_pool == 0 and get_living_enemies().is_empty():
			phase = Phase.VICTORY
			log_message("Победа в Чистом вымысле! Все 15 Солдат Пустоты уничтожены!")
			battle_ended.emit(true)
			return true
	else:
		if get_living_enemies().is_empty():
			phase = Phase.VICTORY
			log_message("Победа!")
			battle_ended.emit(true)
			return true
			
	if get_living_allies().is_empty():
		phase = Phase.DEFEAT
		log_message("Поражение...")
		battle_ended.emit(false)
		return true
	return false

func can_player_act() -> bool:
	return _waiting_for_player and phase == Phase.RUNNING

func player_basic_attack(target: CombatUnit) -> void:
	if not can_player_act() or current_unit == null:
		return
	action_hit_enemies.clear()
	_waiting_for_player = false
	# --- ИЗОЛЯЦИЯ: Срез изменений от других союзников ---
	var is_rimes := current_unit.id == "rimes"
	if not is_rimes:
		capture_isolation_snapshot()
		
	_execute_basic_attack(current_unit, target)
	
	if not is_rimes:
		restore_isolation_snapshot()
		
	_end_turn(current_unit)

func player_enhanced_basic(target: CombatUnit) -> void:
	if not can_player_act() or current_unit == null:
		return
	current_attack_action_id += 1
		
	if current_unit.id == "isaac_admin":
		action_hit_enemies.clear()
		_waiting_for_player = false
		IsaacAdminAbilities.execute_enhanced_basic(current_unit, target, self)
		_end_turn(current_unit)
		return
	if current_unit.id == "shoji_swan":
		action_hit_enemies.clear()
		_waiting_for_player = false
		ShojiSwanAbilities.execute_enhanced_basic(current_unit, target, self)
		_end_turn(current_unit)
		return
	if current_unit.id != ArseniyAbilities.ID:
		return
	if not ArseniyAbilities.is_new_development(current_unit):
		log_message("Усиленная атака доступна только в «Новой разработке»!")
		return
	if skill_points < 1:
		log_message("Недостаточно ОН!")
		return
	_waiting_for_player = false
	_spend_skill_points(1)
	ArseniyAbilities.execute_enhanced_basic(current_unit, target, self)
	_end_turn(current_unit)

func player_skill(target: CombatUnit, extra_targets: Array = []) -> void:
	if not can_player_act() or current_unit == null:
		return

	var costs_sp := true
	if current_unit.id == ArseniyAbilities.ID and not ArseniyAbilities.skill_q_costs_sp(current_unit):
		costs_sp = false
	elif current_unit.id == KaoriAbilities.ID and target == (current_unit.get_meta("e_shuriken_target") if current_unit.has_meta("e_shuriken_target") else null):
		costs_sp = false
	elif current_unit.id == "dasha" and current_unit.has_meta("overload_turns") and int(current_unit.get_meta("overload_turns", 0)) > 0:
		costs_sp = false
	elif current_unit.id == "isaac" and int(current_unit.get_meta("isaac_theory_stacks", 0)) >= 8:
		# Е2: Усиленный Навык Q Айзека не тратит очки навыков
		if current_unit.eidolon >= 2:
			costs_sp = false
	elif current_unit.id == "joan_spirit":
		costs_sp = false
	elif current_unit.id == "dotseva_crimson_tears" and bool(current_unit.get_meta("doceva_tears_zone_active", false)):
		costs_sp = false

	if costs_sp and skill_points < 1:
		log_message("Недостаточно ОН!")
		return

	_waiting_for_player = false
	if costs_sp:
		_spend_skill_points(1)
		
	if current_unit.get_meta("light_cone_id", "") == "lullaby":
		gain_energy_with_err(current_unit, 5.0)
		
	if current_unit.get_meta("light_cone_id", "") == "vitality":
		heal_unit(current_unit, current_unit.stats.max_hp * 0.10)
		log_message("Конус Живучесть: %s восстановил 10%% ХП." % current_unit.display_name)

	if battle_mode == "dungeon_kitchens" and current_unit.is_ally:
		heal_unit(current_unit, current_unit.stats.max_hp * 0.12)
		current_unit.set_meta("dungeon_kitchens_atk_turns", 1)
		current_unit.set_meta("dungeon_kitchens_atk_skip_tick", true)
		log_message("🍳 Аномалия «Световой резонанс»: %s восстановил 12%% макс. ХП и получил +20%% СА на 1 ход!" % current_unit.display_name)

	var is_rimes := current_unit.id == "rimes"
	if not is_rimes:
		capture_isolation_snapshot()

	set_meta("current_attack_type", "skill_q")
	_execute_skill(current_unit, target, extra_targets)
	set_meta("current_attack_type", "")
	
	if not is_rimes:
		restore_isolation_snapshot()
	
	_end_turn(current_unit)

func player_skill_e(target: CombatUnit) -> void:
	if not can_player_act() or current_unit == null:
		return
	
	if current_unit.id == "rimes":
		var other_allies_alive := false
		for ally in allies:
			if ally.is_alive() and ally != current_unit:
				other_allies_alive = true
				break
		if not other_allies_alive:
			log_message("Нельзя использовать Навык E: на поле боя нет других живых союзников!")
			return
		
	var costs_sp := 2
	if current_unit.id == KaoriAbilities.ID and target == (current_unit.get_meta("e_shuriken_target") if current_unit.has_meta("e_shuriken_target") else null):
		costs_sp = 0
	elif current_unit.id == "dasha":
		costs_sp = 2
	elif current_unit.id == ShojiAbilities.ID:
		costs_sp = 1
	elif current_unit.id == "dotseva": # <--- ДОБАВЛЕНО: Доцева в Тумане тратит только 1 ОН
		var in_fog := int(current_unit.get_meta("dotseva_fog_turns", 0)) > 0
		costs_sp = 1 if in_fog else 2
	elif current_unit.id == "naama":
		if current_unit.get_meta("naama_e4_free_skill", false):
			costs_sp = 0
		else:
			costs_sp = 2
	elif current_unit.id == "lenskaya": # <--- ДОБАВИТЬ ЭТО ДЛЯ ЛЕНСКОЙ
		costs_sp = 1
	elif current_unit.id == "rimes":
		costs_sp = 2
	elif current_unit.id == "musienko":
		if current_unit.has_meta("musienko_annihilation_active"):
			log_message("Навык E заблокирован в состоянии «Аннигиляции бытия»!")
			return
		costs_sp = 2
	elif current_unit.id == "valramors":
		costs_sp = 1
	elif current_unit.id == "joan_spirit":
		var e_cost := 3 if current_unit.eidolon >= 1 else 4
		var regrets := int(current_unit.get_meta("joan_regret", 0))
		if regrets < e_cost:
			log_message("Недостаточно зарядов «Сожаления» (%d/%d)!" % [regrets, e_cost])
			return
		costs_sp = 0
	elif current_unit.id == "isaac_admin":
		costs_sp = 1
	elif current_unit.id == "sara_admin":
		costs_sp = 1
	elif current_unit.id == "shoji_swan":
		costs_sp = 1
	elif current_unit.id == "katarina":
		costs_sp = 2
	elif current_unit.id == "dotseva_crimson_tears":
		costs_sp = 2

	if skill_points < costs_sp:
		log_message("Недостаточно ОН!")
		return

	if skill_points < costs_sp:
		log_message("Недостаточно ОН!")
		return
		
	_waiting_for_player = false
	if costs_sp > 0:
		_spend_skill_points(costs_sp)
		
	if current_unit.get_meta("light_cone_id", "") == "lullaby":
		gain_energy_with_err(current_unit, 5.0)
		
	if current_unit.get_meta("light_cone_id", "") == "vitality":
		heal_unit(current_unit, current_unit.stats.max_hp * 0.10)

	if battle_mode == "dungeon_kitchens" and current_unit.is_ally:
		heal_unit(current_unit, current_unit.stats.max_hp * 0.12)
		current_unit.set_meta("dungeon_kitchens_atk_turns", 1)
		current_unit.set_meta("dungeon_kitchens_atk_skip_tick", true)
		log_message("🍳 Аномалия «Световой резонанс»: %s восстановил 12%% макс. ХП и получил +20%% СА на 1 ход!" % current_unit.display_name)
	
	if current_unit.get_meta("light_cone_id", "") == "perfect_metamorphosis":
		var current_stacks := int(current_unit.get_meta("meta_spd_stacks", 0))
		if current_stacks < 3:
			current_unit.set_meta("meta_spd_stacks", current_stacks + 1)
			current_unit.add_speed_modifier(0.0, 6.0) # +6 Скорости flat
			log_message("🦋 Конус «Метаморфоз»: Скорость %s повышена на +6 ед. (стаки: %d/3)!" % [current_unit.display_name, current_stacks + 1])
			
	# --- ИЗОЛЯЦИЯ: Срез изменений от других союзников ---
	var is_rimes := current_unit.id == "rimes"
	if not is_rimes:
		capture_isolation_snapshot()
		
	# Конус Падения мира: использование навыка E накладывает Проявление Гнева на 3 хода
	if current_unit.get_meta("light_cone_id", "") == "inevitable_fall":
		current_unit.set_meta("inevitable_fall_wrath_turns", 3)
		current_unit.set_meta("inevitable_fall_wrath_skip_tick", true)
		log_message("Конус «Падение мира неизбежно»: На %s наложен статус «Проявление Гнева» на 3 хода." % current_unit.display_name)

	set_meta("current_attack_type", "skill_e")
	_execute_skill_e(current_unit, target)
	set_meta("current_attack_type", "")
	
	if not is_rimes:
		restore_isolation_snapshot()
		
	_end_turn(current_unit)
	if current_unit.id == "naama" and current_unit.get_meta("naama_e4_free_skill", false):
		current_unit.set_meta("naama_e4_free_skill", false)

# НОВАЯ МЕХАНИКА: Добавление ультимейта в моментальную очередь
func queue_ultimate(unit: CombatUnit) -> void:
	if not unit.is_ally or not unit.is_alive():
		return
	
	# След 3 Арсения Админа: Если союзник тратит > 200 Энергии на ульту
	var ars := get_arseniy_admin_unit()
	if ars and ars.is_alive() and unit.max_energy > 200.0:
		for enemy in get_living_enemies():
			enemy.set_meta("arseniy_trace3_vuln_turns", 3)
			enemy.set_meta("arseniy_trace3_vuln_skip_tick", true)
		log_message("⚡ След 3 Арсения: Потрачено >200 Энергии! Все враги получают +30% уязвимости ко всему урону на 3 хода.")
	# ИСПРАВЛЕНО: Если это Арсений и он НЕ в «Новой разработке» — не даем ультовать,
	# сохраняя ему 100% энергии для последующей активации Навыка E
	if unit.id == "arseniy" and not ArseniyAbilities.is_new_development(unit):
		log_message("⚡ %s не находится в «Новой разработке»! Сверхспособность удержана на 100%% энергии." % unit.display_name)
		return # Выходим без сброса энергии и постановки в очередь
		
	var recast_window := int(unit.get_meta("ult_recast_window", 0))
	var costs_energy := true
	if unit.id == KaoriAbilities.ID and recast_window > 0:
		costs_energy = false
		
	if unit.id == "joan_spirit":
		var in_spirit: bool = bool(unit.get_meta("joan_spirit_form", false))
		var wishes: int = int(unit.get_meta("joan_last_wish", 0))
		var required: int = 8 if in_spirit else 12 # Было 10, стало 8
		if wishes < required:
			return
		costs_energy = false
		
	if costs_energy and unit.energy < unit.max_energy:
		return 
		
	if costs_energy:
		unit.spend_energy(unit.max_energy)
		
	for ally in allies:
		if ally.is_alive() and ally != unit and ally.get_meta("light_cone_id", "") == "touch_waking_world":
			var energy_gain := ally.max_energy * 0.08
			gain_energy_with_err(ally, energy_gain)
			log_message("Конус «Коснись...»: %s получил %d энергии за ульт союзника." % [ally.display_name, int(energy_gain)])
		
	if unit.get_meta("light_cone_id", "") == "medical_smell":
		unit.set_meta("medical_smell_healing_turns", 2)
		
	if unit.get_meta("light_cone_id", "") == "archive" and costs_energy:
		unit.statuses.self_atk_buff_percent += 0.30
		unit.set_meta("archive_buff_turns", 2)
		log_message("Конус Архив: СА %s повышена на 30%% на 2 хода!" % unit.display_name)
	
	action_hit_enemies.clear()
	ult_queue.append(unit)
	log_message("⚡ Сверхспособность %s поставлена в очередь!" % unit.display_name)
	
	if _waiting_for_player:
		_waiting_for_player = false
		
	if not _is_processing_ult_queue:
		_process_ult_queue()
		
# НОВАЯ МЕХАНИКА: Пошаговая обработка прерываний из очереди Сверхспособностей
# НОВАЯ МЕХАНИКА: Пошаговая обработка прерываний из очереди Сверхспособностей
func _process_ult_queue() -> void:
	if _is_processing_ult_queue:
		return
		
	_is_processing_ult_queue = true
	
	while not ult_queue.is_empty():
		if phase != Phase.RUNNING:
			ult_queue.clear()
			_is_processing_ult_queue = false
			return
			
		var unit: CombatUnit = ult_queue.pop_front()
		current_attack_action_id += 1
		log_message("⚡ Активация Сверхспособности %s из очереди!" % unit.display_name)
		
		var target: CombatUnit = null
		if unit.has_meta("ult_target"):
			target = unit.get_meta("ult_target")
			unit.remove_meta("ult_target")
			
		# ИСПРАВЛЕНО: Список ультимейтов, требующих выбора цели
		var requires_target := unit.id in ["arseniy", "pusenkov", "kaori", "shoji", "vika", "rimes", "isaac", "musienko", "valramors", "arseniy_admin", "katarina"]
		if requires_target and target == null:
			set_meta("is_selecting_ult_target", true)
			ult_targeting_requested.emit(unit)
			
			while has_meta("is_selecting_ult_target") and get_meta("is_selecting_ult_target"):
				await get_tree().create_timer(0.1).timeout
				
			if unit.has_meta("ult_target"):
				target = unit.get_meta("ult_target")
				unit.remove_meta("ult_target")
		
		_execute_ultimate(unit, target)
		
		check_joan_talent_trigger()
		
		# ИСПРАВЛЕНО: Вызываем проверку конуса ЗДЕСЬ — внутри цикла для ультующего героя!
		evaluate_feel_my_presence(unit)
		
		if unit.has_meta("milena_e1_res_pen"):
			unit.remove_meta("milena_e1_res_pen")
		
		unit_updated.emit(unit)
		if target:
			unit_updated.emit(target)
			
		await get_tree().create_timer(0.6).timeout
		
	_is_processing_ult_queue = false
	
	if current_unit and current_unit.is_ally and phase == Phase.RUNNING:
		_waiting_for_player = true 
	
	# Строка evaluate_feel_my_presence(unit) ОТСЮДА УДАЛЕНА
	
	unit_updated.emit(current_unit)
	
func player_ultimate(target: CombatUnit = null) -> void:
	if not can_player_act() or current_unit == null:
		return
	
	var ars_admin := get_arseniy_admin_unit()
	if ars_admin and ars_admin.is_alive() and current_unit.is_ally:
		if current_unit.max_energy > 200.0:
			for enemy in get_living_enemies():
				if enemy.is_alive():
					enemy.set_meta("arseniy_trace3_vuln_turns", 3)
					enemy.set_meta("arseniy_trace3_vuln_skip_tick", true)
			log_message("⚡ След 3 Арсения: %s потратил >200 энергии на Сверхспособность! Все враги получают +30%% уязвимости ко ВСЕМУ урону на 3 хода." % current_unit.display_name)
			
	var recast_window: int = int(current_unit.get_meta("ult_recast_window", 0))
	var costs_energy := true
	if current_unit.id == KaoriAbilities.ID and recast_window > 0:
		costs_energy = false 
		
	if costs_energy and current_unit.energy < current_unit.max_energy:
		log_message("Недостаточно энергии!")
		return
	if current_unit.id == ArseniyAbilities.ID and not ArseniyAbilities.is_new_development(current_unit):
		log_message("Сверхспособность доступна только в «Новой разработке»!")
		return
	_waiting_for_player = false
	if costs_energy:
		current_unit.spend_energy(current_unit.max_energy)
		
	if current_unit.get_meta("light_cone_id", "") == "medical_smell":
		current_unit.set_meta("medical_smell_healing_turns", 2)
		
	if current_unit.get_meta("light_cone_id", "") == "archive" and costs_energy:
		current_unit.statuses.self_atk_buff_percent += 0.30
		current_unit.set_meta("archive_buff_turns", 2)
		log_message("Конус Архив: СА %s повышена на 30%% на 2 хода!" % current_unit.display_name)
		
	_execute_ultimate(current_unit, target)
	_end_turn(current_unit)

func _execute_basic_attack(attacker: CombatUnit, target: CombatUnit) -> void:
	current_attack_action_id += 1
	_last_attacker = attacker
	start_attack_recording(attacker)
	match attacker.id:
		MarinaAbilities.ID:
			var mult := MarinaAbilities.get_basic_multiplier(attacker.eidolon)
			var result := calc_dmg(attacker, target, mult)
			deal_damage(target, result.damage, attacker, attacker.element, result.crit)
			ToughnessSystem.apply_weakness_hit(attacker, target, self)
			ToughnessSystem.on_hit_entanglement(target)
			gain_skill_point()
			gain_energy_with_err(attacker, 20.0)
			log_message("%s — базовая атака по %s: %d%s" % [attacker.display_name, target.display_name, int(result.damage), " (КРИТ!)" if result.crit else ""])
		SaraAbilities.ID:
			SaraAbilities.execute_basic(attacker, target, self)
		ArseniyAbilities.ID:
			ArseniyAbilities.execute_basic(attacker, target, self)
		PusenkovAbilities.ID:
			var counter: int = attacker.get_meta("basic_counter", 0)
			if counter >= 3:
				var mult: float = 2.30 + 0.30 
				if attacker.eidolon >= 3:
					mult *= 1.20 
					
				var extra_cd: float = attacker.stats.get_effective_crit_dmg(attacker.statuses) + get_extra_crit_dmg(attacker)
				var old_cr: float = attacker.stats.crit_rate
				attacker.stats.crit_rate = 2.0
				
				var res: Dictionary = DamageCalculator.calc_damage(attacker, target, mult, 0.0, true, 0.0, extra_cd)
				attacker.stats.crit_rate = old_cr
				
				var final_dmg: float = float(res.get("damage", 0.0))
				if attacker.eidolon >= 4 and randf() < 0.40:
					final_dmg *= 3.0
					log_message("Эйдолон 4 Кирилла: Сработал тройной урон!")
					
				deal_damage(target, final_dmg, attacker, attacker.element, true)
				ToughnessSystem.apply_weakness_hit(attacker, target, self, 2.0)
				
				if attacker.has_meta("untargetable") and attacker.get_meta("untargetable"):
					attacker.set_meta("untargetable", false)
					log_message("Кирилл провел Усиленную базовую атаку и вышел из состояния Недосягаемости.")
				
				if target.has_meta("dead_or_alive") and target.get_meta("dead_or_alive"):
					target.set_meta("dead_or_alive", false)
					var bonus_mult: float = 3.0
					if attacker.eidolon >= 6:
						bonus_mult += 1.40 
					if attacker.eidolon >= 5:
						bonus_mult *= 1.20 
					var extra_res: Dictionary = calc_dmg(attacker, target, bonus_mult)
					var extra_dmg: float = float(extra_res.get("damage", 0.0))
					deal_damage(target, extra_dmg, attacker, attacker.element, extra_res.crit)
					log_message("Статус «Живым или мёртвым» снят! Враг получил %d доп. урона." % int(extra_dmg))
					
				attacker.set_meta("basic_counter", 0)
				gain_energy_with_err(attacker, 20.0)
				log_message("%s — Усиленная базовая атака по %s: %d (КРИТ!)" % [attacker.display_name, target.display_name, int(final_dmg)])
			else:
				var mult: float = 1.50
				if attacker.eidolon >= 3:
					mult *= 1.20 
					
				var is_doa: bool = target.has_meta("dead_or_alive") and target.get_meta("dead_or_alive")
				var penalty: float = 1.0
				if is_doa:
					if skill_points > 0:
						if attacker.eidolon < 6:
							_spend_skill_points(1) 
					else:
						penalty = 0.30 
						log_message("У Кирилла нет ОН для атак по Живым/Мёртвым! Урон снижен на 70%.")
						
					attacker.set_meta("action_advance_pending", 100.0)
					
				var res: Dictionary = calc_dmg(attacker, target, mult * penalty)
				var normal_dmg: float = float(res.get("damage", 0.0))
				deal_damage(target, normal_dmg, attacker, attacker.element, res.crit)
				ToughnessSystem.apply_weakness_hit(attacker, target, self)
				
				if not is_doa:
					gain_skill_point()
					
				attacker.set_meta("basic_counter", counter + 1)
				gain_energy_with_err(attacker, 20.0)
				log_message("%s — Базовая атака (%d/3) по %s: %d урона." % [attacker.display_name, counter + 1, target.display_name, int(normal_dmg)])
				
		KaoriAbilities.ID:
			var is_enhanced: bool = attacker.get_meta("weakness_concentration", false)
			if is_enhanced:
				var mult: float = 1.50
				if attacker.eidolon >= 3:
					mult *= 1.20 
					
				var extra_efficiency := 0.20
				if attacker.eidolon >= 1:
					extra_efficiency += 0.10
					
				var old_eff := attacker.stats.weakness_efficiency
				attacker.stats.weakness_efficiency += extra_efficiency
				
				var res := calc_dmg(attacker, target, mult)
				deal_damage(target, res.damage, attacker, attacker.element, res.crit)
				ToughnessSystem.apply_weakness_hit(attacker, target, self)
				
				attacker.stats.weakness_efficiency = old_eff
				attacker.set_meta("weakness_concentration", false)
				
				if attacker.eidolon >= 6:
					gain_skill_point()
				
				gain_energy_with_err(attacker, 20.0)
				log_message("%s совершила Усиленную базовую атаку по %s: %d" % [attacker.display_name, target.display_name, int(res.damage)])
			else:
				var mult := 1.0
				if attacker.eidolon >= 3:
					mult *= 1.20
				var res := calc_dmg(attacker, target, mult)
				deal_damage(target, res.damage, attacker, attacker.element, res.crit)
				ToughnessSystem.apply_weakness_hit(attacker, target, self)
				gain_skill_point()
				gain_energy_with_err(attacker, 20.0)
				log_message("%s — Базовая атака по %s: %d" % [attacker.display_name, target.display_name, int(res.damage)])
		"shoji":
			var mult: float = 1.20
			if attacker.eidolon >= 3:
				mult *= 1.20 
				
			if attacker.eidolon >= 1:
				target.set_meta("shoji_fire_res_reduced_turns", 3)
				log_message("Эйдолон 1 Сёдзи: Наложена огненная уязвимость на %s на 3 хода!" % target.display_name)
				
			var res := calc_dmg(attacker, target, mult)
			deal_damage(target, res.damage, attacker, attacker.element, res.crit)
			ToughnessSystem.apply_weakness_hit(attacker, target, self)
			gain_skill_point()
			gain_energy_with_err(attacker, 20.0)
			log_message("%s — Базовая атака по %s: %d" % [attacker.display_name, target.display_name, int(res.damage)])
		"dasha":
			var in_dance: bool = attacker.get_meta("circle_dance", false)
			if in_dance:
				var mult: float = 1.60
				var res := calc_dmg(attacker, target, mult)
				deal_damage(target, res.damage, attacker, attacker.element, res.crit)
				ToughnessSystem.apply_weakness_hit(attacker, target, self, 1.25)
				
				var adjacent := get_adjacent_enemies(target)
				for adj in adjacent:
					var adj_res := calc_dmg(attacker, adj, 0.90)
					deal_damage(adj, adj_res.damage, attacker, attacker.element, adj_res.crit)
					ToughnessSystem.apply_weakness_hit(attacker, adj, self, 0.75)
			else:
				var mult: float = 0.60
				var res := calc_dmg(attacker, target, mult)
				deal_damage(target, res.damage, attacker, attacker.element, res.crit)
				ToughnessSystem.apply_weakness_hit(attacker, target, self)
				gain_skill_point()
				
			gain_energy_with_err(attacker, 20.0)
		"danill":
			var def_val: float = attacker.stats.def
			var stacks: int = int(attacker.get_meta("danill_talent_stacks", 0))
			def_val *= (1.0 + 0.10 * float(stacks))
			
			var mult: float = 0.50 # Занерфлено: 70% -> 50%
			if attacker.eidolon >= 1:
				mult += 0.30 # 80% при Е1
				
			var def_mult := DamageCalculator.calc_def_multiplier(target.stats.def)
			var res := calc_dmg(attacker, target, mult)
			deal_damage(target, res.damage, attacker, attacker.element, res.crit)
			ToughnessSystem.apply_weakness_hit(attacker, target, self)
			gain_skill_point()
			gain_energy_with_err(attacker, 20.0)
			log_message("%s — базовая атака по %s: %d урона от защиты." % [attacker.display_name, target.display_name, int(res.damage)])
		"vika":
			var res := calc_dmg(attacker, target, 0.50)
			deal_damage(target, res.damage, attacker, attacker.element, res.crit)
			ToughnessSystem.apply_weakness_hit(attacker, target, self)
			gain_skill_point()
			gain_energy_with_err(attacker, 20.0)
			log_message("%s — базовая атака по %s: %d урона." % [attacker.display_name, target.display_name, int(res.damage)])
		"dotseva":
			var in_fog := int(attacker.get_meta("dotseva_fog_turns", 0)) > 0
			if in_fog:
				var stacks := int(attacker.get_meta("dotseva_calibration_stacks", 0))
				var living := get_living_enemies()
				
				for enemy in living:
					var res := calc_dmg(attacker, enemy, 0.45)
					var def_mult := DamageCalculator.calc_def_multiplier(enemy.stats.def)
					var res_mult := DamageCalculator.get_res_multiplier(attacker, enemy)
					var total_dmg := float(res.damage) + ((stacks * 40.0) * def_mult * res_mult)
					
					deal_damage(enemy, total_dmg, attacker, attacker.element, res.crit)
					apply_weakness_hit_and_delay(attacker, enemy, self)
					
				gain_energy_with_err(attacker, 20.0)
				log_message("Усиленная базовая атака: %s наносит АоЕ-урон от Калибровки." % attacker.display_name)
			else:
				var res := calc_dmg(attacker, target, 1.10)
				deal_damage(target, res.damage, attacker, attacker.element, res.crit)
				apply_weakness_hit_and_delay(attacker, target, self)
				gain_skill_point()
				gain_energy_with_err(attacker, 20.0)
				log_message("%s — базовая атака по %s: %d урона." % [attacker.display_name, target.display_name, int(res.damage)])
		"milena":
			# ИСПРАВЛЕНО: Безопасное наложение среза через систему словарных дебаффов
			apply_def_reduction(target, "Милена (Базовая)", 0.20, 1)
			
			if attacker.eidolon >= 2:
				target.delay_action(35.0)
				log_message("Э2 Милены: действие %s задержано на 35%%." % target.display_name)
				
			if attacker.eidolon >= 4:
				attacker.advance_action(40.0)
				action_order_changed.emit()
				log_message("Э4 Милены: её собственное действие продвинуто на 40%%.")
				
			gain_skill_point()
			gain_energy_with_err(attacker, 20.0)
			log_message("%s использует базовую атаку на %s: наложен срез защиты −20%% (БЕЗ УРОНА)." % [attacker.display_name, target.display_name])
		"naama":
			NaamaAbilities.execute_basic_attack(attacker, target, self)
		"lenskaya":
			LenskayaAbilities.execute_basic_attack(attacker, target, self)
		"rimes":
			RimesAbilities.execute_basic_attack(attacker, target, self)
		"isaac":
			IsaacAbilities.execute_basic_attack(attacker, target, self)
		"keloist":
			KeloistAbilities.execute_basic_attack(attacker, target, self)
		"musienko":
			MusienkoAbilities.execute_basic_attack(attacker, target, self)
		"joan":
			JoanAbilities.execute_basic_attack(attacker, target, self)
		"jeff":
			JeffAbilities.execute_basic_attack(attacker, target, self)
		"valramors":
			ValramorsAbilities.execute_basic_attack(attacker, target, self)
		"joan_spirit":
			if attacker.get_meta("joan_spirit_form", false) and has_meta("joan_spirit_enhanced_basic_selected"):
				remove_meta("joan_spirit_enhanced_basic_selected")
				JoanSpiritAbilities.execute_enhanced_basic(attacker, target, self)
			else:
				JoanSpiritAbilities.execute_basic_attack(attacker, target, self)
		"isaac_admin":
			var in_hacked := int(attacker.get_meta("isaac_hacked_turns", 0)) > 0
			if in_hacked:
				IsaacAdminAbilities.execute_enhanced_basic(attacker, target, self)
			else:
				IsaacAdminAbilities.execute_basic_attack(attacker, target, self)
		"sara_admin":
			SaraAdminAbilities.execute_basic_attack(attacker, target, self)
		"arseniy_admin":
			ArseniyAdminAbilities.execute_basic_attack(attacker, target, self)
		"dasha_admin":
			DashaAdminAbilities.execute_basic_attack(attacker, target, self)
		"shoji_swan":
			var is_enhanced: bool = bool(attacker.get_meta("shoji_swan_enhanced_basic", false))
			if is_enhanced:
				ShojiSwanAbilities.execute_enhanced_basic(attacker, target, self)
			else:
				ShojiSwanAbilities.execute_basic_attack(attacker, target, self)
		"katarina":
			KatarinaAbilities.execute_basic_attack(attacker, target, self)
		"dotseva_crimson_tears":
			DotsevaCrimsonTearsAbilities.execute_basic_attack(attacker, target, self)
			
			
	# --- ПЕРЕХВАТ ТАЛАНТА ДЖЕФФА ПРИ АТАКАХ СОЮЗНИКОВ ---
	if attacker.id != "jeff" and attacker.is_ally:
		var jeff := get_jeff_unit()
		if jeff and jeff.is_alive() and jeff.get_meta("jeff_make_noise_active", false):
			jeff.set_meta("jeff_make_noise_active", false)
			JeffAbilities.trigger_talent_fua(jeff, target, self)
	finish_attack_recording(attacker)
		
func _execute_skill(attacker: CombatUnit, target: CombatUnit, extra_targets: Array = []) -> void:
	current_attack_action_id += 1
	_last_attacker = attacker
	start_attack_recording(attacker)
	match attacker.id:
		MarinaAbilities.ID:
			var living := get_living_enemies()
			for enemy in living:
				# Условие >50% ХП вырезано по ребалансу, передаем всегда false
				var mult := MarinaAbilities.get_skill_multiplier(attacker.eidolon, false)
				var result := calc_dmg(attacker, enemy, mult)
				deal_damage(enemy, result.damage, attacker, attacker.element, result.crit)
				apply_weakness_hit_and_delay(attacker, enemy)
				ToughnessSystem.on_hit_entanglement(enemy)
				log_message("Навык Q: %d урона по %s%s" % [int(result.damage), enemy.display_name, " (КРИТ!)" if result.crit else ""])
				if attacker.eidolon >= 6:
					MarinaAbilities.apply_suppression(enemy, 1, 2)
			gain_energy_with_err(attacker, 30.0)
			_update_marina_e4()
		SaraAbilities.ID:
			if target == null or not target.is_ally:
				log_message("Выберите союзника!")
				return
			SaraAbilities.execute_skill_q(attacker, target, self)
		ArseniyAbilities.ID:
			if ArseniyAbilities.is_new_development(attacker):
				if target == null or not target.is_ally:
					log_message("Выберите союзника!")
					return
				ArseniyAbilities.execute_skill_q_buff(attacker, target, self)
			else:
				if target == null:
					log_message("Выберите противника!")
					return
				var targets_to_hit: Array[CombatUnit] = [target]
				var adjacent := get_adjacent_enemies(target)
				for adj in adjacent:
					targets_to_hit.append(adj)
				ArseniyAbilities.execute_skill_q_damage(attacker, targets_to_hit, self)
		PusenkovAbilities.ID:
			if target == null or target.is_ally:
				log_message("Выберите врага!")
				return
			PusenkovAbilities.set_target_status(target, "priority", self)
			attacker.set_meta("action_advance_pending", 80.0)
			
			var current_spd_turns: int = int(attacker.get_meta("spd_buff_turns", 0))
			if current_spd_turns == 0:
				attacker.stats.spd += 20.0
			attacker.set_meta("spd_buff_turns", 2)
			
			gain_energy_with_err(attacker, 30.0)
			log_message("%s наложил «Приоритетную Цель» на %s. Кирилл продвинется на 80%% после своего хода." % [attacker.display_name, target.display_name])
			
		KaoriAbilities.ID:
			attacker.set_meta("untargetable", true)
			attacker.set_meta("untargetable_turns", 2)
			attacker.set_meta("in_fog_buff", true)
			gain_energy_with_err(attacker, 30.0)
			log_message("%s ушла «В туман» на 2 хода (Недосягаемость). Следующая атака нанесет на 100%% больше урона." % attacker.display_name)
		"shoji":
			if target == null or target.is_ally:
				log_message("Выберите врага!")
				return
			
			# Кэшируем соседей до нанесения урона и подрыва DoT
			var adjacent := get_adjacent_enemies(target)
			
			# ИСПРАВЛЕНО: Если надет Метаморфоз, накладываем Сияние ПЕРВЫМ делом на цель и соседей до любого урона и взрыва!
			if attacker.get_meta("light_cone_id", "") == "perfect_metamorphosis":
				target.set_meta("radiance_status_turns", 1)
				target.set_meta("radiance_owner", attacker)
				log_message("🦋 Конус Метаморфоза: на %s наложен статус «Сияние» (Горение) на 1 ход." % target.display_name)
				
				# Накладываем на всех живых соседей
				for adj in adjacent:
					if adj.is_alive():
						adj.set_meta("radiance_status_turns", 1)
						adj.set_meta("radiance_owner", attacker)
						log_message("🦋 Конус Метаморфоза: на соседа %s наложен статус «Сияние» (Горение) на 1 ход." % adj.display_name)
			
			var mult: float = 1.60
			if attacker.eidolon >= 3:
				mult *= 1.20 
				
			var res := calc_dmg(attacker, target, mult)
			deal_damage(target, res.damage, attacker, attacker.element, res.crit)
			ToughnessSystem.apply_weakness_hit(attacker, target, self)
			
			# Взрываем DoT на главной цели (Сияние уже наложено!)
			explode_dots(target, attacker, 1.0)
			
			for adj in adjacent:
				if adj.is_alive():
					var adj_res := calc_dmg(attacker, adj, 0.40)
					deal_damage(adj, adj_res.damage, attacker, attacker.element, adj_res.crit)
					ToughnessSystem.apply_weakness_hit(attacker, adj, self)
					
					# Взрываем DoT на соседе (Сияние уже наложено!)
					explode_dots(adj, attacker, 0.40)
					
			gain_energy_with_err(attacker, 20.0)
			log_message("%s — Навык Q по %s: %d урона, взорваны все DoT!" % [attacker.display_name, target.display_name, int(res.damage)])
		"dasha":
			if target == null or target.is_ally:
				log_message("Выберите врага!")
				return
				
			# Кэшируем соседей до нанесения урона
			var adjacent := get_adjacent_enemies(target)
			
			set_meta("current_attack_type", "skill_q")
			attacker.set_meta("dasha_q_breaks", 0)
			
			var mult := 2.0
			var res := calc_dmg(attacker, target, mult)
			deal_damage(target, res.damage, attacker, attacker.element, res.crit)
			# Навык Q Даши по центральной цели: +25% истощения стойкости (1.25x)
			ToughnessSystem.apply_weakness_hit(attacker, target, self, 1.25)
			
			if target.statuses.toughness_broken or target.toughness <= 0.0:
				var s_break := DamageCalculator.calc_super_break_damage(attacker, target, 30.0)
				deal_damage(target, s_break, attacker, attacker.element, false, "Суперпробитие")
				log_message("Суперпробитие по %s! Нанесено %d урона суперпробития." % [target.display_name, int(s_break)])
				
			for adj in adjacent:
				if adj.is_alive():
					var adj_res := calc_dmg(attacker, adj, 2.0)
					deal_damage(adj, adj_res.damage, attacker, attacker.element, adj_res.crit)
					# Навык Q Даши по соседним целям: -25% истощения стойкости (0.75x)
					ToughnessSystem.apply_weakness_hit(attacker, adj, self, 0.75)
					
					if adj.statuses.toughness_broken or adj.toughness <= 0.0:
						var s_break_adj := DamageCalculator.calc_super_break_damage(attacker, adj, 30.0)
						deal_damage(adj, s_break_adj, attacker, attacker.element, false, "Суперпробитие")
						log_message("Суперпробитие по соседу %s! Нанесено %d урона суперпробития." % [adj.display_name, int(s_break_adj)])
					
			var q_breaks: int = int(attacker.get_meta("dasha_q_breaks", 0))
			if q_breaks > 0:
				gain_energy_with_err(attacker, attacker.max_energy * 0.05 * float(q_breaks))
				log_message("След 3 Даши: Восстановлено %d%% энергии за %d пробитых уязвимостей!" % [q_breaks * 5, q_breaks])
				
			set_meta("current_attack_type", "")
			gain_energy_with_err(attacker, 30.0)
		"danill":
			if target == null or not target.is_ally:
				log_message("Выберите союзника!")
				return
			var shield_amount := get_effective_def_complete(attacker) * 0.40 + 300.0 # Занерфлено: 60% -> 40%
			apply_shield(target, shield_amount, 3, "Навык Q Данилла")
			gain_energy_with_err(attacker, 30.0)
			log_message("Навык Q Данилла: На %s наложен щит прочностью %d на 3 хода." % [target.display_name, int(shield_amount)])
		"vika":
			if target == null or target.is_ally:
				log_message("Выберите врага!")
				return
				
			var adjacent := get_adjacent_enemies(target)
			
			var res := calc_dmg(attacker, target, 1.55)
			deal_damage(target, res.damage, attacker, attacker.element, res.crit)
			ToughnessSystem.apply_weakness_hit(attacker, target, self, 1.5)
			
			var hp_dmg_base := attacker.stats.max_hp * 0.20
			for adj in adjacent:
				if adj.is_alive():
					var def_mult := DamageCalculator.calc_def_multiplier(adj.stats.def)
					var final_adj_dmg := hp_dmg_base * def_mult
					deal_damage(adj, final_adj_dmg, attacker, attacker.element, false)
					ToughnessSystem.apply_weakness_hit(attacker, adj, self, 0.5)
					
			gain_energy_with_err(attacker, 30.0)
			log_message("Навык Q: %s нанесла %d квантового урона по %s и задела соседей." % [attacker.display_name, int(res.damage), target.display_name])
		# Внутри _execute_skill() -> match attacker.id:
		# Внутри _execute_skill() -> match attacker.id -> "dotseva":
		# Внутри _execute_skill() -> match attacker.id:
		"dotseva":
			if target == null or target.is_ally:
				log_message("Выберите врага!")
				return
				
			# Кэшируем соседей до нанесения урона
			var adjacent := get_adjacent_enemies(target)
			
			var in_fog := int(attacker.get_meta("dotseva_fog_turns", 0)) > 0
			var stacks := int(attacker.get_meta("dotseva_calibration_stacks", 0))
			
			if in_fog:
				# Усиленный навык Q (1 ОН): наносит всем (Калибровка * 10)% СА + 250
				var mult := (float(stacks) * 10.0) / 100.0
				var living := get_living_enemies()
				var hit_count := 0
				
				for enemy in living:
					hit_count += 1
					var res := calc_dmg(attacker, enemy, mult)
					var def_mult := DamageCalculator.calc_def_multiplier(enemy.stats.def)
					var res_mult := DamageCalculator.get_res_multiplier(attacker, enemy)
					var total_dmg := float(res.damage) + (350.0 * def_mult * res_mult)
					
					deal_damage(enemy, total_dmg, attacker, attacker.element, res.crit)
					apply_weakness_hit_and_delay(attacker, enemy, self)
					
				# Накладываем стаки строго после вычисления и нанесения урона
				if hit_count > 0:
					add_calibration_stacks(attacker, hit_count)
					log_message("След Доцевой: получено +%d стаков Калибровки за %d пораженных целей." % [hit_count, hit_count])
					
				gain_energy_with_err(attacker, 30.0)
			else:
				# ИСПРАВЛЕНО: Обычный навык Q (1 ОН): 165% СА + 300 центру, 80% СА + 50 соседям
				
				# Центр (выбранный противник)
				var res_central := calc_dmg(attacker, target, 1.65)
				var def_mult_c := DamageCalculator.calc_def_multiplier(target.stats.def)
				var res_mult_c := DamageCalculator.get_res_multiplier(attacker, target)
				var final_c := float(res_central.damage) + (300.0 * def_mult_c * res_mult_c)
				
				deal_damage(target, final_c, attacker, attacker.element, res_central.crit)
				apply_weakness_hit_and_delay(attacker, target, self)
				
				# Соседи (смежные цели получают 80% СА + 50)
				for adj in adjacent:
					if adj.is_alive():
						var res_adj := calc_dmg(attacker, adj, 0.80) # Снижено до 80% СА
						var def_mult_a := DamageCalculator.calc_def_multiplier(adj.stats.def)
						var res_mult_a := DamageCalculator.get_res_multiplier(attacker, adj)
						var final_a := float(res_adj.damage) + (50.0 * def_mult_a * res_mult_a)
						
						deal_damage(adj, final_a, attacker, attacker.element, res_adj.crit)
						apply_weakness_hit_and_delay(attacker, adj, self)
						
				gain_energy_with_err(attacker, 30.0)
				log_message("Навык Q: Доцева наносит урон по %s и окружающим врагам." % target.display_name)
		# Внутри _execute_skill() -> match attacker.id:
		"milena":
			# Обновляет Обертон
			if int(attacker.get_meta("milena_overtone_turns", 0)) > 0:
				attacker.set_meta("milena_overtone_turns", 3)
				# ИСПРАВЛЕНО: Взводим флаг пропуска, чтобы ход не списался в конце этого же действия
				attacker.set_meta("milena_overtone_skip_tick", true)
				
			# Энергетический обмен: забирает 10% макс. энергии у союзников и отдает им обратно
			for ally in allies:
				if ally.is_alive() and ally != attacker:
					var steal_val := ally.max_energy * 0.10
					var actual_stolen := minf(ally.energy, steal_val)
					
					ally.energy -= actual_stolen
					gain_energy_with_err(attacker, actual_stolen)
					
					ally.gain_energy(ally.max_energy * 0.10)
					unit_updated.emit(ally)
					
			gain_energy_with_err(attacker, 30.0)
			log_message("Навык Q: %s обновила шкалы энергии союзников и продлила Обертон до 3 ходов." % attacker.display_name)
		"naama":
			NaamaAbilities.execute_skill_q(attacker, target, extra_targets, self)
		"lenskaya":
			LenskayaAbilities.execute_skill_q(attacker, target, extra_targets, self)
		"rimes":
			RimesAbilities.execute_skill_q(attacker, target, extra_targets, self)
		"isaac":
			IsaacAbilities.execute_skill_q(attacker, target, extra_targets, self)
		"keloist":
			KeloistAbilities.execute_skill_q(attacker, target, extra_targets, self)
		"musienko":
			MusienkoAbilities.execute_skill_q(attacker, target, extra_targets, self)
		"joan":
			JoanAbilities.execute_skill_q(attacker, target, self)
		"jeff":
			JeffAbilities.execute_skill_q(attacker, target, self)
		"valramors":
			ValramorsAbilities.execute_skill_q(attacker, target, self)
		"joan_spirit":
			JoanSpiritAbilities.execute_skill_q(attacker, self)
		"isaac_admin":
			var in_hacked := int(attacker.get_meta("isaac_hacked_turns", 0)) > 0
			if in_hacked:
				IsaacAdminAbilities.execute_enhanced_skill_q(attacker, target, self)
			else:
				IsaacAdminAbilities.execute_skill_q(attacker, target, self)
		"sara_admin":
			SaraAdminAbilities.execute_skill_q(attacker, self)
		"arseniy_admin":
			ArseniyAdminAbilities.execute_skill_q(attacker, target, self)
		"dasha_admin":
			DashaAdminAbilities.execute_skill_q(attacker, self)
		"shoji_swan":
			ShojiSwanAbilities.execute_skill_q(attacker, target, self)
		"katarina":
			KatarinaAbilities.execute_skill_q(attacker, target, self)
		"dotseva_crimson_tears":
			DotsevaCrimsonTearsAbilities.execute_skill_q(attacker, target, self)
	finish_attack_recording(attacker)

func _execute_skill_e(attacker: CombatUnit, target: CombatUnit) -> void:
	current_attack_action_id += 1
	start_attack_recording(attacker)
	match attacker.id:
		MarinaAbilities.ID:
			var living := get_living_enemies()
			var is_dot := attacker.eidolon >= 1
			# Накладывает 1 уровень Подавления на всех на 3 хода
			for enemy in living:
				MarinaAbilities.apply_suppression(enemy, 1, 3, is_dot)
				enemy.statuses.dot_pending_marina_proc = true
				
			log_message("Навык E: На всех врагов наложено Подавление на 3 хода.")
			gain_energy_with_err(attacker, 25.0)
			_update_marina_e4()
		SaraAbilities.ID:
			if target == null or not target.is_ally:
				log_message("Выберите союзника!")
				return
			SaraAbilities.execute_skill_e(attacker, target, self)
		ArseniyAbilities.ID:
			ArseniyAbilities.execute_skill_e(attacker, self)
		# Внутри _execute_skill_e() -> match attacker.id:
		PusenkovAbilities.ID:
			if target == null or target.is_ally:
				log_message("Выберите противника!")
				return
			var mult: float = 0.70
			if attacker.eidolon >= 3:
				mult *= 1.20 
				
			# ИСПРАВЛЕНО: Безопасное наложение среза Кирилла через словарный хелпер
			apply_def_reduction(target, "Кирилл (Навык E)", 0.40, 1)
			
			var result: Dictionary = calc_dmg(attacker, target, mult)
			var skill_dmg: float = float(result.get("damage", 0.0))
			deal_damage(target, skill_dmg, attacker, attacker.element, result.crit)
			apply_weakness_hit_and_delay(attacker, target, self)
			
			target.delay_action(65.0) 
			gain_energy_with_err(attacker, 30.0)
			log_message("%s — Навык E по %s: %d урона." % [attacker.display_name, target.display_name, int(skill_dmg)])
			
		KaoriAbilities.ID:
			if target == null or target.is_ally:
				log_message("Выберите противника!")
				return
				
			var is_enhanced: bool = (target == (attacker.get_meta("e_shuriken_target") if attacker.has_meta("e_shuriken_target") else null))
			var mult: float = 0.0
			var extra_efficiency := 0.0
			
			if is_enhanced:
				mult = 1.00 * attacker.get_effective_be() + 1.00
				extra_efficiency = 0.20
				attacker.set_meta("e_shuriken_target", null)
				log_message("Каори применила Усиленный Навык E. Метка сюрикена снята.")
			else:
				mult = 0.50 * attacker.get_effective_be() + 0.30
				attacker.set_meta("e_shuriken_target", target) 
				
			if attacker.eidolon >= 3:
				mult *= 1.20 
				
			var old_eff := attacker.stats.weakness_efficiency
			attacker.stats.weakness_efficiency += extra_efficiency
			
			var result := calc_dmg(attacker, target, mult)
			deal_damage(target, result.damage, attacker, attacker.element, result.crit)
			ToughnessSystem.apply_weakness_hit(attacker, target, self)
			
			attacker.stats.weakness_efficiency = old_eff
			gain_energy_with_err(attacker, 30.0)
			log_message("%s бросила сюрикен в %s: %d урона." % [attacker.display_name, target.display_name, int(result.damage)])
		# Внутри _execute_skill_e() -> match attacker.id:
		"shoji":
			if target == null or target.is_ally:
				log_message("Выберите врага!")
				return
			
			var adjacent := get_adjacent_enemies(target)
			
			var mult: float = 0.70
			if attacker.eidolon >= 3:
				mult *= 1.20 
				
			var res := calc_dmg(attacker, target, mult)
			deal_damage(target, res.damage, attacker, attacker.element, res.crit)
			ToughnessSystem.apply_weakness_hit(attacker, target, self)
			
			# Наложение Горения на главную цель по формуле ШПЭ (Базовый шанс 100%)
			if NaamaAbilities.roll_debuff(1.00, attacker, target, self):
				var current_turns_t := int(target.get_meta("shoji_burn_turns", 0))
				target.set_meta("shoji_burn_stacks", 1)
				target.set_meta("shoji_burn_turns", maxi(current_turns_t, 3))
				log_message("%s получил Горение Сёдзи на 3 хода." % target.display_name)
			
			# Наложение Горения на соседей (Базовый шанс 100%)
			for adj in adjacent:
				if adj.is_alive():
					var adj_res := calc_dmg(attacker, adj, 0.30)
					deal_damage(adj, adj_res.damage, attacker, attacker.element, adj_res.crit)
					ToughnessSystem.apply_weakness_hit(attacker, adj, self)
					
					if NaamaAbilities.roll_debuff(1.00, attacker, adj, self):
						var current_turns_a := int(adj.get_meta("shoji_burn_turns", 0))
						adj.set_meta("shoji_burn_stacks", 1)
						adj.set_meta("shoji_burn_turns", maxi(current_turns_a, 3))
						log_message("Сосед %s получил Горение Сёдзи на 3 хода." % adj.display_name)
			gain_energy_with_err(attacker, 15.0)
		"dasha":
			attacker.set_meta("circle_dance", true)
			log_message("%s входит в состояние «Танец кругов»." % attacker.display_name)
			
			if attacker.eidolon >= 1:
				attacker.statuses.self_atk_buff_percent += 0.20
				attacker.set_meta("dasha_e1_turns", 3)
				log_message("Эйдолон 1 Даши: Сила атаки увеличена на 20%% на 3 хода.")
				
			gain_energy_with_err(attacker, 30.0)
			
			# ИСПРАВЛЕНО: Даша мгновенно проводит бонус-атаку (взмах таланта) при входе в Танец кругов
			execute_dasha_bonus_attack(attacker)
		"danill":
			var shield_amount := get_effective_def_complete(attacker) * 0.50 + 400.0 # Занерфлено: 100% + 500 -> 50% + 400
			apply_shield(attacker, shield_amount, 3, "Навык E Данилла")
			attacker.set_meta("e_shield_active", true)
			
			attacker.set_meta("danill_taunt_turns", 3)
			gain_energy_with_err(attacker, 30.0)
			log_message("Навык E: Данилл наложил на себя щит %d, вошел в Провокацию на 3 хода и снизил входящий урон союзников на 30%%." % int(shield_amount))
		"vika":
			var current_hp := attacker.stats.hp
			var max_hp := attacker.stats.max_hp
			var lost_hp := 0.0
			
			if attacker.get_hp_ratio() <= 0.50:
				lost_hp = current_hp - 1.0
				attacker.stats.hp = 1.0
			else:
				lost_hp = current_hp * 0.50
				attacker.stats.hp = current_hp - lost_hp
				
			unit_updated.emit(attacker)
			
			# Навешиваем бафф СА
			var atk_buff := lost_hp * 0.50
			var current_buff := float(attacker.get_meta("vika_e_atk_buff", 0.0))
			attacker.set_meta("vika_e_atk_buff", current_buff + atk_buff)
			attacker.set_meta("vika_e_atk_turns", 4)
			
			# След 1: Продлевает "Пробуждение" на 2 хода
			var awk_t := int(attacker.get_meta("vika_awakening_turns", 0))
			if awk_t > 0:
				attacker.set_meta("vika_awakening_turns", awk_t + 2)
				log_message("След Вики: Состояние «Пробуждение» продлено на 2 хода.")
				
			attacker.advance_action(50.0)
			action_order_changed.emit()
			gain_energy_with_err(attacker, 30.0)
			log_message("Навык E: %s потратила %d ХП. СА увеличена на +%d на 3 хода. Действие продвинуто на 50%%." % [attacker.display_name, int(lost_hp), int(atk_buff)])
			trigger_accepted_sin_hp_loss(current_unit)
		"dotseva":
			var in_fog := int(attacker.get_meta("dotseva_fog_turns", 0)) > 0
			if in_fog:
				if attacker.eidolon >= 6:
					# Е6: Все уже имеют статус Должника, поэтому выбираем 1 цель под Shared DMG
					if target == null or target.is_ally:
						log_message("Выберите врага!")
						return
					for enemy in enemies:
						if enemy.has_meta("dotseva_e6_shared_target"):
							enemy.remove_meta("dotseva_e6_shared_target")
					target.set_meta("dotseva_e6_shared_target", true)
					log_message("Э6 Доцевой: %s выбран главной целью. Весь получаемый им урон копируется соседям!" % target.display_name)
				else:
					# ИСПРАВЛЕНО: статус 'Должник' теперь вечный (без ограничения по ходам)
					if target == null or target.is_ally:
						log_message("Выберите врага!")
						return
					target.set_meta("dotseva_debtor_status", true)
					
					var adjacent := get_adjacent_enemies(target)
					for adj in adjacent:
						adj.set_meta("dotseva_debtor_status", true)
					log_message("Усиленный Навык E: На %s и соседей наложен статус Должника." % target.display_name)
			else:
				# Обычный навык 2 (2 ОН): Калибровка +5 стаков, Бонус-атака без сброса стаков
				add_calibration_stacks(attacker, 5)
				
				var living := get_living_enemies()
				for enemy in living:
					# ИСПРАВЛЕНО: урон бонус-атаки занерфлен до 100% СА (вместо 180% СА)
					var res := calc_dmg(attacker, enemy, 1.00, 0.0, false, 0.0, 0.0, false, true, "Бонус-атака")
					var def_mult := DamageCalculator.calc_def_multiplier(enemy.stats.def)
					var res_mult := DamageCalculator.get_res_multiplier(attacker, enemy)
					var total_dmg := float(res.damage) + (300.0 * def_mult * res_mult)
					
					deal_damage(enemy, total_dmg, attacker, attacker.element, res.crit, "Бонус-атака")
				log_message("Навык E: Доцева получила +5 стаков Калибровки и провела бонус-атаку по всем целям.")
			gain_energy_with_err(attacker, 30.0)
		"milena":
			attacker.set_meta("milena_overtone_turns", 3)
			if current_unit == attacker:
				attacker.set_meta("milena_overtone_skip_tick", true)
				
			update_milena_overtone_spd_buff(attacker, true)
			gain_energy_with_err(attacker, 50.0)
			log_message("Навык E: Милена активирует «Обертон» на 3 хода. Сила атаки союзников повышена на 30%% от СА Милены, а скорость на 15%%.")
			unit_updated.emit(attacker)
		"naama":
			NaamaAbilities.execute_skill_e(attacker, target, self)
		"lenskaya":
			LenskayaAbilities.execute_skill_e(attacker, target, self)
		"rimes":
			RimesAbilities.execute_skill_e(attacker, target, self)
			if target != null and target.id == "masked_silhouette" and target.has_meta("mask_layers"):
				target.remove_meta("mask_layers")
				target.set_meta("silhouette_mask_def_buff", 0.0)
				apply_def_reduction(target, "Разоблачение Силуэта", 0.20, 99)
				
				log_message("🎭 Тайна сияющей маски: Раймс затянул Силуэт в Изоляцию! Маска мгновенно уничтожена. Защита Силуэта снижена на -20%% до конца боя!")
				unit_updated.emit(target)
		"isaac":
			IsaacAbilities.execute_skill_e(attacker, target, self)
		"keloist":
			KeloistAbilities.execute_skill_e(attacker, target, self)
		"musienko":
			MusienkoAbilities.execute_skill_e(attacker, target, self)
		"joan":
			JoanAbilities.execute_skill_e(attacker, target, self)
		"jeff":
			JeffAbilities.execute_skill_e(attacker, target, self)
		"valramors":
			ValramorsAbilities.execute_skill_e(attacker, target, self)
		"joan_spirit":
			JoanSpiritAbilities.execute_skill_e(attacker, self)
		"isaac_admin":
			IsaacAdminAbilities.execute_skill_e(attacker, target, self)
		"sara_admin":
			SaraAdminAbilities.execute_skill_e(attacker, self)
		"arseniy_admin":
			ArseniyAdminAbilities.execute_skill_e(attacker, self, false)
		"dasha_admin":
			DashaAdminAbilities.execute_skill_e(attacker, self)
		"shoji_swan":
			ShojiSwanAbilities.execute_skill_e(attacker, self)
		"katarina":
			KatarinaAbilities.execute_skill_e(attacker, self)
		"dotseva_crimson_tears":
			DotsevaCrimsonTearsAbilities.execute_skill_e(attacker, target, self)
	finish_attack_recording(attacker)
			
func _execute_ultimate(attacker: CombatUnit, target: CombatUnit) -> void:
	start_attack_recording(attacker)
	set_meta("current_action_key", "ultimate") # ДОБАВЛЕНО: Фиксируем каст ультимейта на менеджере
	attacker.set_meta("is_casting_ultimate", true)
	_last_attacker = attacker

	if battle_mode == "level_16" and attacker.is_ally:
		attacker.advance_action(25.0)
		action_order_changed.emit()
		log_message("⚡ Аномалия уровня 16: Активация Сверхспособности продвинула действие %s на 25%%!" % attacker.display_name)
	elif battle_mode == "dungeon_dam" and attacker.is_ally:
		attacker.advance_action(30.0)
		action_order_changed.emit()
		log_message("🌊 Аномалия «Стремительный поток»: Сверхспособность продвинула действие %s на 30%%!" % attacker.display_name)
	
	# След 3 Арсения Админа: Если любой союзник тратит >200 энергии на ульту (Айзек тратит 250)
	var ars_admin := get_arseniy_admin_unit()
	if ars_admin and ars_admin.is_alive() and attacker.is_ally:
		if attacker.max_energy > 200.0:
			for enemy in get_living_enemies():
				if enemy.is_alive():
					enemy.set_meta("arseniy_trace3_vuln_turns", 3)
					enemy.set_meta("arseniy_trace3_vuln_skip_tick", true)
			log_message("⚡ След 3 Арсения: %s потратил >200 энергии на Сверхспособность! Все враги получают +30%% уязвимости ко ВСЕМУ урону на 3 хода." % attacker.display_name)
	
	var isaac_ref := get_isaac_unit()
	if isaac_ref and isaac_ref.is_alive():
		IsaacAbilities.add_theory_stacks(isaac_ref, 1, self)
		
	if attacker.is_ally and attacker.get_meta("light_cone_id", "") == "echoes_of_the_past":
		# Восстановление 15% ХП
		var heal_amt: float = attacker.stats.max_hp * 0.15
		heal_unit(attacker, heal_amt)
		
		# Увеличение скорости на 40% на 2 хода (сбрасываем старый модификатор при быстром перекасте)
		if attacker.has_meta("echoes_spd_buff_turns") and int(attacker.get_meta("echoes_spd_buff_turns", 0)) > 0:
			attacker.remove_speed_modifier(0.40, 0.0)
			
		attacker.add_speed_modifier(0.40, 0.0)
		attacker.set_meta("echoes_spd_buff_turns", 2)
		attacker.set_meta("echoes_spd_buff_skip_tick", true)
		log_message("Конус «Отголоски прошлого»: %s безусловно восстановил 15%% ХП и ускорился на 40%% за активацию ульты!" % attacker.display_name)

	if attacker.is_ally and attacker.get_meta("light_cone_id", "") == "first_minutes_of_war":
		var heal_amt: float = attacker.stats.max_hp * 0.20
		heal_unit(attacker, heal_amt)
		log_message("Конус «Первые минуты войны»: %s восстановил 20%% макс. ХП (%d) после Сверхспособности." % [attacker.display_name, int(heal_amt)])
	
	# --- СЕТ ИССЛЕДОВАТЕЛЯ БУДУЩЕГО (4ч) ---
	if attacker.is_ally and attacker.has_meta("set_bereft_future_4"):
		var targets_ally: bool = false
		if target != null and target.is_ally and target != attacker:
			targets_ally = true
		elif attacker.id in ["danill", "milena", "jeff", "sara_admin"]:
			targets_ally = true
			
		if targets_ally:
			log_message("🌪 Сет Исследователя отнятого будущего: %s ускорил команду на +12%% на 1 ход!" % attacker.display_name)
			for ally in allies:
				if ally.is_alive():
					if ally.has_meta("relic_bereft_spd_turns") and int(ally.get_meta("relic_bereft_spd_turns", 0)) > 0:
						ally.remove_speed_modifier(0.12, 0.0)
						
					ally.add_speed_modifier(0.12, 0.0)
					ally.set_meta("relic_bereft_spd_turns", 1)
					
					# ИСПРАВЛЕНО: skip_tick равен true ТОЛЬКО для самого активного ультующего героя!
					if ally == attacker:
						ally.set_meta("relic_bereft_spd_skip_tick", true)
					else:
						ally.set_meta("relic_bereft_spd_skip_tick", false)
						
					ally.recalculate_action_value()
			action_order_changed.emit()
	
	if attacker.get_meta("light_cone_id", "") == "concert_dead":
		if attacker.id == "jeff": # Массовая ульта Джеффа накладывает статус на ВСЕХ союзников
			for ally in allies:
				if ally.is_alive():
					ally.set_meta("stage_partner_turns", 2)
					ally.set_meta("stage_partner_skip_tick", true)
			log_message("🎭 Конус «Концерт для мертвецов»: Сверхспособность Джеффа наложила статус «Партнёр по сцене» (+15%% СА, +15%% лечения) на всех союзников на 2 хода!")
		elif target != null and target.is_ally: # Одиночный выбор союзника
			target.set_meta("stage_partner_turns", 2)
			target.set_meta("stage_partner_skip_tick", true)
			log_message("🎭 Конус «Концерт для мертвецов»: На %s наложен статус «Партнёр по сцене» (+15%% СА, +15%% лечения) на 2 хода!" % target.display_name)
		# Сара не выбирает союзников, а открывает зону, поэтому на неё статус не накладывается, как вы и просили!

	# 3. КОНУС «ПАЛЯЩИЙ ВЗОР»: Бафф следующего Навыка Е на +30%
	if attacker.get_meta("light_cone_id", "") == "scorching_gaze":
		attacker.set_meta("scorching_gaze_next_e_buff", true)
		log_message("🔥 Конус «Палящий взор»: Урон следующего Навыка Е %s будет повышен на +30%%!" % attacker.display_name)

	# 4. КОНУС «СОЛНЦЕ, ЧТО ЗАТМЕВАЕТ ЛУНУ»: Статус «Пылающее солнце» (+40% СА на 3 хода)
	if attacker.get_meta("light_cone_id", "") == "sun_eclipses_moon":
		attacker.set_meta("blazing_sun_turns", 3)
		attacker.set_meta("blazing_sun_skip_tick", true)
		log_message("☀ Конус «Солнце, затмевающее луну»: %s получил статус «Пылающее солнце» (+40%% СА на 3 хода)!" % attacker.display_name)
				
	# ИСПРАВЛЕНО: Глобальная активация конуса «Басня...» для любого владельца при ульте
	if attacker.get_meta("light_cone_id", "") == "crimson_tears":
		attacker.add_speed_modifier(0.40, 0.0)
		attacker.set_meta("crimson_tears_spd_turns", 3)
		attacker.set_meta("crimson_tears_spd_skip_tick", true)
		log_message("Конус «Басня...»: Сверхспособность активирована! Скорость %s повышен на +40%% на 2 хода." % attacker.display_name)
		
	# ИСПРАВЛЕНО: Конус «Я не могу тебя убить» восстанавливает 1 ОД с шансом 80% при касте ульты (даже без выбранной цели)
	if attacker.get_meta("light_cone_id", "") == "cant_kill_you":
		if target != null:
			target.set_meta("cant_kill_you_crit_boost_" + attacker.id, true)
		else:
			for enemy in get_living_enemies():
				enemy.set_meta("cant_kill_you_crit_boost_" + attacker.id, true)
				
		if randf() < 0.80:
			gain_skill_point()
			log_message("🎯 Конус «Я не могу тебя убить»: Сверхспособность восстановила 1 ОД!")

	# Конус «Поместить в карантин»: продвижение действий всех союзников на 24%
	if attacker.get_meta("light_cone_id", "") == "quarantine":
		for ally in allies:
			if ally.is_alive():
				if ally == current_unit:
					ally.set_meta("action_advance_pending", float(ally.get_meta("action_advance_pending", 0.0)) + 24.0)
				else:
					ally.advance_action(24.0)
		action_order_changed.emit()
		log_message("🛡 Конус «Поместить в карантин»: Сверхспособность %s продвинула действия всех союзников на 24%%!" % attacker.display_name)

	# Конус «Повреждённое сохранение»: использование Сверхспособности на союзнике даёт статус «Погружение» на 3 хода
	if attacker.get_meta("light_cone_id", "") == "corrupted_save":
		var targets_ally: bool = (target != null and target.is_ally) or attacker.id in ["danill", "milena", "jeff", "sara_admin", "sara"]
		if targets_ally:
			attacker.set_meta("immersion_turns", 3)
			attacker.set_meta("immersion_skip_tick", true)
			log_message("🌊 Конус «Повреждённое сохранение»: %s применил Сверхспособность на союзника и получил статус «Погружение» на 3 хода!" % attacker.display_name)

	# Конус «Момент, когда падают сервера»: даёт владельцу статус «Рефакторинг» на 3 хода
	if attacker.get_meta("light_cone_id", "") == "server_crash_moment":
		attacker.set_meta("refactoring_turns", 3)
		attacker.set_meta("refactoring_skip_tick", true)
		log_message("⚙ Конус «Момент, когда падают сервера»: %s получил статус «Рефакторинг» на 3 хода!" % attacker.display_name)
	
	# --- СЕТЫ РЕЛИКВИЙ ПРИ АКТИВАЦИИ СВЕРХСПОСОБНОСТИ ---
	
	# Принявший дар света (4 части): лечит 25% от макс ХП за ульту
	if attacker.has_meta("set_light_gift_4"):
		var heal_amt: float = attacker.stats.max_hp * 0.25
		heal_unit(attacker, heal_amt)
		log_message("⚡ Сет Дара Света (4ч): %s восстановил %d ХП за ульту!" % [attacker.display_name, int(heal_amt)])
		
	# Дающий луч надежды путник (4 части): вешает бафф +12% на следующую атаку
	if attacker.has_meta("set_hope_beam_4"):
		attacker.set_meta("hope_beam_ult_buff", true)
		
	# Отряд быстрого реагирования (4 части): продвигает действие на 25% за ульту
	if attacker.has_meta("set_rapid_response_4"):
		attacker.advance_action(25.0)
		log_message("🌪 Сет Отряда быстрого реагирования (4ч): действие %s продвинуто на 25%%!" % attacker.display_name)
		action_order_changed.emit()
		
	match attacker.id:
		MarinaAbilities.ID:
			var living := get_living_enemies()
			var is_dot := attacker.eidolon >= 1
			for enemy in living:
				# 1. Применяем Подавление ПЕРВЫМ делом, чтобы снизить скорость цели до расчёта урона.
				# Это гарантирует, что конус «Мгновение счастья» зафиксирует замедление и даст +25% урона.
				MarinaAbilities.apply_suppression(enemy, 1, 3, is_dot)
				if is_dot:
					enemy.statuses.dot_pending_marina_proc = true
				
				# 2. Рассчитываем урон (скорость цели уже снижена дебаффом Подавления)
				var mult := MarinaAbilities.get_ult_multiplier(attacker.eidolon, living.size(), enemy.is_elite)
				var result := calc_dmg(attacker, enemy, mult, 0.0, false, 0.0, 0.0, true) 
				
				# 3. Наносим урон Сверхспособности
				deal_damage(enemy, result.damage, attacker, attacker.element, result.crit)
				
				# 4. Пробиваем стойкость и накладываем Связывание
				apply_weakness_hit_and_delay(attacker, enemy, self)
				ToughnessSystem.on_hit_entanglement(enemy)
				
				log_message("Сверхспособность: %d урона по %s" % [int(result.damage), enemy.display_name])
			_update_marina_e4()
		SaraAbilities.ID:
			SaraAbilities.execute_ultimate(attacker, self)
		ArseniyAbilities.ID:
			if target == null or target.is_ally:
				log_message("Выберите противника!")
				return
			ArseniyAbilities.execute_ultimate(attacker, target, self) 
		PusenkovAbilities.ID:
			if target == null or target.is_ally:
				log_message("Выберите противника!")
				return
			attacker.set_meta("untargetable", true)
			if target.has_meta("priority_target") and target.get_meta("priority_target"):
				PusenkovAbilities.set_target_status(target, "dead_or_alive", self)
				log_message("Сверхспособность: Статус %s повышен до «Живым или мёртвым»!" % target.display_name)
			else:
				PusenkovAbilities.set_target_status(target, "priority", self)
				log_message("Сверхспособность: %s помечен как «Приоритетная Цель»!" % target.display_name)
			log_message("%s перешел в состояние Недосягаемости." % attacker.display_name)
			
		KaoriAbilities.ID:
			if target == null or target.is_ally:
				log_message("Выберите противника!")
				return
				
			var recast_window: int = int(attacker.get_meta("ult_recast_window", 0))
			var mult: float = 0.0
			var tgh_mult := 1.0
			
			if recast_window > 0:
				mult = 1.00 * attacker.get_effective_be() + 1.00
				attacker.set_meta("ult_recast_window", 0) 
				tgh_mult = 1.5 
				log_message("Каори производит бесплатное повторное применение сверхспособности!")
			else:
				mult = 1.00 * attacker.get_effective_be() + 1.00
				attacker.set_meta("ult_recast_window", 2) 
				
			if attacker.eidolon >= 5:
				mult *= 1.20 
				
			var result := calc_dmg(attacker, target, mult, 0.0, false, 0.0, 0.0, true) 
			deal_damage(target, result.damage, attacker, attacker.element, result.crit)
			
			ToughnessSystem.apply_weakness_hit(attacker, target, self, tgh_mult)
			gain_energy_with_err(attacker, 5.0)
		# Внутри _execute_ultimate() -> match attacker.id:
		"shoji":
			var living := get_living_enemies()
			var mult: float = 1.30
			if attacker.eidolon >= 5:
				mult *= 1.20 
				
			for enemy in living:
				# 1. ПЕРВЫМ ДЕЛОМ: Накладываем статус «Сияния» от конуса Метаморфоза
				if attacker.get_meta("light_cone_id", "") == "perfect_metamorphosis":
					enemy.set_meta("radiance_status_turns", 1)
					enemy.set_meta("radiance_owner", attacker)
					log_message("🦋 Конус Метаморфоза: на %s наложен статус «Сияние» (Горение) на 1 ход." % enemy.display_name)
					
				# 2. Накладываем/обновляем стандартное Горение Сёдзи по формуле ШПЭ (Базовый шанс 100%, 2 хода)
				if NaamaAbilities.roll_debuff(1.00, attacker, enemy, self):
					var current_turns := int(enemy.get_meta("shoji_burn_turns", 0))
					enemy.set_meta("shoji_burn_stacks", 1)
					enemy.set_meta("shoji_burn_turns", maxi(current_turns, 2))
					log_message("%s получил Горение Сёдзи на 2 хода." % enemy.display_name)
				
				# 3. Наносим прямой урон Сверхспособности Сёдзи
				var res := calc_dmg(attacker, enemy, mult, 0.0, false, 0.0, 0.0, true)
				deal_damage(enemy, res.damage, attacker, attacker.element, res.crit)
				ToughnessSystem.apply_weakness_hit(attacker, enemy, self, 1.2)
				
				# 4. И только ПОСЛЕ этого производим подрыв всех DoT-эффектов!
				explode_dots(enemy, attacker, 1.0)
				
				if enemy.statuses.break_status != "":
					enemy.statuses.break_status_turns = 3
				if enemy.statuses.suppression_stacks > 0:
					enemy.statuses.suppression_turns = 2
					
			gain_energy_with_err(attacker, 5.0)
			log_message("%s применила Сверхспособность: %d ультимативного урона по всем, DoT-эффекты обновлены и подорваны!" % [attacker.display_name, int(mult * attacker.stats.atk)])
		"dasha":
			var current_hp_ratio := attacker.get_hp_ratio()
			var lost_hp := 0.0
			
			if current_hp_ratio <= 0.30:
				var target_hp := attacker.stats.max_hp * 0.01
				lost_hp = maxf(attacker.stats.hp - target_hp, 0.0)
				attacker.stats.hp = target_hp
			else:
				var damage_self := attacker.stats.max_hp * 0.30
				lost_hp = attacker.stats.take_damage(damage_self)
				
			unit_updated.emit(attacker)
			
			if attacker.get_meta("circle_dance", false):
				if attacker.stats.hp < attacker.stats.max_hp * 0.20:
					attacker.set_meta("circle_dance", false)
					log_message("Внимание! Здоровье Даши упало ниже 20%%! Состояние «Танец кругов» автоматически сброшено.")
			
			attacker.set_meta("overload_turns", 2)
			attacker.set_meta("overload_skip_tick", true) 
			log_message("%s применила Сверхспособность, потеряв %d ХП (напрямую в обход щитов), и вошла в состояние «Перегрузка» на 2 хода!" % [attacker.display_name, int(lost_hp)])
			gain_energy_with_err(attacker, 5.0)
			trigger_accepted_sin_hp_loss(attacker)
		"danill":
			var mult_e2 := 1.20 if attacker.eidolon >= 2 else 1.00 
			var shield_amount := (get_effective_def_complete(attacker) * 0.25 + 300.0) * mult_e2 # Занерфлено: 40% + 400 -> 25% + 300
			
			for ally in allies:
				if ally.is_alive():
					apply_shield(ally, shield_amount, 3, "Ульта Данилла")
			gain_energy_with_err(attacker, 5.0)
			log_message("Сверхспособность: Наложен массовый щит %d на всех союзников на 3 хода." % int(shield_amount))
		"vika":
			if target == null or target.is_ally:
				log_message("Выберите врага!")
				return
				
			# E2 Крит. шанс
			if attacker.eidolon >= 2:
				if not attacker.has_meta("vika_e2_active") or not bool(attacker.get_meta("vika_e2_active")):
					attacker.set_meta("vika_e2_active", true)
					attacker.stats.crit_rate += 0.30
					log_message("Э2: крит. шанс Вики повышен на +30%% на 2 хода!")
				else:
					log_message("Э2: длительность баффа крит. шанса Вики обновлена!")
				attacker.set_meta("vika_e2_turns", 2)
				if current_unit == attacker:
					attacker.set_meta("vika_e2_skip_tick", true)
				
			var adjacent := get_adjacent_enemies(target)
			
			# Центр: 280% СА + 30% макс. ХП
			var base_dmg_central := calc_dmg(attacker, target, 2.80, 0.0, false, 0.0, 0.0, true)
			var hp_addition_central := attacker.stats.max_hp * 0.30
			var def_mult_central := DamageCalculator.calc_def_multiplier(target.stats.def)
			# ИСПРАВЛЕНО: Приведение к float для исключения ошибок нетипизированного словаря (Variant)
			var final_central: float = float(base_dmg_central.get("damage", 0.0)) + (hp_addition_central * def_mult_central)
			
			deal_damage(target, final_central, attacker, attacker.element, base_dmg_central.get("crit", false))
			ToughnessSystem.apply_weakness_hit(attacker, target, self, 1.5)
			
			# Соседи: 50% СА + 30% макс. ХП
			var hp_addition_adj := attacker.stats.max_hp * 0.30
			for adj in adjacent:
				if adj.is_alive():
					var base_dmg_adj := calc_dmg(attacker, adj, 0.50, 0.0, false, 0.0, 0.0, true)
					var def_mult_adj := DamageCalculator.calc_def_multiplier(adj.stats.def)
					# ИСПРАВЛЕНО: Приведение к float для исключения ошибок нетипизированного словаря (Variant)
					var final_adj: float = float(base_dmg_adj.get("damage", 0.0)) + (hp_addition_adj * def_mult_adj)
					deal_damage(adj, final_adj, attacker, attacker.element, base_dmg_adj.get("crit", false))
					ToughnessSystem.apply_weakness_hit(attacker, adj, self, 1.0)
					
			# След 2: Снимает все дебаффы при входе в состояние "Пробуждение"
			attacker.statuses.cleanse_all()
			log_message("След Вики: Сняты все дебаффы с %s!" % attacker.display_name)
			
			# Переход в Пробуждение
			var current_awk := int(attacker.get_meta("vika_awakening_turns", 0))
			attacker.set_meta("vika_awakening_turns", maxi(current_awk, 2))
			if current_unit == attacker:
				attacker.set_meta("vika_awk_skip_tick", true)
				
			gain_energy_with_err(attacker, 5.0)
			log_message("Сверхспособность: %s нанесла урон по %s и перешла в состояние «Пробуждение» на 2 хода!" % [attacker.display_name, target.display_name])
		"dotseva":
			var turns := 3 if attacker.eidolon >= 1 else 2
			
			attacker.set_meta("dotseva_fog_turns", turns)
			if current_unit == attacker:
				attacker.set_meta("dotseva_fog_skip_tick", true)
				
			log_message("Сверхспособность: Доцева переходит в состояние «Лёгкий туман» на %d х. Способности усилены!" % turns)
			gain_energy_with_err(attacker, 5.0)
		"milena":
			log_message("⚡ СВЕРХСПОСОБНОСТЬ МИЛЕНЫ")
			
			for ally in allies:
				if ally.is_alive() and ally != attacker:
					var is_doomed := ally.id in ["arseniy", "dasha", "shoji", "danill", "naama", "rimes", "musienko", "jeff", "valramors"]
					
					# Е6: Сверхспособность теперь восстанавливает энергию любых союзников (но активирует лишь если они Обреченные)
					if is_doomed or attacker.eidolon >= 6:
						ally.gain_energy(ally.max_energy)
						unit_updated.emit(ally)
						
					if is_doomed:
						# Е1: Атакующие Сверхспобности Обречённых, активированные Миленой, игнорируют 10% сопротивления
						if attacker.eidolon >= 1:
							ally.set_meta("milena_e1_res_pen", 0.10)
							
						queue_ultimate(ally)
						
			gain_energy_with_err(attacker, 5.0)
		"naama":
			NaamaAbilities.execute_ultimate(attacker, target, self)
		"lenskaya":
			LenskayaAbilities.execute_ultimate(attacker, target, self)
		"rimes":
			RimesAbilities.execute_ultimate(attacker, target, self)
		"isaac":
			IsaacAbilities.execute_ultimate(attacker, target, self)
		"keloist":
			KeloistAbilities.execute_ultimate(attacker, target, self)
		"musienko":
			MusienkoAbilities.execute_ultimate(attacker, target, self)
		"joan":
			JoanAbilities.execute_ultimate(attacker, target, self)
		"jeff":
			JeffAbilities.execute_ultimate(attacker, target, self)
		"valramors":
			ValramorsAbilities.execute_ultimate(attacker, target, self)
		"joan_spirit":
			JoanSpiritAbilities.execute_ultimate(attacker, self)
		"isaac_admin":
			IsaacAdminAbilities.execute_ultimate(attacker, self)
		"sara_admin":
			SaraAdminAbilities.execute_ultimate(attacker, self)
		"arseniy_admin":
			ArseniyAdminAbilities.execute_ultimate(attacker, target, self)
		"dasha_admin":
			DashaAdminAbilities.execute_ultimate(attacker, self)
		"shoji_swan":
			ShojiSwanAbilities.execute_ultimate(attacker, self)
		"katarina":
			KatarinaAbilities.execute_ultimate(attacker, target, self)
		"dotseva_crimson_tears":
			DotsevaCrimsonTearsAbilities.execute_ultimate(attacker, self)
		
	if attacker.get_meta("light_cone_id", "") == "history_soaked_in_blood":
		attacker.remove_meta("blood_soaked_hit_targets")
		if bool(attacker.get_meta("blood_soaked_ult_triggered", false)):
			attacker.remove_meta("blood_soaked_ult_triggered")
			attacker.set_meta("blood_soaked_recorded_dmg", 0.0)
			log_message("🩸 Конус «История, вымоченная в крови»: Накопленный урон очищен после Сверхспособности.")
			unit_updated.emit(attacker)

	# ИСПРАВЛЕНО: Снимаем флаг выполнения Сверхспособности для Басни о Багровых Слезах
	if attacker.has_meta("is_casting_ultimate"):
		attacker.remove_meta("is_casting_ultimate")
	remove_meta("current_action_key") # ДОБАВЛЕНО: Безопасно снимаем флаг каста ультимейта
	finish_attack_recording(attacker)
	
func _spend_skill_points(amount: int) -> void:
	skill_points -= amount
	skill_points_changed.emit(skill_points)

func get_action_preview() -> Array:
	return ActionValueSystem.preview_turn_order(get_all_units(), 10)

func get_extra_crit_dmg(attacker: CombatUnit) -> float:
	if attacker.is_ally:
		var bonus := 0.0
		bonus += ArseniyAbilities.get_ally_crit_bonus(self)
		if attacker.id == PusenkovAbilities.ID:
			bonus += PusenkovAbilities.get_excess_crit_dmg_bonus(attacker)
		return bonus
	return 0.0
	
func add_calibration_stacks(unit: CombatUnit, count: int) -> void:
	var max_stacks := 25
	max_stacks += 5 # След 1: +5 к макс. лимиту (всего 30)
	if unit.eidolon >= 2:
		max_stacks += 10 # Е2: +10 к макс. лимиту (всего 40)
		
	var current := int(unit.get_meta("dotseva_calibration_stacks", 0))
	var new_stacks := mini(current + count, max_stacks)
	unit.set_meta("dotseva_calibration_stacks", new_stacks)
	unit.set_meta("dotseva_calibration_turns", 3) # Обновляем длительность до 3 ходов
	
	log_message("Калибровка Доцевой: %d/%d стаков." % [new_stacks, max_stacks])
	
	if new_stacks >= max_stacks:
		trigger_dotseva_talent_fua(unit, new_stacks)
		
func trigger_dotseva_talent_fua(unit: CombatUnit, stacks: int) -> void:
	if has_meta("lenskaya_fua_attacker_credited"):
		remove_meta("lenskaya_fua_attacker_credited")
	log_message("💥 ТАЛАНТ ДОЦЕВОЙ: Достигнут максимум Калибровки! Бонус-атака по всем целям!")
	unit.set_meta("dotseva_calibration_stacks", 0)
	unit.set_meta("dotseva_calibration_turns", 0)
	
	var mult := (5.0 * float(stacks)) / 100.0
	var living := get_living_enemies()
	
	for enemy in living:
		var res := calc_dmg(unit, enemy, mult, 0.0, false, 0.0, 0.0, false, true, "Бонус-атака")
		var def_mult := DamageCalculator.calc_def_multiplier(enemy.stats.def)
		var res_mult := DamageCalculator.get_res_multiplier(unit, enemy)
		var total_dmg := float(res.damage) + (300.0 * def_mult * res_mult)
		
		deal_damage(enemy, total_dmg, unit, unit.element, res.crit, "Бонус-атака")
	
	if has_meta("lenskaya_fua_attacker_credited"):
		remove_meta("lenskaya_fua_attacker_credited")

func calc_dmg(attacker: CombatUnit, target: CombatUnit, mult: float, element_bonus: float = 0.0, force_crit: bool = false, extra_damage_bonus: float = 0.0, extra_crit_dmg: float = 0.0, is_ultimate: bool = false, allow_crit: bool = true, tag_override: String = "", base_damage_override: float = -1.0) -> Dictionary:
	if target == null:
		return { "damage": 0.0, "crit": false }
		
	# --- ТРИГГЕР ПРЕДВАРИТЕЛЬНОГО НАЛОЖЕНИЯ ПЕРЕДАЧИ ПОРЧИ ВАЛРАМОРСА ---
	# Срабатывает до вычисления урона, чтобы первая атака наносилась по ослабленной цели
	if attacker != null and attacker.is_ally and attacker.has_meta("valramors_corruption_transfer") and tag_override != "DoT" and tag_override != "cant_kill_bonus_hit" and tag_override != "copied_e6" and tag_override != "debtor_proc":
		# Тратим статус сразу, чтобы предотвратить повторный запуск при перерасчетах deal_damage и мульти-хитах
		attacker.remove_meta("valramors_corruption_transfer")
		
		var cur_action_key := String(get_meta("current_attack_type", ""))
		if tag_override == "Basic" or tag_override == "basic":
			cur_action_key = "basic"
		elif tag_override == "Skill" or tag_override == "skill":
			cur_action_key = "skill_q"
		elif is_ultimate:
			cur_action_key = "ultimate"
			
		var act_type := get_action_type(attacker, cur_action_key, tag_override)
		var target_to_debuff := target
		
		# Если атака бьет по площади, находим врага с наибольшим текущим ХП
		if act_type == "blast" or act_type == "group" or act_type == "bounce":
			var living := get_living_enemies()
			var highest_hp: float = 0.0
			for enemy in living:
				if enemy.is_alive() and enemy.stats.hp > highest_hp:
					highest_hp = enemy.stats.hp
					target_to_debuff = enemy
					
		if target_to_debuff:
			var valramors := get_valramors_unit()
			var ehr := ValramorsAbilities.get_valramors_ehr(valramors) if valramors else 0.0
			var eff_res := NaamaAbilities.get_effect_res(target_to_debuff)
			
			var final_chance: float = float(1.20 * (1.0 + ehr) * (1.0 - eff_res))
			if randf() < final_chance:
				apply_def_reduction(target_to_debuff, "Передача порчи (Валраморс)", 0.40, 3)
				log_message("🔮 Передача порчи: %s передал порчу на %s перед ударом! Защита цели снижена на -40%%." % [attacker.display_name, target_to_debuff.display_name])
			else:
				log_message("💨 Промах! «Передача порчи» на %s не наложилась перед ударом из-за сопротивления." % target_to_debuff.display_name)

	var is_fua: bool = (tag_override == "Бонус-атака" or tag_override == "FollowUp" or tag_override == "dotseva_fua" or tag_override == "lenskaya_fua" or tag_override == "lenskaya_true_fua" or tag_override == "debtor_proc")
	
	# --- 1. РАСЧЕТ БАЗОВОГО УРОНА ---
	# Базовый урон = Множитель способности * Характеристика + Дополнительный урон
	var base_stat_val: float = attacker.stats.atk
	if attacker.id == "musienko":
		base_stat_val = float(attacker.get_meta("base_hp_original", attacker.stats.max_hp))
	elif attacker.id == "danill":
		var danill_relic_def: float = float(attacker.get_meta("relic_def_pct", 0.0))
		var effective_def: float = attacker.stats.def * (1.0 + danill_relic_def)
		var stacks: int = int(attacker.get_meta("danill_talent_stacks", 0))
		effective_def *= (1.0 + 0.10 * float(stacks))
		if attacker.has_meta("danill_trace3_def_buff") and attacker.get_meta("danill_trace3_def_buff"):
			effective_def *= 1.30
		base_stat_val = get_effective_def_complete(attacker)
	if attacker.id == "dasha_admin":
		base_stat_val = get_effective_def_complete(attacker)
		
	# Сбор плоских баффов характеристики (СА)
	var extra_atk_flat: float = 0.0
	if attacker.has_meta("keloist_flat_atk_buff"):
		extra_atk_flat += float(attacker.get_meta("keloist_flat_atk_buff", 0.0))
	if attacker.has_meta("relic_galilean_atk_pct"):
		extra_atk_flat += attacker.stats.atk * float(attacker.get_meta("relic_galilean_atk_pct", 0.0))
	if attacker.has_meta("relic_silhouette_atk_pct"):
		extra_atk_flat += attacker.stats.atk * float(attacker.get_meta("relic_silhouette_atk_pct", 0.0))
		
	var milena_flat_atk: float = 0.0
	var milena := get_milena_unit()
	if milena and milena.is_alive() and attacker.is_ally:
		var milena_relic_pct: float = float(milena.get_meta("relic_atk_pct", 0.0))
		var milena_eff_atk: float = milena.stats.atk * (1.0 + milena_relic_pct)
		if attacker.id != "milena":
			milena_flat_atk += milena_eff_atk * 0.05

	var vika_flat: float = 0.0
	if attacker.id == "vika" and attacker.has_meta("vika_e_atk_buff"):
		vika_flat = float(attacker.get_meta("vika_e_atk_buff", 0.0))
	
	var valramors_debuff_pct: float = 0.0
	if attacker != null and attacker.has_meta("valramors_talent_turns") and int(attacker.get_meta("valramors_talent_turns", 0)) > 0:
		valramors_debuff_pct = -0.15
		
	var q_flat: float = 0.0
	var q_pct: float = 0.0
	if attacker.has_meta("arseniy_q_turns") and int(attacker.get_meta("arseniy_q_turns", 0)) > 0:
		q_pct = float(attacker.get_meta("arseniy_q_atk_percent", 0.0))
		q_flat = float(attacker.get_meta("arseniy_q_atk_flat", 0.0))

	# Процентные баффы характеристики (СА)
	var stat_multiplier: float = 1.0 + q_pct + attacker.statuses.self_atk_buff_percent + attacker.statuses.atk_buff_percent + valramors_debuff_pct
	if attacker.has_meta("relic_atk_pct"):
		stat_multiplier += float(attacker.get_meta("relic_atk_pct", 0.0))
	if attacker.has_meta("faction_chaos_atk_pct"):
		stat_multiplier += float(attacker.get_meta("faction_chaos_atk_pct", 0.0))
	if attacker.has_meta("faction_empyrean_atk_pct"):
		stat_multiplier += float(attacker.get_meta("faction_empyrean_atk_pct", 0.0))
	if attacker.has_meta("lc_atk_pct_bonus"):
		stat_multiplier += float(attacker.get_meta("lc_atk_pct_bonus", 0.0))
	if attacker.has_meta("lenskaya_trace3_atk_percent"):
		stat_multiplier += float(attacker.get_meta("lenskaya_trace3_atk_percent", 0.0))
	if attacker.has_meta("save_world_plan_stacks"):
		stat_multiplier += 0.04 * float(attacker.get_meta("save_world_plan_stacks", 0))
	
	var js_unit := get_joan_spirit_unit()
	if js_unit and js_unit.is_alive():
		var gold_stacks: int = int(js_unit.get_meta("joan_gold_remnants", 0))
		stat_multiplier += float(gold_stacks) * 0.04
	
	# След 2 Айзека Админа: +30% СА на 2 хода после Навыка Е
	if attacker != null and attacker.has_meta("isaac_admin_trace2_atk_turns") and int(attacker.get_meta("isaac_admin_trace2_atk_turns", 0)) > 0:
		stat_multiplier += 0.30
			
	if milena and milena.is_alive() and attacker.is_ally:
		if int(milena.get_meta("milena_overtone_turns", 0)) > 0:
			stat_multiplier += 0.30
			
	# Бафф статуса «Партнёр по сцене» (+15% СА)
	if attacker.has_meta("stage_partner_turns") and int(attacker.get_meta("stage_partner_turns", 0)) > 0:
		stat_multiplier += 0.15
		
	# Бафф статуса «Пылающее солнце» (+40% СА)
	if attacker.has_meta("blazing_sun_turns") and int(attacker.get_meta("blazing_sun_turns", 0)) > 0:
		stat_multiplier += 0.40

	# Бафф Таланта Сёдзи (+50% СА на 2 хода при сбросе 90 Векторов)
	if attacker.has_meta("shoji_swan_atk_turns") and int(attacker.get_meta("shoji_swan_atk_turns", 0)) > 0:
		stat_multiplier += 0.50

	# Бафф Силы Атаки от Таланта Доцевой • Багровые слёзы («Закрой глаза»)
	if attacker.has_meta("doceva_tears_atk_buff_pct"):
		stat_multiplier += float(attacker.get_meta("doceva_tears_atk_buff_pct", 0.0))

	# Бафф Силы Атаки от метки Навыка Q Катарины
	if attacker.has_meta("katarina_q_ally_atk_buff_turns") and int(attacker.get_meta("katarina_q_ally_atk_buff_turns", 0)) > 0:
		stat_multiplier += 0.15
	
	if attacker.id == "valramors":
		var is_active := (attacker.slot_index == 0) or (attacker.eidolon >= 6)
		if is_active:
			var ehr := ValramorsAbilities.get_valramors_ehr(attacker)
			stat_multiplier += ehr

	var final_scaling_stat: float = base_stat_val * stat_multiplier + extra_atk_flat + milena_flat_atk + vika_flat + q_flat + attacker.statuses.atk_buff_flat

	# Учет дополнительного плоского урона
	var flat_additional_damage: float = 0.0
	if tag_override == "debtor_proc":
		var cal_stacks := int(attacker.get_meta("dotseva_calibration_stacks", 0))
		flat_additional_damage = 300.0 + (cal_stacks * 80.0)
	elif tag_override == "dotseva_fua" or tag_override == "Бонус-атака":
		flat_additional_damage = 300.0
	elif attacker.id == "dotseva":
		var cur_attack: String = String(get_meta("current_attack_type", ""))
		if cur_attack == "skill_q" or tag_override == "Skill":
			flat_additional_damage = 300.0 # Обычный Q дает +300 к урону
		elif tag_override == "dotseva_fua_normal":
			flat_additional_damage = 350.0

	var crit_rate_sum: float = attacker.stats.crit_rate

	var base_damage: float = mult * final_scaling_stat + flat_additional_damage
	if base_damage_override >= 0.0:
		base_damage = base_damage_override

	# --- 2. МНОЖИТЕЛЬ ПОВЫШЕНИЯ УРОНА (Outgoing DMG Boost) ---
	var dmg_boost_sum: float = attacker.stats.damage_bonus + element_bonus + extra_damage_bonus
	
	var final_is_ultimate: bool = is_ultimate or (get_meta("current_action_key", "") == "ultimate")
	# --- СВЕТОВЫЕ КОНУСЫ: БАФФЫ НАНОСИМОГО УРОНА ---
	var lc_equipped: String = attacker.get_meta("light_cone_id", "")
	var cur_act_key := String(get_meta("current_attack_type", ""))
	var is_basic_or_skill: bool = (tag_override == "Basic" or tag_override == "basic" or tag_override == "Skill" or tag_override == "skill" or cur_act_key == "basic" or cur_act_key == "skill_q" or cur_act_key == "skill_e")
	
	# 1. Конус «Апокалипсис»: Базовая атака и навыки +18% урона
	if lc_equipped == "apocalypse":
		if is_basic_or_skill and not final_is_ultimate and not is_fua:
			dmg_boost_sum += 0.18
			
	# 2. Конус «Пробуждение зверя»: Урон +25% (+30% если % ХП врага >= % ХП владельца)
	if lc_equipped == "beast_awakening":
		dmg_boost_sum += 0.25
		if target != null and attacker.stats.max_hp > 0 and target.stats.max_hp > 0:
			var owner_hp_ratio := attacker.stats.hp / attacker.stats.max_hp
			var target_hp_ratio := target.stats.hp / target.stats.max_hp
			if target_hp_ratio >= owner_hp_ratio:
				dmg_boost_sum += 0.30
				
	# 3. Конусы DoT-урона: «Пустота» (+20%) и «Что есть реальность?» (+38%)
	if tag_override == "DoT":
		if lc_equipped == "void_dot":
			dmg_boost_sum += 0.20
		elif lc_equipped == "what_is_reality":
			dmg_boost_sum += 0.38
	
	# 4. Конус «Отголоски прошлого»: Урон Сверхспособности -30%
	if final_is_ultimate and lc_equipped == "echoes_of_the_past":
		dmg_boost_sum -= 0.30
		
	# 5. Конус «План по спасению мира»: Урон бонус-атак +30%
	if is_fua and lc_equipped == "save_the_world_plan":
		dmg_boost_sum += 0.30
		
	# ИСПРАВЛЕНО: Безопасное определение ультимейта по метаданным (решает проблему сброса Е1 при перерасчете)
	
	
	if battle_mode == "level_6" and attacker != null and attacker.path == CombatConstants.Path.ERUDITION:
		dmg_boost_sum += 0.20
	
	
	# Палящий взор: +30% урона следующего Навыка Е
	if attacker.get_meta("light_cone_id", "") == "scorching_gaze":
		var cur_atk_type := String(get_meta("current_attack_type", ""))
		if (cur_atk_type == "skill_e" or tag_override == "Skill") and attacker.has_meta("scorching_gaze_next_e_buff"):
			dmg_boost_sum += 0.30
			
	# Ощути моё присутствие: +25% урона при 3 стаках
	if attacker.has_meta("feel_presence_dmg_bonus"):
		dmg_boost_sum += float(attacker.get_meta("feel_presence_dmg_bonus", 0.0))
		
	if final_is_ultimate:
		if attacker.get_meta("light_cone_id", "") == "database":
			dmg_boost_sum += 0.30
		if attacker.get_meta("light_cone_id", "") == "moment_of_happiness":
			var target_spd_reduced := false
			if target.stats.get_effective_spd() < target.stats.spd:
				target_spd_reduced = true
			elif target.statuses.imaginary_spd_debuff_turns > 0 or target.statuses.suppression_stacks > 0:
				target_spd_reduced = true
			if target_spd_reduced:
				dmg_boost_sum += 0.25
	

		
	if attacker.has_meta("in_fog_buff") and attacker.get_meta("in_fog_buff"):
		dmg_boost_sum += 1.0
		attacker.set_meta("in_fog_buff", false)
				
		# 1. Е1 Жоана: повышает урон СВЕРХСПОСОБНОСТЕЙ персонажей Эрудиции на 10%
		var joan_unit = get_joan_unit()
		if joan_unit and joan_unit.is_alive() and joan_unit.eidolon >= 1:
			if attacker.path == CombatConstants.Path.ERUDITION:
				dmg_boost_sum += 0.10
				# Лог пишется только во время основного хода, чтобы избежать спама при перерасчете
				if not is_ultimate: 
					log_message("⚡ Эйдолон 1 Жоана: Урон Сверхспособности Эрудита %s повышен на 10%%." % attacker.display_name)
	
	if attacker.is_ally: # ИСПРАВЛЕНО: Конус больше не баффает противников с совпадающим элементом!
		for ally in allies:
			if ally.is_alive() and ally.get_meta("light_cone_id", "") == "better_world":
				if attacker.element == ally.element:
					dmg_boost_sum += 0.20
					break
					
	if is_fua:
		var lenskaya_ref := get_lenskaya_unit()
		if lenskaya_ref and lenskaya_ref.is_alive():
			var manipulation: int = int(lenskaya_ref.get_meta("lenskaya_manipulation", 0))
			dmg_boost_sum += float(clampi(manipulation, 0, 15)) * 0.03
		if attacker.has_meta("set_galilean_2") or attacker.has_meta("set_galilean_4"):
			dmg_boost_sum += 0.20
		if attacker.has_meta("has_set_irkutsk"):
			var i_stacks: int = int(attacker.get_meta("relic_irkutsk_feat_stacks", 0))
			dmg_boost_sum += 0.05 * float(i_stacks)
		if attacker.has_meta("lenskaya_tech_fua_buff_turns") and int(attacker.get_meta("lenskaya_tech_fua_buff_turns", 0)) > 0:
			dmg_boost_sum += 0.40
		if attacker.is_ally:
			for ally in allies:
				if ally.is_alive() and ally.get_meta("light_cone_id", "") == "save_the_world_plan":
					if int(ally.get_meta("save_world_plan_stacks", 0)) >= 10:
						dmg_boost_sum += 0.20
						break
			if battle_mode == "level_18":
				dmg_boost_sum += 0.35

	if attacker.has_meta("set_chaos_4") and (attacker.stats.hp / attacker.stats.max_hp) < 0.50:
		dmg_boost_sum += 0.20
	if attacker.has_meta("set_lava_fighter_4") and current_unit != attacker:
		dmg_boost_sum += 0.20
	if attacker.has_meta("set_hope_beam_4"):
		var cur_attack: String = String(get_meta("current_attack_type", ""))
		if cur_attack == "skill_q" or cur_attack == "skill_e":
			dmg_boost_sum += 0.12
		if attacker.has_meta("hope_beam_ult_buff") and attacker.get_meta("hope_beam_ult_buff"):
			dmg_boost_sum += 0.12
			
	if attacker.has_meta("has_set_krasnodar"):
		if crit_rate_sum >= 0.50: # ИСПРАВЛЕНО: Сверяется с динамическим КШ в бою
			if is_ultimate or is_fua:
				dmg_boost_sum += 0.15
				
	if attacker.has_meta("has_set_other_side_universe"):
		if crit_rate_sum >= 0.70:
			# ИСПРАВЛЕНО: Переименовали переменную в is_osu_basic_skill во избежание конфликта
			var is_osu_basic_skill: bool = (tag_override == "Basic" or tag_override == "basic" or tag_override == "Skill" or tag_override == "skill" or tag_override == "debtor_proc" or tag_override == "copied_e6")
			if is_osu_basic_skill and not is_ultimate and not is_fua:
				dmg_boost_sum += 0.20

	if attacker.id == "dotseva":
		var enemy_count := get_living_enemies().size()
		dmg_boost_sum += 0.10 * float(enemy_count)
		
	if attacker.has_meta("academy_dmg_bonus_turns") and int(attacker.get_meta("academy_dmg_bonus_turns", 0)) > 0:
		dmg_boost_sum += 0.30
		
	# Аномалии подземелий (Dungeon Anomalies DMG Boost)
	if attacker != null and attacker.is_ally:
		if battle_mode == "dungeon_academy":
			if attacker.element == CombatConstants.Element.ICE or attacker.element == CombatConstants.Element.QUANTUM:
				dmg_boost_sum += 0.30
			if target != null and (target.statuses.skip_next_turn or target.statuses.toughness_broken or target.toughness <= 0.0):
				dmg_boost_sum += 0.40
		elif battle_mode == "dungeon_hq":
			if attacker.element == CombatConstants.Element.FIRE or attacker.element == CombatConstants.Element.PHYSICAL:
				dmg_boost_sum += 0.30
		elif battle_mode == "dungeon_kitchens":
			if attacker.element == CombatConstants.Element.LIGHTNING or attacker.element == CombatConstants.Element.IMAGINARY:
				dmg_boost_sum += 0.30
			if attacker.has_meta("dungeon_kitchens_atk_turns") and int(attacker.get_meta("dungeon_kitchens_atk_turns", 0)) > 0:
				dmg_boost_sum += 0.20
		elif battle_mode == "dungeon_dam":
			if attacker.element == CombatConstants.Element.WIND:
				dmg_boost_sum += 0.30
			if attacker.has_meta("dungeon_dam_heal_buff_turns") and int(attacker.get_meta("dungeon_dam_heal_buff_turns", 0)) > 0:
				dmg_boost_sum += 0.20
		elif battle_mode == "dungeon_dawn_chaos":
			if attacker.current_shield > 0.0:
				dmg_boost_sum += 0.30
		elif battle_mode == "dungeon_as_house":
			if is_fua:
				dmg_boost_sum += 0.50
		elif battle_mode == "planar_empyreans":
			if attacker.stats.get_effective_spd() >= 120.0:
				dmg_boost_sum += 0.35
		elif battle_mode == "planar_slums":
			if final_is_ultimate or is_fua:
				dmg_boost_sum += 0.40
				
		if attacker.has_meta("dungeon_slums_stacks") and int(attacker.get_meta("dungeon_slums_turns", 0)) > 0:
			dmg_boost_sum += float(attacker.get_meta("dungeon_slums_stacks", 0)) * 0.30
	
	# Расчет эффектов Следа 2 Жоана при 1 противнике на поле
	var joan_unit = get_joan_unit()
	if joan_unit and joan_unit.is_alive() and get_living_enemies().size() == 1:
		var cur_action_key := String(get_meta("current_attack_type", ""))
		if tag_override == "Basic" or tag_override == "basic":
			cur_action_key = "basic"
		elif tag_override == "Skill" or tag_override == "skill":
			cur_action_key = "skill_q"
		elif is_ultimate:
			cur_action_key = "ultimate"
			
		var act_type := get_action_type(attacker, cur_action_key, tag_override)
		
		if act_type == "blast":
			dmg_boost_sum += 0.10 # Взрывные атаки +10%
			log_message("⚡ След 2 Жоана: Взрывная атака %s наносит на 10%% больше урона единственной цели!" % attacker.display_name)
		elif act_type == "group":
			dmg_boost_sum += 0.75 # Групповые атаки +75%
			log_message("⚡ След 2 Жоана: Групповая атака %s наносит на 75%% больше урона единственной цели!" % attacker.display_name)
			
	# 2. Е2 Жоана: повышает урон самого Жоана по целям с меткой «Не промахнись» на 20%
	if attacker.id == "joan" and attacker.eidolon >= 2:
		if target.has_meta("joan_dont_miss_turns") and int(target.get_meta("joan_dont_miss_turns", 0)) > 0:
			dmg_boost_sum += 0.20
			log_message("⚡ Эйдолон 2 Жоана: Урон Жоана по цели %s с меткой повышен на 20%%!" % target.display_name)
	
	if attacker.has_meta("inevitable_fall_wrath_turns") and int(attacker.get_meta("inevitable_fall_wrath_turns", 0)) > 0:
		dmg_boost_sum += 0.30
		
	if attacker.has_meta("level19_dmg_buff"):
		dmg_boost_sum += float(attacker.get_meta("level19_dmg_buff", 0.0))

	if battle_mode == "level_20" and attacker != null and attacker.is_ally and target != null and target.id == "masked_silhouette":
		var mask_broken := int(target.get_meta("mask_layers", 0)) <= 0
		var in_isolation: bool = (target.has_meta("rimes_isolated") and bool(target.get_meta("rimes_isolated"))) or (attacker.has_meta("rimes_isolation_target") and attacker.get_meta("rimes_isolation_target") == target)
		if mask_broken or in_isolation:
			dmg_boost_sum += 0.40

	var outgoing_dmg_boost_mult: float = 1.0 + dmg_boost_sum
	
	# --- УНИВЕРСАЛЬНАЯ СИСТЕМА БИНАРНОГО УРОНА (КОНСОЛЬ) ---
	var is_binary: bool = (tag_override == "Binary" or tag_override == "binary" or (attacker != null and attacker.has_meta("is_binary_attack")))
	var isaac_admin_ref := get_isaac_admin_unit()
	var sara_admin_ref := get_sara_admin_unit() # <--- ЕДИНОЕ ОБЪЯВЛЕНИЕ ДЛЯ ВСЕЙ ФУНКЦИИ
	var shoji_swan_ref := get_shoji_swan_unit()
	
	# Сёдзи в состоянии «Танец»: её Бинарный урон перестаёт быть Бинарным (если нет E6)
	if attacker != null and attacker.id == "shoji_swan" and get_shoji_swan_stance() == "dance":
		if not (shoji_swan_ref and shoji_swan_ref.eidolon >= 6):
			is_binary = false
			
	# Сёдзи в состоянии «Танец»: повышает наносимый союзниками не-Бинарный урон на +30%
	if shoji_swan_ref and shoji_swan_ref.is_alive() and get_shoji_swan_stance() == "dance":
		if not is_binary and attacker != null and attacker.is_ally:
			dmg_boost_sum += 0.30
			outgoing_dmg_boost_mult = 1.0 + dmg_boost_sum

	# Е6 Айзека / Е6 Сёдзи: Весь урон всех союзников конвертируется в Бинарный
	if ((isaac_admin_ref and isaac_admin_ref.is_alive() and isaac_admin_ref.eidolon >= 6) or (shoji_swan_ref and shoji_swan_ref.is_alive() and shoji_swan_ref.eidolon >= 6)) and attacker != null and attacker.is_ally:
		is_binary = true
	
	if is_binary:
		var binary_boost: float = 0.0
		
		# Ультра Даши: +50% Бинарного урона на 1 ход
		if attacker != null and attacker.has_meta("dasha_ult_binary_turns") and int(attacker.get_meta("dasha_ult_binary_turns", 0)) > 0:
			binary_boost += 0.50

		# Аномалия 15 уровня: Бинарный урон увеличен на +30%
		if battle_mode == "level_15" and attacker != null and attacker.is_ally:
			binary_boost += 0.30
			
		# Е6 Даши: +30% Бинарного урона на 2 хода
		if attacker != null and attacker.has_meta("dasha_e6_binary_turns") and int(attacker.get_meta("dasha_e6_binary_turns", 0)) > 0:
			binary_boost += 0.30
			
		# Е2 Даши: +20% Бинарного урона Навыку E
		if attacker != null and attacker.has_meta("dasha_e2_binary_boost"):
			binary_boost += 0.20
			
		# Синергия Консоли [4]: Бинарный урон участников +20%
		if attacker != null and attacker.has_meta("faction_console_full_access"):
			binary_boost += 0.20
			
		# 1. Базовый бонус: +1% за каждый Вектор из ОБЩЕГО пула Консоли
		var cur_vectors: int = get_console_vectors()
		if attacker != null and attacker.has_meta("sara_override_vectors"):
			cur_vectors = int(attacker.get_meta("sara_override_vectors", 20))
		binary_boost += float(cur_vectors) * 0.01
		
		# 2. Зона Сары («Среда разработки»)
		if sara_admin_ref and sara_admin_ref.is_alive() and int(sara_admin_ref.get_meta("sara_dev_env_turns", 0)) > 0:
			var spd_over: float = maxf(sara_admin_ref.stats.get_effective_spd() - 100.0, 0.0)
			var env_bonus: float = minf(spd_over, 60.0) * 0.01
			binary_boost += env_bonus
			
		# 3. Техника Сары
		if attacker != null and attacker.has_meta("sara_tech_binary_turns") and int(attacker.get_meta("sara_tech_binary_turns", 0)) > 0:
			binary_boost += 0.30
			
		# 4. Е4 Сары
		if attacker != null and attacker.id == "sara_admin" and attacker.eidolon >= 4:
			binary_boost += 0.40
			
		# 5. След 1 Айзека Админа
		if isaac_admin_ref and isaac_admin_ref.is_alive() and int(isaac_admin_ref.get_meta("isaac_hacked_turns", 0)) > 0:
			binary_boost += 0.20
			
		# 6. Конус «Повреждённое сохранение»: пока есть Погружение, Бинарный урон союзников +25%
		if attacker != null and attacker.is_ally:
			for ally in allies:
				if ally.is_alive() and ally.get_meta("light_cone_id", "") == "corrupted_save" and int(ally.get_meta("immersion_turns", 0)) > 0:
					binary_boost += 0.25
					break

		# 7. Конус «Момент, когда падают сервера»: постоянный бонус Бинарного урона +40%
		if attacker != null and attacker.get_meta("light_cone_id", "") == "server_crash_moment":
			binary_boost += 0.40

		# 8. Сёдзи (Вирус): бонус +40% Бинарного урона при ульте
		if attacker != null and attacker.has_meta("shoji_swan_ult_virus_bonus"):
			binary_boost += float(attacker.get_meta("shoji_swan_ult_virus_bonus", 0.40))

		# 9. Е2 Сёдзи (Вирус): союзники наносят +50% Бинарного урона
		if shoji_swan_ref and shoji_swan_ref.is_alive() and get_shoji_swan_stance() == "virus" and shoji_swan_ref.eidolon >= 2 and attacker != null and attacker.is_ally:
			binary_boost += 0.50
			
		# Е6 Айзека / Е6 Сёдзи: Бинарный урон получает усиление от обычных баффов урона
		if (isaac_admin_ref and isaac_admin_ref.is_alive() and isaac_admin_ref.eidolon >= 6) or (shoji_swan_ref and shoji_swan_ref.is_alive() and shoji_swan_ref.eidolon >= 6):
			outgoing_dmg_boost_mult = 1.0 + dmg_boost_sum + binary_boost
		else:
			outgoing_dmg_boost_mult = 1.0 + binary_boost
			
	# --- 3. МНОЖИТЕЛЬ КРИТА (Crit Multiplier) ---
	var crit_dmg_sum: float = attacker.stats.get_effective_crit_dmg(attacker.statuses) + extra_crit_dmg
	
	# Сет Иркутска: При 5 стаках Подвига Крит. урон повышается на +25%
	if attacker.has_meta("has_set_irkutsk"):
		var i_stacks: int = int(attacker.get_meta("relic_irkutsk_feat_stacks", 0))
		if i_stacks == 5:
			crit_dmg_sum += 0.25 # Добавлено: +25% КУ при макс. стаках
	
	# Конус «Танец при луне»: Крит. урон +48% по врагам под дебаффом ЗАЩ или Замедлением
	if attacker.get_meta("light_cone_id", "") == "moon_dance":
		var has_def_debuff := target.has_meta("def_reductions") or (target.statuses.toughness_broken)
		var has_spd_debuff := target.statuses.imaginary_spd_debuff_turns > 0 or target.has_meta("lenskaya_slow_turns") or (target.stats.get_effective_spd() < target.stats.spd)
		if has_def_debuff or has_spd_debuff:
			crit_dmg_sum += 0.48
			
	# Новый След 3 Жоана: Если на цели есть DoT, получаемый КУ увеличен на +50%
	var js_trace3_unit := get_joan_spirit_unit()
	if js_trace3_unit and js_trace3_unit.is_alive() and not target.is_ally:
		if has_any_dot(target):
			crit_dmg_sum += 0.50
			
	if attacker.id == "lenskaya":
		var manipulation: int = int(attacker.get_meta("lenskaya_manipulation", 0))
		crit_rate_sum += float(clampi(manipulation, 0, 15)) * 0.05
	elif attacker.id == "rimes":
		var stacks: int = int(attacker.get_meta("rimes_talent_stacks", 0))
		var max_stacks: int = 6 if attacker.eidolon >= 1 else 4
		if stacks == max_stacks:
			crit_rate_sum += 0.35
		if attacker.has_meta("rimes_isolation_target"):
			crit_rate_sum += 0.20
			crit_dmg_sum += 0.80

	if target.has_meta("priority_target") or target.has_meta("dead_or_alive"):
		crit_rate_sum += 0.10
		var cd_bonus: float = 0.20
		if target.has_meta("dead_or_alive") and attacker.id == "pusenkov" and attacker.eidolon >= 2:
			cd_bonus += 0.20
		crit_dmg_sum += cd_bonus
	
	if attacker.id == "valramors":
		var is_active := (attacker.slot_index == 0) or (attacker.eidolon >= 6)
		if is_active:
			crit_dmg_sum += 0.60

	if target.has_meta("isaac_crit_dmg_taken_turns") and int(target.get_meta("isaac_crit_dmg_taken_turns", 0)) > 0:
		crit_dmg_sum += 0.50
	if attacker.has_meta("isaac_ult_buff_turns") and int(attacker.get_meta("isaac_ult_buff_turns", 0)) > 0:
		crit_dmg_sum += 1.00
		
	if sara_admin_ref and sara_admin_ref.is_alive() and attacker.is_ally:
		if get_console_vectors() >= 30:
			crit_rate_sum += 0.20
			crit_dmg_sum += 0.50

	# Е2 Сёдзи: в состоянии «Вирус» увеличивает свой Крит. урон на +1% за каждый Вектор
	if shoji_swan_ref and shoji_swan_ref.is_alive() and get_shoji_swan_stance() == "virus" and shoji_swan_ref.eidolon >= 2:
		if attacker != null and attacker.id == "shoji_swan":
			crit_dmg_sum += float(get_console_vectors()) * 0.01

	# Аномалия 20 уровня: +50% Крит. урона по Силуэту без маски или в Изоляции
	if battle_mode == "level_20" and attacker != null and attacker.is_ally and target != null and target.id == "masked_silhouette":
		var mask_broken := int(target.get_meta("mask_layers", 0)) <= 0
		var in_isolation: bool = (target.has_meta("rimes_isolated") and bool(target.get_meta("rimes_isolated"))) or (attacker.has_meta("rimes_isolation_target") and attacker.get_meta("rimes_isolation_target") == target)
		if mask_broken or in_isolation:
			crit_dmg_sum += 0.50

	# След 1 Катарины: +4% КШ за каждое ослабление на цели (макс 32%)
	if attacker != null and attacker.id == "katarina" and target != null:
		var debuff_cnt := get_unit_debuff_count(target)
		crit_rate_sum += minf(float(debuff_cnt) * 0.04, 0.32)

	# Эйдолон 6 Катарины: весь урон по цели со статусом «Сломленный дух» становится критическим
	var kat_unit := get_katarina_unit()
	if kat_unit and kat_unit.is_alive() and kat_unit.eidolon >= 6:
		if target != null and target.has_meta("katarina_broken_spirit") and bool(target.get_meta("katarina_broken_spirit", false)):
			if allow_crit and tag_override != "DoT" and tag_override != "True Damage":
				force_crit = true

	var is_crit: bool = false
	if allow_crit:
		is_crit = force_crit or (randf() < crit_rate_sum)

	var crit_mult: float = 1.0
	if is_crit:
		crit_mult = 1.0 + crit_dmg_sum

	# --- 4. МНОЖИТЕЛЬ БЕССИЛИЯ (Weaken) ---
	var weaken_sum: float = 0.0
	if attacker.has_meta("naama_kiss_turns") and int(attacker.get_meta("naama_kiss_turns", 0)) > 0:
		weaken_sum += 0.20
	if attacker.has_meta("isaac_dmg_reduce_turns") and int(attacker.get_meta("isaac_dmg_reduce_turns", 0)) > 0:
		weaken_sum += 0.30
		
	if attacker != null and attacker.has_meta("arseniy_atk_weaken_turns") and int(attacker.get_meta("arseniy_atk_weaken_turns", 0)) > 0:
		weaken_sum += 0.30

	# Сверхспособность Доцевой • Багровые слёзы: уменьшает наносимый врагами урон на 30%
	if attacker != null and attacker.has_meta("doceva_tears_outgoing_dmg_red_turns") and int(attacker.get_meta("doceva_tears_outgoing_dmg_red_turns", 0)) > 0:
		weaken_sum += 0.30
		
	var weaken_mult: float = maxf(0.0, 1.0 - weaken_sum)
	
		
	# --- 5. МНОЖИТЕЛЬ ЗАЩИТЫ (DEF) ---
	var level_atk: float = float(attacker.get_meta("level", 80.0)) if attacker != null else 80.0
	var level_def: float = float(target.get_meta("level", 80.0))

	var def_buff: float = 0.0
	var def_shred: float = 0.0
	var def_ignore: float = 0.0

	# Если цель защищается и это союзник, учитываем его реликвии на защиту
	if target.is_ally:
		def_buff += float(target.get_meta("relic_def_pct", 0.0))
	
	if attacker != null and attacker.has_meta("talent_ignore_20_def"):
		def_ignore += 0.20
		
	# Учет прибавок Маски Силуэта на противнике
	if target.has_meta("silhouette_mask_def_buff"): # ИСПРАВЛЕНО
		def_buff += float(target.get_meta("silhouette_mask_def_buff", 0.0))
	if target.has_meta("silhouette_mask_def_buff_permanent"): # ИСПРАВЛЕНО
		def_buff += float(target.get_meta("silhouette_mask_def_buff_permanent", 0.0))
		
	if target.has_meta("danill_talent_stacks"):
		def_buff += 0.10 * float(target.get_meta("danill_talent_stacks", 0))
	if target.has_meta("danill_trace3_def_buff") and bool(target.get_meta("danill_trace3_def_buff")):
		def_buff += 0.30
		
	if js_unit and js_unit.is_alive():
		# Е2: Бонус урона Эрудитам
		if js_unit.eidolon >= 2 and attacker.path == CombatConstants.Path.ERUDITION:
			var living_cnt := get_living_enemies().size()
			match living_cnt:
				2: dmg_boost_sum += 0.80
				3: dmg_boost_sum += 0.45
				4: dmg_boost_sum += 0.30
				5: dmg_boost_sum += 0.15
		# Е6: Вся команда игнорирует 40% защиты врагов
		if js_unit.eidolon >= 6 and attacker.is_ally:
			def_ignore += 0.40

	if target.has_meta("def_reductions"):
		var reductions: Dictionary = target.get_meta("def_reductions")
		for src in reductions:
			var data: Dictionary = reductions[src]
			if int(data.get("turns", 0)) > 0:
				def_shred += float(data.get("percent", 0.0))

	if target.has_meta("naama_kiss_turns") and int(target.get_meta("naama_kiss_turns", 0)) > 0:
		def_shred += 0.15
		
	if target.has_meta("naama_intox_stacks") and int(target.get_meta("naama_intox_stacks", 0)) >= 20:
		def_shred += 0.20
		
	if attacker != null and attacker.has_meta("set_lost_self_4"):
		var dot_count := get_active_dots_count(target)
		def_ignore += minf(float(clampi(dot_count, 0, 3)) * 0.06, 0.18)

	if battle_mode == "dungeon_dawn_chaos" and target != null and not target.is_ally:
		var chaos_dots := get_active_dots_count(target)
		def_shred += minf(0.30, float(chaos_dots) * 0.05)


	var lenskaya_ref := get_lenskaya_unit()
	if lenskaya_ref and lenskaya_ref.is_alive() and is_fua:
		if lenskaya_ref.eidolon >= 2:
			def_ignore += 0.40
			
	if battle_mode == "level_8" and attacker != null and attacker.path == CombatConstants.Path.HUNT:
		def_ignore += 0.40
			
	if attacker.has_meta("valramors_tech_ignore_turns") and int(attacker.get_meta("valramors_tech_ignore_turns", 0)) > 0:
		def_ignore += 0.15

	# Конус «Момент, когда падают сервера»: под статусом «Рефакторинг» Бинарный урон игнорирует 20% защиты цели
	if is_binary and attacker != null and attacker.get_meta("light_cone_id", "") == "server_crash_moment" and int(attacker.get_meta("refactoring_turns", 0)) > 0:
		def_ignore += 0.20

	# Навык Q Катарины: игнорирует 30% защиты цели
	if attacker != null and attacker.id == "katarina":
		var cur_atk_type := String(get_meta("current_attack_type", ""))
		if cur_atk_type == "skill_q" or tag_override == "Skill":
			def_ignore += 0.30

	var def_multiplier_bracket: float = 0.0
	if target.is_ally:
		# Для персонажей база защиты берется из их характеристик (base_def_original)
		var base_def_char: float = float(target.get_meta("base_def_original", target.stats.def))
		var final_target_def: float = base_def_char * maxf(0.0, 1.0 + def_buff - def_shred - def_ignore)
		def_multiplier_bracket = 1.0 - (final_target_def / (final_target_def + 200.0 + 10.0 * level_atk))
	else:
		# Для противников формула со скриншота:
		var numerator: float = level_atk + 20.0
		var denominator: float = (level_def + 20.0) * maxf(0.0, 1.0 + def_buff - def_shred - def_ignore) + level_atk + 20.0
		def_multiplier_bracket = numerator / denominator

	# --- 6. МНОЖИТЕЛЬ СОПРОТИВЛЕНИЯ (RES) ---
	var final_element := element_bonus
	if final_element == 0.0:
		final_element = attacker.element

	var is_weak: bool = int(final_element) in target.weaknesses
	var base_res: float = 0.0 if is_weak else 0.20

	var res_shred: float = 0.0
	if int(final_element) == CombatConstants.Element.PHYSICAL and target.has_meta("phys_res_reduced_turns") and int(target.get_meta("phys_res_reduced_turns", 0)) > 0:
		res_shred += 0.20
	if int(final_element) == CombatConstants.Element.FIRE and target.has_meta("shoji_fire_res_reduced_turns") and int(target.get_meta("shoji_fire_res_reduced_turns", 0)) > 0:
		res_shred += 0.40
		
	if int(final_element) == CombatConstants.Element.QUANTUM and target.has_meta("quantum_res_reduced_turns") and int(target.get_meta("quantum_res_reduced_turns", 0)) > 0:
		res_shred += 0.12

	# Снижение сопротивлений от Навыка Q Катарины (E1 снижает все типы на 20%, база - физ на 20%)
	if target.has_meta("katarina_all_res_reduction") and int(target.get_meta("katarina_vuln_turns", 0)) > 0:
		res_shred += float(target.get_meta("katarina_all_res_reduction", 0.20))
	elif int(final_element) == CombatConstants.Element.PHYSICAL and target.has_meta("katarina_phys_res_reduction") and int(target.get_meta("katarina_vuln_turns", 0)) > 0:
		res_shred += float(target.get_meta("katarina_phys_res_reduction", 0.20))
		
	# Е6 Арсения: если Векторы >= 60, ВСЕ типы сопротивления -20%
	if get_console_vectors() >= 60:
		var ars_e6 := get_arseniy_admin_unit()
		if ars_e6 and ars_e6.is_alive() and ars_e6.eidolon >= 6:
			res_shred += 0.20

	var res_pen: float = get_valramors_res_pen(attacker) # Интегрирован След 1 и Е2
	if attacker.id == "musienko" and attacker.has_meta("musienko_annihilation_active") and attacker.eidolon >= 2:
		res_pen += 0.20
	
	if attacker.has_meta("joan_ult_ignore_imaginary_res"):
		res_pen += 1.0 # 100% пробитие сопротивления
	
	if attacker.has_meta("sara_ult_res_pen_turns") and int(attacker.get_meta("sara_ult_res_pen_turns", 0)) > 0:
		res_pen += 0.20
		
	# След 3 Сёдзи: в состоянии «Танец» за каждые 2 ед. скорости свыше 110 повышает пробитие сопротивлений 1-го героя на +1% (макс 25%)
	if shoji_swan_ref and shoji_swan_ref.is_alive() and get_shoji_swan_stance() == "dance":
		if attacker != null and not allies.is_empty() and attacker == allies[0]:
			var spd_over: float = maxf(shoji_swan_ref.stats.get_effective_spd() - 110.0, 0.0)
			var shoji_t3_pen: float = minf(floor(spd_over / 2.0) * 0.01, 0.25)
			res_pen += shoji_t3_pen
		
	var res_multiplier_bracket: float = 1.0 - (base_res - res_shred - res_pen)

	# --- 7. МНОЖИТЕЛЬ СЛАБОСТИ (Vulnerability) ---
	var vulnerability_sum: float = 0.0
	if target.statuses.toughness_broken:
		vulnerability_sum += 0.20
	vulnerability_sum += target.statuses.damage_taken_bonus
		
	# Сёдзи в состоянии «Вирус»: повышает получаемый врагами Бинарный урон на +60%
	if is_binary and shoji_swan_ref and shoji_swan_ref.is_alive() and get_shoji_swan_stance() == "virus":
		vulnerability_sum += 0.60

	# Уязвимость от Сверхспособности Сёдзи (Танец)
	if target.has_meta("shoji_swan_dance_vuln_turns") and int(target.get_meta("shoji_swan_dance_vuln_turns", 0)) > 0:
		vulnerability_sum += float(target.get_meta("shoji_swan_dance_vuln_pct", 0.0))

	# Уязвимость от Техники Сёдзи (+30% на 2 хода)
	if target.has_meta("shoji_swan_tech_vuln_turns") and int(target.get_meta("shoji_swan_tech_vuln_turns", 0)) > 0:
		vulnerability_sum += 0.30
		
	# След 2 Арсения: Векторы > 40 -> +20% уязвимости к Бинарному урону
	if is_binary and get_console_vectors() > 40:
		var arseniy_adm_ref := get_arseniy_admin_unit()
		if arseniy_adm_ref and arseniy_adm_ref.is_alive():
			vulnerability_sum += 0.20
			
	# Уязвимость от Навыка E Арсения (+30% к Бинарному урону)
	if is_binary and target.has_meta("arseniy_binary_vuln_turns") and int(target.get_meta("arseniy_binary_vuln_turns", 0)) > 0:
		vulnerability_sum += 0.30
		
	# Уязвимость от Следа 3 Арсения (+30% КО ВСЕМУ урону)
	if target.has_meta("arseniy_trace3_vuln_turns") and int(target.get_meta("arseniy_trace3_vuln_turns", 0)) > 0:
		vulnerability_sum += 0.30

	if target.has_meta("valramors_ult_vuln_turns") and int(target.get_meta("valramors_ult_vuln_turns", 0)) > 0:
		vulnerability_sum += 0.20
	
	if tag_override == "DoT":
		if target.has_meta("naama_dot_vuln_turns") and int(target.get_meta("naama_dot_vuln_turns", 0)) > 0:
			vulnerability_sum += 0.30
		if target.statuses.suppression_stacks > 0:
			vulnerability_sum += 0.15 * float(target.statuses.suppression_stacks)
	
	# ИСПРАВЛЕНО: Дебаффы Жоана добавлены в финальный перерасчет deal_damage
	# Навык Е Жоана: +20% или +50% получаемого урона (дебафф "Не промахнись")
	if target.has_meta("joan_dont_miss_turns") and int(target.get_meta("joan_dont_miss_turns", 0)) > 0:
		vulnerability_sum += float(target.get_meta("joan_dont_miss_vuln", 0.20))
		
	# Техника Жоана: +20% получаемого урона
	if target.has_meta("joan_tech_vuln_turns") and int(target.get_meta("joan_tech_vuln_turns", 0)) > 0:
		vulnerability_sum += 0.20
	
	if target.has_meta("sara_e2_vuln_turns") and int(target.get_meta("sara_e2_vuln_turns", 0)) > 0:
		vulnerability_sum += 0.30

	# Е4: Слабость к Бинарному урону +20%
	if is_binary and target.has_meta("binary_vuln_turns") and int(target.get_meta("binary_vuln_turns", 0)) > 0:
		vulnerability_sum += 0.20

	# Серверный Вирус: +25% получаемого Бинарного урона
	if is_binary and target.id == "server_virus":
		vulnerability_sum += 0.25

	# Взлом файрвола Серверного Вируса: +20% уязвимости
	if target.has_meta("server_virus_breached_turns") and int(target.get_meta("server_virus_breached_turns", 0)) > 0:
		vulnerability_sum += 0.20

	# Орто Мутант: +30% уязвимости к AoE-атакам (Эрудиция / атаки по площади)
	if target.id == "ortho_mutant":
		var is_aoe := false
		if attacker != null and attacker.path == CombatConstants.Path.ERUDITION:
			is_aoe = true
		elif action_hit_enemies.size() >= 3:
			is_aoe = true
		elif tag_override == "group" or tag_override == "blast" or tag_override == "BinaryGroup":
			is_aoe = true
		if is_aoe:
			vulnerability_sum += 0.30
		
	# Тестовая админ-уязвимость
	if target.has_meta("admin_vuln_turns") and int(target.get_meta("admin_vuln_turns", 0)) > 0:
		vulnerability_sum += float(target.get_meta("admin_vuln_pct", 0.30))

	# Уязвимость от Улучшенного Навыка Q Доцевой • Багровые слёзы (+15%)
	if target.has_meta("doceva_tears_q_vuln_turns") and int(target.get_meta("doceva_tears_q_vuln_turns", 0)) > 0:
		vulnerability_sum += float(target.get_meta("doceva_tears_q_vuln_pct", 0.15))

	# Уязвимость от Эйдолона 2 Доцевой • Багровые слёзы (+40%)
	if target.has_meta("doceva_tears_e2_vuln_turns") and int(target.get_meta("doceva_tears_e2_vuln_turns", 0)) > 0:
		vulnerability_sum += float(target.get_meta("doceva_tears_e2_vuln_pct", 0.40))

	# След 2 / E6 Катарины: уязвимость к Бинарному урону
	if is_binary and target != null:
		if target.has_meta("katarina_e6_binary_vuln"):
			vulnerability_sum += float(target.get_meta("katarina_e6_binary_vuln", 0.40))
		elif target.has_meta("katarina_broken_spirit") and bool(target.get_meta("katarina_broken_spirit", false)):
			var kat_ref := get_katarina_unit()
			if kat_ref and kat_ref.is_alive():
				vulnerability_sum += 0.30

	var vulnerability_mult: float = 1.0 + vulnerability_sum

	# --- 8. МНОЖИТЕЛЬ СНИЖЕНИЯ ПОЛУЧАЕМОГО УРОНА (Мультипликативный) ---
	var dmg_reduction_mult: float = 1.0
	
	if tag_override == "DoT" and not target.is_ally:
		var js_dot_ref := get_joan_spirit_unit()
		if js_dot_ref and js_dot_ref.is_alive():
			if has_any_dot(target):
				dmg_reduction_mult *= 0.10 # Оставляет лишь 10% входящего DoT
	
	if target.has_meta("dasha_tech_reduce_turns") and int(target.get_meta("dasha_tech_reduce_turns", 0)) > 0:
		dmg_reduction_mult *= (1.0 - 0.40) # -40% входящего урона
		
	if target.is_ally:
		if target.has_meta("lc_all_res_bonus"):
			dmg_reduction_mult *= (1.0 - 0.12)
		if target.has_meta("keloist_orthoshield_turns") and int(target.get_meta("keloist_orthoshield_turns", 0)) > 0:
			dmg_reduction_mult *= (1.0 - 0.40)
		if target.id == "keloist":
			var any_orthoshield := false
			for ally in allies:
				if ally.is_alive() and ally.has_meta("keloist_orthoshield_turns") and int(ally.get_meta("keloist_orthoshield_turns", 0)) > 0:
					any_orthoshield = true
					break
			if any_orthoshield:
				dmg_reduction_mult *= (1.0 - 0.20)
			if target.id == "joan_spirit" and target.get_meta("joan_spirit_form", false):
				dmg_reduction_mult *= 0.60 # -40% получаемого урона в Форме духа
	else:
		if target.id == "void_armored" and target.has_meta("hell_armor") and target.get_meta("hell_armor"):
			dmg_reduction_mult *= (1.0 - 0.40)
		if target.id == "server_virus" and not is_binary:
			dmg_reduction_mult *= 0.75 # Не-Бинарный урон снижен на 25%
			

	# --- 9. МНОЖИТЕЛЬ ПРОБИТОЙ УЯЗВИМОСТИ ---
	var broken_vulnerability_mult: float = 1.0 if target.statuses.toughness_broken else 0.90

	# --- 10. МОДИФИКАТОРЫ СОСТОЯНИЯ ВИКИ ---
	var vika_awakening_mult: float = 1.0
	if attacker.id == "vika" and int(attacker.get_meta("vika_awakening_turns", 0)) > 0:
		vika_awakening_mult = 1.20 if attacker.eidolon >= 6 else 0.80
	


	# Сборка финального значения урона
	var final_damage: float = base_damage * crit_mult * outgoing_dmg_boost_mult * weaken_mult * def_multiplier_bracket * res_multiplier_bracket * vulnerability_mult * dmg_reduction_mult * broken_vulnerability_mult * vika_awakening_mult

	return {
		"damage": maxf(0.0, final_damage),
		"crit": is_crit
	}
	
func get_adjacent_enemies(target: CombatUnit) -> Array[CombatUnit]:
	var adjacent: Array[CombatUnit] = []
	if target == null:
		return adjacent
	var idx: int = enemies.find(target)
	if idx >= 0:
		# Ищем ближайшего живого соседа слева (пропуская погибших)
		for i in range(idx - 1, -1, -1):
			if enemies[i].is_alive():
				adjacent.append(enemies[i])
				break
		# Ищем ближайшего живого соседа справа (пропуская погибших)
		for i in range(idx + 1, enemies.size()):
			if enemies[i].is_alive():
				adjacent.append(enemies[i])
				break
		return adjacent
	# Страховка: если цель находится среди союзников (например, враг атакует отряд взрывным ударом)
	var ally_idx: int = allies.find(target)
	if ally_idx >= 0:
		for i in range(ally_idx - 1, -1, -1):
			if allies[i].is_alive():
				adjacent.append(allies[i])
				break
		for i in range(ally_idx + 1, allies.size()):
			if allies[i].is_alive():
				adjacent.append(allies[i])
				break
	return adjacent

# Полная и исправленная версия метода подрыва DoT-эффектов с независимой детонацией каждого статуса
# Полная и исправленная версия метода подрыва DoT-эффектов с независимой детонацией каждого статуса
func explode_dots(target: CombatUnit, attacker: CombatUnit, efficiency: float = 1.0) -> int:
	var exploded_count: int = 0
	if target.statuses.suppression_is_dot and target.statuses.suppression_stacks > 0:
		var marina := get_marina_unit()
		if marina and marina.is_alive():
			var dot := DamageCalculator.calc_dot_damage(marina, 0.15 * target.statuses.suppression_stacks)
			deal_damage(target, dot * efficiency, marina, CombatConstants.Element.ICE, false, "DoT")
			log_message("Взрыв Подавления на %s: %d" % [target.display_name, int(dot * efficiency)])
			exploded_count += 1
	
	# --- НААМА: Взрыв Опьянения вне своего хода ---
	if target.has_meta("naama_intox_stacks") and int(target.get_meta("naama_intox_stacks", 0)) > 0:
		NaamaAbilities.trigger_intoxication_explosion(target, attacker, self, efficiency)
		exploded_count += 1
		
	if target.statuses.entanglement_stacks > 0:
		var dot := DamageCalculator.calc_dot_damage(_get_last_attacker_or_default(), 0.20 * float(target.statuses.entanglement_stacks))
		deal_damage(target, dot * efficiency, _get_last_attacker_or_default(), _get_last_attacker_or_default().element, false, "DoT")
		log_message("Взрыв Связывания на %s: %d" % [target.display_name, int(dot * efficiency)])
		exploded_count += 1
		
	if target.statuses.break_status != "":
		var dot := DamageCalculator.calc_dot_damage(_get_last_attacker_or_default(), 0.30)
		deal_damage(target, dot * efficiency, _get_last_attacker_or_default(), _get_last_attacker_or_default().element, false, "DoT")
		log_message("Взрыв пробоя (%s) на %s: %d" % [target.statuses.break_status, target.display_name, int(dot * efficiency)])
		exploded_count += 1
		
	# ИСПРАВЛЕНО: Две независимые изолированные проверки для раздельного взрыва каждого статуса урона!
	
	# 1. ОТДЕЛЬНЫЙ ВЗРЫВ: Стандартное Горение Сёдзи (120% СА)
	if target.has_meta("shoji_burn_turns") and int(target.get_meta("shoji_burn_turns", 0)) > 0:
		var talent_mult := 1.20
		if attacker.eidolon >= 5:
			talent_mult *= 1.20 # E5
			
		var dot_res: Dictionary = calc_dmg(attacker, target, talent_mult, 0.0, false, 0.0, 0.0, false, false)
		var dot_dmg: float = float(dot_res.get("damage", 0.0))
		
		if attacker.eidolon >= 2:
			dot_dmg *= 1.30
			
		# Е6 Сёдзи: доп. взрывной урон
		if attacker.eidolon >= 6:
			var bonus_mult := 0.60
			var e6_res: Dictionary = calc_dmg(attacker, target, bonus_mult, 0.0, false, 0.0, 0.0, false, false)
			dot_dmg += float(e6_res.get("damage", 0.0))
			log_message("Эйдолон 6 Сёдзи: доп. взрывное Горение наносит %d." % int(float(e6_res.get("damage", 0.0))))
			
		deal_damage(target, dot_dmg * efficiency, attacker, CombatConstants.Element.FIRE, false, "DoT")
		log_message("Взрыв Горения Сёдзи на %s: %d урона." % [target.display_name, int(dot_dmg * efficiency)])
		exploded_count += 1

	# 2. ОТДЕЛЬНЫЙ ВЗРЫВ: Сияние от Идеального Метаморфоза (120% СА)
	if target.has_meta("radiance_status_turns") and int(target.get_meta("radiance_status_turns", 0)) > 0:
		var talent_mult := 0.80
		if attacker.eidolon >= 5:
			talent_mult *= 1.20 # E5
			
		var dot_res: Dictionary = calc_dmg(attacker, target, talent_mult, 0.0, false, 0.0, 0.0, false, false)
		var dot_dmg: float = float(dot_res.get("damage", 0.0))
		
		if attacker.eidolon >= 2:
			dot_dmg *= 1.30
			
		# Е6 Сёдзи: доп. взрывной урон
		if attacker.eidolon >= 6:
			var bonus_mult := 0.60
			var e6_res: Dictionary = calc_dmg(attacker, target, bonus_mult, 0.0, false, 0.0, 0.0, false, false)
			dot_dmg += float(e6_res.get("damage", 0.0))
			log_message("Эйдолон 6 Сёдзи: доп. взрывное Сияние наносит %d." % int(float(e6_res.get("damage", 0.0))))
			
		deal_damage(target, dot_dmg * efficiency, attacker, CombatConstants.Element.FIRE, false, "DoT")
		log_message("Взрыв Сияния Метаморфоза на %s: %d урона." % [target.display_name, int(dot_dmg * efficiency)])
		exploded_count += 1
	
	if target.has_meta("jeff_bass_listen_turns") and int(target.get_meta("jeff_bass_listen_turns", 0)) > 0:
		var jeff := get_jeff_unit()
		if jeff and jeff.is_alive():
			var dot_mult := 0.80 # Базовый коэффициент Шока 80% СА
			
			if jeff.eidolon >= 2 and check_nihility_allies_e2():
				dot_mult *= 1.50
				
			var dot_res: Dictionary = calc_dmg(jeff, target, dot_mult, 0.0, false, 0.0, 0.0, false, false, "DoT")
			var dot_dmg: float = float(dot_res.get("damage", 0.0))
			
			deal_damage(target, dot_dmg * efficiency, jeff, CombatConstants.Element.LIGHTNING, false, "DoT")
			log_message("🎶 Бассы! Слушай! (Взрыв) на %s: нанесено %d урона (%d%% эффективности)." % [target.display_name, int(dot_dmg * efficiency), int(efficiency * 100.0)])
			exploded_count += 1

	return exploded_count
				
func execute_dasha_bonus_attack(attacker: CombatUnit) -> void:
	if has_meta("lenskaya_fua_attacker_credited"):
		remove_meta("lenskaya_fua_attacker_credited")
	log_message("★ БОНУС-АТАКА Даши активирована!")
	
	var is_overload: bool = attacker.has_meta("overload_turns") and int(attacker.get_meta("overload_turns", 0)) > 0
	var enemy_count: int = get_living_enemies().size()
	
	var be_val: float = attacker.stats.break_effect
	var hp_pct: float = attacker.stats.hp / attacker.stats.max_hp
	if hp_pct > 0.50:
		var excess_hp_pct: float = (hp_pct - 0.50) * 100.0
		be_val += excess_hp_pct * 0.015
		
	var mult: float = 0.0
	var flat_damage: float = 0.0
	if is_overload:
		mult = 0.20 * be_val + 1.50
		flat_damage = 50.0 * float(enemy_count)
	else:
		mult = 0.10 * be_val + 1.40
		flat_damage = 20.0 * float(enemy_count)
		
	if attacker.eidolon >= 5:
		mult *= 1.20
		flat_damage *= 1.20
		
	var targets := get_living_enemies()
	for enemy in targets:
		var def_ignore := 0.0
		var extra_mult := 1.0
		if attacker.eidolon >= 6:
			def_ignore = 0.20
			if targets.size() == 1:
				extra_mult = 2.0
				log_message("Эйдолон 6 Даши: Бонус-атака по единственной цели наносит удвоенный урон!")
				
		var old_def := enemy.stats.def
		enemy.stats.def *= (1.0 - def_ignore)
		
		var result := calc_dmg(attacker, enemy, mult, 0.0, false, 0.0, 0.0, false, true, "Бонус-атака")
		var bonus_dmg: float = (float(result.get("damage", 0.0)) + flat_damage) * extra_mult
		
		enemy.stats.def = old_def
		
		deal_damage(enemy, bonus_dmg, attacker, attacker.element, result.crit, "Бонус-атака")
		ToughnessSystem.apply_weakness_hit(attacker, enemy, self)
		
	if attacker.eidolon >= 2 and not _has_abundance_ally():
		var heal_pct: float = 50.0 * be_val
		var heal_amount: float = attacker.stats.max_hp * (heal_pct / 100.0)
		heal_unit(attacker, heal_amount)
		log_message("Эйдолон 2 Даши: Восстановлено %d ХП (лечение от ЭП)." % int(heal_amount))
		
	if has_meta("lenskaya_fua_attacker_credited"):
		remove_meta("lenskaya_fua_attacker_credited")

func _has_abundance_ally() -> bool:
	for ally in allies:
		if ally.path == CombatConstants.Path.ABUNDANCE and ally.is_alive():
			return true
	return false

func apply_shield(unit: CombatUnit, amount: float, turns: int, source_name: String) -> void:
	if unit.has_meta("relic_shield_strength_pct"):
		amount *= (1.0 + float(unit.get_meta("relic_shield_strength_pct", 0.0)))
	var current_val: float = float(unit.get_meta("shield_value", 0.0))
	
	if (unit.id == "danill" or unit.id == "danila") and unit.get_meta("e_shield_active", false):
		if "Ульта" in source_name or "Ult" in source_name:
			unit.set_meta("shield_turns", turns)
			
			if amount > current_val:
				unit.set_meta("shield_value", amount)
				log_message("Щит Данилла перекрыт ультимейтом: прочность обновлена до %d, длительность продлена до %d х." % [int(amount), turns])
			else:
				log_message("Щит Данилла сохранил прочность %d, длительность продлена до %d х." % [int(current_val), turns])
			
			if current_unit == unit:
				unit.set_meta("shield_skip_tick", true)
				
			combat_text_spawned.emit(unit, "Щит: %d" % int(unit.get_meta("shield_value")), Color(0.7, 0.7, 0.7), "", false)
			unit_updated.emit(unit)
			return
	
	if amount >= current_val:
		unit.set_meta("shield_value", amount)
		unit.set_meta("shield_turns", turns)
		unit.set_meta("shield_source", source_name)
		
		if current_unit == unit:
			unit.set_meta("shield_skip_tick", true)
			
		combat_text_spawned.emit(unit, "Щит: %d" % int(amount), Color(0.7, 0.7, 0.7), "", false)
	else:
		var current_turns := int(unit.get_meta("shield_turns", 0))
		if turns > current_turns:
			unit.set_meta("shield_turns", turns)
			log_message("Длительность щита %s продлена до %d х." % [unit.display_name, turns])
			combat_text_spawned.emit(unit, "Щит: %d" % int(current_val), Color(0.7, 0.7, 0.7), "", false)
			
	unit_updated.emit(unit)
	
# === НАЙДИТЕ И ОБНОВИТЕ ЭТОТ МЕТОД В BATTLE_MANAGER.GD ===
func update_milena_overtone_spd_buff(_unit: CombatUnit, active: bool) -> void:
	for ally in allies:
		if ally.id != "milena" and ally.is_alive():
			var has_buff: bool = ally.get_meta("milena_overtone_spd_active", false)
			
			# Считываем ОРИГИНАЛЬНУЮ чистую базу скорости союзника (без учета реликвий)
			var base_spd: float = float(ally.get_meta("base_spd_original", ally.stats.spd))
			var flat_spd_bonus: float = base_spd * 0.15 # Ровно 15% от чистой базы
			
			if active and not has_buff:
				ally.set_meta("milena_overtone_spd_active", true)
				# Запоминаем точное начисленное плоское значение для последующего корректного снятия
				ally.set_meta("milena_overtone_spd_val", flat_spd_bonus)
				
				ally.add_speed_modifier(0.0, flat_spd_bonus)
				ally.recalculate_action_value()
				action_order_changed.emit()
			elif not active and has_buff:
				var applied_val: float = float(ally.get_meta("milena_overtone_spd_val", flat_spd_bonus))
				ally.set_meta("milena_overtone_spd_active", false)
				
				ally.remove_speed_modifier(0.0, applied_val)
				ally.recalculate_action_value()
				action_order_changed.emit()
				
func _on_danill_e_shield_broken(danill: CombatUnit) -> void:
	if has_meta("lenskaya_fua_attacker_credited"):
		remove_meta("lenskaya_fua_attacker_credited")
	if not danill.get_meta("e_shield_active", false):
		return
	danill.set_meta("e_shield_active", false)
	log_message("★ След Данилла: Усиленный щит навыка E рассеялся!")
	
	var def_val: float = get_effective_def_complete(danill) # ИСПРАВЛЕНО
	var stacks: int = int(danill.get_meta("danill_talent_stacks", 0))
	def_val *= (1.0 + 0.10 * float(stacks))
	if danill.has_meta("danill_trace3_def_buff") and danill.get_meta("danill_trace3_def_buff"):
		def_val *= 1.30
		
	var bonus_dmg: float = def_val * 0.40
	var enemies_list := get_living_enemies()
	for enemy in enemies_list:
		var res := calc_dmg(danill, enemy, 0.40, 0.0, false, 0.0, 0.0, false, true, "Бонус-атака")
		deal_damage(enemy, res.damage, danill, danill.element, res.crit, "Бонус-атака")
		ToughnessSystem.apply_weakness_hit(danill, enemy, self)
		
	log_message("Бонус-атака Данилла нанесла %d урона всем врагам." % int(bonus_dmg))
	gain_skill_point()
	log_message("След Данилла: Восстановлено 1 ОД!")
	
	if has_meta("lenskaya_fua_attacker_credited"):
		remove_meta("lenskaya_fua_attacker_credited")
	
func _apply_relic_effects(unit: CombatUnit, relics: Dictionary) -> void:
	if relics.is_empty() and TeamConfig.get_equipped_relics(unit.id).is_empty():
		return
		
	# Проверяем, есть ли индивидуальные реликвии новой системы
	var equipped_relics: Dictionary = {}
	if relics.has("slots") and relics["slots"] is Dictionary and not relics["slots"].is_empty():
		for slot_name in relics["slots"]:
			var slot_val = relics["slots"][slot_name]
			if slot_val is Dictionary:
				equipped_relics[slot_name] = slot_val
			elif slot_val is String or slot_val is StringName:
				var uid: String = String(slot_val)
				var r_dict: Dictionary = TeamConfig.get_relic(uid)
				if not r_dict.is_empty():
					equipped_relics[slot_name] = r_dict
	elif not TeamConfig.get_equipped_relics(unit.id).is_empty():
		equipped_relics = TeamConfig.get_equipped_relics(unit.id)
		
	var cavern_set_1: String = ""
	var cavern_set_2: String = ""
	var planar_set: String = ""
	
	var relic_atk_pct: float = 0.0
	var relic_def_pct: float = 0.0
	var relic_hp_pct: float = 0.0
	
	if not equipped_relics.is_empty():
		# 1. Применяем характеристики каждой надетой реликвии (основные статы + сабстаты)
		for slot_name in equipped_relics:
			var r: Dictionary = equipped_relics[slot_name]
			var stats_to_apply: Array[Dictionary] = []
			
			var m_stat: Dictionary = r.get("main_stat", {})
			if not m_stat.is_empty():
				stats_to_apply.append(m_stat)
			for s in r.get("substats", []):
				if s is Dictionary:
					stats_to_apply.append(s)
					
			for st in stats_to_apply:
				var s_type: String = String(st.get("type", ""))
				var s_val: float = float(st.get("value", 0.0))
				match s_type:
					"flat_hp":
						unit.stats.max_hp += s_val
					"flat_atk":
						unit.stats.atk += s_val
					"flat_def":
						unit.stats.def += s_val
					"hp_pct":
						relic_hp_pct += s_val
					"atk_pct":
						relic_atk_pct += s_val
					"def_pct":
						relic_def_pct += s_val
					"crit_rate":
						unit.stats.crit_rate += s_val
					"crit_dmg":
						unit.stats.crit_dmg += s_val
					"speed":
						unit.add_speed_modifier(0.0, s_val)
						unit.set_meta("relic_speed_flat", float(unit.get_meta("relic_speed_flat", 0.0)) + s_val)
						unit.recalculate_action_value()
					"ehr":
						unit.stats.effect_hit_rate += s_val
					"heal":
						unit.set_meta("relic_heal_bonus", float(unit.get_meta("relic_heal_bonus", 0.0)) + s_val)
					"break_effect":
						unit.stats.break_effect += s_val
					"err":
						unit.set_meta("relic_err_bonus", float(unit.get_meta("relic_err_bonus", 0.0)) + s_val)
					"phys_dmg":
						if unit.element == CombatConstants.Element.PHYSICAL:
							unit.stats.damage_bonus += s_val
					"fire_dmg":
						if unit.element == CombatConstants.Element.FIRE:
							unit.stats.damage_bonus += s_val
					"ice_dmg":
						if unit.element == CombatConstants.Element.ICE:
							unit.stats.damage_bonus += s_val
					"lightning_dmg":
						if unit.element == CombatConstants.Element.LIGHTNING:
							unit.stats.damage_bonus += s_val
					"wind_dmg":
						if unit.element == CombatConstants.Element.WIND:
							unit.stats.damage_bonus += s_val
					"quantum_dmg":
						if unit.element == CombatConstants.Element.QUANTUM:
							unit.stats.damage_bonus += s_val
					"imaginary_dmg":
						if unit.element == CombatConstants.Element.IMAGINARY:
							unit.stats.damage_bonus += s_val
							
		# 2. Подсчет сетовых бонусов из надетых частей
		var cavern_counts: Dictionary = {}
		for c_slot in RelicSystem.CAVERN_SLOTS:
			if equipped_relics.has(c_slot):
				var s_id: String = String(equipped_relics[c_slot].get("set_id", ""))
				if not s_id.is_empty():
					cavern_counts[s_id] = cavern_counts.get(s_id, 0) + 1
					
		for s_id in cavern_counts:
			if cavern_counts[s_id] >= 4:
				cavern_set_1 = s_id
				cavern_set_2 = ""
				break
			elif cavern_counts[s_id] >= 2:
				if cavern_set_1.is_empty():
					cavern_set_1 = s_id
				elif cavern_set_2.is_empty() and cavern_set_1 != s_id:
					cavern_set_2 = s_id
					
		if equipped_relics.has("sphere") and equipped_relics.has("rope"):
			var sph_s: String = String(equipped_relics["sphere"].get("set_id", ""))
			var rope_s: String = String(equipped_relics["rope"].get("set_id", ""))
			if sph_s == rope_s and not sph_s.is_empty():
				planar_set = sph_s
				unit.set_meta("planar_set", planar_set)
				
		unit.set_meta("base_hp_original", unit.stats.max_hp)
		unit.set_meta("base_atk_original", unit.stats.atk)
		unit.set_meta("base_def_original", unit.stats.def)
		unit.set_meta("base_spd_original", unit.stats.spd)
	else:
		cavern_set_1 = String(relics.get("cavern_set_1", ""))
		cavern_set_2 = String(relics.get("cavern_set_2", ""))
		var has_cavern_set: bool = (cavern_set_1 != "")
		
		# 1. СНАЧАЛА ПРИМЕНЯЕМ ПЛОСКИЕ ХАРАКТЕРИСТИКИ ГОЛОВЫ И РУК (ОНИ ВХОДЯТ В ПОСТОЯННЫЕ)
		if has_cavern_set:
			unit.stats.max_hp += 350.0
			unit.stats.atk += 175.0
			
		# 2. КЭШИРУЕМ ПОСТОЯННЫЕ ХАРАКТЕРИСТИКИ (ОНИ ВКЛЮЧАЮТ ГОЛОВУ И РУКИ, НО НЕ ВКЛЮЧАЮТ ПРОЦЕНТЫ)
		unit.set_meta("base_hp_original", unit.stats.max_hp)
		unit.set_meta("base_atk_original", unit.stats.atk)
		unit.set_meta("base_def_original", unit.stats.def)
		unit.set_meta("base_spd_original", unit.stats.spd)
		
		if has_cavern_set:
			# Тело и Ноги: процентные прибавки будут отталкиваться от новых постоянных чисел
			var body_stat: String = String(relics.get("body", ""))
			match body_stat:
				"atk_pct": relic_atk_pct += 0.21
				"def_pct": relic_def_pct += 0.26
				"ehr": unit.stats.effect_hit_rate += 0.21
				"hp_pct": relic_hp_pct += 0.21
				"heal": unit.set_meta("relic_heal_bonus", float(unit.get_meta("relic_heal_bonus", 0.0)) + 0.17)
				"crit_rate": unit.stats.crit_rate += 0.16
				"crit_dmg": unit.stats.crit_dmg += 0.32
				
			var feet_stat: String = String(relics.get("feet", ""))
			match feet_stat:
				"atk_pct": relic_atk_pct += 0.21
				"hp_pct": relic_hp_pct += 0.21
				"def_pct": relic_def_pct += 0.26
				"speed":
					unit.add_speed_modifier(0.0, 12.0)
					unit.set_meta("relic_speed_flat", 12.0)
					unit.recalculate_action_value()

		planar_set = String(relics.get("planar_set", ""))
		var has_planar_set: bool = (planar_set != "")
		
		if has_planar_set:
			unit.set_meta("planar_set", planar_set)
			
			var sphere_stat: String = String(relics.get("sphere", ""))
			var sphere_matched_element: int = -1
			match sphere_stat:
				"phys_dmg": sphere_matched_element = CombatConstants.Element.PHYSICAL
				"ice_dmg": sphere_matched_element = CombatConstants.Element.ICE
				"fire_dmg": sphere_matched_element = CombatConstants.Element.FIRE
				"wind_dmg": sphere_matched_element = CombatConstants.Element.WIND
				"lightning_dmg": sphere_matched_element = CombatConstants.Element.LIGHTNING
				"quantum_dmg": sphere_matched_element = CombatConstants.Element.QUANTUM
				"imaginary_dmg": sphere_matched_element = CombatConstants.Element.IMAGINARY
			
			if sphere_matched_element != -1:
				if unit.element == sphere_matched_element:
					unit.stats.damage_bonus += 0.19
					unit.set_meta("relic_dmg_bonus", 0.19)
					unit.set_meta("relic_elemental_type", sphere_stat)
					log_message("🛡 Релики: Наложен бонус стихийного урона +19%% для %s." % unit.display_name)
				else:
					log_message("🛡 Релики: Сфера %s не подходит элементу %s (урон не начислен)." % [sphere_stat, unit.display_name])
			elif sphere_stat == "atk_pct":
				relic_atk_pct += 0.21
			elif sphere_stat == "def_pct":
				relic_def_pct += 0.26
			elif sphere_stat == "hp_pct":
				relic_hp_pct += 0.21
				
			var rope_stat: String = String(relics.get("rope", ""))
			match rope_stat:
				"atk_pct": relic_atk_pct += 0.21
				"hp_pct": relic_hp_pct += 0.21
				"def_pct": relic_def_pct += 0.26
				"break_effect": unit.stats.break_effect += 0.32
				"err": unit.set_meta("relic_err_bonus", 0.10)
			
	# --- 3. АКТИВАЦИЯ ЭФФЕКТОВ НАБОРОВ (РАССЧИТЫВАЕТСЯ ДО ПРИМЕНЕНИЯ ПРОЦЕНТОВ К СТАТАМ) ---
	var is_symbiosis_2: bool = (cavern_set_1 == "symbiosis" or cavern_set_2 == "symbiosis")
	var is_symbiosis_4: bool = (cavern_set_1 == "symbiosis" and cavern_set_2 == "")
	var is_chaos_2: bool = (cavern_set_1 == "chaos" or cavern_set_2 == "chaos")
	var is_chaos_4: bool = (cavern_set_1 == "chaos" and cavern_set_2 == "")
	var is_mortal_world_2: bool = (cavern_set_1 == "mortal_world" or cavern_set_2 == "mortal_world")
	var is_mortal_world_4: bool = (cavern_set_1 == "mortal_world" and cavern_set_2 == "")
	var is_lava_fighter_2: bool = (cavern_set_1 == "lava_fighter" or cavern_set_2 == "lava_fighter")
	var is_lava_fighter_4: bool = (cavern_set_1 == "lava_fighter" and cavern_set_2 == "")
	var is_light_gift_2: bool = (cavern_set_1 == "light_gift" or cavern_set_2 == "light_gift")
	var is_light_gift_4: bool = (cavern_set_1 == "light_gift" and cavern_set_2 == "")
	var is_hope_beam_2: bool = (cavern_set_1 == "hope_beam" or cavern_set_2 == "hope_beam")
	var is_hope_beam_4: bool = (cavern_set_1 == "hope_beam" and cavern_set_2 == "")
	var is_rapid_response_2: bool = (cavern_set_1 == "rapid_response" or cavern_set_2 == "rapid_response")
	var is_rapid_response_4: bool = (cavern_set_1 == "rapid_response" and cavern_set_2 == "")
	var is_biology_doctor_2: bool = (cavern_set_1 == "biology_doctor" or cavern_set_2 == "biology_doctor")
	var is_biology_doctor_4: bool = (cavern_set_1 == "biology_doctor" and cavern_set_2 == "")
	var is_dying_planet_2: bool = (cavern_set_1 == "dying_planet" or cavern_set_2 == "dying_planet")
	var is_dying_planet_4: bool = (cavern_set_1 == "dying_planet" and cavern_set_2 == "")
	# Регистрация 2-частных и 4-частных комплектов версии 1.1 и 1.2
	var is_lost_self_2: bool = (cavern_set_1 == "lost_self" or cavern_set_2 == "lost_self")
	var is_lost_self_4: bool = (cavern_set_1 == "lost_self" and cavern_set_2 == "")
	var is_galilean_2: bool = (cavern_set_1 == "galilean" or cavern_set_2 == "galilean")
	var is_galilean_4: bool = (cavern_set_1 == "galilean" and cavern_set_2 == "")
	var is_silhouette_2: bool = (cavern_set_1 == "silhouette" or cavern_set_2 == "silhouette")
	var is_silhouette_4: bool = (cavern_set_1 == "silhouette" and cavern_set_2 == "")
	var is_accepted_sin_2: bool = (cavern_set_1 == "accepted_sin" or cavern_set_2 == "accepted_sin")
	var is_accepted_sin_4: bool = (cavern_set_1 == "accepted_sin" and cavern_set_2 == "")
	var is_bereft_future_2: bool = (cavern_set_1 == "bereft_future" or cavern_set_2 == "bereft_future")
	var is_bereft_future_4: bool = (cavern_set_1 == "bereft_future" and cavern_set_2 == "")
	
	# Сет 1: Жертва долгого симбиоза
	if is_symbiosis_2 and unit.element == CombatConstants.Element.ICE:
		unit.stats.damage_bonus += 0.10
	if is_symbiosis_4:
		unit.stats.effect_hit_rate += 0.12
		unit.set_meta("set_symbiosis_4", true)
		
	# Сет 2: Истинный родоначальник хаоса
	if is_chaos_2 and unit.element == CombatConstants.Element.QUANTUM:
		unit.stats.damage_bonus += 0.10
	if is_chaos_4:
		unit.set_meta("set_chaos_4", true)
		
	# Сет 3: Отпор бренного мира
	if is_mortal_world_2 and unit.element == CombatConstants.Element.PHYSICAL:
		unit.stats.damage_bonus += 0.10
	if is_mortal_world_4:
		unit.stats.weakness_efficiency += 0.15 
		unit.set_meta("set_mortal_world_4", true)

	# Сет 4: Боец огня и лавы
	if is_lava_fighter_2 and unit.element == CombatConstants.Element.FIRE:
		unit.stats.damage_bonus += 0.10
	if is_lava_fighter_4:
		unit.set_meta("set_lava_fighter_4", true)

	# Сет 5: Принявший дар света
	if is_light_gift_2 and unit.element == CombatConstants.Element.LIGHTNING:
		unit.stats.damage_bonus += 0.10
	if is_light_gift_4:
		unit.set_meta("set_light_gift_4", true)

	# Сет 6: Дающий луч надежды путник
	if is_hope_beam_2 and unit.element == CombatConstants.Element.IMAGINARY:
		unit.stats.damage_bonus += 0.10
	if is_hope_beam_4:
		unit.set_meta("set_hope_beam_4", true)

	# Сет 7: Отряд быстрого реагирования
	if is_rapid_response_2 and unit.element == CombatConstants.Element.WIND:
		unit.stats.damage_bonus += 0.10
	if is_rapid_response_4:
		unit.set_meta("set_rapid_response_4", true)
		
	# Сет 8: Доктор биологических наук (исходящее исцеление)
	if is_biology_doctor_2:
		unit.set_meta("relic_heal_bonus", float(unit.get_meta("relic_heal_bonus", 0.0)) + 0.10)
	if is_biology_doctor_4:
		unit.set_meta("set_biology_doctor_4", true)
		
	# Сет 9: Оборона умирающей планеты (защита и щиты)
	if is_dying_planet_2:
		relic_def_pct += 0.15 # Добавляем к проценту защиты ДО применения
	if is_dying_planet_4:
		unit.set_meta("relic_shield_strength_pct", 0.20)
		
	# Сет: Потерянное в вечности «Я» (+15% СА)
	if is_lost_self_2:
		relic_atk_pct += 0.15
	if is_lost_self_4:
		unit.set_meta("set_lost_self_4", true)
		
	# Сет: Галилеянин изолированного мира (+20% урон бонус-атак базово)
	if is_galilean_2:
		unit.set_meta("set_galilean_2", true)
	if is_galilean_4:
		unit.set_meta("set_galilean_4", true)
		
	# Сет: Прячущийся во тьме силуэт (+16% Крит. урона)
	if is_silhouette_2:
		unit.stats.crit_dmg += 0.16
	if is_silhouette_4:
		unit.set_meta("set_silhouette_4", true)
		
	# Сет: Принявший грех глава (+12% ХП)
	if is_accepted_sin_2:
		relic_hp_pct += 0.12
	if is_accepted_sin_4:
		unit.set_meta("set_accepted_sin_4", true)
		
	# Сет: Исследователь отнятого будущего (+6% скорости)
	if is_bereft_future_2:
		unit.add_speed_modifier(0.06, 0.0)
	if is_bereft_future_4:
		unit.set_meta("set_bereft_future_4", true)
		
	# ПЛАНАРНЫЕ НАБОРЫ (Базовое безусловное начисление)
	if planar_set == "lost_edge":
		relic_hp_pct += 0.12 # Базовые +12% ХП начисляются всегда
		unit.set_meta("has_set_lost_edge", true) # Вешаем маркер для динамического баффа пати

	# Свободный остров Япония (+15% защиты, доп. +15% если ШПЭ >= 50%)
	if planar_set == "japan_island":
		relic_def_pct += 0.15 # Базовые +15% Защиты
		if unit.stats.effect_hit_rate >= 0.50:
			relic_def_pct += 0.15 # Дополнительные +15% Защиты (ШПЭ статичен на старте)

	# Краснодар - сердце апокалипсиса
	if planar_set == "krasnodar":
		unit.stats.crit_rate += 0.08 # Базовые +8% Крита
		unit.set_meta("has_set_krasnodar", true) # Вешаем маркер для динамического баффа ульты
			
	# Сияющий Детройт (+12% СА базово)
	if planar_set == "detroit":
		relic_atk_pct += 0.12 # Базовые +12% Силы Атаки начисляются всегда
		unit.set_meta("has_set_detroit", true) # Вешаем маркер для динамического баффа +12% СА при скорости >= 120
		
	# Сет: Другая сторона вселенной
	if planar_set == "other_side_universe":
		unit.stats.crit_rate += 0.12
		unit.set_meta("has_set_other_side_universe", true)
		
	# Сет: Погрязший в руинах Иркутск
	if planar_set == "irkutsk":
		unit.set_meta("has_set_irkutsk", true)
			
	# --- 4. ПРИМЕНЕНИЕ ВСЕХ НАКОПЛЕННЫХ ПРОЦЕНТОВ К СТАТАМ ---
	# ИСПРАВЛЕНО: Процентные модификаторы НЕ МУТИРУЮТ unit.stats.atk и unit.stats.def напрямую!
	# Они сохраняются в метаданные и рассчитываются динамически (СА в calc_dmg, ЗАЩ при ударах врагов)
	if relic_hp_pct > 0.0:
		unit.set_meta("relic_hp_pct", relic_hp_pct)
		unit.stats.max_hp += unit.stats.max_hp * relic_hp_pct
		
	if relic_atk_pct > 0.0:
		unit.set_meta("relic_atk_pct", relic_atk_pct)
		# unit.stats.atk остается неизменной (только база + руки)
		
	if relic_def_pct > 0.0:
		unit.set_meta("relic_def_pct", relic_def_pct)
		# unit.stats.def остается неизменной (только база)
		
	# Восстанавливаем здоровье до 100% после изменения max_hp
	unit.stats.hp = unit.stats.max_hp
		
func _handle_enemy_death_reinforcement(dead_enemy: CombatUnit) -> void:
	if battle_mode != "fiction" or dead_enemy.is_ally:
		return
		
	fiction_defeated_count += 1
	log_message("💀 Повержен солдат Пустоты (%d / 15)" % fiction_defeated_count)
	
	var idx: int = enemies.find(dead_enemy) # Явно типизирован int
	if idx == -1:
		return
		
	if fiction_max_pool > 0:
		fiction_max_pool -= 1
		
		# Создаём абсолютно чистого нового юнита
		var new_soldier: CombatUnit = VoidSoldier.create_unit() # Явно типизирован CombatUnit
		new_soldier.slot_index = idx # Закрепляем за тем же слотом
		
		# Задаем чистую шкалу AV без хвостов
		new_soldier.recalculate_action_value()
		new_soldier.action_value = new_soldier.base_action_value
		
		# Кэшируем его оригинальные статы для Инфо
		new_soldier.set_meta("base_hp_original", new_soldier.stats.max_hp)
		new_soldier.set_meta("base_atk_original", new_soldier.stats.atk)
		new_soldier.set_meta("base_def_original", new_soldier.stats.def)
		new_soldier.set_meta("base_spd_original", new_soldier.stats.spd)
		
		# Заменяем мертвого солдата на живого в массиве
		enemies[idx] = new_soldier
		
		log_message("📥 На поле боя вступает новый Солдат Пустоты! (Осталось в запасе: %d)" % fiction_max_pool)
		
		# Оповещаем UI, что нужно обновить связи карточек с новыми врагами
		enemies_reshuffled.emit.call_deferred()
		action_order_changed.emit()

# Мост для прямой регистрации дебаффов (гарантирует совместимость и защиту от вылетов)
func register_feel_my_presence_debuff(unit: CombatUnit, debuff_type: String) -> void:
	if unit == null or not unit.is_alive():
		return
	if unit.get_meta("light_cone_id", "") != "feel_my_presence":
		return
		
	var type_name := "Защиты" if debuff_type == "def" else ("Скорости" if debuff_type == "spd" else "Силы атаки")
	_grant_feel_presence_stack(unit, debuff_type, type_name)
	
# === ДОБАВИТЬ ЭТОТ МЕТОД В САМЫЙ НИЗ BATTLE_MANAGER.GD ===
func _evaluate_planar_start_conditions(unit: CombatUnit) -> void:
	if not unit.has_meta("planar_set"):
		return
		
	var planar_set: String = String(unit.get_meta("planar_set", ""))
	
	if planar_set == "detroit":
		var spd: float = unit.stats.get_effective_spd()
		if spd >= 120.0:
			var base_atk_val: float = float(unit.get_meta("base_atk_original", unit.stats.atk))
			var current_relic_pct: float = float(unit.get_meta("relic_atk_pct", 0.0))
			
			# Обновляем процент баффа в метаданных (было 12%, стало 24%)
			var new_relic_pct: float = current_relic_pct + 0.12
			unit.set_meta("relic_atk_pct", new_relic_pct)
			
			# Пересчитываем итоговую СА от чистой базы
			unit.stats.atk = base_atk_val * (1.0 + new_relic_pct)
			
			unit.set_meta("relic_detroit_atk_pct", 0.24)
			log_message("⚡ Сет Детройта: Скорость %s на старте боя %.0f >= 120! Получен дополнительный бонус +12%% СА." % [unit.display_name, spd])
			
	elif planar_set == "lost_edge":
		var spd: float = unit.stats.get_effective_spd()
		if spd >= 120.0:
			unit.set_meta("planar_lost_edge_active", true)
			log_message("⚡ Сет Лаборатории края: Скорость %s на старте боя %.0f >= 120! Вся пати получает +8%% СА." % [unit.display_name, spd])
			
	elif planar_set == "japan_island":
		var ehr: float = unit.stats.effect_hit_rate
		if ehr >= 0.50:
			var current_relic_def: float = float(unit.get_meta("relic_def_pct", 0.0))
			# Обновляем процент защиты в метаданных (добавляем +15%)
			unit.set_meta("relic_def_pct", current_relic_def + 0.15)
			# Мутация unit.stats.def УДАЛЕНА.
			log_message("⚡ Сет Японии: ШПЭ %s на старте боя %.0f%% >= 50%%! Получена дополнительная защита +15%% DEF." % [unit.display_name, ehr * 100.0])
			
	elif planar_set == "krasnodar":
		var cr: float = unit.stats.crit_rate
		if cr >= 0.50:
			unit.set_meta("planar_krasnodar_active", true)
			log_message("⚡ Сет Краснодара: Крит. Шанс %s на старте боя %.0f%% >= 50%%! Урон ульты и бонус-атак повышен на 15%%." % [unit.display_name, cr * 100.0])

# === НАЙДИТЕ ЭТОТ МЕТОД В САМОМ НИЗУ BATTLE_MANAGER.GD И ЗАМЕНИТЕ ЕГО ===
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В САМЫЙ НИЗУ BATTLE_MANAGER.GD ===
# Полный расчет боевой силы атаки с защитой от бесконечной рекурсии таланта Милены
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В BATTLE_MANAGER.GD ===
func get_effective_atk_complete(unit: CombatUnit) -> float:
	if unit == null:
		return 0.0
		
	var s := unit.stats
	var relic_atk_pct_val: float = float(unit.get_meta("relic_atk_pct", 0.0))
	
	
	if unit.id == "valramors":
		var is_active := (unit.slot_index == 0) or (unit.eidolon >= 6)
		if is_active:
			var ehr := ValramorsAbilities.get_valramors_ehr(unit)
			relic_atk_pct_val += ehr # Прибавляем ШПЭ (например, 0.60 для +60% СА) в проценты реликвий
			
	var lc_pct_val: float = 0.0
	if unit.has_meta("lc_atk_pct_bonus"):
		lc_pct_val = float(unit.get_meta("lc_atk_pct_bonus", 0.0))
		
	var detroit_dynamic_atk_pct := 0.0
	if unit.has_meta("has_set_detroit"):
		if s.get_effective_spd() >= 120.0:
			detroit_dynamic_atk_pct = 0.12
	
	var dasha_e1_flat: float = 0.0
	if unit.id == "dasha_admin" and unit.eidolon >= 1:
		var eff_def := get_effective_def_complete(unit)
		if eff_def > 3000.0:
			dasha_e1_flat += floorf((eff_def - 3000.0) / 100.0) * 150.0
			
	# Независимые баффы силы атаки от новых конусов
	var stage_partner_pct: float = 0.0
	if unit.has_meta("stage_partner_turns") and int(unit.get_meta("stage_partner_turns", 0)) > 0:
		stage_partner_pct = 0.15
		
	# Независимый дебафф силы атаки от Таланта Валраморса (-15% СА)
	var valramors_debuff_pct: float = 0.0
	if unit.has_meta("valramors_talent_turns") and int(unit.get_meta("valramors_talent_turns", 0)) > 0:
		valramors_debuff_pct = -0.15

	var blazing_sun_pct: float = 0.0
	if unit.has_meta("blazing_sun_turns") and int(unit.get_meta("blazing_sun_turns", 0)) > 0:
		blazing_sun_pct = 0.40
		
	var lost_edge_count: int = 0
	for ally in allies:
		if ally.is_alive() and ally.has_meta("has_set_lost_edge"):
			if ally.stats.get_effective_spd() >= 120.0:
				lost_edge_count += 1
				
	var lost_edge_bonus: float = 0.08 * float(lost_edge_count)
	
	var q_pct: float = 0.0
	var q_flat: float = 0.0
	if unit.has_meta("arseniy_q_turns") and int(unit.get_meta("arseniy_q_turns", 0)) > 0:
		q_pct = float(unit.get_meta("arseniy_q_atk_percent", 0.0))
		q_flat = float(unit.get_meta("arseniy_q_atk_flat", 0.0))
		
	var faction_pct: float = 0.0
	if unit.has_meta("faction_chaos_atk_pct"):
		faction_pct += float(unit.get_meta("faction_chaos_atk_pct", 0.0))
	if unit.has_meta("faction_empyrean_atk_pct"):
		faction_pct += float(unit.get_meta("faction_empyrean_atk_pct", 0.0))
	
	var relic_flat_atk: float = 0.0
	if unit.has_meta("relic_galilean_atk_pct"):
		relic_flat_atk += unit.stats.atk * float(unit.get_meta("relic_galilean_atk_pct", 0.0))
	if unit.has_meta("relic_silhouette_atk_pct"):
		relic_flat_atk += unit.stats.atk * float(unit.get_meta("relic_silhouette_atk_pct", 0.0))
	

	# След 2 Айзека: +30% СА на 2 хода после использования Навыка Е
	var isaac_trace2_pct: float = 0.0
	if unit.has_meta("isaac_admin_trace2_atk_turns") and int(unit.get_meta("isaac_admin_trace2_atk_turns", 0)) > 0:
		isaac_trace2_pct = 0.30
		
	var milena_flat_atk: float = 0.0
	var milena_overtone_pct: float = 0.0
	var milena_unit := get_milena_unit()
	if milena_unit and milena_unit.is_alive() and unit.is_ally:
		# ИСПРАВЛЕНО: Рекурсивный вызов перенесен внутрь проверки. Бесконечный цикл устранен.
		if unit.id != "milena":
			var milena_eff_atk: float = get_effective_atk_complete(milena_unit)
			milena_flat_atk += milena_eff_atk * 0.05
			if int(milena_unit.get_meta("milena_overtone_turns", 0)) > 0:
				milena_overtone_pct = 0.30
			
	var vika_flat: float = 0.0
	if unit.id == "vika" and unit.has_meta("vika_e_atk_buff"):
		vika_flat = float(unit.get_meta("vika_e_atk_buff", 0.0))
		
	var keloist_flat_atk_buff_val: float = 0.0
	if unit.has_meta("keloist_flat_atk_buff"):
		keloist_flat_atk_buff_val = float(unit.get_meta("keloist_flat_atk_buff", 0.0))
		
	var standard_pct: float = unit.statuses.self_atk_buff_percent + unit.statuses.atk_buff_percent
	var standard_flat: float = unit.statuses.atk_buff_flat
	
	var lenskaya_t3_pct := 0.0
	if unit.has_meta("lenskaya_trace3_atk_percent"):
		lenskaya_t3_pct = float(unit.get_meta("lenskaya_trace3_atk_percent", 0.0))
	
	# Прибавка силы атаки союзникам от Остатков золота Жоана (+4% за стак)
	var joan_gold_pct := 0.0
	var js_unit := get_joan_spirit_unit()
	if js_unit and js_unit.is_alive() and unit.is_ally:
		var gold_stacks: int = int(js_unit.get_meta("joan_gold_remnants", 0))
		joan_gold_pct = float(gold_stacks) * 0.04
	
	var shoji_swan_atk_pct := 0.0
	if unit.has_meta("shoji_swan_atk_turns") and int(unit.get_meta("shoji_swan_atk_turns", 0)) > 0:
		shoji_swan_atk_pct = 0.50

	var save_world_plan_atk_pct := 0.0
	if unit.has_meta("save_world_plan_stacks"):
		save_world_plan_atk_pct = 0.04 * float(unit.get_meta("save_world_plan_stacks", 0))
		
	var eff_atk: float = s.atk * (1.0 + standard_pct + q_pct + faction_pct + lc_pct_val + lost_edge_bonus + detroit_dynamic_atk_pct + relic_atk_pct_val + milena_overtone_pct + lenskaya_t3_pct + joan_gold_pct + stage_partner_pct + blazing_sun_pct + valramors_debuff_pct + isaac_trace2_pct + shoji_swan_atk_pct + save_world_plan_atk_pct) + standard_flat + q_flat + vika_flat + milena_flat_atk + keloist_flat_atk_buff_val + relic_flat_atk + dasha_e1_flat
	return eff_atk
	
func get_naama_unit() -> CombatUnit:
	for a in allies:
		if a.id == "naama":
			return a
	return null

func get_lenskaya_unit() -> CombatUnit:
	for a in allies:
		if a.id == "lenskaya":
			return a
	return null
	
func get_keloist_unit() -> CombatUnit:
	for a in allies:
		if a.id == "keloist":
			return a
	return null

# === ДОБАВИТЬ В САМЫЙ НИЗ BATTLE_MANAGER.GD ===

# Переменные для хранения слепка состояния изолированного врага
var _isolation_snapshot_meta: Dictionary = {}
var _isolation_snapshot_statuses: Dictionary = {}
var _isolated_unit_ref: CombatUnit = null

# Метод сохранения слепка состояния
func capture_isolation_snapshot() -> void:
	_isolation_snapshot_meta.clear()
	_isolation_snapshot_statuses.clear()
	_isolated_unit_ref = null
	
	for enemy in enemies:
		if enemy.is_alive() and enemy.has_meta("rimes_isolation_source"):
			_isolated_unit_ref = enemy
			break
			
	if _isolated_unit_ref == null:
		return
		
	# Кэшируем метаданные, кроме системных меток изоляции
	for meta_name in _isolated_unit_ref.get_meta_list():
		if meta_name != "rimes_isolation_source" and meta_name != "rimes_isolation_start_hp":
			_isolation_snapshot_meta[meta_name] = _isolated_unit_ref.get_meta(meta_name)
			
	# Динамически кэшируем все скриптовые свойства класса StatusEffects
	var st = _isolated_unit_ref.statuses
	if st and st.get_script():
		for prop in st.get_script().get_script_property_list():
			var p_name: String = String(prop.get("name", ""))
			if p_name != "" and int(prop.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE:
				_isolation_snapshot_statuses[p_name] = st.get(p_name)

# Метод восстановления состояния из слепка
func restore_isolation_snapshot() -> void:
	if _isolated_unit_ref == null or not _isolated_unit_ref.is_alive():
		return
		
	# Стираем дебаффы/баффы, наложенные за это действие
	var current_meta := _isolated_unit_ref.get_meta_list()
	for meta_name in current_meta:
		if meta_name != "rimes_isolation_source" and meta_name != "rimes_isolation_start_hp":
			_isolated_unit_ref.remove_meta(meta_name)
			
	# Восстанавливаем оригинальные метаданные
	for meta_name in _isolation_snapshot_meta:
		_isolated_unit_ref.set_meta(meta_name, _isolation_snapshot_meta[meta_name])
		
	# Восстанавливаем оригинальные статусы
	var st = _isolated_unit_ref.statuses
	if st:
		for p_name in _isolation_snapshot_statuses:
			st.set(p_name, _isolation_snapshot_statuses[p_name])
			
	unit_updated.emit(_isolated_unit_ref)
	
	# Очищаем временную память
	_isolation_snapshot_meta.clear()
	_isolation_snapshot_statuses.clear()
	_isolated_unit_ref = null

# Получение ссылки на Раймса
func get_rimes_unit() -> CombatUnit:
	for a in allies:
		if a.id == "rimes":
			return a
	return null

func get_isaac_unit() -> CombatUnit:
	for a in allies:
		if a.id == "isaac":
			return a
	return null
	
func get_musienko_unit() -> CombatUnit:
	for a in allies:
		if a.id == "musienko":
			return a
	return null
	
func get_joan_unit() -> CombatUnit:
	for a in allies:
		if a.id == "joan":
			return a
	return null
	
func get_jeff_unit() -> CombatUnit:
	for a in allies:
		if a.id == "jeff":
			return a
	return null
	
func get_valramors_unit() -> CombatUnit:
	for a in allies:
		if a.id == "valramors":
			return a
	return null
	
# Фильтрация валидных целей для вражеского ИИ с учетом Изоляции
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В BATTLE_MANAGER.GD ===
func get_valid_targets_for_enemy(enemy: CombatUnit) -> Array[CombatUnit]:
	var valid: Array[CombatUnit] = []
	
	# Если это дуэль 1 на 1 (единственный враг), то все союзники затянуты в Изоляцию. Враг видит и атакует всех союзников нормально!
	if is_rimes_duel_active():
		for ally in allies:
			if ally.is_alive():
				if ally.has_meta("untargetable") and ally.get_meta("untargetable"):
					continue
				valid.append(ally)
		return valid
		
	# Иначе (если врагов несколько), изолированный враг видит только Раймса
	if enemy.has_meta("rimes_isolation_source"):
		var rimes_ref: CombatUnit = enemy.get_meta("rimes_isolation_source")
		if rimes_ref.is_alive():
			valid.append(rimes_ref)
		return valid
		
	# И не-изолированные враги не видят изолированного Раймса
	for ally in allies:
		if ally.is_alive():
			if ally.has_meta("untargetable") and ally.get_meta("untargetable"):
				continue
			if ally.id == "rimes" and ally.has_meta("rimes_isolation_target"):
				continue
			valid.append(ally)
			
	return valid
	
# === ДОБАВЬТЕ ЭТОТ МЕТОД В САМЫЙ НИЗ BATTLE_MANAGER.GD ===
func is_rimes_duel_active() -> bool:
	var rimes_ref: CombatUnit = get_rimes_unit()
	if rimes_ref and rimes_ref.is_alive() and rimes_ref.has_meta("rimes_isolation_target"):
		if get_living_enemies().size() == 1:
			return true
	return false

# === ДОБАВИТЬ В САМЫЙ НИЗ BATTLE_MANAGER.GD ===
func recalculate_unit_max_hp(unit: CombatUnit) -> void:
	var base_hp: float = float(unit.get_meta("base_hp_original", unit.stats.max_hp))
	var total_hp_pct := 0.0
	
	# 1. Процентные прибавки ХП от реликвий
	if unit.has_meta("relic_hp_pct"):
		total_hp_pct += float(unit.get_meta("relic_hp_pct", 0.0))
		
	# 2. Процент синергии Рассвета Хаоса (+15%)
	if unit.has_meta("faction_chaos_hp_pct"):
		total_hp_pct += float(unit.get_meta("faction_chaos_hp_pct", 0.0))
		
	# 3. Процент Следа 3 Мусиенко (+10% за каждого напарника из Рассвета Хаоса)
	if unit.has_meta("musienko_trace3_hp_pct"):
		total_hp_pct += float(unit.get_meta("musienko_trace3_hp_pct", 0.0))
		
	unit.stats.max_hp = base_hp * (1.0 + total_hp_pct)
	unit.stats.hp = unit.stats.max_hp # Лечим до 100% при изменении макс. ХП
	unit_updated.emit(unit)

# === ДОБАВИТЬ ЭТОТ МЕТОД В САМЫЙ НИЗ BATTLE_MANAGER.GD ===
func trigger_dungeon_slums_hp_change(unit: CombatUnit) -> void:
	if unit == null or not unit.is_ally or not unit.is_alive():
		return
	var stacks: int = int(unit.get_meta("dungeon_slums_stacks", 0))
	if stacks < 2:
		stacks += 1
		unit.set_meta("dungeon_slums_stacks", stacks)
		unit.stats.crit_rate += 0.15
	unit.set_meta("dungeon_slums_turns", 2)
	unit.set_meta("dungeon_slums_skip_tick", true)
	log_message("🏚 Аномалия «Принятие Греха»: %s меняет ХП! Крит. шанс +%d%%, Урон +%d%% (%d/2 стака на 2 хода)." % [unit.display_name, stacks * 15, stacks * 30, stacks])

func trigger_accepted_sin_hp_loss(unit: CombatUnit) -> void:
	if unit.is_ally and current_unit and current_unit.is_ally:
		notify_joan_spirit_last_wish("ally_self_harm")
	if battle_mode == "dungeon_slums_apt" and unit.is_ally:
		trigger_dungeon_slums_hp_change(unit)
	if unit.is_alive() and unit.has_meta("set_accepted_sin_4"):
		var s_stacks: int = int(unit.get_meta("relic_sin_stacks", 0))
		if s_stacks < 6:
			var new_s_stacks: int = s_stacks + 1
			unit.set_meta("relic_sin_stacks", new_s_stacks)
			
			# Начисляем крит. шанс напрямую
			unit.stats.crit_rate += 0.05
			log_message("🩸 Сет Принявшего грех: %s получил +5%% КШ (%d/6)." % [unit.display_name, new_s_stacks])
		else:
			log_message("🩸 Сет Принявшего грех: Бафф крит. шанса на %s обновлен на максимуме (6/6)." % unit.display_name)
			
		# ИСПРАВЛЕНО: Обновление ходов и skip_tick вынесено сюда, чтобы они продлевались и на 6 стаках!
		unit.set_meta("relic_sin_turns", 1)
		unit.set_meta("relic_sin_skip_tick", true)

# Полный динамический расчет боевой защиты без мутации базовых характеристик
func get_effective_def_complete(unit: CombatUnit) -> float:
	if unit == null:
		return 0.0
	var s := unit.stats
	var base_def: float = float(unit.get_meta("base_def_original", s.def))
	var relic_def_pct_val: float = float(unit.get_meta("relic_def_pct", 0.0))
	
	# Учет прибавок Маски Силуэта
	if unit.has_meta("silhouette_mask_def_buff"): # ИСПРАВЛЕНО
		relic_def_pct_val += float(unit.get_meta("silhouette_mask_def_buff", 0.0))
	if unit.has_meta("silhouette_mask_def_buff_permanent"): # ИСПРАВЛЕНО
		relic_def_pct_val += float(unit.get_meta("silhouette_mask_def_buff_permanent", 0.0))
		
	# Учет баффов защиты (например, таланта Данилла и Следа 3)
	var def_buff_pct: float = 0.0
	if unit.has_meta("danill_talent_stacks"):
		def_buff_pct += 0.10 * float(unit.get_meta("danill_talent_stacks", 0))
	if unit.has_meta("danill_trace3_def_buff") and bool(unit.get_meta("danill_trace3_def_buff")):
		def_buff_pct += 0.30
		
	return base_def * (1.0 + relic_def_pct_val + def_buff_pct)

func check_joan_talent_trigger() -> void:
	var joan: CombatUnit = null
	for ally in allies:
		if ally.is_alive() and ally.id == "joan":
			joan = ally
			break
	if joan == null:
		return
		
	var living_enemies := get_living_enemies()
	if living_enemies.is_empty():
		return
		
	var unique_hits: Array[CombatUnit] = []
	for enemy in action_hit_enemies:
		if enemy.is_alive() and not enemy in unique_hits:
			unique_hits.append(enemy)
			
	# Если атака задела ВСЕХ живых противников на арене
	if unique_hits.size() >= living_enemies.size():
		# Находим противника с самым большим макс. ХП
		var strongest_enemy: CombatUnit = null
		for enemy in living_enemies:
			if strongest_enemy == null or enemy.stats.max_hp > strongest_enemy.stats.max_hp:
				strongest_enemy = enemy
				
		if strongest_enemy:
			JoanAbilities.trigger_talent_fua(joan, strongest_enemy, self, false)
			
	action_hit_enemies.clear()

# Возвращает категорию текущей атаки согласно классификации
func get_action_type(unit: CombatUnit, action_key: String, tag_override: String = "") -> String:
	if tag_override == "BinaryGroup":
		return "group"
	if tag_override == "Бонус-атака" or tag_override == "FollowUp":
		match unit.id:
			"dasha", "danill", "musienko": return "group"
			"lenskaya":
				# Различаем бонус-атаки Награды (одиночная) и Следа 2 (взрывная)
				if has_meta("lenskaya_fua_is_bounty"):
					return "single"
				return "blast"
			"joan": return "single"
		return "single"
		
	if tag_override == "debtor_proc" or tag_override == "copied_e6":
		return "group" if unit.id == "dotseva" else "single"
		
	match unit.id:
		"marina":
			match action_key:
				"basic": return "single"
				"skill_q": return "group"
				"skill_e": return "debuff"
				"ultimate": return "group"
		"sara":
			match action_key:
				"basic": return "single"
				"skill_q", "skill_e", "ultimate": return "heal"
		"arseniy":
			match action_key:
				"basic":
					if ArseniyAbilities.is_new_development(unit):
						return "debuff"
					return "single"
				"skill_q":
					if ArseniyAbilities.is_new_development(unit):
						return "support"
					return "blast"
				"skill_e": return "self_buff"
				"ultimate": return "single"
		"pusenkov":
			match action_key:
				"basic": return "single"
				"skill_q": return "self_buff"
				"skill_e": return "single"
				"ultimate": return "debuff"
		"kaori":
			match action_key:
				"basic": return "single"
				"skill_q": return "self_buff"
				"skill_e": return "single"
				"ultimate": return "single"
		"shoji":
			match action_key:
				"basic": return "single"
				"skill_q", "skill_e": return "blast"
				"ultimate": return "group"
		"dasha":
			match action_key:
				"basic":
					if unit.get_meta("circle_dance", false):
						return "blast"
					return "single"
				"skill_q": return "blast"
				"skill_e", "ultimate": return "self_buff"
		"danill":
			match action_key:
				"basic": return "single"
				"skill_q", "skill_e", "ultimate": return "shield"
		"vika":
			match action_key:
				"basic": return "single"
				"skill_q", "ultimate": return "blast"
				"skill_e": return "self_buff"
		"dotseva":
			match action_key:
				"basic":
					var in_fog := int(unit.get_meta("dotseva_fog_turns", 0)) > 0
					return "group" if in_fog else "single"
				"skill_q":
					var in_fog := int(unit.get_meta("dotseva_fog_turns", 0)) > 0
					return "group" if in_fog else "blast"
				"skill_e":
					var in_fog := int(unit.get_meta("dotseva_fog_turns", 0)) > 0
					return "debuff" if in_fog else "group"
				"ultimate": return "self_buff"
		"milena":
			match action_key:
				"basic": return "debuff"
				"skill_q", "skill_e", "ultimate": return "support"
		"naama":
			match action_key:
				"basic": return "single"
				"skill_q": return "blast"
				"skill_e": return "debuff"
				"ultimate": return "group"
		"lenskaya":
			match action_key:
				"basic":
					var in_stinger := int(unit.get_meta("lenskaya_stinger_turns", 0)) > 0
					return "blast" if in_stinger else "single"
				"skill_q":
					var in_stinger := int(unit.get_meta("lenskaya_stinger_turns", 0)) > 0
					return "debuff" if in_stinger else "group"
				"skill_e": return "blast"
				"ultimate": return "group"
		"rimes":
			match action_key:
				"basic", "skill_q", "ultimate": return "single"
				"skill_e": return "self_buff"
		"isaac":
			match action_key:
				"basic": return "single"
				"skill_q":
					var stacks := int(unit.get_meta("isaac_theory_stacks", 0))
					return "support" if stacks >= 8 else "group"
				"skill_e": return "blast"
				"ultimate": return "support"
		"keloist":
			match action_key:
				"basic": return "single"
				"skill_q": return "group"
				"skill_e": return "support"
				"ultimate": return "group"
		"musienko":
			match action_key:
				"basic":
					var in_anni := unit.has_meta("musienko_annihilation_active")
					return "blast" if in_anni else "single"
				"skill_q", "ultimate": return "single" if action_key == "skill_q" else "blast"
				"skill_e": return "self_buff"
		"joan":
			match action_key:
				"basic", "skill_q", "ultimate": return "single"
				"skill_e": return "debuff"
		"jeff":
			match action_key:
				"basic": return "single"
				"skill_q": return "heal"
				"skill_e": return "debuff"
				"ultimate": return "heal"
		"valramors":
			match action_key:
				"basic": return "single"
				"skill_q":
					var e6_active := unit.eidolon >= 6
					return "group" if e6_active else "single"
				"skill_e": return "support"
				"ultimate": return "blast"
		"joan_spirit":
			match action_key:
				"basic":
					var in_spirit: bool = bool(unit.get_meta("joan_spirit_form", false))
					if in_spirit and bool(unit.get_meta("joan_spirit_enhanced_basic_selected", false)):
						return "blast"
					return "single"
				"skill_q", "skill_e": 
					return "group"
				"ultimate":
					var in_spirit: bool = bool(unit.get_meta("joan_spirit_form", false))
					return "group" if in_spirit else "self_buff"
		"isaac_admin":
			match action_key:
				"basic":
					var in_hacked := int(unit.get_meta("isaac_hacked_turns", 0)) > 0
					return "blast" if in_hacked else "single"
				"skill_q": 
					return "blast" # И обычный, и Улучшенный Навык Q бьют сплэшом (Взрывная)
				"skill_e": 
					return "bounce" # Отскоки по случайным врагам
				"ultimate": 
					return "self_buff" # Переход во Взлом (Усиление)
		"sara_admin":
			match action_key:
				"basic": 
					return "single"
				"skill_q": 
					return "support" # Активирует зону (Поддержка)
				"skill_e": 
					return "group" # Наносит Бинарный урон всем (Групповая)
				"ultimate": 
					return "support" # Запускает Навыки Е команды (Поддержка)
		"arseniy_admin":
			match action_key:
				"basic", "skill_q": return "single"
				"skill_e": return "group"
				"ultimate": return "blast"
		"dasha_admin":
			match action_key:
				"basic": return "single"
				"skill_q": return "heal"
				"skill_e": return "group"
				"ultimate": return "support"
	return "single"

func check_nihility_allies_e2() -> bool:
	var count := 0
	for ally in allies:
		if ally.is_alive() and ally.path == CombatConstants.Path.NIHILITY:
			count += 1
	return count >= 2

# Полный расчет Quantum RES PEN / ALL RES PEN с учетом Е2 Валраморса
func get_valramors_res_pen(attacker: CombatUnit) -> float:
	var valramors := get_valramors_unit()
	if valramors == null or not valramors.is_alive():
		return 0.0
		
	# Считаем количество живых Quantum-союзников в отряде
	var q_count := 0
	for ally in allies:
		if ally.is_alive() and ally.element == CombatConstants.Element.QUANTUM:
			q_count += 1
			
	if valramors.eidolon >= 2:
		# Е2: ALL RES PEN для всей пати от любого количества Квантовых
		if q_count >= 2:
			return 0.30
		elif q_count >= 1:
			return 0.20
	else:
		# Стандарт: Quantum RES PEN только для Квантовых атак
		if attacker.element == CombatConstants.Element.QUANTUM:
			if q_count >= 4:
				return 0.30
			elif q_count >= 3:
				return 0.20
			elif q_count >= 2:
				return 0.10
	return 0.0

# Возвращает true, если на цель наложен активный срез защиты из указанного источника
func has_def_reduction_source(target: CombatUnit, source_name: String) -> bool:
	if target.has_meta("def_reductions"):
		var reductions: Dictionary = target.get_meta("def_reductions")
		if reductions.has(source_name):
			var data: Dictionary = reductions[source_name]
			if int(data.get("turns", 0)) > 0:
				return true
	return false

func get_adjacent_allies(target: CombatUnit) -> Array[CombatUnit]:
	var adjacent: Array[CombatUnit] = []
	if target == null:
		return adjacent
	var idx: int = allies.find(target)
	if idx >= 0:
		for i in range(idx - 1, -1, -1):
			if allies[i].is_alive():
				adjacent.append(allies[i])
				break
		for i in range(idx + 1, allies.size()):
			if allies[i].is_alive():
				adjacent.append(allies[i])
				break
		return adjacent
	var enemy_idx: int = enemies.find(target)
	if enemy_idx >= 0:
		for i in range(enemy_idx - 1, -1, -1):
			if enemies[i].is_alive():
				adjacent.append(enemies[i])
				break
		for i in range(enemy_idx + 1, enemies.size()):
			if enemies[i].is_alive():
				adjacent.append(enemies[i])
				break
	return adjacent

func get_joan_spirit_unit() -> CombatUnit:
	for a in allies:
		if a.id == "joan_spirit":
			return a
	return null

# Единый контроллер начисления стаков Последнего желания (строго 1 стак за 1 ход)
func notify_joan_spirit_last_wish(trigger_type: String) -> void:
	var js: CombatUnit = get_joan_spirit_unit()
	if js == null or not js.is_alive():
		return
		
	# Если за этот ход Жоан уже получил стак — блокируем любые повторные начисления
	if bool(get_meta("joan_wish_granted_this_turn", false)):
		return
		
	if trigger_type == "enemy_attack":
		set_meta("joan_wish_granted_this_turn", true)
		JoanSpiritAbilities.add_last_wish(js, 1, self)
		log_message("🌟 Талант Жоана: +1 «Последнее желание» за атаку врага в его ход.")
	elif trigger_type == "ally_self_harm":
		set_meta("joan_wish_granted_this_turn", true)
		JoanSpiritAbilities.add_last_wish(js, 1, self)
		log_message("🌟 Талант Жоана: +1 «Последнее желание» за расход ХП союзником в свой ход.")

# След 2 Жоана: за каждые 4 атаки по единственному противнику Жоан восстанавливает 1 Последнее желание
func _check_joan_spirit_trace2_solo_hit(target: CombatUnit, attacker: CombatUnit, tag_override: String, was_target_alive: bool) -> void:
	var js: CombatUnit = get_joan_spirit_unit()
	if js == null or not js.is_alive():
		return
		
	var living_enemies := get_living_enemies()
	var is_solo_enemy: bool = false
	if living_enemies.size() == 1 and living_enemies[0] == target:
		is_solo_enemy = true
	elif living_enemies.is_empty() and was_target_alive:
		is_solo_enemy = true
		
	if not is_solo_enemy:
		set_meta("joan_trace2_solo_hits", 0)
		return
		
	# Защита от мультихитов внутри одной атаки
	var attack_key: String = "%d_%s_%s" % [current_attack_action_id, attacker.id if attacker else "ally", tag_override]
	if target.has_meta("joan_t2_last_attack_key") and String(target.get_meta("joan_t2_last_attack_key", "")) == attack_key:
		return
	target.set_meta("joan_t2_last_attack_key", attack_key)
	
	var hits: int = int(get_meta("joan_trace2_solo_hits", 0)) + 1
	if hits >= 4:
		set_meta("joan_trace2_solo_hits", 0)
		JoanSpiritAbilities.add_last_wish(js, 1, self)
		log_message("⚡ След 2 Жоана: 4 атаки по единственному противнику! Восстановлено 1 «Последнее желание» (%d/12)." % int(js.get_meta("joan_last_wish", 0)))
	else:
		set_meta("joan_trace2_solo_hits", hits)
		log_message("⚡ След 2 Жоана: Атака по единственному противнику от %s (%d/4 для +1 «Последнего желания»)." % [attacker.display_name, hits])

# === ЕДИНЫЙ ЦЕНТРАЛЬНЫЙ РЕЕСТР DoT-СТАТУСОВ ===

# Возвращает список всех активных периодических эффектов на юните
static func get_unit_active_dots(unit: CombatUnit) -> Array[String]:
	var dots: Array[String] = []
	if unit == null:
		return dots
		
	# 1. Периодический урон от пробития уязвимостей (Горение, Шок, Выветривание, Кровотечение)
	if unit.statuses.break_status != "":
		dots.append(unit.statuses.break_status)
		
	# 2. Подавление Марины (при наличии Е1 официально считается DoT)
	if unit.statuses.suppression_is_dot and unit.statuses.suppression_stacks > 0:
		dots.append("Подавление")
		
	# 3. Горение Сёдзи
	if unit.has_meta("shoji_burn_turns") and int(unit.get_meta("shoji_burn_turns", 0)) > 0:
		dots.append("Горение Сёдзи")
		
	# 4. Опьянение Наамы
	if unit.has_meta("naama_intox_stacks") and int(unit.get_meta("naama_intox_stacks", 0)) > 0:
		dots.append("Опьянение")
		
	# 5. Шок Джеффа («Бассы! Слушай!»)
	if unit.has_meta("jeff_bass_listen_turns") and int(unit.get_meta("jeff_bass_listen_turns", 0)) > 0:
		dots.append("Шок Джеффа")
		
	# 6. Сияние от конуса «Идеальный Метаморфоз»
	if unit.has_meta("radiance_status_turns") and int(unit.get_meta("radiance_status_turns", 0)) > 0:
		dots.append("Сияние")
		
	# 7. Кислотный мутаген Орто Мутанта (пассивный DoT для активации Следа 3 Жоана)
	if unit.has_meta("ortho_acid_dot_turns") and int(unit.get_meta("ortho_acid_dot_turns", 0)) > 0:
		dots.append("Кислотный мутаген")

	# 8. Горение Штаба («Лавовый отпор»)
	if unit.has_meta("hq_burn_turns") and int(unit.get_meta("hq_burn_turns", 0)) > 0:
		dots.append("Горение Штаба")
		
	return dots

# Проверка: есть ли на цели хотя бы один активный DoT
func has_any_dot(unit: CombatUnit) -> bool:
	return not get_unit_active_dots(unit).is_empty()

# Количество активных DoT на цели
func get_active_dots_count(unit: CombatUnit) -> int:
	return get_unit_active_dots(unit).size()

# Универсальный метод начисления стаков конуса «Ощути моё присутствие»
# Единый автоматический анализатор дебаффов для конуса «Ощути моё присутствие»
func evaluate_feel_my_presence(attacker: CombatUnit) -> void:
	if attacker == null or not attacker.is_alive():
		return
	if attacker.get_meta("light_cone_id", "") != "feel_my_presence":
		return
	if bool(attacker.get_meta("feel_presence_completed", false)):
		return # 3 стака уже получены на весь бой
		
	var living := get_living_enemies()
	var applied_def := false
	var applied_spd := false
	var applied_atk := false
	
	for enemy in living:
		# 1. КАТЕГОРИЯ: СНИЖЕНИЕ ЗАЩИТЫ (DEF)
		if enemy.has_meta("def_reductions"):
			var reds: Dictionary = enemy.get_meta("def_reductions")
			for src in reds:
				if int(reds[src].get("turns", 0)) > 0:
					applied_def = true
		if attacker.id == "naama":
			if enemy.has_meta("naama_kiss_turns") and int(enemy.get_meta("naama_kiss_turns", 0)) > 0:
				applied_def = true # След 2 Наамы снижает ЗАЩ на 15%
			if int(enemy.get_meta("naama_intox_stacks", 0)) >= 20:
				applied_def = true # 20 стаков Опьянения снижают ЗАЩ на 20%
				
		# 2. КАТЕГОРИЯ: СНИЖЕНИЕ СКОРОСТИ (SPD) — только реальный срез СКР, не задержка хода!
		if attacker.id == "valramors" and enemy.has_meta("valramors_talent_turns") and int(enemy.get_meta("valramors_talent_turns", 0)) > 0:
			applied_spd = true # Талант Валраморса режет СКР на -8%
		if attacker.id == "marina" and enemy.statuses.suppression_stacks > 0:
			applied_spd = true # Подавление Марины режет СКР на -8%/стак
		if attacker.id == "lenskaya" and enemy.has_meta("lenskaya_slow_turns") and int(enemy.get_meta("lenskaya_slow_turns", 0)) > 0:
			applied_spd = true # Замедление Ленской режет СКР на -20%
			
		# 3. КАТЕГОРИЯ: СНИЖЕНИЕ СИЛЫ АТАКИ (ATK) — только реальный срез СА, не бессилие урона!
		if attacker.id == "valramors" and enemy.has_meta("valramors_talent_turns") and int(enemy.get_meta("valramors_talent_turns", 0)) > 0:
			applied_atk = true # Талант Валраморса режет СА на -15%
		if enemy.statuses.atk_buff_percent < 0.0:
			applied_atk = true # Прямой отрицательный дебафф СА
			
	# Начисляем строго по 1 стаку за каждую подтвержденную категорию дебаффа
	if applied_def: _grant_feel_presence_stack(attacker, "def", "Защиты")
	if applied_spd: _grant_feel_presence_stack(attacker, "spd", "Скорости")
	if applied_atk: _grant_feel_presence_stack(attacker, "atk", "Силы атаки")

func _grant_feel_presence_stack(unit: CombatUnit, category_key: String, category_name: String) -> void:
	var meta_key := "feel_presence_" + category_key + "_credited"
	if not bool(unit.get_meta(meta_key, false)):
		unit.set_meta(meta_key, true)
		var cur: int = int(unit.get_meta("feel_presence_stacks", 0)) + 1
		unit.set_meta("feel_presence_stacks", cur)
		log_message("👁 Конус «Ощути моё присутствие»: %s получил стак «Истощения» за срез %s (%d/3)!" % [unit.display_name, category_name, cur])
		
		if cur >= 3:
			unit.set_meta("feel_presence_completed", true)
			unit.set_meta("feel_presence_dmg_bonus", 0.25)
			log_message("👁 МАКСИМУМ КОНУСА: Собрано 3 стака! Урон %s +25%%, Крит. шанс ВСЕХ союзников +20%% до конца боя!" % unit.display_name)
			for ally in allies:
				if ally.is_alive():
					ally.stats.crit_rate += 0.20
					ally.set_meta("feel_presence_team_crit", true)
					unit_updated.emit(ally)

# Единый центральный метод добавления Векторов Консоли (интегрирован со всеми талантами)
func add_console_vectors(amount: int) -> void:
	if amount <= 0:
		return
	
	var shoji_u := get_shoji_swan_unit()
	var shoji_active: bool = (shoji_u != null and shoji_u.is_alive())
	
	var sara := get_sara_admin_unit()
	# Если талант Сары активен (фиксация на 100), всё, что выше — в буфер
	if sara and sara_talent_active:
		sara_buffered_vectors += amount
		log_message("🛡 Буфер Сары: +%d Векторов записано в буфер (лимит 100 зафиксирован)." % amount)
		return
		
	var cur := get_console_vectors()
	var peak_val := cur + amount
	var new_val := peak_val
	
	# След 1 Даши: За каждые 10 полученных командой Векторов даёт 1 Цифровой след
	var dasha_adm := get_dasha_admin_unit()
	if dasha_adm and dasha_adm.is_alive():
		var acc: int = int(dasha_adm.get_meta("dasha_vector_acc", 0)) + amount
		if acc >= 10:
			var foot_gain := int(acc / 10)
			acc = acc % 10
			DashaAdminAbilities.add_digital_footprint(dasha_adm, foot_gain, self)
		dasha_adm.set_meta("dasha_vector_acc", acc)
		
	# Разблокировки способностей по пиковому значению (навсегда)
	if peak_val >= 20 and shoji_u and shoji_u.is_alive() and not bool(shoji_u.get_meta("shoji_swan_e_unlocked", false)):
		shoji_u.set_meta("shoji_swan_e_unlocked", true)
		log_message("🔓 [SYSTEM UNLOCKED]: Накоплено 20 Векторов! Навык Е Сёдзи разблокирован навсегда.")
		
	var sara_u := get_sara_admin_unit()
	if peak_val >= 30 and sara_u and sara_u.is_alive() and not bool(sara_u.get_meta("sara_admin_e_unlocked", false)):
		sara_u.set_meta("sara_admin_e_unlocked", true)
		log_message("🔓 [SYSTEM UNLOCKED]: Накоплено 30 Векторов! Навык Е Сары разблокирован.")

	var arseniy_u := get_arseniy_admin_unit()
	if peak_val >= 40 and arseniy_u and arseniy_u.is_alive() and not bool(arseniy_u.get_meta("arseniy_admin_e_unlocked", false)):
		arseniy_u.set_meta("arseniy_admin_e_unlocked", true)
		log_message("🔓 [SYSTEM UNLOCKED]: Накоплено 40 Векторов! Навык Е Арсения разблокирован.")

	var isaac_u := get_isaac_admin_unit()
	if peak_val >= 50 and isaac_u and isaac_u.is_alive() and not bool(isaac_u.get_meta("isaac_admin_e_unlocked", false)):
		isaac_u.set_meta("isaac_admin_e_unlocked", true)
		log_message("🔓 [ROOT ACCESS]: Накоплено 50 Векторов! Навык Е Айзека разблокирован.")

	if peak_val >= 80 and dasha_adm and dasha_adm.is_alive() and not bool(dasha_adm.get_meta("dasha_admin_e_unlocked", false)):
		dasha_adm.set_meta("dasha_admin_e_unlocked", true)
		log_message("🔓 [SYSTEM UNLOCKED]: Накоплено 80 Векторов! Навык Е Даши разблокирован навсегда.")

	# Энергия Айзека (Талант: Векторы = Энергия)
	if isaac_u and isaac_u.is_alive():
		gain_energy_with_err(isaac_u, float(amount))

	# ПРИОРИТЕТ 1: ТАЛАНТ СЁДЗИ (ПОРОГ 90)
	# В отряде с Сёдзи Лебединое озеро Векторы МОМЕНТАЛЬНО сбрасываются при достижении 90!
	# Талант Сары (100) НИКОГДА не срабатывает в отряде с живой Сёдзи.
	if shoji_active and new_val >= 90:
		while new_val >= 90:
			new_val -= 90
			for ally in allies:
				if ally.is_alive():
					ally.set_meta("shoji_swan_atk_turns", 2)
					ally.set_meta("shoji_swan_atk_skip_tick", true)
			log_message("🦢 ТАЛАНТ СЁДЗИ: Накоплено 90 Векторов! Счётчик сброшен до %d, все союзники получают +50%% СА на 2 хода!" % new_val)
		
		set_console_vectors(new_val)
		unit_updated.emit(shoji_u)
		action_order_changed.emit()
		return

	# ПРИОРИТЕТ 2: ТАЛАНТ САРЫ (ПОРОГ 100) — ТОЛЬКО ЕСЛИ СЁДЗИ НЕТ ИЛИ ОНА МЕРТВА
	if not shoji_active and cur < 100 and new_val >= 100:
		if sara and sara.is_alive() and sara_talent_cooldown == 0:
			activate_sara_talent(new_val - 100)
			return

	set_console_vectors(new_val)
	log_message("⚡ [КОНСОЛЬ]: Пул Векторов: %d (+%d)." % [new_val, amount])
		
	# 4. Талант Айзека (>101 Вектор)
	if isaac_u and isaac_u.is_alive():
		while get_console_vectors() >= 101:
			var v_cur := get_console_vectors()
			set_console_vectors(v_cur - 101)
			if isaac_u and isaac_u.is_alive():
				isaac_u.set_meta("isaac_vectors", v_cur - 101)
			log_message("💥 ТАЛАНТ АДМИНИСТРАТОРА: 101 Вектор превышен! Мгновенная атака 400%% СА (-101 Вектор).")
			IsaacAdminAbilities.trigger_talent_overload_attack(isaac_u if isaac_u else allies[0], self)
		
	# 5. Талант Арсения (>150 Векторов)
	var ars := get_arseniy_admin_unit()
	if ars and ars.is_alive():
		ArseniyAdminAbilities.check_overload_talent(ars, self)
		
	unit_updated.emit(null)
	
func get_isaac_admin_unit() -> CombatUnit:
	for a in allies:
		if a.id == "isaac_admin": return a
	return null
	
# Получение общего пула Векторов Консоли
func get_console_vectors() -> int:
	return int(get_meta("console_vectors", 0))

# Установка общего пула Векторов Консоли
# Установка общего пула Векторов Консоли
func set_console_vectors(val: int) -> void:
	set_meta("console_vectors", val)
	# Синхронизируем значение для карточек союзников в UI
	for ally in allies:
		ally.set_meta("console_vectors", val)
		
	# ТАЛАНТ АРСЕНИЯ АДМИНА: Проверка перегрузки 150+ Векторов
	var ars := get_arseniy_admin_unit()
	if ars and ars.is_alive():
		ArseniyAdminAbilities.check_overload_talent(ars, self)
		
func get_sara_admin_unit() -> CombatUnit:
	for a in allies:
		if a.id == "sara_admin": return a
	return null

func get_arseniy_admin_unit() -> CombatUnit:
	for a in allies:
		if a.id == "arseniy_admin": return a
	return null
	
func get_dasha_admin_unit() -> CombatUnit:
	for a in allies:
		if a.id == "dasha_admin": return a
	return null

func get_shoji_swan_unit() -> CombatUnit:
	for a in allies:
		if a.id == "shoji_swan": return a
	return null

func get_katarina_unit() -> CombatUnit:
	for a in allies:
		if a.id == "katarina": return a
	return null

func get_dotseva_crimson_tears_unit() -> CombatUnit:
	for a in allies:
		if a.id == "dotseva_crimson_tears": return a
	return null

func get_shoji_swan_stance() -> String:
	var u := get_shoji_swan_unit()
	if u:
		return String(u.get_meta("shoji_swan_stance", "virus"))
	return "virus"

# Проверка и активация Таланта Арсения Админа (+5 Векторов при атаке ослабленной цели)
func check_arseniy_talent(target: CombatUnit, attacker: CombatUnit) -> void:
	if attacker == null or not attacker.is_alive() or not attacker.is_ally:
		return
	if target == null or not target.is_alive() or target.is_ally:
		return
		
	var has_ars_def_shred := false
	if target.has_meta("def_reductions"):
		var reds: Dictionary = target.get_meta("def_reductions")
		for src in reds:
			if "арсений" in src.to_lower() or "arseniy" in src.to_lower():
				has_ars_def_shred = true
				break
				
	if has_ars_def_shred:
		if not has_meta("arseniy_talent_credited_this_action"):
			set_meta("arseniy_talent_credited_this_action", true)
			var ars := get_arseniy_admin_unit()
			if ars and ars.is_alive():
				log_message("⚡ Талант Арсения Админа: Атака по ослабленной цели восстановила 5 Векторов!")
				add_console_vectors(3)

# Обертка для безопасного исполнения перегрузки Арсения на следующем кадре
func _execute_arseniy_overload(ars_unit: CombatUnit) -> void:
	ArseniyAdminAbilities.execute_overload_damage(ars_unit, self)

func activate_sara_talent(excess: int) -> void:
	var sara := get_sara_admin_unit()
	if not sara or not sara.is_alive(): return
	
	sara_talent_active = true
	sara_buffered_vectors = excess
	set_meta("console_vectors", 100) # Фиксируем на 100
	
	log_message("🛡 ТАЛАНТ САРЫ: Пул зафиксирован на 100! Продвижение действий союзников Консоли на 100%!")
	for ally in allies:
		if ally.is_alive() and ally.id in FactionSystem.FACTIONS["console"].members:
			ally.advance_action(100.0)
	action_order_changed.emit()
	
func release_sara_buffer() -> void:
	sara_talent_active = false
	var vectors_to_add := sara_buffered_vectors
	sara_buffered_vectors = 0
	sara_talent_cooldown = 4 # 3 хода + 1 текущий (он сбросится в _end_turn)
	
	log_message("🛡 ТАЛАНТ САРЫ: Индекс действия сменился! Выгрузка буфера: +%d Векторов." % vectors_to_add)
	
	# Проверяем кто есть в пати для активации их талантов
	var isaac := get_isaac_admin_unit()
	var ars := get_arseniy_admin_unit()
	
	# Логика: Айзек приоритетнее, потом Арсений
	if isaac and isaac.is_alive():
		# Айзек: вычесть 1 для активации таланта (если нужно), потом сумма
		# Если логика требует именно 101, то мы вручную добавляем
		set_meta("console_vectors", 100 + vectors_to_add)
		# И вызываем проверку перегрузки Айзека
		IsaacAdminAbilities.trigger_talent_overload_attack(isaac, self)
		set_meta("console_vectors", 0) # После взрыва остаток присуммируем
		# (Тут можно дописать логику корректного пересчета остатка)
	elif ars and ars.is_alive():
		# Логика Арсения (сброс до 150)
		set_console_vectors(get_console_vectors() + vectors_to_add)
		ArseniyAdminAbilities.check_overload_talent(ars, self)
	else:
		set_console_vectors(get_console_vectors() + vectors_to_add)
