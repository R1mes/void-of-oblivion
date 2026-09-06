class_name ToughnessSystem
extends RefCounted

const BASE_TGH_REDUCTION := 30.0

# Откройте toughness_system.gd и обновите первую функцию класса:
# === ЗАМЕНИТЬ МЕТОД apply_weakness_hit В TOUGHNESS_SYSTEM.GD ===
# === ОБНОВЛЕННЫЙ МЕТОД В TOUGHNESS_SYSTEM.GD ===
static func apply_weakness_hit(
	attacker: CombatUnit,
	target: CombatUnit,
	battle: BattleManager,
	multiplier: float = 1.0
) -> bool:
	if target == null or attacker == null:
		return false 
	if target.has_meta("rimes_isolation_source") and attacker.id != "rimes":
		return false 
	if not target.is_ally and target.max_toughness <= 0.0:
		return false
	if target.toughness <= 0.0:
		return false
	if not CombatConstants.element_matches_weakness(attacker.element, target.weaknesses):
		return false

	# Учитываем множитель конкретного умения при срезе стойкости
	# (новое значение stats.weakness_efficiency автоматически учтено здесь)
	var reduction: float = BASE_TGH_REDUCTION * (1.0 + attacker.stats.weakness_efficiency) * multiplier
	
	target.toughness = maxf(target.toughness - reduction, 0.0)

	if target.toughness <= 0.0:
		_trigger_break(attacker, target, battle)
		return true
	return false

