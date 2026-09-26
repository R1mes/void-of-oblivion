class_name DamageCalculator
extends RefCounted

const LEVEL_MULTIPLIER := 1640.0
const BASE_BREAK_VALUE := 1640.0

static func calc_def_multiplier(target_def: float) -> float:
	return 1.0 - target_def / (target_def + 300.0)

static func get_def_multiplier(attacker: CombatUnit, target: CombatUnit, extra_def_ignore: float = 0.0) -> float:
	if target == null:
		return 1.0
	var level_atk: float = float(attacker.get_meta("level", 80.0)) if attacker != null else 80.0
	var level_def: float = float(target.get_meta("level", 80.0))

	var def_shred: float = 0.0
	var def_ignore: float = extra_def_ignore

	# 1. Срезы защиты на цели (def_reductions)
	if target.has_meta("def_reductions"):
		var reductions: Dictionary = target.get_meta("def_reductions")
		for src in reductions:
			var data: Dictionary = reductions[src]
			if int(data.get("turns", 0)) > 0:
				def_shred += float(data.get("percent", 0.0))
	if target.has_meta("cleaner_def_reduction_turns") and int(target.get_meta("cleaner_def_reduction_turns", 0)) > 0:
		def_shred += float(target.get_meta("cleaner_def_reduction_pct", 0.20))
	if target.has_meta("naama_kiss_turns") and int(target.get_meta("naama_kiss_turns", 0)) > 0:
		def_shred += 0.15
	if target.has_meta("naama_intox_stacks") and int(target.get_meta("naama_intox_stacks", 0)) >= 20:
		def_shred += 0.20

	# 2. Игнорирование защиты атакующим (def_ignore)
	if attacker != null:
		if attacker.has_meta("talent_ignore_20_def"):
			def_ignore += 0.20
		if attacker.has_meta("valramors_tech_ignore_turns") and int(attacker.get_meta("valramors_tech_ignore_turns", 0)) > 0:
			def_ignore += 0.15
		if attacker.id == "lenskaya_antimatter":
			var am_st: String = String(attacker.get_meta("lenskaya_am_stance", "none"))
			if am_st in ["keeper", "warrior"]:
				def_ignore += 0.10
			if attacker.has_meta("lenskaya_am_ignore_20_def"):
				def_ignore += 0.20
			if attacker.eidolon >= 6 and attacker.has_meta("lenskaya_am_supernova_100_zero"):
				def_ignore += 0.30
		var is_redemption: bool = false
		if attacker.has_meta("redemption_turns") and int(attacker.get_meta("redemption_turns", 0)) > 0:
			is_redemption = true
		elif attacker is Memosprite and (attacker as Memosprite).owner != null and (attacker as Memosprite).owner.has_meta("redemption_turns") and int((attacker as Memosprite).owner.get_meta("redemption_turns", 0)) > 0:
			is_redemption = true
		elif attacker.has_meta("owner_unit"):
			var o: CombatUnit = attacker.get_meta("owner_unit")
			if o != null and o.has_meta("redemption_turns") and int(o.get_meta("redemption_turns", 0)) > 0:
				is_redemption = true
		if is_redemption:
			def_ignore += 0.30

	var total_shred_ignore: float = clampf(def_shred + def_ignore, 0.0, 1.0)
	var numerator: float = level_atk + 20.0
	var denominator: float = (level_def + 20.0) * (1.0 - total_shred_ignore) + level_atk + 20.0
	if denominator <= 0.0:
		return 1.0
	return numerator / denominator

