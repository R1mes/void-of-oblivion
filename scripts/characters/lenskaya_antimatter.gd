class_name LenskayaAntimatterAbilities
extends RefCounted

const ID: String = "lenskaya_antimatter"
const MAX_ENERGY: float = 250.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Ленская • Явление антиматерии",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3600,
			"atk": 1450,
			"def": 900,
			"spd": 102,
			"crit_rate": 0.25,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	unit.set_meta("lenskaya_am_stance", "none") # "none", "keeper", "warrior"
	unit.set_meta("lenskaya_am_in_inverted", false)
	unit.set_meta("lenskaya_am_atk_buff_turns", 0)
	unit.set_meta("faction_antimatter_member", true)
	return unit

static func apply_traces(unit: CombatUnit, bm: BattleManager) -> void:
	unit.set_meta("faction_antimatter_member", true)
	
	# Талант: если в отряде 2+ союзника Консоли, приобретает особенность «Консоль»
	var console_count := 0
	for ally in bm.allies:
		if ally != unit and FactionSystem.FACTIONS.has("console") and ally.id in FactionSystem.FACTIONS["console"].members:
			console_count += 1
	if console_count >= 2:
		unit.set_meta("faction_console_member", true)
		unit.set_meta("has_console_trait", true)
		bm.log_message("🌌 Талант Ленской: в отряде 2+ союзника Консоли — получена особенность «Консоль»!")

# --- БАЗОВАЯ АТАКА И УСИЛЕННАЯ БАЗОВАЯ АТАКА ---

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	if bool(attacker.get_meta("lenskaya_am_in_inverted", false)):
		attacker.set_meta("lenskaya_am_in_inverted", false)
		attacker.remove_meta("untargetable")
		bm.lenskaya_am_inverted_exit_requested.emit(attacker)
		
	var stance: String = String(attacker.get_meta("lenskaya_am_stance", "none"))
	if stance in ["keeper", "warrior"]:
		execute_enhanced_basic(attacker, target, bm)
		return

	var elem: int = CombatConstants.Element.QUANTUM if (attacker.eidolon >= 6) else CombatConstants.Element.PHYSICAL
	attacker.set_meta("current_attack_element", elem)
	var is_binary := attacker.eidolon >= 6
	if is_binary:
		attacker.set_meta("is_binary_attack", true)
		
	var res := bm.calc_dmg(attacker, target, 1.00, 0.0, false, 0.0, 0.0, false, true, "Basic")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, elem, bool(res.get("crit", false)), "Binary" if is_binary else "Basic")
	if is_binary:
		attacker.remove_meta("is_binary_attack")
		
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
	attacker.remove_meta("current_attack_element")
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.log_message("🌌 %s — Базовая атака по %s: %d урона." % [attacker.display_name, target.display_name, int(dmg)])
	_apply_e2_decomposition(attacker, [target], bm)
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

