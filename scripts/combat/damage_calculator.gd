class_name DamageCalculator
extends RefCounted

const BASE_BREAK_VALUE := 6.14

static func calc_def_multiplier(target_def: float) -> float:
	return 1.0 - target_def / (target_def + 300.0)

static func roll_crit(attacker: CombatUnit) -> bool:
	return randf() < attacker.stats.crit_rate

# Срез сопротивлений элементов у противников (дебаффы на цели)
static func get_target_res_shred(target: CombatUnit, element: int) -> float:
	var shred := 0.0
	match element:
		CombatConstants.Element.PHYSICAL:
			if target.has_meta("phys_res_reduced_turns") and int(target.get_meta("phys_res_reduced_turns", 0)) > 0:
				shred += 0.20
		CombatConstants.Element.FIRE:
			if target.has_meta("shoji_fire_res_reduced_turns") and int(target.get_meta("shoji_fire_res_reduced_turns", 0)) > 0:
				shred += 0.40
	return shred

# Получение множителя Сопротивления (RES) для атаки (возвращает строго float)
static func get_res_multiplier(attacker: CombatUnit, target: CombatUnit) -> float:
	# 1. Базовое сопротивление (0% если уязвимость есть, иначе 20%)
	var base_res := 0.20
	if attacker.element in target.weaknesses:
		base_res = 0.0
		
	# 2. Срез сопротивления (дебафф на цели)
	var res_shred := get_target_res_shred(target, attacker.element)
	
	var e1_pen := 0.0
	if attacker.has_meta("milena_e1_res_pen"):
		e1_pen = float(attacker.get_meta("milena_e1_res_pen", 0.0))
	
	# 3. Пробитие сопротивления / Игнор (бафф на атакующем)
	var res_pen := float(attacker.get_meta("res_pen_bonus", 0.0))
	
	# Формула HSR: 1 - (RES - Shred - RES_PEN)
	return 1.0 - (base_res - res_shred - res_pen)

# Полная и строго типизированная версия calc_damage с поддержкой легендарных конусов
# Полная и строго типизированная версия calc_damage с поддержкой конусов
static func calc_damage(
	attacker: CombatUnit,
	target: CombatUnit,
	atk_multiplier: float,
	element_bonus: float = 0.0,
	force_crit: bool = false,
	extra_damage_bonus: float = 0.0,
	extra_crit_dmg: float = 0.0,
) -> Dictionary:
	var crit_dmg_val := attacker.stats.get_effective_crit_dmg(attacker.statuses, extra_crit_dmg)
	var dmg_bonus := 1.0 + attacker.stats.damage_bonus + element_bonus + extra_damage_bonus
	
	if target.statuses.toughness_broken:
		dmg_bonus += CombatConstants.BREAK_DAMAGE_BONUS
		
	# Внутри calc_damage() -> в блоке расчета dmg_bonus:
	if target.statuses.suppression_stacks > 0:
		if target.statuses.suppression_is_dot:
			# Е1: Общий урон увеличивается на 10% за каждый стак Подавления
			dmg_bonus += 0.10 * float(target.statuses.suppression_stacks)
		else:
			# Без Е1: Стабильные +10% урона
			dmg_bonus += 0.10

	# --- ИСПРАВЛЕНО: КОНУС «МГНОВЕНИЕ СЧАСТЬЯ»: +25% ультимативного урона, если СКОРОСТЬ цели снижена ---
	if attacker.get_meta("light_cone_id", "") == "moment_of_happiness" and extra_damage_bonus == 0.30: # (is_ultimate)
		if target.stats.get_effective_spd() < target.stats.spd:
			dmg_bonus += 0.25
			
	# --- ИСПРАВЛЕНО: КОНУС «Я НЕ МОГУ ТЕБЯ УБИТЬ»: +30% Крит. шанса по помеченной ультимейтом цели ---
	var extra_cr := 0.0
	if target and target.has_meta("cant_kill_you_crit_boost_" + attacker.id) and target.get_meta("cant_kill_you_crit_boost_" + attacker.id, false):
		extra_cr += 0.30
		
	var old_cr := attacker.stats.crit_rate
	attacker.stats.crit_rate += extra_cr
	
	var crit := force_crit or roll_crit(attacker)
	var crit_mult := 1.0 + crit_dmg_val if crit else 1.0
	
	# Восстанавливаем оригинальный крит. шанс
	attacker.stats.crit_rate = old_cr

	# Вычисляем множитель Сопротивлений (RES)
	var res_mult := get_res_multiplier(attacker, target)

	var base := attacker.stats.get_effective_atk(attacker.statuses) * atk_multiplier
	
	# Интегрируем сопротивление в финальный урон
	var final := base * calc_def_multiplier(target.stats.def) * crit_mult * dmg_bonus * res_mult
	final = maxf(final, 1.0)
	
	return {"damage": final, "crit": crit}

static func calc_break_damage(attacker: CombatUnit, target: CombatUnit = null) -> float:
	var target_max_toughness := 150.0 
	if target:
		target_max_toughness = target.max_toughness
		
	# ИСПРАВЛЕНО: Считываем эффективный BE через новый метод (с учетом баффа Милены)
	var break_effect_val := attacker.get_effective_be()
	return BASE_BREAK_VALUE * (target_max_toughness + 2.0) * (1.0 + break_effect_val)

static func calc_dot_damage(attacker: CombatUnit, multiplier: float) -> float:
	var base_dot := attacker.stats.atk * multiplier
	
	# Световые конусы небытия
	if attacker.has_meta("light_cone_id"):
		var lc: String = attacker.get_meta("light_cone_id")
		if lc == "void_dot":
			base_dot *= 1.20
		elif lc == "what_is_reality":
			base_dot *= 1.38
			
	return base_dot

static func calc_super_break_damage(attacker: CombatUnit, target: CombatUnit, base_tgh_reduction: float) -> float:
	# Рассчитываем силу истощения стойкости атаки
	var tgh_reduction_term := base_tgh_reduction * (1.0 + attacker.stats.weakness_efficiency) / 30.0
	
	# Считываем урон пробития, который масштабируется от макс. стойкости врага и эффекта пробития атакующего
	var base_break_dmg := calc_break_damage(attacker, target)
	
	# Применяем множитель защиты цели
	var def_mult := calc_def_multiplier(target.stats.def)
	
	# Итоговый урон суперпробития
	return tgh_reduction_term * base_break_dmg * def_mult
