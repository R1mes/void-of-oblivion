class_name ValramorsAbilities
extends RefCounted

const ID: String = "valramors"
const MAX_ENERGY: float = 120.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Валраморс",
		"element": CombatConstants.Element.QUANTUM, # Квантовый
		"path": CombatConstants.Path.NIHILITY,       # Небытие
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3100,
			"atk": 1450,
			"def": 850,
			"spd": 106,
			"crit_rate": 0.28,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.15,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	# Валраморс принадлежит к двум фракциям: Обреченные и Рассвет Хаоса
	unit.set_meta("faction_doomed_member", true)
	unit.set_meta("faction_chaos_member", true)

# Динамический расчет эффективного ШПЭ (След 2: +35% от шанса крита)
static func get_valramors_ehr(unit: CombatUnit) -> float:
	if unit == null:
		return 0.0
	return unit.stats.effect_hit_rate + (unit.stats.crit_rate * 0.35)

# Наложение дебаффа Таланта «Приказ принят»
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В VALRAMORS.GD ===
static func apply_talent_debuff(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var ehr := get_valramors_ehr(attacker)
	
	var base_chance := 1.00
	
	# ИСПРАВЛЕНО: Безопасное считывание Сопротивления эффектам во избежание падения движка
	var eff_res: float = NaamaAbilities.get_effect_res(target)
	var final_chance: float = float(base_chance * (1.0 + ehr) * (1.0 - eff_res))
	
	if randf() < final_chance:
		target.set_meta("valramors_talent_turns", 3)
		target.set_meta("valramors_talent_skip_tick", true)
		
		if not target.has_meta("valramors_spd_applied"):
			target.set_meta("valramors_spd_applied", true)
			target.add_speed_modifier(-0.08, 0.0)
			target.recalculate_action_value()
			bm.action_order_changed.emit()
		
		# Наложение уязвимости по первому персонажу в отряде (slot_index = 0)
		var allies_list := bm.get_living_allies()
		if allies_list.size() > 0:
			var first_ally := allies_list[0]
			var first_element: int = first_ally.element
			
			if not first_element in target.weaknesses:
				target.weaknesses.append(first_element)
				target.set_meta("valramors_talent_weakness", first_element)
				bm.log_message("🎭 Талант Валраморса: На %s наложен дебафф «Приказ принят» (АТК −15%%, СКР −8%%) и уязвимость %s на 3 хода." % [target.display_name, CombatConstants.ELEMENT_NAMES.get(first_element, "?")])
		bm.unit_updated.emit(target)
	else:
		bm.log_message("💨 Промах! Талант Валраморса не наложил дебафф на %s из-за сопротивления." % target.display_name)
		
# БАЗОВАЯ АТАКА (120% СА)
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 1.20, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm)
	
	# Талант «Приказ принят» срабатывает при каждой атаке
	apply_talent_debuff(attacker, target, bm)
	
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.action_order_changed.emit()

# НАВЫК Q (190% СА выбранному, базовый шанс 120% на срез защиты −40% на 2 хода)
# Е6: Навык Q атакует ВСЕХ противников на поле боя и срезает им защиту
static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var e6_active := attacker.eidolon >= 6
	var ehr := get_valramors_ehr(attacker)
	
	if e6_active:
		bm.log_message("⚡ Э6 Валраморса: Навык Q наносит сокрушительный АоЕ-удар по всем врагам!")
		var living := bm.get_living_enemies()
		for enemy in living:
			var res := bm.calc_dmg(attacker, enemy, 1.90, 0.0, false, 0.0, 0.0, false, true, "Skill")
			bm.deal_damage(enemy, res.damage, attacker, attacker.element, res.crit, "Skill")
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
			
			# Срез защиты (Базовый шанс 120%)
			if NaamaAbilities.roll_debuff(1.20, attacker, enemy, bm):
				bm.apply_def_reduction(enemy, "Навык Валраморса (Е6)", 0.40, 2)
			apply_talent_debuff(attacker, enemy, bm)
	else:
		var res := bm.calc_dmg(attacker, target, 1.90, 0.0, false, 0.0, 0.0, false, true, "Skill")
		bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Skill")
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
		
		# Срез защиты выбранной цели (Базовый шанс 120%)
		if NaamaAbilities.roll_debuff(1.20, attacker, target, bm):
			bm.apply_def_reduction(target, "Навык Валраморса", 0.40, 2)
		apply_talent_debuff(attacker, target, bm)
		
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)
	bm.action_order_changed.emit()

# НАВЫК E (Статус «Передача порчи» на союзника на 3 хода)
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	target.set_meta("valramors_corruption_transfer", true)
	bm.log_message("🔮 Навык E: На союзника %s наложен статус «Передача порчи»!" % target.display_name)
	bm.unit_updated.emit(target)
	bm.gain_energy_with_err(attacker, 30.0)