static func execute_enhanced_basic(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	if bool(attacker.get_meta("lenskaya_am_in_inverted", false)):
		attacker.set_meta("lenskaya_am_in_inverted", false)
		attacker.remove_meta("untargetable")
		bm.lenskaya_am_inverted_exit_requested.emit(attacker)
		
	var stance: String = String(attacker.get_meta("lenskaya_am_stance", "none"))
	var in_stance: bool = stance in ["keeper", "warrior"]
	
	if in_stance:
		# Enhanced Basic Attack [Одиночная атака]
		# Наносит выбранному противнику квантовый урон, равный 120% СА.
		attacker.set_meta("current_attack_element", CombatConstants.Element.QUANTUM)
		var res := bm.calc_dmg(attacker, target, 1.20, 0.0, false, 0.0, 0.0, false, true, "Basic")
		var dmg: float = float(res.get("damage", 0.0))
		var is_binary := attacker.eidolon >= 6
		var tag := "Binary" if is_binary else "Basic"
		if is_binary:
			attacker.set_meta("is_binary_attack", true)
		bm.deal_damage(target, dmg, attacker, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)), tag)
		if is_binary:
			attacker.remove_meta("is_binary_attack")
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
		attacker.remove_meta("current_attack_element")
		bm.gain_skill_point()
		bm.gain_energy_with_err(attacker, 20.0)
		bm.log_message("🌌 %s — Усиленная базовая атака по %s: %d квантового урона (120%% СА)." % [attacker.display_name, target.display_name, int(dmg)])
		_apply_e2_decomposition(attacker, [target], bm)
		bm.action_order_changed.emit()
		bm.unit_updated.emit(attacker)
		return

	attacker.set_meta("is_binary_attack", true)
	var adj := bm.get_adjacent_enemies(target)
	var elem: int = CombatConstants.Element.QUANTUM if (attacker.eidolon >= 6) else CombatConstants.Element.PHYSICAL
	attacker.set_meta("current_attack_element", elem)
	
	var res_c := bm.calc_dmg(attacker, target, 1.80, 0.0, false, 0.0, 0.0, false, true, "Binary")
	var dmg_c: float = float(res_c.get("damage", 0.0))
	bm.deal_damage(target, dmg_c, attacker, elem, bool(res_c.get("crit", false)), "Binary")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.5)
	
	for e in adj:
		if e.is_alive():
			var res_a := bm.calc_dmg(attacker, e, 1.20, 0.0, false, 0.0, 0.0, false, true, "Binary")
			var dmg_a: float = float(res_a.get("damage", 0.0))
			bm.deal_damage(e, dmg_a, attacker, elem, bool(res_a.get("crit", false)), "Binary")
			ToughnessSystem.apply_weakness_hit(attacker, e, bm, 1.0)
			
	attacker.remove_meta("is_binary_attack")
	attacker.remove_meta("current_attack_element")
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.log_message("🌌 %s — Усиленная базовая атака по %s: %d урона (и соседям по 120%% СА)." % [attacker.display_name, target.display_name, int(dmg_c)])
	_apply_e2_decomposition(attacker, [target] + adj, bm)
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# --- НАВЫК Q ---

static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var stance: String = String(attacker.get_meta("lenskaya_am_stance", "none"))
	match stance:
		"none":
			_execute_skill_q_formless(attacker, target, bm)
		"keeper":
			_execute_skill_q_keeper(attacker, target, bm)
		"warrior":
			_execute_skill_q_warrior(attacker, target, bm)

static func _execute_skill_q_formless(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var adj := bm.get_adjacent_enemies(target)
	var elem: int = CombatConstants.Element.QUANTUM if (attacker.eidolon >= 6) else CombatConstants.Element.PHYSICAL
	attacker.set_meta("current_attack_element", elem)
	var res_c := bm.calc_dmg(attacker, target, 1.10, 0.0, false, 0.0, 0.0, false, true, "Skill")
	var dmg_c: float = float(res_c.get("damage", 0.0))
	bm.deal_damage(target, dmg_c, attacker, elem, bool(res_c.get("crit", false)), "Skill")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.5)
	
	for e in adj:
		if e.is_alive():
			var res_a := bm.calc_dmg(attacker, e, 0.50, 0.0, false, 0.0, 0.0, false, true, "Skill")
			bm.deal_damage(e, float(res_a.get("damage", 0.0)), attacker, elem, bool(res_a.get("crit", false)), "Skill")
			ToughnessSystem.apply_weakness_hit(attacker, e, bm, 0.5)
			
	attacker.remove_meta("current_attack_element")
	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("🌌 %s — Навык Q «Без формы» по %s: %d урона." % [attacker.display_name, target.display_name, int(dmg_c)])
	_apply_e2_decomposition(attacker, [target] + adj, bm)
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

