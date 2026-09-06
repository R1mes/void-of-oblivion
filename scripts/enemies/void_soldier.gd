class_name VoidSoldier
extends RefCounted

const ID := "void_soldier"
const SPLASH_INTERVAL := 4

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Солдат Пустоты",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": false,
		"stats": {
			"hp": 17550,
			"atk": 1100,
			"def": 620,
			"spd": 98,
			"crit_rate": 0.10,
			"crit_dmg": 0.55,
			"effect_res": 0.10,
		},
		"toughness": 150,
		"weaknesses": [
			CombatConstants.Element.ICE,
			CombatConstants.Element.FIRE,
			CombatConstants.Element.LIGHTNING,
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

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit) -> Dictionary:
	return DamageCalculator.calc_damage(attacker, target, 1.05)

static func should_use_splash(turn_count: int) -> bool:
	return turn_count > 0 and turn_count % SPLASH_INTERVAL == 0

static func execute_splash_attack(attacker: CombatUnit, allies: Array, battle: BattleManager) -> void:
	battle.log_message("%s — «Удар по площади»!" % attacker.display_name)
	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			var result := DamageCalculator.calc_damage(attacker, ally, 0.50)
			battle.deal_damage(ally, result.damage, attacker)
			battle.log_message("  → %s: %d урона" % [ally.display_name, int(result.damage)])
