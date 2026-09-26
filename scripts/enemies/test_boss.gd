class_name TestBoss
extends RefCounted

## Противник «Тест Босс» для режима «Тестовая среда»
## Предназначен для равного бенчмаркинга команд без рандома и скрытых механик.

const ID := "test_boss"

static func create_unit(custom_hp: float = 1500000.0, custom_def: float = 1200.0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Тест Босс",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": custom_hp,
			"atk": 2400,
			"def": custom_def,
			"spd": 100,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_res": 0.0,
		},
		"toughness": 360,
		"weaknesses": [
			CombatConstants.Element.ICE,
			CombatConstants.Element.FIRE,
			CombatConstants.Element.PHYSICAL,
			CombatConstants.Element.WIND,
			CombatConstants.Element.LIGHTNING,
			CombatConstants.Element.QUANTUM,
			CombatConstants.Element.IMAGINARY,
		],
	})
	return unit

static func pick_target(allies: Array) -> CombatUnit:
	var living: Array[CombatUnit] = []
	for a in allies:
		if a is CombatUnit and a.is_alive():
			living.append(a)
	if living.is_empty():
		return null
	return living[randi() % living.size()]

static func execute_turn(enemy: CombatUnit, allies: Array, battle: BattleManager) -> void:
	var available_targets: Array[CombatUnit] = battle.get_valid_targets_for_enemy(enemy)
	if available_targets.is_empty():
		for a in allies:
			if a is CombatUnit and a.is_alive():
				available_targets.append(a)
	if available_targets.is_empty():
		return

	var danill := battle.get_danila_unit()
	var primary_target: CombatUnit = null
	if danill and danill.is_alive() and int(danill.get_meta("danill_taunt_turns", 0)) > 0 and danill in available_targets:
		primary_target = danill
	else:
		primary_target = pick_target(available_targets)

	if primary_target == null:
		return

	var turn_count: int = int(enemy.get_meta("turn_count", 1))

	# Ротация атак: 1 - Одиночный (1.5x), 2 - Рассекающий (1.0x / 0.6x), 3 - AoE (0.9x)
	var mod_turn := turn_count % 3
	match mod_turn:
		1:
			_execute_single_attack(enemy, primary_target, battle)
		2:
			_execute_blast_attack(enemy, primary_target, allies, battle)
		_:
			_execute_aoe_attack(enemy, allies, battle)

static func _execute_single_attack(enemy: CombatUnit, target: CombatUnit, battle: BattleManager) -> void:
	battle.log_message("%s использует «Калиброванный выстрел» по %s!" % [enemy.display_name, target.display_name])
	var result: Dictionary = DamageCalculator.calc_damage(enemy, target, 1.50)
	var dmg_val: float = float(result.get("damage", 0.0))
	battle.deal_damage(target, dmg_val, enemy, -1, result.get("crit", false))
	battle.log_message("  → %s получает %d урона%s" % [
		target.display_name,
		int(dmg_val),
		" (КРИТ!)" if result.get("crit", false) else ""
	])

static func _execute_blast_attack(enemy: CombatUnit, primary_target: CombatUnit, allies: Array, battle: BattleManager) -> void:
	battle.log_message("%s использует «Резонансный взрыв» по %s!" % [enemy.display_name, primary_target.display_name])
	# Основная цель
	var res_main: Dictionary = DamageCalculator.calc_damage(enemy, primary_target, 1.00)
	var dmg_main: float = float(res_main.get("damage", 0.0))
	battle.deal_damage(primary_target, dmg_main, enemy, -1, res_main.get("crit", false))
	battle.log_message("  → [Основная цель] %s: %d урона" % [primary_target.display_name, int(dmg_main)])

	# Соседние союзники
	var adjacents: Array[CombatUnit] = battle.get_adjacent_allies(primary_target)
	for adj in adjacents:
		if adj.is_alive():
			var res_adj: Dictionary = DamageCalculator.calc_damage(enemy, adj, 0.60)
			var dmg_adj: float = float(res_adj.get("damage", 0.0))
			battle.deal_damage(adj, dmg_adj, enemy, -1, res_adj.get("crit", false))
			battle.log_message("  → [Соседняя цель] %s: %d урона" % [adj.display_name, int(dmg_adj)])

static func _execute_aoe_attack(enemy: CombatUnit, allies: Array, battle: BattleManager) -> void:
	battle.log_message("%s активирует «Тестовый импульс поля» по всей команде!" % enemy.display_name)
	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			var res_aoe: Dictionary = DamageCalculator.calc_damage(enemy, ally, 0.90)
			var dmg_aoe: float = float(res_aoe.get("damage", 0.0))
			battle.deal_damage(ally, dmg_aoe, enemy, -1, res_aoe.get("crit", false))
			battle.log_message("  → %s: %d урона" % [ally.display_name, int(dmg_aoe)])