static func _execute_skill_q_keeper(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	if not bm.spend_xaeroh(30, attacker):
		bm.log_message("Недостаточно Xaeroh (нужно 30)!")
		return
		
	# След 1: атака расходующая Xaeroh восстанавливает 5 энергии
	bm.gain_energy_with_err(attacker, 5.0)
	
	# За каждую ед. скорости свыше 100: +1% урона (макс +175%)
	var spd_over: float = maxf(attacker.stats.get_effective_spd() - 100.0, 0.0)
	var spd_boost: float = minf(spd_over * 0.01, 1.75)
	attacker.set_meta("temp_spd_dmg_boost", spd_boost)
	attacker.set_meta("current_attack_element", CombatConstants.Element.QUANTUM)
	
	var res_c := bm.calc_dmg(attacker, target, 0.50, 0.0, false, 0.0, 0.0, false, true, "Skill")
	var dmg_c: float = float(res_c.get("damage", 0.0))
	bm.deal_damage(target, dmg_c, attacker, CombatConstants.Element.QUANTUM, bool(res_c.get("crit", false)), "Skill")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 0.5)
	
	var hit_targets: Array[CombatUnit] = [target]
	# 6 отскоков по случайным врагам
	for i in range(6):
		var living := bm.get_living_enemies()
		if living.is_empty():
			break
		var bounce_target: CombatUnit = living.pick_random()
		var res_b := bm.calc_dmg(attacker, bounce_target, 0.50, 0.0, false, 0.0, 0.0, false, true, "Skill")
		var dmg_b: float = float(res_b.get("damage", 0.0))
		bm.deal_damage(bounce_target, dmg_b, attacker, CombatConstants.Element.QUANTUM, bool(res_b.get("crit", false)), "Skill")
		ToughnessSystem.apply_weakness_hit(attacker, bounce_target, bm, 0.5)
		if not bounce_target in hit_targets:
			hit_targets.append(bounce_target)
			
	attacker.remove_meta("temp_spd_dmg_boost")
	attacker.remove_meta("current_attack_element")
	_apply_trace3_console_binary_dmg(attacker, hit_targets, bm)
	_apply_e2_decomposition(attacker, hit_targets, bm)
	
	bm.lenskaya_am_keeper_q_vfx_requested.emit(attacker, hit_targets)
	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("🌌 %s — Навык Q «Хранитель Ничто» (7 ударов, +%d%% от скорости): %d суммарного удара." % [attacker.display_name, int(spd_boost * 100), int(dmg_c)])
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

