class_name ArseniyAbilities
extends RefCounted

const ID := "arseniy"
const MAX_ENERGY := 110.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Арсений",
		"element": CombatConstants.Element.ICE,
		"path": CombatConstants.Path.HARMONY,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3600,
			"atk": 1150,
			"def": 850,
			"spd": 104,
			"crit_rate": 0.12,
			"crit_dmg": 0.65,
			"effect_hit_rate": 0.20,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	unit.gain_energy(unit.max_energy * 0.67)

static func is_new_development(unit: CombatUnit) -> bool:
	return unit.statuses.new_development_turns > 0

static func apply_new_development(unit: CombatUnit, turns: int) -> void:
	unit.statuses.new_development_turns = maxi(unit.statuses.new_development_turns, turns)
	unit.statuses.new_development_source = unit.display_name

static func apply_self_atk_buff(unit: CombatUnit, percent: float, turns: int) -> void:
	unit.statuses.self_atk_buff_percent = percent
	unit.statuses.self_atk_buff_turns = maxi(unit.statuses.self_atk_buff_turns, turns)
	unit.statuses.self_atk_buff_source = unit.display_name

static func get_ally_crit_bonus(battle: BattleManager) -> float:
	var arseniy := battle.get_arseniy_unit()
	if arseniy and is_new_development(arseniy):
		return 0.10
	return 0.0

static func apply_dark_seal(battle: BattleManager, target: CombatUnit, turns: int = 2) -> void:
	if battle.dark_seal_holder and battle.dark_seal_holder != target:
		clear_dark_seal(battle.dark_seal_holder)
	battle.dark_seal_holder = target
	target.statuses.has_dark_seal = true
	target.statuses.dark_seal_turns = turns
	target.statuses.dark_seal_source = battle.get_arseniy_unit().display_name if battle.get_arseniy_unit() else "Арсений"

static func clear_dark_seal(target: CombatUnit) -> void:
	target.statuses.has_dark_seal = false
	target.statuses.dark_seal_turns = 0
	target.statuses.dark_seal_source = ""

static func talent_advance(arseniy: CombatUnit, battle: BattleManager) -> void:
	arseniy.advance_action(10.0)
	battle.action_order_changed.emit()
	battle.log_message("Талант: действие %s продвинуто на 10%%" % arseniy.display_name)

static func execute_basic(attacker: CombatUnit, target: CombatUnit, battle: BattleManager) -> void:
	var crit_bonus := battle.get_extra_crit_dmg(attacker)
	var result := DamageCalculator.calc_damage(
		attacker, target, 0.60, 0.0, false, 0.0, crit_bonus,
	)
	battle.deal_damage(target, result.damage, attacker)
	ToughnessSystem.apply_weakness_hit(attacker, target, battle)
	ToughnessSystem.on_hit_entanglement(target)
	battle.gain_skill_point()
	attacker.gain_energy(20)
	battle.log_message(
		"%s — базовая атака по %s: %d%s" % [
			attacker.display_name,
			target.display_name,
			int(result.damage),
			" (КРИТ!)" if result.crit else "",
		],
	)

static func execute_enhanced_basic(
	attacker: CombatUnit,
	target: CombatUnit,
	battle: BattleManager,
) -> void:
	apply_dark_seal(battle, target, 2)
	talent_advance(attacker, battle)
	battle.gain_skill_point()
	attacker.gain_energy(20)
	battle.log_message(
		"Усиленная атака: «Тёмная печать» на %s (2 хода)" % target.display_name,
	)
	battle.unit_updated.emit(target)

static func execute_skill_q_damage(
	attacker: CombatUnit,
	targets: Array,
	battle: BattleManager,
) -> void:
	var crit_bonus := battle.get_extra_crit_dmg(attacker)
	for i in range(targets.size()):
		var target = targets[i]
		if target is CombatUnit and target.is_alive():
			var result := DamageCalculator.calc_damage(
				attacker, target, 1.0, 0.0, false, 0.0, crit_bonus,
			)
			battle.deal_damage(target, result.damage, attacker)
			
			# ИСПРАВЛЕНО: Центральная цель (индекс 0) получает +25% истощения стойкости (1.25x),
			# а соседние (индекс > 0) получают -25% (0.75x).
			var tgh_mult: float = 1.25 if i == 0 else 0.75
			ToughnessSystem.apply_weakness_hit(attacker, target, battle, tgh_mult)
			
			ToughnessSystem.on_hit_entanglement(target)
			battle.log_message(
				"Навык Q: %d урона по %s%s" % [
					int(result.damage),
					target.display_name,
					" (КРИТ!)" if result.crit else "",
				],
			)
	attacker.gain_energy(30)

static func execute_skill_q_buff(
	attacker: CombatUnit,
	ally: CombatUnit,
	battle: BattleManager,
) -> void:
	# ИСПРАВЛЕНО: Считываем истинную эффективную СА Арсения со всеми конусами и реликвиями
	var arseniy_eff_atk: float = battle.get_effective_atk_complete(attacker)
	var bonus_atk: float = arseniy_eff_atk * 0.30 + 150.0
	
	ally.set_meta("arseniy_q_atk_percent", 0.0) 
	ally.set_meta("arseniy_q_atk_flat", bonus_atk)
	ally.set_meta("arseniy_q_turns", 1)
	
	talent_advance(attacker, battle)
	attacker.gain_energy(30)
	battle.log_message(
		"Усиленный Q: СА %s +%d на 1 ход (независимый бафф)" % [
			ally.display_name,
			int(bonus_atk),
		],
	)
	battle.unit_updated.emit(ally)

