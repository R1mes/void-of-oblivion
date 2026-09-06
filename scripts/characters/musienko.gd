# scripts/characters/musienko.gd
class_name MusienkoAbilities
extends RefCounted

const ID: String = "musienko"
const MAX_ENERGY: float = 140.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit: CombatUnit = CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Мусиенко",
		"element": CombatConstants.Element.FIRE, # Огонь
		"path": CombatConstants.Path.DESTRUCTION, # Разрушение
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3700,
			"atk": 1100,
			"def": 600,
			"spd": 102,
			"crit_rate": 0.20,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.15,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	pass

# Метод расхода 15% ХП за использование способностей (Талант)
static func consume_talent_hp(unit: CombatUnit, bm: BattleManager) -> void:
	var hp_to_consume: float = unit.stats.max_hp * 0.15
	var final_hp: float = maxf(unit.stats.hp - hp_to_consume, 1.0)
	unit.stats.hp = final_hp
	bm.log_message("🩸 Талант Мусиенко: Потрачено 15%% ХП для активации способности.")
	bm.unit_updated.emit(unit)
	
	# Каждое потребление ХП дает 1 заряд Кровавого возмездия
	increment_retribution_stacks(unit, bm)
	
	bm.trigger_accepted_sin_hp_loss(unit)

# Начисление стаков Кровавого возмездия
static func increment_retribution_stacks(unit: CombatUnit, bm: BattleManager) -> void:
	var current: int = int(unit.get_meta("musienko_retribution_stacks", 0))
	if current >= 6:
		return
		
	var new_stacks: int = current + 1
	unit.set_meta("musienko_retribution_stacks", new_stacks)
	bm.log_message("🩸 Кровавое возмездие: %d/6 зарядов." % new_stacks)
	
	if new_stacks >= 6:
		unit.set_meta("musienko_retribution_stacks", 0) # Сброс стаков
		trigger_talent_fua(unit, bm)