static func _execute_skill_q_warrior(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	if not bm.spend_xaeroh(30, attacker):
		bm.log_message("Недостаточно Xaeroh (нужно 30)!")
		return
		
	# След 1: +5 энергии при расходе Xaeroh
	bm.gain_energy_with_err(attacker, 5.0)
	
	var in_inv := bool(attacker.get_meta("lenskaya_am_in_inverted", false))
	var hit_targets: Array[CombatUnit] = []
	attacker.set_meta("current_attack_element", CombatConstants.Element.QUANTUM)
	
	if in_inv:
		# Выход из состояния «В изнанке»
		attacker.set_meta("lenskaya_am_in_inverted", false)
		attacker.remove_meta("untargetable")
		attacker.set_meta("lenskaya_am_atk_buff_turns", 3)
		bm.log_message("🌌 Ленская выходит из «В изнанке» -> СА +40%% на 3 хода!")
		bm.lenskaya_am_inverted_exit_requested.emit(attacker)
		bm.lenskaya_am_warrior_q_vfx_requested.emit(attacker, target, true)
		
		attacker.set_meta("lenskaya_am_ignore_20_def", true)
		
		# 400% СА центру и 120% СА всем остальным
		var res_c := bm.calc_dmg(attacker, target, 4.00, 0.0, false, 0.0, 0.0, false, true, "Skill")
		var dmg_c: float = float(res_c.get("damage", 0.0))
		bm.deal_damage(target, dmg_c, attacker, CombatConstants.Element.QUANTUM, bool(res_c.get("crit", false)), "Skill")
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 2.0)
		target.delay_action(20.0)
		hit_targets.append(target)
		
		# Казнь центральной цели, если ХП < 10% (не босса)
		var is_boss_c: bool = target.id in ["void_boss", "masked_silhouette"] or (target.stats.max_hp >= 50000 and not target.is_elite)
		if not is_boss_c and target.is_alive() and target.stats.hp / target.stats.max_hp < 0.10:
			bm.log_message("⚔ КАЗНЬ ИЗ ИЗНАНКИ! %s казнит центральную цель %s!" % [attacker.display_name, target.display_name])
			bm.deal_damage(target, target.stats.max_hp, attacker, CombatConstants.Element.QUANTUM, false, "lenskaya_am_execution")
			
		for enemy in bm.get_living_enemies():
			if enemy != target and enemy.is_alive():
				var res_all := bm.calc_dmg(attacker, enemy, 1.20, 0.0, false, 0.0, 0.0, false, true, "Skill")
				var dmg_all: float = float(res_all.get("damage", 0.0))
				bm.deal_damage(enemy, dmg_all, attacker, CombatConstants.Element.QUANTUM, bool(res_all.get("crit", false)), "Skill")
				ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
				enemy.delay_action(20.0)
				hit_targets.append(enemy)
				
				# Казнь неосновных целей (только элитные и обычные мобы)
				var is_boss: bool = enemy.id in ["void_boss", "masked_silhouette"] or (enemy.stats.max_hp >= 50000 and not enemy.is_elite)
				if not is_boss and enemy.is_alive() and enemy.stats.hp / enemy.stats.max_hp < 0.10:
					bm.log_message("⚔ КАЗНЬ! %s уничтожает %s чистым уроном!" % [attacker.display_name, enemy.display_name])
					bm.deal_damage(enemy, enemy.stats.max_hp, attacker, CombatConstants.Element.QUANTUM, false, "lenskaya_am_execution")
					
		attacker.remove_meta("lenskaya_am_ignore_20_def")
		bm.log_message("🌌 %s — Сокрушительный Навык Q из «В изнанке» по всем целям (задержка действий врагов 20%%, игнор 20%% защиты)." % attacker.display_name)
	else:
		# Обычный Воин небытия: 180% центру, 70% соседям
		bm.lenskaya_am_warrior_q_vfx_requested.emit(attacker, target, false)
		var adj := bm.get_adjacent_enemies(target)
		var res_c := bm.calc_dmg(attacker, target, 1.80, 0.0, false, 0.0, 0.0, false, true, "Skill")
		var dmg_c: float = float(res_c.get("damage", 0.0))
		bm.deal_damage(target, dmg_c, attacker, CombatConstants.Element.QUANTUM, bool(res_c.get("crit", false)), "Skill")
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.5)
		hit_targets.append(target)
		
		for e in adj:
			if e.is_alive():
				var res_a := bm.calc_dmg(attacker, e, 0.70, 0.0, false, 0.0, 0.0, false, true, "Skill")
				bm.deal_damage(e, float(res_a.get("damage", 0.0)), attacker, CombatConstants.Element.QUANTUM, bool(res_a.get("crit", false)), "Skill")
				ToughnessSystem.apply_weakness_hit(attacker, e, bm, 0.5)
				hit_targets.append(e)
		bm.log_message("🌌 %s — Навык Q «Воин небытия» по %s: %d урона." % [attacker.display_name, target.display_name, int(dmg_c)])

	attacker.remove_meta("current_attack_element")
	_apply_trace3_console_binary_dmg(attacker, hit_targets, bm)
	_apply_e2_decomposition(attacker, hit_targets, bm)
	
	bm.gain_energy_with_err(attacker, 30.0)
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# --- НАВЫК E ---

static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var stance: String = String(attacker.get_meta("lenskaya_am_stance", "none"))
	match stance:
		"none":
			_execute_skill_e_formless(attacker, target, bm)
		"keeper":
			_execute_skill_e_keeper(attacker, bm)
		"warrior":
			_execute_skill_e_warrior(attacker, bm)

static func _execute_skill_e_formless(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var elem: int = CombatConstants.Element.QUANTUM if (attacker.eidolon >= 6) else CombatConstants.Element.PHYSICAL
	attacker.set_meta("current_attack_element", elem)
	var is_binary := attacker.eidolon >= 6
	if is_binary:
		attacker.set_meta("is_binary_attack", true)
		
	var res := bm.calc_dmg(attacker, target, 3.00, 0.0, false, 0.0, 0.0, false, true, "Binary" if is_binary else "Skill")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, elem, bool(res.get("crit", false)), "Binary" if is_binary else "Skill")
	if is_binary:
		attacker.remove_meta("is_binary_attack")
	attacker.remove_meta("current_attack_element")
		
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 2.0)
	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("🌌 %s — Навык E «Без формы» по %s: %d урона." % [attacker.display_name, target.display_name, int(dmg)])
	_apply_e2_decomposition(attacker, [target], bm)
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

