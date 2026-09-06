class_name ArseniyAdminAbilities
extends RefCounted

const ID: String = "arseniy_admin"
const MAX_ENERGY: float = 150.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Арсений • Права администратора",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.NIHILITY,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 2900,
			"atk": 1150,
			"def": 920,
			"spd": 105,
			"crit_rate": 0.05,
			"crit_dmg": 0.30,
			"effect_hit_rate": 0.20,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	unit.set_meta("arseniy_admin_e_unlocked", false)
	return unit

static func apply_traces(unit: CombatUnit, bm: BattleManager) -> void:
	unit.set_meta("faction_console_member", true)
	
# Проверка Таланта (Экстренный сброс при >150 Векторах) с защитой от рекурсии через call_deferred
static func check_overload_talent(unit: CombatUnit, bm: BattleManager) -> void:
	if unit == null or not unit.is_alive(): 
		return
	
	if bm.get_console_vectors() > 150:
		bm.log_message("💥 ТАЛАНТ АРСЕНИЯ АДМИНА: Количество Векторов превысило 150! Экстренный квантовый сброс системы!")
		
		# Обнуляем Векторы
		bm.set_console_vectors(0)
		
		# Вызываемся через call_deferred, чтобы разорвать стек синхронных вызовов урона
		bm.call_deferred("_execute_arseniy_overload", unit)

static func execute_overload_damage(unit: CombatUnit, bm: BattleManager) -> void:
	if unit == null or not unit.is_alive(): 
		return
	var living := bm.get_living_enemies()
	unit.set_meta("is_binary_attack", true)
	var mult: float = 3.00 * (1.20 if unit.eidolon >= 5 else 1.0)
	for enemy in living:
		if enemy.is_alive():
			var res := bm.calc_dmg(unit, enemy, mult, 0.0, false, 0.0, 0.0, false, true, "BinaryGroup")
			bm.deal_damage(enemy, res.damage, unit, unit.element, res.crit, "BinaryGroup")
			ToughnessSystem.apply_weakness_hit(unit, enemy, bm, 2.0)
	unit.remove_meta("is_binary_attack")
	
# --- СПОСОБНОСТИ ---

# 1. Базовая атака: 70% СА квантового урона.
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var mult: float = 0.70 * (1.20 if attacker.eidolon >= 3 else 1.0)
	var res := bm.calc_dmg(attacker, target, mult, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, res.damage, attacker, CombatConstants.Element.QUANTUM, res.crit, "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm)
	
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)

# 2. Навык Q: 120% СА цели, срез ЗАЩ 30% на 2 хода (баз. шанс 85%).
static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var mult: float = 1.20 * (1.20 if attacker.eidolon >= 3 else 1.0)
	var res := bm.calc_dmg(attacker, target, mult, 0.0, false, 0.0, 0.0, false, true, "Skill")
	bm.deal_damage(target, res.damage, attacker, CombatConstants.Element.QUANTUM, res.crit, "Skill")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
	
	# Срез защиты 30% на 2 хода (баз. шанс 85%)
	if NaamaAbilities.roll_debuff(0.85, attacker, target, bm):
		bm.apply_def_reduction(target, "Арсений Админ (Навык Q)", 0.30, 2)
		
	# Е2: 100% базовый шанс понизить квантовое сопр. на 12% на 2 хода
	if attacker.eidolon >= 2:
		if NaamaAbilities.roll_debuff(1.00, attacker, target, bm):
			target.set_meta("quantum_res_reduced_turns", 2)
			target.set_meta("quantum_res_reduced_skip_tick", true)
			bm.log_message("🔮 Е2 Арсения: Наложено снижение Квантового сопротивления -12%% на 2 хода.")
			
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(target)

