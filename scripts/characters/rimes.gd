# scripts/characters/rimes.gd
class_name RimesAbilities
extends RefCounted

const ID: String = "rimes"
const MAX_ENERGY: float = 140.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Раймс",
		"element": CombatConstants.Element.QUANTUM, # Квантовый
		"path": CombatConstants.Path.HUNT,           # Охота
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 2300,
			"atk": 2000,
			"def": 550,
			"spd": 110,
			"crit_rate": 0.20,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.10,
			"break_effect": 0.20,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	pass

# Метод Казни (нанесение Чистого урона равного макс. ХП цели)
static func execute_target(target: CombatUnit, attacker: CombatUnit, bm: BattleManager) -> void:
	if not target.is_alive():
		return
		
	bm.log_message("⚔ КАЗНЬ! %s хладнокровно казнит %s чистым уроном!" % [attacker.display_name, target.display_name])
	var max_hp := target.stats.max_hp
	
	# Бело-голубой урон (Color(0.8, 0.95, 1.0)) с тегом Казни
	bm.deal_damage(target, max_hp, attacker, CombatConstants.Element.QUANTUM, false, "rimes_execution")
	
	# Если цель казнена в Изоляции, снимаем её
	if attacker.get_meta("rimes_isolation_target") == target:
		remove_eternal_isolation(attacker, target, bm, true)

# Накопление зарядов Таланта
# === НАЙДИТЕ И ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В RIMES.GD ===
static func increment_talent_stacks(unit: CombatUnit, bm: BattleManager) -> void:
	var max_stacks := 6 if unit.eidolon >= 1 else 4
	var current := int(unit.get_meta("rimes_talent_stacks", 0))
	
	if current >= max_stacks:
		return
		
	var new_stacks := current + 1
	
	# ИСПРАВЛЕНО: Старый триггер прыжка стаков удален! (Логика Е1 перенесена на старт боя)
	
	unit.set_meta("rimes_talent_stacks", new_stacks)
	bm.log_message("🎯 Талант Раймса «Угадай, кто следующий?»: %d/%d стаков." % [new_stacks, max_stacks])
	
	# Рост статов: +10% скорости за стак
	var prev_spd := 0.10 * float(current)
	var new_spd := 0.10 * float(new_stacks)
	unit.remove_speed_modifier(prev_spd, 0.0)
	unit.add_speed_modifier(new_spd, 0.0)
	
	# След 3: Энергия восстанавливается до максимума на макс. стаках
	if new_stacks == max_stacks:
		unit.energy = unit.max_energy
		bm.log_message("⚡ След 3 Раймса: Максимум стаков! Сверхспособность полностью заряжена.")
		
	unit.recalculate_action_value()
	bm.unit_updated.emit(unit)
	bm.action_order_changed.emit()
	
# Вход в Вечную Изоляцию
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	attacker.set_meta("rimes_isolation_target", target)
	target.set_meta("rimes_isolation_source", attacker)
	target.set_meta("rimes_isolation_start_hp", target.stats.hp)
	
	bm.log_message("⛓ ВЕЧНАЯ ИЗОЛЯЦИЯ: %s и %s вошли в Изоляцию!" % [attacker.display_name, target.display_name])
	
	# Если на поле остался всего один живой враг — активируем режим Дуэли
	if bm.is_rimes_duel_active():
		bm.log_message("🌌 КАРМАННОЕ ИЗМЕРЕНИЕ: Активирован режим Дуэли 1 на 1!")
		bm.action_order_changed.emit()
		bm.enemies_reshuffled.emit()
	
	if target.stats.hp / target.stats.max_hp < 0.15:
		execute_target(target, attacker, bm)
		
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)
	bm.unit_updated.emit(target)
	