static func _execute_skill_e_keeper(attacker: CombatUnit, bm: BattleManager) -> void:
	if not bm.spend_xaeroh(60, attacker):
		bm.log_message("Недостаточно Xaeroh (нужно 60)!")
		return
		
	# След 1: расход Xaeroh -> +5 энергии
	bm.gain_energy_with_err(attacker, 5.0)
	
	# Повышает свою скорость на 30% от скорости всех союзников (кроме себя) на 2 хода
	var sum_spd: float = 0.0
	for ally in bm.allies:
		if ally.is_alive() and ally != attacker:
			sum_spd += ally.stats.get_effective_spd()
	var spd_gain: float = sum_spd * 0.30
	if attacker.has_meta("lenskaya_am_spd_gain"):
		var old_gain: float = float(attacker.get_meta("lenskaya_am_spd_gain", 0.0))
		attacker.remove_speed_modifier(0.0, old_gain)
	attacker.add_speed_modifier(0.0, spd_gain)
	attacker.set_meta("lenskaya_am_spd_gain", spd_gain)
	attacker.set_meta("lenskaya_am_spd_buff_turns", 2)
	attacker.set_meta("lenskaya_am_spd_buff_skip_tick", true)
	
	# Повышает СА всех союзников на 30% от СА Ленской на 3 хода
	var atk_boost: float = bm.get_effective_atk_complete(attacker) * 0.30
	for ally in bm.allies:
		if ally.is_alive():
			ally.set_meta("lenskaya_am_team_atk_boost", atk_boost)
			ally.set_meta("lenskaya_am_team_atk_turns", 3)
			if ally == attacker:
				ally.set_meta("lenskaya_am_team_atk_skip_tick", true)
			
	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("🌌 %s — Навык E «Хранитель Ничто»: +%d Скорости себе на 2 хода, +%d СА команде на 3 хода!" % [attacker.display_name, int(spd_gain), int(atk_boost)])
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

static func _execute_skill_e_warrior(attacker: CombatUnit, bm: BattleManager) -> void:
	if not bm.spend_xaeroh(60, attacker):
		bm.log_message("Недостаточно Xaeroh (нужно 60)!")
		return
		
	# След 1: расход Xaeroh -> +5 энергии
	bm.gain_energy_with_err(attacker, 5.0)
	
	# Переходит в состояние «В изнанке» (недосягаемость)
	attacker.set_meta("lenskaya_am_in_inverted", true)
	attacker.set_meta("untargetable", true)
	bm.lenskaya_am_warrior_e_slash_requested.emit(attacker)
	
	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("🌌 %s — Навык E «Воин небытия»: переход в состояние «В изнанке» (недосягаемость до следующего действия)!" % attacker.display_name)
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# --- ТАЛАНТ: СБРОС ---

static func execute_talent_reset(attacker: CombatUnit, bm: BattleManager) -> void:
	bm.set_xaeroh(0)
	attacker.set_meta("lenskaya_am_stance", "none")
	if attacker.has_meta("lenskaya_am_in_inverted") and bool(attacker.get_meta("lenskaya_am_in_inverted", false)):
		attacker.set_meta("lenskaya_am_in_inverted", false)
		attacker.remove_meta("untargetable")
		bm.lenskaya_am_inverted_exit_requested.emit(attacker)
		
	# След 2: выход через Талант восстанавливает 25 энергии
	bm.gain_energy_with_err(attacker, 25.0)
	attacker.advance_action(100.0)
	bm.log_message("🌌 %s — Талант «Сброс»: все Xaeroh сброшены до 0, выход в «Без формы», действие продвинуто на 100%% (+25 энергии)!" % attacker.display_name)
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# --- СВЕРХСПОСОБНОСТЬ ---