# === ЗАМЕНИТЬ МЕТОД _trigger_break В TOUGHNESS_SYSTEM.GD ===
static func _trigger_break(attacker: CombatUnit, target: CombatUnit, battle: BattleManager) -> void:
	var break_dmg: float = DamageCalculator.calc_break_damage(attacker, target)

	# Аномалия Уровня 13: Урон Пробития и Суперпробития +50%
	if battle.battle_mode == "level_13":
		break_dmg *= 1.50

	# Бронированный Рыцарь: Снятие Адской Брони при пробое и удвоение урона пробития
	if target.id == "void_armored" and target.has_meta("hell_armor") and target.get_meta("hell_armor"):
		target.set_meta("hell_armor", false)
		break_dmg *= 2.0 # Удваиваем урон пробития
		battle.log_message("Уязвимость пробита в состоянии Адской Брони! Броня разрушена, урон пробития удвоен!")

	# Серверный Вирус: Пробитие его уязвимости даёт 40 Векторов
	if target.id == "server_virus":
		battle.add_console_vectors(40)
		battle.log_message("🌐 Пробита уязвимость Серверного Вируса! Получено +40 Векторов Консоли!")
		
		# Аномалия Уровня 15: сносит 2 слоя Файрвола и наносит 10% макс ХП
		if battle.battle_mode == "level_15" and target.has_meta("server_virus_firewall"):
			var fw: int = int(target.get_meta("server_virus_firewall", 0))
			fw = maxi(0, fw - 2)
			target.set_meta("server_virus_firewall", fw)
			battle.log_message("⚡ Аномалия Уровня 15: Пробитие стойкости снесло 2 слоя Файрвола! Осталось: %d" % fw)
			if fw == 0:
				battle.add_console_vectors(10)
				target.set_meta("server_virus_breached_turns", 2)
				battle.log_message("💥 Файрвол Серверного Вируса полностью взломан! Получено +10 Векторов, цель получает +20% уязвимости на 2 хода!")
				battle.unit_updated.emit(target)
			var extra_virus_dmg := target.stats.max_hp * 0.10
			battle.deal_damage(target, extra_virus_dmg, attacker, -1, false, "True Damage")

	# Аномалия Уровня 12: Пробитие уязвимости продвигает действие союзника на 30%
	if battle.battle_mode == "level_12" and attacker != null and attacker.is_ally:
		attacker.advance_action(30.0)
		battle.action_order_changed.emit()
		battle.log_message("⚡ Аномалия Уровня 12: Пробитие уязвимости продвинуло действие %s на 30%%!" % attacker.display_name)

	# ИСПРАВЛЕНО: Наносим урон через deal_damage, чтобы он записывался в статистику атакующего
	battle.deal_damage(target, break_dmg, attacker)

	battle.log_message(
		"%s пробил стойкость %s! Урон пробития: %d" % [
			attacker.display_name,
			target.display_name,
			int(break_dmg),
		],
	)

	target.statuses.toughness_broken = true
	target.statuses.toughness_break_source = attacker.display_name
	target.statuses.damage_taken_bonus = CombatConstants.BREAK_DAMAGE_BONUS
	target.delay_action(CombatConstants.BREAK_ACTION_DELAY * 100.0)

	if target.statuses.suppression_stacks > 0:
		target.delay_action(CombatConstants.SUPPRESSION_BREAK_EXTRA_DELAY * 100.0)

	_apply_break_status(attacker.element, target, battle, attacker)

	# --- ИСПРАВЛЕНО: ГЛОБАЛЬНОЕ НАЛОЖЕНИЕ СРЕЗА ЗАЩИТЫ ЖЕРТВЫ СИМБИОЗА (4 части) ПРИ ПРОБОЕ ---
	if attacker.has_meta("set_symbiosis_4"):
		battle.apply_def_reduction(target, "Жертва долгого симбиоза (4ч)", 0.15, 99)
		battle.log_message("❄ Сет Симбиоза (4ч) %s: Защита %s снижена на 15%% при пробитии уязвимости!" % [attacker.display_name, target.display_name])

	# ИСПРАВЛЕНО: След 1 Каори переработан на доп. урон (150 * ЭП)% от её силы атаки
	if attacker.id == KaoriAbilities.ID:
		var kaori_trace_dmg: float = (1.50 * attacker.get_effective_be()) * attacker.stats.atk
		battle.deal_damage(target, kaori_trace_dmg, attacker)
		battle.log_message(
			"След 1 Каори: Доп. урон пробития (150 * ЭП)%% СА — %d" % int(kaori_trace_dmg),
		)

	# --- ИСПРАВЛЕНО: Талант Даши (Получение стака «Пируэта») ---
	if attacker.id == "dasha" and attacker.get_meta("circle_dance", false):
		var stacks: int = int(attacker.get_meta("pirouette_stacks", 0)) + 1
		attacker.set_meta("pirouette_stacks", stacks)
		battle.log_message("Талант Даши: Получен стак «Пируэта» (%d/3)!" % stacks)
		if stacks >= 3:
			attacker.set_meta("pirouette_stacks", 0)
			# Моментальный запуск бонус-атаки
			battle.execute_dasha_bonus_attack(attacker)

	# --- ИСПРАВЛЕНО: След 3 Даши (Накапливаем количество пробитых врагов Навыком Q за этот удар) ---
	if attacker.id == "dasha" and battle.get_meta("current_attack_type", "") == "skill_q":
		attacker.set_meta("dasha_q_breaks", int(attacker.get_meta("dasha_q_breaks", 0)) + 1)

	# --- ИСПРАВЛЕНО: Trace 2 Марины (союзник пробил — Марина наносит урон на свой счет) ---
	for ally in battle.allies:
		if ally.id == MarinaAbilities.ID and ally != attacker and ally.is_alive():
			var marina_break: float = DamageCalculator.calc_break_damage(ally, target)
			battle.deal_damage(target, marina_break, ally)
			battle.log_message(
				"След Марины: доп. урон пробития %d" % int(marina_break),
			)

	# Эйдолон 4 Данилла: накладывает щит Q на пробившего союзника при пробое Элиты
	if target.is_elite:
		var danill: CombatUnit = battle.get_danila_unit()
		if danill and danill.is_alive() and danill.eidolon >= 4:
			var q_shield: float = danill.stats.def * 0.60 + 330.0
			battle.apply_shield(attacker, q_shield, 3, "Е4 Данилла")
			battle.log_message("Эйдолон 4 Данилла: На %s наложен щит за пробитие Элиты!" % attacker.display_name)

	# Конус «Коснись...»: дает 1 стак Долга при пробитии союзником уязвимости
	for ally in battle.allies:
		if ally.is_alive() and ally.get_meta("light_cone_id", "") == "touch_waking_world":
			var current_debt: int = int(ally.get_meta("mutual_debt_stacks", 0))
			var new_debt: int = mini(current_debt + 1, 5)
			ally.set_meta("mutual_debt_stacks", new_debt)
			battle.log_message("🛡 Конус «Коснись...»: %s получил %d стак «Общего долга» за пробитие." % [ally.display_name, new_debt])
			
