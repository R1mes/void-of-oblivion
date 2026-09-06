class_name ShojiAbilities
extends RefCounted

const ID := "shoji"

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Сёдзи",
		"element": CombatConstants.Element.FIRE,
		"path": CombatConstants.Path.NIHILITY,
		"is_ally": true,
		"eidolon": eidolon,
		"stats": {
			"hp": 2900,
			"atk": 1970,
			"def": 800,
			"spd": 105,
			"crit_rate": 0.05,
			"crit_dmg": 0.30,
			"effect_hit_rate": 0.20,
			"break_effect": 0.20,
			"weakness_efficiency": 0.00,
			"damage_bonus": 0.00,
		},
	})
	
	unit.max_energy = 110.0
	unit.energy = 0.0
	return unit

static func apply_traces(_unit: CombatUnit) -> void:
	pass