static func choose_ult_keeper(attacker: CombatUnit, bm: BattleManager) -> void:
	attacker.set_meta("lenskaya_am_stance", "keeper")
	bm.add_xaeroh(100)
	# След 1: при переходе в состояние восстанавливается 1 ОН
	bm.gain_skill_point()
	bm.log_message("🌌 Сверхспособность: %s переходит в состояние «Хранитель Ничто» (+100 Xaeroh, +1 ОН)!" % attacker.display_name)
	if attacker.eidolon >= 6:
		attacker.set_meta("current_attack_element", CombatConstants.Element.QUANTUM)
		bm.log_message("🌌 Эйдолон 6: Вход в форму «Хранитель Ничто» наносит 50%% СА урона Сверхспособности всем противникам!")
		var hit_targets: Array[CombatUnit] = []
		for enemy in bm.get_living_enemies():
			if enemy.is_alive():
				var res := bm.calc_dmg(attacker, enemy, 0.50, 0.0, false, 0.0, 0.0, false, true, "Ultimate")
				bm.deal_damage(enemy, float(res.get("damage", 0.0)), attacker, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)), "Ultimate")
				ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
				hit_targets.append(enemy)
		attacker.remove_meta("current_attack_element")
		_apply_e2_decomposition(attacker, hit_targets, bm)
	bm.unit_updated.emit(attacker)
	bm.action_order_changed.emit()

static func choose_ult_warrior(attacker: CombatUnit, bm: BattleManager) -> void:
	attacker.set_meta("lenskaya_am_stance", "warrior")
	bm.add_xaeroh(100)
	# След 1: при переходе в состояние восстанавливается 1 ОН
	bm.gain_skill_point()
	bm.log_message("🌌 Сверхспособность: %s переходит в состояние «Воин небытия» (+100 Xaeroh, +1 ОН)!" % attacker.display_name)
	if attacker.eidolon >= 6:
		attacker.set_meta("current_attack_element", CombatConstants.Element.QUANTUM)
		bm.log_message("🌌 Эйдолон 6: Вход в форму «Воин небытия» наносит 50%% СА урона Сверхспособности всем противникам!")
		var hit_targets: Array[CombatUnit] = []
		for enemy in bm.get_living_enemies():
			if enemy.is_alive():
				var res := bm.calc_dmg(attacker, enemy, 0.50, 0.0, false, 0.0, 0.0, false, true, "Ultimate")
				bm.deal_damage(enemy, float(res.get("damage", 0.0)), attacker, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)), "Ultimate")
				ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
				hit_targets.append(enemy)
		attacker.remove_meta("current_attack_element")
		_apply_e2_decomposition(attacker, hit_targets, bm)
	bm.unit_updated.emit(attacker)
	bm.action_order_changed.emit()

