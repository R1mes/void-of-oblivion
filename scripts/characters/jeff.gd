class_name JeffAbilities
extends RefCounted

const ID: String = "jeff"
const MAX_ENERGY: float = 160.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Джефф",
		"element": CombatConstants.Element.LIGHTNING, # Электрический
		"path": CombatConstants.Path.ABUNDANCE,       # Изобилие
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 4200,
			"atk": 1100,
			"def": 750,
			"spd": 104,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.15,
			"break_effect": 0.20,
			"weakness_efficiency": 0.00,
		},
	})
	unit.set_meta("jeff_make_noise_active", false)
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	# Джефф является членом фракции Обреченных
	unit.set_meta("faction_doomed_member", true)

# Наложение статуса "Бассы! Слушай!" на цель с проработкой Следа 2
static func apply_bass_listen(jeff: CombatUnit, target: CombatUnit, bm: BattleManager, turns: int) -> void:
	if NaamaAbilities.roll_debuff(0.85, jeff, target, bm):
		target.set_meta("jeff_bass_listen_turns", turns)
		# СТРОКА С АКТИВАЦИЕЙ "jeff_bass_listen_skip_tick" ПОЛНОСТЬЮ УДАЛЕНА ОТСЮДА
		
		bm.log_message("🎶 На %s наложен статус «Бассы! Слушай!» (Шок) на %d х." % [target.display_name, turns])
		bm.unit_updated.emit(target)
		
		# След 2: Хилл союзника с самым низким процентом ХП
		var best_ally: CombatUnit = null
		var lowest_pct: float = 2.0
		for ally in bm.allies:
			if ally.is_alive():
				var pct: float = ally.stats.hp / ally.stats.max_hp
				if pct < lowest_pct:
					lowest_pct = pct
					best_ally = ally
					
		if best_ally:
			var heal_amt: float = jeff.stats.max_hp * 0.08 + 50.0
			bm.heal_unit(best_ally, heal_amt)
			bm.log_message("🎶 След 2 Джеффа: Союзник %s с наивысшей потерей ХП исцелен на %d!" % [best_ally.display_name, int(heal_amt)])
	else:
		bm.log_message("💨 Промах! Статус «Бассы! Слушай!» не наложился на %s из-за сопротивления эффектам." % target.display_name)
		
# БАЗОВАЯ АТАКА (100% СА, E4: Хилл себя на 10% макс. ХП)
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 1.00, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm)
	
	# Эйдолон 4: Восстановление 10% от макс. ХП при базовой атаке
	if attacker.eidolon >= 4:
		var self_heal: float = attacker.stats.max_hp * 0.10
		bm.heal_unit(attacker, self_heal)
		bm.log_message("⚡ Эйдолон 4 Джеффа: Базовая атака восстановила Джеффу %d ХП." % int(self_heal))
		
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.action_order_changed.emit()


# НАВЫК Q (Хилл 20% макс. ХП + 200 выбранному, и 10% макс. ХП + 50 соседям)
static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	# Вычисляем хилл центральной цели
	var central_heal: float = attacker.stats.max_hp * 0.20 + 200.0
	bm.heal_unit(target, central_heal)
	
	# ИСПРАВЛЕНО: Считываем соседей-союзников через центральный метод менеджера боя
	var adjacent := bm.get_adjacent_allies(target)
	for adj in adjacent:
		if adj.is_alive():
			var adj_heal: float = attacker.stats.max_hp * 0.10 + 50.0
			bm.heal_unit(adj, adj_heal)
	bm.gain_energy_with_err(attacker, 15.0)
			
# НАВЫК E (Наложение статуса "Бассы! Слушай!" на цель и соседей на 2 хода)
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var adjacent := bm.get_adjacent_enemies(target)
	
	apply_bass_listen(attacker, target, bm, 2)
	
	for adj in adjacent:
		if adj.is_alive():
			apply_bass_listen(attacker, adj, bm, 2)
			
	bm.gain_energy_with_err(attacker, 30.0)
	bm.action_order_changed.emit()

