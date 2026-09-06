class_name VikaAbilities
extends RefCounted

const ID := "vika"
const MAX_ENERGY := 110.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Вика",
		"element": CombatConstants.Element.QUANTUM, # Квантовый элемент
		"path": CombatConstants.Path.DESTRUCTION,  # Путь Разрушения
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 4800,           # Высокое базовое ХП для скейлингов
			"atk": 1050,           # Низкий базовый урон
			"def": 950,           # Хорошая защита
			"spd": 98,            # Невысокая скорость
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.0,
			"break_effect": 0.20,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	return