static func get_vuln_multiplier(target: CombatUnit) -> float:
	if target == null:
		return 1.0
	var vuln_mult: float = 1.0
	if target.has_meta("lenskaya_radiance_enemy_turns") and int(target.get_meta("lenskaya_radiance_enemy_turns", 0)) > 0:
		var has_e2: bool = bool(target.get_meta("lenskaya_radiance_enemy_e2", false))
		vuln_mult += (0.45 if has_e2 else 0.30)
	if target.has_meta("ego_reality_vuln_turns") and int(target.get_meta("ego_reality_vuln_turns", 0)) > 0:
		vuln_mult += 0.30
	if target.has_meta("valramors_ult_vuln_turns") and int(target.get_meta("valramors_ult_vuln_turns", 0)) > 0:
		vuln_mult += 0.20
	if target.has_meta("joan_tech_vuln_turns") and int(target.get_meta("joan_tech_vuln_turns", 0)) > 0:
		vuln_mult += 0.20
	if target.has_meta("katarina_vuln_turns") and int(target.get_meta("katarina_vuln_turns", 0)) > 0:
		vuln_mult += 0.20
	if target.has_meta("shoji_swan_dance_vuln_turns") and int(target.get_meta("shoji_swan_dance_vuln_turns", 0)) > 0:
		vuln_mult += float(target.get_meta("shoji_swan_dance_vuln_pct", 0.20))
	if target.has_meta("admin_vuln_turns") and int(target.get_meta("admin_vuln_turns", 0)) > 0:
		vuln_mult += float(target.get_meta("admin_vuln_pct", 0.30))
	if target.has_meta("kyle_vuln_pct") and int(target.get_meta("kyle_mind_fracture_turns", 0)) > 0:
		vuln_mult += float(target.get_meta("kyle_vuln_pct", 0.0))
	return vuln_mult

static func get_dmg_reduction_multiplier(target: CombatUnit) -> float:
	if target == null:
		return 1.0
	var red_mult: float = 1.0
	if target.has_meta("dmg_reduction"):
		red_mult *= maxf(0.0, 1.0 - float(target.get_meta("dmg_reduction", 0.0)))
	if target.has_meta("boss_dmg_reduction"):
		red_mult *= maxf(0.0, 1.0 - float(target.get_meta("boss_dmg_reduction", 0.0)))
	return red_mult

static func get_element_break_multiplier(element: int) -> float:
	match element:
		CombatConstants.Element.PHYSICAL, CombatConstants.Element.FIRE:
			return 2.0
		CombatConstants.Element.WIND:
			return 1.5
		CombatConstants.Element.LIGHTNING, CombatConstants.Element.ICE:
			return 1.0
		CombatConstants.Element.QUANTUM, CombatConstants.Element.IMAGINARY:
			return 0.5
	return 1.0

static func roll_crit(attacker: CombatUnit) -> bool:
	if attacker != null and attacker.is_ally and TeamConfig.is_test_mode_battle:
		return true
	return randf() < attacker.stats.crit_rate

# Срез сопротивлений элементов у противников (дебаффы на цели)
static func get_target_res_shred(target: CombatUnit, element: int) -> float:
	var shred := 0.0
	match element:
		CombatConstants.Element.PHYSICAL:
			if target.has_meta("phys_res_reduced_turns") and int(target.get_meta("phys_res_reduced_turns", 0)) > 0:
				shred += 0.20
			elif target.has_meta("katarina_phys_res_reduction") and int(target.get_meta("katarina_vuln_turns", 0)) > 0:
				shred += float(target.get_meta("katarina_phys_res_reduction", 0.20))
		CombatConstants.Element.FIRE:
			if target.has_meta("shoji_fire_res_reduced_turns") and int(target.get_meta("shoji_fire_res_reduced_turns", 0)) > 0:
				shred += 0.40
		CombatConstants.Element.QUANTUM:
			if target.has_meta("quantum_res_reduced_turns") and int(target.get_meta("quantum_res_reduced_turns", 0)) > 0:
				shred += 0.12
	if target.has_meta("katarina_all_res_reduction") and int(target.get_meta("katarina_vuln_turns", 0)) > 0:
		shred += float(target.get_meta("katarina_all_res_reduction", 0.20))
	return shred