# СВЕРХСПОСОБНОСТЬ (Хилл всех на 15% макс. ХП + 200, заливка +20 энергии всем союзникам)
static func execute_ultimate(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("🔊 Сверхспособность Джеффа: Бассы на максимум! Хилл и заливка энергии отряду!")
	
	var heal_amt: float = attacker.stats.max_hp * 0.15 + 200.0
	for ally in bm.allies:
		if ally.is_alive():
			bm.heal_unit(ally, heal_amt)
			bm.gain_energy_with_err(ally, 20.0)
			
	# След 1: Сверхспособность обновляет длительность всех активных DoT на врагах
	for enemy in bm.enemies:
		if enemy.is_alive():
			var dots_updated := false
			if enemy.has_meta("shoji_burn_turns") and int(enemy.get_meta("shoji_burn_turns", 0)) > 0:
				enemy.set_meta("shoji_burn_turns", 3)
				dots_updated = true
			if enemy.has_meta("naama_intox_stacks") and int(enemy.get_meta("naama_intox_stacks", 0)) > 0:
				# Для Опьянения Наамы не сбрасываем стаки, а просто подтверждаем удержание
				dots_updated = true
			if enemy.has_meta("jeff_bass_listen_turns") and int(enemy.get_meta("jeff_bass_listen_turns", 0)) > 0:
				enemy.set_meta("jeff_bass_listen_turns", 2)
				dots_updated = true
			if enemy.has_meta("radiance_status_turns") and int(enemy.get_meta("radiance_status_turns", 0)) > 0:
				enemy.set_meta("radiance_status_turns", 2)
				dots_updated = true
			if enemy.statuses.break_status != "":
				enemy.statuses.break_status_turns = 3
				dots_updated = true
				
			if dots_updated:
				bm.log_message("⚡ След 1 Джеффа: Все DoT-статусы на %s обновлены!" % enemy.display_name)
				bm.unit_updated.emit(enemy)
				
	# Эйдолон 1: Сверхспособность активирует Талант «Пошумите!»
	if attacker.eidolon >= 1:
		attacker.set_meta("jeff_make_noise_active", true)
		bm.log_message("⚡ Эйдолон 1 Джеффа: статус «Пошумите!» активирован за ультимейт.")

	bm.gain_energy_with_err(attacker, 5.0)
	bm.unit_updated.emit(attacker)

# БОНУС-АТАКA ТАЛАНТА (Наносит 30% макс. ХП Джеффа и вешает дебафф)
static func trigger_talent_fua(unit: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("💥 Джефф проводит БОНУС-АТАКУ «Пошумите!» по %s!" % target.display_name)
	
	if bm.has_meta("lenskaya_fua_attacker_credited"):
		bm.remove_meta("lenskaya_fua_attacker_credited")
		
	var dmg_base: float = unit.stats.max_hp * 0.30
	var def_mult := DamageCalculator.calc_def_multiplier(target.stats.def)
	var final_dmg := dmg_base * def_mult
	
	bm.deal_damage(target, final_dmg, unit, unit.element, false, "Бонус-атака")
	bm.apply_weakness_hit_and_delay(unit, target, bm, 0.5) # Стойкость бонус-атак 0.5
	
	# Наложение статуса "Бассы! Слушай!" на 2 хода
	apply_bass_listen(unit, target, bm, 2)
	
	# След 3: Проведение бонус-атаки увеличивает исходящий хил Джеффа на 20% на 1 ход
	unit.set_meta("jeff_trace3_heal_buff", 0.20)
	unit.set_meta("jeff_trace3_heal_turns", 1)
	unit.set_meta("jeff_trace3_heal_skip_tick", true)
	
	# Эйдолон 6: Бонус-атака детонирует DoT на цели с 25% эффективностью
	if unit.eidolon >= 6:
		bm.log_message("⚡ Эйдолон 6 Джеффа: Бонус-атака провоцирует детонацию DoT на цели!")
		bm.explode_dots(target, unit, 0.25)
		
	if bm.has_meta("lenskaya_fua_attacker_credited"):
		bm.remove_meta("lenskaya_fua_attacker_credited")