# Срабатывание Бонус-атаки Таланта
static func trigger_talent_fua(unit: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("💥 ТАЛАНТ МУСИЕНКО: Кровавое возмездие накоплено! Бонус-атака по всем врагам!")
	
	# Исцеляет Мусиенко на 30% от его макс. ХП
	var heal_amt: float = unit.stats.max_hp * 0.30
	bm.heal_unit(unit, heal_amt)
	
	# Наносит 160% от макс. ХП всем противникам
	var living: Array[CombatUnit] = bm.get_living_enemies()
	for enemy in living:
		var res: Dictionary = bm.calc_dmg(unit, enemy, 1.60, 0.0, false, 0.0, 0.0, false, true, "Бонус-атака")
		bm.deal_damage(enemy, res.damage, unit, unit.element, res.crit, "Бонус-атака")
		ToughnessSystem.apply_weakness_hit(unit, enemy, bm, 1.0)
		
		# E1: Враги, пораженные бонус-атакой, снижают защиту на 20% на 2 хода
		if unit.eidolon >= 1:
			bm.apply_def_reduction(enemy, "Мусиенко (Е1 Бонус-атака)", 0.20, 2)
			
	# Засчитывается в состоянии Аннигиляции бытия (проверяем преждевременный выход)
	register_annihilation_action(unit, "TalentFUA", bm)

# Регистрация истории ходов для проверки преждевременного выхода из Аннигиляции
static func register_annihilation_action(attacker: CombatUnit, action_id: String, bm: BattleManager) -> void:
	if not attacker.has_meta("musienko_annihilation_active"):
		return
		
	var used_actions: Array = attacker.get_meta("musienko_used_actions", [])
	
	# Е1: Бонус-атака таланта больше не может досрочно завершить состояние Аннигиляции при повторе
	if action_id == "TalentFUA" and attacker.eidolon >= 1:
		return
		
	if action_id in used_actions:
		# Повторное действие -> Досрочный выход!
		bm.log_message("💥 АННИГИЛЯЦИЯ БЫТИЯ: Повторное действие «%s»! Досрочный выход из состояния!" % action_id)
		exit_annihilation(attacker, bm)
	else:
		used_actions.append(action_id)
		attacker.set_meta("musienko_used_actions", used_actions)

# Выход из Аннигиляции (Детонация записанного урона)
static func exit_annihilation(unit: CombatUnit, bm: BattleManager) -> void:
	if not unit.has_meta("musienko_annihilation_active"):
		return
		
	unit.remove_meta("musienko_annihilation_active")
	
	# Снимаем бафф скорости (+80%)
	if unit.has_meta("musienko_annihilation_spd_bonus"):
		var spd_bonus: float = float(unit.get_meta("musienko_annihilation_spd_bonus"))
		unit.remove_speed_modifier(0.0, spd_bonus)
		unit.remove_meta("musienko_annihilation_spd_bonus")
		
	# Снимаем дебаффы улучшенного Q со всех врагов
	var living: Array[CombatUnit] = bm.get_living_enemies()
	for enemy in living:
		if enemy.has_meta("def_reductions"):
			var reductions: Dictionary = enemy.get_meta("def_reductions")
			if reductions.has("Мусиенко (Улучшенный Q)"):
				reductions.erase("Мусиенко (Улучшенный Q)")
				bm.recalculate_target_def(enemy)
				
	# Детонация Чистого урона от записанного значения (30% базово / 60% при Е6)
	var is_e6: bool = unit.eidolon >= 6
	var factor: float = 0.60 if is_e6 else 0.30
	bm.log_message("💥 АННИГИЛЯЦИЯ БЫТИЯ окончена! Детонация %.0f%% накопленного урона!" % (factor * 100.0))
	
	for enemy in living:
		if enemy.has_meta("musienko_recorded_damage"):
			var rec_dmg: float = float(enemy.get_meta("musienko_recorded_damage", 0.0))
			enemy.remove_meta("musienko_recorded_damage")
			
			if rec_dmg > 0.0:
				var true_dmg: float = rec_dmg * factor
				bm.deal_damage(enemy, true_dmg, unit, CombatConstants.Element.FIRE, false, "musienko_true_damage")
				
				# Е6: Если ХП врага стало меньше 15% — он Казнится чистым уроном (обычный или элита)
				if is_e6 and enemy.is_alive() and enemy.stats.hp / enemy.stats.max_hp < 0.15:
					bm.log_message("⚔ Е6 КАЗНЬ Мусиенко по %s!" % enemy.display_name)
					bm.deal_damage(enemy, enemy.stats.max_hp, unit, CombatConstants.Element.FIRE, false, "rimes_execution")
					
	unit.recalculate_action_value()
	bm.unit_updated.emit(unit)
	bm.action_order_changed.emit()

# БАЗОВАЯ АТАКА (Обычная / Улучшенная)
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	consume_talent_hp(attacker, bm)
	
	var in_anni: bool = attacker.has_meta("musienko_annihilation_active")
	var tag: String = "Basic"
	if attacker.eidolon >= 6:
		tag = "Бонус-атака"
		
	if in_anni:
		# Улучшенная базовая: 140% макс. ХП центральной цели, 90% соседям
		var adjacent: Array[CombatUnit] = bm.get_adjacent_enemies(target)
		
		var res_c: Dictionary = bm.calc_dmg(attacker, target, 1.30, 0.0, false, 0.0, 0.0, false, true, tag)
		bm.deal_damage(target, res_c.damage, attacker, attacker.element, res_c.crit, tag)
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
		
		for adj in adjacent:
			if adj.is_alive():
				var res_a: Dictionary = bm.calc_dmg(attacker, adj, 0.70, 0.0, false, 0.0, 0.0, false, true, tag)
				bm.deal_damage(adj, res_a.damage, attacker, attacker.element, res_a.crit, tag)
				ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 0.5)
				
		register_annihilation_action(attacker, "EnhancedBasic", bm)
	else:
		# Обычная: 120% макс. ХП
		var res: Dictionary = bm.calc_dmg(attacker, target, 1.00, 0.0, false, 0.0, 0.0, false, true, tag)
		bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, tag)
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
		
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)

