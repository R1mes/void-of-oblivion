class_name TestSoldier
extends RefCounted

## Противник «Тест Солдат» для режима «Тестовая среда» (режим «Чистый вымысел»).

const ID := "test_soldier"

static func create_unit(custom_hp: float = 70000.0, custom_def: float = 400.0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Тест Солдат",
		"element": CombatConstants.Element.ICE,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": false,
		"stats": {
			"hp": custom_hp,
			"atk": 1200,
			"def": custom_def,
			"spd": 90,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_res": 0.0,
		},
		"toughness": 120,
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
	var target: CombatUnit = null
	if danill and danill.is_alive() and int(danill.get_meta("danill_taunt_turns", 0)) > 0 and danill in available_targets:
		target = danill
	else:
		target = pick_target(available_targets)

	if target == null:
		return

	battle.log_message("%s атакует %s!" % [enemy.display_name, target.display_name])
	var result: Dictionary = DamageCalculator.calc_damage(enemy, target, 1.00)
	var dmg_val: float = float(result.get("damage", 0.0))
	battle.deal_damage(target, dmg_val, enemy, -1, result.get("crit", false))
	battle.log_message("  → %s получает %d урона" % [target.display_name, int(dmg_val)])
