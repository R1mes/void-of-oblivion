# scripts/characters/lenskaya.gd
class_name LenskayaAbilities
extends RefCounted

const ID: String = "lenskaya"
const MAX_ENERGY: float = 130.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit: CombatUnit = CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Ленская",
		"element": CombatConstants.Element.ICE,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3100,
			"atk": 2000,
			"def": 600,
			"spd": 101,
			"crit_rate": 0.05,
			"crit_dmg": 0.30,
			"effect_hit_rate": 0.00,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	pass

# Накопление зарядов Манипуляции
static func add_manipulation_stack(unit: CombatUnit, count: int, bm: BattleManager) -> void:
	var current: int = int(unit.get_meta("lenskaya_manipulation", 0))
	
	# ИСПРАВЛЕНО: Лимит Манипуляций занерфлен и ограничен на уровне 47 стаков
	var new_stacks: int = clampi(current + count, 0, 47)
	
	unit.set_meta("lenskaya_manipulation", new_stacks)
	bm.log_message("Манипуляция %s: %d зарядов (максимум: 47)." % [unit.display_name, new_stacks])
	bm.unit_updated.emit(unit)

# Регистрация бонус-атак союзников для Таланта и Следа 3
# Регистрация бонус-атак союзников для Таланта и Следа 3
static func on_ally_fua(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var lenskaya: CombatUnit = bm.get_lenskaya_unit()
	if lenskaya == null or not lenskaya.is_alive():
		return
		
	# Талант: За каждую Бонус-атаку Ленская получает 2 заряда Манипуляции
	add_manipulation_stack(lenskaya, 2, bm)
	
	# ИСПРАВЛЕНО: След 3 — СА союзника +15% на 2 хода (может суммироваться до 2 раз, макс +30% СА)
	var current_stacks: int = int(attacker.get_meta("lenskaya_trace3_stacks", 0))
	if current_stacks < 2:
		var new_stacks: int = current_stacks + 1
		attacker.set_meta("lenskaya_trace3_stacks", new_stacks)
		attacker.set_meta("lenskaya_trace3_atk_percent", float(new_stacks) * 0.15)
		attacker.set_meta("lenskaya_trace3_turns", 2)
		bm.log_message("След 3 Ленской: СА %s повышена на +15%% на 2 хода (стаки: %d/2)." % [attacker.display_name, new_stacks])
	else:
		# Если стаки уже максимальные, просто обновляем длительность баффа
		attacker.set_meta("lenskaya_trace3_turns", 2)
		bm.log_message("След 3 Ленской: Длительность СА баффа на %s обновлена до 2 ходов." % attacker.display_name)
		
	bm.unit_updated.emit(attacker)
	
# БАЗОВАЯ АТАКА (Обычная / Улучшенная в Жале)
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var in_stinger: bool = int(attacker.get_meta("lenskaya_stinger_turns", 0)) > 0
	var tag: String = "Basic"
	if attacker.eidolon >= 6:
		tag = "Бонус-атака" # Е6: Весь урон Ленской считается Бонус-атаками
		
	if in_stinger:
		# ИСПРАВЛЕНО: Кэшируем соседей ДО нанесения урона и смерти центральной цели!
		var adjacent: Array[CombatUnit] = bm.get_adjacent_enemies(target)
		
		# Усиленная: 160% СА центру, 60% соседям
		var res_c: Dictionary = bm.calc_dmg(attacker, target, 1.60, 0.0, false, 0.0, 0.0, false, true, tag)
		bm.deal_damage(target, res_c.damage, attacker, attacker.element, res_c.crit, tag)
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
		
		for adj in adjacent:
			if adj.is_alive():
				var res_a: Dictionary = bm.calc_dmg(attacker, adj, 0.60, 0.0, false, 0.0, 0.0, false, true, tag)
				bm.deal_damage(adj, res_a.damage, attacker, attacker.element, res_a.crit, tag)
				ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 0.5)
	else:
		# Обычная: 110% СА
		var res: Dictionary = bm.calc_dmg(attacker, target, 1.10, 0.0, false, 0.0, 0.0, false, true, tag)
		bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, tag)
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
		
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	
# НАВЫК Q (Обычный AoE / Улучшенный - Награда за голову)
static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, extra_targets: Array, bm: BattleManager) -> void:
	var in_stinger: bool = int(attacker.get_meta("lenskaya_stinger_turns", 0)) > 0
	var tag: String = "Skill"
	if attacker.eidolon >= 6:
		tag = "Бонус-атака"
		
	if in_stinger:
		# Улучшенный Q: Статус Награда за голову на 1 ход (на 3 хода при Е4)
		var living: Array[CombatUnit] = bm.get_living_enemies()
		for enemy in living:
			enemy.remove_meta("lenskaya_bounty_turns") # Снимаем старую метку
			
		var bounty_turns: int = 3 if attacker.eidolon >= 4 else 1
		target.set_meta("lenskaya_bounty_turns", bounty_turns)
		
		bm.log_message("Улучшенный Q: На %s наложен статус «Награда за голову» на %d х." % [target.display_name, bounty_turns])
		bm.unit_updated.emit(target)
	else:
		# Обычный Q: 180% СА всем и замедление на 20% на 2 хода (Базовый шанс 100%, НЕ СУММИРУЕТСЯ)
		var living: Array[CombatUnit] = bm.get_living_enemies()
		for enemy in living:
			var res: Dictionary = bm.calc_dmg(attacker, enemy, 1.80, 0.0, false, 0.0, 0.0, false, true, tag)
			bm.deal_damage(enemy, res.damage, attacker, attacker.element, res.crit, tag)
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
			
			# ИСПРАВЛЕНО: Проверка не-суммирования замедления Ленской
			if not enemy.has_meta("lenskaya_slow_turns") or int(enemy.get_meta("lenskaya_slow_turns", 0)) <= 0:
				if NaamaAbilities.roll_debuff(1.00, attacker, enemy, bm):
					enemy.add_speed_modifier(-0.20, 0.0)
					enemy.set_meta("lenskaya_slow_turns", 2)
					enemy.set_meta("lenskaya_slow_value", enemy.stats.spd * 0.20)
			else:
				# Если враг уже замедлен — просто обновляем длительность дебаффа до 2 ходов
				enemy.set_meta("lenskaya_slow_turns", 2)
				bm.log_message("Замедление %s уже активно. Длительность замедления обновлена до 2 ходов." % enemy.display_name)
	
	bm.gain_energy_with_err(attacker, 30.0)