static func _apply_break_status(
	element: CombatConstants.Element,
	target: CombatUnit,
	battle: BattleManager,
	attacker: CombatUnit,
) -> void:
	var src := attacker.display_name
	match element:
		CombatConstants.Element.FIRE:
			target.statuses.break_status = "Горение"
			target.statuses.break_status_turns = 3
			target.statuses.break_status_source = src
			battle.log_message("%s получает Горение" % target.display_name)
		CombatConstants.Element.WIND:
			target.statuses.break_status = "Выветривание"
			target.statuses.break_status_turns = 3
			target.statuses.break_status_source = src
			battle.log_message("%s получает Выветривание" % target.display_name)
		CombatConstants.Element.PHYSICAL:
			target.statuses.break_status = "Кровотечение"
			target.statuses.break_status_turns = 3
			target.statuses.break_status_source = src
			battle.log_message("%s получает Кровотечение" % target.display_name)
		CombatConstants.Element.LIGHTNING:
			target.statuses.break_status = "Шок"
			target.statuses.break_status_turns = 3
			target.statuses.break_status_source = src
			battle.log_message("%s получает Шок" % target.display_name)
		CombatConstants.Element.ICE:
			target.statuses.skip_next_turn = true
			target.statuses.skip_next_turn_source = src
			battle.log_message("%s заморожен!" % target.display_name)
		CombatConstants.Element.QUANTUM:
			target.statuses.entanglement_stacks += 1
			target.statuses.entanglement_source = src
			battle.log_message("%s получает Связывание (стак %d)" % [
				target.display_name,
				target.statuses.entanglement_stacks,
			])
		CombatConstants.Element.IMAGINARY:
			target.delay_action(50.0)
			target.statuses.imaginary_spd_debuff_turns = 2
			target.statuses.imaginary_source = src
			target.stats.add_spd_debuff(0.20)
			battle.log_message("%s в Оковах" % target.display_name)

static func on_hit_entanglement(target: CombatUnit) -> void:
	if target.statuses.entanglement_stacks > 0:
		target.statuses.entanglement_stacks += 1

# === ОБНОВЛЕННЫЙ МЕТОД В TOUGHNESS_SYSTEM.GD ===
static func process_turn_start_dots(target: CombatUnit, battle: BattleManager) -> void:
	# 1. Обработка Подавления Марины на Е1
	if target.statuses.suppression_is_dot and target.statuses.suppression_stacks > 0:
		var marina := battle.get_marina_unit()
		if marina and marina.is_alive() and marina.eidolon >= 1:
			var stacks := target.statuses.suppression_stacks
			var talent_mult := 0.40 * float(stacks)
			
			var dot_res := battle.calc_dmg(marina, target, talent_mult, 0.0, false, 0.0, 0.0, false, false)
			var dot_dmg := float(dot_res.get("damage", 0.0))
			
			# Наносим урон и сохраняем ФАКТИЧЕСКИ нанесенное значение (после всех множителей в deal_damage)
			var actual_dmg: float = battle.deal_damage(target, dot_dmg, marina, CombatConstants.Element.ICE, false, "DoT")
			
			# Выводим в логгер реальный урон
			battle.log_message(
				"DoT Подавления x%d на %s: %d урона (Е1 Марины)." % [stacks, target.display_name, int(actual_dmg)]
			)

	# 2. Обработка Связывания (Квантовый пробой)
	if target.statuses.entanglement_stacks > 0:
		var stacks := target.statuses.entanglement_stacks
		var dot := DamageCalculator.calc_dot_damage(
			battle._get_last_attacker_or_default(),
			0.20 * float(stacks),
		)
		# Сохраняем и выводим фактический урон
		var actual_dmg: float = battle.deal_damage(target, dot, battle._get_last_attacker_or_default())
		battle.log_message(
			"Связывание на %s: %d урона (%d стаков)" % [
				target.display_name, int(actual_dmg), stacks,
			],
		)
		target.statuses.entanglement_stacks = 0
		return

	# 3. Обработка остальных периодических эффектов пробития (Шок, Горение и т.д.)
	if target.statuses.break_status != "" and target.statuses.break_status_turns > 0:
		var dot := DamageCalculator.calc_dot_damage(
			battle._get_last_attacker_or_default(),
			0.30,
		)
		# Сохраняем и выводим фактический урон
		var actual_dmg: float = battle.deal_damage(target, dot, battle._get_last_attacker_or_default())
		battle.log_message(
			"DoT (%s) на %s: %d" % [
				target.statuses.break_status,
				target.display_name,
				int(actual_dmg),
			],
		)
		target.statuses.break_status_turns -= 1
		if target.statuses.break_status_turns <= 0:
			target.statuses.break_status = ""
			target.statuses.break_status_source = ""
								
static func tick_imaginary_debuff(target: CombatUnit) -> void:
	if target.statuses.imaginary_spd_debuff_turns > 0:
		target.statuses.imaginary_spd_debuff_turns -= 1
		if target.statuses.imaginary_spd_debuff_turns <= 0:
			target.stats.clear_spd_debuffs()
			target.statuses.imaginary_source = ""