# Снятие Вечной Изоляции
static func remove_eternal_isolation(attacker: CombatUnit, target: CombatUnit, bm: BattleManager, target_defeated: bool) -> void:
	if attacker.has_meta("rimes_isolation_target"):
		attacker.remove_meta("rimes_isolation_target")
	if target.has_meta("rimes_isolation_source"):
		target.remove_meta("rimes_isolation_source")
	if target.has_meta("rimes_isolation_start_hp"):
		target.remove_meta("rimes_isolation_start_hp")
		
	bm.log_message("⛓ Состояние «Вечной Изоляции» снято.")
	
	if target_defeated:
		bm.gain_skill_point()
		bm.log_message("🛡 Вечная Изоляция: Противник повержен! Восстановлено +1 ОН.")
		
	bm.unit_updated.emit(attacker)
	bm.unit_updated.emit(target)
	
	# Перерисовываем UI
	bm.action_order_changed.emit()
	bm.enemies_reshuffled.emit()
	
# БАЗОВАЯ АТАКА (Обычная / Улучшенная / Е4 навсегда)
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var in_isolation := attacker.has_meta("rimes_isolation_target")
	var is_enhanced := in_isolation or attacker.eidolon >= 4
	
	var mult: float = 2.70 if is_enhanced else 1.60
	var res := bm.calc_dmg(attacker, target, mult, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
	
	# След 1: Продвижение действия на 40% после базового удара
	attacker.advance_action(40.0)
	bm.log_message("След 1 Раймса: Его следующее действие продвинуто на 40%.")
	
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.action_order_changed.emit()

# НАВЫК Q (Обычный с казнью при <20% / Улучшенный с ослаблением СА на 40%)
static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, extra_targets: Array, bm: BattleManager) -> void:
	var in_isolation := attacker.has_meta("rimes_isolation_target")
	
	if in_isolation:
		# Улучшенный Q: 350% СА, снижает СА цели на 40% на 1 ход (Базовый шанс 100%)
		var res := bm.calc_dmg(attacker, target, 3.50, 0.0, false, 0.0, 0.0, false, true, "Skill")
		bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Skill")
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
		
		if NaamaAbilities.roll_debuff(1.00, attacker, target, bm):
			target.statuses.atk_buff_percent -= 0.40
			target.statuses.atk_buff_turns = 1
			target.statuses.atk_buff_source = "Раймс (Улучшенный Q)"
			bm.log_message("Дебафф Раймса: Сила атаки %s снижена на -40%% на 1 ход." % target.display_name)
	else:
		# Обычный Q: 270% СА
		var res := bm.calc_dmg(attacker, target, 2.70, 0.0, false, 0.0, 0.0, false, true, "Skill")
		bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Skill")
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
		
		# Казнь: <20% ХП, не босс и не элита (если только не Е6)
		var is_executable := not target.is_elite and not (target.id == "void_boss")
		if attacker.eidolon >= 6:
			is_executable = true
			
		if is_executable and target.is_alive() and target.stats.hp / target.stats.max_hp < 0.20:
			execute_target(target, attacker, bm)
			
	bm.gain_energy_with_err(attacker, 30.0)

# СВЕРХСПСОБНОСТЬ (480% СА, Казнь при <30% ХП)
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В RIMES.GD ===
static func execute_ultimate(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	# ГЛОБАЛЬНЫЙ ЩИТ: Защита от пустой цели
	if target == null:
		return
		
	var in_isolation := attacker.has_meta("rimes_isolation_target")
	
	# ИСПРАВЛЕНО: Скейл ультимейта повышен с 480% до 500% СА (5.00)
	var res := bm.calc_dmg(attacker, target, 5.00, 0.0, false, 0.0, 0.0, true)
	bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Ultimate")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.5)
	
	if in_isolation:
		bm.gain_skill_point()
		bm.log_message("Сверхспособность: Восстановлено +1 ОН за ульт в Изоляции.")
		
	# ИСПРАВЛЕНО: Сверхспособность лечит Раймсу 30% от его максимального ХП
	var heal_amt: float = attacker.stats.max_hp * 0.30
	bm.heal_unit(attacker, heal_amt)
	bm.log_message("Сверхспособность Раймса: Восстановлено 30%% макс. ХП (+%d)." % int(heal_amt))
	
	# Казнь: <30% ХП
	var is_executable := not target.is_elite and not (target.id == "void_boss")
	if attacker.eidolon >= 6:
		is_executable = true
		
	if is_executable and target.is_alive() and target.stats.hp / target.stats.max_hp < 0.30:
		execute_target(target, attacker, bm)
		
	bm.gain_energy_with_err(attacker, 5.0)