# НАВЫК Q (Обычный 220% СА / Улучшенный 300% СА + срез защиты −25%)
static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, extra_targets: Array, bm: BattleManager) -> void:
	consume_talent_hp(attacker, bm)
	
	var in_anni: bool = attacker.has_meta("musienko_annihilation_active")
	var tag: String = "Skill"
	
	if in_anni:
		# Улучшенный Q (1 ОН): 300% макс. ХП, снижает защиту на 25% до конца Аннигиляции
		var res: Dictionary = bm.calc_dmg(attacker, target, 3.00, 0.0, false, 0.0, 0.0, false, true, tag)
		bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, tag)
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
		
		bm.apply_def_reduction(target, "Мусиенко (Улучшенный Q)", 0.25, 99) # Висит до окончания Аннигиляции (exit_annihilation снимет вручную)
		
		register_annihilation_action(attacker, "EnhancedSkillQ", bm)
	else:
		# Обычный Q: 220% макс. ХП. Если текущее ХП цели < 40% — урон повышен на 30%
		var mult: float = 2.20
		if target.stats.hp / target.stats.max_hp < 0.40:
			mult *= 1.30
			bm.log_message("Навык Q Мусиенко: ХП цели < 40%%! Урон повышен на +30%%.")
			
		var res: Dictionary = bm.calc_dmg(attacker, target, mult, 0.0, false, 0.0, 0.0, false, true, tag)
		bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, tag)
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
		
	bm.gain_energy_with_err(attacker, 30.0)

# НАВЫК E (Вход в Аннигиляцию бытия)
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	consume_talent_hp(attacker, bm)
	
	attacker.set_meta("musienko_annihilation_active", true)
	attacker.set_meta("musienko_used_actions", [])
	
	# Бафф скорости на +80%
	var spd_bonus: float = attacker.stats.spd * 0.80
	attacker.add_speed_modifier(0.0, spd_bonus)
	attacker.set_meta("musienko_annihilation_spd_bonus", spd_bonus)
	
	# E2: ХП не может подняться выше 60% (если выше, принудительно урезается до 60%)
	if attacker.eidolon >= 2:
		if attacker.stats.hp > attacker.stats.max_hp * 0.60:
			attacker.stats.hp = attacker.stats.max_hp * 0.60
			bm.log_message("Эйдолон 2: В Изоляции здоровье Мусиенко ограничено на уровне 60%%.")
			
	bm.log_message("⛓ АННИГИЛЯЦИЯ БЫТИЯ: %s переходит в сокрушительное состояние! Скорость увеличена на +80%%." % attacker.display_name)
	
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)
	bm.action_order_changed.emit()

# СВЕРХСПОСОБНОСТЬ (Лечит на 20% ХП, наносит 350% центру, 180% соседям, Казнь центра при <10% ХП)
static func execute_ultimate(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	consume_talent_hp(attacker, bm)
	
	# Восстанавливает 20% от макс. ХП
	var heal_amt: float = attacker.stats.max_hp * 0.20
	bm.heal_unit(attacker, heal_amt)
	
	var adjacent: Array[CombatUnit] = bm.get_adjacent_enemies(target)
	
	# Центр (350% макс. ХП)
	var res_c: Dictionary = bm.calc_dmg(attacker, target, 3.30, 0.0, false, 0.0, 0.0, true)
	bm.deal_damage(target, res_c.damage, attacker, attacker.element, res_c.crit, "Ultimate")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.5)
	
	# Соседи (180% макс. ХП)
	for adj in adjacent:
		if adj.is_alive():
			var res_a: Dictionary = bm.calc_dmg(attacker, adj, 1.70, 0.0, false, 0.0, 0.0, true)
			bm.deal_damage(adj, res_a.damage, attacker, attacker.element, res_a.crit, "Ultimate")
			ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 1.0)
			
	# Казнь центральной цели при <10% ХП
	if target.is_alive() and target.stats.hp / target.stats.max_hp < 0.10:
		bm.log_message("⚔ КАЗНЬ Мусиенко по %s!" % target.display_name)
		bm.deal_damage(target, target.stats.max_hp, attacker, attacker.element, false, "rimes_execution")
		
	# E4: Сверхспособность повышает КУ на +60% на 3 хода
	if attacker.eidolon >= 4:
		attacker.set_meta("musienko_e4_cd_turns", 3)
		attacker.set_meta("musienko_e4_cd_skip_tick", true)
		bm.log_message("Эйдолон 4: Крит. урон повышен на +60%% на 3 хода!")
		
	bm.gain_energy_with_err(attacker, 5.0)
	bm.unit_updated.emit(attacker)