# НАВЫК E (Взрыв Манипуляции)
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В LENSKAYA.GD ===
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var manipulation: int = int(attacker.get_meta("lenskaya_manipulation", 0))
	
	# ИСПРАВЛЕНО: Сброс стаков удален отсюда, чтобы калькулятор calc_dmg считал крит. шанс с полной Манипуляцией!
	
	var tag: String = "Skill"
	if attacker.eidolon >= 6:
		tag = "Бонус-атака"
		
	var central_mult: float = float(24 * manipulation) / 100.0
	var adj_mult: float = float(7 * manipulation) / 100.0
	
	bm.log_message("%s поглощает %d зарядов Манипуляции!" % [attacker.display_name, manipulation])
	
	# Кэшируем соседей ДО нанесения урона и смерти центральной цели
	var adjacent: Array[CombatUnit] = bm.get_adjacent_enemies(target)
	
	# Центр (расчет и удар происходят при полных стаках Манипуляции)
	var res_c: Dictionary = bm.calc_dmg(attacker, target, central_mult, 0.0, false, 0.0, 0.0, false, true, tag)
	bm.deal_damage(target, res_c.damage, attacker, attacker.element, res_c.crit, tag)
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
	
	# Соседи
	for adj in adjacent:
		if adj.is_alive():
			var res_a: Dictionary = bm.calc_dmg(attacker, adj, adj_mult, 0.0, false, 0.0, 0.0, false, true, tag)
			bm.deal_damage(adj, res_a.damage, attacker, attacker.element, res_a.crit, tag)
			ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 0.5)
			
	# ИСПРАВЛЕНО: Сбрасываем стаки Манипуляции строго ПОСЛЕ того, как весь урон рассчитан и нанесен!
	attacker.set_meta("lenskaya_manipulation", 0)
	
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)
	
