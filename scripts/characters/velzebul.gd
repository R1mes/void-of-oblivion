class_name VelzebulAbilities
extends RefCounted

const ID: String = "velzebul"
const MAX_ENERGY: float = 140.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Вельзевул",
		"element": CombatConstants.Element.ICE,
		"path": CombatConstants.Path.HARMONY,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3400,
			"atk": 1150,
			"def": 850,
			"spd": 113,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	unit.set_meta("velzebul_sinful_hearts", 0)
	unit.set_meta("velzebul_in_offering", eidolon >= 1)
	unit.set_meta("velzebul_e_enhanced", false)
	return unit

static func apply_traces(unit: CombatUnit, bm: BattleManager) -> void:
	pass

# --- ТЕХНИКА: ПОДДЕРЖКА ---
# Продвигает действие первого персонажа в отряде на 100% (или второго, если Вельзевул первый) и восстанавливает ему 30% энергии
static func execute_technique(allies: Array, velzebul_unit: CombatUnit, bm: BattleManager) -> void:
	var target_ally: CombatUnit = null
	if not allies.is_empty():
		var first: CombatUnit = allies[0]
		if first == velzebul_unit or (first != null and first.id == ID):
			if allies.size() > 1 and allies[1] is CombatUnit and allies[1].is_alive():
				target_ally = allies[1]
		elif first != null and first.is_alive():
			target_ally = first
			
	if target_ally == null:
		for ally in allies:
			if ally is CombatUnit and ally.is_alive() and ally != velzebul_unit and ally.id != ID:
				target_ally = ally
				break
		if target_ally == null and velzebul_unit != null and velzebul_unit.is_alive():
			target_ally = velzebul_unit

	if target_ally != null:
		target_ally.advance_action(100.0)
		var energy_gain: float = target_ally.max_energy * 0.30
		bm.gain_energy_with_err(target_ally, energy_gain)
		bm.log_message("🩸 Техника Вельзевул: Действие %s продвинуто на 100%%, восстановлено 30%% энергии (%d ед.)!" % [target_ally.display_name, int(energy_gain)])
		bm.action_order_changed.emit()
		bm.unit_updated.emit(target_ally)

