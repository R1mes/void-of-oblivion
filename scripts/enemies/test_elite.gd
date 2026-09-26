class_name TestElite
extends RefCounted

## Противник «Тест Элита» для режима «Тестовая среда» (режим «3 противника»).

const ID := "test_elite"

static func create_unit(custom_hp: float = 500000.0, custom_def: float = 800.0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Тест Элита",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": custom_hp,
			"atk": 1600,
			"def": custom_def,
			"spd": 95,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_res": 0.0,
		},
		"toughness": 240,
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

	if turn_count % 2 == 1:
		_execute_single_attack(enemy, primary_target, battle)
	else:
		_execute_blast_attack(enemy, primary_target, allies, battle)

static func _execute_single_attack(enemy: CombatUnit, target: CombatUnit, battle: BattleManager) -> void:
	battle.log_message("%s атакует %s точечным зарядом!" % [enemy.display_name, target.display_name])
	var result: Dictionary = DamageCalculator.calc_damage(enemy, target, 1.00)
	var dmg_val: float = float(result.get("damage", 0.0))
	battle.deal_damage(target, dmg_val, enemy, -1, result.get("crit", false))
	battle.log_message("  → %s получает %d урона" % [target.display_name, int(dmg_val)])

static func _execute_blast_attack(enemy: CombatUnit, primary_target: CombatUnit, allies: Array, battle: BattleManager) -> void:
	battle.log_message("%s использует «Квантовый всплеск» по %s!" % [enemy.display_name, primary_target.display_name])
	var res_main: Dictionary = DamageCalculator.calc_damage(enemy, primary_target, 0.80)
	var dmg_main: float = float(res_main.get("damage", 0.0))
	battle.deal_damage(primary_target, dmg_main, enemy, -1, res_main.get("crit", false))
	battle.log_message("  → [Основная цель] %s: %d урона" % [primary_target.display_name, int(dmg_main)])

	var adjacents: Array[CombatUnit] = battle.get_adjacent_allies(primary_target)
	for adj in adjacents:
		if adj.is_alive():
			var res_adj: Dictionary = DamageCalculator.calc_damage(enemy, adj, 0.40)
			var dmg_adj: float = float(res_adj.get("damage", 0.0))
			battle.deal_damage(adj, dmg_adj, enemy, -1, res_adj.get("crit", false))
			battle.log_message("  → [Соседняя цель] %s: %d урона" % [adj.display_name, int(dmg_adj)])
