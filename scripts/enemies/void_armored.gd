class_name VoidArmored
extends RefCounted

const ID := "void_armored"
const ARMOR_INTERVAL := 4

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Бронированный Рыцарь",
		"element": CombatConstants.Element.FIRE,
		"path": CombatConstants.Path.PRESERVATION,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": 65250,
			"atk": 1320,
			"def": 1200,
			"spd": 88,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_res": 0.20,
		},
		"toughness": 240,
		"weaknesses": [
			CombatConstants.Element.LIGHTNING,
			CombatConstants.Element.QUANTUM,
			CombatConstants.Element.FIRE,
		],
	})
	unit.set_meta("hell_armor", false)
	return unit

static func pick_target(allies: Array) -> CombatUnit:
	var living: Array[CombatUnit] = []
	for a in allies:
		if a is CombatUnit and a.is_alive():
			living.append(a)
	if living.is_empty():
		return null
	return living[randi() % living.size()]

static func execute_armor_skill(attacker: CombatUnit, battle: BattleManager) -> void:
	attacker.set_meta("hell_armor", true)
	battle.log_message("%s активирует «Адскую броню»! Получаемый им урон снижен на 40%%." % attacker.display_name)
	
	# ИСПРАВЛЕНО: Отправляем сигнал обновления в UI, чтобы статус сразу появился на карточке
	battle.unit_updated.emit(attacker)

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit) -> Dictionary:
	return DamageCalculator.calc_damage(attacker, target, 1.10)