# --- БАЗОВАЯ АТАКА ---
# Одиночная атака: 100% СА ледяного урона (+1 ОН, +20 ЭН)
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 1.00, 0.0, false, 0.0, 0.0, false, true, "Basic")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, CombatConstants.Element.ICE, bool(res.get("crit", false)), "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
	
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	
	_check_trace1_sp_refund(attacker, target, bm)
	bm.log_message("🩸 %s — Базовая атака по %s: %d ледяного урона (+1 ОН, +20 ЭН)." % [attacker.display_name, target.display_name, int(dmg)])
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# --- УСИЛЕННАЯ БАЗОВАЯ АТАКА ---
# Одиночная атака: 190% СА ледяного урона (0 ОН, +20 ЭН), +1 Грешное сердце (макс 4)
static func execute_enhanced_basic(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 1.90, 0.0, false, 0.0, 0.0, false, true, "Basic")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, CombatConstants.Element.ICE, bool(res.get("crit", false)), "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.5)
	
	# Усиленные базовые атаки Вельзевул не генерируют очки навыков и не тратят (0 ОН), восстанавливают 5 Зеро
	bm.gain_energy_with_err(attacker, 20.0)
	bm.add_xaeroh(5)
	_check_trace1_sp_refund(attacker, target, bm)
	
	var hearts: int = int(attacker.get_meta("velzebul_sinful_hearts", 0)) + 1
	hearts = mini(hearts, 4)
	attacker.set_meta("velzebul_sinful_hearts", hearts)
	# След 3: +10% скорости Вельзевул за каждое Грешное сердце
	attacker.add_speed_modifier(0.10, 0.0)
	
	if attacker.eidolon >= 1:
		bm.gain_energy_with_err(attacker, 5.0)
		bm.add_xaeroh(5)
		bm.log_message("🩸 Эйдолон 1 Вельзевул: +5 Энергии и +5 Зеро от получения Грешного сердца!")
		
	bm.log_message("🩸 %s — Усиленная базовая атака по %s: %d ледяного урона (+5 Зеро). Получено Грешное сердце (%d/4)!" % [
		attacker.display_name, target.display_name, int(dmg), hearts
	])
	
	if hearts >= 4:
		attacker.set_meta("velzebul_in_offering", false)
		attacker.set_meta("velzebul_e_enhanced", true)
		if not bool(attacker.get_meta("velzebul_t3_max_hp_applied", false)):
			attacker.set_meta("velzebul_t3_max_hp_applied", true)
			var hp_gain: float = attacker.stats.max_hp * 0.40
			attacker.stats.max_hp += hp_gain
			attacker.stats.hp += hp_gain
			bm.log_message("🩸 След 3 Вельзевул: Собраны все 4 сердца — макс. ХП увеличено на 40%% (+%d ХП, текущее: %d/%d)!" % [
				int(hp_gain), int(attacker.stats.hp), int(attacker.stats.max_hp)
			])
		bm.log_message("🩸 Вельзевул собрала максимум Грешных сердец (4/4)! Стойка «Подношение» завершена, Навык E становится Усиленным до конца боя, а Сверхспособность разблокирована!")
		
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# --- НАВЫК Q ---
# 1 ОН [Групповая атака]: 110% СА ледяного урона всем врагам, генерирует 15 Зеро (+30 ЭН)
static func execute_skill_q(attacker: CombatUnit, bm: BattleManager) -> void:
	var living := bm.get_living_enemies()
	var hit_enemy_with_seal := false
	for enemy in living:
		if enemy.is_alive():
			var res := bm.calc_dmg(attacker, enemy, 1.10, 0.0, false, 0.0, 0.0, false, true, "Skill")
			bm.deal_damage(enemy, float(res.get("damage", 0.0)), attacker, CombatConstants.Element.ICE, bool(res.get("crit", false)), "Skill")
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
			if int(enemy.get_meta("velzebul_seal_turns", 0)) > 0:
				hit_enemy_with_seal = true
				
	bm.add_xaeroh(15)
	bm.gain_energy_with_err(attacker, 30.0)
	
	if hit_enemy_with_seal:
		bm.gain_skill_point()
		bm.log_message("🩸 След 1 Вельзевул: Атака поразила врага с Печатью -> восстановлено +1 ОН!")
		
	if attacker.eidolon >= 4:
		attacker.set_meta("velzebul_e4_spd_turns", 2)
		attacker.add_speed_modifier(0.30, 0.0)
		bm.log_message("🩸 Эйдолон 4: Скорость Вельзевул увеличена на 30%% на 2 хода!")
		
	bm.log_message("🩸 %s — Навык Q: на всех противников натравлен мушиный рой (110%% СА ледяного урона), получено +15 Зеро!" % attacker.display_name)
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# --- НАВЫК E ---
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var is_enhanced: bool = bool(attacker.get_meta("velzebul_e_enhanced", false))
	if is_enhanced:
		_execute_enhanced_skill_e(attacker, target, bm)
	else:
		_execute_offering_skill_e(attacker, bm)

