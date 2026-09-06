class_name VoidBoss
extends RefCounted

const ID := "void_boss"
const FREEZE_INTERVAL := 3
const AOE_INTERVAL := 4

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Повелитель Пустоты",
		"element": CombatConstants.Element.IMAGINARY,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": true, # Босс считается элитным противником
		"stats": {
			"hp": 117000, # Огромный запас здоровья
			"atk": 1800, # Высокая сила атаки
			"def": 950,
			"spd": 95,
			"crit_rate": 0.15,
			"crit_dmg": 0.80,
			"effect_res": 0.35,
		},
		"toughness": 360, # Прочный щит стойкости
		"weaknesses": [
			CombatConstants.Element.PHYSICAL,
			CombatConstants.Element.IMAGINARY,
			CombatConstants.Element.WIND,
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

static func execute_freeze_attack(attacker: CombatUnit, target: CombatUnit, battle: BattleManager) -> void:
	battle.log_message("%s использует «Ледяное Заточение» на %s!" % [attacker.display_name, target.display_name])
	var result: Dictionary = DamageCalculator.calc_damage(attacker, target, 1.0)
	var dmg_val: float = float(result.get("damage", 0.0))
	battle.deal_damage(target, dmg_val, attacker)
	
	# Накладываем статус пропуска хода (заморозка)
	target.statuses.skip_next_turn = true
	target.statuses.skip_next_turn_source = attacker.display_name
	battle.log_message("  → %s заморожен и пропустит следующий ход!" % target.display_name)

static func execute_aoe_attack(attacker: CombatUnit, allies: Array, battle: BattleManager) -> void:
	battle.log_message("%s обрушивает разрушительный «Коллапс Звезд»!" % attacker.display_name)
	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			var result: Dictionary = DamageCalculator.calc_damage(attacker, ally, 1.10)
			var dmg_val: float = float(result.get("damage", 0.0))
			battle.deal_damage(ally, dmg_val, attacker)
			battle.log_message("  → %s получает %d урона!" % [ally.display_name, int(dmg_val)])

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit) -> Dictionary:
	return DamageCalculator.calc_damage(attacker, target, 1.20)

static func pick_skill(turn_count: int) -> String:
	if turn_count > 0 and turn_count % AOE_INTERVAL == 0:
		return "aoe"
	if turn_count > 0 and turn_count % FREEZE_INTERVAL == 0:
		return "freeze"
	return "basic"