static func choose_ult_supernova(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	bm.lenskaya_am_supernova_vfx_requested.emit(attacker, target)
	bm.add_xaeroh(100)
	var x_val := bm.get_xaeroh()
	var mult: float = float(x_val) * 0.028
	
	if x_val >= 100:
		attacker.set_meta("lenskaya_am_supernova_100_zero", true)
		
	attacker.set_meta("current_attack_element", CombatConstants.Element.QUANTUM)
	var res := bm.calc_dmg(attacker, target, mult, 0.0, false, 0.0, 0.0, false, true, "Ultimate")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)), "Ultimate")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 3.0)
	
	var hit_targets: Array[CombatUnit] = [target]
	# Эйдолон 4: Уничтожение сверхновой наносит всем остальным противникам 60% СА квантового Бинарного урона
	if attacker.eidolon >= 4:
		attacker.set_meta("is_binary_attack", true)
		for e in bm.get_living_enemies():
			if e != target and e.is_alive():
				var res_e4 := bm.calc_dmg(attacker, e, 0.60, 0.0, false, 0.0, 0.0, false, true, "Binary")
				bm.deal_damage(e, float(res_e4.get("damage", 0.0)), attacker, CombatConstants.Element.QUANTUM, bool(res_e4.get("crit", false)), "Binary")
				ToughnessSystem.apply_weakness_hit(attacker, e, bm, 1.0)
				hit_targets.append(e)
		attacker.remove_meta("is_binary_attack")
		
	attacker.remove_meta("current_attack_element")
	attacker.remove_meta("lenskaya_am_supernova_100_zero")
	_apply_e2_decomposition(attacker, hit_targets, bm)
	
	# Эйдолон 6: Xaeroh тратится лишь на 30% (остается 70%), доп. ход ульты (выбор формы)
	if attacker.eidolon >= 6:
		var kept_x := int(round(float(x_val) * 0.70))
		bm.set_xaeroh(kept_x)
		attacker.set_meta("lenskaya_am_e6_followup_ult", true)
		bm.log_message("🌌 Эйдолон 6: Xaeroh сохранён на 70%% (%d ед.), получен дополнительный ход Сверхспособности для выбора формы!" % kept_x)
	else:
		bm.set_xaeroh(0)
		
	bm.log_message("🌌 %s — «Уничтожение сверхновой» по %s: %d урона (%d%% СА от %d Xaeroh)!" % [attacker.display_name, target.display_name, int(dmg), int(mult * 100), x_val])
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# --- СЛЕД 3 И ЭЙДОЛОН 2 ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---

static func _apply_trace3_console_binary_dmg(attacker: CombatUnit, targets: Array, bm: BattleManager) -> void:
	if not attacker.has_meta("has_console_trait"):
		return
	var vectors := bm.get_console_vectors()
	var tens_vectors: int = int(floor(float(vectors) / 20.0))
	if tens_vectors <= 0:
		return
	var mult: float = float(tens_vectors) * 0.20
	attacker.set_meta("is_binary_attack", true)
	for t in targets:
		if t is CombatUnit and t.is_alive():
			var res := bm.calc_dmg(attacker, t, mult, 0.0, false, 0.0, 0.0, false, true, "Binary")
			bm.deal_damage(t, float(res.get("damage", 0.0)), attacker, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)), "Binary")
	attacker.remove_meta("is_binary_attack")

static func _apply_e2_decomposition(attacker: CombatUnit, targets: Array, bm: BattleManager) -> void:
	if attacker.eidolon < 2:
		return
	var is_single_target := (targets.size() == 1)
	for t in targets:
		if t is CombatUnit and t.is_alive():
			t.set_meta("lenskaya_am_decomp_turns", 2)
			var is_boss_or_elite: bool = t.is_elite or t.id in ["void_boss", "masked_silhouette"] or (t.stats.max_hp >= 50000 and not t.is_ally)
			var vuln: float = 0.60 if is_boss_or_elite else 0.30
			t.set_meta("lenskaya_am_decomp_vuln", vuln)
			if is_single_target:
				t.set_meta("lenskaya_am_e2_single_pen", true)
			bm.log_message("🌌 Эйдолон 2: на %s наложено «Разложение» на 2 хода (+%d%% получаемого квантового урона%s)!" % [
				t.display_name, 
				int(vuln * 100),
				", игнор 20% квант. сопротивления" if is_single_target else ""
			])

# --- ТЕХНИКА ---

static func execute_technique(initiator: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("🌌 Техника Ленской: нанесение 160%% СА физ. урона всем противникам и +30 Xaeroh!")
	bm.add_xaeroh(30)
	initiator.set_meta("current_attack_element", CombatConstants.Element.PHYSICAL)
	for enemy in bm.get_living_enemies():
		if enemy.is_alive():
			var res := bm.calc_dmg(initiator, enemy, 1.60, 0.0, false, 0.0, 0.0, false, true, "Technique")
			var dmg: float = float(res.get("damage", 0.0))
			bm.deal_damage(enemy, dmg, initiator, CombatConstants.Element.PHYSICAL, bool(res.get("crit", false)), "Technique")
			ToughnessSystem.apply_weakness_hit(initiator, enemy, bm, 1.0)
	initiator.remove_meta("current_attack_element")
