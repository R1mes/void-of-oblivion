class_name VoidElite
extends RefCounted

const ID := "void_elite"
const AOE_INTERVAL := 2
const HEAL_INTERVAL := 3

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Элитный Страж",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": 44550,
			"atk": 1450,
			"def": 780,
			"spd": 92,
			"crit_rate": 0.12,
			"crit_dmg": 0.70,
			"effect_res": 0.20,
		},
		"toughness": 240,
		"weaknesses": [
			CombatConstants.Element.ICE,
			CombatConstants.Element.PHYSICAL,
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

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit) -> Dictionary:
	return DamageCalculator.calc_damage(attacker, target, 1.10)

static func execute_aoe_skill(attacker: CombatUnit, allies: Array, battle: BattleManager) -> void:
	battle.log_message("%s использует «Волну Пустоты»!" % attacker.display_name)
	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			var result := DamageCalculator.calc_damage(attacker, ally, 0.85)
			battle.deal_damage(ally, result.damage, attacker)
			battle.log_message(
				"  → %s: %d урона%s" % [
					ally.display_name,
					int(result.damage),
					" (КРИТ!)" if result.crit else "",
				],
			)

static func execute_self_heal(attacker: CombatUnit, battle: BattleManager) -> void:
	var amount := attacker.stats.max_hp * 0.08
	var healed: float = attacker.heal(amount)
	battle.log_message(
		"%s — «Поглощение»: +%d ХП" % [attacker.display_name, int(healed)],
	)
	battle.unit_updated.emit(attacker)

static func should_use_aoe(turn_count: int) -> bool:
	return turn_count > 0 and turn_count % AOE_INTERVAL == 0

static func should_use_heal(turn_count: int) -> bool:
	return turn_count > 0 and turn_count % HEAL_INTERVAL == 0

static func pick_skill(turn_count: int) -> String:
	if should_use_aoe(turn_count):
		return "aoe"
	if should_use_heal(turn_count):
		return "heal"
	return "basic"