static func get_res_multiplier(attacker: CombatUnit, target: CombatUnit, element_override: int = -1) -> float:
	var eff_elem: int = element_override if element_override != -1 else (attacker.element if attacker != null else CombatConstants.Element.PHYSICAL)
	if element_override == -1 and attacker != null:
		if attacker.has_meta("current_attack_element"):
			eff_elem = int(attacker.get_meta("current_attack_element"))
		elif attacker.id == "lenskaya_antimatter":
			var stance: String = String(attacker.get_meta("lenskaya_am_stance", "none"))
			if not stance in ["keeper", "warrior"] and attacker.eidolon < 6:
				eff_elem = CombatConstants.Element.PHYSICAL

	# 1. Базовое сопротивление (0% если уязвимость есть, иначе 20%)
	var base_res := 0.20
	if eff_elem in target.weaknesses:
		base_res = 0.0
	if eff_elem == CombatConstants.Element.ICE and target.has_meta("ice_res_bonus"):
		base_res = float(target.get_meta("ice_res_bonus", 0.40))
	if eff_elem == CombatConstants.Element.IMAGINARY and target.has_meta("imaginary_res_bonus"):
		base_res = float(target.get_meta("imaginary_res_bonus", 0.40))
		
	# 2. Срез сопротивления (дебафф на цели)
	var res_shred := get_target_res_shred(target, eff_elem)
	
	var e1_pen := 0.0
	if attacker.has_meta("milena_e1_res_pen"):
		e1_pen += float(attacker.get_meta("milena_e1_res_pen", 0.0))

	# Е6 Ленской: 20% пробития сопротивлений
	if attacker.id == "lenskaya" and attacker.eidolon >= 6:
		e1_pen += 0.20
	
	# 3. Пробитие сопротивления / Игнор (бафф на атакующем)
	var res_pen := float(attacker.get_meta("res_pen_bonus", 0.0))
	
	# Формула HSR: 1 - (RES - Shred - RES_PEN)
	return 1.0 - (base_res - res_shred - res_pen - e1_pen)

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
	if attacker.has_meta("ice_reflection_bonus") and int(attacker.get_meta("ice_reflection_buff_turns", 0)) > 0 and (attacker.element == CombatConstants.Element.ICE or element_bonus > 0.0):
		dmg_bonus += float(attacker.get_meta("ice_reflection_bonus", 0.15))
	
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

	# След 1 Ленской • Хранитель небес: КШ +10% от ЭП (макс +30%), КУ +50% от ЭП (макс +150%)
	if attacker.id == "lenskaya_sky_guardian":
		var eff_be := attacker.get_effective_be()
		extra_cr += minf(eff_be * 0.10, 0.30)
		crit_dmg_val += minf(eff_be * 0.50, 1.50)
		
	var old_cr := attacker.stats.crit_rate
	attacker.stats.crit_rate += extra_cr
	
	# В режиме «Тестовая среда»:
	# Крит. шанс союзников гарантированно 100%, а избыточный шанс (>100%) переводится в КУ (1% КШ = 1.5% КУ)
	if TeamConfig.is_test_mode_battle and attacker.is_ally:
		var total_cr: float = maxf(attacker.stats.crit_rate, 1.0)
		if total_cr > 1.0:
			var excess_cr: float = total_cr - 1.0
			crit_dmg_val += excess_cr * 1.5
		attacker.stats.crit_rate = 1.0

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

static func calc_raw_break_damage(attacker: CombatUnit, target: CombatUnit = null, element_override: int = -1) -> float:
	var elem_mult: float = 1.0
	if element_override != -1:
		elem_mult = get_element_break_multiplier(element_override)
	elif attacker != null:
		var elem: int = attacker.element
		if attacker.has_meta("current_attack_element"):
			elem = int(attacker.get_meta("current_attack_element"))
		elif attacker.id == "lenskaya_antimatter":
			var stance: String = String(attacker.get_meta("lenskaya_am_stance", "none"))
			if not stance in ["keeper", "warrior"] and attacker.eidolon < 6:
				elem = CombatConstants.Element.PHYSICAL
		elem_mult = get_element_break_multiplier(elem)
	var target_max_toughness := 60.0
	if target != null and target.max_toughness > 0.0:
		target_max_toughness = target.max_toughness
	var toughness_mult: float = 0.5 + (target_max_toughness / 120.0)
	return LEVEL_MULTIPLIER * elem_mult * toughness_mult