static func execute_skill_e(attacker: CombatUnit, battle: BattleManager) -> void:
	if attacker.eidolon >= 4:
		attacker.statuses.cleanse_all()
		battle.log_message("Э4: все дебаффы сняты с %s" % attacker.display_name)
	apply_new_development(attacker, 2)
	attacker.set_meta("new_dev_skip_tick", true)
	attacker.gain_energy(25)
	battle.log_message("Навык E: «Новая разработка» — следующие 2 действия усилены")
	battle.unit_updated.emit(attacker)

static func execute_ultimate(
	attacker: CombatUnit,
	target: CombatUnit,
	battle: BattleManager,
) -> void:
	if not is_new_development(attacker):
		battle.log_message("Сверхспособность доступна только в «Новой разработке»!")
		return

	var crit_bonus := battle.get_extra_crit_dmg(attacker)
	var result := DamageCalculator.calc_damage(
		attacker, target, 2.30, 0.0, false, 0.0, crit_bonus,
	)
	battle.deal_damage(target, result.damage, attacker)
	ToughnessSystem.apply_weakness_hit(attacker, target, battle, 1.5)
	ToughnessSystem.on_hit_entanglement(target)
	battle.gain_skill_point()

	# ИСПРАВЛЕНО: Считываем истинную эффективную СА Арсения для баффа Сверхспособности
	var arseniy_eff_atk: float = battle.get_effective_atk_complete(attacker)
	var atk_buff: float = arseniy_eff_atk * 0.20
	
	for ally in battle.allies:
		if ally.is_alive():
			ally.statuses.atk_buff_flat = atk_buff
			ally.statuses.atk_buff_turns = maxi(ally.statuses.atk_buff_turns, 2)
			ally.statuses.atk_buff_source = attacker.display_name
			if attacker.eidolon >= 6:
				ally.statuses.crit_dmg_buff = attacker.stats.crit_dmg * 0.30
				ally.statuses.crit_dmg_buff_turns = maxi(ally.statuses.crit_dmg_buff_turns, 2)
				ally.statuses.crit_dmg_buff_source = attacker.display_name
			battle.unit_updated.emit(ally)

	battle.log_message(
		"Сверхспособность: %d урона по %s, +1 ОН" % [int(result.damage), target.display_name],
	)
	battle.log_message("След 3: СА союзников усилена на 2 хода")
	if attacker.eidolon >= 6:
		battle.log_message("Э6: крит. урон союзников усилен")

static func on_enemy_killed(killer: CombatUnit, victim: CombatUnit, battle: BattleManager) -> void:
	if not victim.statuses.has_dark_seal:
		return
	clear_dark_seal(victim)
	battle.dark_seal_holder = null
	if killer == null or not killer.is_ally:
		return

	killer.gain_energy(killer.max_energy * 0.20)
	battle.log_message(
		"Тёмная печать: %s восстанавливает 20%% энергии" % killer.display_name,
	)

	var arseniy := battle.get_arseniy_unit()
	if arseniy and arseniy.eidolon >= 1:
		killer.advance_action(30.0)
		battle.action_order_changed.emit()
		battle.log_message("Э1: действие %s продвинуто на 30%%" % killer.display_name)

static func tick_turn_end(unit: CombatUnit, battle: BattleManager) -> void:
	if unit.id == ID and unit.statuses.new_development_turns > 0:
		if unit.get_meta("new_dev_skip_tick", false):
			unit.set_meta("new_dev_skip_tick", false)
		else:
			unit.statuses.new_development_turns -= 1
			if unit.statuses.new_development_turns <= 0:
				unit.statuses.new_development_source = ""

	if unit.statuses.atk_buff_turns > 0:
		unit.statuses.atk_buff_turns -= 1
		if unit.statuses.atk_buff_turns <= 0:
			unit.statuses.atk_buff_percent = 0.0
			unit.statuses.atk_buff_flat = 0.0
			unit.statuses.atk_buff_source = ""

	if unit.statuses.self_atk_buff_turns > 0:
		unit.statuses.self_atk_buff_turns -= 1
		if unit.statuses.self_atk_buff_turns <= 0:
			unit.statuses.self_atk_buff_percent = 0.0
			unit.statuses.self_atk_buff_source = ""

	if unit.statuses.crit_dmg_buff_turns > 0:
		unit.statuses.crit_dmg_buff_turns -= 1
		if unit.statuses.crit_dmg_buff_turns <= 0:
			unit.statuses.crit_dmg_buff = 0.0
			unit.statuses.crit_dmg_buff_source = ""

	if not unit.is_ally and unit.statuses.dark_seal_turns > 0:
		unit.statuses.dark_seal_turns -= 1
		if unit.statuses.dark_seal_turns <= 0:
			clear_dark_seal(unit)
			if battle.dark_seal_holder == unit:
				battle.dark_seal_holder = null

static func apply_technique(unit: CombatUnit) -> void:
	apply_new_development(unit, 1)
	apply_self_atk_buff(unit, 0.20, 2)

static func skill_q_costs_sp(arseniy: CombatUnit) -> bool:
	if is_new_development(arseniy):
		return true
	return arseniy.eidolon < 2