# 3. Навык E: 130% СА Бинарным уроном ВСЕМ врагам, уязвимость к Бинарному урону 30% на 3 хода (85%).
static func execute_skill_e(attacker: CombatUnit, bm: BattleManager, is_out_of_turn: bool = false) -> void:
	# След 1: Если активируется вне своего хода (например, ультой Сары) -> +1 ОН
	if is_out_of_turn:
		bm.gain_skill_point()
		bm.log_message("⚡ След 1 Арсения Админа: Навык Е активирован вне очереди, восстановлено 1 ОН!")
		
	var living := bm.get_living_enemies()
	attacker.set_meta("is_binary_attack", true)
	var mult: float = 1.10 * (1.20 if attacker.eidolon >= 3 else 1.0)
	
	for enemy in living:
		var res := bm.calc_dmg(attacker, enemy, mult, 0.0, false, 0.0, 0.0, false, true, "Binary")
		bm.deal_damage(enemy, res.damage, attacker, CombatConstants.Element.QUANTUM, res.crit, "Binary")
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
		
		# Уязвимость к Бинарному урону 30% на 3 хода (баз. шанс 85%)
		if NaamaAbilities.roll_debuff(0.85, attacker, enemy, bm):
			enemy.set_meta("arseniy_binary_vuln_turns", 3)
			enemy.set_meta("arseniy_binary_vuln_skip_tick", true)
			bm.log_message("🌐 Навык E Арсения: На %s наложена уязвимость +30%% к Бинарному урону на 3 хода." % enemy.display_name)
			
	attacker.remove_meta("is_binary_attack")
	
	if not is_out_of_turn:
		bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)

# 4. Сверхспособность (150 ЭН): 180% центру, 90% соседям (срез наносимого урона врагов).
# Если есть другие бойцы Консоли -> Урон Бинарный + срез защиты -20%.
static func execute_ultimate(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var console_allies := 0
	for ally in bm.allies:
		if ally.is_alive() and ally != attacker and ally.has_meta("faction_console_member"):
			console_allies += 1
			
	var is_binary_ult := console_allies > 0
	var tag := "Binary" if is_binary_ult else "Ultimate"
	if is_binary_ult:
		attacker.set_meta("is_binary_attack", true)
		bm.log_message("🌐 СВЕРХСПОСОБНОСТЬ: В отряде есть Консоль! Урон становится Бинарным, врагам срежет защиту!")
		
	var adjacent := bm.get_adjacent_enemies(target)
	var mult_c: float = 1.80 * (1.20 if attacker.eidolon >= 5 else 1.0)
	var mult_a: float = 0.90 * (1.20 if attacker.eidolon >= 5 else 1.0)
	
	# Центральная цель (180% СА)
	var res_c := bm.calc_dmg(attacker, target, mult_c, 0.0, false, 0.0, 0.0, true, true, tag)
	bm.deal_damage(target, res_c.damage, attacker, CombatConstants.Element.QUANTUM, res_c.crit, tag)
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 2.0)
	_apply_ult_debuffs(attacker, target, bm, is_binary_ult)
	
	# Соседи (90% СА)
	for adj in adjacent:
		if adj.is_alive():
			var res_a := bm.calc_dmg(attacker, adj, mult_a, 0.0, false, 0.0, 0.0, true, true, tag)
			bm.deal_damage(adj, res_a.damage, attacker, CombatConstants.Element.QUANTUM, res_a.crit, tag)
			ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 1.0)
			_apply_ult_debuffs(attacker, adj, bm, is_binary_ult)
			
	if is_binary_ult:
		attacker.remove_meta("is_binary_attack")
		
	bm.gain_energy_with_err(attacker, 5.0)

static func _apply_ult_debuffs(attacker: CombatUnit, target: CombatUnit, bm: BattleManager, is_binary_ult: bool) -> void:
	# ИСПРАВЛЕНО: Железобетонная страховка от передачи нулевой или погибшей цели
	if target == null or not target.is_alive(): 
		return
	
	# Базовый дебафф: Снижение наносимого врагом урона на 30% на 2 хода (с защитой от сопротивления)
	if NaamaAbilities.roll_debuff(0.85, attacker, target, bm):
		target.set_meta("arseniy_atk_weaken_turns", 2)
		target.set_meta("arseniy_atk_weaken_skip_tick", true)
		
	# Дебафф при Консоли: Срез защиты -20% на 2 хода
	if is_binary_ult:
		if NaamaAbilities.roll_debuff(0.85, attacker, target, bm):
			bm.apply_def_reduction(target, "Арсений Админ (Ульта)", 0.20, 2)
			