# СВЕРХСПОСОБНОСТЬ (300% СА центру, 100% СА соседям)
static func execute_ultimate(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("🔮 Сверхспособность Валраморса: Искажение пространства!")
	
	# Кэшируем соседей ДО нанесения урона и смерти центральной цели
	var adjacent := bm.get_adjacent_enemies(target)
	
	# Урон по центральной цели
	var res_c := bm.calc_dmg(attacker, target, 2.60, 0.0, false, 0.0, 0.0, true, true, "Ultimate")
	bm.deal_damage(target, res_c.damage, attacker, attacker.element, res_c.crit, "Ultimate")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 2.0)
	apply_talent_debuff(attacker, target, bm)
	
	# Е1: Сверхспособность восстанавливает по 5 энергии за каждое ослабление (макс 20)
	if attacker.eidolon >= 1:
		var debuff_count := 0
		if target.has_meta("def_reductions") and not target.get_meta("def_reductions").is_empty(): debuff_count += 1
		if target.has_meta("naama_kiss_turns") and int(target.get_meta("naama_kiss_turns", 0)) > 0: debuff_count += 1
		if target.has_meta("isaac_dmg_reduce_turns") and int(target.get_meta("isaac_dmg_reduce_turns", 0)) > 0: debuff_count += 1
		if target.has_meta("isaac_crit_dmg_taken_turns") and int(target.get_meta("isaac_crit_dmg_taken_turns", 0)) > 0: debuff_count += 1
		if target.has_meta("valramors_talent_turns") and int(target.get_meta("valramors_talent_turns", 0)) > 0: debuff_count += 2 # ATK & SPD
		if target.has_meta("shoji_burn_turns") and int(target.get_meta("shoji_burn_turns", 0)) > 0: debuff_count += 1
		if target.has_meta("naama_intox_stacks") and int(target.get_meta("naama_intox_stacks", 0)) > 0: debuff_count += 1
		if target.has_meta("jeff_bass_listen_turns") and int(target.get_meta("jeff_bass_listen_turns", 0)) > 0: debuff_count += 1
		
		var energy_gain: float = minf(20.0, float(debuff_count) * 5.0)
		if energy_gain > 0.0:
			bm.gain_energy_with_err(attacker, energy_gain)
			bm.log_message("🔮 Э1 Валраморса: Восстановлено +%d энергии за %d дебаффов на цели!" % [int(energy_gain), debuff_count])

	# Условия Сверхспособности на ХП центральной цели после атаки
	if target.is_alive():
		var hp_ratio := target.stats.hp / target.stats.max_hp
		var is_boss := target.id == "masked_silhouette"
		
		# Если не босс и ХП < 10% — моментальная Казнь (чистым уроном)
		if not is_boss and hp_ratio < 0.10:
			bm.log_message("🔮 Сверхспособность Валраморса: Здоровье элиты/рядового %s упало ниже 10%%! Моментальная КАЗНЬ!" % target.display_name)
			var cur_hp := target.stats.hp
			bm.deal_damage(target, cur_hp, attacker, attacker.element, false, "rimes_execution")
		# Если ХП после атаки > 50% — уязвимость +20% к получаемому урону на 2 хода
		elif hp_ratio > 0.50:
			target.set_meta("valramors_ult_vuln_turns", 2)
			target.set_meta("valramors_ult_vuln_skip_tick", true)
			bm.log_message("🔮 Сверхспособность Валраморса: Здоровье цели %s выше 50%%! Получаемый ею урон увеличен на +20%% на 2 хода." % target.display_name)
			bm.unit_updated.emit(target)

	# Урон по соседям
	for adj in adjacent:
		if adj.is_alive():
			var res_a := bm.calc_dmg(attacker, adj, 1.00, 0.0, false, 0.0, 0.0, true, true, "Ultimate")
			bm.deal_damage(adj, res_a.damage, attacker, attacker.element, res_a.crit, "Ultimate")
			ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 1.0)
			apply_talent_debuff(attacker, adj, bm)
			
	# Е4: Сверхспособность задерживает действия всех пораженных врагов на 20%
	if attacker.eidolon >= 4:
		if target.is_alive():
			target.delay_action(20.0)
		for adj in adjacent:
			if adj.is_alive():
				adj.delay_action(20.0)
		bm.log_message("⚡ Эйдолон 4 Валраморса: Действия пораженных противников отложены на 20%.")
		bm.action_order_changed.emit()
		
	bm.gain_energy_with_err(attacker, 5.0)
	bm.unit_updated.emit(attacker)