# СВЕРХСПОСОБНОСТЬ
static func execute_ultimate(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var tag: String = "Ultimate"
	if attacker.eidolon >= 6:
		tag = "Бонус-атака"
		
	var living: Array[CombatUnit] = bm.get_living_enemies()
	for enemy in living:
		var res: Dictionary = bm.calc_dmg(attacker, enemy, 0.80, 0.0, false, 0.0, 0.0, true)
		bm.deal_damage(enemy, res.damage, attacker, attacker.element, res.crit, tag)
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.2)
		
	attacker.set_meta("lenskaya_stinger_turns", 3)
	attacker.set_meta("lenskaya_stinger_skip_tick", true)
	bm.log_message("%s переходит в состояние «Жало» на 3 хода!" % attacker.display_name)
	
	# След 1: Сверхспособность даёт Ленской 2 заряда Манипуляции
	add_manipulation_stack(attacker, 2, bm)
	
	# След 2: Моментальная бонус-атака по цели с наибольшим ХП
	var max_hp_enemy: CombatUnit = null
	for enemy in living:
		if enemy.is_alive():
			if max_hp_enemy == null or enemy.stats.max_hp > max_hp_enemy.stats.max_hp:
				max_hp_enemy = enemy
				
	if max_hp_enemy:
		bm.log_message("След 2: моментальная атака состояния «Жало» по %s!" % max_hp_enemy.display_name)
		trigger_bounty_fua(max_hp_enemy, true, bm)
		
	bm.gain_energy_with_err(attacker, 5.0)
	bm.unit_updated.emit(attacker)

# Логика Бонус-атаки "Награда за голову"
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В LENSKAYA.GD ===

# Логика Бонус-атаки "Награда за голову"
static func trigger_bounty_fua(target: CombatUnit, is_fua: bool, bm: BattleManager) -> void:
	var lenskaya: CombatUnit = bm.get_lenskaya_unit()
	if lenskaya == null or not lenskaya.is_alive():
		return
		
	# Сбрасываем блокировку для начала собственной бонус-атаки Ленской!
	if bm.has_meta("lenskaya_fua_attacker_credited"):
		bm.remove_meta("lenskaya_fua_attacker_credited")
		
	bm.advance_fua_sequence()
	bm.log_message("🎯 Триггер Бонус-атаки Ленской по %s." % target.display_name)
	
	if is_fua:
		# Если активировано бонус-атакой союзника: 70% цели, 40% соседям
		if lenskaya.eidolon >= 1:
			# Е1: Наносит урон вообще ВСЕМ целям на поле боя в размере 70% СА
			var living: Array[CombatUnit] = bm.get_living_enemies()
			for enemy in living:
				if enemy.is_alive():
					_apply_fua_damage(lenskaya, enemy, 0.70, bm)
		else:
			# Кэшируем соседей ДО нанесения урона и смерти центральной цели!
			var adjacent: Array[CombatUnit] = bm.get_adjacent_enemies(target)
			
			_apply_fua_damage(lenskaya, target, 0.70, bm)
			
			for adj in adjacent:
				if adj.is_alive():
					_apply_fua_damage(lenskaya, adj, 0.40, bm)
	else:
		# Если активировано обычной атакой/навыком: 50% цели
		_apply_fua_damage(lenskaya, target, 0.50, bm)
		
	# ИСПРАВЛЕНО: Ручной вызов on_ally_fua() удален! Начисление стаков теперь происходит на 100% автоматически в deal_damage()
	
	# Сбрасываем блокировку на выходе из собственной бонус-атаки Ленской!
	if bm.has_meta("lenskaya_fua_attacker_credited"):
		bm.remove_meta("lenskaya_fua_attacker_credited")
			
# Внутренний метод нанесения урона с проверкой на Е6 (Чистый урон)
static func _apply_fua_damage(lenskaya: CombatUnit, target: CombatUnit, mult: float, bm: BattleManager) -> void:
	if lenskaya.eidolon >= 6:
		# Е6: Чистый урон (игнорирует защиты, сопр, понижения урона)
		var true_dmg: float = bm.get_effective_atk_complete(lenskaya) * mult
		bm.deal_damage(target, true_dmg, lenskaya, CombatConstants.Element.ICE, false, "lenskaya_true_fua")
	else:
		var res: Dictionary = bm.calc_dmg(lenskaya, target, mult, 0.0, false, 0.0, 0.0, false, true, "Бонус-атака")
		bm.deal_damage(target, res.damage, lenskaya, CombatConstants.Element.ICE, res.crit, "Бонус-атака")
		ToughnessSystem.apply_weakness_hit(lenskaya, target, bm, 0.5)
		
	if lenskaya.eidolon >= 2:
		# Е2: Откладывает действия пораженных целей на 7%
		target.delay_action(7.0)
		bm.log_message("Эйдолон 2 Ленской: действие %s задержано на 7%%." % target.display_name)