static func calc_break_damage(attacker: CombatUnit, target: CombatUnit = null, ability_mult: float = 1.0, element_override: int = -1) -> float:
	if attacker == null:
		return 0.0
	var base_break := calc_raw_break_damage(attacker, target, element_override)
	var be_mult := 1.0 + attacker.get_effective_be()
	var break_boost_mult := 1.0 + float(attacker.get_meta("break_dmg_boost", 0.0))
	if target != null:
		if target.has_meta("insurgent_extra_break_vuln") and target.statuses.toughness_broken:
			break_boost_mult += float(target.get_meta("insurgent_extra_break_vuln", 0.0))
		if target.id == "antimatter_slave" and target.statuses.toughness_broken:
			break_boost_mult += 0.50

	var def_ignore_extra := 0.0
	if attacker.has_meta("set_dark_side_defector_4"):
		if attacker.get_effective_be() >= 1.30:
			def_ignore_extra += 0.10

	var def_mult := get_def_multiplier(attacker, target, def_ignore_extra)
	var res_mult := get_res_multiplier(attacker, target, element_override) if target != null else 1.0
	var vuln_mult := get_vuln_multiplier(target)
	var dmg_red_mult := get_dmg_reduction_multiplier(target)
	# Множитель пробития цели: 0.9 если стойкость не была истощена (включая первичный урон пробития)
	var broken_mult := 0.9 if (target == null or not target.statuses.toughness_broken) else 1.0

	return base_break * ability_mult * be_mult * break_boost_mult * def_mult * res_mult * vuln_mult * dmg_red_mult * broken_mult

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

static func calc_super_break_damage(attacker: CombatUnit, target: CombatUnit, base_tgh_reduction: float, ability_mult: float = 1.0) -> float:
	if attacker == null or target == null:
		return 0.0

	# 1. Уменьшение стойкости / 10 с учетом эффективности пробития атакующего
	var effective_tgh_reduction: float = base_tgh_reduction * (1.0 + attacker.stats.weakness_efficiency)
	var tgh_reduction_term: float = effective_tgh_reduction / 10.0

	# 2. Множитель уровня и способности
	var base_super_break: float = tgh_reduction_term * LEVEL_MULTIPLIER * ability_mult

	# 3. (1 + Эффект пробития)
	var break_effect_mult: float = 1.0 + attacker.get_effective_be()

	# 4. (1 + Повышение урона пробития)
	var break_boost_mult: float = 1.0 + float(attacker.get_meta("break_dmg_boost", 0.0))
	if target.has_meta("insurgent_extra_break_vuln") and target.statuses.toughness_broken:
		break_boost_mult += float(target.get_meta("insurgent_extra_break_vuln", 0.0))
	if target.id == "antimatter_slave" and target.statuses.toughness_broken:
		break_boost_mult += 0.50

	# 5. (1 + Повышение урона суперпробития)
	var extra_sb_mult: float = float(attacker.get_meta("super_break_mult", 0.0))
	# След 3 Ленской: Урон Суперпробития Усиленной базовой атаки повышается на 30%
	if attacker.id == "lenskaya_sky_guardian" and (attacker.get_meta("is_enhanced_basic", false) or (base_tgh_reduction >= 30.0 and int(attacker.get_meta("lenskaya_enhanced_basic_turns", 0)) > 0)):
		extra_sb_mult += 0.30
	var super_break_boost_mult: float = 1.0 + extra_sb_mult

	# 6. Множитель защиты
	var def_ignore_extra := 0.0
	if attacker.has_meta("set_dark_side_defector_4"):
		var eff_be := attacker.get_effective_be()
		if eff_be >= 1.80:
			def_ignore_extra += 0.15

	var def_mult: float = get_def_multiplier(attacker, target, def_ignore_extra)

	# 7. Множитель сопротивления
	var res_mult: float = get_res_multiplier(attacker, target)

	# 8. Множитель получаемого урона (Vulnerability)
	var vuln_mult: float = get_vuln_multiplier(target)

	# 9. Множитель уменьшения урона цели
	var dmg_red_mult: float = get_dmg_reduction_multiplier(target)

	return base_super_break * break_effect_mult * break_boost_mult * super_break_boost_mult * def_mult * res_mult * vuln_mult * dmg_red_mult