# Навык E (Подношение Вельзевул, 2 ОН)
static func _execute_offering_skill_e(attacker: CombatUnit, bm: BattleManager) -> void:
	attacker.set_meta("velzebul_in_offering", true)
	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("🩸 Вельзевул переходит в состояние «Подношение Вельзевул»! Базовая атака усилена, начинается сбор Грешных сердец.")
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# Усиленный Навык E (1 ОН, Blast)
# 110% СА цели, 30% СА соседям, накладывает Печать Вельзевула на 3 хода
static func _execute_enhanced_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	if target == null or not target.is_alive():
		var living := bm.get_living_enemies()
		if not living.is_empty():
			target = living[0]
		else:
			return
			
	var adj := bm.get_adjacent_enemies(target)
	var res_c := bm.calc_dmg(attacker, target, 1.10, 0.0, false, 0.0, 0.0, false, true, "Skill")
	var dmg_c: float = float(res_c.get("damage", 0.0))
	bm.deal_damage(target, dmg_c, attacker, CombatConstants.Element.ICE, bool(res_c.get("crit", false)), "Skill")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.5)
	target.set_meta("velzebul_seal_turns", 3)
	
	for e in adj:
		if e.is_alive():
			var res_a := bm.calc_dmg(attacker, e, 0.30, 0.0, false, 0.0, 0.0, false, true, "Skill")
			bm.deal_damage(e, float(res_a.get("damage", 0.0)), attacker, CombatConstants.Element.ICE, bool(res_a.get("crit", false)), "Skill")
			ToughnessSystem.apply_weakness_hit(attacker, e, bm, 0.5)
			e.set_meta("velzebul_seal_turns", 3)
			
	bm.gain_energy_with_err(attacker, 30.0)
	_check_trace1_sp_refund(attacker, target, bm)
	
	bm.log_message("🩸 %s — Усиленный Навык E: %d ледяного урона по %s и урон соседям. Наложен статус «Печать Вельзевула» на 3 хода!" % [
		attacker.display_name, int(dmg_c), target.display_name
	])
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# --- СВЕРХСПОСОБНОСТЬ (140 ЭН) ---
# Доступна только при сборе 4 Грешных сердец.
# 150% СА всем врагам. Союзники Антиматерии получают +40% урона на 2 хода.
# Враги получают -20% ледяного и квантового сопротивления на 2 хода.
static func execute_ultimate(attacker: CombatUnit, bm: BattleManager) -> void:
	var hearts: int = int(attacker.get_meta("velzebul_sinful_hearts", 0))
	if hearts < 4:
		bm.log_message("Сверхспособность Вельзевул заблокирована: требуется собрать 4 Грешных сердца (сейчас: %d/4)!" % hearts)
		return
		
	var living := bm.get_living_enemies()
	for enemy in living:
		if enemy.is_alive():
			var res := bm.calc_dmg(attacker, enemy, 1.50, 0.0, false, 0.0, 0.0, false, true, "Ultimate")
			bm.deal_damage(enemy, float(res.get("damage", 0.0)), attacker, CombatConstants.Element.ICE, bool(res.get("crit", false)), "Ultimate")
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 2.0)
			enemy.set_meta("velzebul_ice_quantum_res_turns", 2)
			
	for ally in bm.allies:
		if ally is CombatUnit and ally.is_alive() and bm.is_antimatter_member(ally):
			ally.set_meta("velzebul_ult_antimatter_dmg_turns", 2)
			
	if attacker.eidolon >= 2:
		for ally in bm.allies:
			if ally is CombatUnit and ally.is_alive():
				if bm.is_antimatter_member(ally):
					ally.advance_action(100.0)
				else:
					ally.advance_action(40.0)
		bm.log_message("🩸 Эйдолон 2 Вельзевул: Действия союзников Антиматерии продвинуты на 100%%, остальных на 40%%!")
		
	bm.log_message("🩸 СВЕРХСПОСОБНОСТЬ: Вельзевул восседает на трон из плоти и обрушивает волну крови! Урон всем врагам, союзники Антиматерии получают +40%% урона, а сопротивление врагов кванту и льду снижено на 20%% на 2 хода!")
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# --- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ И ПРОВЕРКИ ---

static func _check_trace1_sp_refund(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	if target != null and int(target.get_meta("velzebul_seal_turns", 0)) > 0:
		bm.gain_skill_point()
		bm.log_message("🩸 След 1 Вельзевул: Атака по цели со статусом «Печать Вельзевула» восстановила +1 ОН!")
